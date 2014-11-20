CREATE OR REPLACE PACKAGE BODY APPS.XXCOS011A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A01C (body)
 * Description      : SQL-LOADER�ɂ����EDI�[�i�ԕi��񃏁[�N�e�[�u���Ɏ捞�܂ꂽEDI�ԕi�m��f�[�^��
 *                    EDI�w�b�_���e�[�u���AEDI���׏��e�[�u���ɂ��ꂼ��o�^���܂��B
 * MD.050           : �ԕi�m��f�[�^�捞�iMD050_COS_011_A01�j
 * Version          : 1.9
 *
 * Program List
 * ----------------------------------- ----------------------------------------------------------
 *  Name                                Description
 * ----------------------------------- ----------------------------------------------------------
 *  init                               �������� (A-1)
 *  sel_in_edi_delivery_work           EDI�[�i�ԕi��񃏁[�N�e�[�u���f�[�^���o (A-2)
 *  xxcos_in_edi_headers_edit          EDI�w�b�_���ϐ��̕ҏW(A-2)(1)
 *  xxcos_in_edi_lists_edit            EDI���׏��ϐ��̕ҏW(A-2)(2)
 *  data_check                         �f�[�^�Ó����`�F�b�N (A-3)
 *  xxcos_in_edi_headers_add           EDI�w�b�_���ϐ��ւ̒ǉ�(A-4)
 *  xxcos_in_edi_headers_up            EDI�w�b�_���ϐ��֐��ʂ����Z(A-5)
 *  xxcos_in_edi_deli_wk_update        EDI�[�i�ԕi��񃏁[�N�e�[�u���ւ̍X�V(A-6)
 *  xxcos_in_edi_headers_insert        EDI�w�b�_���e�[�u���ւ̃f�[�^�}��(A-7)
 *  xxcos_in_edi_lines_insert          EDI���׏��e�[�u���ւ̃f�[�^�}��(A-8)
 *  xxcos_in_edi_deli_work_delete      EDI�[�i�ԕi��񃏁[�N�e�[�u���f�[�^�폜(A-9)
 *  xxcos_in_edi_head_lock             EDI�w�b�_���e�[�u�����b�N(A-10)(1)
 *  xxcos_in_edi_line_lock             EDI���׏��e�[�u�����b�N(A-10)(2)
 *  xxcos_in_edi_head_delete           EDI�w�b�_���e�[�u���f�[�^�폜(A-10)(3)
 *  xxcos_in_edi_line_delete           EDI���׏��e�[�u���폜(A-10)(4)
 *  xxcos_in_edi_head_line_delete      EDI�w�b�_���e�[�u���AEDI���׏��e�[�u���f�[�^�폜(A-10)
 *  submain                            ���C�������v���V�[�W��
 *  main                               �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/27    1.0   K.Watanabe      �V�K�쐬
 *  2009/02/12    1.1   T.Ishiwata      [COS_058]�ڋq���o�ɉc�ƒP�ʂ�ǉ�
 *                                      [COS_073]�I���X�e�[�^�X�ɂ�鏈������̏C��
 *                                      [COS_082]�`�[�v�̏C��
 *                                      [COS_096]���P���i�����j�̎擾�����ǉ�
 *                                      [COS_103]�ϊ���ڋq�R�[�h�擾���W�b�N�̏C��
 *                                      [COS_118]EDI���폜���W�b�N�̏C��
 *  2009/05/19    1.2   T.Kitajima      [T1_0242]�i�ڎ擾���AOPM�i�ڃ}�X�^.�����i�����j�J�n�������ǉ�
 *                                      [T1_0243]�i�ڎ擾���A�q�i�ڑΏۊO�����ǉ�
 *                                      [T1_1055]���i�\�A�P���擾���W�b�N�ύX
 *  2009/05/28    1.3   T.Kitajima      [T1_0711]�����㌏���Ή�
 *                                      [T1_1164]oracle�G���[�Ή�
 *  2009/06/04    1.4   T.Kitajima      [T1_1289]�����㌏���Ή�
 *  2009/06/15    1.5   M.Sano          [T1_0700]�ugt_err_edideli_work_data�v�z��̏������Ή�
 *  2009/06/29    1.5   T.Tominaga      [T1_0022, T1_0023, T1_0024, T1_0042, T1_0201]
 *                                      �E�u���C�N�����ɓX�܃R�[�h��ǉ�
 *                                      �E�e��`�F�b�N�����ŃG���[�ɂ��Ȃ��Ή�
 *  2009/07/21    1.5   N.Maeda         [000644]�[�������ǉ�
 *                                      [000437]PT�l���̒ǉ�
 *  2009/08/05    1.5   N.Maeda         [000437]���r���[�w�E�ǉ�
 *  2009/08/06    1.5   M.Sano          [0000644]���r���[�w�E�Ή�
 *  2009/09/28    1.6   K.Satomura      [0001156,0001289]
 *  2010/03/02    1.7   M.Sano          [E_�{�ғ�_01159]�p�����[�^(�`�F�[���X)�ɁuDEFAULT NULL�v�ǉ�
 *  2010/04/23    1.8   T.Yoshimoto     [E_�{�ғ�_02427]chain_peculiar_area_header�o�^�f�[�^�ύX
 *  2011/07/26    1.9   K.Kiriu         [E_�{�ғ�_07906]����BMS�Ή�
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
  cd_process_date           CONSTANT DATE        := xxccp_common_pkg2.get_process_date; -- �Ɩ�������
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_line               CONSTANT VARCHAR2(3) := '   ';
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
  --*** �f�[�^���o�G���[��O ***
  global_data_sel_expt      EXCEPTION;
  --�Ώۃf�[�^�Ȃ���O
  global_nodata_expt        EXCEPTION;
  -- ���b�N�G���[
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT   VARCHAR2(100) := 'XXCOS011A01';               -- �p�b�P�[�W��
--
  cv_application            CONSTANT   VARCHAR2(5)   := 'XXCOS';                     -- �A�v���P�[�V������
  -- �v���t�@�C��
  cv_prf_edi_del_date       CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_PURGE_TERM';     -- XXCOS:EDI���폜����
  cv_prf_case_code          CONSTANT   VARCHAR2(50)  := 'XXCOS1_CASE_UOM_CODE';      -- XXCOS:�P�[�X�P�ʃR�[�h
  cv_prf_orga_code1         CONSTANT   VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:�݌ɑg�D�R�[�h
  cv_prf_org_id             CONSTANT   VARCHAR2(50)  := 'ORG_ID';                    -- MO:�c�ƒP��
  -- �N�C�b�N�R�[�h(�^�C�v)
  cv_lookup_type            CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_ITEM_ERR_TYPE';
  cv_lookup_type1           CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_EXE_TYPE';
  cv_lookup_type2           CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_STATUS';
  cv_lookup_type3           CONSTANT   VARCHAR2(50)  := 'XXCOS1_DATA_TYPE_CODE';
  cv_lookup_type4           CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_CREATE_CLASS';   -- EDI�쐬���敪
  -- �N�C�b�N�R�[�h(�R�[�h)
  cv_inv_num_err_flag       CONSTANT   VARCHAR2(1)   := '9';   -- ���s�敪�F�u�G���[�v
  cv_creation_class_code    CONSTANT   VARCHAR2(10)  := '30';
  cv_customer_class_code10  CONSTANT   VARCHAR2(10)  := '10';  -- �ڋq�}�X�^.�ڋq�敪 = '10'(�ڋq)
  cv_customer_class_code18  CONSTANT   VARCHAR2(10)  := '18';  -- �ڋq�}�X�^.�ڋq�敪 = '18'(EDI�`�F�[���X)
  cv_cust_site_use_code     CONSTANT   VARCHAR2(10)  := 'SHIP_TO';                   -- �ڋq�g�p�ړI�F�o�א�
  cn_0                      CONSTANT   NUMBER := 0;
  cn_1                      CONSTANT   NUMBER := 1;
  cn_m1                     CONSTANT   NUMBER := -1;
  cv_y                      CONSTANT   VARCHAR2(1)   := 'Y';
-- ******************** 2009/09/28 1.6 K.Satomura MOD START *********************** --
  cv_n                      CONSTANT   VARCHAR2(1)   := 'N';
-- ******************** 2009/09/28 1.6 K.Satomura MOD END   *********************** --

  cv_0                      CONSTANT   VARCHAR2(1)   := '0';
  cv_1                      CONSTANT   VARCHAR2(1)   := '1';
  cv_2                      CONSTANT   VARCHAR2(1)   := '2';
  cv_par                    CONSTANT   VARCHAR2(1)   := '%';
  --* -------------------------------------------------------------------------------------------
  gv_msg_nodata_err         CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00003'; --�Ώۃf�[�^�Ȃ��G���[
  gv_msg_in_param_none_err  CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00006'; --�K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
  gv_msg_in_param_err       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00019'; --���̓p�����[�^�s���G���[���b�Z�[�W
  gv_msg_in_none_err        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00015'; --�K�{���ږ����̓G���[���b�Z�[�W
  gv_msg_get_profile_err    CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00004'; --�v���t�@�C���擾�G���[���b�Z�[�W
  gv_msg_orga_id_err        CONSTANT   VARCHAR2(20)  := 'APP-XXCOI1-00006'; --�݌ɑg�DID�擾�G���[���b�Z�[�W
  gv_msg_lock               CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00001'; --���b�N�G���[���b�Z�[�W
  gv_msg_nodata             CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00013'; --�f�[�^���o�G���[���b�Z�[�W
  gv_msg_cust_num_chg_err   CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00020'; --�ڋq�R�[�h�ϊ��G���[���b�Z�[�W
  gv_msg_item_code_err      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00023'; --EDI�A�g�i�ڃR�[�h�敪�G���[���b�Z�[�W
  gv_msg_product_code_err   CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00024'; --���i�R�[�h�ϊ��G���[���b�Z�[�W
  gv_msg_price_list_err     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00022'; --���i�\���ݒ�G���[���b�Z�[�W
  gv_msg_data_update_err    CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00011'; --�f�[�^�X�V�G���[���b�Z�[�W
  gv_msg_data_delete_err    CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00012'; --�f�[�^�폜�G���[���b�Z�[�W
  gv_msg_param_out_msg1     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12151'; --�p�����[�^�o�̓��b�Z�[�W1
  gv_msg_param_out_msg2     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12152'; --�p�����[�^�o�̓��b�Z�[�W2
  gv_msg_prod_cd_ng_rec_num CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00039'; --���i�R�[�h�G���[�������b�Z�[�W
  gv_msg_normal_msg         CONSTANT   VARCHAR2(20)  := 'APP-XXCCP1-90004'; --����I�����b�Z�[�W
  gv_msg_warning_msg        CONSTANT   VARCHAR2(20)  := 'APP-XXCCP1-90005'; --�x���I�����b�Z�[�W
  gv_msg_error_msg          CONSTANT   VARCHAR2(20)  := 'APP-XXCCP1-90006'; --�G���[�I���S���[���o�b�N���b�Z�[�W
  cv_msg_call_api_err       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00017'; --API�ďo�G���[
--****************************** 2009/05/19 1.2 T.Kitajima ADD START ******************************--
  cv_msg_price_err          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00123'; -- �P���擾�G���[���b�Z�[�W
--****************************** 2009/05/19 1.2 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
  cv_msg_count              CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12176'; -- �����������b�Z�[�W
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
--****************************** 2009/09/28 1.6 K.Satomura ADD START ******************************--
  cv_msg_item_err_type      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-11959';  -- EDI�i�ڃG���[�^�C�v
  cv_msg_lookup_value       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00046';  -- �N�C�b�N�R�[�h
  cv_msg_mst_notfound       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-10002';  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
--****************************** 2009/09/28 1.6 K.Satomura ADD END   ******************************--
  --* -------------------------------------------------------------------------------------------
  --�g�[�N��
  cv_msg_in_param           CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12168';  -- ���s�敪
  --�g�[�N�� �v���t�@�C��
  cv_msg_edi_del_date       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12169';  -- EDI���폜����
  cv_msg_case_code          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12153';  -- �P�[�X�P�ʃR�[�h
  cv_msg_orga_code          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12154';  -- �݌ɑg�D�R�[�h
  cv_msg_org_id             CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00047';  -- MO:�c�ƒP��
  --�g�[�N�� �v���t�@�C��
  cv_msg_in_file_name       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12171';  -- �C���^�[�t�F�[�X�t�@�C����
  --* -------------------------------------------------------------------------------------------
  cv_tkn_profile            CONSTANT   VARCHAR2(50) :=  'PROFILE';              --�v���t�@�C��
  cv_tkn_item               CONSTANT   VARCHAR2(50) :=  'ITEM';
  cv_tkn_org_code           CONSTANT   VARCHAR2(50) :=  'ORG_CODE_TOK';
  cv_tkn_in_param           CONSTANT   VARCHAR2(50) :=  'IN_PARAM';             --���̓p�����[�^
  cv_tkn_api_name           CONSTANT   VARCHAR2(50) :=  'API_NAME';             --API��
  cv_tkn_table_name         CONSTANT   VARCHAR2(50) :=  'TABLE';                --�e�[�u����
  cv_tkn_table_name1        CONSTANT   VARCHAR2(50) :=  'TABLE_NAME';           --�e�[�u����
  cv_tkn_key_data           CONSTANT   VARCHAR2(50) :=  'KEY_DATA';             --�L�[�f�[�^
  cv_chain_shop_code        CONSTANT   VARCHAR2(50) :=  'CHAIN_SHOP_CODE';
  cv_shop_code              CONSTANT   VARCHAR2(50) :=  'SHOP_CODE';
  cv_prod_code              CONSTANT   VARCHAR2(50) :=  'PROD_CODE';
  cv_prod_type              CONSTANT   VARCHAR2(50) :=  'PROD_TYPE';
  cv_param1                 CONSTANT   VARCHAR2(50) :=  'PARAM1';
  cv_param2                 CONSTANT   VARCHAR2(50) :=  'PARAM2';
  cv_application1           CONSTANT   VARCHAR2(5)   := 'XXCOI';             -- �A�v���P�[�V������
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
  cv_tkn_cnt1               CONSTANT   VARCHAR2(50) :=  'COUNT1';            -- �J�E���g1
  cv_tkn_cnt2               CONSTANT   VARCHAR2(50) :=  'COUNT2';            -- �J�E���g2
  cv_tkn_cnt3               CONSTANT   VARCHAR2(50) :=  'COUNT3';            -- �J�E���g3
  cv_tkn_cnt4               CONSTANT   VARCHAR2(50) :=  'COUNT4';            -- �J�E���g4
  cv_tkn_cnt5               CONSTANT   VARCHAR2(50) :=  'COUNT5';            -- �J�E���g5
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
--****************************** 2009/09/28 1.6 K.Satomura ADD START ******************************--
  cv_tkn_column_name        CONSTANT   VARCHAR2(50) :=  'COLMUN';            -- ��
--****************************** 2009/09/28 1.6 K.Satomura ADD END   ******************************--
  --* -------------------------------------------------------------------------------------------
  --���b�Z�[�W�p������
  cv_msg_str_profile_name   CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12155';  -- �v���t�@�C����
  cv_msg_edi_deli_work      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12156';  -- EDI�[�i�ԕi��񃏁[�N�e�[�u��
  cv_msg_edi_headers        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12157';  -- EDI�w�b�_���e�[�u��
  cv_msg_edi_lines          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12158';  -- EDI���׏��e�[�u��
  cv_msg_mtl_cust_items     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12159';  -- �ڋq�i��
  cv_msg_shop_code          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12160';  -- �X�R�[�h
  cv_msg_class_name1        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12161';  -- ���s�敪�F�u�V�K�v
  cv_msg_class_name2        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12162';  -- ���s�敪�F�u�Ď��{�v
  cv_msg_class_name3        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12163';  -- ���s�敪�F�u�G���[�v
  cv_msg_data_type_code     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12164';  -- �f�[�^��R�[�h�F�u�ԕi�m��v
  cv_msg_sum_order_qty      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12165';  -- �������ʁi���v�A�o���j
  cv_msg_jan_code           CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12166';  -- JAN�R�[�h
  cv_msg_none               CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12167';  -- �Ȃ�
  --�g�[�N�� �v���t�@�C��
  cv_msg_in_file_name1      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12172';  -- �C���^�[�t�F�[�X�t�@�C����
--****************************** 2009/06/29 1.5 T.Tominaga ADD START ******************************
  cv_data_type_32           CONSTANT   VARCHAR2(10)  := '32';                -- �f�[�^��R�[�h�F�o�Ɋm��
  cv_data_type_33           CONSTANT   VARCHAR2(10)  := '33';                -- �f�[�^��R�[�h�F�ԕi�m��
--****************************** 2009/06/29 1.5 T.Tominaga ADD END   ******************************
  --* -------------------------------------------------------------------------------------------
--****************************** 2009/05/19 1.2 T.Kitajima ADD START ******************************--
  cv_format_yyyymmdd        CONSTANT   VARCHAR2(20)  := 'YYYY/MM/DD';        -- ���t�t�H�[�}�b�g
--****************************** 2009/05/19 1.2 T.Kitajima ADD  END  ******************************--
-- ************** 2009/07/22 N.Maeda ADD START ****************** --
  cv_date_time              CONSTANT   VARCHAR2(25)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_time                   CONSTANT   VARCHAR2(25)  := '23:59:59';
  cv_space                  CONSTANT   VARCHAR2(1)   := ' ';
-- ************** 2009/07/22 N.Maeda ADD  END  ****************** --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_status_work_warn        VARCHAR2(1) DEFAULT xxccp_common_pkg.set_status_normal;
  gv_status_work_err         VARCHAR2(1) DEFAULT xxccp_common_pkg.set_status_normal;
--
  --�g�[�N�� �v���t�@�C��
  gv_in_file_name            VARCHAR2(50) DEFAULT NULL;     -- �C���^�[�t�F�[�X�t�@�C����
  gv_in_param                VARCHAR2(50) DEFAULT NULL;     -- ���s�敪
  gv_prf_edi_del_date0       VARCHAR2(50) DEFAULT NULL;     -- EDI���폜����
  gv_prf_case_code0          VARCHAR2(50) DEFAULT NULL;     -- �P�[�X�P�ʃR�[�h
  gv_prf_orga_code0          VARCHAR2(50) DEFAULT NULL;     -- �݌ɑg�D�R�[�h
--
  -- �e�[�u����`����
  gv_tkn_edi_deli_work       VARCHAR2(50);     -- EDI�[�i�ԕi��񃏁[�N�e�[�u��
  gv_tkn_edi_headers         VARCHAR2(50);     -- EDI�w�b�_���e�[�u��
  gv_tkn_edi_lines           VARCHAR2(50);     -- EDI���׏��e�[�u��
  gv_tkn_mtl_cust_items      VARCHAR2(50);     -- �ڋq�i��
  gv_tkn_shop_code           VARCHAR2(50);     -- �X�R�[�h
  gv_msg_tkn_org_id          VARCHAR2(50);     -- MO:�c�ƒP��
  gv_sum_order_qty           VARCHAR2(50);     -- �������ʁi���v�A�o���j
  gv_jan_code                VARCHAR2(10);     -- JAN�R�[�h
  gn_org_id                  NUMBER;           -- MO:�c�ƒP��
  gv_none                    VARCHAR2(10);     -- �Ȃ�
  gv_run_class_name01        VARCHAR2(50) DEFAULT NULL; -- ���s�敪�F�u�V�K�v����
  gv_run_class_name02        VARCHAR2(50) DEFAULT NULL; -- ���s�敪�F�u�Ď��{�v����
  gv_run_class_name1         VARCHAR2(2)  DEFAULT NULL; -- ���s�敪�F�u�V�K�v
  gv_run_class_name2         VARCHAR2(2)  DEFAULT NULL; -- ���s�敪�F�u�Ď��{�v
  gv_run_class_name3         VARCHAR2(2)  DEFAULT NULL; -- ���s�敪�F�u�G���[�v
  gv_run_data_type_code      VARCHAR2(50) DEFAULT NULL; -- �f�[�^��R�[�h�F�u�ԕi�m��v
  gn_normal_headers_cnt      NUMBER DEFAULT 0; -- ���팏��(headers)
  gn_normal_lines_cnt        NUMBER DEFAULT 0; -- ���팏��(lines)
  -- �`�[�ԍ�
  gv_invoice_number          VARCHAR2(12) DEFAULT NULL;
--
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
  gn_msg_cnt                 NUMBER;                        -- ���b�Z�[�W����
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
-- ************** 2009/07/22 N.Maeda ADD START ****************** --
  gd_edi_del_consider_date   DATE;             -- EDI���폜���ԍl�����t�쐬
-- ************** 2009/07/22 N.Maeda ADD  END  ****************** --
-- ************** 2009/09/28 1.6 K.Satomura ADD START ****************** --
  gt_dummy_item_number     mtl_system_items_b.segment1%TYPE;
  gt_dummy_unit_of_measure mtl_system_items_b.primary_unit_of_measure%TYPE;
-- ************** 2009/09/28 1.6 K.Satomura ADD END   ****************** --
  --
  --* -------------------------------------------------------------------------------------------
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- EDI�[�i�ԕi��񃏁[�N�e�[�u���f�[�^�i�[�p�ϐ�(xxcos_edi_delivery_work)
  TYPE g_rec_edideli_work_data IS RECORD(
                -- �[�i�ԕi���[�NID
      delivery_return_work_id      xxcos_edi_delivery_work.delivery_return_work_id%TYPE,
                -- �}�̋敪
      medium_class                 xxcos_edi_delivery_work.medium_class%TYPE,
                -- �f�[�^��R�[�h
      data_type_code               xxcos_edi_delivery_work.data_type_code%TYPE,
                -- �t�@�C���m��
      file_no                      xxcos_edi_delivery_work.file_no%TYPE,
                -- ���敪
      info_class                   xxcos_edi_delivery_work.info_class%TYPE,
                -- ������
      process_date                 xxcos_edi_delivery_work.process_date%TYPE,
                -- ��������
      process_time                 xxcos_edi_delivery_work.process_time%TYPE,
                -- ���_�i����j�R�[�h
      base_code                    xxcos_edi_delivery_work.base_code%TYPE,
                -- ���_���i�������j
      base_name                    xxcos_edi_delivery_work.base_name%TYPE,
                -- ���_���i�J�i�j
      base_name_alt                xxcos_edi_delivery_work.base_name_alt%TYPE,
                -- �d�c�h�`�F�[���X�R�[�h
      edi_chain_code               xxcos_edi_delivery_work.edi_chain_code%TYPE,
                -- �d�c�h�`�F�[���X���i�����j
      edi_chain_name               xxcos_edi_delivery_work.edi_chain_name%TYPE,
                -- �d�c�h�`�F�[���X���i�J�i�j
      edi_chain_name_alt           xxcos_edi_delivery_work.edi_chain_name_alt%TYPE,
                -- �`�F�[���X�R�[�h
      chain_code                   xxcos_edi_delivery_work.chain_code%TYPE,
                -- �`�F�[���X���i�����j
      chain_name                   xxcos_edi_delivery_work.chain_name%TYPE,
                -- �`�F�[���X���i�J�i�j
      chain_name_alt               xxcos_edi_delivery_work.chain_name_alt%TYPE,
                -- ���[�R�[�h
      report_code                  xxcos_edi_delivery_work.report_code%TYPE,
                -- ���[�\����
      report_show_name             xxcos_edi_delivery_work.report_show_name%TYPE,
                -- �ڋq�R�[�h
      customer_code                xxcos_edi_delivery_work.customer_code%TYPE,
                -- �ڋq���i�����j
      customer_name                xxcos_edi_delivery_work.customer_name%TYPE,
                -- �ڋq���i�J�i�j
      customer_name_alt            xxcos_edi_delivery_work.customer_name_alt%TYPE,
                -- �ЃR�[�h
      company_code                 xxcos_edi_delivery_work.company_code%TYPE,
                -- �Ж��i�����j
      company_name                 xxcos_edi_delivery_work.company_name%TYPE,
                -- �Ж��i�J�i�j
      company_name_alt             xxcos_edi_delivery_work.company_name_alt%TYPE,
                -- �X�R�[�h
      shop_code                    xxcos_edi_delivery_work.shop_code%TYPE,
                -- �X���i�����j
      shop_name                    xxcos_edi_delivery_work.shop_name%TYPE,
                -- �X���i�J�i�j
      shop_name_alt                xxcos_edi_delivery_work.shop_name_alt%TYPE,
                -- �[���Z���^�[�R�[�h
      delivery_center_code         xxcos_edi_delivery_work.delivery_center_code%TYPE,
                -- �[���Z���^�[���i�����j
      delivery_center_name         xxcos_edi_delivery_work.delivery_center_name%TYPE,
                -- �[���Z���^�[���i�J�i�j
      delivery_center_name_alt     xxcos_edi_delivery_work.delivery_center_name_alt%TYPE,
                -- ������
      order_date                   xxcos_edi_delivery_work.order_date%TYPE,
                -- �Z���^�[�[�i��
      center_delivery_date         xxcos_edi_delivery_work.center_delivery_date%TYPE,
                -- ���[�i��
      result_delivery_date         xxcos_edi_delivery_work.result_delivery_date%TYPE,
                -- �X�ܔ[�i��
      shop_delivery_date           xxcos_edi_delivery_work.shop_delivery_date%TYPE,
                -- �f�[�^�쐬���i�d�c�h�f�[�^���j
      data_creation_date_edi_data  xxcos_edi_delivery_work.data_creation_date_edi_data%TYPE,
                -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
      data_creation_time_edi_data  xxcos_edi_delivery_work.data_creation_time_edi_data%TYPE,
                -- �`�[�敪
      invoice_class                xxcos_edi_delivery_work.invoice_class%TYPE,
                -- �����ރR�[�h
      small_classification_code    xxcos_edi_delivery_work.small_classification_code%TYPE,
                -- �����ޖ�
      small_classification_name    xxcos_edi_delivery_work.small_classification_name%TYPE,
                -- �����ރR�[�h
      middle_classification_code   xxcos_edi_delivery_work.middle_classification_code%TYPE,
                -- �����ޖ�
      middle_classification_name   xxcos_edi_delivery_work.middle_classification_name%TYPE,
                -- �啪�ރR�[�h
      big_classification_code      xxcos_edi_delivery_work.big_classification_code%TYPE,
                -- �啪�ޖ�
      big_classification_name      xxcos_edi_delivery_work.big_classification_name%TYPE,
                -- ����敔��R�[�h
      other_party_department_code  xxcos_edi_delivery_work.other_party_department_code%TYPE,
                -- ����攭���ԍ�
      other_party_order_number     xxcos_edi_delivery_work.other_party_order_number%TYPE,
                -- �`�F�b�N�f�W�b�g�L���敪
      check_digit_class            xxcos_edi_delivery_work.check_digit_class%TYPE,
                -- �`�[�ԍ�
      invoice_number               xxcos_edi_delivery_work.invoice_number%TYPE,
                -- �`�F�b�N�f�W�b�g
      check_digit                  xxcos_edi_delivery_work.check_digit%TYPE,
                -- ����
      close_date                   xxcos_edi_delivery_work.close_date%TYPE,
                -- �󒍂m���i�d�a�r�j
      order_no_ebs                 xxcos_edi_delivery_work.order_no_ebs%TYPE,
                -- �����敪
      ar_sale_class                xxcos_edi_delivery_work.ar_sale_class%TYPE,
                -- �z���敪
      delivery_classe              xxcos_edi_delivery_work.delivery_classe%TYPE,
                -- �ւm��
      opportunity_no               xxcos_edi_delivery_work.opportunity_no%TYPE,
                -- �A����
      contact_to                   xxcos_edi_delivery_work.contact_to%TYPE,
                -- ���[�g�Z�[���X
      route_sales                  xxcos_edi_delivery_work.route_sales%TYPE,
                -- �@�l�R�[�h
      corporate_code               xxcos_edi_delivery_work.corporate_code%TYPE,
                -- ���[�J�[��
      maker_name                   xxcos_edi_delivery_work.maker_name%TYPE,
                -- �n��R�[�h
      area_code                    xxcos_edi_delivery_work.area_code%TYPE,
                -- �n�於�i�����j
      area_name                    xxcos_edi_delivery_work.area_name%TYPE,
                -- �n�於�i�J�i�j
      area_name_alt                xxcos_edi_delivery_work.area_name_alt%TYPE,
                -- �����R�[�h
      vendor_code                  xxcos_edi_delivery_work.vendor_code%TYPE,
                -- ����於�i�����j
      vendor_name                  xxcos_edi_delivery_work.vendor_name%TYPE,
                -- ����於�P�i�J�i�j
      vendor_name1_alt             xxcos_edi_delivery_work.vendor_name1_alt%TYPE,
                -- ����於�Q�i�J�i�j
      vendor_name2_alt             xxcos_edi_delivery_work.vendor_name2_alt%TYPE,
                -- �����s�d�k
      vendor_tel                   xxcos_edi_delivery_work.vendor_tel%TYPE,
                -- �����S����
      vendor_charge                xxcos_edi_delivery_work.vendor_charge%TYPE,
                -- �����Z���i�����j
      vendor_address               xxcos_edi_delivery_work.vendor_address%TYPE,
                -- �͂���R�[�h�i�ɓ����j
      deliver_to_code_itouen       xxcos_edi_delivery_work.deliver_to_code_itouen%TYPE,
                -- �͂���R�[�h�i�`�F�[���X�j
      deliver_to_code_chain        xxcos_edi_delivery_work.deliver_to_code_chain%TYPE,
                -- �͂���i�����j
      deliver_to                   xxcos_edi_delivery_work.deliver_to%TYPE,
                -- �͂���P�i�J�i�j
      deliver_to1_alt              xxcos_edi_delivery_work.deliver_to1_alt%TYPE,
                -- �͂���Q�i�J�i�j
      deliver_to2_alt              xxcos_edi_delivery_work.deliver_to2_alt%TYPE,
                -- �͂���Z���i�����j
      deliver_to_address           xxcos_edi_delivery_work.deliver_to_address%TYPE,
                -- �͂���Z���i�J�i�j
      deliver_to_address_alt       xxcos_edi_delivery_work.deliver_to_address_alt%TYPE,
                -- �͂���s�d�k
      deliver_to_tel               xxcos_edi_delivery_work.deliver_to_tel%TYPE,
                -- ������R�[�h
      balance_accounts_code        xxcos_edi_delivery_work.balance_accounts_code%TYPE,
                -- ������ЃR�[�h
      balance_accounts_company_code xxcos_edi_delivery_work.balance_accounts_company_code%TYPE,
                -- ������X�R�[�h
      balance_accounts_shop_code   xxcos_edi_delivery_work.balance_accounts_shop_code%TYPE,
                -- �����於�i�����j
      balance_accounts_name        xxcos_edi_delivery_work.balance_accounts_name%TYPE,
                -- �����於�i�J�i�j
      balance_accounts_name_alt    xxcos_edi_delivery_work.balance_accounts_name_alt%TYPE,
                -- ������Z���i�����j
      balance_accounts_address     xxcos_edi_delivery_work.balance_accounts_address%TYPE,
                -- ������Z���i�J�i�j
      balance_accounts_address_alt xxcos_edi_delivery_work.balance_accounts_address_alt%TYPE,
                -- ������s�d�k
      balance_accounts_tel         xxcos_edi_delivery_work.balance_accounts_tel%TYPE,
                -- �󒍉\��
      order_possible_date          xxcos_edi_delivery_work.order_possible_date%TYPE,
                -- ���e�\��
      permission_possible_date     xxcos_edi_delivery_work.permission_possible_date%TYPE,
                -- ����N����
      forward_month                xxcos_edi_delivery_work.forward_month%TYPE,
                -- �x�����ϓ�
      payment_settlement_date      xxcos_edi_delivery_work.payment_settlement_date%TYPE,
                -- �`���V�J�n��
      handbill_start_date_active   xxcos_edi_delivery_work.handbill_start_date_active%TYPE,
                -- ��������
      billing_due_date             xxcos_edi_delivery_work.billing_due_date%TYPE,
                -- �o�׎���
      shipping_time                xxcos_edi_delivery_work.shipping_time%TYPE,
                -- �[�i�\�莞��
      delivery_schedule_time       xxcos_edi_delivery_work.delivery_schedule_time%TYPE,
                -- ��������
      order_time                   xxcos_edi_delivery_work.order_time%TYPE,
                -- �ėp���t���ڂP
      general_date_item1           xxcos_edi_delivery_work.general_date_item1%TYPE,
                -- �ėp���t���ڂQ
      general_date_item2           xxcos_edi_delivery_work.general_date_item2%TYPE,
                -- �ėp���t���ڂR
      general_date_item3           xxcos_edi_delivery_work.general_date_item3%TYPE,
                -- �ėp���t���ڂS
      general_date_item4           xxcos_edi_delivery_work.general_date_item4%TYPE,
                -- �ėp���t���ڂT
      general_date_item5           xxcos_edi_delivery_work.general_date_item5%TYPE,
                -- ���o�׋敪
      arrival_shipping_class       xxcos_edi_delivery_work.arrival_shipping_class%TYPE,
                -- �����敪
      vendor_class                 xxcos_edi_delivery_work.vendor_class%TYPE,
                -- �`�[����敪
      invoice_detailed_class       xxcos_edi_delivery_work.invoice_detailed_class%TYPE,
                -- �P���g�p�敪
      unit_price_use_class         xxcos_edi_delivery_work.unit_price_use_class%TYPE,
                -- �T�u�����Z���^�[�R�[�h
      sub_distribution_center_code xxcos_edi_delivery_work.sub_distribution_center_code%TYPE,
                -- �T�u�����Z���^�[�R�[�h��
      sub_distribution_center_name xxcos_edi_delivery_work.sub_distribution_center_name%TYPE,
                -- �Z���^�[�[�i���@
      center_delivery_method       xxcos_edi_delivery_work.center_delivery_method%TYPE,
                -- �Z���^�[���p�敪
      center_use_class             xxcos_edi_delivery_work.center_use_class%TYPE,
                -- �Z���^�[�q�ɋ敪
      center_whse_class            xxcos_edi_delivery_work.center_whse_class%TYPE,
                -- �Z���^�[�n��敪
      center_area_class            xxcos_edi_delivery_work.center_area_class%TYPE,
                -- �Z���^�[���׋敪
      center_arrival_class         xxcos_edi_delivery_work.center_arrival_class%TYPE,
                -- �f�|�敪
      depot_class                  xxcos_edi_delivery_work.depot_class%TYPE,
                -- �s�b�c�b�敪
      tcdc_class                   xxcos_edi_delivery_work.tcdc_class%TYPE,
                -- �t�o�b�t���O
      upc_flag                     xxcos_edi_delivery_work.upc_flag%TYPE,
                -- ��ċ敪
      simultaneously_class         xxcos_edi_delivery_work.simultaneously_class%TYPE,
                -- �Ɩ��h�c
      business_id                  xxcos_edi_delivery_work.business_id%TYPE,
                -- �q���敪
      whse_directly_class          xxcos_edi_delivery_work.whse_directly_class%TYPE,
                -- �i�i���ߋ敪
      premium_rebate_class         xxcos_edi_delivery_work.premium_rebate_class%TYPE,
                -- ���ڎ��
      item_type                    xxcos_edi_delivery_work.item_type%TYPE,
                -- �߉ƐH�敪
      cloth_house_food_class       xxcos_edi_delivery_work.cloth_house_food_class%TYPE,
                -- ���݋敪
      mix_class                    xxcos_edi_delivery_work.mix_class%TYPE,
                -- �݌ɋ敪
      stk_class                    xxcos_edi_delivery_work.stk_class%TYPE,
                -- �ŏI�C���ꏊ�敪
      last_modify_site_class       xxcos_edi_delivery_work.last_modify_site_class%TYPE,
                -- ���[�敪
      report_class                 xxcos_edi_delivery_work.report_class%TYPE,
                -- �ǉ��E�v��敪
      addition_plan_class          xxcos_edi_delivery_work.addition_plan_class%TYPE,
                -- �o�^�敪
      registration_class           xxcos_edi_delivery_work.registration_class%TYPE,
                -- ����敪
      specific_class               xxcos_edi_delivery_work.specific_class%TYPE,
                -- ����敪
      dealings_class               xxcos_edi_delivery_work.dealings_class%TYPE,
                -- �����敪
      order_class                  xxcos_edi_delivery_work.order_class%TYPE,
                -- �W�v���׋敪
      sum_line_class               xxcos_edi_delivery_work.sum_line_class%TYPE,
                -- �o�׈ē��ȊO�敪
      shipping_guidance_class      xxcos_edi_delivery_work.shipping_guidance_class%TYPE,
                -- �o�׋敪
      shipping_class               xxcos_edi_delivery_work.shipping_class%TYPE,
                -- ���i�R�[�h�g�p�敪
      product_code_use_class       xxcos_edi_delivery_work.product_code_use_class%TYPE,
                -- �ϑ��i�敪
      cargo_item_class             xxcos_edi_delivery_work.cargo_item_class%TYPE,
                -- �s�^�`�敪
      ta_class                     xxcos_edi_delivery_work.ta_class%TYPE,
                -- ���R�[�h
      plan_code                    xxcos_edi_delivery_work.plan_code%TYPE,
                -- �J�e�S���[�R�[�h
      category_code                xxcos_edi_delivery_work.category_code%TYPE,
                -- �J�e�S���[�敪
      category_class               xxcos_edi_delivery_work.category_class%TYPE,
                -- �^����i
      carrier_means                xxcos_edi_delivery_work.carrier_means%TYPE,
                -- ����R�[�h
      counter_code                 xxcos_edi_delivery_work.counter_code%TYPE,
                -- �ړ��T�C��
      move_sign                    xxcos_edi_delivery_work.move_sign%TYPE,
                -- �d�n�r�E�菑�敪
      eos_handwriting_class        xxcos_edi_delivery_work.eos_handwriting_class%TYPE,
                -- �[�i��ۃR�[�h
      delivery_to_section_code     xxcos_edi_delivery_work.delivery_to_section_code%TYPE,
                -- �`�[����
      invoice_detailed             xxcos_edi_delivery_work.invoice_detailed%TYPE,
                -- �Y�t��
      attach_qty                   xxcos_edi_delivery_work.attach_qty%TYPE,
                -- �t���A
      other_party_floor            xxcos_edi_delivery_work.other_party_floor%TYPE,
                -- �s�d�w�s�m��
      text_no                      xxcos_edi_delivery_work.text_no%TYPE,
                -- �C���X�g�A�R�[�h
      in_store_code                xxcos_edi_delivery_work.in_store_code%TYPE,
                -- �^�O
      tag_data                     xxcos_edi_delivery_work.tag_data%TYPE,
                -- ����
      competition_code             xxcos_edi_delivery_work.competition_code%TYPE,
                -- ��������
      billing_chair                xxcos_edi_delivery_work.billing_chair%TYPE,
                -- �`�F�[���X�g�A�[�R�[�h
      chain_store_code             xxcos_edi_delivery_work.chain_store_code%TYPE,
                -- �`�F�[���X�g�A�[�R�[�h��������
      chain_store_short_name       xxcos_edi_delivery_work.chain_store_short_name%TYPE,
                -- ���z���^���旿
      direct_delivery_rcpt_fee     xxcos_edi_delivery_work.direct_delivery_rcpt_fee%TYPE,
                -- ��`���
      bill_info                    xxcos_edi_delivery_work.bill_info%TYPE,
                -- �E�v
      description                  xxcos_edi_delivery_work.description%TYPE,
                -- �����R�[�h
      interior_code                xxcos_edi_delivery_work.interior_code%TYPE,
                -- �������@�[�i�J�e�S���[
      order_info_delivery_category xxcos_edi_delivery_work.order_info_delivery_category%TYPE,
                -- �d���`��
      purchase_type                xxcos_edi_delivery_work.purchase_type%TYPE,
                -- �[�i�ꏊ���i�J�i�j
      delivery_to_name_alt         xxcos_edi_delivery_work.delivery_to_name_alt%TYPE,
                -- �X�o�ꏊ
      shop_opened_site             xxcos_edi_delivery_work.shop_opened_site%TYPE,
                -- ���ꖼ
      counter_name                 xxcos_edi_delivery_work.counter_name%TYPE,
                -- �����ԍ�
      extension_number             xxcos_edi_delivery_work.extension_number%TYPE,
                -- �S���Җ�
      charge_name                  xxcos_edi_delivery_work.charge_name%TYPE,
                -- �l�D
      price_tag                    xxcos_edi_delivery_work.price_tag%TYPE,
                -- �Ŏ�
      tax_type                     xxcos_edi_delivery_work.tax_type%TYPE,
                -- ����ŋ敪
      consumption_tax_class        xxcos_edi_delivery_work.consumption_tax_class%TYPE,
                -- �a�q
      brand_class                  xxcos_edi_delivery_work.brand_class%TYPE,
                -- �h�c�R�[�h
      id_code                      xxcos_edi_delivery_work.id_code%TYPE,
                -- �S�ݓX�R�[�h
      department_code              xxcos_edi_delivery_work.department_code%TYPE,
                -- �S�ݓX��
      department_name              xxcos_edi_delivery_work.department_name%TYPE,
                -- �i�ʔԍ�
      item_type_number             xxcos_edi_delivery_work.item_type_number%TYPE,
                -- �E�v�i�S�ݓX�j
      description_department       xxcos_edi_delivery_work.description_department%TYPE,
                -- �l�D���@
      price_tag_method             xxcos_edi_delivery_work.price_tag_method%TYPE,
                -- ���R��
      reason_column                xxcos_edi_delivery_work.reason_column%TYPE,
                -- �`���w�b�_
      a_column_header              xxcos_edi_delivery_work.a_column_header%TYPE,
                -- �c���w�b�_
      d_column_header              xxcos_edi_delivery_work.d_column_header%TYPE,
                -- �u�����h�R�[�h
      brand_code                   xxcos_edi_delivery_work.brand_code%TYPE,
                -- ���C���R�[�h
      line_code                    xxcos_edi_delivery_work.line_code%TYPE,
                -- �N���X�R�[�h
      class_code                   xxcos_edi_delivery_work.class_code%TYPE,
                -- �`�|�P��
      a1_column                    xxcos_edi_delivery_work.a1_column%TYPE,
                -- �a�|�P��
      b1_column                    xxcos_edi_delivery_work.b1_column%TYPE,
                -- �b�|�P��
      c1_column                    xxcos_edi_delivery_work.c1_column%TYPE,
                -- �c�|�P��
      d1_column                    xxcos_edi_delivery_work.d1_column%TYPE,
                -- �d�|�P��
      e1_column                    xxcos_edi_delivery_work.e1_column%TYPE,
                -- �`�|�Q��
      a2_column                    xxcos_edi_delivery_work.a2_column%TYPE,
                -- �a�|�Q��
      b2_column                    xxcos_edi_delivery_work.b2_column%TYPE,
                -- �b�|�Q��
      c2_column                    xxcos_edi_delivery_work.c2_column%TYPE,
                -- �c�|�Q��
      d2_column                    xxcos_edi_delivery_work.d2_column%TYPE,
                -- �d�|�Q��
      e2_column                    xxcos_edi_delivery_work.e2_column%TYPE,
                -- �`�|�R��
      a3_column                    xxcos_edi_delivery_work.a3_column%TYPE,
                -- �a�|�R��
      b3_column                    xxcos_edi_delivery_work.b3_column%TYPE,
                -- �b�|�R��
      c3_column                    xxcos_edi_delivery_work.c3_column%TYPE,
                -- �c�|�R��
      d3_column                    xxcos_edi_delivery_work.d3_column%TYPE,
                -- �d�|�R��
      e3_column                    xxcos_edi_delivery_work.e3_column%TYPE,
                -- �e�|�P��
      f1_column                    xxcos_edi_delivery_work.f1_column%TYPE,
                -- �f�|�P��
      g1_column                    xxcos_edi_delivery_work.g1_column%TYPE,
                -- �g�|�P��
      h1_column                    xxcos_edi_delivery_work.h1_column%TYPE,
                -- �h�|�P��
      i1_column                    xxcos_edi_delivery_work.i1_column%TYPE,
                -- �i�|�P��
      j1_column                    xxcos_edi_delivery_work.j1_column%TYPE,
                -- �j�|�P��
      k1_column                    xxcos_edi_delivery_work.k1_column%TYPE,
                -- �k�|�P��
      l1_column                    xxcos_edi_delivery_work.l1_column%TYPE,
                -- �e�|�Q��
      f2_column                    xxcos_edi_delivery_work.f2_column%TYPE,
                -- �f�|�Q��
      g2_column                    xxcos_edi_delivery_work.g2_column%TYPE,
                -- �g�|�Q��
      h2_column                    xxcos_edi_delivery_work.h2_column%TYPE,
                -- �h�|�Q��
      i2_column                    xxcos_edi_delivery_work.i2_column%TYPE,
                -- �i�|�Q��
      j2_column                    xxcos_edi_delivery_work.j2_column%TYPE,
                -- �j�|�Q��
      k2_column                    xxcos_edi_delivery_work.k2_column%TYPE,
                -- �k�|�Q��
      l2_column                    xxcos_edi_delivery_work.l2_column%TYPE,
                -- �e�|�R��
      f3_column                    xxcos_edi_delivery_work.f3_column%TYPE,
                -- �f�|�R��
      g3_column                    xxcos_edi_delivery_work.g3_column%TYPE,
                -- �g�|�R��
      h3_column                    xxcos_edi_delivery_work.h3_column%TYPE,
                -- �h�|�R��
      i3_column                    xxcos_edi_delivery_work.i3_column%TYPE,
                -- �i�|�R��
      j3_column                    xxcos_edi_delivery_work.j3_column%TYPE,
                -- �j�|�R��
      k3_column                    xxcos_edi_delivery_work.k3_column%TYPE,
                -- �k�|�R��
      l3_column                    xxcos_edi_delivery_work.l3_column%TYPE,
                -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
      chain_peculiar_area_header   xxcos_edi_delivery_work.chain_peculiar_area_header%TYPE,
                -- �󒍊֘A�ԍ��i���j
      order_connection_number      xxcos_edi_delivery_work.order_connection_number%TYPE,
                -- �s�m��
      line_no                      xxcos_edi_delivery_work.line_no%TYPE,
                -- ���i�敪
      stockout_class               xxcos_edi_delivery_work.stockout_class%TYPE,
                -- ���i���R
      stockout_reason              xxcos_edi_delivery_work.stockout_reason%TYPE,
                -- ���i�R�[�h�i�ɓ����j
      product_code_itouen          xxcos_edi_delivery_work.product_code_itouen%TYPE,
                -- ���i�R�[�h�P
      product_code1                xxcos_edi_delivery_work.product_code1%TYPE,
                -- ���i�R�[�h�Q
      product_code2                xxcos_edi_delivery_work.product_code2%TYPE,
                -- �i�`�m�R�[�h
      jan_code                     xxcos_edi_delivery_work.jan_code%TYPE,
                -- �h�s�e�R�[�h
      itf_code                     xxcos_edi_delivery_work.itf_code%TYPE,
                -- �����h�s�e�R�[�h
      extension_itf_code           xxcos_edi_delivery_work.extension_itf_code%TYPE,
                -- �P�[�X���i�R�[�h
      case_product_code            xxcos_edi_delivery_work.case_product_code%TYPE,
                -- �{�[�����i�R�[�h
      ball_product_code            xxcos_edi_delivery_work.ball_product_code%TYPE,
                -- ���i�R�[�h�i��
      product_code_item_type       xxcos_edi_delivery_work.product_code_item_type%TYPE,
                -- ���i�敪
      prod_class                   xxcos_edi_delivery_work.prod_class%TYPE,
                -- ���i���i�����j
      product_name                 xxcos_edi_delivery_work.product_name%TYPE,
                -- ���i���P�i�J�i�j
      product_name1_alt            xxcos_edi_delivery_work.product_name1_alt%TYPE,
                -- ���i���Q�i�J�i�j
      product_name2_alt            xxcos_edi_delivery_work.product_name2_alt%TYPE,
                -- �K�i�P
      item_standard1               xxcos_edi_delivery_work.item_standard1%TYPE,
                -- �K�i�Q
      item_standard2               xxcos_edi_delivery_work.item_standard2%TYPE,
                -- ����
      qty_in_case                  xxcos_edi_delivery_work.qty_in_case%TYPE,
                -- �P�[�X����
      num_of_cases                 xxcos_edi_delivery_work.num_of_cases%TYPE,
                -- �{�[������
      num_of_ball                  xxcos_edi_delivery_work.num_of_ball%TYPE,
                -- �F
      item_color                   xxcos_edi_delivery_work.item_color%TYPE,
                -- �T�C�Y
      item_size                    xxcos_edi_delivery_work.item_size%TYPE,
                -- �ܖ�������
      expiration_date              xxcos_edi_delivery_work.expiration_date%TYPE,
                -- ������
      product_date                 xxcos_edi_delivery_work.product_date%TYPE,
                -- �����P�ʐ�
      order_uom_qty                xxcos_edi_delivery_work.order_uom_qty%TYPE,
                -- �o�גP�ʐ�
      shipping_uom_qty             xxcos_edi_delivery_work.shipping_uom_qty%TYPE,
                -- ����P�ʐ�
      packing_uom_qty              xxcos_edi_delivery_work.packing_uom_qty%TYPE,
                -- ����
      deal_code                    xxcos_edi_delivery_work.deal_code%TYPE,
                -- �����敪
      deal_class                   xxcos_edi_delivery_work.deal_class%TYPE,
                -- �ƍ�
      collation_code               xxcos_edi_delivery_work.collation_code%TYPE,
                -- �P��
      uom_code                     xxcos_edi_delivery_work.uom_code%TYPE,
                -- �P���敪
      unit_price_class             xxcos_edi_delivery_work.unit_price_class%TYPE,
                -- �e����ԍ�
      parent_packing_number        xxcos_edi_delivery_work.parent_packing_number%TYPE,
                -- ����ԍ�
      packing_number               xxcos_edi_delivery_work.packing_number%TYPE,
                -- ���i�Q�R�[�h
      product_group_code           xxcos_edi_delivery_work.product_group_code%TYPE,
                -- �P�[�X��̕s�t���O
      case_dismantle_flag          xxcos_edi_delivery_work.case_dismantle_flag%TYPE,
                -- �P�[�X�敪
      case_class                   xxcos_edi_delivery_work.case_class%TYPE,
                -- �������ʁi�o���j
      indv_order_qty               xxcos_edi_delivery_work.indv_order_qty%TYPE,
                -- �������ʁi�P�[�X�j
      case_order_qty               xxcos_edi_delivery_work.case_order_qty%TYPE,
                -- �������ʁi�{�[���j
      ball_order_qty               xxcos_edi_delivery_work.ball_order_qty%TYPE,
                -- �������ʁi���v�A�o���j
      sum_order_qty                xxcos_edi_delivery_work.sum_order_qty%TYPE,
                -- �o�א��ʁi�o���j
      indv_shipping_qty            xxcos_edi_delivery_work.indv_shipping_qty%TYPE,
                -- �o�א��ʁi�P�[�X�j
      case_shipping_qty            xxcos_edi_delivery_work.case_shipping_qty%TYPE,
                -- �o�א��ʁi�{�[���j
      ball_shipping_qty            xxcos_edi_delivery_work.ball_shipping_qty%TYPE,
                -- �o�א��ʁi�p���b�g�j
      pallet_shipping_qty          xxcos_edi_delivery_work.pallet_shipping_qty%TYPE,
                -- �o�א��ʁi���v�A�o���j
      sum_shipping_qty             xxcos_edi_delivery_work.sum_shipping_qty%TYPE,
                -- ���i���ʁi�o���j
      indv_stockout_qty            xxcos_edi_delivery_work.indv_stockout_qty%TYPE,
                -- ���i���ʁi�P�[�X�j
      case_stockout_qty            xxcos_edi_delivery_work.case_stockout_qty%TYPE,
                -- ���i���ʁi�{�[���j
      ball_stockout_qty            xxcos_edi_delivery_work.ball_stockout_qty%TYPE,
                -- ���i���ʁi���v�A�o���j
      sum_stockout_qty             xxcos_edi_delivery_work.sum_stockout_qty%TYPE,
                -- �P�[�X����
      case_qty                     xxcos_edi_delivery_work.case_qty%TYPE,
                -- �I���R���i�o���j����
      fold_container_indv_qty      xxcos_edi_delivery_work.fold_container_indv_qty%TYPE,
                -- ���P���i�����j
      order_unit_price             xxcos_edi_delivery_work.order_unit_price%TYPE,
                -- ���P���i�o�ׁj
      shipping_unit_price          xxcos_edi_delivery_work.shipping_unit_price%TYPE,
                -- �������z�i�����j
      order_cost_amt               xxcos_edi_delivery_work.order_cost_amt%TYPE,
                -- �������z�i�o�ׁj
      shipping_cost_amt            xxcos_edi_delivery_work.shipping_cost_amt%TYPE,
                -- �������z�i���i�j
      stockout_cost_amt            xxcos_edi_delivery_work.stockout_cost_amt%TYPE,
                -- ���P��
      selling_price                xxcos_edi_delivery_work.selling_price%TYPE,
                -- �������z�i�����j
      order_price_amt              xxcos_edi_delivery_work.order_price_amt%TYPE,
                -- �������z�i�o�ׁj
      shipping_price_amt           xxcos_edi_delivery_work.shipping_price_amt%TYPE,
                -- �������z�i���i�j
      stockout_price_amt           xxcos_edi_delivery_work.stockout_price_amt%TYPE,
                -- �`���i�S�ݓX�j
      a_column_department          xxcos_edi_delivery_work.a_column_department%TYPE,
                -- �c���i�S�ݓX�j
      d_column_department          xxcos_edi_delivery_work.d_column_department%TYPE,
                -- �K�i���E���s��
      standard_info_depth          xxcos_edi_delivery_work.standard_info_depth%TYPE,
                -- �K�i���E����
      standard_info_height         xxcos_edi_delivery_work.standard_info_height%TYPE,
                -- �K�i���E��
      standard_info_width          xxcos_edi_delivery_work.standard_info_width%TYPE,
                -- �K�i���E�d��
      standard_info_weight         xxcos_edi_delivery_work.standard_info_weight%TYPE,
                -- �ėp���p�����ڂP
      general_succeeded_item1      xxcos_edi_delivery_work.general_succeeded_item1%TYPE,
                -- �ėp���p�����ڂQ
      general_succeeded_item2      xxcos_edi_delivery_work.general_succeeded_item2%TYPE,
                -- �ėp���p�����ڂR
      general_succeeded_item3      xxcos_edi_delivery_work.general_succeeded_item3%TYPE,
                -- �ėp���p�����ڂS
      general_succeeded_item4      xxcos_edi_delivery_work.general_succeeded_item4%TYPE,
                -- �ėp���p�����ڂT
      general_succeeded_item5      xxcos_edi_delivery_work.general_succeeded_item5%TYPE,
                -- �ėp���p�����ڂU
      general_succeeded_item6      xxcos_edi_delivery_work.general_succeeded_item6%TYPE,
                -- �ėp���p�����ڂV
      general_succeeded_item7      xxcos_edi_delivery_work.general_succeeded_item7%TYPE,
                -- �ėp���p�����ڂW
      general_succeeded_item8      xxcos_edi_delivery_work.general_succeeded_item8%TYPE,
                -- �ėp���p�����ڂX
      general_succeeded_item9      xxcos_edi_delivery_work.general_succeeded_item9%TYPE,
                -- �ėp���p�����ڂP�O
      general_succeeded_item10     xxcos_edi_delivery_work.general_succeeded_item10%TYPE,
                -- �ėp�t�����ڂP
      general_add_item1            xxcos_edi_delivery_work.general_add_item1%TYPE,
                -- �ėp�t�����ڂQ
      general_add_item2            xxcos_edi_delivery_work.general_add_item2%TYPE,
                -- �ėp�t�����ڂR
      general_add_item3            xxcos_edi_delivery_work.general_add_item3%TYPE,
                -- �ėp�t�����ڂS
      general_add_item4            xxcos_edi_delivery_work.general_add_item4%TYPE,
                -- �ėp�t�����ڂT
      general_add_item5            xxcos_edi_delivery_work.general_add_item5%TYPE,
                -- �ėp�t�����ڂU
      general_add_item6            xxcos_edi_delivery_work.general_add_item6%TYPE,
                -- �ėp�t�����ڂV
      general_add_item7            xxcos_edi_delivery_work.general_add_item7%TYPE,
                -- �ėp�t�����ڂW
      general_add_item8            xxcos_edi_delivery_work.general_add_item8%TYPE,
                -- �ėp�t�����ڂX
      general_add_item9            xxcos_edi_delivery_work.general_add_item9%TYPE,
                -- �ėp�t�����ڂP�O
      general_add_item10           xxcos_edi_delivery_work.general_add_item10%TYPE,
                -- �`�F�[���X�ŗL�G���A�i���ׁj
      chain_peculiar_area_line     xxcos_edi_delivery_work.chain_peculiar_area_line%TYPE,
                -- �i�`�[�v�j�������ʁi�o���j
      invoice_indv_order_qty       xxcos_edi_delivery_work.invoice_indv_order_qty%TYPE,
                -- �i�`�[�v�j�������ʁi�P�[�X�j
      invoice_case_order_qty       xxcos_edi_delivery_work.invoice_case_order_qty%TYPE,
                -- �i�`�[�v�j�������ʁi�{�[���j
      invoice_ball_order_qty       xxcos_edi_delivery_work.invoice_ball_order_qty%TYPE,
                -- �i�`�[�v�j�������ʁi���v�A�o���j
      invoice_sum_order_qty        xxcos_edi_delivery_work.invoice_sum_order_qty%TYPE,
                -- �i�`�[�v�j�o�א��ʁi�o���j
      invoice_indv_shipping_qty    xxcos_edi_delivery_work.invoice_indv_shipping_qty%TYPE,
                -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
      invoice_case_shipping_qty    xxcos_edi_delivery_work.invoice_case_shipping_qty%TYPE,
                -- �i�`�[�v�j�o�א��ʁi�{�[���j
      invoice_ball_shipping_qty    xxcos_edi_delivery_work.invoice_ball_shipping_qty%TYPE,
                -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
      invoice_pallet_shipping_qty  xxcos_edi_delivery_work.invoice_pallet_shipping_qty%TYPE,
                -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
      invoice_sum_shipping_qty     xxcos_edi_delivery_work.invoice_sum_shipping_qty%TYPE,
                -- �i�`�[�v�j���i���ʁi�o���j
      invoice_indv_stockout_qty    xxcos_edi_delivery_work.invoice_indv_stockout_qty%TYPE,
                -- �i�`�[�v�j���i���ʁi�P�[�X�j
      invoice_case_stockout_qty    xxcos_edi_delivery_work.invoice_case_stockout_qty%TYPE,
                -- �i�`�[�v�j���i���ʁi�{�[���j
      invoice_ball_stockout_qty    xxcos_edi_delivery_work.invoice_ball_stockout_qty%TYPE,
                -- �i�`�[�v�j���i���ʁi���v�A�o���j
      invoice_sum_stockout_qty     xxcos_edi_delivery_work.invoice_sum_stockout_qty%TYPE,
                -- �i�`�[�v�j�P�[�X����
      invoice_case_qty             xxcos_edi_delivery_work.invoice_case_qty%TYPE,
                -- �i�`�[�v�j�I���R���i�o���j����
      invoice_fold_container_qty   xxcos_edi_delivery_work.invoice_fold_container_qty%TYPE,
                -- �i�`�[�v�j�������z�i�����j
      invoice_order_cost_amt       xxcos_edi_delivery_work.invoice_order_cost_amt%TYPE,
                -- �i�`�[�v�j�������z�i�o�ׁj
      invoice_shipping_cost_amt    xxcos_edi_delivery_work.invoice_shipping_cost_amt%TYPE,
                -- �i�`�[�v�j�������z�i���i�j
      invoice_stockout_cost_amt    xxcos_edi_delivery_work.invoice_stockout_cost_amt%TYPE,
                -- �i�`�[�v�j�������z�i�����j
      invoice_order_price_amt      xxcos_edi_delivery_work.invoice_order_price_amt%TYPE,
                -- �i�`�[�v�j�������z�i�o�ׁj
      invoice_shipping_price_amt   xxcos_edi_delivery_work.invoice_shipping_price_amt%TYPE,
                -- �i�`�[�v�j�������z�i���i�j
      invoice_stockout_price_amt   xxcos_edi_delivery_work.invoice_stockout_price_amt%TYPE,
                -- �i�����v�j�������ʁi�o���j
      total_indv_order_qty         xxcos_edi_delivery_work.total_indv_order_qty%TYPE,
                -- �i�����v�j�������ʁi�P�[�X�j
      total_case_order_qty         xxcos_edi_delivery_work.total_case_order_qty%TYPE,
                -- �i�����v�j�������ʁi�{�[���j
      total_ball_order_qty         xxcos_edi_delivery_work.total_ball_order_qty%TYPE,
                -- �i�����v�j�������ʁi���v�A�o���j
      total_sum_order_qty          xxcos_edi_delivery_work.total_sum_order_qty%TYPE,
                -- �i�����v�j�o�א��ʁi�o���j
      total_indv_shipping_qty      xxcos_edi_delivery_work.total_indv_shipping_qty%TYPE,
                -- �i�����v�j�o�א��ʁi�P�[�X�j
      total_case_shipping_qty      xxcos_edi_delivery_work.total_case_shipping_qty%TYPE,
                -- �i�����v�j�o�א��ʁi�{�[���j
      total_ball_shipping_qty      xxcos_edi_delivery_work.total_ball_shipping_qty%TYPE,
                -- �i�����v�j�o�א��ʁi�p���b�g�j
      total_pallet_shipping_qty    xxcos_edi_delivery_work.total_pallet_shipping_qty%TYPE,
                -- �i�����v�j�o�א��ʁi���v�A�o���j
      total_sum_shipping_qty       xxcos_edi_delivery_work.total_sum_shipping_qty%TYPE,
                -- �i�����v�j���i���ʁi�o���j
      total_indv_stockout_qty      xxcos_edi_delivery_work.total_indv_stockout_qty%TYPE,
                -- �i�����v�j���i���ʁi�P�[�X�j
      total_case_stockout_qty      xxcos_edi_delivery_work.total_case_stockout_qty%TYPE,
                -- �i�����v�j���i���ʁi�{�[���j
      total_ball_stockout_qty      xxcos_edi_delivery_work.total_ball_stockout_qty%TYPE,
                -- �i�����v�j���i���ʁi���v�A�o���j
      total_sum_stockout_qty       xxcos_edi_delivery_work.total_sum_stockout_qty%TYPE,
                -- �i�����v�j�P�[�X����
      total_case_qty               xxcos_edi_delivery_work.total_case_qty%TYPE,
                -- �i�����v�j�I���R���i�o���j����
      total_fold_container_qty     xxcos_edi_delivery_work.total_fold_container_qty%TYPE,
                -- �i�����v�j�������z�i�����j
      total_order_cost_amt         xxcos_edi_delivery_work.total_order_cost_amt%TYPE,
                -- �i�����v�j�������z�i�o�ׁj
      total_shipping_cost_amt      xxcos_edi_delivery_work.total_shipping_cost_amt%TYPE,
                -- �i�����v�j�������z�i���i�j
      total_stockout_cost_amt      xxcos_edi_delivery_work.total_stockout_cost_amt%TYPE,
                -- �i�����v�j�������z�i�����j
      total_order_price_amt        xxcos_edi_delivery_work.total_order_price_amt%TYPE,
                -- �i�����v�j�������z�i�o�ׁj
      total_shipping_price_amt     xxcos_edi_delivery_work.total_shipping_price_amt%TYPE,
                -- �i�����v�j�������z�i���i�j
      total_stockout_price_amt     xxcos_edi_delivery_work.total_stockout_price_amt%TYPE,
                -- �g�[�^���s��
      total_line_qty               xxcos_edi_delivery_work.total_line_qty%TYPE,
                -- �g�[�^���`�[����
      total_invoice_qty            xxcos_edi_delivery_work.total_invoice_qty%TYPE,
                -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
      chain_peculiar_area_footer   xxcos_edi_delivery_work.chain_peculiar_area_footer%TYPE,
               --�X�e�[�^�X
      err_status                   xxcos_edi_delivery_work.err_status%TYPE,
               -- �C���^�t�F�[�X�t�@�C����
/* 2011/07/26 Ver1.9 Mod Start */
--      if_file_name                 xxcos_edi_delivery_work.if_file_name%TYPE
      if_file_name                 xxcos_edi_delivery_work.if_file_name%TYPE,
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
               -- ���ʂa�l�r�w�b�_�f�[�^
      bms_header_data              xxcos_edi_delivery_work.bms_header_data%TYPE,
               -- ���ʂa�l�r���׃f�[�^
      bms_line_data                xxcos_edi_delivery_work.bms_line_data%TYPE
/* 2011/07/26 Ver1.9 Add End   */
    );
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  TYPE g_tab_edideli_work_data IS TABLE OF g_rec_edideli_work_data INDEX BY PLS_INTEGER;
  -- ===============================
  --  EDI�[�i�ԕi��񃏁[�N�e�[�u��
  -- ===============================
  gt_edideli_work_data                 g_tab_edideli_work_data;
  -- ===============================
  -- �G���[EDI�[�i�ԕi��񃏁[�N���R�[�h�^
  -- ===============================
  TYPE g_rec_err_edi_wk_data_rtype IS RECORD(
                -- �[�i�ԕi���[�NID
      delivery_return_work_id      xxcos_edi_delivery_work.delivery_return_work_id%TYPE,
                --�X�e�[�^�X
      err_status1                  xxcos_edi_delivery_work.err_status%TYPE,
                --�X�e�[�^�X
      err_status2                  xxcos_edi_delivery_work.err_status%TYPE,
                -- ���[�U�[�E�G���[�E���b�Z�[�W
      errmsg1                      VARCHAR2(5000),
                -- ���[�U�[�E�G���[�E���b�Z�[�W
      errmsg2                      VARCHAR2(5000)
    );
  -- ===============================
  -- �G���[EDI�[�i�ԕi��񃏁[�N
  -- ===============================
  TYPE g_rec_err_edi_wk_data_ttype IS TABLE OF g_rec_err_edi_wk_data_rtype INDEX BY BINARY_INTEGER;
  gt_err_edideli_work_data  g_rec_err_edi_wk_data_ttype;
  --
  --
  -- ===============================
  -- �ڋq�f�[�^���R�[�h�^
  -- ===============================
  TYPE g_req_cust_acc_data_rtype IS RECORD(
       account_number    hz_cust_accounts.account_number%TYPE,       -- �ڋq�}�X�^.�ڋq�R�[�h
       price_list_id     hz_cust_site_uses_all.price_list_id%TYPE,   -- ���i�\ID
       chain_store_code  xxcmm_cust_accounts.chain_store_code%TYPE,  -- �`�F�[���X�R�[�h(EDI)
       store_code        xxcmm_cust_accounts.store_code%TYPE,        -- �X�܃R�[�h
       edi_item_code_div xxcmm_cust_accounts.edi_item_code_div%TYPE  -- EDI�A�g�i�ڃR�[�h�敪
    );
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  -- �ڋq�f�[�^ �e�[�u���^
  -- ===============================
  TYPE g_req_cust_acc_data_ttype IS TABLE OF g_req_cust_acc_data_rtype INDEX BY BINARY_INTEGER;
  gt_req_cust_acc_data  g_req_cust_acc_data_ttype;
  --* -------------------------------------------------------------------------------------------
  --* -------------------------------------------------------------------------------------------
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_prf_edi_del_date       VARCHAR2(50) DEFAULT NULL;  -- XXCOS:EDI���폜����
  gv_prf_case_code          VARCHAR2(50) DEFAULT NULL;  -- XXCOS:�P�[�X�P�ʃR�[�h
  gv_prf_orga_code          VARCHAR2(50) DEFAULT NULL;  -- XXCOI:�݌ɑg�D�R�[�h
  gv_prf_orga_id            VARCHAR2(50) DEFAULT NULL;  -- XXCOS:�݌ɑg�DID
  gt_head_invoice_number_key VARCHAR2(12) DEFAULT NULL;  -- �`�[�ԍ�
  gt_edi_header_info_id      NUMBER       DEFAULT 0;     -- EDI�w�b�_���ID
--****************************** 2009/06/29 1.5 T.Tominaga ADD START ******************************
  gt_head_shop_invoice_key  VARCHAR2(50) DEFAULT NULL;  -- �X�R�[�h�E�`�[�ԍ� �u���C�N�p�ϐ�
--****************************** 2009/06/29 1.5 T.Tominaga ADD  END  ******************************
--
  --* -------------------------------------------------------------------------------------------
  -- EDI�w�b�_���e�[�u���f�[�^�o�^�p�ϐ�(xxcos_edi_headers)
  TYPE g_req_edi_headers_data_rtype IS RECORD(
       edi_header_info_id           xxcos_edi_headers.edi_header_info_id%TYPE,   -- EDI�w�b�_���ID
       medium_class                 xxcos_edi_headers.medium_class%TYPE,         -- �}�̋敪
       data_type_code               xxcos_edi_headers.data_type_code%TYPE,       -- �f�[�^��R�[�h
       file_no                      xxcos_edi_headers.file_no%TYPE,              -- �t�@�C���m��
       info_class                   xxcos_edi_headers.info_class%TYPE,           -- ���敪
       process_date                 xxcos_edi_headers.process_date%TYPE,         -- ������
       process_time                 xxcos_edi_headers.process_time%TYPE,         -- ��������
       base_code                    xxcos_edi_headers.base_code%TYPE,            -- ���_�i����j�R�[�h
       base_name                    xxcos_edi_headers.base_name%TYPE,            -- ���_���i�������j
       base_name_alt                xxcos_edi_headers.base_name_alt%TYPE,        -- ���_���i�J�i�j
       edi_chain_code               xxcos_edi_headers.edi_chain_code%TYPE,       -- �d�c�h�`�F�[���X�R�[�h
       edi_chain_name               xxcos_edi_headers.edi_chain_name%TYPE,       -- �d�c�h�`�F�[���X���i�����j
       edi_chain_name_alt           xxcos_edi_headers.edi_chain_name_alt%TYPE,   -- �d�c�h�`�F�[���X���i�J�i�j
       chain_code                   xxcos_edi_headers.chain_code%TYPE,           -- �`�F�[���X�R�[�h
       chain_name                   xxcos_edi_headers.chain_name%TYPE,           -- �`�F�[���X���i�����j
       chain_name_alt               xxcos_edi_headers.chain_name_alt%TYPE,       -- �`�F�[���X���i�J�i�j
       report_code                  xxcos_edi_headers.report_code%TYPE,          -- ���[�R�[�h
       report_show_name             xxcos_edi_headers.report_show_name%TYPE,     -- ���[�\����
       customer_code                xxcos_edi_headers.customer_code%TYPE,        -- �ڋq�R�[�h
       customer_name                xxcos_edi_headers.customer_name%TYPE,        -- �ڋq���i�����j
       customer_name_alt            xxcos_edi_headers.customer_name_alt%TYPE,    -- �ڋq���i�J�i�j
       company_code                 xxcos_edi_headers.company_code%TYPE,         -- �ЃR�[�h
       company_name                 xxcos_edi_headers.company_name%TYPE,         -- �Ж��i�����j
       company_name_alt             xxcos_edi_headers.company_name_alt%TYPE,     -- �Ж��i�J�i�j
       shop_code                    xxcos_edi_headers.shop_code%TYPE,            -- �X�R�[�h
       shop_name                    xxcos_edi_headers.shop_name%TYPE,            -- �X���i�����j
       shop_name_alt                xxcos_edi_headers.shop_name_alt%TYPE,        -- �X���i�J�i�j
                                                                                 -- �[���Z���^�[�R�[�h
       deli_center_code             xxcos_edi_headers.delivery_center_code%TYPE,
                                                                                 -- �[���Z���^�[���i�����j
       deli_center_name             xxcos_edi_headers.delivery_center_name%TYPE,
                                                                                 -- �[���Z���^�[���i�J�i�j
       deli_center_name_alt         xxcos_edi_headers.delivery_center_name_alt%TYPE,
       order_date                   xxcos_edi_headers.order_date%TYPE,           -- ������
                                                                                 -- �Z���^�[�[�i��
       center_delivery_date         xxcos_edi_headers.center_delivery_date%TYPE,
       result_delivery_date         xxcos_edi_headers.result_delivery_date%TYPE, -- ���[�i��
       shop_delivery_date           xxcos_edi_headers.shop_delivery_date%TYPE,   -- �X�ܔ[�i��
                                                                          -- �f�[�^�쐬���i�d�c�h�f�[�^���j
       data_cd_edi_data             xxcos_edi_headers.data_creation_date_edi_data%TYPE,
                                                                          -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
       data_ct_edi_data             xxcos_edi_headers.data_creation_time_edi_data%TYPE,
       invoice_class                xxcos_edi_headers.invoice_class%TYPE,          -- �`�[�敪
                                                                                   -- �����ރR�[�h
       small_class_cd               xxcos_edi_headers.small_classification_code%TYPE,
                                                                                   -- �����ޖ�
       small_class_nm               xxcos_edi_headers.small_classification_name%TYPE,
                                                                                   -- �����ރR�[�h
       mid_class_cd                 xxcos_edi_headers.middle_classification_code%TYPE,
                                                                                   -- �����ޖ�
       mid_class_nm                 xxcos_edi_headers.middle_classification_name%TYPE,
                                                                                   -- �啪�ރR�[�h
       big_class_cd                 xxcos_edi_headers.big_classification_code%TYPE,
                                                                                   -- �啪�ޖ�
       big_class_nm                 xxcos_edi_headers.big_classification_name%TYPE,
                                                                                   -- ����敔��R�[�h
       other_par_dep_cd             xxcos_edi_headers.other_party_department_code%TYPE,
                                                                                   -- ����攭���ԍ�
       other_par_order_num          xxcos_edi_headers.other_party_order_number%TYPE,
                                                                                -- �`�F�b�N�f�W�b�g�L���敪
       check_digit_class            xxcos_edi_headers.check_digit_class%TYPE,
       invoice_number               xxcos_edi_headers.invoice_number%TYPE,       -- �`�[�ԍ�
       check_digit                  xxcos_edi_headers.check_digit%TYPE,          -- �`�F�b�N�f�W�b�g
       close_date                   xxcos_edi_headers.close_date%TYPE,           -- ����
       order_no_ebs                 xxcos_edi_headers.order_no_ebs%TYPE,         -- �󒍂m���i�d�a�r�j
       ar_sale_class                xxcos_edi_headers.ar_sale_class%TYPE,        -- �����敪
       delivery_classe              xxcos_edi_headers.delivery_classe%TYPE,      -- �z���敪
       opportunity_no               xxcos_edi_headers.opportunity_no%TYPE,       -- �ւm��
       contact_to                   xxcos_edi_headers.contact_to%TYPE,           -- �A����
       route_sales                  xxcos_edi_headers.route_sales%TYPE,          -- ���[�g�Z�[���X
       corporate_code               xxcos_edi_headers.corporate_code%TYPE,       -- �@�l�R�[�h
       maker_name                   xxcos_edi_headers.maker_name%TYPE,           -- ���[�J�[��
       area_code                    xxcos_edi_headers.area_code%TYPE,            -- �n��R�[�h
       area_name                    xxcos_edi_headers.area_name%TYPE,            -- �n�於�i�����j
       area_name_alt                xxcos_edi_headers.area_name_alt%TYPE,        -- �n�於�i�J�i�j
       vendor_code                  xxcos_edi_headers.vendor_code%TYPE,          -- �����R�[�h
       vendor_name                  xxcos_edi_headers.vendor_name%TYPE,          -- ����於�i�����j
       vendor_name1_alt             xxcos_edi_headers.vendor_name1_alt%TYPE,     -- ����於�P�i�J�i�j
       vendor_name2_alt             xxcos_edi_headers.vendor_name2_alt%TYPE,     -- ����於�Q�i�J�i�j
       vendor_tel                   xxcos_edi_headers.vendor_tel%TYPE,           -- �����s�d�k
       vendor_charge                xxcos_edi_headers.vendor_charge%TYPE,        -- �����S����
       vendor_address               xxcos_edi_headers.vendor_address%TYPE,       -- �����Z���i�����j
                                                                                   -- �͂���R�[�h�i�ɓ����j
       deli_to_cd_itouen            xxcos_edi_headers.deliver_to_code_itouen%TYPE,
                                                                                   -- �͂���R�[�h�i�`�F�[���X�j
       deli_to_cd_chain             xxcos_edi_headers.deliver_to_code_chain%TYPE,
       deli_to                      xxcos_edi_headers.deliver_to%TYPE,           -- �͂���i�����j
       deli_to1_alt                 xxcos_edi_headers.deliver_to1_alt%TYPE,      -- �͂���P�i�J�i�j
       deli_to2_alt                 xxcos_edi_headers.deliver_to2_alt%TYPE,      -- �͂���Q�i�J�i�j
       deli_to_add                  xxcos_edi_headers.vendor_address%TYPE,       -- �͂���Z���i�����j
       deli_to_add_alt              xxcos_edi_headers.deliver_to_address_alt%TYPE, -- �͂���Z���i�J�i�j
       deli_to_tel                  xxcos_edi_headers.deliver_to_tel%TYPE,       -- �͂���s�d�k
                                                                                   -- ������R�[�h
       bal_accounts_cd              xxcos_edi_headers.balance_accounts_code%TYPE,
                                                                                   -- ������ЃR�[�h
       bal_acc_comp_cd              xxcos_edi_headers.balance_accounts_company_code%TYPE,
                                                                                   -- ������X�R�[�h
       bal_acc_shop_cd              xxcos_edi_headers.balance_accounts_shop_code%TYPE,
                                                                                   -- �����於�i�����j
       bal_acc_name                 xxcos_edi_headers.balance_accounts_name%TYPE,
                                                                                   -- �����於�i�J�i�j
       bal_acc_name_alt             xxcos_edi_headers.balance_accounts_name_alt%TYPE,
                                                                                   -- ������Z���i�����j
       bal_acc_add                  xxcos_edi_headers.balance_accounts_address%TYPE,
                                                                                   -- ������Z���i�J�i�j
       bal_acc_add_alt              xxcos_edi_headers.balance_accounts_address_alt%TYPE,
                                                                                   -- ������s�d�k
       bal_acc_tel                  xxcos_edi_headers.balance_accounts_tel%TYPE,
       order_possible_date          xxcos_edi_headers.order_possible_date%TYPE,    -- �󒍉\��
                                                                                   -- ���e�\��
       perm_poss_date               xxcos_edi_headers.permission_possible_date%TYPE,
       forward_month                xxcos_edi_headers.forward_month%TYPE,          -- ����N����
                                                                                   -- �x�����ϓ�
       pay_settl_date               xxcos_edi_headers.payment_settlement_date%TYPE,
                                                                                   -- �`���V�J�n��
       hand_st_date_act             xxcos_edi_headers.handbill_start_date_active%TYPE,
       billing_due_date             xxcos_edi_headers.billing_due_date%TYPE,     -- ��������
       shipping_time                xxcos_edi_headers.shipping_time%TYPE,        -- �o�׎���
       deli_schedule_time           xxcos_edi_headers.delivery_schedule_time%TYPE, -- �[�i�\�莞��
       order_time                   xxcos_edi_headers.order_time%TYPE,           -- ��������
       general_date_item1           xxcos_edi_headers.general_date_item1%TYPE,   -- �ėp���t���ڂP
       general_date_item2           xxcos_edi_headers.general_date_item2%TYPE,   -- �ėp���t���ڂQ
       general_date_item3           xxcos_edi_headers.general_date_item3%TYPE,   -- �ėp���t���ڂR
       general_date_item4           xxcos_edi_headers.general_date_item4%TYPE,   -- �ėp���t���ڂS
       general_date_item5           xxcos_edi_headers.general_date_item5%TYPE,   -- �ėp���t���ڂT
       arr_shipping_class           xxcos_edi_headers.arrival_shipping_class%TYPE, -- ���o�׋敪
       vendor_class                 xxcos_edi_headers.vendor_class%TYPE,         -- �����敪
       inv_detailed_class           xxcos_edi_headers.invoice_detailed_class%TYPE,   -- �`�[����敪
       unit_price_use_class         xxcos_edi_headers.unit_price_use_class%TYPE, -- �P���g�p�敪
                                                                            -- �T�u�����Z���^�[�R�[�h
       sub_dist_center_cd           xxcos_edi_headers.sub_distribution_center_name%TYPE,
                                                                            -- �T�u�����Z���^�[�R�[�h��
       sub_dist_center_nm           xxcos_edi_headers.sub_distribution_center_name%TYPE,
       center_deli_method           xxcos_edi_headers.center_delivery_method%TYPE, -- �Z���^�[�[�i���@
       center_use_class             xxcos_edi_headers.center_use_class%TYPE,      -- �Z���^�[���p�敪
       center_whse_class            xxcos_edi_headers.center_whse_class%TYPE,     -- �Z���^�[�q�ɋ敪
       center_area_class            xxcos_edi_headers.center_area_class%TYPE,     -- �Z���^�[�n��敪
       center_arr_class             xxcos_edi_headers.center_arrival_class%TYPE,  -- �Z���^�[���׋敪
       depot_class                  xxcos_edi_headers.depot_class%TYPE,           -- �f�|�敪
       tcdc_class                   xxcos_edi_headers.tcdc_class%TYPE,            -- �s�b�c�b�敪
       upc_flag                     xxcos_edi_headers.upc_flag%TYPE,              -- �t�o�b�t���O
       simultaneously_cls           xxcos_edi_headers.simultaneously_class%TYPE,  -- ��ċ敪
       business_id                  xxcos_edi_headers.business_id%TYPE,           -- �Ɩ��h�c
       whse_directly_cls            xxcos_edi_headers.whse_directly_class%TYPE,   -- �q���敪
       premium_rebate_cls           xxcos_edi_headers.premium_rebate_class%TYPE,  -- �i�i���ߋ敪
       item_type                    xxcos_edi_headers.item_type%TYPE,             -- ���ڎ��
       cloth_hous_fod_cls           xxcos_edi_headers.cloth_house_food_class%TYPE, -- �߉ƐH�敪
       mix_class                    xxcos_edi_headers.mix_class%TYPE,             -- ���݋敪
       stk_class                    xxcos_edi_headers.stk_class%TYPE,             -- �݌ɋ敪
       last_mod_site_cls            xxcos_edi_headers.last_modify_site_class%TYPE, -- �ŏI�C���ꏊ�敪
       report_class                 xxcos_edi_headers.report_class%TYPE,          -- ���[�敪
       add_plan_cls                 xxcos_edi_headers.addition_plan_class%TYPE,   -- �ǉ��E�v��敪
       registration_class           xxcos_edi_headers.registration_class%TYPE,    -- �o�^�敪
       specific_class               xxcos_edi_headers.specific_class%TYPE,        -- ����敪
       dealings_class               xxcos_edi_headers.dealings_class%TYPE,        -- ����敪
       order_class                  xxcos_edi_headers.order_class%TYPE,           -- �����敪
       sum_line_class               xxcos_edi_headers.sum_line_class%TYPE,        -- �W�v���׋敪
       ship_guidance_cls            xxcos_edi_headers.shipping_guidance_class%TYPE, -- �o�׈ē��ȊO�敪
       shipping_class               xxcos_edi_headers.shipping_class%TYPE,        -- �o�׋敪
                                                                                    -- ���i�R�[�h�g�p�敪
       prod_cd_use_cls              xxcos_edi_headers.product_code_use_class%TYPE,
       cargo_item_class             xxcos_edi_headers.cargo_item_class%TYPE,      -- �ϑ��i�敪
       ta_class                     xxcos_edi_headers.ta_class%TYPE,              -- �s�^�`�敪
       plan_code                    xxcos_edi_headers.plan_code%TYPE,             -- ���R�[�h
       category_code                xxcos_edi_headers.category_code%TYPE,         -- �J�e�S���[�R�[�h
       category_class               xxcos_edi_headers.category_class%TYPE,        -- �J�e�S���[�敪
       carrier_means                xxcos_edi_headers.carrier_means%TYPE,         -- �^����i
       counter_code                 xxcos_edi_headers.counter_code%TYPE,          -- ����R�[�h
       move_sign                    xxcos_edi_headers.move_sign%TYPE,             -- �ړ��T�C��
       eos_handwrit_cls             xxcos_edi_headers.eos_handwriting_class%TYPE, -- �d�n�r�E�菑�敪
       deli_to_section_cd           xxcos_edi_headers.delivery_to_section_code%TYPE, -- �[�i��ۃR�[�h
       invoice_detailed             xxcos_edi_headers.invoice_detailed%TYPE,      -- �`�[����
       attach_qty                   xxcos_edi_headers.attach_qty%TYPE,            -- �Y�t��
       other_party_floor            xxcos_edi_headers.other_party_floor%TYPE,     -- �t���A
       text_no                      xxcos_edi_headers.text_no%TYPE,               -- �s�d�w�s�m��
       in_store_code                xxcos_edi_headers.in_store_code%TYPE,         -- �C���X�g�A�R�[�h
       tag_data                     xxcos_edi_headers.tag_data%TYPE,              -- �^�O
       competition_code             xxcos_edi_headers.competition_code%TYPE,      -- ����
       billing_chair                xxcos_edi_headers.billing_chair%TYPE,         -- ��������
       chain_store_code             xxcos_edi_headers.chain_store_code%TYPE,      -- �`�F�[���X�g�A�[�R�[�h
                                                                        -- �`�F�[���X�g�A�[�R�[�h��������
       chain_st_sh_name             xxcos_edi_headers.chain_store_short_name%TYPE,
       dir_deli_rcpt_fee            xxcos_edi_headers.direct_delivery_rcpt_fee%TYPE, -- ���z���^���旿
       bill_info                    xxcos_edi_headers.bill_info%TYPE,              -- ��`���
       description                  xxcos_edi_headers.description%TYPE,            -- �E�v
       interior_code                xxcos_edi_headers.interior_code%TYPE,          -- �����R�[�h
                                                                         -- �������@�[�i�J�e�S���[
       order_in_deli_cate           xxcos_edi_headers.order_info_delivery_category%TYPE,
       purchase_type                xxcos_edi_headers.purchase_type%TYPE,          -- �d���`��
                                                                                     -- �[�i�ꏊ���i�J�i�j
       deli_to_name_alt             xxcos_edi_headers.delivery_to_name_alt%TYPE,
       shop_opened_site             xxcos_edi_headers.shop_opened_site%TYPE,        -- �X�o�ꏊ
       counter_name                 xxcos_edi_headers.counter_name%TYPE,            -- ���ꖼ
       extension_number             xxcos_edi_headers.extension_number%TYPE,        -- �����ԍ�
       charge_name                  xxcos_edi_headers.charge_name%TYPE,             -- �S���Җ�
       price_tag                    xxcos_edi_headers.price_tag%TYPE,               -- �l�D
       tax_type                     xxcos_edi_headers.tax_type%TYPE,                -- �Ŏ�
       consump_tax_cls              xxcos_edi_headers.consumption_tax_class%TYPE,   -- ����ŋ敪
       brand_class                  xxcos_edi_headers.brand_class%TYPE,             -- �a�q
       id_code                      xxcos_edi_headers.id_code%TYPE,                 -- �h�c�R�[�h
       department_code              xxcos_edi_headers.department_code%TYPE,         -- �S�ݓX�R�[�h
       department_name              xxcos_edi_headers.department_name%TYPE,         -- �S�ݓX��
       item_type_number             xxcos_edi_headers.item_type_number%TYPE,        -- �i�ʔԍ�
       description_depart           xxcos_edi_headers.description_department%TYPE,  -- �E�v�i�S�ݓX�j
       price_tag_method             xxcos_edi_headers.price_tag_method%TYPE,        -- �l�D���@
       reason_column                xxcos_edi_headers.reason_column%TYPE,           -- ���R��
       a_column_header              xxcos_edi_headers.a_column_header%TYPE,         -- �`���w�b�_
       d_column_header              xxcos_edi_headers.d_column_header%TYPE,         -- �c���w�b�_
       brand_code                   xxcos_edi_headers.brand_code%TYPE,              -- �u�����h�R�[�h
       line_code                    xxcos_edi_headers.line_code%TYPE,               -- ���C���R�[�h
       class_code                   xxcos_edi_headers.class_code%TYPE,              -- �N���X�R�[�h
       a1_column                    xxcos_edi_headers.a1_column%TYPE,               -- �`�|�P��
       b1_column                    xxcos_edi_headers.b1_column%TYPE,               -- �a�|�P��
       c1_column                    xxcos_edi_headers.c1_column%TYPE,               -- �b�|�P��
       d1_column                    xxcos_edi_headers.d1_column%TYPE,               -- �c�|�P��
       e1_column                    xxcos_edi_headers.e1_column%TYPE,               -- �d�|�P��
       a2_column                    xxcos_edi_headers.a2_column%TYPE,               -- �`�|�Q��
       b2_column                    xxcos_edi_headers.b2_column%TYPE,               -- �a�|�Q��
       c2_column                    xxcos_edi_headers.c2_column%TYPE,               -- �b�|�Q��
       d2_column                    xxcos_edi_headers.d2_column%TYPE,               -- �c�|�Q��
       e2_column                    xxcos_edi_headers.e2_column%TYPE,               -- �d�|�Q��
       a3_column                    xxcos_edi_headers.a3_column%TYPE,               -- �`�|�R��
       b3_column                    xxcos_edi_headers.b3_column%TYPE,               -- �a�|�R��
       c3_column                    xxcos_edi_headers.c3_column%TYPE,               -- �b�|�R��
       d3_column                    xxcos_edi_headers.d3_column%TYPE,               -- �c�|�R��
       e3_column                    xxcos_edi_headers.e3_column%TYPE,               -- �d�|�R��
       f1_column                    xxcos_edi_headers.f1_column%TYPE,               -- �e�|�P��
       g1_column                    xxcos_edi_headers.g1_column%TYPE,               -- �f�|�P��
       h1_column                    xxcos_edi_headers.h1_column%TYPE,               -- �g�|�P��
       i1_column                    xxcos_edi_headers.i1_column%TYPE,               -- �h�|�P��
       j1_column                    xxcos_edi_headers.j1_column%TYPE,               -- �i�|�P��
       k1_column                    xxcos_edi_headers.k1_column%TYPE,               -- �j�|�P��
       l1_column                    xxcos_edi_headers.l1_column%TYPE,               -- �k�|�P��
       f2_column                    xxcos_edi_headers.f2_column%TYPE,               -- �e�|�Q��
       g2_column                    xxcos_edi_headers.g2_column%TYPE,               -- �f�|�Q��
       h2_column                    xxcos_edi_headers.h2_column%TYPE,               -- �g�|�Q��
       i2_column                    xxcos_edi_headers.i2_column%TYPE,               -- �h�|�Q��
       j2_column                    xxcos_edi_headers.j2_column%TYPE,               -- �i�|�Q��
       k2_column                    xxcos_edi_headers.k2_column%TYPE,               -- �j�|�Q��
       l2_column                    xxcos_edi_headers.l2_column%TYPE,               -- �k�|�Q��
       f3_column                    xxcos_edi_headers.f3_column%TYPE,               -- �e�|�R��
       g3_column                    xxcos_edi_headers.g3_column%TYPE,               -- �f�|�R��
       h3_column                    xxcos_edi_headers.h3_column%TYPE,               -- �g�|�R��
       i3_column                    xxcos_edi_headers.i3_column%TYPE,               -- �h�|�R��
       j3_column                    xxcos_edi_headers.j3_column%TYPE,               -- �i�|�R��
       k3_column                    xxcos_edi_headers.k3_column%TYPE,               -- �j�|�R��
       l3_column                    xxcos_edi_headers.l3_column%TYPE,               -- �k�|�R��
                                                                 -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
-- 2010/04/23 v1.8 T.Yoshimoto Mod Start �{�ғ�#2427
--       chain_pecarea_head           xxcos_edi_headers.chain_peculiar_area_header%TYPE,
       chain_pe_area_head           xxcos_edi_headers.chain_peculiar_area_header%TYPE,
-- 2010/04/23 v1.8 T.Yoshimoto Mod Start �{�ғ�#2427
                                                                 -- �󒍊֘A�ԍ�
       order_connect_num            xxcos_edi_headers.order_connection_number%TYPE,
                                                                 -- �i�`�[�v�j�������ʁi�o���j
       inv_indv_order_qty           xxcos_edi_headers.invoice_indv_order_qty%TYPE,
                                                                 -- �i�`�[�v�j�������ʁi�P�[�X�j
       inv_case_order_qty           xxcos_edi_headers.invoice_case_order_qty%TYPE,
                                                                 -- �i�`�[�v�j�������ʁi�{�[���j
       inv_ball_order_qty           xxcos_edi_headers.invoice_ball_order_qty%TYPE,
                                                                 -- �i�`�[�v�j�������ʁi���v�A�o���j
       inv_sum_order_qty            xxcos_edi_headers.invoice_sum_order_qty%TYPE,
                                                                 -- �i�`�[�v�j�o�א��ʁi�o���j
       inv_indv_ship_qty            xxcos_edi_headers.invoice_indv_shipping_qty%TYPE,
                                                                 -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
       inv_case_ship_qty            xxcos_edi_headers.invoice_case_shipping_qty%TYPE,
                                                                 -- �i�`�[�v�j�o�א��ʁi�{�[���j
       inv_ball_ship_qty            xxcos_edi_headers.invoice_ball_shipping_qty%TYPE,
                                                                 -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
       inv_pall_ship_qty            xxcos_edi_headers.invoice_pallet_shipping_qty%TYPE,
                                                                 -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
       inv_sum_ship_qty             xxcos_edi_headers.invoice_sum_shipping_qty%TYPE,
                                                                 -- �i�`�[�v�j���i���ʁi�o���j
       inv_indv_stock_qty           xxcos_edi_headers.invoice_indv_stockout_qty%TYPE,
                                                                 -- �i�`�[�v�j���i���ʁi�P�[�X�j
       inv_case_stock_qty           xxcos_edi_headers.invoice_case_stockout_qty%TYPE,
                                                                 -- �i�`�[�v�j���i���ʁi�{�[���j
       inv_ball_stock_qty           xxcos_edi_headers.invoice_ball_stockout_qty%TYPE,
                                                                 -- �i�`�[�v�j���i���ʁi���v�A�o���j
       inv_sum_stock_qty            xxcos_edi_headers.invoice_sum_stockout_qty%TYPE,
                                                                 -- �i�`�[�v�j�P�[�X����
       inv_case_qty                 xxcos_edi_headers.invoice_case_qty%TYPE,
                                                                 -- �i�`�[�v�j�I���R���i�o���j����
       inv_fold_cont_qty            xxcos_edi_headers.invoice_fold_container_qty%TYPE,
                                                                 -- �i�`�[�v�j�������z�i�����j
       inv_order_cost_amt           xxcos_edi_headers.invoice_order_cost_amt%TYPE,
                                                                 -- �i�`�[�v�j�������z�i�o�ׁj
       inv_ship_cost_amt            xxcos_edi_headers.invoice_shipping_cost_amt%TYPE,
                                                                 -- �i�`�[�v�j�������z�i���i�j
       inv_stock_cost_amt           xxcos_edi_headers.invoice_stockout_cost_amt%TYPE,
                                                                 -- �i�`�[�v�j�������z�i�����j
       inv_order_price_amt          xxcos_edi_headers.invoice_order_price_amt%TYPE,
                                                                 -- �i�`�[�v�j�������z�i�o�ׁj
       inv_ship_price_amt           xxcos_edi_headers.invoice_shipping_price_amt%TYPE,
                                                                  -- �i�`�[�v�j�������z�i���i�j
       inv_stock_price_amt          xxcos_edi_headers.invoice_stockout_price_amt%TYPE,
                                                                 -- �i�����v�j�������ʁi�o���j
       tot_indv_order_qty           xxcos_edi_headers.total_indv_order_qty%TYPE,
                                                                 -- �i�����v�j�������ʁi�P�[�X�j
       tot_case_order_qty           xxcos_edi_headers.total_case_order_qty%TYPE,
                                                                 -- �i�����v�j�������ʁi�{�[���j
       tot_ball_order_qty           xxcos_edi_headers.total_ball_order_qty%TYPE,
                                                                 -- �i�����v�j�������ʁi���v�A�o���j
       tot_sum_order_qty            xxcos_edi_headers.total_sum_order_qty%TYPE,
                                                                 -- �i�����v�j�o�א��ʁi�o���j
       tot_indv_ship_qty            xxcos_edi_headers.total_indv_shipping_qty%TYPE,
                                                                 -- �i�����v�j�o�א��ʁi�P�[�X�j
       tot_case_ship_qty            xxcos_edi_headers.total_case_shipping_qty%TYPE,
                                                                 -- �i�����v�j�o�א��ʁi�{�[���j
       tot_ball_ship_qty            xxcos_edi_headers.total_ball_shipping_qty%TYPE,
                                                                 -- �i�����v�j�o�א��ʁi�p���b�g�j
       tot_pallet_ship_qty          xxcos_edi_headers.total_pallet_shipping_qty%TYPE,
                                                                 -- �i�����v�j�o�א��ʁi���v�A�o���j
       tot_sum_ship_qty             xxcos_edi_headers.total_sum_shipping_qty%TYPE,
                                                                 -- �i�����v�j���i���ʁi�o���j
       tot_indv_stockout_qty        xxcos_edi_headers.total_indv_stockout_qty%TYPE,
                                                                 -- �i�����v�j���i���ʁi�P�[�X�j
       tot_case_stockout_qty        xxcos_edi_headers.total_case_stockout_qty%TYPE,
                                                                 -- �i�����v�j���i���ʁi�{�[���j
       tot_ball_stockout_qty        xxcos_edi_headers.total_case_stockout_qty%TYPE,
                                                                 -- �i�����v�j���i���ʁi���v�A�o���j
       tot_sum_stockout_qty         xxcos_edi_headers.total_case_stockout_qty%TYPE,
                                                                 -- �i�����v�j�P�[�X����
       tot_case_qty                 xxcos_edi_headers.total_case_qty%TYPE,
                                                                 -- �i�����v�j�I���R���i�o���j����
       tot_fold_container_qty       xxcos_edi_headers.total_fold_container_qty%TYPE,
                                                                  -- �i�����v�j�������z�i�����j
       tot_order_cost_amt           xxcos_edi_headers.total_order_cost_amt%TYPE,
                                                                 -- �i�����v�j�������z�i�o�ׁj
       tot_ship_cost_amt            xxcos_edi_headers.total_shipping_cost_amt%TYPE,
                                                                 -- �i�����v�j�������z�i���i�j
       tot_stockout_cost_amt        xxcos_edi_headers.total_stockout_cost_amt%TYPE,
                                                                 -- �i�����v�j�������z�i�����j
       tot_order_price_amt          xxcos_edi_headers.total_order_price_amt%TYPE,
                                                                 -- �i�����v�j�������z�i�o�ׁj
       tot_ship_price_amt           xxcos_edi_headers.total_shipping_price_amt%TYPE,
                                                                 -- �i�����v�j�������z�i���i�j
       tot_stockout_price_amt       xxcos_edi_headers.total_stockout_price_amt%TYPE,
                                                                 -- �g�[�^���s��
       tot_line_qty                 xxcos_edi_headers.total_line_qty%TYPE,
                                                                 -- �g�[�^���`�[����
       tot_invoice_qty              xxcos_edi_headers.total_invoice_qty%TYPE,
                                                                 -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
       chain_pe_area_foot           xxcos_edi_headers.chain_peculiar_area_footer%TYPE,
                                                                 -- �ϊ���ڋq�R�[�h
       conv_customer_code           xxcos_edi_headers.conv_customer_code%TYPE,
                                                                 -- �󒍘A�g�σt���O
       order_forward_flag           xxcos_edi_headers.order_forward_flag%TYPE,
                                                                 -- �쐬���敪
       creation_class               xxcos_edi_headers.creation_class%TYPE,
                                                                 -- EDI�[�i�\�著�M�σt���O
       edi_deli_sche_flg            xxcos_edi_headers.edi_delivery_schedule_flag%TYPE,
                                                                 -- ���i�\�w�b�_ID
/* 2011/07/26 Ver1.9 Mod Start */
--       price_list_header_id         xxcos_edi_headers.price_list_header_id%TYPE
       price_list_header_id         xxcos_edi_headers.price_list_header_id%TYPE,
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
                                                                 -- ���ʂa�l�r�w�b�_�f�[�^
       bms_header_data              xxcos_edi_headers.bms_header_data%TYPE
/* 2011/07/26 Ver1.9 Add End   */
   );
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  -- �ڋq�f�[�^ �e�[�u���^
  TYPE g_req_edi_headers_data_ttype IS TABLE OF g_req_edi_headers_data_rtype INDEX BY BINARY_INTEGER;
  gt_req_edi_headers_data  g_req_edi_headers_data_ttype;
  --* -------------------------------------------------------------------------------------------
  --* -------------------------------------------------------------------------------------------
  -- EDI���׏��e�[�u���f�[�^�o�^�p�ϐ�(xxcos_edi_lines)
  TYPE g_req_edi_lines_data_rtype IS RECORD(
        edi_line_info_id             xxcos_edi_lines.edi_line_info_id%TYPE,    -- EDI���׏��ID
        invoice_number               xxcos_edi_headers.invoice_number%TYPE,    -- �`�[�ԍ�
        edi_header_info_id           xxcos_edi_lines.edi_header_info_id%TYPE,  -- EDI�w�b�_���ID
        line_no                      xxcos_edi_lines.line_no%TYPE,             -- �s�m��
        stockout_class               xxcos_edi_lines.stockout_class%TYPE,      -- ���i�敪
        stockout_reason              xxcos_edi_lines.stockout_reason%TYPE,     -- ���i���R
                                                                                 -- ���i�R�[�h�i�ɓ����j
        product_code_itouen          xxcos_edi_lines.product_code_itouen%TYPE,
        product_code1                xxcos_edi_lines.product_code1%TYPE,       -- ���i�R�[�h�P
        product_code2                xxcos_edi_lines.product_code2%TYPE,       -- ���i�R�[�h�Q
        jan_code                     xxcos_edi_lines.jan_code%TYPE,            -- �i�`�m�R�[�h
        itf_code                     xxcos_edi_lines.itf_code%TYPE,            -- �h�s�e�R�[�h
        extension_itf_code           xxcos_edi_lines.extension_itf_code%TYPE,  -- �����h�s�e�R�[�h
        case_product_code            xxcos_edi_lines.case_product_code%TYPE,   -- �P�[�X���i�R�[�h
        ball_product_code            xxcos_edi_lines.ball_product_code%TYPE,   -- �{�[�����i�R�[�h
        prod_cd_item_type            xxcos_edi_lines.product_code_item_type%TYPE, -- ���i�R�[�h�i��
        prod_class                   xxcos_edi_lines.prod_class%TYPE,          -- ���i�敪
        product_name                 xxcos_edi_lines.product_name%TYPE,        -- ���i���i�����j
        product_name1_alt            xxcos_edi_lines.product_name1_alt%TYPE,   -- ���i���P�i�J�i�j
        product_name2_alt            xxcos_edi_lines.product_name2_alt%TYPE,   -- ���i���Q�i�J�i�j
        item_standard1               xxcos_edi_lines.item_standard1%TYPE,      -- �K�i�P
        item_standard2               xxcos_edi_lines.item_standard2%TYPE,      -- �K�i�Q
        qty_in_case                  xxcos_edi_lines.qty_in_case%TYPE,         -- ����
        num_of_cases                 xxcos_edi_lines.num_of_cases%TYPE,        -- �P�[�X����
        num_of_ball                  xxcos_edi_lines.num_of_ball%TYPE,         -- �{�[������
        item_color                   xxcos_edi_lines.item_color%TYPE,          -- �F
        item_size                    xxcos_edi_lines.item_size%TYPE,           -- �T�C�Y
        expiration_date              xxcos_edi_lines.expiration_date%TYPE,     -- �ܖ�������
        product_date                 xxcos_edi_lines.product_date%TYPE,        -- ������
        order_uom_qty                xxcos_edi_lines.order_uom_qty%TYPE,       -- �����P�ʐ�
        ship_uom_qty                 xxcos_edi_lines.shipping_uom_qty%TYPE,    -- �o�גP�ʐ�
        packing_uom_qty              xxcos_edi_lines.packing_uom_qty%TYPE,     -- ����P�ʐ�
        deal_code                    xxcos_edi_lines.deal_code%TYPE,           -- ����
        deal_class                   xxcos_edi_lines.deal_class%TYPE,          -- �����敪
        collation_code               xxcos_edi_lines.collation_code%TYPE,      -- �ƍ�
        uom_code                     xxcos_edi_lines.uom_code%TYPE,            -- �P��
        unit_price_class             xxcos_edi_lines.unit_price_class%TYPE,    -- �P���敪
        parent_pack_num              xxcos_edi_lines.parent_packing_number%TYPE, -- �e����ԍ�
        packing_number               xxcos_edi_lines.packing_number%TYPE,      -- ����ԍ�
        product_group_code           xxcos_edi_lines.product_group_code%TYPE,  -- ���i�Q�R�[�h
        case_dismantle_flag          xxcos_edi_lines.case_dismantle_flag%TYPE, -- �P�[�X��̕s�t���O
        case_class                   xxcos_edi_lines.case_class%TYPE,          -- �P�[�X�敪
        indv_order_qty               xxcos_edi_lines.indv_order_qty%TYPE,      -- �������ʁi�o���j
        case_order_qty               xxcos_edi_lines.case_order_qty%TYPE,      -- �������ʁi�P�[�X�j
        ball_order_qty               xxcos_edi_lines.ball_order_qty%TYPE,      -- �������ʁi�{�[���j
        sum_order_qty                xxcos_edi_lines.sum_order_qty%TYPE,       -- �������ʁi���v�A�o���j
        indv_shipping_qty            xxcos_edi_lines.indv_shipping_qty%TYPE,   -- �o�א��ʁi�o���j
        case_shipping_qty            xxcos_edi_lines.case_shipping_qty%TYPE,   -- �o�א��ʁi�P�[�X�j
        ball_shipping_qty            xxcos_edi_lines.ball_shipping_qty%TYPE,   -- �o�א��ʁi�{�[���j
        pallet_shipping_qty          xxcos_edi_lines.pallet_shipping_qty%TYPE, -- �o�א��ʁi�p���b�g�j
        sum_shipping_qty             xxcos_edi_lines.sum_shipping_qty%TYPE,    -- �o�א��ʁi���v�A�o���j
        indv_stockout_qty            xxcos_edi_lines.indv_stockout_qty%TYPE,   -- ���i���ʁi�o���j
        case_stockout_qty            xxcos_edi_lines.case_stockout_qty%TYPE,   -- ���i���ʁi�P�[�X�j
        ball_stockout_qty            xxcos_edi_lines.ball_stockout_qty%TYPE,   -- ���i���ʁi�{�[���j
        sum_stockout_qty             xxcos_edi_lines.sum_stockout_qty%TYPE,    -- ���i���ʁi���v�A�o���j
        case_qty                     xxcos_edi_lines.case_qty%TYPE,            -- �P�[�X����
                                                                               -- �I���R���i�o���j����
        fold_cont_indv_qty           xxcos_edi_lines.FOLD_CONTAINER_INDV_QTY%TYPE,
        order_unit_price             xxcos_edi_lines.order_unit_price%TYPE,    -- ���P���i�����j
        shipping_unit_price          xxcos_edi_lines.shipping_unit_price%TYPE, -- ���P���i�o�ׁj
        order_cost_amt               xxcos_edi_lines.order_cost_amt%TYPE,      -- �������z�i�����j
        shipping_cost_amt            xxcos_edi_lines.shipping_cost_amt%TYPE,   -- �������z�i�o�ׁj
        stockout_cost_amt            xxcos_edi_lines.stockout_cost_amt%TYPE,   -- �������z�i���i�j
        selling_price                xxcos_edi_lines.selling_price%TYPE,       -- ���P��
        order_price_amt              xxcos_edi_lines.order_price_amt%TYPE,     -- �������z�i�����j
        shipping_price_amt           xxcos_edi_lines.shipping_price_amt%TYPE,  -- �������z�i�o�ׁj
        stockout_price_amt           xxcos_edi_lines.stockout_price_amt%TYPE,  -- �������z�i���i�j
        a_col_department             xxcos_edi_lines.a_column_department%TYPE, -- �`���i�S�ݓX�j
        d_col_department             xxcos_edi_lines.d_column_department%TYPE, -- �c���i�S�ݓX�j
        stand_info_depth             xxcos_edi_lines.standard_info_depth%TYPE, -- �K�i���E���s��
        stand_info_height            xxcos_edi_lines.standard_info_height%TYPE, -- �K�i���E����
        stand_info_width             xxcos_edi_lines.standard_info_width%TYPE, -- �K�i���E��
        stand_info_weight            xxcos_edi_lines.standard_info_weight%TYPE, -- �K�i���E�d��
        gen_succeed_item1            xxcos_edi_lines.general_succeeded_item1%TYPE, -- �ėp���p�����ڂP
        gen_succeed_item2            xxcos_edi_lines.general_succeeded_item2%TYPE, -- �ėp���p�����ڂQ
        gen_succeed_item3            xxcos_edi_lines.general_succeeded_item3%TYPE, -- �ėp���p�����ڂR
        gen_succeed_item4            xxcos_edi_lines.general_succeeded_item4%TYPE, -- �ėp���p�����ڂS
        gen_succeed_item5            xxcos_edi_lines.general_succeeded_item5%TYPE, -- �ėp���p�����ڂT
        gen_succeed_item6            xxcos_edi_lines.general_succeeded_item6%TYPE, -- �ėp���p�����ڂU
        gen_succeed_item7            xxcos_edi_lines.general_succeeded_item7%TYPE, -- �ėp���p�����ڂV
        gen_succeed_item8            xxcos_edi_lines.general_succeeded_item8%TYPE, -- �ėp���p�����ڂW
        gen_succeed_item9            xxcos_edi_lines.general_succeeded_item9%TYPE, -- �ėp���p�����ڂX
        gen_succeed_item10           xxcos_edi_lines.general_succeeded_item10%TYPE, -- �ėp���p�����ڂP�O
        gen_add_item1                xxcos_edi_lines.general_add_item1%TYPE,       -- �ėp�t�����ڂP
        gen_add_item2                xxcos_edi_lines.general_add_item2%TYPE,       -- �ėp�t�����ڂQ
        gen_add_item3                xxcos_edi_lines.general_add_item3%TYPE,       -- �ėp�t�����ڂR
        gen_add_item4                xxcos_edi_lines.general_add_item4%TYPE,       -- �ėp�t�����ڂS
        gen_add_item5                xxcos_edi_lines.general_add_item5%TYPE,       -- �ėp�t�����ڂT
        gen_add_item6                xxcos_edi_lines.general_add_item6%TYPE,       -- �ėp�t�����ڂU
        gen_add_item7                xxcos_edi_lines.general_add_item7%TYPE,       -- �ėp�t�����ڂV
        gen_add_item8                xxcos_edi_lines.general_add_item8%TYPE,       -- �ėp�t�����ڂW
        gen_add_item9                xxcos_edi_lines.general_add_item9%TYPE,       -- �ėp�t�����ڂX
        gen_add_item10               xxcos_edi_lines.general_add_item10%TYPE,      -- �ėp�t�����ڂP�O
                                                                         -- �`�F�[���X�ŗL�G���A�i���ׁj
        chain_pec_a_line             xxcos_edi_lines.chain_peculiar_area_line%TYPE,
        item_code                    xxcos_edi_lines.item_code%TYPE,               -- �i�ڃR�[�h
        line_uom                     xxcos_edi_lines.line_uom%TYPE,                -- ���גP��
                                                                                   -- �󒍊֘A���הԍ�
/* 2011/07/26 Ver1.9 Mod Start */
--        order_con_line_num           xxcos_edi_lines.order_connection_line_number%TYPE
        order_con_line_num           xxcos_edi_lines.order_connection_line_number%TYPE,
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
        bms_line_data                xxcos_edi_lines.bms_line_data%TYPE            -- ���ʂa�l�r���׃f�[�^
/* 2011/07/26 Ver1.9 Add End   */
    );
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  -- �ڋq�f�[�^ �e�[�u���^
  TYPE g_req_edi_lines_data_ttype IS TABLE OF g_req_edi_lines_data_rtype INDEX BY BINARY_INTEGER;
  gt_req_edi_lines_data  g_req_edi_lines_data_ttype;
  --* -------------------------------------------------------------------------------------------
  --* -------------------------------------------------------------------------------------------
  -- ===============================
  -- �i�ڃf�[�^���R�[�h�^
  -- ===============================
  TYPE ga_req_mtl_sys_items_rtype IS RECORD(
                         -- �i�ڃ}�X�^�̕i��ID
      inventory_item_id  mtl_system_items_b.inventory_item_id%TYPE
                         -- �i�ڃ}�X�^�̕i�ڃR�[�h
     ,segment1           mtl_system_items_b.segment1%TYPE
                         -- �P��
     ,unit_of_measure    mtl_system_items_b.primary_unit_of_measure%TYPE
    );
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  -- �i�ڃf�[�^ �e�[�u���^
  -- ===============================
  TYPE ga_req_mtl_sys_items_ttype IS TABLE OF ga_req_mtl_sys_items_rtype INDEX BY BINARY_INTEGER;
  gt_req_mtl_sys_items  ga_req_mtl_sys_items_ttype;
  --
  gt_delivery_return_work_id          xxcos_edi_delivery_work.delivery_return_work_id%TYPE;
                          -- EDI�[�i�ԕi��񃏁[�N�ϐ��̔[�i�ԕi���[�NID
  --* -------------------------------------------------------------------------------------------
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)(A-1)
   *                  :  ���̓p�����[�^�Ó����`�F�b�N
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_name      IN VARCHAR2,     --   �C���^�t�F�[�X�t�@�C����
    iv_run_class      IN VARCHAR2,     --   ���s�敪�F�u�V�K�v�u�Ď��s�v
    iv_edi_chain_code IN VARCHAR2,     --   EDI�`�F�[���X�R�[�h
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
-- ******************** 2009/09/28 1.6 K.Satomura ADD START *********************** --
    lv_tok_item_err_type VARCHAR2(100); -- ���b�Z�[�W�g�[�N���P
    lv_tok_lookup_value  VARCHAR2(100); -- ���b�Z�[�W�g�[�N���Q
-- ******************** 2009/09/28 1.6 K.Satomura ADD END   *********************** --
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
  --* -------------------------------------------------------------------------------------------
    IF  ( iv_file_name  IS NULL ) THEN                 -- �C���^�t�F�[�X�t�@�C������NULL
      -- �C���^�t�F�[�X�t�@�C����
      gv_in_file_name    :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  cv_msg_in_file_name
                         );
      lv_retcode         :=  cv_status_error;
      lv_errmsg          :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  gv_msg_in_param_none_err,
                         iv_token_name1        =>  cv_tkn_in_param,
                         iv_token_value1       =>  gv_in_file_name
                         );
    END IF;
    --* -------------------------------------------------------------------------------------------
    --�G���[�̏ꍇ�A���f������B
    IF  ( lv_retcode  <>  cv_status_normal )  THEN
      RAISE   global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --* -------------------------------------------------------------------------------------------
    IF  ( iv_run_class IS NULL ) THEN                 -- ���s�敪�̃p�����^��NULL
      -- ���s�敪
      gv_in_param       :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  cv_msg_in_param
                        );
      lv_retcode        :=  cv_status_error;
      lv_errmsg         :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  gv_msg_in_param_none_err,
                        iv_token_name1        =>  cv_tkn_in_param,
                        iv_token_value1       =>  gv_in_param
                        );
    --* -------------------------------------------------------------------------------------------
    ELSIF  (( iv_run_class  =  gv_run_class_name1 )     -- ���s�敪�F�u�V�K�v
    OR      ( iv_run_class  =  gv_run_class_name2 ))    -- ���s�敪�F�u�Ď��{�v
    THEN
      NULL;
    ELSE
      -- ���s�敪
      gv_in_param       :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  cv_msg_in_param
                        );
      lv_retcode        :=  cv_status_error;
      lv_errmsg         :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  gv_msg_in_param_err,
                        iv_token_name1        =>  cv_tkn_in_param,
                        iv_token_value1       =>  gv_in_param
                        );
    END IF;
    --* -------------------------------------------------------------------------------------------
    --�G���[�̏ꍇ�A���f������B
    IF  ( lv_retcode <> cv_status_normal )  THEN
      RAISE   global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-1. EDI���폜���Ԃ̎擾
    --==================================
    gv_prf_edi_del_date :=  FND_PROFILE.VALUE( cv_prf_edi_del_date );
    --
    IF  ( gv_prf_edi_del_date IS NULL )   THEN
      -- EDI���폜����
      gv_prf_edi_del_date0 :=  xxccp_common_pkg.get_msg(
                            iv_application        =>  cv_application,
                            iv_name               =>  cv_msg_edi_del_date
                            );
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_get_profile_err,
                           iv_token_name1        =>  cv_tkn_profile,
                           iv_token_value1       =>  gv_prf_edi_del_date0
                           );
      RAISE global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-2. �P�[�X�P�ʃR�[�h�̎擾
    --==================================
    gv_prf_case_code    :=  FND_PROFILE.VALUE( cv_prf_case_code );
    --
    IF  ( gv_prf_case_code  IS NULL )   THEN
      -- �P�[�X�P�ʃR�[�h
      gv_prf_case_code0    :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  cv_msg_case_code
                           );
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_get_profile_err,
                           iv_token_name1        =>  cv_tkn_profile,
                           iv_token_value1       =>  gv_prf_case_code0
                           );
      RAISE global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-3. �݌ɑg�D�R�[�h�̎擾
    --==================================
    gv_prf_orga_code    :=  FND_PROFILE.VALUE( cv_prf_orga_code1  );
    --
    IF  ( gv_prf_orga_code  IS NULL )   THEN
      -- �݌ɑg�D�R�[�h
      gv_prf_orga_code0    :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  cv_msg_orga_code
                           );
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_get_profile_err,
                           iv_token_name1        =>  cv_tkn_profile,
                           iv_token_value1       =>  gv_prf_orga_code0
                           );
      RAISE global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-4. �݌ɑg�D�h�c�̎擾
    --==================================
    gv_prf_orga_id      :=  xxcoi_common_pkg.get_organization_id(
                         gv_prf_orga_code
                         );
    --
    IF  ( gv_prf_orga_id       IS NULL )  THEN
      lv_errmsg          :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application1,
                         iv_name               =>  gv_msg_orga_id_err,
                         iv_token_name1        =>  cv_tkn_org_code,
                         iv_token_value1       =>  gv_prf_orga_code
                         );
      RAISE global_api_expt;
    END IF;
    --
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-5. MO:�c�ƒP�ʂ̎擾
    --==================================
    gn_org_id :=  FND_PROFILE.VALUE( cv_prf_org_id );
    --
    IF  ( gn_org_id IS NULL )   THEN
      -- MO:�c�ƒP��
      gv_msg_tkn_org_id    :=  xxccp_common_pkg.get_msg(
                            iv_application        =>  cv_application,
                            iv_name               =>  cv_msg_org_id
                            );
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_get_profile_err,
                           iv_token_name1        =>  cv_tkn_profile,
                           iv_token_value1       =>  gv_msg_tkn_org_id
                           );
      RAISE global_api_expt;
    END IF;
    --
    --* -------------------------------------------------------------------------------------------
-- ******************** 2009/09/28 1.6 K.Satomura ADD START *********************** --
    --==================================
    -- 2-6. �_�~�[�i�ڃR�[�h�̎擾
    --==================================
    BEGIN
      SELECT msi.segment1                dummy_item_code         -- �_�~�[�i�ڃR�[�h
            ,msi.primary_unit_of_measure primary_unit_of_measure -- ��P��
      INTO   gt_dummy_item_number
            ,gt_dummy_unit_of_measure
      FROM   fnd_lookup_values_vl flv -- �Q�ƃ^�C�v�R�[�h
            ,mtl_system_items_b msi -- �i�ڃ}�X�^
      WHERE  flv.lookup_type        = cv_lookup_type
      AND    flv.enabled_flag       = cv_y
      AND    flv.attribute1         = cv_1
      AND    TRUNC(cd_process_date) BETWEEN flv.start_date_active
                                        AND NVL(flv.end_date_active, TRUNC(cd_process_date))
      AND    flv.lookup_code        = msi.segment1   -- �Q�ƃ^�C�v�R�[�h.�R�[�h=�i�ڃ}�X�^.�i�ڃR�[�h
      AND    msi.organization_id    = gv_prf_orga_id -- �݌ɑg�DID
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- �}�X�^�`�F�b�N�G���[���o��
        lv_tok_item_err_type := xxccp_common_pkg.get_msg(
                                   iv_application => cv_application
                                  ,iv_name        => cv_msg_item_err_type
                                );
        --
        lv_tok_lookup_value  := xxccp_common_pkg.get_msg(
                                   iv_application => cv_application
                                  ,iv_name        => cv_msg_lookup_value
                                );
        lv_errmsg            := xxccp_common_pkg.get_msg(
                                   iv_application  => cv_application
                                  ,iv_name         => cv_msg_mst_notfound
                                  ,iv_token_name1  => cv_tkn_column_name
                                  ,iv_token_value1 => lv_tok_item_err_type
                                  ,iv_token_name2  => cv_tkn_table_name
                                  ,iv_token_value2 => lv_tok_lookup_value
                                );
        --
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
        --
    END;
-- ******************** 2009/09/28 1.6 K.Satomura ADD END   *********************** --
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_headers_add
   * Description      : EDI�w�b�_���ϐ��ւ̒ǉ�(A-4)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_headers_add(
    in_line_cnt1  IN NUMBER,       --   LOOP�p�J�E���^1
    in_line_cnt2  IN NUMBER,       --   LOOP�p�J�E���^2
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_headers_add'; -- �v���O������
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
               -- �i�`�[�v�j�������ʁi�o���j
    gt_req_edi_headers_data(in_line_cnt1).inv_indv_order_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).indv_order_qty, 0);
               -- �i�`�[�v�j�������ʁi�P�[�X�j
    gt_req_edi_headers_data(in_line_cnt1).inv_case_order_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).case_order_qty, 0);
               -- �i�`�[�v�j�������ʁi�{�[���j
    gt_req_edi_headers_data(in_line_cnt1).inv_ball_order_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).ball_order_qty, 0);
               -- �i�`�[�v�j�������ʁi���v�A�o���j
    gt_req_edi_headers_data(in_line_cnt1).inv_sum_order_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).sum_order_qty, 0);
               -- �i�`�[�v�j�o�א��ʁi�o���j
    gt_req_edi_headers_data(in_line_cnt1).inv_indv_ship_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).indv_shipping_qty, 0);
               -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
    gt_req_edi_headers_data(in_line_cnt1).inv_case_ship_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).case_shipping_qty, 0);
               -- �i�`�[�v�j�o�א��ʁi�{�[���j
    gt_req_edi_headers_data(in_line_cnt1).inv_ball_ship_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).ball_shipping_qty, 0);
               -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
    gt_req_edi_headers_data(in_line_cnt1).inv_pall_ship_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).pallet_shipping_qty, 0);
               -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
    gt_req_edi_headers_data(in_line_cnt1).inv_sum_ship_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).sum_shipping_qty, 0);
               -- �i�`�[�v�j���i���ʁi�o���j
    gt_req_edi_headers_data(in_line_cnt1).inv_indv_stock_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).indv_stockout_qty, 0);
               -- �i�`�[�v�j���i���ʁi�P�[�X�j
    gt_req_edi_headers_data(in_line_cnt1).inv_case_stock_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).case_stockout_qty, 0);
               -- �i�`�[�v�j���i���ʁi�{�[���j
    gt_req_edi_headers_data(in_line_cnt1).inv_ball_stock_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).ball_stockout_qty, 0);
               -- �i�`�[�v�j���i���ʁi���v�A�o���j
    gt_req_edi_headers_data(in_line_cnt1).inv_sum_stock_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).sum_stockout_qty, 0);
               -- �i�`�[�v�j�P�[�X����
    gt_req_edi_headers_data(in_line_cnt1).inv_case_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).case_qty, 0);
               -- �i�`�[�v�j�I���R���i�o���j����
    gt_req_edi_headers_data(in_line_cnt1).inv_fold_cont_qty
                            := NVL(gt_edideli_work_data(in_line_cnt2).fold_container_indv_qty, 0);
               -- �i�`�[�v�j�������z�i�����j
    gt_req_edi_headers_data(in_line_cnt1).inv_order_cost_amt
                            := NVL(gt_edideli_work_data(in_line_cnt2).order_cost_amt, 0);
               -- �i�`�[�v�j�������z�i�o�ׁj
    gt_req_edi_headers_data(in_line_cnt1).inv_ship_cost_amt
                            := NVL(gt_edideli_work_data(in_line_cnt2).shipping_cost_amt, 0);
               -- �i�`�[�v�j�������z�i���i�j
    gt_req_edi_headers_data(in_line_cnt1).inv_stock_cost_amt
                            := NVL(gt_edideli_work_data(in_line_cnt2).stockout_cost_amt, 0);
               -- �i�`�[�v�j�������z�i�����j
    gt_req_edi_headers_data(in_line_cnt1).inv_order_price_amt
                            := NVL(gt_edideli_work_data(in_line_cnt2).order_price_amt, 0);
               -- �i�`�[�v�j�������z�i�o�ׁj
    gt_req_edi_headers_data(in_line_cnt1).inv_ship_price_amt
                            := NVL(gt_edideli_work_data(in_line_cnt2).shipping_price_amt, 0);
               -- �i�`�[�v�j�������z�i���i�j
    gt_req_edi_headers_data(in_line_cnt1).inv_stock_price_amt
                            := NVL(gt_edideli_work_data(in_line_cnt2).stockout_price_amt, 0);
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END xxcos_in_edi_headers_add;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_headers_up
   * Description      : EDI�w�b�_���ϐ��֐��ʂ����Z(A-5)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_headers_up(
    in_line_cnt1   IN NUMBER,       --   LOOP�p�J�E���^1
    in_line_cnt2   IN NUMBER,       --   LOOP�p�J�E���^2
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_headers_up'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)  ;   -- ���^�[���E�R�[�h
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
               -- �i�`�[�v�j�������ʁi�o���j
    gt_req_edi_headers_data(in_line_cnt1).inv_indv_order_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_indv_order_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).indv_order_qty, 0);
               -- �i�`�[�v�j�������ʁi�P�[�X�j
    gt_req_edi_headers_data(in_line_cnt1).inv_case_order_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_case_order_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).case_order_qty, 0);
               -- �i�`�[�v�j�������ʁi�{�[���j
    gt_req_edi_headers_data(in_line_cnt1).inv_ball_order_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_ball_order_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).ball_order_qty, 0);
               -- �i�`�[�v�j�������ʁi���v�A�o���j
    gt_req_edi_headers_data(in_line_cnt1).inv_sum_order_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_sum_order_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).sum_order_qty, 0);
               -- �i�`�[�v�j�o�א��ʁi�o���j
    gt_req_edi_headers_data(in_line_cnt1).inv_indv_ship_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_indv_ship_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).indv_shipping_qty, 0);
               -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
    gt_req_edi_headers_data(in_line_cnt1).inv_case_ship_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_case_ship_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).case_shipping_qty, 0);
               -- �i�`�[�v�j�o�א��ʁi�{�[���j
    gt_req_edi_headers_data(in_line_cnt1).inv_ball_ship_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_ball_ship_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).ball_shipping_qty, 0);
               -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
    gt_req_edi_headers_data(in_line_cnt1).inv_pall_ship_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_pall_ship_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).pallet_shipping_qty, 0);
               -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
    gt_req_edi_headers_data(in_line_cnt1).inv_sum_ship_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_sum_ship_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).sum_shipping_qty, 0);
               -- �i�`�[�v�j���i���ʁi�o���j
    gt_req_edi_headers_data(in_line_cnt1).inv_indv_stock_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_indv_stock_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).indv_stockout_qty, 0);
               -- �i�`�[�v�j���i���ʁi�P�[�X�j
    gt_req_edi_headers_data(in_line_cnt1).inv_case_stock_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_case_stock_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).case_stockout_qty, 0);
               -- �i�`�[�v�j���i���ʁi�{�[���j
    gt_req_edi_headers_data(in_line_cnt1).inv_ball_stock_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_ball_stock_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).ball_stockout_qty, 0);
               -- �i�`�[�v�j���i���ʁi���v�A�o���j
    gt_req_edi_headers_data(in_line_cnt1).inv_sum_stock_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_sum_stock_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).sum_stockout_qty, 0);
               -- �i�`�[�v�j�P�[�X����
    gt_req_edi_headers_data(in_line_cnt1).inv_case_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_case_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).case_qty, 0);
               -- �i�`�[�v�j�I���R���i�o���j����
    gt_req_edi_headers_data(in_line_cnt1).inv_fold_cont_qty
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_fold_cont_qty, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).fold_container_indv_qty, 0);
               -- �i�`�[�v�j�������z�i�����j
    gt_req_edi_headers_data(in_line_cnt1).inv_order_cost_amt
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_order_cost_amt, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).order_cost_amt, 0);
               -- �i�`�[�v�j�������z�i�o�ׁj
    gt_req_edi_headers_data(in_line_cnt1).inv_ship_cost_amt
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_ship_cost_amt, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).shipping_cost_amt, 0);
               -- �i�`�[�v�j�������z�i���i�j
    gt_req_edi_headers_data(in_line_cnt1).inv_stock_cost_amt
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_stock_cost_amt, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).stockout_cost_amt, 0);
               -- �i�`�[�v�j�������z�i�����j
    gt_req_edi_headers_data(in_line_cnt1).inv_order_price_amt
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_order_price_amt, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).order_price_amt, 0);
               -- �i�`�[�v�j�������z�i�o�ׁj
    gt_req_edi_headers_data(in_line_cnt1).inv_ship_price_amt
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_ship_price_amt, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).shipping_price_amt, 0);
               -- �i�`�[�v�j�������z�i���i�j
    gt_req_edi_headers_data(in_line_cnt1).inv_stock_price_amt
            := NVL(gt_req_edi_headers_data(in_line_cnt1).inv_stock_price_amt, 0)
             + NVL(gt_edideli_work_data(in_line_cnt2).stockout_price_amt, 0);
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
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
  END xxcos_in_edi_headers_up;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_headers_edit
   * Description      : EDI�w�b�_���ϐ��̕ҏW(A-2)(1)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_headers_edit(
    in_line_cnt1    IN NUMBER,       --   LOOP�p�J�E���^1
    in_line_cnt     IN NUMBER,       --   LOOP�p�J�E���^2
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_headers_edit'; -- �v���O������
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
    ln_seq     NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
    -- EDI�w�b�_���ID���V�[�P���X����擾����
    SELECT xxcos_edi_headers_s01.NEXTVAL
    INTO   ln_seq
    FROM   dual;
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --* -------------------------------------------------------------------------------------------
    -- EDI�w�b�_���e�[�u���f�[�^�o�^�p�ϐ�(XXCOS_IN_EDI_HEADERS)
    --* -------------------------------------------------------------------------------------------
    -- EDI�w�b�_���ID
    gt_edi_header_info_id    := ln_seq;
    --
                -- EDI�w�b�_���ID
    gt_req_edi_headers_data(in_line_cnt1).edi_header_info_id   := ln_seq;
                -- �}�̋敪
    gt_req_edi_headers_data(in_line_cnt1).medium_class   := gt_edideli_work_data(in_line_cnt).medium_class;
                -- �f�[�^��R�[�h
    gt_req_edi_headers_data(in_line_cnt1).data_type_code := gt_edideli_work_data(in_line_cnt).data_type_code;
                -- �t�@�C���m��
    gt_req_edi_headers_data(in_line_cnt1).file_no        := gt_edideli_work_data(in_line_cnt).file_no;
                -- ���敪
    gt_req_edi_headers_data(in_line_cnt1).info_class     := gt_edideli_work_data(in_line_cnt).info_class;
                -- ������
    gt_req_edi_headers_data(in_line_cnt1).process_date   := gt_edideli_work_data(in_line_cnt).process_date;
                -- ��������
    gt_req_edi_headers_data(in_line_cnt1).process_time   := gt_edideli_work_data(in_line_cnt).process_time;
                -- ���_�i����j�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).base_code      := gt_edideli_work_data(in_line_cnt).base_code;
                -- ���_���i�������j
    gt_req_edi_headers_data(in_line_cnt1).base_name      := gt_edideli_work_data(in_line_cnt).base_name;
                -- ���_���i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).base_name_alt  := gt_edideli_work_data(in_line_cnt).base_name_alt;
                -- �d�c�h�`�F�[���X�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).edi_chain_code := gt_edideli_work_data(in_line_cnt).edi_chain_code;
                -- �d�c�h�`�F�[���X���i�����j
    gt_req_edi_headers_data(in_line_cnt1).edi_chain_name := gt_edideli_work_data(in_line_cnt).edi_chain_name;
                -- �d�c�h�`�F�[���X���i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).edi_chain_name_alt
                                                   := gt_edideli_work_data(in_line_cnt).edi_chain_name_alt;
                -- �`�F�[���X�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).chain_code     := gt_edideli_work_data(in_line_cnt).chain_code;
                -- �`�F�[���X���i�����j
    gt_req_edi_headers_data(in_line_cnt1).chain_name     := gt_edideli_work_data(in_line_cnt).chain_name;
                -- �`�F�[���X���i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).chain_name_alt := gt_edideli_work_data(in_line_cnt).chain_name_alt;
                -- ���[�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).report_code    := gt_edideli_work_data(in_line_cnt).report_code;
                -- ���[�\����
    gt_req_edi_headers_data(in_line_cnt1).report_show_name
                                                   := gt_edideli_work_data(in_line_cnt).report_show_name;
                -- �ڋq�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).customer_code  := gt_edideli_work_data(in_line_cnt).customer_code;
                -- �ڋq���i�����j
    gt_req_edi_headers_data(in_line_cnt1).customer_name  := gt_edideli_work_data(in_line_cnt).customer_name;
                -- �ڋq���i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).customer_name_alt
                                                   := gt_edideli_work_data(in_line_cnt).customer_name_alt;
                -- �ЃR�[�h
    gt_req_edi_headers_data(in_line_cnt1).company_code   := gt_edideli_work_data(in_line_cnt).company_code;
                -- �Ж��i�����j
    gt_req_edi_headers_data(in_line_cnt1).company_name   := gt_edideli_work_data(in_line_cnt).company_name;
                -- �Ж��i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).company_name_alt
                                                   := gt_edideli_work_data(in_line_cnt).company_name_alt;
                -- �X�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).shop_code      := gt_edideli_work_data(in_line_cnt).shop_code;
                -- �X���i�����j
    gt_req_edi_headers_data(in_line_cnt1).shop_name      := gt_edideli_work_data(in_line_cnt).shop_name;
                -- �X���i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).shop_name_alt  := gt_edideli_work_data(in_line_cnt).shop_name_alt;
                -- �[���Z���^�[�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).deli_center_code
                                                   := gt_edideli_work_data(in_line_cnt).delivery_center_code;
                -- �[���Z���^�[���i�����j
    gt_req_edi_headers_data(in_line_cnt1).deli_center_name
                                                   := gt_edideli_work_data(in_line_cnt).delivery_center_name;
                -- �[���Z���^�[���i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).deli_center_name_alt
                                                   := gt_edideli_work_data(in_line_cnt).delivery_center_name_alt;
                -- ������
    gt_req_edi_headers_data(in_line_cnt1).order_date     := gt_edideli_work_data(in_line_cnt).order_date;
                -- �Z���^�[�[�i��
    gt_req_edi_headers_data(in_line_cnt1).center_delivery_date
                                                   := gt_edideli_work_data(in_line_cnt).center_delivery_date;
                -- ���[�i��
    gt_req_edi_headers_data(in_line_cnt1).result_delivery_date
                                                   := gt_edideli_work_data(in_line_cnt).result_delivery_date;
                -- �X�ܔ[�i��
    gt_req_edi_headers_data(in_line_cnt1).shop_delivery_date
                                                   := gt_edideli_work_data(in_line_cnt).shop_delivery_date;
                -- �f�[�^�쐬���iEDI�f�[�^���j
    gt_req_edi_headers_data(in_line_cnt1).data_cd_edi_data
                                                   := gt_edideli_work_data(in_line_cnt).data_creation_date_edi_data;
                -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
    gt_req_edi_headers_data(in_line_cnt1).data_ct_edi_data
                                                   := gt_edideli_work_data(in_line_cnt).data_creation_time_edi_data;
                -- �`�[�敪
    gt_req_edi_headers_data(in_line_cnt1).invoice_class  := gt_edideli_work_data(in_line_cnt).invoice_class;
                -- �����ރR�[�h
    gt_req_edi_headers_data(in_line_cnt1).small_class_cd := gt_edideli_work_data(in_line_cnt).small_classification_code;
                -- �����ޖ�
    gt_req_edi_headers_data(in_line_cnt1).small_class_nm := gt_edideli_work_data(in_line_cnt).small_classification_name;
                -- �����ރR�[�h
    gt_req_edi_headers_data(in_line_cnt1).mid_class_cd   := gt_edideli_work_data(in_line_cnt).middle_classification_code;
                -- �����ޖ�
    gt_req_edi_headers_data(in_line_cnt1).mid_class_nm   := gt_edideli_work_data(in_line_cnt).middle_classification_name;
                -- �啪�ރR�[�h
    gt_req_edi_headers_data(in_line_cnt1).big_class_cd   := gt_edideli_work_data(in_line_cnt).big_classification_code;
                -- �啪�ޖ�
    gt_req_edi_headers_data(in_line_cnt1).big_class_nm   := gt_edideli_work_data(in_line_cnt).big_classification_name;
                -- ����敔��R�[�h
    gt_req_edi_headers_data(in_line_cnt1).other_par_dep_cd
                                                   := gt_edideli_work_data(in_line_cnt).other_party_department_code;
                -- ����攭���ԍ�
    gt_req_edi_headers_data(in_line_cnt1).other_par_order_num
                                                   := gt_edideli_work_data(in_line_cnt).other_party_order_number;
                -- �`�F�b�N�f�W�b�g�L���敪
    gt_req_edi_headers_data(in_line_cnt1).check_digit_class
                                                   := gt_edideli_work_data(in_line_cnt).check_digit_class;
                -- �`�[�ԍ�
    gt_req_edi_headers_data(in_line_cnt1).invoice_number := gt_edideli_work_data(in_line_cnt).invoice_number;
                -- �`�F�b�N�f�W�b�g
    gt_req_edi_headers_data(in_line_cnt1).check_digit    := gt_edideli_work_data(in_line_cnt).check_digit;
                -- ����
    gt_req_edi_headers_data(in_line_cnt1).close_date     := gt_edideli_work_data(in_line_cnt).close_date;
                -- �󒍂m���i�d�a�r�j
    gt_req_edi_headers_data(in_line_cnt1).order_no_ebs   := gt_edideli_work_data(in_line_cnt).order_no_ebs;
                -- �����敪
    gt_req_edi_headers_data(in_line_cnt1).ar_sale_class  := gt_edideli_work_data(in_line_cnt).ar_sale_class;
                -- �z���敪
    gt_req_edi_headers_data(in_line_cnt1).delivery_classe
                                                   := gt_edideli_work_data(in_line_cnt).delivery_classe;
                -- �ւm��
    gt_req_edi_headers_data(in_line_cnt1).opportunity_no := gt_edideli_work_data(in_line_cnt).opportunity_no;
                -- �A����
    gt_req_edi_headers_data(in_line_cnt1).contact_to     := gt_edideli_work_data(in_line_cnt).contact_to;
                -- ���[�g�Z�[���X
    gt_req_edi_headers_data(in_line_cnt1).route_sales    := gt_edideli_work_data(in_line_cnt).route_sales;
                -- �@�l�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).corporate_code := gt_edideli_work_data(in_line_cnt).corporate_code;
                -- ���[�J�[��
    gt_req_edi_headers_data(in_line_cnt1).maker_name     := gt_edideli_work_data(in_line_cnt).maker_name;
                -- �n��R�[�h
    gt_req_edi_headers_data(in_line_cnt1).area_code      := gt_edideli_work_data(in_line_cnt).area_code;
                -- �n�於�i�����j
    gt_req_edi_headers_data(in_line_cnt1).area_name      := gt_edideli_work_data(in_line_cnt).area_name;
                -- �n�於�i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).area_name_alt  := gt_edideli_work_data(in_line_cnt).area_name_alt;
                -- �����R�[�h
    gt_req_edi_headers_data(in_line_cnt1).vendor_code    := gt_edideli_work_data(in_line_cnt).vendor_code;
                -- ����於�i�����j
    gt_req_edi_headers_data(in_line_cnt1).vendor_name    := gt_edideli_work_data(in_line_cnt).vendor_name;
                -- ����於�P�i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).vendor_name1_alt
                                                   := gt_edideli_work_data(in_line_cnt).vendor_name1_alt;
                -- ����於�Q�i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).vendor_name2_alt
                                                   := gt_edideli_work_data(in_line_cnt).vendor_name2_alt;
                -- �����s�d�k
    gt_req_edi_headers_data(in_line_cnt1).vendor_tel     := gt_edideli_work_data(in_line_cnt).vendor_tel;
                -- �����S����
    gt_req_edi_headers_data(in_line_cnt1).vendor_charge  := gt_edideli_work_data(in_line_cnt).vendor_charge;
                -- �����Z���i�����j
    gt_req_edi_headers_data(in_line_cnt1).vendor_address := gt_edideli_work_data(in_line_cnt).vendor_address;
                -- �͂���R�[�h�i�ɓ����j
    gt_req_edi_headers_data(in_line_cnt1).deli_to_cd_itouen
                                                   := gt_edideli_work_data(in_line_cnt).deliver_to_code_itouen;
                -- �͂���R�[�h�i�`�F�[���X�j
    gt_req_edi_headers_data(in_line_cnt1).deli_to_cd_chain
                                                   := gt_edideli_work_data(in_line_cnt).deliver_to_code_chain;
                -- �͂���i�����j
    gt_req_edi_headers_data(in_line_cnt1).deli_to        := gt_edideli_work_data(in_line_cnt).deliver_to;
                -- �͂���P�i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).deli_to1_alt   := gt_edideli_work_data(in_line_cnt).deliver_to1_alt;
                -- �͂���Q�i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).deli_to2_alt   := gt_edideli_work_data(in_line_cnt).deliver_to2_alt;
                -- �͂���Z���i�����j
    gt_req_edi_headers_data(in_line_cnt1).deli_to_add    := gt_edideli_work_data(in_line_cnt).deliver_to_address;
                -- �͂���Z���i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).deli_to_add_alt
                                                   := gt_edideli_work_data(in_line_cnt).deliver_to_address_alt;
                -- �͂���s�d�k
    gt_req_edi_headers_data(in_line_cnt1).deli_to_tel    := gt_edideli_work_data(in_line_cnt).deliver_to_tel;
                -- ������R�[�h
    gt_req_edi_headers_data(in_line_cnt1).bal_accounts_cd
                                                   := gt_edideli_work_data(in_line_cnt).balance_accounts_code;
                -- ������ЃR�[�h
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_comp_cd
                                                   := gt_edideli_work_data(in_line_cnt).balance_accounts_company_code;
                -- ������X�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_shop_cd
                                                   := gt_edideli_work_data(in_line_cnt).balance_accounts_shop_code;
                -- �����於�i�����j
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_name   := gt_edideli_work_data(in_line_cnt).balance_accounts_name;
                -- �����於�i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_name_alt
                                                   := gt_edideli_work_data(in_line_cnt).balance_accounts_name_alt;
                -- ������Z���i�����j
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_add    := gt_edideli_work_data(in_line_cnt).balance_accounts_address;
                -- ������Z���i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_add_alt
                                                   := gt_edideli_work_data(in_line_cnt).balance_accounts_address_alt;
                -- ������s�d�k
    gt_req_edi_headers_data(in_line_cnt1).bal_acc_tel    := gt_edideli_work_data(in_line_cnt).balance_accounts_tel;
                -- �󒍉\��
    gt_req_edi_headers_data(in_line_cnt1).order_possible_date
                                                   := gt_edideli_work_data(in_line_cnt).order_possible_date;
                -- ���e�\��
    gt_req_edi_headers_data(in_line_cnt1).perm_poss_date := gt_edideli_work_data(in_line_cnt).permission_possible_date;
                -- ����N����
    gt_req_edi_headers_data(in_line_cnt1).forward_month  := gt_edideli_work_data(in_line_cnt).forward_month;
                -- �x�����ϓ�
    gt_req_edi_headers_data(in_line_cnt1).pay_settl_date := gt_edideli_work_data(in_line_cnt).payment_settlement_date;
                -- �`���V�J�n��
    gt_req_edi_headers_data(in_line_cnt1).hand_st_date_act
                                                   := gt_edideli_work_data(in_line_cnt).handbill_start_date_active;
                -- ��������
    gt_req_edi_headers_data(in_line_cnt1).billing_due_date
                                                   := gt_edideli_work_data(in_line_cnt).billing_due_date;
                -- �o�׎���
    gt_req_edi_headers_data(in_line_cnt1).shipping_time  := gt_edideli_work_data(in_line_cnt).shipping_time;
                -- �[�i�\�莞��
    gt_req_edi_headers_data(in_line_cnt1).deli_schedule_time
                                                   := gt_edideli_work_data(in_line_cnt).delivery_schedule_time;
                -- ��������
    gt_req_edi_headers_data(in_line_cnt1).order_time     := gt_edideli_work_data(in_line_cnt).order_time;
                -- �ėp���t���ڂP
    gt_req_edi_headers_data(in_line_cnt1).general_date_item1
                                                   := gt_edideli_work_data(in_line_cnt).general_date_item1;
                -- �ėp���t���ڂQ
    gt_req_edi_headers_data(in_line_cnt1).general_date_item2
                                                   := gt_edideli_work_data(in_line_cnt).general_date_item2;
                -- �ėp���t���ڂR
    gt_req_edi_headers_data(in_line_cnt1).general_date_item3
                                                   := gt_edideli_work_data(in_line_cnt).general_date_item3;
                -- �ėp���t���ڂS
    gt_req_edi_headers_data(in_line_cnt1).general_date_item4
                                                   := gt_edideli_work_data(in_line_cnt).general_date_item4;
                -- �ėp���t���ڂT
    gt_req_edi_headers_data(in_line_cnt1).general_date_item5
                                                   := gt_edideli_work_data(in_line_cnt).general_date_item5;
                -- ���o�׋敪
    gt_req_edi_headers_data(in_line_cnt1).arr_shipping_class
                                                   := gt_edideli_work_data(in_line_cnt).arrival_shipping_class;
                -- �����敪
    gt_req_edi_headers_data(in_line_cnt1).vendor_class   := gt_edideli_work_data(in_line_cnt).vendor_class;
                -- �`�[����敪
    gt_req_edi_headers_data(in_line_cnt1).inv_detailed_class
                                                   := gt_edideli_work_data(in_line_cnt).invoice_detailed_class;
                -- �P���g�p�敪
    gt_req_edi_headers_data(in_line_cnt1).unit_price_use_class
                                                   := gt_edideli_work_data(in_line_cnt).unit_price_use_class;
                -- �T�u�����Z���^�[�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).sub_dist_center_cd
                                                   := gt_edideli_work_data(in_line_cnt).sub_distribution_center_code;
                -- �T�u�����Z���^�[�R�[�h��
    gt_req_edi_headers_data(in_line_cnt1).sub_dist_center_nm
                                                   := gt_edideli_work_data(in_line_cnt).sub_distribution_center_name;
                -- �Z���^�[�[�i���@
    gt_req_edi_headers_data(in_line_cnt1).center_deli_method
                                                   := gt_edideli_work_data(in_line_cnt).center_delivery_method;
                -- �Z���^�[���p�敪
    gt_req_edi_headers_data(in_line_cnt1).center_use_class
                                                   := gt_edideli_work_data(in_line_cnt).center_use_class;
                -- �Z���^�[�q�ɋ敪
    gt_req_edi_headers_data(in_line_cnt1).center_whse_class
                                                   := gt_edideli_work_data(in_line_cnt).center_whse_class;
                -- �Z���^�[�n��敪
    gt_req_edi_headers_data(in_line_cnt1).center_area_class
                                                   := gt_edideli_work_data(in_line_cnt).center_area_class;
                -- �Z���^�[���׋敪
    gt_req_edi_headers_data(in_line_cnt1).center_arr_class
                                                   := gt_edideli_work_data(in_line_cnt).center_arrival_class;
                -- �f�|�敪
    gt_req_edi_headers_data(in_line_cnt1).depot_class    := gt_edideli_work_data(in_line_cnt).depot_class;
                -- �s�b�c�b�敪
    gt_req_edi_headers_data(in_line_cnt1).tcdc_class     := gt_edideli_work_data(in_line_cnt).tcdc_class;
                -- �t�o�b�t���O
    gt_req_edi_headers_data(in_line_cnt1).upc_flag       := gt_edideli_work_data(in_line_cnt).upc_flag;
                -- ��ċ敪
    gt_req_edi_headers_data(in_line_cnt1).simultaneously_cls
                                                   := gt_edideli_work_data(in_line_cnt).simultaneously_class;
                -- �Ɩ��h�c
    gt_req_edi_headers_data(in_line_cnt1).business_id    := gt_edideli_work_data(in_line_cnt).business_id;
                -- �q���敪
    gt_req_edi_headers_data(in_line_cnt1).whse_directly_cls
                                                   := gt_edideli_work_data(in_line_cnt).whse_directly_class;
                -- �i�i���ߋ敪
    gt_req_edi_headers_data(in_line_cnt1).premium_rebate_cls
                                                   := gt_edideli_work_data(in_line_cnt).premium_rebate_class;
                -- ���ڎ��
    gt_req_edi_headers_data(in_line_cnt1).item_type      := gt_edideli_work_data(in_line_cnt).item_type;
                -- �߉ƐH�敪
    gt_req_edi_headers_data(in_line_cnt1).cloth_hous_fod_cls
                                                   := gt_edideli_work_data(in_line_cnt).cloth_house_food_class;
                -- ���݋敪
    gt_req_edi_headers_data(in_line_cnt1).mix_class      := gt_edideli_work_data(in_line_cnt).mix_class;
                -- �݌ɋ敪
    gt_req_edi_headers_data(in_line_cnt1).stk_class      := gt_edideli_work_data(in_line_cnt).stk_class;
                -- �ŏI�C���ꏊ�敪
    gt_req_edi_headers_data(in_line_cnt1).last_mod_site_cls
                                                   := gt_edideli_work_data(in_line_cnt).last_modify_site_class;
                -- ���[�敪
    gt_req_edi_headers_data(in_line_cnt1).report_class   := gt_edideli_work_data(in_line_cnt).report_class;
                -- �ǉ��E�v��敪
    gt_req_edi_headers_data(in_line_cnt1).add_plan_cls   := gt_edideli_work_data(in_line_cnt).addition_plan_class;
                -- �o�^�敪
    gt_req_edi_headers_data(in_line_cnt1).registration_class
                                                   := gt_edideli_work_data(in_line_cnt).registration_class;
                -- ����敪
    gt_req_edi_headers_data(in_line_cnt1).specific_class := gt_edideli_work_data(in_line_cnt).specific_class;
                -- ����敪
    gt_req_edi_headers_data(in_line_cnt1).dealings_class := gt_edideli_work_data(in_line_cnt).dealings_class;
                -- �����敪
    gt_req_edi_headers_data(in_line_cnt1).order_class    := gt_edideli_work_data(in_line_cnt).order_class;
                -- �W�v���׋敪
    gt_req_edi_headers_data(in_line_cnt1).sum_line_class := gt_edideli_work_data(in_line_cnt).sum_line_class;
                -- �o�׈ē��ȊO�敪
    gt_req_edi_headers_data(in_line_cnt1).ship_guidance_cls
                                                   := gt_edideli_work_data(in_line_cnt).shipping_guidance_class;
                -- �o�׋敪
    gt_req_edi_headers_data(in_line_cnt1).shipping_class := gt_edideli_work_data(in_line_cnt).shipping_class;
                -- ���i�R�[�h�g�p�敪
    gt_req_edi_headers_data(in_line_cnt1).prod_cd_use_cls
                                                   := gt_edideli_work_data(in_line_cnt).product_code_use_class;
                -- �ϑ��i�敪
    gt_req_edi_headers_data(in_line_cnt1).cargo_item_class
                                                   := gt_edideli_work_data(in_line_cnt).cargo_item_class;
                -- �s�^�`�敪
    gt_req_edi_headers_data(in_line_cnt1).ta_class       := gt_edideli_work_data(in_line_cnt).ta_class;
                -- ���R�[�h
    gt_req_edi_headers_data(in_line_cnt1).plan_code      := gt_edideli_work_data(in_line_cnt).plan_code;
                -- �J�e�S���[�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).category_code  := gt_edideli_work_data(in_line_cnt).category_code;
                -- �J�e�S���[�敪
    gt_req_edi_headers_data(in_line_cnt1).category_class := gt_edideli_work_data(in_line_cnt).category_class;
                -- �^����i
    gt_req_edi_headers_data(in_line_cnt1).carrier_means  := gt_edideli_work_data(in_line_cnt).carrier_means;
                -- ����R�[�h
    gt_req_edi_headers_data(in_line_cnt1).counter_code   := gt_edideli_work_data(in_line_cnt).counter_code;
                -- �ړ��T�C��
    gt_req_edi_headers_data(in_line_cnt1).move_sign      := gt_edideli_work_data(in_line_cnt).move_sign;
                -- �d�n�r�E�菑�敪
    gt_req_edi_headers_data(in_line_cnt1).eos_handwrit_cls
                                                   := gt_edideli_work_data(in_line_cnt).eos_handwriting_class;
                -- �[�i��ۃR�[�h
    gt_req_edi_headers_data(in_line_cnt1).deli_to_section_cd
                                                   := gt_edideli_work_data(in_line_cnt).delivery_to_section_code;
                -- �`�[����
    gt_req_edi_headers_data(in_line_cnt1).invoice_detailed
                                                   := gt_edideli_work_data(in_line_cnt).invoice_detailed;
                -- �Y�t��
    gt_req_edi_headers_data(in_line_cnt1).attach_qty     := gt_edideli_work_data(in_line_cnt).attach_qty;
                -- �t���A
    gt_req_edi_headers_data(in_line_cnt1).other_party_floor
                                                   := gt_edideli_work_data(in_line_cnt).other_party_floor;
                -- �s�d�w�s�m��
    gt_req_edi_headers_data(in_line_cnt1).text_no        := gt_edideli_work_data(in_line_cnt).text_no;
                -- �C���X�g�A�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).in_store_code  := gt_edideli_work_data(in_line_cnt).in_store_code;
                -- �^�O
    gt_req_edi_headers_data(in_line_cnt1).tag_data       := gt_edideli_work_data(in_line_cnt).tag_data;
                -- ����
    gt_req_edi_headers_data(in_line_cnt1).competition_code
                                                   := gt_edideli_work_data(in_line_cnt).competition_code;
                -- ��������
    gt_req_edi_headers_data(in_line_cnt1).billing_chair  := gt_edideli_work_data(in_line_cnt).billing_chair;
                -- �`�F�[���X�g�A�[�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).chain_store_code
                                                   := gt_edideli_work_data(in_line_cnt).chain_store_code;
                -- �`�F�[���X�g�A�[�R�[�h��������
    gt_req_edi_headers_data(in_line_cnt1).chain_st_sh_name
                                                   := gt_edideli_work_data(in_line_cnt).chain_store_short_name;
                -- ���z���^���旿
    gt_req_edi_headers_data(in_line_cnt1).dir_deli_rcpt_fee
                                                   := gt_edideli_work_data(in_line_cnt).direct_delivery_rcpt_fee;
                -- ��`���
    gt_req_edi_headers_data(in_line_cnt1).bill_info      := gt_edideli_work_data(in_line_cnt).bill_info;
                -- �E�v
    gt_req_edi_headers_data(in_line_cnt1).description    := gt_edideli_work_data(in_line_cnt).description;
                -- �����R�[�h
    gt_req_edi_headers_data(in_line_cnt1).interior_code  := gt_edideli_work_data(in_line_cnt).interior_code;
                -- �������@�[�i�J�e�S���[
    gt_req_edi_headers_data(in_line_cnt1).order_in_deli_cate
                                                   := gt_edideli_work_data(in_line_cnt).order_info_delivery_category;
                -- �d���`��
    gt_req_edi_headers_data(in_line_cnt1).purchase_type  := gt_edideli_work_data(in_line_cnt).purchase_type;
                -- �[�i�ꏊ���i�J�i�j
    gt_req_edi_headers_data(in_line_cnt1).deli_to_name_alt
                                                   := gt_edideli_work_data(in_line_cnt).delivery_to_name_alt;
                -- �X�o�ꏊ
    gt_req_edi_headers_data(in_line_cnt1).shop_opened_site
                                                   := gt_edideli_work_data(in_line_cnt).shop_opened_site;
                -- ���ꖼ
    gt_req_edi_headers_data(in_line_cnt1).counter_name   := gt_edideli_work_data(in_line_cnt).counter_name;
                -- �����ԍ�
    gt_req_edi_headers_data(in_line_cnt1).extension_number
                                                   := gt_edideli_work_data(in_line_cnt).extension_number;
                -- �S���Җ�
    gt_req_edi_headers_data(in_line_cnt1).charge_name    := gt_edideli_work_data(in_line_cnt).charge_name;
                -- �l�D
    gt_req_edi_headers_data(in_line_cnt1).price_tag      := gt_edideli_work_data(in_line_cnt).price_tag;
                -- �Ŏ�
    gt_req_edi_headers_data(in_line_cnt1).tax_type       := gt_edideli_work_data(in_line_cnt).tax_type;
                -- ����ŋ敪
    gt_req_edi_headers_data(in_line_cnt1).consump_tax_cls
                                                   := gt_edideli_work_data(in_line_cnt).consumption_tax_class;
                -- �a�q
    gt_req_edi_headers_data(in_line_cnt1).brand_class    := gt_edideli_work_data(in_line_cnt).brand_class;
                -- �h�c�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).id_code        := gt_edideli_work_data(in_line_cnt).id_code;
                -- �S�ݓX�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).department_code
                                                   := gt_edideli_work_data(in_line_cnt).department_code;
                -- �S�ݓX��
    gt_req_edi_headers_data(in_line_cnt1).department_name
                                                   := gt_edideli_work_data(in_line_cnt).department_name;
                -- �i�ʔԍ�
    gt_req_edi_headers_data(in_line_cnt1).item_type_number
                                                   := gt_edideli_work_data(in_line_cnt).item_type_number;
                -- �E�v�i�S�ݓX�j
    gt_req_edi_headers_data(in_line_cnt1).description_depart
                                                   := gt_edideli_work_data(in_line_cnt).description_department;
                -- �l�D���@
    gt_req_edi_headers_data(in_line_cnt1).price_tag_method
                                                   := gt_edideli_work_data(in_line_cnt).price_tag_method;
                -- ���R��
    gt_req_edi_headers_data(in_line_cnt1).reason_column  := gt_edideli_work_data(in_line_cnt).reason_column;
                -- �`���w�b�_
    gt_req_edi_headers_data(in_line_cnt1).a_column_header
                                                   := gt_edideli_work_data(in_line_cnt).a_column_header;
                -- �c���w�b�_
    gt_req_edi_headers_data(in_line_cnt1).d_column_header
                                                   := gt_edideli_work_data(in_line_cnt).d_column_header;
                -- �u�����h�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).brand_code     := gt_edideli_work_data(in_line_cnt).brand_code;
                -- ���C���R�[�h
    gt_req_edi_headers_data(in_line_cnt1).line_code      := gt_edideli_work_data(in_line_cnt).line_code;
                -- �N���X�R�[�h
    gt_req_edi_headers_data(in_line_cnt1).class_code     := gt_edideli_work_data(in_line_cnt).class_code;
                -- �`�|�P��
    gt_req_edi_headers_data(in_line_cnt1).a1_column      := gt_edideli_work_data(in_line_cnt).a1_column;
                -- �a�|�P��
    gt_req_edi_headers_data(in_line_cnt1).b1_column      := gt_edideli_work_data(in_line_cnt).b1_column;
                -- �b�|�P��
    gt_req_edi_headers_data(in_line_cnt1).c1_column      := gt_edideli_work_data(in_line_cnt).c1_column;
                -- �c�|�P��
    gt_req_edi_headers_data(in_line_cnt1).d1_column      := gt_edideli_work_data(in_line_cnt).d1_column;
                -- �d�|�P��
    gt_req_edi_headers_data(in_line_cnt1).e1_column      := gt_edideli_work_data(in_line_cnt).e1_column;
                -- �`�|�Q��
    gt_req_edi_headers_data(in_line_cnt1).a2_column      := gt_edideli_work_data(in_line_cnt).a2_column;
                -- �a�|�Q��
    gt_req_edi_headers_data(in_line_cnt1).b2_column      := gt_edideli_work_data(in_line_cnt).b2_column;
                -- �b�|�Q��
    gt_req_edi_headers_data(in_line_cnt1).c2_column      := gt_edideli_work_data(in_line_cnt).c2_column;
                -- �c�|�Q��
    gt_req_edi_headers_data(in_line_cnt1).d2_column      := gt_edideli_work_data(in_line_cnt).d2_column;
                -- �d�|�Q��
    gt_req_edi_headers_data(in_line_cnt1).e2_column      := gt_edideli_work_data(in_line_cnt).e2_column;
                -- �`�|�R��
    gt_req_edi_headers_data(in_line_cnt1).a3_column      := gt_edideli_work_data(in_line_cnt).a3_column;
                -- �a�|�R��
    gt_req_edi_headers_data(in_line_cnt1).b3_column      := gt_edideli_work_data(in_line_cnt).b3_column;
                -- �b�|�R��
    gt_req_edi_headers_data(in_line_cnt1).c3_column      := gt_edideli_work_data(in_line_cnt).c3_column;
                -- �c�|�R��
    gt_req_edi_headers_data(in_line_cnt1).d3_column      := gt_edideli_work_data(in_line_cnt).d3_column;
                -- �d�|�R��
    gt_req_edi_headers_data(in_line_cnt1).e3_column      := gt_edideli_work_data(in_line_cnt).e3_column;
                -- �e�|�P��
    gt_req_edi_headers_data(in_line_cnt1).f1_column      := gt_edideli_work_data(in_line_cnt).f1_column;
                -- �f�|�P��
    gt_req_edi_headers_data(in_line_cnt1).g1_column      := gt_edideli_work_data(in_line_cnt).g1_column;
                -- �g�|�P��
    gt_req_edi_headers_data(in_line_cnt1).h1_column      := gt_edideli_work_data(in_line_cnt).h1_column;
                -- �h�|�P��
    gt_req_edi_headers_data(in_line_cnt1).i1_column      := gt_edideli_work_data(in_line_cnt).i1_column;
                -- �i�|�P��
    gt_req_edi_headers_data(in_line_cnt1).j1_column      := gt_edideli_work_data(in_line_cnt).j1_column;
                -- �j�|�P��
    gt_req_edi_headers_data(in_line_cnt1).k1_column      := gt_edideli_work_data(in_line_cnt).k1_column;
                -- �k�|�P��
    gt_req_edi_headers_data(in_line_cnt1).l1_column      := gt_edideli_work_data(in_line_cnt).l1_column;
                -- �e�|�Q��
    gt_req_edi_headers_data(in_line_cnt1).f2_column      := gt_edideli_work_data(in_line_cnt).f2_column;
                -- �f�|�Q��
    gt_req_edi_headers_data(in_line_cnt1).g2_column      := gt_edideli_work_data(in_line_cnt).g2_column;
                -- �g�|�Q��
    gt_req_edi_headers_data(in_line_cnt1).h2_column      := gt_edideli_work_data(in_line_cnt).h2_column;
                -- �h�|�Q��
    gt_req_edi_headers_data(in_line_cnt1).i2_column      := gt_edideli_work_data(in_line_cnt).i2_column;
                -- �i�|�Q��
    gt_req_edi_headers_data(in_line_cnt1).j2_column      := gt_edideli_work_data(in_line_cnt).j2_column;
                -- �j�|�Q��
    gt_req_edi_headers_data(in_line_cnt1).k2_column      := gt_edideli_work_data(in_line_cnt).k2_column;
                -- �k�|�Q��
    gt_req_edi_headers_data(in_line_cnt1).l2_column      := gt_edideli_work_data(in_line_cnt).l2_column;
                -- �e�|�R��
    gt_req_edi_headers_data(in_line_cnt1).f3_column      := gt_edideli_work_data(in_line_cnt).f3_column;
                -- �f�|�R��
    gt_req_edi_headers_data(in_line_cnt1).g3_column      := gt_edideli_work_data(in_line_cnt).g3_column;
                -- �g�|�R��
    gt_req_edi_headers_data(in_line_cnt1).h3_column      := gt_edideli_work_data(in_line_cnt).h3_column;
                -- �h�|�R��
    gt_req_edi_headers_data(in_line_cnt1).i3_column      := gt_edideli_work_data(in_line_cnt).i3_column;
                -- �i�|�R��
    gt_req_edi_headers_data(in_line_cnt1).j3_column      := gt_edideli_work_data(in_line_cnt).j3_column;
                -- �j�|�R��
    gt_req_edi_headers_data(in_line_cnt1).k3_column      := gt_edideli_work_data(in_line_cnt).k3_column;
                -- �k�|�R��
    gt_req_edi_headers_data(in_line_cnt1).l3_column      := gt_edideli_work_data(in_line_cnt).l3_column;
                -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
-- 2010/04/23 v1.8 T.Yoshimoto Mod Start �{�ғ�#2427
--    gt_req_edi_headers_data(in_line_cnt1).chain_pecarea_head
    gt_req_edi_headers_data(in_line_cnt1).chain_pe_area_head
-- 2010/04/23 v1.8 T.Yoshimoto Mod End �{�ғ�#2427
                                                   := gt_edideli_work_data(in_line_cnt).chain_peculiar_area_header;
                -- �󒍊֘A�ԍ�
    gt_req_edi_headers_data(in_line_cnt1).order_connect_num
                                                   := gt_edideli_work_data(in_line_cnt).order_connection_number;
                -- �i�����v�j�������ʁi�o���j
    gt_req_edi_headers_data(in_line_cnt1).tot_indv_order_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_indv_order_qty;
                -- �i�����v�j�������ʁi�P�[�X�j
    gt_req_edi_headers_data(in_line_cnt1).tot_case_order_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_case_order_qty;
                -- �i�����v�j�������ʁi�{�[���j
    gt_req_edi_headers_data(in_line_cnt1).tot_ball_order_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_ball_order_qty;
                -- �i�����v�j�������ʁi���v�A�o���j
    gt_req_edi_headers_data(in_line_cnt1).tot_sum_order_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_sum_order_qty;
                -- �i�����v�j�o�א��ʁi�o���j
    gt_req_edi_headers_data(in_line_cnt1).tot_indv_ship_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_indv_shipping_qty;
                -- �i�����v�j�o�א��ʁi�P�[�X�j
    gt_req_edi_headers_data(in_line_cnt1).tot_case_ship_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_case_shipping_qty;
                -- �i�����v�j�o�א��ʁi�{�[���j
    gt_req_edi_headers_data(in_line_cnt1).tot_ball_ship_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_ball_shipping_qty;
                -- �i�����v�j�o�א��ʁi�p���b�g�j
    gt_req_edi_headers_data(in_line_cnt1).tot_pallet_ship_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_pallet_shipping_qty;
                -- �i�����v�j�o�א��ʁi���v�A�o���j
    gt_req_edi_headers_data(in_line_cnt1).tot_sum_ship_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_sum_shipping_qty;
                -- �i�����v�j���i���ʁi�o���j
    gt_req_edi_headers_data(in_line_cnt1).tot_indv_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_indv_stockout_qty;
                -- �i�����v�j���i���ʁi�P�[�X�j
    gt_req_edi_headers_data(in_line_cnt1).tot_case_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_case_stockout_qty;
                -- �i�����v�j���i���ʁi�{�[���j
    gt_req_edi_headers_data(in_line_cnt1).tot_ball_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_ball_stockout_qty;
                -- �i�����v�j���i���ʁi���v�A�o���j
    gt_req_edi_headers_data(in_line_cnt1).tot_sum_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_sum_stockout_qty;
                -- �i�����v�j�P�[�X����
    gt_req_edi_headers_data(in_line_cnt1).tot_case_qty   := gt_edideli_work_data(in_line_cnt).total_case_qty;
                -- �i�����v�j�I���R���i�o���j����
    gt_req_edi_headers_data(in_line_cnt1).tot_fold_container_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_fold_container_qty;
                -- �i�����v�j�������z�i�����j
    gt_req_edi_headers_data(in_line_cnt1).tot_order_cost_amt
                                                   := gt_edideli_work_data(in_line_cnt).total_order_cost_amt;
                -- �i�����v�j�������z�i�o�ׁj
    gt_req_edi_headers_data(in_line_cnt1).tot_ship_cost_amt
                                                   := gt_edideli_work_data(in_line_cnt).total_shipping_cost_amt;
                -- �i�����v�j�������z�i���i�j
    gt_req_edi_headers_data(in_line_cnt1).tot_stockout_cost_amt
                                                   := gt_edideli_work_data(in_line_cnt).total_stockout_cost_amt;
                -- �i�����v�j�������z�i�����j
    gt_req_edi_headers_data(in_line_cnt1).tot_order_price_amt
                                                   := gt_edideli_work_data(in_line_cnt).total_order_price_amt;
                -- �i�����v�j�������z�i�o�ׁj
    gt_req_edi_headers_data(in_line_cnt1).tot_ship_price_amt
                                                   := gt_edideli_work_data(in_line_cnt).total_shipping_price_amt;
                -- �i�����v�j�������z�i���i�j
    gt_req_edi_headers_data(in_line_cnt1).tot_stockout_price_amt
                                                   := gt_edideli_work_data(in_line_cnt).total_stockout_price_amt;
                -- �g�[�^���s��
    gt_req_edi_headers_data(in_line_cnt1).tot_line_qty   := gt_edideli_work_data(in_line_cnt).total_line_qty;
                -- �g�[�^���`�[����
    gt_req_edi_headers_data(in_line_cnt1).tot_invoice_qty
                                                   := gt_edideli_work_data(in_line_cnt).total_invoice_qty;
                -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
    gt_req_edi_headers_data(in_line_cnt1).chain_pe_area_foot
                                                   := gt_edideli_work_data(in_line_cnt).chain_peculiar_area_footer;
/* 2011/07/26 Ver1.9 Add Start */
                --���ʂa�l�r�w�b�_�f�[�^
    gt_req_edi_headers_data(in_line_cnt1).bms_header_data
                                                   := gt_edideli_work_data(in_line_cnt).bms_header_data;
/* 2011/07/26 Ver1.9 Add End   */
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END xxcos_in_edi_headers_edit;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_lists_edit
   * Description      : EDI���׏��ϐ��̕ҏW(A-2)(2)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_lists_edit(
    in_line_cnt    IN NUMBER,       --   LOOP�p�J�E���^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_lists_edit'; -- �v���O������
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
    ln_seq     NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
    -- EDI���׏��ID���V�[�P���X����擾����
    SELECT xxcos_edi_lines_s01.NEXTVAL
    INTO   ln_seq
    FROM   dual;
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  --
  --* -------------------------------------------------------------------------------------------
  -- EDI���׏��e�[�u���f�[�^�o�^�p�ϐ�(XXCOS_IN_EDI_LINES)
  --* -------------------------------------------------------------------------------------------
    gt_req_edi_lines_data(in_line_cnt).edi_line_info_id    := ln_seq;                     -- EDI���׏��ID
    gt_req_edi_lines_data(in_line_cnt).invoice_number      := gt_head_invoice_number_key; -- �`�[�ԍ�
    gt_req_edi_lines_data(in_line_cnt).edi_header_info_id  := gt_edi_header_info_id;      -- EDI�w�b�_���ID
                -- �s�m��
    gt_req_edi_lines_data(in_line_cnt).line_no          := gt_edideli_work_data(in_line_cnt).line_no;
                -- ���i�敪
    gt_req_edi_lines_data(in_line_cnt).stockout_class   := gt_edideli_work_data(in_line_cnt).stockout_class;
                -- ���i���R
    gt_req_edi_lines_data(in_line_cnt).stockout_reason  := gt_edideli_work_data(in_line_cnt).stockout_reason;
                -- ���i�R�[�h�i�ɓ����j
    gt_req_edi_lines_data(in_line_cnt).product_code_itouen
                                                   := gt_edideli_work_data(in_line_cnt).product_code_itouen;
                -- ���i�R�[�h�P
    gt_req_edi_lines_data(in_line_cnt).product_code1    := gt_edideli_work_data(in_line_cnt).product_code1;
                -- ���i�R�[�h�Q
    gt_req_edi_lines_data(in_line_cnt).product_code2    := gt_edideli_work_data(in_line_cnt).product_code2;
                -- �i�`�m�R�[�h
    gt_req_edi_lines_data(in_line_cnt).jan_code         := gt_edideli_work_data(in_line_cnt).jan_code;
                -- �h�s�e�R�[�h
    gt_req_edi_lines_data(in_line_cnt).itf_code         := gt_edideli_work_data(in_line_cnt).itf_code;
                -- �����h�s�e�R�[�h
    gt_req_edi_lines_data(in_line_cnt).extension_itf_code
                                                   := gt_edideli_work_data(in_line_cnt).extension_itf_code;
                -- �P�[�X���i�R�[�h
    gt_req_edi_lines_data(in_line_cnt).case_product_code
                                                   := gt_edideli_work_data(in_line_cnt).case_product_code;
                -- �{�[�����i�R�[�h
    gt_req_edi_lines_data(in_line_cnt).ball_product_code
                                                   := gt_edideli_work_data(in_line_cnt).ball_product_code;
                -- ���i�R�[�h�i��
    gt_req_edi_lines_data(in_line_cnt).prod_cd_item_type
                                                   := gt_edideli_work_data(in_line_cnt).product_code_item_type;
                -- ���i�敪
    gt_req_edi_lines_data(in_line_cnt).prod_class       := gt_edideli_work_data(in_line_cnt).prod_class;
                -- ���i���i�����j
    gt_req_edi_lines_data(in_line_cnt).product_name     := gt_edideli_work_data(in_line_cnt).product_name;
                -- ���i���Q�i�J�i�j
    gt_req_edi_lines_data(in_line_cnt).product_name1_alt
                                                   := gt_edideli_work_data(in_line_cnt).product_name1_alt;
                -- ���i���Q�i�J�i�j
    gt_req_edi_lines_data(in_line_cnt).product_name2_alt
                                                   := gt_edideli_work_data(in_line_cnt).product_name2_alt;
                -- �K�i�P
    gt_req_edi_lines_data(in_line_cnt).item_standard1   := gt_edideli_work_data(in_line_cnt).item_standard1;
                -- �K�i�Q
    gt_req_edi_lines_data(in_line_cnt).item_standard2   := gt_edideli_work_data(in_line_cnt).item_standard2;
                -- ����
    gt_req_edi_lines_data(in_line_cnt).qty_in_case      := gt_edideli_work_data(in_line_cnt).qty_in_case;
                -- �P�[�X����
    gt_req_edi_lines_data(in_line_cnt).num_of_cases     := gt_edideli_work_data(in_line_cnt).num_of_cases;
                -- �{�[������
    gt_req_edi_lines_data(in_line_cnt).num_of_ball      := gt_edideli_work_data(in_line_cnt).num_of_ball;
                -- �F
    gt_req_edi_lines_data(in_line_cnt).item_color       := gt_edideli_work_data(in_line_cnt).item_color;
                -- �T�C�Y
    gt_req_edi_lines_data(in_line_cnt).item_size        := gt_edideli_work_data(in_line_cnt).item_size;
                -- �ܖ�������
    gt_req_edi_lines_data(in_line_cnt).expiration_date  := gt_edideli_work_data(in_line_cnt).expiration_date;
                -- ������
    gt_req_edi_lines_data(in_line_cnt).product_date     := gt_edideli_work_data(in_line_cnt).product_date;
                -- �����P�ʐ�
    gt_req_edi_lines_data(in_line_cnt).order_uom_qty    := gt_edideli_work_data(in_line_cnt).order_uom_qty;
                -- �o�גP�ʐ�
    gt_req_edi_lines_data(in_line_cnt).ship_uom_qty     := gt_edideli_work_data(in_line_cnt).shipping_uom_qty;
                -- ����P�ʐ�
    gt_req_edi_lines_data(in_line_cnt).packing_uom_qty  := gt_edideli_work_data(in_line_cnt).packing_uom_qty;
                -- ����
    gt_req_edi_lines_data(in_line_cnt).deal_code        := gt_edideli_work_data(in_line_cnt).deal_code;
                -- �����敪
    gt_req_edi_lines_data(in_line_cnt).deal_class       := gt_edideli_work_data(in_line_cnt).deal_class;
                -- �ƍ�
    gt_req_edi_lines_data(in_line_cnt).collation_code   := gt_edideli_work_data(in_line_cnt).collation_code;
                -- �P��
    gt_req_edi_lines_data(in_line_cnt).uom_code         := gt_edideli_work_data(in_line_cnt).uom_code;
                -- �P���敪
    gt_req_edi_lines_data(in_line_cnt).unit_price_class := gt_edideli_work_data(in_line_cnt).unit_price_class;
                -- �e����ԍ�
    gt_req_edi_lines_data(in_line_cnt).parent_pack_num  := gt_edideli_work_data(in_line_cnt).parent_packing_number;
                -- ����ԍ�
    gt_req_edi_lines_data(in_line_cnt).packing_number   := gt_edideli_work_data(in_line_cnt).packing_number;
                -- ���i�Q�R�[�h
    gt_req_edi_lines_data(in_line_cnt).product_group_code
                                                   := gt_edideli_work_data(in_line_cnt).product_group_code;
                -- �P�[�X��̕s�t���O
    gt_req_edi_lines_data(in_line_cnt).case_dismantle_flag
                                                   := gt_edideli_work_data(in_line_cnt).case_dismantle_flag;
                -- �P�[�X�敪
    gt_req_edi_lines_data(in_line_cnt).case_class       := gt_edideli_work_data(in_line_cnt).case_class;
                -- �������ʁi�o���j
    gt_req_edi_lines_data(in_line_cnt).indv_order_qty   := gt_edideli_work_data(in_line_cnt).indv_order_qty;
                -- �������ʁi�P�[�X�j
    gt_req_edi_lines_data(in_line_cnt).case_order_qty   := gt_edideli_work_data(in_line_cnt).case_order_qty;
                -- �������ʁi�{�[���j
    gt_req_edi_lines_data(in_line_cnt).ball_order_qty   := gt_edideli_work_data(in_line_cnt).ball_order_qty;
                -- �������ʁi���v�A�o���j
    gt_req_edi_lines_data(in_line_cnt).sum_order_qty    := gt_edideli_work_data(in_line_cnt).sum_order_qty;
                -- �o�א��ʁi�o���j
    gt_req_edi_lines_data(in_line_cnt).indv_shipping_qty
                                                   := gt_edideli_work_data(in_line_cnt).indv_shipping_qty;
                -- �o�א��ʁi�P�[�X�j
    gt_req_edi_lines_data(in_line_cnt).case_shipping_qty
                                                   := gt_edideli_work_data(in_line_cnt).case_shipping_qty;
                -- �o�א��ʁi�{�[���j
    gt_req_edi_lines_data(in_line_cnt).ball_shipping_qty
                                                   := gt_edideli_work_data(in_line_cnt).ball_shipping_qty;
                -- �o�א��ʁi�p���b�g�j
    gt_req_edi_lines_data(in_line_cnt).pallet_shipping_qty
                                                   := gt_edideli_work_data(in_line_cnt).pallet_shipping_qty;
                -- �o�א��ʁi���v�A�o���j
    gt_req_edi_lines_data(in_line_cnt).sum_shipping_qty := gt_edideli_work_data(in_line_cnt).sum_shipping_qty;
                -- ���i���ʁi�o���j
    gt_req_edi_lines_data(in_line_cnt).indv_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).indv_stockout_qty;
                -- ���i���ʁi�P�[�X�j
    gt_req_edi_lines_data(in_line_cnt).case_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).case_stockout_qty;
                -- ���i���ʁi�{�[���j
    gt_req_edi_lines_data(in_line_cnt).ball_stockout_qty
                                                   := gt_edideli_work_data(in_line_cnt).ball_stockout_qty;
                -- ���i���ʁi���v�A�o���j
    gt_req_edi_lines_data(in_line_cnt).sum_stockout_qty := gt_edideli_work_data(in_line_cnt).sum_stockout_qty;
                -- �P�[�X����
    gt_req_edi_lines_data(in_line_cnt).case_qty         := gt_edideli_work_data(in_line_cnt).case_qty;
                -- �I���R���i�o���j����
    gt_req_edi_lines_data(in_line_cnt).fold_cont_indv_qty
                                                   := gt_edideli_work_data(in_line_cnt).fold_container_indv_qty;
                -- ���P���i�o�ׁj
    gt_req_edi_lines_data(in_line_cnt).shipping_unit_price
                                                   := gt_edideli_work_data(in_line_cnt).shipping_unit_price;
                -- �������z�i�����j
    gt_req_edi_lines_data(in_line_cnt).order_cost_amt   := gt_edideli_work_data(in_line_cnt).order_cost_amt;
                -- �������z�i�o�ׁj
    gt_req_edi_lines_data(in_line_cnt).shipping_cost_amt
                                                   := gt_edideli_work_data(in_line_cnt).shipping_cost_amt;
                -- �������z�i���i�j
    gt_req_edi_lines_data(in_line_cnt).stockout_cost_amt
                                                   := gt_edideli_work_data(in_line_cnt).stockout_cost_amt;
                -- ���P��
    gt_req_edi_lines_data(in_line_cnt).selling_price    := gt_edideli_work_data(in_line_cnt).selling_price;
                -- �������z�i�����j
    gt_req_edi_lines_data(in_line_cnt).order_price_amt  := gt_edideli_work_data(in_line_cnt).order_price_amt;
                -- �������z�i�o�ׁj
    gt_req_edi_lines_data(in_line_cnt).shipping_price_amt
                                                   := gt_edideli_work_data(in_line_cnt).shipping_price_amt;
                -- �������z�i���i�j
    gt_req_edi_lines_data(in_line_cnt).stockout_price_amt
                                                   := gt_edideli_work_data(in_line_cnt).stockout_price_amt;
                -- �`���i�S�ݓX�j
    gt_req_edi_lines_data(in_line_cnt).a_col_department := gt_edideli_work_data(in_line_cnt).a_column_department;
                -- �c���i�S�ݓX�j
    gt_req_edi_lines_data(in_line_cnt).d_col_department := gt_edideli_work_data(in_line_cnt).d_column_department;
                -- �K�i���E���s��
    gt_req_edi_lines_data(in_line_cnt).stand_info_depth := gt_edideli_work_data(in_line_cnt).standard_info_depth;
                -- �K�i���E����
    gt_req_edi_lines_data(in_line_cnt).stand_info_height
                                                   := gt_edideli_work_data(in_line_cnt).standard_info_height;
                -- �K�i���E��
    gt_req_edi_lines_data(in_line_cnt).stand_info_width := gt_edideli_work_data(in_line_cnt).standard_info_width;
                -- �K�i���E�d��
    gt_req_edi_lines_data(in_line_cnt).stand_info_weight
                                                   := gt_edideli_work_data(in_line_cnt).standard_info_weight;
                -- �ėp���p�����ڂP
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item1
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item1;
                -- �ėp���p�����ڂQ
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item2
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item2;
                -- �ėp���p�����ڂR
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item3
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item3;
                -- �ėp���p�����ڂS
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item4
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item4;
                -- �ėp���p�����ڂT
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item5
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item5;
                -- �ėp���p�����ڂU
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item6
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item6;
                -- �ėp���p�����ڂV
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item7
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item7;
                -- �ėp���p�����ڂW
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item8
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item8;
                -- �ėp���p�����ڂX
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item9
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item9;
                -- �ėp���p�����ڂP�O
    gt_req_edi_lines_data(in_line_cnt).gen_succeed_item10
                                                   := gt_edideli_work_data(in_line_cnt).general_succeeded_item10;
                -- �ėp�t�����ڂP
    gt_req_edi_lines_data(in_line_cnt).gen_add_item1    := gt_edideli_work_data(in_line_cnt).general_add_item1;
                -- �ėp�t�����ڂQ
    gt_req_edi_lines_data(in_line_cnt).gen_add_item2    := gt_edideli_work_data(in_line_cnt).general_add_item2;
                -- �ėp�t�����ڂR
    gt_req_edi_lines_data(in_line_cnt).gen_add_item3    := gt_edideli_work_data(in_line_cnt).general_add_item3;
                -- �ėp�t�����ڂS
    gt_req_edi_lines_data(in_line_cnt).gen_add_item4    := gt_edideli_work_data(in_line_cnt).general_add_item4;
                -- �ėp�t�����ڂT
    gt_req_edi_lines_data(in_line_cnt).gen_add_item5    := gt_edideli_work_data(in_line_cnt).general_add_item5;
                -- �ėp�t�����ڂU
    gt_req_edi_lines_data(in_line_cnt).gen_add_item6    := gt_edideli_work_data(in_line_cnt).general_add_item6;
                -- �ėp�t�����ڂV
    gt_req_edi_lines_data(in_line_cnt).gen_add_item7    := gt_edideli_work_data(in_line_cnt).general_add_item7;
                -- �ėp�t�����ڂW
    gt_req_edi_lines_data(in_line_cnt).gen_add_item8    := gt_edideli_work_data(in_line_cnt).general_add_item8;
                -- �ėp�t�����ڂX
    gt_req_edi_lines_data(in_line_cnt).gen_add_item9    := gt_edideli_work_data(in_line_cnt).general_add_item9;
                -- �ėp�t�����ڂP�O
    gt_req_edi_lines_data(in_line_cnt).gen_add_item10   := gt_edideli_work_data(in_line_cnt).general_add_item10;
                -- �`�F�[���X�ŗL�G���A�i���ׁj
    gt_req_edi_lines_data(in_line_cnt).chain_pec_a_line := gt_edideli_work_data(in_line_cnt).chain_peculiar_area_line;
/* 2011/07/26 Ver1.9 Add Start */
                -- ���ʂa�l�r���׃f�[�^
   gt_req_edi_lines_data(in_line_cnt).bms_line_data     := gt_edideli_work_data(in_line_cnt).bms_line_data;
/* 2011/07/26 Ver1.9 Add End   */
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END xxcos_in_edi_lists_edit;
--
  /**********************************************************************************
   * Procedure Name   : data_check
   * Description      : �f�[�^�Ó����`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE data_check(
    in_line_cnt    IN NUMBER,       --   LOOP�p�J�E���^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_check'; -- �v���O������
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
    lv_process_flag            VARCHAR2(1);                                 -- �e�����̏������ʃt���O
    lt_chain_account_number    hz_cust_accounts.account_number%TYPE;        -- �ڋq�R�[�h(�`�F�[���X)
    lt_head_price_list_id      hz_cust_site_uses_all.price_list_id%TYPE;    -- ���i�\ID
    lt_unit_price              qp_list_lines.operand%TYPE;                  -- �P��
    lt_head_edi_item_code_div  xxcmm_cust_accounts.edi_item_code_div%TYPE;  -- EDI�A�g�i�ڃR�[�h�敪
    lv_edi_chain_code          VARCHAR2(100) DEFAULT NULL; --ܰ��p���ݓX����
    lv_store_code              VARCHAR2(100) DEFAULT NULL; --ܰ��p�X����
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
    lv_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�������ʃt���O�̏�����
    lv_process_flag := cv_status_normal;
--
    --==============================================================
    -- �d�c�h�`�F�[���X�R�[�h
    gt_req_edi_headers_data(in_line_cnt).edi_chain_code := gt_edideli_work_data(in_line_cnt).edi_chain_code;
    -- �X�R�[�h
    gt_req_edi_headers_data(in_line_cnt).shop_code      := gt_edideli_work_data(in_line_cnt).shop_code;
    -- �������ʁi���v�A�o���j
    gt_req_edi_lines_data(in_line_cnt).sum_order_qty    := gt_edideli_work_data(in_line_cnt).sum_order_qty;
    -- �`�[�ԍ�
    gt_req_edi_headers_data(in_line_cnt).invoice_number := gt_edideli_work_data(in_line_cnt).invoice_number;
    gt_req_edi_lines_data(in_line_cnt).invoice_number   := gt_edideli_work_data(in_line_cnt).invoice_number;
    -- �ڋq�R�[�h
    gt_req_edi_headers_data(in_line_cnt).customer_code  := gt_edideli_work_data(in_line_cnt).customer_code;
    -- ���i�R�[�h�Q
    gt_req_edi_lines_data(in_line_cnt).product_code2    := gt_edideli_work_data(in_line_cnt).product_code2;
    -- ���P��(����)
    gt_req_edi_lines_data(in_line_cnt).order_unit_price := gt_edideli_work_data(in_line_cnt).order_unit_price;
--****************************** 2009/06/29 1.5 T.Tominaga ADD START ******************************
    -- �i��ID
    gt_req_mtl_sys_items(in_line_cnt).inventory_item_id := NULL;
    -- �i�ڃR�[�h
    gt_req_mtl_sys_items(in_line_cnt).segment1          := NULL;
    -- ��P��
    gt_req_mtl_sys_items(in_line_cnt).unit_of_measure   := NULL;
--****************************** 2009/06/29 1.5 T.Tominaga ADD END   ******************************
    --==============================================================
--****************************** 2009/06/29 1.5 T.Tominaga DEL START ******************************
--      --==============================================================
--      -- �X�R�[�h�`�F�b�N
--      --==============================================================
--      IF  ( gt_req_edi_headers_data(in_line_cnt).shop_code IS NULL )  THEN
--        --* -------------------------------------------------------------
--        --�K�{�G���[���b�Z�[�W  gv_msg_in_none_err
--        --* -------------------------------------------------------------
--        lv_process_flag :=  cv_status_error;
--        ov_retcode      :=  cv_status_warn;
--        -- �[�i�ԕi���[�NID(error)
--        gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--        --�X�e�[�^�X(error)
--        gt_err_edideli_work_data(in_line_cnt).err_status1 := cv_status_warn;
--        -- �g�[�N���擾(�X�R�[�h)
--        gv_tkn_shop_code :=  xxccp_common_pkg.get_msg(
--                         iv_application        =>  cv_application,
--                         iv_name               =>  cv_msg_shop_code
--                         );
--        -- ���[�U�[�E�G���[�E���b�Z�[�W
--        gt_err_edideli_work_data(in_line_cnt).errmsg1  :=  xxccp_common_pkg.get_msg(
--                                                       iv_application  =>  cv_application,
--                                                       iv_name         =>  gv_msg_in_none_err,
--                                                       iv_token_name1  =>  cv_tkn_item,
--                                                       iv_token_value1 =>  gv_tkn_shop_code
--                                                       );
--      END IF;
--      --==============================================================
--      -- �������ʁi���v�A�o���j�`�F�b�N
--      --==============================================================
--      IF  ( NVL(gt_req_edi_lines_data(in_line_cnt).sum_order_qty, 0) = 0 )
--      THEN
--        --* -------------------------------------------------------------
--        --�K�{�G���[���b�Z�[�W  gv_msg_in_none_err
--        --* -------------------------------------------------------------
--        lv_process_flag := cv_status_error;
--        ov_retcode      :=  cv_status_warn;
--        -- �[�i�ԕi���[�NID(error)
--        gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--        --�X�e�[�^�X(error)
--        gt_err_edideli_work_data(in_line_cnt).err_status2 := cv_status_warn;
--        --�g�[�N��(�������ʁi���v�A�o���j)
--        gv_sum_order_qty :=  xxccp_common_pkg.get_msg(
--                         iv_application  =>  cv_application,
--                         iv_name         =>  cv_msg_sum_order_qty
--                         );
--        -- ���[�U�[�E�G���[�E���b�Z�[�W
--        gt_err_edideli_work_data(in_line_cnt).errmsg2 :=  xxccp_common_pkg.get_msg(
--                                                      iv_application        =>  cv_application,
--                                                      iv_name               =>  gv_msg_in_none_err,
--                                                      iv_token_name1        =>  cv_tkn_item,
--                                                      iv_token_value1       =>  gv_sum_order_qty
--                                                      );
--      END IF;
--****************************** 2009/06/29 1.5 T.Tominaga DEL END   ******************************
    --==============================================================
    -- ��L�܂ł̏����ŃG���[���Ȃ��ꍇ
    --==============================================================
    IF ( lv_process_flag = cv_status_normal ) THEN
      --==============================================================
      -- �u�ڋq�R�[�h�v�̑Ó��� �`�F�b�N
      --==============================================================
      BEGIN
        -- �d�c�h�`�F�[���X�R�[�h
        lv_edi_chain_code := gt_edideli_work_data(in_line_cnt).edi_chain_code;
        -- �X�R�[�h
        lv_store_code     := gt_edideli_work_data(in_line_cnt).shop_code;
        --
        SELECT   cust.account_number         account_number,   -- �ڋq�}�X�^.�ڋq�R�[�h
                 csua.price_list_id          price_list_id     -- ���i�\ID
        INTO     gt_req_cust_acc_data(in_line_cnt).account_number,     -- �ڋq�R�[�h
                 gt_req_cust_acc_data(in_line_cnt).price_list_id       -- ���i�\ID
        FROM     hz_cust_accounts       cust,                   -- �ڋq�}�X�^
                 hz_cust_site_uses_all  csua,                   -- �ڋq�g�p�ړI
                 hz_cust_acct_sites_all casa,                   -- �ڋq���ݒn
                 xxcmm_cust_accounts    xca                     -- �ڋq�ǉ����
                                      -- �ڋq�}�X�^.�ڋqID   =  �ڋq���ݒn.�ڋqID
        WHERE    cust.cust_account_id = casa.cust_account_id
                                    -- �ڋq�}�X�^.�ڋqID   =  �ڋq�ǉ����.�ڋqID
          AND    cust.cust_account_id = xca.customer_id
                                      -- �ڋq���ݒn.�ڋq���ݒnID = �ڋq�g�p�ړI.�ڋq���ݒnID
          AND    casa.cust_acct_site_id = csua.cust_acct_site_id
                                     -- �ڋq�}�X�^.�ڋq�敪 = '10'(�ڋq)
          AND    cust.customer_class_code = cv_customer_class_code10
                                      -- �ڋq�}�X�^.�`�F�[���X�R�[�h(EDI) = A-2�Œ��o����EDI�`�F�[���X�R�[�h
          AND    xca.chain_store_code = lv_edi_chain_code
                                      -- �ڋq�}�X�^.�X�܃R�[�h = A-2�Œ��o�����X�R�[�h
          AND    xca.store_code       = lv_store_code
          AND    csua.site_use_code   = cv_cust_site_use_code            -- �ڋq�g�p�ړI�FSHIP_TO(�o�א�)
          AND    casa.org_id          = gn_org_id                        -- �c�ƒP��
          AND    csua.org_id          = casa.org_id
          AND    rownum = 1;
        --
        -- ���i�\ID
        lt_head_price_list_id := gt_req_cust_acc_data(in_line_cnt).price_list_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  -- �i�Ώۃf�[�^�����G���[�j
--****************************** 2009/06/29 1.5 T.Tominaga DEL START ******************************
--            --* -------------------------------------------------------------
--            --�ڋq�R�[�h�ϊ��G���[���b�Z�[�W  gv_msg_cust_num_chg_err
--            --* -------------------------------------------------------------
--            lv_process_flag :=  cv_status_error;
--            ov_retcode      :=  cv_status_warn;
--            -- �[�i�ԕi���[�NID(error)
--            gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                  gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--            --�X�e�[�^�X(error)
--            gt_err_edideli_work_data(in_line_cnt).err_status1 := cv_status_warn;
--            -- ���[�U�[�E�G���[�E���b�Z�[�W
--            gt_err_edideli_work_data(in_line_cnt).errmsg1 :=
--                  xxccp_common_pkg.get_msg(
--                    iv_application  =>  cv_application,
--                   iv_name         =>  gv_msg_cust_num_chg_err,
--                    iv_token_name1  =>  cv_chain_shop_code,
--                    iv_token_name2  =>  cv_shop_code,
--                    iv_token_value1 =>  gt_req_edi_headers_data(in_line_cnt).edi_chain_code,
--                    iv_token_value2 =>  gt_req_edi_headers_data(in_line_cnt).shop_code
--                    );
--****************************** 2009/05/28 1.3 T.Kitajima DEL  END  ******************************--
          gt_req_cust_acc_data(in_line_cnt).account_number := NULL; --�x�����ɎQ�Ƃ��Y���G���[�ƂȂ�ׁA������
      END;
    ELSE
      gt_req_cust_acc_data(in_line_cnt).account_number := NULL; --�x�����ɎQ�Ƃ��Y���G���[�ƂȂ�ׁA������
    END IF;
    --* -------------------------------------------------------------
    -- ��L�܂ł̏����ŃG���[���Ȃ��ꍇ
    --* -------------------------------------------------------------
    IF ( lv_process_flag = cv_status_normal )  THEN
      --* -------------------------------------------------------------
      -- �u���i�R�[�h�v�̑Ó����`�F�b�N
      --* -------------------------------------------------------------
      BEGIN
        --* -------------------------------------------------------------
        --== �uEDI�A�g�i�ڃR�[�h�敪�v���o ==--
        --* -------------------------------------------------------------
        SELECT xca.edi_item_code_div,    -- �ڋq�ǉ����.EDI�A�g�i�ڃR�[�h�敪
               cust.account_number       -- �ڋq�}�X�^.�ڋq�R�[�h(�`�F�[���X)
        INTO   lt_head_edi_item_code_div,
               lt_chain_account_number
        FROM   hz_cust_accounts       cust,                 -- �ڋq�}�X�^
               xxcmm_cust_accounts    xca                   -- �ڋq�ǉ����
        WHERE  cust.cust_account_id = xca.customer_id
                                    -- �ڋq�}�X�^.�`�F�[���X�R�[�h(EDI) = A-2�Œ��o����EDI�`�F�[���X�R�[�h
          AND  xca.chain_store_code = gt_req_edi_headers_data(in_line_cnt).edi_chain_code
          AND  cust.customer_class_code = cv_customer_class_code18
        ;                                                   -- �ڋq�}�X�^.�ڋq�敪 = '18'(�`�F�[���X)
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
--****************************** 2009/06/29 1.5 T.Tominaga MOD START ******************************
--            --* -------------------------------------------------------------
--            --EDI�A�g�i�ڃR�[�h�敪�G���[���b�Z�[�W  gv_msg_item_code_err
--            --* -------------------------------------------------------------
--            lv_process_flag :=  cv_status_error;
--            ov_retcode      :=  cv_status_warn;
--            -- �[�i�ԕi���[�NID(error)
--            gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                  gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--            --�X�e�[�^�X(error)
--            gt_err_edideli_work_data(in_line_cnt).err_status1 := cv_status_warn;
--            -- ���[�U�[�E�G���[�E���b�Z�[�W
--            gt_err_edideli_work_data(in_line_cnt).errmsg1 :=
--                  xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_application,
--                    iv_name          =>  gv_msg_item_code_err,
--                    iv_token_name1   =>  cv_chain_shop_code,
--                    iv_token_value1  =>  gt_req_edi_headers_data(in_line_cnt).edi_chain_code
--                    );
          NULL;
--****************************** 2009/06/29 1.5 T.Tominaga MOD END   ******************************
      END;
    END IF;
    --* -------------------------------------------------------------
    -- ��L�܂ł̏����ŃG���[���Ȃ��ꍇ
    --* -------------------------------------------------------------
    IF ( lv_process_flag = cv_status_normal )  THEN
      --* -------------------------------------------------------------
      -- �uEDI�A�g�i�ڃR�[�h�敪�v���uNULL�v�܂��́u0�F�Ȃ��v�̏ꍇ
      --* -------------------------------------------------------------
      IF  (( lt_head_edi_item_code_div  IS NULL )
      OR   ( lt_head_edi_item_code_div  = cv_0 ))
      THEN
--****************************** 2009/06/29 1.5 T.Tominaga DEL START ******************************
--          --* -------------------------------------------------------------
--          --EDI�A�g�i�ڃR�[�h�敪�G���[���b�Z�[�W  gv_msg_item_code_err
--          --* -------------------------------------------------------------
--          lv_process_flag :=  cv_status_error;
--          ov_retcode      :=  cv_status_warn;
--          -- �[�i�ԕi���[�NID(error)
--          gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                  gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--          --�X�e�[�^�X(error)
--          gt_err_edideli_work_data(in_line_cnt).err_status1 := cv_status_warn;
--          -- ���[�U�[�E�G���[�E���b�Z�[�W
--          gt_err_edideli_work_data(in_line_cnt).errmsg1 :=
--                  xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_application,
--                    iv_name          =>  gv_msg_item_code_err,
--                    iv_token_name1   =>  cv_chain_shop_code,
--                    iv_token_value1  =>  gt_req_edi_headers_data(in_line_cnt).edi_chain_code
--                    );
        NULL;
--****************************** 2009/06/29 1.5 T.Tominaga DEL END   ******************************
      --* -------------------------------------------------------------
      -- �uEDI�A�g�i�ڃR�[�h�敪�v���u2�FJAN�R�[�h�v�̏ꍇ
      --  �i�ڃ}�X�^�`�F�b�N (3-1)
      --* -------------------------------------------------------------
      ELSIF  ( lt_head_edi_item_code_div  = cv_2 )  THEN
        --* -------------------------------------------------------------
        --== �i�ڃ}�X�^(JAN�R�[�h)���f�[�^���o ==--
        --* -------------------------------------------------------------
        BEGIN
--****************************** 2009/05/19 1.2 T.Kitajima MOD START ******************************--
--          SELECT mtl_item.inventory_item_id,        -- �i��ID
--                 mtl_item.segment1,                 -- �i�ڃR�[�h
--                 mtl_item.primary_unit_of_measure   -- ��P��
--          INTO   gt_req_mtl_sys_items(in_line_cnt).inventory_item_id,
--                 gt_req_mtl_sys_items(in_line_cnt).segment1,
--                 gt_req_mtl_sys_items(in_line_cnt).unit_of_measure
--          FROM   mtl_system_items_b    mtl_item,
--                 ic_item_mst_b         mtl_item1
--          WHERE  mtl_item.segment1          = mtl_item1.item_no
--                                            -- ���i�R�[�h�Q
--            AND  mtl_item1.attribute21      = gt_req_edi_lines_data(in_line_cnt).product_code2
--                                            -- �݌ɑg�DID
--            AND  mtl_item.organization_id   = gv_prf_orga_id;
--
          SELECT ims.inventory_item_id,
                 ims.segment1,
                 ims.primary_unit_of_measure
            INTO gt_req_mtl_sys_items(in_line_cnt).inventory_item_id,
                 gt_req_mtl_sys_items(in_line_cnt).segment1,
                 gt_req_mtl_sys_items(in_line_cnt).unit_of_measure
            FROM (
                  SELECT msi.inventory_item_id,        -- �i��ID
                         msi.segment1,                 -- �i�ڃR�[�h
                         msi.primary_unit_of_measure   -- ��P��
                    FROM mtl_system_items_b    msi,
                         ic_item_mst_b         iim,
                         xxcmn_item_mst_b      xim
                   WHERE msi.segment1          = iim.item_no
                                                    -- ���i�R�[�h�Q
                    AND  iim.attribute21      = gt_req_edi_lines_data(in_line_cnt).product_code2
                                                    -- �݌ɑg�DID
                    AND  msi.organization_id  = gv_prf_orga_id
                    AND xim.item_id           = iim.item_id         --OPM�i��.�i��ID        =OPM�i�ڃA�h�I��.�i��ID
                    AND xim.item_id           = xim.parent_item_id  --OPM�i�ڃA�h�I��.�i��ID=OPM�i�ڃA�h�I��.�e�i��ID
                    AND TO_DATE(iim.attribute13,cv_format_yyyymmdd) <= NVL( gt_edideli_work_data(in_line_cnt).shop_delivery_date, 
                                                                      NVL( gt_edideli_work_data(in_line_cnt).center_delivery_date, 
                                                                           NVL( gt_edideli_work_data(in_line_cnt).order_date, 
                                                                                gt_edideli_work_data(in_line_cnt).data_creation_date_edi_data
                                                                              )
                                                                         )
                                                                    )
                  ORDER BY iim.attribute13 DESC
                 ) ims
          WHERE ROWNUM  = 1
          ;
--****************************** 2009/05/19 1.2 T.Kitajima MOD  END  ******************************--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN  -- �����f�[�^�Ȃ�
            --* -------------------------------------------------------------
            -- �uEDI�A�g�i�ڃR�[�h�敪�v���u2�FJAN�R�[�h�v�̏ꍇ
            --  �i�ڃ}�X�^�`�F�b�N (3-1) �P�[�X�i�`�m�R�[�h
            --* -------------------------------------------------------------
            BEGIN
              --* -------------------------------------------------------------
              --== �i�ڃ}�X�^(�P�[�XJAN�R�[�h)���f�[�^���o ==--
              --* -------------------------------------------------------------
--****************************** 2009/05/19 1.2 T.Kitajima MOD START ******************************--
--              SELECT mtl_item.inventory_item_id,        -- �i��ID
--                     mtl_item.segment1                  -- �i�ڃR�[�h
--              INTO   gt_req_mtl_sys_items(in_line_cnt).inventory_item_id,
--                     gt_req_mtl_sys_items(in_line_cnt).segment1
--              FROM   mtl_system_items_b    mtl_item,
--                     ic_item_mst_b         mtl_item1,
--                     xxcmm_system_items_b  xxcmm_sib
--              WHERE  mtl_item.segment1      = mtl_item1.item_no
--                AND  mtl_item.segment1      = xxcmm_sib.item_code
--                                            -- ���i�R�[�h�Q
--                AND  xxcmm_sib.case_jan_code = gt_req_edi_lines_data(in_line_cnt).product_code2
--                                            -- �݌ɑg�DID
--                AND  mtl_item.organization_id = gv_prf_orga_id;
--
              SELECT ims.inventory_item_id,
                     ims.segment1
                INTO gt_req_mtl_sys_items(in_line_cnt).inventory_item_id,
                     gt_req_mtl_sys_items(in_line_cnt).segment1
                FROM (
                      SELECT msi.inventory_item_id inventory_item_id,   -- �i��ID
                             msi.segment1          segment1             -- �i�ڃR�[�h
                        FROM mtl_system_items_b    msi,
                             ic_item_mst_b         iim,
                             xxcmn_item_mst_b      xim,
                             xxcmm_system_items_b  xsi
                       WHERE msi.segment1        = iim.item_no
                         AND msi.segment1        = xsi.item_code
                                                     -- ���i�R�[�h�Q
                         AND xsi.case_jan_code   = gt_req_edi_lines_data(in_line_cnt).product_code2
                                                     -- �݌ɑg�DID
                         AND msi.organization_id = gv_prf_orga_id
                         AND xim.item_id         = iim.item_id         --OPM�i��.�i��ID        =OPM�i�ڃA�h�I��.�i��ID
-- ******************** 2009/08/05 1.5 N.Maeda MOD START *********************** --
                         AND iim.item_id         = xim.parent_item_id  --OPM�i��.�i��ID=OPM�i�ڃA�h�I��.�e�i��ID
--                         AND xim.item_id         = xim.parent_item_id  --OPM�i�ڃA�h�I��.�i��ID=OPM�i�ڃA�h�I��.�e�i��ID
-- ******************** 2009/08/05 1.5 N.Maeda MOD  END  *********************** --
                         AND TO_DATE(iim.attribute13,cv_format_yyyymmdd) <= NVL( gt_edideli_work_data(in_line_cnt).shop_delivery_date, 
                                                                           NVL( gt_edideli_work_data(in_line_cnt).center_delivery_date, 
                                                                                NVL( gt_edideli_work_data(in_line_cnt).order_date, 
                                                                                     gt_edideli_work_data(in_line_cnt).data_creation_date_edi_data
                                                                                   )
                                                                              )
                                                                         )
                       ORDER BY iim.attribute13 DESC
                     ) ims
              WHERE ROWNUM  = 1
              ;
--****************************** 2009/05/19 1.2 T.Kitajima MOD  END  ******************************--
              --* -------------------------------------------------------------
              --== A-1�Œ��o�����P�[�X�P�ʺ���
              --* -------------------------------------------------------------
              gt_req_mtl_sys_items(in_line_cnt).unit_of_measure := gv_prf_case_code;
            --
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
--****************************** 2009/06/29 1.5 T.Tominaga MOD START ******************************
--                  --* -------------------------------------------------------------
--                  -- ���i�R�[�h�ϊ��G���[���b�Z�[�W  gv_msg_product_code_err
--                  --* -------------------------------------------------------------
--                  lv_process_flag :=  cv_status_warn;
--                  ov_retcode      :=  cv_status_warn;
--                  -- �[�i�ԕi���[�NID(error)
--                  gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                         gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--                  --�X�e�[�^�X(error)
--                  gt_err_edideli_work_data(in_line_cnt).err_status1 := cv_status_warn;
--                  --�g�[�N��(JAN�R�[�h)
--                  gv_jan_code    :=  xxccp_common_pkg.get_msg(
--                                 iv_application        =>  cv_application,
--                                 iv_name               =>  cv_msg_jan_code
--                               );
--                  -- ���[�U�[�E�G���[�E���b�Z�[�W
--                  gt_err_edideli_work_data(in_line_cnt).errmsg1 :=
--                         xxccp_common_pkg.get_msg(
--                           iv_application   =>  cv_application,
--                           iv_name          =>  gv_msg_product_code_err,
--                           iv_token_name1   =>  cv_prod_code,
--                           iv_token_name2   =>  cv_prod_type,
--                           iv_token_value1  =>  gt_req_edi_lines_data(in_line_cnt).product_code2,
--                           iv_token_value2  =>  gv_jan_code
--                           );
--                  --* -------------------------------------------------------------
--                  --* JAN�A�P�[�XJAN�R�[�h�����݂��Ȃ��ꍇ�A�_�~�[�i�ڃR�[�h���擾
--                  --* -------------------------------------------------------------
--                  SELECT  flvv.lookup_code        -- �R�[�h
--                  INTO    gt_req_mtl_sys_items(in_line_cnt).segment1
--                  FROM    fnd_lookup_values_vl  flvv          -- ���b�N�A�b�v�}�X�^
--                  WHERE   flvv.lookup_type  = cv_lookup_type  -- ���b�N�A�b�v.�^�C�v
--                    AND   flvv.enabled_flag       = cv_y                -- �L��
--                    AND   flvv.attribute1         = cv_1
--                    AND (( flvv.start_date_active IS NULL )
--                    OR   ( flvv.start_date_active <= cd_process_date ))
--                    AND (( flvv.end_date_active   IS NULL )
--                    OR   ( flvv.end_date_active   >= cd_process_date ));  -- �Ɩ����t��FROM-TO��
-- ******************** 2009/09/28 1.6 K.Satomura MOD START *********************** --
            --NULL;
            gt_req_mtl_sys_items(in_line_cnt).segment1        := gt_dummy_item_number;
            gt_req_mtl_sys_items(in_line_cnt).unit_of_measure := gt_dummy_unit_of_measure;
-- ******************** 2009/09/28 1.6 K.Satomura MOD END   *********************** --
--****************************** 2009/06/29 1.5 T.Tominaga MOD END   ******************************
            END;
        END;
      --* -------------------------------------------------------------
      -- �uEDI�A�g�i�ڃR�[�h�敪�v���u1�F�ڋq�i�ځv�̏ꍇ
      --  �ڋq�i�ڃ}�X�^�`�F�b�N (3-2)
      --* -------------------------------------------------------------
      ELSIF  ( lt_head_edi_item_code_div  = cv_1 )  THEN
        --* -------------------------------------------------------------
        -- �u���i�R�[�h�Q�v�̑Ó����`�F�b�N
        --* -------------------------------------------------------------
        BEGIN
          --* -------------------------------------------------------------
          --== �ڋq�}�X�^�f�[�^���o ==--
          --* -------------------------------------------------------------
          SELECT mcix.inventory_item_id,         -- �i��ID
                 mtl_item.segment1,              -- �i�ڃR�[�h
                 mtci.attribute1                 -- �P��
          INTO   gt_req_mtl_sys_items(in_line_cnt).inventory_item_id,
                 gt_req_mtl_sys_items(in_line_cnt).segment1,
                 gt_req_mtl_sys_items(in_line_cnt).unit_of_measure
          FROM   hz_cust_accounts         cust,                  -- �ڋq�}�X�^
                 mtl_customer_item_xrefs  mcix,                  -- �ڋq�i�ڑ��ݎQ��
                 mtl_customer_items       mtci,                  -- �ڋq�i��
                 mtl_system_items_b       mtl_item,              -- �i�ڃ}�X�^
                 mtl_parameters           mtl_parm               -- �ڋq�i�����Ұ�Ͻ�
                                 -- �ڋq�}�X�^.�ڋq�R�[�h = �`�F�[���X�̌ڋq�R�[�h
          WHERE  cust.account_number         = lt_chain_account_number
                                 -- �ڋq�}�X�^.�ڋq�敪 = '18'(�`�F�[���X)
            AND  cust.customer_class_code    = cv_customer_class_code18
                                 -- �ڋq�i��.�ڋqID = �ڋq�}�X�^.�ڋqID
            AND  mtci.customer_id            = cust.cust_account_id
                                 --�ڋq�i�ڃ}�X�^�D�ڋq�i�� �� ���i�R�[�h�Q
            AND  mtci.customer_item_number   = gt_req_edi_lines_data(in_line_cnt).product_code2
                                 -- �ڋq�i��.�ڋq�i��ID = �ڋq�i�ڑ��ݎQ��.�ڋq�i��ID
            AND  mtci.customer_item_id       = mcix.customer_item_id
            AND  mcix.master_organization_id = mtl_parm.master_organization_id
                                 -- �݌ɑg�DID
            AND  mtl_parm.organization_id    = gv_prf_orga_id
                                 -- �ڋq�i�ڑ��ݎQ��.�i��ID = �i�ڃ}�X�^.�i��ID
            AND  mtl_item.inventory_item_id  = mcix.inventory_item_id
            AND  mtl_item.organization_id    = mtl_parm.organization_id
-- ******************** 2009/09/28 1.6 K.Satomura MOD START *********************** --
            AND  mtci.inactive_flag          = cv_n
            AND  mcix.inactive_flag          = cv_n
            AND  mcix.preference_number      = 
                 (
                   SELECT MIN(cix.preference_number)
                   FROM   mtl_customer_items      cit
                         ,mtl_customer_item_xrefs cix
                   WHERE  cit.customer_id          = cust.cust_account_id
                   AND    cit.customer_item_number = mtci.customer_item_number
                   AND    cit.customer_item_id     = cix.customer_item_id
                   AND    cit.inactive_flag        = cv_n
                   AND    cix.inactive_flag        = cv_n
                 )
-- ******************** 2009/09/28 1.6 K.Satomura MOD END   *********************** --
            ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
--****************************** 2009/06/29 1.5 T.Tominaga MOD START ******************************
--              --* -------------------------------------------------------------
--              --== �ڋq�i�ڂ����݂��Ȃ��ꍇ�A�_�~�[�i�ڃR�[�h���擾
--              --* -------------------------------------------------------------
--              SELECT  flvv.lookup_code        -- �R�[�h
--              INTO    gt_req_mtl_sys_items(in_line_cnt).segment1
--              FROM    fnd_lookup_values_vl  flvv        -- ���b�N�A�b�v�}�X�^
--              WHERE   flvv.lookup_type  = cv_lookup_type  -- ���b�N�A�b�v.�^�C�v
--                AND   flvv.enabled_flag       = cv_y                -- �L��
--                AND   flvv.attribute1         = cv_1
--                AND (( flvv.start_date_active IS NULL )
--                OR   ( flvv.start_date_active <= cd_process_date ))
--                AND (( flvv.end_date_active   IS NULL )
--                OR   ( flvv.end_date_active   >= cd_process_date ))  -- �Ɩ����t��FROM-TO��
--              ;
--              --* -------------------------------------------------------------
--              -- ���i�R�[�h�ϊ��G���[���b�Z�[�W  gv_msg_product_code_err
--              --* -------------------------------------------------------------
--              lv_process_flag :=  cv_status_warn;
--              ov_retcode      :=  cv_status_warn;
--              -- �[�i�ԕi���[�NID(error)
--              gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                      gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--              --�X�e�[�^�X(error)
--              gt_err_edideli_work_data(in_line_cnt).err_status1 := cv_status_warn;
--              --�g�[�N��(�ڋq�i��)
--              gv_tkn_mtl_cust_items  :=  xxccp_common_pkg.get_msg(
--                                     iv_application  =>  cv_application,
--                                     iv_name         =>  cv_msg_mtl_cust_items
--                                     );
--              -- ���[�U�[�E�G���[�E���b�Z�[�W
--              gt_err_edideli_work_data(in_line_cnt).errmsg1 :=
--                      xxccp_common_pkg.get_msg(
--                        iv_application   =>  cv_application,
--                        iv_name          =>  gv_msg_product_code_err,
--                        iv_token_name1   =>  cv_prod_code,
--                       iv_token_name2   =>  cv_prod_type,
--                        iv_token_value1  =>  gt_req_edi_lines_data(in_line_cnt).product_code2,
--                        iv_token_value2  =>  gv_tkn_mtl_cust_items
--                        );
-- ******************** 2009/09/28 1.6 K.Satomura MOD START *********************** --
            --NULL;
            gt_req_mtl_sys_items(in_line_cnt).segment1        := gt_dummy_item_number;
            gt_req_mtl_sys_items(in_line_cnt).unit_of_measure := gt_dummy_unit_of_measure;
-- ******************** 2009/09/28 1.6 K.Satomura MOD END   *********************** --
--****************************** 2009/06/29 1.5 T.Tominaga MOD END   ******************************
        END;
      END IF;
    END IF;
    --* -------------------------------------------------------------
    -- ��L�܂ł̏����ŃG���[���Ȃ��ꍇ(�x���͏������s)
    --* -------------------------------------------------------------
    IF ( lv_process_flag <> cv_status_error )  THEN
      --* -------------------------------------------------------------
      -- �i�ڃR�[�h�̐ݒ�
      --* -------------------------------------------------------------
      IF ( gt_req_mtl_sys_items(in_line_cnt).segment1 IS NOT NULL ) THEN
        gt_req_edi_lines_data(in_line_cnt).item_code := SUBSTRB(gt_req_mtl_sys_items(in_line_cnt).segment1,1,7);
      END IF;
      --* -------------------------------------------------------------
      -- ���גP�ʂ̐ݒ� (4-1)(4-2)
      --* -------------------------------------------------------------
      IF ( gt_req_mtl_sys_items(in_line_cnt).unit_of_measure  IS NOT NULL ) THEN
        gt_req_edi_lines_data(in_line_cnt).line_uom := gt_req_mtl_sys_items(in_line_cnt).unit_of_measure;
      END IF;
      --* -------------------------------------------------------------
      -- ���i�\����P�������擾 (5)
      -- �u���P���i�����j�v�����ݒ�iNULL�܂��͂O�j�̏ꍇ
      --* -------------------------------------------------------------
      IF  (( gt_req_edi_lines_data(in_line_cnt).order_unit_price  IS NULL )
      OR   ( gt_req_edi_lines_data(in_line_cnt).order_unit_price  = 0     ))
      THEN
--****************************** 2009/05/19 1.2 T.Kitajima MOD START ******************************--
--        --* -------------------------------------------------------------
--        -- �ڋq�̉��i�\ID���ݒ肳��Ă���ꍇ
--        --* -------------------------------------------------------------
--        IF  ( lt_head_price_list_id IS NOT NULL ) THEN
--          --* -------------------------------------------------------------
--          -- ���ʊ֐����擾����
--          --* -------------------------------------------------------------
--          lt_unit_price := xxcos_common2_pkg.get_unit_price(
--                        gt_req_mtl_sys_items(in_line_cnt).inventory_item_id, -- �i��ID
--                        lt_head_price_list_id,                               -- ���i�\ID
--                        gt_req_edi_lines_data(in_line_cnt).line_uom          -- ���גP��
--                        );
--        ELSE
--          lt_unit_price := cn_m1;
--        END IF;
--        --* -------------------------------------------------------------
--        -- ���ʊ֐����擾���P�����擾�ł����ꍇ
--        --* -------------------------------------------------------------
--        IF ( lt_unit_price >= cn_0 ) THEN
--          gt_req_edi_lines_data(in_line_cnt).order_unit_price := lt_unit_price;
--        ELSE
--          --* -------------------------------------------------------------
--          --���i�\���ݒ�G���[���b�Z�[�W  gv_msg_price_list_err
--          --* -------------------------------------------------------------
--          lv_process_flag :=  cv_status_warn;
--          ov_retcode      :=  cv_status_warn;
--          -- �[�i�ԕi���[�NID(error)
--          gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                  gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--          --�X�e�[�^�X(error)
--          gt_err_edideli_work_data(in_line_cnt).err_status2 := cv_status_warn;
--          -- ���[�U�[�E�G���[�E���b�Z�[�W
--          gt_err_edideli_work_data(in_line_cnt).errmsg2 :=
--                  xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_application,
--                    iv_name          =>  gv_msg_price_list_err,
--                    iv_token_name1   =>  cv_chain_shop_code,
--                    iv_token_name2   =>  cv_shop_code,
--                    iv_token_value1  =>  gt_req_edi_headers_data(in_line_cnt).edi_chain_code,
--                    iv_token_value2  =>  gt_req_edi_headers_data(in_line_cnt).shop_code
--                    );
--        END IF;
--
        --* -------------------------------------------------------------
        -- �ڋq�̉��i�\ID���ݒ肳��Ă���ꍇ
        --* -------------------------------------------------------------
        IF  ( lt_head_price_list_id IS NOT NULL ) THEN
          --* -------------------------------------------------------------
          -- ���ʊ֐����擾����
          --* -------------------------------------------------------------
          lt_unit_price := xxcos_common2_pkg.get_unit_price(
                        gt_req_mtl_sys_items(in_line_cnt).inventory_item_id, -- �i��ID
                        lt_head_price_list_id,                               -- ���i�\ID
                        gt_req_edi_lines_data(in_line_cnt).line_uom          -- ���גP��
                        );
--
          --* -------------------------------------------------------------
          -- ���ʊ֐����擾���P�����擾�ł����ꍇ
          --* -------------------------------------------------------------
          IF ( lt_unit_price >= cn_0 ) THEN
            gt_req_edi_lines_data(in_line_cnt).order_unit_price := lt_unit_price;
          ELSE
--****************************** 2009/06/29 1.5 T.Tominaga MOD START ******************************
--              --* -------------------------------------------------------------
--              --�P���擾�G���[���b�Z�[�W  cv_msg_price_err
--              --* -------------------------------------------------------------
--              lv_process_flag :=  cv_status_warn;
--              ov_retcode      :=  cv_status_warn;
--              -- �[�i�ԕi���[�NID(error)
--              gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                      gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--              --�X�e�[�^�X(error)
--              gt_err_edideli_work_data(in_line_cnt).err_status2 := cv_status_warn;
--              -- ���[�U�[�E�G���[�E���b�Z�[�W
--              gt_err_edideli_work_data(in_line_cnt).errmsg2 :=
--                     xxccp_common_pkg.get_msg( cv_application, 
--                                               cv_msg_price_err 
--                                             );
            NULL;
--****************************** 2009/06/29 1.5 T.Tominaga MOD END   ******************************
          END IF;
        ELSE
--****************************** 2009/06/29 1.5 T.Tominaga MOD START ******************************
--            --* -------------------------------------------------------------
--            --���i�\���ݒ�G���[���b�Z�[�W  gv_msg_price_list_err
--            --* -------------------------------------------------------------
--            lv_process_flag :=  cv_status_warn;
--            ov_retcode      :=  cv_status_warn;
--            -- �[�i�ԕi���[�NID(error)
--            gt_err_edideli_work_data(in_line_cnt).delivery_return_work_id :=
--                    gt_edideli_work_data(in_line_cnt).delivery_return_work_id;
--            --�X�e�[�^�X(error)
--            gt_err_edideli_work_data(in_line_cnt).err_status2 := cv_status_warn;
--            -- ���[�U�[�E�G���[�E���b�Z�[�W
--            gt_err_edideli_work_data(in_line_cnt).errmsg2 :=
--                    xxccp_common_pkg.get_msg(
--                      iv_application   =>  cv_application,
--                      iv_name          =>  gv_msg_price_list_err,
--                      iv_token_name1   =>  cv_chain_shop_code,
--                      iv_token_name2   =>  cv_shop_code,
--                      iv_token_value1  =>  gt_req_edi_headers_data(in_line_cnt).edi_chain_code,
--                      iv_token_value2  =>  gt_req_edi_headers_data(in_line_cnt).shop_code
--                      );
          NULL;
--****************************** 2009/06/29 1.5 T.Tominaga MOD END   ******************************
        END IF;
--****************************** 2009/05/19 1.2 T.Kitajima MOD  END  ******************************--
      END IF;
-- ***************************** 2009/08/06 1.5 M.Sano    ADD  START ***************************** --
      --* -------------------------------------------------------------
      --  �������z�i�����j�̍Čv�Z
      -- �u�������z�i�����j�v�����ݒ�iNULL�܂��͂O�j�̏ꍇ
      --* -------------------------------------------------------------
      IF ( NVL(gt_edideli_work_data(in_line_cnt).order_cost_amt,0) = cv_0 ) THEN
        gt_edideli_work_data(in_line_cnt).order_cost_amt :=
          TRUNC( gt_req_edi_lines_data(in_line_cnt).order_unit_price * gt_req_edi_lines_data(in_line_cnt).sum_order_qty );
      END IF;
-- ***************************** 2009/08/06 1.5 M.Sano    ADD   END  ***************************** --
    END IF;
    -- * -------------------------------------------------------------
    -- * ���^�[���R�[�h�̕ێ��A
    -- * -------------------------------------------------------------
    IF ( lv_process_flag =  cv_status_warn ) THEN
      gv_status_work_warn :=  cv_status_warn;
--****************************** 2009/06/04 1.4 T.Kitajima DEL START ******************************--
--      gn_warn_cnt         :=  gn_warn_cnt  +  1;
--****************************** 2009/06/04 1.4 T.Kitajima DEL  END  ******************************--
    ELSIF ( lv_process_flag =  cv_status_error ) THEN
      gv_status_work_err  :=  cv_status_error;
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
      gn_error_cnt        :=  gn_error_cnt + 1;
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
    END IF;
    --* -------------------------------------------------------------
    --  �w�b�_�L�[�u���C�N�ҏW
    --* -------------------------------------------------------------
--****************************** 2009/06/29 1.5 T.Tominaga MOD START ******************************
--    IF (( gt_head_invoice_number_key IS NULL )
--    OR  ( gt_head_invoice_number_key <> gt_req_edi_headers_data(in_line_cnt).invoice_number ))
    IF (( gt_head_shop_invoice_key IS NULL )
    OR  ( gt_head_shop_invoice_key <> gt_req_edi_headers_data(in_line_cnt).shop_code || gt_req_edi_headers_data(in_line_cnt).invoice_number ))
--****************************** 2009/06/29 1.5 T.Tominaga MOD END   ******************************
    THEN
      gn_normal_headers_cnt := gn_normal_headers_cnt + 1;  --�w�b�_�̓Y���C���N�������g
      --* -------------------------------------------------------------
      -- �ڋq�R�[�h(�ϊ���ڋq�R�[�h)
      --* -------------------------------------------------------------
      gt_req_edi_headers_data(gn_normal_headers_cnt).conv_customer_code := gt_req_cust_acc_data(in_line_cnt).account_number;
      --* -------------------------------------------------------------
      --  * Procedure Name   : xxcos_in_edi_headers_edit
      --  * Description      : EDI�w�b�_���ϐ��̕ҏW(A-2)(1)
      --* -------------------------------------------------------------
      xxcos_in_edi_headers_edit(
        gn_normal_headers_cnt, --   LOOP�p�J�E���^1
        in_line_cnt,           --   LOOP�p�J�E���^2
        lv_errbuf,     --   �G���[�E���b�Z�[�W
        lv_retcode,    --   ���^�[���E�R�[�h
        lv_errmsg      --   ���[�U�[�E�G���[�E���b�Z�[�W
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      --* -------------------------------------------------------------
      --  * Procedure Name   : xxcos_in_edi_lines_edit
      --  * Description      : EDI���׏��ϐ��̕ҏW(A-2)(2)
      --* -------------------------------------------------------------
      xxcos_in_edi_lists_edit(
        in_line_cnt,    --   LOOP�p�J�E���^
        lv_errbuf,     --   �G���[�E���b�Z�[�W
        lv_retcode,    --   ���^�[���E�R�[�h
        lv_errmsg      --   ���[�U�[�E�G���[�E���b�Z�[�W
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      gn_normal_lines_cnt := gn_normal_lines_cnt + 1;
      --* -------------------------------------------------------------
      -- * Procedure Name   : xxcos_in_edi_headers_add
      -- * Description      : EDI�w�b�_���ϐ��ւ̒ǉ�(A-4)
      --* -------------------------------------------------------------
      xxcos_in_edi_headers_add(
        gn_normal_headers_cnt,
        in_line_cnt,
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    ELSE
      --* -------------------------------------------------------------
      --  ����w�b�_�ҏW
      --* -------------------------------------------------------------
      --* -------------------------------------------------------------
      --  * Procedure Name   : xxcos_in_edi_lines_edit
      --  * Description      : EDI���׏��ϐ��̕ҏW(A-2)(2)
      --* -------------------------------------------------------------
      xxcos_in_edi_lists_edit(
        in_line_cnt,    --   LOOP�p�J�E���^
        lv_errbuf,     --   �G���[�E���b�Z�[�W
        lv_retcode,    --   ���^�[���E�R�[�h
        lv_errmsg      --   ���[�U�[�E�G���[�E���b�Z�[�W
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      gn_normal_lines_cnt := gn_normal_lines_cnt + 1;
      --* -------------------------------------------------------------
      -- * Procedure Name   : xxcos_in_edi_headers_up
      -- * Description      : EDI�w�b�_���ϐ��֐��ʂ����Z(A-5)
      --* -------------------------------------------------------------
      xxcos_in_edi_headers_up(
        gn_normal_headers_cnt,
        in_line_cnt,
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �`�[�ԍ��̃Z�b�g
    gt_head_invoice_number_key  := gt_req_edi_headers_data(in_line_cnt).invoice_number;
--****************************** 2009/06/29 1.5 T.Tominaga ADD START ******************************
    -- �u���C�N�L�[�i�X�R�[�h�{�`�[�ԍ��j�̃Z�b�g
    gt_head_shop_invoice_key  := gt_req_edi_headers_data(in_line_cnt).shop_code || gt_req_edi_headers_data(in_line_cnt).invoice_number;
--****************************** 2009/06/29 1.5 T.Tominaga ADD END   ******************************
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
  END data_check;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_deli_wk_update
   * Description      : EDI�[�i�ԕi��񃏁[�N�e�[�u���ւ̍X�V(A-6)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_deli_wk_update(
    iv_file_name  IN  VARCHAR2,     --   �C���^�t�F�[�X�t�@�C����
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_deli_wk_update'; -- �v���O������
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
    gv_run_class_name3 := cv_1;
    BEGIN
      --* -------------------------------------------------------------
      -- EDI�[�i�ԕi��񃏁[�N�e�[�u�� XXCOS_EDI_DELIVERY_WORK UPDATE
      --* -------------------------------------------------------------
      UPDATE xxcos_edi_delivery_work
         SET err_status             =  gv_run_class_name3,      -- �X�e�[�^�X
             last_updated_by        =  cn_last_updated_by,      -- �ŏI�X�V��
             last_update_date       =  cd_last_update_date,     -- �ŏI�X�V��
             last_update_login      =  cn_last_update_login,    -- �ŏI�X�V���O�C��
             request_id             =  cn_request_id,           -- �v��ID
                                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             program_application_id =  cn_program_application_id,
             program_id             =  cn_program_id,           -- �R���J�����g�E�v���O����ID
             program_update_date    =  cd_program_update_date   -- �v���O�����X�V��
      WHERE  if_file_name = iv_file_name;          -- �C���^�t�F�[�X�t�@�C����
--
      --�R���J�����g�ُ͈�I��������ׂ����ŃR�~�b�g����
      COMMIT;
--
    EXCEPTION
      WHEN OTHERS THEN
      -- EDI�[�i�ԕi��񃏁[�N�e�[�u��
      gv_tkn_edi_deli_work :=  xxccp_common_pkg.get_msg(
                           iv_application =>  cv_application,
                           iv_name        =>  cv_msg_edi_deli_work
                           );
      lv_errmsg  :=  xxccp_common_pkg.get_msg(
                 iv_application   =>  cv_application,
                 iv_name          =>  gv_msg_data_update_err,
                 iv_token_name1   =>  cv_tkn_table_name1,
                 iv_token_name2   =>  cv_tkn_key_data,
                 iv_token_value1  =>  gv_tkn_edi_deli_work,
                 iv_token_value2  =>  iv_file_name
                 );
      lv_errbuf  := SQLERRM;
      RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
----#################################  �Œ��O������ START   ####################################
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
  END xxcos_in_edi_deli_wk_update;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_headers_insert
   * Description      : EDI�w�b�_���e�[�u���ւ̃f�[�^�}��(A-7)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_headers_insert(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_headers_insert'; -- �v���O������
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
    ln_edi_header_info_id    NUMBER  DEFAULT 0;
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
    --* -------------------------------------------------------------
    -- ���[�v�J�n�F
    --* -------------------------------------------------------------
    <<xxcos_edi_headers_insert>>
    FOR  ln_no  IN  1..gn_normal_headers_cnt  LOOP
      --* -------------------------------------------------------------
      --* Description      : EDI�w�b�_���e�[�u���ւ̃f�[�^�}��(A-7)
      --* -------------------------------------------------------------
      INSERT INTO xxcos_edi_headers
        (
          edi_header_info_id,                   -- EDI�w�b�_���ID
          medium_class,                         -- �}�̋敪
          data_type_code,                       -- �f�[�^��R�[�h
          file_no,                              -- �t�@�C��NO
          info_class,                           -- ���敪
          process_date,                         -- ������
          process_time,                         -- ��������
          base_code,                            -- ���_�i����j�R�[�h
          base_name,                            -- ���_���i�������j
          base_name_alt,                        -- ���_���i�J�i�j
          edi_chain_code,                       -- EDI�`�F�[���X�R�[�h
          edi_chain_name,                       -- EDI�`�F�[���X���i�����j
          edi_chain_name_alt,                   -- EDI�`�F�[���X���i�J�i�j
          chain_code,                           -- �`�F�[���X�R�[�h
          chain_name,                           -- �`�F�[���X���i�����j
          chain_name_alt,                       -- �`�F�[���X���i�J�i�j
          report_code,                          -- ���[�R�[�h
          report_show_name,                     -- ���[�\����
          customer_code,                        -- �ڋq�R�[�h
          customer_name,                        -- �ڋq���i�����j
          customer_name_alt,                    -- �ڋq���i�J�i�j
          company_code,                         -- �ЃR�[�h
          company_name,                         -- �Ж��i�����j
          company_name_alt,                     -- �Ж��i�J�i�j
          shop_code,                            -- �X�R�[�h
          shop_name,                            -- �X���i�����j
          shop_name_alt,                        -- �X���i�J�i�j
          delivery_center_code,                 -- �[���Z���^�[�R�[�h
          delivery_center_name,                 -- �[���Z���^�[���i�����j
          delivery_center_name_alt,             -- �[���Z���^�[���i�J�i�j
          order_date,                           -- ������
          center_delivery_date,                 -- �Z���^�[�[�i��
          result_delivery_date,                 -- ���[�i��
          shop_delivery_date,                   -- �X�ܔ[�i��
          data_creation_date_edi_data,          -- �f�[�^�쐬���iEDI�f�[�^���j
          data_creation_time_edi_data,          -- �f�[�^�쐬�����iEDI�f�[�^���j
          invoice_class,                        -- �`�[�敪
          small_classification_code,            -- �����ރR�[�h
          small_classification_name,            -- �����ޖ�
          middle_classification_code,           -- �����ރR�[�h
          middle_classification_name,           -- �����ޖ�
          big_classification_code,              -- �啪�ރR�[�h
          big_classification_name,              -- �啪�ޖ�
          other_party_department_code,          -- ����敔��R�[�h
          other_party_order_number,             -- ����攭���ԍ�
          check_digit_class,                    -- �`�F�b�N�f�W�b�g�L���敪
          invoice_number,                       -- �`�[�ԍ�
          check_digit,                          -- �`�F�b�N�f�W�b�g
          close_date,                           -- ����
          order_no_ebs,                         -- ��NO�iEBS�j
          ar_sale_class,                        -- �����敪
          delivery_classe,                      -- �z���敪
          opportunity_no,                       -- ��NO
          contact_to,                           -- �A����
          route_sales,                          -- ���[�g�Z�[���X
          corporate_code,                       -- �@�l�R�[�h
          maker_name,                           -- ���[�J�[��
          area_code,                            -- �n��R�[�h
          area_name,                            -- �n�於�i�����j
          area_name_alt,                        -- �n�於�i�J�i�j
          vendor_code,                          -- �����R�[�h
          vendor_name,                          -- ����於�i�����j
          vendor_name1_alt,                     -- ����於�P�i�J�i�j
          vendor_name2_alt,                     -- ����於�Q�i�J�i�j
          vendor_tel,                           -- �����TEL
          vendor_charge,                        -- �����S����
          vendor_address,                       -- �����Z���i�����j
          deliver_to_code_itouen,               -- �͂���R�[�h�i�ɓ����j
          deliver_to_code_chain,                -- �͂���R�[�h�i�`�F�[���X�j
          deliver_to,                           -- �͂���i�����j
          deliver_to1_alt,                      -- �͂���P�i�J�i�j
          deliver_to2_alt,                      -- �͂���Q�i�J�i�j
          deliver_to_address,                   -- �͂���Z���i�����j
          deliver_to_address_alt,               -- �͂���Z���i�J�i�j
          deliver_to_tel,                       -- �͂���TEL
          balance_accounts_code,                -- ������R�[�h
          balance_accounts_company_code,        -- ������ЃR�[�h
          balance_accounts_shop_code,           -- ������X�R�[�h
          balance_accounts_name,                -- �����於�i�����j
          balance_accounts_name_alt,            -- �����於�i�J�i�j
          balance_accounts_address,             -- ������Z���i�����j
          balance_accounts_address_alt,         -- ������Z���i�J�i�j
          balance_accounts_tel,                 -- ������TEL
          order_possible_date,                  -- �󒍉\��
          permission_possible_date,             -- ���e�\��
          forward_month,                        -- ����N����
          payment_settlement_date,              -- �x�����ϓ�
          handbill_start_date_active,           -- �`���V�J�n��
          billing_due_date,                     -- ��������
          shipping_time,                        -- �o�׎���
          delivery_schedule_time,               -- �[�i�\�莞��
          order_time,                           -- ��������
          general_date_item1,                   -- �ėp���t���ڂP
          general_date_item2,                   -- �ėp���t���ڂQ
          general_date_item3,                   -- �ėp���t���ڂR
          general_date_item4,                   -- �ėp���t���ڂS
          general_date_item5,                   -- �ėp���t���ڂT
          arrival_shipping_class,               -- ���o�׋敪
          vendor_class,                         -- �����敪
          invoice_detailed_class,               -- �`�[����敪
          unit_price_use_class,                 -- �P���g�p�敪
          sub_distribution_center_code,         -- �T�u�����Z���^�[�R�[�h
          sub_distribution_center_name,         -- �T�u�����Z���^�[�R�[�h��
          center_delivery_method,               -- �Z���^�[�[�i���@
          center_use_class,                     -- �Z���^�[���p�敪
          center_whse_class,                    -- �Z���^�[�q�ɋ敪
          center_area_class,                    -- �Z���^�[�n��敪
          center_arrival_class,                 -- �Z���^�[���׋敪
          depot_class,                          -- �f�|�敪
          tcdc_class,                           -- TCDC�敪
          upc_flag,                             -- UPC�t���O
          simultaneously_class,                 -- ��ċ敪
          business_id,                          -- �Ɩ�ID
          whse_directly_class,                  -- �q���敪
          premium_rebate_class,                 -- �i�i���ߋ敪
          item_type,                            -- ���ڎ��
          cloth_house_food_class,               -- �߉ƐH�敪
          mix_class,                            -- ���݋敪
          stk_class,                            -- �݌ɋ敪
          last_modify_site_class,               -- �ŏI�C���ꏊ�敪
          report_class,                         -- ���[�敪
          addition_plan_class,                  -- �ǉ��E�v��敪
          registration_class,                   -- �o�^�敪
          specific_class,                       -- ����敪
          dealings_class,                       -- ����敪
          order_class,                          -- �����敪
          sum_line_class,                       -- �W�v���׋敪
          shipping_guidance_class,              -- �o�׈ē��ȊO�敪
          shipping_class,                       -- �o�׋敪
          product_code_use_class,               -- ���i�R�[�h�g�p�敪
          cargo_item_class,                     -- �ϑ��i�敪
          ta_class,                             -- T/A�敪
          plan_code,                            -- ���R�[�h
          category_code,                        -- �J�e�S���[�R�[�h
          category_class,                       -- �J�e�S���[�敪
          carrier_means,                        -- �^����i
          counter_code,                         -- ����R�[�h
          move_sign,                            -- �ړ��T�C��
          eos_handwriting_class,                -- EOS�E�菑�敪
          delivery_to_section_code,             -- �[�i��ۃR�[�h
          invoice_detailed,                     -- �`�[����
          attach_qty,                           -- �Y�t��
          other_party_floor,                    -- �t���A
          text_no,                              -- TEXTNO
          in_store_code,                        -- �C���X�g�A�R�[�h
          tag_data,                             -- �^�O
          competition_code,                     -- ����
          billing_chair,                        -- ��������
          chain_store_code,                     -- �`�F�[���X�g�A�[�R�[�h
          chain_store_short_name,               -- �`�F�[���X�g�A�[�R�[�h��������
          direct_delivery_rcpt_fee,             -- ���z���^���旿
          bill_info,                            -- ��`���
          description,                          -- �E�v
          interior_code,                        -- �����R�[�h
          order_info_delivery_category,         -- �������@�[�i�J�e�S���[
          purchase_type,                        -- �d���`��
          delivery_to_name_alt,                 -- �[�i�ꏊ���i�J�i�j
          shop_opened_site,                     -- �X�o�ꏊ
          counter_name,                         -- ���ꖼ
          extension_number,                     -- �����ԍ�
          charge_name,                          -- �S���Җ�
          price_tag,                            -- �l�D
          tax_type,                             -- �Ŏ�
          consumption_tax_class,                -- ����ŋ敪
          brand_class,                          -- BR
          id_code,                              -- ID�R�[�h
          department_code,                      -- �S�ݓX�R�[�h
          department_name,                      -- �S�ݓX��
          item_type_number,                     -- �i�ʔԍ�
          description_department,               -- �E�v�i�S�ݓX�j
          price_tag_method,                     -- �l�D���@
          reason_column,                        -- ���R��
          a_column_header,                      -- A���w�b�_
          d_column_header,                      -- D���w�b�_
          brand_code,                           -- �u�����h�R�[�h
          line_code,                            -- ���C���R�[�h
          class_code,                           -- �N���X�R�[�h
          a1_column,                            -- �`�|�P��
          b1_column,                            -- �a�|�P��
          c1_column,                            -- �b�|�P��
          d1_column,                            -- �c�|�P��
          e1_column,                            -- �d�|�P��
          a2_column,                            -- �`�|�Q��
          b2_column,                            -- �a�|�Q��
          c2_column,                            -- �b�|�Q��
          d2_column,                            -- �c�|�Q��
          e2_column,                            -- �d�|�Q��
          a3_column,                            -- �`�|�R��
          b3_column,                            -- �a�|�R��
          c3_column,                            -- �b�|�R��
          d3_column,                            -- �c�|�R��
          e3_column,                            -- �d�|�R��
          f1_column,                            -- �e�|�P��
          g1_column,                            -- �f�|�P��
          h1_column,                            -- �g�|�P��
          i1_column,                            -- �h�|�P��
          j1_column,                            -- �i�|�P��
          k1_column,                            -- �j�|�P��
          l1_column,                            -- �k�|�P��
          f2_column,                            -- �e�|�Q��
          g2_column,                            -- �f�|�Q��
          h2_column,                            -- �g�|�Q��
          i2_column,                            -- �h�|�Q��
          j2_column,                            -- �i�|�Q��
          k2_column,                            -- �j�|�Q��
          l2_column,                            -- �k�|�Q��
          f3_column,                            -- �e�|�R��
          g3_column,                            -- �f�|�R��
          h3_column,                            -- �g�|�R��
          i3_column,                            -- �h�|�R��
          j3_column,                            -- �i�|�R��
          k3_column,                            -- �j�|�R��
          l3_column,                            -- �k�|�R��
          chain_peculiar_area_header,           -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
          order_connection_number,              -- �󒍊֘A�ԍ�
          invoice_indv_order_qty,               -- �i�`�[�v�j�������ʁi�o���j
          invoice_case_order_qty,               -- �i�`�[�v�j�������ʁi�P�[�X�j
          invoice_ball_order_qty,               -- �i�`�[�v�j�������ʁi�{�[���j
          invoice_sum_order_qty,                -- �i�`�[�v�j�������ʁi���v�A�o���j
          invoice_indv_shipping_qty,            -- �i�`�[�v�j�o�א��ʁi�o���j
          invoice_case_shipping_qty,            -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
          invoice_ball_shipping_qty,            -- �i�`�[�v�j�o�א��ʁi�{�[���j
          invoice_pallet_shipping_qty,          -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
          invoice_sum_shipping_qty,             -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
          invoice_indv_stockout_qty,            -- �i�`�[�v�j���i���ʁi�o���j
          invoice_case_stockout_qty,            -- �i�`�[�v�j���i���ʁi�P�[�X�j
          invoice_ball_stockout_qty,            -- �i�`�[�v�j���i���ʁi�{�[���j
          invoice_sum_stockout_qty,             -- �i�`�[�v�j���i���ʁi���v�A�o���j
          invoice_case_qty,                     -- �i�`�[�v�j�P�[�X����
          invoice_fold_container_qty,           -- �i�`�[�v�j�I���R���i�o���j����
          invoice_order_cost_amt,               -- �i�`�[�v�j�������z�i�����j
          invoice_shipping_cost_amt,            -- �i�`�[�v�j�������z�i�o�ׁj
          invoice_stockout_cost_amt,            -- �i�`�[�v�j�������z�i���i�j
          invoice_order_price_amt,              -- �i�`�[�v�j�������z�i�����j
          invoice_shipping_price_amt,           -- �i�`�[�v�j�������z�i�o�ׁj
          invoice_stockout_price_amt,           -- �i�`�[�v�j�������z�i���i�j
          total_indv_order_qty,                 -- �i�����v�j�������ʁi�o���j
          total_case_order_qty,                 -- �i�����v�j�������ʁi�P�[�X�j
          total_ball_order_qty,                 -- �i�����v�j�������ʁi�{�[���j
          total_sum_order_qty,                  -- �i�����v�j�������ʁi���v�A�o���j
          total_indv_shipping_qty,              -- �i�����v�j�o�א��ʁi�o���j
          total_case_shipping_qty,              -- �i�����v�j�o�א��ʁi�P�[�X�j
          total_ball_shipping_qty,              -- �i�����v�j�o�א��ʁi�{�[���j
          total_pallet_shipping_qty,            -- �i�����v�j�o�א��ʁi�p���b�g�j
          total_sum_shipping_qty,               -- �i�����v�j�o�א��ʁi���v�A�o���j
          total_indv_stockout_qty,              -- �i�����v�j���i���ʁi�o���j
          total_case_stockout_qty,              -- �i�����v�j���i���ʁi�P�[�X�j
          total_ball_stockout_qty,              -- �i�����v�j���i���ʁi�{�[���j
          total_sum_stockout_qty,               -- �i�����v�j���i���ʁi���v�A�o���j
          total_case_qty,                       -- �i�����v�j�P�[�X����
          total_fold_container_qty,             -- �i�����v�j�I���R���i�o���j����
          total_order_cost_amt,                 -- �i�����v�j�������z�i�����j
          total_shipping_cost_amt,              -- �i�����v�j�������z�i�o�ׁj
          total_stockout_cost_amt,              -- �i�����v�j�������z�i���i�j
          total_order_price_amt,                -- �i�����v�j�������z�i�����j
          total_shipping_price_amt,             -- �i�����v�j�������z�i�o�ׁj
          total_stockout_price_amt,             -- �i�����v�j�������z�i���i�j
          total_line_qty,                       -- �g�[�^���s��
          total_invoice_qty,                    -- �g�[�^���`�[����
          chain_peculiar_area_footer,           -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
          conv_customer_code,                   -- �ϊ���ڋq�R�[�h
          order_forward_flag,                   -- �󒍘A�g�σt���O
          creation_class,                       -- �쐬���敪
          edi_delivery_schedule_flag,           -- edi�[�i�\�著�M�σt���O
          price_list_header_id,                 -- ���i�\�w�b�_id
          created_by,                           -- �쐬��
          creation_date,                        -- �쐬��
          last_updated_by,                      -- �ŏI�X�V��
          last_update_date,                     -- �ŏI�X�V��
          last_update_login,                    -- �ŏI�X�V���O�C��
          request_id,                           -- �v��ID
          program_application_id,               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          program_id,                           -- �R���J�����g�E�v���O����ID
/* 2011/07/26 Ver1.9 Mod Start */
--          program_update_date                   -- �v���O�����X�V��
          program_update_date,                  -- �v���O�����X�V��
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
          bms_header_data                       -- ���ʂa�l�r�w�b�_�f�[�^
/* 2011/07/26 Ver1.9 Add End   */
        )
      VALUES
        (
          gt_req_edi_headers_data(ln_no).edi_header_info_id,     -- EDI�w�b�_���ID
          gt_req_edi_headers_data(ln_no).medium_class,           -- �}�̋敪
          gt_req_edi_headers_data(ln_no).data_type_code,         -- �f�[�^��R�[�h
          gt_req_edi_headers_data(ln_no).file_no,                -- �t�@�C��NO
          gt_req_edi_headers_data(ln_no).info_class,             -- ���敪
          gt_req_edi_headers_data(ln_no).process_date,           -- ������
          gt_req_edi_headers_data(ln_no).process_time,           -- ��������
          gt_req_edi_headers_data(ln_no).base_code,              -- ���_�i����j�R�[�h
          gt_req_edi_headers_data(ln_no).base_name,              -- ���_���i�������j
          gt_req_edi_headers_data(ln_no).base_name_alt,          -- ���_���i�J�i�j
          gt_req_edi_headers_data(ln_no).edi_chain_code,         -- EDI�`�F�[���X�R�[�h
          gt_req_edi_headers_data(ln_no).edi_chain_name,         -- EDI�`�F�[���X���i�����j
          gt_req_edi_headers_data(ln_no).edi_chain_name_alt,     -- EDI�`�F�[���X���i�J�i�j
          gt_req_edi_headers_data(ln_no).chain_code,             -- �`�F�[���X�R�[�h
          gt_req_edi_headers_data(ln_no).chain_name,             -- �`�F�[���X���i�����j
          gt_req_edi_headers_data(ln_no).chain_name_alt,         -- �`�F�[���X���i�J�i�j
          gt_req_edi_headers_data(ln_no).report_code,            -- ���[�R�[�h
          gt_req_edi_headers_data(ln_no).report_show_name,       -- ���[�\����
          gt_req_edi_headers_data(ln_no).customer_code,          -- �ڋq�R�[�h
          gt_req_edi_headers_data(ln_no).customer_name,          -- �ڋq���i�����j
          gt_req_edi_headers_data(ln_no).customer_name_alt,      -- �ڋq���i�J�i�j
          gt_req_edi_headers_data(ln_no).company_code,           -- �ЃR�[�h
          gt_req_edi_headers_data(ln_no).company_name,           -- �Ж��i�����j
          gt_req_edi_headers_data(ln_no).company_name_alt,       -- �Ж��i�J�i�j
          gt_req_edi_headers_data(ln_no).shop_code,              -- �X�R�[�h
          gt_req_edi_headers_data(ln_no).shop_name,              -- �X���i�����j
          gt_req_edi_headers_data(ln_no).shop_name_alt,          -- �X���i�J�i�j
          gt_req_edi_headers_data(ln_no).deli_center_code,       -- �[���Z���^�[�R�[�h
          gt_req_edi_headers_data(ln_no).deli_center_name,       -- �[���Z���^�[���i�����j
          gt_req_edi_headers_data(ln_no).deli_center_name_alt,   -- �[���Z���^�[���i�J�i�j
          gt_req_edi_headers_data(ln_no).order_date,             -- ������
          gt_req_edi_headers_data(ln_no).center_delivery_date,   -- �Z���^�[�[�i��
          gt_req_edi_headers_data(ln_no).result_delivery_date,   -- ���[�i��
          gt_req_edi_headers_data(ln_no).shop_delivery_date,     -- �X�ܔ[�i��
          gt_req_edi_headers_data(ln_no).data_cd_edi_data,       -- �f�[�^�쐬���iEDI�f�[�^���j
          gt_req_edi_headers_data(ln_no).data_ct_edi_data,       -- �f�[�^�쐬�����iEDI�f�[�^���j
          gt_req_edi_headers_data(ln_no).invoice_class,          -- �`�[�敪
          gt_req_edi_headers_data(ln_no).small_class_cd,         -- �����ރR�[�h
          gt_req_edi_headers_data(ln_no).small_class_nm,         -- �����ޖ�
          gt_req_edi_headers_data(ln_no).mid_class_cd,           -- �����ރR�[�h
          gt_req_edi_headers_data(ln_no).mid_class_nm,           -- �����ޖ�
          gt_req_edi_headers_data(ln_no).big_class_cd,           -- �啪�ރR�[�h
          gt_req_edi_headers_data(ln_no).big_class_nm,           -- �啪�ޖ�
          gt_req_edi_headers_data(ln_no).other_par_dep_cd,       -- ����敔��R�[�h
          gt_req_edi_headers_data(ln_no).other_par_order_num,    -- ����攭���ԍ�
          gt_req_edi_headers_data(ln_no).check_digit_class,      -- �`�F�b�N�f�W�b�g�L���敪
          gt_req_edi_headers_data(ln_no).invoice_number,         -- �`�[�ԍ�
          gt_req_edi_headers_data(ln_no).check_digit,            -- �`�F�b�N�f�W�b�g
          gt_req_edi_headers_data(ln_no).close_date,             -- ����
          gt_req_edi_headers_data(ln_no).order_no_ebs,           -- ��NO�iEBS�j
          gt_req_edi_headers_data(ln_no).ar_sale_class,          -- �����敪
          gt_req_edi_headers_data(ln_no).delivery_classe,        -- �z���敪
          gt_req_edi_headers_data(ln_no).opportunity_no,         -- ��NO
          gt_req_edi_headers_data(ln_no).contact_to,             -- �A����
          gt_req_edi_headers_data(ln_no).route_sales,            -- ���[�g�Z�[���X
          gt_req_edi_headers_data(ln_no).corporate_code,         -- �@�l�R�[�h
          gt_req_edi_headers_data(ln_no).maker_name,             -- ���[�J�[��
          gt_req_edi_headers_data(ln_no).area_code,              -- �n��R�[�h
          gt_req_edi_headers_data(ln_no).area_name,              -- �n�於�i�����j
          gt_req_edi_headers_data(ln_no).area_name_alt,          -- �n�於�i�J�i�j
          gt_req_edi_headers_data(ln_no).vendor_code,            -- �����R�[�h
          gt_req_edi_headers_data(ln_no).vendor_name,            -- ����於�i�����j
          gt_req_edi_headers_data(ln_no).vendor_name1_alt,       -- ����於�P�i�J�i�j
          gt_req_edi_headers_data(ln_no).vendor_name2_alt,       -- ����於�Q�i�J�i�j
          gt_req_edi_headers_data(ln_no).vendor_tel,             -- �����TEL
          gt_req_edi_headers_data(ln_no).vendor_charge,          -- �����S����
          gt_req_edi_headers_data(ln_no).vendor_address,         -- �����Z���i�����j
          gt_req_edi_headers_data(ln_no).deli_to_cd_itouen,      -- �͂���R�[�h�i�ɓ����j
          gt_req_edi_headers_data(ln_no).deli_to_cd_chain,       -- �͂���R�[�h�i�`�F�[���X�j
          gt_req_edi_headers_data(ln_no).deli_to,                -- �͂���i�����j
          gt_req_edi_headers_data(ln_no).deli_to1_alt,           -- �͂���P�i�J�i�j
          gt_req_edi_headers_data(ln_no).deli_to2_alt,           -- �͂���Q�i�J�i�j
          gt_req_edi_headers_data(ln_no).deli_to_add,            -- �͂���Z���i�����j
          gt_req_edi_headers_data(ln_no).deli_to_add_alt,        -- �͂���Z���i�J�i�j
          gt_req_edi_headers_data(ln_no).deli_to_tel,            -- �͂���TEL
          gt_req_edi_headers_data(ln_no).bal_accounts_cd,        -- ������R�[�h
          gt_req_edi_headers_data(ln_no).bal_acc_comp_cd,        -- ������ЃR�[�h
          gt_req_edi_headers_data(ln_no).bal_acc_shop_cd,        -- ������X�R�[�h
          gt_req_edi_headers_data(ln_no).bal_acc_name,           -- �����於�i�����j
          gt_req_edi_headers_data(ln_no).bal_acc_name_alt,       -- �����於�i�J�i�j
          gt_req_edi_headers_data(ln_no).bal_acc_add,            -- ������Z���i�����j
          gt_req_edi_headers_data(ln_no).bal_acc_add_alt,        -- ������Z���i�J�i�j
          gt_req_edi_headers_data(ln_no).bal_acc_tel,            -- ������TEL
          gt_req_edi_headers_data(ln_no).order_possible_date,    -- �󒍉\��
          gt_req_edi_headers_data(ln_no).perm_poss_date,         -- ���e�\��
          gt_req_edi_headers_data(ln_no).forward_month,          -- ����N����
          gt_req_edi_headers_data(ln_no).pay_settl_date,         -- �x�����ϓ�
          gt_req_edi_headers_data(ln_no).hand_st_date_act,       -- �`���V�J�n��
          gt_req_edi_headers_data(ln_no).billing_due_date,       -- ��������
          gt_req_edi_headers_data(ln_no).shipping_time,          -- �o�׎���
          gt_req_edi_headers_data(ln_no).deli_schedule_time,     -- �[�i�\�莞��
          gt_req_edi_headers_data(ln_no).order_time,             -- ��������
          gt_req_edi_headers_data(ln_no).general_date_item1,     -- �ėp���t���ڂP
          gt_req_edi_headers_data(ln_no).general_date_item2,     -- �ėp���t���ڂQ
          gt_req_edi_headers_data(ln_no).general_date_item3,     -- �ėp���t���ڂR
          gt_req_edi_headers_data(ln_no).general_date_item4,     -- �ėp���t���ڂS
          gt_req_edi_headers_data(ln_no).general_date_item5,     -- �ėp���t���ڂT
          gt_req_edi_headers_data(ln_no).arr_shipping_class,     -- ���o�׋敪
          gt_req_edi_headers_data(ln_no).vendor_class,           -- �����敪
          gt_req_edi_headers_data(ln_no).inv_detailed_class,     -- �`�[����敪
          gt_req_edi_headers_data(ln_no).unit_price_use_class,   -- �P���g�p�敪
          gt_req_edi_headers_data(ln_no).sub_dist_center_cd,     -- �T�u�����Z���^�[�R�[�h
          gt_req_edi_headers_data(ln_no).sub_dist_center_nm,     -- �T�u�����Z���^�[�R�[�h��
          gt_req_edi_headers_data(ln_no).center_deli_method,     -- �Z���^�[�[�i���@
          gt_req_edi_headers_data(ln_no).center_use_class,       -- �Z���^�[���p�敪
          gt_req_edi_headers_data(ln_no).center_whse_class,      -- �Z���^�[�q�ɋ敪
          gt_req_edi_headers_data(ln_no).center_area_class,      -- �Z���^�[�n��敪
          gt_req_edi_headers_data(ln_no).center_arr_class,       -- �Z���^�[���׋敪
          gt_req_edi_headers_data(ln_no).depot_class,            -- �f�|�敪
          gt_req_edi_headers_data(ln_no).tcdc_class,             -- TCDC�敪
          gt_req_edi_headers_data(ln_no).upc_flag,               -- UPC�t���O
          gt_req_edi_headers_data(ln_no).simultaneously_cls,     -- ��ċ敪
          gt_req_edi_headers_data(ln_no).business_id,            -- �Ɩ�ID
          gt_req_edi_headers_data(ln_no).whse_directly_cls,      -- �q���敪
          gt_req_edi_headers_data(ln_no).premium_rebate_cls,     -- �i�i���ߋ敪
          gt_req_edi_headers_data(ln_no).item_type,              -- ���ڎ��
          gt_req_edi_headers_data(ln_no).cloth_hous_fod_cls,     -- �߉ƐH�敪
          gt_req_edi_headers_data(ln_no).mix_class,              -- ���݋敪
          gt_req_edi_headers_data(ln_no).stk_class,              -- �݌ɋ敪
          gt_req_edi_headers_data(ln_no).last_mod_site_cls,      -- �ŏI�C���ꏊ�敪
          gt_req_edi_headers_data(ln_no).report_class,           -- ���[�敪
          gt_req_edi_headers_data(ln_no).add_plan_cls,           -- �ǉ��E�v��敪
          gt_req_edi_headers_data(ln_no).registration_class,     -- �o�^�敪
          gt_req_edi_headers_data(ln_no).specific_class,         -- ����敪
          gt_req_edi_headers_data(ln_no).dealings_class,         -- ����敪
          gt_req_edi_headers_data(ln_no).order_class,            -- �����敪
          gt_req_edi_headers_data(ln_no).sum_line_class,         -- �W�v���׋敪
          gt_req_edi_headers_data(ln_no).ship_guidance_cls,      -- �o�׈ē��ȊO�敪
          gt_req_edi_headers_data(ln_no).shipping_class,         -- �o�׋敪
          gt_req_edi_headers_data(ln_no).prod_cd_use_cls,        -- ���i�R�[�h�g�p�敪
          gt_req_edi_headers_data(ln_no).cargo_item_class,       -- �ϑ��i�敪
          gt_req_edi_headers_data(ln_no).ta_class,               -- T/A�敪
          gt_req_edi_headers_data(ln_no).plan_code,              -- ���R�[�h
          gt_req_edi_headers_data(ln_no).category_code,          -- �J�e�S���[�R�[�h
          gt_req_edi_headers_data(ln_no).category_class,         -- �J�e�S���[�敪
          gt_req_edi_headers_data(ln_no).carrier_means,          -- �^����i
          gt_req_edi_headers_data(ln_no).counter_code,           -- ����R�[�h
          gt_req_edi_headers_data(ln_no).move_sign,              -- �ړ��T�C��
          gt_req_edi_headers_data(ln_no).eos_handwrit_cls,       -- EOS�E�菑�敪
          gt_req_edi_headers_data(ln_no).deli_to_section_cd,     -- �[�i��ۃR�[�h
          gt_req_edi_headers_data(ln_no).invoice_detailed,       -- �`�[����
          gt_req_edi_headers_data(ln_no).attach_qty,             -- �Y�t��
          gt_req_edi_headers_data(ln_no).other_party_floor,      -- �t���A
          gt_req_edi_headers_data(ln_no).text_no,                -- TEXTNO
          gt_req_edi_headers_data(ln_no).in_store_code,          -- �C���X�g�A�R�[�h
          gt_req_edi_headers_data(ln_no).tag_data,               -- �^�O
          gt_req_edi_headers_data(ln_no).competition_code,       -- ����
          gt_req_edi_headers_data(ln_no).billing_chair,          -- ��������
          gt_req_edi_headers_data(ln_no).chain_store_code,       -- �`�F�[���X�g�A�[�R�[�h
          gt_req_edi_headers_data(ln_no).chain_st_sh_name,       -- �`�F�[���X�g�A�[�R�[�h��������
          gt_req_edi_headers_data(ln_no).dir_deli_rcpt_fee,      -- ���z���^���旿
          gt_req_edi_headers_data(ln_no).bill_info,              -- ��`���
          gt_req_edi_headers_data(ln_no).description,            -- �E�v
          gt_req_edi_headers_data(ln_no).interior_code,          -- �����R�[�h
          gt_req_edi_headers_data(ln_no).order_in_deli_cate,     -- �������@�[�i�J�e�S���[
          gt_req_edi_headers_data(ln_no).purchase_type,          -- �d���`��
          gt_req_edi_headers_data(ln_no).deli_to_name_alt,       -- �[�i�ꏊ���i�J�i�j
          gt_req_edi_headers_data(ln_no).shop_opened_site,       -- �X�o�ꏊ
          gt_req_edi_headers_data(ln_no).counter_name,           -- ���ꖼ
          gt_req_edi_headers_data(ln_no).extension_number,       -- �����ԍ�
          gt_req_edi_headers_data(ln_no).charge_name,            -- �S���Җ�
          gt_req_edi_headers_data(ln_no).price_tag,              -- �l�D
          gt_req_edi_headers_data(ln_no).tax_type,               -- �Ŏ�
          gt_req_edi_headers_data(ln_no).consump_tax_cls,        -- ����ŋ敪
          gt_req_edi_headers_data(ln_no).brand_class,            -- BR
          gt_req_edi_headers_data(ln_no).id_code,                -- ID�R�[�h
          gt_req_edi_headers_data(ln_no).department_code,        -- �S�ݓX�R�[�h
          gt_req_edi_headers_data(ln_no).department_name,        -- �S�ݓX��
          gt_req_edi_headers_data(ln_no).item_type_number,       -- �i�ʔԍ�
          gt_req_edi_headers_data(ln_no).description_depart,     -- �E�v�i�S�ݓX�j
          gt_req_edi_headers_data(ln_no).price_tag_method,       -- �l�D���@
          gt_req_edi_headers_data(ln_no).reason_column,          -- ���R��
          gt_req_edi_headers_data(ln_no).a_column_header,        -- A���w�b�_
          gt_req_edi_headers_data(ln_no).d_column_header,        -- D���w�b�_
          gt_req_edi_headers_data(ln_no).brand_code,             -- �u�����h�R�[�h
          gt_req_edi_headers_data(ln_no).line_code,              -- ���C���R�[�h
          gt_req_edi_headers_data(ln_no).class_code,             -- �N���X�R�[�h
          gt_req_edi_headers_data(ln_no).a1_column,              -- �`�|�P��
          gt_req_edi_headers_data(ln_no).b1_column,              -- �a�|�P��
          gt_req_edi_headers_data(ln_no).c1_column,              -- �b�|�P��
          gt_req_edi_headers_data(ln_no).d1_column,              -- �c�|�P��
          gt_req_edi_headers_data(ln_no).e1_column,              -- �d�|�P��
          gt_req_edi_headers_data(ln_no).a2_column,              -- �`�|�Q��
          gt_req_edi_headers_data(ln_no).b2_column,              -- �a�|�Q��
          gt_req_edi_headers_data(ln_no).c2_column,              -- �b�|�Q��
          gt_req_edi_headers_data(ln_no).d2_column,              -- �c�|�Q��
          gt_req_edi_headers_data(ln_no).e2_column,              -- �d�|�Q��
          gt_req_edi_headers_data(ln_no).a3_column,              -- �`�|�R��
          gt_req_edi_headers_data(ln_no).b3_column,              -- �a�|�R��
          gt_req_edi_headers_data(ln_no).c3_column,              -- �b�|�R��
          gt_req_edi_headers_data(ln_no).d3_column,              -- �c�|�R��
          gt_req_edi_headers_data(ln_no).e3_column,              -- �d�|�R��
          gt_req_edi_headers_data(ln_no).f1_column,              -- �e�|�P��
          gt_req_edi_headers_data(ln_no).g1_column,              -- �f�|�P��
          gt_req_edi_headers_data(ln_no).h1_column,              -- �g�|�P��
          gt_req_edi_headers_data(ln_no).i1_column,              -- �h�|�P��
          gt_req_edi_headers_data(ln_no).j1_column,              -- �i�|�P��
          gt_req_edi_headers_data(ln_no).k1_column,              -- �j�|�P��
          gt_req_edi_headers_data(ln_no).l1_column,              -- �k�|�P��
          gt_req_edi_headers_data(ln_no).f2_column,              -- �e�|�Q��
          gt_req_edi_headers_data(ln_no).g2_column,              -- �f�|�Q��
          gt_req_edi_headers_data(ln_no).h2_column,              -- �g�|�Q��
          gt_req_edi_headers_data(ln_no).i2_column,              -- �h�|�Q��
          gt_req_edi_headers_data(ln_no).j2_column,              -- �i�|�Q��
          gt_req_edi_headers_data(ln_no).k2_column,              -- �j�|�Q��
          gt_req_edi_headers_data(ln_no).l2_column,              -- �k�|�Q��
          gt_req_edi_headers_data(ln_no).f3_column,              -- �e�|�R��
          gt_req_edi_headers_data(ln_no).g3_column,              -- �f�|�R��
          gt_req_edi_headers_data(ln_no).h3_column,              -- �g�|�R��
          gt_req_edi_headers_data(ln_no).i3_column,              -- �h�|�R��
          gt_req_edi_headers_data(ln_no).j3_column,              -- �i�|�R��
          gt_req_edi_headers_data(ln_no).k3_column,              -- �j�|�R��
          gt_req_edi_headers_data(ln_no).l3_column,              -- �k�|�R��
-- 2010/04/23 v1.8 T.Yoshimoto Mod Start �{�ғ�#2427
--          gt_req_edi_headers_data(ln_no).chain_pe_area_foot,     -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
          gt_req_edi_headers_data(ln_no).chain_pe_area_head,     -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
-- 2010/04/23 v1.8 T.Yoshimoto Mod End �{�ғ�#2427
          gt_req_edi_headers_data(ln_no).order_connect_num,      -- �󒍊֘A�ԍ�
          gt_req_edi_headers_data(ln_no).inv_indv_order_qty,     -- �i�`�[�v�j�������ʁi�o���j
          gt_req_edi_headers_data(ln_no).inv_case_order_qty,     -- �i�`�[�v�j�������ʁi�P�[�X�j
          gt_req_edi_headers_data(ln_no).inv_ball_order_qty,     -- �i�`�[�v�j�������ʁi�{�[���j
          gt_req_edi_headers_data(ln_no).inv_sum_order_qty,      -- �i�`�[�v�j�������ʁi���v�A�o���j
          gt_req_edi_headers_data(ln_no).inv_indv_ship_qty,      -- �i�`�[�v�j�o�א��ʁi�o���j
          gt_req_edi_headers_data(ln_no).inv_case_ship_qty,      -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
          gt_req_edi_headers_data(ln_no).inv_ball_ship_qty,      -- �i�`�[�v�j�o�א��ʁi�{�[���j
          gt_req_edi_headers_data(ln_no).inv_pall_ship_qty,      -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
          gt_req_edi_headers_data(ln_no).inv_sum_ship_qty,       -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
          gt_req_edi_headers_data(ln_no).inv_indv_stock_qty,     -- �i�`�[�v�j���i���ʁi�o���j
          gt_req_edi_headers_data(ln_no).inv_case_stock_qty,     -- �i�`�[�v�j���i���ʁi�P�[�X�j
          gt_req_edi_headers_data(ln_no).inv_ball_stock_qty,     -- �i�`�[�v�j���i���ʁi�{�[���j
          gt_req_edi_headers_data(ln_no).inv_sum_stock_qty,      -- �i�`�[�v�j���i���ʁi���v�A�o���j
          gt_req_edi_headers_data(ln_no).inv_case_qty,           -- �i�`�[�v�j�P�[�X����
          gt_req_edi_headers_data(ln_no).inv_fold_cont_qty,      -- �i�`�[�v�j�I���R���i�o���j����
          gt_req_edi_headers_data(ln_no).inv_order_cost_amt,     -- �i�`�[�v�j�������z�i�����j
          gt_req_edi_headers_data(ln_no).inv_ship_cost_amt,      -- �i�`�[�v�j�������z�i�o�ׁj
          gt_req_edi_headers_data(ln_no).inv_stock_cost_amt,     -- �i�`�[�v�j�������z�i���i�j
          gt_req_edi_headers_data(ln_no).inv_order_price_amt,    -- �i�`�[�v�j�������z�i�����j
          gt_req_edi_headers_data(ln_no).inv_ship_price_amt,     -- �i�`�[�v�j�������z�i�o�ׁj
          gt_req_edi_headers_data(ln_no).inv_stock_price_amt,    -- �i�`�[�v�j�������z�i���i�j
          gt_req_edi_headers_data(ln_no).tot_indv_order_qty,     -- �i�����v�j�������ʁi�o���j
          gt_req_edi_headers_data(ln_no).tot_case_order_qty,     -- �i�����v�j�������ʁi�P�[�X�j
          gt_req_edi_headers_data(ln_no).tot_ball_order_qty,     -- �i�����v�j�������ʁi�{�[���j
          gt_req_edi_headers_data(ln_no).tot_sum_order_qty,      -- �i�����v�j�������ʁi���v�A�o���j
          gt_req_edi_headers_data(ln_no).tot_indv_ship_qty,      -- �i�����v�j�o�א��ʁi�o���j
          gt_req_edi_headers_data(ln_no).tot_case_ship_qty,      -- �i�����v�j�o�א��ʁi�P�[�X�j
          gt_req_edi_headers_data(ln_no).tot_ball_ship_qty,      -- �i�����v�j�o�א��ʁi�{�[���j
          gt_req_edi_headers_data(ln_no).tot_pallet_ship_qty,    -- �i�����v�j�o�א��ʁi�p���b�g�j
          gt_req_edi_headers_data(ln_no).tot_sum_ship_qty,       -- �i�����v�j�o�א��ʁi���v�A�o���j
          gt_req_edi_headers_data(ln_no).tot_indv_stockout_qty,  -- �i�����v�j���i���ʁi�o���j
          gt_req_edi_headers_data(ln_no).tot_case_stockout_qty,  -- �i�����v�j���i���ʁi�P�[�X�j
          gt_req_edi_headers_data(ln_no).tot_ball_stockout_qty,  -- �i�����v�j���i���ʁi�{�[���j
          gt_req_edi_headers_data(ln_no).tot_sum_stockout_qty,   -- �i�����v�j���i���ʁi���v�A�o���j
          gt_req_edi_headers_data(ln_no).tot_case_qty,           -- �i�����v�j�P�[�X����
          gt_req_edi_headers_data(ln_no).tot_fold_container_qty, -- �i�����v�j�I���R���i�o���j����
          gt_req_edi_headers_data(ln_no).tot_order_cost_amt,     -- �i�����v�j�������z�i�����j
          gt_req_edi_headers_data(ln_no).tot_ship_cost_amt,      -- �i�����v�j�������z�i�o�ׁj
          gt_req_edi_headers_data(ln_no).tot_stockout_cost_amt,  -- �i�����v�j�������z�i���i�j
          gt_req_edi_headers_data(ln_no).tot_order_price_amt,    -- �i�����v�j�������z�i�����j
          gt_req_edi_headers_data(ln_no).tot_ship_price_amt,     -- �i�����v�j�������z�i�o�ׁj
          gt_req_edi_headers_data(ln_no).tot_stockout_price_amt, -- �i�����v�j�������z�i���i�j
          gt_req_edi_headers_data(ln_no).tot_line_qty,           -- �g�[�^���s��
          gt_req_edi_headers_data(ln_no).tot_invoice_qty,        -- �g�[�^���`�[����
          gt_req_edi_headers_data(ln_no).chain_pe_area_foot,     -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
          gt_req_edi_headers_data(ln_no).conv_customer_code,     -- �ϊ���ڋq�R�[�h
          gt_req_edi_headers_data(ln_no).order_forward_flag,     -- �󒍘A�g�σt���O
          gt_req_edi_headers_data(ln_no).creation_class,         -- �쐬���敪
          gt_req_edi_headers_data(ln_no).edi_deli_sche_flg,      -- edi�[�i�\�著�M�σt���O
          gt_req_edi_headers_data(ln_no).price_list_header_id,   -- ���i�\�w�b�_id
          cn_created_by,                      -- �쐬��
          cd_creation_date,                   -- �쐬��
          cn_last_updated_by,                 -- �ŏI�X�V��
          cd_last_update_date,                -- �ŏI�X�V��
          cn_last_update_login,               -- �ŏI�X�V���O�C��
          cn_request_id,                      -- �v��ID
          cn_program_application_id,          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          cn_program_id,                      -- �R���J�����g�E�v���O����ID
/* 2011/07/26 Ver1.9 Mod Start */
--          cd_program_update_date              -- �v���O�����X�V��
          cd_program_update_date,             -- �v���O�����X�V��
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
          gt_req_edi_headers_data(ln_no).bms_header_data         -- ���ʂa�l�r�w�b�_�f�[�^
/* 2011/07/26 Ver1.9 Add End   */
        );
--
    END LOOP xxcos_edi_headers_insert;
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END xxcos_in_edi_headers_insert;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_lines_insert
   * Description      : EDI���׏��e�[�u���ւ̃f�[�^�}��(A-8)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_lines_insert(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_lines_insert'; -- �v���O������
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
    lv_edi_header_info_id  NUMBER  DEFAULT 0;
--
    ln_edi_line_info_id    NUMBER  DEFAULT 0;
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
    --* -------------------------------------------------------------
    -- ���[�v�J�n�F
    --* -------------------------------------------------------------
    <<xxcos_edi_lines_insert>>
    FOR  ln_no  IN  1..gn_normal_lines_cnt  LOOP
      --* -------------------------------------------------------------
      --* Description      : EDI���׏��e�[�u���ւ̃f�[�^�}��(A-8)
      --* -------------------------------------------------------------
      INSERT  INTO  xxcos_edi_lines
        (
          edi_line_info_id,
          edi_header_info_id,
          line_no,
          stockout_class,
          stockout_reason,
          product_code_itouen,
          product_code1,
          product_code2,
          jan_code,
          itf_code,
          extension_itf_code,
          case_product_code,
          ball_product_code,
          product_code_item_type,
          prod_class,
          product_name,
          product_name1_alt,
          product_name2_alt,
          item_standard1,
          item_standard2,
          qty_in_case,
          num_of_cases,
          num_of_ball,
          item_color,
          item_size,
          expiration_date,
          product_date,
          order_uom_qty,
          shipping_uom_qty,
          packing_uom_qty,
          deal_code,
          deal_class,
          collation_code,
          uom_code,
          unit_price_class,
          parent_packing_number,
          packing_number,
          product_group_code,
          case_dismantle_flag,
          case_class,
          indv_order_qty,
          case_order_qty,
          ball_order_qty,
          sum_order_qty,
          indv_shipping_qty,
          case_shipping_qty,
          ball_shipping_qty,
          pallet_shipping_qty,
          sum_shipping_qty,
          indv_stockout_qty,
          case_stockout_qty,
          ball_stockout_qty,
          sum_stockout_qty,
          case_qty,
          fold_container_indv_qty,
          order_unit_price,
          shipping_unit_price,
          order_cost_amt,
          shipping_cost_amt,
          stockout_cost_amt,
          selling_price,
          order_price_amt,
          shipping_price_amt,
          stockout_price_amt,
          a_column_department,
          d_column_department,
          standard_info_depth,
          standard_info_height,
          standard_info_width,
          standard_info_weight,
          general_succeeded_item1,
          general_succeeded_item2,
          general_succeeded_item3,
          general_succeeded_item4,
          general_succeeded_item5,
          general_succeeded_item6,
          general_succeeded_item7,
          general_succeeded_item8,
          general_succeeded_item9,
          general_succeeded_item10,
          general_add_item1,
          general_add_item2,
          general_add_item3,
          general_add_item4,
          general_add_item5,
          general_add_item6,
          general_add_item7,
          general_add_item8,
          general_add_item9,
          general_add_item10,
          chain_peculiar_area_line,
          item_code,
          line_uom,
          order_connection_line_number,
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          last_update_login,
          request_id,
          program_application_id,
          program_id,
/* 2011/07/26 Ver1.9 Mod Start */
--          program_update_date
          program_update_date,
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
          bms_line_data
/* 2011/07/26 Ver1.9 Add End   */
        )
      VALUES
        (
          gt_req_edi_lines_data(ln_no).edi_line_info_id,        -- EDI���׏��ID
          gt_req_edi_lines_data(ln_no).edi_header_info_id,      -- EDI�w�b�_���ID
          gt_req_edi_lines_data(ln_no).line_no,                 -- �s����
          gt_req_edi_lines_data(ln_no).stockout_class,          -- ���i�敪
          gt_req_edi_lines_data(ln_no).stockout_reason,         -- ���i���R
          gt_req_edi_lines_data(ln_no).product_code_itouen,     -- ���i�R�[�h�i�ɓ����j
          gt_req_edi_lines_data(ln_no).product_code1,           -- ���i�R�[�h�P
          gt_req_edi_lines_data(ln_no).product_code2,           -- ���i�R�[�h�Q
          gt_req_edi_lines_data(ln_no).jan_code,                -- JAN�R�[�h
          gt_req_edi_lines_data(ln_no).itf_code,                -- ITF�R�[�h
          gt_req_edi_lines_data(ln_no).extension_itf_code,      -- ����ITF�R�[�h
          gt_req_edi_lines_data(ln_no).case_product_code,       -- �P�[�X���i�R�[�h
          gt_req_edi_lines_data(ln_no).ball_product_code,       -- �{�[�����i�R�[�h
          gt_req_edi_lines_data(ln_no).prod_cd_item_type,       -- ���i�R�[�h�i��
          gt_req_edi_lines_data(ln_no).prod_class,              -- ���i�敪
          gt_req_edi_lines_data(ln_no).product_name,            -- ���i���i�����j
          gt_req_edi_lines_data(ln_no).product_name1_alt,       -- ���i���P�i�J�i�j
          gt_req_edi_lines_data(ln_no).product_name2_alt,       -- ���i���Q�i�J�i�j
          gt_req_edi_lines_data(ln_no).item_standard1,          -- �K�i�P
          gt_req_edi_lines_data(ln_no).item_standard2,          -- �K�i�Q
          gt_req_edi_lines_data(ln_no).qty_in_case,             -- ����
          gt_req_edi_lines_data(ln_no).num_of_cases,            -- �P�[�X����
          gt_req_edi_lines_data(ln_no).num_of_ball,             -- �{�[������
          gt_req_edi_lines_data(ln_no).item_color,              -- �F
          gt_req_edi_lines_data(ln_no).item_size,               -- �T�C�Y
          gt_req_edi_lines_data(ln_no).expiration_date,         -- �ܖ�������
          gt_req_edi_lines_data(ln_no).product_date,            -- ������
          gt_req_edi_lines_data(ln_no).order_uom_qty,           -- �����P�ʐ�
          gt_req_edi_lines_data(ln_no).ship_uom_qty,            -- �o�גP�ʐ�
          gt_req_edi_lines_data(ln_no).packing_uom_qty,         -- ����P�ʐ�
          gt_req_edi_lines_data(ln_no).deal_code,               -- ����
          gt_req_edi_lines_data(ln_no).deal_class,              -- �����敪
          gt_req_edi_lines_data(ln_no).collation_code,          -- �ƍ�
          gt_req_edi_lines_data(ln_no).uom_code,                -- �P��
          gt_req_edi_lines_data(ln_no).unit_price_class,        -- �P���敪
          gt_req_edi_lines_data(ln_no).parent_pack_num,         -- �e����ԍ�
          gt_req_edi_lines_data(ln_no).packing_number,          -- ����ԍ�
          gt_req_edi_lines_data(ln_no).product_group_code,      -- ���i�Q�R�[�h
          gt_req_edi_lines_data(ln_no).case_dismantle_flag,     -- �P�[�X��̕s�t���O
          gt_req_edi_lines_data(ln_no).case_class,              -- �P�[�X�敪
          gt_req_edi_lines_data(ln_no).indv_order_qty,          -- �������ʁi�o���j
          gt_req_edi_lines_data(ln_no).case_order_qty,          -- �������ʁi�P�[�X�j
          gt_req_edi_lines_data(ln_no).ball_order_qty,          -- �������ʁi�{�[���j
          gt_req_edi_lines_data(ln_no).sum_order_qty,           -- �������ʁi���v�A�o���j
          gt_req_edi_lines_data(ln_no).indv_shipping_qty,       -- �o�א��ʁi�o���j
          gt_req_edi_lines_data(ln_no).case_shipping_qty,       -- �o�א��ʁi�P�[�X�j
          gt_req_edi_lines_data(ln_no).ball_shipping_qty,       -- �o�א��ʁi�{�[���j
          gt_req_edi_lines_data(ln_no).pallet_shipping_qty,     -- �o�א��ʁi�p���b�g�j
          gt_req_edi_lines_data(ln_no).sum_shipping_qty,        -- �o�א��ʁi���v�A�o���j
          gt_req_edi_lines_data(ln_no).indv_stockout_qty,       -- ���i���ʁi�o���j
          gt_req_edi_lines_data(ln_no).case_stockout_qty,       -- ���i���ʁi�P�[�X�j
          gt_req_edi_lines_data(ln_no).ball_stockout_qty,       -- ���i���ʁi�{�[���j
          gt_req_edi_lines_data(ln_no).sum_stockout_qty,        -- ���i���ʁi���v�A�o���j
          gt_req_edi_lines_data(ln_no).case_qty,                -- �P�[�X����
          gt_req_edi_lines_data(ln_no).fold_cont_indv_qty,      -- �I���R���i�o���j����
          gt_req_edi_lines_data(ln_no).order_unit_price,        -- ���P���i�����j
          gt_req_edi_lines_data(ln_no).shipping_unit_price,     -- ���P���i�o�ׁj
          gt_req_edi_lines_data(ln_no).order_cost_amt,          -- �������z�i�����j
          gt_req_edi_lines_data(ln_no).shipping_cost_amt,       -- �������z�i�o�ׁj
          gt_req_edi_lines_data(ln_no).stockout_cost_amt,       -- �������z�i���i�j
          gt_req_edi_lines_data(ln_no).selling_price,           -- ���P��
          gt_req_edi_lines_data(ln_no).order_price_amt,         -- �������z�i�����j
          gt_req_edi_lines_data(ln_no).shipping_price_amt,      -- �������z�i�o�ׁj
          gt_req_edi_lines_data(ln_no).stockout_price_amt,      -- �������z�i���i�j
          gt_req_edi_lines_data(ln_no).a_col_department,        -- A���i�S�ݓX�j
          gt_req_edi_lines_data(ln_no).d_col_department,        -- D���i�S�ݓX�j
          gt_req_edi_lines_data(ln_no).stand_info_depth,        -- �K�i���E���s��
          gt_req_edi_lines_data(ln_no).stand_info_height,       -- �K�i���E����
          gt_req_edi_lines_data(ln_no).stand_info_width,        -- �K�i���E��
          gt_req_edi_lines_data(ln_no).stand_info_weight,       -- �K�i���E�d��
          gt_req_edi_lines_data(ln_no).gen_succeed_item1,       -- �ėp���p�����ڂP
          gt_req_edi_lines_data(ln_no).gen_succeed_item2,       -- �ėp���p�����ڂQ
          gt_req_edi_lines_data(ln_no).gen_succeed_item3,       -- �ėp���p�����ڂR
          gt_req_edi_lines_data(ln_no).gen_succeed_item4,       -- �ėp���p�����ڂS
          gt_req_edi_lines_data(ln_no).gen_succeed_item5,       -- �ėp���p�����ڂT
          gt_req_edi_lines_data(ln_no).gen_succeed_item6,       -- �ėp���p�����ڂU
          gt_req_edi_lines_data(ln_no).gen_succeed_item7,       -- �ėp���p�����ڂV
          gt_req_edi_lines_data(ln_no).gen_succeed_item8,       -- �ėp���p�����ڂW
          gt_req_edi_lines_data(ln_no).gen_succeed_item9,       -- �ėp���p�����ڂX
          gt_req_edi_lines_data(ln_no).gen_succeed_item10,      -- �ėp���p�����ڂP�O
          gt_req_edi_lines_data(ln_no).gen_add_item1,           -- �ėp�t�����ڂP
          gt_req_edi_lines_data(ln_no).gen_add_item2,           -- �ėp�t�����ڂQ
          gt_req_edi_lines_data(ln_no).gen_add_item3,           -- �ėp�t�����ڂR
          gt_req_edi_lines_data(ln_no).gen_add_item4,           -- �ėp�t�����ڂS
          gt_req_edi_lines_data(ln_no).gen_add_item5,           -- �ėp�t�����ڂT
          gt_req_edi_lines_data(ln_no).gen_add_item6,           -- �ėp�t�����ڂU
          gt_req_edi_lines_data(ln_no).gen_add_item7,           -- �ėp�t�����ڂV
          gt_req_edi_lines_data(ln_no).gen_add_item8,           -- �ėp�t�����ڂW
          gt_req_edi_lines_data(ln_no).gen_add_item9,           -- �ėp�t�����ڂX
          gt_req_edi_lines_data(ln_no).gen_add_item10,          -- �ėp�t�����ڂP�O
          gt_req_edi_lines_data(ln_no).chain_pec_a_line,        -- �`�F�[���X�ŗL�G���A�i���ׁj
          gt_req_edi_lines_data(ln_no).item_code,               -- �i�ڃR�[�h
          gt_req_edi_lines_data(ln_no).line_uom,                -- �P�[�X�o���敪
          gt_req_edi_lines_data(ln_no).order_con_line_num,      -- �󒍊֘A���הԍ�
          cn_created_by,                          -- �쐬��
          cd_creation_date,                       -- �쐬��
          cn_last_updated_by,                     -- �ŏI�X�V��
          cd_last_update_date,                    -- �ŏI�X�V��
          cn_last_update_login,                   -- �ŏI�X�V���O�C��
          cn_request_id,                          -- �v��ID
          cn_program_application_id,              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          cn_program_id,                          -- �R���J�����g�E�v���O����ID
/* 2011/07/26 Ver1.9 Mod Start */
--          cd_program_update_date                  -- �v���O�����X�V��
          cd_program_update_date,                 -- �v���O�����X�V��
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
          gt_req_edi_lines_data(ln_no).bms_line_data            -- ���ʂa�l�r�w�b�_�f�[�^
/* 2011/07/26 Ver1.9 Add End   */
        );
--
    END LOOP  xxcos_edi_lines_insert;
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
--
  --��������
  gn_normal_cnt := gn_normal_lines_cnt;
--
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--

    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END xxcos_in_edi_lines_insert;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_deli_work_delete
   * Description      : EDI�[�i�ԕi��񃏁[�N�e�[�u���f�[�^�폜(A-9)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_deli_work_delete(
    iv_file_name      IN  VARCHAR2,     --   �C���^�t�F�[�X�t�@�C����
    iv_run_class      IN  VARCHAR2,     --   ���s�敪�F�u�V�K�v�u�Ď��s�v
    iv_edi_chain_code IN  VARCHAR2,     --   EDI�`�F�[���X�R�[�h
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_deli_work_delete'; -- �v���O������
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
    BEGIN
      DELETE FROM xxcos_edi_delivery_work edideliwk
       WHERE  edideliwk.if_file_name     = iv_file_name           -- �C���^�t�F�[�X�t�@�C����
         AND  edideliwk.err_status       = iv_run_class           -- ���s�敪
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--         AND  edideliwk.data_type_code   = gv_run_data_type_code  -- �f�[�^��R�[�h
         AND  edideliwk.data_type_code   IN ( cv_data_type_32, cv_data_type_33 )  -- �f�[�^��R�[�h
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
         AND (( iv_edi_chain_code IS NOT NULL
         AND   edideliwk.edi_chain_code  =  iv_edi_chain_code )   -- EDI�`�F�[���X�R�[�h
         OR  ( iv_edi_chain_code IS NULL ));
--
    EXCEPTION
      WHEN OTHERS THEN
        -- EDI�[�i�ԕi��񃏁[�N�e�[�u��
        gv_tkn_edi_deli_work :=  xxccp_common_pkg.get_msg(
                             iv_application  =>  cv_application,
                             iv_name         =>  cv_msg_edi_deli_work
                             );
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_application,
                   iv_name          =>  gv_msg_data_delete_err,
                   iv_token_name1   =>  cv_tkn_table_name1,
                   iv_token_name2   =>  cv_tkn_key_data,
                   iv_token_value1  =>  gv_tkn_edi_deli_work,
                   iv_token_value2  =>  iv_file_name
                   );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
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
  END xxcos_in_edi_deli_work_delete;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_head_lock
   * Description      : EDI�w�b�_���e�[�u�����b�N(A-10)(1)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_head_lock(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_head_lock'; -- �v���O������
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
    -- ===============================
    -- EDI�w�b�_���s�a�k�J�[�\��
    -- �쐬���敪���u�O�R�v�ԕi�m��f�[�^
    -- ���폜���Ԃ��߂����f�[�^
    -- (�X�ܔ[�����A�Z���^�[�[�����A�������A�f�[�^�쐬��)
    -- ===============================
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    CURSOR headers_lock_cur( lv_param1 IN CHAR )
    CURSOR headers_lock_cur
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD End    ******************************************
    IS
      SELECT head.edi_header_info_id
      FROM   xxcos_edi_headers  head
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      WHERE  head.data_type_code = lv_param1
      WHERE  head.data_type_code IN ( cv_data_type_32, cv_data_type_33 )
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
        AND  NVL(head.shop_delivery_date,
             NVL(head.center_delivery_date,
             NVL(head.order_date, TRUNC(head.data_creation_date_edi_data))))
-- ************** 2009/07/22 N.Maeda MOD START ****************** --
          <= gd_edi_del_consider_date
--          < TRUNC(cd_creation_date - TO_NUMBER(gv_prf_edi_del_date))
-- ************** 2009/07/22 N.Maeda MOD  END  ****************** --
      FOR UPDATE NOWAIT;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================================
    -- �e�[�u�����b�N(EDI�w�b�_���s�a�k�J�[�\��)
    --==============================================================
    --�J�[�\���I�[�v��(���b�N�̃`�F�b�N)
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    OPEN  headers_lock_cur( gv_run_data_type_code );
    OPEN  headers_lock_cur;
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
    --�J�[�\���N���[�Y
    CLOSE headers_lock_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      gv_tkn_edi_headers :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  cv_msg_edi_headers
                         );
      ov_errmsg          :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  gv_msg_lock,
                         iv_token_name1        =>  cv_tkn_table_name,
                         iv_token_value1       =>  gv_tkn_edi_headers
                         );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
      IF  ( headers_lock_cur%ISOPEN ) THEN
        CLOSE headers_lock_cur;
      END IF;
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
  END xxcos_in_edi_head_lock;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_line_lock
   * Description      : EDI���׏��e�[�u�����b�N(A-10)(2)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_line_lock(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_line_lock'; -- �v���O������
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
    lt_edi_header_info_id  xxcos_edi_headers.edi_header_info_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ===============================
    -- EDI�w�b�_���s�a�k�J�[�\��
    -- �쐬���敪���u�O�R�v�ԕi�m��f�[�^
    -- ���폜���Ԃ��߂����f�[�^
    -- (�X�ܔ[�����A�Z���^�[�[�����A�������A�f�[�^�쐬��)
    -- ===============================
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    CURSOR headers_cur( lv_param1 IN CHAR )
    CURSOR headers_cur
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
    IS
      SELECT head.edi_header_info_id
      FROM   xxcos_edi_headers  head
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      WHERE  head.data_type_code  = lv_param1
      WHERE  head.data_type_code  IN ( cv_data_type_32, cv_data_type_33 )
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
        AND  NVL(head.shop_delivery_date,
             NVL(head.center_delivery_date,
             NVL(head.order_date, TRUNC(head.data_creation_date_edi_data))))
-- ************** 2009/07/22 N.Maeda MOD START ****************** --
          <= gd_edi_del_consider_date;
--          < TRUNC(cd_creation_date - TO_NUMBER(gv_prf_edi_del_date));
-- ************** 2009/07/22 N.Maeda MOD  END  ****************** --
    -- ===============================
    -- EDI���׏��s�a�k�J�[�\��
    -- EDI�w�b�_���s�a�k��EDI�w�b�_ID
    -- (�X�ܔ[�����A�Z���^�[�[�����A�������A�f�[�^�쐬��)
    -- ===============================
    CURSOR lines_lock_cur(ln_param1 IN NUMBER)
    IS
      SELECT line.edi_line_info_id
      FROM   xxcos_edi_lines    line
      WHERE  line.edi_header_info_id = ln_param1
      FOR UPDATE NOWAIT;
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
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================================
    -- EDI�w�b�_���s�a�k�J�[�\������
    --==============================================================
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    OPEN headers_cur( gv_run_data_type_code );
    OPEN headers_cur;
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
    <<header_loop>>
    LOOP
      FETCH headers_cur INTO lt_edi_header_info_id;
      EXIT WHEN headers_cur%NOTFOUND;
      --==============================================================
      -- �e�[�u�����b�N(EDI���׏��s�a�k�J�[�\��)
      --==============================================================
      --�J�[�\���I�[�v��(���b�N�`�F�b�N)
      OPEN lines_lock_cur( lt_edi_header_info_id );
      --�J�[�\���N���[�Y
      CLOSE lines_lock_cur;
    END LOOP header_loop;
    CLOSE headers_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      gv_tkn_edi_lines    :=  xxccp_common_pkg.get_msg(
                          iv_application        =>  cv_application,
                          iv_name               =>  cv_msg_edi_lines
                          );
      ov_errmsg           :=  xxccp_common_pkg.get_msg(
                          iv_application        =>  cv_application,
                          iv_name               =>  gv_msg_lock,
                          iv_token_name1        =>  cv_tkn_table_name,
                          iv_token_value1       =>  gv_tkn_edi_lines
                          );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
      IF  ( headers_cur%ISOPEN ) THEN
        CLOSE headers_cur;
      END IF;
      IF  ( lines_lock_cur%ISOPEN ) THEN
        CLOSE lines_lock_cur;
      END IF;
----#################################  �Œ��O������ START   ####################################
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
  END xxcos_in_edi_line_lock;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_head_delete
   * Description      : EDI�w�b�_���e�[�u���f�[�^�폜(A-10)(3)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_head_delete(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_head_delete'; -- �v���O������
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    BEGIN
--
      --==============================================================
      -- EDI�w�b�_���s�a�k�폜 (�X�ܔ[�����A�Z���^�[�[�����A�������A�f�[�^�쐬��)
      --==============================================================
      DELETE FROM   xxcos_edi_headers  head
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      WHERE  head.data_type_code  = gv_run_data_type_code
      WHERE  head.data_type_code  IN ( cv_data_type_32, cv_data_type_33 )
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
        AND  NVL(head.shop_delivery_date,
             NVL(head.center_delivery_date,
             NVL(head.order_date, TRUNC(head.data_creation_date_edi_data))))
-- ************** 2009/07/22 N.Maeda MOD START ****************** --
          <= gd_edi_del_consider_date;
--          < TRUNC(cd_creation_date - TO_NUMBER(gv_prf_edi_del_date));
-- ************** 2009/07/22 N.Maeda MOD  END  ****************** --
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn_edi_headers :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  cv_msg_edi_headers
                           );
        lv_errmsg          :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_data_delete_err,
                           iv_token_name1        =>  cv_tkn_table_name1,
                           iv_token_name2        =>  cv_tkn_key_data,
                           iv_token_value1       =>  gv_tkn_edi_headers,
                           iv_token_value2       =>  NULL
                           );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END xxcos_in_edi_head_delete;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_line_delete
   * Description      : EDI���׏��e�[�u���f�[�^�폜(A-10)(4)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_line_delete(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_line_delete'; -- �v���O������
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
    lt_edi_header_info_id  xxcos_edi_headers.edi_header_info_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ===============================
    -- EDI�w�b�_���s�a�k�J�[�\��
    -- �쐬���敪���u�O�R�v�ԕi�m��f�[�^
    -- ���폜���Ԃ��߂����f�[�^
    -- (�X�ܔ[�����A�Z���^�[�[�����A�������A�f�[�^�쐬��)
    -- ===============================
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    CURSOR headers_lock_cur(lv_param1 IN NUMBER)
    CURSOR headers_lock_cur
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
    IS
      SELECT head.edi_header_info_id
      FROM   xxcos_edi_headers  head
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      WHERE  head.data_type_code  = lv_param1
      WHERE  head.data_type_code  IN ( cv_data_type_32, cv_data_type_33 )
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
        AND  NVL(head.shop_delivery_date,
             NVL(head.center_delivery_date,
             NVL(head.order_date, TRUNC(head.data_creation_date_edi_data))))
-- ************** 2009/07/22 N.Maeda MOD START ****************** --
          <= gd_edi_del_consider_date
--          < TRUNC(cd_creation_date - TO_NUMBER(gv_prf_edi_del_date))
-- ************** 2009/07/22 N.Maeda MOD  END  ****************** --
      FOR UPDATE NOWAIT;
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
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    BEGIN
--
      --==============================================================
      -- EDI�w�b�_���s�a�k�J�[�\��
      --==============================================================
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      OPEN  headers_lock_cur( gv_run_data_type_code );
      OPEN  headers_lock_cur;
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
      <<header_loop>>
      LOOP
        FETCH headers_lock_cur INTO lt_edi_header_info_id;
        EXIT WHEN headers_lock_cur%NOTFOUND;
        --==============================================================
        -- EDI���׏��s�a�k�폜 (�X�ܔ[�����A�Z���^�[�[�����A�������A�f�[�^�쐬��)
        --==============================================================
        DELETE  FROM   xxcos_edi_lines    line
        WHERE  line.edi_header_info_id  =  lt_edi_header_info_id;
--
      END LOOP header_loop;
      CLOSE headers_lock_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn_edi_lines :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  cv_msg_edi_lines
                         );
        lv_errmsg        :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  gv_msg_data_delete_err,
                         iv_token_name1        =>  cv_tkn_table_name1,
                         iv_token_name2        =>  cv_tkn_key_data,
                         iv_token_value1       =>  gv_tkn_edi_lines,
                         iv_token_value2       =>  NULL
                         );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
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
  END xxcos_in_edi_line_delete;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_head_line_delete
   * Description      : EDI�w�b�_���e�[�u���AEDI���׏��e�[�u���f�[�^�폜(A-10)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_head_line_delete(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_head_line_delete'; -- �v���O������
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
--
-- ************** 2009/07/22 N.Maeda ADD START ****************** --
   -- EDI���폜���ԍl�����t�쐬
   gd_edi_del_consider_date :=
     TO_DATE( ( TO_CHAR( TRUNC( cd_creation_date - TO_NUMBER( gv_prf_edi_del_date ) ) 
     , cv_format_yyyymmdd ) || cv_space || cv_time ) ,cv_date_time );
-- ************** 2009/07/22 N.Maeda ADD  END  ****************** --
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --==============================================================
    -- �e�[�u�����b�N(EDI�w�b�_���s�a�k�J�[�\��)
    --==============================================================
    xxcos_in_edi_head_lock(
       lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
       lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
       lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --==============================================================
    -- �e�[�u�����b�N(EDI���׏��s�a�k�J�[�\��)
    --==============================================================
    xxcos_in_edi_line_lock(
       lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
       lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
       lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- * Procedure Name   : xxcos_in_edi_line_delete
    -- * Description      : EDI���׏��e�[�u���f�[�^�폜(A-10)(3)
    --==============================================================
    xxcos_in_edi_line_delete(
       lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
       lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
       lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- * Procedure Name   : xxcos_in_edi_head_delete
    -- * Description      : EDI�w�b�_���e�[�u���f�[�^�폜(A-10)(3)
    --==============================================================
    xxcos_in_edi_head_delete(
       lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
       lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
       lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error ) THEN
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
  END xxcos_in_edi_head_line_delete;
--
--
  /**********************************************************************************
   * Procedure Name   : sel_in_edi_delivery_work
   * Description      : EDI�[�i�ԕi��񃏁[�N�e�[�u���f�[�^���o (A-2)
   *                  :  SQL-LOADER�ɂ����EDI�[�i�ԕi��񃏁[�N�e�[�u���Ɏ�荞�܂ꂽ���R�[�h��
   *                     ���o���܂��B�����Ƀ��R�[�h���b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE sel_in_edi_delivery_work(
    iv_file_name      IN VARCHAR2,     --   �C���^�t�F�[�X�t�@�C����
    iv_run_class      IN VARCHAR2,     --   ���s�敪�F�u�V�K�v�u�Ď��s�v
    iv_edi_chain_code IN VARCHAR2,     --   EDI�`�F�[���X�R�[�h
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sel_in_edi_delivery_work'; -- �v���O������
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
    lv_cur_param1 VARCHAR2(100) DEFAULT NULL;    -- ���o�J�[�\���p���n���p�����^�P
    lv_cur_param2 VARCHAR2(100) DEFAULT NULL;    -- ���o�J�[�\���p���n���p�����^�Q
    lv_cur_param3 VARCHAR2(100) DEFAULT NULL;    -- ���o�J�[�\���p���n���p�����^�R
    lv_cur_param4 VARCHAR2(255) DEFAULT NULL;    -- ���o�J�[�\���p���n���p�����^�S
    ln_no         NUMBER        DEFAULT 0;       -- ���[�v�J�E���^�[
--
    -- *** ���[�J���E�J�[�\�� ***
    --* -------------------------------------------------------------------------------------------
    -- EDI�[�i�ԕi��񃏁[�N�e�[�u���f�[�^���o
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    CURSOR get_edideli_work_data_cur( lv_cur_param1 CHAR, lv_cur_param2 CHAR, lv_cur_param3 CHAR, lv_cur_param4 CHAR )
    CURSOR get_edideli_work_data_cur( lv_cur_param1 CHAR, lv_cur_param3 CHAR, lv_cur_param4 CHAR )
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
    IS
    SELECT
      edideliwk.delivery_return_work_id       delivery_return_work_id,     -- �[�i�ԕi���[�NID
      edideliwk.medium_class                  medium_class,                -- �}�̋敪
      edideliwk.data_type_code                data_type_code,              -- �f�[�^��R�[�h
      edideliwk.file_no                       file_no,                     -- �t�@�C��NO
      edideliwk.info_class                    info_class,                  -- ���敪
      edideliwk.process_date                  process_date,                -- ������
      edideliwk.process_time                  process_time,                -- ��������
      edideliwk.base_code                     base_code,                   -- ���_�i����j�R�[�h
      edideliwk.base_name                     base_name,                   -- ���_���i�������j
      edideliwk.base_name_alt                 base_name_alt,               -- ���_���i�J�i�j
      edideliwk.edi_chain_code                edi_chain_code,              -- EDI�`�F�[���X�R�[�h
      edideliwk.edi_chain_name                edi_chain_name,              -- EDI�`�F�[���X���i�����j
      edideliwk.edi_chain_name_alt            edi_chain_name_alt,          -- EDI�`�F�[���X���i�J�i�j
      edideliwk.chain_code                    chain_code,                  -- �`�F�[���X�R�[�h
      edideliwk.chain_name                    chain_name,                  -- �`�F�[���X���i�����j
      edideliwk.chain_name_alt                chain_name_alt,              -- �`�F�[���X���i�J�i�j
      edideliwk.report_code                   report_code,                 -- ���[�R�[�h
      edideliwk.report_show_name              report_show_name,            -- ���[�\����
      edideliwk.customer_code                 customer_code,               -- �ڋq�R�[�h
      edideliwk.customer_name                 customer_name,               -- �ڋq���i�����j
      edideliwk.customer_name_alt             customer_name_alt,           -- �ڋq���i�J�i�j
      edideliwk.company_code                  company_code,                -- �ЃR�[�h
      edideliwk.company_name                  company_name,                -- �Ж��i�����j
      edideliwk.company_name_alt              company_name_alt,            -- �Ж��i�J�i�j
      edideliwk.shop_code                     shop_code,                   -- �X�R�[�h
      edideliwk.shop_name                     shop_name,                   -- �X���i�����j
      edideliwk.shop_name_alt                 shop_name_alt,               -- �X���i�J�i�j
      edideliwk.delivery_center_code          delivery_center_code,        -- �[���Z���^�[�R�[�h
      edideliwk.delivery_center_name          delivery_center_name,        -- �[���Z���^�[���i�����j
      edideliwk.delivery_center_name_alt      delivery_center_name_alt,    -- �[���Z���^�[���i�J�i�j
      edideliwk.order_date                    order_date,                  -- ������
      edideliwk.center_delivery_date          center_delivery_date,        -- �Z���^�[�[�i��
      edideliwk.result_delivery_date          result_delivery_date,        -- ���[�i��
      edideliwk.shop_delivery_date            shop_delivery_date,          -- �X�ܔ[�i��
      edideliwk.data_creation_date_edi_data   data_creation_date_edi_data, -- �f�[�^�쐬���iEDI�f�[�^���j
      edideliwk.data_creation_time_edi_data   data_creation_time_edi_data, -- �f�[�^�쐬�����iEDI�f�[�^���j
      edideliwk.invoice_class                 invoice_class,               -- �`�[�敪
      edideliwk.small_classification_code     small_classification_code,   -- �����ރR�[�h
      edideliwk.small_classification_name     small_classification_name,   -- �����ޖ�
      edideliwk.middle_classification_code    middle_classification_code,  -- �����ރR�[�h
      edideliwk.middle_classification_name    middle_classification_name,  -- �����ޖ�
      edideliwk.big_classification_code       big_classification_code,     -- �啪�ރR�[�h
      edideliwk.big_classification_name       big_classification_name,     -- �啪�ޖ�
      edideliwk.other_party_department_code   other_party_department_code, -- ����敔��R�[�h
      edideliwk.other_party_order_number      other_party_order_number,    -- ����攭���ԍ�
      edideliwk.check_digit_class             check_digit_class,           -- �`�F�b�N�f�W�b�g�L���敪
      edideliwk.invoice_number                invoice_number,              -- �`�[�ԍ�
      edideliwk.check_digit                   check_digit,                 -- �`�F�b�N�f�W�b�g
      edideliwk.close_date                    close_date,                  -- ����
      edideliwk.order_no_ebs                  order_no_ebs,                -- ��NO�iEBS�j
      edideliwk.ar_sale_class                 ar_sale_class,               -- �����敪
      edideliwk.delivery_classe               delivery_classe,             -- �z���敪
      edideliwk.opportunity_no                opportunity_no,              -- ��NO
      edideliwk.contact_to                    contact_to,                  -- �A����
      edideliwk.route_sales                   route_sales,                 -- ���[�g�Z�[���X
      edideliwk.corporate_code                corporate_code,              -- �@�l�R�[�h
      edideliwk.maker_name                    maker_name,                  -- ���[�J�[��
      edideliwk.area_code                     area_code,                   -- �n��R�[�h
      edideliwk.area_name                     area_name,                   -- �n�於�i�����j
      edideliwk.area_name_alt                 area_name_alt,               -- �n�於�i�J�i�j
      edideliwk.vendor_code                   vendor_code,                 -- �����R�[�h
      edideliwk.vendor_name                   vendor_name,                 -- ����於�i�����j
      edideliwk.vendor_name1_alt              vendor_name1_alt,            -- ����於�P�i�J�i�j
      edideliwk.vendor_name2_alt              vendor_name2_alt,            -- ����於�Q�i�J�i�j
      edideliwk.vendor_tel                    vendor_tel,                  -- �����TEL
      edideliwk.vendor_charge                 vendor_charge,               -- �����S����
      edideliwk.vendor_address                vendor_address,              -- �����Z���i�����j
      edideliwk.deliver_to_code_itouen        deliver_to_code_itouen,      -- �͂���R�[�h�i�ɓ����j
      edideliwk.deliver_to_code_chain         deliver_to_code_chain,       -- �͂���R�[�h�i�`�F�[���X�j
      edideliwk.deliver_to                    deliver_to,                  -- �͂���i�����j
      edideliwk.deliver_to1_alt               deliver_to1_alt,             -- �͂���P�i�J�i�j
      edideliwk.deliver_to2_alt               deliver_to2_alt,             -- �͂���Q�i�J�i�j
      edideliwk.deliver_to_address            deliver_to_address,          -- �͂���Z���i�����j
      edideliwk.deliver_to_address_alt        deliver_to_address_alt,      -- �͂���Z���i�J�i�j
      edideliwk.deliver_to_tel                deliver_to_tel,              -- �͂���TEL
      edideliwk.balance_accounts_code         balance_accounts_code,       -- ������R�[�h
      edideliwk.balance_accounts_company_code balance_accounts_company_code, -- ������ЃR�[�h
      edideliwk.balance_accounts_shop_code    balance_accounts_shop_code,  -- ������X�R�[�h
      edideliwk.balance_accounts_name         balance_accounts_name,       -- �����於�i�����j
      edideliwk.balance_accounts_name_alt     balance_accounts_name_alt,   -- �����於�i�J�i�j
      edideliwk.balance_accounts_address      balance_accounts_address,    -- ������Z���i�����j
      edideliwk.balance_accounts_address_alt  balance_accounts_address_alt,-- ������Z���i�J�i�j
      edideliwk.balance_accounts_tel          balance_accounts_tel,        -- ������TEL
      edideliwk.order_possible_date           order_possible_date,         -- �󒍉\��
      edideliwk.permission_possible_date      permission_possible_date,    -- ���e�\��
      edideliwk.forward_month                 forward_month,               -- ����N����
      edideliwk.payment_settlement_date       payment_settlement_date,     -- �x�����ϓ�
      edideliwk.handbill_start_date_active    handbill_start_date_active,  -- �`���V�J�n��
      edideliwk.billing_due_date              billing_due_date,            -- ��������
      edideliwk.shipping_time                 shipping_time,               -- �o�׎���
      edideliwk.delivery_schedule_time        delivery_schedule_time,      -- �[�i�\�莞��
      edideliwk.order_time                    order_time,                  -- ��������
      edideliwk.general_date_item1            general_date_item1,          -- �ėp���t���ڂP
      edideliwk.general_date_item2            general_date_item2,          -- �ėp���t���ڂQ
      edideliwk.general_date_item3            general_date_item3,          -- �ėp���t���ڂR
      edideliwk.general_date_item4            general_date_item4,          -- �ėp���t���ڂS
      edideliwk.general_date_item5            general_date_item5,          -- �ėp���t���ڂT
      edideliwk.arrival_shipping_class        arrival_shipping_class,      -- ���o�׋敪
      edideliwk.vendor_class                  vendor_class,                -- �����敪
      edideliwk.invoice_detailed_class        invoice_detailed_class,      -- �`�[����敪
      edideliwk.unit_price_use_class          unit_price_use_class,        -- �P���g�p�敪
      edideliwk.sub_distribution_center_code  sub_distribution_center_code,-- �T�u�����Z���^�[�R�[�h
      edideliwk.sub_distribution_center_name  sub_distribution_center_name,-- �T�u�����Z���^�[�R�[�h��
      edideliwk.center_delivery_method        center_delivery_method,      -- �Z���^�[�[�i���@
      edideliwk.center_use_class              center_use_class,            -- �Z���^�[���p�敪
      edideliwk.center_whse_class             center_whse_class,           -- �Z���^�[�q�ɋ敪
      edideliwk.center_area_class             center_area_class,           -- �Z���^�[�n��敪
      edideliwk.center_arrival_class          center_arrival_class,        -- �Z���^�[���׋敪
      edideliwk.depot_class                   depot_class,                 -- �f�|�敪
      edideliwk.tcdc_class                    tcdc_class,                  -- TCDC�敪
      edideliwk.upc_flag                      upc_flag,                    -- UPC�t���O
      edideliwk.simultaneously_class          simultaneously_class,        -- ��ċ敪
      edideliwk.business_id                   business_id,                 -- �Ɩ�ID
      edideliwk.whse_directly_class           whse_directly_class,         -- �q���敪
      edideliwk.premium_rebate_class          premium_rebate_class,        -- �i�i���ߋ敪
      edideliwk.item_type                     item_type,                   -- ���ڎ��
      edideliwk.cloth_house_food_class        cloth_house_food_class,      -- �߉ƐH�敪
      edideliwk.mix_class                     mix_class,                   -- ���݋敪
      edideliwk.stk_class                     stk_class,                   -- �݌ɋ敪
      edideliwk.last_modify_site_class        last_modify_site_class,      -- �ŏI�C���ꏊ�敪
      edideliwk.report_class                  report_class,                -- ���[�敪
      edideliwk.addition_plan_class           addition_plan_class,         -- �ǉ��E�v��敪
      edideliwk.registration_class            registration_class,          -- �o�^�敪
      edideliwk.specific_class                specific_class,              -- ����敪
      edideliwk.dealings_class                dealings_class,              -- ����敪
      edideliwk.order_class                   order_class,                 -- �����敪
      edideliwk.sum_line_class                sum_line_class,              -- �W�v���׋敪
      edideliwk.shipping_guidance_class       shipping_guidance_class,     -- �o�׈ē��ȊO�敪
      edideliwk.shipping_class                shipping_class,              -- �o�׋敪
      edideliwk.product_code_use_class        product_code_use_class,      -- ���i�R�[�h�g�p�敪
      edideliwk.cargo_item_class              cargo_item_class,            -- �ϑ��i�敪
      edideliwk.ta_class                      ta_class,                    -- T/A�敪
      edideliwk.plan_code                     plan_code,                   -- ���R�[�h
      edideliwk.category_code                 category_code,               -- �J�e�S���[�R�[�h
      edideliwk.category_class                category_class,              -- �J�e�S���[�敪
      edideliwk.carrier_means                 carrier_means,               -- �^����i
      edideliwk.counter_code                  counter_code,                -- ����R�[�h
      edideliwk.move_sign                     move_sign,                   -- �ړ��T�C��
      edideliwk.eos_handwriting_class         eos_handwriting_class,       -- EOS�E�菑�敪
      edideliwk.delivery_to_section_code      delivery_to_section_code,    -- �[�i��ۃR�[�h
      edideliwk.invoice_detailed              invoice_detailed,            -- �`�[����
      edideliwk.attach_qty                    attach_qty,                  -- �Y�t��
      edideliwk.other_party_floor             other_party_floor,           -- �t���A
      edideliwk.text_no                       text_no,                     -- TEXT_NO
      edideliwk.in_store_code                 in_store_code,               -- �C���X�g�A�R�[�h
      edideliwk.tag_data                      tag_data,                    -- �^�O
      edideliwk.competition_code              competition_code,            -- ����
      edideliwk.billing_chair                 billing_chair,               -- ��������
      edideliwk.chain_store_code              chain_store_code,            -- �`�F�[���X�g�A�[�R�[�h
      edideliwk.chain_store_short_name        chain_store_short_name,      -- �`�F�[���X�g�A�[�R�[�h��������
      edideliwk.direct_delivery_rcpt_fee      direct_delivery_rcpt_fee,    -- ���z���^���旿
      edideliwk.bill_info                     bill_info,                   -- ��`���
      edideliwk.description                   description,                 -- �E�v
      edideliwk.interior_code                 interior_code,               -- �����R�[�h
      edideliwk.order_info_delivery_category  order_info_delivery_category,-- �������@�[�i�J�e�S���[
      edideliwk.purchase_type                 purchase_type,               -- �d���`��
      edideliwk.delivery_to_name_alt          delivery_to_name_alt,        -- �[�i�ꏊ���i�J�i�j
      edideliwk.shop_opened_site              shop_opened_site,            -- �X�o�ꏊ
      edideliwk.counter_name                  counter_name,                -- ���ꖼ
      edideliwk.extension_number              extension_number,            -- �����ԍ�
      edideliwk.charge_name                   charge_name,                 -- �S���Җ�
      edideliwk.price_tag                     price_tag,                   -- �l�D
      edideliwk.tax_type                      tax_type,                    -- �Ŏ�
      edideliwk.consumption_tax_class         consumption_tax_class,       -- ����ŋ敪
      edideliwk.brand_class                   brand_class,                 -- BR
      edideliwk.id_code                       id_code,                     -- ID�R�[�h
      edideliwk.department_code               department_code,             -- �S�ݓX�R�[�h
      edideliwk.department_name               department_name,             -- �S�ݓX��
      edideliwk.item_type_number              item_type_number,            -- �i�ʔԍ�
      edideliwk.description_department        description_department,      -- �E�v�i�S�ݓX�j
      edideliwk.price_tag_method              price_tag_method,            -- �l�D���@
      edideliwk.reason_column                 reason_column,               -- ���R��
      edideliwk.a_column_header               a_column_header,             -- A���w�b�_
      edideliwk.d_column_header               d_column_header,             -- D���w�b�_
      edideliwk.brand_code                    brand_code,                  -- �u�����h�R�[�h
      edideliwk.line_code                     line_code,                   -- ���C���R�[�h
      edideliwk.class_code                    class_code,                  -- �N���X�R�[�h
      edideliwk.a1_column                     a1_column,                   -- �`�|�P��
      edideliwk.b1_column                     b1_column,                   -- �a�|�P��
      edideliwk.c1_column                     c1_column,                   -- �b�|�P��
      edideliwk.d1_column                     d1_column,                   -- �c�|�P��
      edideliwk.e1_column                     e1_column,                   -- �d�|�P��
      edideliwk.a2_column                     a2_column,                   -- �`�|�Q��
      edideliwk.b2_column                     b2_column,                   -- �a�|�Q��
      edideliwk.c2_column                     c2_column,                   -- �b�|�Q��
      edideliwk.d2_column                     d2_column,                   -- �c�|�Q��
      edideliwk.e2_column                     e2_column,                   -- �d�|�Q��
      edideliwk.a3_column                     a3_column,                   -- �`�|�R��
      edideliwk.b3_column                     b3_column,                   -- �a�|�R��
      edideliwk.c3_column                     c3_column,                   -- �b�|�R��
      edideliwk.d3_column                     d3_column,                   -- �c�|�R��
      edideliwk.e3_column                     e3_column,                   -- �d�|�R��
      edideliwk.f1_column                     f1_column,                   -- �e�|�P��
      edideliwk.g1_column                     g1_column,                   -- �f�|�P��
      edideliwk.h1_column                     h1_column,                   -- �g�|�P��
      edideliwk.i1_column                     i1_column,                   -- �h�|�P��
      edideliwk.j1_column                     j1_column,                   -- �i�|�P��
      edideliwk.k1_column                     k1_column,                   -- �j�|�P��
      edideliwk.l1_column                     l1_column,                   -- �k�|�P��
      edideliwk.f2_column                     f2_column,                   -- �e�|�Q��
      edideliwk.g2_column                     g2_column,                   -- �f�|�Q��
      edideliwk.h2_column                     h2_column,                   -- �g�|�Q��
      edideliwk.i2_column                     i2_column,                   -- �h�|�Q��
      edideliwk.j2_column                     j2_column,                   -- �i�|�Q��
      edideliwk.k2_column                     k2_column,                   -- �j�|�Q��
      edideliwk.l2_column                     l2_column,                   -- �k�|�Q��
      edideliwk.f3_column                     f3_column,                   -- �e�|�R��
      edideliwk.g3_column                     g3_column,                   -- �f�|�R��
      edideliwk.h3_column                     h3_column,                   -- �g�|�R��
      edideliwk.i3_column                     i3_column,                   -- �h�|�R��
      edideliwk.j3_column                     j3_column,                   -- �i�|�R��
      edideliwk.k3_column                     k3_column,                   -- �j�|�R��
      edideliwk.l3_column                     l3_column,                   -- �k�|�R��
      edideliwk.chain_peculiar_area_header    chain_peculiar_area_header,  -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
      edideliwk.order_connection_number       order_connection_number,     -- �󒍊֘A�ԍ��i���j
      edideliwk.line_no                       line_no,                     -- �s����
      edideliwk.stockout_class                stockout_class,              -- ���i�敪
      edideliwk.stockout_reason               stockout_reason,             -- ���i���R
      edideliwk.product_code_itouen           product_code_itouen,         -- ���i�R�[�h�i�ɓ����j
      edideliwk.product_code1                 product_code1,               -- ���i�R�[�h�P
      edideliwk.product_code2                 product_code2,               -- ���i�R�[�h�Q
      edideliwk.jan_code                      jan_code,                    -- JAN�R�[�h
      edideliwk.itf_code                      itf_code,                    -- ITF�R�[�h
      edideliwk.extension_itf_code            extension_itf_code,          -- ����ITF�R�[�h
      edideliwk.case_product_code             case_product_code,           -- �P�[�X���i�R�[�h
      edideliwk.ball_product_code             ball_product_code,           -- �{�[�����i�R�[�h
      edideliwk.product_code_item_type        product_code_item_type,      -- ���i�R�[�h�i��
      edideliwk.prod_class                    prod_class,                  -- ���i�敪
      edideliwk.product_name                  product_name,                -- ���i���i�����j
      edideliwk.product_name1_alt             product_name1_alt,           -- ���i���P�i�J�i�j
      edideliwk.product_name2_alt             product_name2_alt,           -- ���i���Q�i�J�i�j
      edideliwk.item_standard1                item_standard1,              -- �K�i�P
      edideliwk.item_standard2                item_standard2,              -- �K�i�Q
      edideliwk.qty_in_case                   qty_in_case,                 -- ����
      edideliwk.num_of_cases                  num_of_cases,                -- �P�[�X����
      edideliwk.num_of_ball                   num_of_ball,                 -- �{�[������
      edideliwk.item_color                    item_color,                  -- �F
      edideliwk.item_size                     item_size,                   -- �T�C�Y
      edideliwk.expiration_date               expiration_date,             -- �ܖ�������
      edideliwk.product_date                  product_date,                -- ������
      edideliwk.order_uom_qty                 order_uom_qty,               -- �����P�ʐ�
      edideliwk.shipping_uom_qty              shipping_uom_qty,            -- �o�גP�ʐ�
      edideliwk.packing_uom_qty               packing_uom_qty,             -- ����P�ʐ�
      edideliwk.deal_code                     deal_code,                   -- ����
      edideliwk.deal_class                    deal_class,                  -- �����敪
      edideliwk.collation_code                collation_code,              -- �ƍ�
      edideliwk.uom_code                      uom_code,                    -- �P��
      edideliwk.unit_price_class              unit_price_class,            -- �P���敪
      edideliwk.parent_packing_number         parent_packing_number,       -- �e����ԍ�
      edideliwk.packing_number                packing_number,              -- ����ԍ�
      edideliwk.product_group_code            product_group_code,          -- ���i�Q�R�[�h
      edideliwk.case_dismantle_flag           case_dismantle_flag,         -- �P�[�X��̕s�t���O
      edideliwk.case_class                    case_class,                  -- �P�[�X�敪
      edideliwk.indv_order_qty                indv_order_qty,              -- �������ʁi�o���j
      edideliwk.case_order_qty                case_order_qty,              -- �������ʁi�P�[�X�j
      edideliwk.ball_order_qty                ball_order_qty,              -- �������ʁi�{�[���j
      edideliwk.sum_order_qty                 sum_order_qty,               -- �������ʁi���v�A�o���j
      edideliwk.indv_shipping_qty             indv_shipping_qty,           -- �o�א��ʁi�o���j
      edideliwk.case_shipping_qty             case_shipping_qty,           -- �o�א��ʁi�P�[�X�j
      edideliwk.ball_shipping_qty             ball_shipping_qty,           -- �o�א��ʁi�{�[���j
      edideliwk.pallet_shipping_qty           pallet_shipping_qty,         -- �o�א��ʁi�p���b�g�j
      edideliwk.sum_shipping_qty              sum_shipping_qty,            -- �o�א��ʁi���v�A�o���j
      edideliwk.indv_stockout_qty             indv_stockout_qty,           -- ���i���ʁi�o���j
      edideliwk.case_stockout_qty             case_stockout_qty,           -- ���i���ʁi�P�[�X�j
      edideliwk.ball_stockout_qty             ball_stockout_qty,           -- ���i���ʁi�{�[���j
      edideliwk.sum_stockout_qty              sum_stockout_qty,            -- ���i���ʁi���v�A�o���j
      edideliwk.case_qty                      case_qty,                    -- �P�[�X����
      edideliwk.fold_container_indv_qty       fold_container_indv_qty,     -- �I���R���i�o���j����
      edideliwk.order_unit_price              order_unit_price,            -- ���P���i�����j
      edideliwk.shipping_unit_price           shipping_unit_price,         -- ���P���i�o�ׁj
      edideliwk.order_cost_amt                order_cost_amt,              -- �������z�i�����j
-- ***************************** 2009/07/21 1.5 N.Maeda    MOD  START ***************************** --
      TRUNC( edideliwk.shipping_cost_amt )    shipping_cost_amt,           -- �������z�i�o�ׁj
      TRUNC( edideliwk.stockout_cost_amt )    stockout_cost_amt,           -- �������z�i���i�j
--      edideliwk.shipping_cost_amt             shipping_cost_amt,           -- �������z�i�o�ׁj
--      edideliwk.stockout_cost_amt             stockout_cost_amt,           -- �������z�i���i�j
-- ***************************** 2009/07/21 1.5 N.Maeda    MOD   END  ***************************** --
      edideliwk.selling_price                 selling_price,               -- ���P��
      edideliwk.order_price_amt               order_price_amt,             -- �������z�i�����j
      edideliwk.shipping_price_amt            shipping_price_amt,          -- �������z�i�o�ׁj
      edideliwk.stockout_price_amt            stockout_price_amt,          -- �������z�i���i�j
      edideliwk.a_column_department           a_column_department,         -- A���i�S�ݓX�j
      edideliwk.d_column_department           d_column_department,         -- D���i�S�ݓX�j
      edideliwk.standard_info_depth           standard_info_depth,         -- �K�i���E���s��
      edideliwk.standard_info_height          standard_info_height,        -- �K�i���E����
      edideliwk.standard_info_width           standard_info_width,         -- �K�i���E��
      edideliwk.standard_info_weight          standard_info_weight,        -- �K�i���E�d��
      edideliwk.general_succeeded_item1       general_succeeded_item1,     -- �ėp���p�����ڂP
      edideliwk.general_succeeded_item2       general_succeeded_item2,     -- �ėp���p�����ڂQ
      edideliwk.general_succeeded_item3       general_succeeded_item3,     -- �ėp���p�����ڂR
      edideliwk.general_succeeded_item4       general_succeeded_item4,     -- �ėp���p�����ڂS
      edideliwk.general_succeeded_item5       general_succeeded_item5,     -- �ėp���p�����ڂT
      edideliwk.general_succeeded_item6       general_succeeded_item6,     -- �ėp���p�����ڂU
      edideliwk.general_succeeded_item7       general_succeeded_item7,     -- �ėp���p�����ڂV
      edideliwk.general_succeeded_item8       general_succeeded_item8,     -- �ėp���p�����ڂW
      edideliwk.general_succeeded_item9       general_succeeded_item9,     -- �ėp���p�����ڂX
      edideliwk.general_succeeded_item10      general_succeeded_item10,    -- �ėp���p�����ڂP�O
      edideliwk.general_add_item1             general_add_item1,           -- �ėp�t�����ڂP
      edideliwk.general_add_item2             general_add_item2,           -- �ėp�t�����ڂQ
      edideliwk.general_add_item3             general_add_item3,           -- �ėp�t�����ڂR
      edideliwk.general_add_item4             general_add_item4,           -- �ėp�t�����ڂS
      edideliwk.general_add_item5             general_add_item5,           -- �ėp�t�����ڂT
      edideliwk.general_add_item6             general_add_item6,           -- �ėp�t�����ڂU
      edideliwk.general_add_item7             general_add_item7,           -- �ėp�t�����ڂV
      edideliwk.general_add_item8             general_add_item8,           -- �ėp�t�����ڂW
      edideliwk.general_add_item9             general_add_item9,           -- �ėp�t�����ڂX
      edideliwk.general_add_item10            general_add_item10,          -- �ėp�t�����ڂP�O
      edideliwk.chain_peculiar_area_line      chain_peculiar_area_line,    -- �`�F�[���X�ŗL�G���A�i���ׁj
      edideliwk.invoice_indv_order_qty        invoice_indv_order_qty,      -- (�`�[�v�j�������ʁi�o���j
      edideliwk.invoice_case_order_qty        invoice_case_order_qty,      -- (�`�[�v�j�������ʁi�P�[�X�j
      edideliwk.invoice_ball_order_qty        invoice_ball_order_qty,      -- (�`�[�v�j�������ʁi�{�[���j
      edideliwk.invoice_sum_order_qty         invoice_sum_order_qty,       -- (�`�[�v�j�������ʁi���v�A�o���j
      edideliwk.invoice_indv_shipping_qty     invoice_indv_shipping_qty,   -- (�`�[�v�j�o�א��ʁi�o���j
      edideliwk.invoice_case_shipping_qty     invoice_case_shipping_qty,   -- (�`�[�v�j�o�א��ʁi�P�[�X�j
      edideliwk.invoice_ball_shipping_qty     invoice_ball_shipping_qty,   -- (�`�[�v�j�o�א��ʁi�{�[���j
      edideliwk.invoice_pallet_shipping_qty   invoice_pallet_shipping_qty, -- (�`�[�v�j�o�א��ʁi�p���b�g�j
      edideliwk.invoice_sum_shipping_qty      invoice_sum_shipping_qty,    -- (�`�[�v�j�o�א��ʁi���v�A�o���j
      edideliwk.invoice_indv_stockout_qty     invoice_indv_stockout_qty,   -- (�`�[�v�j���i���ʁi�o���j
      edideliwk.invoice_case_stockout_qty     invoice_case_stockout_qty,   -- (�`�[�v�j���i���ʁi�P�[�X�j
      edideliwk.invoice_ball_stockout_qty     invoice_ball_stockout_qty,   -- (�`�[�v�j���i���ʁi�{�[���j
      edideliwk.invoice_sum_stockout_qty      invoice_sum_stockout_qty,    -- (�`�[�v�j���i���ʁi���v�A�o���j
      edideliwk.invoice_case_qty              invoice_case_qty,            -- (�`�[�v�j�P�[�X����
      edideliwk.invoice_fold_container_qty    invoice_fold_container_qty,  -- (�`�[�v�j�I���R���i�o���j����
      edideliwk.invoice_order_cost_amt        invoice_order_cost_amt,      -- (�`�[�v�j�������z�i�����j
      edideliwk.invoice_shipping_cost_amt     invoice_shipping_cost_amt,   -- (�`�[�v�j�������z�i�o�ׁj
      edideliwk.invoice_stockout_cost_amt     invoice_stockout_cost_amt,   -- (�`�[�v�j�������z�i���i�j
      edideliwk.invoice_order_price_amt       invoice_order_price_amt,     -- (�`�[�v�j�������z�i�����j
      edideliwk.invoice_shipping_price_amt    invoice_shipping_price_amt,  -- (�`�[�v�j�������z�i�o�ׁj
      edideliwk.invoice_stockout_price_amt    invoice_stockout_price_amt,  -- (�`�[�v�j�������z�i���i�j
      edideliwk.total_indv_order_qty          total_indv_order_qty,        -- (�����v�j�������ʁi�o���j
      edideliwk.total_case_order_qty          total_case_order_qty,        -- (�����v�j�������ʁi�P�[�X�j
      edideliwk.total_ball_order_qty          total_ball_order_qty,        -- (�����v�j�������ʁi�{�[���j
      edideliwk.total_sum_order_qty           total_sum_order_qty,         -- (�����v�j�������ʁi���v�A�o���j
      edideliwk.total_indv_shipping_qty       total_indv_shipping_qty,     -- (�����v�j�o�א��ʁi�o���j
      edideliwk.total_case_shipping_qty       total_case_shipping_qty,     -- (�����v�j�o�א��ʁi�P�[�X�j
      edideliwk.total_ball_shipping_qty       total_ball_shipping_qty,     -- (�����v�j�o�א��ʁi�{�[���j
      edideliwk.total_pallet_shipping_qty     total_pallet_shipping_qty,   -- (�����v�j�o�א��ʁi�p���b�g�j
      edideliwk.total_sum_shipping_qty        total_sum_shipping_qty,      -- (�����v�j�o�א��ʁi���v�A�o���j
      edideliwk.total_indv_stockout_qty       total_indv_stockout_qty,     -- (�����v�j���i���ʁi�o���j
      edideliwk.total_case_stockout_qty       total_case_stockout_qty,     -- (�����v�j���i���ʁi�P�[�X�j
      edideliwk.total_ball_stockout_qty       total_ball_stockout_qty,     -- (�����v�j���i���ʁi�{�[���j
      edideliwk.total_sum_stockout_qty        total_sum_stockout_qty,      -- (�����v�j���i���ʁi���v�A�o���j
      edideliwk.total_case_qty                total_case_qty,              -- (�����v�j�P�[�X����
      edideliwk.total_fold_container_qty      total_fold_container_qty,    -- (�����v�j�I���R���i�o���j����
      edideliwk.total_order_cost_amt          total_order_cost_amt,        -- (�����v�j�������z�i�����j
      edideliwk.total_shipping_cost_amt       total_shipping_cost_amt,     -- (�����v�j�������z�i�o�ׁj
      edideliwk.total_stockout_cost_amt       total_stockout_cost_amt,     -- (�����v�j�������z�i���i�j
      edideliwk.total_order_price_amt         total_order_price_amt,       -- (�����v�j�������z�i�����j
      edideliwk.total_shipping_price_amt      total_shipping_price_amt,    -- (�����v�j�������z�i�o�ׁj
      edideliwk.total_stockout_price_amt      total_stockout_price_amt,    -- (�����v�j�������z�i���i�j
      edideliwk.total_line_qty                total_line_qty,              -- �g�[�^���s��
      edideliwk.total_invoice_qty             total_invoice_qty,           -- �g�[�^���`�[����
      edideliwk.chain_peculiar_area_footer    chain_peculiar_area_footer,  -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
      edideliwk.err_status                    err_status,                  -- �X�e�[�^�X
/* 2011/07/26 Ver1.9 Mod Start */
--      edideliwk.if_file_name                  if_file_name                 -- �C���^�t�F�[�X�t�@�C����
      edideliwk.if_file_name                  if_file_name,                -- �C���^�t�F�[�X�t�@�C����
/* 2011/07/26 Ver1.9 Mod End   */
/* 2011/07/26 Ver1.9 Add Start */
      edideliwk.bms_header_data               bms_header_data,             -- ���ʂa�l�r�w�b�_�f�[�^
      edideliwk.bms_line_data                 bms_line_data                -- ���ʂa�l�r���׃f�[�^
/* 2011/07/26 Ver1.9 Add End   */
    FROM    xxcos_edi_delivery_work    edideliwk                           -- EDI�[�i�ԕi��񃏁[�N�e�[�u��
    WHERE   edideliwk.if_file_name     = lv_cur_param4          -- �C���^�t�F�[�X�t�@�C����
      AND   edideliwk.err_status       =    lv_cur_param1                  -- �X�e�[�^�X
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      AND   edideliwk.data_type_code   = lv_cur_param2          -- �f�[�^��R�[�h
      AND   edideliwk.data_type_code   IN ( cv_data_type_32, cv_data_type_33 )  -- �f�[�^��R�[�h
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
      AND (( lv_cur_param3 IS NOT NULL
        AND   edideliwk.edi_chain_code   =    lv_cur_param3 )              -- EDI�`�F�[���X�R�[�h
        OR ( lv_cur_param3 IS NULL ))
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--    ORDER BY edideliwk.invoice_number,edideliwk.line_no                    -- �\�[�g�����i�`�[�ԍ��A�sNO�j
    ORDER BY edideliwk.shop_code,                                          -- �\�[�g�����i�X�R�[�h�j
             edideliwk.invoice_number,                                     -- �\�[�g�����i�`�[�ԍ��j
             edideliwk.line_no                                             -- �\�[�g�����i�sNO�j
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
    FOR UPDATE OF
            edideliwk.delivery_return_work_id NOWAIT;
    -- *** ���[�J���E���R�[�h ***
--
  --* -------------------------------------------------------------------------------------------
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
    --==============================================================
    -- ���s�敪�̃`�F�b�N
    --==============================================================
    --
    IF  ( iv_run_class  =  gv_run_class_name1 )  THEN     -- ���s�敪�F�u�V�K�v
      lv_cur_param1 := gv_run_class_name1;       -- ���o�J�[�\���p���n���p�����^�P
-- ******************** 2009/06/29 Var.1.5 T.Tominaga DEL START  ******************************************
--      lv_cur_param2 := gv_run_data_type_code;    -- ���o�J�[�\���p���n���p�����^�Q
-- ******************** 2009/06/29 Var.1.5 T.Tominaga DEL END    ******************************************
    ELSIF  ( iv_run_class  =  gv_run_class_name2 )  THEN   -- ���s�敪�F�u�Ď��{�v
      lv_cur_param1 := gv_run_class_name2;       -- ���o�J�[�\���p���n���p�����^�P
-- ******************** 2009/06/29 Var.1.5 T.Tominaga DEL START  ******************************************
--      lv_cur_param2 := gv_run_data_type_code;    -- ���o�J�[�\���p���n���p�����^�Q
-- ******************** 2009/06/29 Var.1.5 T.Tominaga DEL END    ******************************************
    END IF;
    --
    lv_cur_param3 := iv_edi_chain_code;          -- ���o�J�[�\���p���n���p�����^�R
    lv_cur_param4 := iv_file_name;               -- ���o�J�[�\���p���n���p�����^�S
--
    --==============================================================
    -- EDI�[�i�ԕi��񃏁[�N�e�[�u���f�[�^�擾
    --==============================================================
    BEGIN
      -- �J�[�\��OPEN
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD START  ******************************************
--      OPEN  get_edideli_work_data_cur( lv_cur_param1, lv_cur_param2, lv_cur_param3, lv_cur_param4 );
      OPEN  get_edideli_work_data_cur( lv_cur_param1, lv_cur_param3, lv_cur_param4 );
-- ******************** 2009/06/29 Var.1.5 T.Tominaga MOD END    ******************************************
      --
      -- �o���N�t�F�b�`
      FETCH get_edideli_work_data_cur BULK COLLECT INTO gt_edideli_work_data;
      -- ���o�����Z�b�g
      gn_target_cnt := get_edideli_work_data_cur%ROWCOUNT;
--****************************** 2009/06/04 1.4 T.Kitajima DEL START ******************************--
--      -- ���팏�� = ���o����
--      gn_normal_cnt := gn_target_cnt;
--****************************** 2009/06/04 1.4 T.Kitajima DEL  END  ******************************--
      --
      -- �J�[�\��CLOSE
      CLOSE get_edideli_work_data_cur;
    EXCEPTION
      -- ���b�N�G���[
      WHEN lock_expt THEN
        IF ( get_edideli_work_data_cur%ISOPEN ) THEN
          CLOSE get_edideli_work_data_cur;
        END IF;
        -- EDI�[�i�ԕi��񃏁[�N�e�[�u��
        gv_tkn_edi_deli_work :=  xxccp_common_pkg.get_msg(
                             iv_application        =>  cv_application,
                             iv_name               =>  cv_msg_edi_deli_work
                             );
        lv_errmsg            :=  xxccp_common_pkg.get_msg(
                             iv_application        =>  cv_application,
                             iv_name               =>  gv_msg_lock,
                             iv_token_name1        =>  cv_tkn_table_name,
                             iv_token_value1       =>  gv_tkn_edi_deli_work
                             );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
      -- ���̑��̒��o�G���[
      WHEN OTHERS THEN
        IF ( get_edideli_work_data_cur%ISOPEN ) THEN
          CLOSE get_edideli_work_data_cur;
        END IF;
        lv_errbuf  := SQLERRM;
        RAISE global_data_sel_expt;
    END;
    --
    -- �Ώۃf�[�^����
    IF  ( gn_target_cnt = 0 ) THEN
      RAISE global_nodata_expt;
    END IF;
    --
    -- ���[�v�J�n�F
    <<xxcos_in_edi_headers_set>>
    FOR  ln_no  IN  1..gn_target_cnt  LOOP
-- 2009/06/15 Ver.1.5 M.Sano Add Start
      gt_err_edideli_work_data(ln_no).err_status1 := cv_status_normal;
      gt_err_edideli_work_data(ln_no).err_status2 := cv_status_normal;
-- 2009/06/15 Ver.1.5 M.Sano Add End
      --==============================================================
      -- * Procedure Name   : data_check
      -- * Description      : �f�[�^�Ó����`�F�b�N(A-3)
      --==============================================================
      data_check(
        ln_no,
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      --==============================================================
      -- �x�����̏ꍇ
      --==============================================================
      IF ( lv_retcode = cv_status_warn ) THEN
        --�X�e�[�^�X(error1)
        IF  ( gt_err_edideli_work_data(ln_no).err_status1 = cv_status_warn ) THEN
          --==============================================================
          -- �G���[�o��
          --==============================================================
          FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT,
               buff   => gt_err_edideli_work_data(ln_no).errmsg1 --���[�U�[�E�G���[���b�Z�[�W
          );
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
          gn_msg_cnt := gn_msg_cnt + 1;
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
        END IF;
        --�X�e�[�^�X(error2)
        IF  ( gt_err_edideli_work_data(ln_no).err_status2 = cv_status_warn ) THEN
          --==============================================================
          -- �G���[�o��
          --==============================================================
          FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT,
               buff   => gt_err_edideli_work_data(ln_no).errmsg2 --���[�U�[�E�G���[���b�Z�[�W
          );
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
          gn_msg_cnt := gn_msg_cnt + 1;
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
        END IF;
      --
      END IF;
    --
    END LOOP  xxcos_in_edi_headers_set;
    --* -------------------------------------------------------------------------------------------
    --  �K�{�`�F�b�N�A�ڋq���`�F�b�N�łP���ł��G���[���L�����ꍇ
    --* -------------------------------------------------------------------------------------------
    IF  ( gv_status_work_err = cv_status_error ) THEN
      -- **********************************************************************************
      -- * Procedure Name   : xxcos_in_edi_deli_wk_update
      -- * Description      : EDI�[�i�ԕi��񃏁[�N�e�[�u���ւ̍X�V(A-6)
      -- ***********************************************************************************
      xxcos_in_edi_deli_wk_update(
        iv_file_name,    --   �C���^�t�F�[�X�t�@�C����
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    --* -------------------------------------------------------------------------------------------
    --  �K�{�`�F�b�N�A�ڋq���`�F�b�N�łP�����G���[�����������ꍇ
    --* -------------------------------------------------------------------------------------------
    ELSE
      -- **********************************************************************************
      -- * Procedure Name   : xxcos_in_edi_headers_insert
      -- * Description      : EDI�w�b�_���e�[�u���ւ̃f�[�^�}��(A-7)
      -- ***********************************************************************************
      xxcos_in_edi_headers_insert(
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      -- **********************************************************************************
      -- * Procedure Name   : xxcos_in_edi_lines_insert
      -- * Description      : EDI���׏��e�[�u���ւ̃f�[�^�}��(A-8)
      -- ***********************************************************************************
      xxcos_in_edi_lines_insert(
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      -- **********************************************************************************
      -- * Procedure Name   : xxcos_in_edi_deli_work_delete
      -- * Description      : EDI�[�i�ԕi��񃏁[�N�e�[�u���f�[�^�폜(A-9)
      -- ***********************************************************************************
      xxcos_in_edi_deli_work_delete(
        iv_file_name,       -- �C���^�t�F�[�X�t�@�C����
        iv_run_class,       -- ���s�敪�F�u�V�K�v�u�Ď��s�v
        iv_edi_chain_code,  -- EDI�`�F�[���X�R�[�h
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- �Ώۃf�[�^�Ȃ�
    WHEN global_nodata_expt THEN
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_nodata_err
                           );
      --���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      --����I���Ƃ���
      ov_retcode := cv_status_normal;
    -- �f�[�^���o�G���[
    WHEN global_data_sel_expt THEN
      -- EDI�[�i�ԕi��񃏁[�N�e�[�u��
      gv_tkn_edi_deli_work :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  cv_msg_edi_deli_work
                           );
      lv_errmsg            :=  xxccp_common_pkg.get_msg(
                           iv_application        =>  cv_application,
                           iv_name               =>  gv_msg_nodata,
                           iv_token_name1        =>  cv_tkn_table_name1,
                           iv_token_name2        =>  cv_tkn_key_data,
                           iv_token_value1       =>  gv_tkn_edi_deli_work,
                           iv_token_value2       =>  iv_file_name
                           );
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
--#####################################  �Œ蕔 END   ##########################################
--
  END sel_in_edi_delivery_work;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name      IN VARCHAR2,     --   �C���^�t�F�[�X�t�@�C����
    iv_run_class      IN VARCHAR2,     --   ���s�敪�F�u�V�K�v�u�Ď��s�v
    iv_edi_chain_code IN VARCHAR2,     --   EDI�`�F�[���X�R�[�h
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- <�J�[�\����>���R�[�h�^
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
--****************************** 2009/06/04 1.4 T.Kitajima ADD START ******************************--
    gn_msg_cnt    := 0;
--****************************** 2009/06/04 1.4 T.Kitajima ADD  END  ******************************--
--
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --==============================================================
    -- �v���O������������(A-0) (�R���J�����g�v���O�������͍��ڂ��o��)
    --==============================================================
    -- �e�[�u����`����
    -- ���s�敪�F�u�V�K�v
    gv_run_class_name01  :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  cv_msg_class_name1
                         );
    --* -------------------------------------------------------------
    --== ���b�N�A�b�v�}�X�^�f�[�^���o
    --* -------------------------------------------------------------
    SELECT  xlvv.lookup_code        -- �R�[�h
      INTO  gv_run_class_name1
      FROM  xxcos_lookup_values_v        xlvv        -- ���b�N�A�b�v�}�X�^
     WHERE  xlvv.lookup_type  = cv_lookup_type1 -- ���b�N�A�b�v.�^�C�v
       AND  xlvv.meaning      = gv_run_class_name01
       AND (( xlvv.start_date_active IS NULL )
       OR   ( xlvv.start_date_active <= cd_process_date ))
       AND (( xlvv.end_date_active   IS NULL )
       OR   ( xlvv.end_date_active   >= cd_process_date ))  -- �Ɩ����t��FROM-TO��
       AND  rownum = 1;
--
    -- ���s�敪�F�u�Ď��{�v
    gv_run_class_name02  :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  cv_msg_class_name2
                         );
    --* -------------------------------------------------------------
    --== ���b�N�A�b�v�}�X�^�f�[�^���o
    --* -------------------------------------------------------------
    SELECT  xlvv.lookup_code        -- �R�[�h
      INTO  gv_run_class_name2
      FROM  xxcos_lookup_values_v        xlvv        -- ���b�N�A�b�v�}�X�^
     WHERE  xlvv.lookup_type  = cv_lookup_type1 -- ���b�N�A�b�v.�^�C�v
       AND  xlvv.meaning      = gv_run_class_name02
       AND (( xlvv.start_date_active IS NULL )
       OR   ( xlvv.start_date_active <= cd_process_date ))
       AND (( xlvv.end_date_active   IS NULL )
       OR   ( xlvv.end_date_active   >= cd_process_date ))  -- �Ɩ����t��FROM-TO��
       AND  rownum = 1;
-- ******************** 2009/06/29 Var.1.5 T.Tominaga DEL START  ******************************************
--    --* --------------------------------------------------------------
--    -- �f�[�^��R�[�h�F�u�ԕi�m��v
--    --* --------------------------------------------------------------
--    gv_run_data_type_code :=  xxccp_common_pkg.get_msg(
--                         iv_application        =>  cv_application,
--                          iv_name               =>  cv_msg_data_type_code
--                          );
----
--    SELECT  xlvv.meaning
--      INTO  gv_run_data_type_code
--      FROM  xxcos_lookup_values_v  xlvv
--     WHERE  xlvv.lookup_type   = cv_lookup_type3 -- ���b�N�A�b�v.�^�C�v
--       AND  xlvv.description   = gv_run_data_type_code
--       AND (( xlvv.start_date_active IS NULL )
--       OR   ( xlvv.start_date_active <= cd_process_date ))
--       AND (( xlvv.end_date_active   IS NULL )
--       OR   ( xlvv.end_date_active   >= cd_process_date ))  -- �Ɩ����t��FROM-TO��
--       ;
-- ******************** 2009/06/29 Var.1.5 T.Tominaga DEL END    ******************************************
--
    --==============================================================
    -- �v���O������������(A-0) (�R���J�����g�v���O�������͍��ڂ��o��)
    --==============================================================
    -- �C���^�t�F�[�X�t�@�C����
    lv_errmsg      :=  xxccp_common_pkg.get_msg(
                   iv_application        =>  cv_application,
                   iv_name               =>  cv_msg_in_file_name1,
                   iv_token_name1        =>  cv_param1,
                   iv_token_value1       =>  iv_file_name
                   );
    --==============================================================
    -- ���̓p�����[�^�u �C���^�t�F�[�X�t�@�C�����v�o��
    --==============================================================
    FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT,
           buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
    );
    FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG,
           buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
    );
    --==============================================================
    -- �v���O������������(A-0) (�R���J�����g�v���O�������͍��ڂ��o��)
    --==============================================================
    IF  ( iv_run_class  =  gv_run_class_name1 )  THEN     -- ���s�敪�F�u�V�K�v
      lv_errmsg    :=  xxccp_common_pkg.get_msg(
                   iv_application        =>  cv_application,
                   iv_name               =>  gv_msg_param_out_msg1,
                   iv_token_name1        =>  cv_param1,
                   iv_token_value1       =>  iv_run_class
                   );
      --==============================================================
      -- ���̓p�����[�^�u���s�敪�v�uEDI�`�F�[���X�R�[�h�v�o��
      --==============================================================
      FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT,
             buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_errmsg
      );
      --==============================================================
    ELSIF  ( iv_run_class  =  gv_run_class_name2 )  THEN    -- ���s�敪�F�u�Ď��{�v
      lv_errmsg    :=  xxccp_common_pkg.get_msg(
                   iv_application        =>  cv_application,
                   iv_name               =>  gv_msg_param_out_msg2,
                   iv_token_name1        =>  cv_param1,
                   iv_token_name2        =>  cv_param2,
                   iv_token_value1       =>  iv_run_class,
                   iv_token_value2       =>  iv_edi_chain_code
                   );
      --==============================================================
      -- ���̓p�����[�^�u���s�敪�v�uEDI�`�F�[���X�R�[�h�v�o��
      --==============================================================
      FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT,
             buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_errmsg
      );
      --==============================================================
    ELSE
      lv_errmsg    :=  xxccp_common_pkg.get_msg(
                   iv_application        =>  cv_application,
                   iv_name               =>  gv_msg_param_out_msg2,
                   iv_token_name1        =>  cv_param1,
                   iv_token_name2        =>  cv_param2,
                   iv_token_value1       =>  iv_run_class,
                   iv_token_value2       =>  iv_edi_chain_code
                   );
      --==============================================================
      -- ���̓p�����[�^�u���s�敪�v�uEDI�`�F�[���X�R�[�h�v�o��
      --==============================================================
      FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT,
             buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_errmsg
      );
    END IF;
    --
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => NULL
    );
    --
    --==============================================================
    -- * Procedure Name   : init
    -- * Description      : ��������(A-1)
    -- *                  :  ���̓p�����[�^�Ó����`�F�b�N
    --==============================================================
    init(
      iv_file_name,       -- �C���^�t�F�[�X�t�@�C����
      iv_run_class,       -- ���s�敪�F�u�V�K�v�u�Ď��s�v
      iv_edi_chain_code,  -- EDI�`�F�[���X�R�[�h
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- * Procedure Name   : sel_in_edi_delivery_work(A-2)
    -- * Description      : EDI�[�i�ԕi��񃏁[�N�e�[�u���f�[�^���o (A-2)
    -- *                  :  SQL-LOADER�ɂ����EDI�[�i�ԕi��񃏁[�N�e�[�u���Ɏ�荞�܂ꂽ���R�[�h��
    -- *                     ���o���܂��B�����Ƀ��R�[�h���b�N���s���܂��B
    --==============================================================
    sel_in_edi_delivery_work(
      iv_file_name,       -- �C���^�t�F�[�X�t�@�C����
      iv_run_class,       -- ���s�敪�F�u�V�K�v�u�Ď��s�v
      iv_edi_chain_code,  -- EDI�`�F�[���X�R�[�h
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF  ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �X�e�[�^�X���G���[�ƂȂ�f�[�^���Ȃ��ꍇ
    --==============================================================
    IF ( gv_status_work_err <> cv_status_error ) THEN
      --==============================================================
      -- * Procedure Name   : xxcos_in_edi_head_line_delete
      -- * Description      : EDI�w�b�_���e�[�u���AEDI���׏��e�[�u���f�[�^�폜(A-10)
      --==============================================================
      xxcos_in_edi_head_line_delete(
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF  ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--****************************** 2009/06/03 1.4 T.Kitajima MOD START ******************************--
----****************************** 2009/05/28 1.4 T.Kitajima MOD START ******************************--
----    --==============================================================
----    -- �R���J�����g�X�e�[�^�X�A�����̐ݒ�
----    --==============================================================
----    IF ( gv_status_work_err = cv_status_error ) THEN
----     ov_retcode    := cv_status_error;  --�X�e�[�^�X�F�G���[
----      gn_warn_cnt   := 0;                --�x�������F0
----     gn_normal_cnt := 0;                --���팏���F0
----      gn_error_cnt  := 1;
----    ELSIF ( gv_status_work_warn =  cv_status_warn ) THEN
----      ov_retcode    := cv_status_warn;   --�X�e�[�^�X�F�x��
----    END IF;
--      IF ( gv_status_work_err = cv_status_error ) THEN
--        ov_retcode    := cv_status_error;  --�X�e�[�^�X�F�G���[
--      ELSIF ( gn_warn_cnt != 0 ) THEN
--        ov_retcode    := cv_status_warn;   --�X�e�[�^�X�F�x��
--      END IF;
----****************************** 2009/05/28 1.3 T.Kitajima MOD  END  ******************************--
    IF    ( gv_status_work_err  =  cv_status_error ) THEN
      ov_retcode    := cv_status_error;  --�X�e�[�^�X�F�G���[
    ELSIF ( gv_status_work_warn =  cv_status_warn ) THEN
      ov_retcode    := cv_status_error;  --�X�e�[�^�X�F�G���[
      ov_retcode    := cv_status_warn;   --�X�e�[�^�X�F�x��
    END IF;
--****************************** 2009/06/03 1.4 T.Kitajima MOD  END  ******************************--
--
  EXCEPTION
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
    errbuf        OUT    VARCHAR2,     --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,     --   �G���[�R�[�h     #�Œ�#
    iv_file_name      IN VARCHAR2,     --   �C���^�t�F�[�X�t�@�C����
    iv_run_class      IN VARCHAR2,     --   ���s�敪�F�u0:�V�K�v�u1:�Ď��s�v
-- ******************** 2010/03/02 1.7 M.Sano     MOD START *********************** --
--    iv_edi_chain_code IN VARCHAR2      --   EDI�`�F�[���X�R�[�h
    iv_edi_chain_code IN VARCHAR2 DEFAULT NULL  --   EDI�`�F�[���X�R�[�h
-- ******************** 2010/03/02 1.7 M.Sano     MOD END   *********************** --
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
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00039'; -- �x���������b�Z�[�W�i���i�R�[�h�G���[�j
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
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    --==============================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    --==============================================================
    submain(
      iv_file_name,       --   �C���^�t�F�[�X�t�@�C����
      iv_run_class,       -- ���s�敪�F�u�V�K�v�u�Ď��s�v
      iv_edi_chain_code,  -- EDI�`�F�[���X�R�[�h
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--****************************** 2009/06/03 1.4 T.Kitajima DEL START ******************************--
----****************************** 2009/05/28 1.3 T.Kitajima ADD START ******************************--
--    --==============================================================
--    -- �R���J�����g�X�e�[�^�X�A�����̐ݒ�
--    --==============================================================
--    IF ( lv_retcode = cv_status_error ) THEN
--      gn_warn_cnt   := 0;                --�x�������F0
--      gn_normal_cnt := 0;                --���팏���F0
--      gn_error_cnt  := 1;
--    ELSIF ( lv_retcode = cv_status_warn ) THEN
--      gn_normal_cnt := gn_normal_cnt - gn_warn_cnt;
--    END IF;
----****************************** 2009/05/28 1.3 T.Kitajima ADD  END  ******************************--
--****************************** 2009/06/03 1.4 T.Kitajima DEL  END  ******************************--

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
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --==============================================================
    --* Description      : �I������(A-11)
    --==============================================================
--****************************** 2009/06/03 1.4 T.Kitajima MOD START ******************************--
--    --�Ώی����o��
--    gv_out_msg  := xxccp_common_pkg.get_msg(
--                iv_application  => cv_appl_short_name,
--                iv_name         => cv_target_rec_msg,
--                iv_token_name1  => cv_cnt_token,
--                iv_token_value1 => TO_CHAR(gn_target_cnt)
--                );
--    FND_FILE.PUT_LINE(
--      which  => FND_FILE.OUTPUT,
--      buff   => gv_out_msg
--    );
--    --
--    --���������o��
--    gv_out_msg  := xxccp_common_pkg.get_msg(
--                iv_application  => cv_appl_short_name,
--                iv_name         => cv_success_rec_msg,
--                iv_token_name1  => cv_cnt_token,
--                iv_token_value1 => TO_CHAR(gn_normal_cnt)
--                );
--    FND_FILE.PUT_LINE(
--      which  => FND_FILE.OUTPUT,
--      buff   => gv_out_msg
--    );
--    --
--    --�G���[�����o��
--    gv_out_msg  := xxccp_common_pkg.get_msg(
--                iv_application  => cv_appl_short_name,
--                iv_name         => cv_error_rec_msg,
--                iv_token_name1  => cv_cnt_token,
--                iv_token_value1 => TO_CHAR(gn_error_cnt)
--                );
--    FND_FILE.PUT_LINE(
--      which  => FND_FILE.OUTPUT,
--      buff   => gv_out_msg
--    );
--    --
--    --�x�������o��
--    gv_out_msg  := xxccp_common_pkg.get_msg(
--                iv_application  => cv_application,
--                iv_name         => cv_warn_rec_msg,
--                iv_token_name1  => cv_cnt_token,
--                iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                );
--    FND_FILE.PUT_LINE(
--      which  => FND_FILE.OUTPUT,
--      buff   => gv_out_msg
--    );
    IF ( gn_error_cnt != 0 ) THEN
      gn_warn_cnt := gn_target_cnt - gn_error_cnt;
    ELSE
      gn_warn_cnt := 0;
    END IF;
    gv_out_msg  := xxccp_common_pkg.get_msg(
                iv_application  => cv_application,
                iv_name         => cv_msg_count,
                iv_token_name1  => cv_tkn_cnt1,
                iv_token_value1 => TO_CHAR(gn_target_cnt),
                iv_token_name2  => cv_tkn_cnt2,
                iv_token_value2 => TO_CHAR(gn_normal_cnt),
                iv_token_name3  => cv_tkn_cnt3,
                iv_token_value3 => TO_CHAR(gn_error_cnt),
                iv_token_name4  => cv_tkn_cnt4,
                iv_token_value4 => TO_CHAR(gn_warn_cnt),
                iv_token_name5  => cv_tkn_cnt5,
                iv_token_value5 => TO_CHAR(gn_msg_cnt)
                );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
--****************************** 2009/06/04 1.4 T.Kitajima MOD  END  ******************************--
    --
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    --
    --�I�����b�Z�[�W
    IF  ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF  ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF  ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg  := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_short_name,
                iv_name         => lv_message_code
                );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
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
END XXCOS011A01C;
/
