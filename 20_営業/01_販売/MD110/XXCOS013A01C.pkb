CREATE OR REPLACE PACKAGE BODY APPS.XXCOS013A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS013A01C (body)
 * Description      : �̔����я����d������쐬���AAR��������ɘA�g���鏈��
 * MD.050           : AR�ւ̔̔����уf�[�^�A�g MD050_COS_013_A01
 * Version          : 1.27
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_data               �̔����уf�[�^�擾(A-2-1)
 *  edit_sum_data          ��������W�񏈗��i����ʔ̓X�j(A-3)
 *  edit_dis_data          AR��v�z���d��쐬�i����ʔ̓X�j(A-4)
 *  edit_sum_bulk_data     AR����������W�񏈗��i���ʔ̓X�j(A-5)
 *  edit_dis_bulk_data     AR��v�z���d��쐬�i���ʔ̓X�j(A-6)
 *  insert_aroif_data      AR�������OIF�o�^����(A-7)
 *  insert_ardis_data      AR��v�z��OIF�o�^����(A-8)
 *  upd_data               �̔����уw�b�_�X�V����(A-9)
 *  del_data               �̔�����AR�p���[�N�폜����(A-10)
 *  submain                ���C�������v���V�[�W��(A-2-2���܂�)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(�I������A-10���܂�)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2009/01/14    1.0   R.HAN            �V�K�쐬
 *  2009/02/17    1.1   R.HAN            get_msg�̃p�b�P�[�W���C��
 *  2009/02/23    1.2   R.HAN            �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/02/23    1.3   R.HAN            �ŃR�[�h�̌���������ǉ�
 *  2009/03/25    1.4   K.KIN            T1_0015�AT1_0019�AT1_0052�A
 *                                       T1_0053�AT1_0057�AT1_0144�Ή�
 *  2009/04/08    1.5   K.KIN            T1_0407
 *  2009/04/09    1.6   K.KIN            T1_0423
 *  2009/04/09    1.7   K.KIN            T1_0436
 *  2009/04/13    1.8   K.KIN            T1_0497
 *  2009/04/13    1.9   K.KIN            T1_0054,T1_0186,T1_0456,T1_0467
 *  2009/04/16    1.10  K.KIN            T1_0587
 *  2009/04/17    1.11  K.KIN            T1_0328
 *  2009/04/21    1.12  K.KIN            T1_0659
 *  2009/04/22    1.13  K.KIN            T1_0116
 *  2009/05/07    1.14  K.KIN            T1_0908
 *  2009/05/07    1.15  K.KIN            T1_0914�AT1_0915
 *  2009/05/11    1.16  K.KIN            T1_0453�AT1_0938
 *  2009/05/12    1.17  K.KIN            T1_0693
 *  2009/05/14    1.18  K.KIN            T1_0795
 *  2009/05/15    1.19  K.KIN            T1_0776
 *  2009/05/20    1.20  K.KIN            T1_1078
 *  2009/07/27    1.21  K.Kiriu          [0000829]PT�Ή�
 *  2009/07/30    1.21  M.Sano           [0000829]PT�ǉ��Ή�
 *                                       [0000899]�`�[���͎Ҏ擾SQL�����ǉ�
 *  2009/08/20    1.22  K.Kiriu          [0000884]PT�Ή�
 *  2009/08/24    1.22  K.Kiriu          [0001165]�`�[���͎Ҏ擾�����s���Ή�
 *  2009/08/28    1.23  K.Kiriu          [0001166]����Ȗڎ擾�����s���Ή�
 *                                       [0001211]�ŋ��}�X�^�e�[�u�������폜
 *                                       [0001215]�擾����Ȃ�CCID��NULL�Őݒ肳���s���Ή�
 *  2009/10/02    1.24  K.Kiriu          [0001321]PT�Ή� �q���g��A�t���O�X�V�����ǉ�
 *                                       [0001359]PT�Ή� �������Ή�
 *                                       [0001472]����̎���ԍ��̔ԏ����ύX(������ -> �o�א�)
 *  2009/10/27    1.25  K.Kiriu          [E_�ŏI�ڍs���n_00375]�x�����������Ή�
 *  2009/11/05    1.26  K.Kiriu          [E_T4_00103]AR����ԍ��̔ԒP�ʕύX�Ή�
 *                                       [E_�ŏI�ڍs���n_00519]���AR����ԍ��̍̔Ԍ`�ԕύX�Ή�
 *                                       [I_E_00648]�ڋq�K�w�s��Ή�
 *  2010/03/08    1.27  K.Atsushiba      [E_�{�ғ�_01400]�l���̎d��A�Ώۃf�[�^�Ȃ��̃X�e�C�^�X�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START  ###############################
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--#######################  �Œ�O���[�o���萔�錾�� END   ################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START ################################
--
  gv_out_msg       VARCHAR2(2000);            -- �o�̓��b�Z�[�W
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--#######################  �Œ�O���[�o���ϐ��錾�� END   ###############################
--
--##########################  �Œ苤�ʗ�O�錾�� START  #################################
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
--##########################  �Œ苤�ʗ�O�錾�� END   ###############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);       -- ���b�N�G���[
  global_proc_date_err_expt EXCEPTION;         -- �Ɩ����t�擾��O
  global_select_data_expt   EXCEPTION;         -- �f�[�^�擾��O
  global_insert_data_expt   EXCEPTION;         -- �o�^������O
  global_update_data_expt   EXCEPTION;         -- �X�V������O
  global_get_profile_expt   EXCEPTION;         -- �v���t�@�C���擾��O
  global_no_data_expt       EXCEPTION;         -- �Ώۃf�[�^�O���G���[
  global_no_lookup_expt     EXCEPTION;         -- LOOKUP�擾�G���[
  global_term_id_expt       EXCEPTION;         -- �x������ID�擾�G���[
  global_card_inf_expt      EXCEPTION;         -- �J�[�h��Ў擾�G���[
/* 2009/10/02 Ver1.24 Add Start */
  global_delete_data_expt   EXCEPTION;         -- �폜�����G���[
/* 2009/10/02 Ver1.24 Add End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_xxccp_short_nm         CONSTANT VARCHAR2(10) := 'XXCCP';            -- ���ʗ̈�Z�k�A�v����
  cv_xxcos_short_nm         CONSTANT VARCHAR2(10) := 'XXCOS';            -- �̕��A�v���P�[�V�����Z�k��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOS013A01C';     -- �p�b�P�[�W��
/* 2009/10/02 Ver1.24 Del Start */
--  cv_no_para_msg            CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
/* 2009/10/02 Ver1.24 Del End   */
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014'; -- �Ɩ����t�擾�G���[
  cv_pro_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004'; -- �v���t�@�C���擾�G���[
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013'; -- �f�[�^���o�G���[���b�Z�[�W
  cv_no_data_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003'; -- �Ώۃf�[�^�������b�Z�[�W
  cv_table_lock_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001'; -- ���b�N�G���[���b�Z�[�W�i�̔�����TB�j
  cv_data_insert_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010'; -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_data_update_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011'; -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_pro_mo_org_cd          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00047'; -- �c�ƒP�ʎ擾�G���[
/* 2009/10/02 Ver1.24 Add Start */
  cv_data_delete_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00012'; -- �f�[�^�폜�G���[���b�Z�[�W
  cv_param_err_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00006'; -- �K�{���̓p�����[�^���ݒ�G���[
/* 2009/10/02 Ver1.24 Add End   */
--
  cv_tkn_sales_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12751'; -- �̔����уw�b�_
  cv_tkn_aroif_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12752'; -- AR�������OIF
  cv_tkn_ardis_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12753'; -- AR��v�z��OIF
  cv_sales_nm_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12754'; -- �̔�����
  cv_pro_bks_id             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12755'; -- ��v����ID
  cv_pro_org_cd             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12756'; -- �݌ɑg�D�R�[�h
  cv_org_id_get_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12757'; -- �݌ɑg�DID
  cv_pro_company_cd         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12758'; -- ��ЃR�[�h
  cv_var_elec_item_cd       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12759'; -- �ϓ��d�C��(�i�ڃR�[�h)
  cv_busi_dept_cd           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12760'; -- �Ɩ��Ǘ���
  cv_busi_emp_cd            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12761'; -- �Ɩ��Ǘ����S����
  cv_card_sale_cls_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12762'; -- �J�[�h����敪�擾�G���[
  cv_tax_cls_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12763'; -- ����ŋ敪�擾�G���[
  cv_cust_err_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12764'; -- �ڋq�敪�擾�G���[
  cv_gyotai_err_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12765'; -- �Ƒԏ����ގ擾�G���[
  cv_trxtype_err_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12766'; -- ����^�C�v�擾�G���[
  cv_itemdesp_err_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12767'; -- AR�i�ږ��דE�v�擾�G���[
  cv_tkn_ccid_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12768'; -- ����Ȗڑg�����}�X�^
  cv_ccid_nodata_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12769'; -- CCID�擾�o���Ȃ��G���[
  cv_dis_item_cd            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12770'; -- ����l���i��
  cv_jour_nodata_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12771'; -- �d��p�^�[���擾�G���[
  cv_tax_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12772'; -- �������œ�(����Ȗڗp)
  cv_goods_msg              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12773'; -- ���i���㍂(����Ȗڗp)
  cv_prod_msg               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12774'; -- ���i���㍂(����Ȗڗp)
  cv_disc_msg               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12775'; -- ����l��(����Ȗڗp)
  cv_success_aroif_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12776'; -- AR�������OIF�����������b�Z�[�W
  cv_success_ardis_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12777'; -- AR��v�z��OIF�����������b�Z�[�W
  cv_employee_code_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12786'; -- �]�ƈ��R�[�h
  cv_header_id_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12787'; -- �w�b�_ID
  cv_order_no_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00131'; -- �`�[�ԍ�
  cv_skip_rec_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12788'; -- �X�L�b�v�������b�Z�[�W
  cv_term_id_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12778'; -- �x������ID�擾�G���[
  cv_tax_in_msg             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12779'; -- ���ŃR�[�h�擾�G���[
  cv_tax_out_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12780'; -- �O�ŃR�[�h�擾�G���[
  cv_tkn_user_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00051'; -- �]�ƈ��}�X�^
  cv_card_comp_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12781'; -- �J�[�h��Ђ����ݒ�
  cv_cust_num_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12782'; -- �J�[�h��Ђ̃f�[�^���ڋq�ǉ����ɂȂ�
  cv_receiv_base_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12783'; -- �������_�����ݒ�
  cv_org_sys_id_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12784'; -- �ڋq���ݒn�Q��ID�����ݒ�
  cv_jour_no_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12785'; -- �d��p�^�[���Ȃ�
  cv_receipt_id_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12789'; -- �x�����@�����ݒ�
  cv_tax_no_msg             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12790'; -- �ΏۊO�ŋ��R�[�h�擾�G���[
/* 2009/07/30 Ver1.21 Add Start */
  cv_goods_prod_cls         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12791'; -- XXCOI:���i���i�敪�J�e�S���Z�b�g��
  cv_no_cate_set_id_msg     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12792'; -- �J�e�S���Z�b�gID�擾�G���[
  cv_no_cate_id_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12793'; -- �J�e�S��ID�擾�G���[���b�Z�[�W
/* 2009/07/30 Ver1.21 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
  cv_msg_param              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12794'; -- �p�����[�^�[�o��
  cv_tkn_target_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12795'; -- �����Ώۋ敪
  cv_tkn_create_c_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12796'; -- �쐬���敪
  cv_tkn_ar_bukl_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12797'; -- XXCOS:AR���ʃZ�b�g�擾����(�o���N)
  cv_tkn_if_bukl_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12798'; -- XXCOS:AR�C���^�[�t�F�[�X�o�b�`�쐬����
  cv_tkn_work_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12799'; -- �̔�����AR�p���[�N
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/10/27 Ver1.25 Add Start */
  cv_tkn_spot_payment_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12800'; -- XXCOS:�x����������
/* 2009/10/27 Ver1.25 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
  cv_tkn_dlv_inp_user_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-14001'; -- XXCOS:AR���ʔ̓X�`�[���͎�
/* 2009/11/05 Ver1.26 Add End   */
--
  -- �g�[�N��
  cv_tkn_pro                CONSTANT  VARCHAR2(20) := 'PROFILE';         -- �v���t�@�C��
  cv_tkn_tbl                CONSTANT  VARCHAR2(20) := 'TABLE';           -- �e�[�u������
  cv_tkn_tbl_nm             CONSTANT  VARCHAR2(20) := 'TABLE_NAME';      -- �e�[�u������
  cv_tkn_lookup_type        CONSTANT  VARCHAR2(20) := 'LOOKUP_TYPE';     -- �Q�ƃ^�C�v
  cv_tkn_lookup_code        CONSTANT  VARCHAR2(20) := 'LOOKUP_CODE';     -- �N�C�b�N�R�[�h
  cv_tkn_lookup_dff2        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE2';      -- �Q�ƃ^�C�v��DFF2
  cv_tkn_lookup_dff3        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE3';      -- �Q�ƃ^�C�v��DFF3
  cv_tkn_lookup_dff4        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE4';      -- �Q�ƃ^�C�v��DFF4
  cv_tkn_lookup_dff5        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE5';      -- �Q�ƃ^�C�v��DFF5
  cv_tkn_segment1           CONSTANT  VARCHAR2(20) := 'SEGMENT1';        -- ��ЃR�[�h
  cv_tkn_segment2           CONSTANT  VARCHAR2(20) := 'SEGMENT2';        -- ����R�[�h
  cv_tkn_segment3           CONSTANT  VARCHAR2(20) := 'SEGMENT3';        -- ����ȖڃR�[�h
  cv_tkn_segment4           CONSTANT  VARCHAR2(20) := 'SEGMENT4';        -- �⏕�ȖڃR�[�h
  cv_tkn_segment5           CONSTANT  VARCHAR2(20) := 'SEGMENT5';        -- �ڋq�R�[�h
  cv_tkn_segment6           CONSTANT  VARCHAR2(20) := 'SEGMENT6';        -- ��ƃR�[�h
  cv_tkn_segment7           CONSTANT  VARCHAR2(20) := 'SEGMENT7';        -- ���Ƌ敪�R�[�h
  cv_tkn_segment8           CONSTANT  VARCHAR2(20) := 'SEGMENT8';        -- �\��
  cv_blank                  CONSTANT  VARCHAR2(1)  := '';                -- �u�����N
  cv_and                    CONSTANT  VARCHAR2(6)  := ' AND ';           -- �u�����N
  cv_tkn_key_data           CONSTANT  VARCHAR2(20) := 'KEY_DATA';        -- �L�[����
  cv_tkn_cust_code          CONSTANT  VARCHAR2(20) := 'CUST_CODE';       -- �ڋq�R�[�h
  cv_tkn_card_company       CONSTANT  VARCHAR2(20) := 'CARD_COMPANY';    -- �J�[�h���
  cv_tkn_payment_term1      CONSTANT  VARCHAR2(20) := 'PAYMENT_TERM1';   -- �x�������P
  cv_tkn_payment_term2      CONSTANT  VARCHAR2(20) := 'PAYMENT_TERM2';   -- �x�������Q
  cv_tkn_payment_term3      CONSTANT  VARCHAR2(20) := 'PAYMENT_TERM3';   -- �x�������R
  cv_tkn_procedure_name     CONSTANT  VARCHAR2(20) := 'PROCEDURE_NAME';  -- �v���V�[�W����
  cv_tkn_invoice_cls        CONSTANT  VARCHAR2(20) := 'INVOICE_CLS';     -- �`�[�敪
  cv_tkn_prod_cls           CONSTANT  VARCHAR2(20) := 'PROD_CLS';        -- �i�ڋ敪
  cv_tkn_gyotai_sho         CONSTANT  VARCHAR2(20) := 'GYOTAI_SHO';      -- �Ƒԏ�����
  cv_tkn_sale_cls           CONSTANT  VARCHAR2(20) := 'SALE_CLS';        -- �J�[�h����敪
  cv_tkn_red_black_flag     CONSTANT  VARCHAR2(20) := 'RED_BLACK_FLAG';  -- �ԍ��t���O
  cv_tkn_header_id          CONSTANT  VARCHAR2(20) := 'HEADER_ID';       -- �w�b�_ID
  cv_tkn_order_no           CONSTANT  VARCHAR2(20) := 'ORDER_NO';        -- �`�[�ԍ�
/* 2009/10/02 Ver1.24 Add Start */
  cv_tkn_param1             CONSTANT  VARCHAR2(20) := 'PARAM1';          -- �p�����[�^1
  cv_tkn_param2             CONSTANT  VARCHAR2(20) := 'PARAM2';          -- �p�����[�^2
  cv_tkn_in_param           CONSTANT VARCHAR2(20)  := 'IN_PARAM';        -- �p�����[�^����
/* 2009/10/02 Ver1.24 Add End   */
--
  -- �t���O�E�敪�萔
  cv_y_flag                 CONSTANT  VARCHAR2(1)  := 'Y';               -- �t���O�l:Y
  cv_n_flag                 CONSTANT  VARCHAR2(1)  := 'N';               -- �t���O�l:N
/* 2009/10/02 Ver1.24 Add Start */
  cv_w_flag                 CONSTANT  VARCHAR2(1)  := 'W';               -- �t���O�l:W
  cv_s_flag                 CONSTANT  VARCHAR2(1)  := 'S';               -- �t���O�l:S
/* 2009/10/02 Ver1.24 Add End   */
  cv_card_class             CONSTANT  VARCHAR2(1)  := '1';               -- �J�[�h����敪�F�J�[�h= 1
  cv_cash_class             CONSTANT  VARCHAR2(1)  := '0';               -- �J�[�h����敪�F����= 0
  cn_min_day                CONSTANT  NUMBER       := 1;                 -- �x�������}�X�^�̏���
  cn_max_day                CONSTANT  NUMBER       := 32;                -- �x�������}�X�^�̍ő��
  cv_goods_prod_syo         CONSTANT  VARCHAR2(1)  := '1';               -- �i�ڋ敪�F���i= 1
  cv_goods_prod_sei         CONSTANT  VARCHAR2(1)  := '2';               -- �i�ڋ敪�F���i= 2
  cv_site_code              CONSTANT  VARCHAR2(10) := 'BILL_TO';         -- �T�C�g�R�[�h
  cn_ship_flg_on            CONSTANT  NUMBER       := 1;                 -- �o�א�ڋq�t���O��ON
  cn_ship_flg_off           CONSTANT  NUMBER       := 0;                 -- �o�א�ڋq�t���O��OFF
/* 2009/07/27 Ver1.21 Add Start */
  cv_cust_relate_status     CONSTANT  VARCHAR2(1)  := 'A';               -- �ڋq�֘A�X�e�[�^�X(�L��)
  cv_cust_bill              CONSTANT  VARCHAR2(1)  := '1';               -- �֘A����(����)
  cv_cust_cash              CONSTANT  VARCHAR2(1)  := '2';               -- �֘A����(����)
  cv_cust_class_uri         CONSTANT  VARCHAR2(2)  := '14';              -- �ڋq�敪(���|���Ǘ���ڋq)
  cv_cust_class_cust        CONSTANT  VARCHAR2(2)  := '10';              -- �ڋq�敪(�ڋq)
  cv_cust_class_ue          CONSTANT  VARCHAR2(2)  := '12';              -- �ڋq�敪(��l)
/* 2009/07/27 Ver1.21 Add End   */
/* 2010/03/08 Ver1.27 Add Start   */
  cv_status_enable          CONSTANT VARCHAR2(1)   := 'A';               -- �X�e�C�^�X�FA�i�L���j
/* 2010/03/08 Ver1.27 Add End   */
--
  -- �N�C�b�N�R�[�h�^�C�v
  cv_qct_card_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_CARD_SALE_CLASS';         -- �J�[�h���敪����}�X�^
  cv_qct_gyotai_sho         CONSTANT  VARCHAR2(50) := 'XXCOS1_GYOTAI_SHO_MST_013_A01';  -- �Ƒԏ����ޓ���}�X�^
  cv_qct_sale_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_SALE_CLASS_MST_013_A01';  -- ����敪����}�X�^
  cv_qct_mkorg_cls          CONSTANT  VARCHAR2(50) := 'XXCOS1_MK_ORG_CLS_MST_013_A01';  -- �쐬���敪����}�X�^
  cv_qct_dlv_slp_cls        CONSTANT  VARCHAR2(50) := 'XXCOS1_DLV_SLP_CLS_MST_013_A01'; -- �[�i�`�[�敪����}�X�^
  cv_qcv_tax_cls            CONSTANT  VARCHAR2(50) := 'XXCOS1_CONSUMPTION_TAX_CLASS';   -- ����ŋ敪����}�X�^
  cv_qct_cust_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_CUS_CLASS_MST_013_A01';   -- �ڋq�敪����}�X�^
  cv_qct_item_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_ITEM_DTL_MST_013_A01';    -- AR�i�ږ��דE�v����}�X�^
  cv_qct_jour_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_JOUR_CLS_MST_013_A01';    -- AR��v�z���d�����}�X�^
  cv_out_tax_cls            CONSTANT  VARCHAR2(50) := 'XXCOS1_CONS_TAX_NO_APPLICABLE';  -- ����ŋ敪(�ΏۊO)
--
  -- �N�C�b�N�R�[�h
  cv_qcc_code               CONSTANT  VARCHAR2(50) := 'XXCOS_013_A01%';                 -- �N�C�b�N�R�[�h
  cv_attribute_y            CONSTANT  VARCHAR2(1)  := 'Y';                              -- DFF�l'Y'
  cv_attribute_n            CONSTANT  VARCHAR2(1)  := 'N';                              -- DFF�l'N'
  cv_attribute_a            CONSTANT  VARCHAR2(1)  := 'A';                              -- DFF�l'A'
  cv_attribute_b            CONSTANT  VARCHAR2(1)  := 'B';                              -- DFF�l'B'
  cv_enabled_yes            CONSTANT  VARCHAR2(1)  := 'Y';                              -- �g�p�\�t���O�萔:�L��
  cv_attribute_1            CONSTANT  VARCHAR2(1)  := '1';                              -- DFF�l'1'
  cv_attribute_2            CONSTANT  VARCHAR2(1)  := '2';                              -- DFF�l'2'
--
  -- �������OIF�e�[�u���ɐݒ肷��Œ�l
  cv_currency_code         CONSTANT  VARCHAR2(3)   := 'JPY';                            -- �ʉ݃R�[�h
  cv_line                  CONSTANT  VARCHAR2(4)   := 'LINE';                           -- ���v�s
  cv_tax                   CONSTANT  VARCHAR2(3)   := 'TAX';                            -- �ŋ��s
  cv_user                  CONSTANT  VARCHAR2(4)   := 'User';                           -- ���Z�^�C�v�p(User��ݒ�)
  cv_open                  CONSTANT  VARCHAR2(4)   := 'OPEN';                           -- �w�b�_�[DFF7(�\���P)
  cv_hold                  CONSTANT  VARCHAR2(4)   := 'HOLD';                           -- �w�b�_�[DFF7(�\���P)
  cv_wait                  CONSTANT  VARCHAR2(7)   := 'WAITING';                        -- �w�b�_�[DFF(�\��)
  cv_round_rule_up         CONSTANT  VARCHAR2(10)  := 'UP';                             -- �؂�グ
  cv_round_rule_down       CONSTANT  VARCHAR2(10)  := 'DOWN';                           -- �؂艺��
  cv_round_rule_nearest    CONSTANT  VARCHAR2(10)  := 'NEAREST';                        -- �l�̌ܓ�
  cn_quantity              CONSTANT  NUMBER        := 1;                                -- ����=1
  cn_con_rate              CONSTANT  NUMBER        := 1;                                -- ���Z���[�g
  cn_percent               CONSTANT  NUMBER        := 100;                              -- 100
  cn_jour_cnt              CONSTANT  NUMBER        := 3;                                -- AR�z���d��J�E���g
--
  -- AR��v�z��OIF�e�[�u���ɐݒ肷��Œ�l
  cv_acct_rev              CONSTANT  VARCHAR2(4)   := 'REV';                            -- �z���^�C�v�F���v
  cv_acct_tax              CONSTANT  VARCHAR2(4)   := 'TAX';                            -- �z���^�C�v�FTAX
  cv_acct_rec              CONSTANT  VARCHAR2(4)   := 'REC';                            -- �z���^�C�v�F���Ȗ�
  cv_nvd                   CONSTANT  VARCHAR2(4)   := 'NV';                             -- VD�ȊO�̋ƑԂƔ[�iVD�ݒ�p
--
  -- ���t�t�H�[�}�b�g
  cv_date_format_non_sep      CONSTANT VARCHAR2(20) := 'YYYYMMDD';
  cv_date_format_on_sep       CONSTANT VARCHAR2(20) := 'YYYY/MM/DD';
  cv_date_format_yyyymm       CONSTANT VARCHAR2(8)  := 'YYYY/MM/';
  cv_substr_st                CONSTANT NUMBER       := 7;
  cv_substr_cnt               CONSTANT NUMBER       := 2;
/* 2009/07/27 Ver1.21 Add Start */
--
  -- ���o�����p
  ct_lang                  CONSTANT  fnd_lookup_values.language%TYPE := USERENV('LANG'); -- ����
  cd_sysdate               CONSTANT  DATE           := SYSDATE;                          -- �V�X�e�����t
/* 2009/07/27 Ver1.21 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
  cv_major                 CONSTANT  VARCHAR2(1)     := '1';                             -- �����Ώۋ敪(���)
  cv_not_major             CONSTANT  VARCHAR2(1)     := '2';                             -- �����Ώۋ敪(����)
/* 2009/10/02 Ver1.24 Add End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �̔����у��[�N�e�[�u����`
  TYPE gr_sales_exp_rec IS RECORD(
      sales_exp_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE    -- �̔����уw�b�_ID
    , dlv_invoice_number        xxcos_sales_exp_headers.dlv_invoice_number%TYPE     -- �[�i�`�[�ԍ�
    , dlv_invoice_class         xxcos_sales_exp_headers.dlv_invoice_class%TYPE      -- �[�i�`�[�敪
    , cust_gyotai_sho           xxcos_sales_exp_headers.cust_gyotai_sho%TYPE        -- �Ƒԏ�����
    , delivery_date             xxcos_sales_exp_headers.delivery_date%TYPE          -- �[�i��
    , inspect_date              xxcos_sales_exp_headers.inspect_date%TYPE           -- ������
    , ship_to_customer_code     xxcos_sales_exp_headers.ship_to_customer_code%TYPE  -- �ڋq�y�[�i��z
    , tax_code                  xxcos_sales_exp_headers.tax_code%TYPE               -- �ŋ��R�[�h
    , tax_rate                  xxcos_sales_exp_headers.tax_rate%TYPE               -- ����ŗ�
    , consumption_tax_class     xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- ����ŋ敪
    , results_employee_code     xxcos_sales_exp_headers.results_employee_code%TYPE  -- ���ьv��҃R�[�h
    , sales_base_code           xxcos_sales_exp_headers.sales_base_code%TYPE        -- ���㋒�_�R�[�h
    , receiv_base_code          xxcos_sales_exp_headers.receiv_base_code%TYPE       -- �������_�R�[�h
    , create_class              xxcos_sales_exp_headers.create_class%TYPE           -- �쐬���敪
    , card_sale_class           xxcos_sales_exp_headers.card_sale_class%TYPE        -- �J�[�h����敪
    , dlv_inv_line_no           xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE  -- �[�i���הԍ�
    , item_code                 xxcos_sales_exp_lines.item_code%TYPE                -- �i�ڃR�[�h
    , sales_class               xxcos_sales_exp_lines.sales_class%TYPE              -- ����敪
    , red_black_flag            xxcos_sales_exp_lines.red_black_flag%TYPE           -- �ԍ��t���O
    , goods_prod_cls            xxcos_good_prod_class_v.goods_prod_class_code%TYPE  -- �i�ڋ敪(���i�E���i)
    , pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE              -- �{�̋��z
    , tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE               -- ����ŋ��z
    , cash_and_card             xxcos_sales_exp_lines.cash_and_card%TYPE            -- �����E�J�[�h���p�z
    , rcrm_receipt_id           ra_cust_receipt_methods.receipt_method_id%TYPE      -- �ڋq�x�����@ID
    , xchv_cust_id_s            xxcos_cust_hierarchy_v.ship_account_id%TYPE         -- �o�א�ڋqID
    , xchv_cust_id_b            xxcos_cust_hierarchy_v.bill_account_id%TYPE         -- ������ڋqID
    , xchv_cust_number_b        xxcos_cust_hierarchy_v.bill_account_number%TYPE     -- ������ڋq�R�[�h
    , xchv_cust_id_c            xxcos_cust_hierarchy_v.cash_account_id%TYPE         -- ������ڋqID
    , hcss_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE       -- �ڋq���ݒn�Q��ID(�o�א�)
    , hcsb_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE       -- �ڋq���ݒn�Q��ID(������)
    , hcsc_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE       -- �ڋq���ݒn�Q��ID(������)
    , xchv_bill_pay_id          xxcos_cust_hierarchy_v.bill_payment_term_id%TYPE    -- �x������ID
    , xchv_bill_pay_id2         xxcos_cust_hierarchy_v.bill_payment_term2%TYPE      -- �x������2
    , xchv_bill_pay_id3         xxcos_cust_hierarchy_v.bill_payment_term3%TYPE      -- �x������3
    , xchv_tax_round            xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE     -- �ŋ��|�[������
    , xseh_rowid                ROWID                                               -- ROWID
    , oif_trx_number            ra_interface_lines_all.trx_number%TYPE              -- AR����ԍ�
    , oif_dff4                  ra_interface_lines_all.interface_line_attribute4%TYPE -- DFF4�F�`�[No�{�V�[�P���X
    , oif_tax_dff4              ra_interface_lines_all.interface_line_attribute4%TYPE -- DFF4�ŋ��p�F�`�[No�{�V�[�P���X
    , line_id                   xxcos_sales_exp_lines.sales_exp_line_id%TYPE          -- �̔����і��הԍ�
    , card_receiv_base          xxcos_sales_exp_headers.receiv_base_code%TYPE         -- �J�[�hVD�������_�R�[�h
    , pay_cust_number           xxcos_cust_hierarchy_v.bill_account_number%TYPE       -- �x�������p������ڋq�R�[�h
/* 2009/10/02 Ver1.24 Add Start */
    , request_id                NUMBER(15,0)                                          -- �v��ID
/* 2009/10/02 Ver1.24 Add End   */
  );
--
  -- �d��p�^�[�����[�N�e�[�u����`
  TYPE gr_jour_cls_rec IS RECORD(
      segment3_nm               fnd_lookup_values.description%TYPE                  -- ����Ȗږ���
    , dlv_invoice_cls           fnd_lookup_values.attribute1%TYPE                   -- �[�i�`�[�敪
    , item_prod_cls             fnd_lookup_values.attribute2%TYPE                   -- �i�ڃR�[�hOR���i�E���i
    , cust_gyotai_sho           fnd_lookup_values.attribute3%TYPE                   -- �Ƒԏ�����
    , card_sale_cls             fnd_lookup_values.attribute4%TYPE                   -- �J�[�h����敪
    , red_black_flag            fnd_lookup_values.attribute5%TYPE                   -- �ԍ��t���O
    , acct_type                 fnd_lookup_values.attribute6%TYPE                   -- �z���^�C�v
    , segment2                  fnd_lookup_values.attribute7%TYPE                   -- ����R�[�h
    , segment3                  fnd_lookup_values.attribute8%TYPE                   -- ����ȖڃR�[�h
    , segment4                  fnd_lookup_values.attribute9%TYPE                   -- �⏕����ȖڃR�[�h
    , segment5                  fnd_lookup_values.attribute10%TYPE                  -- �ڋq�R�[�h
    , segment6                  fnd_lookup_values.attribute11%TYPE                  -- ��ƃR�[�h
    , segment7                  fnd_lookup_values.attribute12%TYPE                  -- ���Ƌ敪�R�[�h
    , segment8                  fnd_lookup_values.attribute13%TYPE                  -- �\���P
    , amount_sign               fnd_lookup_values.attribute14%TYPE                  -- ���z����
  );
--
  -- ���[�N�e�[�u����`
  TYPE gr_select_ccid IS RECORD(
      code_combination_id       gl_code_combinations.code_combination_id%TYPE       -- CCID
  );
  -- �i�ږ��׃��[�N�e�[�u����`
  TYPE gr_sel_item_desp IS RECORD(
      description               fnd_lookup_values.description%TYPE                  -- �i�ږ��דE�v
  );
  -- ����^�C�v���[�N�e�[�u����`
  TYPE gr_sel_trx_type IS RECORD(
      attribute1                fnd_lookup_values.attribute1%TYPE                   -- ����^�C�v
    , attribute2                VARCHAR2(30)                                        -- ���������s�敪
  );
  -- AR��v�z���W��p���[�N�e�[�u����`
  TYPE gr_dis_sum IS RECORD(
      sales_exp_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE    -- �̔����уw�b�_ID
    , dlv_invoice_number        xxcos_sales_exp_headers.dlv_invoice_number%TYPE     -- �[�i�`�[�ԍ�
    , interface_line_dff4       VARCHAR2(20)                                        -- �����̔�:LINE
    , interface_tax_dff4        VARCHAR2(20)                                        -- �����̔�:TAX
    , dlv_invoice_class         xxcos_sales_exp_headers.dlv_invoice_class%TYPE      -- �[�i�`�[�敪
    , item_code                 xxcos_sales_exp_lines.item_code%TYPE                -- �i�ڃR�[�h
    , goods_prod_cls            xxcos_good_prod_class_v.goods_prod_class_code%TYPE  -- �i�ڋ敪�i���i�E���i�j
    , cust_gyotai_sho           xxcos_sales_exp_headers.cust_gyotai_sho%TYPE        -- �Ƒԏ�����
    , sales_base_code           xxcos_sales_exp_headers.sales_base_code%TYPE        -- ���㋒�_�R�[�h
    , card_sale_class           xxcos_sales_exp_headers.card_sale_class%TYPE        -- �J�[�h����敪
    , red_black_flag            xxcos_sales_exp_lines.red_black_flag%TYPE           -- �ԍ��t���O
    , gccs_segment3             gl_code_combinations.segment3%TYPE                  -- ���㊨��ȖڃR�[�h
    , gcct_segment3             gl_code_combinations.segment3%TYPE                  -- �ŋ�����ȖڃR�[�h
    , pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE              -- �{�̋��z
    , tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE               -- ����ŋ��z
    , consumption_tax_class     xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- ����ŋ敪
  );
/* 2009/10/02 Ver1.24 Add Start */
  TYPE g_sales_exp_id_bk IS RECORD(
      sales_exp_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE    -- �̔����уw�b�_ID
    , xseh_rowid                ROWID                                               -- ROWID
  );
/* 2009/10/02 Ver1.24 Add End   */
--
  -- �̔����у��[�N�e�[�u���^��`
  TYPE g_sales_exp_ttype IS TABLE OF gr_sales_exp_rec INDEX BY BINARY_INTEGER;
  TYPE g_v_od_data_ttype IS TABLE OF gr_sales_exp_rec INDEX BY VARCHAR(100);
/* 2009/10/02 Ver1.24 Add Start */
  TYPE g_sales_exp_ttype_bk IS TABLE OF g_sales_exp_id_bk INDEX BY BINARY_INTEGER;
/* 2009/10/02 Ver1.24 Add End   */
--
  gt_sales_exp_tbl              g_sales_exp_ttype;                                  -- �̔����уf�[�^(���C��SQL)
  gt_sales_exp_tbl2             g_sales_exp_ttype;                                  -- �̔����уf�[�^(���[�N�e�[�u���C���T�[�g)
/* 2009/10/02 Ver1.24 Mod Start */
--  gt_sales_skip_tbl             g_sales_exp_ttype;                                  -- �̔����уf�[�^
  gt_sales_skip_tbl             g_sales_exp_ttype_bk;                               -- �̔����уf�[�^(�X�L�b�v�f�[�^)
  gt_sales_target_tbl           g_sales_exp_ttype_bk;                               -- �̔����уf�[�^(����������)
/* 2009/10/02 Ver1.24 Mod End   */
  gt_sales_norm_tbl             g_sales_exp_ttype;                                  -- �̔����є���ʔ̓X�f�[�^
  gt_sales_norm_tbl2            g_sales_exp_ttype;                                  -- �̔����є���ʔ̓X�f�[�^�i�C���T�[�g�j
  gt_sales_bulk_tbl             g_sales_exp_ttype;                                  -- �̔����ё��ʔ̓X�f�[�^
  gt_sales_bulk_tbl2            g_sales_exp_ttype;                                  -- �̔����ё��ʔ̓X�f�[�^�i�C���T�[�g�j
/* 2009/10/02 Ver1.24 Add Start */
  gt_sales_sum_tbl_brk          g_sales_exp_ttype;                                  -- ��������W��f�[�^�i�u���[�N�f�[�^�ێ��j
  gt_sales_dis_tbl_brk          g_sales_exp_ttype;                                  -- AR��v�z���d��f�[�^�i�u���[�N�f�[�^�ێ��j
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/10/02 Ver1.24 Del Start */
--  gt_sales_norm_order_tbl       g_v_od_data_ttype;                                  -- �̔����є���ʔ̓X�f�[�^(�\�[�g)
--  gt_sales_bulk_order_tbl       g_v_od_data_ttype;                                  -- �̔����ё��ʔ̓X�f�[�^(�\�[�g)
--
----*** MIYATA DELETE START ***
--gt_norm_card_tbl              g_sales_exp_ttype;                                  -- �̔����є���ʔ̓X�J�[�h�f�[�^
--gt_bulk_card_tbl              g_sales_exp_ttype;                                  -- �̔����ё��ʔ̓X�J�[�h�f�[�^
----*** MIYATA DELETE END   ***
/* 2009/10/02 Ver1.24 Del End   */
--
  TYPE g_sales_h_ttype   IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
  gt_sales_h_tbl                     g_sales_h_ttype;                               -- �̔����уt���O�X�V�p
--
  TYPE g_jour_cls_ttype  IS TABLE OF gr_jour_cls_rec INDEX BY BINARY_INTEGER;
  gt_jour_cls_tbl                    g_jour_cls_ttype;                              -- �d��p�^�[��
--
  TYPE g_ar_oif_ttype    IS TABLE OF ra_interface_lines_all%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_ar_interface_tbl                g_ar_oif_ttype;                                -- AR�������OIF
  gt_ar_interface_tbl1               g_ar_oif_ttype;                                -- AR�������OIF
--
  TYPE g_ar_dis_ttype    IS TABLE OF ra_interface_distributions_all%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_ar_dis_tbl                      g_ar_dis_ttype;                                -- AR��v�z��OIF
  gt_ar_dis_tbl1                     g_ar_dis_ttype;                                -- AR��v�z��OIF
--
  TYPE g_dis_sum_ttype   IS TABLE OF gr_dis_sum INDEX BY BINARY_INTEGER;
  gt_ar_dis_sum_tbl                  g_dis_sum_ttype;                               -- AR��v�z���W��p
  gt_ar_dis_bul_tbl                  g_dis_sum_ttype;                               -- AR��v�z���W��p(BULK)
--
  TYPE g_sel_ccid_ttype  IS TABLE OF gr_select_ccid INDEX BY VARCHAR2( 200 );
  gt_sel_ccid_tbl                    g_sel_ccid_ttype;                              -- CCID
--
  TYPE g_sel_item_ttype  IS TABLE OF gr_sel_item_desp INDEX BY VARCHAR2( 200 );
  gt_sel_item_desp_tbl               g_sel_item_ttype;                              -- �i�ږ��דE�v
--
  TYPE g_sel_trx_ttype   IS TABLE OF gr_sel_trx_type INDEX BY VARCHAR2( 200 );
  gt_sel_trx_type_tbl                g_sel_trx_ttype;                               -- ����^�C�v
--
/* 2010/03/08 Ver1.27 Add Start   */
  TYPE g_discount_item_ttype   IS TABLE OF VARCHAR2(9) INDEX BY VARCHAR2( 9 );
  gt_discount_item_tbl            g_discount_item_ttype;                               -- �l���i��
/* 2010/03/08 Ver1.27 Add End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�����擾
  gd_process_date                     DATE;                                         -- �Ɩ����t
  gv_company_code                     VARCHAR2(30);                                 -- ��ЃR�[�h
  gv_set_bks_id                       VARCHAR2(30);                                 -- ��v����ID
  gv_org_cd                           VARCHAR2(30);                                 -- �݌ɑg�D�R�[�h
  gv_org_id                           VARCHAR2(30);                                 -- �݌ɑg�DID
  gv_mo_org_id                        VARCHAR2(30);                                 -- �c�ƒP��ID
  gv_var_elec_item_cd                 VARCHAR2(30);                                 -- �ϓ��d�C��(�i�ڃR�[�h)
  gv_busi_dept_cd                     VARCHAR2(30);                                 -- �Ɩ��Ǘ���
  gv_busi_emp_cd                      VARCHAR2(30);                                 -- �Ɩ��Ǘ����S����
  gv_sales_nm                         VARCHAR2(30);                                 -- ������:�̔�����
  gv_tax_msg                          VARCHAR2(20);                                 -- ������:�������œ�
  gv_goods_msg                        VARCHAR2(20);                                 -- ������:���i���㍂
  gv_prod_msg                         VARCHAR2(20);                                 -- ������:���i���㍂
  gv_disc_msg                         VARCHAR2(20);                                 -- ������:����l��
  gv_item_tax                         VARCHAR2(30);                                 -- �i�ږ��דE�v(TAX)
/* 2010/03/08 Ver1.27 Del Start   */
--  gv_dis_item_cd                      VARCHAR2(30);                                 -- ����l���i�ڃR�[�h
/* 2010/03/08 Ver1.27 Del End   */
/* 2009/07/30 Ver1.21 Add Start */
  gv_goods_prod_cls                   VARCHAR2(30);                                 -- ���i���i�敪�J�e�S���Z�b�g��
  gt_category_id                      mtl_categories_b.category_id%TYPE;            -- �J�e�S��ID
  gt_category_set_id                  mtl_category_sets_tl.category_set_id%TYPE;    -- �J�e�S���Z�b�gID
/* 2009/07/30 Ver1.21 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
  gn_ar_bulk_collect_cnt              NUMBER;                                       -- �o���N��������
  gn_if_bulk_collect_cnt              NUMBER;                                       -- �o���N��������(IF)
/* 2009/10/27 Ver1.25 Add Start */
  gt_spot_payment_code                ra_terms_tl.name%TYPE;                        -- �x�����@����
/* 2009/10/27 Ver1.25 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
  gv_dlv_inp_user                     VARCHAR2(30);                                 -- ���ʔ̓X�`�[���͎�
/* 2009/11/05 Ver1.26 Add End   */
--
  gn_fetch_first_flag                 NUMBER(1) DEFAULT 0;                              -- BULK�����̊J�n����p 0:�J�n�A1:2��ڈȍ~
  gn_fetch_end_flag                   NUMBER(1) DEFAULT 0;                              -- BULK�����̏I������p 0:�p���A1:�I��
  --AR����ԍ��ҏW�p
/* 2009/11/05 Ver1.26 Del Start */
--  gt_create_class_brk                 xxcos_sales_exp_headers.create_class%TYPE;        -- �쐬�敪(�u���[�N����p)
/* 2009/11/05 Ver1.26 Del End   */
  gt_invoice_number_brk               xxcos_sales_exp_headers.dlv_invoice_number%TYPE;  -- �[�i�`�[�ԍ�(�u���[�N����p)
  gt_invoice_class_brk                xxcos_sales_exp_headers.dlv_invoice_class%TYPE;   -- �[�i�`�[�敪(����u���[�N����p)
  gt_xchv_cust_id_s_brk               xxcos_cust_hierarchy_v.bill_account_id%TYPE;      -- �o�א�ڋq(����u���[�N����p)
  gt_xchv_cust_id_b_brk               xxcos_cust_hierarchy_v.bill_account_id%TYPE;      -- ������ڋq(���u���[�N����p)
/* 2009/11/05 Ver1.26 Add Start */
  gt_pay_cust_number_brk              xxcos_cust_hierarchy_v.bill_account_number%TYPE;  -- �x���搿���ڋq(���u���[�N����p)
/* 2009/11/05 Ver1.26 Add End   */
  gt_header_id_brk                    xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- �̔����уw�b�_ID(�u���[�N����p)
  gt_cash_sale_cls_brk                xxcos_sales_exp_headers.card_sale_class%TYPE;     -- �J�[�h����敪(�u���[�N����p)
  gt_sales_date_brk                   xxcos_sales_exp_headers.inspect_date%TYPE;        -- ����v���(���u���[�N����p)
  gv_trx_number_brk                   VARCHAR2(20);                                     -- AR����ԍ�(�u���[�N����p)
  gv_trx_number                       VARCHAR2(20);                                     -- AR����ԍ�
  gn_trx_number_id                    NUMBER;                                           -- �������DFF3�p:�����̔Ԕԍ�
  gn_trx_number_tax_id                NUMBER;                                           -- �������DFF3�p�ŋ��p:�����̔Ԕԍ�
  --��������W�񏈗��p
  gv_sum_flag                         VARCHAR2(1);                                      -- �W��t���O Y:�W�� N:�쐬
  gv_trx_number_brk2                  VARCHAR2(20);                                     -- AR����ԍ�(�u���[�N����p)
  gt_header_id_brk2                   xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- �̔����уw�b�_ID(�u���[�N����p)
  gt_prod_cls_brk2                    xxcos_good_prod_class_v.goods_prod_class_code%TYPE;  -- �i�ڋ敪(�u���[�N����p)
  gt_item_code_brk2                   xxcos_sales_exp_lines.item_code%TYPE;             -- �i�ڃR�[�h(�u���[�N����p)
  gn_amount                           NUMBER    DEFAULT 0;                              -- �{�̋��z(�W��)
  gn_tax                              NUMBER    DEFAULT 0;                              -- ����Ŋz(�W��)
  gn_term_amount                      NUMBER    DEFAULT 0;                              -- �{�̋��z(����i�ڋ敪�̍��v�v�Z�p)
  gn_max_amount                       NUMBER    DEFAULT 0;                              -- �{�̋��z(�i�ڋ敪�̋��z���v�ێ��p)
  gt_goods_prod_class                 xxcos_good_prod_class_v.goods_prod_class_code%TYPE;  --�i�ڋ敪
  gt_goods_item_code                  xxcos_sales_exp_lines.item_code%TYPE;                --�i�ڃR�[�h
  --AR��v�z���W�񏈗��p
  gv_sum_flag_ar                      VARCHAR2(1);                                      -- �W��t���O Y:�W�� N:�쐬
  gt_invoice_number_ar_brk            xxcos_sales_exp_headers.dlv_invoice_number%TYPE;  -- �[�i�`�[�ԍ�(�u���[�N�����p)
  gt_item_code_ar_brk                 xxcos_sales_exp_lines.item_code%TYPE;             -- �i�ڃR�[�h(�u���[�N�����p)
  gt_prod_cls_ar_brk                  xxcos_good_prod_class_v.goods_prod_class_code%TYPE;  -- �i�ڋ敪�i���i�E���i�j(�u���[�N�����p)
  gt_gyotai_sho_ar_brk                xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;     -- �Ƒԏ�����(�u���[�N�����p)
  gt_card_sale_class_ar_brk           xxcos_sales_exp_headers.card_sale_class%TYPE;     -- �J�[�h����敪(�u���[�N�����p)
  gt_tax_code_ar_brk                  xxcos_sales_exp_headers.tax_code%TYPE;            -- �ŋ��R�[�h(�u���[�N�����p)
  gt_invoice_class_ar_brk             xxcos_sales_exp_headers.dlv_invoice_class%TYPE;   -- �[�i�`�[�敪(�u���[�N�����p)
  gt_red_black_flag_ar_brk            xxcos_sales_exp_lines.red_black_flag%TYPE;        -- �ԍ��t���O(�u���[�N�����p)
  gt_header_id_ar_brk                 xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- �̔����уw�b�_ID(�u���[�N�����p)
  gv_trx_number_ar_brk                VARCHAR2(20);                                     -- AR����ԍ�(�u���[�N�����p)
  gn_amount_ar                        NUMBER DEFAULT 0;                                 -- �{�̋��z(�W��)
  gn_tax_ar                           NUMBER DEFAULT 0;                                 -- �����Ŋz(�W��)
  --�o�א�ڋq�`�F�b�N�p(���̂�)
  gn_key_trx_number                   ra_interface_lines_all.trx_number%TYPE;                   --AR����ԍ�(���v�s)
  gn_key_dff4                         ra_interface_lines_all.interface_line_attribute4%TYPE;    --���v�s�Ƃ̕R�t��
  gn_key_ship_customer_id             ra_interface_lines_all.orig_system_ship_customer_id%TYPE; --�o�א�ڋq
  gn_ship_flg                         NUMBER(1);                                                --�`�F�b�N�t���O
  --�����擾�p
  gn_work_cnt                         NUMBER DEFAULT 0;                                 -- ���[�N�쐬����
  gn_aroif_cnt_tmp                    NUMBER DEFAULT 0;                                 -- AR�������OIF(BUKL���v���Z�p)
  gn_ardis_cnt_tmp                    NUMBER DEFAULT 0;                                 -- AR��v�z��OIF(BUKL���v���Z�p)
/* 2009/10/02 Ver1.24 Add End   */
--
  gt_cust_cls_cd                      hz_cust_accounts.customer_class_code%TYPE;    -- �ڋq�敪�i��l�j
  gt_cash_sale_cls                    fnd_lookup_values.lookup_code%TYPE;           -- �J�[�h����敪(����:0)
  gt_fvd_xiaoka                       fnd_lookup_values.meaning%TYPE;               -- �Ƒԏ�����-�t��VD�i�����j:'24'
  gt_gyotai_fvd                       fnd_lookup_values.meaning%TYPE;               -- �Ƒԏ�����-�t��VD:'25'
  gt_vd_xiaoka                        fnd_lookup_values.meaning%TYPE;               -- �Ƒԏ�����-����VD:'27'
  gt_no_tax_cls                       fnd_lookup_values.attribute3%TYPE;            -- ����敪-��ې�:4
  gt_in_tax_cls                       fnd_lookup_values.attribute2%TYPE;            -- ����敪-����:2205
  gt_out_tax_cls                      fnd_lookup_values.attribute2%TYPE;            -- ����敪-�O��:2105
  gn_aroif_cnt                        NUMBER;                                       -- ���팏���iAR�������OIF�j
  gn_ardis_cnt                        NUMBER;                                       -- ���팏���iAR��v�z��OIF�j
  gn_warn_flag                        VARCHAR2(1) DEFAULT 'N';                      -- �x���t���O
  gn_skip_cnt                         NUMBER DEFAULT 0;                             -- �X�L�b�v����
  gv_skip_flag                        VARCHAR2(1);                                  -- �X�L�b�v�t���O
  gt_exp_tax_cls                      fnd_lookup_values.meaning%TYPE;               -- ����ŋ敪(�ΏۊO)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
/* 2009/10/02 Ver1.24 Add Start */
--
  --BULK�����J�[�\��(����)
  CURSOR bulk_data_cur
  IS
    SELECT   xseaw.sales_exp_header_id     sales_exp_header_id      --�̔����уw�b�_ID
            ,xseaw.dlv_invoice_number      dlv_invoice_number       --�[�i�`�[�ԍ�
            ,xseaw.dlv_invoice_class       dlv_invoice_class        --�[�i�`�[�敪
            ,xseaw.cust_gyotai_sho         cust_gyotai_sho          --�Ƒԏ�����
            ,xseaw.delivery_date           delivery_date            --�[�i��
            ,xseaw.inspect_date            inspect_date             --������
            ,xseaw.ship_to_customer_code   ship_to_customer_code    --�ڋq�y�[�i��z
            ,xseaw.tax_code                tax_code                 --�ŋ��R�[�h
            ,xseaw.tax_rate                tax_rate                 --����ŗ�
            ,xseaw.consumption_tax_class   consumption_tax_class    --����ŋ敪
            ,xseaw.results_employee_code   results_employee_code    --���ьv��҃R�[�h
            ,xseaw.sales_base_code         sales_base_code          --���㋒�_�R�[�h
            ,xseaw.receiv_base_code        receiv_base_code         --�������_�R�[�h
            ,xseaw.create_class            create_class             --�쐬���敪
            ,xseaw.card_sale_class         card_sale_class          --�J�[�h����敪
            ,xseaw.dlv_inv_line_no         dlv_inv_line_no          --�[�i���הԍ�
            ,xseaw.item_code               item_code                --�i�ڃR�[�h
            ,xseaw.sales_class             sales_class              --����敪
            ,xseaw.red_black_flag          red_black_flag           --�ԍ��t���O
            ,xseaw.goods_prod_cls          goods_prod_cls           --�i�ڋ敪(���i�E���i)
            ,xseaw.pure_amount             pure_amount              --�{�̋��z
            ,xseaw.tax_amount              tax_amount               --����ŋ��z
            ,xseaw.cash_and_card           cash_and_card            --�����E�J�[�h���p�z
            ,xseaw.rcrm_receipt_id         rcrm_receipt_id          --�ڋq�x�����@ID
            ,xseaw.xchv_cust_id_s          xchv_cust_id_s           --�o�א�ڋqID
            ,xseaw.xchv_cust_id_b          xchv_cust_id_b           --������ڋqID
            ,xseaw.xchv_cust_number_b      xchv_cust_number_b       --������ڋq�R�[�h
            ,xseaw.xchv_cust_id_c          xchv_cust_id_c           --������ڋqID
            ,xseaw.hcss_org_sys_id         hcss_org_sys_id          --�ڋq���ݒn�Q��ID(�o�א�)
            ,xseaw.hcsb_org_sys_id         hcsb_org_sys_id          --�ڋq���ݒn�Q��ID(������)
            ,xseaw.hcsc_org_sys_id         hcsc_org_sys_id          --�ڋq���ݒn�Q��ID(������)
            ,xseaw.xchv_bill_pay_id        xchv_bill_pay_id         --�x������ID
            ,xseaw.xchv_bill_pay_id2       xchv_bill_pay_id2        --�x������2
            ,xseaw.xchv_bill_pay_id3       xchv_bill_pay_id3        --�x������3
            ,xseaw.xchv_tax_round          xchv_tax_round           --�ŋ��|�[������
            ,xseaw.xseh_rowid              xseh_rowid               --�̔����уw�b�_ROWID
            ,xseaw.oif_trx_number          oif_trx_number           --AR����ԍ�
            ,xseaw.oif_dff4                oif_dff4                 --DFF4�F�`�[No�{�V�[�P���X
            ,xseaw.oif_tax_dff4            oif_tax_dff4             --DFF4�ŋ��p�F�`�[No�{�V�[�P���X
            ,xseaw.line_id                 line_id                  --�̔����і��הԍ�
            ,xseaw.card_receiv_base        card_receiv_base         --�J�[�hVD�������_�R�[�h
            ,xseaw.pay_cust_number         pay_cust_number          --�x�������p������ڋq�R�[�h
            ,xseaw.request_id              request_id               --�v��ID
    FROM     xxcos_sales_exp_ar_work xseaw
    WHERE    xseaw.request_id = cn_request_id
    ORDER BY
/* 2009/11/05 Ver1.26 Mod Start */
--             xseaw.sales_exp_header_id --�̔����уw�b�_ID
--            ,xseaw.dlv_invoice_number  --�[�i�`�[�ԍ�
--            ,xseaw.dlv_invoice_class   --�[�i�`�[�敪
--            ,xseaw.card_sale_class     --�J�[�h����敪
--            ,xseaw.cust_gyotai_sho     --�Ƒԏ�����
--            ,xseaw.goods_prod_cls      --�i�ڋ敪
--            ,xseaw.item_code           --�i�ڃR�[�h
--            ,xseaw.red_black_flag      --�ԍ��t���O
--            ,xseaw.line_id             --�̔����і��הԍ�
             xseaw.dlv_invoice_number  --�[�i�`�[�ԍ�
            ,xseaw.dlv_invoice_class   --�[�i�`�[�敪
            ,xseaw.xchv_cust_id_s      --�o�א�ڋq
            ,xseaw.cust_gyotai_sho     --�Ƒԏ�����
            ,xseaw.sales_exp_header_id --�̔����уw�b�_ID
            ,xseaw.card_sale_class     --�J�[�h����敪
            ,xseaw.goods_prod_cls      --�i�ڋ敪
/* 2010/03/08 Ver1.27 Add Start   */
            ,xseaw.item_code           --�i�ڃR�[�h
            ,xseaw.red_black_flag      --�ԍ��t���O
/* 2010/03/08 Ver1.27 Add End   */
/* 2009/11/05 Ver1.26 Mod End   */
    ;
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
  --BULK�����J�[�\��(���)
  CURSOR bulk_data_cur2
  IS
    SELECT   xseaw.sales_exp_header_id     sales_exp_header_id      --�̔����уw�b�_ID
            ,xseaw.dlv_invoice_number      dlv_invoice_number       --�[�i�`�[�ԍ�
            ,xseaw.dlv_invoice_class       dlv_invoice_class        --�[�i�`�[�敪
            ,xseaw.cust_gyotai_sho         cust_gyotai_sho          --�Ƒԏ�����
            ,xseaw.delivery_date           delivery_date            --�[�i��
            ,xseaw.inspect_date            inspect_date             --������
            ,xseaw.ship_to_customer_code   ship_to_customer_code    --�ڋq�y�[�i��z
            ,xseaw.tax_code                tax_code                 --�ŋ��R�[�h
            ,xseaw.tax_rate                tax_rate                 --����ŗ�
            ,xseaw.consumption_tax_class   consumption_tax_class    --����ŋ敪
            ,xseaw.results_employee_code   results_employee_code    --���ьv��҃R�[�h
            ,xseaw.sales_base_code         sales_base_code          --���㋒�_�R�[�h
            ,xseaw.receiv_base_code        receiv_base_code         --�������_�R�[�h
            ,xseaw.create_class            create_class             --�쐬���敪
            ,xseaw.card_sale_class         card_sale_class          --�J�[�h����敪
            ,xseaw.dlv_inv_line_no         dlv_inv_line_no          --�[�i���הԍ�
            ,xseaw.item_code               item_code                --�i�ڃR�[�h
            ,xseaw.sales_class             sales_class              --����敪
            ,xseaw.red_black_flag          red_black_flag           --�ԍ��t���O
            ,xseaw.goods_prod_cls          goods_prod_cls           --�i�ڋ敪(���i�E���i)
            ,xseaw.pure_amount             pure_amount              --�{�̋��z
            ,xseaw.tax_amount              tax_amount               --����ŋ��z
            ,xseaw.cash_and_card           cash_and_card            --�����E�J�[�h���p�z
            ,xseaw.rcrm_receipt_id         rcrm_receipt_id          --�ڋq�x�����@ID
            ,xseaw.xchv_cust_id_s          xchv_cust_id_s           --�o�א�ڋqID
            ,xseaw.xchv_cust_id_b          xchv_cust_id_b           --������ڋqID
            ,xseaw.xchv_cust_number_b      xchv_cust_number_b       --������ڋq�R�[�h
            ,xseaw.xchv_cust_id_c          xchv_cust_id_c           --������ڋqID
            ,xseaw.hcss_org_sys_id         hcss_org_sys_id          --�ڋq���ݒn�Q��ID(�o�א�)
            ,xseaw.hcsb_org_sys_id         hcsb_org_sys_id          --�ڋq���ݒn�Q��ID(������)
            ,xseaw.hcsc_org_sys_id         hcsc_org_sys_id          --�ڋq���ݒn�Q��ID(������)
            ,xseaw.xchv_bill_pay_id        xchv_bill_pay_id         --�x������ID
            ,xseaw.xchv_bill_pay_id2       xchv_bill_pay_id2        --�x������2
            ,xseaw.xchv_bill_pay_id3       xchv_bill_pay_id3        --�x������3
            ,xseaw.xchv_tax_round          xchv_tax_round           --�ŋ��|�[������
            ,xseaw.xseh_rowid              xseh_rowid               --�̔����уw�b�_ROWID
            ,xseaw.oif_trx_number          oif_trx_number           --AR����ԍ�
            ,xseaw.oif_dff4                oif_dff4                 --DFF4�F�`�[No�{�V�[�P���X
            ,xseaw.oif_tax_dff4            oif_tax_dff4             --DFF4�ŋ��p�F�`�[No�{�V�[�P���X
            ,xseaw.line_id                 line_id                  --�̔����і��הԍ�
            ,xseaw.card_receiv_base        card_receiv_base         --�J�[�hVD�������_�R�[�h
            ,xseaw.pay_cust_number         pay_cust_number          --�x�������p������ڋq�R�[�h
            ,xseaw.request_id              request_id               --�v��ID
    FROM     xxcos_sales_exp_ar_work xseaw
    WHERE    xseaw.request_id = cn_request_id
    ORDER BY
             xseaw.inspect_date        --������(����v���)
            ,xseaw.dlv_invoice_class   --�[�i�`�[�敪
            ,xseaw.xchv_cust_id_b      --������ڋq
            ,xseaw.pay_cust_number     --�x�������p������ڋq�R�[�h
            ,xseaw.card_sale_class     --�J�[�h����敪
            ,xseaw.sales_exp_header_id --�̔����уw�b�_ID
            ,xseaw.goods_prod_cls      --�i�ڋ敪(���i�E���i)
/* 2010/03/08 Ver1.27 Add Start   */
            ,xseaw.item_code           --�i�ڃR�[�h
            ,xseaw.red_black_flag      --�ԍ��t���O
/* 2010/03/08 Ver1.27 Add End   */
    ;
/* 2009/11/05 Ver1.26 Add End   */
  -- �d��p�^�[���J�[�\��
  CURSOR jour_cls_cur
  IS
    SELECT
           flvl.description           segment3_nm     -- ����Ȗږ���
         , flvl.attribute1            dlv_invoice_cls -- �[�i�`�[�敪
         , flvl.attribute2            item_prod_cls   -- �i�ڃR�[�h OR �i�ڋ敪(���i�E���i)
         , flvl.attribute3            cust_gyotai_sho -- �Ƒԏ�����
         , flvl.attribute4            card_sale_cls   -- �J�[�h����敪
         , flvl.attribute5            red_black_flag  -- �ԍ��t���O
         , flvl.attribute6            acct_type       -- �z���^�C�v(REC�EREV�ETAX)
         , flvl.attribute7            segment2        -- ����R�[�h
         , flvl.attribute8            segment3        -- ����ȖڃR�[�h
         , flvl.attribute9            segment4        -- �⏕����ȖڃR�[�h
         , flvl.attribute10           segment5        -- �ڋq�R�[�h
         , flvl.attribute11           segment6        -- ��ƃR�[�h
         , flvl.attribute12           segment7        -- ���Ƌ敪�R�[�h
         , flvl.attribute13           segment8        -- �\���P
         , flvl.attribute14           amount_sign     -- ���z����
    FROM
            fnd_lookup_values         flvl
    WHERE
            flvl.lookup_type          = cv_qct_jour_cls
      AND   flvl.lookup_code          LIKE cv_qcc_code
      AND   flvl.enabled_flag         = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--      AND   flvl.language             = USERENV( 'LANG' )
      AND   flvl.language             = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
      AND   gd_process_date BETWEEN   NVL( flvl.start_date_active, gd_process_date )
                            AND       NVL( flvl.end_date_active,   gd_process_date );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
/* 2009/10/02 Ver1.24 Mod Start */
--      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
--    , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
--    , ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      iv_target       IN  VARCHAR2    -- �����Ώۋ敪
    , iv_create_class IN  VARCHAR2    -- �쐬���敪
    , ov_errbuf       OUT VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2 )  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
/* 2009/10/02 Ver1.24 Mod End   */
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'init';             -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################  �Œ胍�[�J���ϐ��錾�� END     ########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    ct_pro_bks_id            CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';
                                                               -- ��v����ID
    ct_pro_org_cd            CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
                                                               -- XXCOI:�݌ɑg�D�R�[�h
    ct_pro_mo_org_cd         CONSTANT VARCHAR2(50) := 'ORG_ID';
                                                               -- MO:�c�ƒP��
    ct_pro_company_cd        CONSTANT VARCHAR2(30) := 'XXCOI1_COMPANY_CODE';
                                                               -- XXCOI:��ЃR�[�h
    ct_var_elec_item_cd      CONSTANT VARCHAR2(30) := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';
                                                               -- XXCOS:�ϓ��d�C��(�i�ڃR�[�h)
    ct_busi_dept_cd          CONSTANT VARCHAR2(30) := 'XXCOS1_BIZ_MAN_DEPT_CODE';
                                                               -- XXCOS:�Ɩ��Ǘ���
    ct_busi_emp_cd           CONSTANT VARCHAR2(30) := 'XXCOS1_BIZ_MAN_DEPT_EMP';
                                                               -- XXCOS:�Ɩ��Ǘ����S����
    ct_dis_item_cd           CONSTANT VARCHAR2(30) := 'XXCOS1_DISCOUNT_ITEM_CODE';
                                                               -- XXCOS:����l���i��
/* 2009/07/30 Ver1.21 Add Start */
    ct_goods_prod_cls        CONSTANT VARCHAR2(30) := 'XXCOI1_GOODS_PRODUCT_CLASS';
                                                               -- XXCOI:���i���i�敪�J�e�S���Z�b�g��
/* 2009/07/30 Ver1.21 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
    ct_ar_bulk_collect_cnt   CONSTANT VARCHAR2(30) := 'XXCOS1_AR_BULK_COLLECT_COUNT';
                                                              -- XXCOS:AR���ʃZ�b�g�擾����(�o���N)
    ct_if_bulk_collect_cnt   CONSTANT VARCHAR2(31) := 'XXCOS1_AR_IF_BULK_COLLECT_COUNT';
                                                              -- XXCOS:AR�C���^�[�t�F�[�X�o�b�`�쐬����
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/10/27 Ver1.25 Add Start */
    ct_spot_payment_cd       CONSTANT VARCHAR2(24) := 'XXCOS1_SPOT_PAYMENT_CODE';
                                                              -- XXCOS:�x����������
/* 2009/10/27 Ver1.25 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
    ct_dlv_inp_user          CONSTANT VARCHAR2(30) := 'XXCOS1_AR_MAJOR_DLV_INPUT_USER';
                                                              -- XXCOS:AR���ʔ̓X�`�[���͎�
/* 2009/11/05 Ver1.26 Add End   */
--
    -- *** ���[�J���ϐ� ***
    lv_profile_name          VARCHAR2(50);                     -- �v���t�@�C����
/* 2009/07/30 Ver1.21 Add Start */
    lt_category_set_id       mtl_category_sets_tl.category_set_id%TYPE;  -- �J�e�S���Z�b�gID
/* 2009/07/30 Ver1.21 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
    lv_param_name            VARCHAR2(50);                     -- �p�����[�^��
/* 2009/10/02 Ver1.24 Add End   */
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
/* 2010/03/08 Ver1.27 Add Start   */
  -- �l���i�ڎ擾�J�[�\��
  CURSOR discount_item_cur
  IS
    SELECT  flv.lookup_code     item_code
    FROM    fnd_lookup_values  flv
    WHERE   flv.lookup_type      = ct_dis_item_cd
    AND     flv.language         = ct_lang
    AND     flv.enabled_flag     = cv_enabled_yes
    AND     gd_process_date BETWEEN   NVL( flv.start_date_active, gd_process_date )
                            AND       NVL( flv.end_date_active,   gd_process_date );
  --
  discount_item_rec           discount_item_cur%ROWTYPE;

/* 2010/03/08 Ver1.27 Add End   */
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--##################  �Œ�X�e�[�^�X�������� END     ###################
--
    --===================================================
    -- �R���J�����g���̓p�����[�^�o��
    --===================================================
    gv_out_msg :=  xxccp_common_pkg.get_msg(
/* 2009/10/02 Ver1.24 Mod Start */
--                     iv_application  => cv_xxccp_short_nm
--                    ,iv_name         => cv_no_para_msg
                     iv_application  => cv_xxcos_short_nm
                    ,iv_name         => cv_msg_param
                    ,iv_token_name1  => cv_tkn_param1      --�g�[�N���R�[�h�P
                    ,iv_token_value1 => iv_target          --�����敪
                    ,iv_token_name2  => cv_tkn_param2      --�g�[�N���R�[�h�Q
                    ,iv_token_value2 => iv_create_class    --�쐬���敪
/* 2009/10/02 Ver1.24 Mod End */
                    );
--
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
   );
--
    --===================================================
    -- �R���J�����g���̓p�����[�^���O�o��
    --===================================================
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_blank
    );
--
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_blank
    );
--
/* 2009/10/02 Ver1.24 Add Start */
    --==================================
    --�p�����[�^�`�F�b�N
    --==================================
    IF ( iv_target IS NULL ) THEN
      lv_param_name := xxccp_common_pkg.get_msg(
                          iv_application => cv_xxcos_short_nm    -- �A�v���P�[�V�����Z�k��
                         ,iv_name        => cv_tkn_target_msg    -- �����Ώۋ敪
                       );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_nm
                    , iv_name         => cv_param_err_msg
                    , iv_token_name1  => cv_tkn_in_param
                    , iv_token_value1 => lv_param_name
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF ( iv_create_class IS NULL ) THEN
      lv_param_name := xxccp_common_pkg.get_msg(
                          iv_application => cv_xxcos_short_nm    -- �A�v���P�[�V�����Z�k��
                         ,iv_name        => cv_tkn_create_c_msg  -- �쐬���敪
                       );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_nm
                    , iv_name         => cv_param_err_msg
                    , iv_token_name1  => cv_tkn_in_param
                    , iv_token_value1 => lv_param_name
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
/* 2009/10/02 Ver1.24 Add End   */
    --==================================
    -- �Ɩ����t�擾
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ����t�擾�G���[�̏ꍇ
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_xxcos_short_nm, cv_process_date_msg );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���擾�F��v����ID
    -- ===============================
    gv_set_bks_id := FND_PROFILE.VALUE( ct_pro_bks_id );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gv_set_bks_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_pro_bks_id                               -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���擾�F�݌ɑg�D�R�[�h
    -- ===============================
    gv_org_cd := FND_PROFILE.VALUE( ct_pro_org_cd );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gv_org_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_pro_org_cd                               -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �݌ɑg�DID�擾
    -- ===============================
    gv_org_id := xxcoi_common_pkg.get_organization_id( gv_org_cd );
    -- �݌ɑg�DID�擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_short_nm
                     , iv_name        => cv_org_id_get_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- MO:�c�ƒP�ʎ擾
    --==================================
    gv_mo_org_id := FND_PROFILE.VALUE( ct_pro_mo_org_cd );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gv_mo_org_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_pro_mo_org_cd                            -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOI:��ЃR�[�h
    --==================================
    gv_company_code := FND_PROFILE.VALUE( ct_pro_company_cd );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_company_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_pro_company_cd                           -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:�ϓ��d�C��(�i�ڃR�[�h)�擾
    --==================================
    gv_var_elec_item_cd := FND_PROFILE.VALUE( ct_var_elec_item_cd );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_var_elec_item_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_nm                          -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_var_elec_item_cd                        -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:�Ɩ��Ǘ���
    --==================================
    gv_busi_dept_cd := FND_PROFILE.VALUE( ct_busi_dept_cd );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_busi_dept_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_busi_dept_cd                             -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:�Ɩ��Ǘ����S����
    --==================================
    gv_busi_emp_cd := FND_PROFILE.VALUE( ct_busi_emp_cd );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_busi_emp_cd IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_busi_emp_cd                              -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOS:����l���i��
    --==================================
/* 2010/03/08 Ver1.27 Del Start   */
--    gv_dis_item_cd := FND_PROFILE.VALUE( ct_dis_item_cd );
--
--    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
--    IF ( gv_dis_item_cd IS NULL ) THEN
--      lv_profile_name := xxccp_common_pkg.get_msg(
--         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
--        ,iv_name        => cv_dis_item_cd                              -- ���b�Z�[�WID
--      );
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_xxcos_short_nm
--                     , iv_name         => cv_pro_msg
--                     , iv_token_name1  => cv_tkn_pro
--                     , iv_token_value1 => lv_profile_name
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
/* 2010/03/08 Ver1.27 Del End   */
/* 2009/07/30 Ver1.21 Add Start */
    -- ===============================
    -- XXCOS�F���i���i�敪�J�e�S���Z�b�g��
    -- ===============================
    gv_goods_prod_cls := FND_PROFILE.VALUE( ct_goods_prod_cls );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gv_goods_prod_cls IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_goods_prod_cls                           -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
/* 2009/07/30 Ver1.21 Add End */
/* 2009/10/02 Ver1.24 Add Start */
    -- ===============================
    -- XXCOS:AR���ʃZ�b�g�擾����(�o���N)
    -- ===============================
    gn_ar_bulk_collect_cnt := TO_NUMBER( FND_PROFILE.VALUE( ct_ar_bulk_collect_cnt ) );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gn_ar_bulk_collect_cnt IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_tkn_ar_bukl_msg                          -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- XXCOS:AR�C���^�[�t�F�[�X�o�b�`�쐬����
    -- ===============================
    gn_if_bulk_collect_cnt := TO_NUMBER( FND_PROFILE.VALUE( ct_if_bulk_collect_cnt ) );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gn_if_bulk_collect_cnt IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_tkn_if_bukl_msg                          -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/10/27 Ver1.25 Add Start */
    -- ===============================
    -- XXCOS:�x����������
    -- ===============================
    gt_spot_payment_code := FND_PROFILE.VALUE( ct_spot_payment_cd );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_spot_payment_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_tkn_spot_payment_msg                     -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
/* 2009/10/27 Ver1.25 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
    -- ===============================
    -- XXCOS:AR���ʔ̓X�`�[���͎�
    -- ===============================
    gv_dlv_inp_user := FND_PROFILE.VALUE( ct_dlv_inp_user );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gv_dlv_inp_user IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm                           -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_tkn_dlv_inp_user_msg                     -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
/* 2009/11/05 Ver1.26 Add End   */
--
    --==================================
    -- 5.�N�C�b�N�R�[�h�擾
    --==================================
    -- �J�[�h����敪=����:0
    BEGIN
      SELECT flvl.lookup_code
      INTO   gt_cash_sale_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qct_card_cls
        AND  flvl.attribute3             = cv_attribute_y
        AND  flvl.enabled_flag           = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_card_sale_cls_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_card_cls
                      , iv_token_name2   => cv_tkn_lookup_dff3
                      , iv_token_value2  => cv_attribute_y
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- ����ŋ敪=��ې�:4
    BEGIN
      SELECT flvl.attribute3
      INTO   gt_no_tax_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qcv_tax_cls
        AND  flvl.attribute4             = cv_attribute_y
        AND  flvl.enabled_flag           = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_tax_cls_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qcv_tax_cls
                      , iv_token_name2   => cv_tkn_lookup_dff4
                      , iv_token_value2  => cv_attribute_y
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- ����ŋ敪=����'2205'
    BEGIN
      SELECT flvl.attribute2
      INTO   gt_in_tax_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qcv_tax_cls
        AND  flvl.attribute3             = cv_attribute_2
        AND  flvl.enabled_flag           = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_tax_in_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qcv_tax_cls
                      , iv_token_name2   => cv_tkn_lookup_dff3
                      , iv_token_value2  => cv_attribute_2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- ����ŋ敪=�O��'2105'
    BEGIN
      SELECT flvl.attribute2
      INTO   gt_out_tax_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qcv_tax_cls
        AND  flvl.attribute3             = cv_attribute_1
        AND  flvl.enabled_flag           = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_short_nm
                        , iv_name          => cv_tax_out_msg
                        , iv_token_name1   => cv_tkn_lookup_type
                        , iv_token_value1  => cv_qcv_tax_cls
                        , iv_token_name2   => cv_tkn_lookup_dff3
                        , iv_token_value2  => cv_attribute_1
                      );
          lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- ����ŋ敪(�ΏۊO)
    BEGIN
      SELECT flvl.meaning
      INTO   gt_exp_tax_cls
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_out_tax_cls
        AND  flvl.enabled_flag           = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_short_nm
                        , iv_name          => cv_tax_no_msg
                        , iv_token_name1   => cv_tkn_lookup_type
                        , iv_token_value1  => cv_out_tax_cls
                      );
          lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- �ڋq�敪=��l:12
    BEGIN
      SELECT flvl.meaning
      INTO   gt_cust_cls_cd
      FROM   fnd_lookup_values           flvl
      WHERE  flvl.lookup_type            = cv_qct_cust_cls
        AND  flvl.lookup_code            LIKE cv_qcc_code
        AND  flvl.enabled_flag           = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language               = USERENV( 'LANG' )
        AND  flvl.language               = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
        AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                             AND         NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_cust_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_cust_cls
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- �Ƒԏ����ށ��t���T�[�r�X�i�����jVD :24
    BEGIN
      SELECT flvl.meaning                   meaning
      INTO   gt_fvd_xiaoka
      FROM   fnd_lookup_values              flvl
      WHERE  flvl.lookup_type               = cv_qct_gyotai_sho
        AND  flvl.lookup_code               LIKE cv_qcc_code
        AND  flvl.attribute2                = cv_attribute_a
        AND  flvl.enabled_flag              = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language                  = USERENV( 'LANG' )
        AND  flvl.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
        AND  gd_process_date BETWEEN        NVL( flvl.start_date_active, gd_process_date )
                             AND            NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_gyotai_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_gyotai_sho
                      , iv_token_name2   => cv_tkn_lookup_dff2
                      , iv_token_value2  => cv_attribute_a
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- �Ƒԏ����ށ��t���T�[�r�XVD :25
    BEGIN
      SELECT flvl.meaning                   meaning
      INTO   gt_gyotai_fvd
      FROM   fnd_lookup_values              flvl
      WHERE  flvl.lookup_type               = cv_qct_gyotai_sho
        AND  flvl.lookup_code               LIKE cv_qcc_code
        AND  flvl.attribute2                = cv_attribute_b
        AND  flvl.enabled_flag              = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language                  = USERENV( 'LANG' )
        AND  flvl.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
        AND  gd_process_date BETWEEN        NVL( flvl.start_date_active, gd_process_date )
                             AND            NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_gyotai_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_gyotai_sho
                      , iv_token_name2   => cv_tkn_lookup_dff2
                      , iv_token_value2  => cv_attribute_b
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
--
    -- �Ƒԏ����ށ�����VD :27
    BEGIN
      SELECT flvl.meaning                   meaning
      INTO   gt_vd_xiaoka
      FROM   fnd_lookup_values              flvl
      WHERE  flvl.lookup_type               = cv_qct_gyotai_sho
        AND  flvl.lookup_code               LIKE cv_qcc_code
        AND  flvl.attribute2                = cv_attribute_n
        AND  flvl.enabled_flag              = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvl.language                  = USERENV( 'LANG' )
        AND  flvl.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
        AND  gd_process_date BETWEEN        NVL( flvl.start_date_active, gd_process_date )
                             AND            NVL( flvl.end_date_active,   gd_process_date );
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_gyotai_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_gyotai_sho
                      , iv_token_name2   => cv_tkn_lookup_dff2
                      , iv_token_value2  => cv_attribute_n
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_no_lookup_expt;
    END;
/* 2009/07/30 Ver1.21 Add Start */
--
    -- �J�e�S���Z�b�gID���擾
    BEGIN
      SELECT mcst.category_set_id  -- �J�e�S���Z�b�gID
      INTO   gt_category_set_id
      FROM   mtl_category_sets_tl mcst
/* 2009/07/27 Ver1.21 Mod Start */
--      WHERE  mcst.language          = USERENV( 'LANG' )
      WHERE  mcst.language          = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
      AND    mcst.category_set_name = gv_goods_prod_cls
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �J�e�S���Z�b�gID�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_no_cate_set_id_msg
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --�J�e�S��ID���擾
    BEGIN
      SELECT mcb.category_id       -- �J�e�S��ID
      INTO   gt_category_id
      FROM   mtl_category_sets_b mcsb
            ,mtl_categories_b    mcb
      WHERE  mcsb.category_set_id = gt_category_set_id
      AND    mcsb.structure_id    = mcb.structure_id
      AND    mcb.segment1         = cv_goods_prod_syo
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �J�e�S��ID�擾�o���Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_no_cate_id_msg
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
/* 2009/07/30 Ver1.21 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
    --=====================================
    -- AR��v�z���d��p�^�[���̎擾
    --=====================================
--
    BEGIN
      -- �J�[�\���I�[�v��
      OPEN  jour_cls_cur;
      FETCH jour_cls_cur BULK COLLECT INTO gt_jour_cls_tbl;
      -- �J�[�\���N���[�Y
      CLOSE jour_cls_cur;
    EXCEPTION
    -- �d��p�^�[���擾���s�����ꍇ
      WHEN OTHERS THEN
        IF ( jour_cls_cur%ISOPEN ) THEN
          CLOSE jour_cls_cur;
        END IF;
        lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_jour_nodata_msg
                         , iv_token_name1  => cv_tkn_lookup_type
                         , iv_token_value1 => cv_qct_jour_cls
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- �d��p�^�[����1�������݂��Ȃ��ꍇ
    IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_jour_nodata_msg
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => cv_qct_jour_cls
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
/* 2009/10/02 Ver1.24 Add End   */
--
/* 2010/03/08 Ver1.27 Add Start   */
    --=====================================
    -- �l���i�ڂ̎擾
    --=====================================
    BEGIN
      OPEN  discount_item_cur;
      --
      <<discount_item_loop>>
      LOOP
        FETCH discount_item_cur INTO discount_item_rec;
        EXIT WHEN discount_item_cur%NOTFOUND;
        --
        gt_discount_item_tbl(discount_item_rec.item_code) := discount_item_rec.item_code;
        --
      END LOOP discount_item_loop;
      --
      CLOSE discount_item_cur;
    EXCEPTION
      WHEN OTHERS THEN
        IF ( discount_item_cur%ISOPEN ) THEN
          CLOSE discount_item_cur;
        END IF;
        --
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_dis_item_cd
                         , iv_token_name1  => cv_tkn_lookup_type
                         , iv_token_value1 => ct_dis_item_cd
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
/* 2010/03/08 Ver1.27 Add End   */
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- �N�C�b�N�R�[�h�擾�G���[
    WHEN global_no_lookup_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   #######################################
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
--##################################  �Œ��O������  END ####################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : �f�[�^�擾(A-2-1)
   ***********************************************************************************/
  PROCEDURE get_data(
/* 2009/10/02 Ver1.24 Mod Start */
--      ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
--    , ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
--    , ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      iv_target        IN  VARCHAR2         -- �����Ώۋ敪
    , iv_create_class  IN  VARCHAR2         -- �쐬���敪
    , ov_errbuf        OUT VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode       OUT VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg        OUT VARCHAR2 )       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
/* 2009/10/02 Ver1.24 Mod End   */
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'get_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_table_name   VARCHAR2(255);                                     -- �e�[�u����
/* 2009/10/02 Ver1.24 Del Start */
--    ln_bulk_idx     NUMBER DEFAULT 0;                                  -- ����ʔ̓X�C���f�b�N�X
--    ln_norm_idx     NUMBER DEFAULT 0;                                  -- ���ʔ̓X�C���f�b�N�X
--    ln_start_idx    NUMBER DEFAULT 1;                                  -- �J�n�ʒu
--    ln_end_idx      NUMBER DEFAULT 1;                                  -- �I���ʒu
--    ln_key_bef      NUMBER DEFAULT 1;                                  -- ��r�L�[
/* 2009/10/02 Ver1.24 Del End   */
    ln_pure_amount  NUMBER DEFAULT 0;                                  -- �J�[�h���R�[�h�̖{�̋��z
    ln_tax_amount   NUMBER DEFAULT 0;                                  -- �J�[�h���R�[�h�̏���ŋ��z
    lv_card_company VARCHAR2(9);                                       -- �ڋq�ǉ����J�[�h���
    ln_sale_idx     NUMBER DEFAULT 0;                                  -- �̔����уC���f�b�N�X
    ln_skip_idx     NUMBER DEFAULT 0;                                  -- �X�L�b�v�C���f�b�N�X
    lv_sale_flag    VARCHAR2(1);                                       -- �t���O
/* 2009/10/02 Ver1.24 Del Start */
--    lv_skip_flag    VARCHAR2(1);                                       -- �t���O
/* 2009/10/02 Ver1.24 Del End   */
    lt_xchv_cust_id              xxcos_cust_hierarchy_v.bill_account_id%TYPE;         -- ������ڋqID
    lt_receiv_base_code          xxcos_sales_exp_headers.receiv_base_code%TYPE ;      -- �������_�R�[�h
    lt_hcsc_org_sys_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE;       -- �ڋq���ݒn�Q��ID(������)
    lt_skip_header_id            xxcos_sales_exp_headers.sales_exp_header_id%TYPE;    --  �̔����уw�b�_ID
    lt_receipt_id                ra_cust_receipt_methods.receipt_method_id%TYPE;      -- �ڋq�x�����@ID
    lt_bill_pay_id               xxcos_cust_hierarchy_v.bill_payment_term_id%TYPE;    -- �x������ID
    lt_bill_pay_id2              xxcos_cust_hierarchy_v.bill_payment_term2%TYPE;      -- �x������2
    lt_bill_pay_id3              xxcos_cust_hierarchy_v.bill_payment_term3%TYPE;      -- �x������3
    lv_heiyou_card_flag          VARCHAR2(1);                                         -- �t���O
    lv_heiyou_cash_flag          VARCHAR2(1);                                         -- �t���O
/* 2009/08/20 Ver1.22 Add Start */
    lt_break_header_id           xxcos_sales_exp_headers.sales_exp_header_id%TYPE;    -- �w�b�_�u���[�N�p
    lv_break_flag                VARCHAR2(1);                                         -- �w�b�_�u���[�N�t���O(�x������)
/* 2009/08/20 Ver1.22 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
    lv_break_flag2              VARCHAR2(1);                                          -- �w�b�_�u���[�N�t���O(�J�[�h���)
/* 2009/11/05 Ver1.26 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
    lv_receipt_id_flag           VARCHAR2(1);                                         -- �x�����@�G���[�t���O
    ln_sale_idx_bk               NUMBER DEFAULT 0;                                    -- �z��̓Y���p
/* 2009/10/02 Ver1.24 Add End   */
--
    -- *** ���[�J���E�J�[�\�� (�̔����уf�[�^���o)***
    CURSOR sales_data_cur
    IS
      SELECT
/* 2009/10/02 Ver1.24 Start */
              /*+
                  USE_NL(xsehv)
              */
/* 2009/10/02 Ver1.24 End   */
/* 2009/07/27 Ver1.21 Mod Start */
--             xseh.sales_exp_header_id          sales_exp_header_id     -- �̔����уw�b�_ID
--           , xseh.dlv_invoice_number           dlv_invoice_number      -- �[�i�`�[�ԍ�
--           , xseh.dlv_invoice_class            dlv_invoice_class       -- �[�i�`�[�敪
--           , xseh.cust_gyotai_sho              cust_gyotai_sho         -- �Ƒԏ�����
--           , xseh.delivery_date                delivery_date           -- �[�i��
--           , xseh.inspect_date                 inspect_date            -- ������
--           , xseh.ship_to_customer_code        ship_to_customer_code   -- �ڋq�y�[�i��z
--           , xseh.tax_code                     tax_code                -- �ŋ��R�[�h
--           , xseh.tax_rate                     tax_rate                -- ����ŗ�
--           , xseh.consumption_tax_class        consumption_tax_class   -- ����ŋ敪
--           , xseh.results_employee_code        results_employee_code   -- ���ьv��҃R�[�h
--           , xseh.sales_base_code              sales_base_code         -- ���㋒�_�R�[�h
--           , xseh.receiv_base_code             receiv_base_code        -- �������_�R�[�h
--           , xseh.create_class                 create_class            -- �쐬���敪
--           , NVL( xseh.card_sale_class, cv_cash_class )
--                                               card_sale_class         -- �J�[�h����敪
             xsehv.sales_exp_header_id          sales_exp_header_id    -- �̔����уw�b�_ID
           , xsehv.dlv_invoice_number           dlv_invoice_number     -- �[�i�`�[�ԍ�
           , xsehv.dlv_invoice_class            dlv_invoice_class      -- �[�i�`�[�敪
           , xsehv.cust_gyotai_sho              cust_gyotai_sho        -- �Ƒԏ�����
           , xsehv.delivery_date                delivery_date          -- �[�i��
           , xsehv.inspect_date                 inspect_date           -- ������
           , xsehv.ship_to_customer_code        ship_to_customer_code  -- �ڋq�y�[�i��z
           , xsehv.tax_code                     tax_code               -- �ŋ��R�[�h
           , xsehv.tax_rate                     tax_rate               -- ����ŗ�
           , xsehv.consumption_tax_class        consumption_tax_class  -- ����ŋ敪
           , xsehv.results_employee_code        results_employee_code  -- ���ьv��҃R�[�h
           , xsehv.sales_base_code              sales_base_code        -- ���㋒�_�R�[�h
           , xsehv.receiv_base_code             receiv_base_code       -- �������_�R�[�h
           , xsehv.create_class                 create_class           -- �쐬���敪
           , NVL( xsehv.card_sale_class, cv_cash_class )
                                               card_sale_class         -- �J�[�h����敪
/* 2009/07/27 Ver1.21 Mod End   */
           , xsel.dlv_invoice_line_number      dlv_inv_line_no         -- �[�i���הԍ�
           , xsel.item_code                    item_code               -- �i�ڃR�[�h
           , xsel.sales_class                  sales_class             -- ����敪
           , xsel.red_black_flag               red_black_flag          -- �ԍ��t���O
/* 2009/07/27 Ver1.21 Mod Start */
--           , CASE 
--               WHEN mcavd.subinventory_code IS NULL THEN cv_goods_prod_sei
--               ELSE                            xgpc.goods_prod_class_code
--             END AS                            goods_prod_cls          -- �i�ڋ敪�i���i�E���i�j
           , ( CASE
/* 2009/07/30 Ver1.21 Mod Start */
--                 WHEN (
--                        SELECT COUNT(1)
--                        FROM   mtl_category_accounts_v  mcav
--                        WHERE  mcav.subinventory_code = xsel.ship_from_subinventory_code
--                        AND    ROWNUM                 = 1
--                      ) = 0
                 WHEN NOT EXISTS (
                        SELECT 1
                        FROM   mtl_category_accounts  mca
                        WHERE  mca.category_id        = gt_category_id
                        AND    mca.organization_id    = gv_org_id
                        AND    mca.subinventory_code  = xsel.ship_from_subinventory_code
                        )
/* 2009/07/30 Ver1.21 Mod End   */
                 THEN
                   cv_goods_prod_sei
                 ELSE
                   (
                     SELECT  mcb.segment1           goods_prod_class_code
                     FROM    mtl_system_items_b     msib  --�i�ڃ}�X�^
                            ,mtl_item_categories    mic   --�i�ڃJ�e�S���}�X�^
                            ,mtl_categories_b       mcb   --�J�e�S���}�X�^
                     WHERE   msib.organization_id   = gv_org_id
                     AND     msib.segment1          = xsel.item_code
                     AND     msib.enabled_flag      = cv_y_flag
                     AND     cd_sysdate             BETWEEN NVL( msib.start_date_active, cd_sysdate )
                                                    AND     NVL( msib.end_date_active, cd_sysdate)
                     AND     msib.organization_id   = mic.organization_id
                     AND     msib.inventory_item_id = mic.inventory_item_id
                     AND     mic.category_set_id    = gt_category_set_id
                     AND     mic.category_id        = mcb.category_id
                     AND     (
                               mcb.disable_date IS NULL
                               OR
                               mcb.disable_date > cd_sysdate
                             )
                     AND     mcb.enabled_flag       = cv_y_flag
                     AND     cd_sysdate             BETWEEN NVL( mcb.start_date_active, cd_sysdate ) 
                                                    AND     NVL( mcb.end_date_active, cd_sysdate )
                   )
               END
             )                                 goods_prod_cls          -- �i�ڋ敪�i���i�E���i�j
/* 2009/07/27 Ver1.21 Mod End   */
           , xsel.pure_amount                  pure_amount             -- �{�̋��z
           , xsel.tax_amount                   tax_amount              -- ����Ŋz
           , NVL( xsel.cash_and_card, 0 )      cash_and_card           -- �����E�J�[�h���p�z
/* 2009/07/27 Ver1.21 Mod Start */
--           , rcrmv.receipt_method_id           rcrm_receipt_id         -- �ڋq�x�����@ID
--           , xchv.ship_account_id              xchv_cust_id_s          -- �o�א�ڋqID
--           , xchv.bill_account_id              xchv_cust_id_b          -- ������ڋqID
--           , xchv.bill_account_number          xchv_cust_number_b      -- ������ڋq�R�[�h
--           , xchv.cash_account_id              xchv_cust_id_c          -- ������ڋqID
           , (
               SELECT rcrm.receipt_method_id
               FROM   ra_cust_receipt_methods  rcrm
                     ,hz_cust_site_uses_all    scsua
               WHERE  rcrm.customer_id        = xsehv.bill_account_id
               AND    rcrm.primary_flag       = cv_y_flag
/* 2010/03/08 Ver1.27 Add Start   */
               AND    scsua.status            = cv_status_enable         --�ڋq�g�p�ړI.�X�e�[�^�X = 'A'(�L��)
               AND    scsua.primary_flag      = cv_y_flag                --�ڋq�g�p�ړI.��t���O   = 'Y'(�I��)
/* 2010/03/08 Ver1.27 Add Start   */
               AND    rcrm.site_use_id        = scsua.site_use_id
               AND    gd_process_date         BETWEEN NVL( rcrm.start_date, gd_process_date )
                                                  AND NVL( rcrm.end_date, gd_process_date )
               AND    scsua.cust_acct_site_id = hcsb.cust_acct_site_id
               AND    scsua.site_use_code     = cv_site_code
               AND    ROWNUM                  = 1
             )                                 rcrm_receipt_id         -- �ڋq�x�����@ID
           , xsehv.ship_account_id             xchv_cust_id_s          -- �o�א�ڋqID
           , xsehv.bill_account_id             xchv_cust_id_b          -- ������ڋqID
           , xsehv.bill_account_number         xchv_cust_number_b      -- ������ڋq�R�[�h
           , xsehv.cash_account_id             xchv_cust_id_c          -- ������ڋqID
/* 2009/07/27 Ver1.21 Mod End   */
           , hcss.cust_acct_site_id            hcss_org_sys_id         -- �ڋq���ݒn�Q��ID�i�o�א�j
           , hcsb.cust_acct_site_id            hcsb_org_sys_id         -- �ڋq���ݒn�Q��ID�i������j
           , hcsc.cust_acct_site_id            hcsc_org_sys_id         -- �ڋq���ݒn�Q��ID�i������j
/* 2009/07/27 Ver1.21 Mod Start */
--           , xchv.bill_payment_term_id         xchv_bill_pay_id        -- �x������ID
--           , xchv.bill_payment_term2           xchv_bill_pay_id2       -- �x������2
--           , xchv.bill_payment_term3           xchv_bill_pay_id3       -- �x������3
--           , xchv.bill_tax_round_rule          xchv_tax_round          -- �ŋ��|�[������
--           , xseh.rowid                        xseh_rowid              -- ROWID
           , hcub.payment_term_id               xchv_bill_pay_id       -- �x������ID
           , hcub.attribute2                    xchv_bill_pay_id2      -- �x������2
           , hcub.attribute3                    xchv_bill_pay_id3      -- �x������3
           , hcub.tax_rounding_rule             xchv_tax_round         -- �ŋ��|�[������
           , xsehv.xseh_rowid                  xseh_rowid              -- ROWID
/* 2009/07/27 Ver1.21 Mod End   */
           , NULL                              oif_trx_number          -- AR����ԍ�
           , NULL                              oif_dff4                -- DFF4�F�`�[No�{�V�[�P���X
           , NULL                              oif_tax_dff4            -- DFF4�ŋ��p�F�`�[No�{�V�[�P���X
           , xsel.sales_exp_line_id            line_id                 -- �̔����і��הԍ�
/* 2009/07/27 Ver1.21 Mod Start */
--           , xseh.receiv_base_code             card_receiv_base        -- �J�[�h�������_�R�[�h
--           , xchv.bill_account_number          pay_cust_number         -- �x�������p������ڋq�R�[�h
           , xsehv.receiv_base_code            card_receiv_base        -- �J�[�h�������_�R�[�h
           , xsehv.bill_account_number         pay_cust_number         -- �x�������p������ڋq�R�[�h
/* 2009/07/27 Ver1.21 Mod End   */
/* 2009/10/02 Ver1.24 Add Start */
           , cn_request_id                     request_id              -- �v��ID
/* 2009/10/02 Ver1.24 Add End   */
      FROM
             xxcos_sales_exp_headers           xseh                    -- �̔����уw�b�_�e�[�u��(���b�N�p)
/* 2009/07/27 Ver1.21 Add Start */
           , (
               -- �@������ڋq��������ڋq�|�o�א�ڋq
/* 2009/10/02 Ver1.24 Mod Start */
--               SELECT /*+
--                          LEADING (xseh) 
--                          INDEX   (xseh xxcos_sales_exp_headers_n02) 
--                          USE_NL  (hcas)
--                      */
/* 2009/11/05 Ver1.26 Mod Start */
--               SELECT /*+
--                          LEADING(xseh) 
--                          INDEX(xseh xxcos_sales_exp_headers_n02)
--                          USE_NL(xseh hcas hcar_sb hcab hcac)
--                      */
               SELECT /*+
                          LEADING(xseh)
                          INDEX(xseh xxcos_sales_exp_headers_n02)
                          USE_NL(xseh flvl hcas hcar_sb hcab hcac)
                      */
/* 2009/11/05 Ver1.26 Mod Start */
/* 2009/10/02 Ver1.24 Mod End   */
                      xseh.sales_exp_header_id      sales_exp_header_id
                     ,xseh.dlv_invoice_number       dlv_invoice_number
                     ,xseh.dlv_invoice_class        dlv_invoice_class
                     ,xseh.cust_gyotai_sho          cust_gyotai_sho
                     ,xseh.delivery_date            delivery_date
                     ,xseh.inspect_date             inspect_date
                     ,xseh.ship_to_customer_code    ship_to_customer_code
                     ,xseh.tax_code                 tax_code
                     ,xseh.tax_rate                 tax_rate
                     ,xseh.consumption_tax_class    consumption_tax_class
                     ,xseh.results_employee_code    results_employee_code
                     ,xseh.sales_base_code          sales_base_code
                     ,xseh.receiv_base_code         receiv_base_code
                     ,xseh.create_class             create_class
                     ,xseh.card_sale_class          card_sale_class
                     ,xseh.rowid                    xseh_rowid
                     ,hcas.account_number           ship_account_number
                     ,hcas.cust_account_id          ship_account_id
                     ,hcas.customer_class_code      customer_class_code
                     ,hcab.account_number           bill_account_number
                     ,hcab.cust_account_id          bill_account_id
                     ,hcac.account_number           cash_account_number
                     ,hcac.cust_account_id          cash_account_id
               FROM   xxcos_sales_exp_headers  xseh
                     ,hz_cust_accounts         hcas     -- �o�א�ڋq
                     ,hz_cust_acct_relate      hcar_sb  -- �ڋq�֘A(����)
                     ,hz_cust_accounts         hcab     -- ������ڋq
                     ,hz_cust_accounts         hcac     -- ������ڋq
/* 2009/11/05 Ver1.26 Add Start */
                     ,fnd_lookup_values        flvl     -- �N�C�b�N�R�[�h
/* 2009/11/05 Ver1.26 Add End   */
/* 2009/10/02 Ver1.24 Mod Start */
--               WHERE  xseh.ar_interface_flag            = cv_n_flag                   -- AR�C���^�t�F�[�X�σt���O:N(�����M)
               WHERE  xseh.ar_interface_flag           IN ( cv_n_flag, cv_w_flag )    -- AR�C���^�t�F�[�X�σt���O:N(�����M) W(�x��)
/* 2009/10/02 Ver1.24 Mod End   */
               AND    xseh.delivery_date               <= gd_process_date             -- �[�i�� <= �Ɩ����t
/* 2009/10/02 Ver1.24 Add Start */
/* 2009/11/05 Ver1.26 Del Start */
--               AND    xseh.create_class                 = iv_create_class             -- �p�����[�^.�쐬���敪
/* 2009/11/05 Ver1.26 Del End   */
               AND    (
                        ( iv_target = cv_major AND xseh.receiv_base_code = gv_busi_dept_cd )
                        OR
                        (
                          ( iv_target = cv_not_major )
                          AND
                          ( 
                            ( xseh.receiv_base_code <> gv_busi_dept_cd )
                            OR
                            ( xseh.receiv_base_code IS NULL )
                          )
                        )
                      )                                                               -- �p�����[�^.�����Ώۋ敪 1:��� 2:����
/* 2009/10/02 Ver1.24 Add End   */
               AND    hcas.account_number               = xseh.ship_to_customer_code
               AND    hcar_sb.related_cust_account_id   = hcas.cust_account_id
               AND    hcar_sb.status                    = cv_cust_relate_status       -- �ڋq�֘A�X�e�[�^�X:A(�L��)
               AND    hcar_sb.attribute1                = cv_cust_bill                -- �֘A����:1(����)
               AND    hcab.cust_account_id              = hcar_sb.cust_account_id
               AND    hcab.customer_class_code          = cv_cust_class_uri           -- �ڋq�敪(����):14(���|���Ǘ���ڋq)
               AND    hcac.cust_account_id              = hcab.cust_account_id
/* 2009/11/05 Ver1.26 Add Start */
               AND    flvl.lookup_type                  = cv_qct_mkorg_cls
               AND    flvl.lookup_code                  LIKE cv_qcc_code
               AND    flvl.attribute2                   IS NULL
               AND    flvl.attribute3                   = iv_create_class             -- �p�����[�^.�쐬���敪
               AND    flvl.enabled_flag                 = cv_enabled_yes
               AND    flvl.language                     = ct_lang
               AND    gd_process_date BETWEEN NVL( flvl.start_date_active, gd_process_date )
                                      AND     NVL( flvl.end_date_active,   gd_process_date )
               AND    flvl.meaning                      = xseh.create_class
/* 2009/11/05 Ver1.26 Add End   */
               AND    EXISTS (
                        SELECT /*+ USE_NL(ship_hasa_1 ship_hsua_1 ship_hzad_1 bill_hasa_1 bill_hsua_1 bill_hzad_1) */
                               'X'
                        FROM   hz_cust_acct_sites     ship_hasa_1
                              ,hz_cust_site_uses      ship_hsua_1
                              ,xxcmm_cust_accounts    ship_hzad_1
                              ,hz_cust_acct_sites     bill_hasa_1
                              ,hz_cust_site_uses      bill_hsua_1
                              ,xxcmm_cust_accounts    bill_hzad_1
                        WHERE  ship_hasa_1.cust_account_id     = hcas.cust_account_id
                        AND    ship_hsua_1.cust_acct_site_id   = ship_hasa_1.cust_acct_site_id
                        AND    ship_hzad_1.customer_id         = hcas.cust_account_id
                        AND    bill_hasa_1.cust_account_id     = hcab.cust_account_id
                        AND    bill_hsua_1.cust_acct_site_id   = bill_hasa_1.cust_acct_site_id
                        AND    bill_hsua_1.site_use_code       = cv_site_code                   -- �T�C�g�R�[�h:BILL_TO
                        AND    bill_hzad_1.customer_id         = hcab.cust_account_id
                        AND    ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    ship_hsua_1.status              = cv_status_enable         --�ڋq�g�p�ړI.�X�e�[�^�X = 'A'(�L��)
                        AND    bill_hsua_1.status              = cv_status_enable         --�ڋq�g�p�ړI.�X�e�[�^�X = 'A'(�L��)
                        AND    ship_hasa_1.status              = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
                        AND    bill_hasa_1.status              = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
                        AND    bill_hsua_1.primary_flag        = cv_y_flag                --�ڋq�g�p�ړI.��t���O   = 'Y'(�I��)
                        AND    ship_hsua_1.primary_flag        = cv_y_flag                --�ڋq�g�p�ړI.��t���O   = 'Y'(�I��)
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    NOT EXISTS (
                                 SELECT /*+ USE_NL(cash_hcar_1) */
                                       'X'
                                FROM   hz_cust_acct_relate  cash_hcar_1
                                WHERE  cash_hcar_1.status                  = cv_cust_relate_status  -- �ڋq�֘A�X�e�[�^�X:A(�L��)
                                AND    cash_hcar_1.attribute1              = cv_cust_cash           -- �֘A����:2(����)
                                AND    cash_hcar_1.related_cust_account_id = hcab.cust_account_id
                                AND    ROWNUM                              = 1
                               )
                        AND    ROWNUM                          = 1
                      )
               UNION ALL
               --�A������ڋq�|������ڋq�|�o�א�ڋq
/* 2009/10/02 Ver1.24 Mod Start */
--               SELECT /*+
--                          LEADING (xseh)
--                          INDEX   (xseh xxcos_sales_exp_headers_n02)
--                          USE_NL  (hcas)
--                      */
/* 2009/11/05 Ver1.26 Mod Start */
--               SELECT /*+
--                          LEADING(xseh)
--                          INDEX(xseh xxcos_sales_exp_headers_n02)
--                          USE_NL(xseh hcas hcar_sb hcab hcar_sc hcac)
--                      */
               SELECT /*+
                          LEADING(xseh)
                          INDEX(xseh xxcos_sales_exp_headers_n02)
                          USE_NL(xseh flvl hcas hcar_sb hcab hcac)
                      */
/* 2009/11/05 Ver1.26 Mod End   */
/* 2009/10/02 Ver1.24 Mod End   */
                      xseh.sales_exp_header_id      sales_exp_header_id
                     ,xseh.dlv_invoice_number       dlv_invoice_number
                     ,xseh.dlv_invoice_class        dlv_invoice_class
                     ,xseh.cust_gyotai_sho          cust_gyotai_sho
                     ,xseh.delivery_date            delivery_date
                     ,xseh.inspect_date             inspect_date
                     ,xseh.ship_to_customer_code    ship_to_customer_code
                     ,xseh.tax_code                 tax_code
                     ,xseh.tax_rate                 tax_rate
                     ,xseh.consumption_tax_class    consumption_tax_class
                     ,xseh.results_employee_code    results_employee_code
                     ,xseh.sales_base_code          sales_base_code
                     ,xseh.receiv_base_code         receiv_base_code
                     ,xseh.create_class             create_class
                     ,xseh.card_sale_class          card_sale_class
                     ,xseh.rowid                    xseh_rowid
                     ,hcas.account_number           ship_account_number
                     ,hcas.cust_account_id          ship_account_id
                     ,hcas.customer_class_code      customer_class_code
                     ,hcab.account_number           bill_account_number
                     ,hcab.cust_account_id          bill_account_id
                     ,hcac.account_number           cash_account_number
                     ,hcac.cust_account_id          cash_account_id
               FROM   xxcos_sales_exp_headers  xseh
                     ,hz_cust_accounts         hcas    -- �o�א�ڋq
                     ,hz_cust_acct_relate      hcar_sb -- �ڋq�֘A(����)
                     ,hz_cust_accounts         hcab    -- ������ڋq
                     ,hz_cust_acct_relate      hcar_sc -- �ڋq�֘A(����)
                     ,hz_cust_accounts         hcac    -- ������ڋq
/* 2009/11/05 Ver1.26 Add Start */
                     ,fnd_lookup_values        flvl    -- �N�C�b�N�R�[�h
/* 2009/11/05 Ver1.26 Add End   */
/* 2009/10/02 Ver1.24 Mod Start */
--               WHERE  xseh.ar_interface_flag             = cv_n_flag                  -- AR�C���^�t�F�[�X�σt���O:N(�����M)
               WHERE  xseh.ar_interface_flag            IN ( cv_n_flag, cv_w_flag )   -- AR�C���^�t�F�[�X�σt���O:N(�����M) W(�x��)
/* 2009/10/02 Ver1.24 Mod End   */
               AND    xseh.delivery_date                <= gd_process_date            -- �[�i�� <= �Ɩ����t
/* 2009/10/02 Ver1.24 Add Start */
/* 2009/11/05 Ver1.26 Del Start */
--               AND    xseh.create_class                  = iv_create_class            -- �p�����[�^.�쐬���敪
/* 2009/11/05 Ver1.26 Del End   */
               AND    (
                        ( iv_target = cv_major AND xseh.receiv_base_code = gv_busi_dept_cd )
                        OR
                        (
                          ( iv_target = cv_not_major )
                          AND
                          ( 
                            ( xseh.receiv_base_code <> gv_busi_dept_cd )
                            OR
                            ( xseh.receiv_base_code IS NULL )
                          )
                        )
                      )                                                               -- �p�����[�^.�����Ώۋ敪 1:��� 2:����
/* 2009/10/02 Ver1.24 Add End   */
               AND    hcas.account_number                = xseh.ship_to_customer_code
               AND    hcas.customer_class_code          IN ( cv_cust_class_cust, cv_cust_class_ue ) -- �ڋq�敪:10(�ڋq),12(��l)
               AND    hcar_sb.related_cust_account_id    = hcas.cust_account_id
               AND    hcar_sb.status                     = cv_cust_relate_status      -- �ڋq�֘A(����)�X�e�[�^�X:A(�L��)
               AND    hcar_sb.attribute1                 = cv_cust_bill               -- �֘A����:1(����)
               AND    hcab.cust_account_id               = hcar_sb.cust_account_id
               AND    hcar_sc.related_cust_account_id    = hcab.cust_account_id
               AND    hcar_sc.status                     = cv_cust_relate_status      -- �ڋq�֘A(����)�X�e�[�^�X:A(�L��)
               AND    hcar_sc.attribute1                 = cv_cust_cash               -- �֘A����(����)
               AND    hcac.cust_account_id               = hcar_sc.cust_account_id
               AND    hcac.customer_class_code           = cv_cust_class_uri          -- �ڋq�敪(����):14(���|���Ǘ���ڋq)
/* 2009/11/05 Ver1.26 Add Start */
               AND    flvl.lookup_type                   = cv_qct_mkorg_cls
               AND    flvl.lookup_code                   LIKE cv_qcc_code
               AND    flvl.attribute2                    IS NULL
               AND    flvl.attribute3                    = iv_create_class            -- �p�����[�^.�쐬���敪
               AND    flvl.enabled_flag                  = cv_enabled_yes
               AND    flvl.language                      = ct_lang
               AND    gd_process_date BETWEEN NVL( flvl.start_date_active, gd_process_date )
                                      AND     NVL( flvl.end_date_active,   gd_process_date )
               AND    flvl.meaning                       = xseh.create_class
/* 2009/11/05 Ver1.26 Add End   */
               AND    EXISTS (
                        SELECT /*+ USE_NL(ship_hasa_2 ship_hsua_2 ship_hzad_2 bill_hasa_2 bill_hsua_2 bill_hzad_2 cash_hasa_2 cash_hzad_2) */
                               'X'
                        FROM   hz_cust_acct_sites     ship_hasa_2
                              ,hz_cust_site_uses      ship_hsua_2
                              ,xxcmm_cust_accounts    ship_hzad_2
                              ,hz_cust_acct_sites     bill_hasa_2
                              ,hz_cust_site_uses      bill_hsua_2
                              ,xxcmm_cust_accounts    bill_hzad_2
                              ,hz_cust_acct_sites     cash_hasa_2
                              ,xxcmm_cust_accounts    cash_hzad_2
                        WHERE  ship_hasa_2.cust_account_id     = hcas.cust_account_id
                        AND    ship_hsua_2.cust_acct_site_id   = ship_hasa_2.cust_acct_site_id
                        AND    ship_hzad_2.customer_id         = hcas.cust_account_id
                        AND    bill_hasa_2.cust_account_id     = hcab.cust_account_id
                        AND    bill_hsua_2.cust_acct_site_id   = bill_hasa_2.cust_acct_site_id
                        AND    bill_hsua_2.site_use_code       = cv_site_code                   -- �T�C�g�R�[�h:BILL_TO
                        AND    bill_hzad_2.customer_id         = hcab.cust_account_id
                        AND    cash_hasa_2.cust_account_id     = hcac.cust_account_id
                        AND    cash_hzad_2.customer_id         = hcac.cust_account_id
                        AND    ship_hsua_2.bill_to_site_use_id = bill_hsua_2.site_use_id
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    ship_hsua_2.status              = cv_status_enable         --�ڋq�g�p�ړI.�X�e�[�^�X = 'A'(�L��)
                        AND    bill_hsua_2.status              = cv_status_enable         --�ڋq�g�p�ړI.�X�e�[�^�X = 'A'(�L��)
                        AND    cash_hasa_2.status              = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
                        AND    bill_hasa_2.status              = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
                        AND    ship_hasa_2.status              = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
                        AND    bill_hsua_2.primary_flag        = cv_y_flag                --�ڋq�g�p�ړI.��t���O   = 'Y'(�I��)
                        AND    ship_hsua_2.primary_flag        = cv_y_flag                --�ڋq�g�p�ړI.��t���O   = 'Y'(�I��)
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    ROWNUM                          = 1
                      )
               UNION ALL
               --�B������ڋq�|������ڋq���o�א�ڋq
/* 2009/10/02 Ver1.24 Mod Start */
--               SELECT /*+
--                          LEADING (xseh)
--                          INDEX   (xseh xxcos_sales_exp_headers_n02)
--                          USE_NL  (hcas)
--                      */
/* 2009/11/05 Ver1.26 Mod Start */
--               SELECT /*+
--                          LEADING(xseh)
--                          INDEX(xseh xxcos_sales_exp_headers_n02)
--                          USE_NL(xseh hcas hcab hcar_sc hcac)
--                      */
               SELECT /*+
                          LEADING(xseh)
                          INDEX(xseh xxcos_sales_exp_headers_n02)
                          USE_NL(xseh flvl hcas hcar_sb hcab hcac)
                      */
/* 2009/11/05 Ver1.26 Mod End   */
/* 2009/10/02 Ver1.24 Mod End   */
                      xseh.sales_exp_header_id      sales_exp_header_id
                     ,xseh.dlv_invoice_number       dlv_invoice_number
                     ,xseh.dlv_invoice_class        dlv_invoice_class
                     ,xseh.cust_gyotai_sho          cust_gyotai_sho
                     ,xseh.delivery_date            delivery_date
                     ,xseh.inspect_date             inspect_date
                     ,xseh.ship_to_customer_code    ship_to_customer_code
                     ,xseh.tax_code                 tax_code
                     ,xseh.tax_rate                 tax_rate
                     ,xseh.consumption_tax_class    consumption_tax_class
                     ,xseh.results_employee_code    results_employee_code
                     ,xseh.sales_base_code          sales_base_code
                     ,xseh.receiv_base_code         receiv_base_code
                     ,xseh.create_class             create_class
                     ,xseh.card_sale_class          card_sale_class
                     ,xseh.rowid                    xseh_rowid
                     ,hcas.account_number           ship_account_number
                     ,hcas.cust_account_id          ship_account_id
                     ,hcas.customer_class_code      customer_class_code
                     ,hcab.account_number           bill_account_number
                     ,hcab.cust_account_id          bill_account_id
                     ,hcac.account_number           cash_account_number
                     ,hcac.cust_account_id          cash_account_id
               FROM   xxcos_sales_exp_headers  xseh
                     ,hz_cust_accounts         hcas     -- �o�א�ڋq
                     ,hz_cust_accounts         hcab     -- ������ڋq
                     ,hz_cust_acct_relate      hcar_sc  -- �ڋq�֘A(����)
                     ,hz_cust_accounts         hcac     -- ������ڋq
/* 2009/11/05 Ver1.26 Add Start */
                     ,fnd_lookup_values        flvl     -- �N�C�b�N�R�[�h
/* 2009/11/05 Ver1.26 Add End   */
/* 2009/10/02 Ver1.24 Mod Start */
--               WHERE  xseh.ar_interface_flag            = cv_n_flag                  -- AR�C���^�t�F�[�X�σt���O:N(�����M)
               WHERE  xseh.ar_interface_flag           IN ( cv_n_flag, cv_w_flag )   -- AR�C���^�t�F�[�X�σt���O:N(�����M) W(�x��)
/* 2009/10/02 Ver1.24 Mod End   */
               AND    xseh.delivery_date               <= gd_process_date            -- �[�i�� <= �Ɩ����t
/* 2009/10/02 Ver1.24 Add Start */
/* 2009/11/05 Ver1.26 Del Start */
--               AND    xseh.create_class                 = iv_create_class            -- �p�����[�^.�쐬���敪
/* 2009/11/05 Ver1.26 Del End   */
               AND    (
                        ( iv_target = cv_major AND xseh.receiv_base_code = gv_busi_dept_cd )
                        OR
                        (
                          ( iv_target = cv_not_major )
                          AND
                          ( 
                            ( xseh.receiv_base_code <> gv_busi_dept_cd )
                            OR
                            ( xseh.receiv_base_code IS NULL )
                          )
                        )
                      )                                                               -- �p�����[�^.�����Ώۋ敪 1:��� 2:����
/* 2009/10/02 Ver1.24 Add End   */
               AND    hcas.account_number               = xseh.ship_to_customer_code
               AND    hcas.customer_class_code         IN ( cv_cust_class_cust, cv_cust_class_ue ) -- �ڋq�敪:10(�ڋq),12(��l)
               AND    hcab.cust_account_id              = hcas.cust_account_id
               AND    hcar_sc.related_cust_account_id   = hcas.cust_account_id
               AND    hcar_sc.status                    = cv_cust_relate_status      -- �ڋq�֘A(����)�X�e�[�^�X:A(�L��)
               AND    hcar_sc.attribute1                = cv_cust_cash               -- �֘A����(����)
               AND    hcac.cust_account_id              = hcar_sc.cust_account_id
               AND    hcac.customer_class_code          = cv_cust_class_uri          -- �ڋq�敪(����):14(���|���Ǘ���ڋq)
/* 2009/11/05 Ver1.26 Add Start */
               AND    flvl.lookup_type                  = cv_qct_mkorg_cls
               AND    flvl.lookup_code                  LIKE cv_qcc_code
               AND    flvl.attribute2                   IS NULL
               AND    flvl.attribute3                   = iv_create_class            -- �p�����[�^.�쐬���敪
               AND    flvl.enabled_flag                 = cv_enabled_yes
               AND    flvl.language                     = ct_lang
               AND    gd_process_date BETWEEN NVL( flvl.start_date_active, gd_process_date )
                                      AND     NVL( flvl.end_date_active,   gd_process_date )
               AND    flvl.meaning                      = xseh.create_class
/* 2009/11/05 Ver1.26 Add End   */
               AND    EXISTS (
                        SELECT /*+ USE_NL(ship_hasa_3 ship_hsua_3 ship_hzad_3 bill_hasa_3 bill_hsua_3 cash_hasa_3 cash_hzad_3) */
                               'X'
                        FROM   hz_cust_acct_sites     ship_hasa_3
                              ,hz_cust_site_uses      ship_hsua_3
                              ,xxcmm_cust_accounts    ship_hzad_3
                              ,hz_cust_acct_sites     bill_hasa_3
                              ,hz_cust_site_uses      bill_hsua_3
                              ,hz_cust_acct_sites     cash_hasa_3
                              ,xxcmm_cust_accounts    cash_hzad_3
                        WHERE  ship_hasa_3.cust_account_id     = hcas.cust_account_id
                        AND    ship_hsua_3.cust_acct_site_id   = ship_hasa_3.cust_acct_site_id
                        AND    ship_hzad_3.customer_id         = hcas.cust_account_id
                        AND    bill_hasa_3.cust_account_id     = hcab.cust_account_id
                        AND    bill_hsua_3.cust_acct_site_id   = bill_hasa_3.cust_acct_site_id
                        AND    bill_hsua_3.site_use_code       = cv_site_code                   -- �T�C�g�R�[�h:BILL_TO
                        AND    cash_hasa_3.cust_account_id     = hcac.cust_account_id
                        AND    cash_hzad_3.customer_id         = hcac.cust_account_id
                        AND    ship_hsua_3.bill_to_site_use_id = bill_hsua_3.site_use_id
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    ship_hsua_3.status              = cv_status_enable         --�ڋq�g�p�ړI.�X�e�[�^�X = 'A'(�L��)
                        AND    bill_hsua_3.status              = cv_status_enable         --�ڋq�g�p�ړI.�X�e�[�^�X = 'A'(�L��)
                        AND    cash_hasa_3.status              = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
                        AND    bill_hasa_3.status              = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
                        AND    ship_hasa_3.status              = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
                        AND    bill_hsua_3.primary_flag        = cv_y_flag                --�ڋq�g�p�ړI.��t���O   = 'Y'(�I��)
                        AND    ship_hsua_3.primary_flag        = cv_y_flag                --�ڋq�g�p�ړI.��t���O   = 'Y'(�I��)
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    ROWNUM                          = 1
                      )
               AND    NOT EXISTS (
                        SELECT /*+ USE_NL(ex_hcar_3) */
                               'X'
                        FROM   hz_cust_acct_relate  ex_hcar_3
                        WHERE  ex_hcar_3.cust_account_id = hcas.cust_account_id
                        AND    ex_hcar_3.status          = cv_cust_relate_status -- �ڋq�֘A�X�e�[�^�X:A(�L��)
                        AND    ROWNUM                    = 1
                      )
               UNION ALL
               --�C������ڋq��������ڋq���o�א�ڋq
/* 2009/10/02 Ver1.24 Mod Start */
--               SELECT /*+
--                          LEADING (xseh)
--                          INDEX   (xseh xxcos_sales_exp_headers_n02)
--                          USE_NL  (hcas)
--                          USE_NL  (hcab)
--                      */
/* 2009/11/05 Ver1.26 Mod Start */
--               SELECT /*+
--                          LEADING (xseh)
--                          INDEX   (xseh xxcos_sales_exp_headers_n02)
--                          USE_NL  (hcas hcab hcac)
--                      */
               SELECT /*+
                          LEADING(xseh)
                          INDEX(xseh xxcos_sales_exp_headers_n02)
                          USE_NL(xseh flvl hcas hcar_sb hcab hcac)
                      */
/* 2009/11/05 Ver1.26 Mod End   */
/* 2009/10/02 Ver1.24 Mod End   */
                      xseh.sales_exp_header_id      sales_exp_header_id
                     ,xseh.dlv_invoice_number       dlv_invoice_number
                     ,xseh.dlv_invoice_class        dlv_invoice_class
                     ,xseh.cust_gyotai_sho          cust_gyotai_sho
                     ,xseh.delivery_date            delivery_date
                     ,xseh.inspect_date             inspect_date
                     ,xseh.ship_to_customer_code    ship_to_customer_code
                     ,xseh.tax_code                 tax_code
                     ,xseh.tax_rate                 tax_rate
                     ,xseh.consumption_tax_class    consumption_tax_class
                     ,xseh.results_employee_code    results_employee_code
                     ,xseh.sales_base_code          sales_base_code
                     ,xseh.receiv_base_code         receiv_base_code
                     ,xseh.create_class             create_class
                     ,xseh.card_sale_class          card_sale_class
                     ,xseh.rowid                    xseh_rowid
                     ,hcas.account_number           ship_account_number
                     ,hcas.cust_account_id          ship_account_id
                     ,hcas.customer_class_code      customer_class_code
                     ,hcab.account_number           bill_account_number
                     ,hcab.cust_account_id          bill_account_id
                     ,hcac.account_number           cash_account_number
                     ,hcac.cust_account_id          cash_account_id
               FROM   xxcos_sales_exp_headers  xseh
                     ,hz_cust_accounts         hcas  -- �o�א�ڋq
                     ,hz_cust_accounts         hcab  -- ������ڋq
                     ,hz_cust_accounts         hcac  -- ������ڋq
/* 2009/11/05 Ver1.26 Add Start */
                     ,fnd_lookup_values        flvl  -- �N�C�b�N�R�[�h
/* 2009/11/05 Ver1.26 Add End   */
/* 2009/10/02 Ver1.24 Mod Start */
--              WHERE   xseh.ar_interface_flag     = cv_n_flag                   -- AR�C���^�t�F�[�X�σt���O:N(�����M)
               WHERE  xseh.ar_interface_flag    IN ( cv_n_flag, cv_w_flag )    -- AR�C���^�t�F�[�X�σt���O:N(�����M) W(�x��)
/* 2009/10/02 Ver1.24 Mod End   */
               AND    xseh.delivery_date        <= gd_process_date             -- �[�i�� <= �Ɩ����t
/* 2009/10/02 Ver1.24 Add Start */
/* 2009/11/05 Ver1.26 Del Start */
--               AND    xseh.create_class          = iv_create_class             -- �p�����[�^.�쐬���敪
/* 2009/11/05 Ver1.26 Del End   */
               AND    (
                        ( iv_target = cv_major AND xseh.receiv_base_code = gv_busi_dept_cd )
                        OR
                        (
                          ( iv_target = cv_not_major )
                          AND
                          ( 
                            ( xseh.receiv_base_code <> gv_busi_dept_cd )
                            OR
                            ( xseh.receiv_base_code IS NULL )
                          )
                        )
                      )                                                               -- �p�����[�^.�����Ώۋ敪 1:��� 2:����
/* 2009/10/02 Ver1.24 Add End   */
              AND     hcas.account_number        = xseh.ship_to_customer_code
              AND     hcas.customer_class_code  IN ( cv_cust_class_cust, cv_cust_class_ue ) -- �ڋq�敪:10(�ڋq),12(��l)
              AND     hcab.cust_account_id       = hcas.cust_account_id
              AND     hcac.cust_account_id       = hcas.cust_account_id
/* 2009/11/05 Ver1.26 Add Start */
              AND     flvl.lookup_type           = cv_qct_mkorg_cls
              AND     flvl.lookup_code           LIKE cv_qcc_code
              AND     flvl.attribute2            IS NULL
              AND     flvl.attribute3            = iv_create_class                    -- �p�����[�^.�쐬���敪
              AND     flvl.enabled_flag          = cv_enabled_yes
              AND     flvl.language              = ct_lang
              AND     gd_process_date BETWEEN NVL( flvl.start_date_active, gd_process_date )
                                      AND     NVL( flvl.end_date_active,   gd_process_date )
              AND     flvl.meaning               = xseh.create_class
/* 2009/11/05 Ver1.26 Add End   */
              AND     EXISTS (
                        SELECT /*+ USE_NL(ship_hasa_4 ship_hsua_4 ship_hzad_4 bill_hasa_4 bill_hsua_4) */
                               'X'
                        FROM   hz_cust_acct_sites     ship_hasa_4
                              ,hz_cust_site_uses      ship_hsua_4
                              ,xxcmm_cust_accounts    ship_hzad_4
                              ,hz_cust_acct_sites     bill_hasa_4
                              ,hz_cust_site_uses      bill_hsua_4
                        WHERE  ship_hasa_4.cust_account_id     = hcas.cust_account_id
                        AND    ship_hsua_4.cust_acct_site_id   = ship_hasa_4.cust_acct_site_id
                        AND    ship_hzad_4.customer_id         = hcas.cust_account_id
                        AND    bill_hasa_4.cust_account_id     = hcab.cust_account_id
                        AND    bill_hsua_4.cust_acct_site_id   = bill_hasa_4.cust_acct_site_id
                        AND    bill_hsua_4.site_use_code       = cv_site_code                   -- �T�C�g�R�[�h:BILL_TO
                        AND    ship_hsua_4.bill_to_site_use_id = bill_hsua_4.site_use_id
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    ship_hsua_4.status              = cv_status_enable         --�ڋq�g�p�ړI.�X�e�[�^�X = 'A'(�L��)
                        AND    bill_hsua_4.status              = cv_status_enable         --�ڋq�g�p�ړI.�X�e�[�^�X = 'A'(�L��)
                        AND    bill_hasa_4.status              = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
                        AND    ship_hasa_4.status              = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
                        AND    bill_hsua_4.primary_flag        = cv_y_flag                --�ڋq�g�p�ړI.��t���O   = 'Y'(�I��)
                        AND    ship_hsua_4.primary_flag        = cv_y_flag                --�ڋq�g�p�ړI.��t���O   = 'Y'(�I��)
/* 2010/03/08 Ver1.27 Add Start   */
                        AND    ROWNUM                          = 1
                      )
/* 2009/11/05 Ver1.26 Mod Start */
--              AND   NOT EXISTS (
--                      SELECT /*+ USE_NL(ex_hcar_4) */
--                             'X'
--                      FROM   hz_cust_acct_relate  ex_hcar_4
--                      WHERE  ex_hcar_4.cust_account_id = hcas.cust_account_id
--                      AND    ex_hcar_4.status          = cv_cust_relate_status  -- �ڋq�֘A�X�e�[�^�X:A(�L��)
--                      AND    ROWNUM                    = 1
--                    )
--             AND    NOT EXISTS (
--                      SELECT /*+ USE_NL(ex_hcar_4) */
--                             'X'
--                      FROM   hz_cust_acct_relate  ex_hcar_4
--                      WHERE  ex_hcar_4.related_cust_account_id = hcas.cust_account_id
--                      AND    ex_hcar_4.status                  = cv_cust_relate_status  -- �ڋq�֘A�X�e�[�^�X:A(�L��)
--                      AND    ROWNUM                            = 1
--                    )
              AND     NOT EXISTS (
                        SELECT /*+
                                  USE_NL(ex_hcar_4)
                               */
                               'X'
                        FROM   hz_cust_acct_relate ex_hcar_4
                        WHERE  (
                                  ex_hcar_4.cust_account_id         = hcas.cust_account_id 
                               OR ex_hcar_4.related_cust_account_id = hcas.cust_account_id
                               )
                        AND    ex_hcar_4.status                     = cv_cust_relate_status  -- �ڋq�֘A�X�e�[�^�X:A(�L��)
                        AND    ex_hcar_4.attribute1                 = cv_cust_cash           -- �֘A����(����)
                      )
/* 2009/11/05 Ver1.26 Mod End   */
             )                                 xsehv                   -- �̔����уw�b�_�e�[�u��(�ڋq�K�w����)
/* 2009/07/27 Ver1.21 Add End   */
           , xxcos_sales_exp_lines             xsel                    -- �̔����і��׃e�[�u��
/* 2009/08/28 Ver1.23 Del Start */
--           , ar_vat_tax_all_b                  avta                    -- �ŋ��}�X�^
/* 2009/08/28 Ver1.23 Del End   */
/* 2009/07/27 Ver1.21 Del Start */
--           , hz_cust_accounts                  hcas                    -- �ڋq�}�X�^�i�o�א�j
--           , hz_cust_accounts                  hcab                    -- �ڋq�}�X�^�i������j
--           , hz_cust_accounts                  hcac                    -- �ڋq�}�X�^�i������j
/* 2009/07/27 Ver1.21 Del End   */
           , hz_cust_acct_sites_all            hcss                    -- �ڋq���ݒn�i�o�א�j
           , hz_cust_acct_sites_all            hcsb                    -- �ڋq���ݒn�i������j
           , hz_cust_acct_sites_all            hcsc                    -- �ڋq���ݒn�i������j
/* 2009/07/27 Ver1.21 Add Start */
           , hz_cust_site_uses_all             hcub                    -- �ڋq�T�C�g�i�����j
/* 2009/07/27 Ver1.21 Add End   */
/* 2009/07/27 Ver1.21 Del Start */
--           , xxcos_good_prod_class_v           xgpc                    -- �i�ڋ敪View
--           , xxcos_cust_hierarchy_v            xchv                    -- �ڋq�K�w�r���[
--           , ( SELECT DISTINCT
--                   mcav.subinventory_code      subinventory_code
--               FROM mtl_category_accounts_v    mcav                    -- ���XView
--             ) mcavd
--           , ( SELECT DISTINCT
--                   rcrm.customer_id      customer_id
--                 , receipt_method_id     receipt_method_id
--               FROM ra_cust_receipt_methods           rcrm                    -- �ڋq�x�����@
--                  , hz_cust_site_uses_all             scsua                   -- �ڋq�g�p�ړI
--               WHERE rcrm.primary_flag                     = cv_y_flag
--                 AND rcrm.site_use_id                      = scsua.site_use_id
--                 AND gd_process_date BETWEEN               NVL( rcrm.start_date, gd_process_date )
--                                     AND                   NVL( rcrm.end_date,   gd_process_date )
--                 AND scsua.site_use_code                   = cv_site_code
--             ) rcrmv
/* 2009/07/27 Ver1.21 Del End   */
      WHERE
/* 2009/07/27 Ver1.21 Mod Start   */
--          xseh.sales_exp_header_id              = xsel.sales_exp_header_id
--      AND xseh.dlv_invoice_number               = xsel.dlv_invoice_number
--      AND xseh.ar_interface_flag                = cv_n_flag
--      AND xseh.delivery_date                   <= gd_process_date
--      AND xsel.item_code                       <> gv_var_elec_item_cd
--      AND xchv.ship_account_number              = xseh.ship_to_customer_code
--      AND hcss.org_id                           = TO_NUMBER( gv_mo_org_id )
--      AND hcsb.org_id                           = TO_NUMBER( gv_mo_org_id )
--      AND hcsc.org_id                           = TO_NUMBER( gv_mo_org_id )
--      AND hcas.account_number                   = xseh.ship_to_customer_code
--      AND hcab.account_number                   = xchv.bill_account_number
--      AND hcac.account_number                   = xchv.cash_account_number
--      AND hcas.customer_class_code             <> gt_cust_cls_cd
--      AND ( xseh.cust_gyotai_sho               <> gt_gyotai_fvd
--         OR ( xseh.cust_gyotai_sho              = gt_gyotai_fvd
--           AND NVL( xseh.card_sale_class, cv_cash_class )
--                                               <> gt_cash_sale_cls )
--         OR ( xseh.cust_gyotai_sho              = gt_gyotai_fvd
--           AND NVL( xseh.card_sale_class, cv_cash_class )
--                                                = gt_cash_sale_cls
--           AND NVL( xsel.cash_and_card, 0 )    <> 0 ) )
--      AND avta.tax_code                         = xseh.tax_code
          xsehv.sales_exp_header_id             = xseh.sales_exp_header_id
      AND xsehv.sales_exp_header_id             = xsel.sales_exp_header_id
      AND xsehv.dlv_invoice_number              = xsel.dlv_invoice_number
      AND xsel.item_code                       <> gv_var_elec_item_cd
      AND hcss.cust_account_id                  = xsehv.ship_account_id
      AND hcss.org_id                           = TO_NUMBER( gv_mo_org_id )
      AND hcsb.cust_account_id                  = xsehv.bill_account_id
      AND hcsb.org_id                           = TO_NUMBER( gv_mo_org_id )
      AND hcsc.cust_account_id                  = xsehv.cash_account_id
      AND hcsc.org_id                           = TO_NUMBER( gv_mo_org_id )
      AND hcub.cust_acct_site_id                = hcsb.cust_acct_site_id
      AND hcub.site_use_code                    = cv_site_code
      AND xsehv.customer_class_code            <> gt_cust_cls_cd
      AND ( xsehv.cust_gyotai_sho              <> gt_gyotai_fvd
         OR ( xsehv.cust_gyotai_sho             = gt_gyotai_fvd
           AND NVL( xsehv.card_sale_class, cv_cash_class )
                                               <> gt_cash_sale_cls )
         OR ( xsehv.cust_gyotai_sho = gt_gyotai_fvd
           AND NVL( xsehv.card_sale_class, cv_cash_class )
                                                = gt_cash_sale_cls
           AND NVL( xsel.cash_and_card, 0 )    <> 0 )
          )
/* 2010/03/08 Ver1.27 Add Start   */
      AND hcsc.status                           = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
      AND hcsb.status                           = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
      AND hcss.status                           = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
      AND hcub.primary_flag                     = cv_y_flag                --�ڋq�g�p�ړI.��t���O   = 'Y'(�I��)
/* 2010/03/08 Ver1.27 Add Start   */
/* 2009/08/28 Ver1.23 Del Start */
--      AND avta.tax_code                         = xsehv.tax_code
/* 2009/07/27 Ver1.21 Mod End   */
--      AND avta.set_of_books_id                  = TO_NUMBER( gv_set_bks_id )
--      AND avta.enabled_flag                     = cv_enabled_yes
--      AND gd_process_date BETWEEN               NVL( avta.start_date, gd_process_date )
--                          AND                   NVL( avta.end_date,   gd_process_date )
/* 2009/08/28 Ver1.23 Del End   */
/* 2009/07/27 Ver1.21 Del Start */
--        AND xgpc.segment1( + )                = xsel.item_code
/* 2009/07/27 Ver1.21 Del End   */
/* 2009/07/27 Ver1.21 Mod Start */
--      AND xseh.create_class                     NOT IN (
--          SELECT
--              flvl.meaning                      meaning
/* 2009/11/05 Ver1.26 Del Start */
--      AND NOT EXISTS (
--          SELECT
--              'X'
--/* 2009/07/27 Ver1.21 Mod End */
--          FROM
--              fnd_lookup_values                 flvl
--          WHERE
--              flvl.lookup_type                  = cv_qct_mkorg_cls
--          AND flvl.lookup_code                  LIKE cv_qcc_code
--          AND flvl.attribute2                   = cv_attribute_y
--          AND flvl.enabled_flag                 = cv_enabled_yes
--/* 2009/07/27 Ver1.21 Mod Start */
----          AND flvl.language                     = USERENV( 'LANG' )
--          AND flvl.language                     = ct_lang
--/* 2009/07/27 Ver1.21 Mod End   */
--          AND gd_process_date BETWEEN           NVL( flvl.start_date_active, gd_process_date )
--                              AND               NVL( flvl.end_date_active,   gd_process_date )
--/* 2009/07/27 Ver1.21 Add Start */
--          AND flvl.meaning                      = xsehv.create_class
--/* 2009/07/27 Ver1.21 Add End   */
--          )
/* 2009/11/05 Ver1.26 Del End   */
/* 2009/07/27 Ver1.21 Mod Start */
--      AND xsel.sales_class                      NOT IN (
--          SELECT
--              flvl.meaning                      meaning
      AND NOT EXISTS (
          SELECT
              'X'
/* 2009/07/27 Ver1.21 Mod End   */
          FROM
              fnd_lookup_values                 flvl
          WHERE
              flvl.lookup_type                  = cv_qct_sale_cls
          AND flvl.lookup_code                  LIKE cv_qcc_code
          AND flvl.attribute1                   = cv_attribute_y
          AND flvl.enabled_flag                 = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--          AND flvl.language                     = USERENV( 'LANG' )
          AND flvl.language                     = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
          AND gd_process_date BETWEEN           NVL( flvl.start_date_active, gd_process_date )
                              AND               NVL( flvl.end_date_active,   gd_process_date )
/* 2009/07/27 Ver1.21 Add Start */
          AND flvl.meaning                      = xsel.sales_class
/* 2009/07/27 Ver1.21 Add End   */
          )
/* 2009/07/27 Ver1.21 Del Start */
--      AND hcss.cust_account_id                  = hcas.cust_account_id
--      AND hcsb.cust_account_id                  = hcab.cust_account_id
--      AND hcsc.cust_account_id                  = hcac.cust_account_id
--      AND xchv.ship_account_id                  = hcas.cust_account_id
--      AND rcrmv.customer_id( + )                = hcab.cust_account_id
--      AND mcavd.subinventory_code( + )          = xsel.ship_from_subinventory_code
/* 2009/07/27 Ver1.21 Del End   */
/* 2009/07/27 Ver1.21 Mod Start */
--      ORDER BY xseh.sales_exp_header_id
--             , xseh.dlv_invoice_number
--             , xseh.dlv_invoice_class
--             , NVL( xseh.card_sale_class, cv_cash_class )
--             , xseh.cust_gyotai_sho
/* 2009/10/02 Ver1.24 Mod Start */
--      ORDER BY xsehv.sales_exp_header_id
--             , xsehv.dlv_invoice_number
--             , xsehv.dlv_invoice_class
--             , NVL( xsehv.card_sale_class, cv_cash_class )
--             , xsehv.cust_gyotai_sho
/* 2009/07/27 Ver1.21 Mod End */
--             , xsel.item_code
--             , xsel.red_black_flag
      ORDER BY
        xseh.sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
    FOR UPDATE OF  xseh.sales_exp_header_id
    NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �J�[�\���I�[�v��
    OPEN  sales_data_cur;
/* 2009/10/02 Ver1.24 Mod Start */
--    FETCH sales_data_cur BULK COLLECT INTO gt_sales_exp_tbl2;
--
--    -- �J�[�\���N���[�Y
--    CLOSE sales_data_cur;
--
    LOOP
--
      EXIT WHEN sales_data_cur%NOTFOUND;
--
      --1�o���N�������̏�����
      ln_sale_idx := 0;
      gt_sales_exp_tbl.DELETE;
      gt_sales_exp_tbl2.DELETE;
--
      FETCH sales_data_cur BULK COLLECT INTO gt_sales_exp_tbl2 LIMIT gn_ar_bulk_collect_cnt;
/* 2009/10/02 Ver1.24 Mod End   */
      --�����E�J�[�h���p�ƃJ�[�hVD�̃��R�[�h�쐬���A�X�L�b�v�p�w�b�_ID�擾����
      <<gt_sales_exp_tbl2_loop>>
      FOR sale_idx IN 1 .. gt_sales_exp_tbl2.COUNT LOOP
/* 2009/10/02 Ver1.24 Add Start */
        --�����������A�̔����уw�b�_�X�V�ׁ̈A�z��ɕێ�
        ln_sale_idx_bk                                          := ln_sale_idx_bk + 1;
        gt_sales_target_tbl(ln_sale_idx_bk).sales_exp_header_id := gt_sales_exp_tbl2(sale_idx).sales_exp_header_id;
        gt_sales_target_tbl(ln_sale_idx_bk).xseh_rowid          := gt_sales_exp_tbl2(sale_idx).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/08/20 Ver1.22 Add Start */
        --�u���[�N�p�ϐ�(�x������)������
        lv_break_flag := cv_n_flag;
/* 2010/03/08 Ver1.27 Add Start   */
        -- �i�ڂ��l���i�ڂ̏ꍇ�A���i���i�敪��NULL�ɂ���
        IF ( gt_discount_item_tbl.EXISTS(gt_sales_exp_tbl2(sale_idx).item_code) = TRUE ) THEN
          gt_sales_exp_tbl2(sale_idx).goods_prod_cls := NULL;
        END IF;
/* 2010/03/08 Ver1.27 Add End   */
        --�w�b�_�P�ʂ̏����ׂ̈̃u���[�N����
        IF ( lt_break_header_id IS NULL )
          OR
           ( lt_break_header_id <> gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id )
        THEN
          --�u���[�N�����p�ϐ�������
          lv_break_flag       := cv_y_flag;                                          --�u���[�N�������s(�x������)
/* 2009/11/05 Ver1.26 Add Start */
          lv_break_flag2      := cv_y_flag;                                          --�u���[�N�������s(�J�[�h���)
/* 2009/11/05 Ver1.26 Add End   */
          lt_break_header_id  := gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id;  --�u���[�N����l�̐ݒ�
          lv_sale_flag        := cv_y_flag;                                          --�쐬�Ώ۔���p�̃t���O
/* 2009/10/02 Ver1.24 Mod Start */
          lv_receipt_id_flag  := cv_n_flag;                                          --�x�����@�G���[����t���O
/* 2009/10/02 Ver1.24 Mod End   */
          --SQL�擾�p�ϐ�������
          lv_card_company     := NULL;  --�J�[�h���
          lt_xchv_cust_id     := NULL;  --�J�[�h���(�ڋq�ǉ����)
          lt_receiv_base_code := NULL;  --�J�[�h���(�������_)
          lt_hcsc_org_sys_id  := NULL;  --�J�[�h���(�ڋq���ݒn�Q��)
          lt_receipt_id       := NULL;  --�J�[�h���(�ڋq�x�����@)
          lt_bill_pay_id      := NULL;  --�J�[�h���(�x������)
          lt_bill_pay_id2     := NULL;  --�J�[�h���(�x������2)
          lt_bill_pay_id3     := NULL;  --�J�[�h���(�x������3)
        END IF;
--
/* 2009/08/20 Ver1.22 Add End   */
        IF ( gt_sales_exp_tbl2( sale_idx ).rcrm_receipt_id IS NULL ) THEN
/* 2009/10/02 Ver1.24 Del Start */
--          --�X�L�b�v����
--          ln_skip_idx := ln_skip_idx + 1;
--          gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id
--                                                             := gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Del End   */
/* 2009/08/20 Ver1.22 Add Start */
          --�w�b�_�P�ʂŃ`�F�b�N����
          IF ( lv_break_flag = cv_y_flag ) THEN
/* 2009/08/20 Ver1.22 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
            --�X�L�b�v����
            ln_skip_idx := ln_skip_idx + 1;
            gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id
                                                               := gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id;
            gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid := gt_sales_exp_tbl2(sale_idx).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
--
            --�x�����@�����ݒ�
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application   => cv_xxcos_short_nm
                          , iv_name          => cv_receipt_id_msg
                          , iv_token_name1   => cv_tkn_header_id
                          , iv_token_value1  => gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id
                          , iv_token_name2   => cv_tkn_order_no
                          , iv_token_value2  => gt_sales_exp_tbl2( sale_idx ).dlv_invoice_number
                          , iv_token_name3   => cv_tkn_cust_code
                          , iv_token_value3  => gt_sales_exp_tbl2( sale_idx ).ship_to_customer_code
                        );
            gn_warn_flag := cv_y_flag;
/* 2009/10/02 Ver1.24 Add Start */
            lv_receipt_id_flag := cv_y_flag;
/* 2009/10/02 Ver1.24 Add End   */
            -- ��s�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => cv_blank
            );
--
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_errmsg
            );
--
            -- ��s�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => cv_blank
            );
--
--
            -- ��s�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => cv_blank
            );
--
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            -- ��s�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => cv_blank
            );
/* 2009/08/20 Ver1.22 Add Start */
--
          END IF;  --�w�b�_�P�ʃ`�F�b�NEND
--
/* 2009/08/20 Ver1.22 Add End   */
        END IF;
--
        --�J�[�hVD�t���O
        lv_heiyou_card_flag := cv_n_flag;
        --�����E�J�[�h���p
        lv_heiyou_cash_flag := cv_n_flag;
--
        IF ( (   gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho = gt_fvd_xiaoka
              OR gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho = gt_gyotai_fvd )
          AND (  gt_sales_exp_tbl2( sale_idx ).card_sale_class = gt_cash_sale_cls
            AND  gt_sales_exp_tbl2( sale_idx ).cash_and_card  <> 0 ) ) THEN
--
          --�����E�J�[�h���p
          lv_heiyou_cash_flag := cv_y_flag;
--
        ELSIF ( ( gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho = gt_fvd_xiaoka
               OR gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho = gt_gyotai_fvd )
          AND   gt_sales_exp_tbl2( sale_idx ).card_sale_class = cv_card_class ) THEN
--
          --�J�[�hVD
          lv_heiyou_card_flag := cv_y_flag;
--
        END IF;
--
        IF ( lv_heiyou_cash_flag = cv_y_flag
          OR lv_heiyou_card_flag = cv_y_flag ) THEN
--
/* 2009/08/20 Ver1.22 Mod Start */
--        lv_sale_flag := cv_y_flag;
--        BEGIN
          --�w�b�_�P�ʂ�1�x�̂݃`�F�b�N����
/* 2009/11/05 Ver1.26 Mod Start */
--          IF ( lv_break_flag = cv_y_flag ) THEN
          IF ( lv_break_flag2 = cv_y_flag ) THEN
/* 2009/11/05 Ver1.26 Mod End   */
--
/* 2009/08/20 Ver1.22 Mod End   */
            BEGIN
/* 2009/11/05 Ver1.26 Add Start */
              --�J�[�h��Ђ̎擾�����s�ςɂ���
              lv_break_flag2 := cv_n_flag;
/* 2009/11/05 Ver1.26 Add End   */
              SELECT xcab.card_company                -- �ڋq�ǉ����J�[�h���
                   , cst.customer_id                  -- �ڋq�ǉ����ڋqID
                   , cst.receiv_base_code             -- �������_
                   , cst.cust_acct_site_id            -- �ڋq���ݒn�Q��ID
                   , cst.receipt_method_id            -- �ڋq�x�����@ID
                   , cst.bill_payment_term_id         -- �x������ID
                   , cst.bill_payment_term2           -- �x������2
                   , cst.bill_payment_term3           -- �x������3
              INTO   lv_card_company
                   , lt_xchv_cust_id
                   , lt_receiv_base_code
                   , lt_hcsc_org_sys_id
                   , lt_receipt_id
                   , lt_bill_pay_id
                   , lt_bill_pay_id2
                   , lt_bill_pay_id3
              FROM   xxcmm_cust_accounts       xcab   -- �ڋq�ǉ����
                   , ( SELECT xca.customer_code          customer_code
                            , xca.customer_id            customer_id          -- �ڋq�ǉ����ڋqID
                            , xca.receiv_base_code       receiv_base_code     -- �������_
                            , hcasa.cust_acct_site_id    cust_acct_site_id    -- �ڋq���ݒn�Q��ID
                            , rcrm.receipt_method_id     receipt_method_id    -- �ڋq�x�����@ID
                            , hcsua.payment_term_id      bill_payment_term_id -- �x������ID
                            , hcsua.attribute2           bill_payment_term2   -- �x������2
                            , hcsua.attribute3           bill_payment_term3   -- �x������3
                        FROM  xxcmm_cust_accounts       xca    -- �ڋq�ǉ����
                            , hz_cust_acct_sites_all    hcasa  -- �ڋq���ݒn�}�X�^
                            , hz_cust_site_uses_all     hcsua  -- �ڋq�g�p�ړI�}�X�^
                            , hz_cust_accounts          hca    -- �ڋq�}�X�^
                            , ra_cust_receipt_methods   rcrm   -- �ڋq�x�����@
                       WHERE  hcasa.cust_account_id     = xca.customer_id
/* 2010/03/08 Ver1.27 Add Start   */
                         AND  hcsua.status            = cv_status_enable         --�ڋq�g�p�ړI.�X�e�[�^�X = 'A'(�L��)
                         AND  hcasa.status            = cv_status_enable         --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
                         AND  hcsua.primary_flag      = cv_y_flag                --�ڋq�g�p�ړI.��t���O   = 'Y'(�I��)
/* 2010/03/08 Ver1.27 Add Start   */
                         AND  hcasa.org_id              = gv_mo_org_id
                         AND  hcasa.cust_acct_site_id   = hcsua.cust_acct_site_id
                         AND  hcsua.site_use_code       = cv_site_code
                         AND  hcsua.org_id              = gv_mo_org_id 
                         AND  xca.customer_id           = hca.cust_account_id
                         AND  rcrm.customer_id          = hca.cust_account_id
                         AND  rcrm.primary_flag         = cv_y_flag
                         AND  rcrm.site_use_id          = hcsua.site_use_id ) cst
              WHERE  xcab.customer_code        = gt_sales_exp_tbl2( sale_idx ).ship_to_customer_code
                AND  xcab.card_company         = cst.customer_code( + );
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
--
                lv_sale_flag := cv_n_flag;
--
            END;
            IF ( lv_sale_flag = cv_n_flag OR lv_card_company IS NULL ) THEN
--
              lv_sale_flag := cv_n_flag;
              -- �J�[�h��Ђ����ݒ�
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_card_comp_msg
                            , iv_token_name1   => cv_tkn_cust_code
                            , iv_token_value1  => gt_sales_exp_tbl2( sale_idx ).ship_to_customer_code
                          );
              gn_warn_flag := cv_y_flag;
--
            ELSIF ( lt_xchv_cust_id IS NULL ) THEN
--
              lv_sale_flag := cv_n_flag;
              -- �J�[�h��Ђ̃f�[�^���ڋq�ǉ����ɂȂ�
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_cust_num_msg
                            , iv_token_name1   => cv_tkn_card_company
                            , iv_token_value1  => lv_card_company
                          );
              gn_warn_flag := cv_y_flag;
--
            ELSIF ( lt_receiv_base_code IS NULL ) THEN
--
              lv_sale_flag := cv_n_flag;
              -- �J�[�h��Ђ̓������_�����ݒ�
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_receiv_base_msg
                            , iv_token_name1   => cv_tkn_card_company
                            , iv_token_value1  => lv_card_company
                          );
              gn_warn_flag := cv_y_flag;
--
            ELSIF ( lt_hcsc_org_sys_id IS NULL ) THEN
--
              lv_sale_flag := cv_n_flag;
              -- �J�[�h��Ђ̌ڋq���ݒn�Q��ID�����ݒ�
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_org_sys_id_msg
                            , iv_token_name1   => cv_tkn_card_company
                            , iv_token_value1  => lv_card_company
                          );
              gn_warn_flag := cv_y_flag;
--
            END IF;
/* 2009/08/20 Ver1.22 Mod Start */
--        END;
          END IF;  --�w�b�_�P�ʂ̏���END
--
/* 2009/08/20 Ver1.22 Mod End   */
/* 2009/10/02 Ver1.24 Mod Start */
--          IF ( lv_sale_flag = cv_y_flag ) THEN
          --�x�����@���ݒ�A�������́A�J�[�h��Џ��ŃG���[�̏ꍇ�͍쐬���Ȃ�
          IF (
               ( lv_sale_flag = cv_y_flag )
            AND
               ( lv_receipt_id_flag = cv_n_flag  )
             )
          THEN
/* 2009/10/02 Ver1.24 Mod End   */
--
            -- *** �J�[�h���R�[�h�S�J�����̐ݒ� ***
            ln_sale_idx := ln_sale_idx + 1;
--
            gt_sales_exp_tbl( ln_sale_idx )                  := gt_sales_exp_tbl2( sale_idx );
            -- �J�[�h����敪�i�P�F�J�[�h�j
            gt_sales_exp_tbl( ln_sale_idx ).card_sale_class  := cv_card_class;
            -- �{�̋��z
            gt_sales_exp_tbl( ln_sale_idx ).pure_amount      := gt_sales_exp_tbl2( sale_idx ).cash_and_card;
            -- �ŋ��͂O���Œ�
            gt_sales_exp_tbl( ln_sale_idx ).tax_amount       := 0;
            -- �ŋ��R�[�h�͏���ŋ敪(�ΏۊO)�ɂ���
            gt_sales_exp_tbl( ln_sale_idx ).tax_code         := gt_exp_tax_cls;
            -- ���p�z�͂O���Œ�
            gt_sales_exp_tbl( ln_sale_idx ).cash_and_card    := 0;
--
            IF ( lv_heiyou_card_flag = cv_y_flag ) THEN
--
              -- �{�̋��z
              gt_sales_exp_tbl( ln_sale_idx ).pure_amount    := gt_sales_exp_tbl2( sale_idx ).pure_amount
                                                                    + gt_sales_exp_tbl2( sale_idx ).tax_amount;
            END IF;
--
            -- ������ڋq
            gt_sales_exp_tbl( ln_sale_idx ).xchv_cust_id_c   := lt_xchv_cust_id;
            -- �������_
            gt_sales_exp_tbl( ln_sale_idx ).card_receiv_base := lt_receiv_base_code;
            -- ������ڋq���ݒnID
            gt_sales_exp_tbl( ln_sale_idx ).hcsc_org_sys_id  := lt_hcsc_org_sys_id;
            -- �x�����@
            gt_sales_exp_tbl( ln_sale_idx ).rcrm_receipt_id  := lt_receipt_id;
            -- �x�������P
            gt_sales_exp_tbl( ln_sale_idx ).xchv_bill_pay_id  := lt_bill_pay_id;
            -- �x�������Q
            gt_sales_exp_tbl( ln_sale_idx ).xchv_bill_pay_id2 := lt_bill_pay_id2;
            -- �x�������R
            gt_sales_exp_tbl( ln_sale_idx ).xchv_bill_pay_id3 := lt_bill_pay_id3;
            -- ������ڋq�R�[�h
            gt_sales_exp_tbl( ln_sale_idx ).pay_cust_number   := lv_card_company;
--
            IF ( gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho <> gt_gyotai_fvd ) THEN
              -- *** �������R�[�h�S�J�����̐ݒ� ***
              ln_sale_idx := ln_sale_idx + 1;
              gt_sales_exp_tbl( ln_sale_idx )                  := gt_sales_exp_tbl2( sale_idx );
              -- �J�[�h����敪�i0�F�����j
              gt_sales_exp_tbl( ln_sale_idx ).card_sale_class  := cv_cash_class;
              -- �{�̋��z
              gt_sales_exp_tbl( ln_sale_idx ).pure_amount      := gt_sales_exp_tbl2( sale_idx ).pure_amount
                                                                    + gt_sales_exp_tbl2( sale_idx ).tax_amount;
              -- �ŋ��͂O���Œ�
              gt_sales_exp_tbl( ln_sale_idx ).tax_amount       := 0;
              -- �ŋ��R�[�h�͏���ŋ敪(�ΏۊO)�ɂ���
              gt_sales_exp_tbl( ln_sale_idx ).tax_code         := gt_exp_tax_cls;
              -- ���p�z�͂O���Œ�
              gt_sales_exp_tbl( ln_sale_idx ).cash_and_card    := 0;
            END IF;
/* 2009/10/02 Ver1.24 Add Start */
            -- �v��ID
            gt_sales_exp_tbl( ln_sale_idx ).request_id         := gt_sales_exp_tbl2( sale_idx ).request_id;
/* 2009/10/02 Ver1.24 Add End   */
--
          ELSE
/* 2009/10/02 Ver1.24 Del Start */
--          --�X�L�b�v����
--          ln_skip_idx := ln_skip_idx + 1;
--          gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id
--                                                          := gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Del End   */
/* 2009/08/20 Ver1.22 Add Start */
            --�J�[�h��Џ��̃`�F�b�N�ŃG���[�̏ꍇ�A�w�b�_�P�ʂŃ��b�Z�[�W���o�͂���
/* 2009/11/05 Ver1.26 Mod Start */
--            IF ( lv_break_flag = cv_y_flag ) THEN
            IF ( lv_break_flag2 = cv_n_flag ) THEN
--
              --�t���O�����b�Z�[�W�o�͍ςɂ���
              lv_break_flag2 := cv_s_flag;
/* 2009/11/05 Ver1.26 Mod End   */
/* 2009/08/20 Ver1.22 Add End   */
/* 2009/10/02 Ver1.24 Add Start */
              --�X�L�b�v����
              ln_skip_idx := ln_skip_idx + 1;
              gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id
                                                            := gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id;
              gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid := gt_sales_exp_tbl2(sale_idx).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => cv_blank
              );
--
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => cv_blank
              );
--
/* 2009/08/20 Ver1.22 Add Start */
            END IF;
/* 2009/08/20 Ver1.22 Add End   */
          END IF;
        ELSE
/* 2009/10/02 Ver1.24 Add Start */
          --�x�����@���ݒ�ŃG���[�̏ꍇ�͍쐬���Ȃ�
          IF ( lv_receipt_id_flag = cv_n_flag ) THEN
--
/* 2009/10/02 Ver1.24 Add End   */
            -- �ΏۊO�f�[�^�Z�b�g
            ln_sale_idx := ln_sale_idx + 1;
            gt_sales_exp_tbl( ln_sale_idx )                    := gt_sales_exp_tbl2( sale_idx );
--
            -- �Ƒԏ�����24�A25���ɐŋ����O�ɌŒ�A�{�̋��z�͐ō��݂��܂��B
            IF (  gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho = gt_fvd_xiaoka
               OR gt_sales_exp_tbl2( sale_idx ).cust_gyotai_sho = gt_gyotai_fvd ) THEN
              -- �ŋ����O�ɌŒ�
              gt_sales_exp_tbl( ln_sale_idx ).tax_amount       := 0;
              -- �ŋ��R�[�h�͏���ŋ敪(�ΏۊO)�ɂ���
              gt_sales_exp_tbl( ln_sale_idx ).tax_code         := gt_exp_tax_cls;
--
              gt_sales_exp_tbl( ln_sale_idx ).pure_amount      := gt_sales_exp_tbl2( sale_idx ).pure_amount
                                                                  + gt_sales_exp_tbl2( sale_idx ).tax_amount;
            END IF;
--
/* 2009/10/02 Ver1.24 Add Start */
          END IF;
/* 2009/10/02 Ver1.24 Add End   */
--
        END IF;
--
      END LOOP gt_sales_exp_tbl2_loop;                                  -- �̔����уf�[�^���[�v�I��
--
/* 2009/10/02 Ver1.24 Mod Start */
      --AR�̔����у��[�N�e�[�u���쐬
      FORALL i IN 1..gt_sales_exp_tbl.COUNT
        INSERT INTO
          xxcos_sales_exp_ar_work
        VALUES
          gt_sales_exp_tbl(i)
        ;
--
      --���[�N�e�[�u���̍쐬����
      gn_work_cnt := gn_work_cnt + gt_sales_exp_tbl.COUNT;
--
--    -- �Ώۏ�������
--    gn_target_cnt   := gt_sales_exp_tbl2.COUNT;
      -- �Ώۏ�������
      gn_target_cnt   := gn_target_cnt + gt_sales_exp_tbl2.COUNT;
--
    END LOOP;
--
    --�z��̍폜
    gt_sales_exp_tbl.DELETE;
    gt_sales_exp_tbl2.DELETE;
--
    CLOSE sales_data_cur;
/* 2009/10/02 Ver1.24 Mod End   */
--
    IF ( gn_target_cnt > 0 ) THEN
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- ����ʔ̓X�f�[�^�Ƒ��ʔ̓X�f�[�^�̕���
--      -- ���o���ꂽ�̔����уf�[�^�̃��[�v
--      <<gt_sales_exp_tbl_loop>>
--      FOR sale_idx IN 1 .. gt_sales_exp_tbl.COUNT LOOP
--        IF ( gt_sales_exp_tbl( sale_idx ).receiv_base_code = gv_busi_dept_cd ) THEN
--          -- ���ʔ̓X�f�[�^�𒊏o
--          lv_skip_flag := cv_n_flag;
--          -- �X�L�b�v����
--          IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
--
--            <<gt_sales_skip_tbl_loop>>
--            FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
--              IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
--                  = gt_sales_exp_tbl( sale_idx ).sales_exp_header_id ) THEN
--                lv_skip_flag := cv_y_flag;
--                EXIT;
--              END IF;
--            END LOOP gt_sales_skip_tbl_loop;
--          END IF;
--
--          IF ( lv_skip_flag = cv_n_flag ) THEN
--            ln_bulk_idx := ln_bulk_idx + 1;
--            gt_sales_bulk_tbl( ln_bulk_idx )                  := gt_sales_exp_tbl( sale_idx );
--          END IF;
--        ELSE
--          -- ����ʔ̓X�f�[�^�𒊏o
--          lv_skip_flag := cv_n_flag;
--          -- �X�L�b�v����
--          IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
--
--            <<gt_sales_skip_tbl_loop>>
--            FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
--              IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
--                  = gt_sales_exp_tbl( sale_idx ).sales_exp_header_id ) THEN
--                lv_skip_flag := cv_y_flag;
--                EXIT;
--              END IF;
--            END LOOP gt_sales_skip_tbl_loop;
--          END IF;
--
--          IF ( lv_skip_flag = cv_n_flag ) THEN
--            ln_norm_idx := ln_norm_idx + 1;
--            gt_sales_norm_tbl( ln_norm_idx )                  := gt_sales_exp_tbl( sale_idx );
--          END IF;
--        END IF;
--      END LOOP gt_sales_exp_tbl_loop;                                  -- �̔����уf�[�^���[�v�I��
      NULL;
/* 2009/10/02 Ver1.24 Mod End   */
--
    ELSIF ( gn_target_cnt = 0 ) THEN
      -- �Ώۃf�[�^�������b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_no_data_msg
                   );
      lv_errbuf  := lv_errmsg;
      lv_retcode := cv_status_warn;
      RAISE global_no_data_expt;
    ELSE
      ov_retcode := cv_status_error;
      RAISE global_select_data_expt;
    END IF;
--
    --=====================================
    -- �S�p������擾
    --=====================================
    -- �P�D�̔�����
    gv_sales_nm := xxccp_common_pkg.get_msg(
                       iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                     , iv_name              => cv_sales_nm_msg         -- ���b�Z�[�WID
                     );
    -- �Q�D�������œ�
    gv_tax_msg   := xxccp_common_pkg.get_msg(
                      iv_application => cv_xxcos_short_nm              -- �A�v���P�[�V�����Z�k��
                    , iv_name        => cv_tax_msg                     -- ���b�Z�[�WID(�������œ�)
                    );
    -- �R�D���i���㍂
    gv_goods_msg := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_short_nm            -- �A�v���P�[�V�����Z�k��
                      , iv_name        => cv_goods_msg                 -- ���b�Z�[�WID(���i���㍂)
                    );
    -- �S�D���i���㍂
    gv_prod_msg  := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_short_nm            -- �A�v���P�[�V�����Z�k��
                      , iv_name        => cv_prod_msg                  -- ���b�Z�[�WID(���i���㍂)
                    );
    -- �T�D����l����
    gv_disc_msg  := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_short_nm            -- �A�v���P�[�V�����Z�k��
                      , iv_name        => cv_disc_msg                  -- ���b�Z�[�WID(����l��)
                    );
--
    --=====================================================================
    -- �i�ږ��דE�v�̎擾(�u�������œ��v�̂�)(A-3 �� A-5�p)
    --=====================================================================
    BEGIN
      SELECT flvi.description
      INTO   gv_item_tax
      FROM   fnd_lookup_values              flvi                         -- AR�i�ږ��דE�v����}�X�^
      WHERE  flvi.lookup_type               = cv_qct_item_cls
        AND  flvi.lookup_code               LIKE cv_qcc_code
        AND  flvi.attribute1                = cv_tax
        AND  flvi.enabled_flag              = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--        AND  flvi.language                  = USERENV( 'LANG' )
        AND  flvi.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
        AND  gd_process_date BETWEEN        NVL( flvi.start_date_active, gd_process_date )
                             AND            NVL( flvi.end_date_active,   gd_process_date );
--
      -- AR�i�ږ��דE�v(�������œ�)�擾�o���Ȃ��ꍇ
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_xxcos_short_nm
                      , iv_name          => cv_itemdesp_err_msg
                      , iv_token_name1   => cv_tkn_lookup_type
                      , iv_token_value1  => cv_qct_item_cls
                    );
        lv_errbuf  := lv_errmsg;
--
        RAISE global_no_lookup_expt;
    END;
--
      -- �擾����AR�i�ږ��דE�v�����[�N�e�[�u���ɐݒ肷��
      gt_sel_item_desp_tbl( cv_tax ).description := gv_item_tax;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
      lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm        -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_sales_msg         -- ���b�Z�[�WID
                       );
      lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_table_lock_msg
                         , iv_token_name1  => cv_tkn_tbl
                         , iv_token_value1 => lv_table_name
                       );
      lv_errbuf     := lv_errmsg;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
--
    -- *** �Ώۃf�[�^�Ȃ� ***
    WHEN global_no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** �f�[�^�擾��O ***
    WHEN global_select_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- �N�C�b�N�R�[�h�擾�G���[
    WHEN global_no_lookup_expt THEN
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_nm
                      , iv_name         => cv_data_get_msg
                    );
      lv_errbuf  := lv_errmsg;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_sum_data
   * Description      : ��������W�񏈗��i����ʔ̓X�j(A-3)
   ***********************************************************************************/
  PROCEDURE edit_sum_data(
      ov_errbuf         OUT VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_sum_data';          -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);               -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    cv_pad_char             CONSTANT VARCHAR2(1) := '0';     -- PAD�֐��Ŗ��ߍ��ޕ���
    cn_pad_num_char         CONSTANT NUMBER := 8;            -- PAD�֐��Ŗ��ߍ��ޕ�����
--
    -- *** ���[�J���ϐ� ***
/* 2009/10/02 Ver1.24 Del Start */
--    ln_sale_norm_idx2       NUMBER DEFAULT 0;           -- ���������J�[�h���R�[�h�̃C���f�b�N�X
--    ln_card_pt              NUMBER DEFAULT 1;           -- �J�[�h���R�[�h�̃C���f�b�N�X���s�ʒu
/* 2009/10/02 Ver1.24 Del Start */
    ln_ar_idx               NUMBER DEFAULT 0;           -- �������OIF�C���f�b�N�X
/* 2009/10/02 Ver1.24 Mod Start */
--    ln_trx_idx              NUMBER DEFAULT 0;           -- AR�z��OIF�W��f�[�^�C���f�b�N�X;
    ln_trx_idx              NUMBER DEFAULT 1;           -- AR�z��OIF�W��f�[�^�C���f�b�N�X;
/* 2009/10/02 Ver1.24 Mod End   */
--
    lv_trx_type_nm          VARCHAR2(30);               -- ����^�C�v����
    lv_trx_idx              VARCHAR2(30);               -- ����^�C�v(�C���f�b�N�X)
    lv_item_idx             VARCHAR2(30);               -- �i�ږ��דE�v(�C���f�b�N�X)
    lv_item_desp            VARCHAR2(30);               -- �i�ږ��דE�v(TAX�ȊO)
    ln_term_id              NUMBER;                     -- �x������ID
/* 2009/10/02 Ver1.24 Del Start */
--    lv_cust_gyotai_sho      VARCHAR2(30);               -- �Ƒԏ�����
--    ln_pure_amount          NUMBER DEFAULT 0;           -- �J�[�h���R�[�h�̖{�̋��z
--    ln_tax_amount           NUMBER DEFAULT 0;           -- �J�[�h���R�[�h�̏���ŋ��z
--    ln_tax                  NUMBER DEFAULT 0;           -- �W������ŋ��z
--    ln_amount               NUMBER DEFAULT 0;           -- �W�����z
--    ln_trx_number_id        NUMBER;                     -- �������DFF3�p:�����̔Ԕԍ�
--    ln_trx_number_tax_id    NUMBER;                     -- �������DFF3�p�ŋ��p:�����̔Ԕԍ�
/* 2009/10/02 Ver1.24 Del End   */
    lv_trx_sent_dv          VARCHAR2(30);               -- ���������s�敪
/* 2009/10/02 Ver1.24 Del Start */
--    lv_trx_number           VARCHAR2(20);               -- AR����ԍ�
/* 2009/10/02 Ver1.24 Del End   */
    ln_trx_number_small     NUMBER;                     -- ����ԍ�:�����̔�
/* 2009/10/02 Ver1.24 Del Start */
--    ln_term_amount          NUMBER DEFAULT 0;           -- �ꎞ���z
--    ln_max_amount           NUMBER DEFAULT 0;           -- �ő���z
--
--    -- *** ���NO�擾�L�[
--      -- �쐬�敪
--    lt_create_class         xxcos_sales_exp_headers.create_class%TYPE;
--      -- �[�i�`�[�ԍ�
--    lt_invoice_number       xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
--      -- �[�i�`�[�敪
--    lt_invoice_class        xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
--      -- ������ڋq
--    lt_xchv_cust_id_b       xxcos_cust_hierarchy_v.bill_account_id%TYPE;
--
--    -- *** �W��L�[(�̔�����)
--      -- �̔����уw�b�_ID
--    lt_header_id            xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
--      -- AR����ԍ�
--    lt_trx_number           VARCHAR2(20);
--     --�J�[�h����敪
--    lt_cash_sale_cls        xxcos_sales_exp_headers.card_sale_class%TYPE;
--
--    lv_sum_flag             VARCHAR2(1);                -- �W��t���O
--    lv_sum_card_flag        VARCHAR2(1);                -- �J�[�h�W��t���O
/* 2009/10/02 Ver1.24 Del End   */
    lv_employee_name        VARCHAR2(100);              -- �`�[���͎�
/* 2009/10/02 Ver1.24 Del Start */
--    lv_idx_key              VARCHAR2(300);              -- PL/SQL�\�\�[�g�p�C���f�b�N�X������
--    ln_now_index            VARCHAR2(300);
--    ln_first_index          VARCHAR2(300);
--    ln_smb_idx              NUMBER DEFAULT 0;           -- ���������C���f�b�N�X
/* 2009/10/02 Ver1.24 Del End   */
    lv_tbl_nm               VARCHAR2(100);              -- �]�ƈ��}�X�^
    lv_employee_nm          VARCHAR2(100);              -- �]�ƈ�
    lv_header_id_nm         VARCHAR2(100);              -- �w�b�_ID
    lv_order_no_nm          VARCHAR2(100);              -- �`�[�ԍ�
    lv_key_info             VARCHAR2(100);              -- �`�[�ԍ�
/* 2009/10/02 Ver1.24 Del Start */
--      -- �i�ڋ敪
--    lt_goods_prod_class     xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
/* 2009/10/02 Ver1.24 Del End   */
    lv_err_flag             VARCHAR2(1);                -- �G���[�p�t���O
    ln_skip_idx             NUMBER DEFAULT 0;           -- �X�L�b�v�p�C���f�b�N�X;
/* 2009/10/02 Ver1.24 Mod Start */
--    lt_goods_item_code      xxcos_sales_exp_lines.item_code%TYPE;
--    lt_item_code            xxcos_sales_exp_lines.item_code%TYPE;
--    lt_prod_cls             xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
/* 2009/10/02 Ver1.24 Mod End   */
    lt_inspect_date        xxcos_sales_exp_headers.inspect_date%TYPE;          -- ������
    ln_key_dff4             VARCHAR2(100);              -- DFF4
    ln_key_trx_number       VARCHAR2(20);               -- ���No
    ln_key_ship_customer_id NUMBER;                     -- �o�א�ڋqID
    ln_start_index          NUMBER DEFAULT 1;           -- ���No���̊J�n�ʒu
    ln_ship_flg             NUMBER DEFAULT 0;           -- �o�א�ڋq�t���O
/* 2009/10/27 Ver1.25 Add Start */
    lt_spot_term_id         ra_terms_tl.term_id%TYPE;   -- �x������ID(����)
    lv_term_chk_flag        VARCHAR2(1);                -- �x�������`�F�b�N���s�t���O
/* 2009/10/27 Ver1.25 Add End   */
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\ ***
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
/* 2009/10/02 Ver1.24 Del Start */
--    --=====================================================================
--    -- �W�v�O�f�[�^�W�J
--    --=====================================================================
--
--    --�e�[�u���\�[������
--    -- ����f�[�^�݂̂�PL/SQL�\�쐬
--    <<loop_make_sort_data>>
--    FOR i IN 1..gt_sales_norm_tbl.COUNT LOOP
--      --�\�[�g�L�[�͔̔����уw�b�_ID�A�J�[�h����敪�A�̔����і���ID
--      lv_idx_key := gt_sales_norm_tbl(i).sales_exp_header_id
--                    || gt_sales_norm_tbl(i).dlv_invoice_number
--                    || gt_sales_norm_tbl(i).dlv_invoice_class
--                    || gt_sales_norm_tbl(i).card_sale_class
--                    || gt_sales_norm_tbl(i).cust_gyotai_sho
--                    || gt_sales_norm_tbl(i).goods_prod_cls
--                    || gt_sales_norm_tbl(i).item_code
--                    || gt_sales_norm_tbl(i).red_black_flag
--                    || gt_sales_norm_tbl(i).line_id;
--      gt_sales_norm_order_tbl(lv_idx_key) := gt_sales_norm_tbl(i);
--    END LOOP loop_make_sort_data;
--
--    IF gt_sales_norm_order_tbl.COUNT = 0 THEN
--      RETURN;
--    END IF;
--
--    ln_first_index := gt_sales_norm_order_tbl.first;
--    ln_now_index := ln_first_index;
--
--    WHILE ln_now_index IS NOT NULL LOOP
--
--      ln_smb_idx := ln_smb_idx + 1;
--      gt_sales_norm_tbl2(ln_smb_idx) := gt_sales_norm_order_tbl(ln_now_index);
--      -- ���̃C���f�b�N�X���擾����
--      ln_now_index := gt_sales_norm_order_tbl.next(ln_now_index);
--
--    END LOOP;--�\�[�g����
--
/* 2009/10/02 Ver1.24 Del End   */
    --�X�L�b�v�J�E���g�Z�b�g
    ln_skip_idx := gt_sales_skip_tbl.COUNT;
--
/* 2009/10/02 Ver1.24 Mod Start */
--    <<gt_sales_norm_tbl2_loop>>
--    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl2.COUNT LOOP
--
--      -- AR����ԍ��̎����̔�
--      IF (  NVL( lt_create_class, 'X' )       <> gt_sales_norm_tbl2( sale_norm_idx ).create_class        -- �쐬���敪
--         OR NVL( lt_invoice_number, 'X' )     <> gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number  -- �[�i�`�[No
--         OR NVL( lt_invoice_class, 'X' )      <> NVL( gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_class, 'X' )   -- �[�i�`�[�敪
--         OR lt_xchv_cust_id_b                 <> gt_sales_norm_tbl2( sale_norm_idx ).xchv_cust_id_b      -- ������ڋq
--         OR (  (  gt_fvd_xiaoka                =  gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho      -- �t���T�[�r�X�i�����jVD :24
--               OR gt_gyotai_fvd                =  gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho )    -- �t���T�[�r�X VD :25
--             AND ( lt_header_id                 <> gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id  -- �̔����уw�b�_ID
--             OR NVL( lt_cash_sale_cls, 'X' ) <> gt_sales_norm_tbl2( sale_norm_idx ).card_sale_class ) )   --�J�[�h����敪
--         )
    <<gt_sales_norm_tbl_loop>>
    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl.COUNT LOOP
--
      -- AR����ԍ��̎����̔�
/* 2009/11/05 Ver1.26 Mod Start */
--      IF (  NVL( gt_create_class_brk, 'X' )     <> gt_sales_norm_tbl( sale_norm_idx ).create_class        -- �쐬���敪
--         OR NVL( gt_invoice_number_brk, 'X' )   <> gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number  -- �[�i�`�[No
      IF (  NVL( gt_invoice_number_brk, 'X' )   <> gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number  -- �[�i�`�[No
/* 2009/11/05 Ver1.26 Mod End   */
         OR NVL( gt_invoice_class_brk, 'X' )    <> NVL( gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_class, 'X' )   -- �[�i�`�[�敪
         OR gt_xchv_cust_id_s_brk               <> gt_sales_norm_tbl( sale_norm_idx ).xchv_cust_id_s      -- �o�א�ڋq
         OR (
              (    gt_fvd_xiaoka    =  gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho   -- �t���T�[�r�X�i�����jVD :24
                OR gt_gyotai_fvd    =  gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho   -- �t���T�[�r�X VD :25
              )
              AND
              (    gt_header_id_brk                 <> gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id  -- �̔����уw�b�_ID
                OR NVL( gt_cash_sale_cls_brk, 'X' ) <> gt_sales_norm_tbl( sale_norm_idx ).card_sale_class      -- �J�[�h����敪
              )
            )
         )
/* 2009/10/02 Ver1.24 Mod End   */
      THEN
--
        BEGIN
          SELECT
            xxcos_trx_number_small_s01.NEXTVAL
          INTO
            ln_trx_number_small
          FROM
            dual
          ;
        END;
--
        -- AR����ԍ��̕ҏW �[�i�`�[�ԍ��{�V�[�P���X8��
/* 2009/10/02 Ver1.24 Mod Start */
--        lv_trx_number := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number
        gv_trx_number := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number
/* 2009/10/02 Ver1.24 Mod End   */
                           || LPAD( TO_CHAR( ln_trx_number_small )
                                            ,cn_pad_num_char
                                            ,cv_pad_char
                                           );
--
      END IF;
--
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- �[�i�`�[�ԍ��{�V�[�P���X�̍̔�
--      IF (   NVL( lt_trx_number , 'X' )     <> lv_trx_number                                            -- AR����ԍ�
--         OR  lt_header_id                   <> gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id   -- �̔����уw�b�_ID
--         )
--
      -- �[�i�`�[�ԍ��{�V�[�P���X�̍̔�
      IF (   NVL( gv_trx_number_brk , 'X' )  <> gv_trx_number                                           -- AR����ԍ�
         OR  gt_header_id_brk                <> gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id  -- �̔����уw�b�_ID
         )
/* 2009/10/02 Ver1.24 Mod End   */
      THEN
          -- �������DFF4�p:�����̔Ԕԍ�
        BEGIN
--
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
/* 2009/10/02 Ver1.24 Mod Start */
--            ln_trx_number_id
            gn_trx_number_id
/* 2009/10/02 Ver1.24 Mod End   */
          FROM
            dual
          ;
        END;
--
        BEGIN
--
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
/* 2009/10/02 Ver1.24 Mod Start */
--            ln_trx_number_tax_id
            gn_trx_number_tax_id
/* 2009/10/02 Ver1.24 Mod End   */
          FROM
            dual
          ;
        END;
      END IF;
--
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- ����ԍ��L�[
--      lt_invoice_class    := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_class;
--      lt_create_class     := gt_sales_norm_tbl2( sale_norm_idx ).create_class;
--      lt_invoice_number   := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number;
--      lt_xchv_cust_id_b   := gt_sales_norm_tbl2( sale_norm_idx ).xchv_cust_id_b;
--      lt_cash_sale_cls    := gt_sales_norm_tbl2( sale_norm_idx ).card_sale_class;
--
--
--      -- �[�i�`�[�ԍ��{�V�[�P���X�̍̔Ԃ̏W��L�[�̒l�Z�b�g
--      lt_trx_number       := lv_trx_number;
--      lt_header_id        := gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id;
--
--
--        -- AR����ԍ�
--      gt_sales_norm_tbl2( sale_norm_idx ).oif_trx_number   := lv_trx_number;
--        -- DFF4
--      gt_sales_norm_tbl2( sale_norm_idx ).oif_dff4         := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number
--                                                                  || TO_CHAR( ln_trx_number_id );
--        -- DFF4�ŋ��p
--      gt_sales_norm_tbl2( sale_norm_idx ).oif_tax_dff4     := gt_sales_norm_tbl2( sale_norm_idx ).dlv_invoice_number
--                                                                  || TO_CHAR( ln_trx_number_tax_id );
--
--      -- �Ƒԏ����ނ̕ҏW
--      IF ( gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
--        AND gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho <> gt_gyotai_fvd) THEN
--
--          gt_sales_norm_tbl2( sale_norm_idx ).cust_gyotai_sho := cv_nvd;                 -- VD�ȊO�̋ƑԁE�[�iVD
--
--      END IF;
--
--    END LOOP gt_sales_norm_tbl2_loop;
--
      -- ����ԍ��L�[
      gt_invoice_class_brk    := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_class;
/* 2009/11/05 Ver1.26 Del Start */
--      gt_create_class_brk     := gt_sales_norm_tbl( sale_norm_idx ).create_class;
/* 2009/11/05 Ver1.26 Del End   */
      gt_invoice_number_brk   := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number;
      gt_xchv_cust_id_s_brk   := gt_sales_norm_tbl( sale_norm_idx ).xchv_cust_id_s;
      gt_cash_sale_cls_brk    := gt_sales_norm_tbl( sale_norm_idx ).card_sale_class;
--
      -- �[�i�`�[�ԍ��{�V�[�P���X�̍̔Ԃ̏W��L�[�̒l�Z�b�g
      gv_trx_number_brk       := gv_trx_number;
      gt_header_id_brk        := gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id;
--
      -- AR����ԍ�
      gt_sales_norm_tbl( sale_norm_idx ).oif_trx_number   := gv_trx_number;
      -- DFF4
      gt_sales_norm_tbl( sale_norm_idx ).oif_dff4         := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number
                                                                || TO_CHAR( gn_trx_number_id );
      -- DFF4�ŋ��p
      gt_sales_norm_tbl( sale_norm_idx ).oif_tax_dff4     := gt_sales_norm_tbl( sale_norm_idx ).dlv_invoice_number
                                                                || TO_CHAR( gn_trx_number_tax_id );
--
      -- �Ƒԏ����ނ̕ҏW
      IF (
             gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
         AND gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho <> gt_gyotai_fvd
         )
      THEN
--
          gt_sales_norm_tbl( sale_norm_idx ).cust_gyotai_sho := cv_nvd;   -- VD�ȊO�̋ƑԁE�[�iVD
--
      END IF;
--
    END LOOP gt_sales_norm_tbl_loop;
/* 2009/10/02 Ver1.24 Mod End   */
--
    --=====================================================================
    -- ��������W�񏈗��i����ʔ̓X�j�J�n
    --=====================================================================
/* 2009/10/02 Ver1.24 Mod Start */
--    -- �W��L�[�̒l�Z�b�g
--    lt_trx_number       := gt_sales_norm_tbl2( 1 ).oif_trx_number;            -- AR����ԍ�
--    lt_header_id        := gt_sales_norm_tbl2( 1 ).sales_exp_header_id;   -- �̔����уw�b�_ID
--
--    -- ���X�g�f�[�^�o�^�ׂɁA�_�~�[�f�[�^���Z�b�g
--    gt_sales_norm_tbl2( gt_sales_norm_tbl2.COUNT + 1 ).sales_exp_header_id
--                        := gt_sales_norm_tbl2( gt_sales_norm_tbl2.COUNT ).sales_exp_header_id;
--
--    lt_item_code        := gt_sales_norm_tbl2( 1 ).item_code;
--    lt_prod_cls         := gt_sales_norm_tbl2( 1 ).goods_prod_cls;
--
    -- �ŏ���BUKL�����̏ꍇ
    IF ( gn_fetch_first_flag = 0 ) THEN
      -- �W��L�[�̒l�Z�b�g
      gv_trx_number_brk2  := gt_sales_norm_tbl( 1 ).oif_trx_number;        -- AR����ԍ�
      gt_header_id_brk2   := gt_sales_norm_tbl( 1 ).sales_exp_header_id;   -- �̔����уw�b�_ID
      gt_item_code_brk2   := gt_sales_norm_tbl( 1 ).item_code;             -- �i�ڃR�[�h
      gt_prod_cls_brk2    := gt_sales_norm_tbl( 1 ).goods_prod_cls;        -- ���i�敪
    END IF;
    -- 2��ڈȍ~��BUKL�����̏ꍇ�A�ێ����Ă����O���R�[�h���C���T�[�g�p�ϐ��Ɉڂ�
    IF ( gt_sales_sum_tbl_brk.COUNT <> 0 ) THEN
      gt_sales_norm_tbl2( ln_trx_idx ) := gt_sales_sum_tbl_brk( ln_trx_idx );
    END IF;
    -- �Ō��BULK�����̍ŏI���R�[�h�̏ꍇ
    IF ( gn_fetch_end_flag = 1 ) THEN
      -- ���X�g�f�[�^�o�^�ׂɁA�_�~�[�f�[�^���Z�b�g(�J�E���g0���l����-1��ݒ�)
      gt_sales_norm_tbl( gt_sales_norm_tbl.COUNT + 1 ).sales_exp_header_id
                           := -1;
    END IF;
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--    <<gt_sales_norm_sum_loop>>
--    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl2.COUNT LOOP
--
--      --=====================================
--      --  �̔����ь��f�[�^�̏W��
--      --=====================================
--      IF (  lt_trx_number   = gt_sales_norm_tbl2( sale_norm_idx ).oif_trx_number
--         AND lt_header_id   = gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id
--         )
--      THEN
--
--        -- �W�񂷂�t���O�����ݒ�
--        lv_sum_flag      := cv_y_flag;
--
--        -- �{�̋��z���W�񂷂�
--        ln_amount := ln_amount + gt_sales_norm_tbl2( sale_norm_idx ).pure_amount;
--
--        IF ( (
--               (
--                  NVL( lt_prod_cls, 'X' ) = cv_goods_prod_syo
--               OR NVL( lt_prod_cls, 'X' ) = cv_goods_prod_sei
--               )
--             AND
--               NVL( lt_prod_cls, 'X' ) = NVL( gt_sales_norm_tbl2( sale_norm_idx ).goods_prod_cls, 'X' )
--             )
--           OR
--             (
--               (
--                   NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_syo
--               AND NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_sei
--               )
--               AND lt_item_code = gt_sales_norm_tbl2( sale_norm_idx ).item_code
--             )
--           )THEN
--             ln_term_amount := ln_term_amount + gt_sales_norm_tbl2( sale_norm_idx ).pure_amount;
--        ELSIF ( ABS( ln_term_amount ) >= ABS( ln_max_amount ) ) THEN
--             ln_max_amount       := ln_term_amount;
--             ln_term_amount      := gt_sales_norm_tbl2( sale_norm_idx ).pure_amount;
--             lt_goods_prod_class := lt_prod_cls;
--             lt_goods_item_code  := lt_item_code;
--        END IF;
--        lt_item_code        := gt_sales_norm_tbl2( sale_norm_idx ).item_code;
--        lt_prod_cls         := gt_sales_norm_tbl2( sale_norm_idx ).goods_prod_cls;
--
--        -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
--        IF ( gt_sales_norm_tbl2( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_tax := ln_tax + gt_sales_norm_tbl2( sale_norm_idx ).tax_amount;
--        END IF;
--
--      ELSE
--
--        IF ( ABS( ln_term_amount ) >= ABS( ln_max_amount ) ) THEN
--             lt_goods_prod_class := lt_prod_cls;
--             lt_goods_item_code  := lt_item_code;
--        END IF;
--        ln_max_amount       := 0;
--        ln_term_amount      := 0;
--        lt_item_code        := gt_sales_norm_tbl2( sale_norm_idx ).item_code;
--        lt_prod_cls         := gt_sales_norm_tbl2( sale_norm_idx ).goods_prod_cls;
--
--        lv_sum_flag := cv_n_flag;
--        ln_trx_idx  := sale_norm_idx - 1;
--      END IF;
--
--      IF ( lv_sum_flag = cv_n_flag ) THEN
--
    <<gt_sales_norm_sum_loop>>
    FOR sale_norm_idx IN 1 .. gt_sales_norm_tbl.COUNT LOOP
--
      --=====================================
      --  �̔����ь��f�[�^�̏W��
      --=====================================
--
      -- ���[�v���̏�����
      lv_err_flag := cv_n_flag; --�G���[�t���OOFF
--
      --AR����ԍ��A�̔����уw�b�_ID�ŏW��
      IF (   gv_trx_number_brk2 = gt_sales_norm_tbl( sale_norm_idx ).oif_trx_number
         AND gt_header_id_brk2  = gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id
         )
      THEN
--
        -- �C���T�[�g�p�̔z���ێ�
        gt_sales_norm_tbl2( ln_trx_idx ) := gt_sales_norm_tbl( sale_norm_idx );
        -- �W�񂷂�t���O�����ݒ�
        gv_sum_flag                      := cv_y_flag;
        -- �{�̋��z���W�񂷂�
        gn_amount                        := gn_amount + gt_sales_norm_tbl( sale_norm_idx ).pure_amount;
--
        --�i�ږ��דK�p�擾���� ( �قȂ�i�ڋ敪�ō��v���z���ő�̕i�ږ��דK�p���擾 )
        IF (
             (
               (
                  NVL( gt_prod_cls_brk2, 'X' ) = cv_goods_prod_syo
               OR NVL( gt_prod_cls_brk2, 'X' ) = cv_goods_prod_sei
               )
             AND
               NVL( gt_prod_cls_brk2, 'X' ) = NVL( gt_sales_norm_tbl( sale_norm_idx ).goods_prod_cls, 'X' )
             )
           OR
             (
               (
                   NVL( gt_prod_cls_brk2, 'X' ) <> cv_goods_prod_syo
               AND NVL( gt_prod_cls_brk2, 'X' ) <> cv_goods_prod_sei
               )
               AND gt_item_code_brk2 = gt_sales_norm_tbl( sale_norm_idx ).item_code
             )
           )
        THEN
--
          --�i�ڋ敪�P�ʂ̍��v��ێ�
          gn_term_amount := gn_term_amount + gt_sales_norm_tbl( sale_norm_idx ).pure_amount;
--
        --�O�̕i�ڋ敪�̍��v��荇�v���z���傫���ꍇ
        ELSIF ( ABS( gn_term_amount ) >= ABS( gn_max_amount ) ) THEN
          gn_max_amount       := gn_term_amount;                                  -- �ő�̋��z��ێ�
          gn_term_amount      := gt_sales_norm_tbl( sale_norm_idx ).pure_amount;  -- �i�ڋ敪�P�ʂ̍��v���z������
          gt_goods_prod_class := gt_prod_cls_brk2;                                 -- �ő���z�̕i�ڋ敪��ݒ�
          gt_goods_item_code  := gt_item_code_brk2;                                -- �ő���z�̕i�ڃR�[�h��ݒ�
        END IF;
--
        gt_item_code_brk2 := gt_sales_norm_tbl( sale_norm_idx ).item_code;
        gt_prod_cls_brk2  := gt_sales_norm_tbl( sale_norm_idx ).goods_prod_cls;
--
        -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
        IF ( gt_sales_norm_tbl( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          gn_tax := gn_tax + gt_sales_norm_tbl( sale_norm_idx ).tax_amount;
        END IF;
--
      ELSE
--
        IF ( ABS( gn_term_amount ) >= ABS( gn_max_amount ) ) THEN
          gt_goods_prod_class := gt_prod_cls_brk2;
          gt_goods_item_code  := gt_item_code_brk2;
        END IF;
        gn_max_amount       := 0;
/* 2009/11/15 Ver1.26 Mod Start */
--        gn_term_amount      := 0;
        gn_term_amount      := gt_sales_norm_tbl( sale_norm_idx ).pure_amount;
/* 2009/11/15 Ver1.26 Mod End   */
        gt_item_code_brk2   := gt_sales_norm_tbl( sale_norm_idx ).item_code;
        gt_prod_cls_brk2    := gt_sales_norm_tbl( sale_norm_idx ).goods_prod_cls;
        gv_sum_flag         := cv_n_flag;
--
      END IF;
--
      IF ( gv_sum_flag = cv_n_flag ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Del Start */
--        --�G���[�t���OOFF
--        lv_err_flag := cv_n_flag;
/* 2009/10/02 Ver1.24 Del End   */
        lt_inspect_date := gt_sales_norm_tbl2( ln_trx_idx ).inspect_date;
/* 2009/10/27 Ver1.25 Add Start */
        lt_spot_term_id  := NULL;
        --=====================================================================
        -- �O�D�x������ID�i�����j�̎擾
        --=====================================================================
        BEGIN
          SELECT /*+
                    INDEX(rtv0.t ra_terms_tl_n1)
                 */
                 rtv0.term_id     --�����̎x������ID
          INTO   lt_spot_term_id
          FROM   ra_terms_vl rtv0
          WHERE  rtv0.term_id IN (
                   gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id
                  ,gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id2
                  ,gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id3
                 )
          AND    rtv0.name    = gt_spot_payment_code                                     -- ����
          AND    lt_inspect_date  BETWEEN NVL( rtv0.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                  AND     NVL( rtv0.end_date_active  , lt_inspect_date )
          AND    ROWNUM       = 1;
--
          lv_term_chk_flag := cv_n_flag;   --�����̎x�����������݂���̂Ŏx������ID�̎擾�͎��s���Ȃ�
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_term_chk_flag := cv_y_flag; --�����̎x���������擾�ł��Ȃ��ꍇ�A�x������ID�̎擾�����s
        END;
/* 2009/10/27 Ver1.25 Add End   */
        --=====================================================================
        -- �P�D�x������ID�̎擾
        --=====================================================================
/* 2009/10/27 Ver1.25 Add Start */
        --�x�������ɑ������܂܂��ꍇ
        IF ( lv_term_chk_flag = cv_y_flag ) THEN
--
/* 2009/10/27 Ver1.25 Add End   */
          BEGIN
--
            SELECT term_id
            INTO   ln_term_id
            FROM
              ( SELECT term_id
                      ,cutoff_date
                FROM
                  ( --****�x�������P�i�����j
                     SELECT rtv11.term_id
                           ,CASE WHEN rtv11.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date ) ) -- �x����-1>����
                                   THEN  LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date )  -- �[�i���̖���
                                   ELSE  DECODE( rtv11.due_cutoff_day -1, 0
                                                  -- �����t0���̏ꍇ�A�[�i���̑O���������擾
                                                 ,TO_DATE( TO_CHAR( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                                    cn_min_day, cv_date_format_on_sep ) -1
                                                  -- �w�����-1�����擾
                                                 ,TO_DATE( TO_CHAR  ( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                           TO_NUMBER( rtv11.due_cutoff_day -1 ), cv_date_format_on_sep
                                                         )
                                               )
                            END cutoff_date
                     FROM   ra_terms_vl      rtv11                           -- �x�������}�X�^
                     WHERE  lt_inspect_date   BETWEEN NVL( rtv11.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                                  AND NVL( rtv11.end_date_active  , lt_inspect_date )
                       AND  rtv11.due_cutoff_day IS NOT NULL                                         -- ���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
                       AND  rtv11.term_id = gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id         -- �ڋq�K�w�r���[�̎x�������P
                       AND  ROWNUM = 1
--
                    UNION ALL
--
                     --****�x�������P�i�����j
                     SELECT rtv12.term_id
                           ,CASE WHEN rtv12.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 )  ) ) -- �x����-1>����
                                   THEN  LAST_DAY(ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 ) ) -- �[�i�����̖���
                                   ELSE  DECODE( rtv12.due_cutoff_day -1 ,0
                                                  -- �����t0���̏ꍇ�A�[�i���̖���
                                                 ,LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date )
                                                  -- �w�����-1�����擾
                                                 ,TO_DATE( TO_CHAR( ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 ),
                                                                    cv_date_format_yyyymm ) || TO_NUMBER( rtv12.due_cutoff_day -1 )
                                                                    , cv_date_format_on_sep
                                                         )
                                               )
                            END cutoff_date
                     FROM   ra_terms_vl      rtv12           -- �x�������}�X�^
                     WHERE  lt_inspect_date   BETWEEN NVL( rtv12.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                                  AND NVL( rtv12.end_date_active  , lt_inspect_date )
                       AND  rtv12.due_cutoff_day IS NOT NULL                                         -- ���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
                       AND  rtv12.term_id = gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id         -- �ڋq�K�w�r���[�̎x�������P
                       AND  ROWNUM = 1
--
                    UNION ALL
--
                    --****�x�������Q�i�����j
                     SELECT rtv21.term_id
                           ,CASE WHEN rtv21.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date ) ) -- �x����-1>����
                                   THEN  LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date )  -- �[�i���̖���
                                   ELSE  DECODE( rtv21.due_cutoff_day -1, 0
                                                  -- �����t0���̏ꍇ�A�[�i���̑O���������擾
                                                 ,TO_DATE( TO_CHAR( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                                    cn_min_day, cv_date_format_on_sep ) -1
                                                  -- �w�����-1�����擾
                                                 ,TO_DATE( TO_CHAR  ( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                           TO_NUMBER( rtv21.due_cutoff_day -1 )
                                                           , cv_date_format_on_sep
                                                         )
                                               )
                            END cutoff_date
                     FROM   ra_terms_vl      rtv21           -- �x�������}�X�^
                     WHERE  lt_inspect_date   BETWEEN NVL( rtv21.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                                  AND NVL( rtv21.end_date_active  , lt_inspect_date )
                       AND  rtv21.due_cutoff_day IS NOT NULL                                         -- ���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
                       AND  rtv21.term_id = gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id2        -- �ڋq�K�w�r���[�̎x�������Q
                       AND  ROWNUM = 1
--
                    UNION ALL
--
                    --****�x�������Q�i�����j
                     SELECT rtv22.term_id
                           ,CASE WHEN rtv22.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 )  ) ) -- �x����-1>����
                                   THEN  LAST_DAY(ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 ) ) -- �[�i�����̖���
                                   ELSE  DECODE( rtv22.due_cutoff_day -1 ,0
                                                  -- �����t0���̏ꍇ�A�[�i���̖���
                                                 ,LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date )
                                                  -- �w�����-1�����擾
                                                 ,TO_DATE( TO_CHAR( ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 ),
                                                                    cv_date_format_yyyymm ) || TO_NUMBER( rtv22.due_cutoff_day -1 )
                                                                    , cv_date_format_on_sep
                                                         )
                                               )
                            END cutoff_date
                     FROM   ra_terms_vl      rtv22           -- �x�������}�X�^
                     WHERE  lt_inspect_date   BETWEEN NVL( rtv22.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                                  AND NVL( rtv22.end_date_active  , lt_inspect_date )
                       AND  rtv22.due_cutoff_day IS NOT NULL                                         -- ���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
                       AND  rtv22.term_id = gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id2        -- �ڋq�K�w�r���[�̎x�������Q
                       AND  ROWNUM = 1
--
                    UNION ALL
--
                    --****�x�������R�i�����j
                     SELECT rtv31.term_id
                           ,CASE WHEN rtv31.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date ) ) -- �x����-1>����
                                   THEN  LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date )  -- �[�i���̖���
                                   ELSE  DECODE( rtv31.due_cutoff_day -1, 0
                                                  -- �����t0���̏ꍇ�A�[�i���̑O���������擾
                                                 ,TO_DATE( TO_CHAR( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                                    cn_min_day, cv_date_format_on_sep ) -1
                                                  -- �w�����-1�����擾
                                                 ,TO_DATE( TO_CHAR  ( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                           TO_NUMBER( rtv31.due_cutoff_day -1 )
                                                           , cv_date_format_on_sep
                                                         )
                                               )
                            END cutoff_date
                     FROM   ra_terms_vl      rtv31           -- �x�������}�X�^
                     WHERE  lt_inspect_date   BETWEEN NVL( rtv31.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                                  AND NVL( rtv31.end_date_active  , lt_inspect_date )
                       AND  rtv31.due_cutoff_day IS NOT NULL                                         -- ���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
                       AND  rtv31.term_id = gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id3        -- �ڋq�K�w�r���[�̎x�������R
                       AND  ROWNUM = 1
--
                    UNION ALL
--
                    --****�x�������R�i�����j
                     SELECT rtv32.term_id
                           ,CASE WHEN rtv32.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 )  ) ) -- �x����-1>����
                                   THEN  LAST_DAY(ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 ) ) -- �[�i�����̖���
                                   ELSE  DECODE( rtv32.due_cutoff_day -1 ,0
                                                  -- �����t0���̏ꍇ�A�[�i���̖���
                                                 ,LAST_DAY( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date )
                                                  -- �w�����-1�����擾
                                                 ,TO_DATE( TO_CHAR( ADD_MONTHS( gt_sales_norm_tbl2( ln_trx_idx ).inspect_date, 1 ),
                                                                    cv_date_format_yyyymm ) || TO_NUMBER( rtv32.due_cutoff_day -1 )
                                                                    , cv_date_format_on_sep
                                                         )
                                               )
                            END cutoff_date
                     FROM   ra_terms_vl      rtv32           -- �x�������}�X�^
                     WHERE  lt_inspect_date   BETWEEN NVL( rtv32.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                                  AND NVL( rtv32.end_date_active  , lt_inspect_date )
                       AND  rtv32.due_cutoff_day IS NOT NULL                                         -- ���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
                       AND  rtv32.term_id = gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id3        -- �ڋq�K�w�r���[�̎x�������R
                       AND  ROWNUM = 1
                  ) rtv
                WHERE TRUNC( rtv.cutoff_date ) >= gt_sales_norm_tbl2( ln_trx_idx ).inspect_date      -- �[�i��
                ORDER BY rtv.cutoff_date
              )
            WHERE  ROWNUM = 1;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- �x������ID�̎擾���ł��Ȃ��ꍇ
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_term_id_msg
                            , iv_token_name1   => cv_tkn_cust_code
                            , iv_token_value1  => gt_sales_norm_tbl2( ln_trx_idx ).pay_cust_number
                            , iv_token_name2   => cv_tkn_payment_term1
                            , iv_token_value2  => gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id
                            , iv_token_name3   => cv_tkn_payment_term2
                            , iv_token_value3  => gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id2
                            , iv_token_name4   => cv_tkn_payment_term3
                            , iv_token_value4  => gt_sales_norm_tbl2( ln_trx_idx ).xchv_bill_pay_id3
                            , iv_token_name5   => cv_tkn_procedure_name
                            , iv_token_value5  => cv_prg_name
                            , iv_token_name6   => cv_tkn_header_id
/* 2009/10/02 Ver1.24 Mod Start */
--                            , iv_token_value6  => lt_header_id
                            , iv_token_value6  => gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
                            , iv_token_name7   => cv_tkn_order_no
                            , iv_token_value7  => gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_number
                          );
              lv_errbuf  := lv_errmsg;
--
              --�G���[�t���OON
              lv_err_flag := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => cv_blank
              );
--
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
          END;
/* 2009/10/27 Ver1.25 Add Start */
        --�x�������ɑ������܂܂��ꍇ
        ELSE
          ln_term_id := lt_spot_term_id;
        END IF;
/* 2009/10/27 Ver1.25 Add End   */
--
        --=====================================================================
        -- �Q�D����^�C�v�̎擾
        --=====================================================================
--
        lv_trx_idx := gt_sales_norm_tbl2( ln_trx_idx ).create_class
                   || gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_class;
        IF ( gt_sel_trx_type_tbl.EXISTS( lv_trx_idx ) ) THEN
          lv_trx_type_nm := gt_sel_trx_type_tbl( lv_trx_idx ).attribute1;
          lv_trx_sent_dv := gt_sel_trx_type_tbl( lv_trx_idx ).attribute2;
        ELSE
          BEGIN
/* 2009/07/27 Ver1.21 Mod Start */
--            SELECT flvm.attribute1 || flvd.attribute1
            SELECT /*+ USE_NL( flvd ) */
                   flvm.attribute1 || flvd.attribute1
/* 2009/07/27 Ver1.21 Mod End   */
                 , rctt.attribute1
            INTO   lv_trx_type_nm
                 , lv_trx_sent_dv
            FROM   fnd_lookup_values              flvm                     -- �쐬���敪����}�X�^
                 , fnd_lookup_values              flvd                     -- �[�i�`�[�敪����}�X�^
                 , ra_cust_trx_types_all          rctt                     -- ����^�C�v�}�X�^
            WHERE  flvm.lookup_type               = cv_qct_mkorg_cls
              AND  flvd.lookup_type               = cv_qct_dlv_slp_cls
              AND  flvm.lookup_code               LIKE cv_qcc_code
              AND  flvd.lookup_code               LIKE cv_qcc_code
              AND  flvm.meaning                   = gt_sales_norm_tbl2( ln_trx_idx ).create_class
              AND  flvd.meaning                   = gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_class
              AND  rctt.name                      = flvm.attribute1 || flvd.attribute1
              AND  rctt.org_id                    = gv_mo_org_id
              AND  flvm.enabled_flag              = cv_enabled_yes
              AND  flvd.enabled_flag              = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--              AND  flvm.language                  = USERENV( 'LANG' )
--              AND  flvd.language                  = USERENV( 'LANG' )
              AND  flvm.language                  = ct_lang
              AND  flvd.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
              AND  gd_process_date BETWEEN        NVL( flvm.start_date_active, gd_process_date )
                                   AND            NVL( flvm.end_date_active,   gd_process_date )
              AND  gd_process_date BETWEEN        NVL( flvd.start_date_active, gd_process_date )
                                   AND            NVL( flvd.end_date_active,   gd_process_date );
--
          -- ����^�C�v�擾�o���Ȃ��ꍇ
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_trxtype_err_msg
                            , iv_token_name1   => cv_tkn_lookup_type
                            , iv_token_value1  => cv_qct_mkorg_cls
                                               || cv_and
                                               || cv_qct_dlv_slp_cls
                            , iv_token_name2   => cv_tkn_header_id
/* 2009/10/02 Ver1.24 Mod Start */
--                            , iv_token_value2  => lt_header_id
                            , iv_token_value2  => gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
                            , iv_token_name3   => cv_tkn_order_no
                            , iv_token_value3  => gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_number
                          );
              lv_errbuf  := lv_errmsg;
--
              --�G���[�t���OON
              lv_err_flag := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- ���b�Z�[�W�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
          END;
--
          -- �擾��������^�C�v�����[�N�e�[�u���ɐݒ肷��
          gt_sel_trx_type_tbl( lv_trx_idx ).attribute1 := lv_trx_type_nm;
          gt_sel_trx_type_tbl( lv_trx_idx ).attribute2 := lv_trx_sent_dv;
--
        END IF;
--
        --=====================================================================
        -- �R�D�i�ږ��דE�v�̎擾(�u�������œ��v�ȊO)
        --=====================================================================
--
        -- �i�ږ��דE�v�̑��݃`�F�b�N-->���݂��Ă���ꍇ�A�擾�K�v���Ȃ�
/* 2009/10/02 Ver1.24 Mod Start */
--        IF ( lt_goods_prod_class IS NULL ) THEN
        IF ( gt_goods_prod_class IS NULL ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
          lv_item_idx := gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_class
/* 2009/10/02 Ver1.24 Mod Start */
--                      || lt_goods_item_code;
                      || gt_goods_item_code;
/* 2009/10/02 Ver1.24 Mod End   */
        ELSE
          lv_item_idx := gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_class
/* 2009/10/02 Ver1.24 Mod Start */
--                      || lt_goods_prod_class;
                      || gt_goods_prod_class;
/* 2009/10/02 Ver1.24 Mod End   */
        END IF;
--
        IF ( gt_sel_item_desp_tbl.EXISTS( lv_item_idx ) ) THEN
          lv_item_desp := gt_sel_item_desp_tbl( lv_item_idx ).description;
        ELSE
          BEGIN
            SELECT flvi.description
            INTO   lv_item_desp
            FROM   fnd_lookup_values              flvi                     -- AR�i�ږ��דE�v����}�X�^
            WHERE  flvi.lookup_type               = cv_qct_item_cls
              AND  flvi.lookup_code               LIKE cv_qcc_code
              AND  flvi.attribute1                = gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_class
/* 2009/10/02 Ver1.24 Mod Start */
--              AND  flvi.attribute2                = NVL( lt_goods_prod_class,
--                                                         lt_goods_item_code )
              AND  flvi.attribute2                = NVL( gt_goods_prod_class,
                                                         gt_goods_item_code )
/* 2009/10/02 Ver1.24 Mod End   */
              AND  flvi.enabled_flag              = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--              AND  flvi.language                  = USERENV( 'LANG' )
              AND  flvi.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
              AND  gd_process_date BETWEEN        NVL( flvi.start_date_active, gd_process_date )
                                   AND            NVL( flvi.end_date_active,   gd_process_date );
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- AR�i�ږ��דE�v�擾�o���Ȃ��ꍇ
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_itemdesp_err_msg
                            , iv_token_name1   => cv_tkn_lookup_type
                            , iv_token_value1  => cv_qct_item_cls
                            , iv_token_name2   => cv_tkn_header_id
/* 2009/10/02 Ver1.24 Mod Start */
--                            , iv_token_value2  => lt_header_id
                            , iv_token_value2  =>  gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
                            , iv_token_name3   => cv_tkn_order_no
                            , iv_token_value3  => gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_number
                          );
              lv_errbuf  := lv_errmsg;
--
              --�G���[�t���OON
              lv_err_flag := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- ���b�Z�[�W�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
          END;
--
          -- �擾����AR�i�ږ��דE�v�����[�N�e�[�u���ɐݒ肷��
          gt_sel_item_desp_tbl( lv_item_idx ).description := lv_item_desp;
        END IF;
--
        --�`�[���͎Ҏ擾
        BEGIN
          SELECT fu.user_name
          INTO   lv_employee_name
          FROM   fnd_user             fu
                ,per_all_people_f     papf
          WHERE  fu.employee_id       = papf.person_id
/* 2009/07/30 Ver1.21 ADD START */
            AND  gt_sales_norm_tbl2( ln_trx_idx ).inspect_date
                   BETWEEN papf.effective_start_date AND papf.effective_end_date
/* 2009/07/30 Ver1.21 ADD End   */
            AND  papf.employee_number = gt_sales_norm_tbl2( ln_trx_idx ).results_employee_code;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- �`�[���͎Ҏ擾�o���Ȃ��ꍇ
              lv_tbl_nm :=xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_tkn_user_msg
                            );
--
              lv_employee_nm :=xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_employee_code_msg
                            );
--
              lv_header_id_nm :=xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_header_id_msg
                            );
--
              lv_order_no_nm  :=xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_order_no_msg
                            );
--
              xxcos_common_pkg.makeup_key_info(
                            iv_item_name1         =>  lv_employee_nm,
                            iv_data_value1        =>  gt_sales_norm_tbl2( ln_trx_idx ).results_employee_code,
                            iv_item_name2         =>  lv_header_id_nm,
/* 2009/10/02 Ver1.24 Mod Start */
--                            iv_data_value2        =>  lt_header_id,
                            iv_data_value2        =>  gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id,
/* 2009/10/02 Ver1.24 Mod End   */
                            iv_item_name3         =>  lv_order_no_nm,
                            iv_data_value3        =>  gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_number,
                            ov_key_info           =>  lv_key_info,                --�ҏW���ꂽ�L�[���
                            ov_errbuf             =>  lv_errbuf,                  --�G���[���b�Z�[�W
                            ov_retcode            =>  lv_retcode,                 --���^�[���R�[�h
                            ov_errmsg             =>  lv_errmsg                   --���[�U�E�G���[�E���b�Z�[�W
                          );
--
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_data_get_msg
                            , iv_token_name1   => cv_tkn_tbl_nm
                            , iv_token_value1  => lv_tbl_nm
                            , iv_token_name2   => cv_tkn_key_data
                            , iv_token_value2  => lv_key_info
                          );
              lv_errbuf  := lv_errmsg;
--
              --�G���[�t���OON
              lv_err_flag := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- ���b�Z�[�W�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
        END;
      END IF;
--
      --�X�L�b�v����
      IF ( lv_err_flag = cv_y_flag ) THEN
         ln_skip_idx := ln_skip_idx + 1;
         gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Add Start */
         gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid          := gt_sales_norm_tbl2( ln_trx_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
      END IF;
--
      --==============================================================
      -- �S�DAR�������OIF�f�[�^�쐬
      --==============================================================
--
      -- -- �W��t���O�fN'�̏ꍇ�AAR�������OIF�f�[�^�쐬����
/* 2009/10/02 Ver1.24 Mod Start */
--      IF ( lv_sum_flag = cv_n_flag ) THEN
      IF ( gv_sum_flag = cv_n_flag ) THEN
/* 2009/10/02 Ver1.24 Mod Start */
--
        -- AR�������OIF�̎��v�s
        ln_ar_idx   := ln_ar_idx  + 1;
--
        -- AR�������OIF�f�[�^�쐬(���v�s)===>NO.1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- ������׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �������DFF1:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_number;
                                                        -- �������DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).oif_dff4;
                                                        -- �������DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �������DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id;
                                                        -- �������DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name  := gv_sales_nm;
                                                        -- ����\�[�X:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- ��v����ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_line;
                                                        -- ���v�s
        gt_ar_interface_tbl( ln_ar_idx ).description    := lv_item_desp;
                                                        -- �i�ږ��דE�v
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- �ʉ�
/* 2009/10/02 Ver1.24 Mod Start */
--        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_amount;
        gt_ar_interface_tbl( ln_ar_idx ).amount         := gn_amount;
/* 2009/10/02 Ver1.24 Mod Start */
                                                        -- ���v�s�F�{�̋��z
        IF ( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          --���Ŏ��A���z�͖{�́{�ŋ�
/* 2009/10/02 Ver1.24 Mod Start */
--          gt_ar_interface_tbl( ln_ar_idx ).amount       := ln_amount + ln_tax;
          gt_ar_interface_tbl( ln_ar_idx ).amount       := gn_amount + gn_tax;
/* 2009/10/02 Ver1.24 Mod End   */
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- ����^�C�v��
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- �x������ID
        IF (  gt_sales_norm_tbl2( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_norm_tbl2( ln_trx_idx ).cash_and_card   = 0 ) THEN
        -- �����̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        :=gt_sales_norm_tbl2( ln_trx_idx ).xchv_cust_id_b;
                                                        -- ������ڋqID
        ELSE
        -- �J�[�h�̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).xchv_cust_id_c;
                                                        -- ������ڋqID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).hcss_org_sys_id;
                                                        -- �o�א�ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).xchv_cust_id_s;
                                                        -- �o�א�ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).rcrm_receipt_id;
                                                        -- �x�����@ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- ���Z�^�C�v:�uUser�v��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- ���Z���[�g:1 ��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_norm_tbl2( ln_trx_idx ).inspect_date;
                                                        -- �����(���������t):��.������
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_norm_tbl2( ln_trx_idx ).delivery_date;
                                                        -- GL�L����(�d��v���):��.�[�i��
        gt_ar_interface_tbl( ln_ar_idx ).trx_number     := gt_sales_norm_tbl2( ln_trx_idx ).oif_trx_number;
                                                        -- ���v�s�̂݁FAR����ԍ�
        gt_ar_interface_tbl( ln_ar_idx ).line_number    := gt_sales_norm_tbl2( ln_trx_idx ).dlv_inv_line_no;
                                                        -- ���v�s�̂݁FAR������הԍ�
        gt_ar_interface_tbl( ln_ar_idx ).quantity       := cn_quantity;
                                                        -- ���v�s�̂݁F����=1
        gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price
/* 2009/10/02 Ver1.24 Mod Start */
--                                                        := ln_amount;
                                                        := gn_amount;
/* 2009/10/02 Ver1.24 Mod End   */
                                                        -- ���v�s�̂݁F�̔��P��=�{�̋��z
        IF ( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          --���Ŏ��A�̔��P���͖{�́{�ŋ�
/* 2009/10/02 Ver1.24 Mod Start */
--          gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price := ln_amount + ln_tax;
          gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price := gn_amount + gn_tax;
/* 2009/10/02 Ver1.24 Mod End   */
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_norm_tbl2( ln_trx_idx ).tax_code;
                                                        -- �ŋ��R�[�h(�ŋ敪)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute_category
                                                        := gv_mo_org_id;
                                                        -- �w�b�_�[DFF�J�e�S��
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute5
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).sales_base_code;
                                                        -- �w�b�_�[dff5(�N�[����)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute6
                                                        := lv_employee_name;
                                                        -- �w�b�_�[dff6(�`�[���͎�)
        IF( lv_trx_sent_dv = cv_n_flag ) THEN
          gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_hold;
                                                        -- �w�b�_�[DFF7(�\���P)
        ELSIF( lv_trx_sent_dv = cv_y_flag ) THEN
          gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_open;
                                                        -- �w�b�_�[DFF7(�\���P)
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute8
                                                        := cv_wait;
                                                        -- �w�b�_�[dff8(�\���Q)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute9
                                                        := cv_wait;
                                                        -- �w�b�_�[dff9(�\��3)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute11
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).card_receiv_base;
                                                        -- �w�b�_�[DFF11(�������_)
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- �c�ƒP��ID
        IF ( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- ���ł̏ꍇ�A'Y'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- �ō����z�t���O
        ELSIF( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_out_tax_cls 
          OR gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_exp_tax_cls ) THEN
          -- �O�ł̏ꍇ�A'N'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- �ō����z�t���O
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- �쐬��
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- �쐬��
--
        -- AR�������OIF�f�[�^�쐬(�ŋ��s)===>NO.2
        ln_ar_idx := ln_ar_idx + 1;
--
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- ������׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �������DFF1:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).dlv_invoice_number;
                                                        -- �������DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).oif_tax_dff4;
                                                        -- �������DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �������DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id;
                                                        -- �������DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name
                                                        := gv_sales_nm;
                                                        -- ����\�[�X:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- ��v����ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_tax;
                                                        -- �ŋ��s
        gt_ar_interface_tbl( ln_ar_idx ).description    := gv_item_tax;
                                                        -- �i�ږ��דE�v
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- �ʉ�
/* 2009/10/02 Ver1.24 Mod Start */
--        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_tax;
        gt_ar_interface_tbl( ln_ar_idx ).amount         := gn_tax;
/* 2009/10/02 Ver1.24 Mod End   */
                                                        -- �ŋ��s�F����ŋ��z
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- ����^�C�v��
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- �x������ID
        IF (  gt_sales_norm_tbl2( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_norm_tbl2( ln_trx_idx ).cash_and_card   = 0 ) THEN
          -- �����̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).xchv_cust_id_b;
                                                        -- ������ڋqID
        ELSE
        -- �J�[�h�̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).xchv_cust_id_c;
                                                        -- ������ڋqID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).hcss_org_sys_id;
                                                        -- �o�א�ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).xchv_cust_id_s;
                                                        -- �o�א�ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_context
                                                        := gv_sales_nm;
                                                        -- �����N�斾�׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �����N�斾��DFF1:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute3
                                                        := gt_ar_interface_tbl( ln_ar_idx - 1 ).interface_line_attribute3;
                                                        -- �����N�斾��DFF3
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4
                                                        := gt_ar_interface_tbl( ln_ar_idx - 1 ).interface_line_attribute4;
                                                        -- �����N�斾��DFF4
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �����N�斾��DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute7
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).sales_exp_header_id;
                                                        -- �����N�斾��DFF7
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_norm_tbl2( ln_trx_idx ).rcrm_receipt_id;
                                                        -- �x�����@ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- ���Z�^�C�v:�uUser�v��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- ���Z���[�g:1 ��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_norm_tbl2( ln_trx_idx ).inspect_date;
                                                        -- �����(���������t):��.������
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_norm_tbl2( ln_trx_idx ).delivery_date;
                                                        -- GL�L����(�d��v���):��.�[�i��
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_norm_tbl2( ln_trx_idx ).tax_code;
                                                        -- �ŋ��R�[�h
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- �c�ƒP��ID
        IF ( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- ���ł̏ꍇ�A'Y'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- �ō����z�t���O
        ELSIF( gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_out_tax_cls  
          OR gt_sales_norm_tbl2( ln_trx_idx ).tax_code = gt_exp_tax_cls ) THEN
          -- �O�ł̏ꍇ�A'N'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- �ō����z�t���O
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- �쐬��
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- �쐬��
--
      END IF;
--
/* 2009/10/02 Ver1.24 Mod Start */
--      IF ( lv_sum_flag = cv_n_flag ) THEN
--        -- �W��L�[�ƏW����z�̃��Z�b�g
--        lt_trx_number      := gt_sales_norm_tbl2( sale_norm_idx ).oif_trx_number;        -- AR����ԍ�
--        lt_header_id       := gt_sales_norm_tbl2( sale_norm_idx ).sales_exp_header_id;   -- �̔����уw�b�_ID
--
--        ln_amount := gt_sales_norm_tbl2( sale_norm_idx ).pure_amount;
--        IF ( gt_sales_norm_tbl2( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_tax  := gt_sales_norm_tbl2( sale_norm_idx ).tax_amount;
--        ELSE
--          ln_tax  := 0;
--        END IF;
--
      IF ( gv_sum_flag = cv_n_flag ) THEN
        --�����R�[�h���C���T�[�g�p�z��ɐݒ肷��
        gt_sales_norm_tbl2( ln_trx_idx ) := gt_sales_norm_tbl( sale_norm_idx );
        -- �W��L�[�ƏW����z�̃��Z�b�g
        gv_trx_number_brk2 := gt_sales_norm_tbl( sale_norm_idx ).oif_trx_number;        -- AR����ԍ�
        gt_header_id_brk2  := gt_sales_norm_tbl( sale_norm_idx ).sales_exp_header_id;   -- �̔����уw�b�_ID
        gn_amount          := gt_sales_norm_tbl( sale_norm_idx ).pure_amount;           -- �{�̋��z
        --��ېł̏ꍇ�A����ł�0
        IF ( gt_sales_norm_tbl( sale_norm_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          gn_tax  := gt_sales_norm_tbl( sale_norm_idx ).tax_amount;
        ELSE
          gn_tax  := 0;
        END IF;
/* 2009/10/02 Ver1.24 Mod End   */
      END IF;
--
    END LOOP gt_sales_norm_sum_loop;                    -- �̔����уf�[�^���[�v�I��
--
/* 2009/10/02 Ver1.24 Add Start */
    -- �����BULK�����ׁ̈A���[�v�I�����_�̃C���T�[�g�p�ϐ���ێ�
    gt_sales_sum_tbl_brk( ln_trx_idx ) := gt_sales_norm_tbl2( ln_trx_idx );
/* 2009/10/02 Ver1.24 Add End   */
--
/* 2009/10/02 Ver1.24 Del Start */
--    <<gt_sales_bulk_check_loop>>
--    FOR ln_ar_idx IN 1 .. gt_ar_interface_tbl.COUNT LOOP
--      -- �J�n�F1���No���ł̏o�א�ڋq�`�F�b�N
--
--      -- KEY����������
--      IF (
--           (
--              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number IS NULL )
--              AND
--              ( gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4 <> NVL( ln_key_dff4, 'X') )
--           )
--           OR
--           (
--              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number IS NOT NULL )
--              AND
--              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number <> NVL( ln_key_trx_number, 'X') )
--           )
--         )THEN
--
--        -- �o�א�ڋq�t���O��ON�̏ꍇ
--        IF ( ln_ship_flg = cn_ship_flg_on )
--        THEN
--          <<gt_sales_bulk_ship_clear_loop>>
--          FOR start_index IN ln_start_index .. ln_ar_idx - 1 LOOP
--            -- �J�n�F1���No���ł̏o�א�ڋq�`�F�b�N
--
--            -- �o�א�ڋqID���N���A
--            gt_ar_interface_tbl( start_index ).orig_system_ship_customer_id := NULL;
--            gt_ar_interface_tbl( start_index ).orig_system_ship_address_id  := NULL;
--
--            -- �Ō�̍s
--            IF ( gt_ar_interface_tbl.COUNT = ln_ar_idx )
--            THEN
--              -- �o�א�ڋqID���N���A
--              gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id := NULL;
--              gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id  := NULL;
--            END IF;
--
--            -- �I���F1���No���ł̏o�א�ڋq�`�F�b�N
--          END LOOP gt_sales_bulk_ship_clear_loop;
--        END IF;
--
--        -- ���No���擾
--        ln_key_trx_number := gt_ar_interface_tbl( ln_ar_idx ).trx_number;
--
--        -- DFF4���擾
--        ln_key_dff4 := gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4;
--
--        -- �o�א�ڋqID���擾
--        ln_key_ship_customer_id := gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id;
--
--        -- ���No�̊J�n�ʒu���擾
--        ln_start_index := ln_ar_idx;
--
--        -- �t���O��������
--        ln_ship_flg := cn_ship_flg_off;
--
--      ELSE
--        -- �o�א�ڋq���������H
--        IF ( gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id <> ln_key_ship_customer_id ) THEN
--          -- �Ⴄ�ꍇ�A�o�א�ڋq�t���O��ON�ɂ���
--          ln_ship_flg := cn_ship_flg_on;
--
--        END IF;
--        -- DFF4���擾
--        ln_key_dff4 := gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4;
--
--        IF ( ln_ship_flg = cn_ship_flg_on AND ln_ar_idx = gt_ar_interface_tbl.COUNT ) THEN
--          <<gt_sales_bulk_ship_clear_loop>>
--          FOR start_index IN ln_start_index .. ln_ar_idx LOOP
--            -- �J�n�F1���No���ł̏o�א�ڋq�`�F�b�N
--
--            -- �o�א�ڋqID���N���A
--            gt_ar_interface_tbl( start_index ).orig_system_ship_customer_id := NULL;
--            gt_ar_interface_tbl( start_index ).orig_system_ship_address_id  := NULL;
--
--            -- �I���F1���No���ł̏o�א�ڋq�`�F�b�N
--          END LOOP gt_sales_bulk_ship_clear_loop;
--        END IF;
--
--      END IF;
--      -- �I���F1���No���ł̏o�א�ڋq�`�F�b�N
--    END LOOP gt_sales_bulk_check_loop;
/* 2009/10/02 Ver1.24 Del Start */
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_no_lookup_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_term_id_expt THEN
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
  END edit_sum_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_dis_data
   * Description      : AR��v�z���d��쐬�i����ʔ̓X�j(A-4)
   ***********************************************************************************/
  PROCEDURE edit_dis_data(
      ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'edit_dis_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_ccid_idx         VARCHAR2(225);                                   -- �Z�O�����g�P�`�W�̌����iCCID�C���f�b�N�X�p�j
    lv_tbl_nm           VARCHAR2(100);                                   -- ����Ȗڑg�����}�X�^�e�[�u��
    lv_sum_flag         VARCHAR2(1);                                     -- �W��t���O
    lt_ccid             gl_code_combinations.code_combination_id%TYPE;   -- ����Ȗ�CCID
    lt_segment3         fnd_lookup_values.attribute7%TYPE;               -- ����ȖڃR�[�h
--
/* 2009/10/02 Ver1.24 Del Start */
--    -- �W��L�[
--    lt_invoice_number   xxcos_sales_exp_headers.dlv_invoice_number%TYPE; -- �W��L�[�F�[�i�`�[�ԍ�
--    lt_invoice_class    xxcos_sales_exp_headers.dlv_invoice_class%TYPE;  -- �W��L�[�F�[�i�`�[�敪
--    lt_item_code        xxcos_sales_exp_lines.item_code%TYPE;            -- �W��L�[�F�i�ڃR�[�h
--    lt_prod_cls         xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
--                                                                         -- �i�ڋ敪�i���i�E���i�j
--    lt_gyotai_sho       xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;    -- �W��L�[�F�Ƒԏ�����
--    lt_card_sale_class  xxcos_sales_exp_headers.card_sale_class%TYPE;    -- �W��L�[�F�J�[�h����敪
--    lt_red_black_flag   xxcos_sales_exp_lines.red_black_flag%TYPE;       -- �W��L�[�F�ԍ��t���O
--    lt_tax_code         xxcos_sales_exp_headers.tax_code%TYPE;           -- �W��L�[�F�ŋ��R�[�h
--    lt_header_id        xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- �W��L�[�F�̔����уw�b�_ID
--    ln_amount           NUMBER DEFAULT 0;                                -- �W�����z
--    ln_tax              NUMBER DEFAULT 0;                                -- �W������ŋ��z
    ln_ar_dis_idx       NUMBER DEFAULT 0;                                -- AR��v�z���W��C���f�b�N�X
/* 2009/10/02 Ver1.24 Mod Start */
--    ln_dis_idx          NUMBER DEFAULT 0;                                -- AR��v�z��OIF�C���f�b�N�X
    ln_dis_idx          NUMBER DEFAULT 1;                                -- AR��v�z��OIF�C���f�b�N�X
/* 2009/10/02 Ver1.24 Mod End   */
    ln_jour_cnt         NUMBER DEFAULT 0;                                -- �d�󐶐��J�E���g
    lv_rec_flag         VARCHAR2(1);                                     -- REC�t���O
/* 2009/10/02 Ver1.24 Del Start */
--    -- AR����ԍ�
--    lt_trx_number       VARCHAR2(20);
/* 2009/10/02 Ver1.24 Del End   */
    lv_err_flag         VARCHAR2(1);                                     -- �G���[�p�t���O
    lv_jour_flag        VARCHAR2(1);                                     -- �G���[�p�t���O
    ln_skip_idx         NUMBER DEFAULT 0;                                -- �X�L�b�v�p�C���f�b�N�X;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
/* 2009/10/02 Ver1.24 Del Start */
--    non_jour_cls_expt         EXCEPTION;                -- �d��p�^�[���Ȃ�
/* 2009/10/02 Ver1.24 Del End   */
    non_ccid_expt             EXCEPTION;                -- CCID�擾�o���Ȃ��G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
/* 2009/10/02 Ver1.24 Del Start */
--    --=====================================
--    -- 1.AR��v�z���d��p�^�[���̎擾
--    --=====================================
--
--    -- �J�[�\���I�[�v��
--    BEGIN
--      OPEN  jour_cls_cur;
--      FETCH jour_cls_cur BULK COLLECT INTO gt_jour_cls_tbl;
--    EXCEPTION
--    -- �d��p�^�[���擾���s�����ꍇ
--      WHEN OTHERS THEN
--        lv_errmsg    := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_xxcos_short_nm
--                         , iv_name         => cv_jour_nodata_msg
--                         , iv_token_name1  => cv_tkn_lookup_type
--                         , iv_token_value1 => cv_qct_jour_cls
--                       );
--        lv_errbuf := lv_errmsg;
--        RAISE non_jour_cls_expt;
--    END;
--    -- �d��p�^�[���擾���s�����ꍇ
--    IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
--      lv_errmsg    := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_xxcos_short_nm
--                       , iv_name         => cv_jour_nodata_msg
--                       , iv_token_name1  => cv_tkn_lookup_type
--                       , iv_token_value1 => cv_qct_jour_cls
--                     );
--      lv_errbuf := lv_errmsg;
--      RAISE non_jour_cls_expt;
--    END IF;
--
--    -- �J�[�\���N���[�Y
--    CLOSE jour_cls_cur;
--
    --�X�L�b�v�J�E���g�Z�b�g
    ln_skip_idx := gt_sales_skip_tbl.COUNT;
    --=====================================
    -- 3.AR��v�z���f�[�^�쐬
    --=====================================
/* 2009/10/02 Ver1.24 Mod Start */
--    -- �W��L�[�̒l�Z�b�g
--    lt_invoice_number   := gt_sales_norm_tbl2( 1 ).dlv_invoice_number;
--    lt_item_code        := gt_sales_norm_tbl2( 1 ).item_code;
--    lt_prod_cls         := gt_sales_norm_tbl2( 1 ).goods_prod_cls;
--    lt_gyotai_sho       := gt_sales_norm_tbl2( 1 ).cust_gyotai_sho;
--    lt_card_sale_class  := gt_sales_norm_tbl2( 1 ).card_sale_class;
--    lt_tax_code         := gt_sales_norm_tbl2( 1 ).tax_code;
--    lt_invoice_class    := gt_sales_norm_tbl2( 1 ).dlv_invoice_class;
--    lt_red_black_flag   := gt_sales_norm_tbl2( 1 ).red_black_flag;
--    lt_header_id        := gt_sales_norm_tbl2( 1 ).sales_exp_header_id;
--
--    -- ���X�g�f�[�^�o�^�ׂɁA�_�~�[�f�[�^���Z�b�g����
--    gt_sales_norm_tbl2( gt_sales_norm_tbl2.COUNT + 1 ).sales_exp_header_id
--                        := gt_sales_norm_tbl2( gt_sales_norm_tbl2.COUNT ).sales_exp_header_id;
--
    -- �ŏ���BUKL�����̏ꍇ
    IF ( gn_fetch_first_flag = 0 ) THEN
      -- �W��L�[�̒l�Z�b�g
      gt_invoice_number_ar_brk   := gt_sales_norm_tbl( 1 ).dlv_invoice_number;
      gt_item_code_ar_brk        := gt_sales_norm_tbl( 1 ).item_code;
      gt_prod_cls_ar_brk         := gt_sales_norm_tbl( 1 ).goods_prod_cls;
      gt_gyotai_sho_ar_brk       := gt_sales_norm_tbl( 1 ).cust_gyotai_sho;
      gt_card_sale_class_ar_brk  := gt_sales_norm_tbl( 1 ).card_sale_class;
      gt_tax_code_ar_brk         := gt_sales_norm_tbl( 1 ).tax_code;
      gt_invoice_class_ar_brk    := gt_sales_norm_tbl( 1 ).dlv_invoice_class;
      gt_red_black_flag_ar_brk   := gt_sales_norm_tbl( 1 ).red_black_flag;
      gt_header_id_ar_brk        := gt_sales_norm_tbl( 1 ).sales_exp_header_id;
    END IF;
    -- 2��ڈȍ~��BUKL�����̏ꍇ�A�ێ����Ă����O���R�[�h���C���T�[�g�p�ϐ��Ɉڂ�
    IF ( gt_sales_dis_tbl_brk.COUNT <> 0 ) THEN
      gt_sales_norm_tbl2( ln_dis_idx ) := gt_sales_dis_tbl_brk( ln_dis_idx );
    END IF;
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--    <<gt_sales_norm_tbl2_loop>>
--    FOR dis_sum_idx IN 1 .. gt_sales_norm_tbl2.COUNT LOOP
--
--      -- AR��v�z���f�[�^�W��J�n
--      IF ( lt_invoice_number = gt_sales_norm_tbl2( dis_sum_idx ).dlv_invoice_number
--        AND
--          (
--            (
--              (
--                 NVL( lt_prod_cls, 'X' ) = cv_goods_prod_syo
--              OR NVL( lt_prod_cls, 'X' ) = cv_goods_prod_sei
--              )
--            AND
--              NVL( lt_prod_cls, 'X' ) = NVL( gt_sales_norm_tbl2( dis_sum_idx ).goods_prod_cls, 'X' )
--            )
--          OR
--            (
--              (
--                  NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_syo
--              AND NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_sei
--              )
--              AND lt_item_code = gt_sales_norm_tbl2( dis_sum_idx ).item_code
--            )
--          )
--        AND lt_gyotai_sho      = gt_sales_norm_tbl2( dis_sum_idx ).cust_gyotai_sho
--        AND lt_card_sale_class = gt_sales_norm_tbl2( dis_sum_idx ).card_sale_class
--        AND lt_tax_code        = gt_sales_norm_tbl2( dis_sum_idx ).tax_code
--        AND lt_header_id       = gt_sales_norm_tbl2( dis_sum_idx ).sales_exp_header_id
--        )
--      THEN
--
--        -- �W�񂷂�t���O�����ݒ�
--        lv_sum_flag := cv_y_flag;
--
--       -- �{�̋��z�Ə���Ŋz���W�񂷂�
--        ln_amount := ln_amount + gt_sales_norm_tbl2( dis_sum_idx ).pure_amount;
--        ln_tax    := ln_tax    + gt_sales_norm_tbl2( dis_sum_idx ).tax_amount;
--      ELSE
--        lv_sum_flag := cv_n_flag;
--        ln_dis_idx  := dis_sum_idx - 1;
--      END IF;
--
    <<gt_sales_norm_tbl_loop>>
    FOR dis_sum_idx IN 1 .. gt_sales_norm_tbl.COUNT LOOP
--
      -- AR��v�z���f�[�^�W��J�n
      IF ( gt_invoice_number_ar_brk = gt_sales_norm_tbl( dis_sum_idx ).dlv_invoice_number
        AND
          (
            (
              (
                 NVL( gt_prod_cls_ar_brk, 'X' ) = cv_goods_prod_syo
              OR NVL( gt_prod_cls_ar_brk, 'X' ) = cv_goods_prod_sei
              )
            AND NVL( gt_prod_cls_ar_brk, 'X' ) = NVL( gt_sales_norm_tbl( dis_sum_idx ).goods_prod_cls, 'X' )
            )
          OR
            (
              (
                  NVL( gt_prod_cls_ar_brk, 'X' ) <> cv_goods_prod_syo
              AND NVL( gt_prod_cls_ar_brk, 'X' ) <> cv_goods_prod_sei
              )
            AND gt_item_code_ar_brk = gt_sales_norm_tbl( dis_sum_idx ).item_code
            )
          )
        AND gt_gyotai_sho_ar_brk      = gt_sales_norm_tbl( dis_sum_idx ).cust_gyotai_sho
        AND gt_card_sale_class_ar_brk = gt_sales_norm_tbl( dis_sum_idx ).card_sale_class
        AND gt_tax_code_ar_brk        = gt_sales_norm_tbl( dis_sum_idx ).tax_code
        AND gt_header_id_ar_brk       = gt_sales_norm_tbl( dis_sum_idx ).sales_exp_header_id
        )
      THEN
--
        -- �C���T�[�g�p�̔z���ێ�
        gt_sales_norm_tbl2( ln_dis_idx ) := gt_sales_norm_tbl( dis_sum_idx );
        -- �W�񂷂�t���O�����ݒ�
        gv_sum_flag_ar                   := cv_y_flag;
        -- �{�̋��z�Ə���Ŋz���W�񂷂�
        gn_amount_ar                     := gn_amount_ar + gt_sales_norm_tbl( dis_sum_idx ).pure_amount;
        gn_tax_ar                        := gn_tax_ar    + gt_sales_norm_tbl( dis_sum_idx ).tax_amount;
--
      ELSE
--
        gv_sum_flag_ar := cv_n_flag;
--
      END IF;
/* 2009/10/02 Ver1.24 Mod End   */
--
      -- -- �W��t���O�fN'�̏ꍇ�A���LAR��v�z��OIF�쐬�������s��
/* 2009/10/02 Ver1.24 Mod Start */
--      IF ( lv_sum_flag = cv_n_flag ) THEN
      IF ( gv_sum_flag_ar = cv_n_flag ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--        IF ( NVL( lt_trx_number, 'X' ) <> gt_sales_norm_tbl2( ln_dis_idx ).oif_trx_number ) THEN
        IF ( NVL( gv_trx_number_ar_brk, 'X' ) <> gt_sales_norm_tbl2( ln_dis_idx ).oif_trx_number ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
          lv_rec_flag := cv_y_flag;
        ELSE
          lv_rec_flag := cv_n_flag;
        END IF;
/* 2009/10/02 Ver1.24 Mod Start */
--        lt_trx_number      := gt_sales_norm_tbl2( ln_dis_idx ).oif_trx_number;        -- AR����ԍ�
        gv_trx_number_ar_brk  := gt_sales_norm_tbl2( ln_dis_idx ).oif_trx_number;        -- AR����ԍ�
/* 2009/10/02 Ver1.24 Mod End   */
--
        -- �d�󐶐��J�E���g�����l
        ln_jour_cnt := 1;
        lv_jour_flag := cv_n_flag;
--
        -- �d��p�^�[�����AR��v�z���̎d���ҏW����
        <<gt_jour_cls_tbl_loop>>
        FOR jcls_idx IN 1 .. gt_jour_cls_tbl.COUNT LOOP
--
/* 2009/10/02 Ver1.24 Mod Start */
--          IF (  gt_jour_cls_tbl( jcls_idx ).dlv_invoice_cls   = lt_invoice_class
--            AND (  gt_jour_cls_tbl( jcls_idx ).item_prod_cls  = lt_item_code
--              OR ( gt_jour_cls_tbl( jcls_idx ).item_prod_cls  <> lt_item_code
--                AND gt_jour_cls_tbl( jcls_idx ).item_prod_cls = lt_prod_cls ) )
--            AND ( gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = lt_gyotai_sho
--              OR  gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho IS NULL )
--            AND ( gt_jour_cls_tbl( jcls_idx ).card_sale_cls   = lt_card_sale_class
--              OR  gt_jour_cls_tbl( jcls_idx ).card_sale_cls   IS NULL )
--            AND ( gt_jour_cls_tbl( jcls_idx ).red_black_flag  = lt_red_black_flag
--              OR  gt_jour_cls_tbl( jcls_idx ).red_black_flag  IS NULL )
--            ) THEN
--
          IF (   gt_jour_cls_tbl( jcls_idx ).dlv_invoice_cls   = gt_invoice_class_ar_brk
             AND (
                    gt_jour_cls_tbl( jcls_idx ).item_prod_cls  = gt_item_code_ar_brk
                 OR
                   (   gt_jour_cls_tbl( jcls_idx ).item_prod_cls  <> gt_item_code_ar_brk
                   AND gt_jour_cls_tbl( jcls_idx ).item_prod_cls   = gt_prod_cls_ar_brk
                   )
                 )
             AND (
                    gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = gt_gyotai_sho_ar_brk
                 OR gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho IS NULL
                 )
             AND (
                    gt_jour_cls_tbl( jcls_idx ).card_sale_cls   = gt_card_sale_class_ar_brk
                 OR gt_jour_cls_tbl( jcls_idx ).card_sale_cls   IS NULL
                 )
             AND (
                    gt_jour_cls_tbl( jcls_idx ).red_black_flag  = gt_red_black_flag_ar_brk
                 OR gt_jour_cls_tbl( jcls_idx ).red_black_flag  IS NULL
                 )
             )
          THEN
/* 2009/10/02 Ver1.24 Mod End */
--
            -- ���̏W��ɂR���R�[�h���쐬����
            EXIT WHEN ( ln_jour_cnt > cn_jour_cnt );
--
            -- ����Ȗڂ̕ҏW
            lt_segment3 := gt_jour_cls_tbl( jcls_idx ).segment3;
--
            --=====================================
            -- 2.����Ȗ�CCID�̎擾
            --=====================================
            -- ����ȖڃZ�O�����g�P�`�Z�O�����g�W���CCID�擾
            lv_ccid_idx := gv_company_code                                   -- �Z�O�����g�P(��ЃR�[�h)
                        || NVL( gt_jour_cls_tbl( jcls_idx ).segment2,        -- �Z�O�����g�Q�i����R�[�h�j
                                gt_sales_norm_tbl2( ln_dis_idx ).sales_base_code )
                                                                             -- �Z�O�����g�Q(�̔����т̔��㋒�_�R�[�h)
                        || lt_segment3                                       -- �Z�O�����g�R(����ȖڃR�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment4              -- �Z�O�����g�S(�⏕�ȖڃR�[�h:�����̂ݐݒ�)
                        || gt_jour_cls_tbl( jcls_idx ).segment5              -- �Z�O�����g�T(�ڋq�R�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment6              -- �Z�O�����g�U(��ƃR�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment7              -- �Z�O�����g�V(���Ƌ敪�R�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment8;             -- �Z�O�����g�W(�\��)
--
            -- CCID�̑��݃`�F�b�N-->���݂��Ă���ꍇ�A�擾�K�v���Ȃ�
            IF ( gt_sel_ccid_tbl.EXISTS(  lv_ccid_idx ) ) THEN
              lt_ccid := gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id;
            ELSE
                  -- CCID�擾���ʊ֐����CCID���擾����
              lt_ccid := xxcok_common_pkg.get_code_combination_id_f (
/* 2009/08/28 Ver1.23 Mod Start */
--                             gd_process_date
                             gt_sales_norm_tbl2( ln_dis_idx ).inspect_date
/* 2009/08/28 Ver1.23 Mod End   */
                           , gv_company_code
                           , NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                  gt_sales_norm_tbl2( ln_dis_idx ).sales_base_code )
                           , lt_segment3
                           , gt_jour_cls_tbl( jcls_idx ).segment4
                           , gt_jour_cls_tbl( jcls_idx ).segment5
                           , gt_jour_cls_tbl( jcls_idx ).segment6
                           , gt_jour_cls_tbl( jcls_idx ).segment7
                           , gt_jour_cls_tbl( jcls_idx ).segment8
                         );
--
              --�G���[�t���OOFF
              lv_err_flag := cv_n_flag;
              IF ( lt_ccid IS NULL ) THEN
                -- CCID���擾�ł��Ȃ��ꍇ
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                  iv_application       => cv_xxcos_short_nm
                                , iv_name              => cv_ccid_nodata_msg
                                , iv_token_name1       => cv_tkn_segment1
                                , iv_token_value1      => gv_company_code
                                , iv_token_name2       => cv_tkn_segment2
                                , iv_token_value2      => NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                                               gt_sales_norm_tbl2( ln_dis_idx ).sales_base_code )
                                , iv_token_name3       => cv_tkn_segment3
                                , iv_token_value3      => lt_segment3
                                , iv_token_name4       => cv_tkn_segment4
                                , iv_token_value4      => gt_jour_cls_tbl( jcls_idx ).segment4
                                , iv_token_name5       => cv_tkn_segment5
                                , iv_token_value5      => gt_jour_cls_tbl( jcls_idx ).segment5
                                , iv_token_name6       => cv_tkn_segment6
                                , iv_token_value6      => gt_jour_cls_tbl( jcls_idx ).segment6
                                , iv_token_name7       => cv_tkn_segment7
                                , iv_token_value7      => gt_jour_cls_tbl( jcls_idx ).segment7
                                , iv_token_name8       => cv_tkn_segment8
                                , iv_token_value8      => gt_jour_cls_tbl( jcls_idx ).segment8
                                , iv_token_name9       => cv_tkn_header_id
/* 2009/10/02 Ver1.24 Mod Start */
--                                , iv_token_value9      => lt_header_id
--                                , iv_token_name10      => cv_tkn_order_no
--                                , iv_token_value10     => lt_invoice_number
                                , iv_token_value9      => gt_header_id_ar_brk
                                , iv_token_name10      => cv_tkn_order_no
                                , iv_token_value10     => gt_invoice_number_ar_brk
/* 2009/10/02 Ver1.24 Mod End   */
                              );
                lv_errbuf  := lv_errmsg;
                lv_err_flag  := cv_y_flag;
                gn_warn_flag := cv_y_flag;
                -- ��s�o��
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => cv_blank
                );
--
                -- ���b�Z�[�W�o��
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => lv_errmsg
                );
--
                -- ��s�o��
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => cv_blank
                );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- ���b�Z�[�W�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
/* 2009/08/28 Ver1.23 Mod Start */
--              END IF;
----
--              -- �擾����CCID�����[�N�e�[�u���ɐݒ肷��
--              gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
              ELSE
                -- ���ʊ֐����擾�ł����ꍇ�A�擾����CCID�����[�N�e�[�u���ɐݒ肷��
                gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
--
              END IF;
/* 2009/08/28 Ver1.23 Mod End   */
--
            END IF;                                       -- CCID�ҏW�I��
--
            --�X�L�b�v����
            IF ( lv_err_flag = cv_y_flag ) THEN
               ln_skip_idx := ln_skip_idx + 1;
               gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_norm_tbl2( ln_dis_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Add Start */
               gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid          := gt_sales_norm_tbl2( ln_dis_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
            END IF;
            --=====================================
            -- AR��v�z��OIF�f�[�^�ݒ�
            --=====================================
            IF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rev ) THEN
              -- ���v�s
              ln_ar_dis_idx := ln_ar_dis_idx + 1;
--
              -- AR��v�z��OIF�̐ݒ荀��
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- ������׃R���e�L�X�g�l�u�̔����сv���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- �������DFF1�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).dlv_invoice_number;
                                                          -- �������DFF3�F�[�i�`�[�ԍ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).oif_dff4;
                                                          -- �������DFF4:�[�i�`�[�ԍ�+�����̔�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- �������DFF5�F�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).sales_exp_header_id;
                                                          -- �������DFF7�F�̔����уw�b�_ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_rev;
                                                          -- ����Ȗڋ敪(�z���^�C�v)
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_amount;
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := gn_amount_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- ���z(���׋��z)
              IF ( gt_sales_norm_tbl2( ln_dis_idx ).tax_code = gt_in_tax_cls ) THEN
                --���Ŏ��A���z�͖{�́{�ŋ�
/* 2009/10/02 Ver1.24 Mod Start */
--                gt_ar_dis_tbl( ln_ar_dis_idx ).amount     := ln_amount + ln_tax;
                gt_ar_dis_tbl( ln_ar_dis_idx ).amount     := gn_amount_ar + gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
              END IF;
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := ln_amount;
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := gn_amount_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- �p�[�Z���g(����)
              IF ( gt_sales_norm_tbl2( ln_dis_idx ).tax_code = gt_in_tax_cls ) THEN
                --���Ŏ��A �p�[�Z���g(�����͖{�́{�ŋ�
/* 2009/10/02 Ver1.24 Mod Start */
--                gt_ar_dis_tbl( ln_ar_dis_idx ).percent    := ln_amount + ln_tax;
                gt_ar_dis_tbl( ln_ar_dis_idx ).percent    := gn_amount_ar + gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
              END IF;
              gt_ar_dis_tbl( ln_ar_dis_idx ).code_combination_id
                                                          := lt_ccid;
                                                          -- ����Ȗڑg����ID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_idx ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- �d�󖾍׃J�e�S��:�c�ƒP��ID���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- �c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).created_by
                                                          := cn_created_by;
                                                          -- �쐬��
              gt_ar_dis_tbl( ln_ar_dis_idx ).creation_date
                                                          := cd_creation_date;
                                                          -- �쐬��
--
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rec AND lv_rec_flag = cv_y_flag ) THEN
              -- ���s(���z�ݒ�Ȃ�)
              ln_ar_dis_idx := ln_ar_dis_idx + 1;
--
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- ������׃R���e�L�X�g�l�u�̔����сv���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- �������DFF1�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).dlv_invoice_number;
                                                          -- �������DFF3�F�[�i�`�[�ԍ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).oif_dff4;
                                                          -- �������DFF4�[�i�`�[�ԍ�+�����̔�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- �������DFF5	�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).sales_exp_header_id;
                                                          -- �������DFF7�F�̔����уw�b�_ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_rec;
                                                          -- ����Ȗڋ敪(�z���^�C�v)
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := cn_percent;
                                                          -- �p�[�Z���g(����)
              gt_ar_dis_tbl( ln_ar_dis_idx ).code_combination_id
                                                          := lt_ccid;
                                                          -- ����Ȗڑg����ID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_idx ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- �d�󖾍׃J�e�S��:�c�ƒP��ID���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- �c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).created_by
                                                          := cn_created_by;
                                                          -- �쐬��
              gt_ar_dis_tbl( ln_ar_dis_idx ).creation_date
                                                          := cd_creation_date;
                                                          -- �쐬��
--
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_tax ) THEN
              -- �ŋ��s
              ln_ar_dis_idx := ln_ar_dis_idx + 1;
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- ������׃R���e�L�X�g�l�u�̔����сv���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- �������DFF1�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).dlv_invoice_number;
                                                          -- �������DFF3�F�[�i�`�[�ԍ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).oif_tax_dff4;
                                                          -- �������DFF4�F�[�i�`�[�ԍ�+�����̔�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- �������DFF5�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_sales_norm_tbl2( ln_dis_idx ).sales_exp_header_id;
                                                          -- �������DFF7�F�̔����уw�b�_ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_tax;
                                                          -- ����Ȗڋ敪(�z���^�C�v)
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_tax;
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- ���z(���׋��z)
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := ln_tax;
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- �p�[�Z���g(����)
              gt_ar_dis_tbl( ln_ar_dis_idx ).code_combination_id
                                                          := lt_ccid;
                                                          -- ����Ȗڑg����ID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_idx ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- �d�󖾍׃J�e�S��:�c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- �c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).created_by
                                                          := cn_created_by;
                                                          -- �쐬��
              gt_ar_dis_tbl( ln_ar_dis_idx ).creation_date
                                                          := cd_creation_date;
                                                          -- �쐬��
            END IF;
--
            -- �d�󐶐��J�E���g�Z�b�g
            ln_jour_cnt := ln_jour_cnt + 1;
          END IF;                                         -- �d��p�^�[������AR��v�z��OIF�f�[�^�̍쐬�����I��
--
        END LOOP gt_jour_cls_tbl_loop;                    -- �d��p�^�[�����f�[�^�쐬�����I��
/* 2009/10/02 Ver1.24 Mod Start */
--        IF ( ln_jour_cnt = 1 AND dis_sum_idx <> gt_sales_norm_tbl2.COUNT ) THEN
        --�d�󂪂P�����Ȃ��ꍇ�G���[
        IF ( ln_jour_cnt = 1 ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application       => cv_xxcos_short_nm
                          , iv_name              => cv_jour_no_msg
                          , iv_token_name1       => cv_tkn_invoice_cls
/* 2009/10/02 Ver1.24 Mod Start */
--                          , iv_token_value1      => lt_invoice_class
--                          , iv_token_name2       => cv_tkn_prod_cls
--                          , iv_token_value2      => NVL( lt_prod_cls, lt_item_code )
--                          , iv_token_name3       => cv_tkn_gyotai_sho
--                          , iv_token_value3      => lt_gyotai_sho
--                          , iv_token_name4       => cv_tkn_sale_cls
--                          , iv_token_value4      => lt_card_sale_class
--                          , iv_token_name5       => cv_tkn_red_black_flag
--                          , iv_token_value5      => lt_red_black_flag
--                          , iv_token_name6       => cv_tkn_header_id
--                          , iv_token_value6      => lt_header_id
--                          , iv_token_name7       => cv_tkn_order_no
--                          , iv_token_value7      => lt_invoice_number
                          , iv_token_value1      => gt_invoice_class_ar_brk
                          , iv_token_name2       => cv_tkn_prod_cls
                          , iv_token_value2      => NVL( gt_prod_cls_ar_brk, gt_item_code_ar_brk )
                          , iv_token_name3       => cv_tkn_gyotai_sho
                          , iv_token_value3      => gt_gyotai_sho_ar_brk
                          , iv_token_name4       => cv_tkn_sale_cls
                          , iv_token_value4      => gt_card_sale_class_ar_brk
                          , iv_token_name5       => cv_tkn_red_black_flag
                          , iv_token_value5      => gt_red_black_flag_ar_brk
                          , iv_token_name6       => cv_tkn_header_id
                          , iv_token_value6      => gt_header_id_ar_brk
                          , iv_token_name7       => cv_tkn_order_no
                          , iv_token_value7      => gt_invoice_number_ar_brk
/* 2009/10/02 Ver1.24 Mod End   */
                        );
          lv_errbuf  := lv_errmsg;
          lv_jour_flag  := cv_y_flag;
          gn_warn_flag := cv_y_flag;
          -- ��s�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_blank
          );
--
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
--
          -- ��s�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_blank
          );
          -- ��s�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => cv_blank
          );
--
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          -- ��s�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => cv_blank
          );
          --�X�L�b�v����
          IF ( lv_jour_flag = cv_y_flag ) THEN
             ln_skip_idx := ln_skip_idx + 1;
             gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_norm_tbl2( ln_dis_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Add Start */
             gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid          := gt_sales_norm_tbl2( ln_dis_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
          END IF;
        END IF;
--
--
/* 2009/10/02 Ver1.24 Mod Start */
--        -- ���z�̐ݒ�
--        ln_amount        := gt_sales_norm_tbl2( dis_sum_idx ).pure_amount;
--        ln_tax           := gt_sales_norm_tbl2( dis_sum_idx ).tax_amount;
        -- ���z�̐ݒ�
        gn_amount_ar  := gt_sales_norm_tbl( dis_sum_idx ).pure_amount;
        gn_tax_ar     := gt_sales_norm_tbl( dis_sum_idx ).tax_amount;
/* 2009/10/02 Ver1.24 Mod End   */
      END IF;                                             -- �W��L�[����AR��v�z��OIF�f�[�^�̏W��I��
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- �W��L�[�̃��Z�b�g
--      lt_invoice_number   := gt_sales_norm_tbl2( dis_sum_idx ).dlv_invoice_number;
--      lt_item_code        := gt_sales_norm_tbl2( dis_sum_idx ).item_code;
--      lt_prod_cls         := gt_sales_norm_tbl2( dis_sum_idx ).goods_prod_cls;
--      lt_gyotai_sho       := gt_sales_norm_tbl2( dis_sum_idx ).cust_gyotai_sho;
--      lt_card_sale_class  := gt_sales_norm_tbl2( dis_sum_idx ).card_sale_class;
--      lt_tax_code         := gt_sales_norm_tbl2( dis_sum_idx ).tax_code;
--      lt_invoice_class    := gt_sales_norm_tbl2( dis_sum_idx ).dlv_invoice_class;
--      lt_red_black_flag   := gt_sales_norm_tbl2( dis_sum_idx ).red_black_flag;
--      lt_header_id        := gt_sales_norm_tbl2( dis_sum_idx ).sales_exp_header_id;
--
      --�����R�[�h���C���T�[�g�p�z��ɐݒ肷��
      gt_sales_norm_tbl2( ln_dis_idx ) := gt_sales_norm_tbl( dis_sum_idx );
      -- �W��L�[�̃��Z�b�g
      gt_invoice_number_ar_brk   := gt_sales_norm_tbl( dis_sum_idx ).dlv_invoice_number;
      gt_item_code_ar_brk        := gt_sales_norm_tbl( dis_sum_idx ).item_code;
      gt_prod_cls_ar_brk         := gt_sales_norm_tbl( dis_sum_idx ).goods_prod_cls;
      gt_gyotai_sho_ar_brk       := gt_sales_norm_tbl( dis_sum_idx ).cust_gyotai_sho;
      gt_card_sale_class_ar_brk  := gt_sales_norm_tbl( dis_sum_idx ).card_sale_class;
      gt_tax_code_ar_brk         := gt_sales_norm_tbl( dis_sum_idx ).tax_code;
      gt_invoice_class_ar_brk    := gt_sales_norm_tbl( dis_sum_idx ).dlv_invoice_class;
      gt_red_black_flag_ar_brk   := gt_sales_norm_tbl( dis_sum_idx ).red_black_flag;
      gt_header_id_ar_brk        := gt_sales_norm_tbl( dis_sum_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--    END LOOP gt_sales_norm_tbl2_loop;                      -- AR��v�z���W��f�[�^���[�v�I��
    END LOOP gt_sales_norm_tbl_loop;                      -- AR��v�z���W��f�[�^���[�v�I��
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Add Start */
    -- �����BULK�����ׁ̈A���[�v�I�����_�̃C���T�[�g�p�ϐ���ێ�
    gt_sales_dis_tbl_brk( ln_dis_idx ) := gt_sales_norm_tbl2( ln_dis_idx );
--
/* 2009/10/02 Ver1.24 Add End   */
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
/* 2009/10/02 Ver1.24 Del Start */
--    WHEN non_jour_cls_expt THEN
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
/* 2009/10/02 Ver1.24 Del End   */
--
    WHEN non_ccid_expt THEN
/* 2009/10/02 Ver1.24 Del Start */
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
/* 2009/10/02 Ver1.24 Del Start */
--      -- �J�[�\���N���[�Y
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
/* 2009/10/02 Ver1.24 Del Start */
--      -- �J�[�\���N���[�Y
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
/* 2009/10/02 Ver1.24 Del Start */
--      -- �J�[�\���N���[�Y
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END edit_dis_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_sum_bulk_data
   * Description      : ��������W�񏈗��i���ʔ̓X�j(A-5)
   ***********************************************************************************/
  PROCEDURE edit_sum_bulk_data(
      ov_errbuf         OUT VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_sum_bulk_data';          -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);               -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    cv_pad_char             CONSTANT VARCHAR2(1) := '0';     -- PAD�֐��Ŗ��ߍ��ޕ���
/* 2009/11/05 Ver1.26 Mod Start */
--    cn_pad_num_char         CONSTANT NUMBER := 3;            -- PAD�֐��Ŗ��ߍ��ޕ�����
    cn_pad_num_char         CONSTANT NUMBER := 2;            -- PAD�֐��Ŗ��ߍ��ޕ�����
/* 2009/11/05 Ver1.26 Mod End   */
--
    -- *** ���[�J���ϐ� ***
/* 2009/10/02 Ver1.24 Mod Start */
--    ln_sale_bulk_idx2       NUMBER DEFAULT 0;           -- ���������J�[�h���R�[�h�̃C���f�b�N�X
--    ln_card_pt              NUMBER DEFAULT 1;           -- �J�[�h���R�[�h�̃C���f�b�N�X���s�ʒu
/* 2009/10/02 Ver1.24 Mod End   */
    ln_ar_idx               NUMBER DEFAULT 0;           -- �������OIF�C���f�b�N�X
/* 2009/10/02 Ver1.24 Mod Start */
--    ln_trx_idx              NUMBER DEFAULT 0;           -- AR�z��OIF�W��f�[�^�C���f�b�N�X;
    ln_trx_idx              NUMBER DEFAULT 1;           -- AR�z��OIF�W��f�[�^�C���f�b�N�X;
/* 2009/10/02 Ver1.24 Mod End   */
    lv_trx_type_nm          VARCHAR2(30);               -- ����^�C�v����
    lv_trx_idx              VARCHAR2(30);               -- ����^�C�v(�C���f�b�N�X)
    lv_item_idx             VARCHAR2(30);               -- �i�ږ��דE�v(�C���f�b�N�X)
    lv_item_desp            VARCHAR2(30);               -- �i�ږ��דE�v(TAX�ȊO)
    ln_term_id              VARCHAR2(30);               -- �x������ID
/* 2009/10/02 Ver1.24 Del Start */
--    lv_cust_gyotai_sho      VARCHAR2(30);               -- �Ƒԏ�����
--    ln_pure_amount          NUMBER DEFAULT 0;           -- �J�[�h���R�[�h�̖{�̋��z
--    ln_tax_amount           NUMBER DEFAULT 0;           -- �J�[�h���R�[�h�̏���ŋ��z
--    ln_tax                  NUMBER DEFAULT 0;           -- �W������ŋ��z
--    ln_amount               NUMBER DEFAULT 0;           -- �W�����z
--    ln_trx_number_id        NUMBER;                     -- �������DFF3�p:�����̔Ԕԍ�
--    ln_trx_number_tax_id    NUMBER;                     -- �������DFF3�p�ŋ��p:�����̔Ԕԍ�
/* 2009/10/02 Ver1.24 Del End   */
    lv_trx_sent_dv          VARCHAR2(30);               -- ���������s�敪
/* 2009/10/02 Ver1.24 Del Start */
--    lv_trx_number           VARCHAR2(20);               -- AR����ԍ�
/* 2009/10/02 Ver1.24 Del End   */
    ln_trx_number_large     NUMBER;                    -- ����ԍ�:�����̔�
/* 2009/10/02 Ver1.24 Del Start */
--    ln_sales_h_tbl_idx      NUMBER DEFAULT 0;           -- �̔����уw�b�_�X�V�p�C���f�b�N�X
--    ln_key_trx_number       VARCHAR2(20);               -- ���No
--    ln_key_dff4             VARCHAR2(100);              -- DFF4
--    ln_key_ship_customer_id NUMBER;                     -- �o�א�ڋqID
--    ln_start_index          NUMBER DEFAULT 1;           -- ���No���̊J�n�ʒu
--    ln_ship_flg             NUMBER DEFAULT 0;           -- �o�א�ڋq�t���O
--    ln_term_amount          NUMBER DEFAULT 0;           -- �ꎞ���z
--    ln_max_amount           NUMBER DEFAULT 0;           -- �ő���z
--
--    -- *** ���NO�擾�L�[
--      -- �쐬�敪
--    lt_create_class         xxcos_sales_exp_headers.create_class%TYPE;
--      -- �[�i�`�[�ԍ�
--    lt_invoice_number       xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
--      -- �[�i�`�[�敪
--    lt_invoice_class        xxcos_sales_exp_headers.dlv_invoice_class%TYPE;
--      -- ������ڋq
--    lt_xchv_cust_id_b       xxcos_cust_hierarchy_v.bill_account_id%TYPE;
--      -- ����v���
--    lt_sales_date           xxcos_sales_exp_headers.inspect_date%TYPE;
--
--    -- *** �W��L�[(�̔�����)
--      -- �̔����уw�b�_ID
--    lt_header_id            xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
--      -- AR����ԍ�
--    lt_trx_number           VARCHAR2(20);
--     --�J�[�h����敪
--    lt_cash_sale_cls        xxcos_sales_exp_headers.card_sale_class%TYPE;
--
--    lv_sum_flag             VARCHAR2(1);                -- �W��t���O
--    lv_sum_card_flag        VARCHAR2(1);                -- �J�[�h�W��t���O
/* 2009/10/02 Ver1.24 Del End   */
/* 2009/11/05 Ver1.26 Del Start */
--    lv_employee_name        VARCHAR2(100);              -- �`�[���͎�
/* 2009/11/05 Ver1.26 Del End   */
/* 2009/10/02 Ver1.24 Del Start */
--    lv_idx_key              VARCHAR2(300);              -- PL/SQL�\�\�[�g�p�C���f�b�N�X������
--    ln_now_index            VARCHAR2(300);
--    ln_first_index          VARCHAR2(300);
--    ln_smb_idx              NUMBER DEFAULT 0;           -- ���������C���f�b�N�X
/* 2009/10/02 Ver1.24 Del End   */
    lv_tbl_nm               VARCHAR2(100);              -- �]�ƈ��}�X�^
    lv_employee_nm          VARCHAR2(100);              -- �]�ƈ�
    lv_header_id_nm         VARCHAR2(100);              -- �w�b�_ID
    lv_order_no_nm          VARCHAR2(100);              -- �`�[�ԍ�
    lv_key_info             VARCHAR2(100);              -- �`�[�ԍ�
/* 2009/10/02 Ver1.24 Del Start */
--      -- �i�ڋ敪
--    lt_goods_prod_class     xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
/* 2009/10/02 Ver1.24 Del End   */
    lv_err_flag             VARCHAR2(1);                -- �G���[�p�t���O
    ln_skip_idx             NUMBER DEFAULT 0;           -- �X�L�b�v�p�C���f�b�N�X;
/* 2009/10/02 Ver1.24 Del Start */
--    lt_goods_item_code      xxcos_sales_exp_lines.item_code%TYPE;
--    lt_item_code            xxcos_sales_exp_lines.item_code%TYPE;
--    lt_prod_cls             xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
/* 2009/10/02 Ver1.24 Del End   */
    lt_inspect_date         xxcos_sales_exp_headers.inspect_date%TYPE;          -- ������
/* 2009/10/27 Ver1.25 Add Start */
    lt_spot_term_id         ra_terms_tl.term_id%TYPE;   -- �x������ID(����)
    lv_term_chk_flag        VARCHAR2(1);                -- �x�������`�F�b�N���s�t���O
/* 2009/10/27 Ver1.25 Add End   */
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\ ***
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
/* 2009/10/02 Ver1.24 Del Start */
--    --=====================================================================
--    -- �W�v�O�f�[�^�W�J
--    --=====================================================================
--
--    --�e�[�u���\�[������
--    -- ����f�[�^�݂̂�PL/SQL�\�쐬
--    <<loop_make_sort_data>>
--    FOR i IN 1..gt_sales_bulk_tbl.COUNT LOOP
--      --�\�[�g�L�[�͔̔����уw�b�_ID�A�J�[�h����敪�A�̔����і���ID
--      lv_idx_key := gt_sales_bulk_tbl(i).sales_exp_header_id
--                    || gt_sales_bulk_tbl(i).dlv_invoice_number
--                    || gt_sales_bulk_tbl(i).dlv_invoice_class
--                    || gt_sales_bulk_tbl(i).card_sale_class
--                    || gt_sales_bulk_tbl(i).cust_gyotai_sho
--                    || gt_sales_bulk_tbl(i).goods_prod_cls
--                    || gt_sales_bulk_tbl(i).item_code
--                    || gt_sales_bulk_tbl(i).red_black_flag
--                    || gt_sales_bulk_tbl(i).line_id;
--      gt_sales_bulk_order_tbl(lv_idx_key) := gt_sales_bulk_tbl(i);
--    END LOOP loop_make_sort_data;
--
--    IF gt_sales_bulk_order_tbl.COUNT = 0 THEN
--      RETURN;
--    END IF;
--
--    ln_first_index := gt_sales_bulk_order_tbl.first;
--    ln_now_index := ln_first_index;
--
--    WHILE ln_now_index IS NOT NULL LOOP
--
--      ln_smb_idx := ln_smb_idx + 1;
--      gt_sales_bulk_tbl2(ln_smb_idx) := gt_sales_bulk_order_tbl(ln_now_index);
--      -- ���̃C���f�b�N�X���擾����
--      ln_now_index := gt_sales_bulk_order_tbl.next(ln_now_index);
--
--    END LOOP;--�\�[�g����
--
--    -- ��������e�[�u���̔���ʔ̓X�f�[�^�J�E���g�Z�b�g
--    ln_ar_idx := gt_ar_interface_tbl.COUNT;
/* 2009/10/02 Ver1.24 Del End   */
--
    --�X�L�b�v�J�E���g�Z�b�g
    ln_skip_idx := gt_sales_skip_tbl.COUNT;
--
/* 2009/10/02 Ver1.24 Mod Start */
--    <<gt_sales_bulk_tbl2_loop>>
--    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl2.COUNT LOOP
--
--
--      -- AR����ԍ��̎����̔�
--      IF (  NVL( lt_create_class, 'X' )        <> gt_sales_bulk_tbl2( sale_bulk_idx ).create_class        -- �쐬���敪
--         OR lt_sales_date                      <> gt_sales_bulk_tbl2( sale_bulk_idx ).inspect_date  -- ����v���
--         OR NVL( lt_invoice_class, 'X' )       <> NVL( gt_sales_bulk_tbl2( sale_bulk_idx ).dlv_invoice_class, 'X' )   -- �[�i�`�[�敪
--         OR lt_xchv_cust_id_b                  <> gt_sales_bulk_tbl2( sale_bulk_idx ).xchv_cust_id_b      -- ������ڋq
--         OR (  ( gt_fvd_xiaoka                 =  gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho      -- �t���T�[�r�X�i�����jVD :24
--               OR gt_gyotai_fvd                =  gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho )    -- �t���T�[�r�X VD :25
--             AND ( lt_header_id                 <> gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id  -- �̔����уw�b�_ID
--             OR NVL( lt_cash_sale_cls, 'X' ) <> gt_sales_bulk_tbl2( sale_bulk_idx ).card_sale_class ) )   --�J�[�h����敪
--         )
--
    <<gt_sales_bulk_tbl_loop>>
    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl.COUNT LOOP
--
      -- AR����ԍ��̎����̔�
/* 2009/11/05 Ver1.26 Mod Start */
--      IF (  NVL( gt_create_class_brk, 'X' )     <> gt_sales_bulk_tbl( sale_bulk_idx ).create_class   -- �쐬���敪
--         OR gt_sales_date_brk                   <> gt_sales_bulk_tbl( sale_bulk_idx ).inspect_date   -- ����v���
      IF (  gt_sales_date_brk                   <> gt_sales_bulk_tbl( sale_bulk_idx ).inspect_date   -- ����v���
/* 2009/11/05 Ver1.26 Mod End   */
         OR NVL( gt_invoice_class_brk, 'X' )    <> NVL( gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_class, 'X' )   -- �[�i�`�[�敪
/* 2009/11/05 Ver1.26 Mod Start */
--         OR gt_xchv_cust_id_b_brk               <> gt_sales_bulk_tbl( sale_bulk_idx ).xchv_cust_id_b      -- ������ڋq
         OR (
              (    gt_xchv_cust_id_b_brk        <> gt_sales_bulk_tbl( sale_bulk_idx ).xchv_cust_id_b   -- ������ڋq
                OR gt_pay_cust_number_brk       <> gt_sales_bulk_tbl( sale_bulk_idx ).pay_cust_number  -- �x��������ڋq
              )
            )  --�����悪�قȂ邩�A�J�[�h��Ђ��قȂ�ꍇ
/* 2009/11/05 Ver1.26 Mod End   */
         OR (
              (    gt_fvd_xiaoka    =  gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho   -- �t���T�[�r�X�i�����jVD :24
                OR gt_gyotai_fvd    =  gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho   -- �t���T�[�r�X VD :25
              )
              AND
/* 2009/11/05 Ver1.26 Mod Start */
--              (    gt_header_id_brk                 <> gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id  -- �̔����уw�b�_ID
--                OR NVL( gt_cash_sale_cls_brk, 'X' ) <> gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class      -- �J�[�h����敪
              (
                NVL( gt_cash_sale_cls_brk, 'X' ) <> gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class      -- �J�[�h����敪
/* 2009/11/05 Ver1.26 Mod End   */
              )
            )
         )
      THEN
/* 2009/10/02 Ver1.24 Mod End   */
--
        BEGIN
          SELECT
            xxcos_trx_number_large_s01.NEXTVAL
          INTO
            ln_trx_number_large
          FROM
            dual
          ;
        END;
--
        -- AR����ԍ��̕ҏW ����v���(YYYYMMDD�F8��) + ������ڋq�ԍ�(9��)�{�[�i�`�[�敪(1��)�{�V�[�P���X2��
/* 2009/10/02 Ver1.24 Mod Start */
--        lv_trx_number := TO_CHAR( gt_sales_bulk_tbl2( sale_bulk_idx ).inspect_date,cv_date_format_non_sep )
        gv_trx_number := TO_CHAR( gt_sales_bulk_tbl( sale_bulk_idx ).inspect_date, cv_date_format_non_sep )
/* 2009/10/02 Ver1.24 Mod End   */
                           || gt_sales_bulk_tbl( sale_bulk_idx ).xchv_cust_number_b
/* 2009/11/05 Ver1.26 Add Start */
                           || gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_class
/* 2009/11/05 Ver1.26 Add End   */
                           || LPAD( TO_CHAR( ln_trx_number_large )
                                            ,cn_pad_num_char
                                            ,cv_pad_char
                                           );
--
      END IF;
--
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- �[�i�`�[�ԍ��{�V�[�P���X�̍̔�
--      IF (  NVL(  lt_trx_number, 'X' )    <> lv_trx_number                                            -- AR����ԍ�
--         OR  lt_header_id                 <> gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id   -- �̔����уw�b�_ID
--         )
      -- �[�i�`�[�ԍ��{�V�[�P���X�̍̔�
      IF (  NVL(  gv_trx_number_brk, 'X' )  <> gv_trx_number                                            -- AR����ԍ�
         OR  gt_header_id_brk               <> gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id   -- �̔����уw�b�_ID
         )
/* 2009/10/02 Ver1.24 Mod End   */
      THEN
          -- �������DFF4�p:�����̔Ԕԍ�
        BEGIN
--
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
/* 2009/10/02 Ver1.24 Mod Start */
--            ln_trx_number_id
            gn_trx_number_id
/* 2009/10/02 Ver1.24 Mod End   */
          FROM
            dual
          ;
        END;
--
        BEGIN
--
          SELECT
            xxcos_trx_number_s01.NEXTVAL
          INTO
/* 2009/10/02 Ver1.24 Mod Start */
--            ln_trx_number_tax_id
            gn_trx_number_tax_id
/* 2009/10/02 Ver1.24 Mod End   */
          FROM
            dual
          ;
        END;
      END IF;
--
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- ����ԍ��L�[
--      lt_invoice_class    := gt_sales_bulk_tbl2( sale_bulk_idx ).dlv_invoice_class;
--      lt_create_class     := gt_sales_bulk_tbl2( sale_bulk_idx ).create_class;
--      lt_sales_date       := gt_sales_bulk_tbl2( sale_bulk_idx ).inspect_date;
--      lt_xchv_cust_id_b   := gt_sales_bulk_tbl2( sale_bulk_idx ).xchv_cust_id_b;
--      lt_cash_sale_cls    := gt_sales_bulk_tbl2( sale_bulk_idx ).card_sale_class;
--
--
--      -- �[�i�`�[�ԍ��{�V�[�P���X�̍̔Ԃ̏W��L�[�̒l�Z�b�g
--      lt_trx_number       := lv_trx_number;
--      lt_header_id        := gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id;
--
--
--        -- AR����ԍ�
--      gt_sales_bulk_tbl2( sale_bulk_idx ).oif_trx_number   := lv_trx_number;
--        -- DFF4
--      gt_sales_bulk_tbl2( sale_bulk_idx ).oif_dff4         := gt_sales_bulk_tbl2( sale_bulk_idx ).dlv_invoice_number
--                                                                  || TO_CHAR( ln_trx_number_id );
--      gt_sales_bulk_tbl2( sale_bulk_idx ).oif_tax_dff4     := gt_sales_bulk_tbl2( sale_bulk_idx ).dlv_invoice_number
--                                                                    || TO_CHAR( ln_trx_number_tax_id );
--
--        -- �Ƒԏ����ނ̕ҏW
--      IF ( gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
--        AND gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho <> gt_gyotai_fvd) THEN
--
--          gt_sales_bulk_tbl2( sale_bulk_idx ).cust_gyotai_sho := cv_nvd;                 -- VD�ȊO�̋ƑԁE�[�iVD
--
--      END IF;
--
--    END LOOP gt_sales_bulk_tbl2_loop;
--
      -- ����ԍ��L�[
      gt_invoice_class_brk    := gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_class;
/* 2009/11/05 Ver1.26 Del Start */
--      gt_create_class_brk     := gt_sales_bulk_tbl( sale_bulk_idx ).create_class;
/* 2009/11/05 Ver1.26 Del End   */
      gt_sales_date_brk       := gt_sales_bulk_tbl( sale_bulk_idx ).inspect_date;
      gt_xchv_cust_id_b_brk   := gt_sales_bulk_tbl( sale_bulk_idx ).xchv_cust_id_b;
/* 2009/11/05 Ver1.26 Add Start */
      gt_pay_cust_number_brk  := gt_sales_bulk_tbl( sale_bulk_idx ).pay_cust_number;
/* 2009/11/05 Ver1.26 Add End   */
      gt_cash_sale_cls_brk    := gt_sales_bulk_tbl( sale_bulk_idx ).card_sale_class;
--
      -- �[�i�`�[�ԍ��{�V�[�P���X�̍̔Ԃ̏W��L�[�̒l�Z�b�g
      gv_trx_number_brk       := gv_trx_number;
      gt_header_id_brk        := gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id;
--
      -- AR����ԍ�
      gt_sales_bulk_tbl( sale_bulk_idx ).oif_trx_number   := gv_trx_number;
      -- DFF4
      gt_sales_bulk_tbl( sale_bulk_idx ).oif_dff4         := gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_number
                                                                  || TO_CHAR( gn_trx_number_id );
      -- DFF4�ŋ��p
      gt_sales_bulk_tbl( sale_bulk_idx ).oif_tax_dff4     := gt_sales_bulk_tbl( sale_bulk_idx ).dlv_invoice_number
                                                                  || TO_CHAR( gn_trx_number_tax_id );
--
      -- �Ƒԏ����ނ̕ҏW
      IF (
             gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho <> gt_fvd_xiaoka
         AND gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho <> gt_gyotai_fvd
         )
      THEN
--
          gt_sales_bulk_tbl( sale_bulk_idx ).cust_gyotai_sho := cv_nvd;  -- VD�ȊO�̋ƑԁE�[�iVD
--
      END IF;
--
    END LOOP gt_sales_bulk_tbl_loop;
/* 2009/10/02 Ver1.24 Mod End   */
--
    --=====================================================================
    -- ��������W�񏈗��i���ʔ̓X�j�J�n
    --=====================================================================
/* 2009/10/02 Ver1.24 Mod Start */
--    -- �W��L�[�̒l�Z�b�g
--    lt_trx_number       := gt_sales_bulk_tbl2( 1 ).oif_trx_number;            -- AR����ԍ�
--    lt_header_id        := gt_sales_bulk_tbl2( 1 ).sales_exp_header_id;   -- �̔����уw�b�_ID
--
--    -- ���X�g�f�[�^�o�^�ׂɁA�_�~�[�f�[�^���Z�b�g
--    gt_sales_bulk_tbl2( gt_sales_bulk_tbl2.COUNT + 1 ).sales_exp_header_id
--                        := gt_sales_bulk_tbl2( gt_sales_bulk_tbl2.COUNT ).sales_exp_header_id;
--
--    lt_item_code        := gt_sales_bulk_tbl2( 1 ).item_code;
--    lt_prod_cls         := gt_sales_bulk_tbl2( 1 ).goods_prod_cls;
--
    -- �ŏ���BUKL�����̏ꍇ
    IF ( gn_fetch_first_flag = 0 ) THEN
      -- �W��L�[�̒l�Z�b�g
      gv_trx_number_brk2  := gt_sales_bulk_tbl( 1 ).oif_trx_number;        -- AR����ԍ�
      gt_header_id_brk2   := gt_sales_bulk_tbl( 1 ).sales_exp_header_id;   -- �̔����уw�b�_ID
      gt_item_code_brk2   := gt_sales_bulk_tbl( 1 ).item_code;             -- �i�ڃR�[�h
      gt_prod_cls_brk2    := gt_sales_bulk_tbl( 1 ).goods_prod_cls;        -- ���i�敪
    END IF;
    -- 2��ڈȍ~��BUKL�����̏ꍇ�A�ێ����Ă����O���R�[�h���C���T�[�g�p�ϐ��Ɉڂ�
    IF ( gt_sales_sum_tbl_brk.COUNT <> 0 ) THEN
      gt_sales_bulk_tbl2( ln_trx_idx ) := gt_sales_sum_tbl_brk( ln_trx_idx );
    END IF;
    -- �Ō��BULK�����̍ŏI���R�[�h�̏ꍇ
    IF ( gn_fetch_end_flag = 1 ) THEN
      -- ���X�g�f�[�^�o�^�ׂɁA�_�~�[�f�[�^���Z�b�g(�J�E���g0���l����-1��ݒ�)
      gt_sales_bulk_tbl( gt_sales_bulk_tbl.COUNT + 1 ).sales_exp_header_id
                           := -1;
    END IF;
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--    <<gt_sales_bulk_sum_loop>>
--    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl2.COUNT LOOP
--
--     --=====================================
--     --  �̔����ь��f�[�^�̏W��
--     --=====================================
--     IF (  lt_trx_number   = gt_sales_bulk_tbl2( sale_bulk_idx ).oif_trx_number
--         AND lt_header_id   = gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id
--         )
--      THEN
--
--        -- �W�񂷂�t���O�����ݒ�
--        lv_sum_flag      := cv_y_flag;
--
--        -- �{�̋��z���W�񂷂�
--        ln_amount := ln_amount + gt_sales_bulk_tbl2( sale_bulk_idx ).pure_amount;
--
--       IF ( (
--               (
--                  NVL( lt_prod_cls, 'X' ) = cv_goods_prod_syo
--               OR NVL( lt_prod_cls, 'X' ) = cv_goods_prod_sei
--               )
--             AND
--               NVL( lt_prod_cls, 'X' ) = NVL( gt_sales_bulk_tbl2( sale_bulk_idx ).goods_prod_cls, 'X' )
--             )
--           OR
--             (
--               (
--                   NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_syo
--               AND NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_sei
--               )
--               AND lt_item_code = gt_sales_bulk_tbl2( sale_bulk_idx ).item_code
--             )
--           )THEN
--             ln_term_amount := ln_term_amount + gt_sales_bulk_tbl2( sale_bulk_idx ).pure_amount;
--        ELSIF ( ABS( ln_term_amount ) >= ABS( ln_max_amount ) ) THEN
--             ln_max_amount       := ln_term_amount;
--             ln_term_amount      := gt_sales_bulk_tbl2( sale_bulk_idx ).pure_amount;
--             lt_goods_prod_class := lt_prod_cls;
--             lt_goods_item_code  := lt_item_code;
--        END IF;
--        lt_item_code        := gt_sales_bulk_tbl2( sale_bulk_idx ).item_code;
--        lt_prod_cls         := gt_sales_bulk_tbl2( sale_bulk_idx ).goods_prod_cls;
--
--        -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
--        IF ( gt_sales_bulk_tbl2( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_tax := ln_tax + gt_sales_bulk_tbl2( sale_bulk_idx ).tax_amount;
--        END IF;
--
--      ELSE
--
--        IF ( ABS( ln_term_amount ) >= ABS( ln_max_amount ) ) THEN
--             lt_goods_prod_class := lt_prod_cls;
--             lt_goods_item_code  := lt_item_code;
--        END IF;
--        ln_max_amount       := 0;
--        ln_term_amount      := 0;
--        lt_item_code        := gt_sales_bulk_tbl2( sale_bulk_idx ).item_code;
--        lt_prod_cls         := gt_sales_bulk_tbl2( sale_bulk_idx ).goods_prod_cls;
--
--        lv_sum_flag := cv_n_flag;
--        ln_trx_idx  := sale_bulk_idx - 1;
--      END IF;
--
--      IF ( lv_sum_flag = cv_n_flag ) THEN
--
    <<gt_sales_bulk_sum_loop>>
    FOR sale_bulk_idx IN 1 .. gt_sales_bulk_tbl.COUNT LOOP
--
      -- ���[�v���̏�����
      lv_err_flag := cv_n_flag; --�G���[�t���OOFF
--
      --=====================================
      --  �̔����ь��f�[�^�̏W��
      --=====================================
      IF (   gv_trx_number_brk2  = gt_sales_bulk_tbl( sale_bulk_idx ).oif_trx_number
         AND gt_header_id_brk2   = gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id
         )
      THEN
--
        -- �C���T�[�g�p�̔z���ێ�
        gt_sales_bulk_tbl2( ln_trx_idx ) := gt_sales_bulk_tbl( sale_bulk_idx );
        -- �W�񂷂�t���O�����ݒ�
        gv_sum_flag                      := cv_y_flag;
        -- �{�̋��z���W�񂷂�
        gn_amount                        := gn_amount + gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;
--
        --�i�ږ��דK�p�擾���� ( �قȂ�i�ڋ敪�ō��v���z���ő�̕i�ږ��דK�p���擾 )
        IF (
             (
               (
                  NVL( gt_prod_cls_brk2, 'X' ) = cv_goods_prod_syo
               OR NVL( gt_prod_cls_brk2, 'X' ) = cv_goods_prod_sei
               )
             AND
               NVL( gt_prod_cls_brk2, 'X' ) = NVL( gt_sales_bulk_tbl( sale_bulk_idx ).goods_prod_cls, 'X' )
             )
           OR
             (
               (
                   NVL( gt_prod_cls_brk2, 'X' ) <> cv_goods_prod_syo
               AND NVL( gt_prod_cls_brk2, 'X' ) <> cv_goods_prod_sei
               )
               AND gt_item_code_brk2 = gt_sales_bulk_tbl( sale_bulk_idx ).item_code
             )
           )
        THEN
--
          --�i�ڋ敪�P�ʂ̍��v��ێ�
          gn_term_amount := gn_term_amount + gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;
--
        --�O�̕i�ڋ敪�̍��v��荇�v���z���傫���ꍇ
        ELSIF ( ABS( gn_term_amount ) >= ABS( gn_max_amount ) ) THEN
          gn_max_amount       := gn_term_amount;
          gn_term_amount      := gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;
          gt_goods_prod_class := gt_prod_cls_brk2;
          gt_goods_item_code  := gt_item_code_brk2;
        END IF;
--
        gt_item_code_brk2  := gt_sales_bulk_tbl( sale_bulk_idx ).item_code;
        gt_prod_cls_brk2   := gt_sales_bulk_tbl( sale_bulk_idx ).goods_prod_cls;
--
        -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          gn_tax := gn_tax + gt_sales_bulk_tbl( sale_bulk_idx ).tax_amount;
        END IF;
--
      ELSE
--
        IF ( ABS( gn_term_amount ) >= ABS( gn_max_amount ) ) THEN
          gt_goods_prod_class := gt_prod_cls_brk2;
          gt_goods_item_code  := gt_item_code_brk2;
        END IF;
        gn_max_amount       := 0;
/* 2009/11/05 Ver1.26 Mod Start */
--        gn_term_amount      := 0;
        gn_term_amount      := gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;
/* 2009/11/05 Ver1.26 Mod End   */
        gt_item_code_brk2   := gt_sales_bulk_tbl( sale_bulk_idx ).item_code;
        gt_prod_cls_brk2    := gt_sales_bulk_tbl( sale_bulk_idx ).goods_prod_cls;
        gv_sum_flag         := cv_n_flag;
--
      END IF;
--
      IF ( gv_sum_flag = cv_n_flag ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Del Start */
--        --�G���[�t���OOFF
--        lv_err_flag := cv_n_flag;
/* 2009/10/02 Ver1.24 Del End   */
        lt_inspect_date := gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date;
/* 2009/10/27 Ver1.25 Add Start */
        lt_spot_term_id  := NULL;
        --=====================================================================
        -- �O�D�x������ID�i�����j�̎擾
        --=====================================================================
        BEGIN
          SELECT /*+
                    INDEX(rtv0.t ra_terms_tl_n1)
                 */
                 rtv0.term_id     --�����̎x������ID
          INTO   lt_spot_term_id
          FROM   ra_terms_vl rtv0
          WHERE  rtv0.term_id IN (
                   gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id
                  ,gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id2
                  ,gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id3
                 )
          AND    rtv0.name    = gt_spot_payment_code                                     -- ����
          AND    lt_inspect_date  BETWEEN NVL( rtv0.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                  AND     NVL( rtv0.end_date_active  , lt_inspect_date )
          AND    ROWNUM       = 1;
--
          lv_term_chk_flag := cv_n_flag;   --�����̎x�����������݂���̂Ŏx������ID�̎擾�͎��s���Ȃ�
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_term_chk_flag := cv_y_flag; --�����̎x���������擾�ł��Ȃ��ꍇ�A�x������ID�̎擾�����s
        END;
/* 2009/10/27 Ver1.25 Add End   */
        --=====================================================================
        -- �P�D�x������ID�̎擾
        --=====================================================================
/* 2009/10/27 Ver1.25 Add Start */
        --�x�������ɑ������܂܂�Ȃ��ꍇ
        IF ( lv_term_chk_flag = cv_y_flag ) THEN
--
/* 2009/10/27 Ver1.25 Add End   */
          BEGIN
--
            SELECT term_id
            INTO   ln_term_id
            FROM
              ( SELECT term_id
                      ,cutoff_date
                FROM
                  ( --****�x�������P�i�����j
                     SELECT rtv11.term_id
                           ,CASE WHEN rtv11.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date ) ) -- �x����-1>����
                                   THEN  LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date )  -- �[�i���̖���
                                   ELSE  DECODE( rtv11.due_cutoff_day -1, 0
                                                  -- �����t0���̏ꍇ�A�[�i���̑O���������擾
                                                 ,TO_DATE( TO_CHAR( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                                    cn_min_day, cv_date_format_on_sep ) -1
                                                  -- �w�����-1�����擾
                                                 ,TO_DATE( TO_CHAR  ( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                           TO_NUMBER( rtv11.due_cutoff_day -1 ), cv_date_format_on_sep
                                                         )
                                               )
                            END cutoff_date
                     FROM   ra_terms_vl      rtv11                           -- �x�������}�X�^
                     WHERE  lt_inspect_date   BETWEEN NVL( rtv11.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                                  AND NVL( rtv11.end_date_active  , lt_inspect_date )
                       AND  rtv11.due_cutoff_day IS NOT NULL                                         -- ���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
                       AND  rtv11.term_id = gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id         -- �ڋq�K�w�r���[�̎x�������P
                       AND  ROWNUM = 1
--
                    UNION ALL
--
                     --****�x�������P�i�����j
                     SELECT rtv12.term_id
                           ,CASE WHEN rtv12.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ) ) ) -- �x����-1>����
                                   THEN  LAST_DAY(ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ) ) -- �[�i�����̖���
                                   ELSE  DECODE( rtv12.due_cutoff_day -1 ,0
                                                  -- �����t0���̏ꍇ�A�[�i���̖���
                                                 ,LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date )
                                                  -- �w�����-1�����擾
                                                 ,TO_DATE( TO_CHAR( ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ),
                                                                    cv_date_format_yyyymm ) || TO_NUMBER( rtv12.due_cutoff_day -1 )
                                                                    , cv_date_format_on_sep
                                                         )
                                               )
                            END cutoff_date
                     FROM   ra_terms_vl      rtv12           -- �x�������}�X�^
                     WHERE  lt_inspect_date   BETWEEN NVL( rtv12.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                                  AND NVL( rtv12.end_date_active  , lt_inspect_date )
                       AND  rtv12.due_cutoff_day IS NOT NULL                                         -- ���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
                       AND  rtv12.term_id = gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id         -- �ڋq�K�w�r���[�̎x�������P
                       AND  ROWNUM = 1
--
                    UNION ALL
--
                    --****�x�������Q�i�����j
                     SELECT rtv21.term_id
                           ,CASE WHEN rtv21.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date ) ) -- �x����-1>����
                                   THEN  LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date )  -- �[�i���̖���
                                   ELSE  DECODE( rtv21.due_cutoff_day -1, 0
                                                  -- �����t0���̏ꍇ�A�[�i���̑O���������擾
                                                 ,TO_DATE( TO_CHAR( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                                    cn_min_day, cv_date_format_on_sep ) -1
                                                  -- �w�����-1�����擾
                                                 ,TO_DATE( TO_CHAR  ( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                           TO_NUMBER( rtv21.due_cutoff_day -1 )
                                                           , cv_date_format_on_sep
                                                         )
                                               )
                            END cutoff_date
                     FROM   ra_terms_vl      rtv21           -- �x�������}�X�^
                     WHERE  lt_inspect_date   BETWEEN NVL( rtv21.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                                  AND NVL( rtv21.end_date_active  , lt_inspect_date )
                       AND  rtv21.due_cutoff_day IS NOT NULL                                         -- ���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
                       AND  rtv21.term_id = gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id2        -- �ڋq�K�w�r���[�̎x�������Q
                       AND  ROWNUM = 1
--
                    UNION ALL
--
                    --****�x�������Q�i�����j
                     SELECT rtv22.term_id
                           ,CASE WHEN rtv22.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ) ) ) -- �x����-1>����
                                   THEN  LAST_DAY(ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ) ) -- �[�i�����̖���
                                   ELSE  DECODE( rtv22.due_cutoff_day -1 ,0
                                                  -- �����t0���̏ꍇ�A�[�i���̖���
                                                 ,LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date )
                                                  -- �w�����-1�����擾
                                                 ,TO_DATE( TO_CHAR( ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ),
                                                                    cv_date_format_yyyymm ) || TO_NUMBER( rtv22.due_cutoff_day -1 )
                                                                    , cv_date_format_on_sep
                                                         )
                                               )
                            END cutoff_date
                     FROM   ra_terms_vl      rtv22           -- �x�������}�X�^
                     WHERE  lt_inspect_date   BETWEEN NVL( rtv22.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                                  AND NVL( rtv22.end_date_active  , lt_inspect_date )
                       AND  rtv22.due_cutoff_day IS NOT NULL                                         -- ���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
                       AND  rtv22.term_id = gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id2        -- �ڋq�K�w�r���[�̎x�������Q
                       AND  ROWNUM = 1
--
                    UNION ALL
--
                    --****�x�������R�i�����j
                     SELECT rtv31.term_id
                           ,CASE WHEN rtv31.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date ) ) -- �x����-1>����
                                   THEN  LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date )  -- �[�i���̖���
                                   ELSE  DECODE( rtv31.due_cutoff_day -1, 0
                                                  -- �����t0���̏ꍇ�A�[�i���̑O���������擾
                                                 ,TO_DATE( TO_CHAR( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                                    cn_min_day, cv_date_format_on_sep ) -1
                                                  -- �w�����-1�����擾
                                                 ,TO_DATE( TO_CHAR  ( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, cv_date_format_yyyymm ) ||
                                                           TO_NUMBER( rtv31.due_cutoff_day -1 )
                                                           , cv_date_format_on_sep
                                                         )
                                               )
                            END cutoff_date
                     FROM   ra_terms_vl      rtv31           -- �x�������}�X�^
                     WHERE  lt_inspect_date   BETWEEN NVL( rtv31.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                                  AND NVL( rtv31.end_date_active  , lt_inspect_date )
                       AND  rtv31.due_cutoff_day IS NOT NULL                                         -- ���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
                       AND  rtv31.term_id = gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id3        -- �ڋq�K�w�r���[�̎x�������R
                       AND  ROWNUM = 1
--
                    UNION ALL
--
                    --****�x�������R�i�����j
                     SELECT rtv32.term_id
                           ,CASE WHEN rtv32.due_cutoff_day -1 >= EXTRACT( DAY FROM LAST_DAY( ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ) ) ) -- �x����-1>����
                                   THEN  LAST_DAY(ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ) ) -- �[�i�����̖���
                                   ELSE  DECODE( rtv32.due_cutoff_day -1 ,0
                                                  -- �����t0���̏ꍇ�A�[�i���̖���
                                                 ,LAST_DAY( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date )
                                                  -- �w�����-1�����擾
                                                 ,TO_DATE( TO_CHAR( ADD_MONTHS( gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date, 1 ),
                                                                    cv_date_format_yyyymm ) || TO_NUMBER( rtv32.due_cutoff_day -1 )
                                                                    , cv_date_format_on_sep
                                                         )
                                               )
                            END cutoff_date
                     FROM   ra_terms_vl      rtv32           -- �x�������}�X�^
                     WHERE  lt_inspect_date  BETWEEN NVL( rtv32.start_date_active, lt_inspect_date ) -- ���������_�ŗL��
                                                 AND NVL( rtv32.end_date_active  , lt_inspect_date )
                       AND  rtv32.due_cutoff_day IS NOT NULL                                         -- ���J�n��or�ŏI�����t�����ݒ�͑ΏۊO
                       AND  rtv32.term_id = gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id3        -- �ڋq�K�w�r���[�̎x�������R
                       AND  ROWNUM = 1
                  ) rtv
                WHERE TRUNC( rtv.cutoff_date ) >= gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date      -- ������
                ORDER BY rtv.cutoff_date
              )
            WHERE  ROWNUM = 1;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- �x������ID�̎擾���ł��Ȃ��ꍇ
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_term_id_msg
                            , iv_token_name1   => cv_tkn_cust_code
                            , iv_token_value1  => gt_sales_bulk_tbl2( ln_trx_idx ).pay_cust_number
                            , iv_token_name2   => cv_tkn_payment_term1
                            , iv_token_value2  => gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id
                            , iv_token_name3   => cv_tkn_payment_term2
                            , iv_token_value3  => gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id2
                            , iv_token_name4   => cv_tkn_payment_term3
                            , iv_token_value4  => gt_sales_bulk_tbl2( ln_trx_idx ).xchv_bill_pay_id3
                            , iv_token_name5   => cv_tkn_procedure_name
                            , iv_token_value5  => cv_prg_name
                            , iv_token_name6   => cv_tkn_header_id
/* 2009/10/02 Ver1.24 Mod Start */
--                            , iv_token_value6  => lt_header_id
                            , iv_token_value6  => gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
                            , iv_token_name7   => cv_tkn_order_no
                            , iv_token_value7  => gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_number
                          );
              lv_errbuf  := lv_errmsg;
--
              lv_err_flag  := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => cv_blank
              );
--
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => cv_blank
              );
--
          END;
/* 2009/10/27 Ver1.25 Add Start */
        --�x�������ɑ������܂܂��ꍇ
        ELSE
          ln_term_id := lt_spot_term_id;
        END IF;
/* 2009/10/27 Ver1.25 Add End   */
--
        --=====================================================================
        -- �Q�D����^�C�v�̎擾
        --=====================================================================
--
        lv_trx_idx := gt_sales_bulk_tbl2( ln_trx_idx ).create_class
                   || gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_class;
        IF ( gt_sel_trx_type_tbl.EXISTS( lv_trx_idx ) ) THEN
          lv_trx_type_nm := gt_sel_trx_type_tbl( lv_trx_idx ).attribute1;
          lv_trx_sent_dv := gt_sel_trx_type_tbl( lv_trx_idx ).attribute2;
        ELSE
          BEGIN
/* 2009/07/27 Ver1.21 Mod Start */
--            SELECT flvm.attribute1 || flvd.attribute1
            SELECT /*+ USE_NL( flvd ) */
                   flvm.attribute1 || flvd.attribute1
/* 2009/07/27 Ver1.21 Mod End   */
                 , rctt.attribute1
            INTO   lv_trx_type_nm
                 , lv_trx_sent_dv
            FROM   fnd_lookup_values              flvm                     -- �쐬���敪����}�X�^
                 , fnd_lookup_values              flvd                     -- �[�i�`�[�敪����}�X�^
                 , ra_cust_trx_types_all          rctt                     -- ����^�C�v�}�X�^
            WHERE  flvm.lookup_type               = cv_qct_mkorg_cls
              AND  flvd.lookup_type               = cv_qct_dlv_slp_cls
              AND  flvm.lookup_code               LIKE cv_qcc_code
              AND  flvd.lookup_code               LIKE cv_qcc_code
              AND  flvm.meaning                   = gt_sales_bulk_tbl2( ln_trx_idx ).create_class
              AND  flvd.meaning                   = gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_class
              AND  rctt.name                      = flvm.attribute1 || flvd.attribute1
              AND  rctt.org_id                    = gv_mo_org_id
              AND  flvm.enabled_flag              = cv_enabled_yes
              AND  flvd.enabled_flag              = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--              AND  flvm.language                  = USERENV( 'LANG' )
--              AND  flvd.language                  = USERENV( 'LANG' )
              AND  flvm.language                  = ct_lang
              AND  flvd.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
              AND  gd_process_date BETWEEN        NVL( flvm.start_date_active, gd_process_date )
                                   AND            NVL( flvm.end_date_active,   gd_process_date )
              AND  gd_process_date BETWEEN        NVL( flvd.start_date_active, gd_process_date )
                                   AND            NVL( flvd.end_date_active,   gd_process_date );
--
          -- ����^�C�v�擾�o���Ȃ��ꍇ
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_trxtype_err_msg
                            , iv_token_name1   => cv_tkn_lookup_type
                            , iv_token_value1  => cv_qct_mkorg_cls
                                               || cv_and
                                               || cv_qct_dlv_slp_cls
                            , iv_token_name2   => cv_tkn_header_id
/* 2009/10/02 Ver1.24 Mod Start */
--                            , iv_token_value2  => lt_header_id
                            , iv_token_value2  => gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
                            , iv_token_name3   => cv_tkn_order_no
                            , iv_token_value3  => gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_number
                          );
              lv_errbuf  := lv_errmsg;
--
              lv_err_flag  := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- ���b�Z�[�W�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
          END;
--
          -- �擾��������^�C�v�����[�N�e�[�u���ɐݒ肷��
          gt_sel_trx_type_tbl( lv_trx_idx ).attribute1 := lv_trx_type_nm;
          gt_sel_trx_type_tbl( lv_trx_idx ).attribute2 := lv_trx_sent_dv;
--
        END IF;
--
        --=====================================================================
        -- �R�D�i�ږ��דE�v�̎擾(�u�������œ��v�ȊO)
        --=====================================================================
--
        -- �i�ږ��דE�v�̑��݃`�F�b�N-->���݂��Ă���ꍇ�A�擾�K�v���Ȃ�
/* 2009/10/02 Ver1.24 Mod Start */
--        IF ( lt_goods_prod_class IS NULL ) THEN
        IF ( gt_goods_prod_class IS NULL ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
          lv_item_idx := gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_class
/* 2009/10/02 Ver1.24 Mod Start */
--                      || lt_goods_item_code;
                      || gt_goods_item_code;
/* 2009/10/02 Ver1.24 Mod End   */
        ELSE
          lv_item_idx := gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_class
/* 2009/10/02 Ver1.24 Mod Start */
--                      || lt_goods_prod_class;
                      || gt_goods_prod_class;
/* 2009/10/02 Ver1.24 Mod End   */
        END IF;
--
        IF ( gt_sel_item_desp_tbl.EXISTS( lv_item_idx ) ) THEN
          lv_item_desp := gt_sel_item_desp_tbl( lv_item_idx ).description;
        ELSE
          BEGIN
            SELECT flvi.description
            INTO   lv_item_desp
            FROM   fnd_lookup_values              flvi                     -- AR�i�ږ��דE�v����}�X�^
            WHERE  flvi.lookup_type               = cv_qct_item_cls
              AND  flvi.lookup_code               LIKE cv_qcc_code
              AND  flvi.attribute1                = gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_class
/* 2009/10/02 Ver1.24 Mod Start */
--              AND  flvi.attribute2                = NVL( lt_goods_prod_class,
--                                                         lt_goods_item_code )
              AND  flvi.attribute2                = NVL( gt_goods_prod_class,
                                                         gt_goods_item_code )
/* 2009/10/02 Ver1.24 Mod End   */
              AND  flvi.enabled_flag              = cv_enabled_yes
/* 2009/07/27 Ver1.21 Mod Start */
--              AND  flvi.language                  = USERENV( 'LANG' )
              AND  flvi.language                  = ct_lang
/* 2009/07/27 Ver1.21 Mod End   */
              AND  gd_process_date BETWEEN        NVL( flvi.start_date_active, gd_process_date )
                                   AND            NVL( flvi.end_date_active,   gd_process_date );
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- AR�i�ږ��דE�v�擾�o���Ȃ��ꍇ
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_xxcos_short_nm
                            , iv_name          => cv_itemdesp_err_msg
                            , iv_token_name1   => cv_tkn_lookup_type
                            , iv_token_value1  => cv_qct_item_cls
                            , iv_token_name2   => cv_tkn_header_id
/* 2009/10/02 Ver1.24 Mod Start */
--                            , iv_token_value2  => lt_header_id
                            , iv_token_value2  => gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod End   */
                            , iv_token_name3   => cv_tkn_order_no
                            , iv_token_value3  => gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_number
                          );
              lv_errbuf  := lv_errmsg;
--
              lv_err_flag  := cv_y_flag;
              gn_warn_flag := cv_y_flag;
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_errmsg
              );
--
              -- ��s�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => cv_blank
              );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- ���b�Z�[�W�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
          END;
--
          -- �擾����AR�i�ږ��דE�v�����[�N�e�[�u���ɐݒ肷��
          gt_sel_item_desp_tbl( lv_item_idx ).description := lv_item_desp;
--
        END IF;
/* 2009/11/05 Ver1.26 Del Start */
--        --�`�[���͎Ҏ擾
--        BEGIN
--          SELECT fu.user_name
--          INTO   lv_employee_name
--          FROM   fnd_user             fu
--                ,per_all_people_f     papf
--          WHERE  fu.employee_id       = papf.person_id
--/* 2009/07/30 Ver1.21 ADD START */
--/* 2009/08/24 Ver1.23 Mod START */
----            AND  gt_sales_norm_tbl2( ln_trx_idx ).inspect_date
--            AND  gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date
--/* 2009/08/24 Ver1.23 Mod End   */
--                   BETWEEN papf.effective_start_date AND papf.effective_end_date
--/* 2009/07/30 Ver1.21 ADD End   */
--            AND  papf.employee_number = gv_busi_emp_cd;
----
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              -- �`�[���͎Ҏ擾�o���Ȃ��ꍇ
--              lv_tbl_nm :=xxccp_common_pkg.get_msg(
--                              iv_application   => cv_xxcos_short_nm
--                            , iv_name          => cv_tkn_user_msg
--                            );
--
--              lv_employee_nm :=xxccp_common_pkg.get_msg(
--                              iv_application   => cv_xxcos_short_nm
--                            , iv_name          => cv_employee_code_msg
--                            );
--
--              lv_header_id_nm :=xxccp_common_pkg.get_msg(
--                              iv_application   => cv_xxcos_short_nm
--                            , iv_name          => cv_header_id_msg
--                            );
--
--              lv_order_no_nm  :=xxccp_common_pkg.get_msg(
--                              iv_application   => cv_xxcos_short_nm
--                            , iv_name          => cv_order_no_msg
--                            );
--
--              xxcos_common_pkg.makeup_key_info(
--                            iv_item_name1         =>  lv_employee_nm,
--                            iv_data_value1        =>  gv_busi_emp_cd,
--                            iv_item_name2         =>  lv_header_id_nm,
--/* 2009/10/02 Ver1.24 Mod Start */
----                            iv_data_value2        =>  lt_header_id,
--                            iv_data_value2        =>  gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id,
--/* 2009/10/02 Ver1.24 Mod End   */
--                            iv_item_name3         =>  lv_order_no_nm,
--                            iv_data_value3        =>  gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_number,
--                            ov_key_info           =>  lv_key_info,                --�ҏW���ꂽ�L�[���
--                            ov_errbuf             =>  lv_errbuf,                  --�G���[���b�Z�[�W
--                            ov_retcode            =>  lv_retcode,                 --���^�[���R�[�h
--                            ov_errmsg             =>  lv_errmsg                   --���[�U�E�G���[�E���b�Z�[�W
--                          );
----
--              lv_errmsg := xxccp_common_pkg.get_msg(
--                              iv_application   => cv_xxcos_short_nm
--                            , iv_name          => cv_data_get_msg
--                            , iv_token_name1   => cv_tkn_tbl_nm
--                            , iv_token_value1  => lv_tbl_nm
--                            , iv_token_name2   => cv_tkn_key_data
--                            , iv_token_value2  => lv_key_info
--                          );
--              lv_errbuf  := lv_errmsg;
----
--              lv_err_flag  := cv_y_flag;
--              gn_warn_flag := cv_y_flag;
----
--              -- ��s�o��
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => cv_blank
--              );
----
--              -- ���b�Z�[�W�o��
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => lv_errmsg
--              );
----
--              -- ��s�o��
--              FND_FILE.PUT_LINE(
--                 which  => FND_FILE.LOG
--                ,buff   => cv_blank
--              );
----
--               -- ��s�o��
--               FND_FILE.PUT_LINE(
--                  which  => FND_FILE.OUTPUT
--                 ,buff   => cv_blank
--               );
----
--               -- ���b�Z�[�W�o��
--               FND_FILE.PUT_LINE(
--                  which  => FND_FILE.OUTPUT
--                 ,buff   => lv_errmsg
--               );
----
--               -- ��s�o��
--               FND_FILE.PUT_LINE(
--                  which  => FND_FILE.OUTPUT
--                 ,buff   => cv_blank
--               );
----
--        END;
/* 2009/11/05 Ver1.26 Del End */
      END IF;
--
      --�X�L�b�v����
      IF ( lv_err_flag = cv_y_flag ) THEN
         ln_skip_idx := ln_skip_idx + 1;
         gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Add Start */
         gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid          := gt_sales_bulk_tbl2( ln_trx_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
      END IF;
      --==============================================================
      -- �S�DAR�������OIF�f�[�^�쐬
      --==============================================================
--
      -- -- �W��t���O�fN'�̏ꍇ�AAR�������OIF�f�[�^�쐬����
/* 2009/10/02 Ver1.24 Mod Start */
--      IF ( lv_sum_flag = cv_n_flag ) THEN
      IF ( gv_sum_flag = cv_n_flag ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
--
        -- AR�������OIF�̎��v�s
        ln_ar_idx   := ln_ar_idx  + 1;
--
        -- AR�������OIF�f�[�^�쐬(���v�s)===>NO.1
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- ������׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �������DFF1:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_number;
                                                        -- �������DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).oif_dff4;
                                                        -- �������DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �������DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id;
                                                        -- �������DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name  := gv_sales_nm;
                                                        -- ����\�[�X:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- ��v����ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_line;
                                                        -- ���v�s
        gt_ar_interface_tbl( ln_ar_idx ).description    := lv_item_desp;
                                                        -- �i�ږ��דE�v
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- �ʉ�
/* 2009/10/02 Ver1.24 Mod Start */
--        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_amount;
        gt_ar_interface_tbl( ln_ar_idx ).amount         := gn_amount;
/* 2009/10/02 Ver1.24 Mod End   */
                                                        -- ���v�s�F�{�̋��z
        IF ( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          --���Ŏ��A���z�͖{�́{�ŋ�
/* 2009/10/02 Ver1.24 Mod Start */
--          gt_ar_interface_tbl( ln_ar_idx ).amount       := ln_amount + ln_tax;
          gt_ar_interface_tbl( ln_ar_idx ).amount       := gn_amount + gn_tax;
/* 2009/10/02 Ver1.24 Mod End   */
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- ����^�C�v��
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- �x������ID
        IF (  gt_sales_bulk_tbl2( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_bulk_tbl2( ln_trx_idx ).cash_and_card   = 0 ) THEN
        -- �����̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        :=gt_sales_bulk_tbl2( ln_trx_idx ).xchv_cust_id_b;
                                                        -- ������ڋqID
        ELSE
        -- �J�[�h�̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).xchv_cust_id_c;
                                                        -- ������ڋqID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).hcss_org_sys_id;
                                                        -- �o�א�ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).xchv_cust_id_s;
                                                        -- �o�א�ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).rcrm_receipt_id;
                                                        -- �x�����@ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- ���Z�^�C�v:�uUser�v��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- ���Z���[�g:1 ��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date;
                                                        -- �����(���������t):��.������
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_bulk_tbl2( ln_trx_idx ).delivery_date;
                                                        -- GL�L����(�d��v���):��.�[�i��
        gt_ar_interface_tbl( ln_ar_idx ).trx_number     := gt_sales_bulk_tbl2( ln_trx_idx ).oif_trx_number;
                                                        -- ���v�s�̂݁FAR����ԍ�
        gt_ar_interface_tbl( ln_ar_idx ).line_number    := gt_sales_bulk_tbl2( ln_trx_idx ).dlv_inv_line_no;
                                                        -- ���v�s�̂݁FAR������הԍ�
        gt_ar_interface_tbl( ln_ar_idx ).quantity       := cn_quantity;
                                                        -- ���v�s�̂݁F����=1
        gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price
/* 2009/10/02 Ver1.24 Mod Start */
--                                                        := ln_amount;
                                                        := gn_amount;
/* 2009/10/02 Ver1.24 Mod End   */
                                                        -- ���v�s�̂݁F�̔��P��=�{�̋��z
        IF ( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          --���Ŏ��A�̔��P���͖{�́{�ŋ�
/* 2009/10/02 Ver1.24 Mod Start */
--          gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price := ln_amount + ln_tax;
          gt_ar_interface_tbl( ln_ar_idx ).unit_selling_price := gn_amount + gn_tax;
/* 2009/10/02 Ver1.24 Mod End   */
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_bulk_tbl2( ln_trx_idx ).tax_code;
                                                        -- �ŋ��R�[�h(�ŋ敪)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute_category
                                                        := gv_mo_org_id;
                                                        -- �w�b�_�[DFF�J�e�S��
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute5
/* 2009/11/05 Ver1.26 Mod Start */
--                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).sales_base_code;
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).receiv_base_code;
/* 2009/11/05 Ver1.26 Mod End   */
                                                        -- �w�b�_�[dff5(�N�[����)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute6
/* 2009/11/05 Ver1.26 Mod Start */
--                                                        := lv_employee_name;
                                                        := gv_dlv_inp_user;
/* 2009/11/05 Ver1.26 Mod End   */
                                                        -- �w�b�_�[dff6(�`�[���͎�)
        IF( lv_trx_sent_dv = cv_n_flag ) THEN
          gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_hold;
                                                        -- �w�b�_�[DFF7(�\���P)
        ELSIF( lv_trx_sent_dv = cv_y_flag ) THEN
          gt_ar_interface_tbl( ln_ar_idx ).header_attribute7
                                                        := cv_open;
                                                        -- �w�b�_�[DFF7(�\���P)
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute8
                                                        := cv_wait;
                                                        -- �w�b�_�[dff8(�\���Q)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute9
                                                        := cv_wait;
                                                        -- �w�b�_�[dff9(�\��3)
        gt_ar_interface_tbl( ln_ar_idx ).header_attribute11
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).card_receiv_base;
                                                        -- �w�b�_�[DFF11(�������_)
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- �c�ƒP��ID
        IF ( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- ���ł̏ꍇ�A'Y'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- �ō����z�t���O
        ELSIF( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_out_tax_cls 
          OR gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_exp_tax_cls ) THEN
          -- �O�ł̏ꍇ�A'N'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- �ō����z�t���O
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- �쐬��
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- �쐬��
--
        -- AR�������OIF�f�[�^�쐬(�ŋ��s)===>NO.2
        ln_ar_idx := ln_ar_idx + 1;
--
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_context
                                                        := gv_sales_nm;
                                                        -- ������׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �������DFF1:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute3
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).dlv_invoice_number;
                                                        -- �������DFF3
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).oif_tax_dff4;
                                                        -- �������DFF4
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �������DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute7
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id;
                                                        -- �������DFF7
        gt_ar_interface_tbl( ln_ar_idx ).batch_source_name
                                                        := gv_sales_nm;
                                                        -- ����\�[�X:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).set_of_books_id
                                                        := TO_NUMBER ( gv_set_bks_id );
                                                        -- ��v����ID
        gt_ar_interface_tbl( ln_ar_idx ).line_type      := cv_tax;
                                                        -- �ŋ��s
        gt_ar_interface_tbl( ln_ar_idx ).description    := gv_item_tax;
                                                        -- �i�ږ��דE�v
        gt_ar_interface_tbl( ln_ar_idx ).currency_code  := cv_currency_code;
                                                        -- �ʉ�
/* 2009/10/02 Ver1.24 Mod Start */
--        gt_ar_interface_tbl( ln_ar_idx ).amount         := ln_tax;
        gt_ar_interface_tbl( ln_ar_idx ).amount         := gn_tax;
/* 2009/10/02 Ver1.24 Mod Start */
                                                        -- �ŋ��s�F����ŋ��z
        gt_ar_interface_tbl( ln_ar_idx ).cust_trx_type_name
                                                        := lv_trx_type_nm;
                                                        -- ����^�C�v��
        gt_ar_interface_tbl( ln_ar_idx ).term_id        := ln_term_id;
                                                        -- �x������ID
        IF (  gt_sales_bulk_tbl2( ln_trx_idx ).card_sale_class = cv_cash_class
          AND gt_sales_bulk_tbl2( ln_trx_idx ).cash_and_card   = 0 ) THEN
          -- �����̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).hcsb_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).xchv_cust_id_b;
                                                        -- ������ڋqID
        ELSE
        -- �J�[�h�̏ꍇ
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_address_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).hcsc_org_sys_id;
                                                        -- ������ڋq���ݒn�Q��ID
          gt_ar_interface_tbl( ln_ar_idx ).orig_system_bill_customer_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).xchv_cust_id_c;
                                                        -- ������ڋqID
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).hcss_org_sys_id;
                                                        -- �o�א�ڋq���ݒn�Q��ID
        gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).xchv_cust_id_s;
                                                        -- �o�א�ڋqID
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_context
                                                        := gv_sales_nm;
                                                        -- �����N�斾�׃R���e�L�X�g:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute1
                                                        := gv_sales_nm;
                                                        -- �����N�斾��DFF1:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute3
                                                        := gt_ar_interface_tbl( ln_ar_idx - 1 ).interface_line_attribute3;
                                                        -- �����N�斾��DFF3
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4
                                                        := gt_ar_interface_tbl( ln_ar_idx - 1 ).interface_line_attribute4;
                                                        -- �����N�斾��DFF4
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute5
                                                        := gv_sales_nm;
                                                        -- �����N�斾��DFF5:�u�̔����сv��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute7
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).sales_exp_header_id;
                                                        -- �����N�斾��DFF7
        gt_ar_interface_tbl( ln_ar_idx ).receipt_method_id
                                                        := gt_sales_bulk_tbl2( ln_trx_idx ).rcrm_receipt_id;
                                                        -- �x�����@ID
        gt_ar_interface_tbl( ln_ar_idx ).conversion_type
                                                        := cv_user;
                                                        -- ���Z�^�C�v:�uUser�v��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).conversion_rate
                                                        := cn_con_rate;
                                                        -- ���Z���[�g:1 ��ݒ�
        gt_ar_interface_tbl( ln_ar_idx ).trx_date       := gt_sales_bulk_tbl2( ln_trx_idx ).inspect_date;
                                                        -- �����(���������t):��.������
        gt_ar_interface_tbl( ln_ar_idx ).gl_date        := gt_sales_bulk_tbl2( ln_trx_idx ).delivery_date;
                                                        -- GL�L����(�d��v���):��.�[�i��
        gt_ar_interface_tbl( ln_ar_idx ).tax_code       := gt_sales_bulk_tbl2( ln_trx_idx ).tax_code;
                                                        -- �ŋ��R�[�h
        gt_ar_interface_tbl( ln_ar_idx ).org_id         := TO_NUMBER( gv_mo_org_id );
                                                        -- �c�ƒP��ID
        IF ( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_in_tax_cls ) THEN
          -- ���ł̏ꍇ�A'Y'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_y_flag;
                                                        -- �ō����z�t���O
        ELSIF( gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_out_tax_cls 
          OR gt_sales_bulk_tbl2( ln_trx_idx ).tax_code = gt_exp_tax_cls ) THEN
          -- �O�ł̏ꍇ�A'N'��ݒ�
          gt_ar_interface_tbl( ln_ar_idx ).amount_includes_tax_flag
                                                        := cv_n_flag;
                                                        -- �ō����z�t���O
        END IF;
        gt_ar_interface_tbl( ln_ar_idx ).created_by     := cn_created_by;
                                                        -- �쐬��
        gt_ar_interface_tbl( ln_ar_idx ).creation_date  := cd_creation_date;
                                                        -- �쐬��
--
      END IF;
--
/* 2009/10/02 Ver1.24 Mod Start */
--      IF ( lv_sum_flag = cv_n_flag ) THEN
--        -- �W��L�[�ƏW����z�̃��Z�b�g
--        lt_trx_number      := gt_sales_bulk_tbl2( sale_bulk_idx ).oif_trx_number;        -- AR����ԍ�
--        lt_header_id       := gt_sales_bulk_tbl2( sale_bulk_idx ).sales_exp_header_id;   -- �̔����уw�b�_ID
--
--        ln_amount := gt_sales_bulk_tbl2( sale_bulk_idx ).pure_amount;
--        IF ( gt_sales_bulk_tbl2( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_tax  := gt_sales_bulk_tbl2( sale_bulk_idx ).tax_amount;
--        ELSE
--          ln_tax  := 0;
--        END IF;
--
      IF ( gv_sum_flag = cv_n_flag ) THEN
        --�����R�[�h���C���T�[�g�p�z��ɐݒ肷��
        gt_sales_bulk_tbl2( ln_trx_idx ) := gt_sales_bulk_tbl( sale_bulk_idx );
        -- �W��L�[�ƏW����z�̃��Z�b�g
        gv_trx_number_brk2  := gt_sales_bulk_tbl( sale_bulk_idx ).oif_trx_number;        -- AR����ԍ�
        gt_header_id_brk2   := gt_sales_bulk_tbl( sale_bulk_idx ).sales_exp_header_id;   -- �̔����уw�b�_ID
        gn_amount           := gt_sales_bulk_tbl( sale_bulk_idx ).pure_amount;           -- �{�̋��z
        --��ېł̏ꍇ�A����ł�0
        IF ( gt_sales_bulk_tbl( sale_bulk_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          gn_tax  := gt_sales_bulk_tbl( sale_bulk_idx ).tax_amount;
        ELSE
          gn_tax  := 0;
        END IF;
/* 2009/10/02 Ver1.24 Mod End   */
      END IF;
--
    END LOOP gt_sales_bulk_sum_loop;                    -- �̔����уf�[�^���[�v�I��
--
/* 2009/10/02 Ver1.24 Add Start */
    -- �����BULK�����ׁ̈A���[�v�I�����_�̃C���T�[�g�p�ϐ���ێ�
    gt_sales_sum_tbl_brk( ln_trx_idx ) := gt_sales_bulk_tbl2( ln_trx_idx );
/* 2009/10/02 Ver1.24 Add End   */
--
/* 2009/10/02 Ver1.24 Del Start */
--    <<gt_sales_bulk_check_loop>>
--    FOR ln_ar_idx IN 1 .. gt_ar_interface_tbl.COUNT LOOP
--      -- �J�n�F1���No���ł̏o�א�ڋq�`�F�b�N
--
--      -- KEY����������
--      IF (
--           (
--              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number IS NULL )
--              AND
--              ( gt_ar_interface_tbl( ln_ar_idx ).link_to_line_attribute4 <> NVL( ln_key_dff4, 'X') )
--           )
--           OR
--           (
--              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number IS NOT NULL )
--              AND
--              ( gt_ar_interface_tbl( ln_ar_idx ).trx_number <> NVL( ln_key_trx_number, 'X') )
--           )
--         )THEN
--
--        -- �o�א�ڋq�t���O��ON�̏ꍇ
--        IF ( ln_ship_flg = cn_ship_flg_on )
--        THEN
--          <<gt_sales_bulk_ship_clear_loop>>
--          FOR start_index IN ln_start_index .. ln_ar_idx - 1 LOOP
--            -- �J�n�F1���No���ł̏o�א�ڋq�`�F�b�N
--
--            -- �o�א�ڋqID���N���A
--            gt_ar_interface_tbl( start_index ).orig_system_ship_customer_id := NULL;
--            gt_ar_interface_tbl( start_index ).orig_system_ship_address_id  := NULL;
--
--            -- �Ō�̍s
--            IF ( gt_ar_interface_tbl.COUNT = ln_ar_idx )
--            THEN
--              -- �o�א�ڋqID���N���A
--              gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id := NULL;
--              gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_address_id  := NULL;
--            END IF;
--
--            -- �I���F1���No���ł̏o�א�ڋq�`�F�b�N
--          END LOOP gt_sales_bulk_ship_clear_loop;
--        END IF;
--
--        -- ���No���擾
--        ln_key_trx_number := gt_ar_interface_tbl( ln_ar_idx ).trx_number;
--
--        -- DFF4���擾
--        ln_key_dff4 := gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4;
--
--        -- �o�א�ڋqID���擾
--        ln_key_ship_customer_id := gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id;
--
--        -- ���No�̊J�n�ʒu���擾
--        ln_start_index := ln_ar_idx;
--
--        -- �t���O��������
--        ln_ship_flg := cn_ship_flg_off;
--
--      ELSE
--        -- �o�א�ڋq���������H
--        IF ( gt_ar_interface_tbl( ln_ar_idx ).orig_system_ship_customer_id <> ln_key_ship_customer_id ) THEN
--          -- �Ⴄ�ꍇ�A�o�א�ڋq�t���O��ON�ɂ���
--          ln_ship_flg := cn_ship_flg_on;
--
--        END IF;
--        -- DFF4���擾
--        ln_key_dff4 := gt_ar_interface_tbl( ln_ar_idx ).interface_line_attribute4;
--
--        IF ( ln_ship_flg = cn_ship_flg_on AND ln_ar_idx = gt_ar_interface_tbl.COUNT ) THEN
--          <<gt_sales_bulk_ship_clear_loop>>
--          FOR start_index IN ln_start_index .. ln_ar_idx LOOP
--            -- �J�n�F1���No���ł̏o�א�ڋq�`�F�b�N
--
--            -- �o�א�ڋqID���N���A
--            gt_ar_interface_tbl( start_index ).orig_system_ship_customer_id := NULL;
--            gt_ar_interface_tbl( start_index ).orig_system_ship_address_id  := NULL;
--
--            -- �I���F1���No���ł̏o�א�ڋq�`�F�b�N
--          END LOOP gt_sales_bulk_ship_clear_loop;
--        END IF;
--
--      END IF;
--      -- �I���F1���No���ł̏o�א�ڋq�`�F�b�N
--    END LOOP gt_sales_bulk_check_loop;
/* 2009/10/02 Ver1.24 Del End   */
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_no_lookup_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_term_id_expt THEN
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
  END edit_sum_bulk_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_dis_bulk_data
   * Description      : AR��v�z���d��쐬�i���ʔ̓X�j(A-6)
   ***********************************************************************************/
  PROCEDURE edit_dis_bulk_data(
      ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'edit_dis_bulk_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_ccid_idx         VARCHAR2(225);                                   -- �Z�O�����g�P�`�W�̌����iCCID�C���f�b�N�X�p�j
    lv_tbl_nm           VARCHAR2(100);                                   -- ����Ȗڑg�����}�X�^�e�[�u��
    lv_sum_flag         VARCHAR2(1);                                     -- �W��t���O
    lt_ccid             gl_code_combinations.code_combination_id%TYPE;   -- ����Ȗ�CCID
    lt_segment3         fnd_lookup_values.attribute7%TYPE;               -- ����ȖڃR�[�h
--
/* 2009/10/02 Ver1.24 Del Start */
--    -- �W��L�[
--    lt_invoice_number   xxcos_sales_exp_headers.dlv_invoice_number%TYPE; -- �W��L�[�F�[�i�`�[�ԍ�
--    lt_invoice_class    xxcos_sales_exp_headers.dlv_invoice_class%TYPE;  -- �W��L�[�F�[�i�`�[�敪
--    lt_item_code        xxcos_sales_exp_lines.item_code%TYPE;            -- �W��L�[�F�i�ڃR�[�h
--    lt_prod_cls         xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
--                                                                         -- �i�ڋ敪�i���i�E���i�j
--    lt_gyotai_sho       xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;    -- �W��L�[�F�Ƒԏ�����
--    lt_card_sale_class  xxcos_sales_exp_headers.card_sale_class%TYPE;    -- �W��L�[�F�J�[�h����敪
--    lt_red_black_flag   xxcos_sales_exp_lines.red_black_flag%TYPE;       -- �W��L�[�F�ԍ��t���O
--    lt_tax_code         xxcos_sales_exp_headers.tax_code%TYPE;           -- �W��L�[�F�ŋ��R�[�h
--    lt_header_id        xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- �W��L�[�F�̔����уw�b�_ID
--    ln_amount           NUMBER DEFAULT 0;                                -- �W�����z
--    ln_tax              NUMBER DEFAULT 0;                                -- �W������ŋ��z
/* 2009/10/02 Ver1.24 Del End   */
    ln_ar_dis_idx       NUMBER DEFAULT 0;                                -- AR��v�z���W��C���f�b�N�X
/* 2009/10/02 Ver1.24 Mod Start */
--    ln_dis_idx          NUMBER DEFAULT 0;                                -- AR��v�z��OIF�C���f�b�N�X
    ln_dis_idx          NUMBER DEFAULT 1;                                -- AR��v�z��OIF�C���f�b�N�X
/* 2009/10/02 Ver1.24 Mod End   */
    ln_jour_cnt         NUMBER DEFAULT 0;                                -- �d�󐶐��J�E���g
    lv_rec_flag         VARCHAR2(1);                                     -- REC�t���O
/* 2009/10/02 Ver1.24 Del Start */
--    -- AR����ԍ�
--    lt_trx_number       VARCHAR2(20);
/* 2009/10/02 Ver1.24 Del End   */
    lv_err_flag         VARCHAR2(1);                                     -- �G���[�p�t���O
    lv_jour_flag        VARCHAR2(1);                                     -- �G���[�p�t���O
    ln_skip_idx         NUMBER DEFAULT 0;                                -- �X�L�b�v�p�C���f�b�N�X;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
/* 2009/10/02 Ver1.24 Del Start */
--    non_jour_cls_expt         EXCEPTION;                -- �d��p�^�[���Ȃ�
/* 2009/10/02 Ver1.24 Del End   */
    non_ccid_expt             EXCEPTION;                -- CCID�擾�o���Ȃ��G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
/* 2009/10/02 Ver1.24 Del Start */
--    -- ��������e�[�u���̔���ʔ̓X�f�[�^�J�E���g�Z�b�g
--    ln_ar_dis_idx := gt_ar_dis_tbl.COUNT;
--
--    --=====================================
--    -- 1.AR��v�z���d��p�^�[���̎擾
--    --=====================================
--
--    -- �J�[�\���I�[�v��
--    BEGIN
--      OPEN  jour_cls_cur;
--      FETCH jour_cls_cur BULK COLLECT INTO gt_jour_cls_tbl;
--    EXCEPTION
--    -- �d��p�^�[���擾���s�����ꍇ
--      WHEN OTHERS THEN
--        lv_errmsg    := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_xxcos_short_nm
--                         , iv_name         => cv_jour_nodata_msg
--                         , iv_token_name1  => cv_tkn_lookup_type
--                         , iv_token_value1 => cv_qct_jour_cls
--                       );
--        lv_errbuf := lv_errmsg;
--        RAISE non_jour_cls_expt;
--    END;
--    -- �d��p�^�[���擾���s�����ꍇ
--    IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
--      lv_errmsg    := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_xxcos_short_nm
--                       , iv_name         => cv_jour_nodata_msg
--                       , iv_token_name1  => cv_tkn_lookup_type
--                       , iv_token_value1 => cv_qct_jour_cls
--                     );
--      lv_errbuf := lv_errmsg;
--      RAISE non_jour_cls_expt;
--    END IF;
--
--    -- �J�[�\���N���[�Y
--    CLOSE jour_cls_cur;
/* 2009/10/02 Ver1.24 Del End   */
--
    --�X�L�b�v�J�E���g�Z�b�g
    ln_skip_idx := gt_sales_skip_tbl.COUNT;
    --=====================================
    -- 3.AR��v�z���f�[�^�쐬
    --=====================================
/* 2009/10/02 Ver1.24 Mod Start */
--    -- �W��L�[�̒l�Z�b�g
--    lt_invoice_number   := gt_sales_bulk_tbl2( 1 ).dlv_invoice_number;
--    lt_item_code        := gt_sales_bulk_tbl2( 1 ).item_code;
--    lt_prod_cls         := gt_sales_bulk_tbl2( 1 ).goods_prod_cls;
--    lt_gyotai_sho       := gt_sales_bulk_tbl2( 1 ).cust_gyotai_sho;
--    lt_card_sale_class  := gt_sales_bulk_tbl2( 1 ).card_sale_class;
--    lt_tax_code         := gt_sales_bulk_tbl2( 1 ).tax_code;
--    lt_invoice_class    := gt_sales_bulk_tbl2( 1 ).dlv_invoice_class;
--    lt_red_black_flag   := gt_sales_bulk_tbl2( 1 ).red_black_flag;
--    lt_header_id        := gt_sales_bulk_tbl2( 1 ).sales_exp_header_id;
--
--    -- ���X�g�f�[�^�o�^�ׂɁA�_�~�[�f�[�^���Z�b�g����
--    gt_sales_bulk_tbl2( gt_sales_bulk_tbl2.COUNT + 1 ).sales_exp_header_id
--                        := gt_sales_bulk_tbl2( gt_sales_bulk_tbl2.COUNT ).sales_exp_header_id;
--
    -- �ŏ���BUKL�����̏ꍇ
    IF ( gn_fetch_first_flag = 0 ) THEN
      -- �W��L�[�̒l�Z�b�g
      gt_invoice_number_ar_brk   := gt_sales_bulk_tbl( 1 ).dlv_invoice_number;
      gt_item_code_ar_brk        := gt_sales_bulk_tbl( 1 ).item_code;
      gt_prod_cls_ar_brk         := gt_sales_bulk_tbl( 1 ).goods_prod_cls;
      gt_gyotai_sho_ar_brk       := gt_sales_bulk_tbl( 1 ).cust_gyotai_sho;
      gt_card_sale_class_ar_brk  := gt_sales_bulk_tbl( 1 ).card_sale_class;
      gt_tax_code_ar_brk         := gt_sales_bulk_tbl( 1 ).tax_code;
      gt_invoice_class_ar_brk    := gt_sales_bulk_tbl( 1 ).dlv_invoice_class;
      gt_red_black_flag_ar_brk   := gt_sales_bulk_tbl( 1 ).red_black_flag;
      gt_header_id_ar_brk        := gt_sales_bulk_tbl( 1 ).sales_exp_header_id;
    END IF;
    -- 2��ڈȍ~��BUKL�����̏ꍇ�A�ێ����Ă����O���R�[�h���C���T�[�g�p�ϐ��Ɉڂ�
    IF ( gt_sales_dis_tbl_brk.COUNT <> 0 ) THEN
      gt_sales_bulk_tbl2( ln_dis_idx ) := gt_sales_dis_tbl_brk( ln_dis_idx );
    END IF;
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--    <<gt_sales_bulk_tbl2_loop>>
--    FOR dis_sum_idx IN 1 .. gt_sales_bulk_tbl2.COUNT LOOP
--
--      -- AR��v�z���f�[�^�W��J�n
--      IF ( lt_invoice_number = gt_sales_bulk_tbl2( dis_sum_idx ).dlv_invoice_number
--        AND
--          (
--            (
--              (
--                 NVL( lt_prod_cls, 'X' ) = cv_goods_prod_syo
--              OR NVL( lt_prod_cls, 'X' ) = cv_goods_prod_sei
--              )
--            AND
--              NVL( lt_prod_cls, 'X' ) = NVL( gt_sales_bulk_tbl2( dis_sum_idx ).goods_prod_cls, 'X' )
--            )
--          OR
--            (
--              (
--                  NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_syo
--              AND NVL( lt_prod_cls, 'X' ) <> cv_goods_prod_sei
--              )
--              AND lt_item_code = gt_sales_bulk_tbl2( dis_sum_idx ).item_code
--            )
--          )
--        AND lt_gyotai_sho      = gt_sales_bulk_tbl2( dis_sum_idx ).cust_gyotai_sho
--        AND lt_card_sale_class = gt_sales_bulk_tbl2( dis_sum_idx ).card_sale_class
--        AND lt_tax_code        = gt_sales_bulk_tbl2( dis_sum_idx ).tax_code
--        AND lt_header_id       = gt_sales_bulk_tbl2( dis_sum_idx ).sales_exp_header_id
--        )
--      THEN
--
--        -- �W�񂷂�t���O�����ݒ�
--        lv_sum_flag := cv_y_flag;
--
--        -- �{�̋��z�Ə���Ŋz���W�񂷂�
--        ln_amount := ln_amount + gt_sales_bulk_tbl2( dis_sum_idx ).pure_amount;
--        ln_tax    := ln_tax    + gt_sales_bulk_tbl2( dis_sum_idx ).tax_amount;
--      ELSE
--        lv_sum_flag := cv_n_flag;
--        ln_dis_idx  := dis_sum_idx - 1;
--      END IF;
--
--
    <<gt_sales_bulk_tbl_loop>>
    FOR dis_sum_idx IN 1 .. gt_sales_bulk_tbl.COUNT LOOP
--
      -- AR��v�z���f�[�^�W��J�n
      IF ( gt_invoice_number_ar_brk = gt_sales_bulk_tbl( dis_sum_idx ).dlv_invoice_number
        AND
          (
            (
              (
                 NVL( gt_prod_cls_ar_brk, 'X' ) = cv_goods_prod_syo
              OR NVL( gt_prod_cls_ar_brk, 'X' ) = cv_goods_prod_sei
              )
            AND
              NVL( gt_prod_cls_ar_brk, 'X' ) = NVL( gt_sales_bulk_tbl( dis_sum_idx ).goods_prod_cls, 'X' )
            )
          OR
            (
              (
                  NVL( gt_prod_cls_ar_brk, 'X' ) <> cv_goods_prod_syo
              AND NVL( gt_prod_cls_ar_brk, 'X' ) <> cv_goods_prod_sei
              )
              AND gt_item_code_ar_brk = gt_sales_bulk_tbl( dis_sum_idx ).item_code
            )
          )
        AND gt_gyotai_sho_ar_brk      = gt_sales_bulk_tbl( dis_sum_idx ).cust_gyotai_sho
        AND gt_card_sale_class_ar_brk = gt_sales_bulk_tbl( dis_sum_idx ).card_sale_class
        AND gt_tax_code_ar_brk        = gt_sales_bulk_tbl( dis_sum_idx ).tax_code
        AND gt_header_id_ar_brk       = gt_sales_bulk_tbl( dis_sum_idx ).sales_exp_header_id
        )
      THEN
--
        -- �C���T�[�g�p�̔z���ێ�
        gt_sales_bulk_tbl2( ln_dis_idx ) := gt_sales_bulk_tbl( dis_sum_idx );
        -- �W�񂷂�t���O�����ݒ�
        gv_sum_flag_ar                   := cv_y_flag;
        -- �{�̋��z�Ə���Ŋz���W�񂷂�
        gn_amount_ar                     := gn_amount_ar + gt_sales_bulk_tbl( dis_sum_idx ).pure_amount;
        gn_tax_ar                        := gn_tax_ar    + gt_sales_bulk_tbl( dis_sum_idx ).tax_amount;
--
      ELSE
--
        gv_sum_flag_ar := cv_n_flag;
--
      END IF;
/* 2009/10/02 Ver1.24 Mod End   */
--
      -- -- �W��t���O�fN'�̏ꍇ�A���LAR��v�z��OIF�쐬�������s��
/* 2009/10/02 Ver1.24 Mod Start */
--      IF ( lv_sum_flag = cv_n_flag ) THEN
      IF ( gv_sum_flag_ar = cv_n_flag ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Mod Start */
--        IF ( NVL( lt_trx_number, 'X' ) <> gt_sales_bulk_tbl2( ln_dis_idx ).oif_trx_number ) THEN
        IF ( NVL( gv_trx_number_ar_brk, 'X' ) <> gt_sales_bulk_tbl2( ln_dis_idx ).oif_trx_number ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
          lv_rec_flag := cv_y_flag;
        ELSE
          lv_rec_flag := cv_n_flag;
        END IF;
/* 2009/10/02 Ver1.24 Mod Start */
--        lt_trx_number      := gt_sales_bulk_tbl2( ln_dis_idx ).oif_trx_number;        -- AR����ԍ�
        gv_trx_number_ar_brk  := gt_sales_bulk_tbl2( ln_dis_idx ).oif_trx_number;        -- AR����ԍ�
/* 2009/10/02 Ver1.24 Mod End   */
--
        -- �d�󐶐��J�E���g�����l
        ln_jour_cnt := 1;
        lv_jour_flag := cv_n_flag;
--
        -- �d��p�^�[�����AR��v�z���̎d���ҏW����
        <<gt_jour_cls_tbl_loop>>
        FOR jcls_idx IN 1 .. gt_jour_cls_tbl.COUNT LOOP
--
/* 2009/10/02 Ver1.24 Mod Start */
--          IF (  gt_jour_cls_tbl( jcls_idx ).dlv_invoice_cls   = lt_invoice_class
--            AND (  gt_jour_cls_tbl( jcls_idx ).item_prod_cls  = lt_item_code
--              OR ( gt_jour_cls_tbl( jcls_idx ).item_prod_cls  <> lt_item_code
--                AND gt_jour_cls_tbl( jcls_idx ).item_prod_cls = lt_prod_cls ) )
--            AND ( gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = lt_gyotai_sho
--              OR  gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho IS NULL )
--            AND ( gt_jour_cls_tbl( jcls_idx ).card_sale_cls   = lt_card_sale_class
--              OR  gt_jour_cls_tbl( jcls_idx ).card_sale_cls   IS NULL )
--            AND ( gt_jour_cls_tbl( jcls_idx ).red_black_flag  = lt_red_black_flag
--              OR  gt_jour_cls_tbl( jcls_idx ).red_black_flag  IS NULL )
--            ) THEN
--
          IF (   gt_jour_cls_tbl( jcls_idx ).dlv_invoice_cls   = gt_invoice_class_ar_brk
             AND (
                    gt_jour_cls_tbl( jcls_idx ).item_prod_cls  = gt_item_code_ar_brk
                 OR
                   (   gt_jour_cls_tbl( jcls_idx ).item_prod_cls  <> gt_item_code_ar_brk
                   AND gt_jour_cls_tbl( jcls_idx ).item_prod_cls   = gt_prod_cls_ar_brk )
                   )
             AND (
                    gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho = gt_gyotai_sho_ar_brk
                 OR gt_jour_cls_tbl( jcls_idx ).cust_gyotai_sho IS NULL
                 )
             AND (
                    gt_jour_cls_tbl( jcls_idx ).card_sale_cls   = gt_card_sale_class_ar_brk
                 OR gt_jour_cls_tbl( jcls_idx ).card_sale_cls   IS NULL
                 )
             AND (
                    gt_jour_cls_tbl( jcls_idx ).red_black_flag  = gt_red_black_flag_ar_brk
                 OR gt_jour_cls_tbl( jcls_idx ).red_black_flag  IS NULL
                 )
             )
          THEN
/* 2009/10/02 Ver1.24 Mod End */
--
            -- ���̏W��ɂR���R�[�h���쐬����
            EXIT WHEN ( ln_jour_cnt > cn_jour_cnt );
--
            -- ����Ȗڂ̕ҏW
            lt_segment3 := gt_jour_cls_tbl( jcls_idx ).segment3;
--
            --=====================================
            -- 2.����Ȗ�CCID�̎擾
            --=====================================
            -- ����ȖڃZ�O�����g�P�`�Z�O�����g�W���CCID�擾
            lv_ccid_idx := gv_company_code                                   -- �Z�O�����g�P(��ЃR�[�h)
                        || NVL( gt_jour_cls_tbl( jcls_idx ).segment2,        -- �Z�O�����g�Q�i����R�[�h�j
                                gt_sales_bulk_tbl2( ln_dis_idx ).sales_base_code )
                                                                             -- �Z�O�����g�Q(�̔����т̔��㋒�_�R�[�h)
                        || lt_segment3                                       -- �Z�O�����g�R(����ȖڃR�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment4              -- �Z�O�����g�S(�⏕�ȖڃR�[�h:�����̂ݐݒ�)
                        || gt_jour_cls_tbl( jcls_idx ).segment5              -- �Z�O�����g�T(�ڋq�R�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment6              -- �Z�O�����g�U(��ƃR�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment7              -- �Z�O�����g�V(���Ƌ敪�R�[�h)
                        || gt_jour_cls_tbl( jcls_idx ).segment8;             -- �Z�O�����g�W(�\��)
--
            -- CCID�̑��݃`�F�b�N-->���݂��Ă���ꍇ�A�擾�K�v���Ȃ�
            IF ( gt_sel_ccid_tbl.EXISTS(  lv_ccid_idx ) ) THEN
              lt_ccid := gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id;
            ELSE
                  -- CCID�擾���ʊ֐����CCID���擾����
              lt_ccid := xxcok_common_pkg.get_code_combination_id_f (
/* 2009/08/28 Ver1.23 Mod Start */
--                             gd_process_date
                             gt_sales_bulk_tbl2( ln_dis_idx ).inspect_date
/* 2009/08/28 Ver1.23 Mod End   */
                           , gv_company_code
                           , NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                  gt_sales_bulk_tbl2( ln_dis_idx ).sales_base_code )
                           , lt_segment3
                           , gt_jour_cls_tbl( jcls_idx ).segment4
                           , gt_jour_cls_tbl( jcls_idx ).segment5
                           , gt_jour_cls_tbl( jcls_idx ).segment6
                           , gt_jour_cls_tbl( jcls_idx ).segment7
                           , gt_jour_cls_tbl( jcls_idx ).segment8
                         );
--
              --�G���[�t���OOFF
              lv_err_flag := cv_n_flag;
              IF ( lt_ccid IS NULL ) THEN
                -- CCID���擾�ł��Ȃ��ꍇ
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                  iv_application       => cv_xxcos_short_nm
                                , iv_name              => cv_ccid_nodata_msg
                                , iv_token_name1       => cv_tkn_segment1
                                , iv_token_value1      => gv_company_code
                                , iv_token_name2       => cv_tkn_segment2
                                , iv_token_value2      => NVL( gt_jour_cls_tbl( jcls_idx ).segment2,
                                                               gt_sales_bulk_tbl2( ln_dis_idx ).sales_base_code )
                                , iv_token_name3       => cv_tkn_segment3
                                , iv_token_value3      => lt_segment3
                                , iv_token_name4       => cv_tkn_segment4
                                , iv_token_value4      => gt_jour_cls_tbl( jcls_idx ).segment4
                                , iv_token_name5       => cv_tkn_segment5
                                , iv_token_value5      => gt_jour_cls_tbl( jcls_idx ).segment5
                                , iv_token_name6       => cv_tkn_segment6
                                , iv_token_value6      => gt_jour_cls_tbl( jcls_idx ).segment6
                                , iv_token_name7       => cv_tkn_segment7
                                , iv_token_value7      => gt_jour_cls_tbl( jcls_idx ).segment7
                                , iv_token_name8       => cv_tkn_segment8
                                , iv_token_value8      => gt_jour_cls_tbl( jcls_idx ).segment8
                                , iv_token_name9       => cv_tkn_header_id
/* 2009/10/02 Ver1.24 Mod Start */
--                                , iv_token_value9      => lt_header_id
--                                , iv_token_name10      => cv_tkn_order_no
--                                , iv_token_value10     => lt_invoice_number
                                , iv_token_value9      => gt_header_id_ar_brk
                                , iv_token_name10      => cv_tkn_order_no
                                , iv_token_value10     => gt_invoice_number_ar_brk
/* 2009/10/02 Ver1.24 Mod End   */
                              );
                lv_errbuf  := lv_errmsg;
                lv_err_flag  := cv_y_flag;
                gn_warn_flag := cv_y_flag;
                -- ��s�o��
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => cv_blank
                );
--
                -- ���b�Z�[�W�o��
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => lv_errmsg
                );
--
                -- ��s�o��
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => cv_blank
                );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
               -- ���b�Z�[�W�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => lv_errmsg
               );
--
               -- ��s�o��
               FND_FILE.PUT_LINE(
                  which  => FND_FILE.OUTPUT
                 ,buff   => cv_blank
               );
--
/* 2009/08/28 Ver1.23 Add Start */
              ELSE
                -- ���ʊ֐�����擾�ł����ꍇ�A�擾����CCID�����[�N�e�[�u���ɐݒ肷��
                gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
/* 2009/08/28 Ver1.23 Add End   */
              END IF;
--
              --�X�L�b�v����
              IF ( lv_err_flag = cv_y_flag ) THEN
                 ln_skip_idx := ln_skip_idx + 1;
                 gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_bulk_tbl2( ln_dis_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Add Start */
                 gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid          := gt_sales_bulk_tbl2( ln_dis_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
              END IF;
/* 2009/08/28 Ver1.23 Del Start */
--              -- �擾����CCID�����[�N�e�[�u���ɐݒ肷��
--              gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
/* 2009/08/28 Ver1.23 Del End   */
--
            END IF;                                       -- CCID�ҏW�I��
--
            --=====================================
            -- AR��v�z��OIF�f�[�^�ݒ�
            --=====================================
            IF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rev ) THEN
              -- ���v�s
              ln_ar_dis_idx := ln_ar_dis_idx + 1;
--
              -- AR��v�z��OIF�̐ݒ荀��
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- ������׃R���e�L�X�g�l�u�̔����сv���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- �������DFF1�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).dlv_invoice_number;
                                                          -- �������DFF3�F�[�i�`�[�ԍ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).oif_dff4;
                                                          -- �������DFF4:�[�i�`�[�ԍ�+�����̔�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- �������DFF5�F�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).sales_exp_header_id;
                                                          -- �������DFF7�F�̔����уw�b�_ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_rev;
                                                          -- ����Ȗڋ敪(�z���^�C�v)
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_amount;
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := gn_amount_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- ���z(���׋��z)
              IF ( gt_sales_bulk_tbl2( ln_dis_idx ).tax_code = gt_in_tax_cls ) THEN
                --���Ŏ��A���z�͖{�́{�ŋ�
/* 2009/10/02 Ver1.24 Mod Start */
--                gt_ar_dis_tbl( ln_ar_dis_idx ).amount     := ln_amount + ln_tax;
                gt_ar_dis_tbl( ln_ar_dis_idx ).amount     := gn_amount_ar + gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
              END IF;
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := ln_amount;
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := gn_amount_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- �p�[�Z���g(����)
              IF ( gt_sales_bulk_tbl2( ln_dis_idx ).tax_code = gt_in_tax_cls ) THEN
                --���Ŏ��A�p�[�Z���g(����)�͖{�́{�ŋ�
/* 2009/10/02 Ver1.24 Mod Start */
--                gt_ar_dis_tbl( ln_ar_dis_idx ).percent    := ln_amount + ln_tax;
                gt_ar_dis_tbl( ln_ar_dis_idx ).percent    := gn_amount_ar + gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
              END IF;
              gt_ar_dis_tbl( ln_ar_dis_idx ).code_combination_id
                                                          := lt_ccid;
                                                          -- ����Ȗڑg����ID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_idx ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- �d�󖾍׃J�e�S��:�c�ƒP��ID���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- �c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).created_by
                                                          := cn_created_by;
                                                          -- �쐬��
              gt_ar_dis_tbl( ln_ar_dis_idx ).creation_date
                                                          := cd_creation_date;
                                                          -- �쐬��
--
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_rec AND lv_rec_flag = cv_y_flag ) THEN
              -- ���s(���z�ݒ�Ȃ�)
              ln_ar_dis_idx := ln_ar_dis_idx + 1;
--
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- ������׃R���e�L�X�g�l�u�̔����сv���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- �������DFF1�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).dlv_invoice_number;
                                                          -- �������DFF3�F�[�i�`�[�ԍ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).oif_dff4;
                                                          -- �������DFF4�[�i�`�[�ԍ�+�����̔�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- �������DFF5	�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).sales_exp_header_id;
                                                          -- �������DFF7�F�̔����уw�b�_ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_rec;
                                                          -- ����Ȗڋ敪(�z���^�C�v)
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := cn_percent;
                                                          -- �p�[�Z���g(����)
              gt_ar_dis_tbl( ln_ar_dis_idx ).code_combination_id
                                                          := lt_ccid;
                                                          -- ����Ȗڑg����ID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_idx ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- �d�󖾍׃J�e�S��:�c�ƒP��ID���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- �c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).created_by
                                                          := cn_created_by;
                                                          -- �쐬��
              gt_ar_dis_tbl( ln_ar_dis_idx ).creation_date
                                                          := cd_creation_date;
                                                          -- �쐬��
--
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).acct_type = cv_acct_tax ) THEN
              -- �ŋ��s
              ln_ar_dis_idx := ln_ar_dis_idx + 1;
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_context
                                                          := gv_sales_nm;
                                                          -- ������׃R���e�L�X�g�l�u�̔����сv���Z�b�g
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute1
                                                          := gv_sales_nm;
                                                          -- �������DFF1�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute3
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).dlv_invoice_number;
                                                          -- �������DFF3�F�[�i�`�[�ԍ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute4
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).oif_tax_dff4;
                                                          -- �������DFF4�F�[�i�`�[�ԍ�+�����̔�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute5
                                                          := gv_sales_nm;
                                                          -- �������DFF5�u�̔����сv��ݒ�
              gt_ar_dis_tbl( ln_ar_dis_idx ).interface_line_attribute7
                                                          := gt_sales_bulk_tbl2( ln_dis_idx ).sales_exp_header_id;
                                                          -- �������DFF7�F�̔����уw�b�_ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).account_class
                                                          := cv_acct_tax;
                                                          -- ����Ȗڋ敪(�z���^�C�v)
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := ln_tax;
              gt_ar_dis_tbl( ln_ar_dis_idx ).amount       := gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- ���z(���׋��z)
/* 2009/10/02 Ver1.24 Mod Start */
--              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := ln_tax;
              gt_ar_dis_tbl( ln_ar_dis_idx ).percent      := gn_tax_ar;
/* 2009/10/02 Ver1.24 Mod End   */
                                                          -- �p�[�Z���g(����)
              gt_ar_dis_tbl( ln_ar_dis_idx ).code_combination_id
                                                          := lt_ccid;
                                                          -- ����Ȗڑg����ID(CCID)
              gt_ar_dis_tbl( ln_ar_dis_idx ).attribute_category
                                                          := gv_mo_org_id;
                                                          -- �d�󖾍׃J�e�S��:�c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).org_id       := TO_NUMBER( gv_mo_org_id );
                                                          -- �c�ƒP��ID
              gt_ar_dis_tbl( ln_ar_dis_idx ).created_by
                                                          := cn_created_by;
                                                          -- �쐬��
              gt_ar_dis_tbl( ln_ar_dis_idx ).creation_date
                                                          := cd_creation_date;
                                                          -- �쐬��
            END IF;
--
            -- �d�󐶐��J�E���g�Z�b�g
            ln_jour_cnt := ln_jour_cnt + 1;
          END IF;                                         -- �d��p�^�[������AR��v�z��OIF�f�[�^�̍쐬�����I��
--
        END LOOP gt_jour_cls_tbl_loop;                    -- �d��p�^�[�����f�[�^�쐬�����I��
--
/* 2009/10/02 Ver1.24 Mod Start */
--        IF ( ln_jour_cnt = 1 AND dis_sum_idx <> gt_sales_bulk_tbl2.COUNT ) THEN
        --�d�󂪂P�����Ȃ��ꍇ�G���[
        IF ( ln_jour_cnt = 1  ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application       => cv_xxcos_short_nm
                          , iv_name              => cv_jour_no_msg
                          , iv_token_name1       => cv_tkn_invoice_cls
/* 2009/10/02 Ver1.24 Mod Start */
--                          , iv_token_value1      => lt_invoice_class
--                          , iv_token_name2       => cv_tkn_prod_cls
--                          , iv_token_value2      => NVL( lt_prod_cls, lt_item_code )
--                          , iv_token_name3       => cv_tkn_gyotai_sho
--                          , iv_token_value3      => lt_gyotai_sho
--                          , iv_token_name4       => cv_tkn_sale_cls
--                          , iv_token_value4      => lt_card_sale_class
--                          , iv_token_name5       => cv_tkn_red_black_flag
--                          , iv_token_value5      => lt_red_black_flag
--                          , iv_token_name6       => cv_tkn_header_id
--                          , iv_token_value6      => lt_header_id
--                          , iv_token_name7       => cv_tkn_order_no
--                          , iv_token_value7      => lt_invoice_number
--
                          , iv_token_value1      => gt_invoice_class_ar_brk
                          , iv_token_name2       => cv_tkn_prod_cls
                          , iv_token_value2      => NVL( gt_prod_cls_ar_brk, gt_item_code_ar_brk )
                          , iv_token_name3       => cv_tkn_gyotai_sho
                          , iv_token_value3      => gt_gyotai_sho_ar_brk
                          , iv_token_name4       => cv_tkn_sale_cls
                          , iv_token_value4      => gt_card_sale_class_ar_brk
                          , iv_token_name5       => cv_tkn_red_black_flag
                          , iv_token_value5      => gt_red_black_flag_ar_brk
                          , iv_token_name6       => cv_tkn_header_id
                          , iv_token_value6      => gt_header_id_ar_brk
                          , iv_token_name7       => cv_tkn_order_no
                          , iv_token_value7      => gt_invoice_number_ar_brk
/* 2009/10/02 Ver1.24 Mod End   */
                        );
          lv_errbuf  := lv_errmsg;
          lv_jour_flag  := cv_y_flag;
          gn_warn_flag := cv_y_flag;
          -- ��s�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_blank
          );
--
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
--
          -- ��s�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_blank
          );
--
          -- ��s�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => cv_blank
          );
--
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          -- ��s�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => cv_blank
          );
          --�X�L�b�v����
          IF ( lv_jour_flag = cv_y_flag ) THEN
             ln_skip_idx := ln_skip_idx + 1;
             gt_sales_skip_tbl( ln_skip_idx ).sales_exp_header_id := gt_sales_bulk_tbl2( ln_dis_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Add Start */
             gt_sales_skip_tbl( ln_skip_idx ).xseh_rowid          := gt_sales_bulk_tbl2( ln_dis_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Add End   */
          END IF;
        END IF;
--
/* 2009/10/02 Ver1.24 Mod Start */
--        -- ���z�̐ݒ�
--        ln_amount        := gt_sales_bulk_tbl2( dis_sum_idx ).pure_amount;
--        ln_tax           := gt_sales_bulk_tbl2( dis_sum_idx ).tax_amount;
        -- ���z�̐ݒ�
        gn_amount_ar   := gt_sales_bulk_tbl( dis_sum_idx ).pure_amount;
        gn_tax_ar      := gt_sales_bulk_tbl( dis_sum_idx ).tax_amount;
/* 2009/10/02 Ver1.24 Mod End   */
      END IF;                                             -- �W��L�[����AR��v�z��OIF�f�[�^�̏W��I��
--
/* 2009/10/02 Ver1.24 Add Start */
      --�����R�[�h���C���T�[�g�p�z��ɐݒ肷��
      gt_sales_bulk_tbl2( ln_dis_idx ) := gt_sales_bulk_tbl( dis_sum_idx );
      -- �W��L�[�̃��Z�b�g
      gt_invoice_number_ar_brk   := gt_sales_bulk_tbl( dis_sum_idx ).dlv_invoice_number;
      gt_item_code_ar_brk        := gt_sales_bulk_tbl( dis_sum_idx ).item_code;
      gt_prod_cls_ar_brk         := gt_sales_bulk_tbl( dis_sum_idx ).goods_prod_cls;
      gt_gyotai_sho_ar_brk       := gt_sales_bulk_tbl( dis_sum_idx ).cust_gyotai_sho;
      gt_card_sale_class_ar_brk  := gt_sales_bulk_tbl( dis_sum_idx ).card_sale_class;
      gt_tax_code_ar_brk         := gt_sales_bulk_tbl( dis_sum_idx ).tax_code;
      gt_invoice_class_ar_brk    := gt_sales_bulk_tbl( dis_sum_idx ).dlv_invoice_class;
      gt_red_black_flag_ar_brk   := gt_sales_bulk_tbl( dis_sum_idx ).red_black_flag;
      gt_header_id_ar_brk        := gt_sales_bulk_tbl( dis_sum_idx ).sales_exp_header_id;
/* 2009/10/02 Ver1.24 Add End  */
--
/* 2009/10/02 Ver1.24 Mod Start */
--    END LOOP gt_sales_bulk_tbl2_loop;                      -- AR��v�z���W��f�[�^���[�v�I��
    END LOOP gt_sales_bulk_tbl_loop;                      -- AR��v�z���W��f�[�^���[�v�I��
/* 2009/10/02 Ver1.24 Mod End   */
--
/* 2009/10/02 Ver1.24 Add Start */
    -- �����BULK�����ׁ̈A���[�v�I�����_�̃C���T�[�g�p�ϐ���ێ�
    gt_sales_dis_tbl_brk( ln_dis_idx ) := gt_sales_bulk_tbl2( ln_dis_idx );
--
/* 2009/10/02 Ver1.24 Add End   */
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
/* 2009/10/02 Ver1.24 Del Start */
--    WHEN non_jour_cls_expt THEN
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
/* 2009/10/02 Ver1.24 Del End   */
--
    WHEN non_ccid_expt THEN
/* 2009/10/02 Ver1.24 Del Start */
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
/* 2009/10/02 Ver1.24 Del Start */
--      -- �J�[�\���N���[�Y
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--     END IF;
/* 2009/10/02 Ver1.24 Del End   */
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
/* 2009/10/02 Ver1.24 Del Start */
--      -- �J�[�\���N���[�Y
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
/* 2009/10/02 Ver1.24 Del Start */
--      -- �J�[�\���N���[�Y
--      IF ( jour_cls_cur%ISOPEN ) THEN
--        CLOSE jour_cls_cur;
--      END IF;
/* 2009/10/02 Ver1.24 Del End   */
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END edit_dis_bulk_data;
--
--
  /***********************************************************************************
   * Procedure Name   : insert_aroif_data
   * Description      : AR�������OIF�o�^����(A-7)
   ***********************************************************************************/
  PROCEDURE insert_aroif_data(
/* 2009/10/02 Ver1.24 Add Start */
    iv_target         IN  VARCHAR2,         --   �����Ώۋ敪
/* 2009/10/02 Ver1.24 Add End   */
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2 )        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_aroif_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm     VARCHAR2(255);                -- �e�[�u����
    ln_ar_idx     NUMBER DEFAULT 0;             -- �������OIF�C���f�b�N�X
    lv_skip_flag  VARCHAR2(1);                  -- �t���O
/* 2009/10/02 Ver1.24 Add Start */
    --�o�א�ڋq�`�F�b�N�p
    ln_start_index        NUMBER DEFAULT 1;
    --�C���T�[�g�����p
    ln_start              NUMBER;               -- �J�n�ʒu
    ln_end                NUMBER;               -- �I���ʒu
    ln_run_flag           NUMBER;               -- �����p���t���O(0:�p���A1:�I��)
/* 2009/10/02 Ver1.24 Add End   */
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
    --==============================================================
    -- ��ʉ�vOIF�e�[�u���փf�[�^�o�^
    --==============================================================
    <<gt_ar_interface_tbl_loop>>
    FOR sale_idx IN 1 .. gt_ar_interface_tbl.COUNT LOOP
      lv_skip_flag := cv_n_flag;
      -- �X�L�b�v����
      IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
--
        <<gt_sales_skip_tbl_loop>>
        FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
          IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
              = gt_ar_interface_tbl( sale_idx ).interface_line_attribute7 ) THEN
            lv_skip_flag := cv_y_flag;
            EXIT;
          END IF;
        END LOOP gt_sales_skip_tbl_loop;
      END IF;
--
      IF ( lv_skip_flag = cv_n_flag ) THEN
        ln_ar_idx := ln_ar_idx + 1;
        gt_ar_interface_tbl1( ln_ar_idx )                  := gt_ar_interface_tbl( sale_idx );
      END IF;
    END LOOP gt_ar_interface_tbl_loop;
/* 2009/10/02 Ver1.24 Add Start */
    --������
    gt_ar_interface_tbl.DELETE; --AR�������OIF�p�z��(�x���f�[�^����)
--
/* 2009/10/02 Ver1.24 Add End   */
--
    IF ( gt_ar_interface_tbl1.COUNT > 0 ) THEN
--
/* 2009/10/02 Ver1.24 Add Start */
--
      --��菈���̂ݏo�א�ڋq�̃`�F�b�N
      IF ( iv_target = cv_major ) THEN
--
        <<gt_ship_check_loop>>
        FOR ln_ar_idx IN 1 .. gt_ar_interface_tbl1.COUNT LOOP
--
          -- ����ԍ����ς������
          IF (
               (
                  ( gt_ar_interface_tbl1( ln_ar_idx ).trx_number IS NULL )
                  AND
                  ( gt_ar_interface_tbl1( ln_ar_idx ).link_to_line_attribute4 <> NVL( gn_key_dff4, 'X') )
               )
             OR
               (
                  ( gt_ar_interface_tbl1( ln_ar_idx ).trx_number IS NOT NULL )
                  AND
                  ( gt_ar_interface_tbl1( ln_ar_idx ).trx_number <> NVL( gn_key_trx_number, 'X') )
               )
             )
          THEN
--
            -- �o�א�ڋq�t���O��ON�̏ꍇ
            IF ( gn_ship_flg = cn_ship_flg_on ) THEN
--
              -- ����̎���ԍ��̏o�א�ڋq�����N���A
              <<gt_ship_clear_loop>>
              FOR start_index IN ln_start_index .. ln_ar_idx - 1 LOOP
--
                -- �o�א�ڋqID�E�Z��ID���N���A
                gt_ar_interface_tbl1( start_index ).orig_system_ship_customer_id := NULL;
                gt_ar_interface_tbl1( start_index ).orig_system_ship_address_id  := NULL;
--
              END LOOP gt_ship_clear_loop;
--
              -- �ŏI�s�̔���(�ŏI�s�̎���ԍ����قȂ�ꍇ)
              IF ( gt_ar_interface_tbl1.COUNT = ln_ar_idx ) THEN
                -- �o�א�ڋqID�E�Z��ID���N���A
                gt_ar_interface_tbl1( ln_ar_idx ).orig_system_ship_customer_id := NULL;
                gt_ar_interface_tbl1( ln_ar_idx ).orig_system_ship_address_id  := NULL;
              END IF;
--
              -- ����OIF�ɏ������܂�Ă���f�[�^�̍X�V
              -- ���v�s
              UPDATE  ra_interface_lines_all rila
              SET     rila.orig_system_ship_customer_id = NULL -- �o�א�ڋqID
                     ,rila.orig_system_ship_address_id  = NULL -- �o�א�ڋq�Z��ID
              WHERE   rila.trx_number = gn_key_trx_number
              ;
              -- �ŋ��s
              UPDATE  ra_interface_lines_all rila
              SET     rila.orig_system_ship_customer_id = NULL -- �o�א�ڋqID
                     ,rila.orig_system_ship_address_id  = NULL -- �o�א�ڋq�Z��ID
              WHERE   rila.link_to_line_attribute4 IN (
                        SELECT rilas.interface_line_attribute4 interface_line_attribute4
                        FROM   ra_interface_lines_all rilas
                        WHERE  rilas.trx_number = gn_key_trx_number )
              ;
--
            END IF;
--
            --������
            gn_ship_flg             := cn_ship_flg_off;                                                -- �t���O��������
            gn_key_trx_number       := gt_ar_interface_tbl1( ln_ar_idx ).trx_number;                   -- ���No���擾
            gn_key_dff4             := gt_ar_interface_tbl1( ln_ar_idx ).interface_line_attribute4;    -- �������DFF4���擾
            gn_key_ship_customer_id := gt_ar_interface_tbl1( ln_ar_idx ).orig_system_ship_customer_id; -- �o�א�ڋqID���擾
            ln_start_index          := ln_ar_idx;                                                      -- ���No�̊J�n�ʒu���擾
--
          ELSE
--
            -- �o�א�ڋq�̍��ك`�F�b�N
            IF ( gt_ar_interface_tbl1( ln_ar_idx ).orig_system_ship_customer_id <> gn_key_ship_customer_id ) THEN
              -- �o�א�ڋq�t���O��ON�ɂ���
              gn_ship_flg := cn_ship_flg_on;
            END IF;
--
            -- �������DFF4�̂ݎ擾(�ŋ��s�Ɏ���ԍ���������)
            gn_key_dff4 := gt_ar_interface_tbl1( ln_ar_idx ).interface_line_attribute4;
--
            -- �ŏI�s�̔���(�ŏI�s�̎���ԍ��������ꍇ)
            IF ( gn_ship_flg = cn_ship_flg_on AND ln_ar_idx = gt_ar_interface_tbl1.COUNT ) THEN
--
              -- ����̎���ԍ��̏o�א�ڋq�����N���A
              <<gt_ship_clear_loop>>
              FOR start_index IN ln_start_index .. ln_ar_idx LOOP
--
                -- �o�א�ڋqID�E�Z��ID���N���A
                gt_ar_interface_tbl1( start_index ).orig_system_ship_customer_id := NULL;
                gt_ar_interface_tbl1( start_index ).orig_system_ship_address_id  := NULL;
--
              END LOOP gt_ship_clear_loop;
--
              -- ����OIF�ɏ������܂�Ă���f�[�^�̍X�V
              -- ���v�s
              UPDATE  ra_interface_lines_all rila
              SET     rila.orig_system_ship_customer_id = NULL -- �o�א�ڋqID
                     ,rila.orig_system_ship_address_id  = NULL -- �o�א�ڋq�Z��ID
              WHERE   rila.trx_number = gn_key_trx_number
              ;
              -- �ŋ��s
              UPDATE  ra_interface_lines_all rila
              SET     rila.orig_system_ship_customer_id = NULL -- �o�א�ڋqID
                     ,rila.orig_system_ship_address_id  = NULL -- �o�א�ڋq�Z��ID
              WHERE   rila.link_to_line_attribute4 IN (
                        SELECT rilas.interface_line_attribute4 interface_line_attribute4
                        FROM   ra_interface_lines_all rilas
                        WHERE  rilas.trx_number = gn_key_trx_number )
              ;
--
            END IF;
--
          END IF;
--
        END LOOP gt_ship_check_loop;
--
      END IF;
/* 2009/10/02 Ver1.24 Add End   */
--
      BEGIN
/* 2009/10/02 Ver1.24 Mod Start */
--        FORALL i IN 1..gt_ar_interface_tbl1.COUNT
--          INSERT INTO
--            ra_interface_lines_all
--          VALUES
--            gt_ar_interface_tbl1(i)
--         ;
--
        -- �����l�ݒ�
        ln_start    := 1;
        ln_end      := gn_if_bulk_collect_cnt;   --BUKL(if)��������
        ln_run_flag := 0;
--
        -- �Ώۃf�[�^��BUKL����������菬�����ꍇ
        IF ( gn_if_bulk_collect_cnt > gt_ar_interface_tbl1.COUNT ) THEN
          ln_end      := gt_ar_interface_tbl1.COUNT; --�z��̌���
          ln_run_flag := 1;                          --�ŏI�̏���
        END IF;
--
        <<bulk_loop>>
        LOOP
          FORALL i IN ln_start..ln_end
            INSERT INTO
              ra_interface_lines_all
            VALUES
              gt_ar_interface_tbl1(i)
            ;
--
          -- �������p�����邩�`�F�b�N
          EXIT WHEN ln_run_flag = 1;
--
          -- ���̑Ώۃf�[�^�̔z��ʒu��ݒ�
          ln_start := ln_end + 1;
          -- �ŏI + BULK�������������z��̌����������ꍇ
          IF ( ln_end + gn_if_bulk_collect_cnt < gt_ar_interface_tbl1.COUNT ) THEN
            ln_end := ln_end + gn_if_bulk_collect_cnt;
          ELSE
            ln_end      := gt_ar_interface_tbl1.COUNT; -- �z��̌���
            ln_run_flag := 1;                          -- �ŏI�̏���
          END IF;
        END LOOP bulk_loop;
--
/* 2009/10/02 Ver1.24 Mod End   */
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_insert_data_expt;
      END;
    END IF;
--
/* 2009/10/02 Ver1.24 Add Start */
    --���������擾
    gn_aroif_cnt_tmp := gn_aroif_cnt_tmp + gt_ar_interface_tbl1.COUNT;
/* 2009/10/02 Ver1.24 Add Start */
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_insert_data_expt THEN
      -- �o�^�Ɏ��s�����ꍇ
      -- �G���[�����ݒ�
      lv_tbl_nm  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm      -- �A�v���Z�k��
                      , iv_name              => cv_tkn_aroif_msg       -- ���b�Z�[�WID
                    );
      ov_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm
                      , iv_name              => cv_data_insert_msg
                      , iv_token_name1       => cv_tkn_tbl_nm
                      , iv_token_value1      => lv_tbl_nm
                      , iv_token_name2       => cv_tkn_key_data
                      , iv_token_value2      => cv_blank
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
  END insert_aroif_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_ardis_data
   * Description      : AR��v�z��OIF�o�^����(A-8)
   ***********************************************************************************/
  PROCEDURE insert_ardis_data(
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2 )        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_ardis_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm     VARCHAR2(255);                -- �e�[�u����
    ln_ar_dis_idx NUMBER DEFAULT 0;             -- �������OIF�C���f�b�N�X
    lv_skip_flag  VARCHAR2(1);                  -- �t���O
/* 2009/10/02 Ver1.24 Add Start */
    ln_start      NUMBER;                       -- �J�n�ʒu
    ln_end        NUMBER;                       -- �I���ʒu
    ln_run_flag   NUMBER;                       -- �����p���t���O(0:�p���A1:�I��)
/* 2009/10/02 Ver1.24 Add End */
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
    --==============================================================
    -- AR��v�z��OIF�e�[�u���փf�[�^�o�^
    --==============================================================
    <<gt_ar_dis_tbl_loop>>
    FOR sale_idx IN 1 .. gt_ar_dis_tbl.COUNT LOOP
      lv_skip_flag := cv_n_flag;
      -- �X�L�b�v����
      IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
--
        <<gt_sales_skip_tbl_loop>>
        FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
          IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
              = gt_ar_dis_tbl( sale_idx ).interface_line_attribute7 ) THEN
            lv_skip_flag := cv_y_flag;
            EXIT;
          END IF;
        END LOOP gt_sales_skip_tbl_loop;
      END IF;
--
      IF ( lv_skip_flag = cv_n_flag ) THEN
        ln_ar_dis_idx := ln_ar_dis_idx + 1;
        gt_ar_dis_tbl1( ln_ar_dis_idx )                  := gt_ar_dis_tbl( sale_idx );
      END IF;
    END LOOP gt_ar_dis_tbl_loop;
--
/* 2009/10/02 Ver1.24 Add Start */
    --������
    gt_ar_dis_tbl.DELETE;  --  AR��v�z��OIF�p�z��(�x���f�[�^����)
/* 2009/10/02 Ver1.24 Add End   */
    IF ( gt_ar_dis_tbl1.COUNT > 0 ) THEN 
      BEGIN
/* 2009/10/02 Ver1.24 Mod Start */
--        FORALL i IN 1..gt_ar_dis_tbl1.COUNT
--          INSERT INTO
--            ra_interface_distributions_all
--          VALUES
--            gt_ar_dis_tbl1(i)
--          ;
--
        -- �����l�ݒ�
        ln_start    := 1;
        ln_end      := gn_if_bulk_collect_cnt;   --BUKL(if)��������
        ln_run_flag := 0;
--
        -- �Ώۃf�[�^��BUKL����������菬�����ꍇ
        IF ( gn_if_bulk_collect_cnt > gt_ar_dis_tbl1.COUNT ) THEN
          ln_end      := gt_ar_dis_tbl1.COUNT; --�z��̌���
          ln_run_flag := 1;                    --�ŏI�̏���
        END IF;
--
        <<bulk_loop>>
        LOOP
          FORALL i IN ln_start..ln_end
            INSERT INTO
              ra_interface_distributions_all
            VALUES
              gt_ar_dis_tbl1(i)
            ;
--
          -- �������p�����邩�`�F�b�N
          EXIT WHEN ln_run_flag = 1;
--
          -- ���̑Ώۃf�[�^�̔z��ʒu��ݒ�
          ln_start := ln_end + 1;
          -- �ŏI + BULK�������������z��̌����������ꍇ
          IF ( ln_end + gn_if_bulk_collect_cnt < gt_ar_dis_tbl1.COUNT ) THEN
            ln_end := ln_end + gn_if_bulk_collect_cnt;
          ELSE
            -- �Ώۃf�[�^��10000���ȉ��̏ꍇ
            ln_end      := gt_ar_dis_tbl1.COUNT;  --�z��̌���
            ln_run_flag := 1;                     --�ŏI�̏���
          END IF;
        END LOOP bulk_loop;
--
/* 2009/10/02 Ver1.24 Mod End   */
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_insert_data_expt;
      END;
    END IF;
--
/* 2009/10/02 Ver1.24 Add Start */
    --���������擾
    gn_ardis_cnt_tmp := gn_ardis_cnt_tmp + gt_ar_dis_tbl1.COUNT;
/* 2009/10/02 Ver1.24 Add End   */
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_insert_data_expt THEN
      -- �o�^�Ɏ��s�����ꍇ
      -- �G���[�����ݒ�
      lv_tbl_nm  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm      -- �A�v���Z�k��
                      , iv_name              => cv_tkn_ardis_msg       -- ���b�Z�[�WID
                    );
      ov_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm
                      , iv_name              => cv_data_insert_msg
                      , iv_token_name1       => cv_tkn_tbl_nm
                      , iv_token_value1      => lv_tbl_nm
                      , iv_token_name2  => cv_tkn_key_data
                      , iv_token_value2 => cv_blank
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
  END insert_ardis_data;
--
  /***********************************************************************************
   * Procedure Name   : upd_data
   * Description      : �̔����уw�b�_�X�V����(A-9)
   ***********************************************************************************/
  PROCEDURE upd_data(
/* 2009/10/02 Ver1.24 Mod Start */
--    ov_errbuf         OUT VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
--    ov_retcode        OUT VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
--    ov_errmsg         OUT VARCHAR2 )        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      iv_target       IN  VARCHAR2    -- �����Ώۋ敪
    , iv_create_class IN  VARCHAR2    -- �쐬���敪
    , ov_errbuf       OUT VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2 )  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
/* 2009/10/02 Ver1.24 Mod End   */
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'upd_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm           VARCHAR2(255);          -- �e�[�u����
    lv_skip_flag        VARCHAR2(1);            -- �t���O
    ln_sales_h_tbl_idx  NUMBER DEFAULT 0;       -- �̔����уw�b�_�X�V�p�C���f�b�N�X
/* 2009/10/02 Ver1.24 Add Start */
    ln_start            NUMBER;                 -- �J�n�ʒu
    ln_end              NUMBER;                 -- �I���ʒu
    ln_run_flag         NUMBER;                 -- �����p���t���O(0:�p���A1:�I��)
    lv_table_name       VARCHAR2(255);          -- �e�[�u����
/* 2009/10/02 Ver1.24 Add End   */
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR no_target_cur
    IS
/* 2009/11/05 Ver1.26 Mod Start */
--      SELECT xseh.rowid  xseh_rowid
      SELECT /*+
               INDEX(xseh xxcos_sales_exp_headers_n02)
             */
             xseh.rowid  xseh_rowid
/* 2009/11/05 Ver1.26 Mod End   */
      FROM   xxcos_sales_exp_headers xseh
      WHERE  xseh.ar_interface_flag   = cv_n_flag          -- �S�����I����N�Ŏc���Ă������
      AND    xseh.delivery_date      <= gd_process_date    -- �[�i�� <= �Ɩ����t
/* 2009/11/05 Ver1.26 Del Start */
--      AND    xseh.create_class        = iv_create_class    -- �p�����[�^.�쐬���敪
/* 2009/11/05 Ver1.26 Del End   */
      AND    (
               ( iv_target = cv_major AND xseh.receiv_base_code = gv_busi_dept_cd )
               OR
               (
                 ( iv_target = cv_not_major )
                 AND
                 (
                   ( xseh.receiv_base_code <> gv_busi_dept_cd )
                   OR
                   ( xseh.receiv_base_code IS NULL )
                 )
               )
             )                                             -- �p�����[�^.�����Ώۋ敪 1:��� 2:����
/* 2009/11/05 Ver1.26 Add Start */
      AND    EXISTS (
             SELECT
                 'X'
             FROM
                 fnd_lookup_values   flvl
             WHERE
                 flvl.lookup_type       = cv_qct_mkorg_cls
             AND flvl.lookup_code       LIKE cv_qcc_code
             AND flvl.attribute3        = iv_create_class    -- �p�����������敪�������Ɠ���
             AND flvl.enabled_flag      = cv_enabled_yes
             AND flvl.language          = ct_lang
             AND gd_process_date BETWEEN NVL( flvl.start_date_active, gd_process_date )
                                 AND     NVL( flvl.end_date_active,   gd_process_date )
             AND flvl.meaning           = xseh.create_class
             )
/* 2009/11/05 Ver1.26 Add End   */
      FOR UPDATE OF
             xseh.sales_exp_header_id
      NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �̔����уw�b�_�X�V����(����I��)
    --==============================================================
--
/* 2009/10/02 Ver1.24 Mod Start */
--      FOR sale_idx IN 1 .. gt_sales_exp_tbl2.COUNT LOOP
    FOR sale_idx IN 1 .. gt_sales_target_tbl.COUNT LOOP
/* 2009/10/02 Ver1.24 Mod End   */
--
      lv_skip_flag := cv_n_flag;
      IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
--
        <<gt_sales_skip_tbl_loop>>
        FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
          IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod Start */
--                  = gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id ) THEN
              = gt_sales_target_tbl( sale_idx ).sales_exp_header_id ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
            lv_skip_flag := cv_y_flag;
            EXIT;
          END IF;
        END LOOP gt_sales_skip_tbl_loop;
      END IF;
--
      IF ( lv_skip_flag = cv_n_flag ) THEN
        ln_sales_h_tbl_idx := ln_sales_h_tbl_idx + 1;
/* 2009/10/02 Ver1.24 Mod Start */
--        gt_sales_h_tbl( ln_sales_h_tbl_idx )                  := gt_sales_exp_tbl2( sale_idx ).xseh_rowid;
        gt_sales_h_tbl( ln_sales_h_tbl_idx )  := gt_sales_target_tbl( sale_idx ).xseh_rowid;
/* 2009/10/02 Ver1.24 Mod End   */
      END IF;
    END LOOP gt_sales_exp_tbl2_loop;                                  -- �̔����уf�[�^���[�v�I��
--
    -- �����Ώۃf�[�^�̃C���^�t�F�[�X�σt���O���ꊇ�X�V����
    BEGIN
/* 2009/10/02 Ver1.24 Mod Start */
--      <<update_interface_flag>>
--      FORALL i IN gt_sales_h_tbl.FIRST..gt_sales_h_tbl.LAST
--        UPDATE
--          xxcos_sales_exp_headers       xseh
--        SET
--          xseh.ar_interface_flag      = cv_y_flag,                     -- AR�C���^�t�F�[�X�σt���O
--          xseh.last_updated_by        = cn_last_updated_by,            -- �ŏI�X�V��
--          xseh.last_update_date       = cd_last_update_date,           -- �ŏI�X�V��
--          xseh.last_update_login      = cn_last_update_login,          -- �ŏI�X�V���O�C��
--          xseh.request_id             = cn_request_id,                 -- �v��ID
--          xseh.program_application_id = cn_program_application_id,     -- �R���J�����g�E�v���O�����E�A�v��ID
--          xseh.program_id             = cn_program_id,                 -- �R���J�����g�E�v���O����ID
--          xseh.program_update_date    = cd_program_update_date         -- �v���O�����X�V��
--        WHERE
--          xseh.rowid                  = gt_sales_h_tbl( i );           -- �̔�����ROWID
--
      -- �����l�ݒ�
      ln_start    := 1;
      ln_end      := gn_ar_bulk_collect_cnt; --BUKL��������
      ln_run_flag := 0;
--
      -- �Ώۃf�[�^��BUKL����������菬�����ꍇ
      IF ( gn_ar_bulk_collect_cnt > gt_sales_h_tbl.COUNT ) THEN
        ln_end      := gt_sales_h_tbl.COUNT; --�z��̌���
        ln_run_flag := 1;                    --�ŏI�̏���
      END IF;
      --
      <<n_update_loop>>
      LOOP
        FORALL i IN ln_start..ln_end
          UPDATE
            xxcos_sales_exp_headers       xseh
          SET
            xseh.ar_interface_flag      = cv_y_flag,                     -- AR�C���^�t�F�[�X�σt���O
            xseh.last_updated_by        = cn_last_updated_by,            -- �ŏI�X�V��
            xseh.last_update_date       = cd_last_update_date,           -- �ŏI�X�V��
            xseh.last_update_login      = cn_last_update_login,          -- �ŏI�X�V���O�C��
            xseh.request_id             = cn_request_id,                 -- �v��ID
            xseh.program_application_id = cn_program_application_id,     -- �R���J�����g�E�v���O�����E�A�v��ID
            xseh.program_id             = cn_program_id,                 -- �R���J�����g�E�v���O����ID
            xseh.program_update_date    = cd_program_update_date         -- �v���O�����X�V��
          WHERE
            xseh.rowid                  = gt_sales_h_tbl( i );           -- �̔�����ROWID
--
        -- �������p�����邩�`�F�b�N
        EXIT WHEN  ln_run_flag = 1;
--
        -- ���̑Ώۃf�[�^�̔z��ʒu��ݒ�
        ln_start := ln_end + 1;
        -- �ŏI + BULK�������������z��̌����������ꍇ
        IF ( ln_end + gn_ar_bulk_collect_cnt < gt_sales_h_tbl.COUNT ) THEN
          ln_end := ln_end + gn_ar_bulk_collect_cnt;
        ELSE
          ln_end      := gt_sales_h_tbl.COUNT; -- �z��̌���
          ln_run_flag := 1;                    -- �ŏI�̏���
        END IF;
--
      END LOOP n_update_loop;  --����f�[�^�X�V���[�v����
--
      -- ������
      gt_sales_h_tbl.DELETE;
      ln_start            := 1;
      ln_end              := gn_ar_bulk_collect_cnt; --BUKL��������
      ln_run_flag         := 0;
      ln_sales_h_tbl_idx  := 0;
--
      --==============================================================
      -- �̔����уw�b�_�X�V����(�x���I��)
      --==============================================================
      FOR sale_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
        ln_sales_h_tbl_idx := ln_sales_h_tbl_idx + 1;
        gt_sales_h_tbl( ln_sales_h_tbl_idx ) := gt_sales_skip_tbl( sale_idx ).xseh_rowid; --ROWID�Z�b�g
      END LOOP;
--
      -- �Ώۃf�[�^��BUKL����������菬�����ꍇ
      IF ( gn_ar_bulk_collect_cnt > gt_sales_h_tbl.COUNT ) THEN
        ln_end      := gt_sales_h_tbl.COUNT; --�z��̌���
        ln_run_flag := 1;                    --�ŏI�̏���
      END IF;
      --
      <<w_update_loop>>
      LOOP
        FORALL i IN ln_start..ln_end
          UPDATE
            xxcos_sales_exp_headers       xseh
          SET
            xseh.ar_interface_flag      = cv_w_flag,                     -- AR�C���^�t�F�[�X�X�L�b�v
            xseh.last_updated_by        = cn_last_updated_by,            -- �ŏI�X�V��
            xseh.last_update_date       = cd_last_update_date,           -- �ŏI�X�V��
            xseh.last_update_login      = cn_last_update_login,          -- �ŏI�X�V���O�C��
            xseh.request_id             = cn_request_id,                 -- �v��ID
            xseh.program_application_id = cn_program_application_id,     -- �R���J�����g�E�v���O�����E�A�v��ID
            xseh.program_id             = cn_program_id,                 -- �R���J�����g�E�v���O����ID
            xseh.program_update_date    = cd_program_update_date         -- �v���O�����X�V��
          WHERE
            xseh.rowid                  = gt_sales_h_tbl( i );           -- �̔�����ROWID
--
        -- �������p�����邩�`�F�b�N
        EXIT WHEN  ln_run_flag = 1;
--
        -- ���̑Ώۃf�[�^�̔z��ʒu��ݒ�
        ln_start := ln_end + 1;
        -- �ŏI + BULK�������������z��̌����������ꍇ
        IF ( ln_end + gn_ar_bulk_collect_cnt < gt_sales_h_tbl.COUNT ) THEN
          ln_end := ln_end + gn_ar_bulk_collect_cnt;
        ELSE
          ln_end      := gt_sales_h_tbl.COUNT; -- �z��̌���
          ln_run_flag := 1;                    -- �ŏI�̏���
        END IF;
--
      END LOOP w_update_loop;  --�x���f�[�^�X�V���[�v����
--
      -- ������
      gt_sales_h_tbl.DELETE;
      ln_start    := 1;
      ln_end      := gn_ar_bulk_collect_cnt; --BUKL��������
      ln_run_flag := 0;
--
      --==============================================================
      -- �̔����уw�b�_�X�V����(�ΏۊO)
      --==============================================================
      --�J�[�\���I�[�v��
      OPEN no_target_cur;
--
      LOOP
--
        EXIT WHEN no_target_cur%NOTFOUND;
--
        gt_sales_h_tbl.DELETE;
--
        FETCH no_target_cur BULK COLLECT INTO gt_sales_h_tbl LIMIT gn_ar_bulk_collect_cnt;
--
        --�ΏۊO�f�[�^�̍X�V
        FORALL i IN 1..gt_sales_h_tbl.COUNT
          UPDATE
            xxcos_sales_exp_headers       xseh
          SET
            xseh.ar_interface_flag      = cv_s_flag,                     -- AR�C���^�t�F�[�X�ΏۊO
            xseh.last_updated_by        = cn_last_updated_by,            -- �ŏI�X�V��
            xseh.last_update_date       = cd_last_update_date,           -- �ŏI�X�V��
            xseh.last_update_login      = cn_last_update_login,          -- �ŏI�X�V���O�C��
            xseh.request_id             = cn_request_id,                 -- �v��ID
            xseh.program_application_id = cn_program_application_id,     -- �R���J�����g�E�v���O�����E�A�v��ID
            xseh.program_id             = cn_program_id,                 -- �R���J�����g�E�v���O����ID
            xseh.program_update_date    = cd_program_update_date         -- �v���O�����X�V��
          WHERE
            xseh.rowid                  = gt_sales_h_tbl( i );           -- �̔�����ROWID
--
      END LOOP;
--
      --�J�[�\���N���[�Y
      CLOSE no_target_cur;
/* 2009/10/02 Ver1.24 Mod End   */
    EXCEPTION
/* 2009/10/02 Ver1.24 Mod Start */
--      WHEN OTHERS THEN
--          RAISE global_update_data_expt;
      WHEN lock_expt THEN
        IF ( no_target_cur%ISOPEN ) THEN
          CLOSE no_target_cur;
        END IF;
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm        -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_sales_msg         -- ���b�Z�[�WID
                       );
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_table_lock_msg
                         , iv_token_name1  => cv_tkn_tbl
                         , iv_token_value1 => lv_table_name
                       );
        lv_errbuf     := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        IF ( no_target_cur%ISOPEN ) THEN
          CLOSE no_target_cur;
        END IF;
        RAISE global_update_data_expt;
/* 2009/10/02 Ver1.24 Mod End   */
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_update_data_expt THEN
      -- �X�V�Ɏ��s�����ꍇ
      -- �G���[�����ݒ�
      gn_error_cnt := gn_target_cnt;
      lv_tbl_nm    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_nm
                        , iv_name         => cv_tkn_sales_msg
                     );
      ov_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_nm
                        , iv_name         => cv_data_update_msg
                        , iv_token_name1  => cv_tkn_tbl_nm
                        , iv_token_value1 => lv_tbl_nm
                        , iv_token_name2  => cv_tkn_key_data
                        , iv_token_value2 => cv_blank
                      );
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode   := cv_status_error;
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
  END upd_data;
--
/* 2009/10/02 Ver1.24 Add Start */
  /***********************************************************************************
   * Procedure Name   : del_data
   * Description      :  �̔�����AR�p���[�N�폜����(A-10)
   ***********************************************************************************/
  PROCEDURE del_data(
      ov_errbuf       OUT VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2 )  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'del_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm           VARCHAR2(255);          -- �e�[�u����
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
    --==============================================================
    -- �̔�����AR�p���[�N�폜����
    --==============================================================
    BEGIN
      DELETE FROM xxcos_sales_exp_ar_work xseaw
      WHERE xseaw.request_id = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_delete_data_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_delete_data_expt THEN
      -- �폜�Ɏ��s�����ꍇ
      -- �G���[�����ݒ�
      gn_error_cnt := gn_target_cnt;
      lv_tbl_nm    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_nm
                        , iv_name         => cv_tkn_work_msg
                     );
      ov_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_nm
                        , iv_name         => cv_data_delete_msg
                        , iv_token_name1  => cv_tkn_tbl_nm
                        , iv_token_value1 => lv_tbl_nm
                        , iv_token_name2  => cv_tkn_key_data
                        , iv_token_value2 => cv_blank
                      );
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode   := cv_status_error;
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
  END del_data;
/* 2009/10/02 Ver1.24 Add End   */
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �T�u���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
  (
/* 2009/10/02 Ver1.24 Mod Start */
--      ov_errbuf    OUT VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
--    , ov_retcode   OUT VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
--    , ov_errmsg    OUT VARCHAR2 )           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      iv_target       IN  VARCHAR2    -- �����Ώۋ敪 1:��� 2:����
    , iv_create_class IN  VARCHAR2    -- �쐬���敪
    , ov_errbuf       OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2 )  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
/* 2009/10/02 Ver1.24 Add End   */
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
/* 2009/10/02 Ver1.24 Del Start */
--    lv_tbl_nm VARCHAR2(255);                -- �e�[�u����
/* 2009/10/02 Ver1.24 Del End   */
/* 2009/10/02 Ver1.24 Mod Start */
    lv_errbuf_bk  VARCHAR2(5000);           -- �G���[�E���b�Z�[�W(�Ώۃf�[�^�������̑ޔ�p)
    lv_errmsg_bk  VARCHAR2(5000);           -- ���[�U�[�E�G���[�E���b�Z�[�W(�Ώۃf�[�^�������̑ޔ�p)
/* 2009/10/02 Ver1.24 Mod End   */
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt    := 0;                  -- �Ώی���
    gn_normal_cnt    := 0;                  -- ���팏��
    gn_error_cnt     := 0;                  -- �G���[����
    gn_aroif_cnt     := 0;                  -- AR�������OIF�o�^����
    gn_ardis_cnt     := 0;                  -- AR��v�z��OIF�o�^����
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init(
/* 2009/10/02 Ver1.24 Mod Start */
--        ov_errbuf  => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
--      , ov_retcode => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
--      , ov_errmsg  => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        iv_target       => iv_target        -- �����Ώۋ敪
      , iv_create_class => iv_create_class  -- �쐬���敪
      , ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
/* 2009/10/02 Ver1.24 Mod End   */
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2-1.�̔����уf�[�^�擾
    -- ===============================
    get_data(
/* 2009/10/02 Ver1.24 Mod Start */
--        ov_errbuf  => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
--      , ov_retcode => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
--      , ov_errmsg  => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        iv_target       => iv_target        -- �����Ώۋ敪
      , iv_create_class => iv_create_class  -- �쐬���敪
      , ov_errbuf       => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode      => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg       => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
/* 2009/10/02 Ver1.24 Mod End   */
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
/* 2010/03/08 Ver1.27 Mod Start   */
    ELSIF (  gn_target_cnt = 0 ) THEN
--    ELSIF (  lv_retcode = cv_status_warn ) THEN
/* 2010/03/08 Ver1.27 Mod End   */
/* 2009/10/02 Ver1.24 Add Start */
      --�G���[�̑ޔ�
      lv_errbuf_bk  := lv_errbuf;
      lv_errmsg_bk  := lv_errmsg;
      -- ===============================
      -- A-9.�̔����уf�[�^�̍X�V����(�ΏۊO�f�[�^�X�V�̈�)
      -- ===============================
      upd_data(
          iv_target       => iv_target        -- �����Ώۋ敪
        , iv_create_class => iv_create_class  -- �쐬���敪         
        , ov_errbuf       => lv_errbuf           -- �G���[�E���b�Z�[�W
        , ov_retcode      => lv_retcode          -- ���^�[���E�R�[�h
        , ov_errmsg       => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := gn_target_cnt;
        RAISE global_update_data_expt;
      END IF;
--
      --�X�V�����ŃG���[���Ȃ��ꍇ�A�ޔ������l��߂�
      lv_errbuf  := lv_errbuf_bk;
      lv_errmsg  := lv_errmsg_bk;
/* 2009/10/02 Ver1.24 Add Start */
      -- �̔����уf�[�^���o��0�����́A���o���R�[�h�Ȃ��x���ŏI��
      RAISE global_no_data_expt;
    END IF;
--
/* 2009/10/02 Ver1.24 Mod Start */
--      -- ===============================
--      -- A-3.��������W�񏈗��i����ʔ̓X�j
--      -- ===============================
--    IF ( gt_sales_norm_tbl.COUNT > 0 ) THEN
--      edit_sum_data(
--           ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
--         , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
--         , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      IF ( lv_retcode = cv_status_error ) THEN
--        gn_error_cnt := gn_target_cnt;
--        RAISE global_process_expt;
--      END IF;
--    END IF;
--
--      -- ===============================
--      -- A-4.AR��v�z���d��쐬�i����ʔ̓X�j
--      -- ===============================
--    IF ( gt_sales_norm_tbl2.COUNT > 0 ) THEN
--      edit_dis_data(
--           ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
--         , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
--         , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      IF ( lv_retcode = cv_status_error ) THEN
--        gn_error_cnt := gn_target_cnt;
--        RAISE global_process_expt;
--      END IF;
--    END IF;
--
--      -- ===============================
--      -- A-5.AR����������W�񏈗��i���ʔ̓X�j
--      -- ===============================
--    IF ( gt_sales_bulk_tbl.COUNT > 0 ) THEN
--      edit_sum_bulk_data(
--           ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
--         , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
--         , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      IF ( lv_retcode = cv_status_error ) THEN
--        gn_error_cnt := gn_target_cnt;
--        RAISE global_process_expt;
--      END IF;
--    END IF;
--
--      -- ===============================
--      -- A-6.AR��v�z���d��쐬�i���ʔ̓X�j
--      -- ===============================
--    IF ( gt_sales_bulk_tbl2.COUNT > 0 ) THEN
--      edit_dis_bulk_data(
--           ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
--         , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
--         , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      IF ( lv_retcode = cv_status_error ) THEN
--        gn_error_cnt := gn_target_cnt;
--        RAISE global_process_expt;
--      END IF;
--    END IF;
--
--    -- ===============================
--    -- A-7.AR�������OIF�o�^����
--    -- ===============================
--    insert_aroif_data(
--          ov_errbuf       => lv_errbuf     -- �G���[�E���b�Z�[�W
--        , ov_retcode      => lv_retcode    -- ���^�[���E�R�[�h
--        , ov_errmsg       => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
--      );
--    IF ( lv_retcode = cv_status_error ) THEN
--      gn_error_cnt := gn_target_cnt;
--      RAISE global_insert_data_expt;
--    END IF;
--
--    -- ===============================
--    -- A-8.AR��v�z��OIF�o�^����
--    -- ===============================
--    insert_ardis_data(
--          ov_errbuf       => lv_errbuf     -- �G���[�E���b�Z�[�W
--        , ov_retcode      => lv_retcode    -- ���^�[���E�R�[�h
--        , ov_errmsg       => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
--      );
--    IF ( lv_retcode = cv_status_error ) THEN
--      gn_error_cnt := gn_target_cnt;
--      RAISE global_insert_data_expt;
--    END IF;
--
    -- ���[�N�e�[�u���Ɍ���������ꍇ�������s
    IF ( gn_work_cnt <> 0 ) THEN
--
      -- ���菈���̏ꍇ
      IF ( iv_target = cv_not_major ) THEN
--
        -- ===============================
        -- A-2-2.�̔�����AR�p���[�N�f�[�^�擾
        -- ===============================
        OPEN bulk_data_cur;
--
        LOOP
--
          --������
          gt_sales_norm_tbl.DELETE;    -- ���C��SQL�p�z��
          gt_ar_interface_tbl1.DELETE; -- AR�������OIF�C���T�[�g�p�z��
          gt_ar_dis_tbl1.DELETE;       -- AR��v�z��OIF�C���T�[�g�p�z��
--
          --���~�b�g���ɏ�������
          FETCH bulk_data_cur BULK COLLECT INTO gt_sales_norm_tbl LIMIT gn_ar_bulk_collect_cnt;
--
          EXIT WHEN gn_fetch_end_flag = 1;
--
          -- �f�[�^�L���`�F�b�N
          IF ( bulk_data_cur%NOTFOUND ) THEN
            gn_fetch_end_flag := 1; --�Ō��BULK����
          END IF;
--
          -- ===============================
          -- A-3.��������W�񏈗��i����ʔ̓X�j
          -- ===============================
          edit_sum_data(
               ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
             , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
             , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_cnt := gn_target_cnt;
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- A-4.AR��v�z���d��쐬�i����ʔ̓X�j
          -- ===============================
          edit_dis_data(
               ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
             , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
             , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_cnt := gn_target_cnt;
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- A-7.AR�������OIF�o�^����
          -- ===============================
          insert_aroif_data(
               iv_target       => iv_target     -- �����Ώۋ敪
             , ov_errbuf       => lv_errbuf     -- �G���[�E���b�Z�[�W
             , ov_retcode      => lv_retcode    -- ���^�[���E�R�[�h
             , ov_errmsg       => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_cnt := gn_target_cnt;
            RAISE global_insert_data_expt;
          END IF;
--
          -- ===============================
          -- A-8.AR��v�z��OIF�o�^����
          -- ===============================
          insert_ardis_data(
              ov_errbuf       => lv_errbuf     -- �G���[�E���b�Z�[�W
            , ov_retcode      => lv_retcode    -- ���^�[���E�R�[�h
            , ov_errmsg       => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_cnt := gn_target_cnt;
            RAISE global_insert_data_expt;
          END IF;
--
          --2��ڈȍ~��BUKL�����ŏ��������������Ȃ�
          gn_fetch_first_flag := 1;
--
        END LOOP;
--
      -- ��菈���̏ꍇ
      ELSIF ( iv_target = cv_major ) THEN
--
        -- ===============================
        -- A-2-2.�̔�����AR�p���[�N�f�[�^�擾
        -- ===============================
/* 2009/11/05 Ver1.26 Mod Start */
--        OPEN bulk_data_cur;
        OPEN bulk_data_cur2;
/* 2009/11/05 Ver1.26 Mod End   */
--
        LOOP
--
          --������
          gt_sales_bulk_tbl.DELETE;    -- ���C��SQL�p�z��
          gt_ar_interface_tbl1.DELETE; -- AR�������OIF�C���T�[�g�p�z��
          gt_ar_dis_tbl1.DELETE;       -- AR��v�z��OIF�C���T�[�g�p�z��
--
          --���~�b�g���ɏ�������
/* 2009/11/05 Ver1.26 Mod Start */
--          FETCH bulk_data_cur BULK COLLECT INTO gt_sales_bulk_tbl LIMIT gn_ar_bulk_collect_cnt;
          FETCH bulk_data_cur2 BULK COLLECT INTO gt_sales_bulk_tbl LIMIT gn_ar_bulk_collect_cnt;
/* 2009/11/05 Ver1.26 Mod End   */
--
          EXIT WHEN gn_fetch_end_flag = 1;
--
          -- �f�[�^�L���`�F�b�N
/* 2009/11/05 Ver1.26 Mod Start */
--          IF ( bulk_data_cur%NOTFOUND ) THEN
          IF ( bulk_data_cur2%NOTFOUND ) THEN
/* 2009/11/05 Ver1.26 Mod End   */
            gn_fetch_end_flag := 1; --�Ō��BULK����
          END IF;
--
          -- ===============================
          -- A-5.AR����������W�񏈗��i���ʔ̓X�j
          -- ===============================
          edit_sum_bulk_data(
               ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
             , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
             , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_cnt := gn_target_cnt;
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- A-6.AR��v�z���d��쐬�i���ʔ̓X�j
          -- ===============================
          edit_dis_bulk_data(
               ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
             , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
             , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_cnt := gn_target_cnt;
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- A-7.AR�������OIF�o�^����
          -- ===============================
          insert_aroif_data(
               iv_target       => iv_target     -- �����Ώۋ敪
             , ov_errbuf       => lv_errbuf     -- �G���[�E���b�Z�[�W
             , ov_retcode      => lv_retcode    -- ���^�[���E�R�[�h
             , ov_errmsg       => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_cnt := gn_target_cnt;
            RAISE global_insert_data_expt;
          END IF;
--
          -- ===============================
          -- A-8.AR��v�z��OIF�o�^����
          -- ===============================
          insert_ardis_data(
              ov_errbuf       => lv_errbuf     -- �G���[�E���b�Z�[�W
            , ov_retcode      => lv_retcode    -- ���^�[���E�R�[�h
            , ov_errmsg       => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_cnt := gn_target_cnt;
            RAISE global_insert_data_expt;
          END IF;
--
          --2��ڈȍ~��BUKL�����ŏ��������������Ȃ�
          gn_fetch_first_flag := 1;
--
        END LOOP;
--
      END IF;
--
      -- �z��폜
      gt_jour_cls_tbl.DELETE;
      gt_sel_ccid_tbl.DELETE;
--
    END IF;
--
/* 2009/10/02 Ver1.24 Mod End   */
    -- ===============================
    -- A-9.�̔����уf�[�^�̍X�V����
    -- ===============================
    upd_data(
/* 2009/10/02 Ver1.24 Mod Start */
--        ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
--      , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
--      , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        iv_target       => iv_target        -- �����Ώۋ敪
      , iv_create_class => iv_create_class  -- �쐬���敪         
      , ov_errbuf       => lv_errbuf           -- �G���[�E���b�Z�[�W
      , ov_retcode      => lv_retcode          -- ���^�[���E�R�[�h
      , ov_errmsg       => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
/* 2009/10/02 Ver1.24 Mod End   */
      );
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := gn_target_cnt;
      RAISE global_update_data_expt;
    END IF;
/* 2009/10/02 Ver1.24 Add Start */
    IF ( gn_work_cnt <> 0 ) THEN
      -- ===============================
      -- A-10.�̔�����AR�p���[�N�폜����
      -- ===============================
      del_data(
          ov_errbuf       => lv_errbuf           -- �G���[�E���b�Z�[�W
        , ov_retcode      => lv_retcode          -- ���^�[���E�R�[�h
        , ov_errmsg       => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := gn_target_cnt;
        RAISE global_update_data_expt;
      END IF;
    END IF;
/* 2009/10/02 Ver1.24 Add End   */
--
    -- �����������Z�b�g
/* 2009/10/02 Ver1.24 Mod Start */
--    gn_aroif_cnt  := gt_ar_interface_tbl1.COUNT;                      -- AR�������OIF�o�^����
--    gn_ardis_cnt  := gt_ar_dis_tbl1.COUNT;                            -- AR��v�z��OIF�o�^����
    gn_aroif_cnt  := gn_aroif_cnt_tmp;             -- AR�������OIF�o�^����
    gn_ardis_cnt  := gn_ardis_cnt_tmp;             -- AR��v�z��OIF�o�^����
/* 2009/10/02 Ver1.24 Mod End   */
    gn_normal_cnt := gn_aroif_cnt + gn_ardis_cnt;
--
    IF ( gn_warn_flag = cv_y_flag ) THEN
--
      IF ( gt_sales_skip_tbl.COUNT > 0 ) THEN
        --�X�L�b�v�����v�Z����
/* 2009/10/02 Ver1.24 Mod Start */
--        <<gt_sales_exp_tbl2_loop>>
--        FOR sale_idx IN 1 .. gt_sales_exp_tbl2.COUNT LOOP
        <<gt_sales_target_tbl_loop>>
        FOR sale_idx IN 1 .. gt_sales_target_tbl.COUNT LOOP
/* 2009/10/02 Ver1.24 Mod End   */
          gv_skip_flag := cv_n_flag;
          -- �X�L�b�v����
          <<gt_sales_skip_tbl_loop>>
          FOR skip_idx IN 1 .. gt_sales_skip_tbl.COUNT LOOP
            IF( gt_sales_skip_tbl( skip_idx ).sales_exp_header_id
/* 2009/10/02 Ver1.24 Mod Start */
--                  = gt_sales_exp_tbl2( sale_idx ).sales_exp_header_id ) THEN
                = gt_sales_target_tbl( sale_idx ).sales_exp_header_id ) THEN
/* 2009/10/02 Ver1.24 Mod End   */
              gv_skip_flag := cv_y_flag;
              EXIT;
            END IF;
          END LOOP gt_sales_skip_tbl_loop;
--
          IF ( gv_skip_flag = cv_y_flag ) THEN
            gn_skip_cnt := gn_skip_cnt + 1;
          END IF;
/* 2009/10/02 Ver1.24 Mod Start */
--        END LOOP gt_sales_exp_tbl2_loop;
        END LOOP gt_sales_target_tbl_loop;
/* 2009/10/02 Ver1.24 Mod End   */
      END IF;
--
      RAISE global_card_inf_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ώۃf�[�^�Ȃ� ***
    WHEN global_no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
/* 2010/03/08 Ver1.27 Mod Start   */
      ov_retcode := cv_status_normal;
--      ov_retcode := cv_status_warn;
/* 2010/03/08 Ver1.27 Mod End   */
    -- *** �f�[�^�擾��O ***
    WHEN global_select_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �o�^������O ***
    WHEN global_insert_data_expt THEN
/* 2009/10/02 Ver1.24 Add Start */
      IF ( bulk_data_cur%ISOPEN ) THEN
        CLOSE bulk_data_cur;
      END IF;
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
      IF ( bulk_data_cur2%ISOPEN ) THEN
        CLOSE bulk_data_cur2;
      END IF;
/* 2009/11/05 Ver1.26 Add End   */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �X�V������O ***
    WHEN global_update_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_card_inf_expt THEN
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
/* 2009/10/02 Ver1.24 Add Start */
      IF ( bulk_data_cur%ISOPEN ) THEN
        CLOSE bulk_data_cur;
      END IF;
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
      IF ( bulk_data_cur2%ISOPEN ) THEN
        CLOSE bulk_data_cur2;
      END IF;
/* 2009/11/05 Ver1.26 Add End   */
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
/* 2009/10/02 Ver1.24 Add Start */
      IF ( bulk_data_cur%ISOPEN ) THEN
        CLOSE bulk_data_cur;
      END IF;
/* 2009/10/02 Ver1.24 Add End   */
/* 2009/11/05 Ver1.26 Add Start */
      IF ( bulk_data_cur2%ISOPEN ) THEN
        CLOSE bulk_data_cur2;
      END IF;
/* 2009/11/05 Ver1.26 Add End   */
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
/* 2009/10/02 Ver1.24 Mod Start */
--      errbuf      OUT VARCHAR2               -- �G���[�E���b�Z�[�W  --# �Œ� #
--    , retcode     OUT VARCHAR2 )             -- ���^�[���E�R�[�h    --# �Œ� #
      errbuf          OUT   VARCHAR2    -- �G���[�E���b�Z�[�W  --# �Œ� #
    , retcode         OUT   VARCHAR2    -- ���^�[���E�R�[�h    --# �Œ� #
    , iv_target       IN    VARCHAR2    -- �����Ώۋ敪 1:��� 2:����
    , iv_create_class IN    VARCHAR2 )  -- �쐬���敪
/* 2009/10/02 Ver1.24 Add End   */
  IS
--
--###########################  �Œ蕔 START   ###########################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10) := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(20) := 'COUNT';             -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);       -- �I�����b�Z�[�W�R�[�h
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
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
/* 2009/10/02 Ver1.24 Add Start */
--        ov_errbuf  => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
--      , ov_retcode => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
--      , ov_errmsg  => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        iv_target       => iv_target         -- �����Ώۋ敪 1:��� 2:����
      , iv_create_class => iv_create_class   -- �쐬���敪
      , ov_errbuf       => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode      => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg       => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
/* 2009/10/02 Ver1.24 Add End   */
    );
--
    --�G���[�o��
/* 2010/03/08 Ver1.27 Mod Start   */
    IF (lv_retcode = cv_status_error OR lv_retcode = cv_status_warn OR gn_target_cnt = 0 ) THEN
--    IF (lv_retcode = cv_status_error OR lv_retcode = cv_status_warn) THEN
/* 2010/03/08 Ver1.27 Mod End   */
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ===============================
    -- A-7.�I������
    -- ===============================
    --��s�}��
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --���������o��:AR�������OIF
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_nm
                    , iv_name         => cv_success_aroif_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_aroif_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --���������o��:AR��v�z��OIF
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_nm
                    , iv_name         => cv_success_ardis_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_ardis_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_short_nm
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_skip_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_xxccp_short_nm
                    , iv_name        => lv_message_code
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
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
END XXCOS013A01C;
/
