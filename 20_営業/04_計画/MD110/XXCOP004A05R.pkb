CREATE OR REPLACE PACKAGE BODY XXCOP004A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A05R(body)
 * Description      : ����v�旧�ĕ\�o�̓��[�N�o�^
 * MD.050           : ����v�旧�ĕ\ MD050_COP_004_A05
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_header_data        �Ώۋ��_�E���[�w�b�_���擾(A-2,A-3)
 *  get_detail_data        ���[���׏��擾(A-4)
 *  qty_editing_data_keep  ���ʐU�����E�f�[�^�ێ�(A-5)
 *  reference_qty_calc     �����Q�l���ʌv�Z(A-6)
 *  insert_svf_work_tbl    ����v�旧�ĕ\���[���[�N�e�[�u���f�[�^�o�^(A-7)
 *  svf_call               SVF�N��(A-8) 
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/29    1.0  SCS.Kikuchi       �V�K�쐬
 *  2009/03/04    1.1  SCS.Kikuchi       SVF�����Ή�
 *  2009/04/28    1.2  SCS.Kikuchi       T1_0645,T1_0838�Ή�
 *  2009/06/10    1.3  SCS.Kikuchi       T1_1411�Ή�
 *  2009/06/23    1.4  SCS.Kikuchi       ��Q:0000025�Ή�
 *  2009/10/13    1.5  SCS.Fukada        ��Q:E_T3_00556�Ή�
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
--��1.1 2009/03/04 Add Start
  internal_process_expt        EXCEPTION;     -- ����PROCEDURE/FUNCTION�G���[�n���h�����O�p
--��1.1 2009/03/04 Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(100) := 'XXCOP004A05R';        -- �p�b�P�[�W��
  cv_target_month_format       CONSTANT VARCHAR2(6)   := 'YYYYMM';              -- �Ώ۔N������
  cv_customer_class_code_base  CONSTANT VARCHAR2(1)   := '1';                   -- �ڋq�敪�F���_
  cv_forecast_class            CONSTANT VARCHAR2(2)   := '01';                  -- �t�H�[�L���X�g���ށF����v��
  cv_prod_class_code_leaf      CONSTANT VARCHAR2(1)   := '1';                   -- ���i�敪�F���[�t
  cv_data_type_forecast        CONSTANT VARCHAR2(1)   := '1';                   -- �f�[�^��ʁF����v��
  cv_data_type_result          CONSTANT VARCHAR2(1)   := '2';                   -- �f�[�^��ʁF�o�׎���
  cv_dlv_invoice_class_1       CONSTANT VARCHAR2(1)   := '1';                   -- �[�i�`�[�敪:�[�i
  cv_dlv_invoice_class_3       CONSTANT VARCHAR2(1)   := '3';                   -- �[�i�`�[�敪:�[�i����
  cv_sales_class_1             CONSTANT VARCHAR2(1)   := '1';                   -- ����敪:�ʏ�
  cv_sales_class_5             CONSTANT VARCHAR2(1)   := '5';                   -- ����敪:���^
  cv_sales_class_6             CONSTANT VARCHAR2(1)   := '6';                   -- ����敪:���{
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_DEL_START
--  cv_cmn_organization_id       CONSTANT VARCHAR2(19)  := 'XXCMN_MASTER_ORG_ID'; -- �}�X�^�i�ڑg�D
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_DEL_END
  cv_inv_item_status_20        CONSTANT VARCHAR2(2)   := '20';                  -- �i�ڃX�e�[�^�X�F���o�^
  cv_inv_item_status_30        CONSTANT VARCHAR2(2)   := '30';                  -- �i�ڃX�e�[�^�X�F�{�o�^
  cv_inv_item_status_40        CONSTANT VARCHAR2(2)   := '40';                  -- �i�ڃX�e�[�^�X�F�p

--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_START
  cv_sales_org_code            CONSTANT VARCHAR2(30)  := 'XXCOP1_SALES_ORG_CODE'; -- �c�Ƒg�D
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_END

  -- ���̓p�����[�^���O�o�͗p
  cv_pm_prod_class_code_tl     CONSTANT VARCHAR2(100) := '���i�敪';
  cv_pm_base_code_tl           CONSTANT VARCHAR2(100) := '���_';
  cv_pm_part                   CONSTANT VARCHAR2(6)   := '�@�F�@';

  -- �G���[���b�Z�[�W
  cv_msg_application           CONSTANT VARCHAR2(100) := 'XXCOP';
  cv_profile_chk_msg           CONSTANT VARCHAR2(19)  := 'APP-XXCOP1-00002';    -- �v���t�@�C���擾�G���[�F�i�ڑg�D
  cv_profile_chk_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'PROF_NAME';
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_MOD_START
--  cv_profile_chk_msg_tkn_val1  CONSTANT VARCHAR2(100) := 'XXCMN:�}�X�^�g�D';
  cv_profile_chk_msg_tkn_val1  CONSTANT VARCHAR2(100) := 'XXCOP:�c�Ƒg�D';
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_MOD_END

--��1.1 2009/03/04 Add Start
  cv_others_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041'; -- CSV����߯ċ@�\�V�X�e���G���[���b�Z�[�W
  cv_others_err_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'ERRMSG';
  cv_api_err_msg              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00016'; -- API�N���G���[
  cv_api_err_msg_tkn_lbl1     CONSTANT VARCHAR2(100) := 'PRG_NAME';
  cv_api_err_msg_tkn_lbl1_val CONSTANT VARCHAR2(100) := 'XXCCP_SVFCOMMON_PKG.SUBMIT_SVF_REQUEST';
  cv_api_err_msg_tkn_lbl2     CONSTANT VARCHAR2(100) := 'ERR_MSG';

  -- SVF�o�͑Ή�
  cv_svf_date_format          CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS';     -- �p�����[�^�F�Ώ۔N������
  cv_file_name                CONSTANT VARCHAR2(40)  := 'XXCOP004A05R'
                                                        || TO_CHAR(SYSDATE,cv_svf_date_format)
                                                        || '.pdf';              -- �o�̓t�@�C����
  cv_output_mode              CONSTANT VARCHAR2(1)   := '1';                    -- �o�͋敪�F�h�P�h�i�o�c�e�j
  cv_frm_file                 CONSTANT VARCHAR2(20)  := 'XXCOP004A05S.xml';     -- �t�H�[���l���t�@�C����
  cv_vrq_file                 CONSTANT VARCHAR2(20)  := 'XXCOP004A05S.vrq';     -- �N�G���[�l���t�@�C����
--��1.1 2009/03/04 Add End
--

--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ����v�旧�ĕ\�w�b�_��񃌃R�[�h�^
  TYPE header_data_trec IS RECORD(
      base_code                   hz_cust_accounts.account_number                       %TYPE  -- �ڋq�R�[�h
    , base_short_name             xxcmn_parties.party_short_name                        %TYPE  -- ���_��
    , ope_days_last_month         xxcop_rep_forecast_planning.operation_days_last_month %TYPE  -- �O����������
    , ope_days_this_month         xxcop_rep_forecast_planning.operation_days_this_month %TYPE  -- �����ғ��\�����
    , ope_days_next_month         xxcop_rep_forecast_planning.operation_days_next_month %TYPE  -- �����ғ��\�����
    , ope_days_this_month_prevday xxcop_rep_forecast_planning.operation_days_this_month %TYPE  -- ������������
    );

  -- ����v�旧�ĕ\�w�b�_���PL/SQL�\
  TYPE header_data_ttype IS
    TABLE OF header_data_trec INDEX BY BINARY_INTEGER;

  -- ����v�旧�ĕ\���׏�񃌃R�[�h�^
  TYPE detail_data_trec IS RECORD(
      data_type           VARCHAR2(1)                                              -- �f�[�^��ʋ敪
    , detail_month        VARCHAR2(6)                                              -- ���הN��
    , prod_class_code     xxcop_rep_forecast_planning.prod_class_code  %TYPE       -- ���i�敪
    , prod_class_name     xxcop_rep_forecast_planning.prod_class_name  %TYPE       -- ���i�敪��
    , crowd_class_code    xxcop_rep_forecast_planning.crowd_class_code %TYPE       -- �Q�R�[�h
    , inventory_item_id   xxcop_item_categories1_v.inventory_item_id   %TYPE       -- INV�i��ID
    , organization_id     xxcop_item_categories1_v.organization_id     %TYPE       -- �g�DID
    , item_id             xxcop_item_categories1_v.item_id             %TYPE       -- OPM�i��ID
    , parent_item_id      xxcop_item_categories1_v.parent_item_id      %TYPE       -- OPM�e�i��ID
    , item_no             xxcop_rep_forecast_planning.item_no          %TYPE       -- ���i�R�[�h
    , item_short_name     xxcop_rep_forecast_planning.item_short_name  %TYPE       -- ���i��
    , quantity            NUMBER                                                   -- ����
    , num_of_cases        xxcop_item_categories1_v.num_of_cases        %TYPE       -- �P�[�X����
    , parent_item_no      xxcop_rep_forecast_planning.item_no          %TYPE       -- �e�i�ڃR�[�h
    );

  -- ����v�旧�ĕ\���׏��PL/SQL�\
  TYPE detail_data_ttype IS
    TABLE OF detail_data_trec INDEX BY BINARY_INTEGER;
    
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���̓p�����[�^�i�[�p
  gv_prod_class_code           VARCHAR2(1);
  gv_base_code                 VARCHAR2(4);

  -- ����������t�i�[�p
  gv_target_month              VARCHAR2(6);           -- �v��Ώ۔N��
  gd_target_date_st_day        DATE;                  -- �v��Ώ۔N������
  gd_target_date_ed_day        DATE;                  -- �v��Ώ۔N������
  gd_system_date               DATE;                  -- �V�X�e�����t
  gd_last_month_start_day      DATE;                  -- �O�������������o�J�n��
  gd_last_month_end_day        DATE;                  -- �O�������������o�I����
  gd_this_month_start_day      DATE;                  -- �����ғ��\��������o�J�n��
  gd_this_month_end_day        DATE;                  -- �����ғ��\��������o�I����
  gd_next_month_start_day      DATE;                  -- �����ғ��\��������o�J�n��
  gd_next_month_end_day        DATE;                  -- �����ғ��\��������o�I����
  gd_prev_day                  DATE;                  -- ���������������o�I�����i�V�X�e�����t�̑O���j
  gd_forecast_collect_st_day   DATE;                  -- ����v�撊�o�J�n���i�v��Ώ۔N���|�R�����̏����j
  gd_forecast_collect_ed_day   DATE;                  -- ����v�撊�o�I�����i�v��Ώ۔N���̖����j
  gd_result_collect_st_day1    DATE;                  -- �o�׎��ђ��o�J�n���i�v��Ώ۔N���|�P�N�R�����̏����j
  gd_result_collect_ed_day1    DATE;                  -- �o�׎��ђ��o�I�����i�v��Ώ۔N���|�P�P���������j
  gd_result_collect_st_day2    DATE;                  -- �o�׎��ђ��o�J�n���i�v��Ώ۔N���|�R�����̏����j
  gd_result_collect_ed_day2    DATE;                  -- �o�׎��ђ��o�I�����i�v��Ώ۔N���|�P�����̖����j
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_DEL_START
--  gn_mater_org_id              mtl_parameters.organization_id%type;
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_DEL_END
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_START
  gv_sales_org_code            mtl_parameters.organization_code%type;
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_END

  -- �o�͑Ώۃf�[�^�i�[�p
  g_header_data_tbl            header_data_ttype;                   -- ����v��`�F�b�N���X�g�o�͑Ώۋ��_
  g_header_data_tbl_init       header_data_ttype;                   -- ����v��`�F�b�N���X�g�o�͑Ώۋ��_�������p
  g_detail_data_tbl            detail_data_ttype;                   -- ����v��`�F�b�N���X�g�o�̓f�[�^
  g_detail_data_tbl_init       detail_data_ttype;                   -- ����v��`�F�b�N���X�g�o�̓f�[�^�������p
  g_forecast_planning_rec      xxcop_rep_forecast_planning%ROWTYPE; -- ����v�旧�ĕ\�o�̓��[�N�e�[�u��
  g_forecast_planning_rec_init xxcop_rep_forecast_planning%ROWTYPE; -- ����v�旧�ĕ\�o�̓��[�N�e�[�u���������p

  -- ����0�����b�Z�[�W�i�[�p
  gv_rep_no_data_msg           VARCHAR2(5000);

  -- �f�o�b�O�o�͔���p
  gv_debug_mode                VARCHAR2(30);
--
--
--
  /**********************************************************************************
   * Procedure Name   : num_edit
   * Description      : �L���͈͊O���Ή�
   ***********************************************************************************/
  FUNCTION num_edit(
     in_value             IN  NUMBER
  )RETURN VARCHAR2
  IS
  BEGIN
     -- �����Q���ȍ~�͐؂�̂�
     RETURN TRUNC(in_value,2);
  END num_edit;

  /**********************************************************************************
   * Procedure Name   : add_months_to_char
   * Description      : �w�茎����ADD_MONTHS���VARCHAR2�^�i�N���`���j�Ŗ߂�
   ***********************************************************************************/
  FUNCTION add_months_to_char(
     id_date              IN  DATE
   , in_value             IN  NUMBER
  )RETURN VARCHAR2
  IS
  BEGIN
     RETURN TO_CHAR(ADD_MONTHS(id_date,in_value),cv_target_month_format);
  END add_months_to_char;

  /**********************************************************************************
   * Procedure Name   : get_header_data
   * Description      : �Ώۋ��_�E���[�w�b�_���擾�iA-2,A-3�j
   ***********************************************************************************/
  PROCEDURE get_header_data(
     ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_header_data'; -- �v���O������
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
    ------------------------------------------------------------
    --  �Ǘ������_�{�z�����_���o
    ------------------------------------------------------------
    SELECT hca.account_number        account_number                -- �ڋq�R�[�h
    ,      xp.party_short_name       base_short_name               -- ���_��
    ,      ( SELECT  count(*)
             FROM    bom_calendar_dates bom
             WHERE   calendar_code = mp.calendar_code
             AND     exception_set_id = mp.calendar_exception_set_id
             AND     calendar_date BETWEEN gd_last_month_start_day AND gd_last_month_end_day
             AND     seq_num is not null
           ) ope_days_last_month                                   -- �O����������
    ,      ( SELECT  count(*)
             FROM    bom_calendar_dates bom
             WHERE   calendar_code = mp.calendar_code
             AND     exception_set_id = mp.calendar_exception_set_id
             AND     calendar_date BETWEEN gd_this_month_start_day AND gd_this_month_end_day
             AND     seq_num is not null
           ) ope_days_this_month                                   -- �����ғ��\�����
    ,      ( SELECT  count(*)
             FROM    bom_calendar_dates bom
             WHERE   calendar_code = mp.calendar_code
             AND     exception_set_id = mp.calendar_exception_set_id
             AND     calendar_date BETWEEN gd_next_month_start_day AND gd_next_month_end_day
             AND     seq_num is not null
           ) ope_days_next_month                                   -- �����ғ��\�����
    ,      ( SELECT  count(*)
             FROM    bom_calendar_dates bom
             WHERE   calendar_code = mp.calendar_code
             AND     exception_set_id = mp.calendar_exception_set_id
             AND     calendar_date BETWEEN gd_this_month_start_day AND gd_prev_day
             AND     seq_num is not null
           ) ope_days_this_month_prevday                           -- ������������
    BULK COLLECT
    INTO   g_header_data_tbl
    FROM   hz_cust_accounts         hca            -- �ڋq�}�X�^
    ,      xxcmn_parties            xp             -- �p�[�e�B�A�h�I���}�X�^
    ,      mtl_parameters           mp             -- �g�D�p�����[�^
    WHERE  hca.customer_class_code =  cv_customer_class_code_base
    AND (  hca.account_number      =  gv_base_code
        OR hca.cust_account_id     IN ( SELECT customer_id
                                        FROM   xxcmm_cust_accounts                      -- �ڋq�ǉ����
                                        WHERE  management_base_code = gv_base_code      -- �Ǘ������_�R�[�h
                                      )
        )
    AND    xp.party_id         (+) =  hca.party_id
    AND    xp.start_date_active(+) <= gd_system_date
    AND    xp.end_date_active  (+) >= gd_system_date
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_MOD_START
--    AND    mp.organization_id      =  gn_mater_org_id
    AND    mp.organization_code    =  gv_sales_org_code
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_MOD_END
    ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--���������ł͎g�p���Ȃ���������������������������������������������
--��    -- *** ���ʊ֐���O�n���h�� ***
--��    WHEN global_api_expt THEN
--��      ov_errmsg  := lv_errmsg;
--��      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--��      ov_retcode := cv_status_error;
--��    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--��    WHEN global_api_others_expt THEN
--��      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--��      ov_retcode := cv_status_error;
--������������������������������������������������������������������
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_header_data;
--
  /**********************************************************************************
   * Procedure Name   : get_detail_data
   * Description      : ���[���׏��擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_detail_data(
     in_header_index      IN  NUMBER      -- �w�b�_��񃌃R�[�hINDEX
   , ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_detail_data'; -- �v���O������
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
    ------------------------------------------------------------
    --  ���[�o�͖��׏��擾
    ------------------------------------------------------------
    SELECT data_type              data_type            -- �f�[�^��ʋ敪
    ,      detail_month           detail_month         -- ���הN��
    ,      prod_class_code        prod_class_code      -- ���i�敪
    ,      prod_class_name        prod_class_name      -- ���i�敪��
    ,      crowd_class_code       crowd_class_code     -- �Q�R�[�h
    ,      inventory_item_id      inventory_item_id    -- INV�i��ID
    ,      organization_id        organization_id      -- �g�DID
    ,      item_id                item_id              -- OPM�i��ID
    ,      parent_item_id         parent_item_id       -- OPM�e�i��ID
    ,      item_no                item_no              -- ���i�R�[�h
    ,      item_short_name        item_short_name      -- ���i��
    ,      quantity               quantity             -- ����
    ,      num_of_cases           num_of_cases         -- �P�[�X����
    ,      parent_item_no         parent_item_no       -- �e�i�ڃR�[�h
    BULK COLLECT
    INTO   g_detail_data_tbl
    FROM
    ( SELECT cv_data_type_forecast                          data_type                -- �f�[�^��ʋ敪
      ,      TO_CHAR(forecast_date,cv_target_month_format)  detail_month             -- ���הN��
      ,      xic1v.prod_class_code                          prod_class_code          -- ���i�敪
      ,      xic1v.prod_class_name                          prod_class_name          -- ���i�敪��
      ,      SUBSTRB(xic1v.crowd_class_code,1,3)            crowd_class_code         -- �Q�R�[�h
      ,      xic1v.inventory_item_id                        inventory_item_id        -- INV�i��ID
      ,      xic1v.organization_id                          organization_id          -- �g�DID
      ,      xic1v.item_id                                  item_id                  -- OPM�i��ID
      ,      xic1v.parent_item_id                           parent_item_id           -- OPM�e�i��ID
      ,      xic1v.item_no                                  item_no                  -- ���i�R�[�h
      ,      xic1v.item_short_name                          item_short_name          -- ���i��
      ,      SUM(mfda.original_forecast_quantity)           quantity                 -- ����
      ,      xic1v.num_of_cases                             num_of_cases             -- �P�[�X����
      ,      xic1v.parent_item_no                           parent_item_no           -- �e�i�ڃR�[�h
      FROM
             mrp_forecast_designators mfde                           -- �t�H�[�L���X�g��
      ,      mrp_forecast_dates       mfda                           -- �t�H�[�L���X�g���t
      ,      xxcop_item_categories1_v xic1v                          -- �v��_�i�ڃJ�e�S���r���[1
      ,      xxcmm_system_items_b     xsib                           -- Disc�i�ڃA�h�I��
      WHERE
             mfde.forecast_designator   =  mfda.forecast_designator
      AND    mfde.organization_id       =  mfda.organization_id
      AND    mfde.attribute1            =  cv_forecast_class         -- FORECAST���ށF����v��
      AND    mfde.attribute3            =  g_header_data_tbl(in_header_index).base_code
      AND    mfda.forecast_date         BETWEEN gd_forecast_collect_st_day
                                        AND     gd_forecast_collect_ed_day
      AND    xic1v.inventory_item_id    =  mfda.inventory_item_id
      AND    xic1v.start_date_active    <= gd_system_date
      AND    xic1v.end_date_active      >= gd_system_date
      AND    xic1v.prod_class_code      =  gv_prod_class_code
      AND    xic1v.item_id              =  xsib.item_id
      AND    xsib.item_status           IN ( cv_inv_item_status_20
                                           , cv_inv_item_status_30
                                           , cv_inv_item_status_40 ) -- �i�ڃX�e�[�^�X
      AND    NVL( xsib.item_status_apply_date, gd_system_date )
                                        <= gd_system_date            -- �i�ڃX�e�[�^�X�K�p��
      GROUP
      BY     TO_CHAR(forecast_date,cv_target_month_format)           -- ���הN��
      ,      xic1v.prod_class_code                                   -- ���i�敪
      ,      xic1v.prod_class_name                                   -- ���i�敪��
      ,      SUBSTRB(xic1v.crowd_class_code,1,3)                     -- �Q�R�[�h
      ,      xic1v.inventory_item_id                                 -- INV�i��ID
      ,      xic1v.organization_id                                   -- �g�DID
      ,      xic1v.item_id                                           -- OPM�i��ID
      ,      xic1v.parent_item_id                                    -- OPM�e�i��ID
      ,      xic1v.item_no                                           -- ���i�R�[�h
      ,      xic1v.item_short_name                                   -- ���i��
      ,      xic1v.num_of_cases                                      -- �P�[�X����
      ,      xic1v.parent_item_no                                    -- �e�i�ڃR�[�h
      UNION ALL
      SELECT cv_data_type_result                            data_type                -- �f�[�^��ʋ敪
--20090623_Ver1.4_0000025_SCS.Kikuchi_MOD_START
--      ,      TO_CHAR(shipment_date,cv_target_month_format)  detail_month             -- ���הN��
      ,      TO_CHAR(xsrst.shipment_date,cv_target_month_format)  detail_month             -- ���הN��
--20090623_Ver1.4_0000025_SCS.Kikuchi_MOD_END
      ,      xic1v.prod_class_code                          prod_class_code          -- ���i�敪
      ,      xic1v.prod_class_name                          prod_class_name          -- ���i�敪��
      ,      SUBSTRB(xic1v.crowd_class_code,1,3)            crowd_class_code         -- �Q�R�[�h
      ,      xic1v.inventory_item_id                        inventory_item_id        -- INV�i��ID
      ,      xic1v.organization_id                          organization_id          -- �g�DID
      ,      xic1v.item_id                                  item_id                  -- OPM�i��ID
      ,      xic1v.parent_item_id                           parent_item_id           -- OPM�e�i��ID
      ,      xic1v.item_no                                  item_no                  -- ���i�R�[�h
      ,      xic1v.item_short_name                          item_short_name          -- ���i��
      ,      SUM(xsrst.quantity)                            quantity                 -- ����
      ,      xic1v.num_of_cases                             num_of_cases             -- �P�[�X����
      ,      xic1v.parent_item_no                           parent_item_no           -- �e�i�ڃR�[�h
      FROM
--20090623_Ver1.4_0000025_SCS.Kikuchi_MOD_START
           ( SELECT xsr1.shipment_date
             ,      xsr1.item_no
             ,      xsr1.quantity
             FROM   xxcop_shipment_results   xsr1
             WHERE  xsr1.shipment_date  BETWEEN gd_result_collect_st_day1
                                          AND     gd_result_collect_ed_day1
             AND    xsr1.base_code      =       g_header_data_tbl(in_header_index).base_code
--20091013_Ver1.5_E_T3_00556_SCS.Fukada_MOD_START
--             UNION
             UNION ALL
--20091013_Ver1.5_E_T3_00556_SCS.Fukada_MOD_END
             SELECT xsr2.shipment_date
             ,      xsr2.item_no
             ,      xsr2.quantity
             FROM   xxcop_shipment_results   xsr2
             WHERE  xsr2.shipment_date  BETWEEN gd_result_collect_st_day2
                                          AND     gd_result_collect_ed_day2
             AND    xsr2.base_code      =       g_header_data_tbl(in_header_index).base_code
             )xsrst                                                  -- �e�R�[�h�o�׎��ѕ\
--             xxcop_shipment_results   xsrst                          -- �e�R�[�h�o�׎��ѕ\
--20090623_Ver1.4_0000025_SCS.Kikuchi_MOD_END
      ,      xxcop_item_categories1_v xic1v                          -- �v��_�i�ڃJ�e�S���r���[1
      ,      xxcmm_system_items_b     xsib                           -- Disc�i�ڃA�h�I��
      WHERE
--20090623_Ver1.4_0000025_SCS.Kikuchi_MOD_START
--             xsrst.base_code            =       g_header_data_tbl(in_header_index).base_code
--      AND    (   xsrst.shipment_date    BETWEEN gd_result_collect_st_day1
--                                        AND     gd_result_collect_ed_day1
--             OR  xsrst.shipment_date    BETWEEN gd_result_collect_st_day2
--                                        AND     gd_result_collect_ed_day2
--             )
--      AND    xic1v.item_no              =       xsrst.item_no
             xic1v.item_no              =       xsrst.item_no
--20090623_Ver1.4_0000025_SCS.Kikuchi_MOD_END
      AND    xic1v.start_date_active    <=      gd_system_date
      AND    xic1v.end_date_active      >=      gd_system_date
      AND    xic1v.prod_class_code      =       gv_prod_class_code
      AND    xic1v.item_id              =       xsib.item_id
      AND    xsib.item_status           IN ( cv_inv_item_status_20
                                           , cv_inv_item_status_30
                                           , cv_inv_item_status_40 ) -- �i�ڃX�e�[�^�X
      AND    NVL( xsib.item_status_apply_date, gd_system_date )
                                        <= gd_system_date            -- �i�ڃX�e�[�^�X�K�p��
      GROUP
      BY     TO_CHAR(shipment_date,cv_target_month_format)           -- ���הN��
      ,      xic1v.prod_class_code                                   -- ���i�敪
      ,      xic1v.prod_class_name                                   -- ���i�敪��
      ,      SUBSTRB(xic1v.crowd_class_code,1,3)                     -- �Q�R�[�h
      ,      xic1v.inventory_item_id                                 -- INV�i��ID
      ,      xic1v.organization_id                                   -- �g�DID
      ,      xic1v.item_id                                           -- OPM�i��ID
      ,      xic1v.parent_item_id                                    -- OPM�e�i��ID
      ,      xic1v.item_no                                           -- ���i�R�[�h
      ,      xic1v.item_short_name                                   -- ���i��
      ,      xic1v.num_of_cases                                      -- �P�[�X����
      ,      xic1v.parent_item_no                                    -- �e�i�ڃR�[�h
    )
    ORDER
    BY     item_no                 -- ���i�R�[�h
    ,      data_type               -- �f�[�^��ʋ敪
    ,      detail_month            -- ���הN��
    ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--���������ł͎g�p���Ȃ���������������������������������������������
--��    -- *** ���ʊ֐���O�n���h�� ***
--��    WHEN global_api_expt THEN
--��      ov_errmsg  := lv_errmsg;
--��      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--��      ov_retcode := cv_status_error;
--��    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--��    WHEN global_api_others_expt THEN
--��      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--��      ov_retcode := cv_status_error;
--������������������������������������������������������������������
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_detail_data;
--
  /**********************************************************************************
   * Procedure Name   : qty_editing_data_keep
   * Description      : ���ʐU�����E�f�[�^�ێ�(A-5)
   ***********************************************************************************/
  PROCEDURE qty_editing_data_keep(
     in_header_index      IN  NUMBER      -- 1.�w�b�_��񃌃R�[�hINDEX
   , in_detail_index      IN  NUMBER      -- 2.���׏�񃌃R�[�hINDEX
   , ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'qty_editing_data_keep'; -- �v���O������
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
    ld_target_date    DATE;
    ln_case_quantity  NUMBER;
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
    -- �Ώ۔N������t�^�ɕϊ�����
    ld_target_date   := TO_DATE(gv_target_month,cv_target_month_format);


    -- ����v�搔�ʂ��P�[�X���Z����
    ln_case_quantity := num_edit(g_detail_data_tbl(in_detail_index).quantity
                              / NVL(g_detail_data_tbl(in_detail_index).num_of_cases,1));

    -- ���הN�����P�N�R�����O�̏ꍇ
    IF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-15)) THEN
      g_forecast_planning_rec.ship_to_quantity_15_months_ago := ln_case_quantity;

    -- ���הN�����P�N�Q�����O�̏ꍇ
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-14)) THEN
      g_forecast_planning_rec.ship_to_quantity_14_months_ago := ln_case_quantity;

    -- ���הN�����P�N�P�����O�̏ꍇ
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-13)) THEN
      g_forecast_planning_rec.ship_to_quantity_13_months_ago := ln_case_quantity;

    -- ���הN�����P�N�O�̏ꍇ
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-12)) THEN
      g_forecast_planning_rec.ship_to_quantity_12_months_ago := ln_case_quantity;

    -- ���הN�����P�P�����O�̏ꍇ
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-11)) THEN
      g_forecast_planning_rec.ship_to_quantity_11_months_ago := ln_case_quantity;

    -- ���הN�����R�����O�̏ꍇ
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-3)) THEN
    
      IF (g_detail_data_tbl(in_detail_index).data_type = cv_data_type_forecast) THEN
        g_forecast_planning_rec.forecast_quantity_3_months_ago := ln_case_quantity;
      ELSE
        g_forecast_planning_rec.ship_to_quantity_3_months_ago  := ln_case_quantity;
      END IF;

    -- ���הN�����Q�����O�̏ꍇ
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-2)) THEN

      IF (g_detail_data_tbl(in_detail_index).data_type = cv_data_type_forecast) THEN
        g_forecast_planning_rec.forecast_quantity_2_months_ago := ln_case_quantity;
      ELSE
        g_forecast_planning_rec.ship_to_quantity_2_months_ago  := ln_case_quantity;
      END IF;

    -- ���הN�����P�����O�̏ꍇ
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,-1)) THEN

      IF (g_detail_data_tbl(in_detail_index).data_type = cv_data_type_forecast) THEN
        g_forecast_planning_rec.forecast_quantity_1_months_ago := ln_case_quantity;
      ELSE
        g_forecast_planning_rec.ship_to_quantity_1_months_ago  := ln_case_quantity;
      END IF;

    -- ���הN�����v��Ώ۔N���̏ꍇ
    ELSIF (g_detail_data_tbl(in_detail_index).detail_month = add_months_to_char(ld_target_date,0)) THEN
      g_forecast_planning_rec.forecast_quantity := ln_case_quantity;

    END IF;

    -- �W�v�L�[�ێ�
    g_forecast_planning_rec.prod_class_code  := g_detail_data_tbl(in_detail_index).prod_class_code;  -- ���i�敪
    g_forecast_planning_rec.prod_class_name  := g_detail_data_tbl(in_detail_index).prod_class_name;  -- ���i�敪��
    g_forecast_planning_rec.crowd_class_code := g_detail_data_tbl(in_detail_index).crowd_class_code; -- �Q�R�[�h
    g_forecast_planning_rec.item_no          := g_detail_data_tbl(in_detail_index).item_no;          -- ���i�R�[�h
    g_forecast_planning_rec.item_short_name  := g_detail_data_tbl(in_detail_index).item_short_name;  -- ���i��
    g_forecast_planning_rec.parent_item_no   := g_detail_data_tbl(in_detail_index).parent_item_no;   -- �e�i�ڃR�[�h
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
--���������ł͎g�p���Ȃ���������������������������������������������
--��    -- *** ���ʊ֐���O�n���h�� ***
--��    WHEN global_api_expt THEN
--��      ov_errmsg  := lv_errmsg;
--��      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--��      ov_retcode := cv_status_error;
--��    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--��    WHEN global_api_others_expt THEN
--��      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--��      ov_retcode := cv_status_error;
--������������������������������������������������������������������
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END qty_editing_data_keep;
  /**********************************************************************************
   * Procedure Name   : insert_check_list
   * Description      : �����Q�l���ʌv�Z(A-6)
   ***********************************************************************************/
  PROCEDURE reference_qty_calc(
     in_header_index      IN  NUMBER      -- 1.�w�b�_��񃌃R�[�hINDEX
   , in_detail_index      IN  NUMBER      -- 2.���׏�񃌃R�[�hINDEX
   , ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reference_qty_calc'; -- �v���O������
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
    ln_book_inventory_quantity   NUMBER;
    ln_standard_qty              NUMBER;
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
    ---------------------------------------------------------------------------
    -- �o�^���ݒ�
    ---------------------------------------------------------------------------
    -- ���[�w�b�_���
    g_forecast_planning_rec.base_code                 := g_header_data_tbl(in_header_index).base_code;
    g_forecast_planning_rec.base_short_name           := g_header_data_tbl(in_header_index).base_short_name;
    g_forecast_planning_rec.target_month              := gv_target_month;
    g_forecast_planning_rec.operation_days_last_month := g_header_data_tbl(in_header_index).ope_days_last_month;
--    g_forecast_planning_rec.operation_days_this_month := g_header_data_tbl(in_header_index).ope_days_this_month;
    g_forecast_planning_rec.operation_days_this_month := g_header_data_tbl(in_header_index).ope_days_this_month_prevday;
    g_forecast_planning_rec.operation_days_next_month := g_header_data_tbl(in_header_index).ope_days_next_month;

    -- �e���ʂ�NULL��0�ɒu������
    g_forecast_planning_rec.ship_to_quantity_15_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_15_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_14_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_14_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_13_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_13_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_12_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_12_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_11_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_11_months_ago,0);
    g_forecast_planning_rec.forecast_quantity_3_months_ago
                                     := NVL(g_forecast_planning_rec.forecast_quantity_3_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_3_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_3_months_ago ,0);
    g_forecast_planning_rec.forecast_quantity_2_months_ago
                                     := NVL(g_forecast_planning_rec.forecast_quantity_2_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_2_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_2_months_ago ,0);
    g_forecast_planning_rec.forecast_quantity_1_months_ago
                                     := NVL(g_forecast_planning_rec.forecast_quantity_1_months_ago,0);
    g_forecast_planning_rec.ship_to_quantity_1_months_ago
                                     := NVL(g_forecast_planning_rec.ship_to_quantity_1_months_ago ,0);
    g_forecast_planning_rec.forecast_quantity
                                     := NVL(g_forecast_planning_rec.forecast_quantity             ,0);


    -- �e�i�ڂŖ����ꍇ�iOPM�i��ID��OPM�e�i��ID���قȂ�j�A�����Q�l���͐ݒ肵�Ȃ��B
    IF (g_detail_data_tbl(in_detail_index).item_id<>g_detail_data_tbl(in_detail_index).parent_item_id) THEN
       g_forecast_planning_rec.present_stock_quantity      := NULL;
       g_forecast_planning_rec.delivery_forecast_quantity  := NULL;
       g_forecast_planning_rec.ship_to_quantity_forecast   := NULL;
--       g_forecast_planning_rec.forecast_remainder_quantity := NULL;
       -- ����v��c����
       g_forecast_planning_rec.forecast_remainder_quantity := 
             num_edit(g_forecast_planning_rec.forecast_quantity_1_months_ago
                      - g_forecast_planning_rec.ship_to_quantity_1_months_ago
             );
       g_forecast_planning_rec.stock_forecast_quantity     := NULL;
       RETURN;
    END IF;

    -----------------------------------------------------------------
    -- �����݌Ɏ󕥕\�i�����j�f�[�^�擾
    -----------------------------------------------------------------
    SELECT NVL(SUM(book_inventory_quantity),0) book_inventory_quantity
    INTO   ln_book_inventory_quantity
    FROM   xxcoi_inv_reception_daily                     -- �����݌Ɏ󕥕\�i�����j
    WHERE  (base_code,organization_id,practice_date,subinventory_code,inventory_item_id) IN
             ( SELECT base_code
                    , organization_id
                    , MAX(practice_date)
                    , subinventory_code
                    , inventory_item_id
               FROM   xxcoi_inv_reception_daily          -- �����݌Ɏ󕥕\�i�����j
               WHERE  base_code         = g_header_data_tbl(in_header_index).base_code
               AND    inventory_item_id = g_detail_data_tbl(in_detail_index).inventory_item_id
--20090428_Ver1.2_T1_0838_SCS.Kikuchi_MOD_START
--               AND    practice_date     BETWEEN gd_this_month_start_day
--                                        AND     gd_prev_day
               AND    practice_date     <= gd_prev_day
--20090428_Ver1.2_T1_0838_SCS.Kikuchi_MOD_END
               GROUP
               BY     base_code
                    , organization_id
                    , subinventory_code
                    , inventory_item_id
             )
    ;

    -----------------------------------------------------------------
    -- �̔����уf�[�^�擾
    -----------------------------------------------------------------
    SELECT NVL(SUM(standard_qty),0) standard_qty
    INTO   ln_standard_qty
    FROM   xxcos_sales_exp_headers xseh           -- �̔����уw�b�_
    ,      xxcos_sales_exp_lines   xsel           -- �̔����і���
    WHERE  xseh.sales_exp_header_id =  xsel.sales_exp_header_id
    AND    xsel.item_code           =  g_detail_data_tbl(in_detail_index).item_no
    AND    xsel.delivery_base_code  =  g_header_data_tbl(in_header_index).base_code
    AND    xseh.dlv_invoice_class   IN (cv_dlv_invoice_class_1,cv_dlv_invoice_class_3)         -- �[�i�`�[�敪
    AND    xsel.sales_class         IN (cv_sales_class_1,cv_sales_class_5,cv_sales_class_6)    -- ����敪
    AND    xseh.delivery_date       BETWEEN gd_this_month_start_day
                                    AND     gd_prev_day
    ;
    -----------------------------------------------------------------
    -- �����݌ɁA�̔����т��P�[�X���Z����
    -----------------------------------------------------------------
    ln_book_inventory_quantity := ln_book_inventory_quantity / NVL(g_detail_data_tbl(in_detail_index).num_of_cases,1);
    ln_standard_qty            := ln_standard_qty / NVL(g_detail_data_tbl(in_detail_index).num_of_cases,1);

    -----------------------------------------------------------------
    -- �����Q�l���ʎZ�o
    -----------------------------------------------------------------
    -- ���݌ɐ���
    g_forecast_planning_rec.present_stock_quantity      := num_edit(ln_book_inventory_quantity);

    -- ����o�ɗ\������
    IF ( g_header_data_tbl(in_header_index).ope_days_this_month_prevday = 0 ) THEN
      g_forecast_planning_rec.delivery_forecast_quantity  := 0;
    ELSE
      g_forecast_planning_rec.delivery_forecast_quantity  := 
            num_edit( ( ln_standard_qty / g_header_data_tbl(in_header_index).ope_days_this_month_prevday )
                   *  ( g_header_data_tbl(in_header_index).ope_days_this_month
--20090610_Ver1.3_T1_1411_SCS.Kikuchi_MOD_START
                      - g_header_data_tbl(in_header_index).ope_days_this_month_prevday )
--                      - g_header_data_tbl(in_header_index).ope_days_this_month_prevday + 1 )
--20090610_Ver1.3_T1_1411_SCS.Kikuchi_MOD_END
              );
    END IF;

    -- ���N�x �Ώی��\������
    IF (  ( g_forecast_planning_rec.ship_to_quantity_12_months_ago = 0 )
       OR ( g_forecast_planning_rec.ship_to_quantity_13_months_ago = 0 )
       )
    THEN
      g_forecast_planning_rec.ship_to_quantity_forecast   := 0;
    ELSE
      g_forecast_planning_rec.ship_to_quantity_forecast   := 
            num_edit( ( g_forecast_planning_rec.ship_to_quantity_12_months_ago
              / g_forecast_planning_rec.ship_to_quantity_13_months_ago )
              *  ( ln_standard_qty + g_forecast_planning_rec.delivery_forecast_quantity )
              );
    END IF;

    -- ����v��c����
    g_forecast_planning_rec.forecast_remainder_quantity := 
          num_edit(g_forecast_planning_rec.forecast_quantity_1_months_ago
                   - g_forecast_planning_rec.ship_to_quantity_1_months_ago
          );

    -- �����݌ɗ\������
    g_forecast_planning_rec.stock_forecast_quantity     :=
          num_edit( ln_book_inventory_quantity - g_forecast_planning_rec.delivery_forecast_quantity
                    + g_forecast_planning_rec.forecast_remainder_quantity
          );

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
--���������ł͎g�p���Ȃ���������������������������������������������
--��    -- *** ���ʊ֐���O�n���h�� ***
--��    WHEN global_api_expt THEN
--��      ov_errmsg  := lv_errmsg;
--��      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--��      ov_retcode := cv_status_error;
--��    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--��    WHEN global_api_others_expt THEN
--��      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--��      ov_retcode := cv_status_error;
--������������������������������������������������������������������
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END reference_qty_calc;
--
  /**********************************************************************************
   * Procedure Name   : insert_check_list
   * Description      : ����v�旧�ĕ\���[���[�N�e�[�u���f�[�^�o�^(A-7)
   ***********************************************************************************/
  PROCEDURE insert_svf_work_tbl(
     ov_errbuf   OUT VARCHAR2            --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode  OUT VARCHAR2            --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg   OUT VARCHAR2            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_svf_work_tbl'; -- �v���O������
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

    -----------------------------------------------------------------
    -- ����v�旧�ĕ\���[���[�N�e�[�u���f�[�^�o�^����
    -----------------------------------------------------------------
    INSERT INTO xxcop_rep_forecast_planning
      ( target_month                                                 -- ���đΏ۔N��
      , prod_class_code                                              -- ���i�敪
      , prod_class_name                                              -- ���i�敪��
      , base_code                                                    -- ���_�R�[�h
      , base_short_name                                              -- ���_��
      , operation_days_last_month                                    -- �O���ғ����ѓ���
      , operation_days_this_month                                    -- �����ғ����ѓ���
      , operation_days_next_month                                    -- �����ғ��\�����
      , crowd_class_code                                             -- �Q�R�[�h�i��R���j
      , item_no                                                      -- ���i�R�[�h
      , item_short_name                                              -- ���i��
      , ship_to_quantity_15_months_ago                               -- �O�N�x �ΏۂR�����O���ѐ���
      , ship_to_quantity_14_months_ago                               -- �O�N�x �ΏۑO�X�����ѐ���
      , ship_to_quantity_13_months_ago                               -- �O�N�x �ΏۑO�����ѐ���
      , ship_to_quantity_12_months_ago                               -- �O�N�x �Ώی����ѐ���
      , ship_to_quantity_11_months_ago                               -- �O�N�x �Ώۗ������ѐ���
      , ship_to_quantity_3_months_ago                                -- ���N�x �ΏۂR�����O���ѐ���
      , ship_to_quantity_2_months_ago                                -- ���N�x �ΏۑO�X�����ѐ���
      , ship_to_quantity_1_months_ago                                -- ���N�x �ΏۑO�����ѐ���
      , ship_to_quantity_forecast                                    -- ���N�x �Ώی��\������
      , forecast_quantity_3_months_ago                               -- ���N�x �ΏۂR�����O�v�搔��
      , forecast_quantity_2_months_ago                               -- ���N�x �ΏۑO�X���v�搔��
      , forecast_quantity_1_months_ago                               -- ���N�x �ΏۑO���v�搔��
      , forecast_quantity                                            -- ���N�x �Ώی��v�搔��
      , present_stock_quantity                                       -- ���݌ɐ���
      , forecast_remainder_quantity                                  -- ����v��c����
      , delivery_forecast_quantity                                   -- ����o�ɗ\������
      , stock_forecast_quantity                                      -- �����݌ɗ\������
      , parent_item_no                                               -- �e�i�ڃR�[�h
      , created_by                                                   -- �쐬��
      , creation_date                                                -- �쐬��
      , last_updated_by                                              -- �ŏI�X�V��
      , last_update_date                                             -- �ŏI�X�V��
      , last_update_login                                            -- �ŏI�X�V���O�C��
      , request_id                                                   -- �v��ID
      , program_application_id                                       -- �v���O�����A�v���P�[�V����ID
      , program_id                                                   -- �v���O����ID
      , program_update_date                                          -- �v���O�����X�V��
      )
    VALUES
      ( g_forecast_planning_rec.target_month                         -- ���đΏ۔N��
      , g_forecast_planning_rec.prod_class_code                      -- ���i�敪
      , g_forecast_planning_rec.prod_class_name                      -- ���i�敪��
      , g_forecast_planning_rec.base_code                            -- ���_�R�[�h
      , g_forecast_planning_rec.base_short_name                      -- ���_��
      , g_forecast_planning_rec.operation_days_last_month            -- �O���ғ����ѓ���
      , g_forecast_planning_rec.operation_days_this_month            -- �����ғ����ѓ���
      , g_forecast_planning_rec.operation_days_next_month            -- �����ғ��\�����
      , g_forecast_planning_rec.crowd_class_code                     -- �Q�R�[�h�i��R���j
      , g_forecast_planning_rec.item_no                              -- ���i�R�[�h
      , g_forecast_planning_rec.item_short_name                      -- ���i��
      , g_forecast_planning_rec.ship_to_quantity_15_months_ago       -- �O�N�x �ΏۂR�����O���ѐ���
      , g_forecast_planning_rec.ship_to_quantity_14_months_ago       -- �O�N�x �ΏۑO�X�����ѐ���
      , g_forecast_planning_rec.ship_to_quantity_13_months_ago       -- �O�N�x �ΏۑO�����ѐ���
      , g_forecast_planning_rec.ship_to_quantity_12_months_ago       -- �O�N�x �Ώی����ѐ���
      , g_forecast_planning_rec.ship_to_quantity_11_months_ago       -- �O�N�x �Ώۗ������ѐ���
      , g_forecast_planning_rec.ship_to_quantity_3_months_ago        -- ���N�x �ΏۂR�����O���ѐ���
      , g_forecast_planning_rec.ship_to_quantity_2_months_ago        -- ���N�x �ΏۑO�X�����ѐ���
      , g_forecast_planning_rec.ship_to_quantity_1_months_ago        -- ���N�x �ΏۑO�����ѐ���
      , g_forecast_planning_rec.ship_to_quantity_forecast            -- ���N�x �Ώی��\������
      , g_forecast_planning_rec.forecast_quantity_3_months_ago       -- ���N�x �ΏۂR�����O�v�搔��
      , g_forecast_planning_rec.forecast_quantity_2_months_ago       -- ���N�x �ΏۑO�X���v�搔��
      , g_forecast_planning_rec.forecast_quantity_1_months_ago       -- ���N�x �ΏۑO���v�搔��
      , g_forecast_planning_rec.forecast_quantity                    -- ���N�x �Ώی��v�搔��
      , g_forecast_planning_rec.present_stock_quantity               -- ���݌ɐ���
      , g_forecast_planning_rec.forecast_remainder_quantity          -- ����v��c����
      , g_forecast_planning_rec.delivery_forecast_quantity           -- ����o�ɗ\������
      , g_forecast_planning_rec.stock_forecast_quantity              -- �����݌ɗ\������
      , g_forecast_planning_rec.parent_item_no                       -- �e�i�ڃR�[�h
      , cn_created_by                                                -- �쐬��
      , cd_creation_date                                             -- �쐬��
      , cn_last_updated_by                                           -- �ŏI�X�V��
      , cd_last_update_date                                          -- �ŏI�X�V��
      , cn_last_update_login                                         -- �ŏI�X�V���O�C��
      , cn_request_id                                                -- �v��ID
      , cn_program_application_id                                    -- �v���O�����A�v���P�[�V����ID
      , cn_program_id                                                -- �v���O����ID
      , cd_program_update_date                                       -- �v���O�����X�V��
      );

      -- ���팏���J�E���g�A�b�v
      gn_normal_cnt := gn_normal_cnt + 1;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
--���������ł͎g�p���Ȃ���������������������������������������������
--��    -- *** ���ʊ֐���O�n���h�� ***
--��    WHEN global_api_expt THEN
--��      ov_errmsg  := lv_errmsg;
--��      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--��      ov_retcode := cv_status_error;
--��    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--��    WHEN global_api_others_expt THEN
--��      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--��      ov_retcode := cv_status_error;
--������������������������������������������������������������������
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_svf_work_tbl;
--
--��1.1 2009/03/04 Add Start
  /**********************************************************************************
   * Procedure Name   : svf_call
   * Description      : SVF�N��(A-8)
   ***********************************************************************************/
  PROCEDURE svf_call(
     ov_errbuf   OUT VARCHAR2            --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode  OUT VARCHAR2            --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg   OUT VARCHAR2            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'svf_call'; -- �v���O������
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
    -- �Ώی������[�����̏ꍇ�A
    -- SVF���[���ʊ֐�(0���o�̓��b�Z�[�W)
    IF (gn_normal_cnt = 0) THEN
      gv_rep_no_data_msg := xxccp_svfcommon_pkg.no_data_msg;
    END IF;

    BEGIN
      -- SVF���[���ʊ֐�(SVF�R���J�����g�̋N���j
      xxccp_svfcommon_pkg.submit_svf_request(
            ov_retcode      =>  lv_retcode                  -- ���^�[���R�[�h
          , ov_errbuf       =>  lv_errbuf                   -- �G���[���b�Z�[�W
          , ov_errmsg       =>  lv_errmsg                   -- ���[�U�[�E�G���[���b�Z�[�W
          , iv_conc_name    =>  cv_pkg_name                 -- �R���J�����g��
          , iv_file_name    =>  cv_file_name                -- �o�̓t�@�C����
          , iv_file_id      =>  cv_pkg_name                 -- ���[ID
          , iv_output_mode  =>  cv_output_mode              -- �o�͋敪
          , iv_frm_file     =>  cv_frm_file                 -- �t�H�[���l���t�@�C����
          , iv_vrq_file     =>  cv_vrq_file                 -- �N�G���[�l���t�@�C����
          , iv_org_id       =>  fnd_global.org_id           -- ORG_ID
          , iv_user_name    =>  cn_created_by               -- ���O�C���E���[�U��
          , iv_resp_name    =>  fnd_global.resp_name        -- ���O�C���E���[�U�̐E�Ӗ�
          , iv_doc_name     =>  NULL                        -- ������
          , iv_printer_name =>  NULL                        -- �v�����^��
          , iv_request_id   =>  cn_request_id               -- �v��ID
          , iv_nodata_msg   =>  NULL                        -- �f�[�^�Ȃ����b�Z�[�W
          , iv_svf_param1   =>  NULL                        -- svf�σp�����[�^1
          , iv_svf_param2   =>  NULL                        -- svf�σp�����[�^2
          , iv_svf_param3   =>  NULL                        -- svf�σp�����[�^3
          , iv_svf_param4   =>  NULL                        -- svf�σp�����[�^4
          , iv_svf_param5   =>  NULL                        -- svf�σp�����[�^5
          , iv_svf_param6   =>  NULL                        -- svf�σp�����[�^6
          , iv_svf_param7   =>  NULL                        -- svf�σp�����[�^7
          , iv_svf_param8   =>  NULL                        -- svf�σp�����[�^8
          , iv_svf_param9   =>  NULL                        -- svf�σp�����[�^9
          , iv_svf_param10  =>  NULL                        -- svf�σp�����[�^10
          , iv_svf_param11  =>  NULL                        -- svf�σp�����[�^11
          , iv_svf_param12  =>  NULL                        -- svf�σp�����[�^12
          , iv_svf_param13  =>  NULL                        -- svf�σp�����[�^13
          , iv_svf_param14  =>  NULL                        -- svf�σp�����[�^14
          , iv_svf_param15  =>  NULL                        -- svf�σp�����[�^15
          );

      -- �G���[�n���h�����O
      IF (lv_retcode <> cv_status_normal) THEN
        ov_retcode := cv_status_error;
        ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_application
                     ,iv_name         => cv_api_err_msg
                     ,iv_token_name1  => cv_api_err_msg_tkn_lbl1
                     ,iv_token_value1 => cv_api_err_msg_tkn_lbl1_val
                     ,iv_token_name2  => cv_api_err_msg_tkn_lbl2
                     ,iv_token_value2 => lv_errmsg
                     );
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_application
                     ,iv_name         => cv_api_err_msg
                     ,iv_token_name1  => cv_api_err_msg_tkn_lbl1
                     ,iv_token_value1 => cv_api_err_msg_tkn_lbl1_val
                     ,iv_token_name2  => cv_api_err_msg_tkn_lbl2
                     ,iv_token_value2 => SQLERRM
                     );
    END;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
--���������ł͎g�p���Ȃ���������������������������������������������
--��    -- *** ���ʊ֐���O�n���h�� ***
--��    WHEN global_api_expt THEN
--��      ov_errmsg  := lv_errmsg;
--��      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--��      ov_retcode := cv_status_error;
--��    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--��    WHEN global_api_others_expt THEN
--��      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--��      ov_retcode := cv_status_error;
--������������������������������������������������������������������
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END svf_call;
--��1.1 2009/03/04 Add End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_prod_class_code  IN     VARCHAR2,     -- 1.���i�敪
    iv_base_code        IN     VARCHAR2,     -- 2.���_
    ov_errbuf           OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_which   NUMBER;
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;

    -- �p�����[�^���������ʃ��|�[�g�ƃ��O�ɏo��
    FOR ix IN 1..1 LOOP

      IF (ix=1) THEN
        ln_which := FND_FILE.LOG;
      ELSE
        ln_which := FND_FILE.OUTPUT;
      END IF;

      FND_FILE.PUT_LINE(ln_which,'');    -- ���s
      FND_FILE.PUT_LINE(ln_which,cv_pm_prod_class_code_tl || cv_pm_part  || iv_prod_class_code );
      FND_FILE.PUT_LINE(ln_which,cv_pm_base_code_tl       || cv_pm_part  || iv_base_code       );
      FND_FILE.PUT_LINE(ln_which,'');    -- ���s

    END LOOP;

    -- �O���[�o���ϐ��Ƀp�����[�^��ݒ�
    gv_prod_class_code := RTRIM( iv_prod_class_code );
    gv_base_code       := RTRIM( iv_base_code );
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    --        A-1 ��������
    -- 1.WHO���擾
    --   ���ϐ���`���Őݒ�ς�
    -- ===============================
    -- �}�X�^�����p���t�ݒ�
    gd_system_date             := TRUNC(SYSDATE);

    gd_this_month_start_day    := TO_DATE(TO_CHAR(gd_system_date,cv_target_month_format),cv_target_month_format);
    gd_this_month_end_day      := ADD_MONTHS(gd_this_month_start_day,1) - (1/24/60/60);
    gd_last_month_start_day    := ADD_MONTHS(gd_this_month_start_day,-1);
    gd_last_month_end_day      := ADD_MONTHS(gd_this_month_end_day  ,-1);
    gd_next_month_start_day    := ADD_MONTHS(gd_this_month_start_day,1);
    gd_next_month_end_day      := ADD_MONTHS(gd_this_month_end_day  ,1);
    gd_prev_day                := gd_system_date - (1/24/60/60);

    -- �v��A���ѐ��ʎ擾�p���t�ݒ�
    gv_target_month            := TO_CHAR(ADD_MONTHS(gd_system_date,1),cv_target_month_format);
    gd_target_date_st_day      := TO_DATE(gv_target_month,cv_target_month_format);
    gd_target_date_ed_day      := TO_DATE(ADD_MONTHS(gd_target_date_st_day,1) - (1/24/60/60));
    gd_forecast_collect_st_day := ADD_MONTHS(gd_target_date_st_day,-3);
    gd_forecast_collect_ed_day := gd_target_date_ed_day;
    gd_result_collect_st_day1  := ADD_MONTHS(gd_target_date_st_day,-15);
    gd_result_collect_ed_day1  := ADD_MONTHS(gd_target_date_ed_day  ,-11);
    gd_result_collect_st_day2  := ADD_MONTHS(gd_target_date_st_day,-3);
    gd_result_collect_ed_day2  := ADD_MONTHS(gd_target_date_ed_day  ,-1);

    -- �w�b�_�[��񃏁[�N�N���A
    g_header_data_tbl := g_header_data_tbl_init;

--20090428_Ver1.2_T1_0645_SCS.Kikuchi_DEL_START
--    ---------------------------------------------------
--    --  �}�X�^�i�ڑg�D�̎擾
--    ---------------------------------------------------
--    BEGIN
--      gn_mater_org_id  :=  TO_NUMBER(fnd_profile.value(cv_cmn_organization_id));
--    EXCEPTION
--      WHEN OTHERS THEN
--        gn_mater_org_id  :=  NULL;
--    END;
--    -- �v���t�@�C���F�}�X�^�i�ڑg�D���擾�o���Ȃ����G���[�ƂȂ�ꍇ
--    IF ( gn_mater_org_id IS NULL ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_msg_application
--                    ,iv_name         => cv_profile_chk_msg
--                    ,iv_token_name1  => cv_profile_chk_msg_tkn_lbl1
--                    ,iv_token_value1 => cv_profile_chk_msg_tkn_val1
--                   );
--      gn_error_cnt := gn_error_cnt + 1;
--      RAISE global_process_expt;
--    END IF;
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_DEL_END
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_START
    ---------------------------------------------------
    --  �c�Ƒg�D�R�[�h�̎擾
    ---------------------------------------------------
    BEGIN
      gv_sales_org_code := fnd_profile.value(cv_sales_org_code);
    EXCEPTION
      WHEN OTHERS THEN
        gv_sales_org_code := NULL;
    END;
    -- �v���t�@�C���F�c�Ƒg�D���擾�o���Ȃ��ꍇ
    IF ( gv_sales_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_profile_chk_msg
                    ,iv_token_name1  => cv_profile_chk_msg_tkn_lbl1
                    ,iv_token_value1 => cv_profile_chk_msg_tkn_val1
                   );
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_END

    -- ================================================
    --  A-2,A-3 �Ώۋ��_�E���[�w�b�_���擾
    -- ================================================
    get_header_data(
      lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;

    <<get_header_data_loop>>
    FOR header_ix IN 1..g_header_data_tbl.COUNT LOOP

      -- ���׏�񃏁[�N�N���A
      g_detail_data_tbl       := g_detail_data_tbl_init;

      -- �o�^�p���[�N�N���A
      g_forecast_planning_rec := g_forecast_planning_rec_init;

      -- ================================================
      --  A-4 ���[���׏��擾
      -- ================================================
      get_detail_data(
        header_ix                            -- �w�b�_��񃌃R�[�hINDEX
       ,lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;

      <<get_detail_data_loop>>
      FOR detail_ix IN 1..g_detail_data_tbl.COUNT LOOP

        -- ======================================================
        --   A-5 ���ʐU�����E�f�[�^�ێ�
        -- ======================================================
        qty_editing_data_keep(
          in_header_index     => header_ix          -- 1.�w�b�_��񃌃R�[�hINDEX
         ,in_detail_index     => detail_ix          -- 2.���׏�񃌃R�[�hINDEX
         ,ov_errbuf           => lv_errbuf          --   �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode          => lv_retcode         --   ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg           => lv_errmsg          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         );

        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;

        -- �ŏI���R�[�h�A�܂��́A�����R�[�h�̕i�ڂ��قȂ�ꍇ�A���[�N�e�[�u���o�^���s�Ȃ��B
        IF  (  (detail_ix = g_detail_data_tbl.COUNT)
            OR (g_detail_data_tbl(detail_ix + 1).item_no <> g_detail_data_tbl(detail_ix).item_no) ) THEN

          -- ======================================================
          --  A-6 �����Q�l���ʌv�Z
          -- ======================================================
          reference_qty_calc(
            in_header_index     => header_ix          -- 1.�w�b�_��񃌃R�[�hINDEX
           ,in_detail_index     => detail_ix          -- 2.���׏�񃌃R�[�hINDEX
           ,ov_errbuf           => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode          => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg           => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;

          -- ======================================================
          --  A-7 ����v�旧�ĕ\���[���[�N�e�[�u���f�[�^�o�^
          -- ======================================================
          insert_svf_work_tbl(
            lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;

          -- �o�^�p���[�N�N���A
          g_forecast_planning_rec := g_forecast_planning_rec_init;

        END IF;

      END LOOP get_detail_data_loop;

    END LOOP get_header_data_loop;

    -- �o�͌����J�E���g�A�b�v
    gn_target_cnt := gn_normal_cnt;

    -- SVF�N���O�ɃR�~�b�g���s�Ȃ�
    COMMIT;
    
    -- ===============================
    --  A-8 SVF�N��
    -- ===============================
--��1.1 2009/03/03 Add Start
    svf_call(
      lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;
--��1.1 2009/03/03 Add End

    -- ===============================
    --  A-9 ���[�N�e�[�u���f�[�^�폜
    -- ===============================
    DELETE
    FROM    xxcop_rep_forecast_planning
    WHERE   request_id = cn_request_id
    ;

  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_START
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      IF (lv_errbuf IS NULL) THEN
        ov_errbuf := NULL;
      ELSE
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
      ov_retcode := cv_status_error;
--20090428_Ver1.2_T1_0645_SCS.Kikuchi_ADD_END
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
    errbuf              OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_prod_class_code  IN  VARCHAR2,      -- 1.���i�敪
    iv_base_code        IN  VARCHAR2       -- 2.���_
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
       IV_WHICH   => 'LOG'              --��1.1 2009/03/04 Add
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
       iv_prod_class_code  -- 1.���i�敪
      ,iv_base_code        -- 2.���_
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
--��1.1 2009/03/04 Upd Start
--��      FND_FILE.PUT_LINE(
--��         which  => FND_FILE.OUTPUT
--��        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--��      );
--��      FND_FILE.PUT_LINE(
--��         which  => FND_FILE.LOG
--��        ,buff => lv_errbuf --�G���[���b�Z�[�W
--��      );

      -- ���[�U�G���[���b�Z�[�W�����O�o��
      IF (lv_errmsg IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff =>   lv_errmsg
        );
      END IF;
      -- �V�X�e���G���[���b�Z�[�W�����O�o��
      IF (lv_errbuf IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff =>   xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_others_err_msg
                    ,iv_token_name1  => cv_others_err_msg_tkn_lbl1
                    ,iv_token_value1 => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                    )
        );
      END IF;
--��1.1 2009/03/04 Upd End
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT   --��1.1 2009/03/04 Upd
       which  => FND_FILE.LOG        --��1.1 2009/03/04 Upd
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
--       which  => FND_FILE.OUTPUT   --��1.1 2009/03/04 Upd
       which  => FND_FILE.LOG        --��1.1 2009/03/04 Upd
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
--       which  => FND_FILE.OUTPUT   --��1.1 2009/03/04 Upd
       which  => FND_FILE.LOG        --��1.1 2009/03/04 Upd
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
--       which  => FND_FILE.OUTPUT   --��1.1 2009/03/04 Upd
       which  => FND_FILE.LOG        --��1.1 2009/03/04 Upd
      ,buff   => gv_out_msg
    );
    --
--    --�X�L�b�v�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
    --��s�}��
    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT   --��1.1 2009/03/04 Upd
       which  => FND_FILE.LOG        --��1.1 2009/03/04 Upd
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
--       which  => FND_FILE.OUTPUT   --��1.1 2009/03/04 Upd
       which  => FND_FILE.LOG        --��1.1 2009/03/04 Upd
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
END XXCOP004A05R;
/
