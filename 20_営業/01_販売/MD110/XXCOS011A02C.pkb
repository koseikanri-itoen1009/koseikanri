CREATE OR REPLACE PACKAGE BODY XXCOS011A02C 
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A02C (spec)
 * Description      : SQL-LOADER�ɂ����EDI�݌ɏ�񃏁[�N�e�[�u���Ɏ捞�܂ꂽEDI�݌ɏ��f�[�^��
 *                     EDI�݌ɏ��e�[�u���ɂ��ꂼ��o�^���܂��B
 * MD.050           : �݌ɏ��f�[�^�捞�iMD050_COS_011_A02�j
 * Version          : 1.0
 *
 * Program List
 * ----------------------------------- ----------------------------------------------------------
 *  Name                                Description
 * ----------------------------------- ----------------------------------------------------------
 *  init                               �������� (A-1)
 *  sel_in_edi_inventory_work          EDI�݌ɏ�񃏁[�N�e�[�u���f�[�^���o (A-2)
 *  xxcos_in_edi_inventory_edit        EDI�݌ɏ��ϐ��̕ҏW(A-2)(1)
 *  data_check                         �f�[�^�Ó����`�F�b�N (A-3)
 *  xxcos_in_invoice_num_add           �`�[�ʍ��v�ϐ��ւ̒ǉ�(A-4)(1)
 *  xxcos_in_invoice_num_req           �`�[�ʍ��v�ϐ��ւ̍ĕҏW(A-4)(2)
 *  xxcos_in_invoice_num_up            �`�[�ʍ��v�ϐ��֐��ʂ����Z(A-5)
 *  xxcos_in_edi_inventory_insert      EDI�݌ɏ��e�[�u���ւ̃f�[�^�}��(A-6)
 *  xxcos_in_edi_inv_wk_update         EDI�݌ɏ�񃏁[�N�e�[�u���ւ̍X�V(A-7)
 *  xxcos_in_edi_inventory_delete      EDI�݌ɏ��e�[�u���f�[�^�폜(A-8)
 *  xxcos_in_edi_inventory_lock        EDI�݌ɏ��e�[�u�����b�N(A-8)(1)
 *  xxcos_in_edi_inv_work_delete       EDI�݌ɏ�񃏁[�N�e�[�u���f�[�^�폜(A-9)
 *  submain                            ���C�������v���V�[�W��
 *  main                               �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/29    1.0   K.Watanabe      �V�K�쐬
 *  2009/02/17    1.1   K.Kiriu         [COS_062]JAN�R�[�h�G���[���̃��b�Z�[�W���C��
 *                                      [COS_080]�`�[�v�̏C��
 *                                      [COS_081]�I���X�e�[�^�X�ɂ�鏈������̏C��
 *                                      [COS_088]�G���[�A�x�����ݎ��̏I���ݒ�̏C��
 *                                      [COS_089]�G���[���̐��팏���ݒ�̏C��
 *                                      [COS_090]�ڋq�i�ڂ̎擾���W�b�N�C��
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
  cv_pkg_name               CONSTANT   VARCHAR2(100) := 'XXCOS011A02';               -- �p�b�P�[�W��
--
  cv_application            CONSTANT   VARCHAR2(5)   := 'XXCOS';                     -- �A�v���P�[�V������
  -- �v���t�@�C��
  cv_prf_edi_del_date       CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_PURGE_TERM';     -- XXCOS:EDI���폜����
  cv_prf_case_code          CONSTANT   VARCHAR2(50)  := 'XXCOS1_CASE_UOM_CODE';      -- XXCOS:�P�[�X�P�ʃR�[�h
  cv_prf_orga_code1         CONSTANT   VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:�݌ɑg�D�R�[�h
  cv_lookup_type            CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_ITEM_ERR_TYPE';  
  cv_lookup_type1           CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_EXE_TYPE';  
  cv_lookup_type2           CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_STATUS';  
  cv_lookup_type3           CONSTANT   VARCHAR2(50)  := 'XXCOS1_EDI_DATA_TYPE_CODE';  
  cv_inv_num_err_flag       CONSTANT   VARCHAR2(1)   := '9';   -- ���s�敪�F�u�G���[�v
  cv_creation_class         CONSTANT   VARCHAR2(10)  := '03';
  cv_customer_class_code10  CONSTANT   VARCHAR2(10)  := '10';  -- �ڋq�}�X�^.�ڋq�敪 = '10'(�ڋq) 
  cv_customer_class_code18  CONSTANT   VARCHAR2(10)  := '18';  -- �ڋq�}�X�^.�ڋq�敪 = '18'(EDI�`�F�[���X) 
  cv_y                      CONSTANT   VARCHAR2(1)   := 'Y';
  --cv_par                    CONSTANT   VARCHAR2(1)   := '%';
  cn_1                      CONSTANT   NUMBER        := 1;
  cn_2                      CONSTANT   NUMBER        := 2;
  cn_3                      CONSTANT   NUMBER        := 3;
  cv_0                      CONSTANT   VARCHAR2(1)   := '0';
  cv_1                      CONSTANT   VARCHAR2(1)   := '1';
  cv_2                      CONSTANT   VARCHAR2(1)   := '2';
  cv_run_class_name         CONSTANT   VARCHAR2(1)   := '1';      -- �u�G���[�v
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
  gv_msg_data_update_err    CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00011'; --�f�[�^�X�V�G���[���b�Z�[�W
  gv_msg_data_delete_err    CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00012'; --�f�[�^�폜�G���[���b�Z�[�W 
  gv_msg_param_out_msg1     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12151'; --�p�����[�^�o�̓��b�Z�[�W1
  gv_msg_param_out_msg2     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12152'; --�p�����[�^�o�̓��b�Z�[�W2
  gv_msg_prod_cd_ng_rec_num CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00039'; --���i�R�[�h�G���[�������b�Z�[�W
  gv_msg_normal_msg         CONSTANT   VARCHAR2(20)  := 'APP-XXCCP1-90004'; --����I�����b�Z�[�W
  gv_msg_warning_msg        CONSTANT   VARCHAR2(20)  := 'APP-XXCCP1-90005'; --�x���I�����b�Z�[�W
  gv_msg_error_msg          CONSTANT   VARCHAR2(20)  := 'APP-XXCCP1-90006'; --�G���[�I���S���[���o�b�N���b�Z�[�W
  cv_msg_call_api_err       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-00017'; --API�ďo�G���[
  --* -------------------------------------------------------------------------------------------
  --�g�[�N��
  cv_msg_in_param           CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12168';  -- ���s�敪
  --�g�[�N�� �v���t�@�C��
  cv_msg_edi_del_date       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12169';  -- EDI���폜����
  cv_msg_case_code          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12153';  -- �P�[�X�P�ʃR�[�h
  cv_msg_orga_code          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12154';  -- �݌ɑg�D�R�[�h
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
  cv_application1           CONSTANT   VARCHAR2(5)  :=  'XXCOI';                 -- �A�v���P�[�V������
  --* -------------------------------------------------------------------------------------------
  --���b�Z�[�W�p������
  cv_msg_str_profile_name   CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12155';  -- �v���t�@�C����
  cv_msg_edi_inv_work       CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12173';  -- EDI�݌ɏ�񃏁[�N�e�[�u��
  cv_msg_edi_inventory      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12174';  -- EDI�݌ɏ��e�[�u��
  cv_msg_mtl_cust_items     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12159';  -- �ڋq�i��
  cv_msg_shop_code          CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12160';  -- �X�R�[�h
  cv_msg_class_name1        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12161';  -- ���s�敪�F�u�V�K�v
  cv_msg_class_name2        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12162';  -- ���s�敪�F�u�Ď��{�v
  cv_msg_class_name3        CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12163';  -- ���s�敪�F�u�G���[�v
  cv_msg_data_type_code     CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12175';  -- �f�[�^��R�[�h�F�u�݌ɏ��v
  cv_msg_jan_code           CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12166';  -- JAN�R�[�h
  cv_msg_none               CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12167';  -- �Ȃ�
  --�g�[�N�� �v���t�@�C��
  cv_msg_in_file_name1      CONSTANT   VARCHAR2(20)  := 'APP-XXCOS1-12172';  -- �C���^�[�t�F�[�X�t�@�C����
  --* -------------------------------------------------------------------------------------------
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_status_work             VARCHAR2(1) DEFAULT NULL;  --�x��:1
  --
  --�g�[�N�� �v���t�@�C��
  gv_in_file_name            VARCHAR2(50) DEFAULT NULL;     -- �C���^�[�t�F�[�X�t�@�C����
  gv_in_param                VARCHAR2(50) DEFAULT NULL;     -- ���s�敪
  gv_prf_edi_del_date0       VARCHAR2(50) DEFAULT NULL;     -- EDI���폜����
  gv_prf_case_code0          VARCHAR2(50) DEFAULT NULL;     -- �P�[�X�P�ʃR�[�h
  gv_prf_orga_code0          VARCHAR2(50) DEFAULT NULL;     -- �݌ɑg�D�R�[�h
--
  -- �e�[�u����`����
  gv_tkn_edi_inv_work        VARCHAR2(50);     -- EDI�݌ɏ�񃏁[�N�e�[�u��
  gv_tkn_edi_inventory       VARCHAR2(50);     -- EDI�݌ɏ��e�[�u��
  gv_tkn_mtl_cust_items      VARCHAR2(50);     -- �ڋq�i��
  gv_tkn_shop_code           VARCHAR2(50);     -- �X�R�[�h
  gv_tkn_jan_code            VARCHAR2(10);     -- JAN�R�[�h
  gv_none                    VARCHAR2(10);     -- �Ȃ�
  gv_run_class_name1         VARCHAR2(50) DEFAULT '0';     -- ���s�敪�F�u�V�K�v
  gv_run_class_name2         VARCHAR2(50) DEFAULT '1';     -- ���s�敪�F�u�Ď��{�v
  gv_run_data_type_code      VARCHAR2(50) DEFAULT NULL;     -- �f�[�^��R�[�h�F�u�ԕi�m��v
  gn_normal_inventry_cnt     NUMBER DEFAULT 0;              -- ���팏��
  -- �`�[�ԍ�
  gv_invoice_number          VARCHAR2(12) DEFAULT NULL;

  --* -------------------------------------------------------------------------------------------
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- EDI�݌ɏ�񃏁[�N�e�[�u���f�[�^�i�[�p�ϐ�(xxcos_edi_inventory_work)
  TYPE g_rec_ediinv_work_data IS RECORD(
                -- �݌ɏ�񃏁[�NID
    stk_info_work_id                 xxcos_edi_inventory_work.stk_info_work_id%TYPE,
                -- �}�̋敪
    medium_class                     xxcos_edi_inventory_work.medium_class%TYPE,
                -- �f�[�^��R�[�h
    data_type_code                   xxcos_edi_inventory_work.data_type_code%TYPE,
                -- �t�@�C���m��
    file_no                          xxcos_edi_inventory_work.file_no%TYPE,
                -- ���敪
    info_class                       xxcos_edi_inventory_work.info_class%TYPE,
                -- ������
    process_date                     xxcos_edi_inventory_work.process_date%TYPE,
                -- ��������
    process_time                     xxcos_edi_inventory_work.process_time%TYPE,
                -- ���_�i����j�R�[�h
    base_code                        xxcos_edi_inventory_work.base_code%TYPE,
                -- ���_���i�������j
    base_name                        xxcos_edi_inventory_work.base_name%TYPE,
                -- ���_���i�J�i�j
    base_name_alt                    xxcos_edi_inventory_work.base_name_alt%TYPE,
                -- �d�c�h�`�F�[���X�R�[�h
    edi_chain_code                   xxcos_edi_inventory_work.edi_chain_code%TYPE,
                -- �d�c�h�`�F�[���X���i�����j
    edi_chain_name                   xxcos_edi_inventory_work.edi_chain_name%TYPE,
                -- �d�c�h�`�F�[���X���i�J�i�j
    edi_chain_name_alt               xxcos_edi_inventory_work.edi_chain_name_alt%TYPE,
                -- ���[�R�[�h
    report_code                      xxcos_edi_inventory_work.report_code%TYPE,
                -- ���[�\����
    report_show_name                 xxcos_edi_inventory_work.report_show_name%TYPE,
                -- �ڋq�R�[�h
    customer_code                    xxcos_edi_inventory_work.customer_code%TYPE,
                -- �ڋq���i�����j
    customer_name                    xxcos_edi_inventory_work.customer_name%TYPE,
                -- �ڋq���i�J�i�j
    customer_name_alt                xxcos_edi_inventory_work.customer_name_alt%TYPE,
                -- �ЃR�[�h
    company_code                     xxcos_edi_inventory_work.company_code%TYPE,
                -- �Ж��i�J�i�j
    company_name_alt                 xxcos_edi_inventory_work.company_name_alt%TYPE,
                -- �X�R�[�h
    shop_code                        xxcos_edi_inventory_work.shop_code%TYPE, 
                -- �X���i�J�i�j
    shop_name_alt                    xxcos_edi_inventory_work.shop_name_alt%TYPE,
                -- �[���Z���^�[�R�[�h
    delivery_center_code             xxcos_edi_inventory_work.delivery_center_code%TYPE,
                -- �[���Z���^�[���i�����j
    delivery_center_name             xxcos_edi_inventory_work.delivery_center_name%TYPE,
                -- �[���Z���^�[���i�J�i�j
    delivery_center_name_alt         xxcos_edi_inventory_work.delivery_center_name_alt%TYPE,
                --�q�ɃR�[�h
    whse_code                        xxcos_edi_inventory_work.whse_code%TYPE,
                --�q�ɖ�
    whse_name                        xxcos_edi_inventory_work.whse_name%TYPE,
                --���i�S���Җ��i�����j
    inspect_charge_name              xxcos_edi_inventory_work.inspect_charge_name%TYPE,
                --���i�S���Җ��i�J�i�j
    inspect_charge_name_alt          xxcos_edi_inventory_work.inspect_charge_name_alt%TYPE,
                --�ԕi�S���Җ��i�����j
    return_charge_name               xxcos_edi_inventory_work.return_charge_name%TYPE,
                --�ԕi�S���Җ��i�J�i�j
    return_charge_name_alt           xxcos_edi_inventory_work.return_charge_name_alt%TYPE,
                --��̒S���Җ��i�����j
    receive_charge_name              xxcos_edi_inventory_work.receive_charge_name%TYPE,
                --��̒S���Җ��i�J�i�j
    receive_charge_name_alt          xxcos_edi_inventory_work.receive_charge_name_alt%TYPE,
                -- ������
    order_date                       xxcos_edi_inventory_work.order_date%TYPE,
                -- �Z���^�[�[�i��
    center_delivery_date             xxcos_edi_inventory_work.center_delivery_date%TYPE,
                --�Z���^�[���[�i��
    center_result_delivery_date      xxcos_edi_inventory_work.center_result_delivery_date%TYPE,
                --�Z���^�[�o�ɓ�
    center_shipping_date             xxcos_edi_inventory_work.center_shipping_date%TYPE,
                --�Z���^�[���o�ɓ�
    center_result_shipping_date      xxcos_edi_inventory_work.center_result_shipping_date%TYPE,
                -- �f�[�^�쐬���i�d�c�h�f�[�^���j
    data_creation_date_edi_data      xxcos_edi_inventory_work.data_creation_date_edi_data%TYPE,
                -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
    data_creation_time_edi_data      xxcos_edi_inventory_work.data_creation_time_edi_data%TYPE,
                --�݌ɓ��t
    stk_date                         xxcos_edi_inventory_work.stk_date%TYPE,
                --�񋟊�Ǝ����R�[�h�敪
    offer_vendor_code_class          xxcos_edi_inventory_work.offer_vendor_code_class%TYPE,
                --�q�Ɏ����R�[�h�敪
    whse_vendor_code_class           xxcos_edi_inventory_work.whse_vendor_code_class%TYPE,
                --�񋟃T�C�N���敪
    offer_cycle_class                xxcos_edi_inventory_work.offer_cycle_class%TYPE,
                --�݌Ɏ��
    stk_type                         xxcos_edi_inventory_work.stk_type%TYPE,
                --���{��敪
    japanese_class                   xxcos_edi_inventory_work.japanese_class%TYPE,
                --�q�ɋ敪
    whse_class                       xxcos_edi_inventory_work.whse_class%TYPE,
                -- �����R�[�h
    vendor_code                      xxcos_edi_inventory_work.vendor_code%TYPE,
                -- ����於�i�����j
    vendor_name                      xxcos_edi_inventory_work.vendor_name%TYPE,
                -- ����於�i�J�i�j
    vendor_name_alt                  xxcos_edi_inventory_work.vendor_name_alt%TYPE,
                -- �`�F�b�N�f�W�b�g�L���敪
    check_digit_class                xxcos_edi_inventory_work.check_digit_class%TYPE,
                -- �`�[�ԍ�
    invoice_number                   xxcos_edi_inventory_work.invoice_number%TYPE,
                -- �`�F�b�N�f�W�b�g
    check_digit                      xxcos_edi_inventory_work.check_digit%TYPE,
                -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
    chain_peculiar_area_header       xxcos_edi_inventory_work.chain_peculiar_area_header%TYPE,
                -- ���i�R�[�h�i�ɓ����j
    product_code_itouen              xxcos_edi_inventory_work.product_code_itouen%TYPE,
                -- ���i�R�[�h�i����j
    product_code_other_party         xxcos_edi_inventory_work.product_code_other_party%TYPE,
                -- �i�`�m�R�[�h
    jan_code                         xxcos_edi_inventory_work.jan_code%TYPE,
                -- �h�s�e�R�[�h
    itf_code                         xxcos_edi_inventory_work.itf_code%TYPE,
                -- ���i���i�����j
    product_name                     xxcos_edi_inventory_work.product_name%TYPE,
                -- ���i���i�J�i�j
    product_name_alt                 xxcos_edi_inventory_work.product_name_alt%TYPE,
                -- ���i�敪
    prod_class                       xxcos_edi_inventory_work.prod_class%TYPE,
                -- �K�p�i���敪
    active_quality_class             xxcos_edi_inventory_work.active_quality_class%TYPE,
                -- ����
    qty_in_case                      xxcos_edi_inventory_work.qty_in_case%TYPE,
                -- �P��
    uom_code                         xxcos_edi_inventory_work.uom_code%TYPE,
                -- ������Ϗo�א���
    day_average_shipping_qty         xxcos_edi_inventory_work.day_average_shipping_qty%TYPE,
                -- �݌Ɏ�ʃR�[�h
    stk_type_code                    xxcos_edi_inventory_work.stk_type_code%TYPE,
                -- �ŏI���ד�
    last_arrival_date                xxcos_edi_inventory_work.last_arrival_date%TYPE,
                -- �ܖ�����
    use_by_date                      xxcos_edi_inventory_work.use_by_date%TYPE,
                -- ������
    product_date                     xxcos_edi_inventory_work.product_date%TYPE,
                -- ����݌Ɂi�P�[�X�j
    upper_limit_stk_case             xxcos_edi_inventory_work.upper_limit_stk_case%TYPE,
                -- ����݌Ɂi�o���j
    upper_limit_stk_indv             xxcos_edi_inventory_work.upper_limit_stk_indv%TYPE,
                -- �����_�i�o���j 
    indv_order_point                 xxcos_edi_inventory_work.indv_order_point%TYPE,
                -- �����_�i�P�[�X�j
    case_order_point                 xxcos_edi_inventory_work.case_order_point%TYPE,
                -- �O�����݌ɐ��ʁi�o���j
    indv_prev_month_stk_qty          xxcos_edi_inventory_work.indv_prev_month_stk_qty%TYPE,
                -- �O�����݌ɐ��ʁi�P�[�X�j
    case_prev_month_stk_qty          xxcos_edi_inventory_work.case_prev_month_stk_qty%TYPE,
                -- �O���݌ɐ��ʁi���v�j 
    sum_prev_month_stk_qty           xxcos_edi_inventory_work.sum_prev_month_stk_qty%TYPE,
                -- �������ʁi�����A�o���j
    day_indv_order_qty               xxcos_edi_inventory_work.day_indv_order_qty%TYPE,
                -- �������ʁi�����A�P�[�X�j
    day_case_order_qty               xxcos_edi_inventory_work.day_case_order_qty%TYPE,
                -- �������ʁi�����A���v�j
    day_sum_order_qty                xxcos_edi_inventory_work.day_sum_order_qty%TYPE,
                -- �������ʁi�����A�o���j
    month_indv_order_qty             xxcos_edi_inventory_work.month_indv_order_qty%TYPE,
                -- �������ʁi�����A�P�[�X�j
    month_case_order_qty             xxcos_edi_inventory_work.month_case_order_qty%TYPE,
                -- �������ʁi�����A���v�j
    month_sum_order_qty              xxcos_edi_inventory_work.month_sum_order_qty%TYPE,
                -- ���ɐ��ʁi�����A�o���j
    day_indv_arrival_qty             xxcos_edi_inventory_work.day_indv_arrival_qty%TYPE,
                -- ���ɐ��ʁi�����A�P�[�X�j
    day_case_arrival_qty             xxcos_edi_inventory_work.day_case_arrival_qty%TYPE,
                -- ���ɐ��ʁi�����A���v�j
    day_sum_arrival_qty              xxcos_edi_inventory_work.day_sum_arrival_qty%TYPE,
                -- �������׉�         
    month_arrival_count              xxcos_edi_inventory_work.month_arrival_count%TYPE,
                -- ���ɐ��ʁi�����A�o���j
    month_indv_arrival_qty           xxcos_edi_inventory_work.month_indv_arrival_qty%TYPE,
                -- ���ɐ��ʁi�����A�P�[�X�j
    month_case_arrival_qty           xxcos_edi_inventory_work.month_case_arrival_qty%TYPE,
                -- ���ɐ��ʁi�����A���v�j
    month_sum_arrival_qty            xxcos_edi_inventory_work.month_sum_arrival_qty%TYPE,
                -- �o�ɐ��ʁi�����A�o���j
    day_indv_shipping_qty            xxcos_edi_inventory_work.day_indv_shipping_qty%TYPE,
                -- �o�ɐ��ʁi�����A�P�[�X�j
    day_case_shipping_qty            xxcos_edi_inventory_work.day_case_shipping_qty%TYPE,
                -- �o�ɐ��ʁi�����A���v�j
    day_sum_shipping_qty             xxcos_edi_inventory_work.day_sum_shipping_qty%TYPE,
                -- �o�ɐ��ʁi�����A�o���j
    month_indv_shipping_qty          xxcos_edi_inventory_work.month_indv_shipping_qty%TYPE,
                -- �o�ɐ��ʁi�����A�P�[�X�j
    month_case_shipping_qty          xxcos_edi_inventory_work.month_case_shipping_qty%TYPE,
                -- �o�ɐ��ʁi�����A���v�j
    month_sum_shipping_qty           xxcos_edi_inventory_work.month_sum_shipping_qty%TYPE,
                -- �j���A���X���ʁi�����A�o���j
    day_indv_destroy_loss_qty        xxcos_edi_inventory_work.day_indv_destroy_loss_qty%TYPE,
                -- �j���A���X���ʁi�����A�P�[�X�j
    day_case_destroy_loss_qty        xxcos_edi_inventory_work.day_case_destroy_loss_qty%TYPE,
                -- �j���A���X���ʁi�����A���v�j
    day_sum_destroy_loss_qty         xxcos_edi_inventory_work.day_sum_destroy_loss_qty%TYPE,
                -- �j���A���X���ʁi�����A�o���j
    month_indv_destroy_loss_qty      xxcos_edi_inventory_work.month_indv_destroy_loss_qty%TYPE,
                -- �j���A���X���ʁi�����A�P�[�X�j
    month_case_destroy_loss_qty      xxcos_edi_inventory_work.month_case_destroy_loss_qty%TYPE,
                -- �j���A���X���ʁi�����A���v�j
    month_sum_destroy_loss_qty       xxcos_edi_inventory_work.month_sum_destroy_loss_qty%TYPE,
                -- �s�Ǎ݌ɐ��ʁi�����A�o���j
    day_indv_defect_stk_qty          xxcos_edi_inventory_work.day_indv_defect_stk_qty%TYPE,
                -- �s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
    day_case_defect_stk_qty          xxcos_edi_inventory_work.day_case_defect_stk_qty%TYPE,
                -- �s�Ǎ݌ɐ��ʁi�����A���v�j
    day_sum_defect_stk_qty           xxcos_edi_inventory_work.day_sum_defect_stk_qty%TYPE,
                -- �s�Ǎ݌ɐ��ʁi�����A�o���j
    month_indv_defect_stk_qty        xxcos_edi_inventory_work.month_indv_defect_stk_qty%TYPE,
                -- �s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
    month_case_defect_stk_qty        xxcos_edi_inventory_work.month_case_defect_stk_qty%TYPE,
                -- �s�Ǎ݌ɐ��ʁi�����A���v�j
    month_sum_defect_stk_qty         xxcos_edi_inventory_work.month_sum_defect_stk_qty%TYPE,
                -- �s�Ǖԕi���ʁi�����A�o���j
    day_indv_defect_return_qty       xxcos_edi_inventory_work.day_indv_defect_return_qty%TYPE,
                -- �s�Ǖԕi���ʁi�����A�P�[�X�j
    day_case_defect_return_qty       xxcos_edi_inventory_work.day_case_defect_return_qty%TYPE,
                -- �s�Ǖԕi���ʁi�����A���v�j
    day_sum_defect_return_qty        xxcos_edi_inventory_work.day_sum_defect_return_qty%TYPE,
                -- �s�Ǖԕi���ʁi�����A�o���j
    month_indv_defect_return_qty     xxcos_edi_inventory_work.month_indv_defect_return_qty%TYPE,
                -- �s�Ǖԕi���ʁi�����A�P�[�X�j
    month_case_defect_return_qty     xxcos_edi_inventory_work.month_case_defect_return_qty%TYPE,
                -- �s�Ǖԕi���ʁi�����A���v�j
    month_sum_defect_return_qty      xxcos_edi_inventory_work.month_sum_defect_return_qty%TYPE,
                -- �s�Ǖԕi����i�����A�o���j
    day_indv_defect_return_rcpt      xxcos_edi_inventory_work.day_indv_defect_return_rcpt%TYPE,
                -- �s�Ǖԕi����i�����A�P�[�X�j
    day_case_defect_return_rcpt      xxcos_edi_inventory_work.day_case_defect_return_rcpt%TYPE,
                -- �s�Ǖԕi����i�����A���v�j
    day_sum_defect_return_rcpt       xxcos_edi_inventory_work.day_sum_defect_return_rcpt%TYPE,
                -- �s�Ǖԕi����i�����A�o���j
    month_indv_defect_return_rcpt      xxcos_edi_inventory_work.month_indv_defect_return_rcpt%TYPE,
                -- �s�Ǖԕi����i�����A�P�[�X�j
    month_case_defect_return_rcpt      xxcos_edi_inventory_work.month_case_defect_return_rcpt%TYPE,
                -- �s�Ǖԕi����i�����A���v�j
    month_sum_defect_return_rcpt       xxcos_edi_inventory_work.month_sum_defect_return_rcpt%TYPE,
                -- �s�Ǖԕi�����i�����A�o���j
    day_indv_defect_return_send        xxcos_edi_inventory_work.day_indv_defect_return_send%TYPE,
                -- �s�Ǖԕi�����i�����A�P�[�X�j
    day_case_defect_return_send        xxcos_edi_inventory_work.day_case_defect_return_send%TYPE,
                -- �s�Ǖԕi�����i�����A���v�j
    day_sum_defect_return_send         xxcos_edi_inventory_work.day_sum_defect_return_send%TYPE,
                -- �s�Ǖԕi�����i�����A�o���j
    month_indv_defect_return_send      xxcos_edi_inventory_work.month_indv_defect_return_send%TYPE,
                -- �s�Ǖԕi�����i�����A�P�[�X�j
    month_case_defect_return_send      xxcos_edi_inventory_work.month_case_defect_return_send%TYPE,
                -- �s�Ǖԕi�����i�����A���v�j
    month_sum_defect_return_send       xxcos_edi_inventory_work.month_sum_defect_return_send%TYPE,
                -- �Ǖi�ԕi����i�����A�o���j
    day_indv_quality_return_rcpt       xxcos_edi_inventory_work.day_indv_quality_return_rcpt%TYPE,
                -- �Ǖi�ԕi����i�����A�P�[�X�j
    day_case_quality_return_rcpt       xxcos_edi_inventory_work.day_case_quality_return_rcpt%TYPE,
                -- �Ǖi�ԕi����i�����A���v�j
    day_sum_quality_return_rcpt        xxcos_edi_inventory_work.day_sum_quality_return_rcpt%TYPE,
                -- �Ǖi�ԕi����i�����A�o���j
    month_indv_quality_return_rcpt     xxcos_edi_inventory_work.month_indv_quality_return_rcpt%TYPE,
                -- �Ǖi�ԕi����i�����A�P�[�X�j
    month_case_quality_return_rcpt     xxcos_edi_inventory_work.month_case_quality_return_rcpt%TYPE,
                -- �Ǖi�ԕi����i�����A���v�j
    month_sum_quality_return_rcpt      xxcos_edi_inventory_work.month_sum_quality_return_rcpt%TYPE,
                -- �Ǖi�ԕi�����i�����A�o���j
    day_indv_quality_return_send       xxcos_edi_inventory_work.day_indv_quality_return_send%TYPE,
                -- �Ǖi�ԕi�����i�����A�P�[�X�j
    day_case_quality_return_send       xxcos_edi_inventory_work.day_case_quality_return_send%TYPE,
                -- �Ǖi�ԕi�����i�����A���v�j
    day_sum_quality_return_send        xxcos_edi_inventory_work.day_sum_quality_return_send%TYPE,
                -- �Ǖi�ԕi�����i�����A�o���j
    month_indv_quality_return_send     xxcos_edi_inventory_work.month_indv_quality_return_send%TYPE,
                -- �Ǖi�ԕi�����i�����A�P�[�X�j
    month_case_quality_return_send     xxcos_edi_inventory_work.month_case_quality_return_send%TYPE,
                -- �Ǖi�ԕi�����i�����A���v�j
    month_sum_quality_return_send      xxcos_edi_inventory_work.month_sum_quality_return_send%TYPE,
                -- �I�����فi�����A�o���j
    day_indv_invent_difference         xxcos_edi_inventory_work.day_indv_invent_difference%TYPE,
                -- �I�����فi�����A�P�[�X�j
    day_case_invent_difference         xxcos_edi_inventory_work.day_case_invent_difference%TYPE,
                -- �I�����فi�����A���v�j
    day_sum_invent_difference          xxcos_edi_inventory_work.day_sum_invent_difference%TYPE,
                -- �I�����فi�����A�o���j
    month_indv_invent_difference       xxcos_edi_inventory_work.month_indv_invent_difference%TYPE,
                -- �I�����فi�����A�P�[�X�j
    month_case_invent_difference       xxcos_edi_inventory_work.month_case_invent_difference%TYPE,
                -- �I�����فi�����A���v�j 
    month_sum_invent_difference        xxcos_edi_inventory_work.month_sum_invent_difference%TYPE,
                -- �݌ɐ��ʁi�����A�o���j 
    day_indv_stk_qty                   xxcos_edi_inventory_work.day_indv_stk_qty%TYPE,
                -- �݌ɐ��ʁi�����A�P�[�X�j
    day_case_stk_qty                   xxcos_edi_inventory_work.day_case_stk_qty%TYPE,
                -- �݌ɐ��ʁi�����A���v�j 
    day_sum_stk_qty                    xxcos_edi_inventory_work.day_sum_stk_qty%TYPE,
                -- �݌ɐ��ʁi�����A�o���j 
    month_indv_stk_qty                 xxcos_edi_inventory_work.month_indv_stk_qty%TYPE,
                -- �݌ɐ��ʁi�����A�P�[�X�j
    month_case_stk_qty                 xxcos_edi_inventory_work.month_case_stk_qty%TYPE,
                -- �݌ɐ��ʁi�����A���v�j 
    month_sum_stk_qty                  xxcos_edi_inventory_work.month_sum_stk_qty%TYPE,
                -- �ۗ��݌ɐ��i�����A�o���j
    day_indv_reserved_stk_qty          xxcos_edi_inventory_work.day_indv_reserved_stk_qty%TYPE,
                -- �ۗ��݌ɐ��i�����A�P�[�X�j
    day_case_reserved_stk_qty          xxcos_edi_inventory_work.day_case_reserved_stk_qty%TYPE,
                -- �ۗ��݌ɐ��i�����A���v�j 
    day_sum_reserved_stk_qty           xxcos_edi_inventory_work.day_sum_reserved_stk_qty%TYPE,
                -- �ۗ��݌ɐ��i�����A�o���j 
    month_indv_reserved_stk_qty        xxcos_edi_inventory_work.month_indv_reserved_stk_qty%TYPE,
                -- �ۗ��݌ɐ��i�����A�P�[�X�j
    month_case_reserved_stk_qty        xxcos_edi_inventory_work.month_case_reserved_stk_qty%TYPE,
                -- �ۗ��݌ɐ��i�����A���v�j
    month_sum_reserved_stk_qty         xxcos_edi_inventory_work.month_sum_reserved_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�o���j
    day_indv_cd_stk_qty                xxcos_edi_inventory_work.day_indv_cd_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�P�[�X�j
    day_case_cd_stk_qty                xxcos_edi_inventory_work.day_case_cd_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A���v�j
    day_sum_cd_stk_qty                 xxcos_edi_inventory_work.day_sum_cd_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�o���j 
    month_indv_cd_stk_qty              xxcos_edi_inventory_work.month_indv_cd_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�P�[�X�j
    month_case_cd_stk_qty              xxcos_edi_inventory_work.month_case_cd_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A���v�j
    month_sum_cd_stk_qty               xxcos_edi_inventory_work.month_sum_cd_stk_qty%TYPE,
                -- �ϑ��݌ɐ��ʁi�����A�o���j 
    day_indv_cargo_stk_qty             xxcos_edi_inventory_work.day_indv_cargo_stk_qty%TYPE,
                -- �ϑ��݌ɐ��ʁi�����A�P�[�X�j
    day_case_cargo_stk_qty             xxcos_edi_inventory_work.day_case_cargo_stk_qty%TYPE,
                -- �ϑ��݌ɐ��ʁi�����A���v�j
    day_sum_cargo_stk_qty              xxcos_edi_inventory_work.day_sum_cargo_stk_qty%TYPE,
                -- �ϑ��݌ɐ��ʁi�����A�o���j 
    month_indv_cargo_stk_qty           xxcos_edi_inventory_work.month_indv_cargo_stk_qty%TYPE,
                -- �ϑ��݌ɐ��ʁi�����A�P�[�X�j
    month_case_cargo_stk_qty           xxcos_edi_inventory_work.month_case_cargo_stk_qty%TYPE,
                -- �ϑ��݌ɐ��ʁi�����A���v�j 
    month_sum_cargo_stk_qty            xxcos_edi_inventory_work.month_sum_cargo_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�o���j 
    day_indv_adjustment_stk_qty        xxcos_edi_inventory_work.day_indv_adjustment_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�P�[�X�j
    day_case_adjustment_stk_qty        xxcos_edi_inventory_work.day_case_adjustment_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A���v�j 
    day_sum_adjustment_stk_qty         xxcos_edi_inventory_work.day_sum_adjustment_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�o���j 
    month_indv_adjustment_stk_qty      xxcos_edi_inventory_work.month_indv_adjustment_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�P�[�X�j
    month_case_adjustment_stk_qty      xxcos_edi_inventory_work.month_case_adjustment_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A���v�j 
    month_sum_adjustment_stk_qty       xxcos_edi_inventory_work.month_sum_adjustment_stk_qty%TYPE,
                -- ���o�א��ʁi�����A�o���j  
    day_indv_still_shipping_qty        xxcos_edi_inventory_work.day_indv_still_shipping_qty%TYPE,
                -- ���o�א��ʁi�����A�P�[�X�j
    day_case_still_shipping_qty        xxcos_edi_inventory_work.day_case_still_shipping_qty%TYPE,
                -- ���o�א��ʁi�����A���v�j  
    day_sum_still_shipping_qty         xxcos_edi_inventory_work.day_sum_still_shipping_qty%TYPE,
                -- ���o�א��ʁi�����A�o���j   
    month_indv_still_shipping_qty      xxcos_edi_inventory_work.month_indv_still_shipping_qty%TYPE,
                -- ���o�א��ʁi�����A�P�[�X�j 
    month_case_still_shipping_qty      xxcos_edi_inventory_work.month_case_still_shipping_qty%TYPE,
                -- ���o�א��ʁi�����A���v�j 
    month_sum_still_shipping_qty       xxcos_edi_inventory_work.month_sum_still_shipping_qty%TYPE,
                -- ���݌ɐ��ʁi�o���j      
    indv_all_stk_qty                   xxcos_edi_inventory_work.indv_all_stk_qty%TYPE,
                -- ���݌ɐ��ʁi�P�[�X�j
    case_all_stk_qty                   xxcos_edi_inventory_work.case_all_stk_qty%TYPE,
                -- ���݌ɐ��ʁi���v�j       
    sum_all_stk_qty                    xxcos_edi_inventory_work.sum_all_stk_qty%TYPE,
                -- ����������               
    month_draw_count                   xxcos_edi_inventory_work.month_draw_count%TYPE,
                -- �����\���ʁi�����A�o���j 
    day_indv_draw_possible_qty         xxcos_edi_inventory_work.day_indv_draw_possible_qty%TYPE,
                -- �����\���ʁi�����A�P�[�X�j
    day_case_draw_possible_qty         xxcos_edi_inventory_work.day_case_draw_possible_qty%TYPE,
                -- �����\���ʁi�����A���v�j
    day_sum_draw_possible_qty          xxcos_edi_inventory_work.day_sum_draw_possible_qty%TYPE,
                -- �����\���ʁi�����A�o���j 
    month_indv_draw_possible_qty       xxcos_edi_inventory_work.month_indv_draw_possible_qty%TYPE,
                -- �����\���ʁi�����A�P�[�X�j
    month_case_draw_possible_qty       xxcos_edi_inventory_work.month_case_draw_possible_qty%TYPE,
                -- �����\���ʁi�����A���v�j 
    month_sum_draw_possible_qty        xxcos_edi_inventory_work.month_sum_draw_possible_qty%TYPE,
                -- �����s�\���i�����A�o���j  
    day_indv_draw_impossible_qty       xxcos_edi_inventory_work.day_indv_draw_impossible_qty%TYPE,
                -- �����s�\���i�����A�P�[�X�j 
    day_case_draw_impossible_qty       xxcos_edi_inventory_work.day_case_draw_impossible_qty%TYPE,
                -- �����s�\���i�����A���v�j 
    day_sum_draw_impossible_qty        xxcos_edi_inventory_work.day_sum_draw_impossible_qty%TYPE,
                -- �݌ɋ��z�i�����j      
    day_stk_amt                        xxcos_edi_inventory_work.day_stk_amt%TYPE,
                -- �݌ɋ��z�i�����j       
    month_stk_amt                      xxcos_edi_inventory_work.month_stk_amt%TYPE,
                -- ���l                       
    remarks                            xxcos_edi_inventory_work.remarks%TYPE,
                -- �`�F�[���X�ŗL�G���A�i���ׁj
    chain_peculiar_area_line           xxcos_edi_inventory_work.chain_peculiar_area_line%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j  
    invoice_day_indv_sum_stk_qty       xxcos_edi_inventory_work.invoice_day_indv_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
    invoice_day_case_sum_stk_qty       xxcos_edi_inventory_work.invoice_day_case_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j  
    invoice_day_sum_sum_stk_qty        xxcos_edi_inventory_work.invoice_day_sum_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j  
    invoice_month_indv_sum_stk_qty     xxcos_edi_inventory_work.invoice_month_indv_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
    invoice_month_case_sum_stk_qty     xxcos_edi_inventory_work.invoice_month_case_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j  
    invoice_month_sum_sum_stk_qty      xxcos_edi_inventory_work.invoice_month_sum_sum_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j 
    invoice_day_indv_cd_stk_qty        xxcos_edi_inventory_work.invoice_day_indv_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
    invoice_day_case_cd_stk_qty        xxcos_edi_inventory_work.invoice_day_case_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j  
    invoice_day_sum_cd_stk_qty         xxcos_edi_inventory_work.invoice_day_sum_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j  
    invoice_month_indv_cd_stk_qty      xxcos_edi_inventory_work.invoice_month_indv_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
    invoice_month_case_cd_stk_qty      xxcos_edi_inventory_work.invoice_month_case_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j  
    invoice_month_sum_cd_stk_qty       xxcos_edi_inventory_work.invoice_month_sum_cd_stk_qty%TYPE,
                -- �`�[�v�j�݌ɋ��z�i�����j            
    invoice_day_stk_amt                xxcos_edi_inventory_work.invoice_day_stk_amt%TYPE,
                -- �`�[�v�j�݌ɋ��z�i�����j            
    invoice_month_stk_amt              xxcos_edi_inventory_work.invoice_month_stk_amt%TYPE,
                -- ���̋��z���v                        
    regular_sell_amt_sum               xxcos_edi_inventory_work.regular_sell_amt_sum%TYPE,
                -- ���߂����z���v                      
    rebate_amt_sum                     xxcos_edi_inventory_work.rebate_amt_sum%TYPE,
                -- ����e����z���v                   
    collect_bottle_amt_sum             xxcos_edi_inventory_work.collect_bottle_amt_sum%TYPE,
                -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j    
    chain_peculiar_area_footer         xxcos_edi_inventory_work.chain_peculiar_area_footer%TYPE,
                -- �X�e�[�^�X                          
    err_status                         xxcos_edi_inventory_work.err_status%TYPE
  );
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  TYPE g_tab_ediinv_work_data IS TABLE OF g_rec_ediinv_work_data INDEX BY PLS_INTEGER;
  -- ===============================
  --  EDI�݌ɏ�񃏁[�N�e�[�u��
  -- ===============================
  gt_ediinv_work_data                 g_tab_ediinv_work_data;

  --
  -- ===============================
  -- �ڋq�f�[�^���R�[�h�^
  -- ===============================
  TYPE g_req_cust_acc_data_rtype IS RECORD(
    account_number    hz_cust_accounts.account_number%TYPE,       -- �ڋq�}�X�^.�ڋq�R�[�h
    chain_store_code  xxcmm_cust_accounts.chain_store_code%TYPE,  -- �`�F�[���X�R�[�h(EDI)
    store_code        xxcmm_cust_accounts.store_code%TYPE         -- �X�܃R�[�h
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
  gv_prf_edi_del_date        VARCHAR2(50) DEFAULT NULL;  -- XXCOS:EDI���폜����
  gv_prf_case_code           VARCHAR2(50) DEFAULT NULL;  -- XXCOS:�P�[�X�P�ʃR�[�h
  gv_prf_orga_code           VARCHAR2(50) DEFAULT NULL;  -- XXCOI:�݌ɑg�D�R�[�h
  gv_prf_orga_id             VARCHAR2(50) DEFAULT NULL;  -- XXCOS:�݌ɑg�DID
  gv_inv_invoice_number_key  VARCHAR2(12) DEFAULT NULL;  -- �`�[�ԍ� 
  gv_err_ediinv_work_flag    VARCHAR2(1)  DEFAULT NULL;  -- �݌ɏ��G���[�t���O 
  gv_dummy_item_code         mtl_system_items_b.segment1%TYPE  DEFAULT NULL;  -- �_�~�[�i�ڐݒ�L��
  --
  --* -------------------------------------------------------------------------------------------
  -- EDI�݌ɏ��e�[�u���f�[�^�W�v�p�ϐ�(xxcos_edi_inventory)
  TYPE g_sum_edi_inv_data_rtype IS RECORD(
                -- �`�[�ԍ�
    invoice_number                     xxcos_edi_inventory.invoice_number%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j  
    invoice_day_indv_sum_stk_qty       xxcos_edi_inventory.invoice_day_indv_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
    invoice_day_case_sum_stk_qty       xxcos_edi_inventory.invoice_day_case_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j  
    invoice_day_sum_sum_stk_qty        xxcos_edi_inventory.invoice_day_sum_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j  
    invoice_month_indv_sum_stk_qty     xxcos_edi_inventory.invoice_month_indv_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
    invoice_month_case_sum_stk_qty     xxcos_edi_inventory.invoice_month_case_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j  
    invoice_month_sum_sum_stk_qty      xxcos_edi_inventory.invoice_month_sum_sum_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j 
    invoice_day_indv_cd_stk_qty        xxcos_edi_inventory.invoice_day_indv_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
    invoice_day_case_cd_stk_qty        xxcos_edi_inventory.invoice_day_case_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j  
    invoice_day_sum_cd_stk_qty         xxcos_edi_inventory.invoice_day_sum_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j  
    invoice_month_indv_cd_stk_qty      xxcos_edi_inventory.invoice_month_indv_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
    invoice_month_case_cd_stk_qty      xxcos_edi_inventory.invoice_month_case_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j  
    invoice_month_sum_cd_stk_qty       xxcos_edi_inventory.invoice_month_sum_cd_stk_qty%TYPE,
                -- �`�[�v�j�݌ɋ��z�i�����j            
    invoice_day_stk_amt                xxcos_edi_inventory.invoice_day_stk_amt%TYPE,
                -- �`�[�v�j�݌ɋ��z�i�����j            
    invoice_month_stk_amt              xxcos_edi_inventory.invoice_month_stk_amt%TYPE
  );
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  -- EDI�݌ɏ��f�[�^ �e�[�u���^
  TYPE g_sum_edi_inv_data_ttype IS TABLE OF g_sum_edi_inv_data_rtype INDEX BY BINARY_INTEGER;
  gt_sum_edi_inv_data  g_sum_edi_inv_data_ttype;
  --* -------------------------------------------------------------------------------------------
  --* -------------------------------------------------------------------------------------------
  -- EDI�݌ɏ��e�[�u���f�[�^�o�^�p�ϐ�(xxcos_edi_inventory)
  TYPE g_req_edi_inv_data_rtype IS RECORD(
                -- �݌ɏ��ID
    stk_info_id                      xxcos_edi_inventory.stk_info_id%TYPE,
                -- �}�̋敪
    medium_class                     xxcos_edi_inventory.medium_class%TYPE,
                -- �f�[�^��R�[�h
    data_type_code                   xxcos_edi_inventory.data_type_code%TYPE,
                -- �t�@�C���m��
    file_no                          xxcos_edi_inventory.file_no%TYPE,
                -- ���敪
    info_class                       xxcos_edi_inventory.info_class%TYPE,
                -- ������
    process_date                     xxcos_edi_inventory.process_date%TYPE,
                -- ��������
    process_time                     xxcos_edi_inventory.process_time%TYPE,
                -- ���_�i����j�R�[�h
    base_code                        xxcos_edi_inventory.base_code%TYPE,
                -- ���_���i�������j
    base_name                        xxcos_edi_inventory.base_name%TYPE,
                -- ���_���i�J�i�j
    base_name_alt                    xxcos_edi_inventory.base_name_alt%TYPE,
                -- �d�c�h�`�F�[���X�R�[�h
    edi_chain_code                   xxcos_edi_inventory.edi_chain_code%TYPE,
                -- �d�c�h�`�F�[���X���i�����j
    edi_chain_name                   xxcos_edi_inventory.edi_chain_name%TYPE,
                -- �d�c�h�`�F�[���X���i�J�i�j
    edi_chain_name_alt               xxcos_edi_inventory.edi_chain_name_alt%TYPE,
                -- ���[�R�[�h
    report_code                      xxcos_edi_inventory.report_code%TYPE,
                -- ���[�\����
    report_show_name                 xxcos_edi_inventory.report_show_name%TYPE,
                -- �ڋq�R�[�h1
    customer_code                    xxcos_edi_inventory.customer_code%TYPE,
                -- �ڋq���i�����j
    customer_name                    xxcos_edi_inventory.customer_name%TYPE,
                -- �ڋq���i�J�i�j
    customer_name_alt                xxcos_edi_inventory.customer_name_alt%TYPE,
                -- �ЃR�[�h
    company_code                     xxcos_edi_inventory.company_code%TYPE,
                -- �Ж��i�J�i�j
    company_name_alt                 xxcos_edi_inventory.company_name_alt%TYPE,
                -- �X�R�[�h
    shop_code                        xxcos_edi_inventory.shop_code%TYPE, 
                -- �X���i�J�i�j
    shop_name_alt                    xxcos_edi_inventory.shop_name_alt%TYPE,
                -- �[���Z���^�[�R�[�h
    delivery_center_code             xxcos_edi_inventory.delivery_center_code%TYPE,
                -- �[���Z���^�[���i�����j
    delivery_center_name             xxcos_edi_inventory.delivery_center_name%TYPE,
                -- �[���Z���^�[���i�J�i�j
    delivery_center_name_alt         xxcos_edi_inventory.delivery_center_name_alt%TYPE,
                --�q�ɃR�[�h
    whse_code                        xxcos_edi_inventory.whse_code%TYPE,
                --�q�ɖ�
    whse_name                        xxcos_edi_inventory.whse_name%TYPE,
                --���i�S���Җ��i�����j
    inspect_charge_name              xxcos_edi_inventory.inspect_charge_name%TYPE,
                --���i�S���Җ��i�J�i�j
    inspect_charge_name_alt          xxcos_edi_inventory.inspect_charge_name_alt%TYPE,
                --�ԕi�S���Җ��i�����j
    return_charge_name               xxcos_edi_inventory.return_charge_name%TYPE,
                --�ԕi�S���Җ��i�J�i�j
    return_charge_name_alt           xxcos_edi_inventory.return_charge_name_alt%TYPE,
                --��̒S���Җ��i�����j
    receive_charge_name              xxcos_edi_inventory.receive_charge_name%TYPE,
                --��̒S���Җ��i�J�i�j
    receive_charge_name_alt          xxcos_edi_inventory.receive_charge_name_alt%TYPE,
                -- ������
    order_date                       xxcos_edi_inventory.order_date%TYPE,
                -- �Z���^�[�[�i��
    center_delivery_date             xxcos_edi_inventory.center_delivery_date%TYPE,
                --�Z���^�[���[�i��
    center_result_delivery_date      xxcos_edi_inventory.center_result_delivery_date%TYPE,
                --�Z���^�[�o�ɓ�
    center_shipping_date             xxcos_edi_inventory.center_shipping_date%TYPE,
                --�Z���^�[���o�ɓ�
    center_result_shipping_date      xxcos_edi_inventory.center_result_shipping_date%TYPE,
                -- �f�[�^�쐬���i�d�c�h�f�[�^���j
    data_creation_date_edi_data      xxcos_edi_inventory.data_creation_date_edi_data%TYPE,
                -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
    data_creation_time_edi_data      xxcos_edi_inventory.data_creation_time_edi_data%TYPE,
                --�݌ɓ��t
    stk_date                         xxcos_edi_inventory.stk_date%TYPE,
                --�񋟊�Ǝ����R�[�h�敪
    offer_vendor_code_class          xxcos_edi_inventory.offer_vendor_code_class%TYPE,
                --�q�Ɏ����R�[�h�敪
    whse_vendor_code_class           xxcos_edi_inventory.whse_vendor_code_class%TYPE,
                --�񋟃T�C�N���敪
    offer_cycle_class                xxcos_edi_inventory.offer_cycle_class%TYPE,
                --�݌Ɏ��
    stk_type                         xxcos_edi_inventory.stk_type%TYPE,
                --���{��敪
    japanese_class                   xxcos_edi_inventory.japanese_class%TYPE,
                --�q�ɋ敪
    whse_class                       xxcos_edi_inventory.whse_class%TYPE,
                -- �����R�[�h
    vendor_code                      xxcos_edi_inventory.vendor_code%TYPE,
                -- ����於�i�����j
    vendor_name                      xxcos_edi_inventory.vendor_name%TYPE,
                -- ����於�i�J�i�j
    vendor_name_alt                  xxcos_edi_inventory.vendor_name_alt%TYPE,
                -- �`�F�b�N�f�W�b�g�L���敪
    check_digit_class                xxcos_edi_inventory.check_digit_class%TYPE,
                -- �`�[�ԍ�
    invoice_number                   xxcos_edi_inventory.invoice_number%TYPE,
                -- �`�F�b�N�f�W�b�g
    check_digit                      xxcos_edi_inventory.check_digit%TYPE,
                -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
    chain_peculiar_area_header       xxcos_edi_inventory.chain_peculiar_area_header%TYPE,
                -- ���i�R�[�h�i�ɓ����j
    product_code_itouen              xxcos_edi_inventory.product_code_itouen%TYPE,
                --���i�R�[�h�i����j
    product_code_other_party         xxcos_edi_inventory.product_code_other_party%TYPE,
                -- �i�`�m�R�[�h
    jan_code                         xxcos_edi_inventory.jan_code%TYPE,
                -- �h�s�e�R�[�h
    itf_code                         xxcos_edi_inventory.itf_code%TYPE,
                -- ���i���i�����j
    product_name                     xxcos_edi_inventory.product_name%TYPE,
                -- ���i���i�J�i�j
    product_name_alt                 xxcos_edi_inventory.product_name_alt%TYPE,
                -- ���i�敪
    prod_class                       xxcos_edi_inventory.prod_class%TYPE,
                -- �K�p�i���敪
    active_quality_class             xxcos_edi_inventory.active_quality_class%TYPE,
                -- ����
    qty_in_case                      xxcos_edi_inventory.qty_in_case%TYPE,
                -- �P��
    uom_code                         xxcos_edi_inventory.uom_code%TYPE,
                -- ������Ϗo�א���
    day_average_shipping_qty         xxcos_edi_inventory.day_average_shipping_qty%TYPE,
                -- �݌Ɏ�ʃR�[�h
    stk_type_code                    xxcos_edi_inventory.stk_type_code%TYPE,
                -- �ŏI���ד�
    last_arrival_date                xxcos_edi_inventory.last_arrival_date%TYPE,
                -- �ܖ�����
    use_by_date                      xxcos_edi_inventory.use_by_date%TYPE,
                -- ������
    product_date                     xxcos_edi_inventory.product_date%TYPE,
                -- ����݌Ɂi�P�[�X�j
    upper_limit_stk_case             xxcos_edi_inventory.upper_limit_stk_case%TYPE,
                -- ����݌Ɂi�o���j
    upper_limit_stk_indv             xxcos_edi_inventory.upper_limit_stk_indv%TYPE,
                -- �����_�i�o���j 
    indv_order_point                 xxcos_edi_inventory.indv_order_point%TYPE,
                -- �����_�i�P�[�X�j
    case_order_point                 xxcos_edi_inventory.case_order_point%TYPE,
                -- �O�����݌ɐ��ʁi�o���j
    indv_prev_month_stk_qty          xxcos_edi_inventory.indv_prev_month_stk_qty%TYPE,
                -- �O�����݌ɐ��ʁi�P�[�X�j
    case_prev_month_stk_qty          xxcos_edi_inventory.case_prev_month_stk_qty%TYPE,
                -- �O���݌ɐ��ʁi���v�j 
    sum_prev_month_stk_qty           xxcos_edi_inventory.sum_prev_month_stk_qty%TYPE,
                -- �������ʁi�����A�o���j
    day_indv_order_qty               xxcos_edi_inventory.day_indv_order_qty%TYPE,
                -- �������ʁi�����A�P�[�X�j
    day_case_order_qty               xxcos_edi_inventory.day_case_order_qty%TYPE,
                -- �������ʁi�����A���v�j
    day_sum_order_qty                xxcos_edi_inventory.day_sum_order_qty%TYPE,
                -- �������ʁi�����A�o���j
    month_indv_order_qty             xxcos_edi_inventory.month_indv_order_qty%TYPE,
                -- �������ʁi�����A�P�[�X�j
    month_case_order_qty             xxcos_edi_inventory.month_case_order_qty%TYPE,
                -- �������ʁi�����A���v�j
    month_sum_order_qty              xxcos_edi_inventory.month_sum_order_qty%TYPE,
                -- ���ɐ��ʁi�����A�o���j
    day_indv_arrival_qty             xxcos_edi_inventory.day_indv_arrival_qty%TYPE,
                -- ���ɐ��ʁi�����A�P�[�X�j
    day_case_arrival_qty             xxcos_edi_inventory.day_case_arrival_qty%TYPE,
                -- ���ɐ��ʁi�����A���v�j
    day_sum_arrival_qty              xxcos_edi_inventory.day_sum_arrival_qty%TYPE,
                -- �������׉�         
    month_arrival_count              xxcos_edi_inventory.month_arrival_count%TYPE,
                -- ���ɐ��ʁi�����A�o���j
    month_indv_arrival_qty           xxcos_edi_inventory.month_indv_arrival_qty%TYPE,
                -- ���ɐ��ʁi�����A�P�[�X�j
    month_case_arrival_qty           xxcos_edi_inventory.month_case_arrival_qty%TYPE,
                -- ���ɐ��ʁi�����A���v�j
    month_sum_arrival_qty            xxcos_edi_inventory.month_sum_arrival_qty%TYPE,
                -- �o�ɐ��ʁi�����A�o���j
    day_indv_shipping_qty            xxcos_edi_inventory_work.day_indv_shipping_qty%TYPE,
                -- �o�ɐ��ʁi�����A�P�[�X�j
    day_case_shipping_qty            xxcos_edi_inventory.day_case_shipping_qty%TYPE,
                -- �o�ɐ��ʁi�����A���v�j
    day_sum_shipping_qty             xxcos_edi_inventory.day_sum_shipping_qty%TYPE,
                -- �o�ɐ��ʁi�����A�o���j
    month_indv_shipping_qty          xxcos_edi_inventory.month_indv_shipping_qty%TYPE,
                -- �o�ɐ��ʁi�����A�P�[�X�j
    month_case_shipping_qty          xxcos_edi_inventory.month_case_shipping_qty%TYPE,
                -- �o�ɐ��ʁi�����A���v�j
    month_sum_shipping_qty           xxcos_edi_inventory.month_sum_shipping_qty%TYPE,
                -- �j���A���X���ʁi�����A�o���j
    day_indv_destroy_loss_qty        xxcos_edi_inventory.day_indv_destroy_loss_qty%TYPE,
                -- �j���A���X���ʁi�����A�P�[�X�j
    day_case_destroy_loss_qty        xxcos_edi_inventory.day_case_destroy_loss_qty%TYPE,
                -- �j���A���X���ʁi�����A���v�j
    day_sum_destroy_loss_qty         xxcos_edi_inventory.day_sum_destroy_loss_qty%TYPE,
                -- �j���A���X���ʁi�����A�o���j
    month_indv_destroy_loss_qty      xxcos_edi_inventory.month_indv_destroy_loss_qty%TYPE,
                -- �j���A���X���ʁi�����A�P�[�X�j
    month_case_destroy_loss_qty      xxcos_edi_inventory.month_case_destroy_loss_qty%TYPE,
                -- �j���A���X���ʁi�����A���v�j
    month_sum_destroy_loss_qty       xxcos_edi_inventory.month_sum_destroy_loss_qty%TYPE,
                -- �s�Ǎ݌ɐ��ʁi�����A�o���j
    day_indv_defect_stk_qty          xxcos_edi_inventory.day_indv_defect_stk_qty%TYPE,
                -- �s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
    day_case_defect_stk_qty          xxcos_edi_inventory.day_case_defect_stk_qty%TYPE,
                -- �s�Ǎ݌ɐ��ʁi�����A���v�j
    day_sum_defect_stk_qty           xxcos_edi_inventory.day_sum_defect_stk_qty%TYPE,
                -- �s�Ǎ݌ɐ��ʁi�����A�o���j
    month_indv_defect_stk_qty        xxcos_edi_inventory.month_indv_defect_stk_qty%TYPE,
                -- �s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
    month_case_defect_stk_qty        xxcos_edi_inventory.month_case_defect_stk_qty%TYPE,
                -- �s�Ǎ݌ɐ��ʁi�����A���v�j
    month_sum_defect_stk_qty         xxcos_edi_inventory.month_sum_defect_stk_qty%TYPE,
                -- �s�Ǖԕi���ʁi�����A�o���j
    day_indv_defect_return_qty       xxcos_edi_inventory.day_indv_defect_return_qty%TYPE,
                -- �s�Ǖԕi���ʁi�����A�P�[�X�j
    day_case_defect_return_qty       xxcos_edi_inventory.day_case_defect_return_qty%TYPE,
                -- �s�Ǖԕi���ʁi�����A���v�j
    day_sum_defect_return_qty        xxcos_edi_inventory.day_sum_defect_return_qty%TYPE,
                -- �s�Ǖԕi���ʁi�����A�o���j
    month_indv_defect_return_qty     xxcos_edi_inventory.month_indv_defect_return_qty%TYPE,
                -- �s�Ǖԕi���ʁi�����A�P�[�X�j
    month_case_defect_return_qty     xxcos_edi_inventory.month_case_defect_return_qty%TYPE,
                -- �s�Ǖԕi���ʁi�����A���v�j
    month_sum_defect_return_qty      xxcos_edi_inventory.month_sum_defect_return_qty%TYPE,
                -- �s�Ǖԕi����i�����A�o���j
    day_indv_defect_return_rcpt      xxcos_edi_inventory.day_indv_defect_return_rcpt%TYPE,
                -- �s�Ǖԕi����i�����A�P�[�X�j
    day_case_defect_return_rcpt      xxcos_edi_inventory.day_case_defect_return_rcpt%TYPE,
                -- �s�Ǖԕi����i�����A���v�j
    day_sum_defect_return_rcpt       xxcos_edi_inventory.day_sum_defect_return_rcpt%TYPE,
                -- �s�Ǖԕi����i�����A�o���j
    month_indv_defect_return_rcpt      xxcos_edi_inventory.month_indv_defect_return_rcpt%TYPE,
                -- �s�Ǖԕi����i�����A�P�[�X�j
    month_case_defect_return_rcpt      xxcos_edi_inventory.month_case_defect_return_rcpt%TYPE,
                -- �s�Ǖԕi����i�����A���v�j
    month_sum_defect_return_rcpt       xxcos_edi_inventory.month_sum_defect_return_rcpt%TYPE,
                -- �s�Ǖԕi�����i�����A�o���j
    day_indv_defect_return_send        xxcos_edi_inventory.day_indv_defect_return_send%TYPE,
                -- �s�Ǖԕi�����i�����A�P�[�X�j
    day_case_defect_return_send        xxcos_edi_inventory.day_case_defect_return_send%TYPE,
                -- �s�Ǖԕi�����i�����A���v�j
    day_sum_defect_return_send         xxcos_edi_inventory.day_sum_defect_return_send%TYPE,
                -- �s�Ǖԕi�����i�����A�o���j
    month_indv_defect_return_send      xxcos_edi_inventory.month_indv_defect_return_send%TYPE,
                -- �s�Ǖԕi�����i�����A�P�[�X�j
    month_case_defect_return_send      xxcos_edi_inventory.month_case_defect_return_send%TYPE,
                -- �s�Ǖԕi�����i�����A���v�j
    month_sum_defect_return_send       xxcos_edi_inventory.month_sum_defect_return_send%TYPE,
                -- �Ǖi�ԕi����i�����A�o���j
    day_indv_quality_return_rcpt       xxcos_edi_inventory.day_indv_quality_return_rcpt%TYPE,
                -- �Ǖi�ԕi����i�����A�P�[�X�j
    day_case_quality_return_rcpt       xxcos_edi_inventory.day_case_quality_return_rcpt%TYPE,
                -- �Ǖi�ԕi����i�����A���v�j
    day_sum_quality_return_rcpt        xxcos_edi_inventory.day_sum_quality_return_rcpt%TYPE,
                -- �Ǖi�ԕi����i�����A�o���j
    month_indv_quality_return_rcpt     xxcos_edi_inventory.month_indv_quality_return_rcpt%TYPE,
                -- �Ǖi�ԕi����i�����A�P�[�X�j
    month_case_quality_return_rcpt     xxcos_edi_inventory.month_case_quality_return_rcpt%TYPE,
                -- �Ǖi�ԕi����i�����A���v�j
    month_sum_quality_return_rcpt      xxcos_edi_inventory.month_sum_quality_return_rcpt%TYPE,
                -- �Ǖi�ԕi�����i�����A�o���j
    day_indv_quality_return_send       xxcos_edi_inventory.day_indv_quality_return_send%TYPE,
                -- �Ǖi�ԕi�����i�����A�P�[�X�j
    day_case_quality_return_send       xxcos_edi_inventory.day_case_quality_return_send%TYPE,
                -- �Ǖi�ԕi�����i�����A���v�j
    day_sum_quality_return_send        xxcos_edi_inventory.day_sum_quality_return_send%TYPE,
                -- �Ǖi�ԕi�����i�����A�o���j
    month_indv_quality_return_send     xxcos_edi_inventory.month_indv_quality_return_send%TYPE,
                -- �Ǖi�ԕi�����i�����A�P�[�X�j
    month_case_quality_return_send     xxcos_edi_inventory.month_case_quality_return_send%TYPE,
                -- �Ǖi�ԕi�����i�����A���v�j
    month_sum_quality_return_send      xxcos_edi_inventory.month_sum_quality_return_send%TYPE,
                -- �I�����فi�����A�o���j
    day_indv_invent_difference         xxcos_edi_inventory.day_indv_invent_difference%TYPE,
                -- �I�����فi�����A�P�[�X�j
    day_case_invent_difference         xxcos_edi_inventory.day_case_invent_difference%TYPE,
                -- �I�����فi�����A���v�j
    day_sum_invent_difference          xxcos_edi_inventory.day_sum_invent_difference%TYPE,
                -- �I�����فi�����A�o���j
    month_indv_invent_difference       xxcos_edi_inventory.month_indv_invent_difference%TYPE,
                -- �I�����فi�����A�P�[�X�j
    month_case_invent_difference       xxcos_edi_inventory.month_case_invent_difference%TYPE,
                -- �I�����فi�����A���v�j 
    month_sum_invent_difference        xxcos_edi_inventory.month_sum_invent_difference%TYPE,
                -- �݌ɐ��ʁi�����A�o���j 
    day_indv_stk_qty                   xxcos_edi_inventory.day_indv_stk_qty%TYPE,
                -- �݌ɐ��ʁi�����A�P�[�X�j
    day_case_stk_qty                   xxcos_edi_inventory.day_case_stk_qty%TYPE,
                -- �݌ɐ��ʁi�����A���v�j 
    day_sum_stk_qty                    xxcos_edi_inventory.day_sum_stk_qty%TYPE,
                -- �݌ɐ��ʁi�����A�o���j 
    month_indv_stk_qty                 xxcos_edi_inventory.month_indv_stk_qty%TYPE,
                -- �݌ɐ��ʁi�����A�P�[�X�j
    month_case_stk_qty                 xxcos_edi_inventory.month_case_stk_qty%TYPE,
                -- �݌ɐ��ʁi�����A���v�j 
    month_sum_stk_qty                  xxcos_edi_inventory.month_sum_stk_qty%TYPE,
                -- �ۗ��݌ɐ��i�����A�o���j
    day_indv_reserved_stk_qty          xxcos_edi_inventory.day_indv_reserved_stk_qty%TYPE,
                -- �ۗ��݌ɐ��i�����A�P�[�X�j
    day_case_reserved_stk_qty          xxcos_edi_inventory.day_case_reserved_stk_qty%TYPE,
                -- �ۗ��݌ɐ��i�����A���v�j 
    day_sum_reserved_stk_qty           xxcos_edi_inventory.day_sum_reserved_stk_qty%TYPE,
                -- �ۗ��݌ɐ��i�����A�o���j 
    month_indv_reserved_stk_qty        xxcos_edi_inventory.month_indv_reserved_stk_qty%TYPE,
                -- �ۗ��݌ɐ��i�����A�P�[�X�j
    month_case_reserved_stk_qty        xxcos_edi_inventory.month_case_reserved_stk_qty%TYPE,
                -- �ۗ��݌ɐ��i�����A���v�j
    month_sum_reserved_stk_qty         xxcos_edi_inventory.month_sum_reserved_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�o���j
    day_indv_cd_stk_qty                xxcos_edi_inventory.day_indv_cd_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�P�[�X�j
    day_case_cd_stk_qty                xxcos_edi_inventory.day_case_cd_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A���v�j
    day_sum_cd_stk_qty                 xxcos_edi_inventory.day_sum_cd_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�o���j 
    month_indv_cd_stk_qty              xxcos_edi_inventory.month_indv_cd_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�P�[�X�j
    month_case_cd_stk_qty              xxcos_edi_inventory.month_case_cd_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A���v�j
    month_sum_cd_stk_qty               xxcos_edi_inventory.month_sum_cd_stk_qty%TYPE,
                -- �ϑ��݌ɐ��ʁi�����A�o���j 
    day_indv_cargo_stk_qty             xxcos_edi_inventory.day_indv_cargo_stk_qty%TYPE,
                -- �ϑ��݌ɐ��ʁi�����A�P�[�X�j
    day_case_cargo_stk_qty             xxcos_edi_inventory.day_case_cargo_stk_qty%TYPE,
                -- �ϑ��݌ɐ��ʁi�����A���v�j
    day_sum_cargo_stk_qty              xxcos_edi_inventory.day_sum_cargo_stk_qty%TYPE,
                -- �ϑ��݌ɐ��ʁi�����A�o���j 
    month_indv_cargo_stk_qty           xxcos_edi_inventory.month_indv_cargo_stk_qty%TYPE,
                -- �ϑ��݌ɐ��ʁi�����A�P�[�X�j
    month_case_cargo_stk_qty           xxcos_edi_inventory.month_case_cargo_stk_qty%TYPE,
                -- �ϑ��݌ɐ��ʁi�����A���v�j 
    month_sum_cargo_stk_qty            xxcos_edi_inventory.month_sum_cargo_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�o���j 
    day_indv_adjustment_stk_qty        xxcos_edi_inventory.day_indv_adjustment_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�P�[�X�j
    day_case_adjustment_stk_qty        xxcos_edi_inventory.day_case_adjustment_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A���v�j 
    day_sum_adjustment_stk_qty         xxcos_edi_inventory.day_sum_adjustment_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�o���j 
    month_indv_adjustment_stk_qty      xxcos_edi_inventory.month_indv_adjustment_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A�P�[�X�j
    month_case_adjustment_stk_qty      xxcos_edi_inventory.month_case_adjustment_stk_qty%TYPE,
                -- �����݌ɐ��ʁi�����A���v�j 
    month_sum_adjustment_stk_qty       xxcos_edi_inventory.month_sum_adjustment_stk_qty%TYPE,
                -- ���o�א��ʁi�����A�o���j  
    day_indv_still_shipping_qty        xxcos_edi_inventory.day_indv_still_shipping_qty%TYPE,
                -- ���o�א��ʁi�����A�P�[�X�j
    day_case_still_shipping_qty        xxcos_edi_inventory.day_case_still_shipping_qty%TYPE,
                -- ���o�א��ʁi�����A���v�j  
    day_sum_still_shipping_qty         xxcos_edi_inventory.day_sum_still_shipping_qty%TYPE,
                -- ���o�א��ʁi�����A�o���j   
    month_indv_still_shipping_qty      xxcos_edi_inventory.month_indv_still_shipping_qty%TYPE,
                -- ���o�א��ʁi�����A�P�[�X�j 
    month_case_still_shipping_qty      xxcos_edi_inventory.month_case_still_shipping_qty%TYPE,
                -- ���o�א��ʁi�����A���v�j 
    month_sum_still_shipping_qty       xxcos_edi_inventory.month_sum_still_shipping_qty%TYPE,
                -- ���݌ɐ��ʁi�o���j      
    indv_all_stk_qty                   xxcos_edi_inventory.indv_all_stk_qty%TYPE,
                -- ���݌ɐ��ʁi�P�[�X�j
    case_all_stk_qty                   xxcos_edi_inventory.case_all_stk_qty%TYPE,
                -- ���݌ɐ��ʁi���v�j       
    sum_all_stk_qty                    xxcos_edi_inventory.sum_all_stk_qty%TYPE,
                -- ����������               
    month_draw_count                   xxcos_edi_inventory.month_draw_count%TYPE,
                -- �����\���ʁi�����A�o���j 
    day_indv_draw_possible_qty         xxcos_edi_inventory.day_indv_draw_possible_qty%TYPE,
                -- �����\���ʁi�����A�P�[�X�j
    day_case_draw_possible_qty         xxcos_edi_inventory.day_case_draw_possible_qty%TYPE,
                -- �����\���ʁi�����A���v�j
    day_sum_draw_possible_qty          xxcos_edi_inventory.day_sum_draw_possible_qty%TYPE,
                -- �����\���ʁi�����A�o���j 
    month_indv_draw_possible_qty       xxcos_edi_inventory.month_indv_draw_possible_qty%TYPE,
                -- �����\���ʁi�����A�P�[�X�j
    month_case_draw_possible_qty       xxcos_edi_inventory.month_case_draw_possible_qty%TYPE,
                -- �����\���ʁi�����A���v�j 
    month_sum_draw_possible_qty        xxcos_edi_inventory.month_sum_draw_possible_qty%TYPE,
                -- �����s�\���i�����A�o���j  
    day_indv_draw_impossible_qty       xxcos_edi_inventory.day_indv_draw_impossible_qty%TYPE,
                -- �����s�\���i�����A�P�[�X�j 
    day_case_draw_impossible_qty       xxcos_edi_inventory.day_case_draw_impossible_qty%TYPE,
                -- �����s�\���i�����A���v�j 
    day_sum_draw_impossible_qty        xxcos_edi_inventory.day_sum_draw_impossible_qty%TYPE,
                -- �݌ɋ��z�i�����j      
    day_stk_amt                        xxcos_edi_inventory.day_stk_amt%TYPE,
                -- �݌ɋ��z�i�����j       
    month_stk_amt                      xxcos_edi_inventory.month_stk_amt%TYPE,
                -- ���l                       
    remarks                            xxcos_edi_inventory.remarks%TYPE,
                -- �`�F�[���X�ŗL�G���A�i���ׁj
    chain_peculiar_area_line           xxcos_edi_inventory.chain_peculiar_area_line%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j  
    invoice_day_indv_sum_stk_qty       xxcos_edi_inventory.invoice_day_indv_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
    invoice_day_case_sum_stk_qty       xxcos_edi_inventory.invoice_day_case_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j  
    invoice_day_sum_sum_stk_qty        xxcos_edi_inventory.invoice_day_sum_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j  
    invoice_month_indv_sum_stk_qty     xxcos_edi_inventory.invoice_month_indv_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
    invoice_month_case_sum_stk_qty     xxcos_edi_inventory.invoice_month_case_sum_stk_qty%TYPE,
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j  
    invoice_month_sum_sum_stk_qty      xxcos_edi_inventory.invoice_month_sum_sum_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j 
    invoice_day_indv_cd_stk_qty        xxcos_edi_inventory.invoice_day_indv_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
    invoice_day_case_cd_stk_qty        xxcos_edi_inventory.invoice_day_case_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j  
    invoice_day_sum_cd_stk_qty         xxcos_edi_inventory.invoice_day_sum_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j  
    invoice_month_indv_cd_stk_qty      xxcos_edi_inventory.invoice_month_indv_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
    invoice_month_case_cd_stk_qty      xxcos_edi_inventory.invoice_month_case_cd_stk_qty%TYPE,
                -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j  
    invoice_month_sum_cd_stk_qty       xxcos_edi_inventory.invoice_month_sum_cd_stk_qty%TYPE,
                -- �`�[�v�j�݌ɋ��z�i�����j            
    invoice_day_stk_amt                xxcos_edi_inventory.invoice_day_stk_amt%TYPE,
                -- �`�[�v�j�݌ɋ��z�i�����j            
    invoice_month_stk_amt              xxcos_edi_inventory.invoice_month_stk_amt%TYPE,
                -- ���̋��z���v                        
    regular_sell_amt_sum               xxcos_edi_inventory.regular_sell_amt_sum%TYPE,
                -- ���߂����z���v                      
    rebate_amt_sum                     xxcos_edi_inventory.rebate_amt_sum%TYPE,
                -- ����e����z���v                   
    collect_bottle_amt_sum             xxcos_edi_inventory.collect_bottle_amt_sum%TYPE,
                -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j    
    chain_peculiar_area_footer         xxcos_edi_inventory.chain_peculiar_area_footer%TYPE,
                -- �ڋq�R�[�h(�ϊ���ڋq�R�[�h)
    conv_customer_code                 xxcos_edi_inventory.conv_customer_code%TYPE,
                -- �i�ڃR�[�h
    item_code                          xxcos_edi_inventory.item_code%TYPE,
                -- �P�ʃR�[�h�iEBS�j
    ebs_uom_code                       xxcos_edi_inventory.ebs_uom_code%TYPE
  );
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  -- EDI�݌ɏ��f�[�^ �e�[�u���^
  TYPE g_req_edi_inv_data_ttype IS TABLE OF g_req_edi_inv_data_rtype INDEX BY BINARY_INTEGER;
  gt_req_edi_inv_data  g_req_edi_inv_data_ttype;
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
  --* -------------------------------------------------------------------------------------------
    IF  ( iv_file_name  IS NULL ) THEN                 -- �C���^�t�F�[�X�t�@�C������NULL 
      -- �C���^�t�F�[�X�t�@�C����
      gv_in_file_name    :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  cv_msg_in_file_name
                         );
      lv_retcode        :=  cv_status_error;
      lv_errmsg         :=  xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_application,
                         iv_name               =>  gv_msg_in_param_none_err,
                         iv_token_name1        =>  cv_tkn_in_param,
                         iv_token_value1       =>  gv_in_file_name
                         );
    END IF;
    --* -------------------------------------------------------------------------------------------
    --�G���[�̏ꍇ�A���f������B
    IF  ( lv_retcode    <>  cv_status_normal )  THEN
      RAISE   global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --* -------------------------------------------------------------------------------------------
    IF  ( iv_run_class  IS NULL ) THEN                 -- ���s�敪�̃p�����^��NULL 
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
    ELSIF (( iv_run_class  =   gv_run_class_name1 )        -- ���s�敪�F�u�V�K�v
    OR     ( iv_run_class  =   gv_run_class_name2 ))       -- ���s�敪�F�u�Ď��{�v
    THEN
      NULL;
    ELSE
      -- ���s�敪
      gv_in_param       :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  cv_msg_in_param
                        );
      lv_retcode       :=  cv_status_error;
      lv_errmsg        :=  xxccp_common_pkg.get_msg(
                       iv_application        =>  cv_application,
                       iv_name               =>  gv_msg_in_param_err,
                       iv_token_name1        =>  cv_tkn_in_param,
                       iv_token_value1       =>  gv_in_param
                       );
    END IF;
    --* -------------------------------------------------------------------------------------------
    --�G���[�̏ꍇ�A���f������B
    IF  ( lv_retcode     <>  cv_status_normal )  THEN
      RAISE   global_api_expt;
    END IF;
    --* -------------------------------------------------------------------------------------------
    --==================================
    -- 2-1. EDI���폜���Ԃ̎擾
    --==================================
    gv_prf_edi_del_date :=  FND_PROFILE.VALUE( cv_prf_edi_del_date );
    -- 
    IF  ( gv_prf_edi_del_date  IS NULL )   THEN
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
    gv_prf_orga_code    :=  FND_PROFILE.VALUE( cv_prf_orga_code1 );
    --
    IF  ( gv_prf_orga_code     IS NULL )   THEN
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
    IF  ( gv_prf_orga_id       IS NULL )   THEN
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
   * Procedure Name   : xxcos_in_invoice_num_add
   * Description      : �`�[�ʍ��v�ϐ��ւ̒ǉ�(A-4)(1)
   ***********************************************************************************/
  PROCEDURE xxcos_in_invoice_num_add(
    in_line_cnt1  IN NUMBER,       --   LOOP�p�J�E���^1
    in_line_cnt2  IN NUMBER,       --   LOOP�p�J�E���^2
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_invoice_num_add'; -- �v���O������
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
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j  
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_indv_sum_stk_qty    := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_indv_stk_qty, 0);
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_case_sum_stk_qty    := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_case_stk_qty, 0);
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_sum_sum_stk_qty     := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_sum_stk_qty, 0);
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_indv_sum_stk_qty  := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_indv_stk_qty, 0);
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_case_sum_stk_qty  := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_case_stk_qty, 0);
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_sum_sum_stk_qty   := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_sum_stk_qty, 0);
                -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_indv_cd_stk_qty     := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_indv_cd_stk_qty, 0);
                -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_case_cd_stk_qty     := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_case_cd_stk_qty, 0);
                -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_sum_cd_stk_qty      := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_sum_cd_stk_qty, 0);
                -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_indv_cd_stk_qty   := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_indv_cd_stk_qty, 0);
                -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_case_cd_stk_qty   := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_case_cd_stk_qty, 0);
                -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_sum_cd_stk_qty    := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_sum_cd_stk_qty, 0);
                -- �`�[�v�j�݌ɋ��z�i�����j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_stk_amt             := 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_stk_amt, 0);
                -- �`�[�v�j�݌ɋ��z�i�����j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_stk_amt           := 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_stk_amt, 0);
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
  END xxcos_in_invoice_num_add;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_invoice_num_req
   * Description      : �`�[�ʍ��v�ϐ��ւ̍ĕҏW(A-4)(2)
   ***********************************************************************************/
  PROCEDURE xxcos_in_invoice_num_req(
    in_line_cnt    IN NUMBER,       --   LOOP�p�J�E���^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_invoice_num_req'; -- �v���O������
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
    ln_count  NUMBER  DEFAULT 1;
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
    --==============================================================
    -- �`�[�ԍ����ɏW�v�����`�[�v���ĕҏW����B
    --==============================================================
    <<xxcos_edi_inventory_req>>
    FOR  ln_no  IN  1..gn_normal_cnt  LOOP
      IF  ( ln_count > in_line_cnt ) THEN
        NULL;
      ELSE
        -- �w�b�_�Ɩ��ׂ̓`�[�ԍ����قȂ�ꍇ
        IF  ( gt_req_edi_inv_data(ln_no).invoice_number  <> 
              gt_sum_edi_inv_data(ln_count).invoice_number )
        THEN
          --�w�b�_�f�[�^�̓Y�����J�E���g�A�b�v����
          ln_count  :=  ln_count  +  1;
        END IF;
              -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j  
        gt_req_edi_inv_data(ln_no).invoice_day_indv_sum_stk_qty    := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_indv_sum_stk_qty, 0);
              -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
        gt_req_edi_inv_data(ln_no).invoice_day_case_sum_stk_qty    := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_case_sum_stk_qty, 0);
              -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j  
        gt_req_edi_inv_data(ln_no).invoice_day_sum_sum_stk_qty     := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_sum_sum_stk_qty, 0);
              -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j  
        gt_req_edi_inv_data(ln_no).invoice_month_indv_sum_stk_qty  := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_indv_sum_stk_qty, 0);
              -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
        gt_req_edi_inv_data(ln_no).invoice_month_case_sum_stk_qty  := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_case_sum_stk_qty, 0);
              -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j  
        gt_req_edi_inv_data(ln_no).invoice_month_sum_sum_stk_qty   := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_sum_sum_stk_qty, 0);
              -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j 
        gt_req_edi_inv_data(ln_no).invoice_day_indv_cd_stk_qty     := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_indv_cd_stk_qty, 0);
              -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
        gt_req_edi_inv_data(ln_no).invoice_day_case_cd_stk_qty     := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_case_cd_stk_qty, 0);
              -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j  
        gt_req_edi_inv_data(ln_no).invoice_day_sum_cd_stk_qty      := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_sum_cd_stk_qty, 0);
              -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j  
        gt_req_edi_inv_data(ln_no).invoice_month_indv_cd_stk_qty   := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_indv_cd_stk_qty, 0);
              -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
        gt_req_edi_inv_data(ln_no).invoice_month_case_cd_stk_qty   := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_case_cd_stk_qty, 0);
              -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j  
        gt_req_edi_inv_data(ln_no).invoice_month_sum_cd_stk_qty    := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_sum_cd_stk_qty, 0);
              -- �`�[�v�j�݌ɋ��z�i�����j            
        gt_req_edi_inv_data(ln_no).invoice_day_stk_amt             := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_day_stk_amt, 0);
              -- �`�[�v�j�݌ɋ��z�i�����j            
        gt_req_edi_inv_data(ln_no).invoice_month_stk_amt           := 
              NVL(gt_sum_edi_inv_data(ln_count).invoice_month_stk_amt, 0);
      END IF;
-- 
    END LOOP  xxcos_edi_inventory_req;
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
  END xxcos_in_invoice_num_req;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_invoice_num_up
   * Description      : �`�[�ʍ��v�ϐ��֐��ʂ����Z(A-5)
   ***********************************************************************************/
  PROCEDURE xxcos_in_invoice_num_up(
    in_line_cnt1   IN NUMBER,       --   LOOP�p�J�E���^1
    in_line_cnt2   IN NUMBER,       --   LOOP�p�J�E���^2
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_invoice_num_up'; -- �v���O������
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
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_indv_sum_stk_qty    := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_indv_sum_stk_qty, 0)    + 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_indv_stk_qty, 0);
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_case_sum_stk_qty    := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_case_sum_stk_qty, 0)    +
                NVL(gt_ediinv_work_data(in_line_cnt2).day_case_stk_qty, 0);
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_sum_sum_stk_qty     := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_sum_sum_stk_qty, 0)     +
                NVL(gt_ediinv_work_data(in_line_cnt2).day_sum_stk_qty, 0);
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_indv_sum_stk_qty  := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_indv_sum_stk_qty, 0)  +
                NVL(gt_ediinv_work_data(in_line_cnt2).month_indv_stk_qty, 0);
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_case_sum_stk_qty  := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_case_sum_stk_qty, 0)  + 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_case_stk_qty, 0);
                -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_sum_sum_stk_qty   := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_sum_sum_stk_qty, 0)   +
                NVL(gt_ediinv_work_data(in_line_cnt2).month_sum_stk_qty, 0);
                -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_indv_cd_stk_qty     := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_indv_cd_stk_qty, 0)     +
                NVL(gt_ediinv_work_data(in_line_cnt2).day_indv_cd_stk_qty, 0);
                -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_case_cd_stk_qty     := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_case_cd_stk_qty, 0)     +
                NVL(gt_ediinv_work_data(in_line_cnt2).day_case_cd_stk_qty, 0);
                -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_sum_cd_stk_qty      := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_sum_cd_stk_qty, 0)      +
                NVL(gt_ediinv_work_data(in_line_cnt2).day_sum_cd_stk_qty, 0);
                -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_indv_cd_stk_qty   := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_indv_cd_stk_qty, 0)   +
                NVL(gt_ediinv_work_data(in_line_cnt2).month_indv_cd_stk_qty, 0);
                -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_case_cd_stk_qty   := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_case_cd_stk_qty, 0)   + 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_case_cd_stk_qty, 0);
                -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_sum_cd_stk_qty    := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_sum_cd_stk_qty, 0)    + 
                NVL(gt_ediinv_work_data(in_line_cnt2).month_sum_cd_stk_qty, 0);
                -- �`�[�v�j�݌ɋ��z�i�����j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_day_stk_amt             := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_day_stk_amt, 0)  + 
                NVL(gt_ediinv_work_data(in_line_cnt2).day_stk_amt, 0);
                -- �`�[�v�j�݌ɋ��z�i�����j
    gt_sum_edi_inv_data(in_line_cnt1).invoice_month_stk_amt           := 
                NVL(gt_sum_edi_inv_data(in_line_cnt1).invoice_month_stk_amt, 0)  +
                NVL(gt_ediinv_work_data(in_line_cnt2).month_stk_amt, 0);
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
  END xxcos_in_invoice_num_up;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_inventory_edit
   * Description      : EDI�݌ɏ��ϐ��̕ҏW(A-2)(1)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_inventory_edit(
    in_line_cnt     IN NUMBER,       --   LOOP�p�J�E���^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_inventory_edit'; -- �v���O������
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
    --* -------------------------------------------------------------------------------------------
    -- EDI�݌ɏ��e�[�u���f�[�^�o�^�p�ϐ�
    --* -------------------------------------------------------------------------------------------
                -- �}�̋敪
    gt_req_edi_inv_data(in_line_cnt).medium_class   := gt_ediinv_work_data(in_line_cnt).medium_class;
                -- �f�[�^��R�[�h
    gt_req_edi_inv_data(in_line_cnt).data_type_code := gt_ediinv_work_data(in_line_cnt).data_type_code;
                -- �t�@�C���m��
    gt_req_edi_inv_data(in_line_cnt).file_no        := gt_ediinv_work_data(in_line_cnt).file_no;
                -- ���敪
    gt_req_edi_inv_data(in_line_cnt).info_class     := gt_ediinv_work_data(in_line_cnt).info_class;
                -- ������
    gt_req_edi_inv_data(in_line_cnt).process_date   := gt_ediinv_work_data(in_line_cnt).process_date;
                -- ��������
    gt_req_edi_inv_data(in_line_cnt).process_time   := gt_ediinv_work_data(in_line_cnt).process_time;
                -- ���_�i����j�R�[�h
    gt_req_edi_inv_data(in_line_cnt).base_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).base_code;
                -- ���_���i�������j
    gt_req_edi_inv_data(in_line_cnt).base_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).base_name;
                -- ���_���i�J�i�j
    gt_req_edi_inv_data(in_line_cnt).base_name_alt       
                                        :=  gt_ediinv_work_data(in_line_cnt).base_name_alt;
                -- �������`�F�[���X�R�[�h 
    gt_req_edi_inv_data(in_line_cnt).edi_chain_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).edi_chain_code;
                -- �������`�F�[���X���i�����j
    gt_req_edi_inv_data(in_line_cnt).edi_chain_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).edi_chain_name;
                -- �������`�F�[���X���i�J�i�j
    gt_req_edi_inv_data(in_line_cnt).edi_chain_name_alt 
                                        :=  gt_ediinv_work_data(in_line_cnt).edi_chain_name_alt;
                -- ���[�R�[�h
    gt_req_edi_inv_data(in_line_cnt).report_code    
                                        :=  gt_ediinv_work_data(in_line_cnt).report_code;
                -- ���[�\����
    gt_req_edi_inv_data(in_line_cnt).report_show_name     
                                        :=  gt_ediinv_work_data(in_line_cnt).report_show_name;
                -- �ڋq�R�[�h
    gt_req_edi_inv_data(in_line_cnt).customer_code    
                                        :=  gt_ediinv_work_data(in_line_cnt).customer_code;
                -- �ڋq���i�����j
    gt_req_edi_inv_data(in_line_cnt).customer_name     
                                        :=  gt_ediinv_work_data(in_line_cnt).customer_name;
                -- �ڋq���i�J�i�j
    gt_req_edi_inv_data(in_line_cnt).customer_name_alt    
                                        :=  gt_ediinv_work_data(in_line_cnt).customer_name_alt;
                -- �ЃR�[�h
    gt_req_edi_inv_data(in_line_cnt).company_code     
                                        :=  gt_ediinv_work_data(in_line_cnt).company_code;
                -- �Ж��i�J�i�j
    gt_req_edi_inv_data(in_line_cnt).company_name_alt    
                                        :=  gt_ediinv_work_data(in_line_cnt).company_name_alt;
                -- �X�R�[�h 
    gt_req_edi_inv_data(in_line_cnt).shop_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).shop_code;
                -- �X���i�J�i�j
    gt_req_edi_inv_data(in_line_cnt).shop_name_alt      
                                        :=  gt_ediinv_work_data(in_line_cnt).shop_name_alt;
                -- �[���Z���^�[�R�[�h 
    gt_req_edi_inv_data(in_line_cnt).delivery_center_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).delivery_center_code;
                -- �[���Z���^�[���i�����j
    gt_req_edi_inv_data(in_line_cnt).delivery_center_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).delivery_center_name;
                -- �[���Z���^�[���i�J�i�j
    gt_req_edi_inv_data(in_line_cnt).delivery_center_name_alt     
                                        :=  gt_ediinv_work_data(in_line_cnt).delivery_center_name_alt;
                -- �q�ɃR�[�h 
    gt_req_edi_inv_data(in_line_cnt).whse_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).whse_code;
                -- �q�ɖ� 
    gt_req_edi_inv_data(in_line_cnt).whse_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).whse_name;
                -- ���i�S���Җ��i�����j
    gt_req_edi_inv_data(in_line_cnt).inspect_charge_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).inspect_charge_name;
                -- ���i�S���Җ��i�J�i�j
    gt_req_edi_inv_data(in_line_cnt).inspect_charge_name_alt      
                                        :=  gt_ediinv_work_data(in_line_cnt).inspect_charge_name_alt;
                -- �ԕi�S���Җ��i�����j
    gt_req_edi_inv_data(in_line_cnt).return_charge_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).return_charge_name;
                -- �ԕi�S���Җ��i�J�i�j
    gt_req_edi_inv_data(in_line_cnt).return_charge_name_alt      
                                        :=  gt_ediinv_work_data(in_line_cnt).return_charge_name_alt;
                -- ��̒S���Җ��i�����j
    gt_req_edi_inv_data(in_line_cnt).receive_charge_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).receive_charge_name;
                -- ��̒S���Җ��i�J�i�j
    gt_req_edi_inv_data(in_line_cnt).receive_charge_name_alt      
                                        :=  gt_ediinv_work_data(in_line_cnt).receive_charge_name_alt;
                -- ������ 
    gt_req_edi_inv_data(in_line_cnt).order_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).order_date;
                -- �Z���^�[�[�i��
    gt_req_edi_inv_data(in_line_cnt).center_delivery_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).center_delivery_date;
                -- �Z���^�[���[�i��
    gt_req_edi_inv_data(in_line_cnt).center_result_delivery_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).center_result_delivery_date;
                -- �Z���^�[�o�ɓ�
    gt_req_edi_inv_data(in_line_cnt).center_shipping_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).center_shipping_date;
                -- �Z���^�[���o�ɓ�
    gt_req_edi_inv_data(in_line_cnt).center_result_shipping_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).center_result_shipping_date;
                -- �f�[�^�쐬���i�������f�[�^���j
    gt_req_edi_inv_data(in_line_cnt).data_creation_date_edi_data      
                                        :=  gt_ediinv_work_data(in_line_cnt).data_creation_date_edi_data;
                -- �f�[�^�쐬�����i�������f�[�^���j
    gt_req_edi_inv_data(in_line_cnt).data_creation_time_edi_data     
                                        :=  gt_ediinv_work_data(in_line_cnt).data_creation_time_edi_data;
                -- �݌ɓ��t
    gt_req_edi_inv_data(in_line_cnt).stk_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).stk_date;
                -- �񋟊�Ǝ����R�[�h�敪
    gt_req_edi_inv_data(in_line_cnt).offer_vendor_code_class     
                                        :=  gt_ediinv_work_data(in_line_cnt).offer_vendor_code_class;
                -- �q�Ɏ����R�[�h�敪
    gt_req_edi_inv_data(in_line_cnt).whse_vendor_code_class      
                                        :=  gt_ediinv_work_data(in_line_cnt).whse_vendor_code_class;
                -- �񋟃T�C�N���敪
    gt_req_edi_inv_data(in_line_cnt).offer_cycle_class     
                                        :=  gt_ediinv_work_data(in_line_cnt).offer_cycle_class;
                -- �݌Ɏ��
    gt_req_edi_inv_data(in_line_cnt).stk_type     
                                        :=  gt_ediinv_work_data(in_line_cnt).stk_type;
                -- ���{��敪
    gt_req_edi_inv_data(in_line_cnt).japanese_class     
                                        :=  gt_ediinv_work_data(in_line_cnt).japanese_class;
                -- �q�ɋ敪
    gt_req_edi_inv_data(in_line_cnt).whse_class     
                                        :=  gt_ediinv_work_data(in_line_cnt).whse_class;
                -- �����R�[�h
    gt_req_edi_inv_data(in_line_cnt).vendor_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).vendor_code;
                -- ����於�i�����j
    gt_req_edi_inv_data(in_line_cnt).vendor_name      
                                        :=  gt_ediinv_work_data(in_line_cnt).vendor_name;
                -- ����於�i�J�i�j
    gt_req_edi_inv_data(in_line_cnt).vendor_name_alt     
                                        :=  gt_ediinv_work_data(in_line_cnt).vendor_name_alt;
                -- �`�F�b�N�f�W�b�g�L���敪
    gt_req_edi_inv_data(in_line_cnt).check_digit_class      
                                        :=  gt_ediinv_work_data(in_line_cnt).check_digit_class;
                -- �`�[�ԍ�
    gt_req_edi_inv_data(in_line_cnt).invoice_number      
                                        :=  gt_ediinv_work_data(in_line_cnt).invoice_number;
                -- �`�F�b�N�f�W�b�g
    gt_req_edi_inv_data(in_line_cnt).check_digit      
                                        :=  gt_ediinv_work_data(in_line_cnt).check_digit;
                -- �`�F�[���X�ŗL�G���A�i�w�b�_�j
    gt_req_edi_inv_data(in_line_cnt).chain_peculiar_area_header      
                                        :=  gt_ediinv_work_data(in_line_cnt).chain_peculiar_area_header;
                -- ���i�R�[�h�i�ɓ����j
    gt_req_edi_inv_data(in_line_cnt).product_code_itouen     
                                        :=  gt_ediinv_work_data(in_line_cnt).product_code_itouen;
                -- ���i�R�[�h�i����j
    gt_req_edi_inv_data(in_line_cnt).product_code_other_party     
                                        :=  gt_ediinv_work_data(in_line_cnt).product_code_other_party;
                -- �������R�[�h 
    gt_req_edi_inv_data(in_line_cnt).jan_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).jan_code;
                -- �������R�[�h 
    gt_req_edi_inv_data(in_line_cnt).itf_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).itf_code;
                -- ���i���i�����j
    gt_req_edi_inv_data(in_line_cnt).product_name     
                                        :=  gt_ediinv_work_data(in_line_cnt).product_name;
                -- ���i���i�J�i�j
    gt_req_edi_inv_data(in_line_cnt).product_name_alt     
                                        :=  gt_ediinv_work_data(in_line_cnt).product_name_alt;
                -- ���i�敪
    gt_req_edi_inv_data(in_line_cnt).prod_class      
                                        :=  gt_ediinv_work_data(in_line_cnt).prod_class;
                -- �K�p�i���敪
    gt_req_edi_inv_data(in_line_cnt).active_quality_class     
                                        :=  gt_ediinv_work_data(in_line_cnt).active_quality_class;
                -- ����
    gt_req_edi_inv_data(in_line_cnt).qty_in_case      
                                        :=  gt_ediinv_work_data(in_line_cnt).qty_in_case;
                -- �P��
    gt_req_edi_inv_data(in_line_cnt).uom_code      
                                        :=  gt_ediinv_work_data(in_line_cnt).uom_code;
                -- ������Ϗo�א���
    gt_req_edi_inv_data(in_line_cnt).day_average_shipping_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_average_shipping_qty;
                -- �݌Ɏ�ʃR�[�h
    gt_req_edi_inv_data(in_line_cnt).stk_type_code     
                                        :=  gt_ediinv_work_data(in_line_cnt).stk_type_code;
                -- �ŏI���ד�
    gt_req_edi_inv_data(in_line_cnt).last_arrival_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).last_arrival_date;
                -- �ܖ�����
    gt_req_edi_inv_data(in_line_cnt).use_by_date     
                                        :=  gt_ediinv_work_data(in_line_cnt).use_by_date;
                -- ������
    gt_req_edi_inv_data(in_line_cnt).product_date      
                                        :=  gt_ediinv_work_data(in_line_cnt).product_date;
                -- ����݌Ɂi�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).upper_limit_stk_case      
                                        :=  gt_ediinv_work_data(in_line_cnt).upper_limit_stk_case;
                -- ����݌Ɂi�o���j
    gt_req_edi_inv_data(in_line_cnt).upper_limit_stk_indv     
                                        :=  gt_ediinv_work_data(in_line_cnt).upper_limit_stk_indv;
                -- �����_�i�o���j
    gt_req_edi_inv_data(in_line_cnt).indv_order_point      
                                        :=  gt_ediinv_work_data(in_line_cnt).indv_order_point;
                -- �����_�i�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).case_order_point      
                                        :=  gt_ediinv_work_data(in_line_cnt).case_order_point;
                -- �O�����݌ɐ��ʁi�o���j
    gt_req_edi_inv_data(in_line_cnt).indv_prev_month_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).indv_prev_month_stk_qty;
                -- �O�����݌ɐ��ʁi�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).case_prev_month_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).case_prev_month_stk_qty;
                -- �O���݌ɐ��ʁi���v�j 
    gt_req_edi_inv_data(in_line_cnt).sum_prev_month_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).sum_prev_month_stk_qty;
                -- �������ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_order_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_order_qty;
                -- �������ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_order_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_order_qty;
                -- �������ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_order_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_order_qty;
                -- �������ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_order_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_order_qty;
                -- �������ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_order_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_order_qty;
                -- �������ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_order_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_order_qty;
                -- ���ɐ��ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_arrival_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_arrival_qty;
                -- ���ɐ��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_arrival_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_arrival_qty;
                -- ���ɐ��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_arrival_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_arrival_qty;
                -- �������׉� 
    gt_req_edi_inv_data(in_line_cnt).month_arrival_count      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_arrival_count;
                -- ���ɐ��ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_arrival_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_arrival_qty;
                -- ���ɐ��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_arrival_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_arrival_qty;
                -- ���ɐ��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_arrival_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_arrival_qty;
                -- �o�ɐ��ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_shipping_qty;
                -- �o�ɐ��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_shipping_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_shipping_qty;
                -- �o�ɐ��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_shipping_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_shipping_qty;
                -- �o�ɐ��ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_shipping_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_shipping_qty;
                -- �o�ɐ��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_shipping_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_shipping_qty;
                -- �o�ɐ��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_shipping_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_shipping_qty;
                -- �j���A���X���ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_destroy_loss_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_destroy_loss_qty;
                -- �j���A���X���ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_destroy_loss_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_destroy_loss_qty;
                -- �j���A���X���ʁi�����A���v�j 
    gt_req_edi_inv_data(in_line_cnt).day_sum_destroy_loss_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_destroy_loss_qty;
                -- �j���A���X���ʁi�����A�o���j 
    gt_req_edi_inv_data(in_line_cnt).month_indv_destroy_loss_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_destroy_loss_qty;
                -- �j���A���X���ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_destroy_loss_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_destroy_loss_qty;
                -- �j���A���X���ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_destroy_loss_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_destroy_loss_qty;
                -- �s�Ǎ݌ɐ��ʁi�����A�o���j 
    gt_req_edi_inv_data(in_line_cnt).day_indv_defect_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_defect_stk_qty;
                -- �s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_defect_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_defect_stk_qty;
                -- �s�Ǎ݌ɐ��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_defect_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_defect_stk_qty;
                -- �s�Ǎ݌ɐ��ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_defect_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_defect_stk_qty;
                -- �s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_defect_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_defect_stk_qty;
                -- �s�Ǎ݌ɐ��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_defect_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_defect_stk_qty;
                -- �s�Ǖԕi���ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_defect_return_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_defect_return_qty;
                -- �s�Ǖԕi���ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_defect_return_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_defect_return_qty;
                -- �s�Ǖԕi���ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_defect_return_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_defect_return_qty;
                -- �s�Ǖԕi���ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_defect_return_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_defect_return_qty;
                -- �s�Ǖԕi���ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_defect_return_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_defect_return_qty;
                -- �s�Ǖԕi���ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_defect_return_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_defect_return_qty;
                -- �s�Ǖԕi����i�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_defect_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_defect_return_rcpt;
                -- �s�Ǖԕi����i�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_defect_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_defect_return_rcpt;
                -- �s�Ǖԕi����i�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_defect_return_rcpt      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_defect_return_rcpt;
                -- �s�Ǖԕi����i�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_defect_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_defect_return_rcpt;
                -- �s�Ǖԕi����i�����A�P�[�X�j 
    gt_req_edi_inv_data(in_line_cnt).month_case_defect_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_defect_return_rcpt;
                -- �s�Ǖԕi����i�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_defect_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_defect_return_rcpt;
                -- �s�Ǖԕi�����i�����A�o���j 
    gt_req_edi_inv_data(in_line_cnt).day_indv_defect_return_send      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_defect_return_send;
                -- �s�Ǖԕi�����i�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_defect_return_send      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_defect_return_send;
                -- �s�Ǖԕi�����i�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_defect_return_send      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_defect_return_send;
                -- �s�Ǖԕi�����i�����A�o���j 
    gt_req_edi_inv_data(in_line_cnt).month_indv_defect_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_defect_return_send;
                -- �s�Ǖԕi�����i�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_defect_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_defect_return_send;
                -- �s�Ǖԕi�����i�����A���v�j 
    gt_req_edi_inv_data(in_line_cnt).month_sum_defect_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_defect_return_send;
                -- �Ǖi�ԕi����i�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_quality_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_quality_return_rcpt;
                -- �Ǖi�ԕi����i�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_quality_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_quality_return_rcpt;
                -- �Ǖi�ԕi����i�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_quality_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_quality_return_rcpt;
                -- �Ǖi�ԕi����i�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_quality_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_quality_return_rcpt;
                -- �Ǖi�ԕi����i�����A�P�[�X�j 
    gt_req_edi_inv_data(in_line_cnt).month_case_quality_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_quality_return_rcpt;
                -- �Ǖi�ԕi����i�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_quality_return_rcpt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_quality_return_rcpt;
                -- �Ǖi�ԕi�����i�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_quality_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_quality_return_send;
                -- �Ǖi�ԕi�����i�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_quality_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_quality_return_send;
                -- �Ǖi�ԕi�����i�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_quality_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_quality_return_send;
                -- �Ǖi�ԕi�����i�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_quality_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_quality_return_send;
                -- �Ǖi�ԕi�����i�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_quality_return_send      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_quality_return_send;
                -- �Ǖi�ԕi�����i�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_quality_return_send     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_quality_return_send;
                -- �I�����فi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_invent_difference     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_invent_difference;
                -- �I�����فi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_invent_difference     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_invent_difference;
                -- �I�����فi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_invent_difference     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_invent_difference;
                -- �I�����فi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_invent_difference      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_invent_difference;
                -- �I�����فi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_invent_difference     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_invent_difference;
                -- �I�����فi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_invent_difference     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_invent_difference;
                -- �݌ɐ��ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_stk_qty;
                -- �݌ɐ��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_stk_qty;
                -- �݌ɐ��ʁi�����A���v�j 
    gt_req_edi_inv_data(in_line_cnt).day_sum_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_stk_qty;
                -- �݌ɐ��ʁi�����A�o���j 
    gt_req_edi_inv_data(in_line_cnt).month_indv_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_stk_qty;
                -- �݌ɐ��ʁi�����A�P�[�X�j 
    gt_req_edi_inv_data(in_line_cnt).month_case_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_stk_qty;
                -- �݌ɐ��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_stk_qty;
                -- �ۗ��݌ɐ��i�����A�o���j 
    gt_req_edi_inv_data(in_line_cnt).day_indv_reserved_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_reserved_stk_qty;
                -- �ۗ��݌ɐ��i�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_reserved_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_reserved_stk_qty;
                -- �ۗ��݌ɐ��i�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_reserved_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_reserved_stk_qty;
                -- �ۗ��݌ɐ��i�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_reserved_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_reserved_stk_qty;
                -- �ۗ��݌ɐ��i�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_reserved_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_reserved_stk_qty;
                -- �ۗ��݌ɐ��i�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_reserved_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_reserved_stk_qty;
                -- �����݌ɐ��ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_cd_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_cd_stk_qty;
                -- �����݌ɐ��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_cd_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_cd_stk_qty;
                -- �����݌ɐ��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_cd_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_cd_stk_qty;
                -- �����݌ɐ��ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_cd_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_cd_stk_qty;
                -- �����݌ɐ��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_cd_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_cd_stk_qty;
                -- �����݌ɐ��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_cd_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_cd_stk_qty;
                -- �ϑ��݌ɐ��ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_cargo_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_cargo_stk_qty;
                -- �ϑ��݌ɐ��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_cargo_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_cargo_stk_qty;
                -- �ϑ��݌ɐ��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_cargo_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_cargo_stk_qty;
                -- �ϑ��݌ɐ��ʁi�����A�o���j  
    gt_req_edi_inv_data(in_line_cnt).month_indv_cargo_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_cargo_stk_qty;
                -- �ϑ��݌ɐ��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_cargo_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_cargo_stk_qty;
                -- �ϑ��݌ɐ��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_cargo_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_cargo_stk_qty;
                -- �����݌ɐ��ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_adjustment_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_adjustment_stk_qty;
                -- �����݌ɐ��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_adjustment_stk_qty      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_adjustment_stk_qty;
                -- �����݌ɐ��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_adjustment_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_adjustment_stk_qty;
                -- �����݌ɐ��ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_adjustment_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_adjustment_stk_qty;
                -- �����݌ɐ��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_adjustment_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_adjustment_stk_qty;
                -- �����݌ɐ��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_adjustment_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_adjustment_stk_qty;
                -- ���o�א��ʁi�����A�o���j 
    gt_req_edi_inv_data(in_line_cnt).day_indv_still_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_still_shipping_qty;
                -- ���o�א��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_still_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_still_shipping_qty;
                -- ���o�א��ʁi�����A���v�j 
    gt_req_edi_inv_data(in_line_cnt).day_sum_still_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_still_shipping_qty;
                -- ���o�א��ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_still_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_still_shipping_qty;
                -- ���o�א��ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_still_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_still_shipping_qty;
                -- ���o�א��ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_still_shipping_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_still_shipping_qty;
                -- ���݌ɐ��ʁi�o���j 
    gt_req_edi_inv_data(in_line_cnt).indv_all_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).indv_all_stk_qty;
                -- ���݌ɐ��ʁi�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).case_all_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).case_all_stk_qty;
                -- ���݌ɐ��ʁi���v�j 
    gt_req_edi_inv_data(in_line_cnt).sum_all_stk_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).sum_all_stk_qty;
                -- ����������
    gt_req_edi_inv_data(in_line_cnt).month_draw_count      
                                        :=  gt_ediinv_work_data(in_line_cnt).month_draw_count;
                -- �����\���ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_draw_possible_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_draw_possible_qty;
                -- �����\���ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_draw_possible_qty    
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_draw_possible_qty;
                -- �����\���ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_draw_possible_qty    
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_draw_possible_qty;
                -- �����\���ʁi�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).month_indv_draw_possible_qty    
                                        :=  gt_ediinv_work_data(in_line_cnt).month_indv_draw_possible_qty;
                -- �����\���ʁi�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).month_case_draw_possible_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_case_draw_possible_qty;
                -- �����\���ʁi�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).month_sum_draw_possible_qty    
                                        :=  gt_ediinv_work_data(in_line_cnt).month_sum_draw_possible_qty;
                -- �����s�\���i�����A�o���j
    gt_req_edi_inv_data(in_line_cnt).day_indv_draw_impossible_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_indv_draw_impossible_qty;
                -- �����s�\���i�����A�P�[�X�j
    gt_req_edi_inv_data(in_line_cnt).day_case_draw_impossible_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_case_draw_impossible_qty;
                -- �����s�\���i�����A���v�j
    gt_req_edi_inv_data(in_line_cnt).day_sum_draw_impossible_qty     
                                        :=  gt_ediinv_work_data(in_line_cnt).day_sum_draw_impossible_qty;
                -- �݌ɋ��z�i�����j
    gt_req_edi_inv_data(in_line_cnt).day_stk_amt      
                                        :=  gt_ediinv_work_data(in_line_cnt).day_stk_amt;
                -- �݌ɋ��z�i�����j
    gt_req_edi_inv_data(in_line_cnt).month_stk_amt     
                                        :=  gt_ediinv_work_data(in_line_cnt).month_stk_amt;
                -- ���l
    gt_req_edi_inv_data(in_line_cnt).remarks      
                                        :=  gt_ediinv_work_data(in_line_cnt).remarks;
                -- �`�F�[���X�ŗL�G���A�i���ׁj
    gt_req_edi_inv_data(in_line_cnt).chain_peculiar_area_line     
                                        :=  gt_ediinv_work_data(in_line_cnt).chain_peculiar_area_line;
                -- ���̋��z���v
    gt_req_edi_inv_data(in_line_cnt).regular_sell_amt_sum     
                                        :=  gt_ediinv_work_data(in_line_cnt).regular_sell_amt_sum;
                -- ���߂����z���v
    gt_req_edi_inv_data(in_line_cnt).rebate_amt_sum     
                                        :=  gt_ediinv_work_data(in_line_cnt).rebate_amt_sum;
                -- ����e����z���v
    gt_req_edi_inv_data(in_line_cnt).collect_bottle_amt_sum     
                                        :=  gt_ediinv_work_data(in_line_cnt).collect_bottle_amt_sum;
                -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
    gt_req_edi_inv_data(in_line_cnt).chain_peculiar_area_footer     
                                        :=  gt_ediinv_work_data(in_line_cnt).chain_peculiar_area_footer;
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
  END xxcos_in_edi_inventory_edit;
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
    lt_chain_account_number     hz_cust_accounts.account_number%TYPE;             -- �ڋq�R�[�h(�`�F�[���X)
    lt_head_edi_item_code_div   xxcmm_cust_accounts.edi_item_code_div%TYPE;       -- EDI�A�g�i�ڃR�[�h�敪
    lt_unit_of_measure          mtl_system_items_b.primary_unit_of_measure%TYPE;  -- �P��
    lv_invoice_number_err_flag  VARCHAR2(1) DEFAULT NULL;                         -- �`�[�G���[�t���O�ϐ�
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
    --==============================================================
    -- �d�c�h�`�F�[���X�R�[�h
    gt_req_edi_inv_data(in_line_cnt).edi_chain_code := gt_ediinv_work_data(in_line_cnt).edi_chain_code;
    -- �X�R�[�h
    gt_req_edi_inv_data(in_line_cnt).shop_code := gt_ediinv_work_data(in_line_cnt).shop_code;
    -- �`�[�ԍ�
    gt_req_edi_inv_data(in_line_cnt).invoice_number := gt_ediinv_work_data(in_line_cnt).invoice_number;
    -- �ڋq�R�[�h
    gt_req_edi_inv_data(in_line_cnt).customer_code  := gt_ediinv_work_data(in_line_cnt).customer_code;
    -- ���i�R�[�h�i����j
    gt_req_edi_inv_data(in_line_cnt).product_code_other_party  
                        := gt_ediinv_work_data(in_line_cnt).product_code_other_party;
    --==============================================================
    lv_invoice_number_err_flag := NULL;
    --==============================================================
    --==============================================================
    -- �X�R�[�h�`�F�b�N
    --==============================================================
    IF  ( gt_req_edi_inv_data(in_line_cnt).shop_code  IS NULL )  THEN
      -- �X�R�[�h
      gv_tkn_shop_code    :=  xxccp_common_pkg.get_msg(
                          iv_application        =>  cv_application,
                          iv_name               =>  cv_msg_shop_code
                          );
      lv_errmsg           :=  xxccp_common_pkg.get_msg(
                          iv_application        =>  cv_application,
                          iv_name               =>  gv_msg_in_none_err,
                          iv_token_name1        =>  cv_tkn_item,
                          iv_token_value1       =>  gv_tkn_shop_code
                          );
      ov_errbuf  :=  lv_errbuf;
      ov_errmsg  :=  lv_errmsg;
      lv_retcode :=  cv_status_warn;
      ov_retcode :=  cv_status_warn;
      lv_invoice_number_err_flag := cv_inv_num_err_flag;
      -- �݌ɏ�񃏁[�NID(error)
      gv_err_ediinv_work_flag  := cv_1;
    END IF;
    --
    --==============================================================
    -- �u�ڋq�R�[�h�v�̑Ó��� �`�F�b�N
    --==============================================================
    IF ( lv_invoice_number_err_flag IS NULL )  THEN
      BEGIN
        SELECT   cust.account_number         account_number   -- �ڋq�}�X�^.�ڋq�R�[�h
         INTO    gt_req_cust_acc_data(in_line_cnt).account_number
         FROM    hz_cust_accounts       cust,                 -- �ڋq�}�X�^
                 xxcmm_cust_accounts    xca                   -- �ڋq�ǉ����
                                      -- �ڋq�}�X�^.�ڋqID   =  �ڋq�ǉ����.�ڋqID
        WHERE    cust.cust_account_id = xca.customer_id        
                                     -- �ڋq�}�X�^.�ڋq�敪  = '10'(�ڋq) 
          AND    cust.customer_class_code = cv_customer_class_code10      
                                      -- �ڋq�}�X�^.�`�F�[���X�R�[�h(EDI) = A-2�Œ��o����EDI�`�F�[���X�R�[�h
          AND    xca.chain_store_code = gt_req_edi_inv_data(in_line_cnt).edi_chain_code
                                      -- �ڋq�}�X�^.�X�܃R�[�h = A-2�Œ��o�����X�R�[�h
          AND    xca.store_code       = gt_req_edi_inv_data(in_line_cnt).shop_code
          AND    rownum= 1;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  -- �i�Ώۃf�[�^�����G���[�j
          --* -------------------------------------------------------------
          --�ڋq�R�[�h�ϊ��G���[���b�Z�[�W  gv_msg_cust_num_chg_err
          --* -------------------------------------------------------------
          lv_errmsg     :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  gv_msg_cust_num_chg_err,
                        iv_token_name1        =>  cv_chain_shop_code,
                        iv_token_name2        =>  cv_shop_code,
                        iv_token_value1       =>  gt_req_edi_inv_data(in_line_cnt).edi_chain_code,
                        iv_token_value2       =>  gt_req_edi_inv_data(in_line_cnt).shop_code
                        );
          ov_errbuf     :=  lv_errbuf;
          ov_errmsg     :=  lv_errmsg;
          ov_retcode    :=  cv_status_warn;
          lv_invoice_number_err_flag := cv_inv_num_err_flag;
          -- �݌ɏ�񃏁[�NID(error)
          gv_err_ediinv_work_flag  := cv_1;
      END;
    END IF;
    --* -------------------------------------------------------------
    -- �u���i�R�[�h�v�̑Ó����`�F�b�N
    --* -------------------------------------------------------------
    IF ( lv_invoice_number_err_flag IS NULL )  THEN
      BEGIN
        --* -------------------------------------------------------------
        -- �ڋq�R�[�h(�ϊ���ڋq�R�[�h)
        --* -------------------------------------------------------------
        gt_req_edi_inv_data(in_line_cnt).conv_customer_code := gt_req_cust_acc_data(in_line_cnt).account_number;
        --* -------------------------------------------------------------
        --== �uEDI�A�g�i�ڃR�[�h�敪�v���o ==--
        --* -------------------------------------------------------------
        SELECT  xca.edi_item_code_div,    -- �ڋq�ǉ����.EDI�A�g�i�ڃR�[�h�敪
                cust.account_number       -- �ڋq�}�X�^.�ڋq�R�[�h
        INTO    lt_head_edi_item_code_div,
                lt_chain_account_number
        FROM    hz_cust_accounts       cust,                 -- �ڋq�}�X�^
                xxcmm_cust_accounts    xca                   -- �ڋq�ǉ����
        WHERE   cust.cust_account_id = xca.customer_id        
                                    -- �ڋq�}�X�^.�`�F�[���X�R�[�h(EDI) = A-2�Œ��o����EDI�`�F�[���X�R�[�h
          AND   xca.chain_store_code = gt_req_edi_inv_data(in_line_cnt).edi_chain_code
                                    -- �ڋq�}�X�^.�ڋq�敪 = '18'(�`�F�[���X)
          AND   cust.customer_class_code = cv_customer_class_code18
         ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --* -------------------------------------------------------------
          --EDI�A�g�i�ڃR�[�h�敪�G���[���b�Z�[�W  gv_msg_item_code_err
          --* -------------------------------------------------------------
          lv_errmsg    :=  xxccp_common_pkg.get_msg(
                       iv_application        =>  cv_application,
                       iv_name               =>  gv_msg_item_code_err,
                       iv_token_name1        =>  cv_chain_shop_code,
                       iv_token_value1       =>  gt_req_edi_inv_data(in_line_cnt).edi_chain_code
                       );
          ov_errbuf  :=  lv_errbuf;
          ov_errmsg  :=  lv_errmsg;
          ov_retcode :=  cv_status_warn;
          lv_invoice_number_err_flag := cv_inv_num_err_flag;
          --
          -- �݌ɏ�񃏁[�NID(error)
          gv_err_ediinv_work_flag  := cv_1;
      END;
      --* -------------------------------------------------------------
      IF  ( lv_invoice_number_err_flag IS NULL )  THEN
        --* -------------------------------------------------------------
        -- �uEDI�A�g�i�ڃR�[�h�敪�v���uNULL�v�܂��́u0�F�Ȃ��v�̏ꍇ
        --* -------------------------------------------------------------
        IF  (( lt_head_edi_item_code_div IS NULL ) 
        OR   ( lt_head_edi_item_code_div  = 0 ))
        THEN
          --* -------------------------------------------------------------
          --EDI�A�g�i�ڃR�[�h�敪�G���[���b�Z�[�W  gv_msg_item_code_err
          --* -------------------------------------------------------------
          lv_errmsg    :=  xxccp_common_pkg.get_msg(
                       iv_application        =>  cv_application,
                       iv_name               =>  gv_msg_item_code_err,
                       iv_token_name1        =>  cv_chain_shop_code,
                       iv_token_value1       =>  gt_req_edi_inv_data(in_line_cnt).edi_chain_code
                       );
          ov_errbuf    :=  lv_errbuf;
          ov_errmsg    :=  lv_errmsg;
          ov_retcode   :=  cv_status_warn;
          lv_invoice_number_err_flag := cv_inv_num_err_flag;
          -- �݌ɏ�񃏁[�NID(error)
          gv_err_ediinv_work_flag  := cv_1;
        --
        --* -------------------------------------------------------------
        -- �uEDI�A�g�i�ڃR�[�h�敪�v���u2�FJAN�R�[�h�v�̏ꍇ
        --  �i�ڃ}�X�^�`�F�b�N (3-1)
        --* -------------------------------------------------------------
        ELSIF  ( lt_head_edi_item_code_div  = 2 )  THEN
          BEGIN
            --* -------------------------------------------------------------
            --== �i�ڃ}�X�^�f�[�^���o ==--
            --* -------------------------------------------------------------
            SELECT mtl_item.segment1,                 -- �i�ڃR�[�h
                   mtl_item.primary_unit_of_measure   -- �P��
            INTO   gt_req_edi_inv_data(in_line_cnt).item_code,
                   lt_unit_of_measure
            FROM   mtl_system_items_b    mtl_item,
                   ic_item_mst_b         mtl_item1
            WHERE  mtl_item.segment1        = mtl_item1.item_no
                                                 -- ���i�R�[�h�i����j
              AND  mtl_item1.attribute21    = gt_req_edi_inv_data(in_line_cnt).product_code_other_party
                                                 -- �݌ɑg�DID
              AND  mtl_item.organization_id = gv_prf_orga_id;
          --
          EXCEPTION
            WHEN  NO_DATA_FOUND THEN
            --* -------------------------------------------------------------
            -- �uEDI�A�g�i�ڃR�[�h�敪�v���u2�FJAN�R�[�h�v�̏ꍇ�Ŏ擾�s�̏ꍇ�A
            --  �i�ڃ}�X�^�`�F�b�N (3-2) �P�[�X�i�`�m�R�[�h�𒊏o
            --* -------------------------------------------------------------
            BEGIN
              --* -------------------------------------------------------------
              --== �i�ڃ}�X�^�f�[�^���o ==-- 
              --* -------------------------------------------------------------
              SELECT mtl_item.segment1                  -- �i�ڃR�[�h
              INTO   gt_req_edi_inv_data(in_line_cnt).item_code
              FROM   mtl_system_items_b    mtl_item,
                     ic_item_mst_b         mtl_item1,
                     xxcmm_system_items_b  xxcmm_sib
              WHERE  mtl_item.segment1        = mtl_item1.item_no
                AND  mtl_item.segment1        = xxcmm_sib.item_code
                                            -- ���i�R�[�h�i����j
                AND  xxcmm_sib.case_jan_code  = gt_req_edi_inv_data(in_line_cnt).product_code_other_party
                                            -- �݌ɑg�DID
                AND  mtl_item.organization_id = gv_prf_orga_id;
                --* -------------------------------------------------------------
                --== A-1�Œ��o�����P�[�X�P�ʺ���
                --* -------------------------------------------------------------
                lt_unit_of_measure := gv_prf_case_code;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
              --* -------------------------------------------------------------
              --* �P�[�X�i�`�m�R�[�h�̏ꍇ�ŃG���[�̏ꍇ�A�_�~�[�i�ڃR�[�h���擾
              --* -------------------------------------------------------------
                BEGIN
                  --* -------------------------------------------------------------
                  -- JAN�R�[�h ���i�R�[�h�ϊ��G���[
                  --* -------------------------------------------------------------
                  gv_tkn_jan_code  :=  xxccp_common_pkg.get_msg(
                                         iv_application        =>  cv_application,
                                         iv_name               =>  cv_msg_jan_code
                                         );
                  --���i�R�[�h�ϊ��G���[���b�Z�[�W  gv_msg_product_code_err
                  lv_errmsg             :=  xxccp_common_pkg.get_msg(
                                        iv_application        =>  cv_application,
                                        iv_name               =>  gv_msg_product_code_err,
                                        iv_token_name1        =>  cv_prod_code,
                                        iv_token_name2        =>  cv_prod_type,
                                        iv_token_value1       =>  gt_req_edi_inv_data(in_line_cnt).product_code_other_party,
                                        iv_token_value2       =>  gv_tkn_jan_code
                                        );
                  ov_errbuf  :=  lv_errbuf;
                  ov_errmsg  :=  lv_errmsg;
                  ov_retcode :=  cv_status_warn;
                  --
                  --== ���b�N�A�b�v�}�X�^�f�[�^���o ==--
                  SELECT  flvv.lookup_code        -- �R�[�h
                  INTO   gt_req_edi_inv_data(in_line_cnt).item_code
                  FROM    fnd_lookup_values_vl  flvv        -- ���b�N�A�b�v�}�X�^
                  WHERE   flvv.lookup_type  = cv_lookup_type  -- ���b�N�A�b�v.�^�C�v
                   AND    flvv.enabled_flag       = cv_y                -- �L��
                   AND    flvv.attribute1         = cv_1
                   AND (( flvv.start_date_active IS NULL )
                   OR   ( flvv.start_date_active <= cd_process_date ))
                   AND (( flvv.end_date_active   IS NULL )
                   OR   ( flvv.end_date_active   >= cd_process_date ))  -- �Ɩ����t��FROM-TO��
                   ;
                --
                gv_dummy_item_code := gt_req_edi_inv_data(in_line_cnt).item_code;
                END;
            --* -------------------------------------------------------------
/*            WHEN OTHERS THEN
                --* -------------------------------------------------------------
                --�ڋq�i�� ���i�R�[�h�ϊ��G���[
                --* -------------------------------------------------------------
                gv_tkn_mtl_cust_items  :=  xxccp_common_pkg.get_msg(
                                       iv_application        =>  cv_application,
                                       iv_name               =>  cv_msg_mtl_cust_items
                                       );
                --���i�R�[�h�ϊ��G���[���b�Z�[�W  gv_msg_product_code_err
                lv_errmsg             :=  xxccp_common_pkg.get_msg(
                                      iv_application        =>  cv_application,
                                      iv_name               =>  gv_msg_product_code_err,
                                      iv_token_name1        =>  cv_prod_code,
                                      iv_token_name2        =>  cv_prod_type,
                                      iv_token_value1       =>  gt_req_edi_inv_data(in_line_cnt).product_code_other_party,
                                      iv_token_value2       =>  gv_tkn_mtl_cust_items
                                      );
                ov_errbuf  :=  lv_errbuf;
                ov_errmsg  :=  lv_errmsg;
                ov_retcode :=  cv_status_warn;
                lv_invoice_number_err_flag := cv_inv_num_err_flag;
                -- �݌ɏ�񃏁[�NID(error)
                gn_error_cnt := gn_error_cnt + 1;
                gv_err_ediinv_work_flag  := cv_1;
*/                --
            END;
          END;
          --
        --* -------------------------------------------------------------
        -- �uEDI�A�g�i�ڃR�[�h�敪�v���u1�F�ڋq�i�ځv�̏ꍇ
        --  �ڋq�i�ڃ}�X�^�`�F�b�N (3-2)
        --* -------------------------------------------------------------
        ELSIF  ( lt_head_edi_item_code_div  = 1 )  THEN
          --* -------------------------------------------------------------
          -- �u���i�R�[�h�Q�v�̑Ó����`�F�b�N
          --* -------------------------------------------------------------
          BEGIN
            --* -------------------------------------------------------------
            --== �ڋq�}�X�^�f�[�^���o ==--
            --* -------------------------------------------------------------
            SELECT mtl_item.segment1,              -- �i�ڃR�[�h
                   mtci.attribute1                 -- �P��
            INTO   gt_req_edi_inv_data(in_line_cnt).item_code,
                   lt_unit_of_measure
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
                                   --�ڋq�i�ڃ}�X�^�D�ڋq�i�� �� ���i�R�[�h�i����j
              AND  mtci.customer_item_number   = gt_req_edi_inv_data(in_line_cnt).product_code_other_party
                                   -- �ڋq�i��.�ڋq�i��ID = �ڋq�i�ڑ��ݎQ��.�ڋq�i��ID
              AND  mtci.customer_item_id       = mcix.customer_item_id
              AND  mcix.master_organization_id = mtl_parm.master_organization_id
                                   -- �݌ɑg�DID
              AND  mtl_parm.organization_id    = gv_prf_orga_id
                                   -- �ڋq�i�ڑ��ݎQ��.�i��ID = �i�ڃ}�X�^.�i��ID
              AND  mtl_item.inventory_item_id  = mcix.inventory_item_id
              AND  mtl_item.organization_id    = mtl_parm.organization_id;
          --
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --* -------------------------------------------------------------
              --== ���b�N�A�b�v�}�X�^�f�[�^���o
              --* -------------------------------------------------------------
              BEGIN
                --== ���b�N�A�b�v�}�X�^�f�[�^���o ==--
                SELECT   flvv.lookup_code        -- �R�[�h
                 INTO    gt_req_edi_inv_data(in_line_cnt).item_code
                 FROM   fnd_lookup_values_vl  flvv        -- ���b�N�A�b�v�}�X�^
                 WHERE  flvv.lookup_type       = cv_lookup_type  -- ���b�N�A�b�v.�^�C�v
                 AND    flvv.enabled_flag       = cv_y                -- �L��
                 AND    flvv.attribute1         = cv_1
                 AND (( flvv.start_date_active IS NULL )
                 OR   ( flvv.start_date_active <= cd_process_date ))
                 AND (( flvv.end_date_active   IS NULL )
                 OR   ( flvv.end_date_active   >= cd_process_date ))  -- �Ɩ����t��FROM-TO��
                 ;
                gv_dummy_item_code := gt_req_edi_inv_data(in_line_cnt).item_code;
                --
                --* -------------------------------------------------------------
                --�ڋq�i�� ���i�R�[�h�ϊ��G���[
                --* -------------------------------------------------------------
                gv_tkn_mtl_cust_items  :=  xxccp_common_pkg.get_msg(
                                       iv_application        =>  cv_application,
                                       iv_name               =>  cv_msg_mtl_cust_items
                                       );
                --���i�R�[�h�ϊ��G���[���b�Z�[�W  gv_msg_product_code_err
                lv_errmsg             :=  xxccp_common_pkg.get_msg(
                                      iv_application        =>  cv_application,
                                      iv_name               =>  gv_msg_product_code_err,
                                      iv_token_name1        =>  cv_prod_code,
                                      iv_token_name2        =>  cv_prod_type,
                                      iv_token_value1       =>  gt_req_edi_inv_data(in_line_cnt).product_code_other_party,
                                      iv_token_value2       =>  gv_tkn_mtl_cust_items
                                      );
                ov_errbuf  :=  lv_errbuf;
                ov_errmsg  :=  lv_errmsg;
                ov_retcode :=  cv_status_warn;
                --
              END;
          END;
        END IF;
      END IF;
    -- * -------------------------------------------------------------
    END IF;
    -- * -------------------------------------------------------------
    -- * ���^�[���R�[�h�����[�j���O�̂Ƃ��A�R�[�h��ۑ�
    -- * -------------------------------------------------------------
    IF ( ov_retcode =  cv_status_warn ) THEN
      gv_status_work :=  cv_status_warn;
      gn_warn_cnt    :=  gn_warn_cnt  +  1;
      --�G���[�o��
       FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT,
            buff   => lv_errmsg
       );
    END IF;
    -- * -------------------------------------------------------------
    --
    IF ( lv_invoice_number_err_flag IS NULL ) THEN
      --�f�[�^����Ɏ擾�ł����ꍇ
      IF  ( ov_retcode =  cv_status_normal ) THEN
        --�P�ʁiEBS�j�̐ݒ�
        gt_req_edi_inv_data(in_line_cnt).ebs_uom_code := lt_unit_of_measure;
      END IF;
      --* -------------------------------------------------------------
      --  * Procedure Name   : xxcos_in_edi_inventory_edit
      --  * Description      : EDI�݌ɏ��ϐ��̕ҏW(A-2)(1)
      --* -------------------------------------------------------------
      xxcos_in_edi_inventory_edit(
        in_line_cnt,   --   LOOP�p�J�E���^2
        lv_errbuf,     --   �G���[�E���b�Z�[�W 
        lv_retcode,    --   ���^�[���E�R�[�h
        lv_errmsg      --   ���[�U�[�E�G���[�E���b�Z�[�W
        );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
    --* -------------------------------------------------------------
    --* -------------------------------------------------------------
    --  �`�[�ԍ��L�[�u���C�N�ҏW
    --* -------------------------------------------------------------
    --* -------------------------------------------------------------
    IF  (( gv_inv_invoice_number_key IS NULL )  
    OR   ( gv_inv_invoice_number_key <> gt_req_edi_inv_data(in_line_cnt).invoice_number ))
    THEN
      --
      gn_normal_inventry_cnt     := gn_normal_inventry_cnt + 1;
      --* -------------------------------------------------------------
      -- * Procedure Name   : xxcos_in_invoice_num_add
      -- * Description      : �`�[�ʍ��v�ϐ��ւ̒ǉ�(A-4)(1)
      --* -------------------------------------------------------------
      xxcos_in_invoice_num_add(
        gn_normal_inventry_cnt,
        in_line_cnt,
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
      -- �`�[�ԍ�
      gt_sum_edi_inv_data(gn_normal_inventry_cnt).invoice_number    := 
                                 gt_req_edi_inv_data(in_line_cnt).invoice_number;
--
    ELSE
      --* -------------------------------------------------------------
      -- * Procedure Name   : xxcos_in_invoice_num_up
      -- * Description      : �`�[�ʍ��v�ϐ��֐��ʂ����Z(A-5)
      --* -------------------------------------------------------------
      xxcos_in_invoice_num_up(
        gn_normal_inventry_cnt,
        in_line_cnt,
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    -- �`�[�ԍ��̃Z�b�g
    gv_inv_invoice_number_key  := gt_req_edi_inv_data(in_line_cnt).invoice_number;
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
   * Procedure Name   : xxcos_in_edi_inv_wk_update
   * Description      : EDI�݌ɏ�񃏁[�N�e�[�u���ւ̍X�V(A-7)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_inv_wk_update(
    iv_file_name      IN VARCHAR2,     --   �C���^�t�F�[�X�t�@�C����
    iv_edi_chain_code IN VARCHAR2,     --   EDI�`�F�[���X�R�[�h
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_inv_wk_update'; -- �v���O������
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
--
    BEGIN
      --* -------------------------------------------------------------
      -- EDI�݌ɏ�񃏁[�N�e�[�u�� XXCOS_EDI_INVENTORY_WORK UPDATE
      --* -------------------------------------------------------------
      UPDATE xxcos_edi_inventory_work
         SET err_status             =  cv_run_class_name,      -- �X�e�[�^�X
             last_updated_by        =  cn_last_updated_by,      -- �ŏI�X�V��
             last_update_date       =  cd_last_update_date,     -- �ŏI�X�V��
             last_update_login      =  cn_last_update_login,    -- �ŏI�X�V���O�C��
             request_id             =  cn_request_id,           -- �v��ID
                                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             program_application_id =  cn_program_application_id, 
             program_id             =  cn_program_id,           -- �R���J�����g�E�v���O����ID
             program_update_date    =  cd_program_update_date   -- �v���O�����X�V��
      WHERE if_file_name  = iv_file_name;
--
      --�R���J�����g�ُ͈�I��������ׂ����ŃR�~�b�g����
      COMMIT;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- EDI�݌ɏ�񃏁[�N�e�[�u��
        gv_tkn_edi_inv_work :=  xxccp_common_pkg.get_msg(
                            iv_application        =>  cv_application,
                            iv_name               =>  cv_msg_edi_inv_work
                            );
        lv_errmsg       :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  gv_msg_data_update_err,
                        iv_token_name1        =>  cv_tkn_table_name1,
                        iv_token_name2        =>  cv_tkn_key_data,
                        iv_token_value1       =>  gv_tkn_edi_inv_work,
                        iv_token_value2       =>  gv_err_ediinv_work_flag
                        );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    --
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
  END xxcos_in_edi_inv_wk_update;
--
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_inventory_insert
   * Description      : EDI�݌ɏ��e�[�u���ւ̃f�[�^�}��(A-6)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_inventory_insert(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_inventory_insert'; -- �v���O������
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
    --* -------------------------------------------------------------
    -- * Procedure Name   : xxcos_in_invoice_num_req
    -- * Description      : �`�[�ʍ��v�ϐ��ւ̍ĕҏW(A-4)(2)
    --* -------------------------------------------------------------
    xxcos_in_invoice_num_req(
      gn_normal_inventry_cnt,
      lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF  ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --* -------------------------------------------------------------
    -- ���[�v�J�n�F
    --* -------------------------------------------------------------
    <<xxcos_edi_inventory_insert>>
    FOR  ln_no  IN  1..gn_normal_cnt  LOOP
      --* -------------------------------------------------------------
      --* Description      : EDI�݌ɏ��e�[�u���ւ̃f�[�^�}��(A-6)
      --* -------------------------------------------------------------
      INSERT INTO xxcos_edi_inventory
        (
          stk_info_id,                      -- �݌ɏ��id
          medium_class,                     -- �}�̋敪
          data_type_code,                   -- �f�[�^��R�[�h
          file_no,                          -- �t�@�C���m�n
          info_class,                       -- ���敪
          process_date,                     -- ������
          process_time,                     -- ��������
          base_code,                        -- ���_�i����j�R�[�h
          base_name,                        -- ���_���i�������j
          base_name_alt,                    -- ���_���i�J�i�j
          edi_chain_code,                   -- �d�c�h�`�F�[���X�R�[�h
          edi_chain_name,                   -- �d�c�h�`�F�[���X���i�����j
          edi_chain_name_alt,               -- �d�c�h�`�F�[���X���i�J�i�j
          report_code,                      -- ���[�R�[�h
          report_show_name,                 -- ���[�\����
          customer_code,                    -- �ڋq�R�[�h
          customer_name,                    -- �ڋq���i�����j
          customer_name_alt,                -- �ڋq���i�J�i�j
          company_code,                     -- �ЃR�[�h
          company_name_alt,                 -- �Ж��i�J�i�j
          shop_code,                        -- �X�R�[�h
          shop_name_alt,                    -- �X���i�J�i�j
          delivery_center_code,             -- �[���Z���^�[�R�[�h
          delivery_center_name,             -- �[���Z���^�[���i�����j
          delivery_center_name_alt,         -- �[���Z���^�[���i�J�i�j
          whse_code,                        -- �q�ɃR�[�h
          whse_name,                        -- �q�ɖ�
          inspect_charge_name,              -- ���i�S���Җ��i�����j
          inspect_charge_name_alt,          -- ���i�S���Җ��i�J�i�j
          return_charge_name,               -- �ԕi�S���Җ��i�����j
          return_charge_name_alt,           -- �ԕi�S���Җ��i�J�i�j
          receive_charge_name,              -- ��̒S���Җ��i�����j
          receive_charge_name_alt,          -- ��̒S���Җ��i�J�i�j
          order_date,                       -- ������
          center_delivery_date,             -- �Z���^�[�[�i��
          center_result_delivery_date,      -- �Z���^�[���[�i��
          center_shipping_date,             -- �Z���^�[�o�ɓ�
          center_result_shipping_date,      -- �Z���^�[���o�ɓ�
          data_creation_date_edi_data,      -- �f�[�^�쐬���i�d�c�h�f�[�^���j
          data_creation_time_edi_data,      -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
          stk_date,                         -- �݌ɓ��t
          offer_vendor_code_class,          -- �񋟊�Ǝ����R�[�h�敪
          whse_vendor_code_class,           -- �q�Ɏ����R�[�h�敪
          offer_cycle_class,                -- �񋟃T�C�N���敪
          stk_type,                         -- �݌Ɏ��
          japanese_class,                   -- ���{��敪
          whse_class,                       -- �q�ɋ敪
          vendor_code,                      -- �����R�[�h
          vendor_name,                      -- ����於�i�����j
          vendor_name_alt,                  -- ����於�i�J�i�j
          check_digit_class,                -- �`�F�b�N�f�W�b�g�L���敪
          invoice_number,                   -- �`�[�ԍ�
          check_digit,                      -- �`�F�b�N�f�W�b�g
          chain_peculiar_area_header,       -- �`�F�[���X�ŗL�G���A�i�w�b�_�j
          product_code_itouen,              -- ���i�R�[�h�i�ɓ����j
          product_code_other_party,         -- ���i�R�[�h�i����j
          jan_code,                         -- �i�`�m�R�[�h
          itf_code,                         -- �h�s�e�R�[�h
          product_name,                     -- ���i���i�����j
          product_name_alt,                 -- ���i���i�J�i�j
          prod_class,                       -- ���i�敪
          active_quality_class,             -- �K�p�i���敪
          qty_in_case,                      -- ����
          uom_code,                         -- �P��
          day_average_shipping_qty,         -- ������Ϗo�א���
          stk_type_code,                    -- �݌Ɏ�ʃR�[�h
          last_arrival_date,                -- �ŏI���ד�
          use_by_date,                      -- �ܖ�����
          product_date,                     -- ������
          upper_limit_stk_case,             -- ����݌Ɂi�P�[�X�j
          upper_limit_stk_indv,             -- ����݌Ɂi�o���j
          indv_order_point,                 -- �����_�i�o���j
          case_order_point,                 -- �����_�i�P�[�X�j
          indv_prev_month_stk_qty,          -- �O�����݌ɐ��ʁi�o���j
          case_prev_month_stk_qty,          -- �O�����݌ɐ��ʁi�P�[�X�j
          sum_prev_month_stk_qty,           -- �O���݌ɐ��ʁi���v�j
          day_indv_order_qty,               -- �������ʁi�����A�o���j
          day_case_order_qty,               -- �������ʁi�����A�P�[�X�j
          day_sum_order_qty,                -- �������ʁi�����A���v�j
          month_indv_order_qty,             -- �������ʁi�����A�o���j
          month_case_order_qty,             -- �������ʁi�����A�P�[�X�j
          month_sum_order_qty,              -- �������ʁi�����A���v�j
          day_indv_arrival_qty,             -- ���ɐ��ʁi�����A�o���j
          day_case_arrival_qty,             -- ���ɐ��ʁi�����A�P�[�X�j
          day_sum_arrival_qty,              -- ���ɐ��ʁi�����A���v�j
          month_arrival_count,              -- �������׉�
          month_indv_arrival_qty,           -- ���ɐ��ʁi�����A�o���j
          month_case_arrival_qty,           -- ���ɐ��ʁi�����A�P�[�X�j
          month_sum_arrival_qty,            -- ���ɐ��ʁi�����A���v�j
          day_indv_shipping_qty,            -- �o�ɐ��ʁi�����A�o���j
          day_case_shipping_qty,            -- �o�ɐ��ʁi�����A�P�[�X�j
          day_sum_shipping_qty,             -- �o�ɐ��ʁi�����A���v�j
          month_indv_shipping_qty,          -- �o�ɐ��ʁi�����A�o���j
          month_case_shipping_qty,          -- �o�ɐ��ʁi�����A�P�[�X�j
          month_sum_shipping_qty,           -- �o�ɐ��ʁi�����A���v�j
          day_indv_destroy_loss_qty,        -- �j���A���X���ʁi�����A�o���j
          day_case_destroy_loss_qty,        -- �j���A���X���ʁi�����A�P�[�X�j
          day_sum_destroy_loss_qty,         -- �j���A���X���ʁi�����A���v�j
          month_indv_destroy_loss_qty,      -- �j���A���X���ʁi�����A�o���j
          month_case_destroy_loss_qty,      -- �j���A���X���ʁi�����A�P�[�X�j
          month_sum_destroy_loss_qty,       -- �j���A���X���ʁi�����A���v�j
          day_indv_defect_stk_qty,          -- �s�Ǎ݌ɐ��ʁi�����A�o���j
          day_case_defect_stk_qty,          -- �s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
          day_sum_defect_stk_qty,           -- �s�Ǎ݌ɐ��ʁi�����A���v�j
          month_indv_defect_stk_qty,        -- �s�Ǎ݌ɐ��ʁi�����A�o���j
          month_case_defect_stk_qty,        -- �s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
          month_sum_defect_stk_qty,         -- �s�Ǎ݌ɐ��ʁi�����A���v�j
          day_indv_defect_return_qty,       -- �s�Ǖԕi���ʁi�����A�o���j
          day_case_defect_return_qty,       -- �s�Ǖԕi���ʁi�����A�P�[�X�j
          day_sum_defect_return_qty,        -- �s�Ǖԕi���ʁi�����A���v�j
          month_indv_defect_return_qty,     -- �s�Ǖԕi���ʁi�����A�o���j
          month_case_defect_return_qty,     -- �s�Ǖԕi���ʁi�����A�P�[�X�j
          month_sum_defect_return_qty,      -- �s�Ǖԕi���ʁi�����A���v�j
          day_indv_defect_return_rcpt,      -- �s�Ǖԕi����i�����A�o���j
          day_case_defect_return_rcpt,      -- �s�Ǖԕi����i�����A�P�[�X�j
          day_sum_defect_return_rcpt,       -- �s�Ǖԕi����i�����A���v�j
          month_indv_defect_return_rcpt,    -- �s�Ǖԕi����i�����A�o���j
          month_case_defect_return_rcpt,    -- �s�Ǖԕi����i�����A�P�[�X�j
          month_sum_defect_return_rcpt,     -- �s�Ǖԕi����i�����A���v�j
          day_indv_defect_return_send,      -- �s�Ǖԕi�����i�����A�o���j
          day_case_defect_return_send,      -- �s�Ǖԕi�����i�����A�P�[�X�j
          day_sum_defect_return_send,       -- �s�Ǖԕi�����i�����A���v�j
          month_indv_defect_return_send,    -- �s�Ǖԕi�����i�����A�o���j
          month_case_defect_return_send,    -- �s�Ǖԕi�����i�����A�P�[�X�j
          month_sum_defect_return_send,     -- �s�Ǖԕi�����i�����A���v�j
          day_indv_quality_return_rcpt,     -- �Ǖi�ԕi����i�����A�o���j
          day_case_quality_return_rcpt,     -- �Ǖi�ԕi����i�����A�P�[�X�j
          day_sum_quality_return_rcpt,      -- �Ǖi�ԕi����i�����A���v�j
          month_indv_quality_return_rcpt,   -- �Ǖi�ԕi����i�����A�o���j
          month_case_quality_return_rcpt,   -- �Ǖi�ԕi����i�����A�P�[�X�j
          month_sum_quality_return_rcpt,    -- �Ǖi�ԕi����i�����A���v�j
          day_indv_quality_return_send,     -- �Ǖi�ԕi�����i�����A�o���j
          day_case_quality_return_send,     -- �Ǖi�ԕi�����i�����A�P�[�X�j
          day_sum_quality_return_send,      -- �Ǖi�ԕi�����i�����A���v�j
          month_indv_quality_return_send,   -- �Ǖi�ԕi�����i�����A�o���j
          month_case_quality_return_send,   -- �Ǖi�ԕi�����i�����A�P�[�X�j
          month_sum_quality_return_send,    -- �Ǖi�ԕi�����i�����A���v�j
          day_indv_invent_difference,       -- �I�����فi�����A�o���j
          day_case_invent_difference,       -- �I�����فi�����A�P�[�X�j
          day_sum_invent_difference,        -- �I�����فi�����A���v�j
          month_indv_invent_difference,     -- �I�����فi�����A�o���j
          month_case_invent_difference,     -- �I�����فi�����A�P�[�X�j
          month_sum_invent_difference,      -- �I�����فi�����A���v�j
          day_indv_stk_qty,                 -- �݌ɐ��ʁi�����A�o���j
          day_case_stk_qty,                 -- �݌ɐ��ʁi�����A�P�[�X�j
          day_sum_stk_qty,                  -- �݌ɐ��ʁi�����A���v�j
          month_indv_stk_qty,               -- �݌ɐ��ʁi�����A�o���j
          month_case_stk_qty,               -- �݌ɐ��ʁi�����A�P�[�X�j
          month_sum_stk_qty,                -- �݌ɐ��ʁi�����A���v�j
          day_indv_reserved_stk_qty,        -- �ۗ��݌ɐ��i�����A�o���j
          day_case_reserved_stk_qty,        -- �ۗ��݌ɐ��i�����A�P�[�X�j
          day_sum_reserved_stk_qty,         -- �ۗ��݌ɐ��i�����A���v�j
          month_indv_reserved_stk_qty,      -- �ۗ��݌ɐ��i�����A�o���j
          month_case_reserved_stk_qty,      -- �ۗ��݌ɐ��i�����A�P�[�X�j
          month_sum_reserved_stk_qty,       -- �ۗ��݌ɐ��i�����A���v�j
          day_indv_cd_stk_qty,              -- �����݌ɐ��ʁi�����A�o���j
          day_case_cd_stk_qty,              -- �����݌ɐ��ʁi�����A�P�[�X�j
          day_sum_cd_stk_qty,               -- �����݌ɐ��ʁi�����A���v�j
          month_indv_cd_stk_qty,            -- �����݌ɐ��ʁi�����A�o���j
          month_case_cd_stk_qty,            -- �����݌ɐ��ʁi�����A�P�[�X�j
          month_sum_cd_stk_qty,             -- �����݌ɐ��ʁi�����A���v�j
          day_indv_cargo_stk_qty,           -- �ϑ��݌ɐ��ʁi�����A�o���j
          day_case_cargo_stk_qty,           -- �ϑ��݌ɐ��ʁi�����A�P�[�X�j
          day_sum_cargo_stk_qty,            -- �ϑ��݌ɐ��ʁi�����A���v�j
          month_indv_cargo_stk_qty,         -- �ϑ��݌ɐ��ʁi�����A�o���j
          month_case_cargo_stk_qty,         -- �ϑ��݌ɐ��ʁi�����A�P�[�X�j
          month_sum_cargo_stk_qty,          -- �ϑ��݌ɐ��ʁi�����A���v�j
          day_indv_adjustment_stk_qty,      -- �����݌ɐ��ʁi�����A�o���j
          day_case_adjustment_stk_qty,      -- �����݌ɐ��ʁi�����A�P�[�X�j
          day_sum_adjustment_stk_qty,       -- �����݌ɐ��ʁi�����A���v�j
          month_indv_adjustment_stk_qty,    -- �����݌ɐ��ʁi�����A�o���j
          month_case_adjustment_stk_qty,    -- �����݌ɐ��ʁi�����A�P�[�X�j
          month_sum_adjustment_stk_qty,     -- �����݌ɐ��ʁi�����A���v�j
          day_indv_still_shipping_qty,      -- ���o�א��ʁi�����A�o���j
          day_case_still_shipping_qty,      -- ���o�א��ʁi�����A�P�[�X�j
          day_sum_still_shipping_qty,       -- ���o�א��ʁi�����A���v�j
          month_indv_still_shipping_qty,    -- ���o�א��ʁi�����A�o���j
          month_case_still_shipping_qty,    -- ���o�א��ʁi�����A�P�[�X�j
          month_sum_still_shipping_qty,     -- ���o�א��ʁi�����A���v�j
          indv_all_stk_qty,                 -- ���݌ɐ��ʁi�o���j
          case_all_stk_qty,                 -- ���݌ɐ��ʁi�P�[�X�j
          sum_all_stk_qty,                  -- ���݌ɐ��ʁi���v�j
          month_draw_count,                 -- ����������
          day_indv_draw_possible_qty,       -- �����\���ʁi�����A�o���j
          day_case_draw_possible_qty,       -- �����\���ʁi�����A�P�[�X�j
          day_sum_draw_possible_qty,        -- �����\���ʁi�����A���v�j
          month_indv_draw_possible_qty,     -- �����\���ʁi�����A�o���j
          month_case_draw_possible_qty,     -- �����\���ʁi�����A�P�[�X�j
          month_sum_draw_possible_qty,      -- �����\���ʁi�����A���v�j
          day_indv_draw_impossible_qty,     -- �����s�\���i�����A�o���j
          day_case_draw_impossible_qty,     -- �����s�\���i�����A�P�[�X�j
          day_sum_draw_impossible_qty,      -- �����s�\���i�����A���v�j
          day_stk_amt,                      -- �݌ɋ��z�i�����j
          month_stk_amt,                    -- �݌ɋ��z�i�����j
          remarks,                          -- ���l
          chain_peculiar_area_line,         -- �`�F�[���X�ŗL�G���A�i���ׁj
          invoice_day_indv_sum_stk_qty,     -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j
          invoice_day_case_sum_stk_qty,     -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
          invoice_day_sum_sum_stk_qty,      -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j
          invoice_month_indv_sum_stk_qty,   -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j
          invoice_month_case_sum_stk_qty,   -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
          invoice_month_sum_sum_stk_qty,    -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j
          invoice_day_indv_cd_stk_qty,      -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j
          invoice_day_case_cd_stk_qty,      -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
          invoice_day_sum_cd_stk_qty,       -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j
          invoice_month_indv_cd_stk_qty,    -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j
          invoice_month_case_cd_stk_qty,    -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
          invoice_month_sum_cd_stk_qty,     -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j
          invoice_day_stk_amt,              -- �`�[�v�j�݌ɋ��z�i�����j
          invoice_month_stk_amt,            -- �`�[�v�j�݌ɋ��z�i�����j
          regular_sell_amt_sum,             -- ���̋��z���v
          rebate_amt_sum,                   -- ���߂����z���v
          collect_bottle_amt_sum,           -- ����e����z���v
          chain_peculiar_area_footer,       -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
          conv_customer_code,               -- �ڋq�R�[�h1
          item_code,                        -- �i�ڃR�[�h
          ebs_uom_code,                     -- �P�ʃR�[�h(EBS)
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          last_update_login,
          request_id,
          program_application_id,
          program_id,
          program_update_date
        )
      VALUES
        (
          xxcos_edi_inventory_s01.NEXTVAL,                            -- �݌ɏ��ID
          gt_req_edi_inv_data(ln_no).medium_class,                     -- �}�̋敪
          gt_req_edi_inv_data(ln_no).data_type_code,                   -- �f�[�^��R�[�h
          gt_req_edi_inv_data(ln_no).file_no,                          -- �t�@�C���m�n
          gt_req_edi_inv_data(ln_no).info_class,                       -- ���敪
          gt_req_edi_inv_data(ln_no).process_date,                     -- ������
          gt_req_edi_inv_data(ln_no).process_time,                     -- ��������
          gt_req_edi_inv_data(ln_no).base_code,                        -- ���_�i����j�R�[�h
          gt_req_edi_inv_data(ln_no).base_name,                        -- ���_���i�������j
          gt_req_edi_inv_data(ln_no).base_name_alt,                    -- ���_���i�J�i�j
          gt_req_edi_inv_data(ln_no).edi_chain_code,                   -- �d�c�h�`�F�[���X�R�[�h
          gt_req_edi_inv_data(ln_no).edi_chain_name,                   -- �d�c�h�`�F�[���X���i�����j
          gt_req_edi_inv_data(ln_no).edi_chain_name_alt,               -- �d�c�h�`�F�[���X���i�J�i�j
          gt_req_edi_inv_data(ln_no).report_code,                      -- ���[�R�[�h
          gt_req_edi_inv_data(ln_no).report_show_name,                 -- ���[�\����
          gt_req_edi_inv_data(ln_no).customer_code,                    -- �ڋq�R�[�h
          gt_req_edi_inv_data(ln_no).customer_name,                    -- �ڋq���i�����j
          gt_req_edi_inv_data(ln_no).customer_name_alt,                -- �ڋq���i�J�i�j
          gt_req_edi_inv_data(ln_no).company_code,                     -- �ЃR�[�h
          gt_req_edi_inv_data(ln_no).company_name_alt,                 -- �Ж��i�J�i�j
          gt_req_edi_inv_data(ln_no).shop_code,                        -- �X�R�[�h
          gt_req_edi_inv_data(ln_no).shop_name_alt,                    -- �X���i�J�i�j
          gt_req_edi_inv_data(ln_no).delivery_center_code,             -- �[���Z���^�[�R�[�h
          gt_req_edi_inv_data(ln_no).delivery_center_name,             -- �[���Z���^�[���i�����j
          gt_req_edi_inv_data(ln_no).delivery_center_name_alt,         -- �[���Z���^�[���i�J�i�j
          gt_req_edi_inv_data(ln_no).whse_code,                        -- �q�ɃR�[�h
          gt_req_edi_inv_data(ln_no).whse_name,                        -- �q�ɖ�
          gt_req_edi_inv_data(ln_no).inspect_charge_name,              -- ���i�S���Җ��i�����j
          gt_req_edi_inv_data(ln_no).inspect_charge_name_alt,          -- ���i�S���Җ��i�J�i�j
          gt_req_edi_inv_data(ln_no).return_charge_name,               -- �ԕi�S���Җ��i�����j
          gt_req_edi_inv_data(ln_no).return_charge_name_alt,           -- �ԕi�S���Җ��i�J�i�j
          gt_req_edi_inv_data(ln_no).receive_charge_name,              -- ��̒S���Җ��i�����j
          gt_req_edi_inv_data(ln_no).receive_charge_name_alt,          -- ��̒S���Җ��i�J�i�j
          gt_req_edi_inv_data(ln_no).order_date,                       -- ������
          gt_req_edi_inv_data(ln_no).center_delivery_date,             -- �Z���^�[�[�i��
          gt_req_edi_inv_data(ln_no).center_result_delivery_date,      -- �Z���^�[���[�i��
          gt_req_edi_inv_data(ln_no).center_shipping_date,             -- �Z���^�[�o�ɓ�
          gt_req_edi_inv_data(ln_no).center_result_shipping_date,      -- �Z���^�[���o�ɓ�
          gt_req_edi_inv_data(ln_no).data_creation_date_edi_data,      -- �f�[�^�쐬���i�d�c�h�f�[�^���j
          gt_req_edi_inv_data(ln_no).data_creation_time_edi_data,      -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
          gt_req_edi_inv_data(ln_no).stk_date,                         -- �݌ɓ��t
          gt_req_edi_inv_data(ln_no).offer_vendor_code_class,          -- �񋟊�Ǝ����R�[�h�敪
          gt_req_edi_inv_data(ln_no).whse_vendor_code_class,           -- �q�Ɏ����R�[�h�敪
          gt_req_edi_inv_data(ln_no).offer_cycle_class,                -- �񋟃T�C�N���敪
          gt_req_edi_inv_data(ln_no).stk_type,                         -- �݌Ɏ��
          gt_req_edi_inv_data(ln_no).japanese_class,                   -- ���{��敪
          gt_req_edi_inv_data(ln_no).whse_class,                       -- �q�ɋ敪
          gt_req_edi_inv_data(ln_no).vendor_code,                      -- �����R�[�h
          gt_req_edi_inv_data(ln_no).vendor_name,                      -- ����於�i�����j
          gt_req_edi_inv_data(ln_no).vendor_name_alt,                  -- ����於�i�J�i�j
          gt_req_edi_inv_data(ln_no).check_digit_class,                -- �`�F�b�N�f�W�b�g�L���敪
          gt_req_edi_inv_data(ln_no).invoice_number,                   -- �`�[�ԍ�
          gt_req_edi_inv_data(ln_no).check_digit,                      -- �`�F�b�N�f�W�b�g
          gt_req_edi_inv_data(ln_no).chain_peculiar_area_header,       -- �`�F�[���X�ŗL�G���A�i�w�b�_�j
          gt_req_edi_inv_data(ln_no).product_code_itouen,              -- ���i�R�[�h�i�ɓ����j
          gt_req_edi_inv_data(ln_no).product_code_other_party,         -- ���i�R�[�h�i����j
          gt_req_edi_inv_data(ln_no).jan_code,                         -- �i�`�m�R�[�h
          gt_req_edi_inv_data(ln_no).itf_code,                         -- �h�s�e�R�[�h
          gt_req_edi_inv_data(ln_no).product_name,                     -- ���i���i�����j
          gt_req_edi_inv_data(ln_no).product_name_alt,                 -- ���i���i�J�i�j
          gt_req_edi_inv_data(ln_no).prod_class,                       -- ���i�敪
          gt_req_edi_inv_data(ln_no).active_quality_class,             -- �K�p�i���敪
          gt_req_edi_inv_data(ln_no).qty_in_case,                      -- ����
          gt_req_edi_inv_data(ln_no).uom_code,                         -- �P��
          gt_req_edi_inv_data(ln_no).day_average_shipping_qty,         -- ������Ϗo�א���
          gt_req_edi_inv_data(ln_no).stk_type_code,                    -- �݌Ɏ�ʃR�[�h
          gt_req_edi_inv_data(ln_no).last_arrival_date,                -- �ŏI���ד�
          gt_req_edi_inv_data(ln_no).use_by_date,                      -- �ܖ�����
          gt_req_edi_inv_data(ln_no).product_date,                     -- ������
          gt_req_edi_inv_data(ln_no).upper_limit_stk_case,             -- ����݌Ɂi�P�[�X�j
          gt_req_edi_inv_data(ln_no).upper_limit_stk_indv,             -- ����݌Ɂi�o���j
          gt_req_edi_inv_data(ln_no).indv_order_point,                 -- �����_�i�o���j
          gt_req_edi_inv_data(ln_no).case_order_point,                 -- �����_�i�P�[�X�j
          gt_req_edi_inv_data(ln_no).indv_prev_month_stk_qty,          -- �O�����݌ɐ��ʁi�o���j
          gt_req_edi_inv_data(ln_no).case_prev_month_stk_qty,          -- �O�����݌ɐ��ʁi�P�[�X�j
          gt_req_edi_inv_data(ln_no).sum_prev_month_stk_qty,           -- �O���݌ɐ��ʁi���v�j
          gt_req_edi_inv_data(ln_no).day_indv_order_qty,               -- �������ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_order_qty,               -- �������ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_order_qty,                -- �������ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_order_qty,             -- �������ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_order_qty,             -- �������ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_order_qty,              -- �������ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_arrival_qty,             -- ���ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_arrival_qty,             -- ���ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_arrival_qty,              -- ���ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).month_arrival_count,              -- �������׉�
          gt_req_edi_inv_data(ln_no).month_indv_arrival_qty,           -- ���ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_arrival_qty,           -- ���ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_arrival_qty,            -- ���ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_shipping_qty,            -- �o�ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_shipping_qty,            -- �o�ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_shipping_qty,             -- �o�ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_shipping_qty,          -- �o�ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_shipping_qty,          -- �o�ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_shipping_qty,           -- �o�ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_destroy_loss_qty,        -- �j���A���X���ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_destroy_loss_qty,        -- �j���A���X���ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_destroy_loss_qty,         -- �j���A���X���ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_destroy_loss_qty,      -- �j���A���X���ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_destroy_loss_qty,      -- �j���A���X���ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_destroy_loss_qty,       -- �j���A���X���ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_defect_stk_qty,          -- �s�Ǎ݌ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_defect_stk_qty,          -- �s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_defect_stk_qty,           -- �s�Ǎ݌ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_defect_stk_qty,        -- �s�Ǎ݌ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_defect_stk_qty,        -- �s�Ǎ݌ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_defect_stk_qty,         -- �s�Ǎ݌ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_defect_return_qty,       -- �s�Ǖԕi���ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_defect_return_qty,       -- �s�Ǖԕi���ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_defect_return_qty,        -- �s�Ǖԕi���ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_defect_return_qty,     -- �s�Ǖԕi���ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_defect_return_qty,     -- �s�Ǖԕi���ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_defect_return_qty,      -- �s�Ǖԕi���ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_defect_return_rcpt,      -- �s�Ǖԕi����i�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_defect_return_rcpt,      -- �s�Ǖԕi����i�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_defect_return_rcpt,       -- �s�Ǖԕi����i�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_defect_return_rcpt,    -- �s�Ǖԕi����i�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_defect_return_rcpt,    -- �s�Ǖԕi����i�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_defect_return_rcpt,     -- �s�Ǖԕi����i�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_defect_return_send,      -- �s�Ǖԕi�����i�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_defect_return_send,      -- �s�Ǖԕi�����i�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_defect_return_send,       -- �s�Ǖԕi�����i�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_defect_return_send,    -- �s�Ǖԕi�����i�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_defect_return_send,    -- �s�Ǖԕi�����i�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_defect_return_send,     -- �s�Ǖԕi�����i�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_quality_return_rcpt,     -- �Ǖi�ԕi����i�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_quality_return_rcpt,     -- �Ǖi�ԕi����i�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_quality_return_rcpt,      -- �Ǖi�ԕi����i�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_quality_return_rcpt,   -- �Ǖi�ԕi����i�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_quality_return_rcpt,   -- �Ǖi�ԕi����i�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_quality_return_rcpt,    -- �Ǖi�ԕi����i�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_quality_return_send,     -- �Ǖi�ԕi�����i�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_quality_return_send,     -- �Ǖi�ԕi�����i�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_quality_return_send,      -- �Ǖi�ԕi�����i�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_quality_return_send,   -- �Ǖi�ԕi�����i�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_quality_return_send,   -- �Ǖi�ԕi�����i�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_quality_return_send,    -- �Ǖi�ԕi�����i�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_invent_difference,       -- �I�����فi�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_invent_difference,       -- �I�����فi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_invent_difference,        -- �I�����فi�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_invent_difference,     -- �I�����فi�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_invent_difference,     -- �I�����فi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_invent_difference,      -- �I�����فi�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_stk_qty,                 -- �݌ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_stk_qty,                 -- �݌ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_stk_qty,                  -- �݌ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_stk_qty,               -- �݌ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_stk_qty,               -- �݌ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_stk_qty,                -- �݌ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_reserved_stk_qty,        -- �ۗ��݌ɐ��i�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_reserved_stk_qty,        -- �ۗ��݌ɐ��i�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_reserved_stk_qty,         -- �ۗ��݌ɐ��i�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_reserved_stk_qty,      -- �ۗ��݌ɐ��i�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_reserved_stk_qty,      -- �ۗ��݌ɐ��i�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_reserved_stk_qty,       -- �ۗ��݌ɐ��i�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_cd_stk_qty,              -- �����݌ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_cd_stk_qty,              -- �����݌ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_cd_stk_qty,               -- �����݌ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_cd_stk_qty,            -- �����݌ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_cd_stk_qty,            -- �����݌ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_cd_stk_qty,             -- �����݌ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_cargo_stk_qty,           -- �ϑ��݌ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_cargo_stk_qty,           -- �ϑ��݌ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_cargo_stk_qty,            -- �ϑ��݌ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_cargo_stk_qty,         -- �ϑ��݌ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_cargo_stk_qty,         -- �ϑ��݌ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_cargo_stk_qty,          -- �ϑ��݌ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_adjustment_stk_qty,      -- �����݌ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_adjustment_stk_qty,      -- �����݌ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_adjustment_stk_qty,       -- �����݌ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_adjustment_stk_qty,    -- �����݌ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_adjustment_stk_qty,    -- �����݌ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_adjustment_stk_qty,     -- �����݌ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_still_shipping_qty,      -- ���o�א��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_still_shipping_qty,      -- ���o�א��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_still_shipping_qty,       -- ���o�א��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_still_shipping_qty,    -- ���o�א��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_still_shipping_qty,    -- ���o�א��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_still_shipping_qty,     -- ���o�א��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).indv_all_stk_qty,                 -- ���݌ɐ��ʁi�o���j
          gt_req_edi_inv_data(ln_no).case_all_stk_qty,                 -- ���݌ɐ��ʁi�P�[�X�j
          gt_req_edi_inv_data(ln_no).sum_all_stk_qty,                  -- ���݌ɐ��ʁi���v�j
          gt_req_edi_inv_data(ln_no).month_draw_count,                 -- ����������
          gt_req_edi_inv_data(ln_no).day_indv_draw_possible_qty,       -- �����\���ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_draw_possible_qty,       -- �����\���ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_draw_possible_qty,        -- �����\���ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).month_indv_draw_possible_qty,     -- �����\���ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).month_case_draw_possible_qty,     -- �����\���ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).month_sum_draw_possible_qty,      -- �����\���ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).day_indv_draw_impossible_qty,     -- �����s�\���i�����A�o���j
          gt_req_edi_inv_data(ln_no).day_case_draw_impossible_qty,     -- �����s�\���i�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).day_sum_draw_impossible_qty,      -- �����s�\���i�����A���v�j
          gt_req_edi_inv_data(ln_no).day_stk_amt,                      -- �݌ɋ��z�i�����j
          gt_req_edi_inv_data(ln_no).month_stk_amt,                    -- �݌ɋ��z�i�����j
          gt_req_edi_inv_data(ln_no).remarks,                          -- ���l
          gt_req_edi_inv_data(ln_no).chain_peculiar_area_line,         -- �`�F�[���X�ŗL�G���A�i���ׁj
          gt_req_edi_inv_data(ln_no).invoice_day_indv_sum_stk_qty,     -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j
          gt_req_edi_inv_data(ln_no).invoice_day_case_sum_stk_qty,     -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).invoice_day_sum_sum_stk_qty,      -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j
          gt_req_edi_inv_data(ln_no).invoice_month_indv_sum_stk_qty,   -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�o���j
          gt_req_edi_inv_data(ln_no).invoice_month_case_sum_stk_qty,   -- �`�[�v�j�݌ɐ��ʍ��v�i�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).invoice_month_sum_sum_stk_qty,    -- �`�[�v�j�݌ɐ��ʍ��v�i�����A���v�j
          gt_req_edi_inv_data(ln_no).invoice_day_indv_cd_stk_qty,      -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).invoice_day_case_cd_stk_qty,      -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).invoice_day_sum_cd_stk_qty,       -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).invoice_month_indv_cd_stk_qty,    -- �`�[�v�j�����݌ɐ��ʁi�����A�o���j
          gt_req_edi_inv_data(ln_no).invoice_month_case_cd_stk_qty,    -- �`�[�v�j�����݌ɐ��ʁi�����A�P�[�X�j
          gt_req_edi_inv_data(ln_no).invoice_month_sum_cd_stk_qty,     -- �`�[�v�j�����݌ɐ��ʁi�����A���v�j
          gt_req_edi_inv_data(ln_no).invoice_day_stk_amt,              -- �`�[�v�j�݌ɋ��z�i�����j
          gt_req_edi_inv_data(ln_no).invoice_month_stk_amt,            -- �`�[�v�j�݌ɋ��z�i�����j
          gt_req_edi_inv_data(ln_no).regular_sell_amt_sum,             -- ���̋��z���v
          gt_req_edi_inv_data(ln_no).rebate_amt_sum,                   -- ���߂����z���v
          gt_req_edi_inv_data(ln_no).collect_bottle_amt_sum,           -- ����e����z���v
          gt_req_edi_inv_data(ln_no).chain_peculiar_area_footer,       -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
          gt_req_edi_inv_data(ln_no).conv_customer_code,               -- �ϊ���ڋq�R�[�h
          gt_req_edi_inv_data(ln_no).item_code,                        -- �i�ڃR�[�h
          gt_req_edi_inv_data(ln_no).ebs_uom_code,                     -- �P�ʃR�[�h�iEBS�j
          cn_created_by,                      -- �쐬��
          cd_creation_date,                   -- �쐬��
          cn_last_updated_by,                 -- �ŏI�X�V��
          cd_last_update_date,                -- �ŏI�X�V��
          cn_last_update_login,               -- �ŏI�X�V���O�C��
          cn_request_id,                      -- �v��ID
          cn_program_application_id,          -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          cn_program_id,                      -- �R���J�����g�E�v���O����ID
          cd_program_update_date              -- �v���O�����X�V��
        );
--
    END LOOP  xxcos_edi_inventory_insert;
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
  END xxcos_in_edi_inventory_insert;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_inv_work_delete
   * Description      : EDI�݌ɏ�񃏁[�N�e�[�u���f�[�^�폜(A-9)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_inv_work_delete(
    iv_file_name      IN VARCHAR2,     --   �C���^�t�F�[�X�t�@�C����
    iv_run_class      IN VARCHAR2,     --   ���s�敪�F�u�V�K�v�u�Ď��s�v
    iv_edi_chain_code IN VARCHAR2,     --   EDI�`�F�[���X�R�[�h
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_inv_work_delete'; -- �v���O������
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
    BEGIN
      DELETE FROM xxcos_edi_inventory_work ediinvwk
       WHERE   ediinvwk.if_file_name     =    iv_file_name       -- �C���^�t�F�[�X�t�@�C����
         AND   ediinvwk.err_status       =    iv_run_class       -- �X�e�[�^�X
         AND (( iv_edi_chain_code IS NOT NULL
           AND   ediinvwk.edi_chain_code   =  iv_edi_chain_code )  -- EDI�`�F�[���X�R�[�h
           OR ( iv_edi_chain_code IS NULL ));
--
    EXCEPTION
      WHEN OTHERS THEN
        -- EDI�݌ɏ�񃏁[�N�e�[�u��
        gv_tkn_edi_inv_work :=  xxccp_common_pkg.get_msg(
                            iv_application        =>  cv_application,
                            iv_name               =>  cv_msg_edi_inv_work
                            );
        lv_errmsg       :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  gv_msg_data_delete_err,
                        iv_token_name1        =>  cv_tkn_table_name1,
                        iv_token_name2        =>  cv_tkn_key_data,
                        iv_token_value1       =>  gv_tkn_edi_inv_work,
                        iv_token_value2       =>  gv_run_data_type_code
                        );
        lv_errbuf       := SQLERRM;
        RAISE global_api_expt;
    END;
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
  END xxcos_in_edi_inv_work_delete ;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_inventory_lock
   * Description      : EDI�݌ɏ��e�[�u�����b�N(A-8)(1)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_inventory_lock(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_inventory_lock'; -- �v���O������
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
    -- EDI�݌ɏ��s�a�k�̍݌ɏ��폜���Ԃ��߂����f�[�^
    -- ===============================
    CURSOR edi_inventory_lock_cur
    IS
      SELECT edi_inv.stk_info_id
      FROM   xxcos_edi_inventory  edi_inv
      WHERE  NVL(edi_inv.center_delivery_date, 
             NVL(edi_inv.order_date, TRUNC(edi_inv.data_creation_date_edi_data))) 
          < TRUNC(cd_creation_date - TO_NUMBER(gv_prf_edi_del_date))
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
--
    --==============================================================
    -- �e�[�u�����b�N(EDI�݌ɏ��s�a�k�J�[�\��)
    --==============================================================
    OPEN  edi_inventory_lock_cur;
    CLOSE edi_inventory_lock_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- ���b�N�G���[ 
    WHEN lock_expt THEN
      gv_tkn_edi_inventory :=  xxccp_common_pkg.get_msg(
                              iv_application        =>  cv_application,
                              iv_name               =>  cv_msg_edi_inventory
                              );
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                          iv_application        =>  cv_application,
                          iv_name               =>  gv_msg_lock,
                          iv_token_name1        =>  cv_tkn_table_name,
                          iv_token_name2        =>  gv_tkn_edi_inventory
                 );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
      IF  ( edi_inventory_lock_cur%ISOPEN ) THEN
        CLOSE edi_inventory_lock_cur;
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
  END xxcos_in_edi_inventory_lock;
--
  /**********************************************************************************
   * Procedure Name   : xxcos_in_edi_inventory_delete
   * Description      : EDI�݌ɏ��e�[�u���f�[�^�폜(A-9)
   ***********************************************************************************/
  PROCEDURE xxcos_in_edi_inventory_delete(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'xxcos_in_edi_inventory_delete'; -- �v���O������
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
      --==============================================================
      -- �e�[�u�����b�N(EDI�݌ɏ��s�a�k)
      --==============================================================
      xxcos_in_edi_inventory_lock(
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
      --EDI�݌ɏ��s�a�k�폜
      DELETE   FROM   xxcos_edi_inventory  edi_inv
        WHERE  NVL(edi_inv.center_delivery_date, 
               NVL(edi_inv.order_date, TRUNC(edi_inv.data_creation_date_edi_data))) 
            < TRUNC(cd_creation_date - TO_NUMBER(gv_prf_edi_del_date));
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn_edi_inventory :=  xxccp_common_pkg.get_msg(
                             iv_application        =>  cv_application,
                             iv_name               =>  cv_msg_edi_inventory
                             );
        lv_errmsg       :=  xxccp_common_pkg.get_msg(
                        iv_application        =>  cv_application,
                        iv_name               =>  gv_msg_data_delete_err,
                        iv_token_name1        =>  cv_tkn_table_name1,
                        iv_token_name2        =>  cv_tkn_key_data,
                        iv_token_value1       =>  gv_tkn_edi_inventory,
                        iv_token_value2       =>  NULL
                        );
        lv_errbuf       := SQLERRM;
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
  END xxcos_in_edi_inventory_delete;
--
  /**********************************************************************************
   * Procedure Name   : sel_in_edi_inventory_work
   * Description      : EDI�݌ɏ�񃏁[�N�e�[�u���f�[�^���o (A-2)
   *                  :  SQL-LOADER�ɂ����EDI�݌ɏ�񃏁[�N�e�[�u���Ɏ�荞�܂ꂽ���R�[�h��
   *                     ���o���܂��B�����Ƀ��R�[�h���b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE sel_in_edi_inventory_work(
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sel_in_edi_inventory_work'; -- �v���O������
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
  -- EDI�݌ɏ�񃏁[�N�e�[�u���f�[�^���o
    CURSOR get_ediinv_work_data_cur( lv_cur_param1 CHAR, lv_cur_param2 CHAR, lv_cur_param3 CHAR )
    IS
    SELECT  
      ediinvwk.stk_info_work_id               stk_info_work_id,              -- �݌ɏ��ܰ�id
      ediinvwk.medium_class                   medium_class,                  -- �}�̋敪
      ediinvwk.data_type_code                 data_type_code,                -- �ް�����
      ediinvwk.file_no                        file_no,                       -- ̧��no
      ediinvwk.info_class                     info_class,                    -- ���敪
      ediinvwk.process_date                   process_date,                  -- ������
      ediinvwk.process_time                   process_time,                  -- ��������
      ediinvwk.base_code                      base_code,                     -- ���_(����)����
      ediinvwk.base_name                      base_name,                     -- ���_��(������)
      ediinvwk.base_name_alt                  base_name_alt,                 -- ���_��(��)
      ediinvwk.edi_chain_code                 edi_chain_code,                -- edi���ݓX����
      ediinvwk.edi_chain_name                 edi_chain_name,                -- edi���ݓX��(����)
      ediinvwk.edi_chain_name_alt             edi_chain_name_alt,            -- edi���ݓX��(��)
      ediinvwk.report_code                    report_code,                   -- ���[����
      ediinvwk.report_show_name               report_show_name,              -- ���[�\����
      ediinvwk.customer_code                  customer_code,                 -- �ڋq����
      ediinvwk.customer_name                  customer_name,                 -- �ڋq��(����)
      ediinvwk.customer_name_alt              customer_name_alt,             -- �ڋq��(��)
      ediinvwk.company_code                   company_code,                  -- �к���
      ediinvwk.company_name_alt               company_name_alt,              -- �Ж�(��)
      ediinvwk.shop_code                      shop_code,                     -- �X����
      ediinvwk.shop_name_alt                  shop_name_alt,                 -- �X��(��)
      ediinvwk.delivery_center_code           delivery_center_code,          -- �[����������
      ediinvwk.delivery_center_name           delivery_center_name,          -- �[��������(����)
      ediinvwk.delivery_center_name_alt       delivery_center_name_alt,      -- �[��������(��)
      ediinvwk.whse_code                      whse_code,                     -- �q�ɺ���
      ediinvwk.whse_name                      whse_name,                     -- �q�ɖ�
      ediinvwk.inspect_charge_name            inspect_charge_name,           -- ���i�S���Җ�(����)
      ediinvwk.inspect_charge_name_alt        inspect_charge_name_alt,       -- ���i�S���Җ�(��)
      ediinvwk.return_charge_name             return_charge_name,            -- �ԕi�S���Җ�(����)
      ediinvwk.return_charge_name_alt         return_charge_name_alt,        -- �ԕi�S���Җ�(��)
      ediinvwk.receive_charge_name            receive_charge_name,           -- ��̒S���Җ�(����)
      ediinvwk.receive_charge_name_alt        receive_charge_name_alt,       -- ��̒S���Җ�(��)
      ediinvwk.order_date                     order_date,                    -- ������
      ediinvwk.center_delivery_date           center_delivery_date,          -- �����[�i��
      ediinvwk.center_result_delivery_date    center_result_delivery_date,   -- �������[�i��
      ediinvwk.center_shipping_date           center_shipping_date,          -- �����o�ɓ�
      ediinvwk.center_result_shipping_date    center_result_shipping_date,   -- �������o�ɓ�
      ediinvwk.data_creation_date_edi_data    data_creation_date_edi_data,   -- �ް��쐬��(edi�ް���)
      ediinvwk.data_creation_time_edi_data    data_creation_time_edi_data,   -- �ް��쐬����(edi�ް���)
      ediinvwk.stk_date                       stk_date,                      -- �݌ɓ��t
      ediinvwk.offer_vendor_code_class        offer_vendor_code_class,       -- �񋟊�Ǝ���溰�ދ敪
      ediinvwk.whse_vendor_code_class         whse_vendor_code_class,        -- �q�Ɏ���溰�ދ敪
      ediinvwk.offer_cycle_class              offer_cycle_class,             -- �񋟻��ً敪
      ediinvwk.stk_type                       stk_type,                      -- �݌Ɏ��
      ediinvwk.japanese_class                 japanese_class,                -- ���{��敪
      ediinvwk.whse_class                     whse_class,                    -- �q�ɋ敪
      ediinvwk.vendor_code                    vendor_code,                   -- ����溰��
      ediinvwk.vendor_name                    vendor_name,                   -- ����於(����)
      ediinvwk.vendor_name_alt                vendor_name_alt,               -- ����於(��)
      ediinvwk.check_digit_class              check_digit_class,             -- �����޼ޯėL���敪
      ediinvwk.invoice_number                 invoice_number,                -- �`�[�ԍ�
      ediinvwk.check_digit                    check_digit,                   -- �����޼ޯ�
      ediinvwk.chain_peculiar_area_header     chain_peculiar_area_header,    -- ���ݓX�ŗL�ر(ͯ��)
      ediinvwk.product_code_itouen            product_code_itouen,           -- ���i����(�ɓ���)
      ediinvwk.product_code_other_party       product_code_other_party,      -- ���i����(���)
      ediinvwk.jan_code                       jan_code,                      -- jan����
      ediinvwk.itf_code                       itf_code,                      -- itf����
      ediinvwk.product_name                   product_name,                  -- ���i��(����)
      ediinvwk.product_name_alt               product_name_alt,              -- ���i��(��)
      ediinvwk.prod_class                     prod_class,                    -- ���i�敪
      ediinvwk.active_quality_class           active_quality_class,          -- �K�p�i���敪
      ediinvwk.qty_in_case                    qty_in_case,                   -- ����
      ediinvwk.uom_code                       uom_code,                      -- �P��
      ediinvwk.day_average_shipping_qty       day_average_shipping_qty,      -- ������Ϗo�א���
      ediinvwk.stk_type_code                  stk_type_code,                 -- �݌Ɏ�ʺ���
      ediinvwk.last_arrival_date              last_arrival_date,             -- �ŏI���ד�
      ediinvwk.use_by_date                    use_by_date,                   -- �ܖ�����
      ediinvwk.product_date                   product_date,                  -- ������
      ediinvwk.upper_limit_stk_case           upper_limit_stk_case,          -- ����݌�(���)
      ediinvwk.upper_limit_stk_indv           upper_limit_stk_indv,          -- ����݌�(�o��)
      ediinvwk.indv_order_point               indv_order_point,              -- �����_(�o��)
      ediinvwk.case_order_point               case_order_point,              -- �����_(���)
      ediinvwk.indv_prev_month_stk_qty        indv_prev_month_stk_qty,       -- �O�����݌ɐ���(�o��)
      ediinvwk.case_prev_month_stk_qty        case_prev_month_stk_qty,       -- �O�����݌ɐ���(���)
      ediinvwk.sum_prev_month_stk_qty         sum_prev_month_stk_qty,        -- �O���݌ɐ���(���v)
      ediinvwk.day_indv_order_qty             day_indv_order_qty,            -- ��������(����,�o��)
      ediinvwk.day_case_order_qty             day_case_order_qty,            -- ��������(����,���)
      ediinvwk.day_sum_order_qty              day_sum_order_qty,             -- ��������(����,���v)
      ediinvwk.month_indv_order_qty           month_indv_order_qty,          -- ��������(����,�o��)
      ediinvwk.month_case_order_qty           month_case_order_qty,          -- ��������(����,���)
      ediinvwk.month_sum_order_qty            month_sum_order_qty,           -- ��������(����,���v)
      ediinvwk.day_indv_arrival_qty           day_indv_arrival_qty,          -- ���ɐ���(����,�o��)
      ediinvwk.day_case_arrival_qty           day_case_arrival_qty,          -- ���ɐ���(����,���)
      ediinvwk.day_sum_arrival_qty            day_sum_arrival_qty,           -- ���ɐ���(����,���v)
      ediinvwk.month_arrival_count            month_arrival_count,           -- �������׉�
      ediinvwk.month_indv_arrival_qty         month_indv_arrival_qty,        -- ���ɐ���(����,�o��)
      ediinvwk.month_case_arrival_qty         month_case_arrival_qty,        -- ���ɐ���(����,���)
      ediinvwk.month_sum_arrival_qty          month_sum_arrival_qty,         -- ���ɐ���(����,���v)
      ediinvwk.day_indv_shipping_qty          day_indv_shipping_qty,         -- �o�ɐ���(����,�o��)
      ediinvwk.day_case_shipping_qty          day_case_shipping_qty,         -- �o�ɐ���(����,���)
      ediinvwk.day_sum_shipping_qty           day_sum_shipping_qty,          -- �o�ɐ���(����,���v)
      ediinvwk.month_indv_shipping_qty        month_indv_shipping_qty,       -- �o�ɐ���(����,�o��)
      ediinvwk.month_case_shipping_qty        month_case_shipping_qty,       -- �o�ɐ���(����,���)
      ediinvwk.month_sum_shipping_qty         month_sum_shipping_qty,        -- �o�ɐ���(����,���v)
      ediinvwk.day_indv_destroy_loss_qty      day_indv_destroy_loss_qty,     -- �j��,۽����(����,�o��)
      ediinvwk.day_case_destroy_loss_qty      day_case_destroy_loss_qty,     -- �j��,۽����(����,���)
      ediinvwk.day_sum_destroy_loss_qty       day_sum_destroy_loss_qty,      -- �j��,۽����(����,���v)
      ediinvwk.month_indv_destroy_loss_qty    month_indv_destroy_loss_qty,   -- �j��,۽����(����,�o��)
      ediinvwk.month_case_destroy_loss_qty    month_case_destroy_loss_qty,   -- �j��,۽����(����,���)
      ediinvwk.month_sum_destroy_loss_qty     month_sum_destroy_loss_qty,    -- �j��,۽����(����,���v)
      ediinvwk.day_indv_defect_stk_qty        day_indv_defect_stk_qty,       -- �s�Ǎ݌ɐ���(����,�o��)
      ediinvwk.day_case_defect_stk_qty        day_case_defect_stk_qty,       -- �s�Ǎ݌ɐ���(����,���)
      ediinvwk.day_sum_defect_stk_qty         day_sum_defect_stk_qty,        -- �s�Ǎ݌ɐ���(����,���v)
      ediinvwk.month_indv_defect_stk_qty      month_indv_defect_stk_qty,     -- �s�Ǎ݌ɐ���(����,�o��)
      ediinvwk.month_case_defect_stk_qty      month_case_defect_stk_qty,     -- �s�Ǎ݌ɐ���(����,���)
      ediinvwk.month_sum_defect_stk_qty       month_sum_defect_stk_qty,      -- �s�Ǎ݌ɐ���(����,���v)
      ediinvwk.day_indv_defect_return_qty     day_indv_defect_return_qty,    -- �s�Ǖԕi����(����,�o��)
      ediinvwk.day_case_defect_return_qty     day_case_defect_return_qty,    -- �s�Ǖԕi����(����,���)
      ediinvwk.day_sum_defect_return_qty      day_sum_defect_return_qty,     -- �s�Ǖԕi����(����,���v)
      ediinvwk.month_indv_defect_return_qty   month_indv_defect_return_qty,  -- �s�Ǖԕi����(����,�o��)
      ediinvwk.month_case_defect_return_qty   month_case_defect_return_qty,  -- �s�Ǖԕi����(����,���)
      ediinvwk.month_sum_defect_return_qty    month_sum_defect_return_qty,   -- �s�Ǖԕi����(����,���v)
      ediinvwk.day_indv_defect_return_rcpt    day_indv_defect_return_rcpt,   -- �s�Ǖԕi���(����,�o��)
      ediinvwk.day_case_defect_return_rcpt    day_case_defect_return_rcpt,   -- �s�Ǖԕi���(����,���)
      ediinvwk.day_sum_defect_return_rcpt     day_sum_defect_return_rcpt,    -- �s�Ǖԕi���(����,���v)
      ediinvwk.month_indv_defect_return_rcpt  month_indv_defect_return_rcpt, -- �s�Ǖԕi���(����,�o��)
      ediinvwk.month_case_defect_return_rcpt  month_case_defect_return_rcpt, -- �s�Ǖԕi���(����,���)
      ediinvwk.month_sum_defect_return_rcpt   month_sum_defect_return_rcpt,  -- �s�Ǖԕi���(����,���v)
      ediinvwk.day_indv_defect_return_send    day_indv_defect_return_send,   -- �s�Ǖԕi����(����,�o��)
      ediinvwk.day_case_defect_return_send    day_case_defect_return_send,   -- �s�Ǖԕi����(����,���)
      ediinvwk.day_sum_defect_return_send     day_sum_defect_return_send,    -- �s�Ǖԕi����(����,���v)
      ediinvwk.month_indv_defect_return_send  month_indv_defect_return_send, -- �s�Ǖԕi����(����,�o��)
      ediinvwk.month_case_defect_return_send  month_case_defect_return_send, -- �s�Ǖԕi����(����,���)
      ediinvwk.month_sum_defect_return_send   month_sum_defect_return_send,  -- �s�Ǖԕi����(����,���v)
      ediinvwk.day_indv_quality_return_rcpt   day_indv_quality_return_rcpt,  -- �Ǖi�ԕi���(����,�o��)
      ediinvwk.day_case_quality_return_rcpt   day_case_quality_return_rcpt,  -- �Ǖi�ԕi���(����,���)
      ediinvwk.day_sum_quality_return_rcpt    day_sum_quality_return_rcpt,   -- �Ǖi�ԕi���(����,���v)
      ediinvwk.month_indv_quality_return_rcpt month_indv_quality_return_rcpt, -- �Ǖi�ԕi���(����,�o��)
      ediinvwk.month_case_quality_return_rcpt month_case_quality_return_rcpt, -- �Ǖi�ԕi���(����,���)
      ediinvwk.month_sum_quality_return_rcpt  month_sum_quality_return_rcpt,  -- �Ǖi�ԕi���(����,���v)
      ediinvwk.day_indv_quality_return_send   day_indv_quality_return_send,   -- �Ǖi�ԕi����(����,�o��)
      ediinvwk.day_case_quality_return_send   day_case_quality_return_send,   -- �Ǖi�ԕi����(����,���)
      ediinvwk.day_sum_quality_return_send    day_sum_quality_return_send,    -- �Ǖi�ԕi����(����,���v)
      ediinvwk.month_indv_quality_return_send month_indv_quality_return_send, -- �Ǖi�ԕi����(����,�o��)
      ediinvwk.month_case_quality_return_send month_case_quality_return_send, -- �Ǖi�ԕi����(����,���)
      ediinvwk.month_sum_quality_return_send  month_sum_quality_return_send,  -- �Ǖi�ԕi����(����,���v)
      ediinvwk.day_indv_invent_difference     day_indv_invent_difference,     -- �I������(����,�o��)
      ediinvwk.day_case_invent_difference     day_case_invent_difference,     -- �I������(����,���)
      ediinvwk.day_sum_invent_difference      day_sum_invent_difference,      -- �I������(����,���v)
      ediinvwk.month_indv_invent_difference   month_indv_invent_difference,   -- �I������(����,�o��)
      ediinvwk.month_case_invent_difference   month_case_invent_difference,   -- �I������(����,���)
      ediinvwk.month_sum_invent_difference    month_sum_invent_difference,    -- �I������(����,���v)
      ediinvwk.day_indv_stk_qty               day_indv_stk_qty,               -- �݌ɐ���(����,�o��)
      ediinvwk.day_case_stk_qty               day_case_stk_qty,               -- �݌ɐ���(����,���)
      ediinvwk.day_sum_stk_qty                day_sum_stk_qty,                -- �݌ɐ���(����,���v)
      ediinvwk.month_indv_stk_qty             month_indv_stk_qty,             -- �݌ɐ���(����,�o��)
      ediinvwk.month_case_stk_qty             month_case_stk_qty,             -- �݌ɐ���(����,���)
      ediinvwk.month_sum_stk_qty              month_sum_stk_qty,              -- �݌ɐ���(����,���v)
      ediinvwk.day_indv_reserved_stk_qty      day_indv_reserved_stk_qty,      -- �ۗ��݌ɐ�(����,�o��)
      ediinvwk.day_case_reserved_stk_qty      day_case_reserved_stk_qty,      -- �ۗ��݌ɐ�(����,���)
      ediinvwk.day_sum_reserved_stk_qty       day_sum_reserved_stk_qty,       -- �ۗ��݌ɐ�(����,���v)
      ediinvwk.month_indv_reserved_stk_qty    month_indv_reserved_stk_qty,    -- �ۗ��݌ɐ�(����,�o��)
      ediinvwk.month_case_reserved_stk_qty    month_case_reserved_stk_qty,    -- �ۗ��݌ɐ�(����,���)
      ediinvwk.month_sum_reserved_stk_qty     month_sum_reserved_stk_qty,     -- �ۗ��݌ɐ�(����,���v)
      ediinvwk.day_indv_cd_stk_qty            day_indv_cd_stk_qty,            -- �����݌ɐ���(����,�o��)
      ediinvwk.day_case_cd_stk_qty            day_case_cd_stk_qty,            -- �����݌ɐ���(����,���)
      ediinvwk.day_sum_cd_stk_qty             day_sum_cd_stk_qty,             -- �����݌ɐ���(����,���v)
      ediinvwk.month_indv_cd_stk_qty          month_indv_cd_stk_qty,          -- �����݌ɐ���(����,�o��)
      ediinvwk.month_case_cd_stk_qty          month_case_cd_stk_qty,          -- �����݌ɐ���(����,���)
      ediinvwk.month_sum_cd_stk_qty           month_sum_cd_stk_qty,           -- �����݌ɐ���(����,���v)
      ediinvwk.day_indv_cargo_stk_qty         day_indv_cargo_stk_qty,         -- �ϑ��݌ɐ���(����,�o��)
      ediinvwk.day_case_cargo_stk_qty         day_case_cargo_stk_qty,         -- �ϑ��݌ɐ���(����,���)
      ediinvwk.day_sum_cargo_stk_qty          day_sum_cargo_stk_qty,          -- �ϑ��݌ɐ���(����,���v)
      ediinvwk.month_indv_cargo_stk_qty       month_indv_cargo_stk_qty,       -- �ϑ��݌ɐ���(����,�o��)
      ediinvwk.month_case_cargo_stk_qty       month_case_cargo_stk_qty,       -- �ϑ��݌ɐ���(����,���)
      ediinvwk.month_sum_cargo_stk_qty        month_sum_cargo_stk_qty,        -- �ϑ��݌ɐ���(����,���v)
      ediinvwk.day_indv_adjustment_stk_qty    day_indv_adjustment_stk_qty,    -- �����݌ɐ���(����,�o��)
      ediinvwk.day_case_adjustment_stk_qty    day_case_adjustment_stk_qty,    -- �����݌ɐ���(����,���)
      ediinvwk.day_sum_adjustment_stk_qty     day_sum_adjustment_stk_qty,     -- �����݌ɐ���(����,���v)
      ediinvwk.month_indv_adjustment_stk_qty  month_indv_adjustment_stk_qty,  -- �����݌ɐ���(����,�o��)
      ediinvwk.month_case_adjustment_stk_qty  month_case_adjustment_stk_qty,  -- �����݌ɐ���(����,���)
      ediinvwk.month_sum_adjustment_stk_qty   month_sum_adjustment_stk_qty,   -- �����݌ɐ���(����,���v)
      ediinvwk.day_indv_still_shipping_qty    day_indv_still_shipping_qty,    -- ���o�א���(����,�o��)
      ediinvwk.day_case_still_shipping_qty    day_case_still_shipping_qty,    -- ���o�א���(����,���)
      ediinvwk.day_sum_still_shipping_qty     day_sum_still_shipping_qty,     -- ���o�א���(����,���v)
      ediinvwk.month_indv_still_shipping_qty  month_indv_still_shipping_qty,  -- ���o�א���(����,�o��)
      ediinvwk.month_case_still_shipping_qty  month_case_still_shipping_qty,  -- ���o�א���(����,���)
      ediinvwk.month_sum_still_shipping_qty   month_sum_still_shipping_qty,   -- ���o�א���(����,���v)
      ediinvwk.indv_all_stk_qty               indv_all_stk_qty,               -- ���݌ɐ���(�o��)
      ediinvwk.case_all_stk_qty               case_all_stk_qty,               -- ���݌ɐ���(���)
      ediinvwk.sum_all_stk_qty                sum_all_stk_qty,                -- ���݌ɐ���(���v)
      ediinvwk.month_draw_count               month_draw_count,               -- ����������
      ediinvwk.day_indv_draw_possible_qty     day_indv_draw_possible_qty,     -- �����\����(����,�o��)
      ediinvwk.day_case_draw_possible_qty     day_case_draw_possible_qty,     -- �����\����(����,���)
      ediinvwk.day_sum_draw_possible_qty      day_sum_draw_possible_qty,      -- �����\����(����,���v)
      ediinvwk.month_indv_draw_possible_qty   month_indv_draw_possible_qty,   -- �����\����(����,�o��)
      ediinvwk.month_case_draw_possible_qty   month_case_draw_possible_qty,   -- �����\����(����,���)
      ediinvwk.month_sum_draw_possible_qty    month_sum_draw_possible_qty,    -- �����\����(����,���v)
      ediinvwk.day_indv_draw_impossible_qty   day_indv_draw_impossible_qty,   -- �����s�\��(����,�o��)
      ediinvwk.day_case_draw_impossible_qty   day_case_draw_impossible_qty,   -- �����s�\��(����,���)
      ediinvwk.day_sum_draw_impossible_qty    day_sum_draw_impossible_qty,    -- �����s�\��(����,���v)
      ediinvwk.day_stk_amt                    day_stk_amt,                    -- �݌ɋ��z(����)
      ediinvwk.month_stk_amt                  month_stk_amt,                  -- �݌ɋ��z(����)
      ediinvwk.remarks                        remarks,                        -- ���l
      ediinvwk.chain_peculiar_area_line       chain_peculiar_area_line,       -- ���ݓX�ŗL�ر(����)
      ediinvwk.invoice_day_indv_sum_stk_qty   invoice_day_indv_sum_stk_qty,   -- �`�[�v)�݌ɐ��ʍ��v(����,�o��)
      ediinvwk.invoice_day_case_sum_stk_qty   invoice_day_case_sum_stk_qty,   -- �`�[�v)�݌ɐ��ʍ��v(����,���)
      ediinvwk.invoice_day_sum_sum_stk_qty    invoice_day_sum_sum_stk_qty,    -- �`�[�v)�݌ɐ��ʍ��v(����,���v)
      ediinvwk.invoice_month_indv_sum_stk_qty invoice_month_indv_sum_stk_qty, -- �`�[�v)�݌ɐ��ʍ��v(����,�o��)
      ediinvwk.invoice_month_case_sum_stk_qty invoice_month_case_sum_stk_qty, -- �`�[�v)�݌ɐ��ʍ��v(����,���)
      ediinvwk.invoice_month_sum_sum_stk_qty  invoice_month_sum_sum_stk_qty,  -- �`�[�v)�݌ɐ��ʍ��v(����,���v)
      ediinvwk.invoice_day_indv_cd_stk_qty    invoice_day_indv_cd_stk_qty,    -- �`�[�v)�����݌ɐ���(����,�o��)
      ediinvwk.invoice_day_case_cd_stk_qty    invoice_day_case_cd_stk_qty,    -- �`�[�v)�����݌ɐ���(����,���)
      ediinvwk.invoice_day_sum_cd_stk_qty     invoice_day_sum_cd_stk_qty,     -- �`�[�v)�����݌ɐ���(����,���v)
      ediinvwk.invoice_month_indv_cd_stk_qty  invoice_month_indv_cd_stk_qty,  -- �`�[�v)�����݌ɐ���(����,�o��)
      ediinvwk.invoice_month_case_cd_stk_qty  invoice_month_case_cd_stk_qty,  -- �`�[�v)�����݌ɐ���(����,���)
      ediinvwk.invoice_month_sum_cd_stk_qty   invoice_month_sum_cd_stk_qty,   -- �`�[�v)�����݌ɐ���(����,���v)
      ediinvwk.invoice_day_stk_amt            invoice_day_stk_amt,            -- �`�[�v)�݌ɋ��z(����)
      ediinvwk.invoice_month_stk_amt          invoice_month_stk_amt,          -- �`�[�v)�݌ɋ��z(����)
      ediinvwk.regular_sell_amt_sum           regular_sell_amt_sum,           -- ���̋��z���v
      ediinvwk.rebate_amt_sum                 rebate_amt_sum,                 -- ���߂����z���v
      ediinvwk.collect_bottle_amt_sum         collect_bottle_amt_sum,         -- ����e����z���v
      ediinvwk.chain_peculiar_area_footer     chain_peculiar_area_footer,     -- ���ݓX�ŗL�ر(̯�)
      ediinvwk.err_status                     err_status                      -- �ð��
    FROM    xxcos_edi_inventory_work    ediinvwk                            -- EDI�݌ɏ�񃏁[�N�e�[�u��
    WHERE   ediinvwk.if_file_name       =    lv_cur_param3                  -- �C���^�t�F�[�X�t�@�C����
      AND   ediinvwk.err_status         =    lv_cur_param1                  -- �X�e�[�^�X
      AND (( lv_cur_param2 IS NOT NULL
        AND   ediinvwk.edi_chain_code   =    lv_cur_param2 )              -- EDI�`�F�[���X�R�[�h
        OR ( lv_cur_param2 IS NULL ))
    ORDER BY ediinvwk.invoice_number                                      -- �\�[�g�����i�`�[�ԍ��j
    FOR UPDATE OF
            ediinvwk.stk_info_work_id NOWAIT;
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
    ELSIF  ( iv_run_class  =  gv_run_class_name2 )  THEN   -- ���s�敪�F�u�Ď��{�v
      lv_cur_param1 := gv_run_class_name2;       -- ���o�J�[�\���p���n���p�����^�P
    END IF;
    --
    lv_cur_param2 := iv_edi_chain_code;          -- ���o�J�[�\���p���n���p�����^�R
    lv_cur_param3 := iv_file_name;               -- ���o�J�[�\���p���n���p�����^�S
--
    --==============================================================
    -- EDI�݌ɏ�񃏁[�N�e�[�u���f�[�^�擾
    --==============================================================
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_ediinv_work_data_cur( lv_cur_param1, lv_cur_param2, lv_cur_param3 );
      --
      -- �o���N�t�F�b�`
      FETCH get_ediinv_work_data_cur BULK COLLECT INTO gt_ediinv_work_data;
      -- ���o�����Z�b�g
      gn_target_cnt := get_ediinv_work_data_cur%ROWCOUNT;
      -- ���팏�� = ���o����
      gn_normal_cnt := gn_target_cnt;
      --
      -- �J�[�\��CLOSE
      CLOSE get_ediinv_work_data_cur;
    EXCEPTION
      -- ���b�N�G���[
      WHEN lock_expt THEN
        IF ( get_ediinv_work_data_cur%ISOPEN ) THEN
          CLOSE get_ediinv_work_data_cur;
        END IF;
        -- EDI�݌ɏ�񃏁[�N�e�[�u��
        gv_tkn_edi_inv_work :=  xxccp_common_pkg.get_msg(
                            iv_application        =>  cv_application,
                            iv_name               =>  cv_msg_edi_inv_work
                            );
        lv_errmsg           :=  xxccp_common_pkg.get_msg(
                            iv_application        =>  cv_application,
                            iv_name               =>  gv_msg_lock,
                            iv_token_name1        =>  cv_tkn_table_name,
                            iv_token_value1       =>  gv_tkn_edi_inv_work
                            );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
      -- ���̑��̒��o�G���[
      WHEN OTHERS THEN
        IF ( get_ediinv_work_data_cur%ISOPEN ) THEN
          CLOSE get_ediinv_work_data_cur;
        END IF;
        lv_errbuf  := SQLERRM;
        RAISE global_data_sel_expt;
    END;
    --
    -- �Ώۃf�[�^����
    IF ( gn_target_cnt = 0 ) THEN
      RAISE global_nodata_expt;
    END IF;
    --
    -- ���[�v�J�n�F
    <<xxcos_in_edi_iinv_set>>
    FOR ln_no IN 1..gn_target_cnt LOOP
      --* -------------------------------------------------------------------------------------------
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
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    --
    END LOOP  xxcos_in_edi_iinv_set;
--
    -- �㑱�������s�\�ȃG���[���������ꍇ
    IF ( gv_err_ediinv_work_flag IS NOT NULL ) THEN
      -- **********************************************************************************
      -- * Procedure Name   : xxcos_in_edi_inv_wk_update
      -- * Description      : EDI�݌ɏ�񃏁[�N�e�[�u���ւ̍X�V(A-7)
      -- ***********************************************************************************
      xxcos_in_edi_inv_wk_update(
        iv_file_name,     --   �C���^�t�F�[�X�t�@�C����
        iv_edi_chain_code,  -- EDI�`�F�[���X�R�[�h
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    --
    ELSE
    --* -------------------------------------------------------------------------------------------
    --  �ڋq���`�F�b�N�ŃG���[�����������ꍇ�B
    --* -------------------------------------------------------------------------------------------
      -- **********************************************************************************
      -- * Procedure Name   : xxcos_in_edi_inventory_insert
      -- * Description      : EDI�݌ɏ��e�[�u���ւ̃f�[�^�}��(A-6)
      -- ***********************************************************************************
      xxcos_in_edi_inventory_insert(
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      IF ( lv_retcode = cv_status_error ) THEN
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
      -- EDI�݌ɏ�񃏁[�N�e�[�u��
      gv_tkn_edi_inv_work :=  xxccp_common_pkg.get_msg(
                          iv_application        =>  cv_application,
                          iv_name               =>  cv_msg_edi_inv_work
                          );
      lv_errmsg           :=  xxccp_common_pkg.get_msg(
                          iv_application        =>  cv_application,
                          iv_name               =>  gv_msg_nodata,
                          iv_token_name1        =>  cv_tkn_table_name1,
                          iv_token_value1       =>  gv_tkn_edi_inv_work,
                          iv_token_name2        =>  cv_tkn_key_data,
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
  END sel_in_edi_inventory_work;
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
    lv_in_if_file    VARCHAR2(5000);
    lv_in_param      VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    --==============================================================
    -- �v���O������������(A-0) (�R���J�����g�v���O�������͍��ڂ��o��)
    --==============================================================
    -- �C���^�t�F�[�X�t�@�C�����i�p�����^�o�́j
    lv_in_if_file :=  xxccp_common_pkg.get_msg(
                   iv_application        =>  cv_application,
                   iv_name               =>  cv_msg_in_file_name1,
                   iv_token_name1        =>  cv_param1,
                   iv_token_value1       =>  iv_file_name
                   );
    --==============================================================
    --==============================================================
    -- ���̓p�����[�^�u �C���^�t�F�[�X�t�@�C�����v�o��
    --==============================================================
    FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT,
             buff   => lv_in_if_file
    );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_in_if_file
      );
    --==============================================================
    --==============================================================
    -- �v���O������������(A-0) (�R���J�����g�v���O�������͍��ڂ��o��)
    --==============================================================
    IF  ( iv_run_class  =  gv_run_class_name1 )  THEN     -- ���s�敪�F�u�V�K�v
    ----  IF  ( iv_edi_chain_code  IS NULL ) THEN
        lv_in_param :=  xxccp_common_pkg.get_msg(
                       iv_application        =>  cv_application,
                       iv_name               =>  gv_msg_param_out_msg1,
                       iv_token_name1        =>  cv_param1,
                       iv_token_value1       =>  iv_run_class
                       );
    --==============================================================
    --= ���s�敪���y�V�K�v�̏ꍇ�A���ݓX���ގw��Ȃ��̂���������\���Ȃ��B
    --==============================================================
    ----   ELSE
    ----    lv_errmsg      :=  xxccp_common_pkg.get_msg(
    ----                   iv_application        =>  cv_application,
    ----                   iv_name               =>  gv_msg_param_out_msg2,
    ----                   iv_token_name1        =>  cv_param1,
    ----                   iv_token_name2        =>  cv_param2,
    ----                   iv_token_value1       =>  iv_run_class,
    ----                   iv_token_value2       =>  iv_edi_chain_code
    ----                   );
    ----   END IF;
      --==============================================================
      -- ���̓p�����[�^�u���s�敪�v�uEDI�`�F�[���X�R�[�h�v�o��
      --==============================================================
      FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT,
             buff   => lv_in_param
      );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_in_param
      );
      --==============================================================
    ELSIF  ( iv_run_class  =  gv_run_class_name2 )  THEN    -- ���s�敪�F�u�Ď��{�v
      lv_in_param :=  xxccp_common_pkg.get_msg(
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
             buff   => lv_in_param
      );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_in_param
      );
      --==============================================================
    ELSE              -- ���s�敪�F�u�V�K�v�u�Ď��{�v �ȊO
      lv_in_param :=  xxccp_common_pkg.get_msg(
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
             buff   => lv_in_param
      );
      FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG,
             buff   => lv_in_param
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
      iv_file_name,       --   �C���^�t�F�[�X�t�@�C����
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
    -- * Procedure Name   : sel_in_edi_inventory_work(A-2)
    -- * Description      : EDI�݌ɏ�񃏁[�N�e�[�u���f�[�^���o (A-2)
    -- *                  :  SQL-LOADER�ɂ����EDI�݌ɏ�񃏁[�N�e�[�u���Ɏ�荞�܂ꂽ���R�[�h��
    -- *                     ���o���܂��B�����Ƀ��R�[�h���b�N���s���܂��B
    --==============================================================
    sel_in_edi_inventory_work(
      iv_file_name,       --   �C���^�t�F�[�X�t�@�C����
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
    -- �X�e�[�^�X���G���[�ƂȂ�f�[�^���Ȃ��ꍇ
    --==============================================================
    IF ( gv_err_ediinv_work_flag IS NULL ) THEN
      --==============================================================
      -- * Procedure Name   : xxcos_in_edi_inv_work_delete
      -- * Description      : EDI�݌ɏ�񃏁[�N�e�[�u���f�[�^�폜(A-9)
      --==============================================================
      xxcos_in_edi_inv_work_delete(
        iv_file_name,       --   �C���^�t�F�[�X�t�@�C����
        iv_run_class,       -- ���s�敪�F�u�V�K�v�u�Ď��s�v
        iv_edi_chain_code,  -- EDI�`�F�[���X�R�[�h
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF  ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      --==============================================================
      -- * Procedure Name   : xxcos_in_edi_inventory_delete
      -- * Description      : EDI�݌ɏ��e�[�u���f�[�^�폜(A-8)
      --==============================================================
      xxcos_in_edi_inventory_delete(
        lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF  ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- �R���J�����g�X�e�[�^�X�A�����̐ݒ�
    --==============================================================
    IF ( gv_err_ediinv_work_flag IS NOT NULL ) THEN
      ov_retcode    :=  cv_status_error;  --�X�e�[�^�X�F�G���[
      gn_normal_cnt :=  0;                --���팏���F0
      gn_warn_cnt   :=  0;                --�x�������F0
    ELSIF ( gv_status_work  =  cv_status_warn ) THEN
      ov_retcode    :=  gv_status_work;   --�X�e�[�^�X�F�x��
    END IF;
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
    iv_edi_chain_code IN VARCHAR2      --   EDI�`�F�[���X�R�[�h
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
    IF  ( lv_retcode = cv_status_error ) THEN
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
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_target_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT,
       buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_success_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT,
       buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_error_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT,
       buff   => gv_out_msg
    );
    --
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_warn_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT,
       buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    --�I�����b�Z�[�W
    IF  ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
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
END XXCOS011A02C;
/
