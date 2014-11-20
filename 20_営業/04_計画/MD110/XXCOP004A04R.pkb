CREATE OR REPLACE PACKAGE BODY XXCOP004A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A04R(body)
 * Description      : ����v��`�F�b�N���X�g�o�̓��[�N�o�^
 * MD.050           : ����v��`�F�b�N���X�g MD050_COP_004_A04
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_target_base_code   �Ώۋ��_�擾�i�z�����_�j�iA-2�j
 *  qty_editing_data_keep  ���ʐU�����E�f�[�^�ێ�(A-4)
 *  insert_check_list      ����v��`�F�b�N���X�g���[���[�N�f�[�^�o�^(A-5)
 *  svf_call               SVF�N��(A-6) 
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/03    1.0  SCS.Kikuchi       �V�K�쐬
 *  2009/03/03    1.1  SCS.Kikuchi       SVF�����Ή�
 *  2009/11/17    1.2  SCS.Miyagawa      SVF�t�@�C�����Ή�
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
--��1.1 2009/03/03 Add Start
  internal_process_expt        EXCEPTION;     -- ����PROCEDURE/FUNCTION�G���[�n���h�����O�p
--��1.1 2009/03/03 Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(100) := 'XXCOP004A04R';    -- �p�b�P�[�W��
  cv_target_month_format       CONSTANT VARCHAR2(6)   := 'YYYYMM';          -- �p�����[�^�F�Ώ۔N������
  cv_customer_class_code_base  CONSTANT VARCHAR2(1)   := '1';               -- �ڋq�敪�i���_�j
  cv_forecast_class            CONSTANT VARCHAR2(2)   := '01';              -- �t�H�[�L���X�g���ށF����v��
  
  -- ���̓p�����[�^���O�o�͗p
  cv_pm_target_month_tl       CONSTANT VARCHAR2(100) := '�Ώ۔N��';
  cv_pm_prod_class_code_tl    CONSTANT VARCHAR2(100) := '���i�敪';
  cv_pm_base_code_tl          CONSTANT VARCHAR2(100) := '���_';
  cv_pm_whse_code_tl          CONSTANT VARCHAR2(100) := '�o�׌��q��';
  cv_pm_part                  CONSTANT VARCHAR2(6)   := '�@�F�@';

--��1.1 2009/03/03 Add Start
  -- ���b�Z�[�W�֘A
  cv_msg_application          CONSTANT VARCHAR2(100) := 'XXCOP';
  cv_others_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041'; -- CSV����߯ċ@�\�V�X�e���G���[���b�Z�[�W
  cv_others_err_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'ERRMSG';
  cv_api_err_msg              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00016'; -- API�N���G���[
  cv_api_err_msg_tkn_lbl1     CONSTANT VARCHAR2(100) := 'PRG_NAME';
  cv_api_err_msg_tkn_lbl1_val CONSTANT VARCHAR2(100) := 'XXCCP_SVFCOMMON_PKG.SUBMIT_SVF_REQUEST';
  cv_api_err_msg_tkn_lbl2     CONSTANT VARCHAR2(100) := 'ERR_MSG';

  -- SVF�o�͑Ή�
--��1.2 2009/11/17 Del Start
--  cv_svf_date_format          CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS';     -- �p�����[�^�F�Ώ۔N������
--  cv_file_name                CONSTANT VARCHAR2(40)  := 'XXCOP004A04R'
--                                                        || TO_CHAR(SYSDATE,cv_svf_date_format)
--                                                        || '.pdf';              -- �o�̓t�@�C����
--��1.2 2009/11/17 Del End
--��1.2 2009/11/17 Add Start
  cv_svf_date_format          CONSTANT VARCHAR2(16)  := 'YYYYMMDD';     -- �p�����[�^�F�Ώ۔N������
  cv_file_name                CONSTANT VARCHAR2(40)  := cv_pkg_name
                                                        || TO_CHAR(SYSDATE,cv_svf_date_format)
                                                        || cn_request_id
                                                        || '.pdf';              -- �o�̓t�@�C����
--��1.2 2009/11/17 Add End
  cv_output_mode              CONSTANT VARCHAR2(1)   := '1';                    -- �o�͋敪�F�h�P�h�i�o�c�e�j
  cv_frm_file                 CONSTANT VARCHAR2(20)  := 'XXCOP004A04S.xml';     -- �t�H�[���l���t�@�C����
  cv_vrq_file                 CONSTANT VARCHAR2(20)  := 'XXCOP004A04S.vrq';     -- �N�G���[�l���t�@�C����

--��1.1 2009/03/03 Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ����v��`�F�b�N���X�g�o�͑Ώۋ��_���R�[�h�^
  TYPE target_base_trec IS RECORD(
      account_number           hz_cust_accounts.account_number %TYPE  -- �ڋq�R�[�h
    , base_short_name          xxcmn_parties.party_short_name  %TYPE  -- ���_��
    );

  -- ����v��`�F�b�N���X�g�o�͑Ώۋ��_PL/SQL�\
  TYPE target_base_ttype IS
    TABLE OF target_base_trec INDEX BY BINARY_INTEGER;

  -- ����v��`�F�b�N���X�g�o�̓f�[�^���R�[�h
  TYPE check_list_data_trec IS RECORD(
      target_month     xxcop_rep_forecast_check_list.target_month %TYPE     -- �Ώ۔N��
    , prod_class_code  xxcop_item_categories1_v.prod_class_code   %TYPE     -- ���i�敪
    , prod_class_name  xxcop_item_categories1_v.prod_class_name   %TYPE     -- ���i�敪��
    , base_code        mrp_forecast_designators.attribute3        %TYPE     -- ���_�R�[�h
    , base_short_name  xxcmn_parties.party_short_name             %TYPE     -- ���_��
    , whse_code        mrp_forecast_designators.attribute2        %TYPE     -- �o�׌��q�ɃR�[�h
    , whse_short_name  mtl_item_locations.attribute11             %TYPE     -- �o�׌��q�ɖ�
    , crowd_class_code xxcop_item_categories1_v.crowd_class_code  %TYPE     -- �Q�R�[�h
    , item_no          xxcop_item_categories1_v.item_no           %TYPE     -- ���i�R�[�h
    , item_short_name  xxcop_item_categories1_v.item_short_name   %TYPE     -- ���i��
    , num_of_cases     xxcop_item_categories1_v.num_of_cases      %TYPE     -- �P�[�X����
    );

  -- ����v��`�F�b�N���X�g����v�搔�ʁi1�`�����jPL/SQL�\
  TYPE check_list_qty_ttype IS
    TABLE OF xxcop_rep_forecast_check_list.forecast_quantity_day1%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���̓p�����[�^�i�[�p
  gv_target_month              VARCHAR2(6);
  gv_prod_class_code           VARCHAR2(1);
  gv_base_code                 VARCHAR2(4);
  gv_whse_code                 VARCHAR2(4);

  -- �Ώ۔N���J�n���A�I�����A�V�X�e�����t�i�[�p
  gd_target_month_start_day    DATE;
  gd_target_month_end_day      DATE;
  gd_system_date               DATE;

  -- �o�͑Ώۃf�[�^�i�[�p
  g_target_base_tbl            target_base_ttype;     -- ����v��`�F�b�N���X�g�o�͑Ώۋ��_
  g_target_base_tbl_init       target_base_ttype;     -- ����v��`�F�b�N���X�g�o�͑Ώۋ��_�������p
  g_check_list_data_rec        check_list_data_trec;  -- ����v��`�F�b�N���X�g�o�̓f�[�^
  g_check_list_data_rec_init   check_list_data_trec;  -- ����v��`�F�b�N���X�g�o�̓f�[�^�������p
  g_check_list_qty_tbl         check_list_qty_ttype;  -- ����v��`�F�b�N���X�g����v�搔�ʁi1�`�����j
  g_check_list_qty_tbl_init    check_list_qty_ttype;  -- ����v��`�F�b�N���X�g����v�搔�ʁi1�`�����j�������p

  -- ����0�����b�Z�[�W�i�[�p
  gv_rep_no_data_msg           VARCHAR2(5000);

  gv_debug_mode                VARCHAR2(30);          -- �f�o�b�O�o�͔���p
--
--
--
  /**********************************************************************************
   * Procedure Name   : get_target_base_code
   * Description      : �Ώۋ��_�擾�i�z�����_�j�iA-2�j
   ***********************************************************************************/
  PROCEDURE get_target_base_code(
     ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_base_code'; -- �v���O������
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
    SELECT hca.account_number   account_number     -- �ڋq�R�[�h
    ,      xp.party_short_name  base_short_name    -- ���_��
    BULK COLLECT
    INTO   g_target_base_tbl
    FROM   hz_cust_accounts         hca            -- �ڋq�}�X�^
    ,      xxcmn_parties            xp             -- �p�[�e�B�A�h�I���}�X�^
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
  END get_target_base_code;
--
  /**********************************************************************************
   * Procedure Name   : qty_editing_data_keep
   * Description      : ���ʐU�����E�f�[�^�ێ�(A-4)
   ***********************************************************************************/
  PROCEDURE qty_editing_data_keep(
     id_forecast_date     IN  mrp_forecast_dates.forecast_date%type              -- �t�H�[�L���X�g���t
   , in_forecast_qty      IN  mrp_forecast_dates.original_forecast_quantity%type -- ���ʌv�搔��
   , in_num_of_cases      IN  xxcop_item_categories1_v.num_of_cases%type         -- �P�[�X����
   , iv_prod_class_code   IN  xxcop_item_categories1_v.prod_class_code%type      -- ���i�敪
   , iv_prod_class_name   IN  xxcop_item_categories1_v.prod_class_name%type      -- ���i�敪��
   , iv_base_code         IN  mrp_forecast_designators.attribute3%type           -- ���_�R�[�h
   , iv_base_short_name   IN  xxcmn_parties.party_short_name%type                -- ���_��
   , iv_whse_code         IN  mrp_forecast_designators.attribute2%type           -- �o�׌��q�ɃR�[�h
   , iv_whse_short_name   IN  mtl_item_locations.attribute12%type                -- �o�׌��q�ɖ�
   , iv_crowd_class_code  IN  xxcop_item_categories1_v.crowd_class_code%type     -- �Q�R�[�h
   , iv_item_no           IN  xxcop_item_categories1_v.item_no%type              -- ���i�R�[�h
   , iv_item_short_name   IN  xxcop_item_categories1_v.item_short_name%type      -- ���i��
   , ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xxcop_rep_forecast_check_list'; -- �v���O������
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
    ln_index number;
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
    -- �t�H�[�L���X�g���t�̓��ɂ���PL/SQL�\��index�ԍ��ɐݒ肷��B
    ln_index := TO_NUMBER(TO_CHAR(id_forecast_date,'dd'));

    -- PL/SQL�\�Ɉ���v�搔�ʁi�t�H�[�L���X�g���ʁ��P�[�X�����j�������؎̂��A�i�[����B
    g_check_list_qty_tbl(ln_index) := TRUNC( in_forecast_qty / NVL( in_num_of_cases ,1 ) );

    -- index�[�������v�Ƃ��ĉ��Z����B
    g_check_list_qty_tbl(0) := NVL(g_check_list_qty_tbl(0),0) + NVL(g_check_list_qty_tbl(ln_index),0);

    -- �u���C�N����E�e�[�u���o�^�p�Ƀf�[�^��ێ�����B

    -- �Ώ۔N���̕ҏW
    g_check_list_data_rec.target_month     := SUBSTRB(TO_CHAR(id_forecast_date,cv_target_month_format),1,6);

    g_check_list_data_rec.prod_class_code  := iv_prod_class_code;            -- ���i�敪
    g_check_list_data_rec.prod_class_name  := iv_prod_class_name;            -- ���i�敪��
    g_check_list_data_rec.base_code        := iv_base_code;                  -- ���_�R�[�h
    g_check_list_data_rec.base_short_name  := iv_base_short_name;            -- ���_��
    g_check_list_data_rec.whse_code        := iv_whse_code;                  -- �o�׌��q�ɃR�[�h
    g_check_list_data_rec.whse_short_name  := iv_whse_short_name;            -- �o�׌��q�ɖ�
    g_check_list_data_rec.crowd_class_code := iv_crowd_class_code;           -- �Q�R�[�h
    g_check_list_data_rec.item_no          := iv_item_no;                    -- ���i�R�[�h
    g_check_list_data_rec.item_short_name  := iv_item_short_name;            -- ���i��

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
--
  /**********************************************************************************
   * Procedure Name   : insert_check_list
   * Description      : ����v��`�F�b�N���X�g���[���[�N�f�[�^�o�^(A-5)
   ***********************************************************************************/
  PROCEDURE insert_check_list(
     ov_errbuf   OUT VARCHAR2            --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode  OUT VARCHAR2            --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg   OUT VARCHAR2            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xxcop_rep_forecast_check_list'; -- �v���O������
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
    -- ����v��`�F�b�N���X�g���[���[�N�e�[�u���f�[�^�o�^����
    -----------------------------------------------------------------
    INSERT INTO xxcop_rep_forecast_check_list
      ( target_month                   -- �Ώ۔N��
      , prod_class_code                -- ���i�敪
      , prod_class_name                -- ���i�敪��
      , base_code                      -- ���_�R�[�h
      , base_short_name                -- ���_��
      , whse_code                      -- �o�׌��q�ɃR�[�h
      , whse_short_name                -- �o�׌��q�ɖ�
      , crowd_class_code               -- �Q�R�[�h
      , item_no                        -- ���i�R�[�h
      , item_short_name                -- ���i��
      , forecast_quantity_total        -- ���v  ����v�搔��
      , forecast_quantity_day1         -- 1��  ����v�搔��
      , forecast_quantity_day2         -- 2��  ����v�搔��
      , forecast_quantity_day3         -- 3��  ����v�搔��
      , forecast_quantity_day4         -- 4��  ����v�搔��
      , forecast_quantity_day5         -- 5��  ����v�搔��
      , forecast_quantity_day6         -- 6��  ����v�搔��
      , forecast_quantity_day7         -- 7��  ����v�搔��
      , forecast_quantity_day8         -- 8��  ����v�搔��
      , forecast_quantity_day9         -- 9��  ����v�搔��
      , forecast_quantity_day10        -- 10�� ����v�搔��
      , forecast_quantity_day11        -- 11�� ����v�搔��
      , forecast_quantity_day12        -- 12�� ����v�搔��
      , forecast_quantity_day13        -- 13�� ����v�搔��
      , forecast_quantity_day14        -- 14�� ����v�搔��
      , forecast_quantity_day15        -- 15�� ����v�搔��
      , forecast_quantity_day16        -- 16�� ����v�搔��
      , forecast_quantity_day17        -- 17�� ����v�搔��
      , forecast_quantity_day18        -- 18�� ����v�搔��
      , forecast_quantity_day19        -- 19�� ����v�搔��
      , forecast_quantity_day20        -- 20�� ����v�搔��
      , forecast_quantity_day21        -- 21�� ����v�搔��
      , forecast_quantity_day22        -- 22�� ����v�搔��
      , forecast_quantity_day23        -- 23�� ����v�搔��
      , forecast_quantity_day24        -- 24�� ����v�搔��
      , forecast_quantity_day25        -- 25�� ����v�搔��
      , forecast_quantity_day26        -- 26�� ����v�搔��
      , forecast_quantity_day27        -- 27�� ����v�搔��
      , forecast_quantity_day28        -- 28�� ����v�搔��
      , forecast_quantity_day29        -- 29�� ����v�搔��
      , forecast_quantity_day30        -- 30�� ����v�搔��
      , forecast_quantity_day31        -- 31�� ����v�搔��
      , created_by                     -- �쐬��
      , creation_date                  -- �쐬��
      , last_updated_by                -- �ŏI�X�V��
      , last_update_date               -- �ŏI�X�V��
      , last_update_login              -- �ŏI�X�V���O�C��
      , request_id                     -- �v��ID
      , program_application_id         -- �v���O�����A�v���P�[�V����ID
      , program_id                     -- �v���O����ID
      , program_update_date            -- �v���O�����X�V��
      )
    VALUES
      ( g_check_list_data_rec.target_month               -- �Ώ۔N��
      , g_check_list_data_rec.prod_class_code            -- ���i�敪
      , g_check_list_data_rec.prod_class_name            -- ���i�敪��
      , g_check_list_data_rec.base_code                  -- ���_�R�[�h
      , g_check_list_data_rec.base_short_name            -- ���_��
      , g_check_list_data_rec.whse_code                  -- �o�׌��q�ɃR�[�h
      , g_check_list_data_rec.whse_short_name            -- �o�׌��q�ɖ�
      , g_check_list_data_rec.crowd_class_code           -- �Q�R�[�h
      , g_check_list_data_rec.item_no                    -- ���i�R�[�h
      , g_check_list_data_rec.item_short_name            -- ���i��
      , g_check_list_qty_tbl(0)                          -- ���v  ����v�搔��
      , g_check_list_qty_tbl(1)                          -- 1��  ����v�搔��
      , g_check_list_qty_tbl(2)                          -- 2��  ����v�搔��
      , g_check_list_qty_tbl(3)                          -- 3��  ����v�搔��
      , g_check_list_qty_tbl(4)                          -- 4��  ����v�搔��
      , g_check_list_qty_tbl(5)                          -- 5��  ����v�搔��
      , g_check_list_qty_tbl(6)                          -- 6��  ����v�搔��
      , g_check_list_qty_tbl(7)                          -- 7��  ����v�搔��
      , g_check_list_qty_tbl(8)                          -- 8��  ����v�搔��
      , g_check_list_qty_tbl(9)                          -- 9��  ����v�搔��
      , g_check_list_qty_tbl(10)                         -- 10�� ����v�搔��
      , g_check_list_qty_tbl(11)                         -- 11�� ����v�搔��
      , g_check_list_qty_tbl(12)                         -- 12�� ����v�搔��
      , g_check_list_qty_tbl(13)                         -- 13�� ����v�搔��
      , g_check_list_qty_tbl(14)                         -- 14�� ����v�搔��
      , g_check_list_qty_tbl(15)                         -- 15�� ����v�搔��
      , g_check_list_qty_tbl(16)                         -- 16�� ����v�搔��
      , g_check_list_qty_tbl(17)                         -- 17�� ����v�搔��
      , g_check_list_qty_tbl(18)                         -- 18�� ����v�搔��
      , g_check_list_qty_tbl(19)                         -- 19�� ����v�搔��
      , g_check_list_qty_tbl(20)                         -- 20�� ����v�搔��
      , g_check_list_qty_tbl(21)                         -- 21�� ����v�搔��
      , g_check_list_qty_tbl(22)                         -- 22�� ����v�搔��
      , g_check_list_qty_tbl(23)                         -- 23�� ����v�搔��
      , g_check_list_qty_tbl(24)                         -- 24�� ����v�搔��
      , g_check_list_qty_tbl(25)                         -- 25�� ����v�搔��
      , g_check_list_qty_tbl(26)                         -- 26�� ����v�搔��
      , g_check_list_qty_tbl(27)                         -- 27�� ����v�搔��
      , g_check_list_qty_tbl(28)                         -- 28�� ����v�搔��
      , g_check_list_qty_tbl(29)                         -- 29�� ����v�搔��
      , g_check_list_qty_tbl(30)                         -- 30�� ����v�搔��
      , g_check_list_qty_tbl(31)                         -- 31�� ����v�搔��
      , cn_created_by                                    -- �쐬��
      , cd_creation_date                                 -- �쐬��
      , cn_last_updated_by                               -- �ŏI�X�V��
      , cd_last_update_date                              -- �ŏI�X�V��
      , cn_last_update_login                             -- �ŏI�X�V���O�C��
      , cn_request_id                                    -- �v��ID
      , cn_program_application_id                        -- �v���O�����A�v���P�[�V����ID
      , cn_program_id                                    -- �v���O����ID
      , cd_program_update_date                           -- �v���O�����X�V��
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
  END insert_check_list;
--
--
--��1.1 2009/03/03 Add Start
  /**********************************************************************************
   * Procedure Name   : svf_call
   * Description      : SVF�N��(A-6)
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
--��1.1 2009/03/03 Add End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_month     IN     VARCHAR2,     -- 1.�Ώ۔N��
    iv_prod_class_code  IN     VARCHAR2,     -- 2.���i�敪
    iv_base_code        IN     VARCHAR2,     -- 3.���_
    iv_whse_code        IN     VARCHAR2,     -- 4.�o�׌��q��
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
    cv_msg_application         CONSTANT VARCHAR2(100) := 'XXCOP' ;               -- ����I�����b�Z�[�W
    cv_param_chk1_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00029';     -- �Ώ۔N���`�F�b�N�G���[���b�Z�[�W
    cv_param_chk1_msg_tkn_lbl  CONSTANT VARCHAR2(100) := 'item';                 --   �g�[�N����
    cv_param_chk1_msg_tkn_val  CONSTANT VARCHAR2(100) := '�Ώ۔N��';             --   �g�[�N���Z�b�g�l
--
    -- *** ���[�J���ϐ� ***
    ln_which NUMBER;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- A-3 �o�̓f�[�^�擾�J�[�\��
    CURSOR get_output_data_cur(
      civ_base_code  IN  VARCHAR2
    )IS
      SELECT xic1v.prod_class_code            prod_class_code             -- ���i�敪
      ,      xic1v.prod_class_name            prod_class_name             -- ���i�敪��
      ,      mfde.attribute3                  base_code                   -- ���_�R�[�h
      ,      mfde.attribute2                  whse_code                   -- �o�׌��q�ɃR�[�h
      ,      mil.attribute12                  whse_short_name             -- �o�׌��q�ɖ�
      ,      xic1v.crowd_class_code           crowd_class_code            -- �Q�R�[�h
      ,      xic1v.item_no                    item_no                     -- ���i�R�[�h
      ,      xic1v.item_short_name            item_short_name             -- ���i��
      ,      mfda.forecast_date               forecast_date               -- �t�H�[�L���X�g���t
      ,      mfda.original_forecast_quantity  original_forecast_quantity  -- ����
      ,      xic1v.num_of_cases               num_of_cases                -- �P�[�X����
      FROM
             mrp_forecast_designators mfde                                -- �t�H�[�L���X�g��
      ,      mrp_forecast_dates       mfda                                -- �t�H�[�L���X�g���t
      ,      xxcop_item_categories1_v xic1v                               -- �v��_�i�ڃJ�e�S���r���[1
      ,      mtl_item_locations       mil                                 -- OPM�ۊǏꏊ�}�X�^
      WHERE
             mfde.forecast_designator =  mfda.forecast_designator
      AND    mfde.organization_id     =  mfda.organization_id
      AND    mfde.attribute1          =  cv_forecast_class                                 -- FORECAST���ށF����v��
      AND    mfde.attribute2          =  nvl( gv_whse_code ,mfde.attribute2 )              -- �o�Ɍ��q��
      AND    mfde.attribute3          =  civ_base_code                                     -- ���_�R�[�h
      AND    mfda.forecast_date       BETWEEN gd_target_month_start_day
                                      AND     gd_target_month_end_day
      AND    xic1v.inventory_item_id  =  mfda.inventory_item_id
      AND    xic1v.start_date_active  <= gd_system_date
      AND    xic1v.end_date_active    >= gd_system_date
      AND    xic1v.prod_class_code    =  nvl( gv_prod_class_code ,xic1v.prod_class_code )  -- ���i�敪
      AND    mil.segment1             =  mfde.attribute2                                   -- �o�Ɍ��q��
      ORDER
      BY     xic1v.prod_class_code                     -- ���i�敪
      ,      mfde.attribute3                           -- ���_�R�[�h
      ,      mfde.attribute2                           -- �o�׌��q�ɃR�[�h
      ,      xic1v.crowd_class_code                    -- �Q�R�[�h
      ,      xic1v.item_no                             -- ���i�R�[�h
      ,      mfda.forecast_date                        -- �t�H�[�L���X�g���t
      ;
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
--    FOR ix IN 1..2 LOOP      --��1.1 2009/03/03 Upd
    -- �o�͐�̓��O�݂̂Ƃ���
    FOR ix IN 1..1 LOOP        --��1.1 2009/03/03 Upd
    
      IF (ix=1) THEN
        ln_which := FND_FILE.LOG;
      ELSE
        ln_which := FND_FILE.OUTPUT;
      END IF;

      FND_FILE.PUT_LINE(ln_which,'');    -- ���s
      FND_FILE.PUT_LINE(ln_which,cv_pm_target_month_tl    || cv_pm_part  || iv_target_month    );
      FND_FILE.PUT_LINE(ln_which,cv_pm_prod_class_code_tl || cv_pm_part  || iv_prod_class_code );
      FND_FILE.PUT_LINE(ln_which,cv_pm_base_code_tl       || cv_pm_part  || iv_base_code       );
      FND_FILE.PUT_LINE(ln_which,cv_pm_whse_code_tl       || cv_pm_part  || iv_whse_code       );
      FND_FILE.PUT_LINE(ln_which,'');    -- ���s

    END LOOP;

    -- �O���[�o���ϐ��Ƀp�����[�^��ݒ�
    gv_target_month    := RTRIM( iv_target_month );
    gv_prod_class_code := RTRIM( iv_prod_class_code );
    gv_base_code       := RTRIM( iv_base_code );
    gv_whse_code       := RTRIM( iv_whse_code );
    
    -- PLSQL�\�N���A�p���[�N������
    FOR ix IN 0..31 LOOP
      g_check_list_qty_tbl_init(ix) := 0;
    END LOOP;
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
    -- 2.�p�����[�^�`�F�b�N
    --   �v�����s��ʂ̃p�����[�^���͎��ɑ����`�F�b�N�ς�
    -- ===============================
    -- ���o�Ώ۔N�����ݒ�
    --   �J�n��       �c ���̓p�����[�^�Ώ۔N���̂P��    �O��  �O��  �O�b
    --   �I����       �c ���̓p�����[�^�Ώ۔N���̌������Q�R���T�X���T�X�b
    --   �}�X�^��� �c �V�X�e�����t�i�����b�؎̂āj
    gd_target_month_start_day := TO_DATE(gv_target_month,cv_target_month_format);
    gd_target_month_end_day   := ADD_MONTHS(TO_DATE(gv_target_month,cv_target_month_format),1) - (1/24/60/60);
    gd_system_date            := TRUNC(SYSDATE);

    -- ===============================
    --  A-2 �Ώۋ��_�擾�i�z�����_�j
    -- ===============================
    get_target_base_code(
      lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;

    <<a2_get_target_base_loop>>
    FOR ix IN 1..g_target_base_tbl.COUNT LOOP

      -- �o�^�p���R�[�h���[�N�N���A
      g_check_list_data_rec := g_check_list_data_rec_init;
      g_check_list_qty_tbl  := g_check_list_qty_tbl_init;

      -- ===============================
      --       A-3 �o�̓f�[�^�擾
      -- ===============================
      <<a3_get_output_data_loop>>
      FOR get_output_data_rec IN get_output_data_cur(g_target_base_tbl(ix).account_number)
      LOOP
        -- �U�����L�[���u���C�N�����ꍇ�A���[�N�e�[�u���o�^���s�Ȃ��B
        IF (  (g_check_list_data_rec.prod_class_code <> get_output_data_rec.prod_class_code)
           OR (g_check_list_data_rec.base_code       <> get_output_data_rec.base_code)
           OR (g_check_list_data_rec.whse_code       <> get_output_data_rec.whse_code)
           OR (g_check_list_data_rec.item_no         <> get_output_data_rec.item_no)
           ) THEN
          -- ===============================
          --  A-5 ���[�N�e�[�u���f�[�^�o�^
          -- ===============================
          insert_check_list(
            lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE global_process_expt;
          END IF;

          -- �o�^�p���R�[�h���[�N�N���A
          g_check_list_data_rec := g_check_list_data_rec_init;
          g_check_list_qty_tbl  := g_check_list_qty_tbl_init;
        END IF;

        -- ===============================
        --   A-4 ���ʐU�����E�f�[�^�ێ�
        -- ===============================
        qty_editing_data_keep(
          id_forecast_date    => get_output_data_rec.forecast_date               -- �t�H�[�L���X�g���t
         ,in_forecast_qty     => get_output_data_rec.original_forecast_quantity  -- ���ʌv�搔��
         ,in_num_of_cases     => get_output_data_rec.num_of_cases                -- �P�[�X����
         ,iv_prod_class_code  => get_output_data_rec.prod_class_code             -- ���i�敪
         ,iv_prod_class_name  => get_output_data_rec.prod_class_name             -- ���i�敪��
         ,iv_base_code        => get_output_data_rec.base_code                   -- ���_�R�[�h
         ,iv_base_short_name  => g_target_base_tbl(ix).base_short_name           -- ���_��
         ,iv_whse_code        => get_output_data_rec.whse_code                   -- �o�׌��q�ɃR�[�h
         ,iv_whse_short_name  => get_output_data_rec.whse_short_name             -- �o�׌��q�ɖ�
         ,iv_crowd_class_code => get_output_data_rec.crowd_class_code            -- �Q�R�[�h
         ,iv_item_no          => get_output_data_rec.item_no                     -- ���i�R�[�h
         ,iv_item_short_name  => get_output_data_rec.item_short_name             -- ���i��
         ,ov_errbuf           => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode          => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg           => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         );

        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;

      END LOOP a3_get_output_data_loop;

      -- �Ώۃf�[�^�����݂����ꍇ�i�i�ڂ��ݒ肳��Ă���ꍇ�j�A
      -- �ŏI�f�[�^�̓u���C�N�Ɣ��f���A���[�N�o�^���s�Ȃ��B
      IF (g_check_list_data_rec.item_no IS NOT NULL) THEN

        -- ===============================
        --  A-5 ���[�N�e�[�u���f�[�^�o�^
        -- ===============================
        insert_check_list(
          lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE global_process_expt;
        END IF;

      END IF;

    END LOOP a2_get_output_data_loop;

    -- �o�͌����J�E���g�A�b�v
    gn_target_cnt := gn_normal_cnt;

    -- SVF�N���O�ɃR�~�b�g���s�Ȃ�
    COMMIT;

--��1.1 2009/03/03 Add Start
    -- ===============================
    --  A-6 SVF�N��
    -- ===============================
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
    --  A-7 ���[�N�e�[�u���f�[�^�폜
    -- ===============================
    DELETE
    FROM    xxcop_rep_forecast_check_list
    WHERE   REQUEST_ID = cn_request_id
    ;

  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      IF (lv_errbuf IS NULL) THEN
        ov_errbuf := NULL;
      ELSE
        ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt	 THEN
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
    iv_target_month     IN  VARCHAR2,      -- 1.�Ώ۔N��
    iv_prod_class_code  IN  VARCHAR2,      -- 2.���i�敪
    iv_base_code        IN  VARCHAR2,      -- 3.���_
    iv_whse_code        IN  VARCHAR2       -- 4.�o�׌��q��
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
       iv_target_month     -- 1.�Ώ۔N��
      ,iv_prod_class_code  -- 2.���i�敪
      ,iv_base_code        -- 3.���_
      ,iv_whse_code        -- 4.�o�׌��q��
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
--��1.1 2009/03/03 Upd Start
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
--��1.1 2009/03/03 Upd End
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT   --��1.1 2009/03/03 Upd
       which  => FND_FILE.LOG        --��1.1 2009/03/03 Upd
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
--       which  => FND_FILE.OUTPUT   --��1.1 2009/03/03 Upd
       which  => FND_FILE.LOG        --��1.1 2009/03/03 Upd
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
--       which  => FND_FILE.OUTPUT   --��1.1 2009/03/03 Upd
       which  => FND_FILE.LOG        --��1.1 2009/03/03 Upd
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
--       which  => FND_FILE.OUTPUT   --��1.1 2009/03/03 Upd
       which  => FND_FILE.LOG        --��1.1 2009/03/03 Upd
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
--       which  => FND_FILE.OUTPUT   --��1.1 2009/03/03 Upd
       which  => FND_FILE.LOG        --��1.1 2009/03/03 Upd
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
--       which  => FND_FILE.OUTPUT   --��1.1 2009/03/03 Upd
       which  => FND_FILE.LOG        --��1.1 2009/03/03 Upd
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
END XXCOP004A04R;
/
