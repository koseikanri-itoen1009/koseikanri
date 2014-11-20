CREATE OR REPLACE PACKAGE BODY APPS.XXCOS013A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS013A02C (body)
 * Description      : INV�ւ̔̔����уf�[�^�A�g
 * MD.050           : INV�ւ̔̔����уf�[�^�A�g MD050_COS_013_A02
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_data               �̔����я��擾(A-2)
 *  get_disposition_id     ����Ȗڕʖ�ID�擾(A-3_01)
 *  get_ccid               ����Ȗ�ID�擾(A-3_02)
 *  make_mtl_tran_data     ���ގ���f�[�^����(A-3)
 *  insert_mtl_tran_oif    ���ގ��OIF�o��(A-4)
 *  update_inv_fsh_flag    �����σX�e�[�^�X�X�V(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/22    1.0   H.Ri             �V�K�쐬
 *  2009/02/13    1.1   H.Ri             [COS_076]���ގ��OIF�̐ݒ荀�ڂ�ύX
 *  2009/02/17    1.2   H.Ri             get_msg�̃p�b�P�[�W���C��
 *  2009/02/20    1.3   H.Ri             �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/04/28    1.4   N.Maeda          ���ގ��OIF�f�[�^�̏W������ɕ���R�[�h��ǉ�
 *  2009/05/13    1.5   K.Kiriu          [T1_0984]���i�A���i����̒ǉ�
 *  2009/06/17    1.6   K.Kiriu          [T1_1472]�������0�̃f�[�^�Ή�
 *  2009/07/16    1.7   K.Kiriu          [0000701]PT�Ή�
 *  2009/07/29    1.8   N.Maeda          [0000863]PT�Ή�
 *  2009/08/06    1.8   N.Maeda          [0000942]PT�Ή�
 *  2009/08/24    1.9   N.Maeda          [0001141]�[�i���l���Ή�
 *  2009/08/25    1.10  N.Maeda          [0001164]PT�Ή�(�x���f�[�^�̃t���O�X�V�����ǉ�[W])
 *                                                �����ΏۊO�f�[�^�̃t���O�X�V�����ǉ�[S]
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** �f�[�^�o�^��O ***
  global_data_insert_expt           EXCEPTION;
  --*** �Ώۃf�[�^���b�N��O ***
  global_data_lock_expt             EXCEPTION;
  --*** �f�[�^���o��O ***
  global_data_select_expt           EXCEPTION;
  --*** �Ώۃf�[�^�X�V��O ***
  global_data_update_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS013A02C';         --�p�b�P�[�W��
  cv_conc_name              CONSTANT  VARCHAR2(100) := 'XXCOS013A02C';         --�R���J�����g��
  cv_xxcos_short_name       CONSTANT  VARCHAR2(100) := 'XXCOS';                --�̕��̈�Z�k�A�v����
  cv_xxccp_short_name       CONSTANT  VARCHAR2(100) := 'XXCCP';                --���ʗ̈�Z�k�A�v����
  cv_xxcoi_short_name       CONSTANT  VARCHAR2(100) := 'XXCOI';                --�݌ɗ̈�Z�k�A�v����
  --���b�Z�[�W
  cv_msg_insert_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00010';     --�f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_lock_err           CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00001';     --���b�N�擾�G���[���b�Z�[�W
  cv_msg_update_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00011';     --�f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_proc_date_err      CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00014';     --�Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_prof_err           CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00004';     --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_org_cd_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOI1-00005';     --�݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_org_id_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOI1-00006';     --�݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_com_cd_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOI1-00007';     --��ЃR�[�h�擾�G���[���b�Z�[�W
  cv_msg_select_err         CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00013';     --�f�[�^���o�G���[���b�Z�[�W
  cv_msg_no_data_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00003';     --�Ώۃf�[�^�����G���[���b�Z�[�W
  cv_msg_type_jor_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12805';     --����^�C�v�^�d��p�^�[���擾�G���[
  cv_msg_src_type_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12802';     --����\�[�X�^�C�vID�擾�G���[
  cv_msg_type_err           CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12803';     --����^�C�vID�擾�G���[���b�Z�[�W
  cv_msg_cok_prof_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00003';     --�v���t�@�C���擾�G���[(�ʗ̈�)
  cv_msg_dispt_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12811';     --����Ȗڕʖ�ID�擾�G���[���b�Z�[�W
  cv_msg_ccid_err           CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12812';     --����Ȗ�ID(CCID)�擾�G���[���b�Z�[�W
/* 2009/07/16 Ver1.6 Add Start */
  cv_msg_category_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12817';     --�J�e�S���Z�b�gID�擾�G���[���b�Z�[�W
/* 2009/07/16 Ver1.6 Add End   */
-- ************ 2009/07/29 N.Maeda 1.8 ADD START *********************** --
  cv_msg_category_id        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12818';     --�J�e�S��ID�擾�G���[���b�Z�[�W
-- ************ 2009/07/29 N.Maeda 1.8 ADD  END  *********************** --
-- ************************ 2009/08/25 1.10 N.Maeda ADD START *************************** --
  cv_msg_sales_exp_nomal    CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12819'; -- �̔����і���(����I���f�[�^)
  cv_msg_sales_exp_warn     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12820'; -- �̔����і���(�x���I���f�[�^)
  cv_msg_sales_exp_exclu    CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12821'; -- �̔����і���(�����ΏۊO�f�[�^)
-- ************************ 2009/08/25 1.10 N.Maeda ADD  END  *************************** --
  --�g�[�N����
  cv_tkn_nm_table_name      CONSTANT  VARCHAR2(100) := 'TABLE_NAME';           --�e�[�u������
  cv_tkn_nm_table_lock      CONSTANT  VARCHAR2(100) := 'TABLE';                --�e�[�u������(���b�N�G���[���p)
  cv_tkn_nm_key_data        CONSTANT  VARCHAR2(100) := 'KEY_DATA';             --�L�[�f�[�^
  cv_tkn_nm_profile_s       CONSTANT  VARCHAR2(100) := 'PROFILE';              --�v���t�@�C����(�̔��̈�)
  cv_tkn_nm_profile_i       CONSTANT  VARCHAR2(100) := 'PRO_TOK';              --�v���t�@�C����(�݌ɗ̈�)
  cv_tkn_nm_profile_k       CONSTANT  VARCHAR2(100) := 'PROFILE';              --�v���t�@�C����(�ʗ̈�)
  cv_tkn_nm_org_cd          CONSTANT  VARCHAR2(100) := 'ORG_CODE_TOK';         --�݌ɑg�D�R�[�h
  cv_tkn_nm_red_blk         CONSTANT  VARCHAR2(100) := 'RED_BLK';              --�ԍ��t���O
  cv_tkn_nm_dlv_inv         CONSTANT  VARCHAR2(100) := 'DLV_INV';              --�[�i�`�[�敪
  cv_tkn_nm_dlv_ptn         CONSTANT  VARCHAR2(100) := 'DLV_PTN';              --�[�i�`�ԋ敪
  cv_tkn_nm_sale_cls        CONSTANT  VARCHAR2(100) := 'SALE_CLS';             --����敪
  cv_tkn_nm_item_cls        CONSTANT  VARCHAR2(100) := 'ITEM_CLS';             --���i���i�敪
  cv_tkn_nm_src_type        CONSTANT  VARCHAR2(100) := 'SOURCE_TYPE';          --����\�[�X�^�C�v��
  cv_tkn_nm_type            CONSTANT  VARCHAR2(100) := 'TYPE';                 --����^�C�v��
  cv_tkn_nm_line_id         CONSTANT  VARCHAR2(100) := 'LINE_ID';              --�̔����і���ID
  cv_tkn_nm_org_id          CONSTANT  VARCHAR2(100) := 'ORG_ID';               --�݌ɑg�DID
  cv_tkn_nm_dept_cd         CONSTANT  VARCHAR2(100) := 'DEPT_CODE';            --����R�[�h
  cv_tkn_nm_inv_acc         CONSTANT  VARCHAR2(100) := 'INV_ACC';              --���o�Ɋ���敪
  cv_tkn_nm_com_cd          CONSTANT  VARCHAR2(100) := 'COM_CODE';             --��ЃR�[�h
  cv_tkn_nm_acc_cd          CONSTANT  VARCHAR2(100) := 'ACC_CODE';             --����ȖڃR�[�h
  cv_tkn_nm_ass_cd          CONSTANT  VARCHAR2(100) := 'ASS_CODE';             --�⏕�ȖڃR�[�h
  cv_tkn_nm_cust_cd         CONSTANT  VARCHAR2(100) := 'CUST_CODE';            --�ڋq�R�[�h
  cv_tkn_nm_ent_cd          CONSTANT  VARCHAR2(100) := 'ENT_CODE';             --��ƃR�[�h
  cv_tkn_nm_res1_cd         CONSTANT  VARCHAR2(100) := 'RES1_CODE';            --�\���P�R�[�h
  cv_tkn_nm_res2_cd         CONSTANT  VARCHAR2(100) := 'RES2_CODE';            --�\���Q�R�[�h
  --�g�[�N���l
  cv_msg_vl_key_request_id  CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00088';     --�v��ID
  cv_msg_vl_min_date        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00120';     --MIN���t
  cv_msg_vl_max_date        CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-00056';     --MAX���t
  cv_msg_vl_table_name1     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12806';     --�̔����і��׃e�[�u����
  cv_msg_vl_table_name2     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12807';     --���ގ��OIF�e�[�u����
  cv_msg_vl_table_name3     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12808';     --����\�[�X�^�C�v�e�[�u��
  cv_msg_vl_table_name4     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12809';     --����^�C�v�e�[�u��
  cv_msg_vl_table_name5     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12801';--�N�C�b�N�R�[�h(����^�C�v/�d��p�^�[������)
  cv_msg_vl_table_name6     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12804';--�N�C�b�N�R�[�h(�[�i�`�ԋ敪����)
  cv_msg_vl_table_name7     CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12810';--�N�C�b�N�R�[�h(����\�[�X�^�C�v����)
  cv_msg_vl_dummy_cust      CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12813';     --XXCOK:�ڋq�R�[�h_�_�~�[�l
  cv_msg_vl_dummy_ent       CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12814';     --XXCOK:��ƃR�[�h_�_�~�[�l
  cv_msg_vl_dummy_res1      CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12815';     --XXCOK:�\���P_�_�~�[�l
  cv_msg_vl_dummy_res2      CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12816';     --XXCOK:�\���Q_�_�~�[�l
  --���t�t�H�[�}�b�g
  cv_yyyymmdd               CONSTANT  VARCHAR2(100) := 'YYYYMMDD';             --YYYYMMDD�^
  cv_yyyy_mm_dd             CONSTANT  VARCHAR2(100) := 'YYYY/MM/DD';           --YYYY/MM/DD�^
  cv_yyyy_mm                CONSTANT  VARCHAR2(100) := 'YYYY/MM';              --YYYY/MM�^
  --�N�C�b�N�R�[�h�Q�Ɨp
  ct_enabled_flg_y          CONSTANT  fnd_lookup_values.enabled_flag%TYPE := 'Y';       --�g�p�\�t���O
  cv_lang                   CONSTANT  VARCHAR2(100) := USERENV( 'LANG' );               --����
  cv_dlv_slp_cls_type       CONSTANT  VARCHAR2(100) := 'XXCOS1_DLV_SLP_CLS_MST_013_A02';--�[�i�`�[�敪�̃N�C�b�N�^�C�v
  cv_dlv_slp_cls_code       CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02%';                --�[�i�`�[�敪�̃N�C�b�N�R�[�h
  cv_dlv_ptn_cls_type       CONSTANT  VARCHAR2(100) := 'XXCOS1_DLV_PTN_MST_013_A02';    --�[�i�`�ԋ敪�̃N�C�b�N�^�C�v
  cv_dlv_ptn_cls_code       CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02%';                --�[�i�`�ԋ敪�̃N�C�b�N�R�[�h
  cv_dlv_ptn_dir_code       CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02_02';              --�H�꒼���̃N�C�b�N�R�[�h
  cv_sale_cls_type          CONSTANT  VARCHAR2(100) := 'XXCOS1_SALE_CLASS_MST_013_A02'; --����敪�̃N�C�b�N�^�C�v
  cv_sale_cls_code          CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02%';                --����敪�̃N�C�b�N�R�[�h
  cv_no_inv_item_type       CONSTANT  VARCHAR2(100) := 'XXCOS1_NO_INV_ITEM_CODE';       --��݌ɕi�ڂ̃N�C�b�N�^�C�v
  cv_txn_src_type           CONSTANT  VARCHAR2(100) := 'XXCOS1_TXN_SRC_MST_013_A02';--����\�[�X�^�C�v�̃N�C�b�N�^�C�v
  cv_txn_src_code           CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02%';            --����\�[�X�^�C�v�̃N�C�b�N�R�[�h
  cv_another_nm_code        CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02_02';          --����Ȗڕʖ��̃N�C�b�N�R�[�h
  cv_txn_type_type          CONSTANT  VARCHAR2(100) := 'XXCOS1_TXN_TYPE_MST_013_A02';   --����^�C�v�̃N�C�b�N�^�C�v
  cv_txn_type_code          CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02%';                --����^�C�v�̃N�C�b�N�R�[�h
  cv_txn_jor_type           CONSTANT  VARCHAR2(100) := 'XXCOS1_INV_TXN_JOR_CLS_013_A02';--����^�C�v�E�d��p�^�[��
  cv_red_black_type         CONSTANT  VARCHAR2(100) := 'XXCOS1_RED_BLACK_FLAG';         --�ԍ��t���O�̃N�C�b�N�^�C�v
  cv_goods_prod_type        CONSTANT  VARCHAR2(100) := 'XXCOS1_GOOD_PROD_CLS_013_A02';  --���i���i�敪�̃N�C�b�N�^�C�v
  cv_goods_prod_code        CONSTANT  VARCHAR2(100) := 'XXCOS_013_A02%';                --���i���i�敪�̃N�C�b�N�R�[�h
  --�v���t�@�C���֘A
  cv_prof_min_date          CONSTANT  VARCHAR2(100) := 'XXCOS1_MIN_DATE';      --�v���t�@�C����(MIN���t)
  cv_prof_max_date          CONSTANT  VARCHAR2(100) := 'XXCOS1_MAX_DATE';      --�v���t�@�C����(MAX���t)
  cv_prof_org               CONSTANT  VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE';--�v���t�@�C����(�݌ɑg�D�R�[�h)
  cv_prof_com_code          CONSTANT  VARCHAR2(100) := 'XXCOI1_COMPANY_CODE';     --�v���t�@�C����(��ЃR�[�h)
  cv_prof_cust_dummy        CONSTANT  VARCHAR2(100) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';    -- �ڋq�R�[�h_�_�~�[�l
  cv_prof_ent_dummy         CONSTANT  VARCHAR2(100) := 'XXCOK1_AFF6_COMPANY_DUMMY';     -- ��ƃR�[�h_�_�~�[�l
  cv_prof_res1_dummy        CONSTANT  VARCHAR2(100) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';-- �\��1_�_�~�[�l
  cv_prof_res2_dummy        CONSTANT  VARCHAR2(100) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';-- �\��2_�_�~�[�l
/* 2009/07/16 Ver1.7 Add Start */
  cv_prof_g_prd_class       CONSTANT  VARCHAR2(100) := 'XXCOI1_GOODS_PRODUCT_CLASS';    --���i���i�敪�J�e�S���Z�b�g��
  --���i���i�敪���t����p
  cd_sysdate                CONSTANT  DATE          := SYSDATE;
/* 2009/07/16 Ver1.7 Add Start */
  --�J�e�S���^�X�e�[�^�X
  cv_inv_flg_n              CONSTANT  VARCHAR2(100) := 'N';                    --�݌ɖ��A�g
  cv_inv_flg_y              CONSTANT  VARCHAR2(100) := 'Y';                    --�݌ɘA�g��
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
  cv_wan_data_flg           CONSTANT  VARCHAR2(1)   := 'W';                    --INV�A�g�x���f�[�^
  cv_excluded_flg           CONSTANT  VARCHAR2(1)   := 'S';                    --INV�A�g�ΏۊO
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
/* 2009/05/13 Ver1.5 Add Start */
  --���i���i�敪
  cv_goods_prod_sei         CONSTANT  VARCHAR2(1)   := '2';  -- �i�ڋ敪�F���i= 2
/* 2009/05/13 Ver1.5 Add End   */
--
-- ************ 2009/07/29 N.Maeda 1.8 ADD START *********************** --
  cv_goods_prod_item        CONSTANT  VARCHAR2(1)   := '1';  -- ���i
-- ************ 2009/07/29 N.Maeda 1.8 ADD  END  *********************** --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --�̔����уf�[�^���R�[�h�^
  TYPE g_rec_sales_exp_rtype IS RECORD (
    line_id                     xxcos_sales_exp_lines.sales_exp_line_id%TYPE,            --�̔����і���ID
    dlv_date                    xxcos_sales_exp_headers.delivery_date%TYPE,              --�[�i��
    dlv_invoice_class           xxcos_sales_exp_headers.dlv_invoice_class%TYPE,          --�[�i�`�[�敪
    sales_base_code             xxcos_sales_exp_headers.sales_base_code%TYPE,            --���㋒�_�R�[�h
    dlv_pattern_class           xxcos_sales_exp_lines.delivery_pattern_class%TYPE,       --�[�i�`�ԋ敪
    sales_class                 xxcos_sales_exp_lines.sales_class%TYPE,                  --����敪
    red_black_flag              xxcos_sales_exp_lines.red_black_flag%TYPE,               --�ԍ��t���O
    standard_uom_code           xxcos_sales_exp_lines.standard_uom_code%TYPE,            --��P��
    standard_qty                xxcos_sales_exp_lines.standard_qty%TYPE,                 --�����
    shipment_from_code          xxcos_sales_exp_lines.ship_from_subinventory_code%TYPE,  --�o�׌��ۊǏꏊ
    inventory_item_id           xxcos_good_prod_class_v.inventory_item_id%TYPE,          --�i��ID
    goods_prod_class            xxcos_good_prod_class_v.goods_prod_class_code%TYPE       --���i���i�敪
  );
  --�̔����уf�[�^�R���N�V�����^
  TYPE g_sales_exp_ttype IS TABLE OF g_rec_sales_exp_rtype INDEX BY BINARY_INTEGER;
  --����\�[�X�^�C�v���R�[�h�^
  TYPE g_rec_txn_src_type_rtype IS RECORD (
    txn_src_type_id             mtl_txn_source_types.transaction_source_type_id%TYPE,    --����\�[�X�^�C�vID
    txn_src_type_nm             mtl_txn_source_types.transaction_source_type_name%TYPE   --����\�[�X�^�C�v��
  );
  --����\�[�X�^�C�v�R���N�V�����^
  TYPE g_txn_src_type_ttype IS TABLE OF g_rec_txn_src_type_rtype INDEX BY BINARY_INTEGER;
  --����^�C�v���R�[�h�^
  TYPE g_rec_txn_type_rtype IS RECORD (
    txn_type_id                 mtl_transaction_types.transaction_type_id%TYPE,          --����^�C�vID
    txn_type_nm                 mtl_transaction_types.transaction_type_name%TYPE         --����^�C�v��
  );
  --����^�C�v�R���N�V�����^
  TYPE g_txn_type_ttype IS TABLE OF g_rec_txn_type_rtype INDEX BY BINARY_INTEGER;
  --����^�C�v�^�d��p�^�[���}�b�s���O�\���R�[�h�^
  TYPE g_rec_jor_map_rtype IS RECORD (
    --���͕�
    red_black_flg               xxcos_sales_exp_lines.red_black_flag%TYPE,               --�ԍ��t���O
    dlv_invoice_class           xxcos_sales_exp_headers.dlv_invoice_class%TYPE,          --�[�i�`�[�敪
    dlv_pattern_class           xxcos_sales_exp_lines.delivery_pattern_class%TYPE,       --�[�i�`�ԋ敪
    sales_class                 xxcos_sales_exp_lines.sales_class%TYPE,                  --����敪
    goods_prod_class            xxcos_good_prod_class_v.goods_prod_class_code%TYPE,      --���i���i�敪
    --�o�͕�
    txn_src_type                mtl_txn_source_types.transaction_source_type_name%TYPE,  --����\�[�X�^�C�v
    txn_type                    mtl_transaction_types.transaction_type_name%TYPE,        --����^�C�v
    in_out_cls                  VARCHAR2(1),                                             --���o�ɋ敪
    dept_code                   VARCHAR2(20),                                            --����R�[�h
    acc_item                    VARCHAR2(20),                                            --����ȖڃR�[�h
    ass_item                    VARCHAR2(20)                                             --�⏕�ȖڃR�[�h
  );
  --����^�C�v�^�d��p�^�[���}�b�s���O�\�R���N�V�����^
  TYPE g_jor_map_ttype IS TABLE OF g_rec_jor_map_rtype INDEX BY BINARY_INTEGER;
  --���ގ��OIF���R�[�h�^
  TYPE g_rec_mtl_txn_oif_rtype IS RECORD (
    source_code                 mtl_transactions_interface.source_code%TYPE,             --�\�[�X�R�[�h
    source_line_id              mtl_transactions_interface.source_line_id%TYPE,          --�\�[�X����ID
    source_header_id            mtl_transactions_interface.source_header_id%TYPE,        --�\�[�X�w�b�_�[ID
    process_flag                mtl_transactions_interface.process_flag%TYPE,            --�����t���O
    validation_required         mtl_transactions_interface.validation_required%TYPE,     --���ؗv
    transaction_mode            mtl_transactions_interface.transaction_mode%TYPE,        --������[�h
    inventory_item_id           mtl_transactions_interface.inventory_item_id%TYPE,       --����i��ID
    organization_id             mtl_transactions_interface.organization_id%TYPE,         --������̑g�DID
    transaction_quantity        mtl_transactions_interface.transaction_quantity%TYPE,    --�������
    transaction_uom             mtl_transactions_interface.transaction_uom%TYPE,         --����P��
    transaction_date            mtl_transactions_interface.transaction_date%TYPE,        --���������
    subinventory_code           mtl_transactions_interface.subinventory_code%TYPE,       --������̕ۊǏꏊ��
    transaction_source_id       mtl_transactions_interface.transaction_source_id%TYPE,   --����\�[�XID
    transaction_source_type_id  mtl_transactions_interface.transaction_source_type_id%TYPE, --����\�[�X�^�C�vID
    transaction_type_id         mtl_transactions_interface.transaction_type_id%TYPE,     --����^�C�vID
    scheduled_flag              mtl_transactions_interface.scheduled_flag%TYPE,          --�v��t���O
    flow_schedule               mtl_transactions_interface.flow_schedule%TYPE,           --�v��t���[
    created_by                  mtl_transactions_interface.created_by%TYPE,              --�쐬��ID
    creation_date               mtl_transactions_interface.creation_date%TYPE,           --�쐬��
    last_updated_by             mtl_transactions_interface.last_updated_by%TYPE,         --�ŏI�X�V��ID
    last_update_date            mtl_transactions_interface.last_update_date%TYPE,        --�ŏI�X�V��
    last_update_login           mtl_transactions_interface.last_update_login%TYPE,       --�ŏI���O�C��ID
    request_id                  mtl_transactions_interface.request_id%TYPE,              --�v��ID
    program_application_id      mtl_transactions_interface.program_application_id%TYPE,  --�v���O�����A�v���P�[�V����ID
    program_id                  mtl_transactions_interface.program_id%TYPE,              --�v���O����ID
    program_update_date         mtl_transactions_interface.program_update_date%TYPE,     --�v���O�����X�V��
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
    sales_exp_line_id           xxcos_sales_exp_lines.sales_exp_line_id%TYPE,            --�̔����і���ID
    dept_code                   VARCHAR2(20)                                             --����R�[�h
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
  );
  --���ގ��OIF�R���N�V�����^
  TYPE g_mtl_txn_oif_ttype IS TABLE OF g_rec_mtl_txn_oif_rtype INDEX BY BINARY_INTEGER;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
  TYPE g_mtl_txn_oif_ttype_var IS TABLE OF g_rec_mtl_txn_oif_rtype INDEX BY VARCHAR(1000);
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
  --����Ȗڕʖ����R�[�h�^
  TYPE g_rec_disposition_rtype IS RECORD (
    org_id                  mtl_generic_dispositions.organization_id%TYPE,               --�݌ɑg�DID
    dept_code               mtl_generic_dispositions.segment1%TYPE,                      --����R�[�h
    inv_acc_cls             mtl_generic_dispositions.segment2%TYPE,                      --���o�Ɋ���敪
    disposition_id          mtl_generic_dispositions.disposition_id%TYPE                 --����Ȗڕʖ�ID
  );
  --����Ȗڕʖ��R���N�V�����^
  TYPE g_disposition_ttype IS TABLE OF g_rec_disposition_rtype INDEX BY BINARY_INTEGER;
  --����Ȗ�ID(CCID)���R�[�h�^
  TYPE g_rec_ccid_rtype IS RECORD (
    com_code                gl_code_combinations.segment1%TYPE,                          --��ЃR�[�h
    dept_code               gl_code_combinations.segment2%TYPE,                          --����R�[�h
    acc_code                gl_code_combinations.segment3%TYPE,                          --����ȖڃR�[�h
    ass_code                gl_code_combinations.segment4%TYPE,                          --�⏕�ȖڃR�[�h
    cust_code               gl_code_combinations.segment5%TYPE,                          --�ڋq�R�[�h
    ent_code                gl_code_combinations.segment6%TYPE,                          --��ƃR�[�h
    res_code1               gl_code_combinations.segment7%TYPE,                          --�\���P�R�[�h
    res_code2               gl_code_combinations.segment8%TYPE,                          --�\���Q�R�[�h
    ccid                    gl_code_combinations.code_combination_id%TYPE                --����Ȗ�ID(CCID)
  );
  --����Ȗ�ID(CCID)�R���N�V�����^
  TYPE g_ccid_ttype IS TABLE OF g_rec_ccid_rtype INDEX BY BINARY_INTEGER;
--************************************* 2009/08/25 N.Maeda Var1.10 ADD START *********************************************
  TYPE g_tab_sales_exp_line_id   IS TABLE OF xxcos_sales_exp_lines.sales_exp_line_id%TYPE
    INDEX BY PLS_INTEGER;
  gt_sales_exp_line_id       g_tab_sales_exp_line_id;      -- �̔����і���ID
--************************************* 2009/08/25 N.Maeda Var1.10 ADD  END  *********************************************
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  g_sales_exp_tab           g_sales_exp_ttype;                                  --�̔����уf�[�^�R���N�V����
  gd_proc_date              DATE;                                               --�Ɩ����t
  gd_min_date               DATE;                                               --MIN���t
  gd_max_date               DATE;                                               --MAX���t
  gt_org_id                 mtl_parameters.organization_id%TYPE;                --�݌ɑg�DID
  gv_com_code               VARCHAR2(100);                                      --��ЃR�[�h
  gv_cust_dummy             VARCHAR2(100);                                      --�ڋq�R�[�h(�_�~�[�l)
  gv_ent_dummy              VARCHAR2(100);                                      --��ƃR�[�h(�_�~�[�l)
  gv_res1_dummy             VARCHAR2(100);                                      --�\���P�R�[�h(�_�~�[�l)
  gv_res2_dummy             VARCHAR2(100);                                      --�\���Q�R�[�h(�_�~�[�l)
/* 2009/07/16 Ver1.7 Add Start */
  gt_category_set_id        mtl_category_sets_tl.category_set_id%TYPE;          --�J�e�S���Z�b�gID
/* 2009/07/16 Ver1.7 Add End   */
-- ************ 2009/07/29 N.Maeda 1.8 ADD START *********************** --
  gt_category_id            mtl_categories_b.category_id%TYPE;  -- �J�e�S��ID
-- ************ 2009/07/29 N.Maeda 1.8 ADD  END  *********************** --
  g_mtl_txn_oif_tab         g_mtl_txn_oif_ttype;                                --���ގ��OIF�R���N�V����
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
  g_mtl_txn_oif_tab_spare   g_mtl_txn_oif_ttype_var;
  g_mtl_txn_oif_ins_tab     g_mtl_txn_oif_ttype;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
  g_disposition_tab         g_disposition_ttype;                                --����Ȗڕʖ��R���N�V����
  g_ccid_tab                g_ccid_ttype;                                       --����Ȗ�ID(CCID)�R���N�V����
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                 -- �v���O������
    cv_msg_no_para  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';     -- �p�����[�^�������b�Z�[�W��
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
    lv_no_para_msg  VARCHAR2(5000);                         -- �p�����[�^�������b�Z�[�W
    lv_date_item    VARCHAR2(100);                          -- MIN���t/MAX���t
    lv_dummy_item   VARCHAR2(100);                          -- CCID�擾�p�_�~�[����
    lt_org_cd       mtl_parameters.organization_code%TYPE;  -- �݌ɑg�D�R�[�h
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
    --========================================
    -- 1.�p�����[�^�������b�Z�[�W�o�͏���
    --========================================
    lv_no_para_msg            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxccp_short_name,
        iv_name               =>  cv_msg_no_para
      );
    --���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_no_para_msg
    );
    --��s�}��(�o��)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --��s�}��(���O)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --���b�Z�[�W���O
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_no_para_msg
    );
    --��s�}��(���O)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --========================================
    -- 2.�Ɩ����t�擾����
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
    -- 3.MIN���t�擾����
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
        iv_token_name1        =>  cv_tkn_nm_profile_s,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 4.MAX���t�擾����
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
        iv_token_name1        =>  cv_tkn_nm_profile_s,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 5.�݌ɑg�D�R�[�h�擾����
    --========================================
    lt_org_cd := FND_PROFILE.VALUE( cv_prof_org );
    IF ( lt_org_cd IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcoi_short_name,
        iv_name               =>  cv_msg_org_cd_err,
        iv_token_name1        =>  cv_tkn_nm_profile_i,
        iv_token_value1       =>  cv_prof_org
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 6.�݌ɑg�DID�擾����
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
    -- 7.��ЃR�[�h�擾����
    --========================================
    gv_com_code := FND_PROFILE.VALUE( cv_prof_com_code );
    IF ( gv_com_code IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcoi_short_name,
        iv_name               =>  cv_msg_com_cd_err,
        iv_token_name1        =>  cv_tkn_nm_profile_i,
        iv_token_value1       =>  cv_prof_com_code
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 8.�ڋq�R�[�h(�_�~�[�l)�擾����
    --========================================
    gv_cust_dummy := FND_PROFILE.VALUE( cv_prof_cust_dummy );
    IF ( gv_cust_dummy IS NULL ) THEN
      lv_dummy_item           :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_dummy_cust
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile_s,
        iv_token_value1       =>  lv_dummy_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 9.��ƃR�[�h(�_�~�[�l)�擾����
    --========================================
    gv_ent_dummy := FND_PROFILE.VALUE( cv_prof_ent_dummy );
    IF ( gv_ent_dummy IS NULL ) THEN
      lv_dummy_item           :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_dummy_ent
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile_s,
        iv_token_value1       =>  lv_dummy_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 10.�\���P�R�[�h(�_�~�[�l)�擾����
    --========================================
    gv_res1_dummy := FND_PROFILE.VALUE( cv_prof_res1_dummy );
    IF ( gv_res1_dummy IS NULL ) THEN
      lv_dummy_item           :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_dummy_res1
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile_s,
        iv_token_value1       =>  lv_dummy_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 11.�\���Q�R�[�h(�_�~�[�l)�擾����
    --========================================
    gv_res2_dummy := FND_PROFILE.VALUE( cv_prof_res2_dummy );
    IF ( gv_res2_dummy IS NULL ) THEN
      lv_dummy_item           :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_dummy_res2
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile_s,
        iv_token_value1       =>  lv_dummy_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
/* 2009/07/16 Ver1.7 Add Start */
    --========================================
    -- 12.�J�e�S���Z�b�gID�擾����
    --========================================
    BEGIN
      SELECT mcst.category_set_id
      INTO   gt_category_set_id
      FROM   mtl_category_sets_tl mcst
      WHERE  mcst.category_set_name = FND_PROFILE.VALUE( cv_prof_g_prd_class )
      AND    mcst.language          = cv_lang;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg               :=  xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_category_err
        );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
/* 2009/07/16 Ver1.7 Add End   */
-- ************ 2009/07/29 N.Maeda 1.8 ADD START *********************** --
--
    -- =======================================
    -- 13.�J�e�S��ID�擾
    -- =======================================
    BEGIN
      SELECT  mcb.category_id       category_id  -- �J�e�S��ID
      INTO    gt_category_id
      FROM    mtl_category_sets_b   mcsb  -- �J�e�S���Z�b�g�}�X�^
              ,mtl_categories_b     mcb   -- �J�e�S���}�X�^
      WHERE   mcsb.category_set_id = gt_category_set_id
      AND     mcsb.structure_id    = mcb.structure_id
      AND     mcb.segment1         = cv_goods_prod_item
      AND    (
              mcb.disable_date IS NULL
             OR
              mcb.disable_date > cd_sysdate
             )
      AND    mcb.enabled_flag        = ct_enabled_flg_y
      AND    cd_sysdate              BETWEEN NVL( mcb.start_date_active, cd_sysdate ) 
                                     AND     NVL( mcb.end_date_active, cd_sysdate );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg      :=  xxccp_common_pkg.get_msg(
                                   iv_application   =>  cv_xxcos_short_name,
                                   iv_name          =>  cv_msg_category_id
                                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
-- ************ 2009/07/29 N.Maeda 1.8 ADD  END  *********************** --
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
   * Procedure Name   : get_data
   * Description      : �����Ώۃf�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_tkn_vl_table_name      VARCHAR2(100);      --�G���[�Ώۂł���e�[�u����
    lv_warnmsg                VARCHAR2(5000);     --���[�U�[�E�x���E���b�Z�[�W
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
--
-- ************************ 2009/08/06 1.18 N.Maeda MOD START *************************** --
--
    --�Ώۃf�[�^�擾
    SELECT /*+
           index(sel XXCOS_SALES_EXP_LINES_N03)
           index(seh XXCOS_SALES_EXP_HEADERS_PK)
           index(mcb MTL_CATEGORIES_B_U1)
           leading(sel seh msib mic mcb)
           use_nl(sel seh msib mic mcb)
           */
           sel.sales_exp_line_id line_id,         --�̔����і���ID
           seh.delivery_date,                     --�[�i��
           seh.dlv_invoice_class,                 --�[�i�`�[�敪
           seh.sales_base_code,                   --���㋒�_�R�[�h
           sel.delivery_pattern_class,            --�[�i�`�ԋ敪
           sel.sales_class,                       --����敪
           sel.red_black_flag,                    --�ԍ��t���O
           sel.standard_uom_code,                 --��P��
           sel.standard_qty,                      --�����
           sel.ship_from_subinventory_code,       --�o�׌��ۊǏꏊ
           msib.inventory_item_id,                --�i��ID
           CASE
             WHEN 
               ( NOT EXISTS ( SELECT 1
                              FROM mtl_category_accounts mca
                              WHERE mca.category_id     = gt_category_id
                              AND mca.organization_id   = gt_org_id
                              AND mca.subinventory_code = sel.ship_from_subinventory_code
                              AND ROWNUM = 1 ) ) THEN  --���X�ȊO
               cv_goods_prod_sei  --���i�Œ�
             ELSE
               mcb.segment1
           END
    BULK COLLECT INTO
           g_sales_exp_tab
    FROM   xxcos_sales_exp_headers  seh,          --�̔����уw�b�_�e�[�u��
           xxcos_sales_exp_lines    sel,          --�̔����і��׃e�[�u��
           mtl_system_items_b     msib,  --�i�ڃ}�X�^
           mtl_item_categories    mic,   --�i�ڃJ�e�S���}�X�^
           mtl_categories_b       mcb    --�J�e�S���}�X�^
           --�̔����уw�b�_.�w�b�_ID=�̔����і���.�w�b�_ID
    WHERE  seh.sales_exp_header_id = sel.sales_exp_header_id
           --�[�i��<=�Ɩ����t
    AND    seh.delivery_date       <= gd_proc_date
           --�[�i�`�[�敪 IN(�[�i,�ԕi,�[�i����,�ԕi����)
    AND    EXISTS(
             SELECT  /*+ use_nl(look_val) */
                     'Y'                         ext_flg
             FROM    fnd_lookup_values           look_val
             WHERE   look_val.lookup_type        = cv_dlv_slp_cls_type
             AND     look_val.lookup_code        LIKE cv_dlv_slp_cls_code
             AND     look_val.meaning            = seh.dlv_invoice_class
             AND     look_val.language           = cv_lang
             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                                 AND     NVL( look_val.end_date_active, gd_max_date )
             AND     look_val.enabled_flag       = ct_enabled_flg_y
           )
           --�[�i�`�ԋ敪 IN(�c�Ǝ�,�H�꒼��,���C���q��, ���q��,�����_�q�ɔ���)
    AND    EXISTS(
             SELECT  /*+ use_nl(look_val) */
                     'Y'                         ext_flg
             FROM    fnd_lookup_values           look_val
             WHERE   look_val.lookup_type        = cv_dlv_ptn_cls_type
             AND     look_val.lookup_code        LIKE cv_dlv_ptn_cls_code
             AND     look_val.meaning            = sel.delivery_pattern_class
             AND     look_val.language           = cv_lang
             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                                 AND     NVL( look_val.end_date_active, gd_max_date )
             AND     look_val.enabled_flag       = ct_enabled_flg_y
           )
           --��݌ɕi�ڂ��揜��
    AND    NOT EXISTS(
             SELECT  /*+ use_nl(look_val) */
                     'Y'                         ext_flg
             FROM    fnd_lookup_values           look_val
             WHERE   look_val.lookup_type        = cv_no_inv_item_type
             AND     look_val.lookup_code        = sel.item_code
             AND     look_val.language           = cv_lang
             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                                 AND     NVL( look_val.end_date_active, gd_max_date )
             AND     look_val.enabled_flag       = ct_enabled_flg_y
           )
-- ********** 2009/08/25 N.Maeda Var1.10 MOD START *********** --
           --INV�C���^�t�F�[�X�σt���O(���A�gorINV�A�g�����x���f�[�^)
    AND    ( ( sel.inv_interface_flag = cv_inv_flg_n )
             OR ( sel.inv_interface_flag = cv_wan_data_flg ) )
--           --INV�C���^�t�F�[�X�σt���O(���A�g)
--    AND    sel.inv_interface_flag       = cv_inv_flg_n
-- ********** 2009/08/25 N.Maeda Var1.10 MOD  END  *********** --
    AND    msib.organization_id     = gt_org_id             -- �݌ɑg�DID
    AND    msib.segment1            = sel.item_code
    AND    msib.enabled_flag        = ct_enabled_flg_y      -- �i�ڃ}�X�^�L���t���O
    AND    gd_proc_date
             BETWEEN NVL(msib.start_date_active, gd_proc_date)
             AND NVL(msib.end_date_active, gd_proc_date)
    AND    mic.organization_id      = msib.organization_id
    AND    mic.inventory_item_id    = msib.inventory_item_id
    AND    mic.category_set_id      = gt_category_set_id
    AND    mic.category_id          = mcb.category_id
    AND    ( mcb.disable_date IS NULL
           OR mcb.disable_date > gd_proc_date
           )
    AND    mcb.enabled_flag        = 'Y'      -- �J�e�S���L���t���O
    AND    gd_proc_date
             BETWEEN NVL(mcb.start_date_active, gd_proc_date)
             AND NVL(mcb.end_date_active, gd_proc_date)
    ORDER BY
           sel.ship_from_subinventory_code,     --�o�׌��ۊǏꏊ
           msib.inventory_item_id,
           seh.delivery_date,                   --�[�i��
           seh.sales_base_code                  --���㋒�_�R�[�h
    FOR UPDATE OF sel.sales_exp_line_id NOWAIT
    ;
--
--    --�Ώۃf�[�^�擾
--    SELECT sel.sales_exp_line_id line_id,         --�̔����і���ID
--           seh.delivery_date,                     --�[�i��
--           seh.dlv_invoice_class,                 --�[�i�`�[�敪
--           seh.sales_base_code,                   --���㋒�_�R�[�h
--           sel.delivery_pattern_class,            --�[�i�`�ԋ敪
--           sel.sales_class,                       --����敪
--           sel.red_black_flag,                    --�ԍ��t���O
--           sel.standard_uom_code,                 --��P��
--           sel.standard_qty,                      --�����
--           sel.ship_from_subinventory_code,       --�o�׌��ۊǏꏊ
---- ************ 2009/07/29 N.Maeda 1.8 MOD START *********************** --
--           msib.inventory_item_id,                --�i��ID
--           CASE
--             WHEN 
--               ( ( SELECT COUNT('X') 
--                   FROM mtl_category_accounts mca
--                   WHERE mca.category_id     = gt_category_id
--                   AND mca.organization_id   = gt_org_id
--                   AND mca.subinventory_code = sel.ship_from_subinventory_code
--                   AND ROWNUM = 1
--                  ) = 0 ) THEN  --���X�ȊO
--               cv_goods_prod_sei  --���i�Œ�
--             ELSE
--               mcb.segment1
--           END
----           gpcv.inventory_item_id,                --�i��ID
----/* 2009/05/13 Ver1.5 Mod Start */
------           gpcv.goods_prod_class_code             --���i���i�敪
----           CASE
----             WHEN mcavd.subinventory_code IS NULL THEN  --���X�ȊO
----               cv_goods_prod_sei  --���i�Œ�
----             ELSE
----               gpcv.goods_prod_class_code
----           END
--/* 2009/05/13 Ver1.5 Mod End   */
--    BULK COLLECT INTO
--           g_sales_exp_tab
--    FROM   xxcos_sales_exp_headers  seh,          --�̔����уw�b�_�e�[�u��
--           xxcos_sales_exp_lines    sel,          --�̔����і��׃e�[�u��
--/* 2009/05/13 Ver1.5 Mod Start */
----           xxcos_good_prod_class_v  gpcv          --���i���i�敪�r���[
--/* 2009/07/16 Ver1.7 Add Start */
----           xxcos_good_prod_class_v  gpcv,         --���i���i�敪�r���[
---- ************ 2009/07/29 N.Maeda 1.8 MOD START *********************** --
--           mtl_system_items_b     msib,  --�i�ڃ}�X�^
--           mtl_item_categories    mic,   --�i�ڃJ�e�S���}�X�^
--           mtl_categories_b       mcb    --�J�e�S���}�X�^
----
----           ( SELECT msib.inventory_item_id inventory_item_id,
----                    msib.segment1          segment1,
----                    mcb.segment1           goods_prod_class_code
----             FROM   mtl_system_items_b     msib,  --�i�ڃ}�X�^
----                    mtl_item_categories    mic,   --�i�ڃJ�e�S���}�X�^
----                    mtl_categories_b       mcb    --�J�e�S���}�X�^
----             WHERE  msib.organization_id    = gt_org_id
----             AND    msib.enabled_flag       = ct_enabled_flg_y
----             AND    cd_sysdate              BETWEEN NVL( msib.start_date_active, cd_sysdate )
----                                            AND     NVL( msib.end_date_active, cd_sysdate)
----             AND    msib.organization_id    = mic.organization_id
----             AND    msib.inventory_item_id  = mic.inventory_item_id
----             AND    mic.category_set_id     = gt_category_set_id
----             AND    mic.category_id         = mcb.category_id
----             AND    (
----                      mcb.disable_date IS NULL
----                    OR
----                      mcb.disable_date > cd_sysdate
----                    )
----             AND    mcb.enabled_flag        = ct_enabled_flg_y
----             AND    cd_sysdate              BETWEEN NVL( mcb.start_date_active, cd_sysdate ) 
----                                            AND     NVL( mcb.end_date_active, cd_sysdate )
----           ) gpcv,                                --���i���i�敪
---- ************ 2009/07/29 N.Maeda 1.8 MOD  END  *********************** --
--/* 2009/07/16 Ver1.7 Add End   */
--/* 2009/05/13 Ver1.5 Mod End   */
--/* 2009/05/13 Ver1.5 Add Start */
---- ************ 2009/07/29 N.Maeda 1.8 DEL START *********************** --
----           ( SELECT DISTINCT
----/* 2009/07/16 Ver1.7 Add Start */
----                    mcav.organization_id     organization_id,
----/* 2009/07/16 Ver1.7 Add End   */
----                    mcav.subinventory_code   subinventory_code
----             FROM   mtl_category_accounts_v  mcav  -- ���XView
----           )                        mcavd
----/* 2009/05/13 Ver1.5 Add End   */
---- ************ 2009/07/29 N.Maeda 1.8 DEL  END  *********************** --
--           --�̔����уw�b�_.�w�b�_ID=�̔����і���.�w�b�_ID
--    WHERE  seh.sales_exp_header_id = sel.sales_exp_header_id
--           --�[�i��<=�Ɩ����t
--    AND    seh.delivery_date       <= gd_proc_date
--/* 2009/07/16 Ver1.7 Mod Start */
----           --�[�i�`�[�敪 IN(�[�i,�ԕi,�[�i����,�ԕi����)
----    AND    EXISTS(
----             SELECT  'Y'                         ext_flg
----             FROM    fnd_lookup_values           look_val,
----                     fnd_lookup_types_tl         types_tl,
----                     fnd_lookup_types            types,
----                     fnd_application_tl          appl,
----                     fnd_application             app
----             WHERE   appl.application_id         = types.application_id
----             AND     app.application_id          = appl.application_id
----             AND     types_tl.lookup_type        = look_val.lookup_type
----             AND     types.lookup_type           = types_tl.lookup_type
----             AND     types.security_group_id     = types_tl.security_group_id
----             AND     types.view_application_id   = types_tl.view_application_id
----             AND     types_tl.language           = cv_lang
----             AND     look_val.language           = cv_lang
----             AND     appl.language               = cv_lang
----             AND     app.application_short_name  = cv_xxcos_short_name
----             AND     look_val.lookup_type        = cv_dlv_slp_cls_type
----             AND     look_val.lookup_code        LIKE cv_dlv_slp_cls_code
----             AND     look_val.meaning            = seh.dlv_invoice_class
----             AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
----             AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
----             AND     look_val.enabled_flag       = ct_enabled_flg_y
----           )
----           --�[�i�`�ԋ敪 IN(�c�Ǝ�,�H�꒼��,���C���q��, ���q��,�����_�q�ɔ���)
----    AND    EXISTS(
----             SELECT  'Y'                         ext_flg
----             FROM    fnd_lookup_values           look_val,
----                     fnd_lookup_types_tl         types_tl,
----                     fnd_lookup_types            types,
----                     fnd_application_tl          appl,
----                     fnd_application             app
----             WHERE   appl.application_id         = types.application_id
----             AND     app.application_id          = appl.application_id
----             AND     types_tl.lookup_type        = look_val.lookup_type
----             AND     types.lookup_type           = types_tl.lookup_type
----             AND     types.security_group_id     = types_tl.security_group_id
----             AND     types.view_application_id   = types_tl.view_application_id
----             AND     types_tl.language           = cv_lang
----             AND     look_val.language           = cv_lang
----             AND     appl.language               = cv_lang
----             AND     app.application_short_name  = cv_xxcos_short_name
----             AND     look_val.lookup_type        = cv_dlv_ptn_cls_type
----             AND     look_val.lookup_code        LIKE cv_dlv_ptn_cls_code
----             AND     look_val.meaning            = sel.delivery_pattern_class
----             AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
----             AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
----             AND     look_val.enabled_flag       = ct_enabled_flg_y
----           )
----           --���i���i�敪
----    AND    sel.item_code       = gpcv.segment1
----           --��݌ɕi�ڂ��揜��
----    AND    NOT EXISTS(
----             SELECT  'Y'                         ext_flg
----             FROM    fnd_lookup_values           look_val,
----                     fnd_lookup_types_tl         types_tl,
----                     fnd_lookup_types            types,
----                     fnd_application_tl          appl,
----                     fnd_application             app
----             WHERE   appl.application_id         = types.application_id
----             AND     app.application_id          = appl.application_id
----             AND     types_tl.lookup_type        = look_val.lookup_type
----             AND     types.lookup_type           = types_tl.lookup_type
----            AND     types.security_group_id     = types_tl.security_group_id
----             AND     types.view_application_id   = types_tl.view_application_id
----             AND     types_tl.language           = cv_lang
----             AND     look_val.language           = cv_lang
----             AND     appl.language               = cv_lang
----             AND     app.application_short_name  = cv_xxcos_short_name
----             AND     look_val.lookup_type        = cv_no_inv_item_type
----             AND     look_val.lookup_code        = sel.item_code
----             AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
----             AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
----             AND     look_val.enabled_flag       = ct_enabled_flg_y
----           )
--           --�[�i�`�[�敪 IN(�[�i,�ԕi,�[�i����,�ԕi����)
--    AND    EXISTS(
--             SELECT  'Y'                         ext_flg
--             FROM    fnd_lookup_values           look_val
--             WHERE   look_val.lookup_type        = cv_dlv_slp_cls_type
--             AND     look_val.lookup_code        LIKE cv_dlv_slp_cls_code
--             AND     look_val.meaning            = seh.dlv_invoice_class
--             AND     look_val.language           = cv_lang
--             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
--                                                 AND     NVL( look_val.end_date_active, gd_max_date )
--             AND     look_val.enabled_flag       = ct_enabled_flg_y
--           )
--           --�[�i�`�ԋ敪 IN(�c�Ǝ�,�H�꒼��,���C���q��, ���q��,�����_�q�ɔ���)
--    AND    EXISTS(
--             SELECT  'Y'                         ext_flg
--             FROM    fnd_lookup_values           look_val
--             WHERE   look_val.lookup_type        = cv_dlv_ptn_cls_type
--             AND     look_val.lookup_code        LIKE cv_dlv_ptn_cls_code
--             AND     look_val.meaning            = sel.delivery_pattern_class
--             AND     look_val.language           = cv_lang
--             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
--                                                 AND     NVL( look_val.end_date_active, gd_max_date )
--             AND     look_val.enabled_flag       = ct_enabled_flg_y
--           )
---- ************ 2009/07/29 N.Maeda 1.8 DEL START *********************** --
----           --���i���i�敪
----    AND    sel.item_code       = gpcv.segment1
---- ************ 2009/07/29 N.Maeda 1.8 DEL  END  *********************** --
--           --��݌ɕi�ڂ��揜��
--    AND    NOT EXISTS(
--             SELECT  'Y'                         ext_flg
--             FROM    fnd_lookup_values           look_val
--             WHERE   look_val.lookup_type        = cv_no_inv_item_type
--             AND     look_val.lookup_code        = sel.item_code
--             AND     look_val.language           = cv_lang
--             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
--                                                 AND     NVL( look_val.end_date_active, gd_max_date )
--             AND     look_val.enabled_flag       = ct_enabled_flg_y
--           )
--/* 2009/07/16 Ver1.7 Mod End   */
--           --INV�C���^�t�F�[�X�σt���O(���A�g)
--    AND    sel.inv_interface_flag       = cv_inv_flg_n
---- ************ 2009/07/29 N.Maeda 1.8 DEL START *********************** --
----/* 2009/05/13 Ver1.5 Add Start */
----    AND    sel.ship_from_subinventory_code = mcavd.subinventory_code(+)
----/* 2009/05/13 Ver1.5 Add End   */
----/* 2009/07/16 Ver1.7 Add Start */
----    AND    gt_org_id                       = mcavd.organization_id(+)
----/* 2009/07/16 Ver1.7 Add End   */
---- ************ 2009/07/29 N.Maeda 1.8 DEL  END  *********************** --
---- ************ 2009/07/29 N.Maeda 1.8 ADD START *********************** --
--    AND    msib.organization_id     = gt_org_id             -- �݌ɑg�DID
--    AND    msib.segment1            = sel.item_code
--    AND    msib.enabled_flag        = ct_enabled_flg_y      -- �i�ڃ}�X�^�L���t���O
--    AND    gd_proc_date
--             BETWEEN NVL(msib.start_date_active, gd_proc_date)
--             AND NVL(msib.end_date_active, gd_proc_date)
--    AND    mic.organization_id      = msib.organization_id
--    AND    mic.inventory_item_id    = msib.inventory_item_id
--    AND    mic.category_set_id      = gt_category_set_id
--    AND    mic.category_id          = mcb.category_id
--    AND    ( mcb.disable_date IS NULL
--           OR mcb.disable_date > gd_proc_date
--           )
--    AND    mcb.enabled_flag        = 'Y'      -- �J�e�S���L���t���O
--    AND    gd_proc_date
--             BETWEEN NVL(mcb.start_date_active, gd_proc_date)
--             AND NVL(mcb.end_date_active, gd_proc_date)
----
---- ************ 2009/07/29 N.Maeda 1.8 ADD  END  *********************** --
--    ORDER BY
--           sel.ship_from_subinventory_code,     --�o�׌��ۊǏꏊ
---- ************ 2009/07/29 N.Maeda 1.8 MOD START *********************** --
--           msib.inventory_item_id,
----           gpcv.inventory_item_id,              --�i��ID
---- ************ 2009/07/29 N.Maeda 1.8 MOD  END  *********************** --
--           seh.delivery_date,                   --�[�i��
----************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
--           seh.sales_base_code                  --���㋒�_�R�[�h
----************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
--    FOR UPDATE OF sel.sales_exp_line_id NOWAIT
--    ;
-- ************************ 2009/08/06 1.18 N.Maeda MOD  END  *************************** --
--
    --���������J�E���g
    gn_target_cnt := g_sales_exp_tab.COUNT;
--
    --���o�f�[�^����0���A�x�����b�Z�[�W�o��
    IF ( gn_target_cnt = 0 ) THEN
      lv_warnmsg              :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_no_data_err
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_warnmsg --���[�U�[�E�x���E���b�Z�[�W
      );
      --��s�}��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => ''
      );
    END IF;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
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
  END get_data;
--
  /**********************************************************************************
   * Function Name    : get_disposition_id
   * Description      : ����Ȗڕʖ�ID�擾(A-3_01)
   ***********************************************************************************/
  FUNCTION get_disposition_id(
    in_org_id           IN NUMBER,        --   �݌ɑg�DID
    iv_dept_code        IN VARCHAR2,      --   ����R�[�h
    iv_inv_acc_cls      IN VARCHAR2       --   ���o�Ɋ���敪
    ) RETURN NUMBER                       --   ����Ȗڕʖ�ID
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_disposition_id'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_disposition_id     mtl_generic_dispositions.disposition_id%TYPE;     --����Ȗڕʖ�ID
    ln_current_inx        NUMBER;                                           --�J�����gIndex
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
--
--###########################  �Œ蕔 END   ############################
--
    --�Y������Ȗڕʖ�ID�͊��Ɏ擾����Ă���ꍇ�A�O���[�o���R���N�V�����̌�����
    IF ( g_disposition_tab.COUNT > 0 ) THEN
      <<ext_chk_loop>>
      FOR i IN g_disposition_tab.FIRST .. g_disposition_tab.LAST LOOP
        IF ( in_org_id      = g_disposition_tab(i).org_id      AND
             iv_dept_code   = g_disposition_tab(i).dept_code   AND
             iv_inv_acc_cls = g_disposition_tab(i).inv_acc_cls ) THEN
          RETURN g_disposition_tab(i).disposition_id;
        END IF;
      END LOOP ext_chk_loop;
    END IF;
    --�Y������Ȗڕʖ�ID�͎擾����Ă��Ȃ��ꍇ�ADB�̌�����
    BEGIN
      SELECT  mgd.disposition_id     disposition_id                                   -- ����Ȗڕʖ�ID
      INTO    lt_disposition_id
      FROM    mtl_generic_dispositions mgd                                            -- ����Ȗڕʖ��e�[�u��
      WHERE   mgd.organization_id = in_org_id                                         -- �݌ɑg�DID
      AND     mgd.segment1        = iv_dept_code                                      -- ����R�[�h
      AND     mgd.segment2        = iv_inv_acc_cls                                    -- ���o�Ɋ���敪
      AND     gd_proc_date        >= NVL( mgd.effective_date, gd_min_date )
      AND     gd_proc_date        <= NVL( mgd.disable_date, gd_max_date )             -- �L��������������
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_disposition_id := NULL;
    END;
    ln_current_inx := g_disposition_tab.COUNT + 1;
    --DB����擾��������Ȗڕʖ�ID���O���[�o���R���N�V�����ɕێ����܂��B
    g_disposition_tab(ln_current_inx).org_id          := in_org_id;
    g_disposition_tab(ln_current_inx).dept_code       := iv_dept_code;
    g_disposition_tab(ln_current_inx).inv_acc_cls     := iv_inv_acc_cls;
    g_disposition_tab(ln_current_inx).disposition_id  := lt_disposition_id;
    RETURN lt_disposition_id;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RETURN NULL;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_disposition_id;
--
  /**********************************************************************************
   * Function Name    : get_ccid
   * Description      : ����Ȗ�ID�擾(A-3_02)
   ***********************************************************************************/
  FUNCTION get_ccid(
    iv_segment1           IN VARCHAR2,      --  ��ЃR�[�h
    iv_segment2           IN VARCHAR2,      --  ����R�[�h
    iv_segment3           IN VARCHAR2,      --  ����ȖڃR�[�h
    iv_segment4           IN VARCHAR2,      --  �⏕�ȖڃR�[�h
    iv_segment5           IN VARCHAR2,      --  �ڋq�R�[�h
    iv_segment6           IN VARCHAR2,      --  ��ƃR�[�h
    iv_segment7           IN VARCHAR2,      --  �\���P�R�[�h
    iv_segment8           IN VARCHAR2,      --  �\���Q�R�[�h
-- ********* 2009/08/24 1.9 N.Maeda ADD START ********* --
    id_dlv_date           IN DATE
-- ********* 2009/08/24 1.9 N.Maeda ADD  END  ********* --
    ) RETURN NUMBER                         --  ����Ȗ�ID
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ccid'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_ccid               mtl_generic_dispositions.disposition_id%TYPE;     --����Ȗ�ID(CCID)
    ln_current_inx        NUMBER;                                           --�J�����gIndex
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
--
--###########################  �Œ蕔 END   ############################
--
    --�Y������Ȗ�ID(CCID)�͊��Ɏ擾����Ă���ꍇ�A�O���[�o���R���N�V�����̌�����
    IF ( g_ccid_tab.COUNT > 0 ) THEN
      <<ext_chk_loop>>
      FOR i IN g_ccid_tab.FIRST .. g_ccid_tab.LAST LOOP
        IF ( iv_segment1 = g_ccid_tab(i).com_code     AND
             iv_segment2 = g_ccid_tab(i).dept_code    AND
             iv_segment3 = g_ccid_tab(i).acc_code     AND
             iv_segment4 = g_ccid_tab(i).ass_code     AND
             iv_segment5 = g_ccid_tab(i).cust_code    AND
             iv_segment6 = g_ccid_tab(i).ent_code     AND
             iv_segment7 = g_ccid_tab(i).res_code1    AND
             iv_segment8 = g_ccid_tab(i).res_code2 ) THEN
          RETURN g_ccid_tab(i).ccid;
        END IF;
      END LOOP ext_chk_loop;
    END IF;
    --�Y������Ȗ�ID(CCID)�͎擾����Ă��Ȃ��ꍇ�A���ʊ֐����擾�B
    lt_ccid := xxcok_common_pkg.get_code_combination_id_f(
-- ********* 2009/08/24 1.9 N.Maeda MOD START ********* --
                                              id_dlv_date,    --�[�i��
--                                              gd_proc_date,   --������
-- ********* 2009/08/24 1.9 N.Maeda MOD  END  ********* --
                                              iv_segment1,    --��ЃR�[�h
                                              iv_segment2,    --����R�[�h
                                              iv_segment3,    --����ȖڃR�[�h
                                              iv_segment4,    --�⏕�ȖڃR�[�h
                                              iv_segment5,    --�ڋq�R�[�h
                                              iv_segment6,    --��ƃR�[�h
                                              iv_segment7,    --�\���P�R�[�h
                                              iv_segment8     --�\���Q�R�[�h
    );
    ln_current_inx := g_ccid_tab.COUNT + 1;
    --���ʊ֐����擾��������Ȗ�ID���O���[�o���R���N�V�����ɕێ����܂��B
    g_ccid_tab(ln_current_inx).com_code       := iv_segment1;
    g_ccid_tab(ln_current_inx).dept_code      := iv_segment2;
    g_ccid_tab(ln_current_inx).acc_code       := iv_segment3;
    g_ccid_tab(ln_current_inx).ass_code       := iv_segment4;
    g_ccid_tab(ln_current_inx).cust_code      := iv_segment5;
    g_ccid_tab(ln_current_inx).ent_code       := iv_segment6;
    g_ccid_tab(ln_current_inx).res_code1      := iv_segment7;
    g_ccid_tab(ln_current_inx).res_code2      := iv_segment8;
    g_ccid_tab(ln_current_inx).ccid           := lt_ccid;
    RETURN lt_ccid;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RETURN NULL;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ccid;
--
  /**********************************************************************************
   * Procedure Name   : make_mtl_tran_data
   * Description      : ���ގ���f�[�^����(A-3)
   ***********************************************************************************/
  PROCEDURE make_mtl_tran_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_mtl_tran_data'; -- �v���O������
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
    cv_in                        CONSTANT VARCHAR2(1)   := '0';                 --���ɋ敪
    cv_out                       CONSTANT VARCHAR2(1)   := '1';                 --�o�ɋ敪
    cv_null                      CONSTANT VARCHAR2(5)   := 'NULL';              --����R�[�h���ݒ�
    cv_source_code               CONSTANT VARCHAR2(20)  := 'XXCOS013A02C';      --�\�[�X�R�[�h
    cn_source_line_id            CONSTANT NUMBER        := 1;                   --�\�[�X����ID
    cn_source_header_id          CONSTANT NUMBER        := 1;                   --�\�[�X�w�b�_�[ID
    cn_process_flag              CONSTANT NUMBER        := 1;                   --�����t���O
    cn_valid_required            CONSTANT NUMBER        := 1;                   --���ؗv
    cn_transaction_mode          CONSTANT NUMBER        := 3;                   --������[�h
    cn_scheduled_flag            CONSTANT NUMBER        := 2;                   --�v��t���O
    cv_flow_schedule             CONSTANT VARCHAR2(1)   := 'Y';                 --�v��t���[
    cn_make_rec_max              CONSTANT NUMBER        := 2;   --1���̔̔����т��Ƃɐ��������ő�f�[�^����
    cv_inv_acc_dir               CONSTANT VARCHAR2(20)  := '03';                --���o�Ɋ���敪(�H�꒼������)
--
    -- *** ���[�J���ϐ� ***
    lv_tkn_vl_table_name         VARCHAR2(100);             --�G���[�Ώۂł���e�[�u����
    l_txn_src_type_tab           g_txn_src_type_ttype;      --����\�[�X�^�C�v�R���N�V����
    l_txn_type_tab               g_txn_type_ttype;          --����^�C�v�R���N�V����
    l_jor_map_tab                g_jor_map_ttype;           --����^�C�v�^�d��p�^�[���}�b�s���O�\�R���N�V����(���o��)
    l_jor_out_tab                g_jor_map_ttype;           --����^�C�v�^�d��p�^�[���}�b�s���O�\�R���N�V����(�o��)
    ln_jor_out_inx               NUMBER;                    --��L�R���N�V������Index
    ln_mtl_txn_inx               NUMBER;                    --���ގ��OIF�R���N�V������Index
    ln_sign                      NUMBER;                    --����
    lt_dept_code                 xxcos_sales_exp_headers.sales_base_code%TYPE;        --����R�[�h
    lt_dlv_ptn_dir               xxcos_sales_exp_lines.delivery_pattern_class%TYPE;   --�[�i�`�ԋ敪(�H�꒼��)
    lt_src_type_id               mtl_transactions_interface.transaction_source_type_id%TYPE;  --����\�[�X�^�C�vID
    lt_type_id                   mtl_transactions_interface.transaction_type_id%TYPE;         --����^�C�vID
    lv_another_nm                VARCHAR2(100);                                         --����Ȗڕʖ�
    lt_disposition_id            mtl_generic_dispositions.disposition_id%TYPE;          --����Ȗڕʖ�ID
    lt_ccid                      mtl_generic_dispositions.disposition_id%TYPE;          --����Ȗ�ID(CCID)
    lv_warnmsg                   VARCHAR2(5000);                                        --���[�U�[�E�x���E���b�Z�[�W
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
    lv_idx_key                   VARCHAR2(1000);                                        -- PL/SQL�\�\�[�g�p�C���f�b�N�X������
    ln_now_index                 VARCHAR2(1000);
    ln_smb_idx                   NUMBER DEFAULT 0;           -- ���������C���f�b�N�X
    ln_first_index               VARCHAR2(300);
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
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
    --���ގ��OIF�R���N�V������Index�̏�����
    ln_mtl_txn_inx := 0;
    --����\�[�X�^�C�v�}�X�^���擾����
    SELECT mtst.transaction_source_type_id txn_src_type_id,     --����\�[�X�^�C�vID
           mtst.transaction_source_type_name txn_src_type_nm    --����\�[�X�^�C�v��
    BULK COLLECT INTO
           l_txn_src_type_tab
    FROM   mtl_txn_source_types  mtst                           --����\�[�X�^�C�v�e�[�u��
    WHERE  EXISTS(
/* 2009/07/16 Ver1.7 Mod Start */
--             SELECT  'Y'                         ext_flg
--             FROM    fnd_lookup_values           look_val,
--                     fnd_lookup_types_tl         types_tl,
--                     fnd_lookup_types            types,
--                     fnd_application_tl          appl,
--                     fnd_application             app
--             WHERE   appl.application_id         = types.application_id
--             AND     app.application_id          = appl.application_id
--             AND     types_tl.lookup_type        = look_val.lookup_type
--             AND     types.lookup_type           = types_tl.lookup_type
--             AND     types.security_group_id     = types_tl.security_group_id
--             AND     types.view_application_id   = types_tl.view_application_id
--             AND     types_tl.language           = cv_lang
--             AND     look_val.language           = cv_lang
--             AND     appl.language               = cv_lang
--             AND     app.application_short_name  = cv_xxcos_short_name
--             AND     look_val.lookup_type        = cv_txn_src_type
--             AND     look_val.lookup_code        LIKE cv_txn_src_code
--             AND     look_val.meaning            = mtst.transaction_source_type_name
--             AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--             AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--             AND     look_val.enabled_flag       = ct_enabled_flg_y
             SELECT  'Y'                         ext_flg
             FROM    fnd_lookup_values           look_val
             WHERE   look_val.lookup_type        = cv_txn_src_type
             AND     look_val.lookup_code        LIKE cv_txn_src_code
             AND     look_val.meaning            = mtst.transaction_source_type_name
             AND     look_val.language           = cv_lang
             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                                 AND     NVL( look_val.end_date_active, gd_max_date )
             AND     look_val.enabled_flag       = ct_enabled_flg_y
/* 2009/07/16 Ver1.7 Mod End   */
            )
            ;
    --����\�[�X�^�C�v�}�X�^���擾���s
    IF ( l_txn_src_type_tab.COUNT = 0 ) THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name3
      );
      RAISE global_data_select_expt;
    END IF;
--
    --����^�C�v�}�X�^���擾����
    SELECT mtt.transaction_type_id txn_type_id,                 --����^�C�vID
           mtt.transaction_type_name txn_type_nm                --����^�C�v��
    BULK COLLECT INTO
           l_txn_type_tab
    FROM   mtl_transaction_types  mtt                           --����^�C�v�e�[�u��
    WHERE  EXISTS(
/* 2009/07/16 Ver1.7 Mod Start */
--             SELECT  'Y'                         ext_flg
--             FROM    fnd_lookup_values           look_val,
--                     fnd_lookup_types_tl         types_tl,
--                     fnd_lookup_types            types,
--                     fnd_application_tl          appl,
--                     fnd_application             app
--             WHERE   appl.application_id         = types.application_id
--             AND     app.application_id          = appl.application_id
--             AND     types_tl.lookup_type        = look_val.lookup_type
--             AND     types.lookup_type           = types_tl.lookup_type
--             AND     types.security_group_id     = types_tl.security_group_id
--             AND     types.view_application_id   = types_tl.view_application_id
--             AND     types_tl.language           = cv_lang
--             AND     look_val.language           = cv_lang
--             AND     appl.language               = cv_lang
--             AND     app.application_short_name  = cv_xxcos_short_name
--             AND     look_val.lookup_type        = cv_txn_type_type
--             AND     look_val.lookup_code        LIKE cv_txn_type_code
--             AND     look_val.meaning            = mtt.transaction_type_name
--             AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--             AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--             AND     look_val.enabled_flag       = ct_enabled_flg_y
             SELECT  'Y'                         ext_flg
             FROM    fnd_lookup_values           look_val
             WHERE   look_val.lookup_type        = cv_txn_type_type
             AND     look_val.lookup_code        LIKE cv_txn_type_code
             AND     look_val.language           = cv_lang
             AND     look_val.meaning            = mtt.transaction_type_name
             AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                                 AND     NVL( look_val.end_date_active, gd_max_date )
             AND     look_val.enabled_flag       = ct_enabled_flg_y
/* 2009/07/16 Ver1.7 Mod End   */
            )
            ;
    --����^�C�v�}�X�^���擾���s
    IF ( l_txn_type_tab.COUNT = 0 ) THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name4
      );
      RAISE global_data_select_expt;
    END IF;
--
    --����^�C�v�^�d��p�^�[���}�b�s���O�\���擾����
    SELECT  look_val1.lookup_code        red_black_flg,      --�ԍ��t���O
            look_val2.meaning            dlv_invoice_class,  --�[�i�`�[�敪
            look_val3.meaning            dlv_pattern_class,  --�[�i�`�ԋ敪
            look_val4.meaning            sales_class,        --����敪
            look_val5.meaning            goods_prod_class,   --���i���i�敪
            look_val.attribute6          txn_src_type,       --����\�[�X�^�C�v
            look_val.attribute7          txn_type,           --����^�C�v
            look_val.attribute11         in_out_cls,         --���o�ɋ敪
            look_val.attribute8          dept_code,          --����R�[�h
            look_val.attribute9          acc_item,           --����ȖڃR�[�h
            look_val.attribute10         ass_item            --�⏕�ȖڃR�[�h
    BULK COLLECT INTO
            l_jor_map_tab
/* 2009/07/16 Ver1.7 Mod Start */
--            --����^�C�v�E�d��p�^�[������敪
--    FROM    fnd_lookup_values            look_val,
--            fnd_lookup_types_tl          types_tl,
--            fnd_lookup_types             types,
--            fnd_application_tl           appl,
--            fnd_application              app,
--            --�ԍ��t���O
--            fnd_lookup_values            look_val1,
--            fnd_lookup_types_tl          types_tl1,
--            fnd_lookup_types             types1,
--            fnd_application_tl           appl1,
--            fnd_application              app1,
--            --�[�i�`�[�敪����}�X�^
--            fnd_lookup_values            look_val2,
--            fnd_lookup_types_tl          types_tl2,
--            fnd_lookup_types             types2,
--            fnd_application_tl           appl2,
--            fnd_application              app2,
--            --�[�i�`�ԋ敪����}�X�^
--            fnd_lookup_values            look_val3,
--            fnd_lookup_types_tl          types_tl3,
--            fnd_lookup_types             types3,
--            fnd_application_tl           appl3,
--            fnd_application              app3,
--            --����敪����}�X�^
--            fnd_lookup_values            look_val4,
--            fnd_lookup_types_tl          types_tl4,
--            fnd_lookup_types             types4,
--            fnd_application_tl           appl4,
--            fnd_application              app4,
--            --���i���i�敪����}�X�^
--            fnd_lookup_values            look_val5,
--            fnd_lookup_types_tl          types_tl5,
--            fnd_lookup_types             types5,
--            fnd_application_tl           appl5,
--            fnd_application              app5
--    WHERE   appl.application_id          = types.application_id
--    AND     app.application_id           = appl.application_id
--    AND     types_tl.lookup_type         = look_val.lookup_type
--    AND     types.lookup_type            = types_tl.lookup_type
--    AND     types.security_group_id      = types_tl.security_group_id
--    AND     types.view_application_id    = types_tl.view_application_id
--    AND     types_tl.language            = cv_lang
--    AND     look_val.language            = cv_lang
--    AND     appl.language                = cv_lang
--    AND     app.application_short_name   = cv_xxcos_short_name
--    AND     look_val.lookup_type         = cv_txn_jor_type
--    AND     gd_proc_date                 >= NVL( look_val.start_date_active, gd_min_date )
--    AND     gd_proc_date                 <= NVL( look_val.end_date_active, gd_max_date )
--    AND     look_val.enabled_flag        = ct_enabled_flg_y
--            --�ԍ��t���O����
--    AND     appl1.application_id         = types1.application_id
--    AND     app1.application_id          = appl1.application_id
--    AND     types_tl1.lookup_type        = look_val1.lookup_type
--    AND     types1.lookup_type           = types_tl1.lookup_type
--    AND     types1.security_group_id     = types_tl1.security_group_id
--    AND     types1.view_application_id   = types_tl1.view_application_id
--    AND     types_tl1.language           = cv_lang
--    AND     look_val1.language           = cv_lang
--    AND     appl1.language               = cv_lang
--    AND     app1.application_short_name  = cv_xxcos_short_name
--    AND     look_val1.lookup_type        = cv_red_black_type
--    AND     gd_proc_date                 >= NVL( look_val1.start_date_active, gd_min_date )
--    AND     gd_proc_date                 <= NVL( look_val1.end_date_active, gd_max_date )
--    AND     look_val1.enabled_flag       = ct_enabled_flg_y
--    AND     look_val.attribute1          = look_val1.attribute1
--            --�[�i�`�[�敪����
--    AND     appl2.application_id         = types2.application_id
--    AND     app2.application_id          = appl2.application_id
--    AND     types_tl2.lookup_type        = look_val2.lookup_type
--    AND     types2.lookup_type           = types_tl2.lookup_type
--    AND     types2.security_group_id     = types_tl2.security_group_id
--    AND     types2.view_application_id   = types_tl2.view_application_id
--    AND     types_tl2.language           = cv_lang
--    AND     look_val2.language           = cv_lang
--    AND     appl2.language               = cv_lang
--    AND     app2.application_short_name  = cv_xxcos_short_name
--    AND     look_val2.lookup_type        = cv_dlv_slp_cls_type
--    AND     look_val2.lookup_code        LIKE cv_dlv_slp_cls_code
--    AND     gd_proc_date                 >= NVL( look_val2.start_date_active, gd_min_date )
--    AND     gd_proc_date                 <= NVL( look_val2.end_date_active, gd_max_date )
--    AND     look_val2.enabled_flag       = ct_enabled_flg_y
--    AND     look_val.attribute2          = look_val2.attribute1
--            --�[�i�`�ԋ敪����
--    AND     appl3.application_id         = types3.application_id
--    AND     app3.application_id          = appl3.application_id
--    AND     types_tl3.lookup_type        = look_val3.lookup_type
--    AND     types3.lookup_type           = types_tl3.lookup_type
--    AND     types3.security_group_id     = types_tl3.security_group_id
--    AND     types3.view_application_id   = types_tl3.view_application_id
--    AND     types_tl3.language           = cv_lang
--    AND     look_val3.language           = cv_lang
--    AND     appl3.language               = cv_lang
--    AND     app3.application_short_name  = cv_xxcos_short_name
--    AND     look_val3.lookup_type        = cv_dlv_ptn_cls_type
--    AND     look_val3.lookup_code        LIKE cv_dlv_ptn_cls_code
--    AND     gd_proc_date                 >= NVL( look_val3.start_date_active, gd_min_date )
--    AND     gd_proc_date                 <= NVL( look_val3.end_date_active, gd_max_date )
--    AND     look_val3.enabled_flag       = ct_enabled_flg_y      
--    AND     look_val.attribute3          = look_val3.attribute1
--            --����敪����
--    AND     appl4.application_id         = types4.application_id
--    AND     app4.application_id          = appl4.application_id
--    AND     types_tl4.lookup_type        = look_val4.lookup_type
--    AND     types4.lookup_type           = types_tl4.lookup_type
--    AND     types4.security_group_id     = types_tl4.security_group_id
--    AND     types4.view_application_id   = types_tl4.view_application_id
--    AND     types_tl4.language           = cv_lang
--    AND     look_val4.language           = cv_lang
--    AND     appl4.language               = cv_lang
--    AND     app4.application_short_name  = cv_xxcos_short_name
--    AND     look_val4.lookup_type        = cv_sale_cls_type
--    AND     look_val4.lookup_code        LIKE cv_sale_cls_code
--    AND     gd_proc_date                 >= NVL( look_val4.start_date_active, gd_min_date )
--    AND     gd_proc_date                 <= NVL( look_val4.end_date_active, gd_max_date )
--    AND     look_val4.enabled_flag       = ct_enabled_flg_y
--    AND     look_val.attribute4          = look_val4.attribute1
--            --���i���i�敪����
--    AND     appl5.application_id         = types5.application_id
--    AND     app5.application_id          = appl5.application_id
--    AND     types_tl5.lookup_type        = look_val5.lookup_type
--    AND     types5.lookup_type           = types_tl5.lookup_type
--    AND     types5.security_group_id     = types_tl5.security_group_id
--    AND     types5.view_application_id   = types_tl5.view_application_id
--    AND     types_tl5.language           = cv_lang
--    AND     look_val5.language           = cv_lang
--    AND     appl5.language               = cv_lang
--    AND     app5.application_short_name  = cv_xxcos_short_name
--    AND     look_val5.lookup_type        = cv_goods_prod_type
--    AND     look_val5.lookup_code        LIKE cv_goods_prod_code
--    AND     gd_proc_date                 >= NVL( look_val5.start_date_active, gd_min_date )
--    AND     gd_proc_date                 <= NVL( look_val5.end_date_active, gd_max_date )
--    AND     look_val5.enabled_flag       = ct_enabled_flg_y
--    AND     look_val.attribute5          = look_val5.attribute1
            --����^�C�v�E�d��p�^�[������敪
    FROM    fnd_lookup_values            look_val,
            --�ԍ��t���O
            fnd_lookup_values            look_val1,
            --�[�i�`�[�敪����}�X�^
            fnd_lookup_values            look_val2,
            --�[�i�`�ԋ敪����}�X�^
            fnd_lookup_values            look_val3,
            --����敪����}�X�^
            fnd_lookup_values            look_val4,
            --���i���i�敪����}�X�^
            fnd_lookup_values            look_val5
    WHERE   look_val.lookup_type         = cv_txn_jor_type
    AND     look_val.language            = cv_lang
    AND     gd_proc_date                 BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                         AND     NVL( look_val.end_date_active, gd_max_date )
    AND     look_val.enabled_flag        = ct_enabled_flg_y
            --�ԍ��t���O����
    AND     look_val1.lookup_type        = cv_red_black_type
    AND     look_val1.language           = cv_lang
    AND     gd_proc_date                 BETWEEN NVL( look_val1.start_date_active, gd_min_date )
                                         AND     NVL( look_val1.end_date_active, gd_max_date )
    AND     look_val1.enabled_flag       = ct_enabled_flg_y
    AND     look_val.attribute1          = look_val1.attribute1
            --�[�i�`�[�敪����
    AND     look_val2.lookup_type        = cv_dlv_slp_cls_type
    AND     look_val2.lookup_code        LIKE cv_dlv_slp_cls_code
    AND     look_val2.language           = cv_lang
    AND     gd_proc_date                 BETWEEN NVL( look_val2.start_date_active, gd_min_date )
                                         AND     NVL( look_val2.end_date_active, gd_max_date )
    AND     look_val2.enabled_flag       = ct_enabled_flg_y
    AND     look_val.attribute2          = look_val2.attribute1
            --�[�i�`�ԋ敪����
    AND     look_val3.lookup_type        = cv_dlv_ptn_cls_type
    AND     look_val3.lookup_code        LIKE cv_dlv_ptn_cls_code
    AND     look_val3.language           = cv_lang
    AND     gd_proc_date                 BETWEEN NVL( look_val3.start_date_active, gd_min_date )
                                         AND     NVL( look_val3.end_date_active, gd_max_date )
    AND     look_val3.enabled_flag       = ct_enabled_flg_y      
    AND     look_val.attribute3          = look_val3.attribute1
            --����敪����
    AND     look_val4.lookup_type        = cv_sale_cls_type
    AND     look_val4.lookup_code        LIKE cv_sale_cls_code
    AND     look_val4.language           = cv_lang
    AND     gd_proc_date                 BETWEEN NVL( look_val4.start_date_active, gd_min_date )
                                         AND     NVL( look_val4.end_date_active, gd_max_date )
    AND     look_val4.enabled_flag       = ct_enabled_flg_y
    AND     look_val.attribute4          = look_val4.attribute1
            --���i���i�敪����
    AND     look_val5.lookup_type        = cv_goods_prod_type
    AND     look_val5.lookup_code        LIKE cv_goods_prod_code
    AND     look_val5.language           = cv_lang
    AND     gd_proc_date                 BETWEEN NVL( look_val5.start_date_active, gd_min_date )
                                         AND     NVL( look_val5.end_date_active, gd_max_date )
    AND     look_val5.enabled_flag       = ct_enabled_flg_y
    AND     look_val.attribute5          = look_val5.attribute1
/* 2009/07/16 Ver1.7 Mod END   */
    ORDER BY
            look_val1.lookup_code        DESC,
            look_val2.meaning            ASC,
            look_val3.meaning            ASC,
            look_val4.meaning            ASC,
            look_val5.meaning            ASC
    ;
    --����^�C�v�^�d��p�^�[���}�b�s���O�\���擾���s
    IF ( l_jor_map_tab.COUNT = 0 ) THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name5
      );
      RAISE global_data_select_expt;
    END IF;
--
    --�[�i�`�ԋ敪(�H�꒼��)�̎擾
    BEGIN
      SELECT  look_val.meaning            dlv_ptn_cls
      INTO    lt_dlv_ptn_dir
/* 2009/07/16 Ver1.7 Mod Start */
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
--      AND     look_val.lookup_type        = cv_dlv_ptn_cls_type
--      AND     look_val.lookup_code        = cv_dlv_ptn_dir_code
--      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--      AND     look_val.enabled_flag       = ct_enabled_flg_y
--      AND     rownum                      = 1
      FROM    fnd_lookup_values           look_val
      WHERE   look_val.lookup_type        = cv_dlv_ptn_cls_type
      AND     look_val.lookup_code        = cv_dlv_ptn_dir_code
      AND     look_val.language           = cv_lang
      AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                          AND     NVL( look_val.end_date_active, gd_max_date )
      AND     look_val.enabled_flag       = ct_enabled_flg_y
      AND     rownum                      = 1
/* 2009/07/16 Ver1.7 Mod End   */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_vl_table_name6
        );
        RAISE global_data_select_expt;
    END;
--
    --����\�[�X�^�C�v(����Ȗڕʖ�)�̎擾
    BEGIN
      SELECT  look_val.meaning            another_name
      INTO    lv_another_nm
/* 2009/07/16 Ver1.7 Mod Start */
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
--      AND     look_val.lookup_type        = cv_txn_src_type
--      AND     look_val.lookup_code        = cv_another_nm_code
--      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--      AND     look_val.enabled_flag       = ct_enabled_flg_y
--      AND     rownum                      = 1
      FROM    fnd_lookup_values           look_val
      WHERE   look_val.lookup_type        = cv_txn_src_type
      AND     look_val.lookup_code        = cv_another_nm_code
      AND     look_val.language           = cv_lang
      AND     gd_proc_date                BETWEEN NVL( look_val.start_date_active, gd_min_date )
                                          AND     NVL( look_val.end_date_active, gd_max_date )
      AND     look_val.enabled_flag       = ct_enabled_flg_y
      AND     rownum                      = 1
/* 2009/07/16 Ver1.7 Mod End   */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_vl_table_name7
        );
        RAISE global_data_select_expt;
    END;
--
    --���ގ���f�[�^��������
    <<make_data_main_loop>>
    FOR i IN g_sales_exp_tab.FIRST .. g_sales_exp_tab.LAST LOOP
      --����^�C�v�^�d��p�^�[���o�͗pIndex�̃N���A
      ln_jor_out_inx := 0;
      --�Y���̔����т̎���^�C�v�^�d��p�^�[���̎擾
      <<get_type_loop>>
      FOR j IN l_jor_map_tab.FIRST .. l_jor_map_tab.LAST LOOP
        IF ( g_sales_exp_tab(i).red_black_flag    = l_jor_map_tab(j).red_black_flg     AND  --�ԍ��t���O
             g_sales_exp_tab(i).dlv_invoice_class = l_jor_map_tab(j).dlv_invoice_class AND  --�[�i�`�[�敪
             g_sales_exp_tab(i).dlv_pattern_class = l_jor_map_tab(j).dlv_pattern_class AND  --�[�i�`�ԋ敪
             g_sales_exp_tab(i).sales_class       = l_jor_map_tab(j).sales_class       AND  --����敪
             g_sales_exp_tab(i).goods_prod_class  = l_jor_map_tab(j).goods_prod_class       --���i���i�敪
           ) THEN
          ln_jor_out_inx := ln_jor_out_inx + 1;
          l_jor_out_tab(ln_jor_out_inx).txn_src_type  := l_jor_map_tab(j).txn_src_type;     --����\�[�X�^�C�v
          l_jor_out_tab(ln_jor_out_inx).txn_type      := l_jor_map_tab(j).txn_type;         --����^�C�v
          l_jor_out_tab(ln_jor_out_inx).in_out_cls    := l_jor_map_tab(j).in_out_cls;       --���o�ɋ敪
          l_jor_out_tab(ln_jor_out_inx).dept_code     := l_jor_map_tab(j).dept_code;        --����R�[�h
          l_jor_out_tab(ln_jor_out_inx).acc_item      := l_jor_map_tab(j).acc_item;         --����ȖڃR�[�h
          l_jor_out_tab(ln_jor_out_inx).ass_item      := l_jor_map_tab(j).ass_item;         --�⏕�ȖڃR�[�h
          --��H�꒼��1���܂��͍H�꒼��2���܂Ń��[�v�𔲂��o��
          EXIT WHEN( g_sales_exp_tab(i).dlv_pattern_class <> lt_dlv_ptn_dir OR ln_jor_out_inx = cn_make_rec_max );
        END IF;
      END LOOP get_type_loop;
      --�Y���̔����т̎���^�C�v�^�d��p�^�[�����擾�ł��Ȃ��ꍇ
      IF ( l_jor_out_tab.COUNT = 0 ) THEN
        --�x���������v�サ�܂��B
        gn_warn_cnt := gn_warn_cnt + 1;
        --�x�����b�Z�[�W���o�͂��܂��B
        lv_warnmsg              :=  xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_type_jor_err,
          iv_token_name1        =>  cv_tkn_nm_line_id,
          iv_token_value1       =>  g_sales_exp_tab(i).line_id,
          iv_token_name2        =>  cv_tkn_nm_red_blk,
          iv_token_value2       =>  g_sales_exp_tab(i).red_black_flag,
          iv_token_name3        =>  cv_tkn_nm_dlv_inv,
          iv_token_value3       =>  g_sales_exp_tab(i).dlv_invoice_class,
          iv_token_name4        =>  cv_tkn_nm_dlv_ptn,
          iv_token_value4       =>  g_sales_exp_tab(i).dlv_pattern_class,
          iv_token_name5        =>  cv_tkn_nm_sale_cls,
          iv_token_value5       =>  g_sales_exp_tab(i).sales_class,
          iv_token_name6        =>  cv_tkn_nm_item_cls,
          iv_token_value6       =>  g_sales_exp_tab(i).goods_prod_class
        );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_warnmsg --���[�U�[�E�x���E���b�Z�[�W
        );
        --��s�}��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => ''
        );
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
        gt_sales_exp_line_id( gn_warn_cnt ) := g_sales_exp_tab(i).line_id;
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
        --�Y���̔����уf�[�^���������Ȃ��̂ŁA�R���N�V��������폜���܂��B
        g_sales_exp_tab.DELETE( i );
      ELSE
        --���ގ���f�[�^����
        <<make_data_sub_loop>>
        FOR k IN l_jor_out_tab.FIRST .. l_jor_out_tab.LAST LOOP
          ln_mtl_txn_inx := ln_mtl_txn_inx + 1;
          --�\�[�X�R�[�h
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).source_code           := cv_source_code;
          --�\�[�X����ID
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).source_line_id        := cn_source_line_id;
          --�\�[�X�w�b�_�[ID
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).source_header_id      := cn_source_header_id;
          --�����t���O
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).process_flag          := cn_process_flag;
          --���ؗv
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).validation_required   := cn_valid_required;
          --������[�h
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_mode      := cn_transaction_mode;
          --����i��ID
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).inventory_item_id     := g_sales_exp_tab(i).inventory_item_id;
          --������̑g�DID
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).organization_id       := gt_org_id;
          --�������(�����F���Ɂ��{ �o�Ɂ��|)
          IF ( l_jor_out_tab(k).in_out_cls = cv_in ) THEN
            ln_sign := 1;
          ELSE
            ln_sign := -1;
          END IF;
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_quantity  := ABS( g_sales_exp_tab(i).standard_qty ) * ln_sign;
          --����P��
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_uom       := g_sales_exp_tab(i).standard_uom_code;
          --���������
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_date      := g_sales_exp_tab(i).dlv_date;
          --������̕ۊǏꏊ��
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).subinventory_code     := g_sales_exp_tab(i).shipment_from_code;
          --����R�[�h�擾
          IF ( l_jor_out_tab(k).dept_code = cv_null ) THEN
            lt_dept_code := g_sales_exp_tab(i).sales_base_code;
          ELSE
            lt_dept_code := l_jor_out_tab(k).dept_code;
          END IF;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).sales_exp_line_id     := g_sales_exp_tab(i).line_id;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
          --����Ȗڏ��擾
          IF ( l_jor_out_tab(k).txn_src_type = lv_another_nm ) THEN
            --����Ȗڕʖ�ID�擾
            lt_disposition_id := get_disposition_id( gt_org_id, lt_dept_code, cv_inv_acc_dir );
            IF ( lt_disposition_id IS NULL ) THEN
              --�����ς̃f�[�^�����J�o�����܂��B
              <<rec1_loop>>
              FOR n IN l_jor_out_tab.FIRST .. k LOOP
                g_mtl_txn_oif_tab.DELETE( ln_mtl_txn_inx );
                ln_mtl_txn_inx := ln_mtl_txn_inx - 1;
              END LOOP rec1_loop;
              --�x���������v�サ�܂��B
              gn_warn_cnt := gn_warn_cnt + 1;
              --�x�����b�Z�[�W���o�͂��܂��B
              lv_warnmsg              :=  xxccp_common_pkg.get_msg(
                iv_application        =>  cv_xxcos_short_name,
                iv_name               =>  cv_msg_dispt_err,
                iv_token_name1        =>  cv_tkn_nm_line_id,
                iv_token_value1       =>  g_sales_exp_tab(i).line_id,
                iv_token_name2        =>  cv_tkn_nm_org_id,
                iv_token_value2       =>  gt_org_id,
                iv_token_name3        =>  cv_tkn_nm_dept_cd,
                iv_token_value3       =>  lt_dept_code,
                iv_token_name4        =>  cv_tkn_nm_inv_acc,
                iv_token_value4       =>  cv_inv_acc_dir
              );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_warnmsg --���[�U�[�E�x���E���b�Z�[�W
              );
              --��s�}��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => ''
              );
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
              gt_sales_exp_line_id( gn_warn_cnt ) := g_sales_exp_tab(i).line_id;
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
              --�Y���̔����уf�[�^���������Ȃ��̂ŁA�R���N�V��������폜���܂��B
              g_sales_exp_tab.DELETE( i );
              --�����[�v���~
              EXIT;
            END IF;
            --����\�[�XID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_source_id := lt_disposition_id;
          ELSE
            --����Ȗ�ID(CCID)�擾
            lt_ccid := get_ccid( gv_com_code,
                                 lt_dept_code,
                                 l_jor_out_tab(k).acc_item,
                                 l_jor_out_tab(k).ass_item,
                                 gv_cust_dummy,
                                 gv_ent_dummy,
                                 gv_res1_dummy,
                                 gv_res2_dummy,
-- ********* 2009/08/24 1.9 N.Maeda ADD START ********* --
                                 g_sales_exp_tab(i).dlv_date
-- ********* 2009/08/24 1.9 N.Maeda ADD  END  ********* --
                                 );
            IF ( lt_ccid IS NULL ) THEN
              --�����ς̃f�[�^�����J�o�����܂��B
              <<rec2_loop>>
              FOR n IN l_jor_out_tab.FIRST .. k LOOP
                g_mtl_txn_oif_tab.DELETE( ln_mtl_txn_inx );
                ln_mtl_txn_inx := ln_mtl_txn_inx - 1;
              END LOOP rec2_loop;
              --�x���������v�サ�܂��B
              gn_warn_cnt := gn_warn_cnt + 1;
              --�x�����b�Z�[�W���o�͂��܂��B
              lv_warnmsg              :=  xxccp_common_pkg.get_msg(
                iv_application        =>  cv_xxcos_short_name,
                iv_name               =>  cv_msg_ccid_err,
                iv_token_name1        =>  cv_tkn_nm_line_id,
                iv_token_value1       =>  g_sales_exp_tab(i).line_id,
                iv_token_name2        =>  cv_tkn_nm_com_cd,
                iv_token_value2       =>  gv_com_code,
                iv_token_name3        =>  cv_tkn_nm_dept_cd,
                iv_token_value3       =>  lt_dept_code,
                iv_token_name4        =>  cv_tkn_nm_acc_cd,
                iv_token_value4       =>  l_jor_out_tab(k).acc_item,
                iv_token_name5        =>  cv_tkn_nm_ass_cd,
                iv_token_value5       =>  l_jor_out_tab(k).ass_item,
                iv_token_name6        =>  cv_tkn_nm_cust_cd,
                iv_token_value6       =>  gv_cust_dummy,
                iv_token_name7        =>  cv_tkn_nm_ent_cd,
                iv_token_value7       =>  gv_ent_dummy,
                iv_token_name8        =>  cv_tkn_nm_res1_cd,
                iv_token_value8       =>  gv_res1_dummy,
                iv_token_name9        =>  cv_tkn_nm_res2_cd,
                iv_token_value9       =>  gv_res2_dummy
              );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_warnmsg --���[�U�[�E�x���E���b�Z�[�W
              );
              --��s�}��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => ''
              );
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
              gt_sales_exp_line_id( gn_warn_cnt ) := g_sales_exp_tab(i).line_id;
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
              --�Y���̔����уf�[�^���������Ȃ��̂ŁA�R���N�V��������폜���܂��B
              g_sales_exp_tab.DELETE( i );
              --�����[�v���~
              EXIT;
            END IF;
            --����\�[�XID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_source_id := lt_ccid;
          END IF;
          --����\�[�X�^�C�vID�̎擾
          lt_src_type_id := NULL;
          <<sch_src_type_loop>>
          FOR l IN l_txn_src_type_tab.FIRST .. l_txn_src_type_tab.LAST LOOP
            IF ( l_jor_out_tab(k).txn_src_type = l_txn_src_type_tab(l).txn_src_type_nm ) THEN
              lt_src_type_id := l_txn_src_type_tab(l).txn_src_type_id;
              EXIT;
            END IF;
          END LOOP sch_src_type_loop;
          IF ( lt_src_type_id IS NULL ) THEN
            --�����ς̃f�[�^�����J�o�����܂��B
            <<rec3_loop>>
            FOR n IN l_jor_out_tab.FIRST .. k LOOP
              g_mtl_txn_oif_tab.DELETE( ln_mtl_txn_inx );
              ln_mtl_txn_inx := ln_mtl_txn_inx - 1;
            END LOOP rec3_loop;
            --�x���������v�サ�܂��B
            gn_warn_cnt := gn_warn_cnt + 1;
            --�x�����b�Z�[�W���o�͂��܂��B
            lv_warnmsg              :=  xxccp_common_pkg.get_msg(
              iv_application        =>  cv_xxcos_short_name,
              iv_name               =>  cv_msg_src_type_err,
              iv_token_name1        =>  cv_tkn_nm_line_id,
              iv_token_value1       =>  g_sales_exp_tab(i).line_id,
              iv_token_name2        =>  cv_tkn_nm_src_type,
              iv_token_value2       =>  l_jor_out_tab(k).txn_src_type
            );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_warnmsg --���[�U�[�E�x���E���b�Z�[�W
            );
            --��s�}��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => ''
            );
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
            gt_sales_exp_line_id( gn_warn_cnt ) := g_sales_exp_tab(i).line_id;
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
            --�Y���̔����уf�[�^���������Ȃ��̂ŁA�R���N�V��������폜���܂��B
            g_sales_exp_tab.DELETE( i );
            --�����[�v���~
            EXIT;
          END IF;
          g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_source_type_id  := lt_src_type_id;
          --����^�C�vID�̎擾
          lt_type_id := NULL;
          <<sch_type_loop>>
          FOR m IN l_txn_type_tab.FIRST .. l_txn_type_tab.LAST LOOP
            IF ( l_jor_out_tab(k).txn_type = l_txn_type_tab(m).txn_type_nm ) THEN
              lt_type_id := l_txn_type_tab(m).txn_type_id;
              EXIT;
            END IF;
          END LOOP sch_type_loop;
          IF ( lt_type_id IS NULL ) THEN
            --�����ς̃f�[�^�����J�o�����܂��B
            <<rec4_loop>>
            FOR n IN l_jor_out_tab.FIRST .. k LOOP
              g_mtl_txn_oif_tab.DELETE( ln_mtl_txn_inx );
              ln_mtl_txn_inx := ln_mtl_txn_inx - 1;
            END LOOP rec4_loop;
            --�x���������v�サ�܂��B
            gn_warn_cnt := gn_warn_cnt + 1;
            --�x�����b�Z�[�W���o�͂��܂��B
            lv_warnmsg              :=  xxccp_common_pkg.get_msg(
              iv_application        =>  cv_xxcos_short_name,
              iv_name               =>  cv_msg_type_err,
              iv_token_name1        =>  cv_tkn_nm_line_id,
              iv_token_value1       =>  g_sales_exp_tab(i).line_id,
              iv_token_name2        =>  cv_tkn_nm_type,
              iv_token_value2       =>  l_jor_out_tab(k).txn_type
            );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_warnmsg --���[�U�[�E�x���E���b�Z�[�W
            );
            --��s�}��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => ''
            );
            --�Y���̔����уf�[�^���������Ȃ��̂ŁA�R���N�V��������폜���܂��B
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
            gt_sales_exp_line_id( gn_warn_cnt ) := g_sales_exp_tab(i).line_id;
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
            g_sales_exp_tab.DELETE( i );
            --�����[�v���~
            EXIT;
          END IF;
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).transaction_type_id     := lt_type_id;
            --�v��t���O
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).scheduled_flag          := cn_scheduled_flag;
            --�v��t���[
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).flow_schedule           := cv_flow_schedule;
            --�쐬��ID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).created_by              := cn_created_by;
            --�쐬��
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).creation_date           := cd_creation_date;
            --�ŏI�X�V��ID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).last_updated_by         := cn_last_updated_by;
            --�ŏI�X�V��
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).last_update_date        := cd_last_update_date;
            --�ŏI���O�C��ID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).last_update_login       := cn_last_update_login;
            --�v��ID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).request_id              := cn_request_id;
            --�v���O�����A�v���P�[�V����ID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).program_application_id  := cn_program_application_id;
            --�v���O����ID
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).program_id              := cn_program_id;
            --�v���O�����X�V��
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).program_update_date     := cd_program_update_date;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
            --����R�[�h
            g_mtl_txn_oif_tab(ln_mtl_txn_inx).dept_code               := lt_dept_code;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
        END LOOP make_data_sub_loop;
        --�Y���̔����т̎���^�C�v�^�d��p�^�[�����̃N���A
        l_jor_out_tab.DELETE;
      END IF;
    END LOOP make_data_main_loop;
--
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
    --�e�[�u���\�[��
    <<loop_make_sort_data>>
    FOR s IN 1..g_mtl_txn_oif_tab.COUNT LOOP
      --�\�[�g�L�[�͕ۊǏꏊ�A�i��ID�A������A����R�[�h�A�̔����і���ID
      lv_idx_key := g_mtl_txn_oif_tab(s).subinventory_code
                    || g_mtl_txn_oif_tab(s).inventory_item_id
                    || g_mtl_txn_oif_tab(s).transaction_date
                    || g_mtl_txn_oif_tab(s).dept_code
                    || g_mtl_txn_oif_tab(s).sales_exp_line_id;
      g_mtl_txn_oif_tab_spare(lv_idx_key) := g_mtl_txn_oif_tab(s);
    END LOOP loop_make_sort_data;
--
    IF g_mtl_txn_oif_tab_spare.COUNT = 0 THEN
      RETURN;
    END IF;
--
    ln_first_index := g_mtl_txn_oif_tab_spare.first;
    ln_now_index := ln_first_index;
--
    WHILE ln_now_index IS NOT NULL LOOP
--
      ln_smb_idx := ln_smb_idx + 1;
      g_mtl_txn_oif_ins_tab(ln_smb_idx) := g_mtl_txn_oif_tab_spare(ln_now_index);
      -- ���̃C���f�b�N�X���擾����
      ln_now_index := g_mtl_txn_oif_tab_spare.next(ln_now_index);
--
    END LOOP;--�\�[�g����--
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
--
  EXCEPTION
    --*** �f�[�^���o��O�n���h�� ***
    WHEN global_data_select_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_select_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  NULL
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
  END make_mtl_tran_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_mtl_tran_oif
   * Description      : ���ގ��OIF�o��(A-4)
   ***********************************************************************************/
  PROCEDURE insert_mtl_tran_oif(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_mtl_tran_oif'; -- �v���O������
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
    lt_subinventory              mtl_transactions_interface.subinventory_code%TYPE;   --������̕ۊǏꏊ(�u���[�N�L�[)
    lt_item_id                   mtl_transactions_interface.inventory_item_id%TYPE;   --����i��ID(�u���[�N�L�[)
    lt_txn_date                  mtl_transactions_interface.transaction_date%TYPE;    --���������(�u���[�N�L�[)
    lt_type_id                   mtl_transactions_interface.transaction_type_id%TYPE; --����^�C�vID
    ln_break_start               NUMBER;                                              --�W��u���[�N�J�n
    ln_break_end                 NUMBER;                                              --�W��u���[�N�I��
    lv_tkn_vl_table_name         VARCHAR2(100);                                       --�G���[�Ώۂł���e�[�u����
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
    lt_dept_code                 VARCHAR2(20);                                        --����R�[�h
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
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
    --�u���[�N�L�[������
    lt_subinventory := g_mtl_txn_oif_tab(1).subinventory_code;
    lt_item_id      := g_mtl_txn_oif_tab(1).inventory_item_id;
    lt_txn_date     := g_mtl_txn_oif_tab(1).transaction_date;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD START *********************************************
    lt_dept_code    := g_mtl_txn_oif_tab(1).dept_code;
--************************************* 2009/04/28 N.Maeda Var1.4 ADD  END  *********************************************
    ln_break_start  := 1;
    ln_break_end    := 1;
--
    --���ގ��OIF�f�[�^�̏W�񏈗�
    <<sum_main_loop>>
--************************************* 2009/04/28 N.Maeda Var1.4 MOD START *********************************************
--    FOR i IN 1 .. g_mtl_txn_oif_tab.LAST LOOP
--      --������̕ۊǏꏊ�A����i��ID�A����������Ńu���[�N
--      IF ( lt_subinventory = g_mtl_txn_oif_tab(i).subinventory_code AND
--           lt_item_id      = g_mtl_txn_oif_tab(i).inventory_item_id AND
--           lt_txn_date     = g_mtl_txn_oif_tab(i).transaction_date ) THEN
    FOR i IN g_mtl_txn_oif_ins_tab.FIRST .. g_mtl_txn_oif_ins_tab.LAST LOOP
      --������̕ۊǏꏊ�A����i��ID�A����������A����R�[�h�Ńu���[�N
      IF ( lt_subinventory = g_mtl_txn_oif_ins_tab(i).subinventory_code AND
           lt_item_id      = g_mtl_txn_oif_ins_tab(i).inventory_item_id AND
           lt_txn_date     = g_mtl_txn_oif_ins_tab(i).transaction_date  AND
           lt_dept_code    = g_mtl_txn_oif_ins_tab(i).dept_code ) THEN
--
--        --�u���[�N�I���܂ŁAIndex��ێ�
--        ln_break_end := i;
--        --�Ō�̃u���[�N
--        IF ( i = g_mtl_txn_oif_tab.LAST ) THEN
--          <<last_same_break_loop>>
--          FOR j IN ln_break_start .. ln_break_end LOOP
--            --�����R�[�h���폜����Ă��Ȃ���΁A�W�v�����ΏۂƂȂ�܂��B
--            IF ( g_mtl_txn_oif_tab.EXISTS( j ) ) THEN
--              --�u���[�N���œ�������^�C�vID�̎�����ʂ��v�サ�܂��B
--              <<last_sum_sub_loop>>
--              FOR k IN ( j + 1 ) .. ln_break_end LOOP
--                IF ( g_mtl_txn_oif_tab.EXISTS( k ) AND 
--                     g_mtl_txn_oif_tab(k).transaction_type_id = g_mtl_txn_oif_tab(j).transaction_type_id ) THEN
--                  g_mtl_txn_oif_tab(j).transaction_quantity := g_mtl_txn_oif_tab(j).transaction_quantity +
--                                                               g_mtl_txn_oif_tab(k).transaction_quantity;
--                  --�v�コ�ꂽ���߁A�폜���܂��B
--                  g_mtl_txn_oif_tab.DELETE( k );
--                END IF;
--              END LOOP last_sum_sub_loop;
--            END IF;
--          END LOOP last_same_break_loop;
--        END IF;
--      ELSE
--        --����̃u���[�N���ŏW�v
--        <<same_break_loop>>
--        FOR j IN ln_break_start .. ln_break_end LOOP
--          --�����R�[�h���폜����Ă��Ȃ���΁A�W�v�����ΏۂƂȂ�܂��B
--          IF ( g_mtl_txn_oif_tab.EXISTS( j ) ) THEN
--            --�u���[�N���œ�������^�C�vID�̎�����ʂ��v�サ�܂��B
--            <<sum_sub_loop>>
--            FOR k IN ( j + 1 ) .. ln_break_end LOOP
--              IF ( g_mtl_txn_oif_tab.EXISTS( k ) AND 
--                   g_mtl_txn_oif_tab(k).transaction_type_id = g_mtl_txn_oif_tab(j).transaction_type_id ) THEN
--                g_mtl_txn_oif_tab(j).transaction_quantity := g_mtl_txn_oif_tab(j).transaction_quantity +
--                                                             g_mtl_txn_oif_tab(k).transaction_quantity;
--                --�v�コ�ꂽ���߁A�폜���܂��B
--                g_mtl_txn_oif_tab.DELETE( k );
--              END IF;
--            END LOOP sum_sub_loop;
--          END IF;
--        END LOOP same_break_loop;
--        --���̃u���[�N�L�[��ݒ肵�܂��B
--        lt_subinventory := g_mtl_txn_oif_tab(i).subinventory_code;
--        lt_item_id      := g_mtl_txn_oif_tab(i).inventory_item_id;
--        lt_txn_date     := g_mtl_txn_oif_tab(i).transaction_date;
        --�u���[�N�I���܂ŁAIndex��ێ�
        ln_break_end := i;
        --�Ō�̃u���[�N
        IF ( i = g_mtl_txn_oif_ins_tab.LAST ) THEN
          <<last_same_break_loop>>
          FOR j IN ln_break_start .. ln_break_end LOOP
            --�����R�[�h���폜����Ă��Ȃ���΁A�W�v�����ΏۂƂȂ�܂��B
            IF ( g_mtl_txn_oif_ins_tab.EXISTS( j ) ) THEN
              --�u���[�N���œ�������^�C�vID�̎�����ʂ��v�サ�܂��B
              <<last_sum_sub_loop>>
              FOR k IN ( j + 1 ) .. ln_break_end LOOP
                IF ( g_mtl_txn_oif_ins_tab.EXISTS( k ) AND 
                     g_mtl_txn_oif_ins_tab(k).transaction_type_id = g_mtl_txn_oif_ins_tab(j).transaction_type_id ) THEN
                  g_mtl_txn_oif_ins_tab(j).transaction_quantity := g_mtl_txn_oif_ins_tab(j).transaction_quantity +
                                                               g_mtl_txn_oif_ins_tab(k).transaction_quantity;
                  --�v�コ�ꂽ���߁A�폜���܂��B
                  g_mtl_txn_oif_ins_tab.DELETE( k );
                END IF;
              END LOOP last_sum_sub_loop;
            END IF;
          END LOOP last_same_break_loop;
        END IF;
      ELSE
        --����̃u���[�N���ŏW�v
        <<same_break_loop>>
        FOR j IN ln_break_start .. ln_break_end LOOP
          --�����R�[�h���폜����Ă��Ȃ���΁A�W�v�����ΏۂƂȂ�܂��B
          IF ( g_mtl_txn_oif_ins_tab.EXISTS( j ) ) THEN
            --�u���[�N���œ�������^�C�vID�̎�����ʂ��v�サ�܂��B
            <<sum_sub_loop>>
            FOR k IN ( j + 1 ) .. ln_break_end LOOP
              IF ( g_mtl_txn_oif_ins_tab.EXISTS( k ) AND 
                   g_mtl_txn_oif_ins_tab(k).transaction_type_id = g_mtl_txn_oif_ins_tab(j).transaction_type_id ) THEN
                g_mtl_txn_oif_ins_tab(j).transaction_quantity := g_mtl_txn_oif_ins_tab(j).transaction_quantity +
                                                             g_mtl_txn_oif_ins_tab(k).transaction_quantity;
                --�v�コ�ꂽ���߁A�폜���܂��B
                g_mtl_txn_oif_ins_tab.DELETE( k );
              END IF;
            END LOOP sum_sub_loop;
          END IF;
        END LOOP same_break_loop;
        --���̃u���[�N�L�[��ݒ肵�܂��B
        lt_subinventory := g_mtl_txn_oif_ins_tab(i).subinventory_code;
        lt_item_id      := g_mtl_txn_oif_ins_tab(i).inventory_item_id;
        lt_txn_date     := g_mtl_txn_oif_ins_tab(i).transaction_date;
        lt_dept_code    := g_mtl_txn_oif_ins_tab(i).dept_code;
--************************************* 2009/04/28 N.Maeda Var1.4 MOD  END  *********************************************
        --���̃u���[�N�J�nIndex��ݒ肵�܂��B
        ln_break_start := i;
      END IF;
    END LOOP sum_main_loop;
--
    --���ގ���e�[�u���o�^����
    BEGIN
      <<insert_loop>>
--************************************* 2009/04/28 N.Maeda Var1.4 MOD START *********************************************
--      FOR l IN g_mtl_txn_oif_tab.FIRST .. g_mtl_txn_oif_tab.LAST LOOP
--        IF ( g_mtl_txn_oif_tab.EXISTS( l ) ) THEN
      FOR l IN g_mtl_txn_oif_ins_tab.FIRST .. g_mtl_txn_oif_ins_tab.LAST LOOP
        IF ( g_mtl_txn_oif_ins_tab.EXISTS( l ) ) THEN
--************************************* 2009/04/28 N.Maeda Var1.4 MOD  END  *********************************************
/* 2009/06/17 Ver1.6 Add Start */
          --������ʂ�0�ȊO�̏ꍇ�쐬����
          IF ( g_mtl_txn_oif_ins_tab(l).transaction_quantity <> 0 ) THEN
/* 2009/06/17 Ver1.6 Add End   */
          INSERT INTO 
            mtl_transactions_interface(
              source_code,                   --�\�[�X�R�[�h
              source_line_id,                --�\�[�X����ID
              source_header_id,              --�\�[�X�w�b�_�[ID
              process_flag,                  --�����t���O
              validation_required,           --���ؗv
              transaction_mode,              --������[�h
              inventory_item_id,             --����i��ID
              organization_id,               --������̑g�DID
              transaction_quantity,          --�������
              transaction_uom,               --����P��
              transaction_date,              --���������
              subinventory_code,             --������̕ۊǏꏊ��
              transaction_source_id,         --����\�[�XID
              transaction_source_type_id,    --����\�[�X�^�C�vID
              transaction_type_id,           --����^�C�vID
              scheduled_flag,                --�v��t���O
              flow_schedule,                 --�v��t���[
              created_by,                    --�쐬��ID
              creation_date,                 --�쐬��
              last_updated_by,               --�ŏI�X�V��ID
              last_update_date,              --�ŏI�X�V��
              last_update_login,             --�ŏI���O�C��ID
              request_id,                    --�v��ID
              program_application_id,        --�v���O�����A�v���P�[�V����ID
              program_id,                    --�v���O����ID
              program_update_date            --�v���O�����X�V��
            )
          VALUES(
--************************************* 2009/04/28 N.Maeda Var1.4 MOD START *********************************************
--            g_mtl_txn_oif_tab(l).source_code,
--            g_mtl_txn_oif_tab(l).source_line_id,
--            g_mtl_txn_oif_tab(l).source_header_id,
--            g_mtl_txn_oif_tab(l).process_flag,
--            g_mtl_txn_oif_tab(l).validation_required,
--            g_mtl_txn_oif_tab(l).transaction_mode,
--            g_mtl_txn_oif_tab(l).inventory_item_id,
--            g_mtl_txn_oif_tab(l).organization_id,
--            g_mtl_txn_oif_tab(l).transaction_quantity,
--            g_mtl_txn_oif_tab(l).transaction_uom,
--            g_mtl_txn_oif_tab(l).transaction_date,
--            g_mtl_txn_oif_tab(l).subinventory_code,
--            g_mtl_txn_oif_tab(l).transaction_source_id,
--            g_mtl_txn_oif_tab(l).transaction_source_type_id,
--            g_mtl_txn_oif_tab(l).transaction_type_id,
--            g_mtl_txn_oif_tab(l).scheduled_flag,
--            g_mtl_txn_oif_tab(l).flow_schedule,
--            g_mtl_txn_oif_tab(l).created_by,
--            g_mtl_txn_oif_tab(l).creation_date,
--            g_mtl_txn_oif_tab(l).last_updated_by,
--            g_mtl_txn_oif_tab(l).last_update_date,
--            g_mtl_txn_oif_tab(l).last_update_login,
--            g_mtl_txn_oif_tab(l).request_id,
--            g_mtl_txn_oif_tab(l).program_application_id,
--            g_mtl_txn_oif_tab(l).program_id,
--            g_mtl_txn_oif_tab(l).program_update_date
            g_mtl_txn_oif_ins_tab(l).source_code,
            g_mtl_txn_oif_ins_tab(l).source_line_id,
            g_mtl_txn_oif_ins_tab(l).source_header_id,
            g_mtl_txn_oif_ins_tab(l).process_flag,
            g_mtl_txn_oif_ins_tab(l).validation_required,
            g_mtl_txn_oif_ins_tab(l).transaction_mode,
            g_mtl_txn_oif_ins_tab(l).inventory_item_id,
            g_mtl_txn_oif_ins_tab(l).organization_id,
            g_mtl_txn_oif_ins_tab(l).transaction_quantity,
            g_mtl_txn_oif_ins_tab(l).transaction_uom,
            g_mtl_txn_oif_ins_tab(l).transaction_date,
            g_mtl_txn_oif_ins_tab(l).subinventory_code,
            g_mtl_txn_oif_ins_tab(l).transaction_source_id,
            g_mtl_txn_oif_ins_tab(l).transaction_source_type_id,
            g_mtl_txn_oif_ins_tab(l).transaction_type_id,
            g_mtl_txn_oif_ins_tab(l).scheduled_flag,
            g_mtl_txn_oif_ins_tab(l).flow_schedule,
            g_mtl_txn_oif_ins_tab(l).created_by,
            g_mtl_txn_oif_ins_tab(l).creation_date,
            g_mtl_txn_oif_ins_tab(l).last_updated_by,
            g_mtl_txn_oif_ins_tab(l).last_update_date,
            g_mtl_txn_oif_ins_tab(l).last_update_login,
            g_mtl_txn_oif_ins_tab(l).request_id,
            g_mtl_txn_oif_ins_tab(l).program_application_id,
            g_mtl_txn_oif_ins_tab(l).program_id,
            g_mtl_txn_oif_ins_tab(l).program_update_date
--************************************* 2009/04/28 N.Maeda Var1.4 MOD  END  *********************************************
          )
          ;
/* 2009/06/17 Ver1.6 Add Start */
          END IF;
/* 2009/06/17 Ver1.6 Add End   */
        END IF;
      END LOOP insert_loop;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_data_insert_expt;
    END;
--
  EXCEPTION
    --*** �f�[�^�o�^��O ***
    WHEN global_data_insert_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name2
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
  END insert_mtl_tran_oif;
--
--
  /**********************************************************************************
   * Procedure Name   : update_inv_fsh_flag
   * Description      : �����σX�e�[�^�X�X�V(A-5)
   ***********************************************************************************/
  PROCEDURE update_inv_fsh_flag(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_inv_fsh_flag'; -- �v���O������
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
    lv_tkn_vl_table_name      VARCHAR2(100);      --�G���[�Ώۂł���e�[�u����
-- ************************ 2009/08/06 1.18 N.Maeda ADD START *************************** --
    ln_up_count               NUMBER;
-- ************************ 2009/08/06 1.18 N.Maeda ADD  END  *************************** --
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
    ln_excluded_num           NUMBER;
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
-- ************************ 2009/08/06 1.8 N.Maeda ADD START *************************** --
    TYPE line_id_tab_type IS TABLE OF xxcos_sales_exp_lines.sales_exp_line_id%TYPE INDEX BY BINARY_INTEGER;
    line_id_tab  line_id_tab_type;
-- ************************ 2009/08/06 1.8 N.Maeda ADD  END  *************************** --
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
    TYPE row_id_type IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    l_row_id  row_id_type;
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- ************************ 2009/08/06 1.18 N.Maeda ADD START *************************** --
--
-- ************************ 2009/08/25 1.10 N.Maeda ADD START *************************** --
    IF ( g_sales_exp_tab.COUNT > 0 ) THEN
-- ************************ 2009/08/25 1.10 N.Maeda ADD  END  *************************** --
      ln_up_count := 0;
      -- UPDATE�p�ϐ��փR�s�[
      <<up_co_loop>>
      FOR c IN g_sales_exp_tab.FIRST..g_sales_exp_tab.LAST LOOP
        IF ( g_sales_exp_tab.EXISTS( c ) ) THEN
          ln_up_count := ln_up_count + 1;
          line_id_tab(ln_up_count) := g_sales_exp_tab(c).line_id;
        END IF;
      END LOOP up_co_loop;
--
-- ************************ 2009/08/06 1.18 N.Maeda ADD  END  *************************** --
--
      --�̔����т̏����σX�e�[�^�X�̍X�V����
      BEGIN
-- ************************ 2009/08/06 1.8 N.Maeda MOD START *************************** --
--
--
        FORALL i IN 1..line_id_tab.COUNT
--
            UPDATE xxcos_sales_exp_lines sel                                   --�̔����і��׃e�[�u��
            SET    sel.inv_interface_flag       = cv_inv_flg_y,                --INV�C���^�t�F�[�X�σt���O
                   sel.last_updated_by          = cn_last_updated_by,          --�ŏI�X�V��
                   sel.last_update_date         = cd_last_update_date,         --�ŏI�X�V��
                   sel.last_update_login        = cn_last_update_login,        --�ŏI�X�V۸޲�
                   sel.request_id               = cn_request_id,               --�v��ID
                   sel.program_application_id   = cn_program_application_id,   --�ݶ��ĥ��۸��ѥ���ع����ID
                   sel.program_id               = cn_program_id,               --�ݶ��ĥ��۸���ID
                   sel.program_update_date      = cd_program_update_date       --��۸��эX�V��
            WHERE  sel.sales_exp_line_id        = line_id_tab(i)               --����ID
            ;
--
--      <<update_loop>>
--      FOR i IN g_sales_exp_tab.FIRST .. g_sales_exp_tab.LAST LOOP
--        IF ( g_sales_exp_tab.EXISTS( i ) ) THEN
--        UPDATE xxcos_sales_exp_lines sel                                   --�̔����і��׃e�[�u��
--        SET    sel.inv_interface_flag       = cv_inv_flg_y,                --INV�C���^�t�F�[�X�σt���O
--               sel.last_updated_by          = cn_last_updated_by,          --�ŏI�X�V��
--               sel.last_update_date         = cd_last_update_date,         --�ŏI�X�V��
--               sel.last_update_login        = cn_last_update_login,        --�ŏI�X�V۸޲�
--               sel.request_id               = cn_request_id,               --�v��ID
--               sel.program_application_id   = cn_program_application_id,   --�ݶ��ĥ��۸��ѥ���ع����ID
--               sel.program_id               = cn_program_id,               --�ݶ��ĥ��۸���ID
--               sel.program_update_date      = cd_program_update_date       --��۸��эX�V��
--        WHERE  sel.sales_exp_line_id        = g_sales_exp_tab(i).line_id   --����ID
--        ;
--        END IF;
--      END LOOP update_loop;
-- ************************ 2009/08/06 1.8 N.Maeda MOD  END  *************************** --
      EXCEPTION
        --�Ώۃf�[�^�X�V���s
        WHEN OTHERS THEN
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
          lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
            iv_application        =>  cv_xxcos_short_name,
            iv_name               =>  cv_msg_sales_exp_nomal
          );
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
          RAISE global_data_update_expt;
      END;
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
    END IF;
--
    IF ( gt_sales_exp_line_id.COUNT > 0 ) THEN
      -- �x���f�[�^�X�V
      BEGIN
        FORALL w IN 1..gt_sales_exp_line_id.COUNT
            UPDATE xxcos_sales_exp_lines sel                                   --�̔����і��׃e�[�u��
            SET    sel.inv_interface_flag       = cv_wan_data_flg,             --INV�C���^�t�F�[�X�x���I���t���O
                   sel.last_updated_by          = cn_last_updated_by,          --�ŏI�X�V��
                   sel.last_update_date         = cd_last_update_date,         --�ŏI�X�V��
                   sel.last_update_login        = cn_last_update_login,        --�ŏI�X�V۸޲�
                   sel.request_id               = cn_request_id,               --�v��ID
                   sel.program_application_id   = cn_program_application_id,   --�ݶ��ĥ��۸��ѥ���ع����ID
                   sel.program_id               = cn_program_id,               --�ݶ��ĥ��۸���ID
                   sel.program_update_date      = cd_program_update_date       --��۸��эX�V��
            WHERE  sel.sales_exp_line_id        = gt_sales_exp_line_id(w)       --����ID
            ;
      EXCEPTION
        --�Ώۃf�[�^�X�V���s
        WHEN OTHERS THEN
          lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
            iv_application        =>  cv_xxcos_short_name,
            iv_name               =>  cv_msg_sales_exp_warn
          );
          RAISE global_data_update_expt;
      END;
    END IF;
--
--
    -- �ΏۊO�f�[�^���b�N�A�ΏۊO�f�[�^�擾
    BEGIN
      SELECT xsel.ROWID row_id
      BULK COLLECT INTO l_row_id
      FROM   xxcos_sales_exp_headers xseh
             ,xxcos_sales_exp_lines   xsel
      WHERE  xseh.sales_exp_header_id = xsel.sales_exp_header_id
      AND    xsel.inv_interface_flag = cv_inv_flg_n
      AND    xseh.delivery_date     <= gd_proc_date
      FOR UPDATE OF xsel.inv_interface_flag NOWAIT;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- �����ΏۊO�f�[�^�����݂���ꍇ
    IF ( l_row_id.COUNT > 0 ) THEN
--
      -- �ΏۊO�f�[�^�X�V
      BEGIN
        FORALL n IN 1..l_row_id.COUNT
          UPDATE xxcos_sales_exp_lines sel                                   --�̔����і��׃e�[�u��
          SET    sel.inv_interface_flag       = cv_excluded_flg,             --INV�C���^�t�F�[�X�x���I���t���O
                 sel.last_updated_by          = cn_last_updated_by,          --�ŏI�X�V��
                 sel.last_update_date         = cd_last_update_date,         --�ŏI�X�V��
                 sel.last_update_login        = cn_last_update_login,        --�ŏI�X�V۸޲�
                 sel.request_id               = cn_request_id,               --�v��ID
                 sel.program_application_id   = cn_program_application_id,   --�ݶ��ĥ��۸��ѥ���ع����ID
                 sel.program_id               = cn_program_id,               --�ݶ��ĥ��۸���ID
                 sel.program_update_date      = cd_program_update_date       --��۸��эX�V��
          WHERE  sel.ROWID                    = l_row_id(n)                  --�sID
          ;
      EXCEPTION
        --�Ώۃf�[�^�X�V���s
        WHEN OTHERS THEN
          lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
            iv_application        =>  cv_xxcos_short_name,
            iv_name               =>  cv_msg_sales_exp_exclu
          );
        RAISE global_data_update_expt;
      END;
    END IF;
--
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
--
  EXCEPTION
    --*** �Ώۃf�[�^�X�V��O�n���h�� ***
    WHEN global_data_update_expt THEN
-- ********** 2009/08/25 N.Maeda Var1.10 DEL START *********** --
--      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
--        iv_application        =>  cv_xxcos_short_name,
--        iv_name               =>  cv_msg_vl_table_name1
--      );
-- ********** 2009/08/25 N.Maeda Var1.10 DEL  END  *********** --
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
-- ********** 2009/08/25 N.Maeda Var1.10 ADD START *********** --
    --*** �r�����b�N�擾�G���[�n���h�� ***
    WHEN global_data_lock_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_sales_exp_exclu
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_lock_err,
        iv_token_name1        =>  cv_tkn_nm_table_lock,
        iv_token_value1       =>  lv_tkn_vl_table_name
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
-- ********** 2009/08/25 N.Maeda Var1.10 ADD  END  *********** --
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
  END update_inv_fsh_flag;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ===============================
    -- A-1  ��������
    -- ===============================
    init(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  �Ώۃf�[�^�擾
    -- ===============================
    get_data(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  ���ގ���f�[�^����
    -- ===============================
    IF ( gn_target_cnt > 0 ) THEN
     make_mtl_tran_data(
       lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
       lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
       lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode = cv_status_normal ) THEN
       NULL;
     ELSE
       RAISE global_process_expt;
     END IF;
    END IF;
--
    -- ===============================
    -- A-4  ���ގ��OIF�o��
    -- ===============================
    IF ( g_mtl_txn_oif_tab.COUNT > 0 ) THEN
      insert_mtl_tran_oif(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- A-5  �����σX�e�[�^�X�X�V
    -- ===============================
-- ************************ 2009/08/25 1.10 N.Maeda DEL START *************************** --
--    IF ( g_sales_exp_tab.COUNT > 0 ) THEN
-- ************************ 2009/08/25 1.10 N.Maeda DEL  END  *************************** --
      update_inv_fsh_flag(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_process_expt;
      END IF;
-- ************************ 2009/08/25 1.10 N.Maeda DEL START *************************** --
--    END IF;
-- ************************ 2009/08/25 1.10 N.Maeda DEL  END  *************************** --
--
--
--************************************* 2009/04/28 N.Maeda Var1.4 MOD START *********************************************
    --���팏���擾
--    gn_normal_cnt := g_mtl_txn_oif_tab.COUNT;
    --���팏���擾
    gn_normal_cnt := g_mtl_txn_oif_ins_tab.COUNT;
--************************************* 2009/04/28 N.Maeda Var1.4 MOD  END  *********************************************
--
--
    --�X�e�[�^�X���䏈��
    IF ( gn_target_cnt = 0 OR gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
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
    errbuf              OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
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
--
--###########################  �Œ蕔 END   #############################
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
    IF ( lv_retcode <> cv_status_normal ) THEN
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
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
END XXCOS013A02C;
/
