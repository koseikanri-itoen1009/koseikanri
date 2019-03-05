CREATE OR REPLACE PACKAGE BODY APPS.XXCSM002A17C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : XXCSM002A17C(body)
 * Description      : CSV�f�[�^�A�b�v���[�h�i�N�ԏ��i�v��j
 * MD.050           : MD050_CSM_002_A17_CSV�f�[�^�A�b�v���[�h�i�N�ԏ��i�v��j
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_upload_data        �t�@�C���A�b�v���[�hIF�擾(A-2)
 *  del_upload_data        �A�b�v���[�h�f�[�^�폜����(A-3)
 *  split_plan_data        �N�ԏ��i�v��f�[�^�̍��ڕ�������(A-4)
 *  item_check             ���ڃ`�F�b�N(A-5)
 *  ins_plan_tmp           ���i�v��A�b�v���[�h���[�N�o�^����(A-6)
 *  chk_base_code          ���_�R�[�h�A�N�x�`�F�b�N����(A-8)
 *  chk_record_kind        ���R�[�h�敪�`�F�b�N����(A-9)
 *  chk_master_data        ���i�Q�}�X�^�`�F�b�N����(A-10)
 *  chk_budget_value       �\�Z�l�`�F�b�N
 *  chk_budget_item        �\�Z���ڃ`�F�b�N����(A-11)
 *  ins_plan_headers       ���i�v��w�b�_�o�^����(A-12)
 *  ins_plan_loc_bdgt      ���_�\�Z�o�^�E�X�V����(A-13)
 *  calc_budget_item       ���i�Q�\�Z�l�Z�o
 *  calc_budget_new_item   �V���i�\�Z�l�Z�o
 *  ins_plan_line          ���i�Q�\�Z�o�^�E�X�V����(A-14)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-15)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/02/08    1.0   N.Koyama          main�V�K�쐬
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
  global_proc_date_err_expt         EXCEPTION;    -- �Ɩ����t�擾��O�n���h��
  global_get_profile_expt           EXCEPTION;    -- �v���t�@�C���擾��O�n���h��
  global_get_org_id_expt            EXCEPTION;    -- �݌ɑg�DID�擾��O�n���h��
  global_get_file_id_lock_expt      EXCEPTION;    -- �t�@�C��ID�̎擾�n���h��
  global_get_file_id_data_expt      EXCEPTION;    -- �t�@�C��ID�̎擾�n���h��
  global_get_f_uplod_name_expt      EXCEPTION;    -- �t�@�C���A�b�v���[�h���̂̎擾�n���h��
  global_get_f_csv_name_expt        EXCEPTION;    -- CSV�t�@�C�����̎擾�n���h��
  global_item_check_expt            EXCEPTION;    -- ���ڃ`�F�b�N�n���h��
  global_del_ul_interface_expt      EXCEPTION;    -- ���R�[�h�폜��O�n���h��
--
  global_data_lock_expt             EXCEPTION;    -- �f�[�^���b�N��O
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  --�v���O��������
  cv_pkg_name                       CONSTANT VARCHAR2(100) := 'XXCSM002A17C';   --�p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  cv_xxcsm_appl_short_name          CONSTANT VARCHAR2(100) := 'XXCSM';          --�o�c�Z�k�A�v����
  cv_xxccp_appl_short_name          CONSTANT VARCHAR2(100) := 'XXCCP';          --����
--
  --���b�Z�[�W
  cv_msg_plan_year_err              CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-00004';    --�\�Z�N�x�`�F�b�N�G���[
  cv_msg_profile_err                CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-00005';    --�v���t�@�C���擾�G���[
  cv_msg_not_exist_calendar         CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-00006';    --�N�Ԕ̔��v��J�����_�[�����݃G���[
  cv_msg_user_base_code             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-00059';    --���O�C�����[�U�[�ݐЋ��_�擾�G���[
  cv_msg_new_item_err               CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10138';    --�V���i�R�[�h�擾�G���[
  --
  cv_msg_no_plan_kind_err           CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10200';    --���_�\�Z�A���i�Q�\�Z�����G���[
  cv_msg_base_code                  CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10201';    --���_�R�[�h
  cv_msg_year                       CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10202';    --�N�x
  cv_msg_plan_kind                  CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10203';    --�\�Z�敪
  cv_msg_record_kind                CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10204';    --���R�[�h�敪
  cv_msg_sales_budget               CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10205';    --����\�Z
  cv_msg_receipt_discount           CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10206';    --�����l��
  cv_msg_sales_discount             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10207';    --����l��
  cv_msg_item_sales_budget          CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10208';    --����
  cv_msg_amount_gross_margin        CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10209';    --�e���z
  cv_msg_margin_rate                CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10210';    --�e����
  cv_msg_base_total                 CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10211';    --���_�v
  cv_msg_add_err                    CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10212';    --�e�[�u���o�^�G���[
  cv_msg_tmp_tbl                    CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10213';    --���i�v��A�b�v���[�h���[�N�e�[�u��
  cv_msg_upload_name_get            CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10215';    --�t�@�C���A�b�v���[�h���̎擾�G���[
  cv_msg_security_err               CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10216';    --�w�苒�_�G���[
  cv_msg_extract_err                CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10217';    --�f�[�^���o�G���[
  cv_msg_master_err                 CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10218';    --���i�Q�}�X�^�G���[
  cv_msg_no_found_rec_kubun         CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10219';    --���R�[�h�敪�����G���[
  cv_msg_too_many_rec_kubun         CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10220';    --���R�[�h�敪�����G���[
  cv_msg_fail_rec_kubun             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10221';    --���R�[�h�敪���
  cv_msg_sales_budget_err           CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10222';    --����w��G���[
  cv_msg_decimal_point_err          CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10223';    --�����_�ȉ��w��G���[
  cv_msg_disconut_item_err          CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10224';    --�l�����ڎw��G���[
  cv_msg_multi_designation_err      CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10225';    --�e���z�A�e���������w��G���[
  cv_msg_file_up_load               CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10226';    --�t�@�C���A�b�v���[�hIF
  cv_msg_item_group_calc_err        CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10227';    --���i�Q�\�Z�l�Z�o�G���[
  cv_msg_get_f_csv_name             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10228';    --CSV�t�@�C�����擾�G���[
  cv_msg_get_rep_h1                 CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10229';    --�t�H�[�}�b�g�p�^�[��
  cv_msg_get_rep_h2                 CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10230';    --CSV�t�@�C����
  cv_msg_process_date_err           CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10231';    --�Ɩ����t�擾�G���[
  cv_msg_delete_data_err            CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10232';    --�f�[�^�폜�G���[
  cv_msg_get_data_err               CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10233';    --�f�[�^���o�G���[
  cv_msg_get_lock_err               CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10234';    --���b�N�G���[
  cv_msg_chk_rec_err                CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10235';    --�t�@�C�����R�[�h�s��v�G���[
  cv_msg_value_over_err             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10236';    --���e�͈̓G���[
  cv_msg_item_plan_loc_bdgt         CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10237';    --���i�v�拒�_�ʗ\�Z�e�[�u��
  cv_msg_item_plan_lines            CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10238';    --���i�v�斾�׃e�[�u��
  cv_msg_null_err                   CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10239';    --���w��G���[
  --
  cv_msg_get_format_err             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10302';    --���ڕs���G���[
  cv_msg_no_upload_date             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10305';    --�A�b�v���[�h�����ΏۂȂ��G���[
  cv_msg_multi_base_code_err        CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10307';    --�������_�G���[
  cv_msg_budget_year_err            CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10308';    --�w��\�Z�N�x�G���[
  cv_msg_multi_year_err             CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10309';    --�����\�Z�N�x�G���[
  cv_msg_discrete_cost_err          CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10315';    --�c�ƌ����擾�G���[
  cv_msg_fixed_price_err            CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10316';    --�艿�擾�G���[
  cv_msg_new_item_calc_err          CONSTANT VARCHAR2(20)  := 'APP-XXCSM1-10326';    --�V���i�\�Z�l�Z�o�G���[
  --�g�[�N��
  cv_tkn_file_id                    CONSTANT VARCHAR2(20)  := 'FILE_ID ';            --�t�@�C��ID
  cv_tkn_profile                    CONSTANT VARCHAR2(20)  := 'PROFILE';             --�v���t�@�C����
  cv_tkn_org_code                   CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';        --�݌ɑg�D�R�[�h
  cv_tkn_table                      CONSTANT VARCHAR2(20)  := 'TABLE';               --�e�[�u����
  cv_tkn_key_data                   CONSTANT VARCHAR2(20)  := 'KEY_DATA';            --�L�[���
  cv_tkn_table_name                 CONSTANT VARCHAR2(20)  := 'TABLE_NAME';          --�e�[�u����
  cv_tkn_data                       CONSTANT VARCHAR2(20)  := 'DATA';                --���R�[�h�f�[�^
  cv_tkn_param1                     CONSTANT VARCHAR2(20)  := 'PARAM1';              --�p�����[�^1
  cv_tkn_param2                     CONSTANT VARCHAR2(20)  := 'PARAM2';              --�p�����[�^2
  cv_tkn_param3                     CONSTANT VARCHAR2(20)  := 'PARAM3';              --�p�����[�^3
  cv_tkn_param4                     CONSTANT VARCHAR2(20)  := 'PARAM4';              --�p�����[�^4
  cv_tkn_column                     CONSTANT VARCHAR2(20)  := 'COLUMN';              --���ږ�
  cv_tkn_base_code                  CONSTANT VARCHAR2(20)  := 'BASE_CODE';           --���_
  cv_tkn_year                       CONSTANT VARCHAR2(20)  := 'YEAR';                --�N�x
  cv_tkn_item                       CONSTANT VARCHAR2(20)  := 'ITEM';                --����
  cv_tkn_plan_kind                  CONSTANT VARCHAR2(20)  := 'PLAN_KIND';           --�\�Z�敪
  cv_tkn_record_kind                CONSTANT VARCHAR2(20)  := 'RECORD_KIND';         --���R�[�h�敪
  cv_tkn_month                      CONSTANT VARCHAR2(20)  := 'MONTH';               --��
  cv_tkn_prof_name                  CONSTANT VARCHAR2(20)  := 'PROF_NAME';           --�v���t�@�C����
  cv_tkn_yosan_nendo                CONSTANT VARCHAR2(20)  := 'YOSAN_NENDO';         --�\�Z�N�x
  cv_tkn_deal_cd                    CONSTANT VARCHAR2(20)  := 'DEAL_CD';             --���i�Q
  cv_tkn_errmsg                     CONSTANT VARCHAR2(20)  := 'ERRMSG';              --�G���[���e�ڍ�
  cv_tkn_item_cd                    CONSTANT VARCHAR2(20)  := 'ITEM_CD';             --���i�R�[�h
  cv_tkn_min                        CONSTANT VARCHAR2(20)  := 'MIN';                 --�ŏ��l
  cv_tkn_max                        CONSTANT VARCHAR2(20)  := 'MAX';                 --�ő�l
  cv_tkn_value                      CONSTANT VARCHAR2(20)  := 'VALUE';               --�l
  cv_tkn_user_id                    CONSTANT VARCHAR2(20)  := 'USER_ID';             --���[�UID
  cv_tkn_row_num                    CONSTANT VARCHAR2(20)  := 'ROW_NUM';             --�G���[�s
--
  --�v���t�@�C���I�v�V������
  cv_prof_yearplan_calender         CONSTANT VARCHAR2(30)  := 'XXCSM1_YEARPLAN_CALENDER';  -- XXCSM:�N�Ԕ̔��v��J�����_�[��
  cv_xxcsm1_dummy_dept_ref          CONSTANT VARCHAR2(30)  := 'XXCSM1_DUMMY_DEPT_REF';     -- XXCSM:�_�~�[����K�w�Q��
  cv_gl_set_of_bks_id_nm            CONSTANT VARCHAR2(30)  := 'GL_SET_OF_BKS_ID';          -- GL��v����ID
--
  --�N�C�b�N�R�[�h
  cv_look_file_upload_obj           CONSTANT VARCHAR2(50)  := 'XXCCP1_FILE_UPLOAD_OBJ';    --�t�@�C���A�b�v���[�h�I�u�W�F�N�g
  cv_look_dummy_dept                CONSTANT VARCHAR2(50)  := 'XXCSM1_DUMMY_DEPT';         --�_�~�[����K�w�Q��
--
  cv_comma                          CONSTANT VARCHAR2(1)   := ',';         --��؂蕶��
  cv_dobule_quote                   CONSTANT VARCHAR2(1)   := '"';         --���蕶��
  cv_line_feed                      CONSTANT VARCHAR2(1)   := CHR(10);     --���s�R�[�h
  cn_c_header                       CONSTANT NUMBER        := 17;          --�t�@�C�����ڐ�
  cn_begin_line                     CONSTANT NUMBER        := 2;           --�ŏ��̍s
  cn_line_zero                      CONSTANT NUMBER        := 0;           --0�s
  cn_item_header                    CONSTANT NUMBER        := 1;           --���ږ�
  cv_msg_comma                      CONSTANT VARCHAR2(2)   := '�A';        --���b�Z�[�W�p��؂蕶��
  ct_user_lang                      CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
  cn_gl_set_of_bks_id               CONSTANT NUMBER        := FND_PROFILE.VALUE( cv_gl_set_of_bks_id_nm );         -- ��v����ID
--
  --CSV���C�A�E�g�i���C�A�E�g�������`�j
  cn_base_code                      CONSTANT NUMBER        := 1;           --���_�R�[�h
  cn_plan_year                      CONSTANT NUMBER        := 2;           --�N�x
  cn_plan_kind                      CONSTANT NUMBER        := 3;           --�\�Z�敪
  cn_record_kind                    CONSTANT NUMBER        := 4;           --���R�[�h�敪
  cn_may                            CONSTANT NUMBER        := 5;           --5���\�Z
  cn_jun                            CONSTANT NUMBER        := 6;           --6���\�Z
  cn_jul                            CONSTANT NUMBER        := 7;           --7���\�Z
  cn_aug                            CONSTANT NUMBER        := 8;           --8���\�Z
  cn_sep                            CONSTANT NUMBER        := 9;           --9���\�Z
  cn_oct                            CONSTANT NUMBER        := 10;          --10���\�Z
  cn_nov                            CONSTANT NUMBER        := 11;          --11���\�Z
  cn_dec                            CONSTANT NUMBER        := 12;          --12���\�Z
  cn_jan                            CONSTANT NUMBER        := 13;          --1���\�Z
  cn_feb                            CONSTANT NUMBER        := 14;          --2���\�Z
  cn_mar                            CONSTANT NUMBER        := 15;          --3���\�Z
  cn_apr                            CONSTANT NUMBER        := 16;          --4���\�Z
  cn_sum                            CONSTANT NUMBER        := 17;          --�N�Ԍv
--
  --���ڒ��i�e���ڂ̍��ڒ����`�j
  cn_base_code_length               CONSTANT NUMBER        := 4;           --���_�R�[�h
  cn_plan_year_length               CONSTANT NUMBER        := 4;           --�N�x
  cn_plan_year_point                CONSTANT NUMBER        := 0;           --�N�x�i�����_�ȉ��j
  cn_plan_kind_length               CONSTANT NUMBER        := 6;           --�\�Z�敪
  cn_rec_kind_length                CONSTANT NUMBER        := 8;           --���R�[�h�敪
  cn_budget_length                  CONSTANT NUMBER        := 14;          --�S�́i����+�����j�̍ő包
  cn_budget_point                   CONSTANT NUMBER        := 2;           --�����̍ő包
  --�͈̓`�F�b�N�p
  cn_min_discount                   CONSTANT NUMBER       := -99999999;      --�l�����ڍŏ��l
  cn_max_discount                   CONSTANT NUMBER       := 0;              --�l�����ڍő�l
  cn_min_gross                      CONSTANT NUMBER       := -99999999999;   --�e���z�ŏ��l
  cn_max_gross                      CONSTANT NUMBER       := 999999999999;   --�e���z�ő�l
  cn_min_rate                       CONSTANT NUMBER       := -999.99;        --�e�����ŏ���
  cn_max_rate                       CONSTANT NUMBER       := 9999.99;        --�e�����ő嗦
  --
  -- ���i�̔��v�揤�i�敪
  cv_item_kbn_group                CONSTANT VARCHAR2(1)   := '0';            -- 0:���i�Q
  cv_item_kbn_tanpin               CONSTANT VARCHAR2(1)   := '1';            -- 1:�P�i
  cv_item_kbn_new                  CONSTANT VARCHAR2(1)   := '2';            -- 2:�V���i
  -- �N�ԌQ�\�Z�敪
  cv_budget_kbn_month              CONSTANT VARCHAR2(1)   := '0';            -- 0:�e���P�ʗ\�Z
  cv_budget_kbn_year               CONSTANT VARCHAR2(1)   := '1';            -- 1:�N�ԌQ�\�Z
  --
  --���i�v�斾��.��
  cn_month_no_1                    CONSTANT NUMBER        := 1;           --1��
  cn_month_no_2                    CONSTANT NUMBER        := 2;           --1��
  cn_month_no_3                    CONSTANT NUMBER        := 3;           --1��
  cn_month_no_4                    CONSTANT NUMBER        := 4;           --1��
  cn_month_no_5                    CONSTANT NUMBER        := 5;           --5��
  cn_month_no_6                    CONSTANT NUMBER        := 6;           --6��
  cn_month_no_7                    CONSTANT NUMBER        := 7;           --7��
  cn_month_no_8                    CONSTANT NUMBER        := 8;           --8��
  cn_month_no_9                    CONSTANT NUMBER        := 9;           --9��
  cn_month_no_10                   CONSTANT NUMBER        := 10;          --10��
  cn_month_no_11                   CONSTANT NUMBER        := 11;          --11��
  cn_month_no_12                   CONSTANT NUMBER        := 12;          --12��
  cn_month_no_99                   CONSTANT NUMBER        := 99;          -- �N�Ԍv�̌�
  --
  cv_sum                           CONSTANT VARCHAR2(10)  := '�N�Ԍv';    -- �N�Ԍv
  cv_sum_kyoten                    CONSTANT VARCHAR2(10)  := '���_�v';    -- ���_�v
  cv_item_group                    CONSTANT VARCHAR2(10)  := '���i�Q';    -- ���i�Q
  --���t�t�H�[�}�b�g
  cv_fmt_std                        CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  cv_fmt_hh24miss                   CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_mm                         CONSTANT VARCHAR2(2)  := 'MM';
--
  cv_no                             CONSTANT VARCHAR2(1)  := 'N';
  cv_yes                            CONSTANT VARCHAR2(1)  := 'Y';
  cv_status_check                   CONSTANT VARCHAR2(1)  := '9';            --�`�F�b�N�G���[:9
  cv_blank                          CONSTANT VARCHAR2(1)  := ' ';            --���p�X�y�[�X
--
  --���ڃ`�F�b�N�����b�Z�[�W�o�͗p�̍��ږ��̗p�ϐ�
  gv_base_code                      VARCHAR2(200);                           --���_�R�[�h
  gv_yaer                           VARCHAR2(200);                           --�N�x
  gv_plan_kind                      VARCHAR2(200);                           --�\�Z�敪
  gv_record_kind                    VARCHAR2(200);                           --���R�[�h�敪
  gv_sales_budget                   VARCHAR2(200);                           --����\�Z
  gv_receipt_discount               VARCHAR2(200);                           --�����l��
  gv_sales_discount                 VARCHAR2(200);                           --����l��
  gv_item_sales_budget              VARCHAR2(200);                           --����
  gv_amount_gross_margin            VARCHAR2(200);                           --�e���z
  gv_margin_rate                    VARCHAR2(200);                           --�e����
  gv_loc_bdgt                       VARCHAR2(200);                           --���_�v
  gv_tkn1                           VARCHAR2(200);                           --�C�ӗp
  gv_chk_base_code                  VARCHAR2(200);                           --���ꋒ�_�`�F�b�N�p
  gv_chk_year                       VARCHAR2(200);                           --����N�x�`�F�b�N�p
  gv_user_base                      VARCHAR2(200);                           --���s���[�U�[���_
  gv_employee_code                  VARCHAR2(200);                           --���s���[�U�[�]�ƈ�
  gv_no_flv_tag                     VARCHAR2(200);                           --�Z�L�����e�B����
  gv_sec_retcode                    VARCHAR2(1);                             --�Z�L�����e�B����X�e�[�^�X�ێ�
  gv_before_plan_kind               VARCHAR2(200);                           --�O���R�[�h�\�Z�敪
  gv_before_record_kind             VARCHAR2(200);                           --�O���R�[�h���R�[�h�敪
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --�N�ԏ��i�v��f�[�^ BLOB�^
  gt_plan_data                      xxccp_common_pkg2.g_file_data_tbl;
--
  TYPE gt_var_data1                 IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;        --1�����z��
  TYPE gt_var_data2                 IS TABLE OF gt_var_data1 INDEX BY BINARY_INTEGER;          --2�����z��
  gr_plan_work_data                 gt_var_data2;                                              --�����p�ϐ�
--
  TYPE g_tab_plan_header_rec        IS TABLE OF xxcsm_item_plan_headers%ROWTYPE   INDEX BY PLS_INTEGER;  --���i�v��w�b�_�e�[�u��
  TYPE g_tab_plan_loc_rec           IS TABLE OF xxcsm_item_plan_loc_bdgt%ROWTYPE  INDEX BY PLS_INTEGER;  --���i�v�拒�_�ʗ\�Z�e�[�u��
  TYPE g_tab_plan_line_rec          IS TABLE OF xxcsm_item_plan_lines%ROWTYPE     INDEX BY PLS_INTEGER;  --���i�v�斾�׃e�[�u��
--
  gr_plan_header_data1              g_tab_plan_header_rec;          --���i�v��w�b�_
  gr_plan_loc_data1                 g_tab_plan_loc_rec;             --���i�v�拒�_�ʗ\�Z
  gr_plan_line_data2                g_tab_plan_line_rec;            --���i�v�斾��
--
  --==================================================
  -- ���[�U�[��`�O���[�o���J�[�\��
  --==================================================
--
    -- �N�ԏ��i�v��ꎞ�\�擾�J�[�\��
    CURSOR get_plan_tmp_cur
    IS
      SELECT  xpt.record_id         AS record_id    -- 01:���R�[�hNo.
             ,xpt.base_code         AS base_code    -- 02:���_�R�[�h
             ,xpt.plan_year         AS plan_year    -- 03:�N�x
             ,xpt.plan_kind         AS plan_kind    -- 04:�\�Z�敪
             ,xpt.record_kind       AS record_kind  -- 05:���R�[�h�敪
             ,xpt.plan_may          AS plan_may     -- 06:5���\�Z
             ,xpt.plan_jun          AS plan_jun     -- 07:6���\�Z
             ,xpt.plan_jul          AS plan_jul     -- 08:7���\�Z
             ,xpt.plan_aug          AS plan_aug     -- 09:8���\�Z
             ,xpt.plan_sep          AS plan_sep     -- 10:9���\�Z
             ,xpt.plan_oct          AS plan_oct     -- 11:10���\�Z
             ,xpt.plan_nov          AS plan_nov     -- 12:11���\�Z
             ,xpt.plan_dec          AS plan_dec     -- 13:12���\�Z
             ,xpt.plan_jan          AS plan_jan     -- 14:1���\�Z
             ,xpt.plan_feb          AS plan_feb     -- 15:2���\�Z
             ,xpt.plan_mar          AS plan_mar     -- 16:3���\�Z
             ,xpt.plan_apr          AS plan_apr     -- 17:4���\�Z
             ,xpt.plan_sum          AS plan_sum     -- 18:���i�Q�N�ԗ\�Z
       FROM   xxcsm_plan_tmp xpt
--    ORDER BY  xpt.base_code
--             ,xpt.plan_year
    ORDER BY  decode(xpt.plan_kind,gv_loc_bdgt,'0',xpt.plan_kind)
             ,decode(xpt.record_kind,gv_sales_discount,1
                                    ,gv_receipt_discount,2
                                    ,gv_sales_budget,3
                                    ,gv_item_sales_budget,4
                                    ,gv_amount_gross_margin,5
                                    ,gv_margin_rate,6
                                    ,7)
    ;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- *** �O���[�o���e�[�u�� ***
  TYPE gr_plan_tmp_ttype IS TABLE OF get_plan_tmp_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  -- *** �O���[�o���z�� ***
  gr_plan_tmps_tab gr_plan_tmp_ttype;
  --
  gv_upload_file_name                       VARCHAR2(128);                                      --�t�@�C���A�b�v���[�h����
  gv_csv_file_name                          VARCHAR2(256);                                      --CSV�t�@�C����
  gd_process_date                           DATE;                                               --�Ɩ����t
  gt_file_id                                xxccp_mrp_file_ul_interface.file_id%TYPE;           --�t�@�C��ID
  gt_item_plan_header_id                    xxcsm_item_plan_headers.item_plan_header_id%TYPE;   --���i�v��w�b�_ID
--
  --���z���v�p
  gt_sale_amount_sum                        xxcos_sales_exp_headers.sale_amount_sum%TYPE;       --������z���v
  gt_pure_amount_sum                        xxcos_sales_exp_headers.pure_amount_sum%TYPE;       --�{�̋��z���v
  gt_tax_amount_sum                         xxcos_sales_exp_headers.tax_amount_sum%TYPE;        --����ŋ��z���v
--
  --�v���t�@�C���l�i�[�p
  gv_prof_yearplan_calender                 VARCHAR2(100);  --XXCSM:�N�Ԕ̔��v��J�����_�[��
  gv_dummy_dept_ref                         VARCHAR2(1);    --XXCSM:�_�~�[����K�w�Q��
  gn_gl_set_of_bks_id                       NUMBER;         --��v����ID
--
  --�J�E���^������p
  gt_plan_year                              xxcsm_item_plan_headers.plan_year%TYPE;    -- �\�Z�N�x
  gd_start_date                             DATE;
  gn_get_counter_data                       NUMBER;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_get_format     IN  VARCHAR2  -- ���̓t�H�[�}�b�g�p�^�[��
    ,in_file_id        IN  NUMBER    -- �t�@�C��ID
    ,ov_errbuf         OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode        OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg         OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_key_info      VARCHAR2(5000);  --key���
    lv_max_date      VARCHAR2(5000);  --MAX���t
    lv_tab_name      VARCHAR2(500);   --�e�[�u����
    lv_status        VARCHAR2(1);     --���ʊ֐��X�e�[�^�X
    lv_out_msg       VARCHAR2(2000);  -- ���b�Z�[�W
    ln_count         NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_login_base_cur
    IS
      SELECT lbi.base_code   AS base_code
        FROM xxcos_login_base_info_v lbi   --���O�C�����[�U���_�r���[
      ;
--
    -- ��v�J�����_���瓖�N�x�̌����擾
    CURSOR cur_get_month_this_year
    IS 
    SELECT   glpds.start_date                                   AS start_date  -- �N�x�J�n��
    FROM     gl_periods        glpds,                                          -- ��v�J�����_�e�[�u��
             gl_sets_of_books  glsob                                           -- ��v����}�X�^
    WHERE    glsob.set_of_books_id        = cn_gl_set_of_bks_id                -- ��v����ID
    AND      glpds.period_set_name        = glsob.period_set_name              -- �J�����_��
    AND      glpds.period_year            = gt_plan_year                       -- �\�Z�N�x
    AND      glpds.adjustment_period_flag = cv_no                              -- ������v���ԊO
    AND      glpds.period_num             = 1;                                 -- �N�x�J�n��
--
    rec_get_month_this_year cur_get_month_this_year%ROWTYPE;
    -- ��v�J�����_�����N�x�̌����擾
    CURSOR cur_get_month_last_year
    IS
    SELECT   glpds.start_date                                   AS start_date  -- �N�x�J�n��
    FROM     gl_periods        glpds,                                          -- ��v�J�����_�e�[�u��
             gl_sets_of_books  glsob                                           -- ��v����}�X�^
    WHERE    glsob.set_of_books_id        = cn_gl_set_of_bks_id                -- ��v����ID
    AND      glpds.period_set_name        = glsob.period_set_name              -- �J�����_��
    AND      glpds.period_year            = gt_plan_year - 1                   -- �\�Z�N�x
    AND      glpds.adjustment_period_flag = cv_no                              -- ������v���ԊO
    AND      glpds.period_num             = 1;                                 -- �N�x�J�n��
--
    rec_get_month_last_year cur_get_month_last_year%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--  ************************************************
    -- 1.�p�����[�^�o��
--  ************************************************
    --�R���J�����g�v���O�������͍��ڂ̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_xxcsm_appl_short_name
                  ,iv_name          => cv_msg_get_rep_h1
                  ,iv_token_name1   => cv_tkn_param1                 --�p�����[�^�P
                  ,iv_token_value1  => in_file_id                    --�t�@�C��ID
                  ,iv_token_name2   => cv_tkn_param2                 --�p�����[�^�Q
                  ,iv_token_value2  => iv_get_format                 --�t�H�[�}�b�g�p�^�[��
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
--  ************************************************
    -- 2.�Ɩ����t�擾
--  ************************************************
--
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
--  ************************************************
    --3.�t�@�C���A�b�v���[�h���́E�t�@�C�����o��
--  ************************************************
    ------------------------------------
    --3-1.�t�@�C���A�b�v���[�h���̎擾
    ------------------------------------
    BEGIN
      SELECT flv.meaning    AS upload_file_name
        INTO gv_upload_file_name
        FROM fnd_lookup_types  flt    --�N�C�b�N�^�C�v
            ,fnd_application   fa     --�A�v���P�[�V����
            ,fnd_lookup_values flv    --�N�C�b�N�R�[�h
       WHERE flt.lookup_type            = flv.lookup_type
         AND fa.application_short_name  = cv_xxccp_appl_short_name
         AND flt.application_id         = fa.application_id
         AND flt.lookup_type            = cv_look_file_upload_obj
         AND flv.lookup_code            = iv_get_format
         AND flv.language               = ct_user_lang
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_get_f_uplod_name_expt;
    END;
--
    ------------------------------------
    -- 3-2.CSV�t�@�C�����擾�����b�N�擾
    ------------------------------------
    BEGIN
      SELECT xmf.file_name  AS csv_file_name
        INTO gv_csv_file_name
        FROM xxccp_mrp_file_ul_interface xmf  --�t�@�C���A�b�v���[�hIF
       WHERE xmf.file_id = in_file_id
       FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_get_f_csv_name_expt;
      --*** ���b�N�擾�G���[�n���h�� ***
      WHEN global_data_lock_expt THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                                 iv_application => cv_xxcsm_appl_short_name
                                ,iv_name        => cv_msg_file_up_load
                               );
        RAISE global_data_lock_expt;
    END;
--
    --�A�b�v���[�h�t�@�C�����̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_xxcsm_appl_short_name
                  ,iv_name          => cv_msg_get_rep_h2
                  ,iv_token_name1   => cv_tkn_param3                 --�t�@�C���A�b�v���[�h����(���b�Z�[�W������)
                  ,iv_token_value1  => gv_upload_file_name           --�t�@�C���A�b�v���[�h����
                  ,iv_token_name2   => cv_tkn_param4                 --CSV�t�@�C����(���b�Z�[�W������)
                  ,iv_token_value2  => gv_csv_file_name              --CSV�t�@�C����
                 );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --1�s��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
--
--  ************************************************
    -- 4.�v���t�@�C���l�擾  ***
--  ************************************************
--
    ------------------------------------
    -- 4-1.XXCSM:�N�Ԕ̔��v��J�����_�[��
    ------------------------------------
    gv_prof_yearplan_calender := FND_PROFILE.VALUE(cv_prof_yearplan_calender);
    IF( gv_prof_yearplan_calender IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_xxcsm_appl_short_name
                     ,iv_name                 => cv_msg_profile_err
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_prof_yearplan_calender
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
--
    ------------------------------------
    -- 4-2.XXCSM:�_�~�[����K�w�Q��
    ------------------------------------
    gv_dummy_dept_ref := FND_PROFILE.VALUE( cv_xxcsm1_dummy_dept_ref );
    IF( gv_dummy_dept_ref IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_xxcsm_appl_short_name
                     ,iv_name                 => cv_msg_profile_err
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_xxcsm1_dummy_dept_ref
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
--
    ------------------------------------
    -- 4-3.GL��v����ID
    ------------------------------------
    gn_gl_set_of_bks_id         := FND_PROFILE.VALUE( cv_gl_set_of_bks_id_nm );
    IF( gn_gl_set_of_bks_id IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_xxcsm_appl_short_name
                     ,iv_name                 => cv_msg_profile_err
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_gl_set_of_bks_id_nm
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
--
--  ************************************************
    -- 5.�N�Ԕ̔��v��J�����_���݃`�F�b�N
--  ************************************************
    SELECT COUNT(*)  AS cnt
    INTO   ln_count
    FROM   fnd_flex_value_sets ffvs
    WHERE  flex_value_set_name = gv_prof_yearplan_calender
    ;
    -- �J�����_��`�����݂��Ȃ��ꍇ
    IF (ln_count = 0) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_xxcsm_appl_short_name
                     ,iv_name                 => cv_msg_not_exist_calendar
                     ,iv_token_name1          => cv_tkn_item
                     ,iv_token_value1         => gv_prof_yearplan_calender
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
--  ************************************************
    -- 6.�\�Z�N�x�擾
--  ************************************************
    xxcsm_common_pkg.get_yearplan_calender(
      id_comparison_date => gd_process_date        -- �^�p��
     ,ov_status          => lv_status              -- ��������(0�F����A1�F�ُ�)
     ,on_active_year     => gt_plan_year           -- �擾�����\�Z�N�x
     ,ov_retcode         => lv_retcode             -- ���^�[���R�[�h
     ,ov_errbuf          => lv_errbuf              -- �G���[���b�Z�[�W
     ,ov_errmsg          => lv_errmsg              -- ���[�U�[�E�G���[���b�Z�[�W
    );
    -- �\�Z�N�x�����݂��Ȃ��ꍇ
    IF ( lv_status <> cv_status_normal ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_xxcsm_appl_short_name
                     ,iv_name                 => cv_msg_plan_year_err
                     ,iv_token_name1          => cv_tkn_item
                     ,iv_token_value1         => gv_prof_yearplan_calender
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
--  ************************************************
    -- 7.���s���[�U�[�̋��_�擾
--  ************************************************
    -- ������
    lv_retcode    := NULL;  -- ���^�[���R�[�h
    lv_errbuf     := NULL;  -- �G���[���b�Z�[�W
    lv_errmsg     := NULL;  -- ���[�U�[�E�G���[���b�Z�[�W
    xxcsm_common_pkg.get_login_user_foothold(
       in_user_id         => fnd_global.user_id          -- ���[�U�[ID
      ,ov_foothold_code   => gv_user_base                -- ���_�R�[�h
      ,ov_employee_code   => gv_employee_code            -- �]�ƈ��R�[�h
      ,ov_retcode         => lv_retcode                  -- ���^�[���R�[�h
      ,ov_errbuf          => lv_errbuf                   -- �G���[���b�Z�[�W
      ,ov_errmsg          => lv_errmsg                   -- ���[�U�[�E�G���[���b�Z�[�W
    );
    -- ���O�C�����[�U�[�ݐЋ��_�����݂��Ȃ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_xxcsm_appl_short_name
                     ,iv_name                 => cv_msg_user_base_code
                     ,iv_token_name1          => cv_tkn_user_id
                     ,iv_token_value1         => fnd_global.user_id
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    IF ov_retcode = cv_status_error THEN
      RETURN;
    END IF;
    --
    --===============================================
    -- 8.�c�Ɗ�敔�A�n��c�ƊǗ����A���Ǘ������菈��
    --===============================================
    -- ������
    gv_sec_retcode    := NULL;  -- ���^�[���R�[�h
    lv_errbuf         := NULL;  -- �G���[���b�Z�[�W
    lv_errmsg         := NULL;  -- ���[�U�[�E�G���[���b�Z�[�W
    --
    xxcsm_common_pkg.year_item_plan_security(
       in_user_id          => fnd_global.user_id            --���[�UID
      ,ov_lv6_kyoten_list  => gv_no_flv_tag                 --�Z�L�����e�B�߂�l
      ,ov_retcode          => gv_sec_retcode                --���^�[���R�[�h
      ,ov_errbuf           => lv_errbuf                     --�G���[���b�Z�[�W
      ,ov_errmsg           => lv_errmsg                     --���[�U�[�E�G���[���b�Z�[�W
    );
    --��ʂɍ��킹�G���[����͂��Ȃ�
    --
--  ************************************************
    -- 9.�N�x�J�n���擾
--  ************************************************
    -- ������
    gd_start_date := NULL;
    -- �N�x�J�n�����擾
    OPEN cur_get_month_this_year;
    FETCH cur_get_month_this_year INTO rec_get_month_this_year;
    CLOSE cur_get_month_this_year;
    -- �N�x�J�n�����Z�b�g
    gd_start_date := rec_get_month_this_year.start_date;
    --
    -- ��v�J�����_�ɗ��N�x�̉�v���Ԃ���`����Ă��Ȃ������ꍇ
    IF (gd_start_date IS NULL) THEN
      -- �N�x�J�n�����擾
      OPEN cur_get_month_last_year;
      FETCH cur_get_month_last_year INTO rec_get_month_last_year;
      CLOSE cur_get_month_last_year;
      -- �N�x�J�n�����Z�b�g
      gd_start_date := rec_get_month_last_year.start_date;
    END IF;
--
--  ************************************************
    -- 10.���ڃ`�F�b�N�����b�Z�[�W�o�͗p�̍��ږ��̎擾
--  ************************************************
      --���_�R�[�h
      gv_base_code := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_base_code                      --���_�R�[�h
                     );
      --
      --�N�x
      gv_yaer := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_year                           --�N�x
                     );
      --�\�Z�敪
      gv_plan_kind := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_plan_kind                      --�\�Z�敪
                     );
      --���R�[�h�敪
      gv_record_kind := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_record_kind                    --���R�[�h�敪
                     );
      --����\�Z
      gv_sales_budget := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_sales_budget                   --����\�Z
                     );
      --�����l��
      gv_receipt_discount := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_receipt_discount               --�����l��
                     );
      --����l��
      gv_sales_discount := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_sales_discount                 --����l��
                     );
      --����
      gv_item_sales_budget := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_item_sales_budget              --����
                     );
      --�e���z
      gv_amount_gross_margin := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_amount_gross_margin            --�e���z
                     );
      --�e����
      gv_margin_rate := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_margin_rate                    --�e����
                     );
      --���_�v
      gv_loc_bdgt    := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_base_total                     --���_�v
                     );
--
    ------------------------------------
    -- ��O����
    ------------------------------------
  EXCEPTION
--
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_xxcsm_appl_short_name
                      ,iv_name          =>  cv_msg_process_date_err
                     );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode  :=  cv_status_error;
--
    --*** �t�@�C���A�b�v���[�h���̎擾�n���h�� ***
    WHEN global_get_f_uplod_name_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_upload_name_get
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode := cv_status_error;
--
    --*** CSV�t�@�C�����擾�n���h�� ***
    WHEN global_get_f_csv_name_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_get_f_csv_name
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => in_file_id
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode := cv_status_error;
--
    --*** ���b�N�擾�G���[�n���h�� ***
    WHEN global_data_lock_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_get_lock_err
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => lv_tab_name
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : �t�@�C���A�b�v���[�hIF�擾(A-2)
   ***********************************************************************************/
   PROCEDURE get_upload_data (
     in_file_id            IN  NUMBER       -- FILE_ID
    ,on_get_counter_data   OUT NUMBER       -- �f�[�^��
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
   )
   IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- �v���O������
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
    lv_tab_name      VARCHAR2(500);   --�e�[�u����
    lv_out_msg       VARCHAR2(2000);  -- ���b�Z�[�W
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
    ------------------------------------
    -- �N�ԏ��i�v��f�[�^�擾
    ------------------------------------
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id           -- �t�@�C���h�c
     ,ov_file_data => gt_plan_data         -- �N�ԏ��i�v��f�[�^(�z��^)
     ,ov_errbuf    => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --�߂�l�`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_file_up_load
                     );
      lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_get_data_err
                    ,iv_token_name1  => cv_tkn_table_name
                    ,iv_token_value1 => lv_tab_name
                    ,iv_token_name2  => cv_tkn_key_data
                    ,iv_token_value2 => in_file_id
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      RAISE global_api_expt;
    END IF;
    --
    -- �N�ԏ��i�v��f�[�^�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gt_plan_data.LAST < cn_begin_line ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcsm_appl_short_name
                      ,iv_name        => cv_msg_no_upload_date
                     );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    END IF;
--
    ------------------------------------
    -- �f�[�^�������̎擾
    ------------------------------------
    --�f�[�^������
    on_get_counter_data := gt_plan_data.COUNT;
    gn_target_cnt       := gt_plan_data.COUNT - 1;
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : del_upload_data
   * Description      : �A�b�v���[�h�f�[�^�폜����(A-3)
   ***********************************************************************************/
  PROCEDURE del_upload_data(
     in_file_id    IN  NUMBER    -- 1.FILE_ID
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_upload_data'; -- �v���O������
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
    lv_tab_name   VARCHAR2(100);    --�e�[�u����
    lv_key_info   VARCHAR2(100);    --�L�[���
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
    -- ************************************
    -- ***  �N�ԏ��i�v��f�[�^�폜����  ***
    -- ************************************
--
    BEGIN
      DELETE
        FROM xxccp_mrp_file_ul_interface xmf  --�t�@�C���A�b�v���[�hIF
       WHERE xmf.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --�L�[���̕ҏW����
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name
                       ,iv_name         => cv_msg_file_up_load
                     );
        lv_key_info := SQLERRM;
        RAISE global_del_ul_interface_expt;
    END;
--
  EXCEPTION
--
    --*** ���R�[�h�폜��O�n���h�� ***
    WHEN global_del_ul_interface_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_delete_data_err
                    ,iv_token_name1  => cv_tkn_table_name
                    ,iv_token_value1 => lv_tab_name
                    ,iv_token_name2  => cv_tkn_key_data
                    ,iv_token_value2 => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END del_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : split_plan_data
   * Description      : �N�ԏ��i�v��f�[�^�̍��ڕ�������(A-4)
   ***********************************************************************************/
  PROCEDURE split_plan_data(
     in_cnt        IN  NUMBER    -- �f�[�^��
    ,ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'split_plan_data'; -- �v���O������
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
--
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_rec_data     VARCHAR2(32765);
    lv_err_msg      VARCHAR2(5000);  --�G���[���b�Z�[�W
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
    <<get_plan_loop>>
    FOR i IN 1 .. in_cnt LOOP
--
      ------------------------------------
      -- �S���ڐ��`�F�b�N
      ------------------------------------
      IF ( ( NVL( LENGTH( gt_plan_data(i) ), 0 )
           - NVL( LENGTH( REPLACE( gt_plan_data(i), cv_comma, NULL ) ), 0 ) ) <> ( cn_c_header - 1 ) )
      THEN
        --�G���[
        lv_rec_data := gt_plan_data(i);
        lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name
                       ,iv_name         => cv_msg_chk_rec_err
                       ,iv_token_name1  => cv_tkn_data
                       ,iv_token_value1 => lv_rec_data
                      );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --�J��������
      FOR j IN 1 .. cn_c_header LOOP
--
        ------------------------------------
        -- ���ڕ���
        ------------------------------------
        gr_plan_work_data(i)(j) := TRIM( REPLACE( xxccp_common_pkg.char_delim_partition(
                                                     iv_char     => gt_plan_data(i)
                                                    ,iv_delim    => cv_comma
                                                    ,in_part_num => j
                                                  ) ,cv_dobule_quote, NULL
                                                )
                                       );
      END LOOP;
--
    END LOOP get_plan_loop;
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
  END split_plan_data;
--
  /**********************************************************************************
   * Procedure Name   : item_check
   * Description      : ���ڃ`�F�b�N(A-5)
   ***********************************************************************************/
  PROCEDURE item_check(
     in_cnt             IN  NUMBER    -- �f�[�^�J�E���^
    ,ov_base_code       OUT VARCHAR2  -- ���_�R�[�h
    ,ov_plan_year       OUT VARCHAR2  -- �N�x
    ,ov_plan_kind       OUT VARCHAR2  -- �\�Z�敪
    ,ov_record_kind     OUT VARCHAR2  -- ���R�[�h�敪
    ,on_may             OUT NUMBER    -- 5���\�Z
    ,on_jun             OUT NUMBER    -- 6���\�Z
    ,on_jul             OUT NUMBER    -- 7���\�Z
    ,on_aug             OUT NUMBER    -- 8���\�Z
    ,on_sep             OUT NUMBER    -- 9���\�Z
    ,on_oct             OUT NUMBER    -- 10���\�Z
    ,on_nov             OUT NUMBER    -- 11���\�Z
    ,on_dec             OUT NUMBER    -- 12���\�Z
    ,on_jan             OUT NUMBER    -- 1���\�Z
    ,on_feb             OUT NUMBER    -- 2���\�Z
    ,on_mar             OUT NUMBER    -- 3���\�Z
    ,on_apr             OUT NUMBER    -- 4���\�Z
    ,on_sum             OUT NUMBER    -- ���i�Q�N�Ԍv�\�Z
    ,ov_errbuf          OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode         OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg          OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                     CONSTANT VARCHAR2(100) := 'item_check'; -- �v���O������
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
    lv_err_msg         VARCHAR2(32767);  --�G���[���b�Z�[�W
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
    --������
    lv_err_msg := NULL;
--
    -- **********************
    -- ***  ���_�R�[�h  ***
    -- **********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_base_code)    -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_base_code)            -- 2.���ڂ̒l
     ,in_item_len     => cn_base_code_length                                -- 3.���ڂ̒���
     ,in_item_decimal => NULL                                               -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                       -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                      -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      -- ���ڕs���G���[���b�Z�[�W
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_base_code)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      ov_base_code := gr_plan_work_data(in_cnt)(cn_base_code);
    END IF;
--
    -- **********************
    -- ***  �N�x          ***
    -- **********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_plan_year)            -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_plan_year)                    -- 2.���ڂ̒l
     ,in_item_len     => cn_plan_year_length                                        -- 3.���ڂ̒���
     ,in_item_decimal => cn_plan_year_point                                         -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      -- ���ڕs���G���[���b�Z�[�W
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_plan_year)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      ov_plan_year := gr_plan_work_data(in_cnt)(cn_plan_year);
    END IF;
--
    -- ********************
    -- ***  �\�Z�敪    ***
    -- ********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_plan_kind)            -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_plan_kind)                    -- 2.���ڂ̒l
     ,in_item_len     => cn_plan_kind_length                                        -- 3.���ڂ̒���
     ,in_item_decimal => NULL                                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_plan_kind)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      ov_plan_kind := gr_plan_work_data(in_cnt)(cn_plan_kind);
    END IF;
--
    -- *********************
    -- ***  ���R�[�h�敪
    -- *********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_record_kind)          -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_record_kind)                  -- 2.���ڂ̒l
     ,in_item_len     => cn_rec_kind_length                                         -- 3.���ڂ̒���
     ,in_item_decimal => NULL                                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_record_kind)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      ov_record_kind := gr_plan_work_data(in_cnt)(cn_record_kind);
    END IF;
--
    -- **************
    -- ***  5���\�Z
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_may)             -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_may)                     -- 2.���ڂ̒l
     ,in_item_len     => cn_budget_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_budget_point                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_may)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_may := gr_plan_work_data(in_cnt)(cn_may);
    END IF;
--
    -- **************
    -- ***  6���\�Z
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_jun)             -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_jun)                     -- 2.���ڂ̒l
     ,in_item_len     => cn_budget_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_budget_point                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_jun)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_jun := gr_plan_work_data(in_cnt)(cn_jun);
    END IF;
--
    -- **************
    -- ***  7���\�Z
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_jul)             -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_jul)                     -- 2.���ڂ̒l
     ,in_item_len     => cn_budget_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_budget_point                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_jul)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_jul := gr_plan_work_data(in_cnt)(cn_jul);
    END IF;
--
     -- **************
    -- ***  8���\�Z
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_aug)             -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_aug)                     -- 2.���ڂ̒l
     ,in_item_len     => cn_budget_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_budget_point                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_aug)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_aug := gr_plan_work_data(in_cnt)(cn_aug);
    END IF;
--
    -- **************
    -- ***  9���\�Z
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_sep)             -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_sep)                     -- 2.���ڂ̒l
     ,in_item_len     => cn_budget_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_budget_point                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_sep)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_sep := gr_plan_work_data(in_cnt)(cn_sep);
    END IF;
--
    -- **************
    -- ***  10���\�Z
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_oct)             -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_oct)                     -- 2.���ڂ̒l
     ,in_item_len     => cn_budget_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_budget_point                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_oct)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_oct := gr_plan_work_data(in_cnt)(cn_oct);
    END IF;
--
    -- **************
    -- ***  11���\�Z
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_nov)             -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_nov)                     -- 2.���ڂ̒l
     ,in_item_len     => cn_budget_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_budget_point                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_nov)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_nov := gr_plan_work_data(in_cnt)(cn_nov);
    END IF;
--
    -- **************
    -- ***  12���\�Z
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_dec)             -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_dec)                     -- 2.���ڂ̒l
     ,in_item_len     => cn_budget_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_budget_point                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_dec)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_dec := gr_plan_work_data(in_cnt)(cn_dec);
    END IF;
--
    -- **************
    -- ***  1���\�Z
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_jan)             -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_jan)                     -- 2.���ڂ̒l
     ,in_item_len     => cn_budget_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_budget_point                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_jan)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_jan := gr_plan_work_data(in_cnt)(cn_jan);
    END IF;
--
    -- **************
    -- ***  2���\�Z
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_feb)             -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_feb)                     -- 2.���ڂ̒l
     ,in_item_len     => cn_budget_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_budget_point                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_feb)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_feb := gr_plan_work_data(in_cnt)(cn_feb);
    END IF;
--
    -- **************
    -- ***  3���\�Z
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_mar)             -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_mar)                     -- 2.���ڂ̒l
     ,in_item_len     => cn_budget_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_budget_point                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_mar)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_mar := gr_plan_work_data(in_cnt)(cn_mar);
    END IF;
--
    -- **************
    -- ***  4���\�Z
    -- **************
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_plan_work_data(cn_item_header)(cn_apr)             -- 1.���ږ���
     ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_apr)                     -- 2.���ڂ̒l
     ,in_item_len     => cn_budget_length                                      -- 3.���ڂ̒���
     ,in_item_decimal => cn_budget_point                                       -- 4.���ڂ̒���(�����_�ȉ�)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.�K�{�t���O
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.���ڑ���
     ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    --���[�j���O
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_apr)  -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                      , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                      , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_err_msg
      );
    --���ʊ֐��G���[
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --����I��
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --�l��ԋp
      on_apr := gr_plan_work_data(in_cnt)(cn_apr);
    END IF;
--
    IF ( gr_plan_work_data(in_cnt)(cn_plan_kind) = gv_loc_bdgt ) THEN
      on_sum := NULL;
    ELSE
      -- **************
      -- ***  ���i�Q�N�Ԍv�\�Z
      -- **************
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_plan_work_data(cn_item_header)(cn_sum)             -- 1.���ږ���
       ,iv_item_value   => gr_plan_work_data(in_cnt)(cn_sum)                     -- 2.���ڂ̒l
       ,in_item_len     => cn_budget_length                                      -- 3.���ڂ̒���
       ,in_item_decimal => cn_budget_point                                       -- 4.���ڂ̒���(�����_�ȉ�)
       ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                          -- 5.�K�{�t���O
       ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                         -- 6.���ڑ���
       ,ov_errbuf       => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode      => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg       => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      --���[�j���O
      IF ( lv_retcode = cv_status_warn ) THEN
        lv_err_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcsm_appl_short_name             -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_msg_get_format_err                -- ���b�Z�[�W�R�[�h
                        , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                        , iv_token_value1 => gr_plan_work_data(cn_item_header)(cn_sum)  -- �g�[�N���l1
                        , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                        , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                        , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                        , iv_token_value3 => in_cnt                               -- �g�[�N���l3�i���o�����݂̍s���j
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
      --���ʊ֐��G���[
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --����I��
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        --�l��ԋp
        on_sum := gr_plan_work_data(in_cnt)(cn_sum);
      END IF;
--
    END IF;
--
    --���[�j���O���b�Z�[�W�m�F
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
  EXCEPTION
--
    -- *** ���ڃ`�F�b�N�G���[�n���h�� ***
    WHEN global_item_check_expt THEN
      ov_retcode := cv_status_check;
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
  END item_check;
--
  /**********************************************************************************
   * Procedure Name   : ins_plan_tmp
   * Description      : ���i�v��A�b�v���[�h���[�N�o�^����(A-6)
   ***********************************************************************************/
  PROCEDURE ins_plan_tmp(
     in_cnt                   IN  NUMBER    -- �f�[�^�J�E���^
    ,iv_base_code             IN  VARCHAR2  -- ���_�R�[�h
    ,iv_plan_year             IN  VARCHAR2  -- �N�x
    ,iv_plan_kind             IN  VARCHAR2  -- �\�Z�敪
    ,iv_record_kind           IN  VARCHAR2  -- ���R�[�h�敪
    ,in_may                   IN  NUMBER    -- 5���\�Z
    ,in_jun                   IN  NUMBER    -- 6���\�Z
    ,in_jul                   IN  NUMBER    -- 7���\�Z
    ,in_aug                   IN  NUMBER    -- 8���\�Z
    ,in_sep                   IN  NUMBER    -- 9���\�Z
    ,in_oct                   IN  NUMBER    -- 10���\�Z
    ,in_nov                   IN  NUMBER    -- 11���\�Z
    ,in_dec                   IN  NUMBER    -- 12���\�Z
    ,in_jan                   IN  NUMBER    -- 1���\�Z
    ,in_feb                   IN  NUMBER    -- 2���\�Z
    ,in_mar                   IN  NUMBER    -- 3���\�Z
    ,in_apr                   IN  NUMBER    -- 4���\�Z
    ,in_sum                   IN  NUMBER    -- ���i�Q�N�ԗ\�Z
    ,ov_errbuf                OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode               OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg                OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_plan_tmp'; -- �v���O������
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
    lv_err_msg         VARCHAR2(32767);  --�G���[���b�Z�[�W
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --������
    lv_err_msg := NULL;
--
    BEGIN
      INSERT INTO xxcsm_plan_tmp(
          record_id           -- 01:���R�[�hNo.
         ,base_code           -- 02:���_�R�[�h
         ,plan_year           -- 03:�N�x
         ,plan_kind           -- 04:�\�Z�敪
         ,record_kind         -- 05:���R�[�h�敪
         ,plan_may            -- 06:5���\�Z
         ,plan_jun            -- 07:6���\�Z
         ,plan_jul            -- 08:7���\�Z
         ,plan_aug            -- 09:8���\�Z
         ,plan_sep            -- 10:9���\�Z
         ,plan_oct            -- 11:10���\�Z
         ,plan_nov            -- 12:11���\�Z
         ,plan_dec            -- 13:12���\�Z
         ,plan_jan            -- 14:1���\�Z
         ,plan_feb            -- 15:2���\�Z
         ,plan_mar            -- 16:3���\�Z
         ,plan_apr            -- 17:4���\�Z
         ,plan_sum            -- 18:���i�Q�N�Ԍv
         ) VALUES (
          in_cnt               -- 01:���R�[�hNo.
         ,iv_base_code         -- 02:���_�R�[�h
         ,iv_plan_year         -- 03:�N�x
         ,iv_plan_kind         -- 04:�\�Z�敪
         ,iv_record_kind       -- 05:���R�[�h�敪
         ,in_may               -- 06:5���\�Z
         ,in_jun               -- 07:6���\�Z
         ,in_jul               -- 08:7���\�Z
         ,in_aug               -- 09:8���\�Z
         ,in_sep               -- 10:9���\�Z
         ,in_oct               -- 11:10���\�Z
         ,in_nov               -- 12:11���\�Z
         ,in_dec               -- 13:12���\�Z
         ,in_jan               -- 14:1���\�Z
         ,in_feb               -- 15:2���\�Z
         ,in_mar               -- 16:3���\�Z
         ,in_apr               -- 17:4���\�Z
         ,in_sum               -- 18:���i�Q�N�Ԍv
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        --
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_xxcsm_appl_short_name, cv_msg_tmp_tbl );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_xxcsm_appl_short_name, cv_msg_add_err, cv_tkn_table, gv_tkn1 );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
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
  END ins_plan_tmp;
--
  /**********************************************************************************
   * Procedure Name   : chk_base_code
   * Description      : ���_�R�[�h�A�N�x�`�F�b�N����(A-8)
   ***********************************************************************************/
  PROCEDURE chk_base_code(
     ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_base_code'; -- �v���O������
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
    -- �Z�L�����e�B����p
    cv_kyoten                         CONSTANT VARCHAR2(1)  := '1';     -- ���_
    cv_security_mgr                   CONSTANT VARCHAR2(1)  := '2';     -- �Ǘ������_
    cv_security_etc                   CONSTANT VARCHAR2(1)  := '3';     -- �c�Ɗ�敔�A�n��c�ƊǗ����A���Ǘ����ȊO
    -- �����X�e�[�^�X
    cv_msg_retcode_ok                 CONSTANT VARCHAR2(1)  := '0';     -- ����
    cv_msg_retcode_alert              CONSTANT VARCHAR2(1)  := '1';     -- �x��
--
    -- *** ���[�J���ϐ� ***
    lv_chk_status         VARCHAR2(1);
    ln_sec_cnt            NUMBER;
    lt_account_number     hz_cust_accounts.account_number%TYPE;
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
    lv_chk_status := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<chk_base_code_loop>>
    FOR i IN 1.. gn_target_cnt LOOP
--
      -- ***********************************
      -- ***  ���_�R�[�h�A�N�x�`�F�b�N
      -- ***********************************
      IF ( i = 1 ) THEN
        -- 1�s�ڂ̃`�F�b�N
        -- **********************
        -- ���_�Z�L�����e�B�`�F�b�N
        -- **********************
        IF ( gv_no_flv_tag = cv_security_mgr -- 2�F�Ǘ������_
          OR gv_no_flv_tag = cv_security_etc -- 3�F���̑�
          OR gv_sec_retcode = cv_msg_retcode_alert )
        THEN
          IF ( gv_dummy_dept_ref = cv_yes ) THEN
          -- �_�~�[�K�w�g�p
            SELECT  COUNT(1)                    AS sec_cnt
              INTO  ln_sec_cnt
              FROM (SELECT  flv.description     AS account_number
                      FROM  fnd_lookup_values   flv
                     WHERE  flv.language        = ct_user_lang
                       AND  flv.lookup_type     = cv_look_dummy_dept
                       AND  flv.enabled_flag    = 'Y'
                       AND  flv.attribute2      = gv_user_base
                   UNION ALL
                    SELECT  hca.account_number  AS account_number
                      FROM  apps.hz_cust_accounts    hca
                           ,apps.hz_parties          hps
                           ,apps.xxcmm_cust_accounts xca
                     WHERE  hca.party_id              = hps.party_id
                       AND  hca.cust_account_id       = xca.customer_id
                       AND (hps.duns_number_c <> '90'
                        OR  hps.duns_number_c IS NULL)
                       AND (xca.management_base_code  = gv_user_base
                        OR  hca.account_number        = gv_user_base))
             WHERE  account_number = gr_plan_tmps_tab(i).base_code
            ;
          ELSE
            -- �_�~�[�K�w���g�p
            SELECT COUNT(1)                    AS sec_cnt
              INTO  ln_sec_cnt
              FROM (SELECT  hca.account_number AS account_number
                      FROM  hz_cust_accounts   hca
                           ,hz_parties         hps
                     WHERE  hca.party_id       = hps.party_id
                       AND  hca.customer_class_code = '1'
                       AND (hps.duns_number_c <> '90'
                        OR  hps.duns_number_c IS NULL)
                       AND  hca.account_number = gv_user_base
                   UNION ALL
                    SELECT  hca.account_number  AS account_number
                      FROM  hz_cust_accounts    hca
                           ,hz_parties          hps
                           ,xxcmm_cust_accounts xca
                     WHERE  hca.party_id              = hps.party_id
                       AND  hca.cust_account_id      = xca.customer_id
                       AND  hca.customer_class_code = '1'
                       AND (hps.duns_number_c <> '90'
                        OR  hps.duns_number_c IS NULL)
                       AND  xca.management_base_code = gv_user_base)
              WHERE  account_number = gr_plan_tmps_tab(i).base_code
            ;
          END IF;
        ELSE
        -- �c�Ɗ�敔�A�n��c�ƊǗ����A���Ǘ���
          SELECT COUNT(1)                    AS sec_cnt
            INTO  ln_sec_cnt
          FROM   hz_cust_accounts    hca
                ,hz_parties          hps
          WHERE  hca.party_id            = hps.party_id
            AND  hca.customer_class_code = '1'
            AND (hps.duns_number_c <> '90'
             OR  hps.duns_number_c IS NULL)
            AND  hca.account_number = gr_plan_tmps_tab(i).base_code
          ;
        END IF;
        --
        IF ( ln_sec_cnt = 0 ) THEN
          --���b�Z�[�W���̕ҏW����
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcsm_appl_short_name
                        ,iv_name          => cv_msg_security_err                  -- ���_�Z�L�����e�B�G���[
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- **********************
        -- �N�x�`�F�b�N
        -- **********************
        IF gr_plan_tmps_tab(i).plan_year <> gt_plan_year THEN
          -- �N�x�G���[���b�Z�[�W�o�͂��A�ُ�I��
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_budget_year_err   -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_yosan_nendo       -- �g�[�N���R�[�h1
                         , iv_token_value1 => TO_CHAR(gt_plan_year)    -- �g�[�N���l1�i�\�Z�N�x�j
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
      ELSE
        IF lv_chk_status = cv_status_normal THEN
          --����̏ꍇ�̂݃`�F�b�N�𑱂���i��ʃ��b�Z�[�W�o�͗}�~�j
          --2�s�ڈȍ~�̃`�F�b�N
          --���_�R�[�h�`�F�b�N
          IF gr_plan_tmps_tab(i).base_code <> gr_plan_tmps_tab(1).base_code THEN
            --�������_�w��s�G���[���b�Z�[�W���o�͂��������~
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_multi_base_code_err  -- ���b�Z�[�W�R�[�h
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
            lv_chk_status := cv_status_check;
          END IF;
          --�N�x�`�F�b�N
          IF gr_plan_tmps_tab(i).plan_year <> gr_plan_tmps_tab(1).plan_year THEN
            --�����\�Z�N�x�w��s�G���[���b�Z�[�W���o�͂��������~
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm_appl_short_name   -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_multi_year_err      -- ���b�Z�[�W�R�[�h
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
            lv_chk_status := cv_status_check;
          END IF;
          --
        END IF;
        --
      END IF;
--
    END LOOP chk_base_code_loop;
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
  END chk_base_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_record_kind
   * Description      : ���R�[�h�敪�`�F�b�N����(A-9)
   ***********************************************************************************/
  PROCEDURE chk_record_kind(
     ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_record_kind'; -- �v���O������
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
    -- ���_�v�A���i�Q���Ƃ̃��R�[�h�敪�������i�[���郌�R�[�h
    TYPE l_plan_kind_rtype IS RECORD (
      plan_kind             VARCHAR2(50)  --���_�v   or ���i�Q�R�[�h
     ,record_kind_a         NUMBER        --����l�� or ����
     ,record_kind_b         NUMBER        --�����l�� or �e���z
     ,record_kind_c         NUMBER        --����\�Z or �e����
     ,else_kind             NUMBER
    );
    -- ���_�A�N�x�A�\�Z�敪�i���i�Q�j���Ƃ̃��R�[�h�敪�������i�[���郌�R�[�h
    TYPE l_plan_kind_ttype IS TABLE OF l_plan_kind_rtype INDEX BY BINARY_INTEGER;
    l_plan_kind_tab   l_plan_kind_ttype;
    --
    ln_plan_cnt                 NUMBER;
    --�O���R�[�h�ێ�
    lv_before_plan_kind         VARCHAR2(20);              -- �\�Z�敪
    --
    lv_record_kind_a_name       VARCHAR2(20);
    lv_record_kind_b_name       VARCHAR2(20);
    lv_record_kind_c_name       VARCHAR2(20);
--
    lv_plan_kind_kyoten         VARCHAR2(1);
    lv_plan_kind_item_group     VARCHAR2(1);
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
    -- ������
    lv_before_plan_kind     := cv_blank;
    ln_plan_cnt             := 0;
    lv_plan_kind_kyoten     := cv_no;
    lv_plan_kind_item_group := cv_no;
--
    <<chk_record_kind_loop>>
    FOR i IN 1.. gn_target_cnt LOOP
--
      -- �O�񏈗��\�Z�敪�ƈقȂ�΁A���R�[�h�敪�������[�N������
      IF lv_before_plan_kind <> gr_plan_tmps_tab(i).plan_kind THEN
        ln_plan_cnt := ln_plan_cnt + 1;
        l_plan_kind_tab(ln_plan_cnt).plan_kind     := gr_plan_tmps_tab(i).plan_kind;
        l_plan_kind_tab(ln_plan_cnt).record_kind_a := 0;
        l_plan_kind_tab(ln_plan_cnt).record_kind_b := 0;
        l_plan_kind_tab(ln_plan_cnt).record_kind_c := 0;
        l_plan_kind_tab(ln_plan_cnt).else_kind     := 0;
      END IF;
      --
      --���R�[�h�敪���肨��у��R�[�h�敪���C���N�������g
      IF gr_plan_tmps_tab(i).plan_kind = gv_loc_bdgt THEN              --���_�v
        IF gr_plan_tmps_tab(i).record_kind = gv_sales_discount THEN       --����l��
          l_plan_kind_tab(ln_plan_cnt).record_kind_a := l_plan_kind_tab(ln_plan_cnt).record_kind_a + 1;
        ELSIF gr_plan_tmps_tab(i).record_kind = gv_receipt_discount THEN  --�����l��
          l_plan_kind_tab(ln_plan_cnt).record_kind_b := l_plan_kind_tab(ln_plan_cnt).record_kind_b + 1;
        ELSIF gr_plan_tmps_tab(i).record_kind = gv_sales_budget THEN      --����\�Z
          l_plan_kind_tab(ln_plan_cnt).record_kind_c := l_plan_kind_tab(ln_plan_cnt).record_kind_c + 1;
        ELSE
          l_plan_kind_tab(ln_plan_cnt).else_kind := l_plan_kind_tab(ln_plan_cnt).else_kind + 1;
        END IF;
      ELSE                                                              --���i�Q�R�[�h
        IF gr_plan_tmps_tab(i).record_kind = gv_item_sales_budget THEN       --����
          l_plan_kind_tab(ln_plan_cnt).record_kind_a := l_plan_kind_tab(ln_plan_cnt).record_kind_a + 1;
        ELSIF gr_plan_tmps_tab(i).record_kind = gv_amount_gross_margin THEN  --�e���z
          l_plan_kind_tab(ln_plan_cnt).record_kind_b := l_plan_kind_tab(ln_plan_cnt).record_kind_b + 1;
        ELSIF gr_plan_tmps_tab(i).record_kind = gv_margin_rate THEN          --�e����
          l_plan_kind_tab(ln_plan_cnt).record_kind_c := l_plan_kind_tab(ln_plan_cnt).record_kind_c + 1;
        ELSE
          l_plan_kind_tab(ln_plan_cnt).else_kind := l_plan_kind_tab(ln_plan_cnt).else_kind + 1;
        END IF;
      END IF;
      --
      lv_before_plan_kind := gr_plan_tmps_tab(i).plan_kind;
      --
    END LOOP  chk_record_kind_loop;
    --
    --�Ώۃ��R�[�h�敪�̌����G���[�����O�o��
    << outlog_loop >>
    FOR i IN 1..l_plan_kind_tab.COUNT LOOP
      IF l_plan_kind_tab(i).plan_kind = gv_loc_bdgt THEN              --���_�v
        lv_record_kind_a_name := gv_sales_discount;
        lv_record_kind_b_name := gv_receipt_discount;
        lv_record_kind_c_name := gv_sales_budget;
        lv_plan_kind_kyoten   := cv_yes;
      ELSE
        lv_record_kind_a_name   := gv_item_sales_budget;
        lv_record_kind_b_name   := gv_amount_gross_margin;
        lv_record_kind_c_name   := gv_margin_rate;
        lv_plan_kind_item_group := cv_yes;
      END IF;
      --
      -- ����l��or���ヌ�R�[�h
      IF l_plan_kind_tab(i).record_kind_a = 0 THEN
        --�����݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_no_found_rec_kubun     -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind              -- �g�[�N���R�[�h1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- �g�[�N���l1�i�\�Z�敪�j
                       , iv_token_name2  => cv_tkn_record_kind            -- �g�[�N���R�[�h2
                       , iv_token_value2 => lv_record_kind_a_name         -- �g�[�N���l2�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF l_plan_kind_tab(i).record_kind_a > 1 THEN
        --�������݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_too_many_rec_kubun     -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind              -- �g�[�N���R�[�h1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- �g�[�N���l1�i�\�Z�敪�j
                       , iv_token_name2  => cv_tkn_record_kind            -- �g�[�N���R�[�h2
                       , iv_token_value2 => lv_record_kind_a_name         -- �g�[�N���l2�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- �����l��or�e���z���R�[�h
      IF l_plan_kind_tab(i).record_kind_b = 0 THEN
        --�����݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_no_found_rec_kubun     -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind              -- �g�[�N���R�[�h1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- �g�[�N���l1�i�\�Z�敪�j
                       , iv_token_name2  => cv_tkn_record_kind            -- �g�[�N���R�[�h2
                       , iv_token_value2 => lv_record_kind_b_name         -- �g�[�N���l2�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF l_plan_kind_tab(i).record_kind_b > 1 THEN
        --�������݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_too_many_rec_kubun     -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind              -- �g�[�N���R�[�h1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- �g�[�N���l1�i�\�Z�敪�j
                       , iv_token_name2  => cv_tkn_record_kind            -- �g�[�N���R�[�h2
                       , iv_token_value2 => lv_record_kind_b_name         -- �g�[�N���l2�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- ����\�Zor�e�������R�[�h
      IF l_plan_kind_tab(i).record_kind_c = 0 THEN
        --�����݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_no_found_rec_kubun     -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind              -- �g�[�N���R�[�h1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- �g�[�N���l1�i�\�Z�敪�j
                       , iv_token_name2  => cv_tkn_record_kind            -- �g�[�N���R�[�h2
                       , iv_token_value2 => lv_record_kind_c_name         -- �g�[�N���l2�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF l_plan_kind_tab(i).record_kind_c > 1 THEN
        --�������݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_too_many_rec_kubun     -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind              -- �g�[�N���R�[�h1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- �g�[�N���l1�i�\�Z�敪�j
                       , iv_token_name2  => cv_tkn_record_kind            -- �g�[�N���R�[�h2
                       , iv_token_value2 => lv_record_kind_c_name         -- �g�[�N���l2�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- ����l���A�����l���A����\�Z�A����A�e���z�A�e�����ȊO�̃��R�[�h���݃G���[
      IF l_plan_kind_tab(i).else_kind > 0 THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name      -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_fail_rec_kubun         -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind              -- �g�[�N���R�[�h1
                       , iv_token_value1 => l_plan_kind_tab(i).plan_kind  -- �g�[�N���l1�i�\�Z�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
    END LOOP  outlog_loop;
    --
    --�\�Z�敪�`�F�b�N
    --�u���_�v�v�\�Z���݃`�F�b�N
    IF lv_plan_kind_kyoten = cv_no THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm_appl_short_name      -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_no_plan_kind_err       -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_plan_kind              -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_sum_kyoten                 -- �g�[�N���l1�i���_�v�j
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_check;
    END IF;
    --
    --���i�Q�\�Z���݃`�F�b�N
    IF lv_plan_kind_item_group = cv_no THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcsm_appl_short_name      -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_no_plan_kind_err       -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_plan_kind              -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_item_group                 -- �g�[�N���l1�i���i�Q�j
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_check;
    END IF;
    --
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
  END chk_record_kind;
--
  /**********************************************************************************
   * Procedure Name   : chk_master_data
   * Description      : ���i�Q�}�X�^�`�F�b�N����(A-10)
   ***********************************************************************************/
  PROCEDURE chk_master_data(
     ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_master_data'; -- �v���O������
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
    lt_item_group_nm        xxcsm_item_group_3_nm_v.item_group_nm%TYPE;
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
    <<chk_master_data_loop>>
    FOR i IN 4.. gn_target_cnt LOOP
      IF MOD(i, 3) <> 1 THEN
        CONTINUE;
      END IF;
      --
      -- ***********************************
      -- ***  ���i�Q�}�X�^���݃`�F�b�N
      -- ***********************************
      BEGIN
        SELECT item_group_nm  AS item_group_nm
        INTO   lt_item_group_nm
        FROM   xxcsm_item_group_3_nm_v
        WHERE item_group_cd = gr_plan_tmps_tab(i).plan_kind
        ;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --���i�Q���}�X�^�ɑ��݂��܂���
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name                     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_master_err                            -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_deal_cd                               -- �g�[�N���R�[�h1
                         , iv_token_value1 => gr_plan_tmps_tab(i).plan_kind                -- �g�[�N���l1�i���i�Q�j
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
      END;
      --
    END LOOP  chk_master_data_loop;
    --
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
  END chk_master_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_budget_value
   * Description      : �\�Z�l�`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_budget_value(
     ov_errbuf               OUT VARCHAR2    -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2    -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_plan_kind            IN  VARCHAR2    -- ���_�v or ���i�Q
    ,iv_month                IN  VARCHAR2    -- ��
    ,in_value1               IN  NUMBER      -- ����l�� or ����
    ,in_value2               IN  NUMBER      -- �����l�� or �e���z
    ,in_value3               IN  NUMBER      -- ����\�Z or �e����
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_budget_value'; -- �v���O������
    --
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- ���b�Z�[�W
    lb_retcode       BOOLEAN;             -- API���^�[���E���b�Z�[�W�p
    --
    ln_cnt           NUMBER;              -- �J�E���^
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    IF iv_plan_kind = gv_loc_bdgt THEN
      -------------------------------------------------
      -- 1.���_�v�̗\�Z�l�`�F�b�N
      -------------------------------------------------
      --����l���`�F�b�N
      IF in_value1 IS NULL THEN
        --����l�����w�肵�Ă�������
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_null_err             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_sales_discount
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
        --
      ELSE
        -- �v���X�l�s�`�F�b�N
        IF in_value1 > 0 THEN
          --0���傫���l�͎w��ł��܂���
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_disconut_item_err    -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_plan_kind
                         , iv_token_value1 => iv_plan_kind
                         , iv_token_name2  => cv_tkn_month
                         , iv_token_value2 => iv_month
                         , iv_token_name3  => cv_tkn_column
                         , iv_token_value3 => gv_sales_discount
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- �����_�ȉ��`�F�b�N
        IF MOD(ABS(in_value1), 1) > 0 THEN
          --�����_�ȉ����w��ł��܂���
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_decimal_point_err    -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_sales_discount
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- ���e�͈̓`�F�b�N
        IF in_value1 < cn_min_discount THEN
          --����l�������e�͈͂𒴂��Ă��܂�
          lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application          => cv_xxcsm_appl_short_name
                        ,iv_name                 => cv_msg_value_over_err
                        ,iv_token_name1          => cv_tkn_plan_kind
                        ,iv_token_value1         => iv_plan_kind
                        ,iv_token_name2          => cv_tkn_month
                        ,iv_token_value2         => iv_month
                        ,iv_token_name3          => cv_tkn_column
                        ,iv_token_value3         => gv_sales_discount
                        ,iv_token_name4          => cv_tkn_min
                        ,iv_token_value4         => TO_CHAR(cn_min_discount)
                        ,iv_token_name5          => cv_tkn_max
                        ,iv_token_value5         => TO_CHAR(cn_max_discount)
                        ,iv_token_name6          => cv_tkn_value
                        ,iv_token_value6         => TO_CHAR(in_value1)
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
      END IF;
      --
      --�����l���`�F�b�N
      IF in_value2 IS NULL THEN
        --�����l�����w�肵�Ă�������
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_null_err             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_receipt_discount
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
        --
      ELSE
        -- �v���X�l�s�`�F�b�N
        IF in_value2 > 0 THEN
          --0���傫���l�͎w��ł��܂���
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_disconut_item_err    -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_plan_kind
                         , iv_token_value1 => iv_plan_kind
                         , iv_token_name2  => cv_tkn_month
                         , iv_token_value2 => iv_month
                         , iv_token_name3  => cv_tkn_column
                         , iv_token_value3 => gv_receipt_discount
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- �����_�ȉ��`�F�b�N
        IF MOD(ABS(in_value2), 1) > 0 THEN
          --�����_�ȉ����w��ł��܂���
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_decimal_point_err    -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_receipt_discount
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- ���e�͈̓`�F�b�N
        IF in_value2 < cn_min_discount THEN
          --�����l�������e�͈͂𒴂��Ă��܂�
          lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application          => cv_xxcsm_appl_short_name
                        ,iv_name                 => cv_msg_value_over_err
                        ,iv_token_name1          => cv_tkn_plan_kind
                        ,iv_token_value1         => iv_plan_kind
                        ,iv_token_name2          => cv_tkn_month
                        ,iv_token_value2         => iv_month
                        ,iv_token_name3          => cv_tkn_column
                        ,iv_token_value3         => gv_receipt_discount
                        ,iv_token_name4          => cv_tkn_min
                        ,iv_token_value4         => TO_CHAR(cn_min_discount)
                        ,iv_token_name5          => cv_tkn_max
                        ,iv_token_value5         => TO_CHAR(cn_max_discount)
                        ,iv_token_name6          => cv_tkn_value
                        ,iv_token_value6         => TO_CHAR(in_value2)
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
      END IF;
      --
      --����\�Z�`�F�b�N
      IF in_value3 IS NULL THEN
        --����\�Z���w�肵�Ă�������
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_null_err             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_sales_budget
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
        --
      ELSE
        -- ����\�Z�}�C�i�X�s�`�F�b�N
        IF in_value3 < 0 THEN
          --����\�Z��0�ȏ��ݒ肵�Ă�������
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_sales_budget_err     -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_plan_kind
                         , iv_token_value1 => iv_plan_kind
                         , iv_token_name2  => cv_tkn_month
                         , iv_token_value2 => iv_month
                         , iv_token_name3  => cv_tkn_column
                         , iv_token_value3 => gv_sales_budget
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- ����\�Z�����_�ȉ��`�F�b�N
        IF MOD(in_value3, 1) > 0 THEN
          --����\�Z�͏����_�ȉ����w��ł��܂���
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_decimal_point_err    -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_sales_budget
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
          --
        END IF;
        --
      END IF;
      --
    ELSE
      -------------------------------------------------
      -- 2.���i�Q�̗\�Z�l�`�F�b�N
      -------------------------------------------------
      --����`�F�b�N
      IF in_value1 IS NULL THEN
        --������w�肵�Ă�������
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_null_err             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_item_sales_budget
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
        --
      ELSE
        -- ����}�C�i�X�s�`�F�b�N
        IF in_value1 < 0 THEN
          --�����0�ȏ��ݒ肵�Ă�������
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_sales_budget_err     -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_plan_kind
                         , iv_token_value1 => iv_plan_kind
                         , iv_token_name2  => cv_tkn_month
                         , iv_token_value2 => iv_month
                         , iv_token_name3  => cv_tkn_column
                         , iv_token_value3 => gv_item_sales_budget
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        -- ���㏬���_�ȉ��`�F�b�N
        IF MOD(in_value1, 1) > 0 THEN
          --����͏����_�ȉ����w��ł��܂���
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_decimal_point_err    -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_plan_kind
                       , iv_token_value1 => iv_plan_kind
                       , iv_token_name2  => cv_tkn_month
                       , iv_token_value2 => iv_month
                       , iv_token_name3  => cv_tkn_column
                       , iv_token_value3 => gv_item_sales_budget
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
          --
        END IF;
      --
      END IF;
      --
      --�e���z�A�e����
      SELECT NVL2(in_value2, 1, 0) + NVL2(in_value3, 1, 0)  AS rec_cnt
      INTO  ln_cnt
      FROM  dual
      ;
      IF ln_cnt = 1 THEN
        IF in_value2 IS NOT NULL THEN
          -- �e���z�����_�ȉ��`�F�b�N
          IF MOD(in_value2, 1) > 0 THEN
            --�e���z�͏����_�ȉ����w��ł��܂���
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name    -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_decimal_point_err    -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_plan_kind
                         , iv_token_value1 => iv_plan_kind
                         , iv_token_name2  => cv_tkn_month
                         , iv_token_value2 => iv_month
                         , iv_token_name3  => cv_tkn_column
                         , iv_token_value3 => gv_amount_gross_margin
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
          END IF;
          --
        END IF;
        --
      ELSE
        -- 1���ڎw��`�F�b�N
        --�e���z�A�e�����͂����ꂩ1���ڂ�ݒ肵�Ă�������
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_xxcsm_appl_short_name
                       ,iv_name                 => cv_msg_multi_designation_err
                       ,iv_token_name1          => cv_tkn_plan_kind
                       ,iv_token_value1         => iv_plan_kind
                       ,iv_token_name2          => cv_tkn_month
                       ,iv_token_value2         => iv_month
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||'���i�Q='||iv_plan_kind||' ��='||iv_month||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END chk_budget_value;
--
  /**********************************************************************************
   * Procedure Name   : chk_budget_item
   * Description      : �\�Z���ڃ`�F�b�N����(A-11)
   ***********************************************************************************/
  PROCEDURE chk_budget_item(
     ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_budget_item'; -- �v���O������
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
    ln_max_column           NUMBER;
    lv_month                VARCHAR(100);
    lv_plan_kind            VARCHAR(100);
    ln_value1               NUMBER;
    ln_value2               NUMBER;
    ln_value3               NUMBER;
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
    <<chk_budget_value_loop>>
    FOR i IN 1.. gn_target_cnt LOOP
      IF MOD(i, 3) <> 1 THEN
        CONTINUE;
      END IF;
      --
      -- ***********************************
      -- ***  �\�Z�l�`�F�b�N
      -- ***********************************
      IF i < 4 THEN
        ln_max_column := 12;
      ELSE
        ln_max_column := 13;
      END IF;
      --
      FOR j IN 1..ln_max_column LOOP
        IF j = 1 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_may;      -- ����l�� or ����
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_may;  -- �����l�� or �e���z
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_may;  -- ����\�Z or �e����
        ELSIF j = 2 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_jun;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_jun;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_jun;
        ELSIF j = 3 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_jul;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_jul;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_jul;
        ELSIF j = 4 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_aug;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_aug;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_aug;
        ELSIF j = 5 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_sep;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_sep;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_sep;
        ELSIF j = 6 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_oct;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_oct;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_oct;
        ELSIF j = 7 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_nov;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_nov;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_nov;
        ELSIF j = 8 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_dec;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_dec;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_dec;
        ELSIF j = 9 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_jan;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_jan;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_jan;
        ELSIF j = 10 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_feb;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_feb;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_feb;
        ELSIF j = 11 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_mar;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_mar;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_mar;
        ELSIF j = 12 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_apr;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_apr;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_apr;
        ELSIF j = 13 THEN
          ln_value1 := gr_plan_tmps_tab(i).plan_sum;
          ln_value2 := gr_plan_tmps_tab(i + 1).plan_sum;
          ln_value3 := gr_plan_tmps_tab(i + 2).plan_sum;
        END IF;
        --
        IF j = 13 THEN
          lv_month := cv_sum;
        ELSE
          lv_month := TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'MM');
        END IF;
        lv_plan_kind := gr_plan_tmps_tab(i).plan_kind;
        -------------------------------------------------
        -- 6-1.�\�Z�l�`�F�b�N
        -------------------------------------------------
        chk_budget_value(
          ov_errbuf               => lv_errbuf          -- �G���[�E���b�Z�[�W
         ,ov_retcode              => lv_retcode         -- ���^�[���E�R�[�h
         ,ov_errmsg               => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
         ,iv_plan_kind            => lv_plan_kind       -- ���_�v or ���i�Q
         ,iv_month                => lv_month
         ,in_value1               => ln_value1          -- ����\�Z or ����
         ,in_value2               => ln_value2          -- �����l�� or �e���z
         ,in_value3               => ln_value3          -- ����l�� or �e����
        );
        -- �X�e�[�^�X�G���[����
        IF ( lv_retcode = cv_status_check ) THEN
          ov_retcode := cv_status_check;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
        --
      END LOOP;
      --
    END LOOP chk_budget_value_loop;
    --
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||'���i�Q='||lv_plan_kind||' ��='||lv_month||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_budget_item;
--
  /**********************************************************************************
   * Procedure Name   : ins_plan_headers
   * Description      : ���i�v��w�b�_�o�^����(A-12)
   ***********************************************************************************/
  PROCEDURE ins_plan_headers(
     ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_plan_headers'; -- �v���O������
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
    -------------------------------------------------
    -- 1.���i�v��w�b�_ID�擾
    -------------------------------------------------
    BEGIN
      SELECT xiph.item_plan_header_id  AS item_plan_header_id
      INTO   gt_item_plan_header_id
      FROM   xxcsm_item_plan_headers xiph
      WHERE  xiph.plan_year = gr_plan_tmps_tab(1).plan_year
      AND    xiph.location_cd = gr_plan_tmps_tab(1).base_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    --
    -------------------------------------------------
    -- 2.���i�v��w�b�_�o�^
    -------------------------------------------------
    IF gt_item_plan_header_id IS NULL THEN
      gt_item_plan_header_id := xxcsm_item_plan_header_s01.NEXTVAL;
      --
      INSERT INTO xxcsm_item_plan_headers(
        item_plan_header_id                 --���i�v��w�b�_ID
       ,plan_year                           --�\�Z�N�x
       ,location_cd                         --���_�R�[�h
       ,created_by                          --�쐬��
       ,creation_date                       --�쐬��
       ,last_updated_by                     --�ŏI�X�V��
       ,last_update_date                    --�ŏI�X�V��
       ,last_update_login                   --�ŏI�X�V���O�C��
       ,request_id                          --�v��ID
       ,program_application_id              --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                          --�R���J�����g�E�v���O����ID
       ,program_update_date                 --�v���O�����X�V��
      ) VALUES (
        gt_item_plan_header_id              --���i�v��w�b�_ID
       ,gr_plan_tmps_tab(1).plan_year       --�\�Z�N�x
       ,gr_plan_tmps_tab(1).base_code       --���_�R�[�h
       ,cn_created_by                       --�쐬��
       ,cd_creation_date                    --�쐬��
       ,cn_last_updated_by                  --�ŏI�X�V��
       ,cd_last_update_date                 --�ŏI�X�V��
       ,cn_last_update_login                --�ŏI�X�V���O�C��
       ,cn_request_id                       --�v��ID
       ,cn_program_application_id           --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,cn_program_id                       --�R���J�����g�E�v���O����ID
       ,cd_program_update_date              --�v���O�����X�V��
      );
      --
    END IF;
    --
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
  END ins_plan_headers;
--
  /**********************************************************************************
   * Procedure Name   : ins_plan_loc_bdgt
   * Description      : ���_�\�Z�o�^�E�X�V����(A-13)
   ***********************************************************************************/
  PROCEDURE ins_plan_loc_bdgt(
     ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_plan_loc_bdgt'; -- �v���O������
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
    --���i�v�拒�_�ʗ\�Z�o�^�p
    TYPE t_item_plan_loc_bdgt_ttype IS TABLE OF xxcsm_item_plan_loc_bdgt%ROWTYPE INDEX BY BINARY_INTEGER;
    l_item_plan_loc_bdgt_tab            t_item_plan_loc_bdgt_ttype;
    lv_tab_name                 VARCHAR2(500);   --�e�[�u����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���i�v�拒�_�ʗ\�Z�e�[�u���s���b�N
    CURSOR cur_lock_item_plan_loc_bdgt IS
      SELECT NULL                        AS item_plan_header_id
            ,xipb.item_plan_loc_bdgt_id  AS item_plan_loc_bdgt_id
            ,NULL                        AS year_month
            ,xipb.month_no               AS month_no
            ,xipb.sales_discount         AS sales_discount
            ,xipb.receipt_discount       AS receipt_discount
            ,xipb.sales_budget           AS sales_budget
            ,NULL                        AS created_by
            ,NULL                        AS creation_date
            ,NULL                        AS last_updated_by
            ,NULL                        AS last_update_date
            ,NULL                        AS last_update_login
            ,NULL                        AS request_id
            ,NULL                        AS program_application_id
            ,NULL                        AS program_id
            ,NULL                        AS program_update_date
      FROM   xxcsm_item_plan_loc_bdgt  xipb
      WHERE  xipb.item_plan_header_id = gt_item_plan_header_id
      FOR UPDATE NOWAIT
    ;
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
    -------------------------------------------------
    -- 1.���i�v�拒�_�ʗ\�Z�擾����у��b�N
    -------------------------------------------------
    OPEN cur_lock_item_plan_loc_bdgt;
    FETCH cur_lock_item_plan_loc_bdgt BULK COLLECT INTO l_item_plan_loc_bdgt_tab;
    CLOSE cur_lock_item_plan_loc_bdgt;
    --
    -- ���i�v�拒�_�ʗ\�Z�o�^�E�X�V
    IF l_item_plan_loc_bdgt_tab.COUNT = 0 THEN
      -------------------------------------------------
      -- 2.���i�v�拒�_�ʗ\�Z�o�^
      -------------------------------------------------
      FOR i IN 1..12 LOOP
        l_item_plan_loc_bdgt_tab(i).item_plan_header_id    := gt_item_plan_header_id;                                        --���i�v��w�b�_ID
        l_item_plan_loc_bdgt_tab(i).item_plan_loc_bdgt_id  := xxcsm_item_plan_bdgt_s01.NEXTVAL;                              --���i�v�拒�_��ID
        l_item_plan_loc_bdgt_tab(i).year_month             := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, i - 1),'YYYYMM')); --�N��
        l_item_plan_loc_bdgt_tab(i).month_no               := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, i - 1),'MM'));     --��
        IF i = 1 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_may * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_may * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_may * 1000;  --����\�Z
        ELSIF i = 2 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_jun * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_jun * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_jun * 1000;  --����\�Z
        ELSIF i = 3 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_jul * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_jul * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_jul * 1000;  --����\�Z
        ELSIF i = 4 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_aug * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_aug * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_aug * 1000;  --����\�Z
        ELSIF i = 5 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_sep * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_sep * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_sep * 1000;  --����\�Z
        ELSIF i = 6 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_oct * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_oct * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_oct * 1000;  --����\�Z
        ELSIF i = 7 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_nov * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_nov * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_nov * 1000;  --����\�Z
        ELSIF i = 8 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_dec * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_dec * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_dec * 1000;  --����\�Z
        ELSIF i = 9 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_jan * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_jan * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_jan * 1000;  --����\�Z
        ELSIF i = 10 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_feb * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_feb * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_feb * 1000;  --����\�Z
        ELSIF i = 11 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_mar * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_mar * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_mar * 1000;  --����\�Z
        ELSIF i = 12 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_apr * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_apr * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_apr * 1000;  --����\�Z
        END IF;
        --who
        l_item_plan_loc_bdgt_tab(i).created_by             := cn_created_by;                  --�쐬��
        l_item_plan_loc_bdgt_tab(i).creation_date          := cd_creation_date;               --�쐬��
        l_item_plan_loc_bdgt_tab(i).last_updated_by        := cn_last_updated_by;             --�ŏI�X�V��
        l_item_plan_loc_bdgt_tab(i).last_update_date       := cd_last_update_date;            --�ŏI�X�V��
        l_item_plan_loc_bdgt_tab(i).last_update_login      := cn_last_update_login;           --�ŏI�X�V���O�C��
        l_item_plan_loc_bdgt_tab(i).request_id             := cn_request_id;                  --�v��ID
        l_item_plan_loc_bdgt_tab(i).program_application_id := cn_program_application_id;      --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        l_item_plan_loc_bdgt_tab(i).program_id             := cn_program_id;                  --�R���J�����g�E�v���O����ID
        l_item_plan_loc_bdgt_tab(i).program_update_date    := cd_program_update_date;         --�v���O�����X�V��
      END LOOP;
      --
      FORALL i in 1..12
        INSERT INTO xxcsm_item_plan_loc_bdgt VALUES l_item_plan_loc_bdgt_tab(i);
      --
    ELSE
      -------------------------------------------------
      -- 3.���i�v�拒�_�ʗ\�Z�X�V
      -------------------------------------------------
      FOR i IN 1..l_item_plan_loc_bdgt_tab.COUNT LOOP
        IF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_5 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_may * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_may * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_may * 1000;  --����\�Z
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_6 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_jun * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_jun * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_jun * 1000;  --����\�Z
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_7 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_jul * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_jul * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_jul * 1000;  --����\�Z
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_8 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_aug * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_aug * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_aug * 1000;  --����\�Z
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_9 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_sep * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_sep * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_sep * 1000;  --����\�Z
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_10 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_oct * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_oct * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_oct * 1000;  --����\�Z
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_11 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_nov * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_nov * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_nov * 1000;  --����\�Z
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_12 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_dec * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_dec * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_dec * 1000;  --����\�Z
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_1 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_jan * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_jan * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_jan * 1000;  --����\�Z
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_2 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_feb * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_feb * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_feb * 1000;  --����\�Z
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_3 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_mar * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_mar * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_mar * 1000;  --����\�Z
        ELSIF l_item_plan_loc_bdgt_tab(i).month_no = cn_month_no_4 THEN
          l_item_plan_loc_bdgt_tab(i).sales_discount       := gr_plan_tmps_tab(1).plan_apr * 1000;  --����l��
          l_item_plan_loc_bdgt_tab(i).receipt_discount     := gr_plan_tmps_tab(2).plan_apr * 1000;  --�����l��
          l_item_plan_loc_bdgt_tab(i).sales_budget         := gr_plan_tmps_tab(3).plan_apr * 1000;  --����\�Z
        END IF;
        --who
        l_item_plan_loc_bdgt_tab(i).last_updated_by        := cn_last_updated_by;             --�ŏI�X�V��
        l_item_plan_loc_bdgt_tab(i).last_update_date       := cd_last_update_date;            --�ŏI�X�V��
        l_item_plan_loc_bdgt_tab(i).last_update_login      := cn_last_update_login;           --�ŏI�X�V���O�C��
        l_item_plan_loc_bdgt_tab(i).request_id             := cn_request_id;                  --�v��ID
        l_item_plan_loc_bdgt_tab(i).program_application_id := cn_program_application_id;      --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        l_item_plan_loc_bdgt_tab(i).program_id             := cn_program_id;                  --�R���J�����g�E�v���O����ID
        l_item_plan_loc_bdgt_tab(i).program_update_date    := cd_program_update_date;         --�v���O�����X�V��
      END LOOP;
      -------------------------------------------------
      -- 5.���i�v�拒�_�ʗ\�Z�X�V
      -------------------------------------------------
      FORALL i in 1..l_item_plan_loc_bdgt_tab.COUNT
        UPDATE xxcsm_item_plan_loc_bdgt
        SET sales_discount         = l_item_plan_loc_bdgt_tab(i).sales_discount          --����l��
           ,receipt_discount       = l_item_plan_loc_bdgt_tab(i).receipt_discount        --�����l��
           ,sales_budget           = l_item_plan_loc_bdgt_tab(i).sales_budget            --����\�Z
           ,last_updated_by        = l_item_plan_loc_bdgt_tab(i).last_updated_by         --�ŏI�X�V��
           ,last_update_date       = l_item_plan_loc_bdgt_tab(i).last_update_date        --�ŏI�X�V��
           ,last_update_login      = l_item_plan_loc_bdgt_tab(i).last_update_login       --�ŏI�X�V���O�C��
           ,request_id             = l_item_plan_loc_bdgt_tab(i).request_id              --�v��ID
           ,program_application_id = l_item_plan_loc_bdgt_tab(i).program_application_id  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,program_id             = l_item_plan_loc_bdgt_tab(i).program_id              --�R���J�����g�E�v���O����ID
           ,program_update_date    = l_item_plan_loc_bdgt_tab(i).program_update_date     --�v���O�����X�V��
        WHERE item_plan_loc_bdgt_id = l_item_plan_loc_bdgt_tab(i).item_plan_loc_bdgt_id   --���i�v�拒�_��ID
        ;
    END IF;
--
  EXCEPTION
    --*** ���b�N�擾�G���[�n���h�� ***
    WHEN global_data_lock_expt THEN
      lv_tab_name := xxccp_common_pkg.get_msg(
                               iv_application => cv_xxcsm_appl_short_name
                              ,iv_name        => cv_msg_item_plan_loc_bdgt
                             );
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_get_lock_err
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => lv_tab_name
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END ins_plan_loc_bdgt;
--
  /**********************************************************************************
   * Procedure Name   : calc_budget_item
   * Description      : ���i�Q�\�Z�l�Z�o
   ***********************************************************************************/
  PROCEDURE calc_budget_item(
     ov_errbuf               OUT VARCHAR2    -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2    -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,on_sales_budget         OUT xxcsm_item_plan_lines.sales_budget%TYPE          -- �Z�o����_����(�P�ʁF�~)
    ,on_amount_gross_margin  OUT xxcsm_item_plan_lines.amount_gross_margin%TYPE   -- �Z�o����_�e���z(�P�ʁF�~)
    ,on_margin_rate          OUT xxcsm_item_plan_lines.margin_rate%TYPE           -- �Z�o����_�e����
    ,iv_item_group_no        IN  VARCHAR2    -- ����_���i�Q
    ,iv_month                IN  VARCHAR2    -- ����_��
    ,in_sales_budget         IN  NUMBER      -- ����_����(�P�ʁF��~)�i�K�{�j
    ,in_amount_gross_margin  IN  NUMBER      -- ����_�e���z(�P�ʁF��~)
    ,in_margin_rate          IN  NUMBER      -- ����_�e����
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'calc_budget_item'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf                 VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode                BOOLEAN;        -- ���b�Z�[�W�߂�l
    lv_step                   VARCHAR2(200);
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    lv_step := '������';
    --����(�~) = ����(��~) * 1000
    on_sales_budget := in_sales_budget * 1000;
    --
    -------------------------------------------------
    -- 1.�e���z�A�e�����̎Z�o
    -------------------------------------------------
    IF in_amount_gross_margin IS NOT NULL THEN
      -------------------------------------------------
      -- �e���z���w�肳��Ă���ꍇ
      -------------------------------------------------
      lv_step := '�e���z�w�� �e���z';
      --�e���z = �A�b�v���[�h�l * 1000
      on_amount_gross_margin := in_amount_gross_margin * 1000;
      --�e���� = ( �e���v�z / ���� * 100 ) �̏����_��3�ʂ��l�̌ܓ�
      lv_step := '�e���z�w�� �e����';
      IF on_sales_budget = 0 THEN
        on_margin_rate := 0;
      ELSE
        BEGIN
          on_margin_rate := ROUND( ( on_amount_gross_margin / on_sales_budget * 100 ), 2);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_xxcsm_appl_short_name     -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_item_group_calc_err   -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_plan_kind
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_month
                           , iv_token_value2 => iv_month
                           , iv_token_name3  => cv_tkn_errmsg
                           , iv_token_value3 => '�e���z�w�� �e�����Z�o > �e���z(��~)='||TO_CHAR(on_amount_gross_margin / 1000)||' ����(��~)='||TO_CHAR(on_sales_budget / 1000)||' �G���[���e='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
    ELSIF in_margin_rate IS NOT NULL THEN
      -------------------------------------------------
      -- �e�������w�肳��Ă���ꍇ
      -------------------------------------------------
      lv_step := '�e�����w�� �e���z';
      --�e���z = ( ���� * �e���v�� / 100 / 1000 ) �̏����_��1�ʂ��l�̌ܓ����āA�P�ʂ��~�ɕύX(�~1000����)
      BEGIN
        on_amount_gross_margin := ROUND( ( on_sales_budget * in_margin_rate / 100 / 1000), 0) * 1000;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_item_group_calc_err   -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_plan_kind
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_month
                         , iv_token_value2 => iv_month
                         , iv_token_name3  => cv_tkn_errmsg
                         , iv_token_value3 => '�e�����w�� �e���z�Z�o > ����(��~)='||TO_CHAR(on_sales_budget / 1000)||' �e����='||TO_CHAR(in_margin_rate)||' �G���[���e='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --
      lv_step := '�e�����w�� �e����';
      --�e���� = �A�b�v���[�h�l
      on_margin_rate := in_margin_rate;
      --
    END IF;
    --
    -------------------------------------------------
    -- 2.���e�͈̓`�F�b�N
    -------------------------------------------------
    lv_step := '���e�͈̓`�F�b�N';
    --0
    IF on_sales_budget = 0 AND on_amount_gross_margin = 0 AND on_margin_rate = 0 THEN
      --�S����0��ok�Ƃ���
      NULL;
    ELSE
      --�e���z
      IF ( ( on_amount_gross_margin / 1000 ) < cn_min_gross ) OR ( cn_max_gross < ( on_amount_gross_margin / 1000 ) ) THEN
        --�e���z�͋��e�͈͂𒴂��Ă��܂��܂��B
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_xxcsm_appl_short_name
                       ,iv_name                 => cv_msg_value_over_err
                       ,iv_token_name1          => cv_tkn_plan_kind
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_month
                       ,iv_token_value2         => iv_month
                       ,iv_token_name3          => cv_tkn_column
                       ,iv_token_value3         => gv_amount_gross_margin
                       ,iv_token_name4          => cv_tkn_min
                       ,iv_token_value4         => TO_CHAR(cn_min_gross)
                       ,iv_token_name5          => cv_tkn_max
                       ,iv_token_value5         => TO_CHAR(cn_max_gross)
                       ,iv_token_name6          => cv_tkn_value
                       ,iv_token_value6         => TO_CHAR(on_amount_gross_margin / 1000)
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
      --�e����
      IF ( on_margin_rate < cn_min_rate ) OR ( cn_max_rate < on_margin_rate ) THEN
        --�e�����͋��e�͈͂𒴂��Ă��܂��܂��B
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_xxcsm_appl_short_name
                       ,iv_name                 => cv_msg_value_over_err
                       ,iv_token_name1          => cv_tkn_plan_kind
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_month
                       ,iv_token_value2         => iv_month
                       ,iv_token_name3          => cv_tkn_column
                       ,iv_token_value3         => gv_margin_rate
                       ,iv_token_name4          => cv_tkn_min
                       ,iv_token_value4         => TO_CHAR(cn_min_rate)
                       ,iv_token_name5          => cv_tkn_max
                       ,iv_token_value5         => TO_CHAR(cn_max_rate)
                       ,iv_token_name6          => cv_tkn_value
                       ,iv_token_value6         => TO_CHAR(on_margin_rate,'FM999999999990.09')
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --
  END calc_budget_item;
  --
--
  /**********************************************************************************
   * Procedure Name   : calc_budget_new_item
   * Description      : �V���i�\�Z�l�Z�o
   ***********************************************************************************/
  PROCEDURE calc_budget_new_item(
     ov_errbuf                   OUT VARCHAR2    -- �G���[�E���b�Z�[�W
    ,ov_retcode                  OUT VARCHAR2    -- ���^�[���E�R�[�h
    ,ov_errmsg                   OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,on_credit_rate              OUT xxcsm_item_plan_lines.credit_rate%TYPE           -- �Z�o����_�|��
    ,on_amount                   OUT xxcsm_item_plan_lines.amount%TYPE                -- �Z�o����_����
    ,iv_item_group_no            IN  VARCHAR2    -- ����_���i�Q
    ,iv_new_item_no              IN  VARCHAR2    -- ����_�V���i�R�[�h
    ,iv_month                    IN  VARCHAR2    -- ����_��
    ,in_sales_budget             IN  NUMBER      -- ����_�V���i�̔���(�P�ʁF�~)
    ,in_amount_gross_margin      IN  NUMBER      -- ����_�V���i�̑e���z(�P�ʁF�~)
    ,in_new_item_discrete_cost   IN  NUMBER      -- ����_�V���i�̉c�ƌ���
    ,in_new_item_fixed_price     IN  NUMBER      -- ����_�V���i�̒艿
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'calc_budget_new_item'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf      VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg     VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode     BOOLEAN;        -- ���b�Z�[�W�߂�l
    lv_step        VARCHAR2(200);
    --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    --�V���i����
    lv_step := '�V���i�̐��ʎZ�o['||iv_item_group_no||' / '||iv_new_item_no||' / '||iv_month||']';
    IF in_new_item_discrete_cost = 0 THEN
      on_amount := 0;
    ELSE
      BEGIN
        --���� = (���i�Q�̔��� - ���i�Q�̑e���v�z) / �V���i�̉c�ƌ����̏����_��2�ʂ��l�̌ܓ�
        on_amount := ROUND( ( in_sales_budget - in_amount_gross_margin ) / in_new_item_discrete_cost, 1);
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_new_item_calc_err     -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => iv_new_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => iv_month
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '�V���i�̐��ʎZ�o > ���i�Q����(��~)='||TO_CHAR(in_sales_budget / 1000)||' ���i�Q�e���z(��~)='||TO_CHAR(in_amount_gross_margin / 1000)||' �V���i�c�ƌ���='||TO_CHAR(in_new_item_discrete_cost)||' �G���[���e='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --
    END IF;
    --
    --�V���i�|��
    lv_step := '�V���i�̊|���Z�o['||iv_item_group_no||' / '||iv_new_item_no||' / '||iv_month||']';
    IF on_amount * in_new_item_fixed_price = 0 THEN
      on_credit_rate := 0;
    ELSE
      --�|�� = ( ���i�Q�̔��� / (�V���i�̒艿 * �V���i�̐���) * 100 )�̏����_��4�ʂ��l�̌ܓ�
      BEGIN
        on_credit_rate := ROUND( ( in_sales_budget / ( in_new_item_fixed_price * on_amount ) * 100 ), 3);
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_new_item_calc_err     -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => iv_new_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => iv_month
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '�V���i�̊|���Z�o > ���i�Q����(��~)='||TO_CHAR(in_sales_budget / 1000)||' �V���i�艿='||TO_CHAR(in_new_item_fixed_price)||' �V���i����='||TO_CHAR(on_amount)||' �G���[���e='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --
  END calc_budget_new_item;
  --
  /**********************************************************************************
   * Procedure Name   : ins_plan_line
   * Description      : ���i�Q�\�Z�o�^�E�X�V����(A-14)
   ***********************************************************************************/
  PROCEDURE ins_plan_line(
     ov_errbuf     OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_plan_line'; -- �v���O������
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
    --���i�v�斾�דo�^�p
    TYPE t_item_plan_lines_ttype IS TABLE OF xxcsm_item_plan_lines%ROWTYPE INDEX BY BINARY_INTEGER;
    l_item_plan_lines_tab            t_item_plan_lines_ttype;
    --���i�Q�\�Z�Z�o���ʑޔ�p
    TYPE l_group_bdgt_rtype IS RECORD (
      sales_budget          xxcsm_item_plan_lines.sales_budget%TYPE
     ,amount_gross_margin   xxcsm_item_plan_lines.amount_gross_margin%TYPE
     ,margin_rate           xxcsm_item_plan_lines.margin_rate%TYPE
    );
    TYPE l_group_bdgt_ttype IS TABLE OF l_group_bdgt_rtype INDEX BY BINARY_INTEGER;
    l_group_bdgt_tab     l_group_bdgt_ttype;
    --
    --�V���i�\�Z�Z�o���ʑޔ�p
    TYPE l_new_item_bdgt_rtype IS RECORD (
      sales_budget          xxcsm_item_plan_lines.sales_budget%TYPE
     ,amount_gross_margin   xxcsm_item_plan_lines.amount_gross_margin%TYPE
     ,credit_rate           xxcsm_item_plan_lines.credit_rate%TYPE
     ,amount                xxcsm_item_plan_lines.amount%TYPE
    );
    TYPE l_new_item_bdgt_ttype IS TABLE OF l_new_item_bdgt_rtype INDEX BY BINARY_INTEGER;
    l_new_item_bdgt_tab     l_new_item_bdgt_ttype;
    --
    ln_sales_budget                 NUMBER;
    ln_amount_gross_margin          NUMBER;
    ln_margin_rate                  NUMBER;
    ln_line_cnt                     NUMBER;
    ln_cnt                          NUMBER;
    ln_sum_sales_budget             xxcsm_item_plan_lines.sales_budget%TYPE;         --�P�i�\�Z���㍇�v
    ln_sum_amount_gross_margin      xxcsm_item_plan_lines.amount_gross_margin%TYPE;  --�P�i�\�Z�e���z���v
--
    lv_step                         VARCHAR2(200);
    lt_item_group_no                xxcsm_item_plan_lines.item_group_no%TYPE;
    lt_new_item_no                  xxcsm_item_plan_lines.item_no%TYPE;
    lv_month                        VARCHAR(100);
    lv_out_msg                      VARCHAR2(2000);  -- ���b�Z�[�W
    lt_new_item_discrete_cost       xxcmm_system_items_b_hst.discrete_cost%TYPE;     --�c�ƌ���
    lt_new_item_fixed_price         xxcmm_system_items_b_hst.fixed_price%TYPE;       --�艿
    lv_tab_name                     VARCHAR2(500);   --�e�[�u����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���i�v�斾�׃e�[�u���s���b�N
    CURSOR cur_lock_item_plan_lines IS
      SELECT NULL                          AS item_plan_header_id
            ,xipl.item_plan_lines_id       AS item_plan_lines_id
            ,NULL                          AS year_month
            ,xipl.month_no                 AS month_no
            ,NULL                          AS year_bdgt_kbn
            ,NULL                          AS item_kbn
            ,NULL                          AS item_no
            ,NULL                          AS item_group_no
            ,xipl.amount                   AS amount
            ,xipl.sales_budget             AS sales_budget
            ,xipl.amount_gross_margin      AS amount_gross_margin
            ,xipl.credit_rate              AS credit_rate
            ,xipl.margin_rate              AS margin_rate
            ,NULL                          AS created_by
            ,NULL                          AS creation_date
            ,NULL                          AS last_updated_by
            ,NULL                          AS last_update_date
            ,NULL                          AS last_update_login
            ,NULL                          AS request_id
            ,NULL                          AS program_application_id
            ,NULL                          AS program_id
            ,NULL                          AS program_update_date
      FROM   xxcsm_item_plan_lines  xipl
      WHERE  xipl.item_plan_header_id = gt_item_plan_header_id
      AND    xipl.item_group_no = lt_item_group_no
      AND    xipl.item_kbn IN (cv_item_kbn_group, cv_item_kbn_new)
      ORDER BY xipl.item_kbn
              ,xipl.month_no
      FOR UPDATE NOWAIT
    ;
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
    --
    <<ins_plan_line_loop>>
    FOR i IN 4.. gn_target_cnt LOOP  --�A�b�v���[�h�f�[�^���[�v
      IF MOD(i, 3) <> 1 THEN
        CONTINUE;
      END IF;
      --
      lt_item_group_no := gr_plan_tmps_tab(i).plan_kind;
      -------------------------------------------------
      -- 1.���i�Q�\�Z�Z�o
      -------------------------------------------------
      l_group_bdgt_tab.DELETE;
      FOR j IN 1..13 LOOP       --���ʃ��[�v
        --
        IF j = 1 THEN  --5����
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_may;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_may;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_may;
        ELSIF j = 2 THEN  --6����
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_jun;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_jun;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_jun;
        ELSIF j = 3 THEN  --7����
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_jul;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_jul;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_jul;
        ELSIF j = 4 THEN  --8����
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_aug;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_aug;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_aug;
        ELSIF j = 5 THEN  --9����
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_sep;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_sep;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_sep;
        ELSIF j = 6 THEN  --10����
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_oct;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_oct;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_oct;
        ELSIF j = 7 THEN  --11����
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_nov;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_nov;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_nov;
        ELSIF j = 8 THEN  --12����
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_dec;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_dec;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_dec;
        ELSIF j = 9 THEN  --1����
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_jan;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_jan;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_jan;
        ELSIF j = 10 THEN  --2����
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_feb;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_feb;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_feb;
        ELSIF j = 11 THEN  --3����
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_mar;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_mar;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_mar;
        ELSIF j = 12 THEN  --4����
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_apr;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_apr;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_apr;
        ELSIF j = 13 THEN  --�N�Ԍv
          ln_sales_budget        := gr_plan_tmps_tab(i).plan_sum;
          ln_amount_gross_margin := gr_plan_tmps_tab(i + 1).plan_sum;
          ln_margin_rate         := gr_plan_tmps_tab(i + 2).plan_sum;
        END IF;
        --
        IF j = 13 THEN
          lv_month := cv_sum;
        ELSE
          lv_month := TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'MM');
        END IF;
        -------------------------------------------------
        -- ���i�Q�\�Z���ڎZ�o
        -------------------------------------------------
        calc_budget_item(
          ov_errbuf              => lv_errbuf                                  -- �G���[�E���b�Z�[�W
         ,ov_retcode             => lv_retcode                                 -- ���^�[���E�R�[�h
         ,ov_errmsg              => lv_errmsg                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
         ,on_sales_budget        => l_group_bdgt_tab(j).sales_budget           -- �Z�o����_����(�P�ʁF�~)
         ,on_amount_gross_margin => l_group_bdgt_tab(j).amount_gross_margin    -- �Z�o����_�e���z(�P�ʁF�~)
         ,on_margin_rate         => l_group_bdgt_tab(j).margin_rate            -- �Z�o����_�e����
         ,iv_item_group_no       => lt_item_group_no                           -- ����_���i�Q
         ,iv_month               => lv_month                                   -- ����_��
         ,in_sales_budget        => ln_sales_budget                            -- ����_����(�P�ʁF��~)�i�K�{�j
         ,in_amount_gross_margin => ln_amount_gross_margin                     -- ����_�e���z(�P�ʁF��~)
         ,in_margin_rate         => ln_margin_rate                             -- ����_�e����
        );
        --
        IF ( lv_retcode = cv_status_check ) THEN
          ov_retcode := cv_status_check;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP;
      --
      --���i�v�斾�׊i�[�揉����
      l_item_plan_lines_tab.DELETE;
      ln_line_cnt := 0;
      -------------------------------------------------
      -- 2.���i�v�斾�׎擾����у��b�N
      -------------------------------------------------
      OPEN cur_lock_item_plan_lines;
      FETCH cur_lock_item_plan_lines BULK COLLECT INTO l_item_plan_lines_tab;
      ln_cnt := l_item_plan_lines_tab.COUNT;
      CLOSE cur_lock_item_plan_lines;
      --
      -- ���i�v�斾�דo�^�E�X�V
      IF ln_cnt = 0 THEN
        -------------------------------------------------
        -- 3.���i�Q�\�Z���o�^���̏��i�Q�\�Z�ݒ�
        -------------------------------------------------
        FOR j IN 1..13 LOOP       --���i�Q�̌��ʃ��[�v
          --
          --�o�^�l�ݒ菈��
          ln_line_cnt := ln_line_cnt + 1;
          --
          l_item_plan_lines_tab(ln_line_cnt).item_plan_header_id := gt_item_plan_header_id;             --���i�v��w�b�_ID
          l_item_plan_lines_tab(ln_line_cnt).item_plan_lines_id  := xxcsm_item_plan_lines_s01.NEXTVAL;  --���i�v�斾��ID
          IF j = 13 THEN  -- �N�Ԍv
            l_item_plan_lines_tab(ln_line_cnt).year_month    := NULL;                    --�N��
            l_item_plan_lines_tab(ln_line_cnt).month_no      := cn_month_no_99;          --��
            l_item_plan_lines_tab(ln_line_cnt).year_bdgt_kbn := cv_budget_kbn_year;      -- 1:�N�ԌQ�\�Z
          ELSE
            l_item_plan_lines_tab(ln_line_cnt).year_month    := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'YYYYMM'));  --�N��
            l_item_plan_lines_tab(ln_line_cnt).month_no      := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'MM'));      --��
            l_item_plan_lines_tab(ln_line_cnt).year_bdgt_kbn := cv_budget_kbn_month;     -- 0:�e���P�ʗ\�Z
          END IF;
          l_item_plan_lines_tab(ln_line_cnt).item_kbn               := cv_item_kbn_group;                   --���i�敪
          l_item_plan_lines_tab(ln_line_cnt).item_no                := NULL;                                --���i�R�[�h
          l_item_plan_lines_tab(ln_line_cnt).item_group_no          := lt_item_group_no;                    --���i�Q�R�[�h
          --
          l_item_plan_lines_tab(ln_line_cnt).sales_budget           := l_group_bdgt_tab(j).sales_budget;          --����
          l_item_plan_lines_tab(ln_line_cnt).amount_gross_margin    := l_group_bdgt_tab(j).amount_gross_margin;   --�e���z
          l_item_plan_lines_tab(ln_line_cnt).margin_rate            := l_group_bdgt_tab(j).margin_rate;           --�e����
          l_item_plan_lines_tab(ln_line_cnt).credit_rate            := 0;                                         --�|��
          l_item_plan_lines_tab(ln_line_cnt).amount                 := 0;                                         --����
          --who
          l_item_plan_lines_tab(ln_line_cnt).created_by             := cn_created_by;                       --�쐬��
          l_item_plan_lines_tab(ln_line_cnt).creation_date          := cd_creation_date;                    --�쐬��
          l_item_plan_lines_tab(ln_line_cnt).last_updated_by        := cn_last_updated_by;                  --�ŏI�X�V��
          l_item_plan_lines_tab(ln_line_cnt).last_update_date       := cd_last_update_date;                 --�ŏI�X�V��
          l_item_plan_lines_tab(ln_line_cnt).last_update_login      := cn_last_update_login;                --�ŏI�X�V���O�C��
          l_item_plan_lines_tab(ln_line_cnt).request_id             := cn_request_id;                       --�v��ID
          l_item_plan_lines_tab(ln_line_cnt).program_application_id := cn_program_application_id;           --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          l_item_plan_lines_tab(ln_line_cnt).program_id             := cn_program_id;                       --�R���J�����g�E�v���O����ID
          l_item_plan_lines_tab(ln_line_cnt).program_update_date    := cd_program_update_date;              --�v���O�����X�V��
          --
        END LOOP;
        --
      ELSE
        -------------------------------------------------
        -- 4.���i�Q�\�Z�o�^�ώ��̏��i�Q�\�Z�ݒ�
        -------------------------------------------------
        FOR k IN 1..13 LOOP
          IF l_item_plan_lines_tab(k).month_no = cn_month_no_5 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(1).sales_budget;          -- ����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(1).amount_gross_margin;   -- �e���z
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(1).margin_rate;           -- �e����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_6 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(2).sales_budget;          -- ����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(2).amount_gross_margin;   -- �e���z
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(2).margin_rate;           -- �e����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_7 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(3).sales_budget;          -- ����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(3).amount_gross_margin;   -- �e���z
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(3).margin_rate;           -- �e����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_8 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(4).sales_budget;          -- ����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(4).amount_gross_margin;   -- �e���z
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(4).margin_rate;           -- �e����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_9 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(5).sales_budget;          -- ����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(5).amount_gross_margin;   -- �e���z
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(5).margin_rate;           -- �e����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_10 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(6).sales_budget;          -- ����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(6).amount_gross_margin;   -- �e���z
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(6).margin_rate;           -- �e����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_11 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(7).sales_budget;          -- ����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(7).amount_gross_margin;   -- �e���z
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(7).margin_rate;           -- �e����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_12 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(8).sales_budget;          -- ����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(8).amount_gross_margin;   -- �e���z
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(8).margin_rate;           -- �e����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_1 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(9).sales_budget;          -- ����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(9).amount_gross_margin;   -- �e���z
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(9).margin_rate;           -- �e����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_2 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(10).sales_budget;          -- ����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(10).amount_gross_margin;   -- �e���z
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(10).margin_rate;           -- �e����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_3 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(11).sales_budget;          -- ����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(11).amount_gross_margin;   -- �e���z
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(11).margin_rate;           -- �e����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_4 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(12).sales_budget;          -- ����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(12).amount_gross_margin;   -- �e���z
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(12).margin_rate;           -- �e����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_99 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_group_bdgt_tab(13).sales_budget;          -- ����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_group_bdgt_tab(13).amount_gross_margin;   -- �e���z
            l_item_plan_lines_tab(k).margin_rate            := l_group_bdgt_tab(13).margin_rate;           -- �e����
          END IF;
          --who
          l_item_plan_lines_tab(k).last_updated_by        := cn_last_updated_by;                  --�ŏI�X�V��
          l_item_plan_lines_tab(k).last_update_date       := cd_last_update_date;                 --�ŏI�X�V��
          l_item_plan_lines_tab(k).last_update_login      := cn_last_update_login;                --�ŏI�X�V���O�C��
          l_item_plan_lines_tab(k).request_id             := cn_request_id;                       --�v��ID
          l_item_plan_lines_tab(k).program_application_id := cn_program_application_id;           --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          l_item_plan_lines_tab(k).program_id             := cn_program_id;                       --�R���J�����g�E�v���O����ID
          l_item_plan_lines_tab(k).program_update_date    := cd_program_update_date;              --�v���O�����X�V��
          --
        END LOOP;
        --
      END IF;
      --
      -------------------------------------------------
      -- 5-1.�V���i�R�[�h�擾
      -------------------------------------------------
      lv_step := '�V���i�R�[�h�擾 ';
      BEGIN
        SELECT  DISTINCT  xicv.attribute3                             --  �V���i�R�[�h
        INTO    lt_new_item_no
        FROM    xxcsm_item_category_v xicv                            --  �i�ڃJ�e�S���r���[
        WHERE   xicv.segment1 LIKE REPLACE(lt_item_group_no,'*','_')  --  ���i�Q�R�[�h
        AND     xicv.attribute3 IS NOT NULL                           --  �V���i�R�[�h
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
          lv_out_msg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_xxcsm_appl_short_name
                         ,iv_name                 => cv_msg_new_item_err
                         ,iv_token_name1          => cv_tkn_deal_cd
                         ,iv_token_value1         => lt_item_group_no
                        );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_out_msg
          );
          ov_retcode := cv_status_check;
      END;
      -------------------------------------------------
      -- 5-2.�V���i�c�ƌ����擾
      -------------------------------------------------
      lv_step := '�V���i�c�ƌ����擾 ';
      BEGIN
        -- �O�N�x�̉c�ƌ�����i�ڕύX��������擾
        SELECT xsibh.discrete_cost                           -- �c�ƌ���
        INTO   lt_new_item_discrete_cost
        FROM   xxcmm_system_items_b_hst   xsibh              -- �i�ڕύX�����e�[�u��
              ,(SELECT MAX(item_hst_id)   item_hst_id        -- �i�ڕύX����ID
                FROM   xxcmm_system_items_b_hst              -- �i�ڕύX����
                WHERE  item_code  = lt_new_item_no           -- �i�ڃR�[�h
                AND    apply_date < gd_start_date            -- �N�x�J�n���O
                AND    apply_flag = cv_yes                   -- �K�p�ς�
                AND    discrete_cost IS NOT NULL             -- �c�ƌ��� IS NOT NULL
               ) xsibh_view
        WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id    -- �i�ڕύX����ID
        AND    xsibh.item_code   = lt_new_item_no            -- �V���i�R�[�h
        AND    xsibh.apply_flag  = cv_yes                    -- �K�p�ς�
        AND    xsibh.discrete_cost IS NOT NULL
        ;
          --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --�c�ƌ����擾�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name          -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_discrete_cost_err          -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_deal_cd                    -- �g�[�N���R�[�h1
                         , iv_token_value1 => lt_item_group_no                  -- �g�[�N���l1�i���i�Q�j
                         , iv_token_name2  => cv_tkn_item_cd                    -- �g�[�N���R�[�h2
                         , iv_token_value2 => lt_new_item_no                    -- �g�[�N���l2�i���i�R�[�h�j
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
      END;
      --
      -------------------------------------------------
      -- 5-3.�V���i�艿�擾
      -------------------------------------------------
      lv_step := '�V���i�艿�擾 ';
      BEGIN
        -- �O�N�x�̒艿��i�ڕύX��������擾
        SELECT xsibh.fixed_price                             -- �艿
        INTO   lt_new_item_fixed_price
        FROM   xxcmm_system_items_b_hst   xsibh              -- �i�ڕύX�����e�[�u��
              ,(SELECT MAX(item_hst_id)   item_hst_id        -- �i�ڕύX����ID
                FROM   xxcmm_system_items_b_hst              -- �i�ڕύX����
                WHERE  item_code  = lt_new_item_no           -- �i�ڃR�[�h
                AND    apply_date < gd_start_date            -- �N�x�J�n���O
                AND    apply_flag = cv_yes                   -- �K�p�ς�
                AND    fixed_price IS NOT NULL               -- �艿 IS NOT NULL
                  ) xsibh_view
        WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id    -- �i�ڕύX����ID
        AND    xsibh.item_code   = lt_new_item_no            -- �V���i�R�[�h
        AND    xsibh.apply_flag  = cv_yes                    -- �K�p�ς�
        AND    xsibh.fixed_price IS NOT NULL
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --�艿�擾�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcsm_appl_short_name          -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_fixed_price_err            -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_deal_cd                    -- �g�[�N���R�[�h1
                         , iv_token_value1 => lt_item_group_no                  -- �g�[�N���l1�i���i�Q�j
                         , iv_token_name2  => cv_tkn_item_cd                    -- �g�[�N���R�[�h2
                         , iv_token_value2 => lt_new_item_no                    -- �g�[�N���l2�i���i�R�[�h�j
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
      END;
      --
      -------------------------------------------------
      -- 6.�V���i�\�Z�Z�o
      -------------------------------------------------
      l_new_item_bdgt_tab.DELETE;
      FOR j IN 1..12 LOOP            --�V���i�̌��ʃ��[�v
        -------------------------------------------------
        -- �P�i�\�Z���v�z�擾
        -------------------------------------------------
        SELECT  NVL(SUM(xipl.sales_budget), 0)         AS  sum_sales_budget         --���㍇�v�z
               ,NVL(SUM(xipl.amount_gross_margin), 0)  AS  sum_amount_gross_margin  --�e�����v�z
        INTO    ln_sum_sales_budget
               ,ln_sum_amount_gross_margin
        FROM    xxcsm_item_plan_lines   xipl
        WHERE   xipl.item_plan_header_id = gt_item_plan_header_id
        AND     xipl.item_group_no = lt_item_group_no
        AND     xipl.item_kbn = cv_item_kbn_tanpin
        AND     xipl.month_no = TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'MM'))
        ;
        -------------------------------------------------
        --�V���i�̔���A�e���z�Z�o
        -------------------------------------------------
        l_new_item_bdgt_tab(j).sales_budget        := l_group_bdgt_tab(j).sales_budget - ln_sum_sales_budget;
        l_new_item_bdgt_tab(j).amount_gross_margin := l_group_bdgt_tab(j).amount_gross_margin - ln_sum_amount_gross_margin;
        --
        lv_month := TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'MM');
        --
        -------------------------------------------------
        -- �V���i�\�Z���ڐݒ�
        -------------------------------------------------
        calc_budget_new_item(
          ov_errbuf                 => lv_errbuf                                         -- �G���[�E���b�Z�[�W
         ,ov_retcode                => lv_retcode                                        -- ���^�[���E�R�[�h
         ,ov_errmsg                 => lv_errmsg                                         -- ���[�U�[�E�G���[�E���b�Z�[�W
         ,on_credit_rate            => l_new_item_bdgt_tab(j).credit_rate                -- �Z�o����_�|��
         ,on_amount                 => l_new_item_bdgt_tab(j).amount                     -- �Z�o����_����
         ,iv_item_group_no          => lt_item_group_no                                  -- ����_���i�Q
         ,iv_new_item_no            => lt_new_item_no                                    -- ����_�V���i�R�[�h
         ,iv_month                  => lv_month                                          -- ����_��
         ,in_sales_budget           => l_new_item_bdgt_tab(j).sales_budget               -- ����_�V���i�̔���(�P�ʁF�~)
         ,in_amount_gross_margin    => l_new_item_bdgt_tab(j).amount_gross_margin        -- ����_�V���i�̑e���z(�P�ʁF�~)
         ,in_new_item_discrete_cost => lt_new_item_discrete_cost                         -- ����_�V���i�̉c�ƌ���(�P�ʁF�~)
         ,in_new_item_fixed_price   => lt_new_item_fixed_price                           -- ����_�V���i�̒艿(�P�ʁF�~)
        );
        --
        IF ( lv_retcode = cv_status_check ) THEN
          ov_retcode := cv_status_check;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP;
      --
      -- ���i�v�斾�דo�^�E�X�V
      IF ln_cnt = 0 THEN
        -------------------------------------------------
        -- 7.���i�Q�\�Z���o�^���̐V���i�\�Z�ݒ�
        -------------------------------------------------
        FOR j IN 1..12 LOOP       --�V���i�̌��ʃ��[�v
          --
          --�o�^�l�ݒ菈��
          ln_line_cnt := ln_line_cnt + 1;
          --
          l_item_plan_lines_tab(ln_line_cnt).item_plan_header_id    := gt_item_plan_header_id;             --���i�v��w�b�_ID
          l_item_plan_lines_tab(ln_line_cnt).item_plan_lines_id     := xxcsm_item_plan_lines_s01.NEXTVAL;  --���i�v�斾��ID
          l_item_plan_lines_tab(ln_line_cnt).year_month             := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'YYYYMM'));  --�N��
          l_item_plan_lines_tab(ln_line_cnt).month_no               := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, j - 1),'MM'));      --��
          l_item_plan_lines_tab(ln_line_cnt).year_bdgt_kbn          := cv_budget_kbn_month;                --0:�e���P�ʗ\�Z
          l_item_plan_lines_tab(ln_line_cnt).item_kbn               := cv_item_kbn_new;                    --���i�敪
          l_item_plan_lines_tab(ln_line_cnt).item_no                := lt_new_item_no;                     --���i�R�[�h
          l_item_plan_lines_tab(ln_line_cnt).item_group_no          := lt_item_group_no;                   --���i�Q�R�[�h
          --
          l_item_plan_lines_tab(ln_line_cnt).sales_budget           := l_new_item_bdgt_tab(j).sales_budget;          --����
          l_item_plan_lines_tab(ln_line_cnt).amount_gross_margin    := l_new_item_bdgt_tab(j).amount_gross_margin;   --�e���z
          l_item_plan_lines_tab(ln_line_cnt).margin_rate            := 0;                                            --�e����
          l_item_plan_lines_tab(ln_line_cnt).credit_rate            := l_new_item_bdgt_tab(j).credit_rate;           --�|��
          l_item_plan_lines_tab(ln_line_cnt).amount                 := l_new_item_bdgt_tab(j).amount;                --����
          --who
          l_item_plan_lines_tab(ln_line_cnt).created_by             := cn_created_by;                   --�쐬��
          l_item_plan_lines_tab(ln_line_cnt).creation_date          := cd_creation_date;                --�쐬��
          l_item_plan_lines_tab(ln_line_cnt).last_updated_by        := cn_last_updated_by;              --�ŏI�X�V��
          l_item_plan_lines_tab(ln_line_cnt).last_update_date       := cd_last_update_date;             --�ŏI�X�V��
          l_item_plan_lines_tab(ln_line_cnt).last_update_login      := cn_last_update_login;            --�ŏI�X�V���O�C��
          l_item_plan_lines_tab(ln_line_cnt).request_id             := cn_request_id;                   --�v��ID
          l_item_plan_lines_tab(ln_line_cnt).program_application_id := cn_program_application_id;       --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          l_item_plan_lines_tab(ln_line_cnt).program_id             := cn_program_id;                   --�R���J�����g�E�v���O����ID
          l_item_plan_lines_tab(ln_line_cnt).program_update_date    := cd_program_update_date;          --�v���O�����X�V��
          --
        END LOOP;
        --
        -------------------------------------------------
        -- 8.���i�v�斾�דo�^�i���i�Q�A�V���i�j
        -------------------------------------------------
        IF ov_retcode = cv_status_normal THEN
          FORALL l in 1..ln_line_cnt
            INSERT INTO xxcsm_item_plan_lines VALUES l_item_plan_lines_tab(l);
        END IF;
        --
      ELSE
        -------------------------------------------------
        -- 9.���i�Q�\�Z�o�^�ώ��̐V���i�\�Z�ݒ�
        -------------------------------------------------
        FOR k IN 14..25 LOOP       --�V���i�̌��ʃ��[�v
          --
          IF l_item_plan_lines_tab(k).month_no = cn_month_no_5 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(1).sales_budget;          --����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(1).amount_gross_margin;   --�e���z
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(1).credit_rate;           --�|��
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(1).amount;                --����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_6 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(2).sales_budget;          --����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(2).amount_gross_margin;   --�e���z
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(2).credit_rate;           --�|��
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(2).amount;                --����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_7 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(3).sales_budget;          --����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(3).amount_gross_margin;   --�e���z
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(3).credit_rate;           --�|��
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(3).amount;                --����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_8 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(4).sales_budget;          --����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(4).amount_gross_margin;   --�e���z
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(4).credit_rate;           --�|��
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(4).amount;                --����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_9 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(5).sales_budget;          --����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(5).amount_gross_margin;   --�e���z
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(5).credit_rate;           --�|��
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(5).amount;                --����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_10 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(6).sales_budget;          --����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(6).amount_gross_margin;   --�e���z
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(6).credit_rate;           --�|��
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(6).amount;                --����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_11 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(7).sales_budget;          --����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(7).amount_gross_margin;   --�e���z
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(7).credit_rate;           --�|��
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(7).amount;                --����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_12 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(8).sales_budget;          --����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(8).amount_gross_margin;   --�e���z
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(8).credit_rate;           --�|��
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(8).amount;                --����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_1 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(9).sales_budget;          --����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(9).amount_gross_margin;   --�e���z
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(9).credit_rate;           --�|��
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(9).amount;                --����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_2 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(10).sales_budget;         --����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(10).amount_gross_margin;  --�e���z
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(10).credit_rate;          --�|��
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(10).amount;               --����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_3 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(11).sales_budget;         --����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(11).amount_gross_margin;  --�e���z
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(11).credit_rate;          --�|��
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(11).amount;               --����
          ELSIF l_item_plan_lines_tab(k).month_no = cn_month_no_4 THEN
            l_item_plan_lines_tab(k).sales_budget           := l_new_item_bdgt_tab(12).sales_budget;         --����
            l_item_plan_lines_tab(k).amount_gross_margin    := l_new_item_bdgt_tab(12).amount_gross_margin;  --�e���z
            l_item_plan_lines_tab(k).credit_rate            := l_new_item_bdgt_tab(12).credit_rate;          --�|��
            l_item_plan_lines_tab(k).amount                 := l_new_item_bdgt_tab(12).amount;               --����
          END IF;
          --who
          l_item_plan_lines_tab(k).last_updated_by        := cn_last_updated_by;                  --�ŏI�X�V��
          l_item_plan_lines_tab(k).last_update_date       := cd_last_update_date;                 --�ŏI�X�V��
          l_item_plan_lines_tab(k).last_update_login      := cn_last_update_login;                --�ŏI�X�V���O�C��
          l_item_plan_lines_tab(k).request_id             := cn_request_id;                       --�v��ID
          l_item_plan_lines_tab(k).program_application_id := cn_program_application_id;           --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          l_item_plan_lines_tab(k).program_id             := cn_program_id;                       --�R���J�����g�E�v���O����ID
          l_item_plan_lines_tab(k).program_update_date    := cd_program_update_date;              --�v���O�����X�V��
          --
        END LOOP;
        --
        -------------------------------------------------
        -- 10.���i�v�斾�׍X�V�i���i�Q�A�V���i�j
        -------------------------------------------------
        IF ov_retcode = cv_status_normal THEN
          FORALL l in 1..l_item_plan_lines_tab.COUNT
            UPDATE xxcsm_item_plan_lines
            SET sales_budget           = l_item_plan_lines_tab(l).sales_budget            --����
               ,amount_gross_margin    = l_item_plan_lines_tab(l).amount_gross_margin     --�e���z
               ,margin_rate            = l_item_plan_lines_tab(l).margin_rate             --�e����
               ,credit_rate            = l_item_plan_lines_tab(l).credit_rate             --�|��
               ,amount                 = l_item_plan_lines_tab(l).amount                  --����
               ,last_updated_by        = l_item_plan_lines_tab(l).last_updated_by         --�ŏI�X�V��
               ,last_update_date       = l_item_plan_lines_tab(l).last_update_date        --�ŏI�X�V��
               ,last_update_login      = l_item_plan_lines_tab(l).last_update_login       --�ŏI�X�V���O�C��
               ,request_id             = l_item_plan_lines_tab(l).request_id              --�v��ID
               ,program_application_id = l_item_plan_lines_tab(l).program_application_id  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               ,program_id             = l_item_plan_lines_tab(l).program_id              --�R���J�����g�E�v���O����ID
               ,program_update_date    = l_item_plan_lines_tab(l).program_update_date     --�v���O�����X�V��
            WHERE item_plan_lines_id = l_item_plan_lines_tab(l).item_plan_lines_id      --���i�v�斾��ID
            ;
        END IF;
        --
      END IF;
      --
    END LOOP;
    --
--
  EXCEPTION
    --*** ���b�N�擾�G���[�n���h�� ***
    WHEN global_data_lock_expt THEN
      lv_tab_name := xxccp_common_pkg.get_msg(
                               iv_application => cv_xxcsm_appl_short_name
                              ,iv_name        => cv_msg_item_plan_lines
                             );
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcsm_appl_short_name
                    ,iv_name         => cv_msg_get_lock_err
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => lv_tab_name
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_plan_line;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     in_get_file_id    IN  NUMBER    -- �t�@�C��ID
    ,iv_get_format_pat IN  VARCHAR2  -- �t�H�[�}�b�g�p�^�[��
    ,ov_errbuf         OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode        OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg         OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    ln_cnt           NUMBER;        -- �J�E���^
    lv_ret_status    VARCHAR2(1);   -- ���^�[���E�X�e�[�^�X
--
    --�擾�l�̊i�[�ϐ�
    lv_base_code         VARCHAR2(4);               -- ���_�R�[�h
    lv_plan_year         VARCHAR2(4);               -- �N�x
    lv_plan_kind         VARCHAR2(20);              -- �\�Z�敪
    lv_record_kind       VARCHAR2(20);              -- ���R�[�h�敪
    ln_may               NUMBER;                    -- 5���\�Z
    ln_jun               NUMBER;                    -- 6���\�Z
    ln_jul               NUMBER;                    -- 7���\�Z
    ln_aug               NUMBER;                    -- 8���\�Z
    ln_sep               NUMBER;                    -- 9���\�Z
    ln_oct               NUMBER;                    -- 10���\�Z
    ln_nov               NUMBER;                    -- 11���\�Z
    ln_dec               NUMBER;                    -- 12���\�Z
    ln_jan               NUMBER;                    -- 1���\�Z
    ln_feb               NUMBER;                    -- 2���\�Z
    ln_mar               NUMBER;                    -- 3���\�Z
    ln_apr               NUMBER;                    -- 4���\�Z
    ln_sum               NUMBER;                    -- ���i�Q�N�Ԍv
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --�J�E���^
    gn_get_counter_data      := 0;     --�f�[�^��
--
    --���[�J���ϐ��̏�����
    ln_cnt        := 0;
    lv_ret_status := cv_status_normal;
--
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
      iv_get_format => iv_get_format_pat -- �t�H�[�}�b�g�p�^�[��
     ,in_file_id    => in_get_file_id    -- �t�@�C��ID
     ,ov_errbuf     => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
--
    -- ===============================================
    -- �t�@�C���A�b�v���[�hIF�擾(A-2)
    -- ===============================================
    get_upload_data(
      in_file_id           => in_get_file_id       -- FILE_ID
     ,on_get_counter_data  => gn_get_counter_data  -- �f�[�^��
     ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �A�b�v���[�h�f�[�^�폜����(A-3)
    -- ===============================================
    del_upload_data(
      in_file_id  => in_get_file_id   -- �t�@�C��ID
     ,ov_errbuf   => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode  => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg   => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      --�R�~�b�g
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �N�ԏ��i�v��f�[�^�̍��ڕ�������(A-4)
    -- ===============================================
    split_plan_data(
      in_cnt            => gn_get_counter_data  -- �f�[�^��
     ,ov_errbuf         => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    FOR i IN cn_begin_line .. gn_get_counter_data LOOP
--
      -- ===============================================
      -- ���ڃ`�F�b�N(A-5)
      -- ===============================================
      item_check(
        in_cnt               => i                    -- �f�[�^�J�E���^
       ,ov_base_code         => lv_base_code         -- ���_�R�[�h
       ,ov_plan_year         => lv_plan_year         -- �N�x
       ,ov_plan_kind         => lv_plan_kind         -- �\�Z�敪
       ,ov_record_kind       => lv_record_kind       -- ���R�[�h�敪
       ,on_may               => ln_may               -- 5���\�Z
       ,on_jun               => ln_jun               -- 6���\�Z
       ,on_jul               => ln_jul               -- 7���\�Z
       ,on_aug               => ln_aug               -- 8���\�Z
       ,on_sep               => ln_sep               -- 9���\�Z
       ,on_oct               => ln_oct               -- 10���\�Z
       ,on_nov               => ln_nov               -- 11���\�Z
       ,on_dec               => ln_dec               -- 12���\�Z
       ,on_jan               => ln_jan               -- 1���\�Z
       ,on_feb               => ln_feb               -- 2���\�Z
       ,on_mar               => ln_mar               -- 3���\�Z
       ,on_apr               => ln_apr               -- 4���\�Z
       ,on_sum               => ln_sum               -- ���i�Q�N�Ԍv
       ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_check ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        --���[�j���O�ێ�
        lv_ret_status := cv_status_check;
      END IF;
--
      IF ( lv_ret_status = cv_status_normal ) THEN
        -- ===============================================
        -- ���i�v��A�b�v���[�h���[�N�o�^����(A-6)
        -- ===============================================
        ins_plan_tmp(
          in_cnt               => i                    -- �f�[�^�J�E���^
         ,iv_base_code         => lv_base_code         -- ���_�R�[�h
         ,iv_plan_year         => lv_plan_year         -- �N�x
         ,iv_plan_kind         => lv_plan_kind         -- �\�Z�敪
         ,iv_record_kind       => lv_record_kind       -- ���R�[�h�敪
         ,in_may               => ln_may               -- 5���\�Z
         ,in_jun               => ln_jun               -- 6���\�Z
         ,in_jul               => ln_jul               -- 7���\�Z
         ,in_aug               => ln_aug               -- 8���\�Z
         ,in_sep               => ln_sep               -- 9���\�Z
         ,in_oct               => ln_oct               -- 10���\�Z
         ,in_nov               => ln_nov               -- 11���\�Z
         ,in_dec               => ln_dec               -- 12���\�Z
         ,in_jan               => ln_jan               -- 1���\�Z
         ,in_feb               => ln_feb               -- 2���\�Z
         ,in_mar               => ln_mar               -- 3���\�Z
         ,in_apr               => ln_apr               -- 4���\�Z
         ,in_sum               => ln_sum               -- ���i�Q�N�Ԍv
         ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
      --
    END LOOP;
    --
    IF lv_ret_status <> cv_status_normal THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
--
    -- ===============================================
    -- ���i�v��A�b�v���[�h���[�N�擾����(A-7)
    -- ===============================================
    -- �I�[�v��
    OPEN get_plan_tmp_cur;
    -- �f�[�^�擾
    FETCH get_plan_tmp_cur BULK COLLECT INTO gr_plan_tmps_tab;
    -- �N���[�Y
    CLOSE get_plan_tmp_cur;
--
    -- ===============================================
    -- ���_�R�[�h�A�N�x�`�F�b�N����(A-8)
    -- ===============================================
    chk_base_code(
        ov_errbuf                  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode                 => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ���R�[�h�敪�`�F�b�N����(A-9)
    -- ===============================================
    chk_record_kind(
        ov_errbuf                  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode                 => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ���i�Q�}�X�^�`�F�b�N����(A-10)
    -- ===============================================
    chk_master_data(
        ov_errbuf                  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode                 => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �\�Z���ڃ`�F�b�N����(A-11)
    -- ===============================================
    chk_budget_item(
        ov_errbuf                  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode                 => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================================
    -- ���i�v��w�b�_�o�^����(A-12)
    -- ===============================================
    ins_plan_headers(
        ov_errbuf                  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode                 => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================================
    -- ���_�\�Z�o�^�E�X�V����(A-13)
    -- ===============================================
    ins_plan_loc_bdgt(
        ov_errbuf                  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode                 => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================================
    -- ���i�Q�\�Z�o�^�E�X�V����(A-14)
    -- ===============================================
    ins_plan_line(
        ov_errbuf                  => lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode                 => lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg                  => lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
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
    errbuf            OUT VARCHAR2  -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode           OUT VARCHAR2  -- ���^�[���E�R�[�h    --# �Œ� #
   ,in_get_file_id    IN  NUMBER    -- �t�@�C��ID
   ,iv_get_format_pat IN  VARCHAR2  -- �t�H�[�}�b�g�p�^�[��
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
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
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_out
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
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(
      in_get_file_id     -- �t�@�C��ID
     ,iv_get_format_pat  -- �t�H�[�}�b�g�p�^�[��
     ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ===============================================
    -- �I������(A-15)
    -- ===============================================
    --�G���[������
    IF ( lv_retcode = cv_status_error ) THEN
      --�G���[���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      --�G���[�����ݒ�
      gn_error_cnt    := 1;
      --�G���[����ROLLBACK
      ROLLBACK;
    ELSE
      gn_normal_cnt := gn_target_cnt;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
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
--###########################  �Œ蕔 END   #######################################################
--
END XXCSM002A17C;
/
