create or replace
PACKAGE BODY XXCFF009A15C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF009A15C(body)
 * Description      : ���[�X�Ǘ����A�g
 * MD.050           : ���[�X�Ǘ����A�g MD050_CFF_009_A15
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   A-2�D���̓p�����[�^�l���O�o�͏���
 *  get_profile_value      A-3�D�v���t�@�C���擾
 *  get_lease_data         A-5. ���[�X�Ǘ����̎擾
 *  get_lease_data         A-6. ���[�X�x���v����f�[�^�擾
 *  put_lease_data         A-7�D���[�X�Ǘ����f�[�^CSV�쐬����
 *  put_lease_data         A-8�D�X�V����
 *  submain                ���C�������v���V�[�W��
 *  main                   ���[�X�Ǘ����CSV�t�@�C���쐬
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   SCS����          main�V�K�쐬
 *  2009/03/17    1.1   SCS�E��          [T1_0062]�Ή�
 *                                       �@���[�X�Ǘ����̏o�͂Ŏx���񐔂�72��ȏ�̏ꍇ�A
 *                                         �o�͂��Ȃ����䂪�Ȃ��B
 *                                       �A���[�X���A�x�����̏��Ԃ��t�ɂȂ��Ă���B
 *                                       �B���[�X��ނ̕������͒Z�k����ݒ肷��B
 *  2009/04/08    1.1   SCS���          [T1_0354]�Ή�
 *                                       �@�A�gCSV�̏o�͎��Ԃ̃t�H�[�}�b�g��'YYYYMMDDHH24MISS'�ɕύX
 *  2009/05/28    1.2   SCS�E��          [��QT1_1224] �A�g�@�\���G���[�̍ۂ�CSV�t�@�C�����폜�����B
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
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
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- ���b�N(�r�W�[)�G���[
  lock_expt             EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCFF009A15C';            -- �p�b�P�[�W��
  cv_appl_short_name    CONSTANT VARCHAR2(100) := 'XXCFF';                   -- �A�v���P�[�V�����Z�k��
  cv_log                CONSTANT VARCHAR2(100) := 'LOG';                     -- �R���J�����g���O�o�͐�
  cv_which              CONSTANT VARCHAR2(100) := 'OUTPUT';                  -- �R���J�����g���O�o�͐�
  -- ���b�Z�[�W�ԍ�
  cv_msg_xxcff00007     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007';         --���b�N�G���[
  cv_msg_xxcff00062     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00062';         --�Ώۃf�[�^����
  cv_msg_xxcff00020     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020';         --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_xxcff00168     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00168';         --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_xxcff00169     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00169';         --�t�@�C���̏ꏊ���������b�Z�[�W
  cv_msg_xxcff00170     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00170';         --�t�@�C�����I�[�v���ł��Ȃ����b�Z�[�W
  cv_msg_xxcff00171     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00171';         --�t�@�C���ɏ����݂ł��Ȃ����b�Z�[
  cv_msg_xxcff50030     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50030';         --���[�X�_�񖾍׃e�[�u��
  cv_msg_xxcff50014     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50014';         --���[�X�����e�[�u��
  --�v���t�@�C��
  cv_file_name_enter    CONSTANT VARCHAR2(30) := 'XXCFF1_FILE_NAME_CONTROL'; --XXCFF:���[�X�Ǘ����t�@�C������
  cv_file_dir_enter     CONSTANT VARCHAR2(30) := 'XXCFF1_FILE_DIR_CONTROL';  --XXCFF:���[�X�Ǘ����t�@�C���i�[�p�X
  cv_file_com_code      CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CODE';      --XXCFF:���[�X��ЃR�[�h
  -- �g�[�N��
  cv_tkn_table          CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_prof           CONSTANT VARCHAR2(15) := 'PROF_NAME';                -- �v���t�@�C����
  cv_tkn_file           CONSTANT VARCHAR2(15) := 'FILE_NAME';                -- �t�@�C����
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_file_name_enter    VARCHAR2(100) ;   --XXCFF:���[�X�_����t�@�C������
  gn_file_dir_enter     VARCHAR2(500) ;   --XXCFF:���[�X�_����t�@�C���i�[�p�X
  gn_file_com_code      VARCHAR2(500) ;   --XXCFF:���[�X��ЃR�[�h
  gd_sysdateb           DATE;             -- �V�X�e�����t
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
    CURSOR get_lease_cur
    IS
    SELECT   xch.lease_company                           AS lease_company                     --02.���[�X���
            ,xch.contract_number                         AS contract_number                   --03.�_��ԍ�
            ,TO_CHAR(xch.contract_date      ,'YYYYMMDD') AS contract_date                     --04.���[�X�_���
            ,xch.payment_frequency                       AS payment_frequency                 --05.�x����
            ,TO_CHAR(xch.lease_start_date   ,'YYYYMMDD') AS lease_start_date                  --06.���[�X�J�n��
            ,TO_CHAR(xch.lease_end_date     ,'YYYYMMDD') AS lease_end_date                    --07.���[�X�I����
            ,TO_CHAR(xch.first_payment_date ,'YYYYMMDD') AS first_payment_date                --08.����x����
            ,TO_CHAR(xch.second_payment_date,'YYYYMMDD') AS second_payment_date               --09.2��ڎx����
            ,xcl.contract_line_num                       AS contract_line_num                 --10.�_��}��
            ,xcsv.contract_status_name                   AS contract_status_name              --11.�_��X�e�[�^�X����
            ,xltv.lease_type_name                        AS lease_type_name                   --12.���[�X�敪����
            ,xch.re_lease_times                          AS re_lease_times                    --13.�ă��[�X��
            ,xcl.gross_total_charge                      AS gross_total_charge                --14.���z�v_���[�X��
            ,xcl.second_charge                           AS second_charge                     --15.2��ڈȍ~���z���[�X��_���[�X��
            ,xcl.second_tax_charge                       AS second_tax_charge                 --16.2��ڈȍ~����Ŋz_���[�X��
            ,xcl.second_total_charge                     AS second_total_charge               --17.2��ڈȍ~�v_���[�X��
          --,xlkv.lease_kind_name                        AS lease_kind_name                   --18.���[�X��ޖ���
            ,xlkv.book_type_code_if                      AS lease_kind_name                   --18.���[�X��ޖ���
            ,xcl.original_cost                           AS original_cost                     --19.�擾���z
            ,DECODE(xcl.lease_kind,0,SUM(NVL(xpp.fin_debt,0)),0)         AS fin_debt          --20.�e�h�m���[�X���z
            ,DECODE(xcl.lease_kind,0,SUM(NVL(xpp.fin_interest_due,0)),0) AS fin_interest_due  --21.�e�h�m���[�X�x������
            ,DECODE(xcl.lease_kind,0,SUM(NVL(xpp.fin_tax_debt,0)),0)     AS fin_tax_debt      --21.�e�h�m���[�X�x������
            ,xcl.calc_interested_rate                    AS calc_interested_rate              --23.�v�Z���q��
            ,xoh.object_code                             AS object_code                       --24.�����R�[�h
            ,xoh.quantity                                AS quantity                          --25.����
            ,xoh.department_code                         AS department_code                   --26.�Ǘ�����R�[�h
            ,TO_CHAR(xoh.cancellation_date ,'YYYYMMDD')  AS cancellation_date                 --27.���r����
            ,xoh.object_header_id             --28.��������id
            ,xcl.contract_line_id             --29.�_�񖾍ד���id
    FROM     xxcff_contract_headers  xch      --���[�X�_��
            ,xxcff_contract_lines    xcl      --���[�X�_�񖾍�
            ,xxcff_object_headers    xoh      --���[�X����
            ,xxcff_pay_planning      xpp      --���[�X�x���v��
            ,xxcff_contract_status_v xcsv     --�_��X�e�[�^�X�r���[
            ,xxcff_lease_type_v      xltv     --���[�X�敪�r���[
            ,xxcff_lease_kind_v      xlkv     --���[�X��ރr���[
    WHERE    xch.contract_header_id = xcl.contract_header_id
    AND      xcl.object_header_id   = xoh.object_header_id
    AND      xcl.contract_line_id   = xpp.contract_line_id(+)
    AND      xch.lease_class        IN(SELECT lease_class_code
                                       FROM   xxcff_lease_class_v
                                       WHERE  vdsh_flag = 'Y')
    AND      xoh.object_status      IN('102','104','107','108','110','111','112')
    AND    ((xoh.info_sys_if_date < xoh.last_update_date OR xoh.info_sys_if_date IS NULL) 
    OR      (xcl.info_sys_if_date < xcl.last_update_date OR xcl.info_sys_if_date IS NULL))
    AND      xch.re_lease_times        = xoh.re_lease_times
    AND      xcsv.contract_status_code = xcl.contract_status
    AND      xltv.lease_type_code      = xch.lease_type
    AND      xlkv.lease_kind_code      = xcl.lease_kind
    GROUP BY 
             xch.lease_company          --02.���[�X���
            ,xch.contract_number        --03.�_��ԍ�
            ,xch.contract_date          --04.���[�X�_���
            ,xch.payment_frequency      --05.�x����
            ,xch.lease_start_date       --06.���[�X�J�n��
            ,xch.lease_end_date         --07.���[�X�I����
            ,xch.first_payment_date     --08.����x����
            ,xch.second_payment_date    --09.2��ڎx����
            ,xcl.contract_line_num      --10.�_��}��
            ,xcsv.contract_status_name  --11.�_��X�e�[�^�X����
            ,xltv.lease_type_name       --12.���[�X�敪����
            ,xch.re_lease_times         --13.�ă��[�X��
            ,xcl.gross_total_charge     --14.���z�v_���[�X��
            ,xcl.second_charge          --15.2��ڈȍ~���z���[�X��_���[�X��
            ,xcl.second_tax_charge      --16.2��ڈȍ~����Ŋz_���[�X��
            ,xcl.second_total_charge    --17.2��ڈȍ~�v_���[�X��
         -- ,xlkv.lease_kind_name       --18.���[�X��ޖ���
            ,xlkv.book_type_code_if     --18.���[�X��ޖ���
            ,xcl.original_cost          --19.�擾���z
            ,xcl.lease_kind
            ,xcl.calc_interested_rate   --23.�v�Z���q��
            ,xoh.object_code            --24.�����R�[�h
            ,xoh.quantity               --25.����
            ,xoh.department_code        --26.�Ǘ�����R�[�h
            ,xoh.cancellation_date      --27.���r����
            ,xoh.object_header_id       --28.��������id
            ,xcl.contract_line_id       --29.�_�񖾍ד���id
    ORDER BY
             xch.lease_company          --02.���[�X���
            ,xch.contract_number        --03.�_��ԍ�
            ,xcl.contract_line_num      --10.�_��}��
    ;
    TYPE g_lease_ttype IS TABLE OF get_lease_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gt_lease_data      g_lease_ttype;
    --
    CURSOR get_payment_cur(i_contract_line_id IN VARCHAR2)
    IS
    SELECT   payment_frequency                             AS payment_frequency --�x����
            ,TO_CHAR(payment_date ,'YYYYMMDD')             AS payment_date      --�x����
            ,NVL(lease_charge,0) + NVL(lease_tax_charge,0) AS lease_charge      --���[�X���{���[�X��_�����
    FROM     xxcff_pay_planning
    WHERE    contract_line_id  = i_contract_line_id
    ORDER BY payment_frequency
    ;
    TYPE g_payment_ttype IS TABLE OF get_payment_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gt_payment_data      g_payment_ttype;
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
    lv_errbuf     VARCHAR2(5000);    -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);       -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000);    -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
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
    xxcff_common1_pkg.put_log_param
    (
     iv_which    => cv_which     -- �o�͋敪
    ,ov_retcode  => lv_retcode   --���^�[���R�[�h
    ,ov_errbuf   => lv_errbuf    --�G���[���b�Z�[�W
    ,ov_errmsg   => lv_errmsg    --���[�U�[�E�G���[���b�Z�[�W
    );
    IF lv_retcode != cv_status_normal THEN
      RAISE global_api_expt;
    END IF;
    xxcff_common1_pkg.put_log_param
    (
     iv_which    => cv_log       -- �o�͋敪
    ,ov_retcode  => lv_retcode   --���^�[���R�[�h
    ,ov_errbuf   => lv_errbuf    --�G���[���b�Z�[�W
    ,ov_errmsg   => lv_errmsg    --���[�U�[�E�G���[���b�Z�[�W
    );
    IF lv_retcode != cv_status_normal THEN
      RAISE global_api_expt;
    END IF;

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
   * Procedure Name   : get_profile_value
   * Description      : A-3. �v���t�@�C���擾����
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
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
    -- =====================================================
    -- �v���t�@�C������ XXCFF:���[�X�Ǘ����f�[�^�t�@�C�����擾
    -- =====================================================
    gn_file_name_enter      := FND_PROFILE.VALUE(cv_file_name_enter);
    IF (gn_file_name_enter IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
       cv_appl_short_name  -- 'XXCFF'
      ,cv_msg_xxcff00020   -- �v���t�@�C���擾�G���[
      ,cv_tkn_prof         -- �g�[�N��'PROF_NAME'
      ,cv_file_name_enter  -- �t�@�C����
      )
      ,1
      ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- =====================================================
    -- �v���t�@�C������ XXCFF:���[�X�Ǘ����f�[�^�t�@�C���i�[�p�X���擾
    -- =====================================================
    gn_file_dir_enter := FND_PROFILE.VALUE(cv_file_dir_enter);
    IF (gn_file_dir_enter IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
       cv_appl_short_name  -- 'XXCFF'
      ,cv_msg_xxcff00020   -- �v���t�@�C���擾�G���[
      ,cv_tkn_prof         -- �g�[�N��'PROF_NAME'
      ,cv_file_dir_enter   -- �p�X��
      )
      ,1
      ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- =====================================================
    -- �v���t�@�C������ XXCFF:���[�X��ЃR�[�h
    -- =====================================================
    gn_file_com_code := FND_PROFILE.VALUE(cv_file_com_code);
    IF (gn_file_com_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
       cv_appl_short_name  -- 'XXCFF'
      ,cv_msg_xxcff00020   -- �v���t�@�C���擾�G���[
      ,cv_tkn_prof         -- �g�[�N��'PROF_NAME'
      ,cv_file_com_code    -- �p�X��
      )
      ,1
      ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END get_profile_value;
  /**********************************************************************************
   * Procedure Name   : get_lease_data
   * Description      : A-6. ���[�X�_����̎擾
   ***********************************************************************************/
  PROCEDURE get_lease_data(
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_data'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
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
    OPEN  get_lease_cur;
    FETCH get_lease_cur BULK COLLECT INTO gt_lease_data;
    gn_target_cnt := gt_lease_data.COUNT;
    CLOSE get_lease_cur;
    --
  EXCEPTION
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
  END get_lease_data;
  /**********************************************************************************
   * Procedure Name   : put_lease_data
   * Description      : A-7�D���[�X�_����f�[�^CSV�쐬����
   ***********************************************************************************/
  PROCEDURE put_lease_data(
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'put_lease_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf           VARCHAR2(5000);                   -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1);                      -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(5000);                   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_open_mode_w      CONSTANT VARCHAR2(10) := 'w';     -- �t�@�C���I�[�v�����[�h�i�㏑���j
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';     -- CSV��؂蕶��
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';     -- �P��͂ݕ���
    cv_null             CONSTANT VARCHAR2(2)  := NULL;    -- �Œ�l
    -- *** ���[�J���ϐ� ***
    ln_target_cnt       NUMBER := 0;                      -- �Ώی���
    ln_loop_cnt         NUMBER;                           -- ���[�v�J�E���^
    ln_cnt              NUMBER;                           -- ���[�v�J�E���^
    in_contract_line_id NUMBER;
    in_object_header_id NUMBER;
    iv_table_name       VARCHAR2(20);
    -- �t�@�C���o�͊֘A
    lf_file_hand        UTL_FILE.FILE_TYPE ;              -- �t�@�C���E�n���h���̐錾
    lv_csv_text         VARCHAR2(32767) ;                 -- �o�͂P�s��������ϐ�
    lb_fexists          BOOLEAN;                          -- �t�@�C�������݂��邩�ǂ���
    ln_file_size        NUMBER;                           -- �t�@�C���̒���
    ln_block_size       NUMBER;                           -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
    -- *** ���[�J���E�J�[�\�� ***
    gn_payment_cnt      NUMBER;
    ln_count            NUMBER;
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
    -- ====================================================
    -- �t�s�k�t�@�C���I�[�v��
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
    (
    gn_file_dir_enter,
    gn_file_name_enter,
    cv_open_mode_w,
    32767
    );
    -- ====================================================
    -- �o�̓f�[�^���o
    -- ====================================================
    IF gn_target_cnt <> 0 THEN
        <<out_loop>>
        FOR ln_loop_cnt IN gt_lease_data.FIRST..gt_lease_data.LAST LOOP
          --
          -- �o�͕�����쐬
          lv_csv_text := 
             cv_enclosed ||  gn_file_com_code                               || cv_enclosed || cv_delimiter  -- 01.��ЃR�[�h
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).lease_company       || cv_enclosed || cv_delimiter  -- 02.���[�X���
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).contract_number     || cv_enclosed || cv_delimiter  -- 03.�_��ԍ�
          ||                 gt_lease_data(ln_loop_cnt).contract_date                      || cv_delimiter  -- 04.���[�X�_���
          ||                 gt_lease_data(ln_loop_cnt).payment_frequency                  || cv_delimiter  -- 05.�x����
          ||                 gt_lease_data(ln_loop_cnt).lease_start_date                   || cv_delimiter  -- 06.���[�X�J�n��
          ||                 gt_lease_data(ln_loop_cnt).lease_end_date                     || cv_delimiter  -- 07.���[�X�I����
          ||                 gt_lease_data(ln_loop_cnt).first_payment_date                 || cv_delimiter  -- 08.����x����
          ||                 gt_lease_data(ln_loop_cnt).second_payment_date                || cv_delimiter  -- 09.2��ڎx����
          ||                 gt_lease_data(ln_loop_cnt).contract_line_num                  || cv_delimiter  -- 10.�_��}��
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).contract_status_name|| cv_enclosed || cv_delimiter  -- 11.�_��X�e�[�^�X����
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).lease_type_name     || cv_enclosed || cv_delimiter  -- 12.���[�X�敪����
          ||                 gt_lease_data(ln_loop_cnt).re_lease_times                     || cv_delimiter  -- 13.�ă��[�X��
          ||                 gt_lease_data(ln_loop_cnt).gross_total_charge                 || cv_delimiter  -- 14.���z�v_���[�X��
          ||                 gt_lease_data(ln_loop_cnt).second_charge                      || cv_delimiter  -- 15.2��ڈȍ~���z���[�X��_���[�X��
          ||                 gt_lease_data(ln_loop_cnt).second_tax_charge                  || cv_delimiter  -- 16.2��ڈȍ~����Ŋz_���[�X��
          ||                 gt_lease_data(ln_loop_cnt).second_total_charge                || cv_delimiter  -- 17.2��ڈȍ~�v_���[�X��
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).lease_kind_name     || cv_enclosed || cv_delimiter  -- 18.���[�X��ޖ���
          ||                 gt_lease_data(ln_loop_cnt).original_cost                      || cv_delimiter  -- 19.�擾���z
          ||                 gt_lease_data(ln_loop_cnt).fin_debt                           || cv_delimiter  -- 20.�e�h�m���[�X���z
          ||                 gt_lease_data(ln_loop_cnt).fin_interest_due                   || cv_delimiter  -- 21.�e�h�m���[�X�x������
          ||                 gt_lease_data(ln_loop_cnt).fin_tax_debt                       || cv_delimiter  -- 22.�e�h�m���[�X���z_�����
          ||                 gt_lease_data(ln_loop_cnt).calc_interested_rate               || cv_delimiter  -- 23.�v�Z���q��
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).object_code         || cv_enclosed || cv_delimiter  -- 24.�����R�[�h
          ||                 gt_lease_data(ln_loop_cnt).quantity                           || cv_delimiter  -- 25.����
          || cv_enclosed ||  gt_lease_data(ln_loop_cnt).department_code     || cv_enclosed || cv_delimiter  -- 26.�Ǘ�����R�[�h
          ||                 gt_lease_data(ln_loop_cnt).cancellation_date                  || cv_delimiter  -- 27.���r����
          ;
          --�x���v�撊�o
          OPEN  get_payment_cur(gt_lease_data(ln_loop_cnt).contract_line_id);
          FETCH get_payment_cur BULK COLLECT INTO gt_payment_data;
                gn_payment_cnt := NVL(gt_payment_data.COUNT,0);
          CLOSE get_payment_cur;
          IF gn_payment_cnt = 0 THEN
              FOR ln_cnt IN 1..72 LOOP
                lv_csv_text       := lv_csv_text  ||  cv_delimiter;                                          -- ���[�X���{���[�X��_�����
                lv_csv_text       := lv_csv_text  ||  cv_delimiter;                                          -- �x����
              END LOOP;
          ELSE
              <<out_loop>>
              FOR ln_cnt IN gt_payment_data.FIRST..gt_payment_data.LAST LOOP
               -- lv_csv_text     := lv_csv_text  ||  gt_payment_data(ln_cnt).payment_date || cv_delimiter;  -- �x����
               -- lv_csv_text     := lv_csv_text  ||  gt_payment_data(ln_cnt).lease_charge || cv_delimiter;  -- ���[�X���{���[�X��_�����
                  IF ( ln_cnt <= 72 ) THEN 
                    lv_csv_text   := lv_csv_text  ||  gt_payment_data(ln_cnt).lease_charge || cv_delimiter;  -- ���[�X���{���[�X��_�����
                    lv_csv_text   := lv_csv_text  ||  gt_payment_data(ln_cnt).payment_date || cv_delimiter;  -- �x����
                  END IF;  
              END LOOP out_loop;
              IF  gn_payment_cnt < 72 THEN
                  ln_count := gn_payment_cnt + 1;
                  FOR ln_cnt IN ln_count..72 LOOP
                      lv_csv_text := lv_csv_text  ||  cv_delimiter;                                          -- ���[�X���{���[�X��_�����
                      lv_csv_text := lv_csv_text  ||  cv_delimiter;                                          -- �x����
                  END LOOP; 
              END IF;
          END IF;
          --
          lv_csv_text := lv_csv_text ||     TO_CHAR(gd_sysdateb,'YYYYMMDDHH24MISS');  --[T1_0354]�Ή�                           -- �A�g����
--          lv_csv_text := lv_csv_text ||     TO_CHAR(gd_sysdateb,'YYYYMMDDHHMISS');                           -- �A�g����
          --
          -- ====================================================
          -- �t�@�C����������
          -- ====================================================
          UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
          --
          -- ====================================================
          -- ���������J�E���g�A�b�v
          -- ====================================================
          ln_target_cnt := ln_target_cnt + 1 ;
          -- ====================================================
          -- A-8�D�X�V����(���[�X�_�񖾍�)
          -- ====================================================
          iv_table_name  := cv_msg_xxcff50030;  --���[�X�_�񖾍׃e�[�u��
          SELECT   contract_line_id AS contract_line_id
          INTO     in_contract_line_id
          FROM     xxcff_contract_lines
          WHERE    contract_line_id      = gt_lease_data(ln_loop_cnt).contract_line_id
          FOR UPDATE NOWAIT
          ;
          UPDATE  xxcff_contract_lines
          SET     info_sys_if_date       = gd_sysdateb
          WHERE   contract_line_id       = gt_lease_data(ln_loop_cnt).contract_line_id
          ;
          --
          -- ====================================================
          -- A-8�D�X�V����(���[�X����)
          -- ====================================================
          iv_table_name  := cv_msg_xxcff50014;  --���[�X�����e�[�u��
          SELECT   object_header_id AS object_header_id
          INTO     in_object_header_id
          FROM     xxcff_object_headers
          WHERE    object_header_id      = gt_lease_data(ln_loop_cnt).object_header_id
          FOR UPDATE NOWAIT
          ;
          UPDATE  xxcff_object_headers
          SET     info_sys_if_date       = gd_sysdateb
          WHERE   object_header_id       = gt_lease_data(ln_loop_cnt).object_header_id
          ;
          --
        END LOOP out_loop;
        --
    ELSE
        -- ====================================================
        -- �t�@�C����������
        -- ====================================================
        UTL_FILE.PUT_LINE( lf_file_hand, cv_null ) ;
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
        (
        cv_appl_short_name,    -- 'XXCFF'
        cv_msg_xxcff00062      -- �Ώۃf�[�^��0���G���[
        )
        ,1
        ,5000);
        lv_errbuf  := lv_errmsg;
        --
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
        --
    END IF;
    -- ====================================================
    -- �t�s�k�t�@�C���N���[�Y
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand );
    --
    gn_normal_cnt := ln_target_cnt;
    --
  EXCEPTION
    -- ====================================================
    -- *** ���b�N(�r�W�[)�G���[
    -- ====================================================
    WHEN lock_expt THEN
      IF UTL_FILE.IS_OPEN  ( lf_file_hand ) THEN
         UTL_FILE.FCLOSE   ( lf_file_hand );
-- T1_1224 2009/05/28 DEL START --
--       UTL_FILE.FREMOVE  ( gn_file_dir_enter , gn_file_name_enter);
-- T1_1224 2009/05/28 DEL END   --
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
      (
       cv_appl_short_name   -- 'XXCFF'
      ,cv_msg_xxcff00007    -- �e�[�u�����b�N�G���[
      ,cv_tkn_table         -- �g�[�N��'TABLE'
      ,iv_table_name        -- �e�[�u����
      )
      ,1
      ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- ====================================================
    -- *** �t�@�C���̏ꏊ�������ł� ***
    -- ====================================================
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
      cv_appl_short_name,    -- 'XXCFF'
      cv_msg_xxcff00169      -- �t�@�C���̏ꏊ������
      )
      ,1
      ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- ====================================================
    -- *** �v���ǂ���Ƀt�@�C�����I�[�v���ł��Ȃ����A�܂��͑���ł��܂��� ***
    -- ====================================================
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
      cv_appl_short_name,    -- 'XXCFF'
      cv_msg_xxcff00170      -- �t�@�C�����I�[�v���ł��Ȃ�
      )
      ,1
      ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- ====================================================
    -- *** �����ݑ��쒆�ɃI�y���[�e�B���O�E�V�X�e���̃G���[���������܂��� ***
    -- ====================================================
    WHEN UTL_FILE.WRITE_ERROR THEN
      IF UTL_FILE.IS_OPEN  ( lf_file_hand ) THEN
         UTL_FILE.FCLOSE   ( lf_file_hand );
-- T1_1224 2009/05/28 DEL START --
--       UTL_FILE.FREMOVE  ( gn_file_dir_enter , gn_file_name_enter);
-- T1_1224 2009/05/28 DEL END   --
      END IF;
      gn_normal_cnt := ln_target_cnt;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
      (
      cv_appl_short_name,   -- 'XXCFF'
      cv_msg_xxcff00171     -- �t�@�C���ɏ����݂ł��Ȃ�
      )
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
  END put_lease_data;
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )    
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
    -- *** ���[�J���ϐ� ***
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
    gn_warn_cnt   := 0;
    --
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --
    -- =====================================================
    --  A-1�D��������
    -- =====================================================
    gd_sysdateb := SYSDATE;
    -- =====================================================
    --  A-2�D���̓p�����[�^�l���O�o�͏���
    -- =====================================================
    init
    (
     lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
    ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  A-3�D�v���t�@�C���擾
    -- =====================================================
    get_profile_value
    (
     lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
    ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  A-4�D���[�X�Ǘ����f�[�^�t�@�C����񃍃O����
    -- =====================================================
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg
    (
     cv_appl_short_name     -- 'XXCFF'
    ,cv_msg_xxcff00168      -- �t�@�C�����o�̓��b�Z�[�W
    ,cv_tkn_file            -- �g�[�N��'FILE_NAME'
    ,gn_file_name_enter     -- �t�@�C����
    )
    ,1
    ,5000);
    --
    FND_FILE.PUT_LINE
    (
     FND_FILE.OUTPUT
    ,lv_errmsg
    );
    --�P�s���s
    FND_FILE.PUT_LINE
    (
     which  => FND_FILE.OUTPUT
    ,buff   => '' 
    );
    --
    -- =====================================================
    --  A-5. ���[�X�Ǘ����̎擾
    --  A-6. ���[�X�x���v����f�[�^�擾
    -- =====================================================
    get_lease_data
    (
     lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
    ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  A-7�D���[�X�Ǘ����f�[�^CSV�쐬����
    --  A-8�D�X�V����
    -- =====================================================
    put_lease_data
    (
     lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
    ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    END IF;
    --
    -- ���팏���̐ݒ�
    gn_normal_cnt := gn_target_cnt - gn_error_cnt;
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                OUT   VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode               OUT   VARCHAR2         --   �G���[�R�[�h     #�Œ�#
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���FXXCFF�̈�
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
    lv_errbuf          VARCHAR2(5000);                               -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);                                  -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);                               -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);                                -- ���b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header
    (
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
    submain
    (
     lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
    ,lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --�G���[�o��
    IF (lv_retcode IN( cv_status_error,cv_status_warn)) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --
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
END XXCFF009A15C;
/