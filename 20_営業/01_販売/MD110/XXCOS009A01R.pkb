CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A01R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOS009A01R (body)
 * Description      : �󒍈ꗗ���X�g
 * MD.050           : �󒍈ꗗ���X�g MD050_COS_009_A01
 * Version          : 1.16
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  check_parameter        �p�����[�^�`�F�b�N(A-2)
 *  get_data               �Ώۃf�[�^�擾(A-3)
 *  insert_rpt_wrk_data    ���[���[�N�e�[�u���o�^(A-4)
 *  update_order_line_data �󒍖��׏o�͍ςݍX�V�iEDI�捞�̂݁j(A-5)
 *  execute_svf            SVF�N��(A-6)
 *  delete_rpt_wrk_data    ���[���[�N�e�[�u���폜(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/07    1.0   T.TYOU           �V�K�쐬
 *  2009/02/12    1.1   T.TYOU           [��Q�ԍ��F064]�ۊǏꏊ�̊O��������������Ȃ�
 *  2009/02/17    1.2   T.TYOU           get_msg�̃p�b�P�[�W���C��
 *  2009/04/14    1.3   T.Kiriu          [T1_0470]�ڋq�����ԍ��擾���C��
 *  2009/05/08    1.4   T.Kitajima       [T1_0925]�o�א�R�[�h�ύX
 *  2009/06/19    1.5   N.Nishimura      [T1_1437]�f�[�^�p�[�W�s��Ή�
 *  2009/07/13    1.6   K.Kiriu          [0000063]���敪�̉ۑ�Ή�
 *  2009/07/29    1.7   T.Tominaga       [0000271]�󒍃\�[�X��EDI�󒍂Ƃ���ȊO�ƂŃJ�[�\���𕪂���iEDI�󒍂̂݃��b�N�j
 *  2009/10/02    1.8   N.Maeda          [0001338]execute_svf�̓Ɨ��g�����U�N�V������
 *  2009/12/28    1.9   K.Kiriui         [E_�{�ғ�_00407]EDI���[�ďo�͑Ή�
 *                                       [E_�{�ғ�_00409]���[�o�͏����ύX�Ή�
 *                                       [E_�{�ғ�_00583]�`�[�敪�A���ދ敪�o�͑Ή�
 *                                       [E_�{�ғ�_00700]���׋��z�̒[�������ύX�Ή�
 *  2010/01/22    1.9   Y.Kikuchi        [E_�{�ғ�_00408]�`�[�v�o�͑Ή�
 *  2010/03/08    1.10  M.Sano           [E_�{�ғ�_01657]���ʂ̎Q�ƌ��ύX
 *  2010/03/29    1.11  M.Sano           [E_�{�ғ�_02006]PT�Ή�(���̑��iCSV/��ʁj)
 *  2010/04/01    1.12  M.Sano           [E_�{�ғ�_01811]�󒍃\�[�X�u�o�׎��ш˗��v�ǉ��Ή�
 *  2011/04/20    1.13  N.Horigome       [E_�{�ғ�_03310]EDI�捞���̎󒍒��o�����C���Ή�
 *  2012/01/30    1.14  K.Kiriu          [E_�{�ғ�_08658]EDI�o�͎��̏o�͐��ʕύX�Ή�
 *  2012/04/18    1.15  Y.Horikawa       [E_�{�ғ�_09441]PT�Ή�
 *  2012/09/13    1.16  K.Taniguchi      [E_�{�ғ�_09939]EDI�捞���̎󒍒��o�����C���Ή�
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
  cn_per_business_group_id  CONSTANT NUMBER      := fnd_global.per_business_group_id; --PER_BUSINESS_GROUP_ID
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** �󒍃\�[�X��ʎ擾��O ***
  global_order_source_get_expt      EXCEPTION;
  --*** �����`�F�b�N��O ***
  global_format_chk_expt            EXCEPTION;
  --***�󒍓� ���t�t�]�`�F�b�N��O ***
  global_date_rever_o_chk_expt      EXCEPTION;
  --***�o�ח\��� ���t�t�]�`�F�b�N��O ***
  global_date_rever_ss_chk_expt     EXCEPTION;
  --***�[�i�\��� ���t�t�]�`�F�b�N��O ***
  global_date_rever_so_chk_expt     EXCEPTION;
  --*** �����Ώۃf�[�^�o�^��O ***
  global_data_insert_expt           EXCEPTION;
  --*** �����Ώۃf�[�^�X�V��O ***
  global_data_update_expt           EXCEPTION;
  --*** SVF�N����O ***
  global_svf_excute_expt            EXCEPTION;
  --*** �Ώۃf�[�^���b�N��O ***
  global_data_lock_expt             EXCEPTION;
  --*** �Ώۃf�[�^�폜��O ***
  global_data_delete_expt           EXCEPTION;
/* 2009/12/28 Ver1.9 Add Start */
  --*** ���[�o�͋敪�擾��O ***
  global_report_output_get_expt     EXCEPTION;
  --*** EDI���[���t�w��Ȃ���O ***
  global_edi_date_chk_expt          EXCEPTION;
  --*** ��M�� ���t�t�]�`�F�b�N��O ***
  global_date_rever_ocd_chk_expt    EXCEPTION;
  --*** �[�i�� ���t�t�]�`�F�b�N��O ***
  global_date_rever_odh_chk_expt    EXCEPTION;
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
  --*** �󒍃X�e�[�^�X���擾��O ***
  global_order_status_get_expt      EXCEPTION;
  --*** �󒍃\�[�X�Q�Ɛ擪�����擾��O ***
  global_orig_sys_st_get_expt       EXCEPTION;
/* 2010/04/01 Ver1.12 Add End   */
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS009A01R';         -- �p�b�P�[�W��
  cv_conc_name              CONSTANT  VARCHAR2(100) := 'XXCOS009A01R';         -- �R���J�����g��
  --���[�o�͊֘A
  cv_report_id              CONSTANT  VARCHAR2(100) := 'XXCOS009A01R';         -- ���[�h�c
  cv_frm_file               CONSTANT  VARCHAR2(100) := 'XXCOS009A01S.xml';     -- �t�H�[���l���t�@�C����
  cv_vrq_file               CONSTANT  VARCHAR2(100) := 'XXCOS009A01S.vrq';     -- �N�G���[�l���t�@�C����
  cv_output_mode            CONSTANT  VARCHAR2(1)   := '1';                    -- �o�͋敪(PDF)
  cv_extension              CONSTANT  VARCHAR2(100) := '.pdf';                 -- �g���q(PDF)
  cv_xxcos_short_name       CONSTANT  VARCHAR2(100) := 'XXCOS';                -- �̕��̈�Z�k�A�v����
  cv_xxccp_short_name       CONSTANT  VARCHAR2(100) := 'XXCCP';                -- ���ʗ̈�Z�k�A�v����
  cv_xxcoi_short_name       CONSTANT  VARCHAR2(100) := 'XXCOI';                -- �݌ɗ̈�Z�k�A�v����
  --���b�Z�[�W
  cv_str_profile_nm         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00047';    -- MO:�c�ƒP��
  cv_msg_format_check_err   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00002';    -- ���t�����`�F�b�N�G���[���b�Z�[�W
  cv_msg_date_rever_err     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00005';    -- ���t�t�]�G���[���b�Z�[�W
  cv_msg_insert_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00010';    -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_update_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00011';    -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_no_data_err        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00018';    -- ����0���G���[���b�Z�[�W
  cv_msg_select_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00013';    -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_lock_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00001';    -- ���b�N�擾�G���[���b�Z�[�W
  cv_msg_delete_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00012';    -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_api_err            CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00017';    -- API�G���[���b�Z�[�W
  cv_msg_org_cd_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOI1-00005';    -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_org_id_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOI1-00006';    -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_proc_date_err      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00014';    -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_prof_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00004';    -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_parameter          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11801';    -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_parameter1         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11812';    -- �p�����[�^�o�̓��b�Z�[�W(EDI�p)�i�V�K�j
  cv_msg_order_source       CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11811';    -- �󒍃\�[�X�擾�G���[���b�Z�[�W
/* 2009/12/28 Ver1.9 Add Start */
  cv_msg_rep_out_type_err   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11813';    -- ���[�o�͋敪�擾�G���[���b�Z�[�W
  cv_msg_parameter2         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11814';    -- �p�����[�^�o�̓��b�Z�[�W(EDI�p)�i�ďo�́j
  cv_msg_edi_date_err       CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11819';    -- EDI���[���t�w��Ȃ��G���[
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
  cv_msg_order_status_err   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11823';    -- �󒍃X�e�[�^�X���̎擾�G���[
  cv_msg_orig_sys_st_err    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11824';    -- �󒍃\�[�X�Q�Ɛ擪�����擾�G���[
/* 2010/04/01 Ver1.12 Add End   */
  --�g�[�N����
  cv_tkn_nm_account              CONSTANT  VARCHAR2(100) :=  'ACCOUNT_NAME';   --��v���Ԏ�ʖ���
  cv_tkn_nm_para_date            CONSTANT  VARCHAR2(100) :=  'PARA_DATE';      --�󒍓�(FROM)�܂��͎󒍓�(TO)
  cv_tkn_nm_order_source         CONSTANT  VARCHAR2(100) :=  'ORDER_SOURCE_ID';              --   �󒍃\�[�X
  cv_tkn_nm_base_code            CONSTANT  VARCHAR2(100) :=  'DELIVERY_BASE_CODE';           --   �[�i���_�R�[�h
  cv_tkn_nm_date_from            CONSTANT  VARCHAR2(100) :=  'DATE_FROM';                    --   (FROM)
  cv_tkn_nm_date_to              CONSTANT  VARCHAR2(100) :=  'DATE_TO';                      --   (TO)
  cv_tkn_nm_ordered_date_f_t     CONSTANT  VARCHAR2(100) :=  'ORDERED_DATE_FROM_TO';         --   �󒍓�(FROM),(TO)
  cv_tkn_nm_s_ship_date_f_t      CONSTANT  VARCHAR2(100) :=  'SCHEDULE_SHIP_DATE_FROM_TO';   --   �o�ח\���(FROM),(TO)
  cv_tkn_nm_s_ordered_date_f_t   CONSTANT  VARCHAR2(100) :=  'SCHEDULE_ORDERED_DATE_FROM_TO';--   �[�i�\���(FROM),(TO)
  cv_tkn_nm_entered_by_code      CONSTANT  VARCHAR2(100) :=  'ENTERED_BY_CODE';             --   ���͎҃R�[�h
  cv_tkn_nm_ship_to_code         CONSTANT  VARCHAR2(100) :=  'SHIP_TO_CODE';                --   �o�א�R�[�h
  cv_tkn_nm_subinventory         CONSTANT  VARCHAR2(100) :=  'SUBINVENTORY';                --   �ۊǏꏊ
  cv_tkn_nm_order_numbe          CONSTANT  VARCHAR2(100) :=  'ORDER_NUMBER';                --   �󒍔ԍ� 
  cv_tkn_nm_table_name           CONSTANT  VARCHAR2(100) :=  'TABLE_NAME';          --�e�[�u������
  cv_tkn_nm_table_lock           CONSTANT  VARCHAR2(100) :=  'TABLE';               --�e�[�u������(���b�N�G���[���p)
  cv_tkn_nm_key_data             CONSTANT  VARCHAR2(100) :=  'KEY_DATA';            --�L�[�f�[�^
  cv_tkn_nm_api_name             CONSTANT  VARCHAR2(100) :=  'API_NAME';            --API����
  cv_tkn_nm_profile1             CONSTANT  VARCHAR2(100) :=  'PROFILE';             --�v���t�@�C����(�̔��̈�)
  cv_tkn_nm_profile2             CONSTANT  VARCHAR2(100) :=  'PRO_TOK';             --�v���t�@�C����(�݌ɗ̈�)
  cv_tkn_nm_org_cd               CONSTANT  VARCHAR2(100) :=  'ORG_CODE_TOK';        --�݌ɑg�D�R�[�h
  cv_tkn_nm_acc_type             CONSTANT  VARCHAR2(100) :=  'TYPE';                --��v���ԋ敪�Q�ƃ^�C�v
/* 2009/12/28 Ver1.9 Add Start */
  cv_tkn_nm_rep_out_type        CONSTANT  VARCHAR2(100)  :=  'REPORT_OUTPUT_TYPE';          --���[�o�͋敪
  cv_tkn_nm_chain_code          CONSTANT  VARCHAR2(100)  :=  'CHAIN_CODE';                  --�`�F�[���X�R�[�h
  cv_tkn_nm_order_c_date_f_t    CONSTANT  VARCHAR2(100)  :=  'ORDER_CREATION_DATE_FROM_TO'; --��M��(FROM),(TO)
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
  cv_tkn_nm_order_source_name    CONSTANT  VARCHAR2(100) :=  'ORDER_SOURCE_NAME';   --�󒍃\�[�X��
  cv_tkn_nm_order_status         CONSTANT  VARCHAR2(100) :=  'ORDER_STATUS';        --�X�e�[�^�X
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
  cv_tkn_output_quantity_type    CONSTANT  VARCHAR2(100) :=  'OUTPUT_QUANTITY_TYPE'; --�o�͐��ʋ敪
/* 2012/01/30 Ver1.14 Add End   */
  --�g�[�N���l
  cv_msg_vl_order_date_from      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11802';    --�󒍓�(FROM)
  cv_msg_vl_order_date_to        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11803';    --�󒍓�(TO)
  cv_msg_vl_s_ship_date_from     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11804';    --�o�ח\���(FROM)
  cv_msg_vl_s_ship_date_to       CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11805';    --�o�ח\���(TO)
  cv_msg_vl_s_order_date_from    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11806';    --�[�i�\���(FROM)
  cv_msg_vl_s_order_date_to      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11807';    --�[�i�\���(TO)
  cv_msg_vl_table_name1          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11808';    --�󒍈ꗗ���X�g���[���[�N�e�[�u��
  cv_msg_vl_table_name2          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11809';    --�󒍃e�[�u��
  cv_msg_vl_table_name3          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11810';    --�󒍖��׃e�[�u��
  cv_msg_vl_api_name             CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00041';    --API����
  cv_msg_vl_key_request_id       CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00088';    --�v��ID
  cv_msg_vl_min_date             CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00120';    --MIN���t
  cv_msg_vl_max_date             CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00056';    --MAX���t
/* 2009/12/28 Ver1.9 Add Start */
  cv_msg_vl_order_c_date_from    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11815';    --��M��(FROM)
  cv_msg_vl_order_c_date_to      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11816';    --��M��(TO)
  cv_msg_vl_order_date_h_from    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11817';    --�[�i��(FROM)
  cv_msg_vl_order_date_h_to      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11818';    --�[�i��(TO)
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
  cv_msg_vl_order_source_edi     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11820';    --EDI�捞
  cv_msg_vl_order_source_clik    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11821';    --�N�C�b�N�󒍓���
  cv_msg_vl_order_source_ship    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11822';    --�o�׎��ш˗�
/* 2010/04/01 Ver1.12 Add End   */
  --�󒍖��׃X�e�[�^�X
  ct_ln_status_closed       CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CLOSED';     --�N���[�Y
  ct_ln_status_cancelled    CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CANCELLED';  --���
  --���t�t�H�[�}�b�g
  cv_yyyymmdd               CONSTANT  VARCHAR2(100) :=  'YYYYMMDD';              --YYYYMMDD�^
  cv_yyyy_mm_dd             CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD';            --YYYY/MM/DD�^
  cv_yyyy_mm                CONSTANT  VARCHAR2(100) :=  'YYYY/MM';               --YYYY/MM�^
  cv_yyyymmddhhmiss         CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD HH24:mi:ss'; --YYYYMMDDHHMISS�^
  --�N�C�b�N�R�[�h�Q�Ɨp
  --�g�p�\�t���O�萔
  cv_emp                    CONSTANT  VARCHAR2(100) := 'EMP';                  -- EMP
  ct_enabled_flg_y          CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                                    :=  'Y';                   --�g�p�\
  cv_lang                   CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );     --����
  cv_return                 CONSTANT  VARCHAR2(100) :=  'RETURN';              --�}�C�i�X�^�C�v
  cv_type_ost_009_a01       CONSTANT  VARCHAR2(100) :=  'XXCOS1_ODR_SRC_TYPE_009_A01';
                                                                               --�󒍃\�[�X���
/* 2009/12/28 Ver1.9 Add Start */
  cv_type_rot               CONSTANT  VARCHAR2(100) :=  'XXCOS1_REPORT_OUTPUT_TYPE';
                                                                               --���[�o�͋敪
/* 2010/04/01 Ver1.12 Add Start */
  cv_type_orig_sys_st       CONSTANT  VARCHAR2(100) :=  'XXCOS1_ORDER_HEADERS_008_A06';
                                                                               --�󒍃\�[�X�Q�Ɛ擪���� 
  cv_type_status_name       CONSTANT  VARCHAR2(100) :=  'XXCOS1_ODR_STATUS_009_A01';
                                                                               --�󒍈ꗗ���X�g�ΏۃX�e�[�^�X
/* 2010/04/01 Ver1.12 Add End   */
  cv_code_rot_1             CONSTANT  VARCHAR2(100) :=  '1';                   --'1'(�V�K)
/* 2009/12/28 Ver1.9 Add End   */
  cv_code_ost_009_a01       CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A01%';      --�󒍃\�[�X�̃N�C�b�N�R�[�h
  cv_diff_y                 CONSTANT  VARCHAR2(100) :=  'Y';                   --Y
/* 2010/04/01 Ver1.12 Add Start */
  ct_lookup_code_ship       CONSTANT  fnd_lookup_values.lookup_code%TYPE       --�u�󒍃\�[�X�Q�Ɛ擪�����v��
                                                    :=  '10';                  --�N�C�b�N�R�[�h(�o�׎��ш˗�)
  ct_lookup_code_clik       CONSTANT  fnd_lookup_values.lookup_code%TYPE       --�u�󒍃\�[�X�Q�Ɛ擪�����v��
                                                    :=  '20';                  --�N�C�b�N�R�[�h(�N�C�b�N��)
/* 2010/04/01 Ver1.12 Add End   */
  --�v���t�@�C���֘A
  cv_prof_org               CONSTANT  VARCHAR2(100) :=  'XXCOI1_ORGANIZATION_CODE';
                                                                               -- �v���t�@�C����(�݌ɑg�D�R�[�h)
  cv_prof_min_date          CONSTANT  VARCHAR2(100) :=  'XXCOS1_MIN_DATE';     -- �v���t�@�C����(MIN���t)
  cv_prof_max_date          CONSTANT  VARCHAR2(100) :=  'XXCOS1_MAX_DATE';     -- �v���t�@�C����(MAX���t)
  --MO:�c�ƒP��
  ct_prof_org_id            CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';
/* 2009/07/13 Ver1.6 Add Start */
  --���敪
  cv_target_order_01        CONSTANT  VARCHAR2(100) :=  '01';                  -- �󒍍쐬�Ώ�01
/* 2009/07/13 Ver1.6 Add End   */
/* 2009/12/28 Ver1.9 Add Start */
  --���[����������
  cv_re_output_flag         CONSTANT  VARCHAR2(1)   := '1';                    -- EDI���[�ďo��
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/01/22 Ver1.9 Add Start E_�{�ғ�_00408�Ή� */
  cn_record_type_detail     CONSTANT  NUMBER        := 1;                      -- ���R�[�h�^�C�v�F����
  cn_record_type_denpyokei  CONSTANT  NUMBER        := 2;                      -- ���R�[�h�^�C�v�F�`�[�v
/* 2010/01/22 Ver1.9 Add End E_�{�ғ�_00408�Ή� */
/* 2012/01/30 Ver1.14 Add Start */
  --�o�͐��ʋ敪
  cv_edi_quantity_type      CONSTANT  VARCHAR2(1)   := '1';                    -- �o�͐��ʋ敪�FEDI
  cv_oe_quantity_type       CONSTANT  VARCHAR2(1)   := '2';                    -- �o�͐��ʋ敪�FOE(���)
/* 2012/01/30 Ver1.14 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
  --���̑��萔
  cv_exists_yes             CONSTANT  VARCHAR2(1)   := 'Y';                    -- ���݃`�F�b�N�o�͗p
  cv_multi                  CONSTANT  VARCHAR2(1)   := '%';                    -- �N�C�b�N�̓E�v�̕��������p
/* 2010/04/01 Ver1.12 Add End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --�󒍖��׃e�[�u���^
  TYPE g_lines_rowid_ttype IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
  --�󒍈ꗗ���X�g���[���[�N�e�[�u���^
  TYPE g_rpt_data_ttype IS TABLE OF xxcos_rep_order_list%ROWTYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  g_report_data_tab           g_rpt_data_ttype;                                  --���[�f�[�^�R���N�V����
  gt_oola_rowid_tab           g_lines_rowid_ttype;                               --����ROWID
  gt_org_id                   mtl_parameters.organization_id%TYPE;               --�݌ɑg�DID
  gd_proc_date                DATE;                                              --�Ɩ����t
  gd_min_date                 DATE;                                              --MIN���t
  gd_max_date                 DATE;                                              --MAX���t
  gn_org_id                   NUMBER;                                            --�c�ƒP��
  gv_order_source_edi_chk     oe_order_sources.name%TYPE;                        --�󒍃\�[�X�iEDI�捞�j
  gv_order_source_clik_chk    oe_order_sources.name%TYPE;                        --�󒍃\�[�X�i�N�C�b�N�󒍓��́j
/* 2010/04/01 Ver1.12 Add Start */
  gv_order_source_ship_chk    oe_order_sources.name%TYPE;                        --�󒍃\�[�X�i�o�׎��ш˗��j
  gt_orig_sys_st_value        fnd_lookup_values.meaning%TYPE DEFAULT '';         --�O���V�X�e���󒍔ԍ��擪����
/* 2010/04/01 Ver1.12 Add End   */
/* 2009/12/28 Ver1.9 Add Start */
  gt_report_output_type_n     fnd_lookup_values.meaning%TYPE;                    --�o�͋敪�i�V�K�j
/* 2009/12/28 Ver1.9 Add End   */
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_order_source                 IN     VARCHAR2,         --   �󒍃\�[�X
    iv_delivery_base_code           IN     VARCHAR2,         --   �[�i���_�R�[�h
    iv_ordered_date_from            IN     VARCHAR2,         --   �󒍓�(FROM)
    iv_ordered_date_to              IN     VARCHAR2,         --   �󒍓�(TO)
    iv_schedule_ship_date_from      IN     VARCHAR2,         --   �o�ח\���(FROM)
    iv_schedule_ship_date_to        IN     VARCHAR2,         --   �o�ח\���(TO)
    iv_schedule_ordered_date_from   IN     VARCHAR2,         --   �[�i�\���(FROM)
    iv_schedule_ordered_date_to     IN     VARCHAR2,         --   �[�i�\���(TO)
    iv_entered_by_code              IN     VARCHAR2,         --   ���͎҃R�[�h
    iv_ship_to_code                 IN     VARCHAR2,         --   �o�א�R�[�h
    iv_subinventory                 IN     VARCHAR2,         --   �ۊǏꏊ
    iv_order_number                 IN     VARCHAR2,         --   �󒍔ԍ�
/* 2009/12/28 Ver1.9 Add Start */
    iv_output_type                  IN     VARCHAR2,         --   �o�͋敪
    iv_chain_code                   IN     VARCHAR2,         --   �`�F�[���X�R�[�h
    iv_order_creation_date_from     IN     VARCHAR2,         --   ��M��(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,         --   ��M��(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,         --   �[�i��(�w�b�_)(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,         --   �[�i��(�w�b�_)(TO)
/* 2009/12/28 Ver1.9 Add Start */
/* 2010/04/01 Ver1.12 Add Start */
    iv_order_status                 IN     VARCHAR2,         --   �󒍃X�e�[�^�X
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
    iv_output_quantity_type         IN     VARCHAR2,         --   �o�͐��ʋ敪
/* 2012/01/30 Ver1.14 Add End   */
    ov_errbuf                       OUT    VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                 -- �v���O������
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
/* 2012/01/30 Ver1.14 Add Start */
    lt_output_quantity_type fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_OUTPUT_QUANTITY_TYPE';  --�󒍈ꗗ�p�o�͐��ʋ敪
/* 2012/01/30 Ver1.14 Add End   */
--
    -- *** ���[�J���ϐ� ***
    lv_para_msg      VARCHAR2(5000);                         -- �p�����[�^�o�̓��b�Z�[�W
    lt_org_cd        mtl_parameters.organization_code%TYPE;  -- �݌ɑg�D�R�[�h
    lv_date_item     VARCHAR2(100);                          -- MIN���t/MAX���t
    lv_profile_name  VARCHAR2(100);                          -- �c�ƒP��
/* 2010/04/01 Ver1.12 Add Start */
    lv_token_value1        VARCHAR2(100);                          -- �G���[���b�Z�[�W�ɏo�͂���g�[�N���l
    lt_order_status_name   fnd_lookup_values.description%TYPE;     -- �󒍃X�e�[�^�X����
/* 2010/04/01 Ver1.12 Add End   */
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
   --==================================
    -- 1.MO:�c�ƒP��
    --==================================
    gn_org_id := FND_PROFILE.VALUE( ct_prof_org_id );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gn_org_id IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application => cv_xxcos_short_name,
        iv_name        => cv_str_profile_nm
      );
      --�v���t�@�C����������擾
      lv_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcos_short_name,
        iv_name               => cv_msg_prof_err,
        iv_token_name1        => cv_tkn_nm_profile1,
        iv_token_value1       => lv_profile_name
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 2.�݌ɑg�D�R�[�h�擾����
    --========================================
    lt_org_cd := FND_PROFILE.VALUE( cv_prof_org );
    IF ( lt_org_cd IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcoi_short_name,
        iv_name               =>  cv_msg_org_cd_err,
        iv_token_name1        =>  cv_tkn_nm_profile2,
        iv_token_value1       =>  cv_prof_org
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 3.�݌ɑg�DID�擾����
    --========================================
    gt_org_id := xxcoi_common_pkg.get_organization_id( lt_org_cd );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcoi_short_name,
        iv_name               =>  cv_msg_org_id_err,
        iv_token_name1        =>  cv_tkn_nm_org_cd,
        iv_token_value1       =>  lt_org_cd
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 4.�Ɩ����t�擾����
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 5.MIN���t�擾����
    --========================================
    gd_min_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_min_date ), cv_yyyy_mm_dd );
    IF ( gd_min_date IS NULL ) THEN
      lv_date_item            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_min_date
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile1,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 6.MAX���t�擾����
    --========================================
    gd_max_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_max_date ), cv_yyyy_mm_dd );
    IF ( gd_max_date IS NULL ) THEN
      lv_date_item            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_max_date
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile1,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 7.�󒍃\�[�X��ʎ擾�̑O����
    --========================================
    BEGIN
      --EDI�捞 �󒍃\�[�X�̖��̂��擾
      SELECT  look_val.description        order_source_edi
      INTO    gv_order_source_edi_chk
-- ******** 2009/10/02 1.8 N.Maeda MOD START ******** --
      FROM    fnd_lookup_values           look_val
      WHERE   look_val.language           = cv_lang
      AND     look_val.lookup_type        = cv_type_ost_009_a01
      AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
      AND     look_val.attribute2         = cv_diff_y               --EDI�捞
      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
      AND     look_val.enabled_flag       = ct_enabled_flg_y
      AND     rownum                      = 1
      ;
--
--      FROM    fnd_lookup_values           look_val,
--              fnd_lookup_types_tl         types_tl,
--              fnd_lookup_types            types,
--              fnd_application_tl          appl,
--              fnd_application             app
--      WHERE   appl.application_id         = types.application_id
--      AND     app.application_id          = appl.application_id
--      AND     types_tl.lookup_type        = look_val.lookup_type
--      AND     types.lookup_type           = types_tl.lookup_type
--      AND     types.security_group_id     = types_tl.security_group_id
--      AND     types.view_application_id   = types_tl.view_application_id
--      AND     types_tl.language           = cv_lang
--      AND     look_val.language           = cv_lang
--      AND     appl.language               = cv_lang
--      AND     app.application_short_name  = cv_xxcos_short_name
--      AND     look_val.lookup_type        = cv_type_ost_009_a01
--      AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
--      AND     look_val.attribute2         = cv_diff_y               --EDI�捞
--      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--      AND     look_val.enabled_flag       = ct_enabled_flg_y
--      AND     rownum                      = 1
--      ;
-- ******** 2009/10/02 1.8 N.Maeda MOD END ******** --
/* 2010/04/01 Ver1.12 Add Start */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_token_value1 := xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_vl_order_source_edi
        );
        RAISE global_order_source_get_expt;
    END;
--
    BEGIN
/* 2010/04/01 Ver1.12 Add End   */
      --�N�C�b�N�󒍓��� �󒍃\�[�X�̖��̂��擾
      SELECT  look_val.description        order_source_clik
      INTO    gv_order_source_clik_chk
-- ******** 2009/10/02 1.8 N.Maeda MOD START ******** --
      FROM    fnd_lookup_values           look_val
      WHERE   look_val.language           = cv_lang
      AND     look_val.lookup_type        = cv_type_ost_009_a01
      AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
      AND     look_val.attribute4         = cv_diff_y               --�N�C�b�N�󒍓���
      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
      AND     look_val.enabled_flag       = ct_enabled_flg_y
      AND     rownum                      = 1
      ;
--
--      FROM    fnd_lookup_values           look_val,
--              fnd_lookup_types_tl         types_tl,
--              fnd_lookup_types            types,
--              fnd_application_tl          appl,
--              fnd_application             app
--      WHERE   appl.application_id         = types.application_id
--      AND     app.application_id          = appl.application_id
--      AND     types_tl.lookup_type        = look_val.lookup_type
--      AND     types.lookup_type           = types_tl.lookup_type
--      AND     types.security_group_id     = types_tl.security_group_id
--      AND     types.view_application_id   = types_tl.view_application_id
--      AND     types_tl.language           = cv_lang
--      AND     look_val.language           = cv_lang
--      AND     appl.language               = cv_lang
--      AND     app.application_short_name  = cv_xxcos_short_name
--      AND     look_val.lookup_type        = cv_type_ost_009_a01
--      AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
--      AND     look_val.attribute4         = cv_diff_y               --�N�C�b�N�󒍓���
--      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--      AND     look_val.enabled_flag       = ct_enabled_flg_y
--      AND     rownum                      = 1
--      ;
-- ******** 2009/10/02 1.8 N.Maeda MOD END ******** --
/* 2010/04/01 Ver1.12 Add Start */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_token_value1 := xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_vl_order_source_clik
        );
        RAISE global_order_source_get_expt;
    END;
--
    BEGIN
      --�o�׎��ш˗� �󒍃\�[�X�̖��̂��擾
      SELECT  look_val.description        order_source_clik
      INTO    gv_order_source_ship_chk
      FROM    fnd_lookup_values           look_val
      WHERE   look_val.language           = cv_lang
      AND     look_val.lookup_type        = cv_type_ost_009_a01
      AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
      AND     look_val.attribute6         = cv_diff_y               --�N�C�b�N�󒍓���
      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
      AND     look_val.enabled_flag       = ct_enabled_flg_y
      AND     rownum                      = 1
      ;
/* 2010/04/01 Ver1.12 Add End   */
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
/* 2010/04/01 Ver1.12 Add Start */
        lv_token_value1 := xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_vl_order_source_ship
        );
/* 2010/04/01 Ver1.12 Add End   */
        RAISE global_order_source_get_expt;
    END;
--
/* 2009/12/28 Ver1.9 Add Start */
    --========================================
    -- 8.EDI���[�̏ꍇ�̑O����
    --========================================
    IF ( iv_order_source = gv_order_source_edi_chk) THEN      --�iEDI�p�j
      BEGIN
        --���o�����ׁ̈A�o�͋敪�̐V�K���擾
        SELECT look_val.meaning
        INTO   gt_report_output_type_n
        FROM   fnd_lookup_values  look_val
        WHERE  look_val.language      =  cv_lang
        AND    look_val.lookup_type   =  cv_type_rot
        AND    look_val.lookup_code   =  cv_code_rot_1
        AND    gd_proc_date           >= NVL( look_val.start_date_active, gd_min_date )
        AND    gd_proc_date           <= NVL( look_val.end_date_active, gd_max_date )
        AND    look_val.enabled_flag  =  ct_enabled_flg_y
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE global_report_output_get_expt;
      END;
    END IF;
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
--
    --========================================
    -- 9.�O���V�X�e���󒍔ԍ��擪�����擾����
    --========================================
    BEGIN
      IF (    iv_order_source = gv_order_source_clik_chk) THEN
        -- �u�󒍃\�[�X�Q�Ɛ擪�����v�̎擾�i�N�C�b�N�󒍓��́j
        SELECT look_val.meaning
        INTO   gt_orig_sys_st_value
        FROM   fnd_lookup_values           look_val
        WHERE  look_val.lookup_type        = cv_type_orig_sys_st
        AND    look_val.language           = cv_lang
        AND    gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
        AND    gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
        AND    look_val.enabled_flag       = ct_enabled_flg_y
        AND    look_val.lookup_code        = ct_lookup_code_clik
        ;
      ELSIF ( iv_order_source = gv_order_source_ship_chk) THEN
        -- �u�󒍃\�[�X�Q�Ɛ擪�����v�̎擾�i�o�׎��ш˗��j
        SELECT look_val.meaning
        INTO   gt_orig_sys_st_value
        FROM   fnd_lookup_values           look_val
        WHERE  look_val.lookup_type        = cv_type_orig_sys_st
        AND    look_val.language           = cv_lang
        AND    gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
        AND    gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
        AND    look_val.enabled_flag       = ct_enabled_flg_y
        AND    look_val.lookup_code        = ct_lookup_code_ship
        ;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_token_value1 := xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  iv_order_source
        );
        RAISE global_orig_sys_st_get_expt;
    END;
--
/* 2010/04/01 Ver1.12 Add End   */
    --========================================
    -- 10.�p�����[�^�o�͏���
    --========================================
    IF ( iv_order_source <> gv_order_source_edi_chk) THEN      --���̑��p�iCSV/��ʁj
/* 2010/04/01 Ver1.12 Mod Start */
      -- �󒍃X�e�[�^�X�̖��̎擾
      IF ( iv_order_status IS NOT NULL ) THEN
        BEGIN
          --�󒍃X�e�[�^�X���̎擾
          SELECT
              look_val.description
          INTO
              lt_order_status_name
          FROM
              fnd_lookup_values  look_val
          WHERE
          -- �Q�ƃ^�C�v�Œ����(�^�C�v�F�󒍈ꗗ���X�g�ΏۃX�e�[�^�X)
              look_val.language      =  cv_lang
          AND look_val.lookup_type   =  cv_type_status_name
          AND gd_proc_date           >= NVL( look_val.start_date_active, gd_min_date )
          AND gd_proc_date           <= NVL( look_val.end_date_active, gd_max_date )
          AND look_val.enabled_flag  =  ct_enabled_flg_y
          -- ���e�Ɠ��̓p�����[�^.�󒍃X�e�[�^�X������̂���
          AND look_val.meaning       =  iv_order_status
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            RAISE global_order_status_get_expt;
        END;
      END IF;
      -- �p�����[�^�̕\��
/* 2010/04/01 Ver1.12 Mod End   */
      lv_para_msg             :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_parameter,
        iv_token_name1        =>  cv_tkn_nm_order_source,
        iv_token_value1       =>  iv_order_source,
        iv_token_name2        =>  cv_tkn_nm_base_code,
        iv_token_value2       =>  iv_delivery_base_code,
        iv_token_name3        =>  cv_tkn_nm_ordered_date_f_t,
        iv_token_value3       =>  iv_ordered_date_from || ',' || iv_ordered_date_to,
        iv_token_name4        =>  cv_tkn_nm_s_ship_date_f_t,
        iv_token_value4       =>  iv_schedule_ship_date_from || ',' || iv_schedule_ship_date_to,
        iv_token_name5        =>  cv_tkn_nm_s_ordered_date_f_t,
        iv_token_value5       =>  iv_schedule_ordered_date_from || ',' || iv_schedule_ordered_date_to,
        iv_token_name6        =>  cv_tkn_nm_entered_by_code,
        iv_token_value6       =>  iv_entered_by_code,
        iv_token_name7        =>  cv_tkn_nm_ship_to_code,
        iv_token_value7       =>  iv_ship_to_code,
        iv_token_name8        =>  cv_tkn_nm_subinventory,
        iv_token_value8       =>  iv_subinventory,
        iv_token_name9        =>  cv_tkn_nm_order_numbe,
/* 2010/04/01 Ver1.12 Mod Start */
--        iv_token_value9       =>  iv_order_number
        iv_token_value9       =>  iv_order_number,
        iv_token_name10       =>  cv_tkn_nm_order_status,
        iv_token_value10      =>  lt_order_status_name
/* 2010/04/01 Ver1.12 Mod End   */
      );
/* 2009/12/28 Ver1.9 Mod Start */
--    ELSE                                                      --EDI�p
    ELSIF ( iv_output_type = gt_report_output_type_n ) THEN   --EDI�i�V�K�j
/* 2009/12/28 Ver1.9 Mod End   */
      lv_para_msg             :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_parameter1,
        iv_token_name1        =>  cv_tkn_nm_order_source,
        iv_token_value1       =>  iv_order_source,
        iv_token_name2        =>  cv_tkn_nm_base_code,
/* 2009/12/28 Ver1.9 Mod Start */
--        iv_token_value2       =>  iv_delivery_base_code
        iv_token_value2       =>  iv_delivery_base_code,
        iv_token_name3        =>  cv_tkn_nm_rep_out_type,
/* 2012/01/30 Ver1.14 Mod Start */
--        iv_token_value3       =>  iv_output_type
        iv_token_value3       =>  iv_output_type,
        iv_token_name4        =>  cv_tkn_output_quantity_type,
        iv_token_value4       =>  xxcos_common_pkg.get_specific_master(
                                    lt_output_quantity_type
                                   ,iv_output_quantity_type
                                  )
/* 2012/01/30 Ver1.14 Mod End   */
/* 2009/12/28 Ver1.9 Mod End   */
      );
/* 2009/12/28 Ver1.9 Add Start */
    ELSE
      lv_para_msg             :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_parameter2,
        iv_token_name1        =>  cv_tkn_nm_order_source,
        iv_token_value1       =>  iv_order_source,
        iv_token_name2        =>  cv_tkn_nm_base_code,
        iv_token_value2       =>  iv_delivery_base_code,
        iv_token_name3        =>  cv_tkn_nm_rep_out_type,
        iv_token_value3       =>  iv_output_type,
        iv_token_name4        =>  cv_tkn_nm_chain_code,
        iv_token_value4       =>  iv_chain_code,
        iv_token_name5        =>  cv_tkn_nm_order_c_date_f_t,
        iv_token_value5       =>  iv_order_creation_date_from || ',' || iv_order_creation_date_to,
        iv_token_name6        =>  cv_tkn_nm_s_ordered_date_f_t,
/* 2012/01/30 Ver1.14 Mod Start */
--        iv_token_value6       =>  iv_ordered_date_h_from || ',' || iv_ordered_date_h_to
        iv_token_value6       =>  iv_ordered_date_h_from || ',' || iv_ordered_date_h_to,
        iv_token_name7        =>  cv_tkn_output_quantity_type,
        iv_token_value7       =>  xxcos_common_pkg.get_specific_master(
                                    lt_output_quantity_type
                                   ,iv_output_quantity_type
                                  )
/* 2012/01/30 Ver1.14 Mod End   */
      );
/* 2009/12/28 Ver1.9 Add End   */
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
--
  EXCEPTION
    -- *** �󒍃\�[�X��ʎ擾��O�n���h�� ***
    WHEN global_order_source_get_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
/* 2010/04/01 Ver1.12 Mod Start */
--        iv_name               =>  cv_msg_order_source
        iv_name               =>  cv_msg_order_source,
        iv_token_name1        =>  cv_tkn_nm_order_source_name,
        iv_token_value1       =>  lv_token_value1
/* 2010/04/01 Ver1.12 Mod End   */
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
/* 2009/12/28 Ver1.9 Add Start */
    -- *** ���[�o�͋敪�擾��O�n���h�� ***
    WHEN global_report_output_get_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_rep_out_type_err
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
/* 2009/12/28 Ver1.9 Add End   */
--
/* 2010/04/01 Ver1.12 Add Start */
    -- *** �󒍃X�e�[�^�X���擾��O�n���h�� ***
    WHEN global_order_status_get_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_order_status_err
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** �󒍃\�[�X�Q�Ɛ擪�����擾��O�n���h�� ***
    WHEN global_orig_sys_st_get_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_orig_sys_st_err,
        iv_token_name1        =>  cv_tkn_nm_order_source_name,
        iv_token_value1       =>  lv_token_value1
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
/* 2010/04/01 Ver1.12 Add End   */
--#################################  �Œ��O������ START   ####################################
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : check_parameter
   * Description      : �p�����[�^�`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    iv_ordered_date_from            IN     VARCHAR2,     --   �󒍓�(FROM)
    iv_ordered_date_to              IN     VARCHAR2,     --   �󒍓�(TO)
    iv_schedule_ship_date_from      IN     VARCHAR2,     --   �o�ח\���(FROM)
    iv_schedule_ship_date_to        IN     VARCHAR2,     --   �o�ח\���(TO)
    iv_schedule_ordered_date_from   IN     VARCHAR2,     --   �[�i�\���(FROM)
    iv_schedule_ordered_date_to     IN     VARCHAR2,     --   �[�i�\���(TO)
/* 2009/12/28 Ver1.9 Add Start */
    iv_order_creation_date_from     IN     VARCHAR2,     --   ��M��(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,     --   ��M��(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,     --   �[�i��(�w�b�_)(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,     --   �[�i��(�w�b�_)(TO)
    iv_order_source                 IN     VARCHAR2,     --   �󒍃\�[�X
    iv_output_type                  IN     VARCHAR2,     -- �o�͋敪
/* 2009/12/28 Ver1.9 Add End   */
    od_ordered_date_from            OUT    DATE,         --   �󒍓�(FROM)_�`�F�b�NOK
    od_ordered_date_to              OUT    DATE,         --   �󒍓�(TO)_�`�F�b�NOK
    od_schedule_ship_date_from      OUT    DATE,         --   �o�ח\���(FROM)_�`�F�b�NOK
    od_schedule_ship_date_to        OUT    DATE,         --   �o�ח\���(TO)_�`�F�b�NOK
    od_schedule_ordered_date_from   OUT    DATE,         --   �[�i�\���(FROM)_�`�F�b�NOK
    od_schedule_ordered_date_to     OUT    DATE,         --   �[�i�\���(TO)_�`�F�b�NOK
/* 2009/12/28 Ver1.9 Add Start */
    od_order_creation_date_from     OUT    DATE,         --   ��M��(FROM)_�`�F�b�NOK
    od_order_creation_date_to       OUT    DATE,         --   ��M��(TO)_�`�F�b�NOK
    od_ordered_date_h_from          OUT    DATE,         --   �[�i��(�w�b�_)(FROM)_�`�F�b�NOK
    od_ordered_date_h_to            OUT    DATE,         --   �[�i��(�w�b�_)(TO)_�`�F�b�NOK
/* 2009/12/28 Ver1.9 Add End   */
    ov_errbuf                       OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- �v���O������
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
    lv_check_item                    VARCHAR2(100);      --�󒍓�(FROM)���͎󒍓�(TO)����
    lv_check_item1                   VARCHAR2(100);      --�󒍓�(FROM)����
    lv_check_item2                   VARCHAR2(100);      --�󒍓�(TO)����
    ld_ordered_date_from             DATE;               -- �󒍓�(FROM)
    ld_ordered_date_to               DATE;               -- �󒍓�(TO)
    ld_schedule_ship_date_from       DATE;               -- �o�ח\���(FROM)
    ld_schedule_ship_date_to         DATE;               -- �o�ח\���(TO)
    ld_schedule_ordered_date_from    DATE;               -- �[�i�\���(FROM)
    ld_schedule_ordered_date_to      DATE;               -- �[�i�\���(TO)
/* 2009/12/28 Ver1.9 Add Start */
    ld_order_creation_date_from      DATE;               -- ��M��(FROM)_�`�F�b�NOK
    ld_order_creation_date_to        DATE;               -- ��M��(TO)_�`�F�b�NOK
    ld_ordered_date_h_from           DATE;               -- �[�i��(�w�b�_)(FROM)_�`�F�b�NOK
    ld_ordered_date_h_to             DATE;               -- �[�i��(�w�b�_)(TO)_�`�F�b�NOK
/* 2009/12/28 Ver1.9 Add End   */
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
    --�󒍓�(FROM)�K�{�`�F�b�N
    IF ( ( iv_ordered_date_from IS NULL ) AND ( iv_ordered_date_to IS NOT NULL ) ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_order_date_from
      );
      RAISE global_format_chk_expt;
    END IF;
    --�󒍓�(TO)�K�{�`�F�b�N
    IF ( ( iv_ordered_date_from IS NOT NULL ) AND ( iv_ordered_date_to IS NULL ) ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_order_date_to
      );
      RAISE global_format_chk_expt;
    END IF;
--
    --�󒍓�(FROM)�A�󒍓�(TO)�������͂��ꂽ�ꍇ
    IF ( ( iv_ordered_date_from IS NOT NULL ) AND ( iv_ordered_date_to IS NOT NULL ) ) THEN
      --�󒍓�(FROM)�����`�F�b�N
      ld_ordered_date_from := FND_DATE.STRING_TO_DATE( iv_ordered_date_from, cv_yyyy_mm_dd );
      IF ( ld_ordered_date_from IS NULL ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_date_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --�󒍓�(TO)�����`�F�b�N
      ld_ordered_date_to := FND_DATE.STRING_TO_DATE( iv_ordered_date_to, cv_yyyy_mm_dd );
      IF ( ld_ordered_date_to IS NULL ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_date_to
        );
        RAISE global_format_chk_expt;
      END IF;
--
      --�󒍓�(FROM)�^-�󒍓�(TO)���t�t�]�`�F�b�N
      IF ( ld_ordered_date_from > ld_ordered_date_to ) THEN
        RAISE global_date_rever_o_chk_expt;
      END IF;
    END IF;
--
    --�o�ח\���(FROM)�K�{�`�F�b�N
    IF ( ( iv_schedule_ship_date_from IS NULL ) AND ( iv_schedule_ship_date_to IS NOT NULL ) ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_s_ship_date_from
      );
      RAISE global_format_chk_expt;
    END IF;
    --�o�ח\���(TO)�K�{�`�F�b�N
    IF ( ( iv_schedule_ship_date_from IS NOT NULL ) AND ( iv_schedule_ship_date_to IS NULL ) ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_s_ship_date_to
      );
      RAISE global_format_chk_expt;
    END IF;
--
    --�o�ח\���(FROM)�A�o�ח\���(TO)�������͂��ꂽ�ꍇ
    IF ( ( iv_schedule_ship_date_from IS NOT NULL ) AND ( iv_schedule_ship_date_to IS NOT NULL ) ) THEN
      --�o�ח\���(FROM)�����`�F�b�N
      ld_schedule_ship_date_from := FND_DATE.STRING_TO_DATE( iv_schedule_ship_date_from, cv_yyyy_mm_dd );
      IF ( ld_schedule_ship_date_from IS NULL ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_s_ship_date_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --�o�ח\���(TO)�����`�F�b�N
      ld_schedule_ship_date_to := FND_DATE.STRING_TO_DATE( iv_schedule_ship_date_to, cv_yyyy_mm_dd );
      IF ( ld_schedule_ship_date_to IS NULL ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_s_ship_date_to
        );
        RAISE global_format_chk_expt;
      END IF;
--
      --�o�ח\���(FROM)�^--�o�ח\���(TO)���t�t�]�`�F�b�N
      IF ( ld_schedule_ship_date_from > ld_schedule_ship_date_to ) THEN
        RAISE global_date_rever_ss_chk_expt;
      END IF;
    END IF;
--
    --�[�i�\���(FROM)�K�{�`�F�b�N
    IF ( ( iv_schedule_ordered_date_from IS NULL ) AND ( iv_schedule_ordered_date_to IS NOT NULL ) ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_s_order_date_from
      );
      RAISE global_format_chk_expt;
    END IF;
    --�[�i�\���(TO)�K�{�`�F�b�N
    IF ( ( iv_schedule_ordered_date_from IS NOT NULL ) AND ( iv_schedule_ordered_date_to IS NULL ) ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_s_order_date_to
      );
      RAISE global_format_chk_expt;
    END IF;
--
    --�[�i�\���(FROM)�A�[�i�\���(TO)�������͂��ꂽ�ꍇ
    IF ( ( iv_schedule_ordered_date_from IS NOT NULL ) AND ( iv_schedule_ordered_date_to IS NOT NULL ) ) THEN
      --�[�i�\���(FROM)�����`�F�b�N
      ld_schedule_ordered_date_from := FND_DATE.STRING_TO_DATE( iv_schedule_ordered_date_from, cv_yyyy_mm_dd );
      IF ( ld_schedule_ordered_date_from IS NULL ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_s_order_date_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --�[�i�\���(TO)�����`�F�b�N
      ld_schedule_ordered_date_to := FND_DATE.STRING_TO_DATE( iv_schedule_ordered_date_to, cv_yyyy_mm_dd );
      IF ( ld_schedule_ordered_date_to IS NULL ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_s_order_date_to
        );
        RAISE global_format_chk_expt;
      END IF;
--
      --�[�i�\���(FROM)�^--�[�i�\���(TO)���t�t�]�`�F�b�N
      IF ( ld_schedule_ordered_date_from > ld_schedule_ordered_date_to ) THEN
        RAISE global_date_rever_so_chk_expt;
      END IF;
    END IF;
/* 2009/12/28 Ver1.9 Add Start */
    --EDI���[�ďo�͎��̓��t�`�F�b�N
    IF ( iv_order_source = gv_order_source_edi_chk ) AND ( iv_output_type <> gt_report_output_type_n ) THEN
--
      --��M���A�[�i���̂��Â�̓��̓`�F�b�N
      IF ( iv_order_creation_date_from IS NULL ) AND ( iv_order_creation_date_to IS NULL )
        AND ( iv_ordered_date_h_from IS NULL ) AND ( iv_ordered_date_h_to IS NULL )
      THEN
        RAISE global_edi_date_chk_expt;
      END IF;
--
      --��M��(FROM)�K�{�`�F�b�N
      IF ( ( iv_order_creation_date_from IS NULL ) AND ( iv_order_creation_date_to IS NOT NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_c_date_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --��M��(TO)�K�{�`�F�b�N
      IF ( ( iv_order_creation_date_from IS NOT NULL ) AND ( iv_order_creation_date_to IS NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_c_date_to
        );
        RAISE global_format_chk_expt;
      END IF;
--
      --��M��(FROM)�A��M��(TO)�������͂��ꂽ�ꍇ
      IF ( ( iv_order_creation_date_from IS NOT NULL ) AND ( iv_order_creation_date_to IS NOT NULL ) ) THEN
        --��M��(FROM)�����`�F�b�N
        ld_order_creation_date_from := FND_DATE.STRING_TO_DATE( iv_order_creation_date_from, cv_yyyy_mm_dd );
        IF ( ld_order_creation_date_from IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_c_date_from
          );
          RAISE global_format_chk_expt;
        END IF;
        --��M��(TO)�����`�F�b�N
        ld_order_creation_date_to := FND_DATE.STRING_TO_DATE( iv_order_creation_date_to, cv_yyyy_mm_dd );
        IF ( ld_order_creation_date_to IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_c_date_to
          );
          RAISE global_format_chk_expt;
        END IF;
--
        --��M��(FROM)�^--��M��(TO)���t�t�]�`�F�b�N
        IF ( ld_order_creation_date_from > ld_order_creation_date_to ) THEN
          RAISE global_date_rever_ocd_chk_expt;
        END IF;
      END IF;
--
      --�[�i��(FROM)�K�{�`�F�b�N
      IF ( ( iv_ordered_date_h_from IS NULL ) AND ( iv_ordered_date_h_to IS NOT NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_date_h_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --�[�i��(TO)�K�{�`�F�b�N
      IF ( ( iv_ordered_date_h_from IS NOT NULL ) AND ( iv_ordered_date_h_to IS NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_date_h_to
        );
        RAISE global_format_chk_expt;
      END IF;
--
      --�[�i��(FROM)�A�[�i��(TO)�������͂��ꂽ�ꍇ
      IF ( ( iv_ordered_date_h_from IS NOT NULL ) AND ( iv_ordered_date_h_to IS NOT NULL ) ) THEN
        --�[�i��(FROM)�����`�F�b�N
        ld_ordered_date_h_from := FND_DATE.STRING_TO_DATE( iv_ordered_date_h_from, cv_yyyy_mm_dd );
        IF ( ld_ordered_date_h_from IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_date_h_from
          );
          RAISE global_format_chk_expt;
        END IF;
        --�[�i��(TO)�����`�F�b�N
        ld_ordered_date_h_to := FND_DATE.STRING_TO_DATE( iv_ordered_date_h_to, cv_yyyy_mm_dd );
        IF ( ld_ordered_date_h_to IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_date_h_to
          );
          RAISE global_format_chk_expt;
        END IF;
--
        --�[�i��(FROM)�^--�[�i��(TO)���t�t�]�`�F�b�N
        IF ( ld_ordered_date_h_from > ld_ordered_date_h_to ) THEN
          RAISE global_date_rever_odh_chk_expt;
        END IF;
      END IF;
--
    END IF;
/* 2009/12/28 Ver1.9 Add End   */
--
--
    --�`�F�b�NOK
    od_ordered_date_from          := ld_ordered_date_from;
    od_ordered_date_to            := ld_ordered_date_to;
    od_schedule_ship_date_from    := ld_schedule_ship_date_from;
    od_schedule_ship_date_to      := ld_schedule_ship_date_to;
    od_schedule_ordered_date_from := ld_schedule_ordered_date_from;
    od_schedule_ordered_date_to   := ld_schedule_ordered_date_to;
/* 2009/12/28 Ver1.9 Add Start */
    od_order_creation_date_from   := ld_order_creation_date_from;
    od_order_creation_date_to     := ld_order_creation_date_to;
    od_ordered_date_h_from        := ld_ordered_date_h_from;
    od_ordered_date_h_to          := ld_ordered_date_h_to;
/* 2009/12/28 Ver1.9 Add End   */
--
  EXCEPTION
    -- *** �����`�F�b�N��O�n���h�� ***
    WHEN global_format_chk_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_format_check_err,
        iv_token_name1        =>  cv_tkn_nm_para_date,
        iv_token_value1       =>  lv_check_item
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- ***�󒍓� ���t�t�]�`�F�b�N��O�n���h�� ***
    WHEN global_date_rever_o_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_date_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_date_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- ***�o�ח\��� ���t�t�]�`�F�b�N��O�n���h�� ***
    WHEN global_date_rever_ss_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_s_ship_date_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_s_ship_date_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- ***�[�i�\��� ���t�t�]�`�F�b�N��O�n���h�� ***
    WHEN global_date_rever_so_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_s_order_date_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_s_order_date_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
/* 2009/12/28 Ver1.9 Add Start */
    -- ***EDI���[���t�w��Ȃ���O�n���h�� ***
    WHEN global_edi_date_chk_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_edi_date_err
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- ***��M�� ���t�t�]�`�F�b�N��O�n���h�� ***
    WHEN global_date_rever_ocd_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_c_date_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_c_date_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- ***�[�i�� ���t�t�]�`�F�b�N��O�n���h�� ***
    WHEN global_date_rever_odh_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_date_h_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_date_h_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
/* 2009/12/28 Ver1.9 Add End  */
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : �����Ώۃf�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_order_source                 IN     VARCHAR2,     --   �󒍃\�[�X
    iv_delivery_base_code           IN     VARCHAR2,     --   �[�i���_�R�[�h
    ld_ordered_date_from            IN     DATE,         --   �󒍓�(FROM)
    ld_ordered_date_to              IN     DATE,         --   �󒍓�(TO)
    ld_schedule_ship_date_from      IN     DATE,         --   �o�ח\���(FROM)
    ld_schedule_ship_date_to        IN     DATE,         --   �o�ח\���(TO)
    ld_schedule_ordered_date_from   IN     DATE,         --   �[�i�\���(FROM)
    ld_schedule_ordered_date_to     IN     DATE,         --   �[�i�\���(TO)
    iv_entered_by_code              IN     VARCHAR2,     --   ���͎҃R�[�h
    iv_ship_to_code                 IN     VARCHAR2,     --   �o�א�R�[�h
    iv_subinventory                 IN     VARCHAR2,     --   �ۊǏꏊ
    iv_order_number                 IN     VARCHAR2,     --   �󒍔ԍ�
/* 2009/12/28 Ver1.9 Add Start */
    iv_output_type                  IN     VARCHAR2,     --   �o�͋敪
    iv_chain_code                   IN     VARCHAR2,     --   �`�F�[���X�R�[�h
    id_order_creation_date_from     IN     DATE,         --   ��M��(FROM)
    id_order_creation_date_to       IN     DATE,         --   ��M��(TO)
    id_ordered_date_h_from          IN     DATE,         --   �[�i��(�w�b�_)(FROM)
    id_ordered_date_h_to            IN     DATE,         --   �[�i��(�w�b�_)(TO)
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
    iv_order_status                 IN     VARCHAR2,     --   �󒍃X�e�[�^�X
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
    iv_output_quantity_type         IN     VARCHAR2,     --   �o�͐��ʋ敪
/* 2012/01/30 Ver1.14 Add End   */
    ov_errbuf                       OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
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
    lv_tkn_vl_table_name      VARCHAR2(100);                          --�e�[�u������(����)
    ln_idx                    NUMBER;                                 --���C�����[�v�J�E���g
    lt_record_id              xxcos_rep_order_list.record_id%TYPE;    --���R�[�hID
--
    -- *** ���[�J���E�J�[�\�� ***
--****************************** 2009/07/29 1.7 T.Tominaga MOD START ******************************--
--    CURSOR data_edi_or_not_cur
    -- �󒍃\�[�X�^�C�v�FEDI�捞�̏ꍇ
    CURSOR data_edi_cur
--****************************** 2009/07/29 1.7 T.Tominaga MOD END   ******************************--
    IS
      SELECT
/* 2009/12/28 Ver1.9 Add Start */
        /*+
-- 2012/04/18 Ver1.15 Mod Start
--            LEADING(xca)
--            USE_NL(xca xca_c hca hca_c ooha oos jrs jrre papf1)
            LEADING(xca hca hp xca_c hca_c hp_c xeh ooha oos jrs jrre papf1 ppt1 fu papf ppt)
            USE_NL(xca hca hp xca_c hca_c hp_c xeh ooha oos jrs jrre papf1 ppt1 fu papf ppt)
-- 2012/04/18 Ver1.15 Mod End
        */
/* 2009/12/28 Ver1.9 Add End   */
        oola.rowid                             AS row_id                     -- rowid
        ,ooha.order_source_id                  AS order_source_id            -- �󒍃\�[�X
        ,oos.name                              AS order_source               -- �󒍃\�[�X
        ,papf.employee_number                  AS entered_by_code            -- ���͎҃R�[�h
        ,papf.per_information18 || ' ' || papf.per_information19
                                               AS entered_by_name            -- ���͎Җ�
--****************************** 2009/05/08 1.4 T.Kitajima MOD START ******************************--
--        ,oola.ship_to_org_id                   AS deliver_from_code          -- �o�א�R�[�h
        ,hca.account_number                   AS deliver_from_code           -- �o�א�R�[�h
--****************************** 2009/05/08 1.4 T.Kitajima MOD START ******************************--
        ,hp.party_name                         AS deliver_to_name            -- �ڋq����
        ,ooha.order_number                     AS order_number               -- �󒍔ԍ�
        ,oola.line_number                      AS line_number                -- ���הԍ�
-- 2009/04/14 Mod Start
--        ,oola.cust_po_number                   AS party_order_number         -- �ڋq�����ԍ�
        ,ooha.cust_po_number                   AS party_order_number         -- �ڋq�����ԍ�
-- 2009/04/14 Mod End
        ,oola.schedule_ship_date               AS shipped_date               -- �o�ד�
        ,oola.request_date                     AS dlv_date                   -- �[�i��
        ,oola.ordered_item                     AS order_item_no              -- �󒍕i�ԍ�
        ,ximb.item_short_name                  AS order_item_name            -- �󒍕i�ږ�
        ,otta.order_category_code              AS order_category_code        -- �J�e�S��
/* 2010/03/08 Ver1.10 Add Start */
--        ,oola.ordered_quantity                 AS quantity                   -- ����
/* 2012/01/30 Ver1.14 Mod Start */
--        ,NVL( ( SELECT xel.sum_order_qty
--                FROM   xxcos_edi_lines        xel
--                WHERE  xel.edi_header_info_id = xeh.edi_header_info_id
--                AND    xel.order_connection_line_number
--                                              = oola.orig_sys_line_ref )
--             , oola.ordered_quantity )         AS quantity                   -- ����
        ,CASE
           --�o�͐��ʋ敪��"1"(EDI�̐���)�̏ꍇ
           WHEN iv_output_quantity_type = cv_edi_quantity_type THEN
             NVL( ( SELECT xel.sum_order_qty
                    FROM   xxcos_edi_lines        xel
                    WHERE  xel.edi_header_info_id = xeh.edi_header_info_id
                    AND    xel.order_connection_line_number
                                              = oola.orig_sys_line_ref )
               , oola.ordered_quantity )
           --�o�͐��ʋ敪��"2"(�󒍉�ʂ̐���)�̏ꍇ
           WHEN iv_output_quantity_type = cv_oe_quantity_type  THEN
             oola.ordered_quantity
         END                                   AS quantity                   -- ����
/* 2012/01/30 Ver1.14 Mod End   */
/* 2010/03/08 Ver1.10 Add End   */
        ,oola.order_quantity_uom               AS uom_code                   -- �󒍒P��
        ,oola.unit_selling_price               AS dlv_unit_price             -- �̔��P��
        ,oola.subinventory                     AS locat_code                 -- �ۊǏꏊ�R�[�h
        ,msi.description                       AS locat_name                 -- �ۊǏꏊ����
        ,ooha.shipping_instructions            AS shipping_instructions      -- �o�׎w��
        ,ooha.attribute19                      AS order_no                   -- �I�[�_�[No.
        ,jrre.source_number                    AS base_employee_num          -- �c�ƒS���R�[�h
        ,papf1.per_information18 || ' ' || papf1.per_information19
                                               AS base_employee_name         -- �c�ƒS����
/* 2009/12/28 Ver1.9 Add Start */
        ,ooha.attribute5                       AS invoice_class              -- �`�[�敪
        ,ooha.attribute20                      AS classification_class       -- ���ދ敪
        ,iv_output_type                        AS report_output_type         -- �o�͋敪
        ,DECODE( iv_output_type
                ,gt_report_output_type_n, NULL
                ,cv_re_output_flag
         )                                     AS edi_re_output_flag         -- EDI�ďo�̓t���O
        ,xca.chain_store_code                  AS chain_code                 -- �`�F�[���X�R�[�h
        ,hp_c.party_name                       AS chain_name                 -- �`�F�[���X����
        ,id_order_creation_date_from           AS order_creation_date_from   -- ��M��(FROM)(�p�����[�^)
        ,id_order_creation_date_to             AS order_creation_date_to     -- ��M��(TO)(�p�����[�^)
        ,id_ordered_date_h_from                AS dlv_date_header_from       -- �[�i��(FROM)(�p�����[�^)
        ,id_ordered_date_h_to                  AS dlv_date_header_to         -- �[�i��(TO)(�p�����[�^)
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/01/22 Ver1.9 Add Start E_�{�ғ�_00408�Ή� */
        ,ooha.request_date                     AS dlv_date_header            --�[�i��(�w�b�_)
/* 2010/01/22 Ver1.9 Add End   E_�{�ғ�_00408�Ή� */
      FROM
        oe_order_headers_all       ooha    -- �󒍃w�b�_
        ,oe_order_lines_all        oola    -- �󒍖���
        ,oe_order_sources          oos     -- �󒍃\�[�X
        ,hz_cust_accounts          hca     -- �ڋq�}�X�^
        ,xxcmm_cust_accounts       xca     -- �ڋq�A�h�I��
        ,hz_parties                hp      -- �p�[�e�B�}�X�^
        ,mtl_secondary_inventories msi     -- �ۊǏꏊ�}�X�^
        ,mtl_system_items_b        msib    -- DISC�i��
        ,ic_item_mst_b             iimb    -- OPM�i��
        --,xxcmm_system_items_b      xsib    -- DISC�i�ڃA�h�I��
        ,xxcmn_item_mst_b          ximb    -- OPM�i�ڃA�h�I��
        ,fnd_user                  fu      -- ���[�U�}�X�^
        ,per_all_people_f          papf    -- �]�ƈ��}�X�^
        ,per_person_types          ppt     -- �]�ƈ��^�C�v�}�X�^
        ,jtf_rs_resource_extns     jrre    -- ���\�[�X�}�X�^
        ,jtf_rs_salesreps          jrs     -- jtf_rs_salesreps
        ,per_all_people_f          papf1   -- �]�ƈ��}�X�^1
        ,per_person_types          ppt1    -- �]�ƈ��^�C�v�}�X�^1
        ,oe_transaction_types_all  otta    -- �󒍖��דE�v�p����^�C�vALL
        ,oe_transaction_types_tl   otttl   -- �󒍖��דE�v�p����^�C�v
/* 2009/12/28 Ver1.8 Add Start */
        ,hz_cust_accounts          hca_c   -- �ڋq�}�X�^(�`�F�[���X)
        ,xxcmm_cust_accounts       xca_c   -- �ڋq�A�h�I��(�`�F�[���X)
        ,hz_parties                hp_c    -- �p�[�e�B�}�X�^(�`�F�[���X)
/* 2009/12/28 Ver1.8 Add End   */
/* 2010/03/08 Ver1.10 Add Start */
        ,xxcos_edi_headers         xeh     -- EDI�w�b�_���
/* 2010/03/08 Ver1.10 Add End   */
      WHERE
      -- �󒍃w�b�_.�󒍃w�b�_ID���󒍖���.�󒍃w�b�_ID
      ooha.header_id                        = oola.header_id
      -- �g�DID
      AND ooha.org_id                       = gn_org_id
      -- �󒍃w�b�_.�\�[�XID���󒍃\�[�X.�\�[�XID
      AND ooha.order_source_id              = oos.order_source_id
      -- �󒍃\�[�X���́iEDI�󒍁A�≮CSV�A����CSV�AOnline�j
      AND oos.name IN ( 
        SELECT  look_val.attribute1
-- ******** 2009/10/02 1.8 N.Maeda MOD START ******** --
        FROM    fnd_lookup_values           look_val
        WHERE   look_val.language           = cv_lang
        AND     look_val.lookup_type        = cv_type_ost_009_a01
        AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
        AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
        AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
        AND     look_val.enabled_flag       = ct_enabled_flg_y
        --�󒍃\�[�X�iEDI�捞�ECSV�捞�E�N�C�b�N�󒍓��́j
        AND     look_val.description        = iv_order_source
--
--        FROM    fnd_lookup_values           look_val,
--                fnd_lookup_types_tl         types_tl,
--                fnd_lookup_types            types,
--                fnd_application_tl          appl,
--                fnd_application             app
--        WHERE   appl.application_id         = types.application_id
--        AND     app.application_id          = appl.application_id
--        AND     types_tl.lookup_type        = look_val.lookup_type
--        AND     types.lookup_type           = types_tl.lookup_type
--        AND     types.security_group_id     = types_tl.security_group_id
--        AND     types.view_application_id   = types_tl.view_application_id
--        AND     types_tl.language           = cv_lang
--        AND     look_val.language           = cv_lang
--        AND     appl.language               = cv_lang
--        AND     app.application_short_name  = cv_xxcos_short_name
--        AND     look_val.lookup_type        = cv_type_ost_009_a01
--        AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
--        AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--        AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--        AND     look_val.enabled_flag       = ct_enabled_flg_y
--        --�󒍃\�[�X�iEDI�捞�ECSV�捞�E�N�C�b�N�󒍓��́j
--        AND     look_val.description        = iv_order_source
-- ******** 2009/10/02 1.8 N.Maeda MOD END  ******** --
      )
      --�󒍃w�b�_.�ڋqID = �ڋq�}�X�^.�ڋqID
      AND ooha.sold_to_org_id               = hca.cust_account_id
      --�ڋq�}�X�^.�ڋqID =�ڋq�}�X�^�A�h�I��.�ڋqID
      AND hca.cust_account_id               = xca.customer_id
      --�ڋq�}�X�^�A�h�I��.�[�i���_�R�[�h=�p�����[�^.���_�R�[�h
      AND xca.delivery_base_code            = iv_delivery_base_code
      --�ڋq�}�X�^.�p�[�e�BID = �p�[�e�B�}�X�^.�p�[�e�BID
      AND hca.party_id                      = hp.party_id 
      --���[�U�}�X�^.���[�UID=�󒍃w�b�_.�ŏI�X�V��
      AND fu.user_id                        = ooha.last_updated_by
      --���[�U�}�X�^.�]�ƈ�ID=�]�ƈ��}�X�^.�]�ƈ�ID
      AND fu.employee_id                    = papf.person_id
      AND gd_proc_date                      >= NVL( papf.effective_start_date, gd_min_date )
      AND gd_proc_date                      <= NVL( papf.effective_end_date, gd_max_date )
      AND ppt.business_group_id             = cn_per_business_group_id
      AND ppt.system_person_type            = cv_emp
      AND ppt.active_flag                   = ct_enabled_flg_y
      AND papf.person_type_id               = ppt.person_type_id
      --�󒍃w�b�_.�c�ƒS��ID=jtf_rs_salesreps.salesrep_id
      AND ooha.salesrep_id                  = jrs.salesrep_id
      --jtf_rs_salesreps.���\�[�XID=���\�[�X�}�X�^.���\�[�XID
      AND jrs.resource_id                   = jrre.resource_id
      --���\�[�X�}�X�^.�\�[�X�ԍ�=�]�ƈ��}�X�^.�]�ƈ�ID
      AND jrre.source_id                    = papf1.person_id
      AND gd_proc_date                      >= NVL( papf1.effective_start_date, gd_min_date )
      AND gd_proc_date                      <= NVL( papf1.effective_end_date, gd_max_date )
      AND ppt1.business_group_id            = cn_per_business_group_id
      AND ppt1.system_person_type           = cv_emp
      AND ppt1.active_flag                  = ct_enabled_flg_y
      AND papf1.person_type_id              = ppt1.person_type_id
      -- �󒍖���.�ۊǏꏊ=�ۊǏꏊ�}�X�^.�ۊǏꏊ�R�[�h
      AND oola.subinventory                 = msi.secondary_inventory_name(+)
      -- �󒍖���.�o�׌��g�DID = �ۊǏꏊ�}�X�^.�g�DID
      AND oola.ship_from_org_id             = msi.organization_id(+)
      --�󒍖���.�i��ID= �i�ڃ}�X�^.�i��ID
      AND oola.inventory_item_id            = msib.inventory_item_id
      AND msib.organization_id              = gt_org_id
      AND msib.segment1                     = iimb.item_no
      AND iimb.item_id                      = ximb.item_id
      --AND msib.segment1                   = xsib.item_code
      --AND iimb.item_id                    = xsib.item_id
      AND gd_proc_date                      >= NVL( ximb.start_date_active, gd_min_date )
      AND gd_proc_date                      <= NVL( ximb.end_date_active, gd_max_date )
      --�󒍖���.���׃^�C�v���󒍃^�C�v.�^�C�v
      AND oola.line_type_id                 = otttl.transaction_type_id
      --�󒍃^�C�v.�^�C�v���󒍃^�C�vALL.�^�C�v
      AND otttl.transaction_type_id         = otta.transaction_type_id
      --����FJA
      AND otttl.language                    = cv_lang
/* 2009/12/28 Ver1.9 Add Start */
      -- �󒍖���.�󒍓��̔N�����Ɩ����t�|�P�̔N��
      AND TO_CHAR( TRUNC( NVL( ooha.ordered_date, gd_proc_date ) ), cv_yyyy_mm ) 
        >= TO_CHAR( ADD_MONTHS( TRUNC( gd_proc_date ), -1 ), cv_yyyy_mm )
/* 2012/09/13 1.16 Del Start */
--      -- �󒍖���.�X�e�[�^�X�����
--      AND oola.flow_status_code NOT IN ( ct_ln_status_cancelled )
/* 2012/09/13 1.16 Del End */
      --�ڋq�}�X�^�A�h�I��.�`�F�[���X�R�[�h���ڋq�}�X�^�A�h�I��(�`�F�[���X).�`�F�[���X�R�[�h(EDI)�y�e���R�[�h�p�z
      AND xca.chain_store_code              = xca_c.edi_chain_code
      --�ڋq�}�X�^�A�h�I��(�`�F�[���X).�ڋqID���ڋq�}�X�^(�`�F�[���X).�ڋqID
      AND xca_c.customer_id                 = hca_c.cust_account_id
      --�ڋq�}�X�^(�`�F�[���X).�p�[�e�BID���p�[�e�B�}�X�^(�`�F�[���X).�p�[�e�BID
      AND hca_c.party_id                    = hp_c.party_id
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/03/08 Ver1.10 Add Start */
      --EDI�w�b�_.�󒍊֘A�ԍ����󒍃w�b�_.�O���V�X�e���󒍔ԍ�
      AND xeh.order_connection_number       = ooha.orig_sys_document_ref
/* 2010/03/08 Ver1.10 Add End   */
-- 2012/04/18 Ver1.15 Add Start
      AND xeh.conv_customer_code            = hca.account_number
-- 2012/04/18 Ver1.15 Add End
      AND ( 
/* 2009/12/28 Ver1.9 Mod Start */
--        --EDI�捞�̏ꍇ
--        ( iv_order_source                   = gv_order_source_edi_chk
--          --�󒍈ꗗ�o�͓� IS NULL
--          AND oola.global_attribute1 IS NULL
--          -- �󒍖���.�󒍓��̔N�����Ɩ����t�|�P�̔N��
--          AND TO_CHAR( TRUNC( NVL( ooha.ordered_date, gd_proc_date ) ), cv_yyyy_mm ) 
--            >= TO_CHAR( ADD_MONTHS( TRUNC( gd_proc_date ), -1 ), cv_yyyy_mm )
--          -- �󒍖���.�X�e�[�^�X�����
--          AND oola.flow_status_code NOT IN ( ct_ln_status_cancelled )
        --�V�K�o�͂̏ꍇ
        ( iv_output_type = gt_report_output_type_n
          --�󒍈ꗗ�o�͓� IS NULL
          AND oola.global_attribute1 IS NULL
/* 2009/12/28 Ver1.9 Mod End */
        )
/* 2009/12/28 Ver1.9 Add  Start */
        OR
        --�ďo�͂̏ꍇ
        ( iv_output_type <> gt_report_output_type_n
          --�󒍈ꗗ�o�͓� IS NOT NULL
          AND oola.global_attribute1 IS NOT NULL
          --�ڋq�}�X�^.�`�F�[���X�R�[�h���p�����[�^.�`�F�[���X�R�[�h
          AND (  iv_chain_code IS NULL
              OR xca.chain_store_code = iv_chain_code
              )
          AND (
            --�p�����[�^��M����NLLL
            (
              id_order_creation_date_from IS NULL
              AND id_order_creation_date_to IS NULL
            )
            --�p�����[�^��M���ɐݒ肠��
            OR (
              --�󒍃w�b�_.�쐬�����p�����[�^.��M���iFROM�j
              TRUNC( ooha.creation_date )     >= 
                  TRUNC( id_order_creation_date_from )
              --�󒍃w�b�_.�쐬�����p�����[�^.��M���iTO�j
              AND TRUNC( ooha.creation_date ) <= TRUNC( id_order_creation_date_to )
            )
          )
          AND (
            --�p�����[�^�[�i����NLLL
            (
              id_ordered_date_h_from IS NULL
              AND id_ordered_date_h_to IS NULL
            )
            --�p�����[�^�[�i���ɐݒ肠��
            OR (
              --�󒍃w�b�_.�[�i�\������p�����[�^.�[�i���iFROM�j
              TRUNC( ooha.request_date )     >= 
                  TRUNC( id_ordered_date_h_from )
              --�󒍃w�b�_.�[�i���\������p�����[�^.�[�i���iTO�j
              AND TRUNC( ooha.request_date ) <= TRUNC( id_ordered_date_h_to )
            )
          )
        )
/* 2009/12/28 Ver1.9 Add  End   */
--****************************** 2009/07/29 1.7 T.Tominaga DEL START ******************************--
--        --CSV/���̑��̏ꍇ
--        OR ( 
--          iv_order_source <> gv_order_source_edi_chk 
--          -- �󒍖���.�X�e�[�^�X���۰��or���
--          AND oola.flow_status_code NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )
--          AND (
--            --�󒍃w�b�_�ƃp�����[�^�̎󒍓�����NULL�̏ꍇ �ޔ�����
--            ooha.ordered_date IS NULL
--            AND ld_ordered_date_from IS NULL
--            AND ld_ordered_date_to IS NULL
--            OR (
--              --�󒍃w�b�_.�󒍓����p�����[�^.�󒍓��iFROM�j
--              TRUNC( ooha.ordered_date )           >= NVL( ld_ordered_date_from, TRUNC( ooha.ordered_date ) )
--              --�󒍃w�b�_.�󒍓����p�����[�^.�󒍓��iTO�j
--              AND TRUNC( ooha.ordered_date )       <= NVL( ld_ordered_date_to, TRUNC( ooha.ordered_date ) )
--            )
--          )
--          AND (
--            --�󒍖��ׂƃp�����[�^�̗\��o�ד�����NULL�̏ꍇ �ޔ�����
--            oola.schedule_ship_date IS NULL
--            AND ld_schedule_ship_date_from IS NULL
--            AND ld_schedule_ship_date_to IS NULL
--            OR (
--              --�󒍖���.�\��o�ד����p�����[�^.�o�ח\����iFROM�j
--              TRUNC( oola.schedule_ship_date )     >= 
--                  NVL( ld_schedule_ship_date_from, TRUNC( oola.schedule_ship_date ) )
--              --�󒍖���.�\��o�ד����p�����[�^.�o�ח\����iTO�j
--              AND TRUNC( oola.schedule_ship_date ) <= NVL( ld_schedule_ship_date_to, TRUNC( oola.schedule_ship_date ) )
--            )
--          )
--          AND (
--            --�󒍖��ׂƃp�����[�^�̗v��������NULL�̏ꍇ �ޔ�����
--            oola.request_date IS NULL
--            AND ld_schedule_ordered_date_from IS NULL
--            AND ld_schedule_ordered_date_to IS NULL
--            OR (
--              --�󒍖���.�v�������p�����[�^.�[�i�\����iFROM�j
--              TRUNC( oola.request_date )           >= NVL( ld_schedule_ordered_date_from, TRUNC( oola.request_date ) )
--              --�󒍖���.�v�������p�����[�^.�[�i�\����iTO�j
--              AND TRUNC( oola.request_date )       <= NVL( ld_schedule_ordered_date_to, TRUNC( oola.request_date ) )
--            )
--          )
--          --�]�ƈ��}�X�^.�]�ƈ��ԍ����p�����[�^.���͎�
--          AND papf.employee_number             = NVL( iv_entered_by_code, papf.employee_number )
--          --�ڋq�}�X�^.�ڋq�R�[�h���p�����[�^.�o�א�
--          AND hca.account_number               = NVL( iv_ship_to_code, hca.account_number )
--          AND (
--            --�󒍖��ׂƃp�����[�^�̕ۊǏꏊ����NULL�̏ꍇ �ޔ�����
--            oola.subinventory IS NULL
--            AND iv_subinventory IS NULL
--            OR (
--              --�󒍖���.�ۊǏꏊ���p�����[�^.�ۊǏꏊ
--              oola.subinventory                = NVL( iv_subinventory, oola.subinventory )
--            )
--          )
--          --�󒍃w�b�_.�󒍔ԍ�=�p�����[�^.�󒍔ԍ�
--          AND ooha.order_number                = NVL( iv_order_number, ooha.order_number )
--        )
--****************************** 2009/07/29 1.7 T.Tominaga DEL END   ******************************--
      )
/* 2009/07/13 Ver1.6 Add Start */
      --���敪 = NULL OR 01
      AND (
            ooha.global_attribute3 IS NULL
          OR
            ooha.global_attribute3 = cv_target_order_01
          )
/* 2009/07/13 Ver1.6 Add End   */
/* 2011/04/20 Ver1.13 Add Start */
      --�󒍖���ID��NULL
      AND oola.global_attribute3 IS NULL
/* 2011/04/20 Ver1.13 Add End   */
      ORDER BY
/* 2009/12/28 Ver1.9 Mod Start */
--        ooha.header_id     --�󒍃w�b�_.�w�b�_ID
--        ,oola.line_id      --�󒍖���.����ID
        xca.chain_store_code  --�`�F�[���X�R�[�h
        ,xca.store_code       --�X�܃R�[�h
        ,ooha.request_date    --�[�i��(�w�b�_)
/* 2010/01/22 Ver1.9 Add Start E_�{�ғ�_00408�Ή� */
        ,ooha.cust_po_number  --�ڋq�����ԍ�
/* 2010/01/22 Ver1.9 Add End   E_�{�ғ�_00408�Ή� */
        ,ooha.order_number    --�󒍔ԍ�
        ,oola.line_number     --�󒍖��הԍ�
/* 2009/12/28 Ver1.9 Mod End   */
      FOR UPDATE OF
        ooha.header_id     --�󒍃w�b�_.�w�b�_ID
        ,oola.line_id      --�󒍖���.����ID
      NOWAIT
      ;
--
--****************************** 2009/07/29 1.7 T.Tominaga ADD START ******************************--
    -- �󒍃\�[�X�^�C�v�F���̑��iCSV/��ʁj�̏ꍇ
    CURSOR data_edi_not_cur
    IS
      SELECT
/* 2010/03/29 Ver1.11 Add Start */
        /*+
           LEADING(xca)
           USE_NL(xca hca ooha oos jrs jrre papf1)
-- 2010/04/01 Ver1.12 Add Start
           INDEX(ooha oe_order_headers_n2)
-- 2010/04/01 Ver1.12 Add End
         */
/* 2010/03/29 Ver1.11 Add End   */
        oola.rowid                             AS row_id                     -- rowid
        ,ooha.order_source_id                  AS order_source_id            -- �󒍃\�[�X
        ,oos.name                              AS order_source               -- �󒍃\�[�X
        ,papf.employee_number                  AS entered_by_code            -- ���͎҃R�[�h
        ,papf.per_information18 || ' ' || papf.per_information19
                                               AS entered_by_name            -- ���͎Җ�
        ,hca.account_number                    AS deliver_from_code          -- �o�א�R�[�h
        ,hp.party_name                         AS deliver_to_name            -- �ڋq����
        ,ooha.order_number                     AS order_number               -- �󒍔ԍ�
        ,oola.line_number                      AS line_number                -- ���הԍ�
        ,ooha.cust_po_number                   AS party_order_number         -- �ڋq�����ԍ�
        ,oola.schedule_ship_date               AS shipped_date               -- �o�ד�
        ,oola.request_date                     AS dlv_date                   -- �[�i��
        ,oola.ordered_item                     AS order_item_no              -- �󒍕i�ԍ�
        ,ximb.item_short_name                  AS order_item_name            -- �󒍕i�ږ�
        ,otta.order_category_code              AS order_category_code        -- �J�e�S��
        ,oola.ordered_quantity                 AS quantity                   -- ����
        ,oola.order_quantity_uom               AS uom_code                   -- �󒍒P��
        ,oola.unit_selling_price               AS dlv_unit_price             -- �̔��P��
        ,oola.subinventory                     AS locat_code                 -- �ۊǏꏊ�R�[�h
        ,msi.description                       AS locat_name                 -- �ۊǏꏊ����
        ,ooha.shipping_instructions            AS shipping_instructions      -- �o�׎w��
        ,ooha.attribute19                      AS order_no                   -- �I�[�_�[No.
        ,jrre.source_number                    AS base_employee_num          -- �c�ƒS���R�[�h
        ,papf1.per_information18 || ' ' || papf1.per_information19
                                               AS base_employee_name         -- �c�ƒS����
/* 2009/12/28 Ver1.9 Add Start */
        ,ooha.attribute5                       AS invoice_class              -- �`�[�敪
        ,ooha.attribute20                      AS classification_class       -- ���ދ敪
        ,NULL                                  AS report_output_type         -- �o�͋敪
        ,NULL                                  AS edi_re_output_flag         -- EDI�ďo�̓t���O
        ,NULL                                  AS chain_code                 -- �`�F�[���X�R�[�h
        ,NULL                                  AS chain_name                 -- �`�F�[���X����
        ,NULL                                  AS order_creation_date_from   -- ��M��(FROM)(�p�����[�^)
        ,NULL                                  AS order_creation_date_to     -- ��M��(TO)(�p�����[�^)
        ,NULL                                  AS dlv_date_header_from       -- �[�i��(FROM)(�p�����[�^)
        ,NULL                                  AS dlv_date_header_to         -- �[�i��(TO)(�p�����[�^)
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/01/22 Ver1.9 Add Start E_�{�ғ�_00408�Ή� */
        ,ooha.request_date                     AS dlv_date_header            --�[�i��(�w�b�_)
/* 2010/01/22 Ver1.9 Add End   E_�{�ғ�_00408�Ή� */
      FROM
        oe_order_headers_all       ooha    -- �󒍃w�b�_
        ,oe_order_lines_all        oola    -- �󒍖���
        ,oe_order_sources          oos     -- �󒍃\�[�X
        ,hz_cust_accounts          hca     -- �ڋq�}�X�^
        ,xxcmm_cust_accounts       xca     -- �ڋq�A�h�I��
        ,hz_parties                hp      -- �p�[�e�B�}�X�^
        ,mtl_secondary_inventories msi     -- �ۊǏꏊ�}�X�^
        ,mtl_system_items_b        msib    -- DISC�i��
        ,ic_item_mst_b             iimb    -- OPM�i��
        ,xxcmn_item_mst_b          ximb    -- OPM�i�ڃA�h�I��
        ,fnd_user                  fu      -- ���[�U�}�X�^
        ,per_all_people_f          papf    -- �]�ƈ��}�X�^
        ,per_person_types          ppt     -- �]�ƈ��^�C�v�}�X�^
        ,jtf_rs_resource_extns     jrre    -- ���\�[�X�}�X�^
        ,jtf_rs_salesreps          jrs     -- jtf_rs_salesreps
        ,per_all_people_f          papf1   -- �]�ƈ��}�X�^1
        ,per_person_types          ppt1    -- �]�ƈ��^�C�v�}�X�^1
        ,oe_transaction_types_all  otta    -- �󒍖��דE�v�p����^�C�vALL
        ,oe_transaction_types_tl   otttl   -- �󒍖��דE�v�p����^�C�v
      WHERE
      -- �󒍃w�b�_.�󒍃w�b�_ID���󒍖���.�󒍃w�b�_ID
      ooha.header_id                        = oola.header_id
      -- �g�DID
      AND ooha.org_id                       = gn_org_id
      -- �󒍃w�b�_.�\�[�XID���󒍃\�[�X.�\�[�XID
      AND ooha.order_source_id              = oos.order_source_id
      -- �󒍃\�[�X���́iEDI�󒍁A�≮CSV�A����CSV�AOnline�j
      AND oos.name IN ( 
        SELECT  look_val.attribute1
-- ******** 2009/10/02 1.8 N.Maeda MOD START ******** --
        FROM    fnd_lookup_values           look_val
        WHERE   look_val.language           = cv_lang
        AND     look_val.lookup_type        = cv_type_ost_009_a01
        AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
        AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
        AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
        AND     look_val.enabled_flag       = ct_enabled_flg_y
        --�󒍃\�[�X�iEDI�捞�ECSV�捞�E�N�C�b�N�󒍓��́E�o�׈˗����сj
        AND     look_val.description        = iv_order_source
--
--        FROM    fnd_lookup_values           look_val,
--                fnd_lookup_types_tl         types_tl,
--                fnd_lookup_types            types,
--                fnd_application_tl          appl,
--                fnd_application             app
--        WHERE   appl.application_id         = types.application_id
--        AND     app.application_id          = appl.application_id
--        AND     types_tl.lookup_type        = look_val.lookup_type
--        AND     types.lookup_type           = types_tl.lookup_type
--        AND     types.security_group_id     = types_tl.security_group_id
--        AND     types.view_application_id   = types_tl.view_application_id
--        AND     types_tl.language           = cv_lang
--        AND     look_val.language           = cv_lang
--        AND     appl.language               = cv_lang
--        AND     app.application_short_name  = cv_xxcos_short_name
--        AND     look_val.lookup_type        = cv_type_ost_009_a01
--        AND     look_val.lookup_code        LIKE cv_code_ost_009_a01
--        AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--        AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--        AND     look_val.enabled_flag       = ct_enabled_flg_y
--        --�󒍃\�[�X�iEDI�捞�ECSV�捞�E�N�C�b�N�󒍓��́j
--        AND     look_val.description        = iv_order_source
-- ******** 2009/10/02 1.8 N.Maeda MOD END  ******** --
      )
/* 2010/04/01 Ver1.12 Add Start */
      AND ooha.orig_sys_document_ref     LIKE gt_orig_sys_st_value || cv_multi
/* 2010/04/01 Ver1.12 Add End   */
      --�󒍃w�b�_.�ڋqID = �ڋq�}�X�^.�ڋqID
      AND ooha.sold_to_org_id               = hca.cust_account_id
      --�ڋq�}�X�^.�ڋqID =�ڋq�}�X�^�A�h�I��.�ڋqID
      AND hca.cust_account_id               = xca.customer_id
      --�ڋq�}�X�^�A�h�I��.�[�i���_�R�[�h=�p�����[�^.���_�R�[�h
      AND xca.delivery_base_code            = iv_delivery_base_code
      --�ڋq�}�X�^.�p�[�e�BID = �p�[�e�B�}�X�^.�p�[�e�BID
      AND hca.party_id                      = hp.party_id 
      --���[�U�}�X�^.���[�UID=�󒍃w�b�_.�ŏI�X�V��
      AND fu.user_id                        = ooha.last_updated_by
      --���[�U�}�X�^.�]�ƈ�ID=�]�ƈ��}�X�^.�]�ƈ�ID
      AND fu.employee_id                    = papf.person_id
      AND gd_proc_date                      >= NVL( papf.effective_start_date, gd_min_date )
      AND gd_proc_date                      <= NVL( papf.effective_end_date, gd_max_date )
      AND ppt.business_group_id             = cn_per_business_group_id
      AND ppt.system_person_type            = cv_emp
      AND ppt.active_flag                   = ct_enabled_flg_y
      AND papf.person_type_id               = ppt.person_type_id
      --�󒍃w�b�_.�c�ƒS��ID=jtf_rs_salesreps.salesrep_id
      AND ooha.salesrep_id                  = jrs.salesrep_id
      --jtf_rs_salesreps.���\�[�XID=���\�[�X�}�X�^.���\�[�XID
      AND jrs.resource_id                   = jrre.resource_id
      --���\�[�X�}�X�^.�\�[�X�ԍ�=�]�ƈ��}�X�^.�]�ƈ�ID
      AND jrre.source_id                    = papf1.person_id
      AND gd_proc_date                      >= NVL( papf1.effective_start_date, gd_min_date )
      AND gd_proc_date                      <= NVL( papf1.effective_end_date, gd_max_date )
      AND ppt1.business_group_id            = cn_per_business_group_id
      AND ppt1.system_person_type           = cv_emp
      AND ppt1.active_flag                  = ct_enabled_flg_y
      AND papf1.person_type_id              = ppt1.person_type_id
      -- �󒍖���.�ۊǏꏊ=�ۊǏꏊ�}�X�^.�ۊǏꏊ�R�[�h
      AND oola.subinventory                 = msi.secondary_inventory_name(+)
      -- �󒍖���.�o�׌��g�DID = �ۊǏꏊ�}�X�^.�g�DID
      AND oola.ship_from_org_id             = msi.organization_id(+)
      --�󒍖���.�i��ID= �i�ڃ}�X�^.�i��ID
      AND oola.inventory_item_id            = msib.inventory_item_id
      AND msib.organization_id              = gt_org_id
      AND msib.segment1                     = iimb.item_no
      AND iimb.item_id                      = ximb.item_id
      AND gd_proc_date                      >= NVL( ximb.start_date_active, gd_min_date )
      AND gd_proc_date                      <= NVL( ximb.end_date_active, gd_max_date )
      --�󒍖���.���׃^�C�v���󒍃^�C�v.�^�C�v
      AND oola.line_type_id                 = otttl.transaction_type_id
      --�󒍃^�C�v.�^�C�v���󒍃^�C�vALL.�^�C�v
      AND otttl.transaction_type_id         = otta.transaction_type_id
      --����FJA
      AND otttl.language                    = cv_lang
      AND ( 
        --���̑��iCSV/��ʁj�̏ꍇ
        ( 
          iv_order_source <> gv_order_source_edi_chk 
          -- �󒍖���.�X�e�[�^�X���۰��or���
          AND oola.flow_status_code NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )
/* 2010/03/29 Ver1.11 Add Start */
          -- �󒍃w�b�_.�X�e�[�^�X���۰��or���
          AND ooha.flow_status_code NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )
/* 2010/03/29 Ver1.11 Add End   */
          AND (
            --�󒍃w�b�_�ƃp�����[�^�̎󒍓�����NULL�̏ꍇ �ޔ�����
            ooha.ordered_date IS NULL
            AND ld_ordered_date_from IS NULL
            AND ld_ordered_date_to IS NULL
            OR (
              --�󒍃w�b�_.�󒍓����p�����[�^.�󒍓��iFROM�j
              TRUNC( ooha.ordered_date )           >= NVL( ld_ordered_date_from, TRUNC( ooha.ordered_date ) )
              --�󒍃w�b�_.�󒍓����p�����[�^.�󒍓��iTO�j
              AND TRUNC( ooha.ordered_date )       <= NVL( ld_ordered_date_to, TRUNC( ooha.ordered_date ) )
            )
          )
          AND (
            --�󒍖��ׂƃp�����[�^�̗\��o�ד�����NULL�̏ꍇ �ޔ�����
            oola.schedule_ship_date IS NULL
            AND ld_schedule_ship_date_from IS NULL
            AND ld_schedule_ship_date_to IS NULL
            OR (
              --�󒍖���.�\��o�ד����p�����[�^.�o�ח\����iFROM�j
              TRUNC( oola.schedule_ship_date )     >= 
                  NVL( ld_schedule_ship_date_from, TRUNC( oola.schedule_ship_date ) )
              --�󒍖���.�\��o�ד����p�����[�^.�o�ח\����iTO�j
              AND TRUNC( oola.schedule_ship_date ) <= NVL( ld_schedule_ship_date_to, TRUNC( oola.schedule_ship_date ) )
            )
          )
          AND (
            --�󒍖��ׂƃp�����[�^�̗v��������NULL�̏ꍇ �ޔ�����
            oola.request_date IS NULL
            AND ld_schedule_ordered_date_from IS NULL
            AND ld_schedule_ordered_date_to IS NULL
            OR (
              --�󒍖���.�v�������p�����[�^.�[�i�\����iFROM�j
              TRUNC( oola.request_date )           >= NVL( ld_schedule_ordered_date_from, TRUNC( oola.request_date ) )
              --�󒍖���.�v�������p�����[�^.�[�i�\����iTO�j
              AND TRUNC( oola.request_date )       <= NVL( ld_schedule_ordered_date_to, TRUNC( oola.request_date ) )
            )
          )
          --�]�ƈ��}�X�^.�]�ƈ��ԍ����p�����[�^.���͎�
/* 2009/12/28 Ver1.9 Mod Start */
--          AND papf.employee_number             = NVL( iv_entered_by_code, papf.employee_number )
          AND (
            iv_entered_by_code IS NULL
            OR iv_entered_by_code = papf.employee_number
          )
/* 2009/12/28 Ver1.9 Mod End   */
          --�ڋq�}�X�^.�ڋq�R�[�h���p�����[�^.�o�א�
/* 2009/12/28 Ver1.9 Mod Start */
--          AND hca.account_number               = NVL( iv_ship_to_code, hca.account_number )
          AND (
            iv_ship_to_code IS NULL
            OR iv_ship_to_code = hca.account_number
          )
/* 2009/12/28 Ver1.9 Mod End   */
          AND (
            --�󒍖��ׂƃp�����[�^�̕ۊǏꏊ����NULL�̏ꍇ �ޔ�����
            oola.subinventory IS NULL
            AND iv_subinventory IS NULL
            OR (
              --�󒍖���.�ۊǏꏊ���p�����[�^.�ۊǏꏊ
              oola.subinventory                = NVL( iv_subinventory, oola.subinventory )
            )
          )
          --�󒍃w�b�_.�󒍔ԍ�=�p�����[�^.�󒍔ԍ�
/* 2009/12/28 Ver1.9 Mod Start */
--          AND ooha.order_number                = NVL( iv_order_number, ooha.order_number )
          AND ( 
            iv_order_number IS NULL
            OR iv_order_number = ooha.order_number
          )
/* 2009/12/28 Ver1.9 Mod End   */
/* 2010/04/01 Ver1.12 Add Start */
          --�󒍖���.�X�e�[�^�X=�p�����[�^.�X�e�[�^�X
          AND (
             iv_order_status IS NULL
            OR oola.flow_status_code = iv_order_status
          )
/* 2010/04/01 Ver1.12 Add End   */
        )
      )
      --���敪 = NULL OR 01
      AND (
            ooha.global_attribute3 IS NULL
          OR
            ooha.global_attribute3 = cv_target_order_01
          )
      ORDER BY
/* 2009/12/28 Ver1.9 Mod Start */
--        ooha.header_id     --�󒍃w�b�_.�w�b�_ID
--        ,oola.line_id      --�󒍖���.����ID
        DECODE(  iv_order_source
               , gv_order_source_clik_chk, papf.employee_number  --�N�C�b�N��
/* 2010/04/01 Ver1.12 Add Start */
               , gv_order_source_ship_chk, papf.employee_number  --�o�׎��ш˗�
/* 2010/04/01 Ver1.12 Add End   */
               , NULL                                            --CSV
        )                     --���͎�
        ,hca.account_number   --�o�א�
/* 2010/04/01 Ver1.12 Mod Start */
--/* 2010/01/22 Ver1.9 Add Start E_�{�ғ�_00408�Ή� */
--        ,ooha.cust_po_number         --�ڋq�����ԍ�
--        ,TRUNC(oola.request_date)    --�[�i��
--/* 2010/01/22 Ver1.9 Add End   E_�{�ғ�_00408�Ή� */
        ,TRUNC(oola.request_date)    --�[�i��
        ,ooha.cust_po_number         --�ڋq�����ԍ�
/* 2010/04/01 Ver1.12 Mod End   */
        ,ooha.order_number    --�󒍔ԍ�
        ,oola.line_number     --�󒍖��הԍ�
/* 2009/12/28 Ver1.9 Mod End   */
      ;
--****************************** 2009/07/29 1.7 T.Tominaga ADD END   ******************************--
--
    -- *** ���[�J���E���R�[�h ***
--****************************** 2009/07/29 1.7 T.Tominaga MOD START ******************************--
--    l_data_edi_or_not_rec                data_edi_or_not_cur%ROWTYPE;
    l_data_edi_or_not_rec                data_edi_cur%ROWTYPE;
--****************************** 2009/07/29 1.7 T.Tominaga MOD END   ******************************--
/* 2010/01/22 Ver1.9 Add Start E_�{�ғ�_00408�Ή� */
    ln_denpyokei_order_amount     NUMBER;
    ln_rowid_idx                  NUMBER;
/* 2010/01/22 Ver1.9 Add End E_�{�ғ�_00408�Ή� */
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --���[�v�J�E���g������
    ln_idx          := 0;
/* 2010/01/22 Ver1.9 Add Start E_�{�ғ�_00408�Ή� */
    ln_rowid_idx    := 0;
/* 2010/01/22 Ver1.9 Add End E_�{�ғ�_00408�Ή� */
--
--****************************** 2009/07/29 1.7 T.Tominaga MOD START ******************************--
--    FOR l_data_edi_or_not_rec IN data_edi_or_not_cur LOOP
    -- EDI�捞
    IF iv_order_source = gv_order_source_edi_chk THEN
      OPEN data_edi_cur;
    -- ���̑��iCSV/��ʁj
    ELSE
      OPEN data_edi_not_cur;
    END IF;
--
    <<loop_get_data>>
    LOOP
--
      --
      --�Ώۃf�[�^�擾
      IF iv_order_source = gv_order_source_edi_chk THEN
        FETCH data_edi_cur INTO l_data_edi_or_not_rec;
        EXIT WHEN data_edi_cur%NOTFOUND;
      -- ���̑��iCSV/��ʁj
      ELSE
        FETCH data_edi_not_cur INTO l_data_edi_or_not_rec;
        EXIT WHEN data_edi_not_cur%NOTFOUND;
      END IF;
--****************************** 2009/07/29 1.7 T.Tominaga MOD END   ******************************--
/* 2010/01/22 Ver1.9 Add Start E_�{�ғ�_00408�Ή� */
      -- �`�[�v���R�[�h�쐬
      IF ( ln_idx > 0 ) THEN
          -- �`�[�v�W�v�L�[���ς�������A�`�[�v���R�[�h�̑}��
          IF
             -- EDI�o��
             ( ( iv_order_source = gv_order_source_edi_chk )
               AND
               (  ( NVL( l_data_edi_or_not_rec.deliver_from_code  ,' ') <> NVL( g_report_data_tab(ln_idx).deliver_from_code  ,' ') )
               OR ( NVL( TO_CHAR( l_data_edi_or_not_rec.dlv_date_header ,cv_yyyymmdd ) ,' ')
                                             <> NVL( TO_CHAR( g_report_data_tab(ln_idx).dlv_date_header ,cv_yyyymmdd ) ,' ') )
               OR ( NVL( l_data_edi_or_not_rec.party_order_number ,' ') <> NVL( g_report_data_tab(ln_idx).party_order_number ,' ') )
               )
             )
             OR
/* 2010/04/01 Ver1.12 Mod Start */
--             -- ���̑��i��ʁj�o��
--             ( ( iv_order_source = gv_order_source_clik_chk )
             -- ���̑��i��ʁE�o�׎��ш˗��j�o��
             ( ( iv_order_source IN ( gv_order_source_clik_chk , gv_order_source_ship_chk ) )
/* 2010/04/01 Ver1.12 Mod End   */
               AND
               (  ( SUBSTRB( l_data_edi_or_not_rec.entered_by_code, 1, 5 )
                                                             <> g_report_data_tab(ln_idx).entered_by_code    )
               OR ( l_data_edi_or_not_rec.deliver_from_code  <> g_report_data_tab(ln_idx).deliver_from_code  )
               OR ( l_data_edi_or_not_rec.party_order_number <> g_report_data_tab(ln_idx).party_order_number )
               OR ( NVL( TO_CHAR( l_data_edi_or_not_rec.dlv_date ,cv_yyyymmdd ) ,' ')
                                                    <> NVL( TO_CHAR( g_report_data_tab(ln_idx).dlv_date ,cv_yyyymmdd ) ,' ') )
               )
             )
             OR
             -- ���̑��iCSV�j�o��
/* 2010/04/01 Ver1.12 Mod Start */
--             ( ( iv_order_source NOT IN ( gv_order_source_edi_chk ,gv_order_source_clik_chk ) )
             ( ( iv_order_source NOT IN ( gv_order_source_edi_chk ,gv_order_source_clik_chk, gv_order_source_ship_chk ) )
/* 2010/04/01 Ver1.12 Mod End   */
               AND
               (  ( l_data_edi_or_not_rec.deliver_from_code  <> g_report_data_tab(ln_idx).deliver_from_code  )
               OR ( l_data_edi_or_not_rec.party_order_number <> g_report_data_tab(ln_idx).party_order_number )
               OR ( NVL( TO_CHAR( l_data_edi_or_not_rec.dlv_date ,cv_yyyymmdd ) ,' ')
                                                    <> NVL( TO_CHAR( g_report_data_tab(ln_idx).dlv_date ,cv_yyyymmdd ) ,' ') )
               )
             )
          THEN
            -- ���R�[�hID�̎擾
            SELECT xxcos_rep_order_list_s01.NEXTVAL redord_id
            INTO   lt_record_id
            FROM   dual
            ;
            ln_idx := ln_idx + 1;
--
            -- SVF�ɂăO���[�v�T�v���X�������s���Ă���A
            -- �T�v���X�Ώۍ��ڂɓ���l���i�[�K�v������ׁA
            -- �O���R�[�h��`�[�v���R�[�h�Ɋi�[����B
            g_report_data_tab(ln_idx) := g_report_data_tab(ln_idx - 1);
--
            -- �`�[�v��p���ڂ̐ݒ�
            g_report_data_tab(ln_idx).record_id          := lt_record_id;                                         --���R�[�hID
            g_report_data_tab(ln_idx).record_type        := cn_record_type_denpyokei;                             --���R�[�h�^�C�v�F�`�[�v
            g_report_data_tab(ln_idx).order_amount_total := ln_denpyokei_order_amount;                            --�󒍋��z���v�i�`�[�v�j
--
            -- �`�[�v���z��������
            ln_denpyokei_order_amount := 0;
          END IF;
      ELSE
          -- �`�[�v���z��������
          ln_denpyokei_order_amount := 0;
      END IF;
--
/* 2010/01/22 Ver1.9 Add End E_�{�ғ�_00408�Ή� */
--
      -- ���R�[�hID�̎擾
      BEGIN
        SELECT xxcos_rep_order_list_s01.NEXTVAL     redord_id
        INTO   lt_record_id
        FROM   dual;
      END;
      --
      ln_idx := ln_idx + 1;
/* 2010/01/22 Ver1.9 Mod End E_�{�ғ�_00408�Ή� */
      ln_rowid_idx := ln_rowid_idx + 1;
      --
      --�󒍖��ׂ��X�V���邽�߁AROWID��ޔ�����B
--      gt_oola_rowid_tab(ln_idx)                        := l_data_edi_or_not_rec.row_id;                --ROWID
      gt_oola_rowid_tab(ln_rowid_idx)                  := l_data_edi_or_not_rec.row_id;                --ROWID
/* 2010/01/22 Ver1.9 Mod End E_�{�ғ�_00408�Ή� */
      --
      g_report_data_tab(ln_idx).record_id              := lt_record_id;                                --���R�[�hID
      g_report_data_tab(ln_idx).order_source           := iv_order_source;                             --�󒍃\�[�X
/* 2010/04/01 Ver1.12 Mod Start */
--      IF ( iv_order_source = gv_order_source_clik_chk ) THEN    --�󒍃\�[�X�F�N�C�b�N�󒍓��͂̏ꍇ
      IF (   iv_order_source = gv_order_source_clik_chk
          OR iv_order_source = gv_order_source_ship_chk ) THEN    --�󒍃\�[�X�F�N�C�b�N�󒍓��́E�o�׎��ш˗��̏ꍇ
/* 2010/04/01 Ver1.12 Mod End   */
        g_report_data_tab(ln_idx).entered_by_code      := SUBSTRB( l_data_edi_or_not_rec.entered_by_code, 1, 5 );
                                                                                                       --���͎҃R�[�h
        g_report_data_tab(ln_idx).entered_by_name      := SUBSTRB( l_data_edi_or_not_rec.entered_by_name, 1, 40 );
                                                                                                       --���͎Җ�
      ELSE
        g_report_data_tab(ln_idx).entered_by_code      := NULL;                                        --���͎҃R�[�h
        g_report_data_tab(ln_idx).entered_by_name      := NULL;                                        --���͎Җ�
      END IF;
      g_report_data_tab(ln_idx).order_number           := l_data_edi_or_not_rec.order_number;          --�󒍔ԍ�
      g_report_data_tab(ln_idx).party_order_number     := SUBSTRB( l_data_edi_or_not_rec.party_order_number, 1, 12 );
                                                                                                       --�ڋq�����ԍ�
      g_report_data_tab(ln_idx).line_number            := l_data_edi_or_not_rec.line_number;           --���הԍ�
      g_report_data_tab(ln_idx).order_no               := SUBSTRB( l_data_edi_or_not_rec.order_no, 1, 16 );
                                                                                                       --�I�[�_�[No.
      g_report_data_tab(ln_idx).shipped_date           := l_data_edi_or_not_rec.shipped_date;          --�o�ד�
      g_report_data_tab(ln_idx).dlv_date               := l_data_edi_or_not_rec.dlv_date;              --�[�i��
      g_report_data_tab(ln_idx).order_item_no          := SUBSTRB( l_data_edi_or_not_rec.order_item_no, 1, 7 );
                                                                                                       --�󒍕i�ԍ�
      g_report_data_tab(ln_idx).order_item_name        := SUBSTRB( l_data_edi_or_not_rec.order_item_name, 1, 20 );
                                                                                                       --�󒍕i��
      IF ( l_data_edi_or_not_rec.order_category_code = cv_return ) THEN 
        g_report_data_tab(ln_idx).quantity             := l_data_edi_or_not_rec.quantity * ( -1 );     --����
      ELSE
        g_report_data_tab(ln_idx).quantity             := l_data_edi_or_not_rec.quantity;              --����
      END IF;
      g_report_data_tab(ln_idx).uom_code               := l_data_edi_or_not_rec.uom_code;              --�P��
      g_report_data_tab(ln_idx).dlv_unit_price         := l_data_edi_or_not_rec.dlv_unit_price;        --�[�i�P��
/* 2009/12/28 Ver1.9 Mod Start */
--      g_report_data_tab(ln_idx).order_amount           := ROUND( g_report_data_tab(ln_idx).quantity * 
      g_report_data_tab(ln_idx).order_amount           := TRUNC( g_report_data_tab(ln_idx).quantity * 
/* 2009/12/28 Ver1.9 Mod End   */
                                                          l_data_edi_or_not_rec.dlv_unit_price );      --�󒍋��z
      g_report_data_tab(ln_idx).locat_code             := l_data_edi_or_not_rec.locat_code;            --�ۊǏꏊ�R�[�h
      g_report_data_tab(ln_idx).locat_name             := SUBSTRB( l_data_edi_or_not_rec.locat_name, 1, 10 );
                                                                                                       --�ۊǏꏊ����
      g_report_data_tab(ln_idx).shipping_instructions  := SUBSTRB( l_data_edi_or_not_rec.shipping_instructions, 1, 26 );                                                                                                       --�o�׎w��
      g_report_data_tab(ln_idx).base_employee_num      := SUBSTRB( l_data_edi_or_not_rec.base_employee_num, 1, 5 );
                                                                                                       --�S���c�ƃR�[�h
      g_report_data_tab(ln_idx).base_employee_name     := SUBSTRB( l_data_edi_or_not_rec.base_employee_name, 1, 12 );
                                                                                                       --�S���c�Ɩ���
      g_report_data_tab(ln_idx).deliver_from_code      := SUBSTRB( l_data_edi_or_not_rec.deliver_from_code, 1, 9 );
                                                                                                       --�o�א�R�[�h
      g_report_data_tab(ln_idx).deliver_to_name        := SUBSTRB( l_data_edi_or_not_rec.deliver_to_name, 1, 38 );
                                                                                                       --�o�א於��
/* 2009/12/28 Ver1.9 Add Start */
      g_report_data_tab(ln_idx).invoice_class          := l_data_edi_or_not_rec.invoice_class;         --�`�[�敪
      g_report_data_tab(ln_idx).classification_class   := l_data_edi_or_not_rec.classification_class;  --���ދ敪
      g_report_data_tab(ln_idx).report_output_type     := l_data_edi_or_not_rec.report_output_type;    --�o�͋敪
      g_report_data_tab(ln_idx).edi_re_output_flag     := l_data_edi_or_not_rec.edi_re_output_flag;    --EDI�ďo�̓t���O
      g_report_data_tab(ln_idx).chain_code             := l_data_edi_or_not_rec.chain_code;            --�`�F�[���X�R�[�h
      g_report_data_tab(ln_idx).chain_name             := l_data_edi_or_not_rec.chain_name;            --�`�F�[���X����
      g_report_data_tab(ln_idx).order_creation_date_from := l_data_edi_or_not_rec.order_creation_date_from; --��M��(FROM)
      g_report_data_tab(ln_idx).order_creation_date_to := l_data_edi_or_not_rec.order_creation_date_to;     --��M��(TO)
      g_report_data_tab(ln_idx).dlv_date_header_from   := l_data_edi_or_not_rec.dlv_date_header_from;       --�[�i��(FROM)
      g_report_data_tab(ln_idx).dlv_date_header_to     := l_data_edi_or_not_rec.dlv_date_header_to;         --�[�i��(TO)
/* 2009/12/28 Ver1.9 Add End   */
      g_report_data_tab(ln_idx).created_by             := cn_created_by;                               --�쐬��
      g_report_data_tab(ln_idx).creation_date          := cd_creation_date;                            --�쐬��
      g_report_data_tab(ln_idx).last_updated_by        := cn_last_updated_by;                          --�ŏI�X�V��
      g_report_data_tab(ln_idx).last_update_date       := cd_last_update_date;                         --�ŏI�X�V��
      g_report_data_tab(ln_idx).last_update_login      := cn_last_update_login;                        --�ŏI�X�V۸޲�
      g_report_data_tab(ln_idx).request_id             := cn_request_id;                               --�v��ID
      g_report_data_tab(ln_idx).program_application_id := cn_program_application_id;                   
                                                                                          --�ݶ��ĥ��۸��ѥ���ع����ID
      g_report_data_tab(ln_idx).program_id             := cn_program_id;                               
                                                                                          --�ݶ��ĥ��۸���ID
      g_report_data_tab(ln_idx).program_update_date    := cd_program_update_date;                      --��۸��эX�V��
      --
/* 2010/01/22 Ver1.9 Add End E_�{�ғ�_00408�Ή� */
      g_report_data_tab(ln_idx).record_type            := cn_record_type_detail;                       --���R�[�h�^�C�v�F���׍s
      g_report_data_tab(ln_idx).order_amount_total     := NULL;                                        --�󒍋��z���v�i�`�[�v�j
      g_report_data_tab(ln_idx).dlv_date_header        := l_data_edi_or_not_rec.dlv_date_header;       --�[�i��(�w�b�_)
      -- �`�[�v���z�����Z
      ln_denpyokei_order_amount := ln_denpyokei_order_amount + g_report_data_tab(ln_idx).order_amount;
/* 2010/01/22 Ver1.9 Add End E_�{�ғ�_00408�Ή� */
--
    END LOOP loop_get_data;
--
/* 2010/01/22 Ver1.9 Add Start E_�{�ғ�_00408�Ή� */
    IF ( ln_idx > 0 ) THEN
      -- ���R�[�hID�̎擾
      SELECT xxcos_rep_order_list_s01.NEXTVAL redord_id
      INTO   lt_record_id
      FROM   dual
      ;
      ln_idx := ln_idx + 1;
  
      -- SVF�ɂăO���[�v�T�v���X�������s���Ă���A
      -- �T�v���X�Ώۍ��ڂɓ���l���i�[�K�v������ׁA
      -- �O���R�[�h��`�[�v���R�[�h�Ɋi�[����B
      g_report_data_tab(ln_idx) := g_report_data_tab(ln_idx - 1);
  
      -- �`�[�v��p���ڂ̐ݒ�
      g_report_data_tab(ln_idx).record_id         := lt_record_id;                                         --���R�[�hID
      g_report_data_tab(ln_idx).record_type       := cn_record_type_denpyokei;                             --���R�[�h�^�C�v�F�`�[�v
      g_report_data_tab(ln_idx).order_amount_total := ln_denpyokei_order_amount;                            --�󒍋��z���v�i�`�[�v�j
    END IF;
/* 2010/01/22 Ver1.9 Add End E_�{�ғ�_00408�Ή� */
--
    --���������J�E���g
    gn_target_cnt := g_report_data_tab.COUNT;
--
--****************************** 2009/07/29 1.7 T.Tominaga ADD START ******************************--
    -- EDI�捞
    IF iv_order_source = gv_order_source_edi_chk THEN
      CLOSE data_edi_cur;
    -- ���̑��iCSV/��ʁj
    ELSE
      CLOSE data_edi_not_cur;
    END IF;
--****************************** 2009/07/29 1.7 T.Tominaga ADD START ******************************--
--
  EXCEPTION
--
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
--****************************** 2009/07/29 1.7 T.Tominaga ADD START ******************************--
      -- EDI�捞
      IF iv_order_source = gv_order_source_edi_chk THEN
        IF ( data_edi_cur%ISOPEN ) THEN
          CLOSE data_edi_cur;
        END IF;
      END IF;
--****************************** 2009/07/29 1.7 T.Tominaga ADD END   ******************************--
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name2
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_lock_err,
        iv_token_name1        =>  cv_tkn_nm_table_lock,
        iv_token_value1       =>  lv_tkn_vl_table_name
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--****************************** 2009/07/29 1.7 T.Tominaga ADD START ******************************--
      -- EDI�捞
      IF iv_order_source = gv_order_source_edi_chk THEN
        IF ( data_edi_cur%ISOPEN ) THEN
          CLOSE data_edi_cur;
        END IF;
      -- ���̑��iCSV/��ʁj
      ELSE
        IF ( data_edi_not_cur%ISOPEN ) THEN
          CLOSE data_edi_not_cur;
        END IF;
      END IF;
--****************************** 2009/07/29 1.7 T.Tominaga ADD START ******************************--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : ���[���[�N�e�[�u���o�^(A-4)
   ***********************************************************************************/
  PROCEDURE insert_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rpt_wrk_data'; -- �v���O������
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
    lv_tkn_vl_table_name      VARCHAR2(100);      --�Ώۃe�[�u����
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
    --���[���[�N�e�[�u���o�^����
    BEGIN
      FORALL ln_cnt IN g_report_data_tab.FIRST .. g_report_data_tab.LAST
        INSERT INTO  xxcos_rep_order_list
        VALUES       g_report_data_tab(ln_cnt);
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_data_insert_expt;
    END;
--
    --���팏���擾
    gn_normal_cnt := g_report_data_tab.COUNT;
--
  EXCEPTION
    --*** �����Ώۃf�[�^�o�^��O ***
    WHEN global_data_insert_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name1
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_insert_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  NULL
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END insert_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : update_order_line_data
   * Description      : �󒍖��׏o�͍ςݍX�V�iEDI�捞�̂݁j(A-5)
   ***********************************************************************************/
  PROCEDURE update_order_line_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_order_line_data'; -- �v���O������
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
    lv_tkn_vl_table_name      VARCHAR2(100);      --�Ώۃe�[�u����
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
    --�󒍖��׃e�[�u���X�V����
    BEGIN
      FORALL ln_cnt IN gt_oola_rowid_tab.FIRST .. gt_oola_rowid_tab.LAST
        UPDATE 
          oe_order_lines_all      oola
        SET
          oola.global_attribute1      = TO_CHAR( SYSDATE, cv_yyyymmddhhmiss ), -- �󒍈ꗗ�o�͓����V�X�e�����t
          oola.last_updated_by        = cn_last_updated_by,                    -- �ŏI�X�V��
          oola.last_update_date       = cd_last_update_date,                   -- �ŏI�X�V��
          oola.last_update_login      = cn_last_update_login,                  -- �ŏI�X�V���O�C��
          oola.request_id             = cn_request_id,                         -- �v��ID
          oola.program_application_id = cn_program_application_id,             -- �R���J�����g�E�v���O�����E�A�v��ID
          oola.program_id             = cn_program_id,                         -- �R���J�����g�E�v���O����ID
          oola.program_update_date    = cd_program_update_date                 -- �v���O�����X�V��
        WHERE
          oola.rowid                  = gt_oola_rowid_tab( ln_cnt );           -- �󒍖���ROWID
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_data_update_expt;
    END;
--
  EXCEPTION
    --*** �����Ώۃf�[�^�X�V��O ***
    WHEN global_data_update_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name3
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_update_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  NULL
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END update_order_line_data;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF�N��(A-6)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
-- ********* 2009/10/02 N.Maeda 1.8 ADD START ********* --
    PRAGMA AUTONOMOUS_TRANSACTION; -- �Ɨ��g�����U�N�V����
-- ********* 2009/10/02 N.Maeda 1.8 ADD  END  ********* --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- �v���O������
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
    lv_nodata_msg       VARCHAR2(5000);   --����0���p���b�Z�[�W
    lv_file_name        VARCHAR2(100);    --�o�̓t�@�C����
    lv_tkn_vl_api_name  VARCHAR2(100);    --API��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --����0���p���b�Z�[�W�擾
    lv_nodata_msg           :=  xxccp_common_pkg.get_msg(
      iv_application        =>  cv_xxcos_short_name,
      iv_name               =>  cv_msg_no_data_err
    );
--
    --�o�̓t�@�C�����ҏW
    lv_file_name := cv_report_id || TO_CHAR( SYSDATE, cv_yyyymmdd ) || TO_CHAR( cn_request_id ) || cv_extension;
--
    --SVF�N��
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              =>  lv_retcode,
      ov_errbuf               =>  lv_errbuf,
      ov_errmsg               =>  lv_errmsg,
      iv_conc_name            =>  cv_conc_name,
      iv_file_name            =>  lv_file_name,
      iv_file_id              =>  cv_report_id,
      iv_output_mode          =>  cv_output_mode,
      iv_frm_file             =>  cv_frm_file,
      iv_vrq_file             =>  cv_vrq_file,
      iv_org_id               =>  NULL,
      iv_user_name            =>  NULL,
      iv_resp_name            =>  NULL,
      iv_doc_name             =>  NULL,
      iv_printer_name         =>  NULL,
      iv_request_id           =>  TO_CHAR( cn_request_id ),
      iv_nodata_msg           =>  lv_nodata_msg,
      iv_svf_param1           =>  NULL,
      iv_svf_param2           =>  NULL,
      iv_svf_param3           =>  NULL,
      iv_svf_param4           =>  NULL,
      iv_svf_param5           =>  NULL,
      iv_svf_param6           =>  NULL,
      iv_svf_param7           =>  NULL,
      iv_svf_param8           =>  NULL,
      iv_svf_param9           =>  NULL,
      iv_svf_param10          =>  NULL,
      iv_svf_param11          =>  NULL,
      iv_svf_param12          =>  NULL,
      iv_svf_param13          =>  NULL,
      iv_svf_param14          =>  NULL,
      iv_svf_param15          =>  NULL
    );
    --SVF�N�����s
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_svf_excute_expt;
    END IF;
--
  EXCEPTION
    --*** SVF�N����O ***
    WHEN global_svf_excute_expt THEN
      lv_tkn_vl_api_name      :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_api_name
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_api_err,
        iv_token_name1        =>  cv_tkn_nm_api_name,
        iv_token_value1       =>  lv_tkn_vl_api_name
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END execute_svf;
--
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : ���[���[�N�e�[�u���폜(A-7)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- �v���O������
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
    lv_key_info               VARCHAR2(5000);     --�L�[���
    lv_tkn_vl_key_request_id  VARCHAR2(100);      --�v��ID�̕���
    lv_tkn_vl_table_name      VARCHAR2(100);      --�Ώۃe�[�u����
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur
    IS
      SELECT xrol.record_id rec_id
      FROM   xxcos_rep_order_list xrol           --�󒍈ꗗ���X�g���[���[�N�e�[�u��
      WHERE  xrol.request_id = cn_request_id     --�v��ID
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
    --�Ώۃf�[�^���b�N
    BEGIN
      -- ���b�N�p�J�[�\���I�[�v��
      OPEN lock_cur;
      -- ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_cur;
    EXCEPTION
      --�Ώۃf�[�^���b�N��O
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
    --�Ώۃf�[�^�폜
    BEGIN
      DELETE FROM 
        xxcos_rep_order_list xrol               --�󒍈ꗗ���X�g���[���[�N�e�[�u��
      WHERE xrol.request_id = cn_request_id     --�v��ID
      ;
    EXCEPTION
      --�Ώۃf�[�^�폜���s
      WHEN OTHERS THEN
        lv_tkn_vl_key_request_id  :=  xxccp_common_pkg.get_msg(
          iv_application          =>  cv_xxcos_short_name,
          iv_name                 =>  cv_msg_vl_key_request_id
        );
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1         =>  lv_tkn_vl_key_request_id,   --�v��ID�̕���
          iv_data_value1        =>  TO_CHAR( cn_request_id ),   --�v��ID
          ov_key_info           =>  lv_key_info,                --�ҏW���ꂽ�L�[���
          ov_errbuf             =>  lv_errbuf,                  --�G���[���b�Z�[�W
          ov_retcode            =>  lv_retcode,                 --���^�[���R�[�h
          ov_errmsg             =>  lv_errmsg                   --���[�U�E�G���[�E���b�Z�[�W
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          RAISE global_data_delete_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
    END;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name1
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_lock_err,
        iv_token_name1        =>  cv_tkn_nm_table_lock,
        iv_token_value1       =>  lv_tkn_vl_table_name
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** �����Ώۃf�[�^�폜��O�n���h�� ***
    WHEN global_data_delete_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name1
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_delete_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  lv_key_info
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_order_source                 IN     VARCHAR2,         --   �󒍃\�[�X
    iv_delivery_base_code           IN     VARCHAR2,         --   �[�i���_�R�[�h
    iv_ordered_date_from            IN     VARCHAR2,         --   �󒍓�(FROM)
    iv_ordered_date_to              IN     VARCHAR2,         --   �󒍓�(TO)
    iv_schedule_ship_date_from      IN     VARCHAR2,         --   �o�ח\���(FROM)
    iv_schedule_ship_date_to        IN     VARCHAR2,         --   �o�ח\���(TO)
    iv_schedule_ordered_date_from   IN     VARCHAR2,         --   �[�i�\���(FROM)
    iv_schedule_ordered_date_to     IN     VARCHAR2,         --   �[�i�\���(TO)
    iv_entered_by_code              IN     VARCHAR2,         --   ���͎҃R�[�h
    iv_ship_to_code                 IN     VARCHAR2,         --   �o�א�R�[�h
    iv_subinventory                 IN     VARCHAR2,         --   �ۊǏꏊ
    iv_order_number                 IN     VARCHAR2,         --   �󒍔ԍ�
/* 2009/12/28 Ver1.9 Add Start */
    iv_output_type                  IN     VARCHAR2,         --   �o�͋敪
    iv_chain_code                   IN     VARCHAR2,         --   �`�F�[���X�R�[�h
    iv_order_creation_date_from     IN     VARCHAR2,         --   ��M��(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,         --   ��M��(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,         --   �[�i��(�w�b�_)(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,         --   �[�i��(�w�b�_)(TO)
/* 2009/12/28 Ver1.9 Add Start */
/* 2010/04/01 Ver1.12 Add Start */
    iv_order_status                 IN     VARCHAR2,         --   �󒍃X�e�[�^�X
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
    iv_output_quantity_type         IN     VARCHAR2,         --   �o�͐��ʋ敪
/* 2012/01/30 Ver1.14 Add End   */
    ov_errbuf                       OUT    VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ld_ordered_date_from             DATE;   -- �󒍓�(FROM)_�`�F�b�NOK
    ld_ordered_date_to               DATE;   -- �󒍓�(TO)_�`�F�b�NOK
    ld_schedule_ship_date_from       DATE;   -- �o�ח\���(FROM)_�`�F�b�NOK
    ld_schedule_ship_date_to         DATE;   -- �o�ח\���(TO)_�`�F�b�NOK
    ld_schedule_ordered_date_from    DATE;   -- �[�i�\���(FROM)_�`�F�b�NOK
    ld_schedule_ordered_date_to      DATE;   -- �[�i�\���(TO)_�`�F�b�NOK
/* 2009/12/28 Ver1.9 Add Start */
    ld_order_creation_date_from      DATE;   -- ��M��(FROM)_�`�F�b�NOK
    ld_order_creation_date_to        DATE;   -- ��M��(TO)_�`�F�b�NOK
    ld_ordered_date_h_from           DATE;   -- �[�i��(�w�b�_)(FROM)_�`�F�b�NOK
    ld_ordered_date_h_to             DATE;   -- �[�i��(�w�b�_)(TO)_�`�F�b�NOK
/* 2009/12/28 Ver1.9 Add End   */
--2009/06/19  Ver1.5 T1_1437  Add start
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h(SVF���s���ʕێ��p)
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
--2009/06/19  Ver1.5 T1_1437  Add end
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
    lv_update_errbuf                  VARCHAR2(5000);
    lv_update_retcode                 VARCHAR2(1);
    lv_update_errmsg                  VARCHAR2(5000);
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
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
--
    -- ===============================
    -- A-1  ��������
    -- ===============================
    init(
      iv_order_source,              -- �󒍃\�[�X
      iv_delivery_base_code,        -- �[�i���_�R�[�h
      iv_ordered_date_from,         -- �󒍓�(FROM)
      iv_ordered_date_to,           -- �󒍓�(TO)
      iv_schedule_ship_date_from,   -- �o�ח\���(FROM)
      iv_schedule_ship_date_to,     -- �o�ח\���(TO)
      iv_schedule_ordered_date_from,-- �[�i�\���(FROM)
      iv_schedule_ordered_date_to,  -- �[�i�\���(TO)
      iv_entered_by_code,           -- ���͎҃R�[�h
      iv_ship_to_code,              -- �o�א�R�[�h
      iv_subinventory,              -- �ۊǏꏊ
      iv_order_number,              -- �󒍔ԍ�
/* 2009/12/28 Ver1.9 Add Start */
      iv_output_type,               -- �o�͋敪
      iv_chain_code,                -- �`�F�[���X�R�[�h
      iv_order_creation_date_from,  -- ��M��(FROM)
      iv_order_creation_date_to,    -- ��M��(TO)
      iv_ordered_date_h_from,       -- �[�i��(�w�b�_)(FROM)
      iv_ordered_date_h_to,         -- �[�i��(�w�b�_)(TO)
/* 2009/12/28 Ver1.9 Add Start */
/* 2010/04/01 Ver1.12 Add Start */
      iv_order_status,              -- �󒍃X�e�[�^�X
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
      iv_output_quantity_type,      -- �o�͐��ʋ敪
/* 2012/01/30 Ver1.14 Add End   */
      lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  �p�����[�^�`�F�b�N
    -- ===============================
    check_parameter(
      iv_ordered_date_from,         -- �󒍓�(FROM)
      iv_ordered_date_to,           -- �󒍓�(TO)
      iv_schedule_ship_date_from,   -- �o�ח\���(FROM)
      iv_schedule_ship_date_to,     -- �o�ח\���(TO)
      iv_schedule_ordered_date_from,-- �[�i�\���(FROM)
      iv_schedule_ordered_date_to,  -- �[�i�\���(TO)
/* 2009/12/28 Ver1.9 Add Start */
      iv_order_creation_date_from,  -- ��M��(FROM)
      iv_order_creation_date_to,    -- ��M��(TO)
      iv_ordered_date_h_from,       -- �[�i��(�w�b�_)(FROM)
      iv_ordered_date_h_to,         -- �[�i��(�w�b�_)(TO)
      iv_order_source,              -- �󒍃\�[�X
      iv_output_type,               -- �o�͋敪
/* 2009/12/28 Ver1.9 Add End   */
      ld_ordered_date_from,         -- �󒍓�(FROM)_�`�F�b�NOK
      ld_ordered_date_to,           -- �󒍓�(TO)_�`�F�b�NOK
      ld_schedule_ship_date_from,   -- �o�ח\���(FROM)_�`�F�b�NOK
      ld_schedule_ship_date_to,     -- �o�ח\���(TO)_�`�F�b�NOK
      ld_schedule_ordered_date_from,-- �[�i�\���(FROM)_�`�F�b�NOK
      ld_schedule_ordered_date_to,  -- �[�i�\���(TO)_�`�F�b�NOK
/* 2009/12/28 Ver1.9 Add Start */
      ld_order_creation_date_from,  -- ��M��(FROM)_�`�F�b�NOK
      ld_order_creation_date_to,    -- ��M��(TO)_�`�F�b�NOK
      ld_ordered_date_h_from,       -- �[�i��(�w�b�_)(FROM)_�`�F�b�NOK
      ld_ordered_date_h_to,         -- �[�i��(�w�b�_)(TO)_�`�F�b�NOK
/* 2009/12/28 Ver1.9 Add End   */
      lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  �Ώۃf�[�^�擾
    -- ===============================
    get_data(
      iv_order_source,              -- �󒍃\�[�X
      iv_delivery_base_code,        -- �[�i���_�R�[�h
      ld_ordered_date_from,         -- �󒍓�(FROM)_�`�F�b�NOK
      ld_ordered_date_to,           -- �󒍓�(TO)_�`�F�b�NOK
      ld_schedule_ship_date_from,   -- �o�ח\���(FROM)_�`�F�b�NOK
      ld_schedule_ship_date_to,     -- �o�ח\���(TO)_�`�F�b�NOK
      ld_schedule_ordered_date_from,-- �[�i�\���(FROM)_�`�F�b�NOK
      ld_schedule_ordered_date_to,  -- �[�i�\���(TO)_�`�F�b�NOK
      iv_entered_by_code,           -- ���͎҃R�[�h
      iv_ship_to_code,              -- �o�א�R�[�h
      iv_subinventory,              -- �ۊǏꏊ
      iv_order_number,              -- �󒍔ԍ�
/* 2009/12/28 Ver1.9 Add Start */
      iv_output_type,               -- �o�͋敪
      iv_chain_code,                -- �`�F�[���X�R�[�h
      ld_order_creation_date_from,  -- ��M��(FROM)_�`�F�b�NOK
      ld_order_creation_date_to,    -- ��M��(TO)_�`�F�b�NOK
      ld_ordered_date_h_from,       -- �[�i��(�w�b�_)(FROM)_�`�F�b�NOK
      ld_ordered_date_h_to,         -- �[�i��(�w�b�_)(TO)_�`�F�b�NOK
/* 2009/12/28 Ver1.9 Add To    */
/* 2010/04/01 Ver1.12 Add Start */
      iv_order_status,              -- �󒍃X�e�[�^�X
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
      iv_output_quantity_type,      -- �o�͐��ʋ敪
/* 2012/01/30 Ver1.14 Add End   */
      lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4  ���[���[�N�e�[�u���o�^
    -- ===============================
    insert_rpt_wrk_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
    COMMIT;
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
--
    -- ===============================
    -- A-5  �󒍖��׏o�͍ςݍX�V�iEDI�捞�V�K�̂݁j
    -- ===============================
/* 2009/12/28 Ver1.9 Mod Start */
--    IF ( iv_order_source = gv_order_source_edi_chk ) THEN 
    IF ( iv_order_source = gv_order_source_edi_chk ) 
      AND ( iv_output_type = gt_report_output_type_n ) THEN
/* 2009/12/28 Ver1.9 Mod End   */
      update_order_line_data(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
-- ************ 2009/10/02 1.8 N.Maeda DEL START ************--
--      IF ( lv_retcode = cv_status_normal ) THEN
--        NULL;
--      ELSE
--        --���[���[�N�e�[�u���ɓo�^���ꂽ�������N���A
--        gn_normal_cnt := 0;
--        RAISE global_process_expt;
--      END IF;
-- ************ 2009/10/02 1.8 N.Maeda DEL  END  ************--
    END IF;
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
      lv_update_errbuf  := lv_errbuf;
      lv_update_retcode := lv_retcode;
      lv_update_errmsg  := lv_errmsg;
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
--
-- ************ 2009/10/02 1.8 N.Maeda DEL START ************--
--    --�R���b�g�����i�ȏ�̏���������̏ꍇ�j
--    COMMIT;
-- ************ 2009/10/02 1.8 N.Maeda DEL  END  ************--
--
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
    IF ( lv_update_retcode = cv_status_normal ) THEN
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
      -- ===============================
      -- A-6  SVF�N��
      -- ===============================
      execute_svf(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
-- 2009/06/19  Ver1.5 T1_1437  Mod start
--    IF ( lv_retcode = cv_status_normal ) THEN
--      NULL;
--    ELSE
--      RAISE global_process_expt;
--    END IF;
      --
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
    IF ( lv_retcode <> cv_status_normal ) THEN
      ROLLBACK;
    END IF;
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
      --�G���[�ł����[�N�e�[�u�����폜����ׁA�G���[����ێ�
      lv_errbuf_svf  := lv_errbuf;
      lv_retcode_svf := lv_retcode;
      lv_errmsg_svf  := lv_errmsg;
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
    END IF;
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
-- 2009/06/19  Ver1.5 T1_1437  Mod End
--
    -- ===============================
    -- A-7  ���[���[�N�e�[�u���폜
    -- ===============================
    delete_rpt_wrk_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
-- 2009/06/19  Ver1.5 T1_1437  Add start
    --�G���[�̏ꍇ�A���[���o�b�N����̂ł����ŃR�~�b�g
    COMMIT;
--
-- ************ 2009/10/02 1.8 N.Maeda ADD START ************--
    IF ( lv_update_retcode = cv_status_error ) THEN
      lv_errbuf   := lv_update_errbuf;
      lv_retcode  := lv_update_retcode;
      lv_errmsg   := lv_update_errmsg;
      RAISE global_process_expt;
    END IF;
-- ************ 2009/10/02 1.8 N.Maeda ADD  END  ************--
    --SVF���s���ʊm�F
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
-- 2009/06/19  Ver1.5 T1_1437  Add End
--
    --����0�����X�e�[�^�X���䏈��
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf                          OUT    VARCHAR2,         --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                         OUT    VARCHAR2,         --   ���^�[���E�R�[�h    --# �Œ� #
    iv_order_source                 IN     VARCHAR2,         --   �󒍃\�[�X
    iv_delivery_base_code           IN     VARCHAR2,         --   �[�i���_�R�[�h
    iv_ordered_date_from            IN     VARCHAR2,         --   �󒍓�(FROM)
    iv_ordered_date_to              IN     VARCHAR2,         --   �󒍓�(TO)
    iv_schedule_ship_date_from      IN     VARCHAR2,         --   �o�ח\���(FROM)
    iv_schedule_ship_date_to        IN     VARCHAR2,         --   �o�ח\���(TO)
    iv_schedule_ordered_date_from   IN     VARCHAR2,         --   �[�i�\���(FROM)
    iv_schedule_ordered_date_to     IN     VARCHAR2,         --   �[�i�\���(TO)
    iv_entered_by_code              IN     VARCHAR2,         --   ���͎҃R�[�h
    iv_ship_to_code                 IN     VARCHAR2,         --   �o�א�R�[�h
    iv_subinventory                 IN     VARCHAR2,         --   �ۊǏꏊ
/* 2009/12/28 Ver1.9 Mod Start */
--    iv_order_number                 IN     VARCHAR2          --   �󒍔ԍ�
    iv_order_number                 IN     VARCHAR2,         --   �󒍔ԍ�
    iv_output_type                  IN     VARCHAR2,         --   �o�͋敪
    iv_chain_code                   IN     VARCHAR2,         --   �`�F�[���X�R�[�h
    iv_order_creation_date_from     IN     VARCHAR2,         --   ��M��(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,         --   ��M��(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,         --   �[�i��(�w�b�_)(FROM)
/* 2010/04/01 Ver1.12 Mod Start */
--    iv_ordered_date_h_to            IN     VARCHAR2          --   �[�i��(�w�b�_)(TO)
    iv_ordered_date_h_to            IN     VARCHAR2,         --   �[�i��(�w�b�_)(TO)
/* 2012/01/30 Ver1.14 Mod Start */
--    iv_order_status                 IN     VARCHAR2          --   �󒍃X�e�[�^�X
    iv_order_status                 IN     VARCHAR2,         --   �󒍃X�e�[�^�X
    iv_output_quantity_type         IN     VARCHAR2          --   �o�͐��ʋ敪
/* 2012/01/30 Ver1.14 Mod End   */
/* 2010/04/01 Ver1.12 Mod End   */
/* 2009/12/28 Ver1.9 Mod End   */
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O
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
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_order_source                 -- �󒍃\�[�X
      ,iv_delivery_base_code           -- �[�i���_�R�[�h
      ,iv_ordered_date_from            -- �󒍓�(FROM)
      ,iv_ordered_date_to              -- �󒍓�(TO)
      ,iv_schedule_ship_date_from      -- �o�ח\���(FROM)
      ,iv_schedule_ship_date_to        -- �o�ח\���(TO)
      ,iv_schedule_ordered_date_from   -- �[�i�\���(FROM)
      ,iv_schedule_ordered_date_to     -- �[�i�\���(TO)
      ,iv_entered_by_code              -- ���͎҃R�[�h
      ,iv_ship_to_code                 -- �o�א�R�[�h
      ,iv_subinventory                 -- �ۊǏꏊ
      ,iv_order_number                 -- �󒍔ԍ�
/* 2009/12/28 Ver1.9 Add Start */
      ,iv_output_type                  -- �o�͋敪
      ,iv_chain_code                   -- �`�F�[���X�R�[�h
      ,iv_order_creation_date_from     -- ��M��(FROM)
      ,iv_order_creation_date_to       -- ��M��(TO)
      ,iv_ordered_date_h_from          -- �[�i��(�w�b�_)(FROM)
      ,iv_ordered_date_h_to            -- �[�i��(�w�b�_)(TO)
/* 2009/12/28 Ver1.9 Add End   */
/* 2010/04/01 Ver1.12 Add Start */
      ,iv_order_status                 -- �󒍃X�e�[�^�X
/* 2010/04/01 Ver1.12 Add End   */
/* 2012/01/30 Ver1.14 Add Start */
      ,iv_output_quantity_type         -- �o�͐��ʋ敪
/* 2012/01/30 Ver1.14 Add End   */
      ,lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
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
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
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
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS009A01R;
/
