CREATE OR REPLACE PACKAGE BODY XXCOP004A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A03C(body)
 * Description      : ����v��W�v
 * MD.050           : ����v��W�v MD050_COP_004_A03
 * Version          : 1.2
 *
 * Program List
 * ------------------------------ ----------------------------------------------------------
 *  Name                           Description
 * ------------------------------ ----------------------------------------------------------
 *  init                           ��������(A-1)
 *  insert_whse_totaling           �����ΏۊO���_ �o�בq�ɏW�v�f�[�^�o�^�iA-3,A-4�j
 *  get_management_forcast_total   �����Ώۋ��_ �Ǘ������_�v�搔�ʏW�v�f�[�^���o�iA-5�j
 *  get_management_result_total    �����Ώۋ��_ �Ǘ������_���ѐ��ʏW�v�f�[�^���o�iA-6�j
 *  get_whse_totaling              �����Ώۋ��_ �Ǘ����o�בq�ɕʎ��ѐ��ʃf�[�^���o(A-7)
 *  insert_base_totaling           �����Ώۋ��_ ����v�搔�ʈ��f�[�^�o�^(A-8,A-9)
 *  csv_output                     ����v��W�v����CSV�o��(A-10)
 *  output_warn_msg                �x���f�[�^���b�Z�[�W�o��
 *  delete_work_table              ����v��W�v���[�N�e�[�u���폜
 *  submain                        ���C�������v���V�[�W��
 *  main                           �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/03    1.0  SCS.Kikuchi       �V�K�쐬
 *  2009/02/13    1.1  SCS.Kikuchi       �����e�X�g�d�l�ύX�i������QNo.008,009�j
 *  2009/04/07    1.2  SCS.Kikuchi       T1_0271�Ή�
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
  internal_process_expt        EXCEPTION;     -- ����PROCEDURE/FUNCTION�G���[�n���h�����O�p
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOP004A03C';        -- �p�b�P�[�W��

  -- ���̓p�����[�^���O�o�͗p
  cv_pm_base_code_tl            CONSTANT VARCHAR2(100) := '���_';
  cv_pm_prod_class_code_tl      CONSTANT VARCHAR2(100) := '���i�敪';
  cv_pm_results_clt_prd_tl      CONSTANT VARCHAR2(100) := '���ю��W����';
  cv_pm_forecast_clt_prd_tl     CONSTANT VARCHAR2(100) := '�v����W����';
  cv_pm_part                    CONSTANT VARCHAR2(6)   := '�@�F�@';
  cv_pm_part2                   CONSTANT VARCHAR2(6)   := '�@�`�@';

  -- ���t�ϊ�����
  cv_date_format1               CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24MISS';
  cv_date_format2               CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS';
  cv_date_format3               CONSTANT VARCHAR2(6)   := 'YYYYMM';
  cv_date_format4               CONSTANT VARCHAR2(2)   := 'DD';
  cv_date_format5               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_date_format6               CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
  cv_date_start_time            CONSTANT VARCHAR2(6)   := '000000';
  cv_date_end_time              CONSTANT VARCHAR2(6)   := '235959';

  -- �����������e�����l
  cv_forecast_class             CONSTANT VARCHAR2(2)   := '01';                         -- �t�H�[�L���X�g���ށF����v��
  cv_flv_lookup_type            CONSTANT VARCHAR2(100) := 'XXCOP1_DIVISION_TARGET_BASE';-- �N�C�b�N�R�[�h�F�����Ώۋ��_
  cv_flv_language               CONSTANT VARCHAR2(2)   := USERENV('LANG');
  cv_flv_enabled_flag           CONSTANT VARCHAR2(1)   := 'Y';
  cv_customer_class_code_base   CONSTANT VARCHAR2(1)   := '1';                -- �ڋq�敪�i���_�j
  cv_leaf_whse_code             CONSTANT VARCHAR2(5)   := '12020';            -- ذ̥���Ǒq��
  cv_drink_whse_code            CONSTANT VARCHAR2(5)   := '22100';            -- ���ݸ�������
  cv_inactive_ind               CONSTANT VARCHAR2(1)   := '1';                -- ����
  cv_inventory_item_status_code CONSTANT VARCHAR2(20)  := 'Inactive';         -- �i�ڃX�e�[�^�X
  cv_obsolete_class             CONSTANT VARCHAR2(1)   := '1';                -- �p�~�敪
  cv_no_shipment_results        CONSTANT VARCHAR2(1)   := '*';                -- �o�׎��тȂ�
  cv_schedule_type              CONSTANT VARCHAR2(1)   := '1';                -- �v��敪
  -- �����\���\�f�[�^�x���敪
  cv_srwt_0                     CONSTANT VARCHAR2(1)   := '0';                -- ����
  cv_srwt_1                     CONSTANT VARCHAR2(1)   := '1';                -- �����ΏۊO�F�����\���\�q�ɕs��v
  cv_srwt_2                     CONSTANT VARCHAR2(1)   := '2';                -- �����ΏۊO�F�����\���\������
  cv_srwt_3                     CONSTANT VARCHAR2(1)   := '3';                -- �����ΏہF�����\���\��
  cv_srwt_4                     CONSTANT VARCHAR2(1)   := '4';                -- �����ΏہF�����\���\�L(���v���ѐ����j
  -- �W�v�J�n���F���t
  cv_week_day_1                 CONSTANT VARCHAR2(2)   := '07';               -- �P�T�ځF�J�n���t
  cv_week_day_2                 CONSTANT VARCHAR2(2)   := '14';               -- �Q�T�ځF�J�n���t
  cv_week_day_3                 CONSTANT VARCHAR2(2)   := '21';               -- �R�T�ځF�J�n���t
  -- �v�揤�i�t���O�u���p
 cv_planed_item_flg_0           CONSTANT VARCHAR2(1)   := '0';
 cv_planed_item_flg_1           CONSTANT VARCHAR2(1)   := '1';
 cv_planed_item_flg_null        CONSTANT VARCHAR2(1)   := NULL;

  -- ���b�Z�[�W�֘A
  cv_msg_application            CONSTANT VARCHAR2(100) := 'XXCOP';
  cv_param_chk_msg1             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00025';
  cv_param_chk_msg1_tkn_lbl1    CONSTANT VARCHAR2(100) := 'PERIOD_FROM';
  cv_param_chk_msg1_tkn_lbl2    CONSTANT VARCHAR2(100) := 'PERIOD_TO';
  cv_param_chk_msg1_tkn_val1_1  CONSTANT VARCHAR2(100) := '���ю��W���ԁiFROM�j';
  cv_param_chk_msg1_tkn_val2_1  CONSTANT VARCHAR2(100) := '���ю��W���ԁiTO�j';
  cv_param_chk_msg1_tkn_val1_2  CONSTANT VARCHAR2(100) := '�v����W���ԁiFROM�j';
  cv_param_chk_msg1_tkn_val2_2  CONSTANT VARCHAR2(100) := '�v����W���ԁiTO�j';
  cv_param_chk_msg2             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00047';
  cv_param_chk_msg2_tkn_lbl1    CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_param_chk_msg2_tkn_val1_1  CONSTANT VARCHAR2(100) := '���ю��W���ԁiFROM�j';
  cv_param_chk_msg2_tkn_val1_2  CONSTANT VARCHAR2(100) := '���ю��W���ԁiTO�j';
  cv_param_chk_msg3             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10009';
  cv_param_chk_msg3_tkn_lbl1    CONSTANT VARCHAR2(100) := 'ITEM_NAME';
  cv_param_chk_msg3_tkn_val1_1  CONSTANT VARCHAR2(100) := '�v����W���ԁiFROM�j';
  cv_param_chk_msg3_tkn_val1_2  CONSTANT VARCHAR2(100) := '�v����W���ԁiTO�j';
  cv_param_chk_msg4             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';
  cv_param_chk_msg4_tkn_lbl1    CONSTANT VARCHAR2(100) := 'PROF_NAME';
  cv_param_chk_msg4_tkn_val1    CONSTANT VARCHAR2(100) := '���ю��W����';
  cv_ins_err_msg                CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';
  cv_ins_err_msg_tkn_lbl1       CONSTANT VARCHAR2(100) := 'TABLE';
  cv_ins_err_msg_tkn_val1       CONSTANT VARCHAR2(100) := '����v��W�v���[�N�e�[�u��';
  cv_others_err_msg             CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00041';
  cv_others_err_msg_tkn_lbl1    CONSTANT VARCHAR2(100) := 'ERRMSG';
  cv_norules1_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10001';
  cv_norules1_err_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'ITEM';
  cv_norules1_err_msg_tkn_lbl2  CONSTANT VARCHAR2(100) := 'BASE';
--��v1.1 Upd Start
  cv_norules1_err_msg_tkn_lbl3  CONSTANT VARCHAR2(100) := 'WHSE';
--��  cv_norules1_err_msg_tkn_lbl3  CONSTANT VARCHAR2(100) := 'YYYYMMDD';
--��  cv_norules1_err_msg_tkn_lbl4  CONSTANT VARCHAR2(100) := 'WHSE';
--��v1.1 Upd End
  cv_norules2_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10005';
  cv_norules2_err_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'ITEM';
  cv_norules2_err_msg_tkn_lbl2  CONSTANT VARCHAR2(100) := 'BASE';
--��v1.1 Del  cv_norules2_err_msg_tkn_lbl3  CONSTANT VARCHAR2(100) := 'FROM';
--��v1.1 Del  cv_norules2_err_msg_tkn_lbl4  CONSTANT VARCHAR2(100) := 'TO';
  cv_noresult_note_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10010';

  -- CSV�o�͗p
  cv_csv_part                   CONSTANT VARCHAR2(1)   := '"';
  cv_csv_cont                   CONSTANT VARCHAR2(1)   := ',';
  cv_csv_header1                CONSTANT VARCHAR2(100) := '�v��敪';
  cv_csv_header2                CONSTANT VARCHAR2(100) := '�o�בq��';
  cv_csv_header3                CONSTANT VARCHAR2(100) := '���i�敪';
  cv_csv_header4                CONSTANT VARCHAR2(100) := '�i�ڃR�[�h';
  cv_csv_header5                CONSTANT VARCHAR2(100) := '�W�v����(FROM)';
  cv_csv_header6                CONSTANT VARCHAR2(100) := '�W�v����(TO)';
  cv_csv_header7                CONSTANT VARCHAR2(100) := '���搔�ʍ��v';
  cv_csv_header8                CONSTANT VARCHAR2(100) := '�v�揤�i�t���O';
  cv_csv_header9                CONSTANT VARCHAR2(100) := '�o�׎��тȂ�';
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ����v��W�v���R�[�h�^�i�����Ώۋ��_�|�Ǘ������_�P�ʁj
  TYPE frcst_base_total1_trec IS RECORD(
      schedule_type        xxcop_wk_forecast_totaling.schedule_type      %TYPE    -- �v��敪
    , management_base_code xxcop_wk_forecast_totaling.base_code          %TYPE    -- �Ǘ������_
    , forecast_whse_code   xxcop_wk_forecast_totaling.whse_code          %TYPE    -- �t�H�[�L���X�g�o�בq��
    , prod_class           xxcop_wk_forecast_totaling.prod_class         %TYPE    -- ���i�敪
    , item_code            xxcop_wk_forecast_totaling.item_code          %TYPE    -- �i�ڃR�[�h
    , count_period_from    xxcop_wk_forecast_totaling.count_period_from  %TYPE    -- �W�v����From
    , count_period_to      xxcop_wk_forecast_totaling.count_period_to    %TYPE    -- �W�v����To
    , forecast_qty         NUMBER                                                 -- �Ǘ������_�W�v�F����v�搔��
    , ship_result_qty      NUMBER                                                 -- �Ǘ������_�W�v�F�o�׎��ѐ���
    );

  -- ����v��W�vPL/SQL�\�i�����Ώۋ��_�|�Ǘ������_�P�ʁj
  TYPE frcst_base_total1_ttype IS
    TABLE OF frcst_base_total1_trec INDEX BY BINARY_INTEGER;

  -- ����v��W�v���R�[�h�^�i�����Ώۋ��_�|�z�����_�P�ʁj
  TYPE frcst_base_total2_trec IS RECORD(
      whse_code                xxcop_wk_forecast_totaling.whse_code               %TYPE  -- �q��
    , planed_item_flg          xxcop_wk_forecast_totaling.planed_item_flg         %TYPE  -- �v�揤�i�t���O
    , no_shipment_results      xxcop_wk_forecast_totaling.no_shipment_results     %TYPE  -- �o�׎��тȂ�
    , sourcing_rules_warn_type xxcop_wk_forecast_totaling.sourcing_rules_warn_type%TYPE  -- �����\���\�f�[�^�x���敪
    , base_code                xxcop_wk_forecast_totaling.base_code               %TYPE  -- �z�����_
    , ship_result_qty          NUMBER                                                    -- �o�בq�ɏW�v�F�o�׎��ѐ���
    );

  -- ����v��W�vPL/SQL�\�i�����Ώۋ��_�|�z�����_�P�ʁj
  TYPE frcst_base_total2_ttype IS
    TABLE OF frcst_base_total2_trec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���̓p�����[�^�i�[�p�ϐ�
  gv_base_code                   VARCHAR2(4);              -- 1.���_
  gv_prod_class_code             VARCHAR2(1);              -- 2.���i�敪
  gd_results_collect_period_st   DATE;                     -- 3.���ю��W���ԁi���j
  gd_results_collect_period_ed   DATE;                     -- 4.���ю��W���ԁi���j
  gd_forecast_collect_period_st  DATE;                     -- 5.�v����W���ԁi���j
  gd_forecast_collect_period_ed  DATE;                     -- 6.�v����W���ԁi���j
  
  -- ��������p�ϐ�
  gd_sysdate                     DATE;                     -- �V�X�e�����t
  gd_totaling_start_date         DATE;                     -- �W�v�J�n��
  gd_totaling_end_date           DATE;                     -- �W�v�I����
  g_frcst_base_total_tbl1        frcst_base_total1_ttype;  -- ����v��W�vPL/SQL�\�i�����Ώۋ��_�|�Ǘ����z�����_�P�ʁj
  g_frcst_base_total_tbl1_init   frcst_base_total1_ttype;  -- �������p
  g_frcst_base_total_tbl2        frcst_base_total2_ttype;  -- ����v��W�vPL/SQL�\�i�����Ώۋ��_�|�z�����_�P�ʁj
  g_frcst_base_total_tbl2_init   frcst_base_total2_ttype;  -- �������p
  gn_base_total_amount           NUMBER;                   -- �Ǘ������_�P�� ���ѐ��ʉ��Z
  gn_internal_warn_cnt           NUMBER;                   -- �����x������
  gn_noresults_cnt               NUMBER;                   -- �o�׎��тȂ�����

  -- �f�o�b�O�p
  gv_debug_mode                  VARCHAR2(30);
--
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    --------------------------------------------------------
    -- 1.���t�t�]�`�F�b�N
    --------------------------------------------------------
    --(1)���ю��W����
    IF (gd_results_collect_period_st > gd_results_collect_period_ed) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_param_chk_msg1
                    ,iv_token_name1  => cv_param_chk_msg1_tkn_lbl1
                    ,iv_token_value1 => cv_param_chk_msg1_tkn_val1_1
                    ,iv_token_name2  => cv_param_chk_msg1_tkn_lbl2
                    ,iv_token_value2 => cv_param_chk_msg1_tkn_val2_1
                   );
      RAISE internal_process_expt;
    END IF;

    --(2)�v����W����
    IF (gd_forecast_collect_period_st > gd_forecast_collect_period_ed) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_param_chk_msg1
                    ,iv_token_name1  => cv_param_chk_msg1_tkn_lbl1
                    ,iv_token_value1 => cv_param_chk_msg1_tkn_val1_2
                    ,iv_token_name2  => cv_param_chk_msg1_tkn_lbl2
                    ,iv_token_value2 => cv_param_chk_msg1_tkn_val2_2
                   );
      RAISE internal_process_expt;
    END IF;

    --------------------------------------------------------
    -- 2.�������`�F�b�N
    --------------------------------------------------------
    --(1)���ю��W���ԁi���j
    IF  (gd_results_collect_period_st > gd_sysdate) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_param_chk_msg2
                    ,iv_token_name1  => cv_param_chk_msg2_tkn_lbl1
                    ,iv_token_value1 => cv_param_chk_msg2_tkn_val1_1
                   );
      RAISE internal_process_expt;
    END IF;

    --(2)���ю��W���ԁi���j
    IF  (TRUNC(gd_results_collect_period_ed) > gd_sysdate) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_param_chk_msg2
                    ,iv_token_name1  => cv_param_chk_msg2_tkn_lbl1
                    ,iv_token_value1 => cv_param_chk_msg2_tkn_val1_2
                   );
      RAISE internal_process_expt;
    END IF;

    --------------------------------------------------------
    -- 3.�ߋ����`�F�b�N
    --------------------------------------------------------
    --(1)�v����W���ԁi���j
    IF  (gd_forecast_collect_period_st < gd_sysdate) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_param_chk_msg3
                    ,iv_token_name1  => cv_param_chk_msg3_tkn_lbl1
                    ,iv_token_value1 => cv_param_chk_msg3_tkn_val1_1
                   );
      RAISE internal_process_expt;
    END IF;

    --(2)�v����W���ԁi���j
    IF  (TRUNC(gd_forecast_collect_period_ed) < gd_sysdate) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_param_chk_msg3
                    ,iv_token_name1  => cv_param_chk_msg3_tkn_lbl1
                    ,iv_token_value1 => cv_param_chk_msg3_tkn_val1_2
                   );
      RAISE internal_process_expt;
    END IF;

    --------------------------------------------------------
    -- 4.WHO���擾
    --   ���ϐ���`���Őݒ�ς�
    --------------------------------------------------------
    NULL;
--
  EXCEPTION
    WHEN internal_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : insert_whse_totaling
   * Description      : �����ΏۊO���_ �o�בq�ɏW�v�f�[�^�o�^(A-3,A-4)
   *                    �Ώۃf�[�^���o�i�o�בq�ɏW�v�j(A-3)
   *                    ���[�N�e�[�u���o�^(A-4)
   *                    �������ȗ����ׁ̈AINSERT�`SELECT�ɕύX
   ***********************************************************************************/
  PROCEDURE insert_whse_totaling(
     ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_whse_totaling'; -- �v���O������
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
    -----------------------------------------------------------
    -- ����v��W�v���[�N�e�[�u���o�^
    --  �i�����ΏۊO���_ �i�ځA���_�A�o�בq�ɒP�ʏW�v�j
    -----------------------------------------------------------
    INSERT
    INTO   xxcop_wk_forecast_totaling(
        schedule_type                               -- �v��敪
      , whse_code                                   -- �o�בq��
      , prod_class                                  -- ���i�敪
      , item_code                                   -- �i�ڃR�[�h
      , count_period_from                           -- �W�v����From
      , count_period_to                             -- �W�v����To
      , total_amount                                -- ���搔�ʍ��v
      , planed_item_flg                             -- �v�揤�i�t���O
      , no_shipment_results                         -- �o�׎��тȂ�
      , sourcing_rules_warn_type                    -- �����\���\�f�[�^�x���敪
      , base_code                                   -- ���_
      , forecast_date                               -- �t�H�[�L���X�g���t
      , created_by                                  -- �쐬��
      , creation_date                               -- �쐬��
      , last_updated_by                             -- �ŏI�X�V��
      , last_update_date                            -- �ŏI�X�V��
      , last_update_login                           -- �ŏI�X�V���O�C��
      , request_id                                  -- �v��ID
      , program_application_id                      -- �v���O�����A�v���P�[�V����ID
      , program_id                                  -- �v���O����ID
      , program_update_date                         -- �v���O�����X�V��
      )
    SELECT
        cv_schedule_type                     schedule_type                            -- �v��敪�F�o�ח\��
      , DECODE( v1.prod_class_code||v1.whse_code
                        ,v1.prod_class_code||xsr.delivery_whse_code ,v1.whse_code
                        ,cv_leaf_whse_code                          ,NVL(xsr.delivery_whse_code,v1.whse_code)
                        ,cv_drink_whse_code                         ,NVL(xsr.delivery_whse_code,v1.whse_code)
                                                                    ,v1.whse_code
              ) whse_code                                                             -- �o�׊Ǘ���R�[�h
      , v1.prod_class_code                   prod_class                               -- ���i�敪
      , v1.item_no                           item_code                                -- �i�ڃR�[�h
      , gd_totaling_start_date               count_period_from                        -- �W�v�J�n��
      , gd_totaling_end_date                 count_period_to                          -- �W�v�I����
      , v1.original_forecast_quantity        total_amount                             -- ����
      , DECODE( v1.prod_class_code||v1.whse_code
                        ,v1.prod_class_code||xsr.delivery_whse_code ,xsr.plan_item_flag
                        ,cv_leaf_whse_code                 ,NVL2(xsr.delivery_whse_code,xsr.plan_item_flag,null)
                        ,cv_drink_whse_code                ,NVL2(xsr.delivery_whse_code,xsr.plan_item_flag,null)
                                                           ,null
              ) planed_item_flg                                                       -- �v�揤�i�t���O
      , NULL                                 no_shipment_results                      -- �o�׎��тȂ�
      , DECODE( v1.prod_class_code||v1.whse_code
                        ,v1.prod_class_code||xsr.delivery_whse_code ,cv_srwt_0
                        ,cv_leaf_whse_code                          ,NVL2(xsr.delivery_whse_code,cv_srwt_0,cv_srwt_2)
                        ,cv_drink_whse_code                         ,NVL2(xsr.delivery_whse_code,cv_srwt_0,cv_srwt_2)
                                                                    ,NVL2(xsr.delivery_whse_code,cv_srwt_1,cv_srwt_2)
              ) sourcing_rules_warn_type                                              -- �����\���\�f�[�^�x���敪
      , v1.base_code                 base_code                                        -- ���_
      , v1.forecast_date             forecast_date                                    -- �t�H�[�L���X�g���t
      , cn_created_by                created_by                                       -- �쐬��
      , cd_creation_date             creation_date                                    -- �쐬��
      , cn_last_updated_by           last_updated_by                                  -- �ŏI�X�V��
      , cd_last_update_date          last_update_date                                 -- �ŏI�X�V��
      , cn_last_update_login         last_update_login                                -- �ŏI�X�V���O�C��
      , cn_request_id                request_id                                       -- �v��ID
      , cn_program_application_id    program_application_id                           -- �v���O�����A�v���P�[�V����ID
      , cn_program_id                program_id                                       -- �v���O����ID
      , cd_program_update_date       program_update_date                              -- �v���O�����X�V��
     FROM
     ( SELECT
           mfde.attribute3                 base_code                                  -- ���_
         , mfde.attribute2                 whse_code                                  -- �o�׊Ǘ���R�[�h
         , xic1v.prod_class_code           prod_class_code                            -- ���i�敪
         , xic1v.item_no                   item_no                                    -- �i�ڃR�[�h
         , mfda.original_forecast_quantity original_forecast_quantity                 -- ����
         , mfda.forecast_date              forecast_date                              -- �t�H�[�L���X�g���t
       FROM
              mrp_forecast_designators mfde                                           -- �t�H�[�L���X�g��
         ,    mrp_forecast_dates       mfda                                           -- �t�H�[�L���X�g���t
         ,    xxcop_item_categories1_v xic1v                                          -- �v��_�i�ڃJ�e�S���r���[1
       WHERE
              mfde.forecast_designator         =  mfda.forecast_designator            -- �t�H�[�L���X�g��
       AND    mfde.organization_id             =  mfda.organization_id                -- �g�DID
       AND    mfde.attribute1                  =  cv_forecast_class                   -- FORECAST���ށF����v��
       AND    mfde.attribute3                  =  NVL(gv_base_code,mfde.attribute3)   -- ���_�R�[�h
       AND    mfda.forecast_date               BETWEEN gd_totaling_start_date
                                               AND     gd_totaling_end_date
       AND    xic1v.inventory_item_id          =  mfda.inventory_item_id
       AND    xic1v.start_date_active          <= mfda.forecast_date
       AND    xic1v.end_date_active            >= mfda.forecast_date
       AND    xic1v.prod_class_code            =  gv_prod_class_code                  -- ���i�敪
       AND    xic1v.inactive_ind               <> cv_inactive_ind                     -- ����
       AND    xic1v.inventory_item_status_code <> cv_inventory_item_status_code       -- �i�ڃX�e�[�^�X
       AND    xic1v.obsolete_class             <> cv_obsolete_class                   -- �p�~�敪
       AND    NOT EXISTS(                         
                SELECT 'X'
                FROM   fnd_lookup_values                                              -- �N�C�b�N�R�[�h
                WHERE  lookup_type  = cv_flv_lookup_type
                AND    language     = cv_flv_language
                AND    description  = mfde.attribute3
                AND    enabled_flag = cv_flv_enabled_flag
                AND    mfda.forecast_date  BETWEEN NVL(start_date_active ,mfda.forecast_date)
                                               AND NVL(end_date_active   ,mfda.forecast_date)
             )
     )v1
       ,    xxcmn_sourcing_rules   xsr                                                -- �����\���\�A�h�I��
     WHERE  xsr.item_code         (+)    =  v1.item_no                                -- �i�ڃR�[�h
     AND    xsr.base_code         (+)    =  v1.base_code                              -- ���_
     AND    xsr.start_date_active (+)    <= v1.forecast_date                          -- �K�p�J�n��
     AND    xsr.end_date_active   (+)    >= v1.forecast_date                          -- �K�p�I����
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
      --�����[�U�G���[���b�Z�[�W�ǉ���
      ov_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_ins_err_msg
                    ,iv_token_name1  => cv_ins_err_msg_tkn_lbl1
                    ,iv_token_value1 => cv_ins_err_msg_tkn_val1
                    );
      --�����[�U�G���[���b�Z�[�W�ǉ���
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_whse_totaling;
--
  /**********************************************************************************
   * Procedure Name   : get_management_forcast_total
   * Description      : �����Ώۋ��_ �Ǘ������_�v�搔�ʏW�v�f�[�^���o�iA-5�j
   ***********************************************************************************/
  PROCEDURE get_management_forcast_total(
     ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_management_forcast_total'; -- �v���O������
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
    --  �����Ώۋ��_ �Ǘ������_���o
    --   �Ǘ������_�ɕR�t���S���_�̌v�搔�ʂ��A
    --   �i�ځA�Ǘ������_�P�ʂɏW�v����B
    ------------------------------------------------------------
    SELECT cv_schedule_type                            schedule_type                 -- �v��敪�F�o�ח\��
       ,   mfde.attribute3                             management_base_code          -- �Ǘ������_
       ,   mfde.attribute2                             forecast_whse_code            -- �o�בq��
       ,   xic1v.prod_class_code                       prod_class_code               -- ���i�敪
       ,   xic1v.item_no                               item_no                       -- �i�ڃR�[�h
       ,   gd_totaling_start_date                      totaling_start_date           -- �W�v�J�n��
       ,   gd_totaling_end_date                        totaling_end_date             -- �W�v�I����
       ,   SUM(NVL(mfda.original_forecast_quantity,0)) original_forecast_quantity    -- ����v�搔��
       ,   NULL
    BULK COLLECT
    INTO 
           g_frcst_base_total_tbl1
    FROM   mrp_forecast_designators mfde                                           -- �t�H�[�L���X�g��
      ,    mrp_forecast_dates       mfda                                           -- �t�H�[�L���X�g���t
      ,    xxcop_item_categories1_v xic1v                                          -- �v��_�i�ڃJ�e�S���r���[1
    WHERE
           mfde.forecast_designator         =  mfda.forecast_designator            -- �t�H�[�L���X�g��
    AND    mfde.organization_id             =  mfda.organization_id                -- �g�DID
    AND    mfde.attribute1                  =  cv_forecast_class
    AND    mfde.attribute3                  =  NVL(gv_base_code,mfde.attribute3)
    AND    mfda.forecast_date               BETWEEN gd_totaling_start_date
                                            AND     gd_totaling_end_date
    AND    xic1v.inventory_item_id          =  mfda.inventory_item_id
    AND    xic1v.start_date_active          <= mfda.forecast_date
    AND    xic1v.end_date_active            >= mfda.forecast_date
    AND    xic1v.prod_class_code            =  gv_prod_class_code
    AND    xic1v.inactive_ind               <> cv_inactive_ind                     -- ����
    AND    xic1v.inventory_item_status_code <> cv_inventory_item_status_code       -- �i�ڃX�e�[�^�X
    AND    xic1v.obsolete_class             <> cv_obsolete_class                   -- �p�~�敪
    AND    EXISTS(
             SELECT 'X'
             FROM   fnd_lookup_values                                              -- �N�C�b�N�R�[�h�\
             WHERE  lookup_type  = cv_flv_lookup_type
             AND    language     = cv_flv_language
             AND    description  = mfde.attribute3
             AND    enabled_flag = cv_flv_enabled_flag
             AND    mfda.forecast_date   BETWEEN NVL(start_date_active ,mfda.forecast_date)
                                             AND NVL(end_date_active   ,mfda.forecast_date)
           )
    GROUP
    BY     mfde.attribute3
      ,    mfde.attribute2
      ,    xic1v.prod_class_code
      ,    xic1v.item_no
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
  END get_management_forcast_total;
--
--
  /**********************************************************************************
   * Procedure Name   : get_management_result_total
   * Description      : �����Ώۋ��_ �Ǘ������_���ѐ��ʏW�v�f�[�^���o�iA-6�j
   ***********************************************************************************/
  PROCEDURE get_management_result_total(
     in_index             IN  NUMBER      --   �Ǘ������_�W�v�f�[�^���o���[�vIndex
   , ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_management_result_total'; -- �v���O������
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
    --  �Ǘ������_���ѐ��ʏW�v�f�[�^���o
    --   A-5�Ŏ擾�����i�ځA�Ǘ������_���ɁA
    --   �Ǘ������_�ɕR�t���S���_�A�S�q�ɂ̎��ѐ��ʂ��W�v����B
    ------------------------------------------------------------
    SELECT  
            SUM(NVL(xsrst.quantity,0))         quantity                                -- �o�׎��ѐ���
    INTO 
            g_frcst_base_total_tbl1(in_index).ship_result_qty                          -- �Ǘ������_�W�v�F�o�׎��ѐ���
    FROM( 
      SELECT    v1.management_base_code        management_base_code                    -- �Ǘ������_
              , v1.base_code                   base_code                               -- �z�����_
              , v1.item_no                     item_no                                 -- �i�ڃR�[�h
              , xsr.delivery_whse_code         delivery_whse_code                      -- �q��
      FROM(
        SELECT
               mfde.attribute3                 management_base_code                    -- �Ǘ������_
          ,    hca.account_number              base_code                               -- �z�����_
          ,    xic1v.item_no                   item_no                                 -- �i�ڃR�[�h
          ,    mfda.forecast_date              forecast_date                           -- �t�H�[�L���X�g���t
        FROM
               mrp_forecast_designators mfde                                           -- �t�H�[�L���X�g��
          ,    mrp_forecast_dates       mfda                                           -- �t�H�[�L���X�g���t
          ,    xxcop_item_categories1_v xic1v                                          -- �v��_�i�ڃJ�e�S���r���[1
          ,    xxcmm_cust_accounts      xca                                            -- �ڋq�ǉ����
          ,    hz_cust_accounts         hca                                            -- �ڋq�}�X�^
        WHERE
               mfde.forecast_designator         =  mfda.forecast_designator            -- �t�H�[�L���X�g��
        AND    mfde.organization_id             =  mfda.organization_id                -- �g�DID
        AND    mfde.attribute1                  =  cv_forecast_class
        AND    mfde.attribute2                  =  g_frcst_base_total_tbl1(in_index).forecast_whse_code
        AND    mfde.attribute3                  =  g_frcst_base_total_tbl1(in_index).management_base_code
        AND    mfda.forecast_date               BETWEEN gd_totaling_start_date
                                                AND     gd_totaling_end_date
        AND    xic1v.inventory_item_id          =  mfda.inventory_item_id
        AND    xic1v.item_no                    =  g_frcst_base_total_tbl1(in_index).item_code
        AND    xic1v.start_date_active          <= mfda.forecast_date
        AND    xic1v.end_date_active            >= mfda.forecast_date
        AND    xic1v.prod_class_code            =  gv_prod_class_code
        AND    xic1v.inactive_ind               <> cv_inactive_ind                     -- ����
        AND    xic1v.inventory_item_status_code <> cv_inventory_item_status_code       -- �i�ڃX�e�[�^�X
        AND    xic1v.obsolete_class             <> cv_obsolete_class                   -- �p�~�敪
        AND    (   xca.management_base_code     =  mfde.attribute3
               OR  hca.account_number           =  mfde.attribute3  )
        AND    hca.cust_account_id              =  xca.customer_id
        AND    hca.customer_class_code          =  cv_customer_class_code_base         -- �ڋq�敪
      )v1
        ,    xxcmn_sourcing_rules     xsr                                -- �����\���\�A�h�I��
      WHERE  xsr.item_code             (+) =  v1.item_no
      AND    xsr.base_code             (+) =  v1.base_code
      AND    xsr.start_date_active     (+) <= v1.forecast_date
      AND    xsr.end_date_active       (+) >= v1.forecast_date
      GROUP
      BY  v1.management_base_code                                              -- �Ǘ������_
        , v1.base_code                                                         -- �z�����_
        , v1.item_no                                                           -- �i�ڃR�[�h
        , xsr.delivery_whse_code                                               -- �q��
    )v2
      ,    xxcop_shipment_results   xsrst                                      -- �e�R�[�h�o�׎��ѕ\
    WHERE  xsrst.item_no             (+) =  v2.item_no
    AND    xsrst.base_code           (+) =  v2.base_code
    AND    xsrst.latest_deliver_from (+) =  v2.delivery_whse_code
    AND    xsrst.shipment_date       (+) BETWEEN gd_results_collect_period_st
                                         AND     gd_results_collect_period_ed
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
  END get_management_result_total;
--
  /**********************************************************************************
   * Procedure Name   : get_whse_totaling
   * Description      : �����Ώۋ��_ �Ǘ����o�בq�ɕʎ��ѐ��ʃf�[�^���o(A-7)
   ***********************************************************************************/
  PROCEDURE get_whse_totaling(
     in_index             IN  NUMBER      --   �Ǘ������_�W�v�f�[�^���o���[�vIndex
   , ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_whse_totaling'; -- �v���O������
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
    -- �o�בq�ɕʏo�׎��ђ��o
    --  �Ǘ������_�ɕR�t�����_���畨���\���\���o�בq�ɂ���肵�A
    --  ���̋��_�A�q�ɒP�ʂŎ��ѐ��ʂ��W�v����
    -----------------------------------------------------------------
    SELECT  
            v2.delivery_whse_code                           delivery_whse_code            -- �o�בq��
       ,    SUBSTRB(TO_CHAR(v2.plan_item_flag),9,1)         plan_item_flag                -- �v�揤�i�t���O
       ,    NVL2(xsrst.item_no,NULL,cv_no_shipment_results) no_shipment_results           -- �o�׎��тȂ�
       ,    v2.sourcing_rules_warn_type                     sourcing_rules_warn_type      -- �����\���\�f�[�^�x���敪
       ,    v2.base_code                                    base_code                     -- �z�����_
       ,    SUM(NVL(xsrst.quantity,0))                      quantity                      -- �o�׎��ѐ���
    BULK COLLECT
    INTO 
           g_frcst_base_total_tbl2
    FROM( 
      SELECT v1.management_base_code           management_base_code      -- �Ǘ������_
           , v1.item_no                        item_no                   -- �i�ڃR�[�h
           , v1.base_code                      base_code                 -- �z�����_
           , xsr.delivery_whse_code            delivery_whse_code        -- �q��
           , MAX(TO_CHAR(v1.forecast_date,cv_date_format6)
             ||xsr.plan_item_flag) plan_item_flag                        -- �v�揤�i�t���O
           , NVL2(xsr.delivery_whse_code
                       ,DECODE(g_frcst_base_total_tbl1(in_index).ship_result_qty ,0 ,cv_srwt_4
                                                                                    ,cv_srwt_0)
                       ,cv_srwt_3
                                            )  sourcing_rules_warn_type  -- �����\���\�f�[�^�x���敪
      FROM(
        SELECT
               mfde.attribute3                 management_base_code                    -- �Ǘ������_
          ,    hca.account_number              base_code                               -- �z�����_
          ,    xic1v.item_no                   item_no                                 -- �i�ڃR�[�h
          ,    mfda.forecast_date              forecast_date                           -- �t�H�[�L���X�g���t
        FROM
               mrp_forecast_designators mfde                                           -- �t�H�[�L���X�g��
          ,    mrp_forecast_dates       mfda                                           -- �t�H�[�L���X�g���t
          ,    xxcop_item_categories1_v xic1v                                          -- �v��_�i�ڃJ�e�S���r���[1
          ,    xxcmm_cust_accounts      xca                                            -- �ڋq�ǉ����
          ,    hz_cust_accounts         hca                                            -- �ڋq�}�X�^
        WHERE
               mfde.forecast_designator         =  mfda.forecast_designator            -- �t�H�[�L���X�g��
        AND    mfde.organization_id             =  mfda.organization_id                -- �g�DID
        AND    mfde.attribute1                  =  cv_forecast_class
        AND    mfde.attribute2                  =  g_frcst_base_total_tbl1(in_index).forecast_whse_code
        AND    mfde.attribute3                  =  g_frcst_base_total_tbl1(in_index).management_base_code
        AND    mfda.forecast_date               BETWEEN gd_totaling_start_date
                                                AND     gd_totaling_end_date
        AND    xic1v.inventory_item_id          =  mfda.inventory_item_id
        AND    xic1v.item_no                    =  g_frcst_base_total_tbl1(in_index).item_code
        AND    xic1v.start_date_active          <= mfda.forecast_date
        AND    xic1v.end_date_active            >= mfda.forecast_date
        AND    xic1v.prod_class_code            =  gv_prod_class_code
        AND    xic1v.inactive_ind               <> cv_inactive_ind                     -- ����
        AND    xic1v.inventory_item_status_code <> cv_inventory_item_status_code       -- �i�ڃX�e�[�^�X
        AND    xic1v.obsolete_class             <> cv_obsolete_class                   -- �p�~�敪
        AND    (   xca.management_base_code     =  mfde.attribute3
               OR  hca.account_number           =  mfde.attribute3  )
        AND    hca.cust_account_id              =  xca.customer_id
        AND    hca.customer_class_code          =  cv_customer_class_code_base         -- �ڋq�敪
      )v1
        ,    xxcmn_sourcing_rules     xsr                                -- �����\���\�A�h�I��
      WHERE  xsr.item_code             (+) =  v1.item_no
      AND    xsr.base_code             (+) =  v1.base_code
      AND    xsr.start_date_active     (+) <= v1.forecast_date
      AND    xsr.end_date_active       (+) >= v1.forecast_date
      GROUP
      BY     v1.management_base_code
           , v1.item_no
           , v1.base_code
           , xsr.delivery_whse_code
           , NVL2(xsr.delivery_whse_code
                       ,DECODE(g_frcst_base_total_tbl1(in_index).ship_result_qty ,0 ,cv_srwt_4
                                                                                    ,cv_srwt_0)
                       ,cv_srwt_3
                 )
    )v2
      ,    xxcop_shipment_results   xsrst                                      -- �e�R�[�h�o�׎��ѕ\
    WHERE  xsrst.item_no             (+) =  v2.item_no
    AND    xsrst.base_code           (+) =  v2.base_code
    AND    xsrst.latest_deliver_from (+) =  v2.delivery_whse_code
    AND    xsrst.shipment_date       (+) BETWEEN gd_results_collect_period_st
                                         AND     gd_results_collect_period_ed
    GROUP
    BY      v2.delivery_whse_code                                                 -- �o�בq��
       ,    SUBSTRB(TO_CHAR(v2.plan_item_flag),9,1)                               -- �v�揤�i�t���O
       ,    NVL2(xsrst.item_no,NULL,cv_no_shipment_results)                       -- �o�׎��тȂ�
       ,    v2.sourcing_rules_warn_type                                           -- �����\���\�f�[�^�x���敪
       ,    v2.base_code                                                          -- �z�����_
    ORDER
    BY     DECODE(SUM(NVL(xsrst.quantity,0)),0,0
                                              ,1 )                                -- ���ʃ[�����Ƀ\�[�g����
      ,    v2.delivery_whse_code                                                  -- �o�וۊǑq�ɃR�[�h
      ,    v2.base_code                                                           -- �z�����_
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
  END get_whse_totaling;
--
--
  /**********************************************************************************
   * Procedure Name   : insert_base_totaling
   * Description      : �����Ώۋ��_ ����v�搔�ʈ��f�[�^�o�^(A-8,A-9)
   *                    ����v�搔��(A-8)
   *                    ����v��W�v(��)���[�N�e�[�u���o�^(A-9)
   *                    �������ȗ����ׁ̈AA-8,A-9�𓝍�
   ***********************************************************************************/
  PROCEDURE insert_base_totaling(
     in_index             IN  NUMBER      --   �Ǘ������_�W�v�f�[�^���o���[�vIndex
   , in_index2            IN  NUMBER      --   �z�����_�E�o�בq�ɕʏo�׎��ђ��o���[�vIndex
   , ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_base_totaling'; -- �v���O������
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
    xxcop_wk_forecast_totaling_rec    xxcop_wk_forecast_totaling%rowtype;
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
    IF (in_index2 IS NOT NULL) THEN

      -- �o�בq�ɒP�ʎ��ѐ��ʍ����[�����傫���ꍇ�݈̂����s�Ȃ�
      IF (g_frcst_base_total_tbl2(in_index2).ship_result_qty > 0) THEN

        -- �Ǘ������_�P�ʂł̈��̗]����Z�b�g����ׁA
        -- �ŏI���R�[�h�ɊǗ������_�P�ʎ��ѐ��ʍ��v�|���݂܂ł̃g�[�^�����ʂ��Z�b�g����B
        -- �i�����s�Ȃ�Ȃ����ѐ��ʁ��[���̃f�[�^���\�[�g���Ō���Ɏ����Ă��Ă���j
        IF (g_frcst_base_total_tbl2.COUNT = in_index2) THEN
          xxcop_wk_forecast_totaling_rec.total_amount
                               := g_frcst_base_total_tbl1(in_index).forecast_qty - gn_base_total_amount;

        -- �ŏI���R�[�h�Ŗ����ꍇ�́A
        -- �Ǘ������_�P�ʈ���v�搔�ʍ��v�~���䗦�i�z�����_�E�q�ɒP�ʎ��ѐ��ʍ��v���Ǘ������_�P�ʎ��ѐ��ʍ��v�j
        -- ���s���A�������͐؎̂Ă��s�Ȃ��B
        ELSE
          xxcop_wk_forecast_totaling_rec.total_amount
                               := TRUNC( g_frcst_base_total_tbl1(in_index).forecast_qty
                                       * ( g_frcst_base_total_tbl2(in_index2).ship_result_qty
                                         / g_frcst_base_total_tbl1(in_index).ship_result_qty  )
                                  );

          -- ���݂̍��v�l���O���[�o���ɕێ�����i�ŏI���R�[�h�̗]����Z�ׁ̈j
          gn_base_total_amount := gn_base_total_amount + xxcop_wk_forecast_totaling_rec.total_amount;
        END IF;

      -- �o�בq�ɒP�ʎ��ѐ��ʍ��v���[���̏ꍇ�A���͍s�Ȃ�Ȃ�
      ELSE
        xxcop_wk_forecast_totaling_rec.total_amount := 0;
      END IF;
      xxcop_wk_forecast_totaling_rec.whse_code
                              := g_frcst_base_total_tbl2(in_index2).whse_code;
      xxcop_wk_forecast_totaling_rec.planed_item_flg
                              := g_frcst_base_total_tbl2(in_index2).planed_item_flg;
      xxcop_wk_forecast_totaling_rec.no_shipment_results
                              := g_frcst_base_total_tbl2(in_index2).no_shipment_results;
      xxcop_wk_forecast_totaling_rec.sourcing_rules_warn_type
                              := g_frcst_base_total_tbl2(in_index2).sourcing_rules_warn_type;
      xxcop_wk_forecast_totaling_rec.base_code
                              := g_frcst_base_total_tbl2(in_index2).base_code;
    ELSE
      xxcop_wk_forecast_totaling_rec.whse_code                := g_frcst_base_total_tbl1(in_index).forecast_whse_code;
      xxcop_wk_forecast_totaling_rec.total_amount             := g_frcst_base_total_tbl1(in_index).forecast_qty;
      xxcop_wk_forecast_totaling_rec.planed_item_flg          := NULL;
      xxcop_wk_forecast_totaling_rec.no_shipment_results      := cv_no_shipment_results;
      xxcop_wk_forecast_totaling_rec.sourcing_rules_warn_type := cv_srwt_0;
      xxcop_wk_forecast_totaling_rec.base_code                := NULL;
    END IF;

--��v1.1 Del Start
--��    -- �o�׎��тȂ������J�E���g
--��    IF (xxcop_wk_forecast_totaling_rec.no_shipment_results=cv_no_shipment_results) THEN
--��      gn_noresults_cnt := gn_noresults_cnt + 1;
--��    END IF;
--��v1.1 Del End

    -----------------------------------------------
    --         ����v��W�v���[�N�e�[�u��
    -----------------------------------------------
    INSERT
    INTO   xxcop_wk_forecast_totaling(
        schedule_type                                                     -- �v��敪
      , whse_code                                                         -- �o�בq��
      , prod_class                                                        -- ���i�敪
      , item_code                                                         -- �i�ڃR�[�h
      , count_period_from                                                 -- �W�v����From
      , count_period_to                                                   -- �W�v����To
      , total_amount                                                      -- ���搔�ʍ��v
      , planed_item_flg                                                   -- �v�揤�i�t���O
      , no_shipment_results                                               -- �o�׎��тȂ�
      , sourcing_rules_warn_type                                          -- �����\���\�f�[�^�x���敪
      , base_code                                                         -- ���_
      , forecast_date                                                     -- �t�H�[�L���X�g���t
      , created_by                                                        -- �쐬��
      , creation_date                                                     -- �쐬��
      , last_updated_by                                                   -- �ŏI�X�V��
      , last_update_date                                                  -- �ŏI�X�V��
      , last_update_login                                                 -- �ŏI�X�V���O�C��
      , request_id                                                        -- �v��ID
      , program_application_id                                            -- �v���O�����A�v���P�[�V����ID
      , program_id                                                        -- �v���O����ID
      , program_update_date                                               -- �v���O�����X�V��
      )
    VALUES(
        g_frcst_base_total_tbl1(in_index).schedule_type                   -- �v��敪�F�o�ח\��
      , xxcop_wk_forecast_totaling_rec.whse_code                          -- �o�׊Ǘ���R�[�h
      , g_frcst_base_total_tbl1(in_index).prod_class                      -- ���i�敪
      , g_frcst_base_total_tbl1(in_index).item_code                       -- �i�ڃR�[�h
      , g_frcst_base_total_tbl1(in_index).count_period_from               -- �W�v�J�n��
      , g_frcst_base_total_tbl1(in_index).count_period_to                 -- �W�v�I����
      , xxcop_wk_forecast_totaling_rec.total_amount                       -- ����
      , xxcop_wk_forecast_totaling_rec.planed_item_flg                    -- �v�揤�i�t���O
      , xxcop_wk_forecast_totaling_rec.no_shipment_results                -- �o�׎��тȂ�
      , xxcop_wk_forecast_totaling_rec.sourcing_rules_warn_type           -- �����\���\�f�[�^�x���敪
      , xxcop_wk_forecast_totaling_rec.base_code                          -- ���_
      , NULL                                                              -- �t�H�[�L���X�g���t
      , cn_created_by                                                     -- �쐬��
      , cd_creation_date                                                  -- �쐬��
      , cn_last_updated_by                                                -- �ŏI�X�V��
      , cd_last_update_date                                               -- �ŏI�X�V��
      , cn_last_update_login                                              -- �ŏI�X�V���O�C��
      , cn_request_id                                                     -- �v��ID
      , cn_program_application_id                                         -- �v���O�����A�v���P�[�V����ID
      , cn_program_id                                                     -- �v���O����ID
      , cd_program_update_date                                            -- �v���O�����X�V��
    );
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
      --�����[�U�G���[���b�Z�[�W�ǉ���
      ov_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_ins_err_msg
                    ,iv_token_name1  => cv_ins_err_msg_tkn_lbl1
                    ,iv_token_value1 => cv_ins_err_msg_tkn_val1
                    );
      --�����[�U�G���[���b�Z�[�W�ǉ���
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_base_totaling;
--
--
  /**********************************************************************************
   * Procedure Name   : csv_output
   * Description      : ����v��W�v����CSV�o��(A-10)
   ***********************************************************************************/
  PROCEDURE csv_output(
     ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'csv_output'; -- �v���O������
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
    -- �G���[���b�Z�[�W
--
    -- *** ���[�J���ϐ� ***
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_ADD_START
    -- ���ʊ֐��F�P�[�X���Z�p
    ln_case_quantity   NUMBER;          -- �P�[�X����
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_ADD_END

    -- �������ʃ��|�[�g�o�͕�����o�b�t�@
    lv_title_buff VARCHAR2(256);
    lv_buff       VARCHAR2(256);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_csv_output_cur IS
    SELECT schedule_type       schedule_type                                                         -- �v��敪
      ,    whse_code           whse_code                                                             -- �o�בq��
      ,    prod_class          prod_class                                                            -- ���i�敪
      ,    item_code           item_code                                                             -- �i�ڃR�[�h
      ,    count_period_from   count_period_from                                                     -- �W�v����From
      ,    count_period_to     count_period_to                                                       -- �W�v����To
      ,    SUM(total_amount)   total_amount                                                          -- ���搔�ʍ��v
      ,    REPLACE(planed_item_flg ,cv_planed_item_flg_0 ,cv_planed_item_flg_null ) planed_item_flg  -- �v�揤�i�t���O
      ,    no_shipment_results no_shipment_results                                                   -- �o�׎��тȂ�
    FROM   xxcop_wk_forecast_totaling
    WHERE  request_id = cn_request_id
    AND    sourcing_rules_warn_type NOT IN (cv_srwt_3,cv_srwt_4)
    AND    NVL(planed_item_flg,' ') <> cv_planed_item_flg_1
--��v1.1 Add Start
    AND    NOT(   no_shipment_results =  cv_no_shipment_results
              AND NVL(total_amount,0) =  0
              )
--��v1.1 Add End
    GROUP
    BY     schedule_type
      ,    whse_code
      ,    prod_class
      ,    item_code
      ,    count_period_from
      ,    count_period_to
      ,    REPLACE(planed_item_flg ,cv_planed_item_flg_0 ,cv_planed_item_flg_null )
      ,    no_shipment_results
    ORDER
    BY     whse_code
      ,    item_code
      ,    count_period_from
      ,    no_shipment_results DESC
      ,    planed_item_flg DESC
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
    -------------------------------------------------------------
    --                      CSV�o��
    -------------------------------------------------------------
    -- �^�C�g���s�ݒ�
    lv_title_buff :=       cv_csv_header1  
        || cv_csv_cont ||  cv_csv_header2  
        || cv_csv_cont ||  cv_csv_header3  
        || cv_csv_cont ||  cv_csv_header4  
        || cv_csv_cont ||  cv_csv_header5  
        || cv_csv_cont ||  cv_csv_header6  
        || cv_csv_cont ||  cv_csv_header7  
        || cv_csv_cont ||  cv_csv_header8  
        || cv_csv_cont ||  cv_csv_header9  
        ;

    <<csv_output_loop>>
    FOR get_csv_output_rec IN get_csv_output_cur LOOP

      -- �^�C�g���s�o��
      IF (lv_title_buff IS NOT NULL) THEN

        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_title_buff
        );
        
        lv_title_buff := NULL;
      END IF;

--��v1.1 Add Start
      -- �o�׎��тȂ������J�E���g
      IF (get_csv_output_rec.no_shipment_results=cv_no_shipment_results) THEN
        gn_noresults_cnt := gn_noresults_cnt + 1;
      END IF;
--��v1.1 Add End

--20090407_Ver1.2_T1_0271_SCS.Kikuchi_ADD_START
      --[���ʊ֐�]�P�[�X�����Z�֐��̌Ăяo���i�P�[�X���v�Z�j
      xxcop_common_pkg.get_case_quantity(
        iv_item_no               => get_csv_output_rec.item_code     -- �i�ڃR�[�h
       ,in_individual_quantity   => get_csv_output_rec.total_amount  -- �o������
       ,in_trunc_digits          => 0                                -- �؎̂Č���
       ,on_case_quantity         => ln_case_quantity        -- �P�[�X����
       ,ov_retcode               => lv_retcode              -- ���^�[���R�[�h
       ,ov_errbuf                => lv_errbuf               -- �G���[�E���b�Z�[�W
       ,ov_errmsg                => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE internal_process_expt;
      END IF;
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_ADD_END

      -- �f�[�^�s
      lv_buff :=           get_csv_output_rec.schedule_type
        || cv_csv_cont ||  get_csv_output_rec.whse_code
        || cv_csv_cont ||  get_csv_output_rec.prod_class
        || cv_csv_cont ||  get_csv_output_rec.item_code
        || cv_csv_cont ||  TO_CHAR(get_csv_output_rec.count_period_from,cv_date_format6)
        || cv_csv_cont ||  TO_CHAR(get_csv_output_rec.count_period_to  ,cv_date_format6)
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_MOD_START
--        || cv_csv_cont ||  TO_CHAR(get_csv_output_rec.total_amount)
        || cv_csv_cont ||  TO_CHAR(ln_case_quantity)
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_MOD_END
        || cv_csv_cont ||  get_csv_output_rec.planed_item_flg
        || cv_csv_cont ||  get_csv_output_rec.no_shipment_results
        ;
      -- �f�[�^�s�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_buff
      );

      -- ���팏�����Z
      gn_normal_cnt := gn_normal_cnt + 1;

    END LOOP csv_output_loop;
--
  EXCEPTION
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_ADD_START
    WHEN internal_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NVL(lv_errbuf,lv_errmsg);
      ov_retcode := cv_status_error;

      -- ���팏�����Z
      gn_normal_cnt := 0;
--20090407_Ver1.2_T1_0271_SCS.Kikuchi_ADD_END
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
  END csv_output;
--
  /**********************************************************************************
   * Procedure Name   : output_warn_msg
   * Description      : �x���f�[�^���b�Z�[�W�o��
   ***********************************************************************************/
  PROCEDURE output_warn_msg(
     ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_warn_msg'; -- �v���O������
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
    -- ���O�o�͕�����o�b�t�@
    lv_buff VARCHAR2(1024);
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_warn_data_cur IS
    SELECT item_code                                  item_code                 -- �i�ڃR�[�h
      ,    base_code                                  base_code                 -- ���_
--��v1.1 Del       ,    TO_CHAR(forecast_date,cv_date_format5)     forecast_date             -- �t�H�[�L���X�g���t
--��v1.1 Del       ,    TO_CHAR(count_period_from,cv_date_format5) count_period_from         -- �W�v����From
--��v1.1 Del       ,    TO_CHAR(count_period_to,cv_date_format5)   count_period_to           -- �W�v����To
      ,    whse_code                                  whse_code                 -- �o�בq��
      ,    sourcing_rules_warn_type                   sourcing_rules_warn_type  -- �����\���\�f�[�^�x���敪
    FROM   xxcop_wk_forecast_totaling                                           -- ����v��W�v���[�N�e�[�u��
    WHERE  request_id = cn_request_id
    AND    sourcing_rules_warn_type not in (cv_srwt_0,cv_srwt_4)
    GROUP
    BY     item_code                                    -- �i�ڃR�[�h
      ,    base_code                                    -- ���_
--��v1.1 Del      ,    TO_CHAR(forecast_date,cv_date_format5)       -- �t�H�[�L���X�g���t
--��v1.1 Del      ,    TO_CHAR(count_period_from,cv_date_format5)   -- �W�v����From
--��v1.1 Del      ,    TO_CHAR(count_period_to,cv_date_format5)     -- �W�v����To
      ,    whse_code                                    -- �o�בq��
      ,    sourcing_rules_warn_type                     -- �����\���\�f�[�^�x���敪
    ORDER
    BY     sourcing_rules_warn_type
      ,    item_code
      ,    base_code
--��v1.1 Upd End      ,    forecast_date
--��v1.1 Upd End      ,    count_period_from
      ,    whse_code
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
    -------------------------------------------------------------
    --                  �x�����b�Z�[�W�o��
    -------------------------------------------------------------
    <<warn_output_loop>>
    FOR get_warn_data_rec IN get_warn_data_cur LOOP

      -- �����x���������Z
      gn_internal_warn_cnt := gn_internal_warn_cnt + 1;

      -- �����ΏۊO�F�����\���\������
      -- �����ΏہF�����\���\��
--��v1.1 Upd Start
--��      IF (get_warn_data_rec.sourcing_rules_warn_type IN (cv_srwt_1,cv_srwt_2)) THEN
      IF (get_warn_data_rec.sourcing_rules_warn_type IN (cv_srwt_1,cv_srwt_2))
      AND(get_warn_data_rec.whse_code<>SUBSTRB(cv_drink_whse_code,2,4))
      THEN
--��v1.1 Upd End
        -- �����\���\�A�h�I���ɓo�^����Ă��܂���B
        lv_buff :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_norules1_err_msg
                      ,iv_token_name1  => cv_norules1_err_msg_tkn_lbl1
                      ,iv_token_value1 => get_warn_data_rec.item_code           -- �i�ڃR�[�h
                      ,iv_token_name2  => cv_norules1_err_msg_tkn_lbl2
                      ,iv_token_value2 => get_warn_data_rec.base_code           -- ���_
--��v1.1 Upd Start
                      ,iv_token_name3  => cv_norules1_err_msg_tkn_lbl3
                      ,iv_token_value3 => get_warn_data_rec.whse_code           -- �o�בq��
--��                      ,iv_token_name3  => cv_norules1_err_msg_tkn_lbl3
--��                      ,iv_token_value3 => get_warn_data_rec.forecast_date       -- �t�H�[�L���X�g���t
--��                      ,iv_token_name4  => cv_norules1_err_msg_tkn_lbl4
--��                      ,iv_token_value4 => get_warn_data_rec.whse_code           -- �o�בq��
--��v1.1 Upd End
                      );
      END IF;

      -- �����ΏہF�����\���\�L(���v���ѐ����j
--��v1.1 Upd Start
--��      IF (get_warn_data_rec.sourcing_rules_warn_type = cv_srwt_3) THEN
      IF (get_warn_data_rec.sourcing_rules_warn_type = cv_srwt_3)
      OR (  (get_warn_data_rec.sourcing_rules_warn_type IN (cv_srwt_1,cv_srwt_2))
         AND(get_warn_data_rec.whse_code=SUBSTRB(cv_drink_whse_code,2,4))
         )
      THEN
--��v1.1 Upd End
        -- �W�v���ԓ��ŕ����\���\�A�h�I���ɓo�^����Ă��Ȃ��f�[�^������܂��B
        lv_buff :=  xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_application
                      ,iv_name         => cv_norules2_err_msg
                      ,iv_token_name1  => cv_norules2_err_msg_tkn_lbl1
                      ,iv_token_value1 => get_warn_data_rec.item_code           -- �i�ڃR�[�h
                      ,iv_token_name2  => cv_norules2_err_msg_tkn_lbl2
                      ,iv_token_value2 => get_warn_data_rec.base_code           -- ���_
--��v1.1 Del Start
--��                      ,iv_token_name3  => cv_norules2_err_msg_tkn_lbl3
--��                      ,iv_token_value3 => get_warn_data_rec.count_period_from   -- �W�v����From
--��                      ,iv_token_name4  => cv_norules2_err_msg_tkn_lbl4
--��                      ,iv_token_value4 => get_warn_data_rec.count_period_to     -- �W�v����To
--��v1.1 Del End
                      );
      END IF;

      -- �f�[�^�s�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_buff
      );

    END LOOP warn_output_loop;
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
  END output_warn_msg;
--
  /**********************************************************************************
   * Procedure Name   : delete_work_table
   * Description      : ����v��W�v���[�N�e�[�u���폜
   ***********************************************************************************/
  PROCEDURE delete_work_table(
     ov_errbuf            OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode           OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg            OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_work_table'; -- �v���O������
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
    -------------------------------------------------------------
    --            ����v��W�v���[�N�e�[�u���폜
    -------------------------------------------------------------
    DELETE
    FROM   xxcop_wk_forecast_totaling
    WHERE  request_id = cn_request_id
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
  END delete_work_table;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_base_code                  IN  VARCHAR2         -- 1.���_
    ,iv_prod_class_code            IN  VARCHAR2         -- 2.���i�敪
    ,iv_results_collect_period_st  IN  VARCHAR2         -- 3.���ю��W���ԁi���j
    ,iv_results_collect_period_ed  IN  VARCHAR2         -- 4.���ю��W���ԁi���j
    ,iv_forecast_collect_period_st IN  VARCHAR2         -- 5.�v����W���ԁi���j
    ,iv_forecast_collect_period_ed IN  VARCHAR2         -- 6.�v����W���ԁi���j
    ,ov_errbuf                     OUT VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode                    OUT VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                     OUT VARCHAR2)        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������

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
    lv_year_month      VARCHAR2(6);
    ln_day             NUMBER(2);
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

    -- �p�����[�^�����O�o��
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');    -- ���s
    FND_FILE.PUT_LINE(FND_FILE.LOG,cv_pm_base_code_tl        || cv_pm_part  || iv_base_code                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG,cv_pm_prod_class_code_tl  || cv_pm_part  || iv_prod_class_code           );
    FND_FILE.PUT_LINE(FND_FILE.LOG,cv_pm_results_clt_prd_tl  || cv_pm_part  || iv_results_collect_period_st
                                                             || cv_pm_part2 || iv_results_collect_period_ed );
    FND_FILE.PUT_LINE(FND_FILE.LOG,cv_pm_forecast_clt_prd_tl || cv_pm_part  || iv_forecast_collect_period_st
                                                             || cv_pm_part2 || iv_forecast_collect_period_ed);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'');    -- ���s

    -- �O���[�o���ϐ��ɓ��̓p�����[�^��ݒ�
    gv_base_code                   := RTRIM(iv_base_code);
    gv_prod_class_code             := RTRIM(iv_prod_class_code);
    gd_results_collect_period_st   := TO_DATE(iv_results_collect_period_st ||' '||cv_date_start_time ,cv_date_format1);
    gd_results_collect_period_ed   := TO_DATE(iv_results_collect_period_ed ||' '||cv_date_end_time   ,cv_date_format1);
    gd_forecast_collect_period_st  := TO_DATE(iv_forecast_collect_period_st||' '||cv_date_start_time ,cv_date_format1);
    gd_forecast_collect_period_ed  := TO_DATE(iv_forecast_collect_period_ed||' '||cv_date_end_time   ,cv_date_format1);

    -- ���������p�O���[�o���ϐ�������
    gd_sysdate           := TRUNC(SYSDATE);
    gn_internal_warn_cnt := 0;
    gn_noresults_cnt     := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    --        A-1 ��������
    -- ===============================
    init(
      lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;

    -- ===============================
    --    A-2 ����v��W�v���Ԑݒ�
    -- ===============================
    <<totaling_period_loop>>
    LOOP

      --------------------------------
      --       �W�v�J�n���ݒ�
      --------------------------------
      IF (gd_totaling_start_date IS NULL) THEN
         gd_totaling_start_date := gd_forecast_collect_period_st;
      ELSE
         gd_totaling_start_date := trunc(gd_totaling_end_date + 1);
      END IF;

      --------------------------------
      --       �W�v�I�����ݒ�
      --------------------------------
      lv_year_month := TO_CHAR(gd_totaling_start_date,cv_date_format3);
      ln_day        := TO_NUMBER(TO_CHAR(gd_totaling_start_date,cv_date_format4));

      IF (ln_day <= 7) THEN
        gd_totaling_end_date   := TO_DATE(lv_year_month||cv_week_day_1||cv_date_end_time,cv_date_format2);
      ELSIF (ln_day <= 14) THEN
        gd_totaling_end_date   := TO_DATE(lv_year_month||cv_week_day_2||cv_date_end_time,cv_date_format2);
      ELSIF (ln_day <= 21) THEN
        gd_totaling_end_date   := TO_DATE(lv_year_month||cv_week_day_3||cv_date_end_time,cv_date_format2);
      ELSE
        gd_totaling_end_date   := ADD_MONTHS(TO_DATE(lv_year_month,cv_date_format3),1) - (1/24/60/60);
      END IF;

      -- �W�v�I�������v����W���ԁi���j���傫���Ȃ����ꍇ�A
      -- �W�v�I�������v����W���ԁi���j�ɐݒ肷��B
      IF (gd_totaling_end_date>gd_forecast_collect_period_ed) THEN
        gd_totaling_end_date := gd_forecast_collect_period_ed;
      END IF;

      -- ���[�N������
      g_frcst_base_total_tbl1 := g_frcst_base_total_tbl1_init;

      -- =========================================
      --   A-3.�Ώۃf�[�^���o�i�o�בq�ɏW�v�j
      --   A-4.���[�N�e�[�u���o�^
      --    �������ȗ����ׁ̈AINSERT�`SELECT�ɕύX
      -- =========================================
      insert_whse_totaling(
        lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE internal_process_expt;
      END IF;

      -- ===================================================
      -- �����Ώۋ��_ �Ǘ������_�v�搔�ʏW�v�f�[�^���o�iA-5�j
      -- ===================================================
      get_management_forcast_total(
        lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE internal_process_expt;
      END IF;

      <<management_base_loop>>
      FOR ix IN 1..g_frcst_base_total_tbl1.COUNT LOOP

        -- ===================================================
        -- �����Ώۋ��_ �Ǘ������_���ѐ��ʏW�v�f�[�^���o�iA-6�j
        -- ===================================================
        get_management_result_total(
          ix                                   -- �Ǘ������_�W�v�f�[�^���o���[�vIndex
         ,lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;

        -- ���[�N������
        gn_base_total_amount    := 0;
        g_frcst_base_total_tbl2 := g_frcst_base_total_tbl2_init;

        -- ===================================================
        --  �z�����_�E�o�בq�ɕʏo�׎��ђ��o(A-7)
        -- ===================================================
        get_whse_totaling(
          ix                                   -- �Ǘ������_�W�v�f�[�^���o���[�vIndex
         ,lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          RAISE internal_process_expt;
        END IF;

        <<base_loop>>
        FOR ix2 IN 1..g_frcst_base_total_tbl2.COUNT LOOP
          -- ===================================================
          -- ����v��W�v(��)���[�N�e�[�u���o�^(A-9)
          -- �������ȗ����ׁ̈A����v�搔��(A-8)�𓝍�
          -- ===================================================
          insert_base_totaling(
            ix                                   -- �Ǘ������_�W�v�f�[�^���o���[�vIndex
           ,ix2                                  -- �z�����_�E�o�בq�ɕʏo�׎��ђ��o���[�vIndex
           ,lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE internal_process_expt;
          END IF;
        END LOOP base_loop;

        IF (g_frcst_base_total_tbl1(ix).ship_result_qty = 0) THEN
          -- ================================================================
          -- �Ǘ������_�P�ʂł̎��ѐ��ʂ��[���őS�Ď��тȂ��̏ꍇ�A
          -- ���o���Ȃ������v�搔�ʂ�CSV�ɏo�͂���ׁA
          -- �t�H�[�L���X�g�q�ɂň���v��W�v���[�N�e�[�u���̓o�^���s�Ȃ��B
          -- ================================================================
          insert_base_totaling(
            ix                                   -- �Ǘ������_�W�v�f�[�^���o���[�vIndex
           ,NULL
           ,lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            RAISE internal_process_expt;
          END IF;
        END IF;
      END LOOP management_base_loop;

      -- �v����W���Ԃ܂Ŋ��������烋�[�v�𔲂���B
      IF (gd_totaling_end_date>=gd_forecast_collect_period_ed) THEN
        EXIT totaling_period_loop;
      END IF;

    END LOOP totaling_period_loop;

    -- ===================================================
    --  ����v��W�v����CSV�o��(A-10)
    -- ===================================================
    csv_output(
      lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;

    -- ===================================================
    --  CSV�x���f�[�^���b�Z�[�W�o��
    -- ===================================================
    output_warn_msg(
      lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;

    -- ===================================================
    --  ����v��W�v���[�N�e�[�u���폜
    -- ===================================================
    delete_work_table(
      lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE internal_process_expt;
    END IF;

    -- �o�׎��тȂ��o�̓m�[�g
    IF (gn_noresults_cnt>0) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff =>   xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_application
                    ,iv_name         => cv_noresult_note_msg
                    )
        );
    END IF;

    -- �Ώی����Z�o
    gn_target_cnt := gn_normal_cnt;

    -- �x�����b�Z�[�W���o�͂����ꍇ�A�x���I���Ŗ߂�
    IF (  (gn_internal_warn_cnt>0) OR (gn_noresults_cnt>0) ) THEN
      ov_retcode := cv_status_warn;
    END IF;

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
--���������ł͎g�p���Ȃ���������������������������������������������
--��    -- *** ���������ʗ�O�n���h�� ***
--��    WHEN global_process_expt THEN
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
      -- �G���[�J�E���g�A�b�v
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
     errbuf                        OUT VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
    ,retcode                       OUT VARCHAR2         --   �G���[�R�[�h     #�Œ�#
    ,iv_base_code                  IN  VARCHAR2         -- 1.���_
    ,iv_prod_class_code            IN  VARCHAR2         -- 2.���i�敪
    ,iv_results_collect_period_st  IN  VARCHAR2         -- 3.���ю��W���ԁi���j
    ,iv_results_collect_period_ed  IN  VARCHAR2         -- 4.���ю��W���ԁi���j
    ,iv_forecast_collect_period_st IN  VARCHAR2         -- 5.�v����W���ԁi���j
    ,iv_forecast_collect_period_ed IN  VARCHAR2         -- 6.�v����W���ԁi���j
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
       iv_base_code                      -- 1.���_
      ,iv_prod_class_code                -- 2.���i�敪
      ,iv_results_collect_period_st      -- 3.���ю��W���ԁi���j
      ,iv_results_collect_period_ed      -- 4.���ю��W���ԁi���j
      ,iv_forecast_collect_period_st     -- 5.�v����W���ԁi���j
      ,iv_forecast_collect_period_ed     -- 6.�v����W���ԁi���j
      ,lv_errbuf                         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN

      -- ���[�U�G���[���b�Z�[�W�����O�o��
      IF (lv_errmsg IS NOT NULL) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff =>   lv_errmsg
        );
      END IF;

      -- �V�X�e���G���[���b�Z�[�W�����O�o��
      IF (lv_errbuf IS NOT NULL) THEN
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
--    --�X�L�b�v�����o��
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
END XXCOP004A03C;
/
