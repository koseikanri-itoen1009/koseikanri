CREATE OR REPLACE PACKAGE BODY XXCOS001A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS001A05C (body)
 * Description      : �o�׊m�F�����iHHT�[�i�f�[�^�j
 * MD.050           : �o�׊m�F����(MD050_COS_001_A05)
 * Version          : 1.14
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_inp_molded_hht    �̔����уf�[�^(�[�i�`�[���͉��)���^����(A-9)
 *  proc_flg_update        �擾���e�[�u���t���O�X�V(A-10)
 *  proc_om_close          OM�N���[�Y����(A-7)
 *  proc_insert            �̔����уf�[�^�o�^����(A-6)
 *  proc_molded_trans      �̔����уf�[�^�i���o�Ɂj���^����(A-5)
 *  proc_molded_edi        �̔����уf�[�^(EDI)���^����(A-4)
 *  proc_molded_hht        �̔����уf�[�^(HHT)���^����(A-3)
 *  proc_extract           �f�[�^���o����(A-2)
 *  proc_init              ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/15    1.0   N.Maeda          �V�K�쐬
 *  2009/2/3      1.1   N.Maeda          �S�ݓX���͋敪���f�����̕ύX
 *                                       �]�ƈ��r���[�̋��_�擾�����̒ǉ�
 *                                       �[�i�`�[���͉�ʓo�^�f�[�^���^����(A-9)�̒ǉ�
 *  2009/02/17    1.2   N.Maeda          ����ŗ��擾�����ɗL���t���O��ǉ�
 *                                       get_msg�̃p�b�P�[�W���C��
 *  2009/02/18    1.3   N.Maeda          �ڋq���擾���̏����ύX(�duns_number��ˢduns_number_c�)
 *  2009/02/20    1.4   N.Maeda          �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/03/18    1.5   T.Kitajima       [T1_0066] HHT�[�i�f�[�^�̔̔����јA�g���ɂ�����ݒ荀�ڂ̕s��
 *                                       [T1_0078] ���z�̒[���v�Z���������s���Ă��Ȃ�
 *  2009/03/23    1.6   N.Maeda          [T1_0078] ���z�̒[�������������̏C��
 *  2009/04/03    1.7   N.Maeda          [T1_0256] HHT�S�ݓX�ۊǏꏊ���o�������C��
 *  2009/04/07    1.8   N.Maeda          [T1_0248] HHt�S�ݓX���͋敪��null�łȂ����̔�����e��ύX
 *  2009/04/09    1.9   N.Maeda          [T1_0401_427]
 *                                                 �O�ŁA����(�`�[�ې�)���̔�����z�̌v�Z���@�C��
 *                                                 �O�Ŏ��̔�����z���v�̌v�Z���@�C��
 *                                                 ���o�Ƀf�[�^�̔̔�����(�[�i����)�ݒ�l�ɑ��{����ݒ�
 *  2009/04/14    1.10  N.Maeda          [T1_0532] �w�b�_����ŋ��z���v�Z�o�l�̑���l�C��
 *  2009/04/14    1.11  N.Maeda          [T1_0537_0544_558]���o�Ƀf�[�^�̔̔�����(�����)�ݒ�l�ɑ��{����ݒ�
 *                                                 ���o�Ƀf�[�^�o�^���̔[�i���הԍ����V�[�P���X�擾����w�b�_���̕��Ԃ֕ύX
 *                                                 �S�ݓXHHT���̕ۊǏꏊ�擾���@�̕ύX
 *  2009/04/16    1.12  N.Maeda          [T1_0350_0447_0450_0589_0712]�������_�R�[�h�擾�A�̔����ѓ������_�R�[�h�ւ̓o�^�̒ǉ�
 *                                                 ���o�Ƀf�[�^�w�b�_�J�E���g�����o�͒ǉ�
 *                                                 �[�i�`�[���͉�ʓo�^�f�[�^���o�����ύX
 *                                                 �g�����U�N�V��������C��
 *                                                 �Ώۃf�[�^���o�����̕ύX
 *  2009/05/12    1.13  N.Maeda          [T1_0768] �[�i�`�[��ʓo�^�f�[�^��OM�󒍃N���[�Y�����ǉ�
 *  2009/05/13    1.14  N.Maeda          [T1_0969_1005] ���o�Ƀf�[�^�̌ڋq�}�X�^�擾���̕ύX�A�o�׋��_�R�[�h�̐ݒ荀�ڕύX
 *                                                      ���{���[�i�`�[�敪�擾���ڕύX
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
  -- ���b�N�G���[
  lock_err_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_err_expt, -54 );
  -- �Ώۃf�[�^���o�G���[
  data_extract_err_expt    EXCEPTION;
  -- ���o�ΏۂȂ��G���[
  no_data_extract          EXCEPTION;
  -- �[�i�`�ԋ敪�G���[
  delivered_from_err_expt  EXCEPTION;
  -- �̔����уf�[�^�o�^�G���[
  insert_err_expt          EXCEPTION;
  -- �X�V�G���[
  updata_err_expt          EXCEPTION;
  -- �N�[���[�Y�����G���[
  no_complet_expt          EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOS001A05C';         -- �p�b�P�[�W��
  cv_application              CONSTANT VARCHAR2(5)   := 'XXCOS';                -- �A�v���P�[�V������
  cv_application_coi          CONSTANT VARCHAR2(5)   := 'XXCOI';                -- �A�v���P�[�V������
  cv_prf_orga_code            CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:�݌ɑg�D�R�[�h
  cv_disc_item_code           CONSTANT VARCHAR2(50)  := 'XXCOS1_DISCOUNT_ITEM_CODE'; -- �l�����i�ڃR�[�h
  cv_org_id                   CONSTANT VARCHAR2(10)  := 'ORG_ID';               -- MO:�c�ƒP�ʎ擾�p�R�[�h
  cv_prf_max_date             CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';      -- XXCOS:MAX���t
  cv_prf_bks_id               CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';     -- GL��v����ID
  -- �G���[�R�[�h
  cv_loc_err                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';     -- ���b�N�G���[
  cv_msg_extract_err          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10001';     -- ���o�G���[
  cv_msg_pro                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';     -- �v���t�@�C���擾�G���[
  cv_msg_target_no_data       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00083';     -- ���͑Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_max_date             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';     -- XXCOS:MAX���t
  cv_msg_orga                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10024';     -- �݌ɑg�DID�擾�G���[
  cv_msg_date                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10025';     -- �Ɩ��������擾�G���[
  cv_msg_orga_code            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10048';     -- �݌ɑg�D�R�[�h
  cv_msg_no_data              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';     -- �}�X�^�f�[�^�擾�G���[
  cv_msg_delivered_from_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10104';     -- �[�i�`�ԋ敪�G���[
  cv_msg_tab_ins_err          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10351';     -- �o�^�G���[
  cv_msg_update_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';     -- �X�V�G���[
  cv_msg_close_err            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10252';     -- OM�󒍃N���[�Y�G���[
  cv_msg_b_k_ping             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10253';     -- �L���G���[
  -- ������擾�p�R�[�h(�e�[�u����)
  cv_msg_selse_unit           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';     -- �c�ƒP��
  cv_msg_disc_item            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00090';     -- ����l�����i�ڃR�[�h
  cv_msg_dlv_head             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10031';     -- �[�i�w�b�_�e�[�u��
  cv_msg_dlv_line             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10032';     -- �[�i���׃e�[�u��
  cv_msg_transactions         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00093';     -- HHT���o�Ɉꎞ�\
  cv_msg_cus_mst              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00049';     -- �ڋq�}�X�^
  cv_msg_lookup_mst           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00066';     -- �Q�ƃR�[�h�}�X�^
  cv_ar_tax_mst               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00067';     -- AR����Ń}�X�^
  cv_inv_item_mst             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00050';     -- �i�ڃ}�X�^
  cv_location_mst             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00052';     -- �ۊǏꏊ�}�X�^
  cv_emp_data_mst             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00068';     -- �]�ƈ����VIEW
  cv_om_order                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00128';     -- OM�󒍏��
  cv_msg_tab_xxcos_sal_exp_head CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00086';    -- �̔����уw�b�_
  cv_msg_tab_xxcos_sal_exp_line CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00087';    -- �̔����і���
  cv_msg_dlv_tab              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00172';     -- �[�i�e�[�u��
  -- ������擾�p�R�[�h(�J������)
  cv_msg_cus_type             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00074';     -- �ڋq�敪
  cv_msg_cus_code             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00053';     -- �ڋq�R�[�h
  cv_msg_lookup_code          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00082';     -- �Q�ƃR�[�h
  cv_msg_lookup_type          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00075';     -- �Q�ƃ^�C�v
  cv_msg_lookup_tax           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00076';     -- ����ŃR�[�h�i�Q�ƃR�[�h�}�X�^DFF2)
  cv_msg_item_code            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10041';     -- �i�ڃR�[�h
  cv_msg_base_code            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00055';     -- ���_�R�[�h
  cv_msg_org_id               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00063';     -- �݌ɑg�DID
  cv_msg_type                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00077';     -- �^�C�v
  cv_msg_code                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00078';     -- �R�[�h
  cv_msg_location_type        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00079';     -- �ۊǏꏊ�敪
  cv_msg_dlv                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00080';     -- �[�i�҃R�[�h
  cv_msg_lookup_inp           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00081';     -- �Q�ƃR�[�h�i���͋敪�j
  cv_msg_lookup_rec_type      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00135';     -- �Q�ƃR�[�h�i���R�[�h��ʁj
  cv_msg_gl_books             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00060';     -- GL��v����
  cv_order_no                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00129';     -- �󒍔ԍ�
  cv_order_s_name             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10251';     -- EDI��
  
  -- ������擾�p�R�[�h(����API����)
  cv_close_api                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11532';     -- �󒍃N���[�YAPI
  -- ���b�Z�[�W�o��
  cv_msg_count_he_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00141';     -- �w�b�_�Ώی���
  cv_msg_count_li_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00142';     -- ���בΏی���
  cv_msg_count_he_update      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00143';     -- �w�b�_�o�^��������
  cv_msg_count_li_update      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00144';     -- ���דo�^��������
  -- �g�[�N��
  cv_tkn_profile              CONSTANT VARCHAR2(20)  := 'PROFILE';              -- �v���t�@�C����
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';                -- �e�[�u����
  cv_tkn_table_name           CONSTANT VARCHAR2(20)  := 'TABLE_NAME';           -- �g�[�N��'TABLE_NAME'
  cv_tkn_table_na             CONSTANT VARCHAR2(20)  := 'TABLE _NAME';          -- �g�[�N��'TABLE _NAME'
  cv_key_data                 CONSTANT VARCHAR2(20)  := 'KEY_DATA';             -- �g�[�N��'KEY_DATA'
  cv_tkn_api_name             CONSTANT VARCHAR2(20)  := 'API_NAME';             -- ���ʊ֐���
  cv_err_msg                  CONSTANT VARCHAR2(20)  := 'ERR_MSG';              -- ���ʊ֐��G���[���b�Z�[�W
  cv_count_num                CONSTANT VARCHAR2(20)  := 'COUNT';                -- �J�E���g��
  cv_line_number              CONSTANT VARCHAR2(20)  := 'LINE_NUMBER';          -- ���הԍ�
  -- �f�[�^�擾�p�Œ�l
--  cn_cust_s                   CONSTANT NUMBER  := 30;                           -- �ڋq
--  cn_cust_v                   CONSTANT NUMBER  := 40;                           -- ��l
--  cn_cost_p                   CONSTANT NUMBER  := 50;                           -- �x�~
  cv_cust_s                   CONSTANT VARCHAR2(2)  := '30';                    -- �ڋq
  cv_cust_v                   CONSTANT VARCHAR2(2)  := '40';                    -- ��l
  cv_cost_p                   CONSTANT VARCHAR2(2)  := '50';                    -- �x�~
  cn_api_ver_num              CONSTANT NUMBER  := 1.0;                          -- �󒍕W��API�o�[�W����(1.0)
  cv_fs_vd_s                  CONSTANT VARCHAR2(10)  := '24';                   -- �Ƒԋ敪(�t���T�[�r�X(����)VD)
  cv_fs_vd                    CONSTANT VARCHAR2(10)  := '25';                   -- �Ƒԋ敪(�t���T�[�r�XVD)
  cv_input_delivery           CONSTANT VARCHAR2(10)  := '1';                    -- ���͋敪(�[�i����)
  cv_input_return             CONSTANT VARCHAR2(10)  := '2';                    -- ���͋敪(�ԕi����)
  cv_input_vd_return          CONSTANT VARCHAR2(10)  := '4';                    -- ���͋敪(���̋@�ԕi)
  cv_input_fs_vd_return       CONSTANT VARCHAR2(10)  := '5';                    -- ���͋敪(�t��VD�[�i������z��)
  cv_untreated_flg            CONSTANT VARCHAR2(1)  := '0';                    -- �̔����јA�g�ς݃t���O(������)
--  cv_order_no_ebs_hht         CONSTANT VARCHAR2(10)  := '0';                    -- ��No�iEBS�j(HHT�`�[)
  cv_record_type_sample       CONSTANT VARCHAR2(10)  := '40';                   -- ���R�[�h���(���{)
  cv_customer_type_c          CONSTANT VARCHAR2(10)  := '10';                   -- �ڋq�敪(�ڋq)
  cv_customer_type_u          CONSTANT VARCHAR2(10)  := '12';                   -- �ڋq�敪(��l)
--  cv_consum_code_out_tax      CONSTANT VARCHAR2(10)  := '0';                    -- �ŃR�[�h(�O��)
--  cv_consum_code_no_tax       CONSTANT VARCHAR2(10)  := '3';                    -- �ŃR�[�h(��ې�)
  cv_depart_screen_class_base CONSTANT VARCHAR2(10)  := '0';                    -- HHT�S�ݓX��ʎ��(���_)
  cv_depart_screen_class_dep  CONSTANT VARCHAR2(10)  := '2';                    -- HHT�S�ݓX��ʎ��(�S�ݓX)
  cv_bace_branch              CONSTANT VARCHAR2(10)  := '1';                    -- �ڋq�敪(���_)
  cv_depart_type              CONSTANT VARCHAR2(10)  := '1';                    -- HHT�S�ݓX���͋敪(�S�ݓX)
  cv_depart_type_k            CONSTANT VARCHAR2(10)  := '2';                    -- HHT�S�ݓX���͋敪(�S�ݓX_���_)
  cv_input_class_eos          CONSTANT VARCHAR2(10)  := '1';                    -- �[�i���́EEOS�`�[����
  cv_input_class_rt           CONSTANT VARCHAR2(10)  := '2';                    -- �ԕi����
  cv_input_class_vd           CONSTANT VARCHAR2(10)  := '3';                    -- ���̋@����
  cv_input_class_vd_rt        CONSTANT VARCHAR2(10)  := '4';                    -- ���̋@�ԕi
  cv_sales_st_class           CONSTANT VARCHAR2(10)  := '1';                    -- ����敪(�ʏ�)
  cv_sales_class              CONSTANT VARCHAR2(10)  := '6';                    -- ����敪(���{)
  cv_forward_flag_alr         CONSTANT VARCHAR2(10)  := '2';                    -- �A�g�ς݃t���O(�A�g�ς�)
  cv_standard_qty             CONSTANT VARCHAR2(10)  := '0';                    -- �����(0)
  cv_standard_unit_price      CONSTANT VARCHAR2(10)  := '0';                    -- ��P��(0)
  cv_sale_amount              CONSTANT VARCHAR2(10)  := '0';                    -- ������z(0)
  cv_pure_amount              CONSTANT VARCHAR2(10)  := '0';                    -- �{�̋��z(0)
  cv_tax_amount               CONSTANT VARCHAR2(10)  := '0';                    -- ����ŋ��z(0)
  cv_cash_and_card            CONSTANT VARCHAR2(10)  := '0';                    -- �����E�J�[�h���p�z(0)
  cv_not_tax_amount           CONSTANT VARCHAR2(10)  := '0';                    -- �Ŕ���P��(0)
  cv_sample_if_flag           CONSTANT VARCHAR2(1)   := 'N';                    -- ���{�]���ς݃t���O(���]��)
  -- ���f�[�^����ŋ敪
  cv_non_tax                  CONSTANT VARCHAR(10)  := '0';                     -- ��ې�
  cv_out_tax                  CONSTANT VARCHAR(10)  := '1';                     -- �O��
  cv_ins_slip_tax             CONSTANT VARCHAR(10)  := '2';                     -- ���Łi�`�[�ېŁj
  cv_ins_bid_tax              CONSTANT VARCHAR(10)  := '3';                     -- ���Łi�P�����݁j
  --
  cn_cons_tkn_zero            CONSTANT NUMBER  := 0;                            -- '0'
  cv_xxcos1_cust_site_use_code CONSTANT VARCHAR2(50)  := 'XXCOS1_CUST_SITE_USE_CODE'; -- �g�p�敪����}�X�^
  cv_xxcos_001_ship           CONSTANT VARCHAR2(50)  := 'XXCOS_001_SHIP';             -- ������
  cv_lookup_type              CONSTANT VARCHAR2(50)  := 'XXCOS1_CONSUMPTION_TAX_CLASS';  -- ����ŋ敪
  cv_xxcos1_cons_tax_no       CONSTANT VARCHAR2(50)  := 'XXCOS1_CONS_TAX_NO_APPLICABLE'; -- ����ŋ敪(�ΏۊO)
  cv_xxcos1_hokan_mst_001_a05 CONSTANT VARCHAR2(50)  := 'XXCOS1_HOKAN_TYPE_MST_001_A05'; -- �ۊǏꏊ���ޓ���}�X�^
  cv_xxcos_001_a05_01         CONSTANT VARCHAR2(50)  := 'XXCOS_001_A05_01';            -- �ʏ틒�_
  cv_xxcos_001_a05_05         CONSTANT VARCHAR2(50)  := 'XXCOS_001_A05_05';            -- �c�Ǝ�
  cv_xxcos_001_a05_09         CONSTANT VARCHAR2(50)  := 'XXCOS_001_A05_09';            -- �S�ݓX�a����
  cv_xxcos1_input_class       CONSTANT VARCHAR2(50)  := 'XXCOS1_INPUT_CLASS';          -- ���͋敪
  cv_xxcoi1_hht_inv_data_div  CONSTANT VARCHAR2(50)  := 'XXCOI1_HHT_INV_DATA_DIV';     -- ���o��T-���R�[�h���
--
  cv_tkn_oeol                 CONSTANT VARCHAR2(10) := 'OEOL';                         -- �N���[�Y�֐��p�萔
  cv_xxcos_r_standard_line    CONSTANT VARCHAR2(50) := 'XXCOS_R_STANDARD_LINE:BLOCK';  -- �N���[�Y�֐��p�萔
  cv_status_booked            CONSTANT VARCHAR2(10) := 'BOOKED';                -- �w�b�_�X�e�[�^�X(�L���ς�) 
  cv_status_type_can          CONSTANT VARCHAR2(10) := 'CANCELLED';             -- �X�e�[�^�X(�L�����Z��)
  cv_status_type_clo          CONSTANT VARCHAR2(10) := 'CLOSE';                 -- �X�e�[�^�X(�N���[�Y)
--  cv_tkn_ja                   CONSTANT VARCHAR2(10) := 'JA';                    -- �g�[�N��'JA'
  cv_tkn_yes                  CONSTANT VARCHAR2(10)  := 'Y';                    -- �g�[�N��'Y'
  cv_tkn_no                   CONSTANT VARCHAR2(10)  := 'N';                    -- �g�[�N��'N'
  -- ���̑��g�[�N��
  cv_con_char                 CONSTANT VARCHAR2(5)  := ',';                     -- �J���}
  cv_space_char               CONSTANT VARCHAR2(5)  := ' ';                     -- �X�y�[�X
  cv_key_name_null            CONSTANT VARCHAR2(5)  := NULL;                    -- �L�[�l�[���uNULL�v
  cv_tkn_null                 CONSTANT VARCHAR2(5)  := NULL;                    -- �g�[�N���NULL�
  cv_tkn_n                    CONSTANT VARCHAR2(5)  := 'N';                     -- �g�[�N���N�
  cv_stand_date               CONSTANT VARCHAR2(25) := 'YYYY/MM/DD HH24:MI:SS'; -- �����`��
  cv_short_day                CONSTANT VARCHAR2(25) := 'YYYY/MM/DD';            -- ���t�`��
  cv_short_time               CONSTANT VARCHAR2(25) := 'HH24:MI:SS';            -- ���Ԍ`��
  cv_tkn_ti                   CONSTANT VARCHAR(10)  := ':';                     -- �R����
  cv_amount_up                CONSTANT VARCHAR(5)   := 'UP';                    -- �����_�[��(�؏�)
  cv_amount_down              CONSTANT VARCHAR(5)   := 'DOWN';                  -- �����_�[��(�؎̂�)
  cv_amount_nearest           CONSTANT VARCHAR(10)  := 'NEAREST';               -- �����_�[��(�l�̌ܓ�)
--******************************* 2009/05/15 N.Maeda Var1.14 MOD START ***************************************
--  cn_red_black_flag_stand     CONSTANT NUMBER  := 0;                            -- �ԍ��t���O(�ʏ�)
  cv_red_black_flag_stand     CONSTANT VARCHAR(1)  := '1';                            -- �ԍ��t���O(�ʏ�)
--******************************* 2009/05/15 N.Maeda Var1.14 MOD END ***************************************
  cv_stand_class              CONSTANT VARCHAR(10)  := NULL;                    -- ����E�����敪(�ʏ�)
--******************************* 2009/05/15 N.Maeda Var1.14 MOD START ***************************************
--  cv_red_black_flag_correct   CONSTANT VARCHAR(10)  := '1';                     -- �ԍ��t���O(����)
  cv_red_black_flag_correct   CONSTANT VARCHAR(10)  := '0';                     -- �ԍ��t���O(����)
--******************************* 2009/05/15 N.Maeda Var1.14 MOD END ***************************************
  cn_correct_class            CONSTANT NUMBER  := 1;                            -- ����E�����敪(����)
  cn_cancel_class             CONSTANT NUMBER  := 2;                            -- ����E�����敪(���)
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--  cv_black_flag               CONSTANT NUMBER  := '1';                      -- �ԁE���t���O(��)
--  cv_red_flag                 CONSTANT NUMBER  := '0';                      -- �ԁE���t���O(��)
  cv_black_flag               CONSTANT VARCHAR(1)  := '1';                      -- �ԁE���t���O(��)
  cv_red_flag                 CONSTANT VARCHAR(1)  := '0';                      -- �ԁE���t���O(��)
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
  cn_tkn_zero                 CONSTANT NUMBER  := 0;                            -- �g�[�N���0�
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--  cn_tkn_shipping_chk         CONSTANT NUMBER  := 4;                            -- ��Ƌ敪(�o�׊m�F����)
  cv_tkn_shipping_chk         CONSTANT VARCHAR(2)  := '4';                            -- ��Ƌ敪(�o�׊m�F����)
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
  cn_disc_standard_qty        CONSTANT NUMBER  := 0;                            -- �l�������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �[�i�w�b�_�f�[�^�i�[�p�ϐ�
  TYPE g_rec_dlv_head_data IS RECORD
    (
     row_id                       ROWID,                                          -- �sID
     order_no_hht                 xxcos_dlv_headers.order_no_hht%TYPE,            -- ��No.(HHT)
     digestion_ln_number          xxcos_dlv_headers.digestion_ln_number%TYPE,     -- �}��
     order_no_ebs                 xxcos_dlv_headers.order_no_ebs%TYPE,            -- ��No.�iEBS�j
     base_code                    xxcos_dlv_headers.base_code%TYPE,               -- ���_�R�[�h
     performance_by_code          xxcos_dlv_headers.dlv_by_code%TYPE,             -- ���ю҃R�[�h
     dlv_by_code                  xxcos_dlv_headers.hht_invoice_no%TYPE,          -- �[�i�҃R�[�h
     hht_invoice_no               xxcos_dlv_headers.hht_invoice_no%TYPE,          -- HHT�`�[No.
     dlv_date                     xxcos_dlv_headers.dlv_date%TYPE,                -- �[�i��
     inspect_date                 xxcos_dlv_headers.inspect_date%TYPE,            -- ������
     sales_classification         xxcos_dlv_headers.sales_classification%TYPE,    -- ���㕪�ދ敪
     sales_invoice                xxcos_dlv_headers.sales_invoice%TYPE,           -- ����`�[�敪
     card_sale_class              xxcos_dlv_headers.card_sale_class%TYPE,         -- �J�[�h����敪
     dlv_time                     xxcos_dlv_headers.dlv_time%TYPE,                -- ����
     customer_number              xxcos_dlv_headers.customer_number%TYPE,         -- �ڋq�R�[�h
     change_out_time_100          xxcos_dlv_headers.change_out_time_100%TYPE,     -- ��K�؂ꎞ��100�~
     change_out_time_10           xxcos_dlv_headers.change_out_time_10%TYPE,      -- ��K�؂ꎞ��10�~
     system_class                 xxcos_dlv_headers.system_class%TYPE,            -- �Ƒԋ敪
     input_class                  xxcos_dlv_headers.input_class%TYPE,             -- ���͋敪
     consumption_tax_class        xxcos_dlv_headers.consumption_tax_class%TYPE,   -- ����ŋ敪
     total_amount                 xxcos_dlv_headers.total_amount%TYPE,            -- ���v���z
     sale_discount_amount         xxcos_dlv_headers.sale_discount_amount%TYPE,    -- ����l���z
     sales_consumption_tax        xxcos_dlv_headers.sales_consumption_tax%TYPE,   -- �������Ŋz
     tax_include                  xxcos_dlv_headers.tax_include%TYPE,             -- �ō����z
     keep_in_code                 xxcos_dlv_headers.keep_in_code%TYPE,            -- �a����R�[�h
     department_screen_class      xxcos_dlv_headers.department_screen_class%TYPE, -- �S�ݓX��ʎ��
     red_black_flag               xxcos_dlv_headers.red_black_flag%TYPE,          -- �ԍ��t���O
     stock_forward_flag           xxcos_dlv_headers.stock_forward_flag%TYPE,      -- ���o�ɓ]���t���O
     stock_forward_date           xxcos_dlv_headers.stock_forward_date%TYPE,      -- ���o�ɓ]���ϓ��t
     results_forward_flag         xxcos_dlv_headers.results_forward_flag%TYPE,    -- �̔����јA�g�σt���O
     results_forward_date         xxcos_dlv_headers.results_forward_date%TYPE,    -- �̔����јA�g�ϓ��t
     cancel_correct_class         xxcos_dlv_headers.cancel_correct_class%TYPE     -- ����E�����敪
    );
  TYPE g_tab_dlv_head_data IS TABLE OF g_rec_dlv_head_data INDEX BY PLS_INTEGER;
--
  -- �[�i���׏��i�[�p�ϐ�
  TYPE g_rec_dlv_lines_data IS RECORD
    (
     order_no_hht          xxcos_dlv_lines.order_no_hht%TYPE,                     -- ��No.�iHHT�j
     line_no_hht           xxcos_dlv_lines.line_no_hht%TYPE,                      -- �sNo.�iHHT�j
     digestion_ln_number   xxcos_dlv_lines.digestion_ln_number%TYPE,              -- �}��
     order_no_ebs          xxcos_dlv_lines.order_no_ebs%TYPE,                     -- ��No.�iEBS�j
     line_number_ebs       xxcos_dlv_lines.line_number_ebs%TYPE,                  -- ���הԍ��iEBS�j
     item_code_self        xxcos_dlv_lines.item_code_self%TYPE,                   -- �i���R�[�h�i���Ёj
     content               xxcos_dlv_lines.content%TYPE,                          -- ����
     inventory_item_id     xxcos_dlv_lines.inventory_item_id%TYPE,                -- �i��ID
     standard_unit         xxcos_dlv_lines.standard_unit%TYPE,                    -- ��P��
     case_number           xxcos_dlv_lines.case_number%TYPE,                      -- �P�[�X��
     quantity              xxcos_dlv_lines.quantity%TYPE,                         -- ����
     sale_class            xxcos_dlv_lines.sale_class%TYPE,                       -- ����敪
     wholesale_unit_ploce  xxcos_dlv_lines.wholesale_unit_ploce%TYPE,             -- ���P��
     selling_price         xxcos_dlv_lines.selling_price%TYPE,                    -- ���P��
     column_no             xxcos_dlv_lines.column_no%TYPE,                        -- �R����No.
     h_and_c               xxcos_dlv_lines.h_and_c%TYPE,                          -- H/C
     sold_out_class        xxcos_dlv_lines.sold_out_class%TYPE,                   -- ���؋敪
     sold_out_time         xxcos_dlv_lines.sold_out_time%TYPE,                    -- ���؎���
     replenish_number      xxcos_dlv_lines.replenish_number%TYPE,                 -- ��[��
     cash_and_card         xxcos_dlv_lines.cash_and_card%TYPE                     -- �����E�J�[�h���p�z
     );
  TYPE g_tab_dlv_lines_data IS TABLE OF g_rec_dlv_lines_data INDEX BY PLS_INTEGER;
--
  -- HHT���o�Ɉꎞ�e�[�u���w�b�_�g�p�ϐ�
  TYPE g_rec_inv_trans_head IS RECORD
    (
     employee_num          xxcoi_hht_inv_transactions.employee_num%TYPE,                  -- �c�ƈ��R�[�h
     invoice_no            xxcoi_hht_inv_transactions.invoice_no%TYPE,                    -- �`�[��
     invoice_type          xxcoi_hht_inv_transactions.invoice_type%TYPE,                  -- �`�[�敪
     inside_code           xxcoi_hht_inv_transactions.inside_code%TYPE,                   -- ���ɑ��R�[�h
     invoice_date          xxcoi_hht_inv_transactions.invoice_date%TYPE,                  -- �`�[���t
     record_type           xxcoi_hht_inv_transactions.record_type%TYPE,                   -- ���R�[�h���
     inside_cust_code      xxcoi_hht_inv_transactions.inside_cust_code%TYPE,              -- ���ɑ��ڋq�R�[�h
     inside_business_low_type  xxcoi_hht_inv_transactions.inside_business_low_type%TYPE,  -- ���ɑ��Ƒԋ敪
     column_no             xxcoi_hht_inv_transactions.column_no%TYPE
    );
  TYPE g_tab_inv_trans_head IS TABLE OF g_rec_inv_trans_head INDEX BY PLS_INTEGER;
--
  --HHT���o�Ɉꎞ�e�[�u���i�[�p�ϐ�
  TYPE g_rec_inv_transactions_data IS RECORD
    (
     row_id                           ROWID,                                                     -- �sID
     transaction_id                   xxcoi_hht_inv_transactions.transaction_id%TYPE,            -- ���o�Ɉꎞ�\ID
     interface_id                     xxcoi_hht_inv_transactions.interface_id%TYPE,              -- �C���^�[�t�F�[�XID
     form_header_id                   xxcoi_hht_inv_transactions.form_header_id%TYPE,            -- ��ʓ��͗p�w�b�_ID
     base_code                        xxcoi_hht_inv_transactions.base_code%TYPE,                 -- ���_�R�[�h
     record_type                      xxcoi_hht_inv_transactions.record_type%TYPE,               -- ���R�[�h���
     employee_num                     xxcoi_hht_inv_transactions.employee_num%TYPE,              -- �c�ƈ��R�[�h
     invoice_no                       xxcoi_hht_inv_transactions.invoice_no%TYPE,                -- �`�[��
     item_code                        xxcoi_hht_inv_transactions.item_code%TYPE,                 -- �i�ڃR�[�h
     case_quantity                    xxcoi_hht_inv_transactions.case_quantity%TYPE,             -- �P�[�X��
     case_in_quantity                 xxcoi_hht_inv_transactions.case_in_quantity%TYPE,          -- ����
     quantity                         xxcoi_hht_inv_transactions.quantity%TYPE,                  -- �{��
     invoice_type                     xxcoi_hht_inv_transactions.invoice_type%TYPE,              -- �`�[�敪
     base_delivery_flag               xxcoi_hht_inv_transactions.base_delivery_flag%TYPE,        -- ���_�ԑq�փt���O
     outside_code                     xxcoi_hht_inv_transactions.outside_code%TYPE,              -- �o�ɑ��R�[�h
     inside_code                      xxcoi_hht_inv_transactions.inside_code%TYPE,               -- ���ɑ��R�[�h
     invoice_date                     xxcoi_hht_inv_transactions.invoice_date%TYPE,              -- �`�[���t
     column_no                        xxcoi_hht_inv_transactions.column_no%TYPE,                 -- �R������
     unit_price                       xxcoi_hht_inv_transactions.unit_price%TYPE,                -- �P��
     hot_cold_div                     xxcoi_hht_inv_transactions.hot_cold_div%TYPE,              -- H/C
     department_flag                  xxcoi_hht_inv_transactions.department_flag%TYPE,           -- �S�ݓX�t���O
     interface_date                   xxcoi_hht_inv_transactions.interface_date%TYPE,            -- ��M����
     other_base_code                  xxcoi_hht_inv_transactions.other_base_code%TYPE,           -- �����_�R�[�h
     outside_subinv_code              xxcoi_hht_inv_transactions.outside_subinv_code%TYPE,       -- �o�ɑ��ۊǏꏊ
     inside_subinv_code               xxcoi_hht_inv_transactions.inside_subinv_code%TYPE,        -- ���ɑ��ۊǏꏊ
     outside_base_code                xxcoi_hht_inv_transactions.outside_base_code%TYPE,         -- �o�ɑ����_
     inside_base_code                 xxcoi_hht_inv_transactions.inside_base_code%TYPE,          -- ���ɑ����_
     total_quantity                   xxcoi_hht_inv_transactions.total_quantity%TYPE,            -- ���{��
     inventory_item_id                xxcoi_hht_inv_transactions.inventory_item_id%TYPE,         -- �i��ID
     primary_uom_code                 xxcoi_hht_inv_transactions.primary_uom_code%TYPE,          -- ��P��
     outside_subinv_code_conv_div     xxcoi_hht_inv_transactions.outside_subinv_code_conv_div%TYPE,-- �o�ɑ��ۊǏꏊ�ϊ�
     inside_subinv_code_conv_div      xxcoi_hht_inv_transactions.inside_subinv_code_conv_div%TYPE, -- ���ɑ��ۊǏꏊ�ϊ�
     outside_business_low_type        xxcoi_hht_inv_transactions.outside_business_low_type%TYPE, -- �o�ɑ��Ƒԋ敪
     inside_business_low_type         xxcoi_hht_inv_transactions.inside_business_low_type%TYPE,  -- ���ɑ��Ƒԋ敪
     outside_cust_code                xxcoi_hht_inv_transactions.outside_cust_code%TYPE,     -- �o�ɑ��ڋq�R�[�h
     inside_cust_code                 xxcoi_hht_inv_transactions.inside_cust_code%TYPE,      -- ���ɑ��ڋq�R�[�h
     hht_program_div                  xxcoi_hht_inv_transactions.hht_program_div%TYPE,       -- ���o�ɃW���[�i�������敪
     consume_vd_flag                  xxcoi_hht_inv_transactions.consume_vd_flag%TYPE,       -- ����VD��[�Ώۃt���O
     item_convert_div                 xxcoi_hht_inv_transactions.item_convert_div%TYPE,      -- ���i�U�֋敪
     stock_uncheck_list_div           xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE,-- ���ɖ��m�F���X�g�Ώۋ敪
     stock_balance_list_div           xxcoi_hht_inv_transactions.stock_balance_list_div%TYPE,-- ���ɍ��يm�F���X�g�Ώ�
     status                           xxcoi_hht_inv_transactions.status%TYPE,                -- �����X�e�[�^�X
     column_if_flag                   xxcoi_hht_inv_transactions.column_if_flag%TYPE,        -- �R�����ʓ]���σt���O
     column_if_date                   xxcoi_hht_inv_transactions.column_if_date%TYPE,        -- �R�����ʓ]����
     sample_if_flag                   xxcoi_hht_inv_transactions.sample_if_flag%TYPE,        -- ���{�]���σt���O
     sample_if_date                   xxcoi_hht_inv_transactions.sample_if_date%TYPE,        -- ���{�]����
     output_flag                      xxcoi_hht_inv_transactions.output_flag%TYPE            -- �o�͍σt���O
     );
  TYPE g_tab_inv_transactions_data IS TABLE OF g_rec_inv_transactions_data INDEX BY PLS_INTEGER;
--
  --HHT���o�Ɉꎞ�e�[�u���i�[�p�ϐ�
  TYPE g_rec_oe_order_data IS RECORD
    (
     order_number         oe_order_headers_all.order_number%TYPE,       -- �󒍔ԍ�
     header_id            oe_order_headers_all.header_id%TYPE,          -- �󒍃w�b�_ID
     head_flow_status_code  oe_order_headers_all.flow_status_code%TYPE, -- �w�b�_�X�e�[�^�X
     order_source_id      oe_order_headers_all.order_source_id%TYPE,    -- �󒍃\�[�XID
     cust_po_number       oe_order_headers_all.cust_po_number%TYPE,     -- �ڋq����
     line_id              oe_order_lines_all.line_id%TYPE,              -- �󒍖���ID
     line_flow_status_code  oe_order_lines_all.flow_status_code%TYPE    -- ���׃X�e�[�^�X
     );
  TYPE g_tab_oe_order_data IS TABLE OF g_rec_oe_order_data INDEX BY PLS_INTEGER;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
  TYPE g_rec_accumulation_data IS RECORD
    (
     row_id                  ROWID,
     dlv_invoice_number      xxcos_sales_exp_lines.dlv_invoice_number%TYPE,       -- �[�i�`�[�ԍ�
     dlv_invoice_line_number xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE,  -- �[�i���הԍ�
     sales_class             xxcos_sales_exp_lines.sales_class%TYPE,              -- ����敪
     red_black_flag          xxcos_sales_exp_lines.red_black_flag%TYPE,           -- �ԍ��t���O
     item_code               xxcos_sales_exp_lines.item_code%TYPE,                -- �i�ڃR�[�h
     dlv_qty                 xxcos_sales_exp_lines.dlv_qty%TYPE,                  -- �[�i����
     standard_qty            xxcos_sales_exp_lines.standard_qty%TYPE,             -- �����
     dlv_uom_code            xxcos_sales_exp_lines.dlv_uom_code%TYPE,             -- �[�i�P��
     standard_uom_code       xxcos_sales_exp_lines.standard_uom_code%TYPE,        -- ��P��(�[�i�P��)
     dlv_unit_price          xxcos_sales_exp_lines.dlv_unit_price%TYPE,            -- �[�i�P��
     standard_unit_price     xxcos_sales_exp_lines.standard_unit_price%TYPE,      -- ��P��(�[�i�P��)
     business_cost           xxcos_sales_exp_lines.business_cost%TYPE,            -- �c�ƌ���
     sale_amount             xxcos_sales_exp_lines.sale_amount%TYPE,              -- ������z
     pure_amount             xxcos_sales_exp_lines.pure_amount%TYPE,              -- �{�̋��z
     tax_amount              xxcos_sales_exp_lines.tax_amount%TYPE,               -- ����ŋ��z
     cash_and_card           xxcos_sales_exp_lines.cash_and_card%TYPE,            -- �����E�J�[�h���p�z
     ship_from_subinventory_code  xxcos_sales_exp_lines.ship_from_subinventory_code%TYPE,      -- �o�׌��ۊǏꏊ
     delivery_base_code      xxcos_sales_exp_lines.delivery_base_code%TYPE,       -- �[�i���_�R�[�h
     hot_cold_class          xxcos_sales_exp_lines.hot_cold_class%TYPE,           -- �g���b
     column_no               xxcos_sales_exp_lines.column_no%TYPE,                -- �R����No
     sold_out_class          xxcos_sales_exp_lines.sold_out_class%TYPE,           -- ���؋敪
     sold_out_time           xxcos_sales_exp_lines.sold_out_time%TYPE,            -- ���؎���
     to_calculate_fees_flag  xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE,   -- �萔���v�Z�C���^�t�F�[�X�σt���O
     unit_price_mst_flag     xxcos_sales_exp_lines.unit_price_mst_flag%TYPE,      -- �P���}�X�^�쐬�σt���O
     inv_interface_flag      xxcos_sales_exp_lines.inv_interface_flag%TYPE,       -- INV�C���^�t�F�[�X�σt���O
     order_invoice_line_number     xxcos_sales_exp_lines.order_invoice_line_number%TYPE,  -- �������הԍ�(NULL�ݒ�)
     standard_unit_price_excluded  xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE, -- �Ŕ���P��
     delivery_pattern_class        xxcos_sales_exp_lines.delivery_pattern_class%TYPE   -- �[�i�`�ԋ敪(���o)
     );
  TYPE g_tab_accumulation_data IS TABLE OF g_rec_accumulation_data INDEX BY PLS_INTEGER;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END ***************************************
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- �w�b�_�f�[�^�o�^�p�ϐ�
  TYPE g_tab_dlv_hht_head_row_id    IS TABLE OF ROWID
    INDEX BY PLS_INTEGER;   -- HHT�sID
  TYPE g_tab_dlv_edi_head_row_id    IS TABLE OF ROWID
    INDEX BY PLS_INTEGER;   -- EDI�sID
  TYPE g_tab_dlv_tran_head_row_id   IS TABLE OF ROWID
    INDEX BY PLS_INTEGER;   -- ���o�Ɉꎞ�\�sID
  TYPE g_tab_head_id                IS TABLE OF xxcos_sales_exp_headers.sales_exp_header_id%TYPE
    INDEX BY PLS_INTEGER;   -- �̔����уw�b�_ID
  TYPE g_tab_head_order_no_ebs      IS TABLE OF xxcos_sales_exp_headers.order_number%TYPE
    INDEX BY PLS_INTEGER;   -- ��No.(EBS)(�󒍔ԍ�)
  TYPE g_tab_head_digestion_ln_number IS TABLE OF xxcos_sales_exp_headers.digestion_ln_number%TYPE
    INDEX BY PLS_INTEGER;   -- �}��(��No(HHT)�}��)
  TYPE g_tab_head_dlv_invoice_class IS TABLE OF xxcos_sales_exp_headers.dlv_invoice_class%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i�`�[�敪(���o)
  TYPE g_tab_head_cancel_cor_cls    IS TABLE OF xxcos_sales_exp_headers.cancel_correct_class%TYPE
    INDEX BY PLS_INTEGER;   -- ����E�����敪(���o)
  TYPE g_tab_head_system_class      IS TABLE OF xxcos_sales_exp_headers.cust_gyotai_sho%TYPE
    INDEX BY PLS_INTEGER;   -- �Ƒԋ敪(�Ƒԏ�����)
  TYPE g_tab_head_dlv_date          IS TABLE OF xxcos_sales_exp_headers.delivery_date%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i��
  TYPE g_tab_head_inspect_date      IS TABLE OF xxcos_sales_exp_headers.inspect_date%TYPE
    INDEX BY PLS_INTEGER;   -- ������
  TYPE g_tab_head_customer_number   IS TABLE OF xxcos_sales_exp_headers.ship_to_customer_code%TYPE
    INDEX BY PLS_INTEGER;   -- �ڋq�y�[�i��z
  TYPE g_tab_head_tax_include       IS TABLE OF xxcos_sales_exp_headers.sale_amount_sum%TYPE
    INDEX BY PLS_INTEGER;   -- ������z���v
  TYPE g_tab_head_total_amount      IS TABLE OF xxcos_sales_exp_headers.pure_amount_sum%TYPE
    INDEX BY PLS_INTEGER;   -- ���v���z(�{�̋��z���v)
  TYPE g_tab_head_sales_consump_tax IS TABLE OF xxcos_sales_exp_headers.tax_amount_sum%TYPE
    INDEX BY PLS_INTEGER;   -- ����ŋ��z���v
  TYPE g_tab_head_consump_tax_class IS TABLE OF xxcos_sales_exp_headers.consumption_tax_class%TYPE
    INDEX BY PLS_INTEGER;   -- ����ŋ敪(���o)
  TYPE g_tab_head_tax_code          IS TABLE OF xxcos_sales_exp_headers.tax_code%TYPE
    INDEX BY PLS_INTEGER;   -- �ŋ��R�[�h(���o)
  TYPE g_tab_head_tax_rate          IS TABLE OF xxcos_sales_exp_headers.tax_rate%TYPE
    INDEX BY PLS_INTEGER;   -- ����ŗ�(���o)
  TYPE g_tab_head_performance_by_code     IS TABLE OF xxcos_sales_exp_headers.results_employee_code%TYPE
    INDEX BY PLS_INTEGER;   -- ���ьv��҃R�[�h
  TYPE g_tab_head_sales_base_code   IS TABLE OF xxcos_sales_exp_headers.sales_base_code%TYPE
    INDEX BY PLS_INTEGER;   -- ���㋒�_�R�[�h(���o)
  TYPE g_tab_head_card_sale_class   IS TABLE OF xxcos_sales_exp_headers.card_sale_class%TYPE
    INDEX BY PLS_INTEGER;   -- �J�[�h����敪
  TYPE g_tab_head_sales_classificat IS TABLE OF xxcos_sales_exp_headers.invoice_class%TYPE
    INDEX BY PLS_INTEGER;   -- �`�[�敪
  TYPE g_tab_head_invoice_class     IS TABLE OF xxcos_sales_exp_headers.invoice_classification_code%TYPE
    INDEX BY PLS_INTEGER;   -- �`�[���ރR�[�h
  TYPE g_tab_head_receiv_base_code  IS TABLE OF xxcos_sales_exp_headers.receiv_base_code%TYPE
    INDEX BY PLS_INTEGER;   -- �������_�R�[�h(���o)
  TYPE g_tab_head_change_out_time_100     IS TABLE OF xxcos_sales_exp_headers.change_out_time_100%TYPE
    INDEX BY PLS_INTEGER;   -- ��K�؂ꎞ��100�~
  TYPE g_tab_head_change_out_time_10 IS TABLE OF xxcos_sales_exp_headers.change_out_time_10%TYPE
    INDEX BY PLS_INTEGER;   -- ��K�؂ꎞ��10�~
  TYPE g_tab_head_hht_dlv_input_date IS TABLE OF xxcos_sales_exp_headers.hht_dlv_input_date%TYPE
    INDEX BY PLS_INTEGER;   -- HHT�[�i���͓���(���^����)
  TYPE g_tab_head_dlv_by_code       IS TABLE OF xxcos_sales_exp_headers.dlv_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i�҃R�[�h
  TYPE g_tab_head_business_date     IS TABLE OF xxcos_sales_exp_headers.business_date%TYPE
    INDEX BY PLS_INTEGER;   -- �o�^�Ɩ����t(���������擾)
  TYPE g_tab_head_order_source_id   IS TABLE OF xxcos_sales_exp_headers.order_source_id%TYPE
    INDEX BY PLS_INTEGER;   -- �󒍃\�[�XID(NULL�ݒ�)
  TYPE g_tab_head_order_invoice_num IS TABLE OF xxcos_sales_exp_headers.order_invoice_number%TYPE
    INDEX BY PLS_INTEGER;   -- �����`�[�ԍ�(NULL�ݒ�)
  TYPE g_tab_head_order_connect_num IS TABLE OF xxcos_sales_exp_headers.order_connection_number%TYPE
    INDEX BY PLS_INTEGER;   -- �󒍊֘A�ԍ�(NULL�ݒ�)
  TYPE g_tab_head_ar_interface_flag IS TABLE OF xxcos_sales_exp_headers.ar_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   -- AR�C���^�t�F�[�X�σt���O('N'�ݒ�)
  TYPE g_tab_head_gl_interface_flag IS TABLE OF xxcos_sales_exp_headers.gl_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   -- GL�C���^�t�F�[�X�σt���O('N'�ݒ�)
  TYPE g_tab_head_dwh_interface_flag IS TABLE OF xxcos_sales_exp_headers.dwh_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   -- ���V�X�e���C���^�t�F�[�X�σt���O('N'�ݒ�)
  TYPE g_tab_head_edi_interface_flag IS TABLE OF xxcos_sales_exp_headers.edi_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   -- EDI���M�ς݃t���O('N'�ݒ�)
  TYPE g_tab_head_edi_send_date     IS TABLE OF xxcos_sales_exp_headers.edi_send_date%TYPE
    INDEX BY PLS_INTEGER;   -- EDI���M����(NULL�ݒ�)
  TYPE g_tab_head_create_class      IS TABLE OF xxcos_sales_exp_headers.create_class%TYPE
    INDEX BY PLS_INTEGER;   -- �쐬���敪(�3��ݒ�)
  TYPE g_tab_head_order_no_hht      IS TABLE OF xxcos_sales_exp_headers.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- ��No.(HHT)(��No(HHT))  
  TYPE g_tab_head_hht_invoice_no    IS TABLE OF xxcos_sales_exp_headers.dlv_invoice_number%TYPE
    INDEX BY PLS_INTEGER;   -- HHT�`�[No.(HHT�`�[No?�A�[�i�`�[No?)
  TYPE g_tab_head_input_class       IS TABLE OF xxcos_sales_exp_headers.input_class%TYPE
    INDEX BY PLS_INTEGER;   -- ���͋敪
--
  --���׃f�[�^�o�^�p�ϐ�
  TYPE g_tab_line_sales_exp_line_id IS TABLE OF xxcos_sales_exp_lines.sales_exp_line_id%TYPE
    INDEX BY PLS_INTEGER;   -- �̔����і���ID
  TYPE g_tab_line_sal_exp_header_id IS TABLE OF xxcos_sales_exp_lines.sales_exp_header_id%TYPE
    INDEX BY PLS_INTEGER;   -- �̔����уw�b�_ID
  TYPE g_tab_line_dlv_invoice_number IS TABLE OF xxcos_sales_exp_lines.dlv_invoice_number%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i�`�[�ԍ�
  TYPE g_tab_line_dlv_invoice_l_num  IS TABLE OF xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i���הԍ�
  TYPE g_tab_line_sales_class        IS TABLE OF xxcos_sales_exp_lines.sales_class%TYPE
    INDEX BY PLS_INTEGER;   -- ����敪
  TYPE g_tab_line_red_black_flag     IS TABLE OF xxcos_sales_exp_lines.red_black_flag%TYPE
    INDEX BY PLS_INTEGER;   -- �ԍ��t���O
  TYPE g_tab_line_item_code          IS TABLE OF xxcos_sales_exp_lines.item_code%TYPE
    INDEX BY PLS_INTEGER;   -- �i�ڃR�[�h
  TYPE g_tab_line_dlv_qty            IS TABLE OF xxcos_sales_exp_lines.dlv_qty%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i����
  TYPE g_tab_line_standard_qty       IS TABLE OF xxcos_sales_exp_lines.standard_qty%TYPE
    INDEX BY PLS_INTEGER;   -- �����
  TYPE g_tab_line_dlv_uom_code       IS TABLE OF xxcos_sales_exp_lines.dlv_uom_code%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i�P��
  TYPE g_tab_line_standard_uom_code  IS TABLE OF xxcos_sales_exp_lines.standard_uom_code%TYPE
    INDEX BY PLS_INTEGER;   -- ��P��(�[�i�P��)
  TYPE g_tab_line_dlv_unit_price     IS TABLE OF xxcos_sales_exp_lines.dlv_unit_price%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i�P��
  TYPE g_tab_line_standard_unit_price IS TABLE OF xxcos_sales_exp_lines.standard_unit_price%TYPE
    INDEX BY PLS_INTEGER;   -- ��P��(�[�i�P��)
  TYPE g_tab_line_business_cost     IS TABLE OF xxcos_sales_exp_lines.business_cost%TYPE
    INDEX BY PLS_INTEGER;   -- �c�ƌ���
  TYPE g_tab_line_sale_amount       IS TABLE OF xxcos_sales_exp_lines.sale_amount%TYPE
    INDEX BY PLS_INTEGER;   -- ������z
  TYPE g_tab_line_pure_amount       IS TABLE OF xxcos_sales_exp_lines.pure_amount%TYPE
    INDEX BY PLS_INTEGER;   -- �{�̋��z
  TYPE g_tab_line_tax_amount        IS TABLE OF xxcos_sales_exp_lines.tax_amount%TYPE
    INDEX BY PLS_INTEGER;   -- ����ŋ��z
  TYPE g_tab_line_cash_and_card     IS TABLE OF xxcos_sales_exp_lines.cash_and_card%TYPE
    INDEX BY PLS_INTEGER;   -- �����E�J�[�h���p�z
  TYPE g_tab_line_ship_from_subinv_co IS TABLE OF xxcos_sales_exp_lines.ship_from_subinventory_code%TYPE
    INDEX BY PLS_INTEGER;   -- �o�׌��ۊǏꏊ
  TYPE g_tab_line_delivery_base_code IS TABLE OF xxcos_sales_exp_lines.delivery_base_code%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i���_�R�[�h
  TYPE g_tab_line_hot_cold_class     IS TABLE OF xxcos_sales_exp_lines.hot_cold_class%TYPE
    INDEX BY PLS_INTEGER;   -- �g���b
  TYPE g_tab_line_column_no          IS TABLE OF xxcos_sales_exp_lines.column_no%TYPE
    INDEX BY PLS_INTEGER;   -- �R����No
  TYPE g_tab_line_sold_out_class     IS TABLE OF xxcos_sales_exp_lines.sold_out_class%TYPE
    INDEX BY PLS_INTEGER;   -- ���؋敪
  TYPE g_tab_line_sold_out_time      IS TABLE OF xxcos_sales_exp_lines.sold_out_time%TYPE
    INDEX BY PLS_INTEGER;   -- ���؎���
  TYPE g_tab_line_to_cal_fees_flag IS TABLE OF xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE
    INDEX BY PLS_INTEGER;   -- �萔���v�Z�C���^�t�F�[�X�σt���O
  TYPE g_tab_line_unit_price_mst_flag    IS TABLE OF xxcos_sales_exp_lines.unit_price_mst_flag%TYPE
    INDEX BY PLS_INTEGER;   -- �P���}�X�^�쐬�σt���O
  TYPE g_tab_line_inv_interface_flag IS TABLE OF xxcos_sales_exp_lines.inv_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   -- INV�C���^�t�F�[�X�σt���O
  TYPE g_tab_line_order_invoice_l_num IS TABLE OF xxcos_sales_exp_lines.order_invoice_line_number%TYPE
    INDEX BY PLS_INTEGER;   -- �������הԍ�(NULL�ݒ�)
  TYPE g_tab_line_not_tax_amount      IS TABLE OF xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE
    INDEX BY PLS_INTEGER;   -- �Ŕ���P��
  TYPE g_tab_line_delivery_pat_class  IS TABLE OF xxcos_sales_exp_lines.delivery_pattern_class%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i�`�ԋ敪(���o)
--
  --OM�󒍏��
  TYPE g_tab_oe_order_number  IS TABLE OF oe_order_headers_all.order_number%TYPE
  INDEX BY PLS_INTEGER;   -- �󒍔ԍ�
  TYPE g_tab_oe_header_id     IS TABLE OF oe_order_headers_all.header_id%TYPE
  INDEX BY PLS_INTEGER;   -- �󒍃w�b�_ID
  TYPE g_tab_oe_he_flow_status_code  IS TABLE OF oe_order_headers_all.flow_status_code%TYPE
  INDEX BY PLS_INTEGER;   -- �w�b�_�X�e�[�^�X
  TYPE g_tab_oe_order_source_id  IS TABLE OF oe_order_headers_all.order_source_id%TYPE
  INDEX BY PLS_INTEGER;   -- �󒍃\�[�XID
  TYPE g_tab_oe_cust_po_number   IS TABLE OF oe_order_headers_all.cust_po_number%TYPE
  INDEX BY PLS_INTEGER;   -- �ڋq����ID
  TYPE g_tab_oe_line_id       IS TABLE OF oe_order_lines_all.line_id%TYPE
  INDEX BY PLS_INTEGER;   -- �󒍖���ID
  TYPE g_tab_oe_li_flow_status_code   IS TABLE OF oe_order_lines_all.flow_status_code%TYPE
  INDEX BY PLS_INTEGER;   -- ���׃X�e�[�^�X
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START *************************************
  TYPE g_tab_msg_war_data     IS TABLE OF VARCHAR2(500) INDEX BY PLS_INTEGER;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END ***************************************
--
  gt_dlv_hht_headers_data         g_tab_dlv_head_data;            -- �[�i�w�b�_(HHT)�e�[�u�����o�f�[�^
  gt_dlv_hht_lines_data           g_tab_dlv_lines_data;           -- �[�i���׏��(HHT)�e�[�u�����o�f�[�^
  gt_inp_dlv_hht_headers_data     g_tab_dlv_head_data;            -- �[�i�`�[���͉�ʓo�^�f�[�^(�w�b�_)�e�[�u�����o�f�[�^
  gt_inp_dlv_hht_lines_data       g_tab_dlv_lines_data;           -- �[�i�`�[���͉�ʓo�^�f�[�^(����)�e�[�u�����o�f�[�^
  gt_dlv_edi_headers_data         g_tab_dlv_head_data;            -- �[�i�w�b�_(EDI)�e�[�u�����o�f�[�^
  gt_dlv_edi_lines_data           g_tab_dlv_lines_data;           -- �[�i���׏��(EDI)�e�[�u�����o�f�[�^
  gt_inv_trans_head               g_tab_inv_trans_head;           -- �w�b�_�o�^�pHHT���o�Ɉꎞ�e�[�u�����o�f�[�^
  gt_inv_transactions_data        g_tab_inv_transactions_data;    -- HHT���o�Ɉꎞ�e�[�u�����o�f�[�^
  gt_oe_order_all                 g_tab_oe_order_data;            -- OM�󒍃e�[�u�����o�f�[�^
--******************************* 2009/05/12 N.Maeda Var1.13 ADD START *************************************
  gt_inp_oe_order_all             g_tab_oe_order_data;            -- �[�i�`�[���͉�ʓo�^OM�󒍃e�[�u�����o�f�[�^
--******************************* 2009/05/12 N.Maeda Var1.13 ADD  END ***************************************
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START *************************************
  gt_accumulation_data            g_tab_accumulation_data;        -- �f�[�^�i�[�p
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END ***************************************
--
  --�w�b�_�f�[�^�i�[�ϐ�
  gt_dlv_hht_head_row_id          g_tab_dlv_hht_head_row_id;       -- �w�b�_�sID(HHT)
  gt_inp_dlv_hht_head_row_id      g_tab_dlv_hht_head_row_id;       -- �w�b�_�sID(�[�i�`�[���͉�ʃf�[�^)
  gt_dlv_edi_head_row_id          g_tab_dlv_edi_head_row_id;       -- �w�b�_�sID(EDI)
  gt_dlv_tran_head_row_id         g_tab_dlv_tran_head_row_id;      -- ���o�Ɉꎞ�\�sID
  gt_head_id                      g_tab_head_id;                   -- �̔����уw�b�_ID
  gt_head_order_no_ebs            g_tab_head_order_no_ebs;         -- �󒍔ԍ�
  gt_head_digestion_ln_number     g_tab_head_digestion_ln_number;  -- �}��(��No(HHT)�}��)
  gt_head_dlv_invoice_class       g_tab_head_dlv_invoice_class;    -- �[�i�`�[�敪(���o)
  gt_head_cancel_cor_cls          g_tab_head_cancel_cor_cls;       -- ����E�����敪(���o)
  gt_head_system_class            g_tab_head_system_class;         -- �Ƒԋ敪(�Ƒԏ�����)
  gt_head_dlv_date                g_tab_head_dlv_date;             -- �[�i��
  gt_head_inspect_date            g_tab_head_inspect_date;         -- ������(����v���)
  gt_head_customer_number         g_tab_head_customer_number;      -- �ڋq�R�[�h(�ڋq�y�[�i��z)
  gt_head_tax_include             g_tab_head_tax_include;          -- �ō����z(������z���v)
  gt_head_total_amount            g_tab_head_total_amount;         -- ���v���z(�{�̋��z���v)
  gt_head_sales_consump_tax       g_tab_head_sales_consump_tax;    -- �������Ŋz(����ŋ��z���v)
  gt_head_consump_tax_class       g_tab_head_consump_tax_class;    -- ����ŋ敪(���o)
  gt_head_tax_code                g_tab_head_tax_code;             -- �ŋ��R�[�h(���o)
  gt_head_tax_rate                g_tab_head_tax_rate;             -- ����ŗ�(���o)
  gt_head_performance_by_code     g_tab_head_performance_by_code;  -- ���ю҃R�[�h(���ьv��҃R�[�h)
  gt_head_sales_base_code         g_tab_head_sales_base_code;      -- ���㋒�_�R�[�h(���o)
  gt_head_card_sale_class         g_tab_head_card_sale_class;      -- �J�[�h����敪
  gt_head_sales_classification    g_tab_head_sales_classificat;    -- ���㕪�ދ敪(�`�[�敪)
  gt_head_invoice_class           g_tab_head_invoice_class;        -- ����`�[�敪(�`�[���ރR�[�h)
  gt_head_receiv_base_code        g_tab_head_receiv_base_code;     -- �������_�R�[�h(���o)
  gt_head_change_out_time_100     g_tab_head_change_out_time_100;  -- ��K�؂ꎞ��100�~
  gt_head_change_out_time_10      g_tab_head_change_out_time_10;   -- ��K�؂ꎞ��10�~
  gt_head_hht_dlv_input_date      g_tab_head_hht_dlv_input_date;   -- HHT�[�i���͓���(���^����)
  gt_head_dlv_by_code             g_tab_head_dlv_by_code;          -- �[�i�҃R�[�h
  gt_head_business_date           g_tab_head_business_date;        -- �o�^�Ɩ����t(���������擾)
  gt_head_order_source_id         g_tab_head_order_source_id;      -- �󒍃\�[�XID(NULL�ݒ�)order_source_id
  gt_head_order_invoice_number    g_tab_head_order_invoice_num;    -- �����`�[�ԍ�(NULL�ݒ�)
  gt_head_order_connection_num    g_tab_head_order_connect_num;    -- �󒍊֘A�ԍ�(NULL�ݒ�)
  gt_head_ar_interface_flag       g_tab_head_ar_interface_flag;    -- AR�C���^�t�F�[�X�σt���O('N'�ݒ�)ar_interface_flag
  gt_head_gl_interface_flag       g_tab_head_gl_interface_flag;    -- GL�C���^�t�F�[�X�σt���O('N'�ݒ�)
  gt_head_dwh_interface_flag      g_tab_head_dwh_interface_flag;   -- ���V�X�e���C���^�t�F�[�X�σt���O('N'�ݒ�)
  gt_head_edi_interface_flag      g_tab_head_edi_interface_flag;   -- EDI���M�ς݃t���O('N'�ݒ�)
  gt_head_edi_send_date           g_tab_head_edi_send_date;        -- EDI���M����(NULL�ݒ�)
  gt_head_create_class            g_tab_head_create_class;         -- �쐬���敪(�3��ݒ�)
  gt_head_order_no_hht            g_tab_head_order_no_hht;         -- ��No.(HHT)(��No(HHT))  
  gt_head_hht_invoice_no          g_tab_head_hht_invoice_no;       -- HHT�`�[No.(HHT�`�[No?�A�[�i�`�[No?)
  gt_head_input_class             g_tab_head_input_class;          -- ���͋敪
--
  --���׃f�[�^�i�[�ϐ�
  gt_line_sales_exp_line_id       g_tab_line_sales_exp_line_id;      -- �̔����і���ID
  gt_line_sales_exp_header_id     g_tab_line_sal_exp_header_id;      -- �̔����уw�b�_ID
  gt_line_dlv_invoice_number      g_tab_line_dlv_invoice_number;     -- �[�i�`�[�ԍ�
  gt_line_dlv_invoice_l_num       g_tab_line_dlv_invoice_l_num;      -- �[�i���הԍ�
  gt_line_sales_class             g_tab_line_sales_class;            -- ����敪
  gt_line_red_black_flag          g_tab_line_red_black_flag;         -- �ԍ��t���O
  gt_line_item_code               g_tab_line_item_code;              -- �i�ڃR�[�h
  gt_line_dlv_qty                 g_tab_line_dlv_qty;                -- �[�i����
  gt_line_standard_qty            g_tab_line_standard_qty;           -- �����
  gt_line_dlv_uom_code            g_tab_line_dlv_uom_code;           -- �[�i�P��
  gt_line_standard_uom_code       g_tab_line_standard_uom_code;      -- ��P��
  gt_dlv_unit_price               g_tab_line_dlv_unit_price;         -- �[�i�P��
  gt_line_standard_unit_price     g_tab_line_standard_unit_price;    -- ��P��
  gt_line_business_cost           g_tab_line_business_cost;          -- �c�ƌ���
  gt_line_sale_amount             g_tab_line_sale_amount;            -- ������z
  gt_line_pure_amount             g_tab_line_pure_amount;            -- �{�̋��z
  gt_line_tax_amount              g_tab_line_tax_amount;             -- ����ŋ��z
  gt_line_cash_and_card           g_tab_line_cash_and_card;          -- �����E�J�[�h���p�z
  gt_line_ship_from_subinv_co     g_tab_line_ship_from_subinv_co;    -- �o�׌��ۊǏꏊ
  gt_line_delivery_base_code      g_tab_line_delivery_base_code;     -- �[�i���_�R�[�h
  gt_line_hot_cold_class          g_tab_line_hot_cold_class;         -- �g���b
  gt_line_column_no               g_tab_line_column_no;              -- �R����No
  gt_line_sold_out_class          g_tab_line_sold_out_class;         -- ���؋敪
  gt_line_sold_out_time           g_tab_line_sold_out_time;          -- ���؎���
  gt_line_to_calculate_fees_flag  g_tab_line_to_cal_fees_flag;       -- �萔���v�Z�C���^�t�F�[�X�σt���O
  gt_line_unit_price_mst_flag     g_tab_line_unit_price_mst_flag;    -- �P���}�X�^�쐬�σt���O
  gt_line_inv_interface_flag      g_tab_line_inv_interface_flag;     -- INV�C���^�t�F�[�X�σt���O
  gt_line_order_invoice_l_num     g_tab_line_order_invoice_l_num;    -- �������הԍ�(NULL�ݒ�)
  gt_line_not_tax_amount          g_tab_line_not_tax_amount;         -- �Ŕ���P��
  gt_line_delivery_pat_class      g_tab_line_delivery_pat_class;     -- �[�i�`�ԋ敪
--
  --OM�󒍏��i�[�ϐ�
  gt_oe_order_number              g_tab_oe_order_number;             -- �󒍔ԍ�
  gt_oe_header_id                 g_tab_oe_header_id;                -- �󒍃w�b�_ID
  gt_oe_he_flow_status_code       g_tab_oe_he_flow_status_code;      -- �X�e�[�^�X
  gt_oe_order_source_id           g_tab_oe_order_source_id;          -- �󒍃\�[�XID
  gt_oe_cust_po_number            g_tab_oe_cust_po_number;           -- �ڋq����
  gt_oe_line_id                   g_tab_oe_line_id;                  -- �󒍖���ID
  gt_oe_li_flow_status_code       g_tab_oe_li_flow_status_code;      -- �X�e�[�^�X
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START *************************************
  --�x�����b�Z�[�W�o�͗p
  gt_msg_war_data                 g_tab_msg_war_data;                -- �x�����(�ڍ�)
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END ***************************************
--
  gn_head_data_no                 NUMBER := 1;                       -- ���уw�b�_�o�^�p�J�E���g
  gn_line_data_no                 NUMBER := 1;                       -- ���і��דo�^�p�J�E���g
  gn_target_edi_cnt               NUMBER := 0;                       -- �[�i�w�b�_(EDI)�J�E���g�p
  gn_line_cnt                     NUMBER := 0;                       -- �[�i����(HHT)�J�E���g�p
  gn_line_edi_cnt                 NUMBER := 0;                       -- �[�i����(edi)�J�E���g�p
  gn_om_data_cnt                  NUMBER := 0;                       -- OM�󒍃f�[�^�����J�E���g�p
  gn_transaction_head_cnt         NUMBER := 0;                       -- �w�b�_�pHHT���o�Ɉꎞ�e�[�u���J�E���g�p
  gn_transaction_cnt              NUMBER := 0;                       -- HHT���o�Ɉꎞ�e�[�u���J�E���g�p
  gn_inp_target_cnt               NUMBER := 0;                       -- ���͉�ʓo�^�f�[�^(�w�b�_)�J�E���g�p
  gn_inp_line_cnt                 NUMBER := 0;                       -- ���͉�ʓo�^�f�[�^(����)�J�E���g�p
  gn_consum_amount                NUMBER;                            -- ����Ŋz
  gn_line_ins_cnt                 NUMBER := 0;                       -- ���דo�^����
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
  gn_wae_data_num                 NUMBER := 0;                       -- �x���f�[�^�i�[�p
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
  gn_orga_id                      NUMBER;                            -- �݌ɑg�DID
  gv_orga_code                    VARCHAR2(50);                      -- �݌ɑg�D�R�[�h
  gv_salse_unit                   VARCHAR2(50);                      -- MO:�c�ƒP��
  gd_input_date                   DATE;                              -- HHT�[�i���͓���
  gd_process_date                 DATE;                              -- �Ɩ�������
  gd_max_date                     DATE;                              -- MAX���t
  gv_disc_item                    VARCHAR2(50);                      -- �l�����i�ڃR�[�h
  gv_bks_id                       VARCHAR2(50);                      -- ��v����ID
  gv_tkn1                         VARCHAR2(5000);                    -- �G���[���b�Z�[�W�p�g�[�N���P
  gv_tkn2                         VARCHAR2(5000);                    -- �G���[���b�Z�[�W�p�g�[�N���Q
  gv_tkn3                         VARCHAR2(5000);                    -- �G���[���b�Z�[�W�p�g�[�N���R
--******************************* 2009/05/12 N.Maeda Var1.13 ADD START *************************************
  gn_cnt_om_order                 NUMBER :=  1;                      -- OM�󒍏��i�[��
--******************************* 2009/05/12 N.Maeda Var1.13 ADD  END ***************************************
--
  /***********************************************************************************
   * Procedure Name   : proc_flg_update
   * Description      : �擾���e�[�u���t���O�X�V(A-10)
   ***********************************************************************************/
  PROCEDURE proc_flg_update(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_flg_update'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_hht_count        NUMBER;       -- �[�i�w�b�_(HHT)�J�E���g�p
    ln_edi_count        NUMBER;       -- �[�i�w�b�_(EDI)�J�E���g�p
    ln_transact_count   NUMBER;       -- ���o�Ɉꎞ�\�J�E���g�p
    ln_inp_transact_count   NUMBER;   -- �[�i�`�[���͉�ʃf�[�^�J�E���g�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--    -- �o�^�����Z�b�g
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--    ln_hht_count      := gt_dlv_hht_headers_data.COUNT;
--    ln_edi_count      := gt_dlv_edi_headers_data.COUNT;
--    ln_transact_count := gt_inv_transactions_data.COUNT;
--    ln_inp_transact_count := gt_inp_dlv_hht_headers_data.COUNT;
    ln_hht_count      := gt_dlv_hht_head_row_id.COUNT;
    ln_transact_count := gt_dlv_tran_head_row_id.COUNT;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
----
--    <<hht_id_loop>>
--    FOR hht_row_count IN 1..ln_hht_count LOOP
--      gt_dlv_hht_head_row_id( hht_row_count ) := gt_dlv_hht_headers_data( hht_row_count ).row_id;
--    END LOOP hht_id_loop;
----
--    <<inp_id_loop>>
--    FOR inp_row_count IN 1..ln_inp_transact_count LOOP
--      gt_inp_dlv_hht_head_row_id( inp_row_count ) := gt_inp_dlv_hht_headers_data( inp_row_count ).row_id;
--    END LOOP inp_id_loop;
----
--    <<edi_id_loop>>
--    FOR edi_row_count IN 1..ln_edi_count LOOP
--      gt_dlv_edi_head_row_id( edi_row_count ) := gt_dlv_edi_headers_data( edi_row_count ).row_id;
--    END LOOP edi_id_loop;
----
--    <<trans_id_loop>>
--    FOR trans_row_count IN 1..ln_transact_count LOOP
--      gt_dlv_tran_head_row_id( trans_row_count ) := gt_inv_transactions_data( trans_row_count ).row_id;
--    END LOOP trans_id_loop;
----
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   *****************************************
    BEGIN
--
      -- ============================
      -- �[�i�w�b�_�iHHT�j�t���O�X�V
      -- ============================
      FORALL i IN 1..ln_hht_count
--
        UPDATE xxcos_dlv_headers
        SET    results_forward_flag = cv_forward_flag_alr,          --�A�g�ς݃t���O
               results_forward_date = gd_process_date,              --�A�g��
               last_updated_by = cn_last_updated_by,                --�ŏI�X�V��
               last_update_date = cd_last_update_date,              --�ŏI�X�V��
               last_update_login = cn_last_update_login,            --�ŏI�X�V۸޲�
               request_id = cn_request_id,                          --�v��ID
               program_application_id = cn_program_application_id,  --�ݶ��ĥ��۸��ѥ���ع����ID
               program_id = cn_program_id,                          --�ݶ��ĥ��۸���ID
               program_update_date = cd_program_update_date         --��۸��эX�V��
        WHERE  ROWID  =  gt_dlv_hht_head_row_id( i );
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_head );
        gv_tkn2    := xxccp_common_pkg.get_msg( cv_application, cv_msg_update_err,
                                                cv_tkn_table_name, gv_tkn1, cv_key_data, cv_tkn_null);
        RAISE updata_err_expt;
    END;
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--    BEGIN
--
--      -- ============================
--      -- �[�i�w�b�_�i�[�i�`�[���͉�ʓo�^�f�[�^�j�t���O�X�V
--      -- ============================
--
--      FORALL i IN 1..ln_inp_transact_count
--
--        UPDATE xxcos_dlv_headers
--        SET    results_forward_flag = cv_forward_flag_alr,          --�A�g�ς݃t���O
--               results_forward_date = gd_process_date,              --�A�g��
--               last_updated_by = cn_last_updated_by,                --�ŏI�X�V��
--               last_update_date = cd_last_update_date,              --�ŏI�X�V��
--               last_update_login = cn_last_update_login,            --�ŏI�X�V۸޲�
--               request_id = cn_request_id,                          --�v��ID
--               program_application_id = cn_program_application_id,  --�ݶ��ĥ��۸��ѥ���ع����ID
--               program_id = cn_program_id,                          --�ݶ��ĥ��۸���ID
--               program_update_date = cd_program_update_date         --��۸��эX�V��
--        WHERE  ROWID  =  gt_inp_dlv_hht_head_row_id( i );
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_head );
--        gv_tkn2    := xxccp_common_pkg.get_msg( cv_application, cv_msg_update_err,
--                                                cv_tkn_table_name, gv_tkn1, cv_key_data, cv_tkn_null);
--        RAISE updata_err_expt;
--    END;
--
--    BEGIN
--      -- ============================
--      -- �[�i�w�b�_�iEDI�j�t���O�X�V
--      -- ============================
--      FORALL i IN 1..ln_edi_count
--
--        UPDATE xxcos_dlv_headers
--        SET    results_forward_flag = cv_forward_flag_alr,          --�A�g�ς݃t���O
--               results_forward_date = gd_process_date,              --�A�g��
--               last_updated_by = cn_last_updated_by,                --�ŏI�X�V��
--               last_update_date = cd_last_update_date,              --�ŏI�X�V��
--               last_update_login = cn_last_update_login,            --�ŏI�X�V۸޲�
--               request_id = cn_request_id,                          --�v��ID
--               program_application_id = cn_program_application_id,  --�ݶ��ĥ��۸��ѥ���ع����ID
--               program_id = cn_program_id,                          --�ݶ��ĥ��۸���ID
--               program_update_date = cd_program_update_date         --��۸��эX�V��                        
--        WHERE  ROWID  =  gt_dlv_edi_head_row_id( i );
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_head );
--        gv_tkn2    := xxccp_common_pkg.get_msg( cv_application, cv_msg_update_err,
--                                                cv_tkn_table_name, gv_tkn1, cv_key_data, cv_tkn_null);
--        RAISE updata_err_expt;
--    END;
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   *****************************************
    BEGIN
      -- ============================
      -- ���o�Ɉꎞ�\�t���O�X�V
      -- ============================
      FORALL i IN 1..ln_transact_count
--
        UPDATE xxcoi_hht_inv_transactions
        SET    sample_if_flag = cv_tkn_yes,                         --�A�g�ς݃t���O
               sample_if_date = gd_process_date,                    --�A�g��
               last_updated_by = cn_last_updated_by,                --�ŏI�X�V��
               last_update_date = cd_last_update_date,              --�ŏI�X�V��
               last_update_login = cn_last_update_login,            --�ŏI�X�V۸޲�
               request_id = cn_request_id,                          --�v��ID
               program_application_id = cn_program_application_id,  --�ݶ��ĥ��۸��ѥ���ع����ID
               program_id = cn_program_id,                          --�ݶ��ĥ��۸���ID
               program_update_date = cd_program_update_date         --��۸��эX�V��                        
        WHERE  ROWID  =  gt_dlv_tran_head_row_id( i );
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_transactions );
        gv_tkn2    := xxccp_common_pkg.get_msg( cv_application, cv_msg_update_err,
                                                cv_tkn_table_name, gv_tkn1, cv_key_data, cv_tkn_null);
        RAISE updata_err_expt;
    END;
--
  EXCEPTION
    WHEN updata_err_expt THEN
--      lv_errbuf  := gv_tkn2;
      ov_errmsg  := gv_tkn2;
      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;                                       --# �C�� #
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
  END proc_flg_update;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_om_close
   * Description      : OM�N���[�Y����(A-7)
   ***********************************************************************************/
  PROCEDURE proc_om_close(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_om_close'; -- �v���O������
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
    lt_order_number          oe_order_headers_all.order_number%TYPE;          -- �󒍔ԍ�
    lt_header_id             oe_order_headers_all.header_id%TYPE;             -- �󒍃w�b�_ID
    lt_he_flow_status_code   oe_order_headers_all.flow_status_code%TYPE;      -- �w�b�_�X�e�[�^�X
    lt_order_source_id       oe_order_headers_all.order_source_id%TYPE;       -- �󒍃\�[�XID
    lt_cust_po_number        oe_order_headers_all.cust_po_number%TYPE;        -- �ڋq����
    lt_line_id               oe_order_lines_all.line_id%TYPE;                 -- �󒍖���ID
    lt_li_flow_status_code   oe_order_lines_all.flow_status_code%TYPE;        -- ���׃X�e�[�^�X
    ln_data_cnt              NUMBER;                                          -- �f�[�^�����m�F�p
    lv_api_msg_data          VARCHAR2(5000);                                  -- ����API���b�Z�[�W
    lv_key_name1             VARCHAR2(500);                                   -- �L�[�f�[�^����1
    lv_key_name2             VARCHAR2(500);                                   -- �L�[�f�[�^����2
    lv_key_data1             VARCHAR2(500);                                   -- �L�[�f�[�^1
    lv_key_data2             VARCHAR2(500);                                   -- �L�[�f�[�^2
--
    -- ��API�p����
    lv_return_status              VARCHAR2(1) ;                         -- API�̏����X�e�[�^�X
    ln_msg_count                  NUMBER;                               -- API�̃G���[���b�Z�[�W����
    lv_msg_data                   VARCHAR2(2000) ;                      -- API�̃G���[���b�Z�[�W
    lv_msg_buf                    VARCHAR2(2000);                       -- API���b�Z�[�W�����p
    -- ��API�p�z��
    lt_order_line_tbl             oe_order_pub.line_tbl_type;
    lt_header_rec                 oe_order_pub.header_rec_type;
    lt_header_val_rec             oe_order_pub.header_val_rec_type;
    lt_header_adj_tbl             oe_order_pub.header_adj_tbl_type;
    lt_header_adj_val_tbl         oe_order_pub.header_adj_val_tbl_type;
    lt_header_price_att_tbl       oe_order_pub.header_price_att_tbl_type;
    lt_header_adj_att_tbl         oe_order_pub.header_adj_att_tbl_type;
    lt_header_adj_assoc_tbl       oe_order_pub.header_adj_assoc_tbl_type;
    lt_header_scredit_tbl         oe_order_pub.header_scredit_tbl_type;
    lt_header_scredit_val_tbl     oe_order_pub.header_scredit_val_tbl_type;
    lt_line_val_tbl               oe_order_pub.line_val_tbl_type;
    lt_line_adj_tbl               oe_order_pub.line_adj_tbl_type;
    lt_line_adj_val_tbl           oe_order_pub.line_adj_val_tbl_type;
    lt_line_price_att_tbl         oe_order_pub.line_price_att_tbl_type;
    lt_line_adj_att_tbl           oe_order_pub.line_adj_att_tbl_type;
    lt_line_adj_assoc_tbl         oe_order_pub.line_adj_assoc_tbl_type;
    lt_line_scredit_tbl           oe_order_pub.line_scredit_tbl_type;
    lt_line_scredit_val_tbl       oe_order_pub.line_scredit_val_tbl_type;
    lt_lot_serial_tbl             oe_order_pub.lot_serial_tbl_type;
    lt_lot_serial_val_tbl         oe_order_pub.lot_serial_val_tbl_type;
    lt_action_request_tbl         oe_order_pub.request_tbl_type;
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
    -- �f�[�^�o�^�����m�F
    ln_data_cnt := gt_oe_order_number.COUNT;
    -- 
    lt_action_request_tbl(1).entity_code := OE_GLOBALS.G_ENTITY_HEADER;
    lt_action_request_tbl(1).request_type := OE_GLOBALS.G_BOOK_ORDER;
--
    <<om_close_loop>>
    FOR cnt_order IN 1..ln_data_cnt LOOP
--
      lt_order_number         := gt_oe_order_number( cnt_order );           -- �󒍔ԍ�
      lt_header_id            := gt_oe_header_id( cnt_order );              -- �󒍃w�b�_ID
      lt_he_flow_status_code  := gt_oe_he_flow_status_code( cnt_order );    -- �X�e�[�^�X
      lt_order_source_id      := gt_oe_order_source_id( cnt_order );        -- �󒍃\�[�XID
      lt_cust_po_number       := gt_oe_cust_po_number( cnt_order );         -- �ڋq����
      lt_line_id              := gt_oe_line_id( cnt_order );                -- �󒍖���ID
      lt_li_flow_status_code  := gt_oe_li_flow_status_code( cnt_order );    -- �X�e�[�^�X
--
      -- �w�b�_�X�e�[�^�X���u�L���ς݁v�ȊO�̏ꍇ
      IF ( lt_he_flow_status_code <> cv_status_booked ) THEN
--
        -- ���ʊ֐��p�ϐ��̏�����
        ln_msg_count     := 0;                                         -- ����API�G���[����
        lv_return_status := NULL;                                      -- ����API�X�e�[�^�X
        lv_msg_data      := NULL;                                      -- ����API���b�Z�[�W
        -- �L���ςݍX�V�Ώہu�󒍃w�b�_ID�v�ݒ�
        lt_action_request_tbl(1).entity_id := lt_header_id;
--
        -- �L���ςݍX�V����
        oe_order_pub.process_order(
          p_api_version_number      => cn_api_ver_num,
          x_return_status           => lv_return_status,
          x_msg_count               => ln_msg_count,
          x_msg_data                => lv_msg_data,
          p_header_rec              => lt_header_rec,
          p_line_tbl                => lt_order_line_tbl,
          p_action_request_tbl      => lt_action_request_tbl,
          x_header_rec              => lt_header_rec,
          x_header_val_rec          => lt_header_val_rec,
          x_header_adj_tbl          => lt_header_adj_tbl,
          x_header_adj_val_tbl      => lt_header_adj_val_tbl,
          x_header_price_att_tbl    => lt_header_price_att_tbl,
          x_header_adj_att_tbl      => lt_header_adj_att_tbl,
          x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl,
          x_header_scredit_tbl      => lt_header_scredit_tbl,
          x_header_scredit_val_tbl  => lt_header_scredit_val_tbl,
          x_line_tbl                => lt_order_line_tbl,
          x_line_val_tbl            => lt_line_val_tbl,
          x_line_adj_tbl            => lt_line_adj_tbl,
          x_line_adj_val_tbl        => lt_line_adj_val_tbl,
          x_line_price_att_tbl      => lt_line_price_att_tbl,
          x_line_adj_att_tbl        => lt_line_adj_att_tbl,
          x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl,
          x_line_scredit_tbl        => lt_line_scredit_tbl,
          x_line_scredit_val_tbl    => lt_line_scredit_val_tbl,
          x_lot_serial_tbl          => lt_lot_serial_tbl,
          x_lot_serial_val_tbl      => lt_lot_serial_val_tbl,
          x_action_request_tbl      => lt_action_request_tbl
          );
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        IF (ln_msg_count > 0 ) THEN
          -- ���b�Z�[�W������0���傫���ꍇ�G���[���b�Z�[�W���o��
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            lv_msg_buf := OE_MSG_PUB.GET(p_msg_index => cnt, 
                                         p_encoded   => 'F');
            lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
          END LOOP message_loop;
--
          --���b�Z�[�W����
          lv_errmsg := xxccp_common_pkg.get_msg(
                         cv_application, cv_msg_b_k_ping,
                         cv_line_number, lt_order_number
                         );
--          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      END IF;
--
      END IF;
--
      -- ���׃N���[�Y����
      BEGIN
        wf_engine.completeactivity(
          cv_tkn_oeol , lt_line_id , cv_xxcos_r_standard_line , cv_tkn_null );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE no_complet_expt;
      END;
--
    END LOOP om_close_loop;
--
  EXCEPTION
    WHEN no_complet_expt THEN
      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_close_api );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_application, cv_msg_close_err,
                       cv_tkn_api_name, gv_tkn1,
                       cv_line_number, lt_line_id );
--      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END proc_om_close;
--
  /**********************************************************************************
   * Procedure Name   : proc_insert
   * Description      : �̔����уf�[�^�o�^����(A-6)
   ***********************************************************************************/
  PROCEDURE proc_insert(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_insert'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --== �f�[�^�o�^���� ==--
    -- �w�b�_�f�[�^�쐬�����Z�b�g
    gn_normal_cnt := gt_head_id.COUNT;
    -- ���׃f�[�^�쐬�����Z�b�g
    gn_line_ins_cnt := gt_line_sales_exp_line_id.COUNT;
--
    -- =================
    -- �w�b�_�f�[�^�o�^
    -- =================
    BEGIN
      FORALL i IN 1..gn_normal_cnt
        INSERT INTO xxcos_sales_exp_headers          --�̔����уw�b�_�e�[�u��
                      (
                        sales_exp_header_id,                -- 1.�̔����уw�b�_ID
                        dlv_invoice_number,                 -- 2.�[�i�`�[�ԍ�
                        order_invoice_number,               -- 3.�����`�[�ԍ�
                        order_number,                       -- 4.�󒍔ԍ�
                        order_no_hht,                       -- 5.��No(HHT)
                        digestion_ln_number,                -- 6.��No(HHT)�}��
                        order_connection_number,            -- 7.�󒍊֘A�ԍ�
                        dlv_invoice_class,                  -- 8.�[�i�`�[�敪
                        cancel_correct_class,               -- 9.����E�����敪
                        input_class,                        -- 10.���͋敪
                        cust_gyotai_sho,                    -- 11.�Ƒԏ�����
                        delivery_date,                      -- 12.�[�i��
                        orig_delivery_date,                 -- 13.�I���W�i���[�i��
                        inspect_date,                       -- 14.������
                        orig_inspect_date,                  -- 15.�I���W�i��������
                        ship_to_customer_code,              -- 16.�ڋq�y�[�i��z
                        sale_amount_sum,                    -- 17.������z���v
                        pure_amount_sum,                    -- 18.�{�̋��z���v
                        tax_amount_sum,                     -- 19.����ŋ��z���v
                        consumption_tax_class,              -- 20.����ŋ敪
                        tax_code,                           -- 21.�ŋ��R�[�h
                        tax_rate,                           -- 22.����ŗ�
                        results_employee_code,              -- 23.���ьv��҃R�[�h
                        sales_base_code,                    -- 24.���㋒�_�R�[�h
                        receiv_base_code,                   -- 25.�������_�R�[�h
                        order_source_id,                    -- 26.�󒍃\�[�XID
                        card_sale_class,                    -- 27.�J�[�h����敪
                        invoice_class,                      -- 28.�`�[�敪
                        invoice_classification_code,        -- 29.�`�[���ރR�[�h
                        change_out_time_100,                -- 30.��K�؂ꎞ��100�~
                        change_out_time_10,                 -- 31.��K�؂ꎞ��10�~
                        ar_interface_flag,                  -- 32.AR�C���^�t�F�[�X�σt���O
                        gl_interface_flag,                  -- 33.G�C���^�t�F�[�X�σt���O
                        dwh_interface_flag,                 -- 34.���V�X�e���C���^�t�F�[�X�σt���O
                        edi_interface_flag,                 -- 35.EDI���M�ς݃t���O
                        edi_send_date,                      -- 36.EDI���M����
                        hht_dlv_input_date,                 -- 37.HHT�[�i���͓���
                        dlv_by_code,                        -- 38.�[�i�҃R�[�h
                        create_class,                       -- 39.�쐬���敪
                        business_date,                      -- 40.�o�^�Ɩ����t
                        created_by,                         -- 41.�쐬��
                        creation_date,                      -- 42.�쐬��
                        last_updated_by,                    -- 43.�ŏI�X�V��
                        last_update_date,                   -- 44.�ŏI�X�V��
                        last_update_login,                  -- 45.�ŏI�X�V۸޲�
                        request_id,                         -- 46.�v��ID
                        program_application_id,             -- 47.�ݶ��ĥ��۸��ѥ���ع����ID
                        program_id,                         -- 48.�ݶ��ĥ��۸���ID
                        program_update_date )               -- 49.��۸��эX�V��
                      VALUES(
                        gt_head_id( i ),                    -- 1.�̔����уw�b�_ID
                        gt_head_hht_invoice_no( i ),        -- 2.HHT�`�[�ԍ�
                        gt_head_order_invoice_number( i ),  -- 3.�����`�[�ԍ�
                        gt_head_order_no_ebs( i ),          -- 4.�󒍔ԍ�
                        gt_head_order_no_hht( i ),          -- 5.��No(HHT)
                        gt_head_digestion_ln_number( i ),   -- 6.��No(HHT)�}��
                        gt_head_order_connection_num( i ),  -- 7.�󒍊֘A�ԍ�
                        gt_head_dlv_invoice_class( i ),     -- 8.�[�i�`�[�敪
                        gt_head_cancel_cor_cls( i ),        -- 9.����E�����敪
                        gt_head_input_class( i ),           -- 10.���͋敪
                        gt_head_system_class( i ),          -- 11.�Ƒԏ�����
                        gt_head_dlv_date( i ),              -- 12.�[�i��
                        gt_head_dlv_date( i ),              -- 13.�I���W�i���[�i��
                        gt_head_inspect_date( i ),          -- 14.������(����v���?)
                        gt_head_inspect_date( i ),          -- 15.�I���W�i��������
                        gt_head_customer_number( i ),       -- 16.�ڋq�y�[�i��z
                        gt_head_tax_include( i ),           -- 17.������z���v
                        gt_head_total_amount( i ),          -- 18.�{�̋��z���v
                        gt_head_sales_consump_tax( i ),     -- 19.����ŋ��z���v
                        gt_head_consump_tax_class( i ),     -- 20.����ŋ敪
                        gt_head_tax_code( i ),              -- 21.�ŋ��R�[�h
                        gt_head_tax_rate( i ),              -- 22.����ŗ�
                        gt_head_performance_by_code( i ),   -- 23.���ьv��҃R�[�h
                        gt_head_sales_base_code( i ),       -- 24.���㋒�_�R�[�h
                        gt_head_receiv_base_code( i ),      -- 25.�������_�R�[�h
                        gt_head_order_source_id( i ),       -- 26.�󒍃\�[�XID
                        gt_head_card_sale_class( i ),       -- 27.�J�[�h����敪
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
                        gt_head_sales_classification( i ),  -- 28.�`�[�敪
                        gt_head_invoice_class( i ),         -- 29.�`�[���ރR�[�h
--                        gt_head_invoice_class( i ),         -- 28.����`�[�敪(�`�[���ރR�[�h)
--                        gt_head_sales_classification( i ),  -- 29.���㕪�ދ敪(�`�[�敪)
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                        gt_head_change_out_time_100( i ),   -- 30.��K�؂ꎞ��100�~
                        gt_head_change_out_time_10( i ),    -- 31.��K�؂ꎞ��10�~
                        gt_head_ar_interface_flag( i ),     -- 32.AR�C���^�t�F�[�X�σt���O
                        gt_head_gl_interface_flag( i ),     -- 33.GL�C���^�t�F�[�X�σt���O
                        gt_head_dwh_interface_flag( i ),    -- 34.���V�X�e���C���^�t�F�[�X�σt���O
                        gt_head_edi_interface_flag( i ),    -- 35.EDI���M�ς݃t���O
                        gt_head_edi_send_date( i ),         -- 36.EDI���M����
                        gt_head_hht_dlv_input_date( i ),    -- 37.HHT�[�i���͓���
                        gt_head_dlv_by_code( i ),           -- 38.�[�i�҃R�[�h
                        gt_head_create_class( i ),          -- 39.�쐬���敪
                        gt_head_business_date( i ),         -- 40.�o�^�Ɩ����t
                        cn_created_by,                      -- 41.�쐬��
                        cd_creation_date,                   -- 42.�쐬��
                        cn_last_updated_by,                 -- 43.�ŏI�X�V��
                        cd_last_update_date,                -- 44.�ŏI�X�V��
                        cn_last_update_login,               -- 45.�ŏI�X�V۸޲�
                        cn_request_id,                      -- 46.�v��ID
                        cn_program_application_id,          -- 47.�ݶ��ĥ��۸��ѥ���ع����ID
                        cn_program_id,                      -- 48.�ݶ��ĥ��۸���ID
                        cd_program_update_date );           -- 49.��۸��эX�V��
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_xxcos_sal_exp_head);
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_ins_err,
                                             cv_tkn_table_na,gv_tkn1 );
        RAISE insert_err_expt;
        RAISE;
    END;
--
    -- ===============================
    -- ���׃f�[�^�o�^
    -- ===============================
    BEGIN
      FORALL i IN 1..gn_line_ins_cnt
        INSERT INTO xxcos_sales_exp_lines            -- �̔����і��׃e�[�u��
                      (
                        sales_exp_line_id,                  -- 1.�̔����і���ID
                        sales_exp_header_id,                -- 2.�̔����уw�b�_ID
                        dlv_invoice_number,                 -- 3.�[�i�`�[�ԍ�
                        dlv_invoice_line_number,            -- 4.�[�i���הԍ�
                        order_invoice_line_number,          -- 5.�������הԍ�
                        sales_class,                        -- 6.����敪
                        red_black_flag,                     -- 7.�ԍ��t���O
                        item_code,                          -- 8.�i�ڃR�[�h
                        dlv_qty,                            -- 9.�[�i����
                        standard_qty,                       -- 10.�����
                        dlv_uom_code,                       -- 11.�[�i�P��
                        standard_uom_code,                  -- 12.��P��
                        dlv_unit_price,                     -- 13.�[�i�P��
                        standard_unit_price_excluded,       -- 14.�Ŕ���P��
                        standard_unit_price,                -- 15.��P��
                        business_cost,                      -- 16.�c�ƌ���
                        sale_amount,                        -- 17.������z
                        pure_amount,                        -- 18.�{�̋��z
                        tax_amount,                         -- 19.����ŋ��z
                        cash_and_card,                      -- 20.�����E�J�[�h���p�z
                        ship_from_subinventory_code,        -- 21.�o�׌��ۊǏꏊ
                        delivery_base_code,                 -- 22.�[�i���_�R�[�h
                        hot_cold_class,                     -- 23.�g���b
                        column_no,                          -- 24.�R����No
                        sold_out_class,                     -- 25.���؋敪
                        sold_out_time,                      -- 26.���؎���
                        delivery_pattern_class,             -- 27.�[�i�`�ԋ敪
                        to_calculate_fees_flag,             -- 28.�萔���v�Z�C���^�t�F�[�X�σt���O
                        unit_price_mst_flag,                -- 29.�P���}�X�^�쐬�σt���O
                        inv_interface_flag,                 -- 30.INV�C���^�t�F�[�X�σt���O
                        created_by,                         -- 31.�쐬��
                        creation_date,                      -- 32.�쐬��
                        last_updated_by,                    -- 33.�ŏI�X�V��
                        last_update_date,                   -- 34.�ŏI�X�V��
                        last_update_login,                  -- 35.�ŏI�X�V۸޲�
                        request_id,                         -- 36.�v��ID
                        program_application_id,             -- 37.�ݶ��ĥ��۸��ѥ���ع����ID
                        program_id,                         -- 38.�ݶ��ĥ��۸���ID
                        program_update_date )               -- 39.��۸��эX�V��
                      VALUES(
                        gt_line_sales_exp_line_id( i ),     -- 1.�̔����і���ID
                        gt_line_sales_exp_header_id( i ),   -- 2.�̔����уw�b�_ID
                        gt_line_dlv_invoice_number( i ),    -- 3.�[�i�`�[�ԍ�
                        gt_line_dlv_invoice_l_num( i ),     -- 4.�[�i���הԍ�
                        gt_line_order_invoice_l_num( i ),   -- 5.�������הԍ�
                        gt_line_sales_class( i ),           -- 6.����敪
                        gt_line_red_black_flag( i ),        -- 7.�ԍ��t���O
                        gt_line_item_code( i ),             -- 8.�i�ڃR�[�h
                        gt_line_dlv_qty( i ),               -- 9.�[�i����
                        gt_line_standard_qty( i ),          -- 10.�����
                        gt_line_dlv_uom_code( i ),          -- 11.�[�i�P��
                        gt_line_standard_uom_code( i ),     -- 12.��P��
                        gt_dlv_unit_price( i ),             -- 13.�[�i�P��
                        gt_line_not_tax_amount( i ),        -- 14.�Ŕ���P��
                        gt_line_standard_unit_price( i ),   -- 15.��P��
                        gt_line_business_cost( i ),         -- 16.�c�ƌ���
                        gt_line_sale_amount( i ),           -- 17.������z
                        gt_line_pure_amount( i ),           -- 18.�{�̋��z
                        gt_line_tax_amount( i ),            -- 19.����ŋ��z
                        gt_line_cash_and_card( i ),         -- 20.�����E�J�[�h���p�z
                        gt_line_ship_from_subinv_co( i ),   -- 21.�o�׌��ۊǏꏊ
                        gt_line_delivery_base_code( i ),    -- 22.�[�i���_�R�[�h
                        gt_line_hot_cold_class( i ),        -- 23.�g���b
                        gt_line_column_no( i ),             -- 24.�R����No
                        gt_line_sold_out_class( i ),        -- 25.���؋敪
                        gt_line_sold_out_time( i ),         -- 26.���؎���
                        gt_line_delivery_pat_class( i ),    -- 27.�[�i�`�ԋ敪
                        gt_line_to_calculate_fees_flag( i ), -- 28.�萔���v�Z�C���^�t�F�[�X�σt���O
                        gt_line_unit_price_mst_flag( i ),   -- 29.�P���}�X�^�쐬�σt���O
                        gt_line_inv_interface_flag( i ),    -- 30.INV�C���^�t�F�[�X�σt���O
                        cn_created_by,                      -- 31.�쐬��
                        cd_creation_date,                   -- 32.�쐬��
                        cn_last_updated_by,                 -- 33.�ŏI�X�V��
                        cd_last_update_date,                -- 34.�ŏI�X�V��
                        cn_last_update_login,               -- 35.�ŏI�X�V۸޲�
                        cn_request_id,                      -- 36.�v��ID
                        cn_program_application_id,          -- 37.�ݶ��ĥ��۸��ѥ���ع����ID
                        cn_program_id,                      -- 38.�ݶ��ĥ��۸���ID
                        cd_program_update_date );           -- 39.��۸��эX�V��
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_xxcos_sal_exp_line );
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_ins_err,
                                             cv_tkn_table_na, gv_tkn1 );
        RAISE insert_err_expt;
        RAISE;
    END;
--
  EXCEPTION
    WHEN insert_err_expt THEN
--      lv_errbuf  := gv_tkn2;
      ov_errmsg  := gv_tkn2;
      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_insert;
--
  /**********************************************************************************
   * Procedure Name   : proc_molded_trans
   * Description      : �̔����уf�[�^�i���o�Ɂj���^����(A-5)
   ***********************************************************************************/
  PROCEDURE proc_molded_trans(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_molded_trans'; -- �v���O������
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
    lt_head_employee_num              xxcoi_hht_inv_transactions.employee_num%TYPE;              -- �c�ƈ��R�[�h
    lt_head_invoice_no                xxcoi_hht_inv_transactions.invoice_no%TYPE;                -- �`�[.No
    lt_head_invoice_type              xxcoi_hht_inv_transactions.invoice_type%TYPE;              -- �`�[�敪
    lt_head_inside_code               xxcoi_hht_inv_transactions.inside_code%TYPE;               -- ���ɑ��R�[�h
    lt_head_invoice_date              xxcoi_hht_inv_transactions.invoice_date%TYPE;              -- �`�[���t
    lt_head_record_type               xxcoi_hht_inv_transactions.record_type%TYPE;               -- ���R�[�h���
    lt_head_inside_cust_code          xxcoi_hht_inv_transactions.inside_cust_code%TYPE;          -- ���ɑ��ڋq�R�[�h
    lt_head_inside_business_low_t     xxcoi_hht_inv_transactions.inside_business_low_type%TYPE;  -- ���ɑ��Ƒԋ敪
--
    lt_transaction_id                 xxcoi_hht_inv_transactions.transaction_id%TYPE;            -- ���o�Ɉꎞ�\ID
    lt_interface_id                   xxcoi_hht_inv_transactions.interface_id%TYPE;              -- �C���^�[�t�F�[�XID
    lt_form_header_id                 xxcoi_hht_inv_transactions.form_header_id%TYPE;            -- ��ʓ��͗p�w�b�_ID
    lt_base_code                      xxcoi_hht_inv_transactions.base_code%TYPE;                 -- ���_�R�[�h
    lt_record_type                    xxcoi_hht_inv_transactions.record_type%TYPE;               -- ���R�[�h���
    lt_employee_num                   xxcoi_hht_inv_transactions.employee_num%TYPE;              -- �c�ƈ��R�[�h
    lt_invoice_no                     xxcoi_hht_inv_transactions.invoice_no%TYPE;                -- �`�[��
    lt_item_code                      xxcoi_hht_inv_transactions.item_code%TYPE;                 -- �i�ڃR�[�h
    lt_case_quantity                  xxcoi_hht_inv_transactions.case_quantity%TYPE;             -- �P�[�X��
    lt_case_in_quantity               xxcoi_hht_inv_transactions.case_in_quantity%TYPE;          -- ����
    lt_quantity                       xxcoi_hht_inv_transactions.quantity%TYPE;                  -- �{��
    lt_invoice_type                   xxcoi_hht_inv_transactions.invoice_type%TYPE;              -- �`�[�敪
    lt_base_delivery_flag             xxcoi_hht_inv_transactions.base_delivery_flag%TYPE;        -- ���_�ԑq�փt���O
    lt_outside_code                   xxcoi_hht_inv_transactions.outside_code%TYPE;              -- �o�ɑ��R�[�h
    lt_inside_code                    xxcoi_hht_inv_transactions.inside_code%TYPE;               -- ���ɑ��R�[�h
    lt_invoice_date                   xxcoi_hht_inv_transactions.invoice_date%TYPE;              -- �`�[���t
    lt_column_no                      xxcoi_hht_inv_transactions.column_no%TYPE;                 -- �R������
    lt_unit_price                     xxcoi_hht_inv_transactions.unit_price%TYPE;                -- �P��
    lt_hot_cold_div                   xxcoi_hht_inv_transactions.hot_cold_div%TYPE;              -- H/C
    lt_department_flag                xxcoi_hht_inv_transactions.department_flag%TYPE;           -- �S�ݓX�t���O
    lt_interface_date                 xxcoi_hht_inv_transactions.interface_date%TYPE;            -- ��M����
    lt_other_base_code                xxcoi_hht_inv_transactions.other_base_code%TYPE;           -- �����_�R�[�h
    lt_outside_subinv_code            xxcoi_hht_inv_transactions.outside_subinv_code%TYPE;       -- �o�ɑ��ۊǏꏊ
    lt_inside_subinv_code             xxcoi_hht_inv_transactions.inside_subinv_code%TYPE;        -- ���ɑ��ۊǏꏊ
    lt_outside_base_code              xxcoi_hht_inv_transactions.outside_base_code%TYPE;         -- �o�ɑ����_
    lt_inside_base_code               xxcoi_hht_inv_transactions.inside_base_code%TYPE;          -- ���ɑ����_
    lt_total_quantity                 xxcoi_hht_inv_transactions.total_quantity%TYPE;            -- ���{��
    lt_inventory_item_id              xxcoi_hht_inv_transactions.inventory_item_id%TYPE;         -- �i��ID
    lt_primary_uom_code               xxcoi_hht_inv_transactions.primary_uom_code%TYPE;          -- ��P��
    lt_outside_subinv_code_co_div     xxcoi_hht_inv_transactions.outside_subinv_code_conv_div%TYPE; -- �o�ɑ��ۊǏꏊ�ϊ�
    lt_inside_subinv_code_conv_div    xxcoi_hht_inv_transactions.inside_subinv_code_conv_div%TYPE;-- ���ɑ��ۊǏꏊ�ϊ�
    lt_outside_business_low_type      xxcoi_hht_inv_transactions.outside_business_low_type%TYPE; -- �o�ɑ��Ƒԋ敪
    lt_inside_business_low_type       xxcoi_hht_inv_transactions.inside_business_low_type%TYPE;  -- ���ɑ��Ƒԋ敪
    lt_outside_cust_code              xxcoi_hht_inv_transactions.outside_cust_code%TYPE;         -- �o�ɑ��ڋq�R�[�h
    lt_inside_cust_code               xxcoi_hht_inv_transactions.inside_cust_code%TYPE;          -- ���ɑ��ڋq�R�[�h
    lt_hht_program_div                xxcoi_hht_inv_transactions.hht_program_div%TYPE;       -- ���o�ɃW���[�i�������敪
    lt_consume_vd_flag                xxcoi_hht_inv_transactions.consume_vd_flag%TYPE;           -- ����VD��[�Ώۃt���O
    lt_item_convert_div               xxcoi_hht_inv_transactions.item_convert_div%TYPE;          -- ���i�U�֋敪
    lt_stock_uncheck_list_div         xxcoi_hht_inv_transactions.stock_uncheck_list_div%TYPE;-- ���ɖ��m�F���X�g�Ώ�
    lt_stock_balance_list_div         xxcoi_hht_inv_transactions.stock_balance_list_div%TYPE;-- ���ɍ��يm�F���X�g�Ώ�
    lt_status                         xxcoi_hht_inv_transactions.status%TYPE;                    -- �����X�e�[�^�X
    lt_column_if_flag                 xxcoi_hht_inv_transactions.column_if_flag%TYPE;            -- �R�����ʓ]���σt���O
    lt_column_if_date                 xxcoi_hht_inv_transactions.column_if_date%TYPE;            -- �R�����ʓ]����
    lt_sample_if_flag                 xxcoi_hht_inv_transactions.sample_if_flag%TYPE;            -- ���{�]���σt���O
    lt_sample_if_date                 xxcoi_hht_inv_transactions.sample_if_date%TYPE;            -- ���{�]����
    lt_output_flag                    xxcoi_hht_inv_transactions.output_flag%TYPE;               -- �o�͍σt���O
    lt_old_sales_cost                 ic_item_mst_b.attribute7%TYPE;                             -- ���c�ƌ���
    lt_new_sales_cost                 ic_item_mst_b.attribute8%TYPE;                             -- �V�c�ƌ���
    lt_st_sales_cost                  ic_item_mst_b.attribute9%TYPE;                             -- �c�ƌ����K�p�J�n��
    lt_stand_unit                     mtl_system_items_b.primary_unit_of_measure%TYPE;           -- ��P��
    lt_inc_num                        xxcmm_system_items_b.inc_num%TYPE;                         -- �������
-- ************** 2009/05/13 1.13 N.Maeda DEL START ****************************************************************
--    lt_tax_odd                        xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE;           -- �ŋ�-�[������
-- ************** 2009/05/13 1.13 N.Maeda DEL  END  ****************************************************************
    lt_sale_base_code                 xxcmm_cust_accounts.sale_base_code%TYPE;                   -- ���㋒�_�R�[�h
-- ************** 2009/05/13 1.13 N.Maeda DEL START ****************************************************************
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--    lt_cash_receiv_base_code          xxcos_cust_hierarchy_v.cash_receiv_base_code%TYPE;         -- �������_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
-- ************** 2009/05/13 1.13 N.Maeda DEL  END  ****************************************************************
    lt_dlv_base_code                  xxcos_rs_info_v.base_code%TYPE;                            -- ���_�R�[�h
    lt_ins_invoice_type               fnd_lookup_values.attribute1%TYPE;                         -- �[�i�`�[�敪
    lt_cust_gyotai_sho                xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;              -- ����E�����敪
    lt_red_black_flag                 xxcos_sales_exp_lines.red_black_flag%TYPE;                 -- �ԍ��t���O
    lt_sales_cost                     ic_item_mst_b.attribute7%TYPE;                             -- �c�ƌ���
    lt_no_tax_code                    fnd_lookup_values.meaning%TYPE;                            -- ����ŃR�[�h(�ΏۊO)
    lv_delivery_type                  VARCHAR2(100);                                             -- �[�i�`�ԋ敪
    lv_key_name1                      VARCHAR2(500);                                             -- �L�[�f�[�^����1
    lv_key_name2                      VARCHAR2(500);                                             -- �L�[�f�[�^����2
    lv_key_data1                      VARCHAR2(500);                                             -- �L�[�f�[�^1
    lv_key_data2                      VARCHAR2(500);                                             -- �L�[�f�[�^2
    ln_actual_id                      NUMBER;                                                    -- �w�b�_ID
    ln_sales_exp_line_id              NUMBER;                                                    -- ����ID
    ln_invoice_line_num               NUMBER;                                                    -- �[�i���הԍ�
    ln_line_no                        NUMBER :=  1;                                              -- ���׃`�F�b�N�ϔԍ�
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
    lt_row_id                         ROWID;                                           -- �X�V�p�sID
    lv_state_flg                      VARCHAR2(1);                                     -- �f�[�^�x���m�F�t���O
    ln_line_data_count                NUMBER;                                          -- ���׌���(�w�b�_�P��)
    ln_tran_rowid_num                 NUMBER := 0;                                     -- �X�e�[�^�X�X�V�p
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--******************************* 2009/05/13 N.Maeda Var1.14 ADD START ***************************************
    lt_normal_class                   fnd_lookup_values.attribute1%TYPE;               -- �[�i�`�[�敪(�ʏ�)
    lt_correct_class                  fnd_lookup_values.attribute1%TYPE;               -- �[�i�`�[�敪(����E����)
--******************************* 2009/05/13 N.Maeda Var1.14 ADD END *****************************************lt_ins_invoice_type
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =================
    -- ����ŃR�[�h�擾
    -- =================
    BEGIN
      SELECT  look_val.meaning      --����ŃR�[�h(�ΏۊO)
      INTO    lt_no_tax_code
      FROM    fnd_lookup_values     look_val,
              fnd_lookup_types_tl   types_tl,
              fnd_lookup_types      types,
              fnd_application_tl    appl,
              fnd_application       app
      WHERE   appl.application_id   = types.application_id
      AND     app.application_id    = appl.application_id
      AND     types_tl.lookup_type  = look_val.lookup_type
      AND     types.lookup_type     = types_tl.lookup_type
      AND     types.security_group_id   = types_tl.security_group_id
      AND     types.view_application_id = types_tl.view_application_id
      AND     types_tl.language = USERENV( 'LANG' )
      AND     look_val.language = USERENV( 'LANG' )
      AND     appl.language     = USERENV( 'LANG' )
      AND     gd_process_date      >= look_val.start_date_active
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     app.application_short_name = cv_application
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     look_val.lookup_type = cv_xxcos1_cons_tax_no
      AND     look_val.lookup_code = cv_xxcos_001_a05_01;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
          -- ���O�o��
          gv_tkn1   := xxccp_common_pkg.get_msg(cv_application, cv_msg_lookup_mst );
          --�L�[�ҏW����
          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code );
          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type );
          lv_key_data1 := cv_xxcos1_hokan_mst_001_a05;
          lv_key_data2 := cv_xxcos_001_a05_01;
        RAISE no_data_extract;
    END;
--
--******************************* 2009/05/13 N.Maeda Var1.14 ADD START ***************************************
    --===============================================================
    --�[�i�`�[�敪�擾
    --===============================================================
    BEGIN
      SELECT  look_val.attribute4,  -- �ʏ펞(�[�i�`�[�敪)
              look_val.attribute5   -- �����E�����(�[�i�`�[�敪)
      INTO    lt_normal_class,
              lt_correct_class
      FROM    fnd_lookup_values     look_val,
              fnd_lookup_types_tl   types_tl,
              fnd_lookup_types      types,
              fnd_application_tl    appl,
              fnd_application       app
      WHERE   appl.application_id   = types.application_id
      AND     app.application_id    = appl.application_id
      AND     types_tl.lookup_type  = look_val.lookup_type
      AND     types.lookup_type     = types_tl.lookup_type
      AND     types.security_group_id   = types_tl.security_group_id
      AND     types.view_application_id = types_tl.view_application_id
      AND     types_tl.language = USERENV( 'LANG' )
      AND     look_val.language = USERENV( 'LANG' )
      AND     appl.language     = USERENV( 'LANG' )
      AND     gd_process_date      >= look_val.start_date_active
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     app.application_short_name = cv_application
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     look_val.lookup_type = cv_xxcos1_input_class
      AND     look_val.lookup_code = cv_input_delivery;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ���O�o��
        lv_key_name1 :=xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
        lv_key_name2 := NULL;
        lv_key_data1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
        lv_key_data2 := NULL;
      RAISE no_data_extract;
    END;
--******************************* 2009/05/13 N.Maeda Var1.14 ADD END *****************************************
--
    <<trans_head_loop>>
    FOR trans_head_no IN 1..gn_transaction_head_cnt LOOP
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, gv_out_msg );
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      -- ���׌����J�E���g(������)
      ln_line_data_count              := 0;
      -- �f�[�^�x���m�F�t���O(������)
      lv_state_flg                    := cv_status_normal;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--
      lt_head_employee_num        := gt_inv_trans_head( trans_head_no ).employee_num;          -- �c�ƈ��R�[�h
      lt_head_invoice_no          := gt_inv_trans_head( trans_head_no ).invoice_no;            -- �`�[No.
      lt_head_invoice_type        := gt_inv_trans_head( trans_head_no ).invoice_type;          -- �`�[�敪
      lt_head_inside_code         := gt_inv_trans_head( trans_head_no ).inside_code;           -- ���ɑ��R�[�h
      lt_head_invoice_date        := gt_inv_trans_head( trans_head_no ).invoice_date;          -- �`�[���t
      lt_head_record_type         := gt_inv_trans_head( trans_head_no ).record_type;           -- ���R�[�h���
      lt_head_inside_cust_code    := gt_inv_trans_head( trans_head_no ).inside_cust_code;      -- ���ɑ��ڋq�R�[�h
      lt_head_inside_business_low_t := gt_inv_trans_head( trans_head_no ).inside_business_low_type; -- ���ɑ��Ƒԋ敪
--
--
      --�[�i���הԍ��̏�����
      ln_invoice_line_num := 0;
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--      --================================
--      --�̔����уw�b�_ID(�V�[�P���X�擾)
--      --================================
--      SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
--      INTO ln_actual_id
--      FROM DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
--
      -- ===============================
      -- �ڋq�}�X�^�t�я��̓��o
      -- ===============================
      BEGIN
-- ************** 2009/05/13 1.13 N.Maeda MOD START ****************************************************************
        SELECT  xca.sale_base_code            -- ���㋒�_�R�[�h
--                --hca.tax_rounding_rule --�ŋ�-�[������
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--                xch.cash_receiv_base_code,  -- �������_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
--                xch.bill_tax_round_rule     -- �ŋ�-�[������(�T�C�g)
        INTO    lt_sale_base_code
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--                lt_cash_receiv_base_code,
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
--                lt_tax_odd
        FROM    hz_cust_accounts hca,      -- �ڋq�}�X�^
                xxcmm_cust_accounts xca   -- �ڋq�ǉ����
--                xxcos_cust_hierarchy_v xch -- �ڋq�K�w�r���[
        WHERE   hca.cust_account_id = xca.customer_id
--        AND     xch.ship_account_id = hca.cust_account_id
--        AND     xch.ship_account_id = xca.customer_id
        AND     hca.account_number = TO_CHAR( lt_head_inside_cust_code );
--        AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
--        AND     hca.party_id IN ( SELECT  hpt.party_id
--                                  FROM    hz_parties hpt
--                                  WHERE   hpt.duns_number_c   IN ( cv_cust_s , cv_cust_v , cv_cost_p ) );
-- ************** 2009/05/13 1.13 N.Maeda MOD  END  ****************************************************************
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
          --�L�[�ҏW����
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
--          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code );
--          lv_key_data1 := cv_customer_type_c||cv_con_char||cv_customer_type_u;
--          lv_key_data2 := lt_head_inside_cust_code;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code ), -- ���ږ��̂P
            iv_data_value1 => ( lt_head_inside_cust_code ),         -- �f�[�^�̒l�P
--            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type ), -- ���ږ��̂P
--            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code ), -- ���ږ��̂Q
--            iv_data_value1 => ( cv_customer_type_c||cv_con_char||cv_customer_type_u ),         -- �f�[�^�̒l�P
--            iv_data_value2 => lt_head_inside_cust_code,       -- �f�[�^�̒l�Q
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
      END;
--
      -- ================================
      -- HHT�[�i���͓����̐��^����
      -- ================================
      lt_head_invoice_date := TRUNC(lt_head_invoice_date);
--
--******************************* 2009/05/13 N.Maeda Var1.14 DEL START ***************************************
--      BEGIN
--        SELECT  look_val.attribute1   -- �ʏ펞(�[�i�`�[�敪(�̔����ѓ��͋敪))
--        INTO    lt_ins_invoice_type
--        FROM    fnd_lookup_values     look_val,
--                fnd_lookup_types_tl   types_tl,
--                fnd_lookup_types      types,
--                fnd_application_tl    appl,
--                fnd_application       app
--        WHERE   appl.application_id   = types.application_id
--        AND     app.application_id    = appl.application_id
--        AND     types_tl.lookup_type  = look_val.lookup_type
--        AND     types.lookup_type     = types_tl.lookup_type
--        AND     types.security_group_id   = types_tl.security_group_id
--        AND     types.view_application_id = types_tl.view_application_id
--        AND     types_tl.language = USERENV( 'LANG' )
--        AND     look_val.language = USERENV( 'LANG' )
--        AND     appl.language     = USERENV( 'LANG' )
--        AND     gd_process_date      >= look_val.start_date_active
--        AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--        AND     app.application_short_name = cv_application_coi
--        AND     look_val.enabled_flag = cv_tkn_yes
--        AND     look_val.lookup_type = cv_xxcoi1_hht_inv_data_div
--        AND     look_val.lookup_code = lt_head_record_type;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- ���O�o��          
--          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
--          --�L�[�ҏW�\�ϐ��ݒ�
----******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
----          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_rec_type );
----          lv_key_name2 := NULL;
----          lv_key_data1 := lt_head_record_type;
----          lv_key_data2 := NULL;
----        RAISE no_data_extract;
--          lv_state_flg    := cv_status_warn;
--          gn_wae_data_num := gn_wae_data_num + 1 ;
--          xxcos_common_pkg.makeup_key_info(
--            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_rec_type ), -- ���ږ��̂P
--            iv_data_value1 => lt_head_record_type,         -- �f�[�^�̒l�P
--            ov_key_info    => gv_tkn2,              -- �L�[���
--            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
--            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
--            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
--          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
--                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
--                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
--                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
--                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
--                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
----******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--      END;
--******************************* 2009/05/13 N.Maeda Var1.14 DEL END *****************************************
--
      -- ���׃f�[�^�擾
      <<trans_loop>>
      FOR line_no IN ln_line_no..gn_transaction_cnt LOOP
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
        lt_row_id                       :=  gt_inv_transactions_data( line_no ).row_id;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
        lt_transaction_id               :=  gt_inv_transactions_data( line_no ).transaction_id;    -- ���o�Ɉꎞ�\ID
        lt_interface_id                 :=  gt_inv_transactions_data( line_no ).interface_id;      -- IF-ID
        lt_form_header_id               :=  gt_inv_transactions_data( line_no ).form_header_id;    -- ��ʓ��͗p�w�b�_ID
        lt_base_code                    :=  gt_inv_transactions_data( line_no ).base_code;         -- ���_�R�[�h
        lt_record_type                  :=  gt_inv_transactions_data( line_no ).record_type;       -- ���R�[�h���
        lt_employee_num                 :=  gt_inv_transactions_data( line_no ).employee_num;      -- �c�ƈ��R�[�h
        lt_invoice_no                   :=  gt_inv_transactions_data( line_no ).invoice_no;        -- �`�[��
        lt_item_code                    :=  gt_inv_transactions_data( line_no ).item_code;         -- �i�ڃR�[�h
        lt_case_quantity                :=  gt_inv_transactions_data( line_no ).case_quantity;     -- �P�[�X��
        lt_case_in_quantity             :=  gt_inv_transactions_data( line_no ).case_in_quantity;  -- ����
        lt_quantity                     :=  gt_inv_transactions_data( line_no ).quantity;          -- �{��
        lt_invoice_type                 :=  gt_inv_transactions_data( line_no ).invoice_type;      -- �`�[�敪
        lt_base_delivery_flag           :=  gt_inv_transactions_data( line_no ).base_delivery_flag;-- ���_�ԑq�փt���O
        lt_outside_code                 :=  gt_inv_transactions_data( line_no ).outside_code;      -- �o�ɑ��R�[�h
        lt_inside_code                  :=  gt_inv_transactions_data( line_no ).inside_code;       -- ���ɑ��R�[�h
        lt_invoice_date                 :=  gt_inv_transactions_data( line_no ).invoice_date;      -- �`�[���t
        lt_column_no                    :=  gt_inv_transactions_data( line_no ).column_no;         -- �R������
        lt_unit_price                   :=  gt_inv_transactions_data( line_no ).unit_price;        -- �P��
        lt_hot_cold_div                 :=  gt_inv_transactions_data( line_no ).hot_cold_div;      -- H/C
        lt_department_flag              :=  gt_inv_transactions_data( line_no ).department_flag;   -- �S�ݓX�t���O
        lt_interface_date               :=  gt_inv_transactions_data( line_no ).interface_date;    -- ��M����
        lt_other_base_code              :=  gt_inv_transactions_data( line_no ).other_base_code;   -- �����_�R�[�h
        lt_outside_subinv_code          :=  gt_inv_transactions_data( line_no ).outside_subinv_code;-- �o�ɑ��ۊǏꏊ
        lt_inside_subinv_code           :=  gt_inv_transactions_data( line_no ).inside_subinv_code; -- ���ɑ��ۊǏꏊ
-- ************** 2009/05/13 1.13 N.Maeda MOD START ****************************************************************
--        lt_outside_base_code            :=  gt_inv_transactions_data( line_no ).outside_base_code; -- �o�ɑ����_
        lt_dlv_base_code                :=  gt_inv_transactions_data( line_no ).outside_base_code; -- �o�ɑ����_
-- ************** 2009/05/13 1.13 N.Maeda MOD  END  ****************************************************************
        lt_inside_base_code             :=  gt_inv_transactions_data( line_no ).inside_base_code;  -- ���ɑ����_
        lt_total_quantity               :=  gt_inv_transactions_data( line_no ).total_quantity;    -- ���{��
        lt_inventory_item_id            :=  gt_inv_transactions_data( line_no ).inventory_item_id; -- �i��ID
        lt_primary_uom_code             :=  gt_inv_transactions_data( line_no ).primary_uom_code;  -- ��P��
        lt_outside_subinv_code_co_div   :=  gt_inv_transactions_data( line_no ).outside_subinv_code_conv_div;
        lt_inside_subinv_code_conv_div  :=  gt_inv_transactions_data( line_no ).inside_subinv_code_conv_div;
        lt_outside_business_low_type    :=  gt_inv_transactions_data( line_no ).outside_business_low_type;
        lt_inside_business_low_type     :=  gt_inv_transactions_data( line_no ).inside_business_low_type;
        lt_outside_cust_code            :=  gt_inv_transactions_data( line_no ).outside_cust_code; -- �o�ɑ��ڋq�R�[�h
        lt_inside_cust_code             :=  gt_inv_transactions_data( line_no ).inside_cust_code;  -- ���ɑ��ڋq�R�[�h
        lt_hht_program_div              :=  gt_inv_transactions_data( line_no ).hht_program_div;
        lt_consume_vd_flag              :=  gt_inv_transactions_data( line_no ).consume_vd_flag; -- ����VD��[�Ώۃt���O
        lt_item_convert_div             :=  gt_inv_transactions_data( line_no ).item_convert_div;  -- ���i�U�֋敪
        lt_stock_uncheck_list_div       :=  gt_inv_transactions_data( line_no ).stock_uncheck_list_div;
        lt_stock_balance_list_div       :=  gt_inv_transactions_data( line_no ).stock_balance_list_div;
        lt_status                       :=  gt_inv_transactions_data( line_no ).status;            -- �����X�e�[�^�X
        lt_column_if_flag               :=  gt_inv_transactions_data( line_no ).column_if_flag;  -- �R�����ʓ]���σt���O
        lt_column_if_date               :=  gt_inv_transactions_data( line_no ).column_if_date;  -- �R�����ʓ]����
        lt_sample_if_flag               :=  gt_inv_transactions_data( line_no ).sample_if_flag;  -- ���{�]���σt���O
        lt_sample_if_date               :=  gt_inv_transactions_data( line_no ).sample_if_date;  -- ���{�]����
        lt_output_flag                  :=  gt_inv_transactions_data( line_no ).output_flag;     -- �o�͍σt���O
--
        EXIT WHEN(lt_head_invoice_no <> lt_invoice_no);
--
        --�[�i���הԍ��̃J�E���g
        ln_invoice_line_num := ln_invoice_line_num + 1;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        ln_line_data_count := ln_line_data_count + 1;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--        -- ===================
--        -- �o�^�p����ID�擾
--        -- ===================
--        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
--        INTO   ln_sales_exp_line_id
--        FROM   DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
--
--
        -- ==================
        -- �[�i�`�ԋ敪�̓��o
        -- ==================
        xxcos_common_pkg.get_delivered_from( lt_outside_subinv_code,
                                             lt_base_code, 
                                             lt_base_code, 
                                             gv_orga_code,
                                             gn_orga_id, 
                                             lv_delivery_type,
                                             lv_errbuf, 
                                             lv_retcode, 
                                             lv_errmsg );
        IF ( lv_retcode <> cv_status_normal ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--          RAISE delivered_from_err_expt;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,
                                                iv_name          => cv_msg_delivered_from_err );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
        END IF;
--
-- ************** 2009/05/13 1.13 N.Maeda DEL START ****************************************************************
--      -- ===================
--      -- �[�i���_�̓��o
--      -- ===================
--      BEGIN
--        SELECT rin_v.base_code  --���_�R�[�h
--        INTO lt_dlv_base_code
--        FROM xxcos_rs_info_v rin_v   --�]�ƈ����view
--        WHERE rin_v.employee_number = lt_employee_num
--/*--==============2009/2/3-START=========================--*/
--        AND   NVL( rin_v.effective_start_date, lt_head_invoice_date ) <= lt_head_invoice_date
--        AND   NVL( rin_v.effective_end_date, lt_head_invoice_date ) >= lt_head_invoice_date;
--/*--==============2009/2/3-END=========================--*/
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--            -- ���O�o��
--            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_emp_data_mst );
--            --�L�[�ҏW�p�ϐ��ݒ�
----******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
----            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv );
----            lv_key_name2 := NULL;
----            lv_key_data1 := lt_employee_num;
----            lv_key_data2 := NULL;
----          RAISE no_data_extract;
--          lv_state_flg    := cv_status_warn;
--          gn_wae_data_num := gn_wae_data_num + 1 ;
--          xxcos_common_pkg.makeup_key_info(
--            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv ), -- ���ږ��̂P
--            iv_data_value1 => lt_employee_num,         -- �f�[�^�̒l�P
--            ov_key_info    => gv_tkn2,              -- �L�[���
--            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
--            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
--            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
--          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
--                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
--                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
--                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
--                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
--                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
--                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--      END;
-- ************** 2009/05/13 1.13 N.Maeda DEL  END ****************************************************************
--
        -- ====================================
        -- �c�ƌ����̓��o(�̔����і���(�R����))
        -- ====================================
        BEGIN
          SELECT ic_item.attribute7,               -- ���c�ƌ���
                 ic_item.attribute8,               -- �V�c�ƌ���
                 ic_item.attribute9,               -- �c�ƌ����K�p�J�n��
                 mtl_item.primary_unit_of_measure, -- ��P��
                 cmm_item.inc_num                  -- �������
          INTO   lt_old_sales_cost,
                 lt_new_sales_cost,
                 lt_st_sales_cost,
                 lt_stand_unit,
                 lt_inc_num
          FROM   mtl_system_items_b    mtl_item,    -- �i��
                 ic_item_mst_b         ic_item,     -- OPM�i��
                 xxcmm_system_items_b  cmm_item     -- Disc�i�ڃA�h�I��
          WHERE  mtl_item.organization_id   = gn_orga_id
          AND  mtl_item.segment1 = lt_item_code
          AND  mtl_item.segment1 = ic_item.item_no
          AND  mtl_item.segment1 = cmm_item.item_code
          AND  cmm_item.item_id  = ic_item.item_id
/*--==============2009/2/4-START=========================--*/
          AND    NVL( mtl_item.start_date_active, gd_process_date) <= gd_process_date
          AND    NVL( mtl_item.end_date_active, gd_max_date ) >= gd_process_date;
/*--==============2009/2/4-end==========================--*/
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          --�L�[�ҏW����
            -- ���O�o��
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_inv_item_mst );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
--            lv_key_data1 := lt_item_code;
--            lv_key_data2 := gn_orga_id;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code ), -- ���ږ��̂P
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id ), -- ���ږ��̂Q
            iv_data_value1 => lt_item_code,         -- �f�[�^�̒l�P
            iv_data_value2 => gn_orga_id,           -- �f�[�^�̒l�Q
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
        END;
--
        -- ===================================
        -- �c�ƌ�������
        -- ===================================
        IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_head_invoice_date ) THEN
          lt_sales_cost := lt_old_sales_cost;
        ELSE
          lt_sales_cost := lt_new_sales_cost;
        END IF;
--
--
        --
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        IF ( lv_state_flg <> cv_status_warn ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
          -- ========================
          -- �ԍ��t���O����
          -- ========================
          IF ( lt_total_quantity < 0 ) THEN
            lt_red_black_flag := cv_red_black_flag_correct;
            -- ����E����
            lt_cust_gyotai_sho := cn_correct_class;
--******************************* 2009/05/13 N.Maeda Var1.14 ADD START ***************************************
            lt_ins_invoice_type := lt_correct_class;
--******************************* 2009/05/13 N.Maeda Var1.14 ADD END *****************************************
          ELSE
--******************************* 2009/05/15 N.Maeda Var1.14 MOD START ***************************************
--            lt_red_black_flag := cn_red_black_flag_stand;
            lt_red_black_flag := cv_red_black_flag_stand;
--******************************* 2009/05/15 N.Maeda Var1.14 MOD END ***************************************
            -- ����
            lt_cust_gyotai_sho := cv_stand_class;
--******************************* 2009/05/13 N.Maeda Var1.14 ADD START ***************************************
            lt_ins_invoice_type := lt_normal_class;
--******************************* 2009/05/13 N.Maeda Var1.14 ADD END *****************************************
          END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--        -- =============================================
--        -- �̔����і��ׁi���o�Ɂj�ϐ��ւ̃Z�b�g
--        -- ============================================
--        gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;    -- �̔����і���ID
--        gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;            -- �̔����уw�b�_ID
--        gt_line_dlv_invoice_number( gn_line_data_no )      := lt_invoice_no;           -- �[�i�`�[�ԍ�
--        gt_line_dlv_invoice_l_num( gn_line_data_no )       := ln_invoice_line_num;     -- �[�i���הԍ�
--        gt_line_sales_class( gn_line_data_no )             := cv_sales_class;          -- ����敪
--        gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;       -- �ԍ��t���O
--        gt_line_item_code( gn_line_data_no )               := lt_item_code;            -- �i�ڃR�[�h
--        gt_line_standard_qty( gn_line_data_no )            := lt_total_quantity;       -- �����
--        gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;           -- ��P��
--        gt_line_standard_unit_price( gn_line_data_no )     := cv_standard_unit_price;  -- ��P��
--        gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero );-- �c�ƌ���
--        gt_line_sale_amount( gn_line_data_no )             := cv_sale_amount;          -- ������z
--        gt_line_pure_amount( gn_line_data_no )             := cv_pure_amount;          -- �{�̋��z
--        gt_line_tax_amount( gn_line_data_no )              := cv_tax_amount;           -- ����ŋ��z
--        gt_line_cash_and_card( gn_line_data_no )           := cv_cash_and_card;        -- �����E�J�[�h���p�z
--        gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_outside_subinv_code;  -- �o�׌��ۊǏꏊ
--        gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;        -- �[�i���_�R�[�h
--        gt_line_hot_cold_class( gn_line_data_no )          := cv_tkn_null;             -- �g���b
--        gt_line_column_no( gn_line_data_no )               := cv_tkn_null;             -- �R����No
--        gt_line_sold_out_class( gn_line_data_no )          := cv_tkn_null;             -- ���؋敪
--        gt_line_sold_out_time( gn_line_data_no )           := cv_tkn_null;             -- ���؎���
--        gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                -- �萔���v�Z-IF�σt���O
--        gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                -- �P���}�X�^�쐬�σt���O
--        gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                -- INV�C���^�t�F�[�X�σt���O
--        gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;             -- �������הԍ�(NULL�ݒ�)
--        gt_line_not_tax_amount( gn_line_data_no )          := cv_not_tax_amount;       -- �Ŕ���P��
--        gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;        -- �[�i�`�ԋ敪
--        gt_line_dlv_qty( gn_line_data_no )                 := lt_total_quantity;       -- �[�i����
--        gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;           -- �[�i�P��
--        gt_dlv_unit_price( gn_line_data_no )               := cv_standard_unit_price;  -- �[�i�P��
--        gn_line_data_no := gn_line_data_no + 1;
          -- ===================
          -- �ꎞ�i�[�p
          -- ===================
          gt_accumulation_data(ln_line_data_count).row_id                     := lt_row_id;               -- �sID
          gt_accumulation_data(ln_line_data_count).dlv_invoice_number         := lt_invoice_no;           -- �[�i�`�[�ԍ�
          gt_accumulation_data(ln_line_data_count).dlv_invoice_line_number    := ln_invoice_line_num;     -- �[�i���הԍ�
          gt_accumulation_data(ln_line_data_count).sales_class                := cv_sales_class;          -- ����敪
          gt_accumulation_data(ln_line_data_count).red_black_flag             := lt_red_black_flag;       -- �ԍ��t���O
          gt_accumulation_data(ln_line_data_count).item_code                  := lt_item_code;            -- �i�ڃR�[�h
          gt_accumulation_data(ln_line_data_count).dlv_qty                    := lt_total_quantity;       -- �[�i����
          gt_accumulation_data(ln_line_data_count).standard_qty               := lt_total_quantity;       -- �����
          gt_accumulation_data(ln_line_data_count).dlv_uom_code               := lt_stand_unit;           -- �[�i�P��
          gt_accumulation_data(ln_line_data_count).standard_uom_code          := lt_stand_unit;           -- ��P��
          gt_accumulation_data(ln_line_data_count).dlv_unit_price             := cv_standard_unit_price;  -- �[�i�P��
          gt_accumulation_data(ln_line_data_count).standard_unit_price        := cv_standard_unit_price;  -- ��P��
          gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- �c�ƌ���
          gt_accumulation_data(ln_line_data_count).sale_amount                := cv_sale_amount;          -- ������z
          gt_accumulation_data(ln_line_data_count).pure_amount                := cv_pure_amount;          -- �{�̋��z
          gt_accumulation_data(ln_line_data_count).tax_amount                 := cv_tax_amount;           -- ����ŋ��z
          gt_accumulation_data(ln_line_data_count).cash_and_card              := cv_cash_and_card;        -- �����E�J�[�h���p�z
          gt_accumulation_data(ln_line_data_count).ship_from_subinventory_code := lt_outside_subinv_code; -- �o�׌��ۊǏꏊ
          gt_accumulation_data(ln_line_data_count).delivery_base_code         := lt_dlv_base_code;        -- �[�i���_�R�[�h
          gt_accumulation_data(ln_line_data_count).hot_cold_class             := cv_tkn_null;             -- �g���b
          gt_accumulation_data(ln_line_data_count).column_no                  := cv_tkn_null;             -- �R����No
          gt_accumulation_data(ln_line_data_count).sold_out_class             := cv_tkn_null;             -- ���؋敪
          gt_accumulation_data(ln_line_data_count).sold_out_time              := cv_tkn_null;             -- ���؎���
          gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                -- �萔���v�Z�C���^�t�F�[�X�σt���O
          gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                -- �P���}�X�^�쐬�σt���O
          gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                -- INV�C���^�t�F�[�X�σt���O
          gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;             -- �������הԍ�(NULL�ݒ�)
          gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := cv_not_tax_amount;     -- �Ŕ���P��
          gt_accumulation_data(ln_line_data_count).delivery_pattern_class     := lv_delivery_type;        -- �[�i�`�ԋ敪(���o)
        END IF;
        ln_line_no := ln_line_no + 1;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
--
      END LOOP trans_loop;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      IF ( lv_state_flg <> cv_status_warn ) THEN
        --================================
        --�̔����уw�b�_ID(�V�[�P���X�擾)
        --================================
        SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
        INTO ln_actual_id
        FROM DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--
        -- =========================================
        -- �w�b�_���i�[����
        -- =========================================
        gt_head_id( gn_head_data_no )                      := ln_actual_id;               -- �̔����уw�b�_ID
        gt_head_order_no_ebs( gn_head_data_no )            := cv_tkn_null;                -- �󒍔ԍ�
        gt_head_hht_invoice_no( gn_head_data_no )          := lt_head_invoice_no;         -- �[�i�`�[�ԍ�
        gt_head_order_no_hht( gn_head_data_no )            := cv_tkn_null;                -- ��No(HHT)
        gt_head_digestion_ln_number( gn_head_data_no )     := cv_tkn_null;                -- �}��(��No(HHT)�}��)
        gt_head_dlv_invoice_class( gn_head_data_no )       := lt_ins_invoice_type;        -- �[�i�`�[�敪(���o)
        gt_head_cancel_cor_cls( gn_head_data_no )          := lt_cust_gyotai_sho;         -- ����E�����敪
        gt_head_system_class( gn_head_data_no )            := lt_head_inside_business_low_t;  -- �Ƒԋ敪(�Ƒԏ�����)
        gt_head_dlv_date( gn_head_data_no )                := lt_head_invoice_date;       -- �[�i��
        gt_head_inspect_date( gn_head_data_no )            := lt_head_invoice_date;       -- ������(����v���)
        gt_head_customer_number( gn_head_data_no )         := lt_head_inside_cust_code;   -- �ڋq�y�[�i��z
        gt_head_tax_include( gn_head_data_no )             := cn_tkn_zero;                -- ������z���v
        gt_head_total_amount( gn_head_data_no )            := cn_tkn_zero;                -- �{�̋��z���v
        gt_head_sales_consump_tax( gn_head_data_no )       := cn_tkn_zero;                -- ����ŋ��z���v(�����o)
        gt_head_consump_tax_class( gn_head_data_no )       := cv_tkn_null;                -- ����ŋ敪(���o)
        gt_head_tax_code( gn_head_data_no )                := lt_no_tax_code;             -- �ŋ��R�[�h(���o)
        gt_head_tax_rate( gn_head_data_no )                := cn_tkn_zero;                -- ����ŗ�(���o)
        gt_head_performance_by_code( gn_head_data_no )     := lt_head_employee_num;       -- ���ьv��҃R�[�h
        gt_head_sales_base_code( gn_head_data_no )         := lt_sale_base_code;          -- ���㋒�_�R�[�h(���o)
        gt_head_card_sale_class( gn_head_data_no )         := cv_tkn_null;                -- �J�[�h����敪
--      gt_head_sales_classification( gn_head_data_no )    := lt_head_invoice_type;       -- �`�[�敪
--      gt_head_invoice_class( gn_head_data_no )           := cv_tkn_null;                -- �`�[���ރR�[�h
        gt_head_sales_classification( gn_head_data_no )    := cv_tkn_null;                -- �`�[�敪
        gt_head_invoice_class( gn_head_data_no )           := lt_head_invoice_type;       -- �`�[���ރR�[�h
-- ************** 2009/05/13 1.13 N.Maeda MOD START ****************************************************************
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--      gt_head_receiv_base_code( gn_head_data_no )        := lt_sale_base_code;          -- �������_�R�[�h(���o)
--        gt_head_receiv_base_code( gn_head_data_no )        := lt_cash_receiv_base_code;   -- �������_�R�[�h(���o)
        gt_head_receiv_base_code( gn_head_data_no )        := cv_tkn_null;                -- �������_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
-- ************** 2009/05/13 1.13 N.Maeda MOD START ****************************************************************
        gt_head_change_out_time_100( gn_head_data_no )     := cv_tkn_null;                -- ��K�؂ꎞ��100�~
        gt_head_change_out_time_10( gn_head_data_no )      := cv_tkn_null;                -- ��K�؂ꎞ��10�~
        gt_head_hht_dlv_input_date( gn_head_data_no )      := lt_head_invoice_date;       -- HHT�[�i���͓���(���^����)
        gt_head_dlv_by_code( gn_head_data_no )             := lt_head_employee_num;       -- �[�i�҃R�[�h
        gt_head_business_date( gn_head_data_no )           := gd_process_date;            -- �o�^�Ɩ����t(���������擾)
        gt_head_order_source_id( gn_head_data_no )         := cv_tkn_null;                -- �󒍃\�[�XID(NULL�ݒ�)
        gt_head_order_invoice_number( gn_head_data_no )    := cv_tkn_null;                -- �����`�[�ԍ�(NULL�ݒ�)
        gt_head_order_connection_num( gn_head_data_no )    := cv_tkn_null;                -- �󒍊֘A�ԍ�(NULL�ݒ�)
        gt_head_ar_interface_flag( gn_head_data_no )       := cv_tkn_n;                   -- AR-IF�σt���O('N')
        gt_head_gl_interface_flag( gn_head_data_no )       := cv_tkn_n;                   -- GL-IF�σt���O('N')
        gt_head_dwh_interface_flag( gn_head_data_no )      := cv_tkn_n;                   -- ���V�X�e��-IF�σt���O('N')
        gt_head_edi_interface_flag( gn_head_data_no )      := cv_tkn_n;                   -- EDI���M�ς݃t���O('N'�ݒ�)
        gt_head_edi_send_date( gn_head_data_no )           := cv_tkn_null;                -- EDI���M����(NULL�ݒ�)
-- ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
--        gt_head_create_class( gn_head_data_no )            := cn_tkn_shipping_chk;        -- �쐬���敪(�4��ݒ�)
        gt_head_create_class( gn_head_data_no )            := cv_tkn_shipping_chk;        -- �쐬���敪(�4��ݒ�)
-- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
        gt_head_input_class( gn_head_data_no )             := cv_tkn_null;                -- ���͋敪
        gn_head_data_no := gn_head_data_no + 1;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
--
        <<line_set_loop>>
        FOR in_data_num IN 1..ln_line_data_count LOOP
--
          ln_tran_rowid_num := ln_tran_rowid_num + 1;
--
          -- ===================
          -- �o�^�p����ID�擾
          -- ===================
          SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
          INTO   ln_sales_exp_line_id
          FROM   DUAL;
--
          gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- �̔����і���ID
          gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- �̔����уw�b�_ID
          gt_line_dlv_invoice_number( gn_line_data_no )      := gt_accumulation_data(in_data_num).dlv_invoice_number;    -- �[�i�`�[�ԍ�
          gt_line_dlv_invoice_l_num( gn_line_data_no )       := gt_accumulation_data(in_data_num).dlv_invoice_line_number; -- �[�i���הԍ�
          gt_line_sales_class( gn_line_data_no )             := gt_accumulation_data(in_data_num).sales_class;           -- ����敪
          gt_line_red_black_flag( gn_line_data_no )          := gt_accumulation_data(in_data_num).red_black_flag;        -- �ԍ��t���O
          gt_line_item_code( gn_line_data_no )               := gt_accumulation_data(in_data_num).item_code;             -- �i�ڃR�[�h
          gt_line_standard_qty( gn_line_data_no )            := gt_accumulation_data(in_data_num).standard_qty;          -- �����
          gt_line_standard_uom_code( gn_line_data_no )       := gt_accumulation_data(in_data_num).standard_uom_code;     -- ��P��
          gt_line_standard_unit_price( gn_line_data_no )     := gt_accumulation_data(in_data_num).standard_unit_price;   -- ��P��
          gt_line_business_cost( gn_line_data_no )           := gt_accumulation_data(in_data_num).business_cost;         -- �c�ƌ���
          gt_line_sale_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).sale_amount;           -- ������z
          gt_line_pure_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).pure_amount;           -- �{�̋��z
          gt_line_tax_amount( gn_line_data_no )              := gt_accumulation_data(in_data_num).tax_amount;            -- ����ŋ��z
          gt_line_cash_and_card( gn_line_data_no )           := gt_accumulation_data(in_data_num).cash_and_card;         -- �����E�J�[�h���p�z
          gt_line_ship_from_subinv_co( gn_line_data_no )     := gt_accumulation_data(in_data_num).ship_from_subinventory_code; -- �o�׌��ۊǏꏊ
          gt_line_delivery_base_code( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_base_code;    -- �[�i���_�R�[�h
          gt_line_hot_cold_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).hot_cold_class;        -- �g���b
          gt_line_column_no( gn_line_data_no )               := gt_accumulation_data(in_data_num).column_no;             -- �R����No
          gt_line_sold_out_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).sold_out_class;        -- ���؋敪
          gt_line_sold_out_time( gn_line_data_no )           := gt_accumulation_data(in_data_num).sold_out_time;         -- ���؎���
          gt_line_to_calculate_fees_flag( gn_line_data_no )  := gt_accumulation_data(in_data_num).to_calculate_fees_flag;-- �萔���v�ZIF�σt���O
          gt_line_unit_price_mst_flag( gn_line_data_no )     := gt_accumulation_data(in_data_num).unit_price_mst_flag;   -- �P���}�X�^�쐬�σt���O
          gt_line_inv_interface_flag( gn_line_data_no )      := gt_accumulation_data(in_data_num).inv_interface_flag;    -- INV�C���^�t�F�[�X�σt���O
          gt_line_order_invoice_l_num( gn_line_data_no )     := gt_accumulation_data(in_data_num).order_invoice_line_number;   -- �������הԍ�
          gt_line_not_tax_amount( gn_line_data_no )          := gt_accumulation_data(in_data_num).standard_unit_price_excluded;-- �Ŕ���P��
          gt_line_delivery_pat_class( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_pattern_class;      -- �[�i�`�ԋ敪
          gt_line_dlv_qty( gn_line_data_no )                 := gt_accumulation_data(in_data_num).dlv_qty;                     -- �[�i����
          gt_line_dlv_uom_code( gn_line_data_no )            := gt_accumulation_data(in_data_num).dlv_uom_code;                -- �[�i�P��
          gt_dlv_unit_price( gn_line_data_no )               := gt_accumulation_data(in_data_num).dlv_unit_price;              -- �[�i�P��
          gn_line_data_no := gn_line_data_no + 1;
          --
          gt_dlv_tran_head_row_id(ln_tran_rowid_num)               := gt_accumulation_data(in_data_num).row_id;
        END LOOP line_set_loop;
      END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
    END LOOP trans_head_loop;
--
  EXCEPTION
    WHEN no_data_extract THEN
      --�L�[�ҏW�֐�
      xxcos_common_pkg.makeup_key_info(
                                       lv_key_name1, 
                                       lv_key_data1, 
                                       lv_key_name2, 
                                       lv_key_data2,
                                       cv_key_name_null, 
                                       cv_tkn_null, 
                                       cv_key_name_null, 
                                       cv_tkn_null,
                                       cv_key_name_null, 
                                       cv_tkn_null, 
                                       cv_key_name_null, 
                                       cv_tkn_null,
                                       cv_key_name_null, 
                                       cv_tkn_null, 
                                       cv_key_name_null, 
                                       cv_tkn_null,
                                       cv_key_name_null, 
                                       cv_tkn_null, 
                                       cv_key_name_null, 
                                       cv_tkn_null,
                                       cv_key_name_null, 
                                       cv_tkn_null, 
                                       cv_key_name_null, 
                                       cv_tkn_null,
                                       cv_key_name_null, 
                                       cv_tkn_null, 
                                       cv_key_name_null, 
                                       cv_tkn_null,
                                       cv_key_name_null, 
                                       cv_tkn_null, 
                                       cv_key_name_null, 
                                       cv_tkn_null,
                                       cv_key_name_null, 
                                       cv_tkn_null, 
                                       cv_key_name_null, 
                                       cv_tkn_null,
                                       cv_key_name_null, 
                                       cv_tkn_null, 
                                       cv_key_name_null, 
                                       cv_tkn_null,
                                       gv_tkn2, 
                                       lv_errbuf, 
                                       lv_retcode, 
                                       lv_errmsg);  
      --���b�Z�[�W����
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_no_data,
                                             cv_tkn_table_name, gv_tkn1,
                                             cv_key_data, gv_tkn2 );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� # 
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--    WHEN delivered_from_err_expt THEN
--      --
--      lv_errmsg := xxccp_common_pkg.get_msg( cv_application,cv_msg_delivered_from_err );
----      lv_errbuf := lv_errmsg;
--      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
--      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;                                            --# �C�� #
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
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
  END proc_molded_trans;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_molded_edi
   * Description      : �̔����уf�[�^�iEDI�j���^����(A-4)
   ***********************************************************************************/
  PROCEDURE proc_molded_edi(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_molded_edi'; -- �v���O������
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
    --�[�i�w�b�_�i�[�p�ϐ�
    lt_order_no_hht              xxcos_dlv_headers.order_no_hht%TYPE;             -- ��No.(HHT)
    lt_digestion_ln_number       xxcos_dlv_headers.digestion_ln_number%TYPE;      -- �}��
    lt_order_no_ebs              xxcos_dlv_headers.order_no_ebs%TYPE;             -- ��No.�iEBS�j
    lt_base_code                 xxcos_dlv_headers.base_code%TYPE;                -- ���_�R�[�h
    lt_performance_by_code       xxcos_dlv_headers.performance_by_code%TYPE;      -- ���ю҃R�[�h
    lt_dlv_by_code               xxcos_dlv_headers.dlv_by_code%TYPE;              -- �[�i�҃R�[�h
    lt_hht_invoice_no            xxcos_dlv_headers.hht_invoice_no%TYPE;           -- HHT�`�[No.
    lt_dlv_date                  xxcos_dlv_headers.dlv_date%TYPE;                 -- �[�i��
    lt_inspect_date              xxcos_dlv_headers.inspect_date%TYPE;             -- ������
    lt_sales_classification      xxcos_dlv_headers.sales_classification%TYPE;     -- ���㕪�ދ敪
    lt_sales_invoice             xxcos_dlv_headers.sales_invoice%TYPE;            -- ����`�[�敪
    lt_card_sale_class           xxcos_dlv_headers.card_sale_class%TYPE;          -- �J�[�h����敪
    lt_dlv_time                  xxcos_dlv_headers.dlv_time%TYPE;                 -- ����
    lt_customer_number           xxcos_dlv_headers.customer_number%TYPE;          -- �ڋq�R�[�h
    lt_change_out_time_100       xxcos_dlv_headers.change_out_time_100%TYPE;      -- ��K�؂ꎞ��100�~
    lt_change_out_time_10        xxcos_dlv_headers.change_out_time_10%TYPE;       -- ��K�؂ꎞ��10�~
    lt_system_class              xxcos_dlv_headers.system_class%TYPE;             -- �Ƒԋ敪
    lt_input_class               xxcos_dlv_headers.input_class%TYPE;              -- ���͋敪
    lt_consumption_tax_class     xxcos_dlv_headers.consumption_tax_class%TYPE;    -- ����ŋ敪
    lt_total_amount              xxcos_dlv_headers.total_amount%TYPE;             -- ���v���z
    lt_sale_discount_amount      xxcos_dlv_headers.sale_discount_amount%TYPE;     -- ����l���z
    lt_sales_consumption_tax     xxcos_dlv_headers.sales_consumption_tax%TYPE;    -- �������Ŋz
    lt_tax_include               xxcos_dlv_headers.tax_include%TYPE;              -- �ō����z
    lt_keep_in_code              xxcos_dlv_headers.keep_in_code%TYPE;             -- �a����R�[�h
    lt_department_screen_class   xxcos_dlv_headers.department_screen_class%TYPE;  -- �S�ݓX��ʎ��
    lt_stock_forward_flag        xxcos_dlv_headers.stock_forward_flag%TYPE;       -- ���o�ɓ]���t���O
    lt_stock_forward_date        xxcos_dlv_headers.stock_forward_date%TYPE;       -- ���o�ɓ]���ϓ��t
    lt_results_forward_flag      xxcos_dlv_headers.results_forward_flag%TYPE;     -- �̔����јA�g�σt���O
    lt_results_forward_date      xxcos_dlv_headers.results_forward_date%TYPE;     -- �̔����јA�g�ϓ��t
    lt_cancel_correct_class      xxcos_dlv_headers.cancel_correct_class%TYPE;     -- ����E�����敪
    lt_red_black_flag            xxcos_dlv_headers.red_black_flag%TYPE;           -- �ԍ��t���O
    --�[�i���׊i�[�p�ϐ�
    lt_lin_order_no_hht          xxcos_dlv_lines.order_no_hht%TYPE;               -- ��No.�iHHT�j
    lt_lin_line_no_hht           xxcos_dlv_lines.line_no_hht%TYPE;                -- �sNo.�iHHT�j
    lt_lin_digestion_ln_number   xxcos_dlv_lines.digestion_ln_number%TYPE;        -- �}��
    lt_lin_order_no_ebs          xxcos_dlv_lines.order_no_ebs%TYPE;               -- ��No.�iEBS�j
    lt_lin_line_number_ebs       xxcos_dlv_lines.line_number_ebs%TYPE;            -- ���הԍ��iEBS�j
    lt_lin_item_code_self        xxcos_dlv_lines.item_code_self%TYPE;             -- �i���R�[�h�i���Ёj
    lt_lin_content               xxcos_dlv_lines.content%TYPE;                    -- ����
    lt_lin_inventory_item_id     xxcos_dlv_lines.inventory_item_id%TYPE;          -- �i��ID
    lt_lin_standard_unit         xxcos_dlv_lines.standard_unit%TYPE;              -- ��P��
    lt_lin_case_number           xxcos_dlv_lines.case_number%TYPE;                -- �P�[�X��
    lt_lin_quantity              xxcos_dlv_lines.quantity%TYPE;                   -- ����
    lt_lin_sale_class            xxcos_dlv_lines.sale_class%TYPE;                 -- ����敪
    lt_lin_wholesale_unit_ploce  xxcos_dlv_lines.wholesale_unit_ploce%TYPE;       -- ���P��
    lt_lin_selling_price         xxcos_dlv_lines.selling_price%TYPE;              -- ���P��
    lt_lin_column_no             xxcos_dlv_lines.column_no%TYPE;                  -- �R����No.
    lt_lin_h_and_c               xxcos_dlv_lines.h_and_c%TYPE;                    -- H/C
    lt_lin_sold_out_class        xxcos_dlv_lines.sold_out_class%TYPE;             -- ���؋敪
    lt_lin_sold_out_time         xxcos_dlv_lines.sold_out_time%TYPE;              -- ���؎���
    lt_lin_replenish_number      xxcos_dlv_lines.replenish_number%TYPE;           -- ��[��
    lt_lin_cash_and_card         xxcos_dlv_lines.cash_and_card%TYPE;              -- �����E�J�[�h���p�z
    --OM�󒍏��i�[�p
    lt_om_order_number           oe_order_headers_all.order_number%TYPE;          -- �󒍔ԍ�
    lt_om_header_id              oe_order_headers_all.header_id%TYPE;             -- �󒍃w�b�_ID
    lt_om_he_flow_status_code       oe_order_headers_all.flow_status_code%TYPE;      -- �X�e�[�^�X
    lt_om_order_source_id        oe_order_headers_all.order_source_id%TYPE;       -- �󒍃\�[�XID
    lt_om_cust_po_number         oe_order_headers_all.cust_po_number%TYPE;        -- �ڋq����
    lt_om_line_id                oe_order_lines_all.line_id%TYPE;                 -- �󒍖���ID
    lt_om_li_flow_status_code       oe_order_lines_all.flow_status_code%TYPE;        -- �X�e�[�^�X
    -- ���̑�
    lt_dlv_base_code             xxcos_rs_info_v.base_code%TYPE;                  -- ���_�R�[�h
    lt_old_sales_cost            ic_item_mst_b.attribute7%TYPE;                   -- ���c�ƌ���
    lt_new_sales_cost            ic_item_mst_b.attribute8%TYPE;                   -- �V�c�ƌ���
    lt_st_sales_cost             ic_item_mst_b.attribute9%TYPE;                   -- �c�ƌ����K�p�J�n��
    lt_tax_odd                   hz_cust_accounts.tax_rounding_rule%TYPE;         -- �ŋ�-�[������
    lt_consum_code               fnd_lookup_values.attribute2%TYPE;               -- ����ŃR�[�h
    lt_consum_type               fnd_lookup_values.attribute3%TYPE;               -- �̔����јA�g���̏���ŋ敪
    lt_tax_consum                ar_vat_tax_all_b.tax_rate%TYPE;                  -- ����ŗ�
    lt_stand_unit                mtl_system_items_b.primary_unit_of_measure%TYPE; -- ��P��
--    lt_lin_not_tax_amount        xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE; -- �Ŕ���P��
    lt_location_type_code        fnd_lookup_values.meaning%TYPE;                  -- �ۊǏꏊ�敪(�c�Ǝ�)
    lt_depart_location_type_code fnd_lookup_values.meaning%TYPE;                  -- �ۊǏꏊ�敪(�S�ݓX)
    lt_secondary_inventory_name  mtl_secondary_inventories.secondary_inventory_name%TYPE; -- �ۊǏꏊ�R�[�h
    lt_ins_invoice_type          fnd_lookup_values.attribute4%TYPE;               -- �[�i�`�[�敪
    lv_depart_code               xxcmm_cust_accounts.dept_hht_div%TYPE;           -- HHT�S�ݓX���͋敪
    lt_inc_num                   xxcmm_system_items_b.inc_num%TYPE;               -- �������
    lt_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;         -- ���㋒�_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
    lt_cash_receiv_base_code          xxcos_cust_hierarchy_v.cash_receiv_base_code%TYPE;         -- �������_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
    lt_sales_cost                ic_item_mst_b.attribute7%TYPE;                   -- �c�ƌ���
    lt_sale_amount_sum           xxcos_sales_exp_headers.sale_amount_sum%TYPE;    -- ������z���v
    lt_pure_amount_sum           xxcos_sales_exp_headers.pure_amount_sum%TYPE;    -- �{�̋��z���v
    lt_tax_amount_sum            xxcos_sales_exp_headers.tax_amount_sum%TYPE;     -- ����ŋ��z���v
    lt_stand_unit_price_excl     xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE;--�Ŕ���P��
    lt_standard_unit_price       xxcos_sales_exp_lines.standard_unit_price%TYPE;  -- ��P��
    lt_sale_amount               xxcos_sales_exp_lines.sale_amount%TYPE;          -- ������z
    lt_pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE;          -- �{�̋��z
    lt_tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE;           -- ����ŋ��z
    --
    lt_set_replenish_number      xxcos_sales_exp_lines.standard_qty%TYPE;         -- �o�^�p�����(�[�i����)
    lt_set_sale_amount           xxcos_sales_exp_lines.sale_amount%TYPE;          -- �o�^�p������z
    lt_set_pure_amount           xxcos_sales_exp_lines.pure_amount%TYPE;          -- �o�^�p�{�̋��z
    lt_set_tax_amount            xxcos_sales_exp_lines.tax_amount%TYPE;           -- �o�^�p����ŋ��z
    lt_set_sale_amount_sum       xxcos_sales_exp_headers.sale_amount_sum%TYPE;    -- �o�^�p������z���v
    lt_set_pure_amount_sum       xxcos_sales_exp_headers.pure_amount_sum%TYPE;    -- �o�^�p�{�̋��z���v
    lt_set_tax_amount_sum        xxcos_sales_exp_headers.tax_amount_sum%TYPE;     -- �o�^�p����ŋ��z���v
    ln_tax_data                  NUMBER;                                          -- �ō��z�Z�o�p
    ln_line_no                   NUMBER :=  1;                                    -- ���׃`�F�b�N�ϔԍ�
    ln_cnt_om_order              NUMBER :=  1;                                    -- OM�󒍏��i�[��
    ln_all_tax_amount            NUMBER :=  0;                                    -- ����ŋ��z���v�l
    ln_max_tax_data              NUMBER :=  0;                                    -- ���׍ő����Ŋz
    ln_max_invoice_num           NUMBER;                                          -- �l�����חp�[�i���הԍ�
    ln_actual_id                 NUMBER;                                          -- �̔����уw�b�_ID
--    ln_sales_amount              NUMBER;                                          -- ������z
--    ln_consum_amount             NUMBER;                                          -- ����ŋ��z
--    ln_tax_odd                   NUMBER;                                          -- ����Œ[��
--    ln_up_odd                    NUMBER;                                          -- �[���؂�グ���l
--    ]ln_amount_data               NUMBER;                                          -- �{�̋��z
--    lt_lin_sale_amount           NUMBER;                                          -- ������z
    ln_sales_exp_line_id         NUMBER;                                          -- ����ID
    ln_discount_tax              NUMBER;                                          -- �l������Ŋz
    ln_max_no_data               NUMBER;                                          -- �w�b�_�ő����Ŗ��׍s�ԍ�
    ld_input_date                DATE;                                            -- HHT�[�i���͓���
    lv_delivery_type             VARCHAR2(100);                                   -- �[�i�`�ԋ敪
    lv_edi_order_name            VARCHAR2(100);                                   -- EDI��
    lv_key_name1                 VARCHAR2(500);                                   -- �L�[�f�[�^����1
    lv_key_name2                 VARCHAR2(500);                                   -- �L�[�f�[�^����2
    lv_key_data1                 VARCHAR2(500);                                   -- �L�[�f�[�^1
    lv_key_data2                 VARCHAR2(500);                                   -- �L�[�f�[�^2
--************************** 2009/03/18 1.5 T.kitajima ADD START ************************************
    ln_amount                    NUMBER;                                          -- ��Ɨp���z�ϐ�
--************************** 2009/03/18 1.5 T.kitajima ADD  END  ************************************
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
    lt_row_id                    ROWID;                                           -- �X�V�p�sID
    lv_state_flg                 VARCHAR2(1);                                     -- �f�[�^�x���m�F�t���O
    ln_line_data_count           NUMBER;                                          -- ���׌���(�w�b�_�P��)
    lv_dept_hht_div_flg          VARCHAR2(1);                                     -- HHT�S�ݓX�敪�G���[�t���O
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
   --****** ���[�U�[��`���[�J���J�[�\�� ********--
    -- OM�󒍃f�[�^�擾�J�[�\��
    CURSOR get_oe_order_cur
    IS
      SELECT ooh.order_number      order_number,            -- �󒍔ԍ�
             ooh.header_id         header_id,               -- �󒍃w�b�_ID
             ooh.flow_status_code  head_flow_status_code,   -- �X�e�[�^�X
             ooh.order_source_id   order_source_id,         -- �󒍃\�[�XID
             ooh.cust_po_number    cust_po_number,          -- �ڋq����
             ool.line_id           line_id,                 -- �󒍖���ID
             ool.flow_status_code  line_flow_status_code    -- �X�e�[�^�X
      FROM   oe_order_headers_all ooh,                      -- OM�󒍃w�b�_
             oe_order_lines_all ool,                        -- OM�󒍖��׃e�[�u��
             oe_order_sources oos                           -- �I�[�_�[�\�[�X
      WHERE  ooh.header_id = ool.header_id
      AND    ooh.order_source_id = oos.order_source_id
      AND    ool.order_source_id = oos.order_source_id
      AND    ooh.org_id = TO_NUMBER ( gv_salse_unit )
      AND    ooh.order_number = lt_order_no_ebs
      AND    ool.flow_status_code NOT IN ( cv_status_type_can , cv_status_type_clo )
      AND    oos.name = lv_edi_order_name
      ORDER BY ooh.order_number,ool.line_id;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- EDI�󒍖��̎擾
    lv_edi_order_name := xxccp_common_pkg.get_msg( cv_application, cv_order_s_name );
    -- ���[�v�J�n�F�w�b�_��
    <<header_loop>>
    FOR ck_no IN 1..gn_target_edi_cnt LOOP
--
      --���הԍ��̏�����
--      ln_sales_exp_line_id            := 0;
      --�Ϗ����ł̏�����
      ln_all_tax_amount               := 0;
      --�ő����Ŋz�̏�����
      ln_max_tax_data                 := 0;
      -- �ő喾�הԍ�
      ln_max_no_data                  := 0;
      -- �ő�sNo
      ln_max_invoice_num              := 0;
      --�Ϗ�c�ƌ������v
--      ln_all_sales_cost               := 0;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      -- ���׌����J�E���g(������)
      ln_line_data_count              := 0;
      -- �f�[�^�x���m�F�t���O(������)
      lv_state_flg                    := cv_status_normal;
      -- HHT�S�ݓX�敪�G���[(������)
      lv_dept_hht_div_flg             := cv_status_normal;
--
      lt_row_id                    := gt_dlv_edi_headers_data( ck_no ).row_id;                   -- �sID
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
      lt_order_no_hht              := gt_dlv_edi_headers_data( ck_no ).order_no_hht;             -- ��No.(HHT)
      lt_digestion_ln_number       := gt_dlv_edi_headers_data( ck_no ).digestion_ln_number;      -- �}��
      lt_order_no_ebs              := gt_dlv_edi_headers_data( ck_no ).order_no_ebs;             -- ��No.�iEBS�j
      lt_base_code                 := gt_dlv_edi_headers_data( ck_no ).base_code;                -- ���_�R�[�h
      lt_performance_by_code       := gt_dlv_edi_headers_data( ck_no ).performance_by_code;      -- ���ю҃R�[�h
      lt_dlv_by_code               := gt_dlv_edi_headers_data( ck_no ).dlv_by_code;              -- �[�i�҃R�[�h
      lt_hht_invoice_no            := gt_dlv_edi_headers_data( ck_no ).hht_invoice_no;           -- HHT�`�[No.
      lt_dlv_date                  := gt_dlv_edi_headers_data( ck_no ).dlv_date;                 -- �[�i��
      lt_inspect_date              := gt_dlv_edi_headers_data( ck_no ).inspect_date;             -- ������
      lt_sales_classification      := gt_dlv_edi_headers_data( ck_no ).sales_classification;     -- ���㕪�ދ敪
      lt_sales_invoice             := gt_dlv_edi_headers_data( ck_no ).sales_invoice;            -- ����`�[�敪
      lt_card_sale_class           := gt_dlv_edi_headers_data( ck_no ).card_sale_class;          -- �J�[�h����敪
      lt_dlv_time                  := gt_dlv_edi_headers_data( ck_no ).dlv_time;                 -- ����
      lt_customer_number           := gt_dlv_edi_headers_data( ck_no ).customer_number;          -- �ڋq�R�[�h
      lt_change_out_time_100       := gt_dlv_edi_headers_data( ck_no ).change_out_time_100;      -- ��K�؂ꎞ��100�~
      lt_change_out_time_10        := gt_dlv_edi_headers_data( ck_no ).change_out_time_10;       -- ��K�؂ꎞ��10�~
      lt_system_class              := gt_dlv_edi_headers_data( ck_no ).system_class;             -- �Ƒԋ敪
      lt_input_class               := gt_dlv_edi_headers_data( ck_no ).input_class;              -- ���͋敪
      lt_consumption_tax_class     := gt_dlv_edi_headers_data( ck_no ).consumption_tax_class;    -- ����ŋ敪
      lt_total_amount              := gt_dlv_edi_headers_data( ck_no ).total_amount;             -- ���v���z
      lt_sale_discount_amount      := gt_dlv_edi_headers_data( ck_no ).sale_discount_amount;     -- ����l���z
      lt_sales_consumption_tax     := gt_dlv_edi_headers_data( ck_no ).sales_consumption_tax;    -- �������Ŋz
      lt_tax_include               := gt_dlv_edi_headers_data( ck_no ).tax_include;              -- �ō����z
      lt_keep_in_code              := gt_dlv_edi_headers_data( ck_no ).keep_in_code;             -- �a����R�[�h
      lt_department_screen_class   := gt_dlv_edi_headers_data( ck_no ).department_screen_class;  -- �S�ݓX��ʎ��
      lt_red_black_flag            := gt_dlv_edi_headers_data( ck_no ).red_black_flag;           -- �ԍ��t���O
      lt_stock_forward_flag        := gt_dlv_edi_headers_data( ck_no ).stock_forward_flag;       -- ���o�ɓ]���t���O
      lt_stock_forward_date        := gt_dlv_edi_headers_data( ck_no ).stock_forward_date;       -- ���o�ɓ]���ϓ��t
      lt_results_forward_flag      := gt_dlv_edi_headers_data( ck_no ).results_forward_flag;     -- �̔����јA�g�σt���O
      lt_results_forward_date      := gt_dlv_edi_headers_data( ck_no ).results_forward_date;     -- �̔����јA�g�ϓ��t
      lt_cancel_correct_class      := gt_dlv_edi_headers_data( ck_no ).cancel_correct_class;     -- ����E�����敪
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--      --================================
--      --�̔����уw�b�_ID(�V�[�P���X�擾)
--      --================================
--      SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
--      INTO ln_actual_id
--      FROM DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   *****************************************
--
      --=========================
      --�ڋq�}�X�^�t�я��̓��o
      --=========================
      BEGIN
        SELECT  xca.sale_base_code, --���㋒�_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
                xch.cash_receiv_base_code,  --�������_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
                --hca.tax_rounding_rule --�ŋ�-�[������
                xch.bill_tax_round_rule -- �ŋ�-�[������(�T�C�g)
        INTO    lt_sale_base_code,
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
                lt_cash_receiv_base_code,
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
                lt_tax_odd
        FROM    hz_cust_accounts hca,  --�ڋq�}�X�^
                xxcmm_cust_accounts xca, --�ڋq�ǉ����
                xxcos_cust_hierarchy_v xch -- �ڋq�K�w�r���[
        WHERE   hca.cust_account_id = xca.customer_id
        AND     xch.ship_account_id = hca.cust_account_id
        AND     xch.ship_account_id = xca.customer_id
        AND     hca.account_number = TO_CHAR( lt_customer_number )
        AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
        AND     hca.party_id IN ( SELECT  hpt.party_id
                                  FROM    hz_parties hpt
                                  WHERE   hpt.duns_number_c   IN ( cv_cust_s , cv_cust_v , cv_cost_p ) );
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
          --�L�[�ҏW����
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
--          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code );
--          lv_key_data1 := cv_customer_type_c||cv_con_char||cv_customer_type_u;
--          lv_key_data2 := lt_customer_number;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type ), -- ���ږ��̂P
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code ), -- ���ږ��̂Q
            iv_data_value1 => ( cv_customer_type_c||cv_con_char||cv_customer_type_u ),         -- �f�[�^�̒l�P
            iv_data_value2 => lt_customer_number,       -- �f�[�^�̒l�Q
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
      END;
--
      --========================
      --����ŃR�[�h�̓��o(HHT)
      --========================
      BEGIN
        SELECT  look_val.attribute2,  --����ŃR�[�h
                look_val.attribute3   --�̔����јA�g���̏���ŋ敪
        INTO    lt_consum_code,
                lt_consum_type
        FROM    fnd_lookup_values     look_val,
                fnd_lookup_types_tl   types_tl,
                fnd_lookup_types      types,
                fnd_application_tl    appl,
                fnd_application       app
        WHERE   appl.application_id   = types.application_id
        AND     app.application_id    = appl.application_id
        AND     types_tl.lookup_type  = look_val.lookup_type
        AND     types.lookup_type     = types_tl.lookup_type
        AND     types.security_group_id   = types_tl.security_group_id
        AND     types.view_application_id = types_tl.view_application_id
        AND     types_tl.language = USERENV( 'LANG' )
        AND     look_val.language = USERENV( 'LANG' )
        AND     appl.language     = USERENV( 'LANG' )
        AND     app.application_short_name = cv_application
        AND     gd_process_date      >= look_val.start_date_active
        AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
        AND     look_val.enabled_flag = cv_tkn_yes
        AND     look_val.lookup_type = cv_lookup_type
        AND     look_val.lookup_code = lt_consumption_tax_class;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��
          gv_tkn1   := xxccp_common_pkg.get_msg(cv_application, cv_msg_lookup_mst );
          --�L�[�ҏW����
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code );
--          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type );
--          lv_key_data1 := lt_consumption_tax_class;
--          lv_key_data2 := cv_lookup_type;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code ), -- ���ږ��̂P
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type ), -- ���ږ��̂Q
            iv_data_value1 => lt_consumption_tax_class,         -- �f�[�^�̒l�P
            iv_data_value2 => cv_lookup_type,       -- �f�[�^�̒l�Q
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
      END;
--
      --====================
      --����Ń}�X�^���擾
      --====================
      BEGIN
        SELECT avtab.tax_rate           -- ����ŗ�
        INTO   lt_tax_consum 
        FROM   ar_vat_tax_all_b avtab   -- AR����Ń}�X�^
        WHERE  avtab.tax_code = lt_consum_code
        AND    avtab.set_of_books_id = TO_NUMBER( gv_bks_id )
/*--==============2009/2/4-START=========================--*/
        AND    NVL( avtab.start_date, gd_process_date )  <= gd_process_date
        AND    NVL( avtab.end_date, gd_max_date ) >= gd_process_date
/*--==============2009/2/4-end==========================--*/
/*--==============2009/2/17-START=========================--*/
        AND    avtab.enabled_flag = cv_tkn_yes;
/*--==============2009/2/17--END==========================--*/
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��          
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_ar_tax_mst );
          --�L�[�ҏW����
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax );
--          lv_key_name2 := NULL;
--          lv_key_data1 := lt_consum_code;
--          lv_key_data2 := NULL;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax ), -- ���ږ��̂P
            iv_data_value1 => lt_consum_code,         -- �f�[�^�̒l�P
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
      END;
--
      -- ����ŗ��Z�o
      ln_tax_data := ( (100 + lt_tax_consum) / 100 );
--
      -- =========================
      -- HHT�[�i���͓����̐��^����
      -- =========================
      ld_input_date :=TO_DATE(TO_CHAR( lt_dlv_date, cv_short_day )||cv_space_char||
                              SUBSTR(lt_dlv_time,1,2)||cv_tkn_ti||SUBSTR(lt_dlv_time,3,2), cv_stand_date );
--
      -- ==================================
      -- �o�׌��ۊǏꏊ�̓��o
      -- ==================================
--
      --�o�׌��ۊǏꏊ�̓��o
      BEGIN
        SELECT xca.dept_hht_div   -- HHT�S�ݓX���͋敪
        INTO   lv_depart_code
        FROM   hz_cust_accounts hca,  -- �ڋq�}�X�^
               xxcmm_cust_accounts xca  -- �ڋq�ǉ����
        WHERE  hca.cust_account_id = xca.customer_id
        AND    hca.account_number = lt_base_code
        AND    hca.customer_class_code = cv_bace_branch;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
          --�L�[�ҏW����
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
--          lv_key_data1 := lt_base_code;
--          lv_key_data2 := cv_bace_branch;
--        RAISE no_data_extract;
          lv_dept_hht_div_flg := cv_status_warn;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- ���ږ��̂P
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type ), -- ���ږ��̂Q
            iv_data_value1 => lt_base_code,         -- �f�[�^�̒l�P
            iv_data_value2 => cv_bace_branch,       -- �f�[�^�̒l�Q
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
      END;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      IF (lv_dept_hht_div_flg <> cv_status_warn) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
/*--==============2009/2/3-START=========================--*/
--      IF ( lv_depart_code = cv_depart_car ) THEN
        IF ( lv_depart_code IS NULL )
          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_base ) ) THEN
/*--==============2009/2/3-end==========================--*/
          --�Q�ƃR�[�h�}�X�^�F�c�ƎԂ̕ۊǏꏊ���ރR�[�h�擾
          BEGIN
            SELECT  look_val.meaning      --�ۊǏꏊ���ރR�[�h
            INTO    lt_location_type_code
            FROM    fnd_lookup_values     look_val,
                    fnd_lookup_types_tl   types_tl,
                    fnd_lookup_types      types,
                    fnd_application_tl    appl,
                    fnd_application       app
            WHERE   appl.application_id   = types.application_id
            AND     app.application_id    = appl.application_id
            AND     types_tl.lookup_type  = look_val.lookup_type
            AND     types.lookup_type     = types_tl.lookup_type
            AND     types.security_group_id   = types_tl.security_group_id
            AND     types.view_application_id = types_tl.view_application_id
            AND     types_tl.language = USERENV( 'LANG' )
            AND     look_val.language = USERENV( 'LANG' )
            AND     appl.language     = USERENV( 'LANG' )
            AND     gd_process_date      >= look_val.start_date_active
            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
            AND     app.application_short_name = cv_application
            AND     look_val.enabled_flag = cv_tkn_yes
            AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
            AND     look_val.lookup_code = cv_xxcos_001_a05_05;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
              --�L�[�ҏW�����p�ϐ�
              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_type );
              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_code );
              lv_key_data1 := cv_xxcos1_hokan_mst_001_a05;
              lv_key_data2 := cv_xxcos_001_a05_05;
              RAISE no_data_extract;
          END;
--
          --�ۊǏꏊ�}�X�^�f�[�^�擾
          BEGIN
            SELECT msi.secondary_inventory_name     -- �ۊǏꏊ�R�[�h
            INTO   lt_secondary_inventory_name
            FROM   mtl_secondary_inventories msi    --�ۊǏꏊ�}�X�^
            WHERE  msi.attribute7 = lt_base_code
            AND    msi.attribute13 = lt_location_type_code
            AND    msi.attribute3 = lt_dlv_by_code;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
              --�L�[�ҏW�����p�ϐ�
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--            lv_key_data1 := lt_base_code;
--            lv_key_data2 := cv_xxcos_001_a05_05;
--            RAISE no_data_extract;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- ���ږ��̂P
                iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- ���ږ��̂Q
                iv_data_value1 => lt_base_code,         -- �f�[�^�̒l�P
                iv_data_value2 => cv_xxcos_001_a05_05,       -- �f�[�^�̒l�Q
                ov_key_info    => gv_tkn2,              -- �L�[���
                ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
                ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
                ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                    iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                    iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                    iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                    iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                    iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
          END;
--
/*--==============2009/2/3-START=========================--*/
--      ELSIF ( lv_depart_code = cv_depart_type ) THEN
--      ELSIF ( lv_depart_code IS NOT NULL ) THEN
        ELSIF ( lv_depart_code = cv_depart_type ) 
          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_dep ) )THEN
/*--==============2009/2/3-END==========================--*/
          --�Q�ƃR�[�h�}�X�^�F�S�ݓX�̕ۊǏꏊ���ރR�[�h�擾
          BEGIN
            SELECT  look_val.meaning    --�ۊǏꏊ���ރR�[�h
            INTO    lt_depart_location_type_code
            FROM    fnd_lookup_values     look_val,
                    fnd_lookup_types_tl   types_tl,
                    fnd_lookup_types      types,
                    fnd_application_tl    appl,
                    fnd_application       app
            WHERE   appl.application_id   = types.application_id
            AND     app.application_id    = appl.application_id
            AND     types_tl.lookup_type  = look_val.lookup_type
            AND     types.lookup_type     = types_tl.lookup_type
            AND     types.security_group_id   = types_tl.security_group_id
            AND     types.view_application_id = types_tl.view_application_id
            AND     types_tl.language = USERENV( 'LANG' )
            AND     look_val.language = USERENV( 'LANG' )
            AND     appl.language     = USERENV( 'LANG' )
            AND     gd_process_date      >= look_val.start_date_active
            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
            AND     app.application_short_name = cv_application
            AND     look_val.enabled_flag = cv_tkn_yes
            AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
            AND     look_val.lookup_code = cv_xxcos_001_a05_09;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
          --�L�[�ҏW����
              -- ���O�o��          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
              --�L�[�ҏW�����p�ϐ��ݒ�
              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_type );
              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_code );
              lv_key_data1 := cv_xxcos1_hokan_mst_001_a05;
              lv_key_data2 := cv_xxcos_001_a05_09;
            RAISE no_data_extract;
          END;
--
          --�ۊǏꏊ�}�X�^�f�[�^�擾
          BEGIN
            SELECT msi.secondary_inventory_name           -- �ۊǏꏊ����
            INTO   lt_secondary_inventory_name
            FROM   mtl_secondary_inventories msi,         -- �ۊǏꏊ�}�X�^
                   mtl_parameters mp                      -- �g�D�p�����[�^
            WHERE  msi.organization_id=mp.organization_id
            AND    mp.organization_code = gv_orga_code
            AND    msi.attribute4       = lt_keep_in_code
            AND    msi.attribute13      = lt_depart_location_type_code;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
              --�L�[�ҏW�����p�ϐ��ݒ�
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--            lv_key_data1 := lt_base_code;
--            lv_key_data2 := cv_xxcos_001_a05_09;
--            RAISE no_data_extract;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- ���ږ��̂P
                iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- ���ږ��̂Q
                iv_data_value1 => lt_base_code,         -- �f�[�^�̒l�P
                iv_data_value2 => cv_xxcos_001_a05_09,       -- �f�[�^�̒l�Q
                ov_key_info    => gv_tkn2,              -- �L�[���
                ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
                ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
                ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                    iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                    iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                    iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                    iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                    iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
          END;
--
        END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--
      -- ==================
      -- �[�i�`�ԋ敪�̓��o
      -- ==================
      xxcos_common_pkg.get_delivered_from( lt_secondary_inventory_name,
                                           lt_base_code, 
                                           lt_base_code, 
                                           gv_orga_code,
                                           gn_orga_id, 
                                           lv_delivery_type,
                                           lv_errbuf, 
                                           lv_retcode, 
                                           lv_errmsg );
      IF ( lv_retcode <> cv_status_normal ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--        RAISE delivered_from_err_expt;
      lv_state_flg    := cv_status_warn;
      gn_wae_data_num := gn_wae_data_num + 1 ;
      gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,
                                                iv_name          => cv_msg_delivered_from_err );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
      END IF;
--
      -- ===================
      -- �[�i���_�̓��o
      -- ===================
      BEGIN
        SELECT rin_v.base_code  --���_�R�[�h
        INTO lt_dlv_base_code
        FROM xxcos_rs_info_v rin_v   --�]�ƈ����view
        WHERE rin_v.employee_number = lt_dlv_by_code
/*--==============2009/2/3-START=========================--*/
        AND   NVL( rin_v.effective_start_date, lt_dlv_date ) <= lt_dlv_date
        AND   NVL( rin_v.effective_end_date, lt_dlv_date ) >= lt_dlv_date;
/*--==============2009/2/3-END=========================--*/
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_emp_data_mst );
          --�L�[�ҏW�p�ϐ��ݒ�
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv );
--            lv_key_name2 := NULL;
--            lv_key_data1 := lt_dlv_by_code;
--            lv_key_data2 := NULL;
--        RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv ), -- ���ږ��̂P
            iv_data_value1 => lt_dlv_by_code,         -- �f�[�^�̒l�P
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
      END;
--
      -- =====================
      -- �[�i�`�[���͋敪�̓��o
      -- =====================
        -- ���͋敪����[�i���́EEOS�`�[���ͣor����̋@����or��ԕi���ͣor����̋@�ԕi����ԍ��t���O���Ԃ̎�
        IF ( ( ( lt_input_class = cv_input_class_eos ) OR ( lt_input_class = cv_input_class_vd ) 
             OR  ( lt_input_class = cv_input_class_rt ) OR ( lt_input_class = cv_input_class_vd_rt ) ) 
           AND ( lt_red_black_flag =  cv_red_flag ) ) THEN
          BEGIN
            SELECT  look_val.attribute5  -- �����E�����(�[�i�`�[�敪(�̔����ѓ��͋敪))
            INTO    lt_ins_invoice_type
            FROM    fnd_lookup_values     look_val,
                    fnd_lookup_types_tl   types_tl,
                    fnd_lookup_types      types,
                    fnd_application_tl    appl,
                    fnd_application       app
            WHERE   appl.application_id   = types.application_id
            AND     app.application_id    = appl.application_id
            AND     types_tl.lookup_type  = look_val.lookup_type
            AND     types.lookup_type     = types_tl.lookup_type
            AND     types.security_group_id   = types_tl.security_group_id
            AND     types.view_application_id = types_tl.view_application_id
            AND     types_tl.language = USERENV( 'LANG' )
            AND     look_val.language = USERENV( 'LANG' )
            AND     appl.language     = USERENV( 'LANG' )
            AND     gd_process_date      >= look_val.start_date_active
            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
            AND     app.application_short_name = cv_application
            AND     look_val.enabled_flag = cv_tkn_yes
            AND     look_val.lookup_type = cv_xxcos1_input_class
            AND     look_val.lookup_code = lt_input_class;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
              --�L�[�ҏW�\�ϐ��ݒ�
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
--              lv_key_name2 := NULL;
--              lv_key_data1 := lt_input_class;
--              lv_key_data2 := NULL;
--            RAISE no_data_extract;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp ), -- ���ږ��̂P
                iv_data_value1 => lt_input_class,         -- �f�[�^�̒l�P
                ov_key_info    => gv_tkn2,              -- �L�[���
                ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
                ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
                ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                    iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                    iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                    iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                    iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                    iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
          END;
--
        --���͋敪�����̑��̏ꍇ
        ELSE
          BEGIN
            SELECT  look_val.attribute4   -- �ʏ펞(�[�i�`�[�敪(�̔����ѓ��͋敪))
            INTO    lt_ins_invoice_type
            FROM    fnd_lookup_values     look_val,
                    fnd_lookup_types_tl   types_tl,
                    fnd_lookup_types      types,
                    fnd_application_tl    appl,
                    fnd_application       app
            WHERE   appl.application_id   = types.application_id
            AND     app.application_id    = appl.application_id
            AND     types_tl.lookup_type  = look_val.lookup_type
            AND     types.lookup_type     = types_tl.lookup_type
            AND     types.security_group_id   = types_tl.security_group_id
            AND     types.view_application_id = types_tl.view_application_id
            AND     types_tl.language = USERENV( 'LANG' )
            AND     look_val.language = USERENV( 'LANG' )
            AND     appl.language     = USERENV( 'LANG' )
            AND     gd_process_date      >= look_val.start_date_active
            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
            AND     app.application_short_name = cv_application
            AND     look_val.enabled_flag = cv_tkn_yes
            AND     look_val.lookup_type = cv_xxcos1_input_class
            AND     look_val.lookup_code = lt_input_class;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
              --�L�[�ҏW�\�ϐ��ݒ�
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
--              lv_key_name2 := NULL;
--              lv_key_data1 := lt_input_class;
--              lv_key_data2 := NULL;
--            RAISE no_data_extract;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp ), -- ���ږ��̂P
                iv_data_value1 => lt_input_class,         -- �f�[�^�̒l�P
                ov_key_info    => gv_tkn2,              -- �L�[���
                ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
                ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
                ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                    iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                    iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                    iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                    iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                    iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                    iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
          END;
        END IF;
--
      --���׃f�[�^�擾
      <<line_loop>>
      FOR line_no IN ln_line_no..gn_line_edi_cnt LOOP
        lt_lin_order_no_hht          := gt_dlv_edi_lines_data( line_no ).order_no_hht;          -- ��No.�iHHT�j
        lt_lin_line_no_hht           := gt_dlv_edi_lines_data( line_no ).line_no_hht;           -- �sNo.�iHHT�j
        lt_lin_digestion_ln_number   := gt_dlv_edi_lines_data( line_no ).digestion_ln_number;   -- �}��
        lt_lin_order_no_ebs          := gt_dlv_edi_lines_data( line_no ).order_no_ebs;          -- ��No.�iEBS�j
        lt_lin_line_number_ebs       := gt_dlv_edi_lines_data( line_no ).line_number_ebs;       -- ���הԍ��iEBS�j
        lt_lin_item_code_self        := gt_dlv_edi_lines_data( line_no ).item_code_self;        -- �i���R�[�h�i���Ёj
        lt_lin_content               := gt_dlv_edi_lines_data( line_no ).content;               -- ����
        lt_lin_inventory_item_id     := gt_dlv_edi_lines_data( line_no ).inventory_item_id;     -- �i��ID
        lt_lin_standard_unit         := gt_dlv_edi_lines_data( line_no ).standard_unit;         -- ��P��
        lt_lin_case_number           := gt_dlv_edi_lines_data( line_no ).case_number;           -- �P�[�X��
        lt_lin_quantity              := gt_dlv_edi_lines_data( line_no ).quantity;              -- ����
        lt_lin_sale_class            := gt_dlv_edi_lines_data( line_no ).sale_class;            -- ����敪
        lt_lin_wholesale_unit_ploce  := gt_dlv_edi_lines_data( line_no ).wholesale_unit_ploce;  -- ���P��
        lt_lin_selling_price         := gt_dlv_edi_lines_data( line_no ).selling_price;         -- ���P��
        lt_lin_column_no             := gt_dlv_edi_lines_data( line_no ).column_no;             -- �R����No.
        lt_lin_h_and_c               := gt_dlv_edi_lines_data( line_no ).h_and_c;               -- H/C
        lt_lin_sold_out_class        := gt_dlv_edi_lines_data( line_no ).sold_out_class;        -- ���؋敪
        lt_lin_sold_out_time         := gt_dlv_edi_lines_data( line_no ).sold_out_time;         -- ���؎���
        lt_lin_replenish_number      := gt_dlv_edi_lines_data( line_no ).replenish_number;      -- ��[��
        lt_lin_cash_and_card         := gt_dlv_edi_lines_data( line_no ).cash_and_card;         -- �����E�J�[�h���p�z
--
        EXIT WHEN ( ( lt_order_no_hht || lt_digestion_ln_number ) <> ( lt_lin_order_no_hht || lt_lin_digestion_ln_number ) );
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        ln_line_data_count := ln_line_data_count + 1;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--        -- ===================
--        -- �o�^�p����ID�擾
--        -- ===================
--        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
--        INTO   ln_sales_exp_line_id
--        FROM   DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
--
        --====================================
        --�c�ƌ����̓��o(�̔����і���(�R����))
        --====================================
        BEGIN
          SELECT ic_item.attribute7,               -- ���c�ƌ���
                 ic_item.attribute8,               -- �V�c�ƌ���
                 ic_item.attribute9,               -- �c�ƌ����K�p�J�n��
                 mtl_item.primary_unit_of_measure, -- ��P��
                 cmm_item.inc_num                  -- �������
          INTO   lt_old_sales_cost,
                 lt_new_sales_cost,
                 lt_st_sales_cost,
                 lt_stand_unit,
                 lt_inc_num
          FROM   mtl_system_items_b    mtl_item,    -- �i��
                 ic_item_mst_b         ic_item,     -- OPM�i��
                 xxcmm_system_items_b  cmm_item     -- Disc�i�ڃA�h�I��
          WHERE  mtl_item.organization_id   = gn_orga_id
          AND  mtl_item.segment1 = lt_lin_item_code_self
          AND  mtl_item.segment1 = ic_item.item_no
          AND  mtl_item.segment1 = cmm_item.item_code
          AND  cmm_item.item_id  = ic_item.item_id
/*--==============2009/2/4-START=========================--*/
          AND    NVL( mtl_item.start_date_active, gd_process_date) <= gd_process_date
          AND    NVL( mtl_item.end_date_active, gd_max_date ) >= gd_process_date;
/*--==============2009/2/4-END==========================--*/
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          --�L�[�ҏW����
            -- ���O�o��
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_inv_item_mst );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
--            lv_key_data1 := lt_lin_item_code_self;
--            lv_key_data2 := gn_orga_id;
--            RAISE no_data_extract;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            xxcos_common_pkg.makeup_key_info(
              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code ), -- ���ږ��̂P
              iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id ),    -- ���ږ��̂Q
              iv_data_value1 => lt_lin_item_code_self,         -- �f�[�^�̒l�P
              iv_data_value2 => gn_orga_id,           -- �f�[�^�̒l�Q
              ov_key_info    => gv_tkn2,              -- �L�[���
              ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
              ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
              ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                  iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                  iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                  iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                  iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                  iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                  iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
        END;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        IF ( lv_state_flg <> cv_status_warn ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
          -- ===================================
          -- �c�ƌ�������
          -- ===================================
          IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_dlv_date ) THEN
            lt_sales_cost := lt_old_sales_cost;
          ELSE
            lt_sales_cost := lt_new_sales_cost;
          END IF;
--
          -- ============
          -- ���׋��z�Z�o
          -- ============
          -- ��P��
          lt_standard_unit_price   := lt_lin_wholesale_unit_ploce;
--
          IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- ��ې�
--
            -- ������z
            lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
            -- �{�̋��z
            lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- ����ŋ��z
            lt_tax_amount            := cn_cons_tkn_zero;
--
          ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
            -- ������z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_sale_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
--          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_sale_amount := TRUNC( lt_sale_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount := ROUND( lt_sale_amount );
--            END IF;
--          END IF;
            ln_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_sale_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_sale_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_sale_amount := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
            -- �{�̋��z
            lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- ����ŋ��z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_tax_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
--          IF ( lt_tax_amount <> TRUNC( lt_tax_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_tax_amount := ( TRUNC( lt_tax_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_tax_amount := TRUNC( lt_tax_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_tax_amount := ROUND( lt_tax_amount );
--            END IF;
--          END IF;
            ln_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_tax_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_tax_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_tax_amount   := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
--
          ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
            -- ������z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_sale_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
--          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_sale_amount := TRUNC( lt_sale_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount := ROUND( lt_sale_amount );
--            END IF;
--          END IF;
            ln_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_sale_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_sale_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_sale_amount   := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
            -- �{�̋��z
            lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- ����ŋ��z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_tax_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
--          IF ( lt_tax_amount <> TRUNC( lt_tax_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_tax_amount := ( TRUNC( lt_tax_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_tax_amount := TRUNC( lt_tax_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_tax_amount := ROUND( lt_tax_amount );
--            END IF;
--          END IF;
            ln_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_tax_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_tax_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_tax_amount   := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
--
          ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--
            -- ������z
            lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- �Ŕ���P��
            lt_stand_unit_price_excl := ( lt_lin_wholesale_unit_ploce / ln_tax_data );
            IF ( lt_stand_unit_price_excl <> TRUNC( lt_stand_unit_price_excl ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_stand_unit_price_excl := ( TRUNC( lt_stand_unit_price_excl ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_stand_unit_price_excl := TRUNC( lt_stand_unit_price_excl );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_stand_unit_price_excl := ROUND( lt_stand_unit_price_excl );
              END IF;
            END IF;
            -- �{�̋��z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_pure_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
--          IF ( lt_pure_amount <> TRUNC( lt_pure_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_pure_amount := ( TRUNC( lt_pure_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_pure_amount := TRUNC( lt_pure_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_pure_amount := ROUND( lt_pure_amount );
--            END IF;
--          END IF;
            ln_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_pure_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
              lt_pure_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
              lt_pure_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_pure_amount   := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- ����ŋ��z
            lt_tax_amount            := TRUNC( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
                                         - lt_pure_amount );
--
          END IF;
--
          --�Ώƃf�[�^����ېłłȂ��Ƃ��̂Ƃ�
          IF ( lt_consumption_tax_class <> cv_non_tax ) THEN
            --����ō��v�Ϗグ
            ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
            --���וʍő����ŎZ�o
            IF ( ln_max_tax_data < lt_tax_amount ) THEN
              ln_max_tax_data := lt_tax_amount;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--              ln_max_no_data  := gn_line_data_no;
              ln_max_no_data  := ln_line_data_count;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            END IF;
          END IF;
--
          -- �ő喾�׍sNo�擾
          IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
            IF ( ln_max_invoice_num IS NULL) OR ( ln_max_invoice_num < lt_lin_line_no_hht ) THEN
              ln_max_invoice_num := lt_lin_line_no_hht;
            END IF;
          END IF;
--
          -- �ԁE���̋��z���Z
          --���̎�
          IF ( lt_red_black_flag = cv_black_flag) THEN
            -- �����(�[�i����)
            lt_set_replenish_number := lt_lin_replenish_number;
            -- ������z
            lt_set_sale_amount := lt_sale_amount;
            -- �{�̋��z
            lt_set_pure_amount := lt_pure_amount;
            -- ����ŋ��z
            lt_set_tax_amount := lt_tax_amount;
          -- �Ԃ̎�
          ELSIF ( lt_red_black_flag = cv_red_flag) THEN
            -- �����(�[�i����)
            lt_set_replenish_number := ( lt_lin_replenish_number * ( -1 ) );
            -- ������z
            lt_set_sale_amount := ( lt_sale_amount * ( -1 ) );
            -- �{�̋��z
            lt_set_pure_amount := ( lt_pure_amount * ( -1 ) );
            -- ����ŋ��z
            lt_set_tax_amount := ( lt_tax_amount * ( -1 ) );
          END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--        --====================
--        --���׃f�[�^�̕ϐ��}��
--        --====================
--        gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- �̔����і���ID
--        gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- �̔����уw�b�_ID
--        gt_line_dlv_invoice_number( gn_line_data_no )      := lt_hht_invoice_no;            -- �[�i�`�[�ԍ�
--        gt_line_dlv_invoice_l_num( gn_line_data_no )       := lt_lin_line_no_hht;           -- �[�i���הԍ�
--        gt_line_sales_class( gn_line_data_no )             := lt_lin_sale_class;            -- ����敪
--        gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;            -- �ԍ��t���O
--        gt_line_item_code( gn_line_data_no )               := lt_lin_item_code_self;        -- �i�ڃR�[�h
--        gt_line_standard_qty( gn_line_data_no )            := lt_set_replenish_number;      -- �����
--        gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;                -- ��P��
--        gt_line_standard_unit_price( gn_line_data_no )     := lt_standard_unit_price;       -- ��P��
--        gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero );-- �c�ƌ���
--        gt_line_sale_amount( gn_line_data_no )             := lt_set_sale_amount;           -- ������z
--        gt_line_pure_amount( gn_line_data_no )             := lt_set_pure_amount;           -- �{�̋��z
--        gt_line_tax_amount( gn_line_data_no )              := lt_set_tax_amount;            -- ����ŋ��z
--        gt_line_cash_and_card( gn_line_data_no )           := lt_lin_cash_and_card;         -- �����E�J�[�h���p�z
--        gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_secondary_inventory_name;  -- �o�׌��ۊǏꏊ
--        gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;             -- �[�i���_�R�[�h
--        gt_line_hot_cold_class( gn_line_data_no )          := lt_lin_h_and_c;               -- �g���b
--        gt_line_column_no( gn_line_data_no )               := lt_lin_column_no;             -- �R����No
--        gt_line_sold_out_class( gn_line_data_no )          := lt_lin_sold_out_class;        -- ���؋敪
--        gt_line_sold_out_time( gn_line_data_no )           := lt_lin_sold_out_time;         -- ���؎���
--        gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                     -- �萔���v�Z-IF�σt���O
--        gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                     -- �P���}�X�^�쐬�σt���O
--        gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                     -- INV-IF�σt���O
--        gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;                  -- �������הԍ�(NULL�ݒ�)
--        gt_line_not_tax_amount( gn_line_data_no )          := lt_stand_unit_price_excl;     -- �Ŕ���P��
--        gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;             -- �[�i�`�ԋ敪
--        gt_line_dlv_qty( gn_line_data_no )                 := lt_set_replenish_number;      -- �[�i����
--        gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;                -- �[�i�P��
--        gt_dlv_unit_price( gn_line_data_no )               := lt_standard_unit_price;       -- �[�i�P��
--        gn_line_data_no := gn_line_data_no + 1;
        -- ===================
        -- �ꎞ�i�[�p
        -- ===================
        gt_accumulation_data(ln_line_data_count).dlv_invoice_number         := lt_hht_invoice_no;             -- �[�i�`�[�ԍ�
        gt_accumulation_data(ln_line_data_count).dlv_invoice_line_number    := lt_lin_line_no_hht;            -- �[�i���הԍ�
        gt_accumulation_data(ln_line_data_count).sales_class                := lt_lin_sale_class;             -- ����敪
        gt_accumulation_data(ln_line_data_count).red_black_flag             := lt_red_black_flag;             -- �ԍ��t���O
        gt_accumulation_data(ln_line_data_count).item_code                  := lt_lin_item_code_self;         -- �i�ڃR�[�h
        gt_accumulation_data(ln_line_data_count).dlv_qty                    := lt_set_replenish_number;       -- �[�i����
        gt_accumulation_data(ln_line_data_count).standard_qty               := lt_set_replenish_number;       -- �����
        gt_accumulation_data(ln_line_data_count).dlv_uom_code               := lt_stand_unit;                 -- �[�i�P��
        gt_accumulation_data(ln_line_data_count).standard_uom_code          := lt_stand_unit;                 -- ��P��
        gt_accumulation_data(ln_line_data_count).dlv_unit_price             := lt_standard_unit_price;        -- �[�i�P��
        gt_accumulation_data(ln_line_data_count).standard_unit_price        := lt_standard_unit_price;        -- ��P��
        gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- �c�ƌ���
        gt_accumulation_data(ln_line_data_count).sale_amount                := lt_set_sale_amount;            -- ������z
        gt_accumulation_data(ln_line_data_count).pure_amount                := lt_set_pure_amount;            -- �{�̋��z
        gt_accumulation_data(ln_line_data_count).tax_amount                 := lt_set_tax_amount;             -- ����ŋ��z
        gt_accumulation_data(ln_line_data_count).cash_and_card              := lt_lin_cash_and_card;          -- �����E�J�[�h���p�z
        gt_accumulation_data(ln_line_data_count).ship_from_subinventory_code := lt_secondary_inventory_name;  -- �o�׌��ۊǏꏊ
        gt_accumulation_data(ln_line_data_count).delivery_base_code         := lt_dlv_base_code;              -- �[�i���_�R�[�h
        gt_accumulation_data(ln_line_data_count).hot_cold_class             := lt_lin_h_and_c;                -- �g���b
        gt_accumulation_data(ln_line_data_count).column_no                  := lt_lin_column_no;              -- �R����No
        gt_accumulation_data(ln_line_data_count).sold_out_class             := lt_lin_sold_out_class;         -- ���؋敪
        gt_accumulation_data(ln_line_data_count).sold_out_time              := lt_lin_sold_out_time;          -- ���؎���
        gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                      -- �萔���v�Z�C���^�t�F�[�X�σt���O
        gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                      -- �P���}�X�^�쐬�σt���O
        gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                      -- INV�C���^�t�F�[�X�σt���O
        gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;                   -- �������הԍ�(NULL�ݒ�)
        gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := lt_stand_unit_price_excl;    -- �Ŕ���P��
        gt_accumulation_data(ln_line_data_count).delivery_pattern_class     :=   lv_delivery_type;            -- �[�i�`�ԋ敪(���o)
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
      END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
      ln_line_no := ln_line_no + 1;
--
      END LOOP line_loop;
      -- �l�������������Ă���ꍇ
      IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        ln_line_data_count := ln_line_data_count + 1;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
        -- =======================================
        -- �l�����z���א���(A-8)
        -- =======================================
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--        -- ===================
--        -- �o�^�p����ID�擾
--        -- ===================
--        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
--        INTO   ln_sales_exp_line_id
--        FROM   DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
--
        -- =================================
        -- �c�ƌ����A��P�ʂ𓱏o
        -- =================================
        BEGIN
          SELECT ic_item.attribute7,              -- ���c�ƌ���
                 ic_item.attribute8,              -- �V�c�ƌ���
                 ic_item.attribute9,              -- �c�ƌ����K�p�J�n��
                 mtl_item.primary_unit_of_measure -- ��P��
          INTO   lt_old_sales_cost,
                 lt_new_sales_cost,
                 lt_st_sales_cost,
                 lt_stand_unit
          FROM   mtl_system_items_b    mtl_item,    -- �i��
                 ic_item_mst_b         ic_item,     -- OPM�i��
                 xxcmm_system_items_b  cmm_item     -- Disc�i�ڃA�h�I��
          WHERE  mtl_item.organization_id   = gn_orga_id
          AND  mtl_item.segment1 = gv_disc_item
          AND  mtl_item.segment1 = ic_item.item_no
          AND  mtl_item.segment1 = cmm_item.item_code
          AND  cmm_item.item_id  = ic_item.item_id
/*--==============2009/2/4-START=========================--*/
          AND    NVL( mtl_item.start_date_active, gd_process_date) <= gd_process_date
          AND    NVL( mtl_item.end_date_active, gd_max_date ) >= gd_process_date;
/*--==============2009/2/4-END==========================--*/
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --�L�[�ҏW����
            -- ���O�o��
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_inv_item_mst );
            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
            lv_key_data1 := gv_disc_item;
            lv_key_data2 := gn_orga_id;
            RAISE no_data_extract;
        END;
        -- ===================================
        -- �c�ƌ�������
        -- ===================================
        IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_dlv_date ) THEN
          lt_sales_cost := lt_old_sales_cost;
        ELSE
          lt_sales_cost := lt_new_sales_cost;
        END IF;
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--/*--==============2009/2/3-START=========================--*/
--        IF ( lv_depart_code = cv_depart_car ) THEN
--        IF ( lv_depart_code IS NULL ) 
--          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_base ) ) THEN
--/*--==============2009/2/3-END==========================--*/
--          --�ۊǏꏊ�}�X�^�f�[�^�擾
--          BEGIN
--            SELECT msi.secondary_inventory_name     -- �ۊǏꏊ�R�[�h
--            INTO   lt_secondary_inventory_name
--            FROM   mtl_secondary_inventories msi    --�ۊǏꏊ�}�X�^
--            WHERE  msi.attribute7 = lt_base_code
--            AND    msi.attribute13 = lt_location_type_code;
--            AND    msi.attribute3 = lt_dlv_by_code;
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              -- ���O�o��
--              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
--              --�L�[�ҏW�����p�ϐ�
--              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--              lv_key_data1 := lt_base_code;
--              lv_key_data2 := cv_xxcos_001_a05_05;
--            RAISE no_data_extract;
--          END;
--
--/*--==============2009/2/3-START=========================--*/
----        ELSIF ( lv_depart_code = cv_depart_type ) THEN
----        ELSIF ( lv_depart_code IS NOT NULL ) THEN
--        ELSIF ( lv_depart_code = cv_depart_type ) 
--          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_dep ) )THEN
--/*--==============2009/2/3-END==========================--*/
--          --�Q�ƃR�[�h�}�X�^�F�S�ݓX�̕ۊǏꏊ���ރR�[�h�擾
--
--          --�ۊǏꏊ�}�X�^�f�[�^�擾
--          BEGIN
--            SELECT msi.secondary_inventory_name           -- �ۊǏꏊ����
--            INTO   lt_secondary_inventory_name
--            FROM   mtl_secondary_inventories msi,         -- �ۊǏꏊ�}�X�^
--                   mtl_parameters mp                      -- �g�D�p�����[�^
--            WHERE  msi.organization_id=mp.organization_id
--            AND    mp.organization_code = gv_orga_code
--            AND    msi.attribute4       = lt_keep_in_code
--            AND    msi.attribute13      = lt_depart_location_type_code;
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              -- ���O�o��
--              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
--              --�L�[�ҏW�����p�ϐ��ݒ�
--              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--              lv_key_data1 := lt_base_code;
--              lv_key_data2 := cv_xxcos_001_a05_09;
--            RAISE no_data_extract;
--          END;
--
--        END IF;
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        IF ( lv_state_flg <> cv_status_warn ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
          -- ================
          -- ���z�Z�o����
          -- ================
          IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- ��ې�
--
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_sale_discount_amount;
            -- ��P��
            lt_standard_unit_price   := lt_sale_discount_amount;
            -- ������z
            lt_sale_amount           := lt_sale_discount_amount;
            -- �{�̋��z
            lt_pure_amount           := lt_sale_discount_amount;
            -- ����ŋ��z
            lt_tax_amount            := cn_cons_tkn_zero;
--
          ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_sale_discount_amount;
            -- ��P��
            lt_standard_unit_price   := lt_sale_discount_amount;
            -- ������z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_sale_amount           := ( lt_sale_discount_amount * ln_tax_data);
--          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_sale_amount := TRUNC( lt_sale_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount := ROUND( lt_sale_amount );
--            END IF;
--          END IF;
            ln_amount           := ( lt_sale_discount_amount );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_sale_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_sale_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_sale_amount := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- �{�̋��z
            lt_pure_amount           := lt_sale_discount_amount;
            -- ����ŋ��z
            ln_amount            := ( lt_sale_discount_amount * ( ln_tax_data - 1 ) );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_tax_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_tax_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_tax_amount := ln_amount;
            END IF;
--
          ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_sale_discount_amount;
            -- ��P��
            lt_standard_unit_price   := ( lt_sale_discount_amount  );
            -- ������z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--         lt_sale_amount           := ( lt_sale_discount_amount * ln_tax_data);
--          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_sale_amount := TRUNC( lt_sale_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount := ROUND( lt_sale_amount );
--            END IF;
--          END IF;
            ln_amount           := ( lt_sale_discount_amount );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_sale_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_sale_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_sale_amount := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- �{�̋��z
            lt_pure_amount           := lt_sale_discount_amount;
            -- ����ŋ��z
            ln_amount            := ( lt_sale_discount_amount * ( ln_tax_data - 1 ) );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_tax_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_tax_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_tax_amount := ln_amount;
            END IF;
--
          ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--
            -- �Ŕ���P��
            lt_stand_unit_price_excl := ( lt_sale_discount_amount / ln_tax_data);
            IF ( lt_stand_unit_price_excl <> TRUNC( lt_stand_unit_price_excl ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_stand_unit_price_excl := ( TRUNC( lt_stand_unit_price_excl ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_stand_unit_price_excl := TRUNC( lt_stand_unit_price_excl );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_stand_unit_price_excl := ROUND( lt_stand_unit_price_excl );
              END IF;
            END IF;
            -- ��P��
            lt_standard_unit_price   := lt_sale_discount_amount;
            -- ������z
            lt_sale_amount           := lt_sale_discount_amount;
            -- �{�̋��z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_pure_amount           := ( lt_sale_discount_amount / ln_tax_data );
--          IF ( lt_pure_amount <> TRUNC( lt_pure_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_pure_amount := ( TRUNC( lt_pure_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_pure_amount := TRUNC( lt_pure_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_pure_amount := ROUND( lt_pure_amount );
--            END IF;
--          END IF;
            ln_amount           := ( lt_sale_discount_amount / ln_tax_data );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_pure_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_pure_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_pure_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_pure_amount := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- ����ŋ��z
            lt_tax_amount            := TRUNC( lt_sale_amount - lt_pure_amount );
          END IF;
--
          -- �l���p�[�i���הԍ��ݒ�
          ln_max_invoice_num := ln_max_invoice_num + 1;
          -- �o�^�p�l�����z�ݒ�
          lt_sale_amount := ( lt_sale_amount * ( -1 ) );
          lt_pure_amount := ( lt_pure_amount * ( -1 ) );
          lt_tax_amount  := ( lt_tax_amount * ( -1 ) );
--
          -- �ԁE���̋��z���Z
          --���̎�
          IF ( lt_red_black_flag = cv_black_flag) THEN
            -- �����(�[�i����)
            lt_set_replenish_number := cn_disc_standard_qty;
            -- ������z
            lt_set_sale_amount := lt_sale_amount;
            -- �{�̋��z
            lt_set_pure_amount := lt_pure_amount;
            -- ����ŋ��z
            lt_set_tax_amount := lt_tax_amount;
          -- �Ԃ̎�
          ELSIF ( lt_red_black_flag = cv_red_flag) THEN
            -- �����(�[�i����)
            lt_set_replenish_number := ( cn_disc_standard_qty * ( -1 ) );
            -- ������z
            lt_set_sale_amount := ( lt_sale_amount * ( -1 ) );
            -- �{�̋��z
            lt_set_pure_amount := ( lt_pure_amount * ( -1 ) );
            -- ����ŋ��z
            lt_set_tax_amount := ( lt_tax_amount * ( -1 ) );
          END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START   ***************************************
--        -- =========================================
--        -- �l�������׃f�[�^�Z�b�g
--        -- =========================================
--        gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- �̔����і���ID
--        gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- �̔����уw�b�_ID

--        gt_line_dlv_invoice_number( gn_line_data_no )      := lt_hht_invoice_no;            -- �[�i�`�[�ԍ�
--        gt_line_dlv_invoice_l_num( gn_line_data_no )       := ln_max_invoice_num;           -- �[�i���הԍ�
--        gt_line_sales_class( gn_line_data_no )             := cv_sales_st_class;            -- ����敪
--        gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;            -- �ԍ��t���O
--        gt_line_item_code( gn_line_data_no )               := gv_disc_item;                 -- �i�ڃR�[�h
--        gt_line_standard_qty( gn_line_data_no )            := lt_set_replenish_number;      -- �����
--        gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;                -- ��P��
--        gt_line_standard_unit_price( gn_line_data_no )     := lt_standard_unit_price;       -- ��P��
--        gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero ); -- �c�ƌ���
--        gt_line_sale_amount( gn_line_data_no )             := lt_set_sale_amount;           -- ������z
--        gt_line_pure_amount( gn_line_data_no )             := lt_set_pure_amount;           -- �{�̋��z
--        gt_line_tax_amount( gn_line_data_no )              := lt_set_tax_amount;            -- ����ŋ��z
--        gt_line_cash_and_card( gn_line_data_no )           := cn_tkn_zero;                  -- �����E�J�[�h���p�z
--        gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_secondary_inventory_name;  -- �o�׌��ۊǏꏊ
--        gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;             -- �[�i���_�R�[�h
--        gt_line_hot_cold_class( gn_line_data_no )          := cv_tkn_null;                  -- �g���b
--        gt_line_column_no( gn_line_data_no )               := cv_tkn_null;                  -- �R����No
--        gt_line_sold_out_class( gn_line_data_no )          := cv_tkn_null;                  -- ���؋敪
--        gt_line_sold_out_time( gn_line_data_no )           := cv_tkn_null;                  -- ���؎���
--        gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                     -- �萔���v�ZIF�σt���O
--        gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                     -- �P���}�X�^�쐬�σt���O
--        gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                     -- INV�C���^�t�F�[�X�σt���O
--        gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;                  -- �������הԍ�(NULL�ݒ�)
--        gt_line_not_tax_amount( gn_line_data_no )          := lt_stand_unit_price_excl;     -- �Ŕ���P��
--        gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;             -- �[�i�`�ԋ敪
--        gt_line_dlv_qty( gn_line_data_no )                 := lt_set_replenish_number;      -- �[�i����
--        gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;                -- �[�i�P��
--        gt_dlv_unit_price( gn_line_data_no )               := lt_standard_unit_price;       -- �[�i�P��
--        gn_line_data_no := gn_line_data_no + 1;
          -- ===================
          -- �ꎞ�i�[�p
          -- ===================
          gt_accumulation_data(ln_line_data_count).dlv_invoice_number         := lt_hht_invoice_no;             -- �[�i�`�[�ԍ�
          gt_accumulation_data(ln_line_data_count).dlv_invoice_line_number    := ln_max_invoice_num;            -- �[�i���הԍ�
          gt_accumulation_data(ln_line_data_count).sales_class                := cv_sales_st_class;             -- ����敪
          gt_accumulation_data(ln_line_data_count).red_black_flag             := lt_red_black_flag;             -- �ԍ��t���O
          gt_accumulation_data(ln_line_data_count).item_code                  := gv_disc_item;                  -- �i�ڃR�[�h
          gt_accumulation_data(ln_line_data_count).dlv_qty                    := lt_set_replenish_number;       -- �[�i����
          gt_accumulation_data(ln_line_data_count).standard_qty               := lt_set_replenish_number;       -- �����
          gt_accumulation_data(ln_line_data_count).dlv_uom_code               := lt_stand_unit;                 -- �[�i�P��
          gt_accumulation_data(ln_line_data_count).standard_uom_code          := lt_stand_unit;                 -- ��P��
          gt_accumulation_data(ln_line_data_count).dlv_unit_price             := lt_standard_unit_price;        -- �[�i�P��
          gt_accumulation_data(ln_line_data_count).standard_unit_price        := lt_standard_unit_price;        -- ��P��
          gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- �c�ƌ���
          gt_accumulation_data(ln_line_data_count).sale_amount                := lt_set_sale_amount;            -- ������z
          gt_accumulation_data(ln_line_data_count).pure_amount                := lt_set_pure_amount;            -- �{�̋��z
          gt_accumulation_data(ln_line_data_count).tax_amount                 := lt_set_tax_amount;             -- ����ŋ��z
          gt_accumulation_data(ln_line_data_count).cash_and_card              := cn_tkn_zero;                   -- �����E�J�[�h���p�z
          gt_accumulation_data(ln_line_data_count).ship_from_subinventory_code := lt_secondary_inventory_name;  -- �o�׌��ۊǏꏊ
          gt_accumulation_data(ln_line_data_count).delivery_base_code         := lt_dlv_base_code;              -- �[�i���_�R�[�h
          gt_accumulation_data(ln_line_data_count).hot_cold_class             := cv_tkn_null;                   -- �g���b
          gt_accumulation_data(ln_line_data_count).column_no                  := cv_tkn_null;                   -- �R����No
          gt_accumulation_data(ln_line_data_count).sold_out_class             := cv_tkn_null;                   -- ���؋敪
          gt_accumulation_data(ln_line_data_count).sold_out_time              := cv_tkn_null;                   -- ���؎���
          gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                      -- �萔���v�Z�C���^�t�F�[�X�σt���O
          gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                      -- �P���}�X�^�쐬�σt���O
          gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                      -- INV�C���^�t�F�[�X�σt���O
          gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;                   -- �������הԍ�(NULL�ݒ�)
          gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := lt_stand_unit_price_excl;    -- �Ŕ���P��
          gt_accumulation_data(ln_line_data_count).delivery_pattern_class     := lv_delivery_type;              -- �[�i�`�ԋ敪(���o)
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
      END IF;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      IF ( lv_state_flg <> cv_status_warn ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
        -- ==================
        -- �w�b�_�o�^�p���z�Z�o
        -- ==================
        IF ( lt_consumption_tax_class = cv_non_tax ) THEN           -- ��ې�
--
          -- ������z���v
          lt_sale_amount_sum := lt_total_amount;
          -- �{�̋��z���v
          lt_pure_amount_sum := lt_total_amount;
          -- ����ŋ��z���v
          lt_tax_amount_sum  := lt_sales_consumption_tax;
        ELSE
         --�l��������
          IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
--
            IF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
              -- ������z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_sale_amount_sum := ( lt_tax_include * ln_tax_data );
--              IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
--                IF ( lt_tax_odd = cv_amount_up ) THEN
--                lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
--                -- �؎̂�
--                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                  lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
--                -- �l�̌ܓ�
--                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
--                END IF;
--              END IF;
              ln_amount := ( lt_tax_include );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_sale_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_sale_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_sale_amount_sum := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- �{�̋��z���v
              lt_pure_amount_sum := lt_tax_include;
              -- ����ŋ��z���v
              ln_amount  := ( lt_sale_amount_sum * ( ln_tax_data - 1 ) );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                  lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_tax_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_tax_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_tax_amount_sum   := ln_amount;
              END IF;
--
            ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
              -- ������z���v
              lt_sale_amount_sum := lt_tax_include;
              -- �{�̋��z���v
              lt_pure_amount_sum := ( lt_total_amount - lt_sale_discount_amount );
              -- ����ŋ��z���v
              lt_tax_amount_sum  := lt_sales_consumption_tax;
--
            ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--
              -- ������z���v
              lt_sale_amount_sum := lt_tax_include;
              -- �{�̋��z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_pure_amount_sum := ( lt_tax_include / ln_tax_data );
--            IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--                lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                 lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
--              END IF;
--            END IF;
              ln_amount := ( lt_tax_include / ln_tax_data );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                  lt_pure_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_pure_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_pure_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_pure_amount_sum   := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- �l������ŎZ�o
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            ln_discount_tax    := ( lt_sale_discount_amount / ln_tax_data );
--            IF ( ln_discount_tax <> TRUNC( ln_discount_tax ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--                ln_discount_tax := ( TRUNC( ln_discount_tax ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                ln_discount_tax := TRUNC( ln_discount_tax );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                 ln_discount_tax:= ROUND( ln_discount_tax );
--              END IF;
--            END IF;
              ln_amount    := ( lt_sale_discount_amount - ( lt_sale_discount_amount / ln_tax_data ) );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                  ln_discount_tax := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  ln_discount_tax := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                   ln_discount_tax:= ROUND( ln_amount );
                END IF;
              ELSE
                ln_discount_tax:= ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- ����ŋ��z���v
              lt_tax_amount_sum  := ( ln_all_tax_amount - ln_discount_tax );
--
            END IF;
          --�l�������������z�Z�o
          ELSE
--
            IF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
            -- ������z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--           lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
--            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
--              END IF;
--            END IF;
              ln_amount := ( lt_total_amount	 );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_sale_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_sale_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_sale_amount_sum := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- �{�̋��z���v
              lt_pure_amount_sum := lt_total_amount;
              -- ����ŋ��z���v
              ln_amount  := ( lt_sale_amount_sum * ( ln_tax_data - 1 ) );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_tax_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_tax_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_tax_amount_sum := ln_amount;
              END IF;
--
            ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
              -- ������z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
--            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN            
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
--              END IF;
--            END IF;
              ln_amount := ( lt_total_amount * ln_tax_data );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_sale_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_sale_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_sale_amount_sum := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- �{�̋��z���v
              lt_pure_amount_sum := lt_total_amount;
              -- ����ŋ��z���v
              lt_tax_amount_sum  := ( lt_sale_amount_sum - lt_pure_amount_sum );
--
            ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--
              -- ������z���v
              lt_sale_amount_sum := lt_total_amount;
              -- �{�̋��z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_pure_amount_sum := ( lt_total_amount / ln_tax_data );
--            IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--                lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
--              END IF;
--            END IF;
              ln_amount := ( lt_total_amount / ln_tax_data );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                  lt_pure_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_pure_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_pure_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_pure_amount_sum   := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- ����ŋ��z���v
              lt_tax_amount_sum  := ln_all_tax_amount;
--
            END IF;
          END IF;
        END IF;
--
        --��ېňȊO�̂Ƃ�
        IF ( lt_consumption_tax_class <> cv_non_tax ) THEN
          --================================================
          --�w�b�_�������Ŋz�Ɩ��ה������Ŋz��r���f����
          --================================================
          -- �l�����ׂ�null�ȊO�̎�
          IF ( lt_sale_discount_amount IS NOT NULL ) AND ( lt_sale_discount_amount <> 0 ) 
          AND ( lt_consumption_tax_class <> cv_ins_bid_tax ) THEN
            ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
          END IF;
          IF ( lt_tax_amount_sum <> ln_all_tax_amount ) THEN
            -- �O�� OR ����(�`�[�ېł̎�)
            IF ( lt_consumption_tax_class = cv_out_tax ) OR ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN
              IF ( lt_red_black_flag = cv_black_flag ) THEN
--******************************* 2009/04/16 N.Maeda Var1.10 MOD START ***************************************
--                gt_line_tax_amount( ln_max_no_data ) := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
                gt_accumulation_data(ln_max_no_data).tax_amount := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
              ELSIF ( lt_red_black_flag = cv_red_flag) THEN
--                gt_line_tax_amount( ln_max_no_data ) := ( ( ln_max_tax_data 
--                                                          + ( lt_tax_amount_sum - ln_all_tax_amount ) ) * ( -1 ) );
                gt_accumulation_data(ln_max_no_data).tax_amount := ( ( ln_max_tax_data 
                                                                      + ( lt_tax_amount_sum - ln_all_tax_amount ) ) * ( -1 ) );
--******************************* 2009/04/16 N.Maeda Var1.10 MOD END   ***************************************
              END IF;
            END IF;
          END IF;
        END IF;
--
        BEGIN
          OPEN  get_oe_order_cur;
          -- �o���N�t�F�b�`
          FETCH get_oe_order_cur BULK COLLECT INTO gt_oe_order_all;
          -- ���o�����Z�b�g
          gn_om_data_cnt := get_oe_order_cur%ROWCOUNT;
          -- �J�[�\��CLOSE
          CLOSE get_oe_order_cur;
        EXCEPTION
          WHEN OTHERS THEN
            IF( get_oe_order_cur%ISOPEN ) THEN
              CLOSE get_oe_order_cur;
            END IF;
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_om_order );
            --�L�[�ҏW�\�ϐ��ݒ�
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_order_no );
--            lv_key_name2 := NULL;
--            lv_key_data1 := lt_order_no_ebs;
--            lv_key_data2 := NULL;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_order_no ), -- ���ږ��̂P
            iv_data_value1 => lt_order_no_ebs,         -- �f�[�^�̒l�P
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
        END;
--
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--        IF ( gn_om_data_cnt > 0 ) THEN
        IF ( gn_om_data_cnt > 0 ) AND ( lv_state_flg <> cv_status_warn )THEN
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
          <<om_order_loop>>
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--          FOR om_data_no IN ln_cnt_om_order..gn_om_data_cnt LOOP
          FOR om_data_no IN 1..gn_om_data_cnt LOOP
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
            -- ====================================
            -- OM�󒍏��i�[
            -- ====================================
--******************************* 2009/05/12 N.Maeda Var1.13 MOD START *************************************
--            gt_oe_order_number( ln_cnt_om_order )      := gt_oe_order_all( om_data_no ).order_number;
--            gt_oe_header_id( ln_cnt_om_order )         := gt_oe_order_all( om_data_no ).header_id;
--            gt_oe_he_flow_status_code( ln_cnt_om_order )  := gt_oe_order_all( om_data_no ).head_flow_status_code;
--            gt_oe_order_source_id( ln_cnt_om_order )   := gt_oe_order_all( om_data_no ).order_source_id;
--            gt_oe_cust_po_number( ln_cnt_om_order )    := gt_oe_order_all( om_data_no ).cust_po_number;
--            gt_oe_line_id( ln_cnt_om_order )           := gt_oe_order_all( om_data_no ).line_id;
--            gt_oe_li_flow_status_code( ln_cnt_om_order )  := gt_oe_order_all( om_data_no ).line_flow_status_code;
--            ln_cnt_om_order := ln_cnt_om_order + 1;
            gt_oe_order_number( gn_cnt_om_order )      := gt_oe_order_all( om_data_no ).order_number;
            gt_oe_header_id( gn_cnt_om_order )         := gt_oe_order_all( om_data_no ).header_id;
            gt_oe_he_flow_status_code( gn_cnt_om_order )  := gt_oe_order_all( om_data_no ).head_flow_status_code;
            gt_oe_order_source_id( gn_cnt_om_order )   := gt_oe_order_all( om_data_no ).order_source_id;
            gt_oe_cust_po_number( gn_cnt_om_order )    := gt_oe_order_all( om_data_no ).cust_po_number;
            gt_oe_line_id( gn_cnt_om_order )           := gt_oe_order_all( om_data_no ).line_id;
            gt_oe_li_flow_status_code( gn_cnt_om_order )  := gt_oe_order_all( om_data_no ).line_flow_status_code;
--******************************* 2009/05/12 N.Maeda Var1.13 MOD  END ***************************************
          END LOOP om_order_loop;
        END IF;
--
        -- �ԁE���̋��z���Z
        --���̎�
        IF ( lt_red_black_flag = cv_black_flag) THEN
          -- ������z���v
          lt_set_sale_amount_sum := lt_sale_amount_sum;
          -- �{�̋��z���v
          lt_set_pure_amount_sum := lt_pure_amount_sum;
          -- ����ŋ��z���v
          lt_set_tax_amount_sum := lt_tax_amount_sum;
        -- �Ԃ̎�
        ELSIF ( lt_red_black_flag = cv_red_flag) THEN
          -- ������z���v
          lt_set_sale_amount_sum := ( lt_sale_amount_sum * ( -1 ) );
          -- �{�̋��z���v
          lt_set_pure_amount_sum := ( lt_pure_amount_sum * ( -1 ) );
          -- ����ŋ��z���v
          lt_set_tax_amount_sum := ( lt_tax_amount_sum * ( -1 ) );
        END IF;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      --================================
      --�̔����уw�b�_ID(�V�[�P���X�擾)
      --================================
        SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
        INTO ln_actual_id
        FROM DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--
        --==========================
        -- �w�b�_�f�[�^�̕ϐ��}��
        --==========================
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        gt_dlv_hht_head_row_id( gn_head_data_no )          := lt_row_id;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
        gt_head_id( gn_head_data_no )                      := ln_actual_id;               -- �̔����уw�b�_ID
        gt_head_order_no_ebs( gn_head_data_no )            := lt_order_no_ebs;            -- �󒍔ԍ�
        gt_head_hht_invoice_no( gn_head_data_no )          := lt_hht_invoice_no;          -- �[�i�`�[�ԍ�
--      gt_head_delivery_pat_class( gn_head_data_no )      := lv_delivery_type;           -- �[�i�`�ԋ敪
        gt_head_order_no_hht( gn_head_data_no )            := lt_order_no_hht;            -- ��No(HHT)
        gt_head_digestion_ln_number( gn_head_data_no )     := lt_digestion_ln_number;     -- ��No(HHT)�}��
        gt_head_dlv_invoice_class( gn_head_data_no )       := lt_ins_invoice_type;        -- �[�i�`�[�敪(���o)
        gt_head_cancel_cor_cls( gn_head_data_no )          := lt_cancel_correct_class;    -- ����E�����敪
        gt_head_system_class( gn_head_data_no )            := lt_system_class;            -- �Ƒԋ敪(�Ƒԏ�����)
        gt_head_dlv_date( gn_head_data_no )                := lt_dlv_date;                -- �[�i��
        gt_head_inspect_date( gn_head_data_no )            := lt_inspect_date;            -- ������(����v���)
        gt_head_customer_number( gn_head_data_no )         := lt_customer_number;         -- �ڋq�y�[�i��z
        gt_head_tax_include( gn_head_data_no )             := lt_set_sale_amount_sum;     -- ������z���v
        gt_head_total_amount( gn_head_data_no )            := lt_set_pure_amount_sum;     -- �{�̋��z���v
        gt_head_sales_consump_tax( gn_head_data_no )       := lt_set_tax_amount_sum;      -- ����ŋ��z���v(�����o)
        gt_head_consump_tax_class( gn_head_data_no )       := lt_consum_type;             -- ����ŋ敪(���o)
        gt_head_tax_code( gn_head_data_no )                := lt_consum_code;             -- �ŋ��R�[�h(���o)
        gt_head_tax_rate( gn_head_data_no )                := lt_tax_consum;              -- ����ŗ�(���o)
        gt_head_performance_by_code( gn_head_data_no )     := lt_performance_by_code;     -- ���ьv��҃R�[�h
        gt_head_sales_base_code( gn_head_data_no )         := lt_sale_base_code;          -- ���㋒�_�R�[�h(���o)
        gt_head_card_sale_class( gn_head_data_no )         := lt_card_sale_class;         -- �J�[�h����敪
--      gt_head_sales_classification( gn_head_data_no )    := lt_sales_classification;    -- �`�[�敪
--      gt_head_invoice_class( gn_head_data_no )           := lt_sales_invoice;           -- �`�[���ރR�[�h
        gt_head_sales_classification( gn_head_data_no )    := lt_sales_invoice;    -- �`�[�敪
        gt_head_invoice_class( gn_head_data_no )           := lt_sales_classification;           -- �`�[���ރR�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
--      gt_head_receiv_base_code( gn_head_data_no )        := lt_sale_base_code;          -- �������_�R�[�h(���o)
        gt_head_receiv_base_code( gn_head_data_no )        := lt_cash_receiv_base_code;   -- �������_�R�[�h(���o)
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
        gt_head_change_out_time_100( gn_head_data_no )     := lt_change_out_time_100;     -- ��K�؂ꎞ��100�~
        gt_head_change_out_time_10( gn_head_data_no )      := lt_change_out_time_10;      -- ��K�؂ꎞ��10�~
        gt_head_hht_dlv_input_date( gn_head_data_no )      := ld_input_date;              -- HHT�[�i���͓���(���^����)
        gt_head_dlv_by_code( gn_head_data_no )             := lt_dlv_by_code;             -- �[�i�҃R�[�h
        gt_head_business_date( gn_head_data_no )           := gd_process_date;            -- �o�^�Ɩ����t(���������擾)
        gt_head_order_source_id( gn_head_data_no )         := cv_tkn_null;                -- �󒍃\�[�XID(NULL�ݒ�)
        gt_head_order_invoice_number( gn_head_data_no )    := cv_tkn_null;                -- �����`�[�ԍ�
        gt_head_order_connection_num( gn_head_data_no )    := cv_tkn_null;                -- �󒍊֘A�ԍ�(NULL�ݒ�)
        gt_head_ar_interface_flag( gn_head_data_no )       := cv_tkn_n;                   -- AR-IF�σt���O('N')
        gt_head_gl_interface_flag( gn_head_data_no )       := cv_tkn_n;                   -- GL-IF�σt���O('N')
        gt_head_dwh_interface_flag( gn_head_data_no )      := cv_tkn_n;                   -- ���V�X�e��-IF�σt���O('N')
        gt_head_edi_interface_flag( gn_head_data_no )      := cv_tkn_n;                   -- EDI���M�ς݃t���O('N'�ݒ�)
        gt_head_edi_send_date( gn_head_data_no )           := cv_tkn_null;                -- EDI���M����(NULL�ݒ�)
-- ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
--        gt_head_create_class( gn_head_data_no )            := cn_tkn_shipping_chk;        -- �쐬���敪(�4��ݒ�)
        gt_head_create_class( gn_head_data_no )            := cv_tkn_shipping_chk;        -- �쐬���敪(�4��ݒ�)
-- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
        gt_head_input_class( gn_head_data_no )             := lt_input_class;             -- ���͋敪
        gn_head_data_no := gn_head_data_no + 1;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
--
        <<line_set_loop>>
        FOR in_data_num IN 1..ln_line_data_count LOOP
--
          -- ===================
          -- �o�^�p����ID�擾
          -- ===================
          SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
          INTO   ln_sales_exp_line_id
          FROM   DUAL;
--
          gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- �̔����і���ID
          gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- �̔����уw�b�_ID
          gt_line_dlv_invoice_number( gn_line_data_no )      := gt_accumulation_data(in_data_num).dlv_invoice_number;    -- �[�i�`�[�ԍ�
          gt_line_dlv_invoice_l_num( gn_line_data_no )       := gt_accumulation_data(in_data_num).dlv_invoice_line_number; -- �[�i���הԍ�
          gt_line_sales_class( gn_line_data_no )             := gt_accumulation_data(in_data_num).sales_class;           -- ����敪
          gt_line_red_black_flag( gn_line_data_no )          := gt_accumulation_data(in_data_num).red_black_flag;        -- �ԍ��t���O
          gt_line_item_code( gn_line_data_no )               := gt_accumulation_data(in_data_num).item_code;             -- �i�ڃR�[�h
          gt_line_standard_qty( gn_line_data_no )            := gt_accumulation_data(in_data_num).standard_qty;          -- �����
          gt_line_standard_uom_code( gn_line_data_no )       := gt_accumulation_data(in_data_num).standard_uom_code;     -- ��P��
          gt_line_standard_unit_price( gn_line_data_no )     := gt_accumulation_data(in_data_num).standard_unit_price;   -- ��P��
          gt_line_business_cost( gn_line_data_no )           := gt_accumulation_data(in_data_num).business_cost;         -- �c�ƌ���
          gt_line_sale_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).sale_amount;           -- ������z
          gt_line_pure_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).pure_amount;           -- �{�̋��z
          gt_line_tax_amount( gn_line_data_no )              := gt_accumulation_data(in_data_num).tax_amount;            -- ����ŋ��z
          gt_line_cash_and_card( gn_line_data_no )           := gt_accumulation_data(in_data_num).cash_and_card;         -- �����E�J�[�h���p�z
          gt_line_ship_from_subinv_co( gn_line_data_no )     := gt_accumulation_data(in_data_num).ship_from_subinventory_code; -- �o�׌��ۊǏꏊ
          gt_line_delivery_base_code( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_base_code;    -- �[�i���_�R�[�h
          gt_line_hot_cold_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).hot_cold_class;        -- �g���b
          gt_line_column_no( gn_line_data_no )               := gt_accumulation_data(in_data_num).column_no;             -- �R����No
          gt_line_sold_out_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).sold_out_class;        -- ���؋敪
          gt_line_sold_out_time( gn_line_data_no )           := gt_accumulation_data(in_data_num).sold_out_time;         -- ���؎���
          gt_line_to_calculate_fees_flag( gn_line_data_no )  := gt_accumulation_data(in_data_num).to_calculate_fees_flag;-- �萔���v�ZIF�σt���O
          gt_line_unit_price_mst_flag( gn_line_data_no )     := gt_accumulation_data(in_data_num).unit_price_mst_flag;   -- �P���}�X�^�쐬�σt���O
          gt_line_inv_interface_flag( gn_line_data_no )      := gt_accumulation_data(in_data_num).inv_interface_flag;    -- INV�C���^�t�F�[�X�σt���O
          gt_line_order_invoice_l_num( gn_line_data_no )     := gt_accumulation_data(in_data_num).order_invoice_line_number;   -- �������הԍ�
          gt_line_not_tax_amount( gn_line_data_no )          := gt_accumulation_data(in_data_num).standard_unit_price_excluded;-- �Ŕ���P��
          gt_line_delivery_pat_class( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_pattern_class;      -- �[�i�`�ԋ敪
          gt_line_dlv_qty( gn_line_data_no )                 := gt_accumulation_data(in_data_num).dlv_qty;                     -- �[�i����
          gt_line_dlv_uom_code( gn_line_data_no )            := gt_accumulation_data(in_data_num).dlv_uom_code;                -- �[�i�P��
          gt_dlv_unit_price( gn_line_data_no )               := gt_accumulation_data(in_data_num).dlv_unit_price;              -- �[�i�P��
          gn_line_data_no := gn_line_data_no + 1;
        END LOOP line_set_loop;
      END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--
    END LOOP header_loop;
--
  EXCEPTION
    WHEN no_data_extract THEN
      --�L�[�ҏW�֐�
      xxcos_common_pkg.makeup_key_info(
                                         lv_key_name1,
                                         lv_key_data1,
                                         lv_key_name2,
                                         lv_key_data2,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         gv_tkn2,
                                         lv_errbuf,
                                         lv_retcode,
                                         lv_errmsg);  
      --���b�Z�[�W����
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_no_data,
                                             cv_tkn_table_name, gv_tkn1,
                                             cv_key_data, gv_tkn2 );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--    WHEN delivered_from_err_expt THEN
--      --
--      lv_errmsg := xxccp_common_pkg.get_msg( cv_application,cv_msg_delivered_from_err );
----      lv_errbuf := lv_errmsg;
--      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
--      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;                                            --# �C�� #
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
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
  END proc_molded_edi;
--
  /**********************************************************************************
   * Procedure Name   : proc_inp_molded_hht
   * Description      : �̔����уf�[�^(�[�i�`�[���͉��)���^����(A-9)
   ***********************************************************************************/
  PROCEDURE proc_inp_molded_hht(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_inp_molded_hht'; -- �v���O������
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
    --�[�i�w�b�_(HHT)�i�[�p�ϐ�
    lt_order_no_hht              xxcos_dlv_headers.order_no_hht%TYPE;             -- ��No.(HHT)
    lt_digestion_ln_number       xxcos_dlv_headers.digestion_ln_number%TYPE;      -- �}��
    lt_order_no_ebs              xxcos_dlv_headers.order_no_ebs%TYPE;             -- ��No.�iEBS�j
    lt_base_code                 xxcos_dlv_headers.base_code%TYPE;                -- ���_�R�[�h
    lt_performance_by_code       xxcos_dlv_headers.performance_by_code%TYPE;      -- ���ю҃R�[�h
    lt_dlv_by_code               xxcos_dlv_headers.dlv_by_code%TYPE;              -- �[�i�҃R�[�h
    lt_hht_invoice_no            xxcos_dlv_headers.hht_invoice_no%TYPE;           -- HHT�`�[No.
    lt_dlv_date                  xxcos_dlv_headers.dlv_date%TYPE;                 -- �[�i��
    lt_inspect_date              xxcos_dlv_headers.inspect_date%TYPE;             -- ������
    lt_sales_classification      xxcos_dlv_headers.sales_classification%TYPE;     -- ���㕪�ދ敪
    lt_sales_invoice             xxcos_dlv_headers.sales_invoice%TYPE;            -- ����`�[�敪
    lt_card_sale_class           xxcos_dlv_headers.card_sale_class%TYPE;          -- �J�[�h����敪
    lt_dlv_time                  xxcos_dlv_headers.dlv_time%TYPE;                 -- ����
    lt_customer_number           xxcos_dlv_headers.customer_number%TYPE;          -- �ڋq�R�[�h
    lt_change_out_time_100       xxcos_dlv_headers.change_out_time_100%TYPE;      -- ��K�؂ꎞ��100�~
    lt_change_out_time_10        xxcos_dlv_headers.change_out_time_10%TYPE;       -- ��K�؂ꎞ��10�~
    lt_system_class              xxcos_dlv_headers.system_class%TYPE;             -- �Ƒԋ敪
    lt_input_class               xxcos_dlv_headers.input_class%TYPE;              -- ���͋敪
    lt_consumption_tax_class     xxcos_dlv_headers.consumption_tax_class%TYPE;    -- ����ŋ敪
    lt_total_amount              xxcos_dlv_headers.total_amount%TYPE;             -- ���v���z
    lt_sale_discount_amount      xxcos_dlv_headers.sale_discount_amount%TYPE;     -- ����l���z
    lt_sales_consumption_tax     xxcos_dlv_headers.sales_consumption_tax%TYPE;    -- �������Ŋz
    lt_tax_include               xxcos_dlv_headers.tax_include%TYPE;              -- �ō����z
    lt_keep_in_code              xxcos_dlv_headers.keep_in_code%TYPE;             -- �a����R�[�h
    lt_department_screen_class   xxcos_dlv_headers.department_screen_class%TYPE;  -- �S�ݓX��ʎ��
    lt_stock_forward_flag        xxcos_dlv_headers.stock_forward_flag%TYPE;       -- ���o�ɓ]���t���O
    lt_stock_forward_date        xxcos_dlv_headers.stock_forward_date%TYPE;       -- ���o�ɓ]���ϓ��t
    lt_results_forward_flag      xxcos_dlv_headers.results_forward_flag%TYPE;     -- �̔����јA�g�σt���O
    lt_results_forward_date      xxcos_dlv_headers.results_forward_date%TYPE;     -- �̔����јA�g�ϓ��t
    lt_cancel_correct_class      xxcos_dlv_headers.cancel_correct_class%TYPE;     -- ����E�����敪
    lt_red_black_flag            xxcos_dlv_headers.red_black_flag%TYPE;           -- �ԍ��t���O
    --�[�i����(HHT)�i�[�p�ϐ�
    lt_lin_order_no_hht          xxcos_dlv_lines.order_no_hht%TYPE;               -- ��No.�iHHT�j
    lt_lin_line_no_hht           xxcos_dlv_lines.line_no_hht%TYPE;                -- �sNo.�iHHT�j
    lt_lin_digestion_ln_number   xxcos_dlv_lines.digestion_ln_number%TYPE;        -- �}��
    lt_lin_order_no_ebs          xxcos_dlv_lines.order_no_ebs%TYPE;               -- ��No.�iEBS�j
    lt_lin_line_number_ebs       xxcos_dlv_lines.line_number_ebs%TYPE;            -- ���הԍ��iEBS�j
    lt_lin_item_code_self        xxcos_dlv_lines.item_code_self%TYPE;             -- �i���R�[�h�i���Ёj
    lt_lin_content               xxcos_dlv_lines.content%TYPE;                    -- ����
    lt_lin_inventory_item_id     xxcos_dlv_lines.inventory_item_id%TYPE;          -- �i��ID
    lt_lin_standard_unit         xxcos_dlv_lines.standard_unit%TYPE;              -- ��P��
    lt_lin_case_number           xxcos_dlv_lines.case_number%TYPE;                -- �P�[�X��
    lt_lin_quantity              xxcos_dlv_lines.quantity%TYPE;                   -- ����
    lt_lin_sale_class            xxcos_dlv_lines.sale_class%TYPE;                 -- ����敪
    lt_lin_wholesale_unit_ploce  xxcos_dlv_lines.wholesale_unit_ploce%TYPE;       -- ���P��
    lt_lin_selling_price         xxcos_dlv_lines.selling_price%TYPE;              -- ���P��
    lt_lin_column_no             xxcos_dlv_lines.column_no%TYPE;                  -- �R����No.
    lt_lin_h_and_c               xxcos_dlv_lines.h_and_c%TYPE;                    -- H/C
    lt_lin_sold_out_class        xxcos_dlv_lines.sold_out_class%TYPE;             -- ���؋敪
    lt_lin_sold_out_time         xxcos_dlv_lines.sold_out_time%TYPE;              -- ���؎���
    lt_lin_replenish_number      xxcos_dlv_lines.replenish_number%TYPE;           -- ��[��
    lt_lin_cash_and_card         xxcos_dlv_lines.cash_and_card%TYPE;              -- �����E�J�[�h���p�z
    -- ���̑�
    lt_dlv_base_code             xxcos_rs_info_v.base_code%TYPE;                  -- ���_�R�[�h
    lt_old_sales_cost            ic_item_mst_b.attribute7%TYPE;                   -- ���c�ƌ���
    lt_new_sales_cost            ic_item_mst_b.attribute8%TYPE;                   -- �V�c�ƌ���
    lt_st_sales_cost             ic_item_mst_b.attribute9%TYPE;                   -- �c�ƌ����K�p�J�n��
--
    ln_line_no                   NUMBER :=  1;                                    -- ���׃`�F�b�N�ϔԍ�
    ln_all_tax_amount            NUMBER :=  0;                                    -- ����ŋ��z���v�l
    ln_max_tax_data              NUMBER :=  0;                                    -- ���׍ő����Ŋz
    ln_actual_id                 NUMBER;                                          -- �̔����уw�b�_ID
--    ln_sales_amount              NUMBER;                                          -- ������z
--    ln_consum_amount             NUMBER;                                          -- ����ŋ��z
--    ln_tax_odd                   NUMBER;                                          -- ����Œ[��
--    ln_up_odd                    NUMBER;                                          -- �[���؂�グ���l
--    ln_amount_data               NUMBER;                                          -- �{�̋��z
--    lt_lin_sale_amount           NUMBER;                                          -- ������z
    ln_sales_exp_line_id         NUMBER;                                          -- ����ID
    ln_max_invoice_num           NUMBER;                                          -- �l�����חp�[�i���הԍ�
    ld_input_date                DATE;                                            -- HHT�[�i���͓���
    lt_tax_odd                   xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE; -- �ŋ�-�[������
    lt_consum_code               fnd_lookup_values.attribute2%TYPE;               -- ����ŃR�[�h
    lt_consum_type               fnd_lookup_values.attribute3%TYPE;               -- �̔����јA�g���̏���ŋ敪
    lt_tax_consum                ar_vat_tax_all_b.tax_rate%TYPE;                  -- ����ŗ�
    lt_stand_unit                mtl_system_items_b.primary_unit_of_measure%TYPE; -- ��P��
--    lt_lin_not_tax_amount        xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE; --�Ŕ���P��
    lt_location_type_code        fnd_lookup_values.meaning%TYPE;                  -- �ۊǏꏊ���ރR�[�h(�c�Ǝ�)
    lt_depart_location_type_code fnd_lookup_values.meaning%TYPE;                  -- �ۊǏꏊ���ރR�[�h(�S�ݓX)
    lt_secondary_inventory_name  mtl_secondary_inventories.secondary_inventory_name%TYPE; -- �ۊǏꏊ�R�[�h
    lt_ins_invoice_type          fnd_lookup_values.attribute4%TYPE;               -- �[�i�`�[�敪
    lv_depart_code               xxcmm_cust_accounts.dept_hht_div%TYPE;           -- HHT�S�ݓX���͋敪
    lt_inc_num                   xxcmm_system_items_b.inc_num%TYPE;               -- �������
    lt_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;         -- ���㋒�_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
    lt_cash_receiv_base_code          xxcos_cust_hierarchy_v.cash_receiv_base_code%TYPE;         -- �������_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
    lt_sales_cost                ic_item_mst_b.attribute7%TYPE;                   -- �c�ƌ���
    lt_sale_amount_sum           xxcos_sales_exp_headers.sale_amount_sum%TYPE;    -- ������z���v
    lt_pure_amount_sum           xxcos_sales_exp_headers.pure_amount_sum%TYPE;    -- �{�̋��z���v
    lt_tax_amount_sum            xxcos_sales_exp_headers.tax_amount_sum%TYPE;     -- ����ŋ��z���v
    lt_stand_unit_price_excl     xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE;--�Ŕ���P��
    lt_standard_unit_price       xxcos_sales_exp_lines.standard_unit_price%TYPE;  -- ��P��
    lt_sale_amount               xxcos_sales_exp_lines.sale_amount%TYPE;          -- ������z
    lt_pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE;          -- �{�̋��z
    lt_tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE;           -- ����ŋ��z
--    lt_cust_acct_site_id         hz_cust_acct_sites_all.cust_acct_site_id%TYPE;   -- �ڋq�T�C�gID
--    lt_site_use_code             fnd_lookup_values.meaning%TYPE;                  -- �g�p�敪
    --
    lt_set_replenish_number      xxcos_sales_exp_lines.standard_qty%TYPE;         -- �o�^�p�����(�[�i����)
    lt_set_sale_amount           xxcos_sales_exp_lines.sale_amount%TYPE;          -- �o�^�p������z
    lt_set_pure_amount           xxcos_sales_exp_lines.pure_amount%TYPE;          -- �o�^�p�{�̋��z
    lt_set_tax_amount            xxcos_sales_exp_lines.tax_amount%TYPE;           -- �o�^�p����ŋ��z
    lt_set_sale_amount_sum       xxcos_sales_exp_headers.sale_amount_sum%TYPE;    -- �o�^�p������z���v
    lt_set_pure_amount_sum       xxcos_sales_exp_headers.pure_amount_sum%TYPE;    -- �o�^�p�{�̋��z���v
    lt_set_tax_amount_sum        xxcos_sales_exp_headers.tax_amount_sum%TYPE;     -- �o�^�p����ŋ��z���v
    ln_discount_tax              NUMBER;                                          -- �l������Ŋz
    ln_tax_data                  NUMBER;                                          -- �ō��z�Z�o�p
    ln_max_no_data               NUMBER;                                          -- �w�b�_�ő����Ŗ��׍s�ԍ�
    lv_delivery_type             VARCHAR2(100);                                   -- �[�i�`�ԋ敪
    lv_key_name1                 VARCHAR2(500);                                   -- �L�[�f�[�^����1
    lv_key_name2                 VARCHAR2(500);                                   -- �L�[�f�[�^����2
    lv_key_data1                 VARCHAR2(500);                                   -- �L�[�f�[�^1
    lv_key_data2                 VARCHAR2(500);                                   -- �L�[�f�[�^2
--************************** 2009/03/18 1.5 T.kitajima ADD START ************************************
    ln_amount                    NUMBER;                                          -- ��Ɨp���z�ϐ�
--************************** 2009/03/18 1.5 T.kitajima ADD  END  ************************************
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
    lt_row_id                    ROWID;                                           -- �X�V�p�sID
    lv_state_flg                 VARCHAR2(1);                                     -- �f�[�^�x���m�F�t���O
    ln_line_data_count           NUMBER;                                          -- ���׌���(�w�b�_�P��)
    lv_dept_hht_div_flg          VARCHAR2(1);                                     -- HHT�S�ݓX�敪�G���[�t���O
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--******************************* 2009/05/12 N.Maeda Var1.13 ADD START ***************************************
    lv_edi_order_name            VARCHAR2(100);                                   -- EDI��
--   --****** ���[�U�[��`���[�J���J�[�\�� ********--
    -- OM�󒍃f�[�^�擾�J�[�\��
    CURSOR get_oe_order_cur
    IS
      SELECT ooh.order_number      order_number,            -- �󒍔ԍ�
             ooh.header_id         header_id,               -- �󒍃w�b�_ID
             ooh.flow_status_code  head_flow_status_code,   -- �X�e�[�^�X
             ooh.order_source_id   order_source_id,         -- �󒍃\�[�XID
             ooh.cust_po_number    cust_po_number,          -- �ڋq����
             ool.line_id           line_id,                 -- �󒍖���ID
             ool.flow_status_code  line_flow_status_code    -- �X�e�[�^�X
      FROM   oe_order_headers_all ooh,                      -- OM�󒍃w�b�_
             oe_order_lines_all ool,                        -- OM�󒍖��׃e�[�u��
             oe_order_sources oos                           -- �I�[�_�[�\�[�X
      WHERE  ooh.header_id = ool.header_id
      AND    ooh.order_source_id = oos.order_source_id
      AND    ool.order_source_id = oos.order_source_id
      AND    ooh.org_id = TO_NUMBER ( gv_salse_unit )
      AND    ooh.order_number = lt_order_no_ebs
      AND    ool.flow_status_code NOT IN ( cv_status_type_can , cv_status_type_clo )
      AND    oos.name = lv_edi_order_name
      ORDER BY ooh.order_number,ool.line_id;
--******************************* 2009/05/13 N.Maeda Var1.13 ADD  END  ***************************************
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--******************************* 2009/05/12 N.Maeda Var1.13 ADD START ***************************************
    -- EDI�󒍖��̎擾
    lv_edi_order_name := xxccp_common_pkg.get_msg( cv_application, cv_order_s_name );
--******************************* 2009/05/13 N.Maeda Var1.13 ADD  END  ***************************************
    -- ���[�v�J�n�F�w�b�_��
    <<header_loop>>
    FOR ck_no IN 1..gn_inp_target_cnt LOOP
--
      -- ���הԍ��̏�����
      ln_sales_exp_line_id            := 0;
      -- �Ϗ����ł̏�����
      ln_all_tax_amount               := 0;
      -- �ő����Ŋz�̏�����
      ln_max_tax_data                 := 0;
      -- �ő�sNo
      ln_max_invoice_num              := 0;
      -- �ő喾�הԍ�
      ln_max_no_data                  := 0;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      -- ���׌����J�E���g(������)
      ln_line_data_count              := 0;
      -- �f�[�^�x���m�F�t���O(������)
      lv_state_flg                    := cv_status_normal;
      -- HHT�S�ݓX�敪�G���[(������)
      lv_dept_hht_div_flg             := cv_status_normal;
      lt_row_id                    := gt_inp_dlv_hht_headers_data( ck_no ).row_id;                   -- �sID
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
      lt_order_no_hht              := TRUNC( gt_inp_dlv_hht_headers_data( ck_no ).order_no_hht );    -- ��No.(HHT)
      lt_digestion_ln_number       := gt_inp_dlv_hht_headers_data( ck_no ).digestion_ln_number;      -- �}��
      lt_order_no_ebs              := gt_inp_dlv_hht_headers_data( ck_no ).order_no_ebs;             -- ��No.�iEBS�j
      lt_base_code                 := gt_inp_dlv_hht_headers_data( ck_no ).base_code;                -- ���_�R�[�h
      lt_performance_by_code       := gt_inp_dlv_hht_headers_data( ck_no ).performance_by_code;      -- ���ю҃R�[�h
      lt_dlv_by_code               := gt_inp_dlv_hht_headers_data( ck_no ).dlv_by_code;              -- �[�i�҃R�[�h
      lt_hht_invoice_no            := gt_inp_dlv_hht_headers_data( ck_no ).hht_invoice_no;           -- HHT�`�[No.
      lt_dlv_date                  := gt_inp_dlv_hht_headers_data( ck_no ).dlv_date;                 -- �[�i��
      lt_inspect_date              := gt_inp_dlv_hht_headers_data( ck_no ).inspect_date;             -- ������
      lt_sales_classification      := gt_inp_dlv_hht_headers_data( ck_no ).sales_classification;     -- ���㕪�ދ敪
      lt_sales_invoice             := gt_inp_dlv_hht_headers_data( ck_no ).sales_invoice;            -- ����`�[�敪
      lt_card_sale_class           := gt_inp_dlv_hht_headers_data( ck_no ).card_sale_class;          -- �J�[�h����敪
      lt_dlv_time                  := gt_inp_dlv_hht_headers_data( ck_no ).dlv_time;                 -- ����
      lt_customer_number           := gt_inp_dlv_hht_headers_data( ck_no ).customer_number;          -- �ڋq�R�[�h
      lt_change_out_time_100       := gt_inp_dlv_hht_headers_data( ck_no ).change_out_time_100;      -- ��K�؂ꎞ��100�~
      lt_change_out_time_10        := gt_inp_dlv_hht_headers_data( ck_no ).change_out_time_10;       -- ��K�؂ꎞ��10�~
      lt_system_class              := gt_inp_dlv_hht_headers_data( ck_no ).system_class;             -- �Ƒԋ敪
      lt_input_class               := gt_inp_dlv_hht_headers_data( ck_no ).input_class;              -- ���͋敪
      lt_consumption_tax_class     := gt_inp_dlv_hht_headers_data( ck_no ).consumption_tax_class;    -- ����ŋ敪
      lt_total_amount              := gt_inp_dlv_hht_headers_data( ck_no ).total_amount;             -- ���v���z
      lt_sale_discount_amount      := gt_inp_dlv_hht_headers_data( ck_no ).sale_discount_amount;     -- ����l���z
      lt_sales_consumption_tax     := gt_inp_dlv_hht_headers_data( ck_no ).sales_consumption_tax;    -- �������Ŋz
      lt_tax_include               := gt_inp_dlv_hht_headers_data( ck_no ).tax_include;              -- �ō����z
      lt_keep_in_code              := gt_inp_dlv_hht_headers_data( ck_no ).keep_in_code;             -- �a����R�[�h
      lt_department_screen_class   := gt_inp_dlv_hht_headers_data( ck_no ).department_screen_class;  -- �S�ݓX��ʎ��
      lt_red_black_flag            := gt_inp_dlv_hht_headers_data( ck_no ).red_black_flag;           -- �ԍ��t���O
      lt_stock_forward_flag        := gt_inp_dlv_hht_headers_data( ck_no ).stock_forward_flag;       -- ���o�ɓ]���t���O
      lt_stock_forward_date        := gt_inp_dlv_hht_headers_data( ck_no ).stock_forward_date;       -- ���o�ɓ]���ϓ��t
      lt_results_forward_flag      := gt_inp_dlv_hht_headers_data( ck_no ).results_forward_flag;     -- �̔����јA�g�σt���O
      lt_results_forward_date      := gt_inp_dlv_hht_headers_data( ck_no ).results_forward_date;     -- �̔����јA�g�ϓ��t
      lt_cancel_correct_class      := gt_inp_dlv_hht_headers_data( ck_no ).cancel_correct_class;     -- ����E�����敪
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--      --================================
--      --�̔����уw�b�_ID(�V�[�P���X�擾)
--      --================================
--      SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
--      INTO ln_actual_id
--      FROM DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
--
      --=========================
      --�ڋq�}�X�^�t�я��̓��o
      --=========================
      BEGIN
        SELECT  xca.sale_base_code, --���㋒�_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
                xch.cash_receiv_base_code,  --�������_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
                --hca.tax_rounding_rule --�ŋ�-�[������
                xch.bill_tax_round_rule -- �ŋ�-�[������(�T�C�g)
        INTO    lt_sale_base_code,
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
                lt_cash_receiv_base_code,
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
                lt_tax_odd
        FROM    hz_cust_accounts hca,  --�ڋq�}�X�^
                xxcmm_cust_accounts xca, --�ڋq�ǉ����
                xxcos_cust_hierarchy_v xch -- �ڋq�K�w�r���[
        WHERE   hca.cust_account_id = xca.customer_id
        AND     xch.ship_account_id = hca.cust_account_id
        AND     xch.ship_account_id = xca.customer_id
        AND     hca.account_number = TO_CHAR( lt_customer_number )
        AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
        AND     hca.party_id IN ( SELECT  hpt.party_id
                                  FROM    hz_parties hpt
                                  WHERE   hpt.duns_number_c   IN ( cv_cust_s , cv_cust_v , cv_cost_p ) );
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
          --�L�[�ҏW����
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
--          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code );
--          lv_key_data1 := cv_customer_type_c||cv_con_char||cv_customer_type_u;
--          lv_key_data2 := lt_customer_number;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type ), -- ���ږ��̂P
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code ), -- ���ږ��̂Q
            iv_data_value1 => ( cv_customer_type_c||cv_con_char||cv_customer_type_u ),         -- �f�[�^�̒l�P
            iv_data_value2 => lt_customer_number,       -- �f�[�^�̒l�Q
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
      END;
--
      -- ========================
      -- ����ŃR�[�h�̓��o(HHT)
      -- ========================
      BEGIN
        SELECT  look_val.attribute2,  --����ŃR�[�h
                look_val.attribute3   --�̔����јA�g���̏���ŋ敪
        INTO    lt_consum_code,
                lt_consum_type
        FROM    fnd_lookup_values     look_val,
                fnd_lookup_types_tl   types_tl,
                fnd_lookup_types      types,
                fnd_application_tl    appl,
                fnd_application       app
        WHERE   appl.application_id   = types.application_id
        AND     app.application_id    = appl.application_id
        AND     types_tl.lookup_type  = look_val.lookup_type
        AND     types.lookup_type     = types_tl.lookup_type
        AND     types.security_group_id   = types_tl.security_group_id
        AND     types.view_application_id = types_tl.view_application_id
        AND     types_tl.language = USERENV( 'LANG' )
        AND     look_val.language = USERENV( 'LANG' )
        AND     appl.language     = USERENV( 'LANG' )
        AND     app.application_short_name = cv_application
        AND     gd_process_date      >= look_val.start_date_active
        AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
        AND     look_val.enabled_flag = cv_tkn_yes
        AND     look_val.lookup_type = cv_lookup_type
        AND     look_val.lookup_code = lt_consumption_tax_class;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��          
          gv_tkn1   := xxccp_common_pkg.get_msg(cv_application, cv_msg_lookup_mst );
          --�L�[�ҏW����
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code );
--          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type );
--          lv_key_data1 := lt_consumption_tax_class;
--          lv_key_data2 := cv_lookup_type;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code ), -- ���ږ��̂P
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type ), -- ���ږ��̂Q
            iv_data_value1 => lt_consumption_tax_class,         -- �f�[�^�̒l�P
            iv_data_value2 => cv_lookup_type,       -- �f�[�^�̒l�Q
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
      END;
--
      --====================
      --����Ń}�X�^���擾
      --====================
      BEGIN
        SELECT avtab.tax_rate           -- ����ŗ�
        INTO   lt_tax_consum 
        FROM   ar_vat_tax_all_b avtab   -- AR����Ń}�X�^
        WHERE  avtab.tax_code = lt_consum_code
        AND    avtab.set_of_books_id = TO_NUMBER( gv_bks_id )
/*--==============2009/2/4-START=========================--*/
        AND    NVL( avtab.start_date, gd_process_date ) <= gd_process_date
        AND    NVL( avtab.end_date, gd_max_date ) >= gd_process_date
/*--==============2009/2/4-END==========================--*/
/*--==============2009/2/17-START=========================--*/
        AND    avtab.enabled_flag = cv_tkn_yes;
/*--==============2009/2/17--END==========================--*/
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��          
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_ar_tax_mst );
          --�L�[�ҏW����
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax );
--          lv_key_name2 := NULL;
--          lv_key_data1 := lt_consum_code;
--          lv_key_data2 := NULL;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax ), -- ���ږ��̂P
            iv_data_value1 => lt_consum_code,         -- �f�[�^�̒l�P
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
      END;
      -- ����ŗ��Z�o
      ln_tax_data := ( (100 + lt_tax_consum) / 100 );
--
      -- =========================
      -- HHT�[�i���͓����̐��^����
      -- =========================
      ld_input_date :=TO_DATE(TO_CHAR( lt_dlv_date, cv_short_day )||cv_space_char||
                              SUBSTR(lt_dlv_time,1,2)||cv_tkn_ti||SUBSTR(lt_dlv_time,3,2), cv_stand_date );
--
      -- ==================================
      -- �o�׌��ۊǏꏊ�̓��o
      -- ==================================
--
      --�o�׌��ۊǏꏊ�̓��o
      BEGIN
        SELECT xca.dept_hht_div   -- HHT�S�ݓX���͋敪
        INTO   lv_depart_code
        FROM   hz_cust_accounts hca,  -- �ڋq�}�X�^
               xxcmm_cust_accounts xca  -- �ڋq�ǉ����
        WHERE  hca.cust_account_id = xca.customer_id
        AND    hca.account_number = lt_base_code
        AND    hca.customer_class_code = cv_bace_branch;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��          
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
          --�L�[�ҏW����
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
--          lv_key_data1 := lt_base_code;
--          lv_key_data2 := cv_bace_branch;
--        RAISE no_data_extract;
          lv_dept_hht_div_flg := cv_status_warn;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- ���ږ��̂P
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type ), -- ���ږ��̂Q
            iv_data_value1 => lt_base_code,         -- �f�[�^�̒l�P
            iv_data_value2 => cv_bace_branch,       -- �f�[�^�̒l�Q
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
      END;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      IF (lv_dept_hht_div_flg <> cv_status_warn) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
/*--==============2009/2/3-START=========================--*/
--      IF ( lv_depart_code = cv_depart_car ) THEN
        IF ( lv_depart_code IS NULL )
          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_base ) ) THEN
/*--==============2009/2/3-END==========================--*/
          --�Q�ƃR�[�h�}�X�^�F�c�ƎԂ̕ۊǏꏊ���ރR�[�h�擾
          BEGIN
            SELECT  look_val.meaning      --�ۊǏꏊ���ރR�[�h
            INTO    lt_location_type_code
            FROM    fnd_lookup_values     look_val,
                    fnd_lookup_types_tl   types_tl,
                    fnd_lookup_types      types,
                    fnd_application_tl    appl,
                    fnd_application       app
            WHERE   appl.application_id   = types.application_id
            AND     app.application_id    = appl.application_id
            AND     types_tl.lookup_type  = look_val.lookup_type
            AND     types.lookup_type     = types_tl.lookup_type
            AND     types.security_group_id   = types_tl.security_group_id
            AND     types.view_application_id = types_tl.view_application_id
            AND     types_tl.language = USERENV( 'LANG' )
            AND     look_val.language = USERENV( 'LANG' )
            AND     appl.language     = USERENV( 'LANG' )
            AND     gd_process_date      >= look_val.start_date_active
            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
            AND     app.application_short_name = cv_application
            AND     look_val.enabled_flag = cv_tkn_yes
            AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
            AND     look_val.lookup_code = cv_xxcos_001_a05_05;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
              --�L�[�ҏW�����p�ϐ�
              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_type );
              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_code );
              lv_key_data1 := cv_xxcos1_hokan_mst_001_a05;
              lv_key_data2 := cv_xxcos_001_a05_05;
            RAISE no_data_extract;
          END;
--
          --�ۊǏꏊ�}�X�^�f�[�^�擾
          BEGIN
            SELECT msi.secondary_inventory_name     -- �ۊǏꏊ�R�[�h
            INTO   lt_secondary_inventory_name
            FROM   mtl_secondary_inventories msi    --�ۊǏꏊ�}�X�^
            WHERE  msi.attribute7 = lt_base_code
            AND    msi.attribute13 = lt_location_type_code
            AND    msi.attribute3 = lt_dlv_by_code;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
              --�L�[�ҏW�����p�ϐ�
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--            lv_key_data1 := lt_base_code;
--            lv_key_data2 := cv_xxcos_001_a05_05;
--            RAISE no_data_extract;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            xxcos_common_pkg.makeup_key_info(
              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- ���ږ��̂P
              iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- ���ږ��̂Q
              iv_data_value1 => lt_base_code,         -- �f�[�^�̒l�P
              iv_data_value2 => cv_xxcos_001_a05_05,       -- �f�[�^�̒l�Q
              ov_key_info    => gv_tkn2,              -- �L�[���
              ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
              ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
              ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                  iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                  iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                  iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                  iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                  iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                  iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   *****************************************
          END;
--
/*--==============2009/2/3-START=========================--*/
--      ELSIF ( lv_depart_code = cv_depart_type ) THEN
--      ELSIF ( lv_depart_code IS NOT NULL ) THEN
        ELSIF ( lv_depart_code = cv_depart_type ) 
          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_dep ) )THEN
/*--==============2009/2/3-END==========================--*/
          --�Q�ƃR�[�h�}�X�^�F�S�ݓX�̕ۊǏꏊ���ރR�[�h�擾
          BEGIN
            SELECT  look_val.meaning    --�ۊǏꏊ���ރR�[�h
            INTO    lt_depart_location_type_code
            FROM    fnd_lookup_values     look_val,
                    fnd_lookup_types_tl   types_tl,
                    fnd_lookup_types      types,
                    fnd_application_tl    appl,
                    fnd_application       app
            WHERE   appl.application_id   = types.application_id
            AND     app.application_id    = appl.application_id
            AND     types_tl.lookup_type  = look_val.lookup_type
            AND     types.lookup_type     = types_tl.lookup_type
            AND     types.security_group_id   = types_tl.security_group_id
            AND     types.view_application_id = types_tl.view_application_id
            AND     types_tl.language = USERENV( 'LANG' )
            AND     look_val.language = USERENV( 'LANG' )
            AND     appl.language     = USERENV( 'LANG' )
            AND     gd_process_date      >= look_val.start_date_active
            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
            AND     app.application_short_name = cv_application
            AND     look_val.enabled_flag = cv_tkn_yes
            AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
            AND     look_val.lookup_code = cv_xxcos_001_a05_09;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              --�L�[�ҏW����
              -- ���O�o��          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
              --�L�[�ҏW�����p�ϐ��ݒ�
              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_type );
              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_code );
              lv_key_data1 := cv_xxcos1_hokan_mst_001_a05;
              lv_key_data2 := cv_xxcos_001_a05_09;
            RAISE no_data_extract;
          END;
--
          --�ۊǏꏊ�}�X�^�f�[�^�擾
          BEGIN
            SELECT msi.secondary_inventory_name           -- �ۊǏꏊ����
            INTO   lt_secondary_inventory_name
            FROM   mtl_secondary_inventories msi,         -- �ۊǏꏊ�}�X�^
                   mtl_parameters mp                      -- �g�D�p�����[�^
            WHERE  msi.organization_id=mp.organization_id
            AND    mp.organization_code = gv_orga_code
            AND    msi.attribute4       = lt_keep_in_code
            AND    msi.attribute13      = lt_depart_location_type_code;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
              --�L�[�ҏW�����p�ϐ��ݒ�
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--            lv_key_data1 := lt_base_code;
--            lv_key_data2 := cv_xxcos_001_a05_09;
--            RAISE no_data_extract;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- ���ږ��̂P
                iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- ���ږ��̂Q
                iv_data_value1 => lt_base_code,         -- �f�[�^�̒l�P
                iv_data_value2 => cv_xxcos_001_a05_09,       -- �f�[�^�̒l�Q
                ov_key_info    => gv_tkn2,              -- �L�[���
                ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
                ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
                ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                  iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                  iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                  iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                  iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                  iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                  iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
          END;
--
        END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--
      -- =============
      -- �[�i�`�ԋ敪�̓��o
      -- =============
      xxcos_common_pkg.get_delivered_from( lt_secondary_inventory_name,
                                           lt_base_code, 
                                           lt_base_code, 
                                           gv_orga_code,
                                           gn_orga_id,
                                           lv_delivery_type,
                                           lv_errbuf,
                                           lv_retcode,
                                           lv_errmsg );
      IF ( lv_retcode <> cv_status_normal ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--        RAISE delivered_from_err_expt;
      lv_state_flg    := cv_status_warn;
      gn_wae_data_num := gn_wae_data_num + 1 ;
      gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,
                                                iv_name          => cv_msg_delivered_from_err );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
      END IF;
--
      -- ===================
      -- �[�i���_�̓��o
      -- ===================
      BEGIN
        SELECT rin_v.base_code  --���_�R�[�h
        INTO lt_dlv_base_code
        FROM xxcos_rs_info_v rin_v   --�]�ƈ����view
        WHERE rin_v.employee_number = lt_dlv_by_code
/*--==============2009/2/3-START=========================--*/
        AND   NVL( rin_v.effective_start_date, lt_dlv_date ) <= lt_dlv_date
        AND   NVL( rin_v.effective_end_date, lt_dlv_date )  >= lt_dlv_date;
/*--==============2009/2/3-END=========================--*/
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- ���O�o��          
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_emp_data_mst );
            --�L�[�ҏW�p�ϐ��ݒ�
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv );
--            lv_key_name2 := NULL;
--            lv_key_data1 := lt_dlv_by_code;
--            lv_key_data2 := NULL;
--         RAISE no_data_extract;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            xxcos_common_pkg.makeup_key_info(
              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv ), -- ���ږ��̂P
              iv_data_value1 => lt_dlv_by_code,         -- �f�[�^�̒l�P
              ov_key_info    => gv_tkn2,              -- �L�[���
              ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
              ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
              ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
      END;
--
        -- =====================
        -- �[�i�`�[���͋敪�̓��o
        -- =====================
          BEGIN
            SELECT  DECODE( lt_cancel_correct_class, 
                            cv_stand_class, look_val.attribute4,    -- ����E�����敪���NULL�(�ʏ펞)(�̔����ѓ��͋敪)
                            cn_correct_class, look_val.attribute5,  -- ����E�����敪���1�(����)(�̔����ѓ��͋敪)
                            cn_cancel_class, look_val.attribute5)   -- ����E�����敪���2�(���)(�̔����ѓ��͋敪)
            INTO    lt_ins_invoice_type
            FROM    fnd_lookup_values     look_val,
                    fnd_lookup_types_tl   types_tl,
                    fnd_lookup_types      types,
                    fnd_application_tl    appl,
                    fnd_application       app
            WHERE   appl.application_id   = types.application_id
            AND     app.application_id    = appl.application_id
            AND     types_tl.lookup_type  = look_val.lookup_type
            AND     types.lookup_type     = types_tl.lookup_type
            AND     types.security_group_id   = types_tl.security_group_id
            AND     types.view_application_id = types_tl.view_application_id
            AND     types_tl.language = USERENV( 'LANG' )
            AND     look_val.language = USERENV( 'LANG' )
            AND     appl.language     = USERENV( 'LANG' )
            AND     gd_process_date      >= look_val.start_date_active
            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
            AND     app.application_short_name = cv_application
            AND     look_val.enabled_flag = cv_tkn_yes
            AND     look_val.lookup_type = cv_xxcos1_input_class
            AND     look_val.lookup_code = lt_input_class;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
              --�L�[�ҏW�\�ϐ��ݒ�
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
--              lv_key_name2 := NULL;
--              lv_key_data1 := lt_input_class;
--              lv_key_data2 := NULL;
--            RAISE no_data_extract;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            xxcos_common_pkg.makeup_key_info(
              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp ), -- ���ږ��̂P
              iv_data_value1 => lt_input_class,         -- �f�[�^�̒l�P
              ov_key_info    => gv_tkn2,              -- �L�[���
              ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
              ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
              ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
          END;
--
      --���׃f�[�^�擾
      <<line_loop>>
      FOR line_no IN ln_line_no..gn_inp_line_cnt LOOP
        lt_lin_order_no_hht          := TRUNC( gt_inp_dlv_hht_lines_data( line_no ).order_no_hht );          -- ��No.�iHHT�j
        lt_lin_line_no_hht           := gt_inp_dlv_hht_lines_data( line_no ).line_no_hht;           -- �sNo.�iHHT�j
        lt_lin_digestion_ln_number   := gt_inp_dlv_hht_lines_data( line_no ).digestion_ln_number;   -- �}��
        lt_lin_order_no_ebs          := gt_inp_dlv_hht_lines_data( line_no ).order_no_ebs;          -- ��No.�iEBS�j
        lt_lin_line_number_ebs       := gt_inp_dlv_hht_lines_data( line_no ).line_number_ebs;       -- ���הԍ��iEBS�j
        lt_lin_item_code_self        := gt_inp_dlv_hht_lines_data( line_no ).item_code_self;        -- �i���R�[�h�i���Ёj
        lt_lin_content               := gt_inp_dlv_hht_lines_data( line_no ).content;               -- ����
        lt_lin_inventory_item_id     := gt_inp_dlv_hht_lines_data( line_no ).inventory_item_id;     -- �i��ID
        lt_lin_standard_unit         := gt_inp_dlv_hht_lines_data( line_no ).standard_unit;         -- ��P��
        lt_lin_case_number           := gt_inp_dlv_hht_lines_data( line_no ).case_number;           -- �P�[�X��
        lt_lin_quantity              := gt_inp_dlv_hht_lines_data( line_no ).quantity;              -- ����
        lt_lin_sale_class            := gt_inp_dlv_hht_lines_data( line_no ).sale_class;            -- ����敪
        lt_lin_wholesale_unit_ploce  := gt_inp_dlv_hht_lines_data( line_no ).wholesale_unit_ploce;  -- ���P��
        lt_lin_selling_price         := gt_inp_dlv_hht_lines_data( line_no ).selling_price;         -- ���P��
        lt_lin_column_no             := gt_inp_dlv_hht_lines_data( line_no ).column_no;             -- �R����No.
        lt_lin_h_and_c               := gt_inp_dlv_hht_lines_data( line_no ).h_and_c;               -- H/C
        lt_lin_sold_out_class        := gt_inp_dlv_hht_lines_data( line_no ).sold_out_class;        -- ���؋敪
        lt_lin_sold_out_time         := gt_inp_dlv_hht_lines_data( line_no ).sold_out_time;         -- ���؎���
        lt_lin_replenish_number      := gt_inp_dlv_hht_lines_data( line_no ).replenish_number;      -- ��[��
        lt_lin_cash_and_card         := gt_inp_dlv_hht_lines_data( line_no ).cash_and_card;         -- �����E�J�[�h���p�z
--
        EXIT WHEN ( ( lt_order_no_hht || lt_digestion_ln_number ) <> ( lt_lin_order_no_hht || lt_lin_digestion_ln_number ) );
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        ln_line_data_count := ln_line_data_count + 1;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--        -- ===================
--        -- �o�^�p����ID�擾
--        -- ===================
--        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
--        INTO   ln_sales_exp_line_id
--        FROM   DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
--
        --====================================
        --�c�ƌ����̓��o(�̔����і���(�R����))
        --====================================
        BEGIN
          SELECT ic_item.attribute7,              -- ���c�ƌ���
                 ic_item.attribute8,              -- �V�c�ƌ���
                 ic_item.attribute9,              -- �c�ƌ����K�p�J�n��
                 mtl_item.primary_unit_of_measure,     -- ��P��
                 cmm_item.inc_num                  -- �������
          INTO   lt_old_sales_cost,
                 lt_new_sales_cost,
                 lt_st_sales_cost,
                 lt_stand_unit,
                 lt_inc_num
          FROM   mtl_system_items_b    mtl_item,    -- �i��
                 ic_item_mst_b         ic_item,     -- OPM�i��
                 xxcmm_system_items_b  cmm_item     -- Disc�i�ڃA�h�I��
          WHERE  mtl_item.organization_id   = gn_orga_id
          AND  mtl_item.segment1 = lt_lin_item_code_self
          AND  mtl_item.segment1 = ic_item.item_no
          AND  mtl_item.segment1 = cmm_item.item_code
          AND  cmm_item.item_id  = ic_item.item_id
/*--==============2009/2/4-START=========================--*/
          AND    NVL( mtl_item.start_date_active, gd_process_date) <= gd_process_date
          AND    NVL( mtl_item.end_date_active, gd_max_date ) >= gd_process_date;
/*--==============2009/2/4-END==========================--*/
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --�L�[�ҏW����
            -- ���O�o��
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_inv_item_mst );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
--            lv_key_data1 := lt_lin_item_code_self;
--            lv_key_data2 := gn_orga_id;
--            RAISE no_data_extract;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            xxcos_common_pkg.makeup_key_info(
              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code ), -- ���ږ��̂P
              iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id ), -- ���ږ��̂Q
              iv_data_value1 => lt_lin_item_code_self,         -- �f�[�^�̒l�P
              iv_data_value2 => gn_orga_id,       -- �f�[�^�̒l�Q
              ov_key_info    => gv_tkn2,              -- �L�[���
              ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
              ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
              ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
        END;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        IF ( lv_state_flg <> cv_status_warn ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
          -- ===================================
          -- �c�ƌ�������
          -- ===================================
          IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_dlv_date ) THEN
            lt_sales_cost := lt_old_sales_cost;
          ELSE
            lt_sales_cost := lt_new_sales_cost;
          END IF;
--
          -- ============
          -- ���׋��z�Z�o
          -- ============
          -- ��P��
          lt_standard_unit_price   := lt_lin_wholesale_unit_ploce;
--
          IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- ��ې�
--
            -- ������z
            lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
            -- �{�̋��z
            lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- ����ŋ��z
            lt_tax_amount            := cn_cons_tkn_zero;
--
          ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
            -- ������z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_sale_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
--                                        * ln_tax_data );
--          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_sale_amount := TRUNC( lt_sale_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount := ROUND( lt_sale_amount );
--            END IF;
--          END IF;
            ln_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_sale_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_sale_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_sale_amount := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
            -- �{�̋��z
            lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- ����ŋ��z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_tax_amount            := (  ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
--          IF ( lt_tax_amount <> TRUNC( lt_tax_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_tax_amount := ( TRUNC( lt_tax_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_tax_amount := TRUNC( lt_tax_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_tax_amount := ROUND( lt_tax_amount );
--            END IF;
--          END IF;
            ln_amount            := (  ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_tax_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_tax_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_tax_amount := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
--
          ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
            -- ������z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_sale_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
--                                        * ln_tax_data );
--          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_sale_amount := TRUNC( lt_sale_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount := ROUND( lt_sale_amount );
--            END IF;
--          END IF;
            ln_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_sale_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_sale_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_sale_amount := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
            -- �{�̋��z
            lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- ����ŋ��z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_tax_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
--          IF ( lt_tax_amount <> TRUNC( lt_tax_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_tax_amount := ( TRUNC( lt_tax_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_tax_amount := TRUNC( lt_tax_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_tax_amount := ROUND( lt_tax_amount );
--            END IF;
--          END IF;
            ln_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_tax_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_tax_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_tax_amount := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
--
          ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--
            -- ������z
            lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- �Ŕ���P��
            ln_amount := ( lt_lin_wholesale_unit_ploce / ln_tax_data );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_stand_unit_price_excl := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_stand_unit_price_excl := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_stand_unit_price_excl := ROUND( ln_amount );
              END IF;
            ELSE
              lt_stand_unit_price_excl := ln_amount;
            END IF;
            -- �{�̋��z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_pure_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
--          IF ( lt_pure_amount <> TRUNC( lt_pure_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_pure_amount := ( TRUNC( lt_pure_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_pure_amount := TRUNC( lt_pure_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_pure_amount := ROUND( lt_pure_amount );
--            END IF;
--          END IF;
            ln_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_pure_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_pure_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_pure_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_pure_amount := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- ����ŋ��z
            lt_tax_amount            := TRUNC( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
                                           - lt_pure_amount );
--
          END IF;
--
          -- ��ېŎ��ȊO
          IF ( lt_consumption_tax_class <> cv_non_tax ) THEN
            -- ����ō��v�Ϗグ
              ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
            -- ���׍ő����Ŏ擾
            IF ( ln_max_tax_data < lt_tax_amount ) THEN
              ln_max_tax_data := lt_tax_amount;
--******************************* 2009/04/21 N.Maeda Var1.10 MOD START ***************************************
             -- ln_max_no_data  := gn_line_data_no;
              ln_max_no_data  := ln_line_data_count;
--******************************* 2009/04/21 N.Maeda Var1.10 MOD END   ***************************************
            END IF;
          END IF;
--
          -- ���׍ő�sNo�m�F
          IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
            IF ( ln_max_invoice_num IS NULL) OR ( ln_max_invoice_num < lt_lin_line_no_hht ) THEN
              ln_max_invoice_num := lt_lin_line_no_hht;
            END IF;
          END IF;
--
          -- �ԁE���̋��z���Z
          --���̎�
          IF ( lt_red_black_flag = cv_black_flag) THEN
            -- �����(�[�i����)
            lt_set_replenish_number := lt_lin_replenish_number;
            -- ������z
            lt_set_sale_amount := lt_sale_amount;
            -- �{�̋��z
            lt_set_pure_amount := lt_pure_amount;
            -- ����ŋ��z
            lt_set_tax_amount := lt_tax_amount;
          -- �Ԃ̎�
          ELSIF ( lt_red_black_flag = cv_red_flag) THEN
            -- �����(�[�i����)
            lt_set_replenish_number := ( lt_lin_replenish_number * ( -1 ) );
            -- ������z
            lt_set_sale_amount := ( lt_sale_amount * ( -1 ) );
            -- �{�̋��z
            lt_set_pure_amount := ( lt_pure_amount * ( -1 ) );
            -- ����ŋ��z
            lt_set_tax_amount := ( lt_tax_amount * ( -1 ) );
          END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--        --====================
--        --���׃f�[�^�̕ϐ��}��
--        --====================
--        gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- �̔����і���ID
--        gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- �̔����уw�b�_ID
--        gt_line_dlv_invoice_number( gn_line_data_no )      := lt_hht_invoice_no;            -- �[�i�`�[�ԍ�
--        gt_line_dlv_invoice_l_num( gn_line_data_no )       := lt_lin_line_no_hht;           -- �[�i���הԍ�
--        gt_line_sales_class( gn_line_data_no )             := lt_lin_sale_class;            -- ����敪
--        gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;            -- �ԍ��t���O
--        gt_line_item_code( gn_line_data_no )               := lt_lin_item_code_self;        -- �i�ڃR�[�h
--        gt_line_standard_qty( gn_line_data_no )            := lt_set_replenish_number;      -- �����
--        gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;                -- ��P��
--        gt_line_standard_unit_price( gn_line_data_no )     := lt_standard_unit_price;       -- ��P��
--        gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero ); -- �c�ƌ���
--        gt_line_sale_amount( gn_line_data_no )             := lt_set_sale_amount;           -- ������z
--        gt_line_pure_amount( gn_line_data_no )             := lt_set_pure_amount;           -- �{�̋��z
--        gt_line_tax_amount( gn_line_data_no )              := lt_set_tax_amount;            -- ����ŋ��z
--        gt_line_cash_and_card( gn_line_data_no )           := lt_lin_cash_and_card;         -- �����E�J�[�h���p�z
--        gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_secondary_inventory_name;  -- �o�׌��ۊǏꏊ
--        gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;             -- �[�i���_�R�[�h
--        gt_line_hot_cold_class( gn_line_data_no )          := lt_lin_h_and_c;               -- �g���b
--        gt_line_column_no( gn_line_data_no )               := lt_lin_column_no;             -- �R����No
--        gt_line_sold_out_class( gn_line_data_no )          := lt_lin_sold_out_class;        -- ���؋敪
--        gt_line_sold_out_time( gn_line_data_no )           := lt_lin_sold_out_time;         -- ���؎���
--        gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                     -- �萔���v�Z-IF�σt���O
--        gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                     -- �P���}�X�^�쐬�σt���O
--        gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                     -- INV-IF�σt���O
--        gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;                  -- �������הԍ�(NULL�ݒ�)
--        gt_line_not_tax_amount( gn_line_data_no )          := lt_stand_unit_price_excl;     -- �Ŕ���P��
--        gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;             -- �[�i�`�ԋ敪
--        gt_line_dlv_qty( gn_line_data_no )                 := lt_set_replenish_number;      -- �[�i����
--        gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;                -- �[�i�P��
--        gt_dlv_unit_price( gn_line_data_no )               := lt_standard_unit_price;       -- �[�i�P��
--        gn_line_data_no := gn_line_data_no + 1;
          -- ===================
          -- �ꎞ�i�[�p
          -- ===================
          gt_accumulation_data(ln_line_data_count).dlv_invoice_number         := lt_hht_invoice_no;             -- �[�i�`�[�ԍ�
          gt_accumulation_data(ln_line_data_count).dlv_invoice_line_number    := lt_lin_line_no_hht;            -- �[�i���הԍ�
          gt_accumulation_data(ln_line_data_count).sales_class                := lt_lin_sale_class;             -- ����敪
          gt_accumulation_data(ln_line_data_count).red_black_flag             := lt_red_black_flag;             -- �ԍ��t���O
          gt_accumulation_data(ln_line_data_count).item_code                  := lt_lin_item_code_self;         -- �i�ڃR�[�h
          gt_accumulation_data(ln_line_data_count).dlv_qty                    := lt_set_replenish_number;       -- �[�i����
          gt_accumulation_data(ln_line_data_count).standard_qty               := lt_set_replenish_number;       -- �����
          gt_accumulation_data(ln_line_data_count).dlv_uom_code               := lt_stand_unit;                 -- �[�i�P��
          gt_accumulation_data(ln_line_data_count).standard_uom_code          := lt_stand_unit;                 -- ��P��
          gt_accumulation_data(ln_line_data_count).dlv_unit_price             := lt_standard_unit_price;        -- �[�i�P��
          gt_accumulation_data(ln_line_data_count).standard_unit_price        := lt_standard_unit_price;        -- ��P��
          gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- �c�ƌ���
          gt_accumulation_data(ln_line_data_count).sale_amount                := lt_set_sale_amount;            -- ������z
          gt_accumulation_data(ln_line_data_count).pure_amount                := lt_set_pure_amount;            -- �{�̋��z
          gt_accumulation_data(ln_line_data_count).tax_amount                 := lt_set_tax_amount;             -- ����ŋ��z
          gt_accumulation_data(ln_line_data_count).cash_and_card              := lt_lin_cash_and_card;          -- �����E�J�[�h���p�z
          gt_accumulation_data(ln_line_data_count).ship_from_subinventory_code := lt_secondary_inventory_name;  -- �o�׌��ۊǏꏊ
          gt_accumulation_data(ln_line_data_count).delivery_base_code         := lt_dlv_base_code;              -- �[�i���_�R�[�h
          gt_accumulation_data(ln_line_data_count).hot_cold_class             := lt_lin_h_and_c;                -- �g���b
          gt_accumulation_data(ln_line_data_count).column_no                  := lt_lin_column_no;              -- �R����No
          gt_accumulation_data(ln_line_data_count).sold_out_class             := lt_lin_sold_out_class;         -- ���؋敪
          gt_accumulation_data(ln_line_data_count).sold_out_time              := lt_lin_sold_out_time;          -- ���؎���
          gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                      -- �萔���v�Z�C���^�t�F�[�X�σt���O
          gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                      -- �P���}�X�^�쐬�σt���O
          gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                      -- INV�C���^�t�F�[�X�σt���O
          gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;                   -- �������הԍ�(NULL�ݒ�)
          gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := lt_stand_unit_price_excl;    -- �Ŕ���P��
          gt_accumulation_data(ln_line_data_count).delivery_pattern_class     :=   lv_delivery_type;            -- �[�i�`�ԋ敪(���o)
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
        ln_line_no := ln_line_no + 1;
--
      END LOOP line_loop;
--
      -- =======================================
      -- �l�����z���א���(A-8)
      -- =======================================
      -- �l�������������Ă���ꍇ
      IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        ln_line_data_count := ln_line_data_count + 1;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--        -- ===================
--        -- �o�^�p����ID�擾
--        -- ===================
--        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
--        INTO   ln_sales_exp_line_id
--        FROM   DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
--
        -- =================================
        -- �c�ƌ����A��P�ʂ𓱏o
        -- =================================
        BEGIN
          SELECT ic_item.attribute7,              -- ���c�ƌ���
                 ic_item.attribute8,              -- �V�c�ƌ���
                 ic_item.attribute9,              -- �c�ƌ����K�p�J�n��
                 mtl_item.primary_unit_of_measure -- ��P��
          INTO   lt_old_sales_cost,
                 lt_new_sales_cost,
                 lt_st_sales_cost,
                 lt_stand_unit
          FROM   mtl_system_items_b    mtl_item,    -- �i��
                 ic_item_mst_b         ic_item,     -- OPM�i��
                 xxcmm_system_items_b  cmm_item     -- Disc�i�ڃA�h�I��
          WHERE  mtl_item.organization_id   = gn_orga_id
          AND  mtl_item.segment1 = gv_disc_item
          AND  mtl_item.segment1 = ic_item.item_no
          AND  mtl_item.segment1 = cmm_item.item_code
          AND  cmm_item.item_id  = ic_item.item_id
/*--==============2009/2/4-START=========================--*/
          AND    NVL( mtl_item.start_date_active, gd_process_date) <= gd_process_date
          AND    NVL( mtl_item.end_date_active, gd_max_date ) >= gd_process_date;
/*--==============2009/2/4-END==========================--*/
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --�L�[�ҏW����
            -- ���O�o��
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_inv_item_mst );
            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
            lv_key_data1 := gv_disc_item;
            lv_key_data2 := gn_orga_id;
            RAISE no_data_extract;
        END;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
        IF ( lv_state_flg <> cv_status_warn ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
          -- ===================================
          -- �c�ƌ�������
          -- ===================================
          IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_dlv_date ) THEN
            lt_sales_cost := lt_old_sales_cost;
          ELSE
            lt_sales_cost := lt_new_sales_cost;
          END IF;
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--/*--==============2009/2/3-START=========================--*/
----        IF ( lv_depart_code = cv_depart_car ) THEN
--        IF ( lv_depart_code IS NULL )
--          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_base ) ) THEN
--/*--==============2009/2/3-END==========================--*/
----
--          --�ۊǏꏊ�}�X�^�f�[�^�擾
--          BEGIN
--            SELECT msi.secondary_inventory_name     -- �ۊǏꏊ�R�[�h
--            INTO   lt_secondary_inventory_name
--            FROM   mtl_secondary_inventories msi    --�ۊǏꏊ�}�X�^
--            WHERE  msi.attribute7 = lt_base_code
--            AND    msi.attribute13 = lt_location_type_code;
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              -- ���O�o��          
--              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
--              --�L�[�ҏW�����p�ϐ�
--              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--              lv_key_data1 := lt_base_code;
--              lv_key_data2 := cv_xxcos_001_a05_05;
--            RAISE no_data_extract;
--          END;
----
--/*--==============2009/2/3-START=========================--*/
----        ELSIF ( lv_depart_code = cv_depart_type ) THEN
----        ELSIF ( lv_depart_code IS NOT NULL ) THEN
--        ELSIF ( lv_depart_code = cv_depart_type ) 
--          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_dep ) )THEN
--/*--==============2009/2/3-END==========================--*/
----
--          --�ۊǏꏊ�}�X�^�f�[�^�擾
--          BEGIN
--            SELECT msi.secondary_inventory_name           -- �ۊǏꏊ����
--            INTO   lt_secondary_inventory_name
--            FROM   mtl_secondary_inventories msi,         -- �ۊǏꏊ�}�X�^
--                   mtl_parameters mp                      -- �g�D�p�����[�^
--            WHERE  msi.organization_id=mp.organization_id
--            AND    mp.organization_code = gv_orga_code
--            AND    msi.attribute4       = lt_keep_in_code
--            AND    msi.attribute13      = lt_depart_location_type_code;
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              -- ���O�o��
--              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
--              --�L�[�ҏW�����p�ϐ��ݒ�
--              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--              lv_key_data1 := lt_base_code;
--              lv_key_data2 := cv_xxcos_001_a05_09;
--            RAISE no_data_extract;
--          END;
----
--        END IF;
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
          -- ================
          -- ���z�Z�o����
          -- ================
          IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- ��ې�
--
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_sale_discount_amount;
            -- ��P��
            lt_standard_unit_price   := lt_sale_discount_amount;
            -- ������z
            lt_sale_amount           := lt_sale_discount_amount;
            -- �{�̋��z
            lt_pure_amount           := lt_sale_discount_amount;
            -- ����ŋ��z
            lt_tax_amount            := ( lt_sale_amount - lt_pure_amount );
--
          ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_sale_discount_amount;
            -- ��P��
            lt_standard_unit_price   := lt_sale_discount_amount;
            -- ������z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_sale_amount           := ( lt_sale_discount_amount * ln_tax_data);
--          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_sale_amount := TRUNC( lt_sale_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount := ROUND( lt_sale_amount );
--            END IF;
--          END IF;
            ln_amount           := lt_sale_discount_amount;
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_sale_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_sale_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_sale_amount := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- �{�̋��z
            lt_pure_amount           := lt_sale_discount_amount;
            -- ����ŋ��z
            ln_amount            := ( lt_sale_amount * ( ln_tax_data - 1 ) );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_tax_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_tax_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_tax_amount := ln_amount;
            END IF;
--
          ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_sale_discount_amount;
            -- ��P��
            lt_standard_unit_price   := ( lt_sale_discount_amount );
            -- ������z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_sale_amount           := ( lt_sale_discount_amount * ln_tax_data);
--          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_sale_amount := TRUNC( lt_sale_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount := ROUND( lt_sale_amount );
--            END IF;
--          END IF;
            ln_amount           := ( lt_sale_discount_amount );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_sale_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_sale_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_sale_amount := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- �{�̋��z
            lt_pure_amount           := lt_sale_discount_amount;
            -- ����ŋ��z
            ln_amount            := ( lt_sale_amount * ( ln_tax_data - 1 ) );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_tax_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_tax_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_tax_amount := ln_amount;
            END IF;
--
          ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--
            -- �Ŕ���P��
            ln_amount := ( lt_sale_discount_amount / ln_tax_data);
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_stand_unit_price_excl := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_stand_unit_price_excl := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_stand_unit_price_excl := ROUND( ln_amount );
              END IF;
            ELSE
              lt_stand_unit_price_excl := ln_amount;
            END IF;
            -- ��P��
            lt_standard_unit_price   := lt_sale_discount_amount;
            -- ������z
            lt_sale_amount           := lt_sale_discount_amount;
            -- �{�̋��z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_pure_amount           := ( lt_sale_discount_amount / ln_tax_data);
--          IF ( lt_pure_amount <> TRUNC( lt_pure_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_pure_amount := ( TRUNC( lt_pure_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_pure_amount := TRUNC( lt_pure_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_pure_amount := ROUND( lt_pure_amount );
--            END IF;
--          END IF;
            ln_amount           := ( lt_sale_discount_amount / ln_tax_data);
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_pure_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_pure_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_pure_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_pure_amount := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- ����ŋ��z
            lt_tax_amount            := ( lt_sale_amount - lt_pure_amount );
          END IF;
--
          -- �l���p�[�i���הԍ��ݒ�
          ln_max_invoice_num := ln_max_invoice_num + 1;
          -- �o�^�p�l�����z�ݒ�
          lt_sale_amount := ( lt_sale_amount * ( -1 ) );
          lt_pure_amount := ( lt_pure_amount * ( -1 ) );
          lt_tax_amount  := ( lt_tax_amount * ( -1 ) );
--
          -- �ԁE���̋��z���Z
          --���̎�
          IF ( lt_red_black_flag = cv_black_flag) THEN
            -- �����(�[�i����)
            lt_set_replenish_number := cn_disc_standard_qty;
            -- ������z
            lt_set_sale_amount := lt_sale_amount;
            -- �{�̋��z
            lt_set_pure_amount := lt_pure_amount;
            -- ����ŋ��z
            lt_set_tax_amount := lt_tax_amount;
          -- �Ԃ̎�
          ELSIF ( lt_red_black_flag = cv_red_flag) THEN
            -- �����(�[�i����)
            lt_set_replenish_number := ( cn_disc_standard_qty * ( -1 ) );
            -- ������z
            lt_set_sale_amount := ( lt_sale_amount * ( -1 ) );
            -- �{�̋��z
            lt_set_pure_amount := ( lt_pure_amount * ( -1 ) );
            -- ����ŋ��z
            lt_set_tax_amount := ( lt_tax_amount * ( -1 ) );
          END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--        -- =========================================
--        -- �l�������׃f�[�^�Z�b�g
--        -- =========================================
--        gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- �̔����і���ID
--        gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- �̔����уw�b�_ID
--        gt_line_dlv_invoice_number( gn_line_data_no )      := lt_hht_invoice_no;            -- �[�i�`�[�ԍ�
--        gt_line_dlv_invoice_l_num( gn_line_data_no )       := ln_max_invoice_num;           -- �[�i���הԍ�
--        gt_line_sales_class( gn_line_data_no )             := cv_sales_st_class;            -- ����敪
--        gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;            -- �ԍ��t���O
--        gt_line_item_code( gn_line_data_no )               := gv_disc_item;                 -- �i�ڃR�[�h
--        gt_line_standard_qty( gn_line_data_no )            := lt_set_replenish_number;      -- �����
--        gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;                -- ��P��
--        gt_line_standard_unit_price( gn_line_data_no )     := lt_standard_unit_price;       -- ��P��
--        gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero ); -- �c�ƌ���
--        gt_line_sale_amount( gn_line_data_no )             := lt_set_sale_amount;           -- ������z
--        gt_line_pure_amount( gn_line_data_no )             := lt_set_pure_amount;           -- �{�̋��z
--        gt_line_tax_amount( gn_line_data_no )              := lt_set_tax_amount;            -- ����ŋ��z
--        gt_line_cash_and_card( gn_line_data_no )           := cn_tkn_zero;                  -- �����E�J�[�h���p�z
--        gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_secondary_inventory_name;  -- �o�׌��ۊǏꏊ
--        gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;             -- �[�i���_�R�[�h
--        gt_line_hot_cold_class( gn_line_data_no )          := cv_tkn_null;                  -- �g���b
--        gt_line_column_no( gn_line_data_no )               := cv_tkn_null;                  -- �R����No
--        gt_line_sold_out_class( gn_line_data_no )          := cv_tkn_null;                  -- ���؋敪
--        gt_line_sold_out_time( gn_line_data_no )           := cv_tkn_null;                  -- ���؎���
--        gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                     -- �萔���v�ZIF�σt���O
--        gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                     -- �P���}�X�^�쐬�σt���O
--        gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                     -- INV�C���^�t�F�[�X�σt���O
--        gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;                  -- �������הԍ�(NULL�ݒ�)
--        gt_line_not_tax_amount( gn_line_data_no )          := lt_stand_unit_price_excl;     -- �Ŕ���P��
--        gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;             -- �[�i�`�ԋ敪
--        gt_line_dlv_qty( gn_line_data_no )                 := lt_set_replenish_number;      -- �[�i����
--        gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;                -- �[�i�P��
--        gt_dlv_unit_price( gn_line_data_no )               := lt_standard_unit_price;       -- �[�i�P��
--        gn_line_data_no := gn_line_data_no + 1;
--
          -- ===================
          -- �ꎞ�i�[�p
          -- ===================
          gt_accumulation_data(ln_line_data_count).dlv_invoice_number         := lt_hht_invoice_no;             -- �[�i�`�[�ԍ�
          gt_accumulation_data(ln_line_data_count).dlv_invoice_line_number    := ln_max_invoice_num;            -- �[�i���הԍ�
          gt_accumulation_data(ln_line_data_count).sales_class                := cv_sales_st_class;             -- ����敪
          gt_accumulation_data(ln_line_data_count).red_black_flag             := lt_red_black_flag;             -- �ԍ��t���O
          gt_accumulation_data(ln_line_data_count).item_code                  := gv_disc_item;                  -- �i�ڃR�[�h
          gt_accumulation_data(ln_line_data_count).dlv_qty                    := lt_set_replenish_number;       -- �[�i����
          gt_accumulation_data(ln_line_data_count).standard_qty               := lt_set_replenish_number;       -- �����
          gt_accumulation_data(ln_line_data_count).dlv_uom_code               := lt_stand_unit;                 -- �[�i�P��
          gt_accumulation_data(ln_line_data_count).standard_uom_code          := lt_stand_unit;                 -- ��P��
          gt_accumulation_data(ln_line_data_count).dlv_unit_price             := lt_standard_unit_price;        -- �[�i�P��
          gt_accumulation_data(ln_line_data_count).standard_unit_price        := lt_standard_unit_price;        -- ��P��
          gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- �c�ƌ���
          gt_accumulation_data(ln_line_data_count).sale_amount                := lt_set_sale_amount;            -- ������z
          gt_accumulation_data(ln_line_data_count).pure_amount                := lt_set_pure_amount;            -- �{�̋��z
          gt_accumulation_data(ln_line_data_count).tax_amount                 := lt_set_tax_amount;             -- ����ŋ��z
          gt_accumulation_data(ln_line_data_count).cash_and_card              := cn_tkn_zero;                   -- �����E�J�[�h���p�z
          gt_accumulation_data(ln_line_data_count).ship_from_subinventory_code := lt_secondary_inventory_name;  -- �o�׌��ۊǏꏊ
          gt_accumulation_data(ln_line_data_count).delivery_base_code         := lt_dlv_base_code;              -- �[�i���_�R�[�h
          gt_accumulation_data(ln_line_data_count).hot_cold_class             := cv_tkn_null;                   -- �g���b
          gt_accumulation_data(ln_line_data_count).column_no                  := cv_tkn_null;                   -- �R����No
          gt_accumulation_data(ln_line_data_count).sold_out_class             := cv_tkn_null;                   -- ���؋敪
          gt_accumulation_data(ln_line_data_count).sold_out_time              := cv_tkn_null;                   -- ���؎���
          gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                      -- �萔���v�Z�C���^�t�F�[�X�σt���O
          gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                      -- �P���}�X�^�쐬�σt���O
          gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                      -- INV�C���^�t�F�[�X�σt���O
          gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;                   -- �������הԍ�(NULL�ݒ�)
          gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := lt_stand_unit_price_excl;    -- �Ŕ���P��
          gt_accumulation_data(ln_line_data_count).delivery_pattern_class     := lv_delivery_type;              -- �[�i�`�ԋ敪(���o)
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--
      END IF;
--
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
      IF ( lv_state_flg <> cv_status_warn ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
--
        -- ==================
        -- �w�b�_�o�^�p���z�Z�o
        -- ==================
        IF ( lt_consumption_tax_class = cv_non_tax ) THEN           -- ��ې�
--
          -- ������z���v
          lt_sale_amount_sum := lt_total_amount;
          -- �{�̋��z���v
          lt_pure_amount_sum := lt_total_amount;
          -- ����ŋ��z���v
          lt_tax_amount_sum  := NVL( lt_sales_consumption_tax, cn_cons_tkn_zero );
        ELSE
         --�l��������
          IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
--
            IF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
              -- ������z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_sale_amount_sum := ( ( lt_total_amount - lt_sale_discount_amount ) * ln_tax_data );
--              IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
--                IF ( lt_tax_odd = cv_amount_up ) THEN
--                lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
--                -- �؎̂�
--                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                  lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
--                -- �l�̌ܓ�
--                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
--                END IF;
--              END IF;
                ln_amount := lt_tax_include;
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
                  lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                  -- �؎̂�
                  ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                    lt_sale_amount_sum := TRUNC( ln_amount );
                  -- �l�̌ܓ�
                  ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                    lt_sale_amount_sum := ROUND( ln_amount );
                  END IF;
                ELSE
                  lt_sale_amount_sum := ln_amount;
                END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- �{�̋��z���v
                lt_pure_amount_sum := ( lt_total_amount - lt_sale_discount_amount );
                -- ����ŋ��z���v
                ln_amount  := ( lt_sale_amount_sum * ( ln_tax_data - 1 ) );
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
                  lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
                  -- �؎̂�
                  ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                    lt_tax_amount_sum := TRUNC( ln_amount );
                  -- �l�̌ܓ�
                  ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_tax_amount_sum := ROUND( ln_amount );
                  END IF;
                ELSE
                  lt_tax_amount_sum := ln_amount;
                END IF;
--
            ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
              -- ������z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_sale_amount_sum := ( ( lt_total_amount - lt_sale_discount_amount ) * ln_tax_data );
--            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
--              END IF;
--            END IF;
--            ln_amount := ( ( lt_total_amount - lt_sale_discount_amount ) * ln_tax_data );
--            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_sale_amount_sum := TRUNC( ln_amount );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_sale_amount_sum := ROUND( ln_amount );
--              END IF;
--            ELSE
--              lt_sale_amount_sum   := ln_amount;
--            END IF;
              lt_sale_amount_sum := lt_tax_include;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- �{�̋��z���v
              lt_pure_amount_sum := ( lt_total_amount - lt_sale_discount_amount );
              -- ����ŋ��z���v
              lt_tax_amount_sum  := lt_sales_consumption_tax;
--
            ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--
              -- ������z���v
              lt_sale_amount_sum := ( lt_total_amount - lt_sale_discount_amount );
              -- �{�̋��z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_pure_amount_sum := ( lt_sale_amount_sum / ln_tax_data );
--            IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--                lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                 lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
--              END IF;
--            END IF;
              ln_amount := ( lt_sale_amount_sum / ln_tax_data );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                  lt_pure_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_pure_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                   lt_pure_amount_sum:= ROUND( ln_amount );
                END IF;
              ELSE
                lt_pure_amount_sum := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- �l������ŎZ�o
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            ln_discount_tax    := ( lt_sale_discount_amount - ( lt_sale_discount_amount / ln_tax_data ) );
--            IF ( ln_discount_tax <> TRUNC( ln_discount_tax ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--                ln_discount_tax := ( TRUNC( ln_discount_tax ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                ln_discount_tax := TRUNC( ln_discount_tax );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                 ln_discount_tax:= ROUND( ln_discount_tax );
--              END IF;
--            END IF;
              ln_amount    := ( lt_sale_discount_amount - ( lt_sale_discount_amount / ln_tax_data ) );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                  ln_discount_tax := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  ln_discount_tax := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  ln_discount_tax := ROUND( ln_amount );
                END IF;
              ELSE
                ln_discount_tax   := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- ����ŋ��z���v
              lt_tax_amount_sum  := ( ln_all_tax_amount - ln_discount_tax );
--
            END IF;
          --�l�������������z�Z�o
          ELSE
--
            IF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
              -- ������z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
--            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
--              END IF;
--            END IF;
              ln_amount := lt_total_amount;
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_sale_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_sale_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_sale_amount_sum   := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- �{�̋��z���v
              lt_pure_amount_sum := lt_total_amount;
              -- ����ŋ��z���v
              ln_amount  := ( lt_sale_amount_sum * ( ln_tax_data - 1 ) );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_tax_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_tax_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_tax_amount_sum := ln_amount;
              END IF;
--
            ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
            -- ������z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
--            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
--              END IF;
--            END IF;
              ln_amount := ( lt_total_amount * ln_tax_data );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_sale_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_sale_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_sale_amount_sum   := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- �{�̋��z���v
              lt_pure_amount_sum := lt_total_amount;
            -- ����ŋ��z���v
              lt_tax_amount_sum  := ( lt_sale_amount_sum - lt_pure_amount_sum );
--
            ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--
              -- ������z���v
              lt_sale_amount_sum := lt_total_amount;
              -- �{�̋��z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_pure_amount_sum := ( lt_total_amount / ln_tax_data );
--            IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--                lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
--              END IF;
--            END IF;
              ln_amount := ( lt_total_amount / ln_tax_data );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                  lt_pure_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_pure_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_pure_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_pure_amount_sum   := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- ����ŋ��z���v
            lt_tax_amount_sum  := ln_all_tax_amount;
--
            END IF;
          END IF;
        END IF;
--
        --��ېňȊO�̎�
        IF (lt_consumption_tax_class <> cv_non_tax) THEN
          -- ================================================
          -- �w�b�_�������Ŋz�Ɩ��ה������Ŋz��r���f����
          -- ================================================
          -- �l�����ׂ�null�ȊO�̎�
          IF ( lt_sale_discount_amount IS NOT NULL ) AND ( lt_sale_discount_amount <> 0 ) 
          AND ( lt_consumption_tax_class <> cv_ins_bid_tax ) THEN
            ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
          END IF;
          IF ( lt_tax_amount_sum <> ln_all_tax_amount ) THEN
            -- �O�� OR ����(�`�[�ېł̎�)
            IF ( lt_consumption_tax_class = cv_out_tax ) OR ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN
--******************************* 2009/04/21 N.Maeda Var1.10 MOD START ***************************************
              IF ( lt_red_black_flag = cv_black_flag) THEN
--                gt_line_tax_amount( ln_max_no_data ) := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
                gt_accumulation_data(ln_max_no_data).tax_amount := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
              ELSIF ( lt_red_black_flag = cv_red_flag) THEN
--                gt_line_tax_amount( ln_max_no_data ) := ( ( ln_max_tax_data 
--                                                          + ( lt_tax_amount_sum - ln_all_tax_amount ) ) * ( -1 ) );
                gt_accumulation_data(ln_max_no_data).tax_amount := ( ( ln_max_tax_data 
                                                                      + ( lt_tax_amount_sum - ln_all_tax_amount ) ) * ( -1 ) );
--******************************* 2009/04/21 N.Maeda Var1.10 MOD END   ***************************************
              END IF;
            END IF;
          END IF;
        END IF;
--
        -- �ԁE���̋��z���Z
        --���̎�
        IF ( lt_red_black_flag = cv_black_flag) THEN
          -- ������z���v
          lt_set_sale_amount_sum := lt_sale_amount_sum;
          -- �{�̋��z���v
          lt_set_pure_amount_sum := lt_pure_amount_sum;
          -- ����ŋ��z���v
          lt_set_tax_amount_sum := lt_tax_amount_sum;
        -- �Ԃ̎�
        ELSIF ( lt_red_black_flag = cv_red_flag) THEN
          -- ������z���v
          lt_set_sale_amount_sum := ( lt_sale_amount_sum * ( -1 ) );
          -- �{�̋��z���v
          lt_set_pure_amount_sum := ( lt_pure_amount_sum * ( -1 ) );
          -- ����ŋ��z���v
          lt_set_tax_amount_sum := ( lt_tax_amount_sum * ( -1 ) );
        END IF;
--
--******************************* 2009/05/12 N.Maeda Var1.13 ADD START *************************************
        IF ( NVL( lt_order_no_ebs, 0 ) <> 0 ) AND ( lt_red_black_flag = cv_black_flag)
        AND ( lt_digestion_ln_number = 1 ) THEN
          BEGIN
            OPEN  get_oe_order_cur;
            -- �o���N�t�F�b�`
            FETCH get_oe_order_cur BULK COLLECT INTO gt_inp_oe_order_all;
            -- ���o�����Z�b�g
            gn_om_data_cnt := gn_om_data_cnt + get_oe_order_cur%ROWCOUNT;
            -- �J�[�\��CLOSE
            CLOSE get_oe_order_cur;
          EXCEPTION
            WHEN OTHERS THEN
              IF( get_oe_order_cur%ISOPEN ) THEN
                CLOSE get_oe_order_cur;
              END IF;
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_om_order );
              --�L�[�ҏW�\�ϐ��ݒ�
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            xxcos_common_pkg.makeup_key_info(
              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_order_no ), -- ���ږ��̂P
              iv_data_value1 => lt_order_no_ebs,         -- �f�[�^�̒l�P
              ov_key_info    => gv_tkn2,              -- �L�[���
              ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
              ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
              ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                  iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                  iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                  iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                  iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                  iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                  iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
          END;
--
          IF ( gt_inp_oe_order_all.COUNT > 0 ) AND ( lv_state_flg <> cv_status_warn )THEN
            <<om_order_loop>>
            FOR om_data_no IN 1..gt_inp_oe_order_all.COUNT LOOP
              -- ====================================
              -- OM�󒍏��i�[
              -- ====================================
              gt_oe_order_number( gn_cnt_om_order )      := gt_inp_oe_order_all( om_data_no ).order_number;
              gt_oe_header_id( gn_cnt_om_order )         := gt_inp_oe_order_all( om_data_no ).header_id;
              gt_oe_he_flow_status_code( gn_cnt_om_order )  := gt_inp_oe_order_all( om_data_no ).head_flow_status_code;
              gt_oe_order_source_id( gn_cnt_om_order )   := gt_inp_oe_order_all( om_data_no ).order_source_id;
              gt_oe_cust_po_number( gn_cnt_om_order )    := gt_inp_oe_order_all( om_data_no ).cust_po_number;
              gt_oe_line_id( gn_cnt_om_order )           := gt_inp_oe_order_all( om_data_no ).line_id;
              gt_oe_li_flow_status_code( gn_cnt_om_order )  := gt_inp_oe_order_all( om_data_no ).line_flow_status_code;
              gn_cnt_om_order := gn_cnt_om_order + 1;
            END LOOP om_order_loop;
          END IF;
        END IF;
--      END IF;
--******************************* 2009/05/12 N.Maeda Var1.13 ADD  END ***************************************
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        --================================
        --�̔����уw�b�_ID(�V�[�P���X�擾)
        --================================
        SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
        INTO ln_actual_id
        FROM DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--
        --==========================
        -- �w�b�_�f�[�^�̕ϐ��}��
        --==========================
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        gt_dlv_hht_head_row_id( gn_head_data_no )          := lt_row_id;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
        gt_head_id( gn_head_data_no )                      := ln_actual_id;                 -- �̔����уw�b�_ID
        gt_head_order_no_ebs( gn_head_data_no )            := lt_order_no_ebs;              -- �󒍔ԍ�
        gt_head_hht_invoice_no( gn_head_data_no )          := lt_hht_invoice_no;            -- �[�i�`�[�ԍ�
        gt_head_order_no_hht( gn_head_data_no )            := lt_order_no_hht;              -- ��No(HHT)
        gt_head_digestion_ln_number( gn_head_data_no )     := lt_digestion_ln_number;       -- �}��(��No(HHT)�}��)
        gt_head_dlv_invoice_class( gn_head_data_no )       := lt_ins_invoice_type;          -- �[�i�`�[�敪(���o)
        gt_head_cancel_cor_cls( gn_head_data_no )          := lt_cancel_correct_class;      -- ����E�����敪
        gt_head_system_class( gn_head_data_no )            := lt_system_class;              -- �Ƒԋ敪(�Ƒԏ�����)
        gt_head_dlv_date( gn_head_data_no )                := lt_dlv_date;                  -- �[�i��
        gt_head_inspect_date( gn_head_data_no )            := lt_inspect_date;              -- ������(����v���)
        gt_head_customer_number( gn_head_data_no )         := lt_customer_number;           -- �ڋq�y�[�i��
        gt_head_tax_include( gn_head_data_no )             := lt_set_sale_amount_sum;       -- ������z���v
        gt_head_total_amount( gn_head_data_no )            := lt_set_pure_amount_sum;       -- �{�̋��z���v
        gt_head_sales_consump_tax( gn_head_data_no )       := lt_set_tax_amount_sum;        -- ����ŋ��z���v(�����o)
        gt_head_consump_tax_class( gn_head_data_no )       := lt_consum_type;               -- ����ŋ敪(���o)
        gt_head_tax_code( gn_head_data_no )                := lt_consum_code;               -- �ŋ��R�[�h(���o)
        gt_head_tax_rate( gn_head_data_no )                := lt_tax_consum;                -- ����ŗ�(���o)
        gt_head_performance_by_code( gn_head_data_no )     := lt_performance_by_code;       -- ���ьv��҃R�[�h
        gt_head_sales_base_code( gn_head_data_no )         := lt_sale_base_code;            -- ���㋒�_�R�[�h(���o)
        gt_head_card_sale_class( gn_head_data_no )         := lt_card_sale_class;           -- �J�[�h����敪
--        gt_head_sales_classification( gn_head_data_no )    := lt_sales_classification;      -- �`�[�敪
--        gt_head_invoice_class( gn_head_data_no )           := lt_sales_invoice;             -- �`�[���ރR�[�h
        gt_head_sales_classification( gn_head_data_no )    := lt_sales_invoice;             -- �`�[�敪
        gt_head_invoice_class( gn_head_data_no )           := lt_sales_classification;      -- �`�[���ރR�[�h
-- ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
--        gt_head_receiv_base_code( gn_head_data_no )        := lt_sale_base_code;          -- �������_�R�[�h(���o)
        gt_head_receiv_base_code( gn_head_data_no )        := lt_cash_receiv_base_code;   -- �������_�R�[�h(���o)
-- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
        gt_head_change_out_time_100( gn_head_data_no )     := lt_change_out_time_100;       -- ��K�؂ꎞ��100�~
        gt_head_change_out_time_10( gn_head_data_no )      := lt_change_out_time_10;        -- ��K�؂ꎞ��10�~
        gt_head_hht_dlv_input_date( gn_head_data_no )      := ld_input_date;                -- HHT�[�i���͓���(���^����)
        gt_head_dlv_by_code( gn_head_data_no )             := lt_dlv_by_code;               -- �[�i�҃R�[�h
        gt_head_business_date( gn_head_data_no )           := gd_process_date;              -- �o�^�Ɩ����t(���������擾)
        gt_head_order_source_id( gn_head_data_no )         := cv_tkn_null;                  -- �󒍃\�[�XID(NULL�ݒ�)
        gt_head_order_invoice_number( gn_head_data_no )    := cv_tkn_null;                  -- �����`�[�ԍ�(NULL�ݒ�)
        gt_head_order_connection_num( gn_head_data_no )    := cv_tkn_null;                  -- �󒍊֘A�ԍ�(NULL�ݒ�)
        gt_head_ar_interface_flag( gn_head_data_no )       := cv_tkn_n;                     -- AR-IF�σt���O('N')
        gt_head_gl_interface_flag( gn_head_data_no )       := cv_tkn_n;                     -- GL-IF�σt���O('N')
        gt_head_dwh_interface_flag( gn_head_data_no )      := cv_tkn_n;                     -- ���V�X�e��IF�σt���O('N')
        gt_head_edi_interface_flag( gn_head_data_no )      := cv_tkn_n;                     -- EDI���M�ς݃t���O('N'�ݒ�)
        gt_head_edi_send_date( gn_head_data_no )           := cv_tkn_null;                  -- EDI���M����(NULL�ݒ�)
-- ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
--        gt_head_create_class( gn_head_data_no )            := cn_tkn_shipping_chk;          -- �쐬���敪(�4��ݒ�)
        gt_head_create_class( gn_head_data_no )            := cv_tkn_shipping_chk;          -- �쐬���敪(�4��ݒ�)
-- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
        gt_head_input_class( gn_head_data_no )             := lt_input_class;               -- ���͋敪
        gn_head_data_no := gn_head_data_no + 1;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--
        <<line_set_loop>>
        FOR in_data_num IN 1..ln_line_data_count LOOP
--
          -- ===================
          -- �o�^�p����ID�擾
          -- ===================
          SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
          INTO   ln_sales_exp_line_id
          FROM   DUAL;
--
          gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- �̔����і���ID
          gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- �̔����уw�b�_ID
          gt_line_dlv_invoice_number( gn_line_data_no )      := gt_accumulation_data(in_data_num).dlv_invoice_number;    -- �[�i�`�[�ԍ�
          gt_line_dlv_invoice_l_num( gn_line_data_no )       := gt_accumulation_data(in_data_num).dlv_invoice_line_number; -- �[�i���הԍ�
          gt_line_sales_class( gn_line_data_no )             := gt_accumulation_data(in_data_num).sales_class;           -- ����敪
          gt_line_red_black_flag( gn_line_data_no )          := gt_accumulation_data(in_data_num).red_black_flag;        -- �ԍ��t���O
          gt_line_item_code( gn_line_data_no )               := gt_accumulation_data(in_data_num).item_code;             -- �i�ڃR�[�h
          gt_line_standard_qty( gn_line_data_no )            := gt_accumulation_data(in_data_num).standard_qty;          -- �����
          gt_line_standard_uom_code( gn_line_data_no )       := gt_accumulation_data(in_data_num).standard_uom_code;     -- ��P��
          gt_line_standard_unit_price( gn_line_data_no )     := gt_accumulation_data(in_data_num).standard_unit_price;   -- ��P��
          gt_line_business_cost( gn_line_data_no )           := gt_accumulation_data(in_data_num).business_cost;         -- �c�ƌ���
          gt_line_sale_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).sale_amount;           -- ������z
          gt_line_pure_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).pure_amount;           -- �{�̋��z
          gt_line_tax_amount( gn_line_data_no )              := gt_accumulation_data(in_data_num).tax_amount;            -- ����ŋ��z
          gt_line_cash_and_card( gn_line_data_no )           := gt_accumulation_data(in_data_num).cash_and_card;         -- �����E�J�[�h���p�z
          gt_line_ship_from_subinv_co( gn_line_data_no )     := gt_accumulation_data(in_data_num).ship_from_subinventory_code; -- �o�׌��ۊǏꏊ
          gt_line_delivery_base_code( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_base_code;    -- �[�i���_�R�[�h
          gt_line_hot_cold_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).hot_cold_class;        -- �g���b
          gt_line_column_no( gn_line_data_no )               := gt_accumulation_data(in_data_num).column_no;             -- �R����No
          gt_line_sold_out_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).sold_out_class;        -- ���؋敪
          gt_line_sold_out_time( gn_line_data_no )           := gt_accumulation_data(in_data_num).sold_out_time;         -- ���؎���
          gt_line_to_calculate_fees_flag( gn_line_data_no )  := gt_accumulation_data(in_data_num).to_calculate_fees_flag;-- �萔���v�ZIF�σt���O
          gt_line_unit_price_mst_flag( gn_line_data_no )     := gt_accumulation_data(in_data_num).unit_price_mst_flag;   -- �P���}�X�^�쐬�σt���O
          gt_line_inv_interface_flag( gn_line_data_no )      := gt_accumulation_data(in_data_num).inv_interface_flag;    -- INV�C���^�t�F�[�X�σt���O
          gt_line_order_invoice_l_num( gn_line_data_no )     := gt_accumulation_data(in_data_num).order_invoice_line_number;   -- �������הԍ�
          gt_line_not_tax_amount( gn_line_data_no )          := gt_accumulation_data(in_data_num).standard_unit_price_excluded;-- �Ŕ���P��
          gt_line_delivery_pat_class( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_pattern_class;      -- �[�i�`�ԋ敪
          gt_line_dlv_qty( gn_line_data_no )                 := gt_accumulation_data(in_data_num).dlv_qty;                     -- �[�i����
          gt_line_dlv_uom_code( gn_line_data_no )            := gt_accumulation_data(in_data_num).dlv_uom_code;                -- �[�i�P��
          gt_dlv_unit_price( gn_line_data_no )               := gt_accumulation_data(in_data_num).dlv_unit_price;              -- �[�i�P��
          gn_line_data_no := gn_line_data_no + 1;
        END LOOP line_set_loop;
      END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
    END LOOP header_loop;
--
  EXCEPTION
    WHEN no_data_extract THEN
      --�L�[�ҏW�֐�
      xxcos_common_pkg.makeup_key_info(
                                         lv_key_name1, lv_key_data1, lv_key_name2, lv_key_data2,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         gv_tkn2, lv_errbuf, lv_retcode, lv_errmsg);  
      --���b�Z�[�W����
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_no_data,
                                             cv_tkn_table_name, gv_tkn1,
                                             cv_key_data, gv_tkn2 );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--    WHEN delivered_from_err_expt THEN
--      --
--      lv_errmsg := xxccp_common_pkg.get_msg( cv_application,cv_msg_delivered_from_err );
----      lv_errbuf := lv_errmsg;
--      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
--      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;                                            --# �C�� #
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
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
  END proc_inp_molded_hht;
--
  /**********************************************************************************
   * Procedure Name   : proc_molded_hht
   * Description      : �̔����уf�[�^(HHT)���^����(A-3)
   ***********************************************************************************/
  PROCEDURE proc_molded_hht(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_molded'; -- �v���O������
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
    --�[�i�w�b�_(HHT)�i�[�p�ϐ�
    lt_order_no_hht              xxcos_dlv_headers.order_no_hht%TYPE;             -- ��No.(HHT)
    lt_digestion_ln_number       xxcos_dlv_headers.digestion_ln_number%TYPE;      -- �}��
    lt_order_no_ebs              xxcos_dlv_headers.order_no_ebs%TYPE;             -- ��No.�iEBS�j
    lt_base_code                 xxcos_dlv_headers.base_code%TYPE;                -- ���_�R�[�h
    lt_performance_by_code       xxcos_dlv_headers.performance_by_code%TYPE;      -- ���ю҃R�[�h
    lt_dlv_by_code               xxcos_dlv_headers.dlv_by_code%TYPE;              -- �[�i�҃R�[�h
    lt_hht_invoice_no            xxcos_dlv_headers.hht_invoice_no%TYPE;           -- HHT�`�[No.
    lt_dlv_date                  xxcos_dlv_headers.dlv_date%TYPE;                 -- �[�i��
    lt_inspect_date              xxcos_dlv_headers.inspect_date%TYPE;             -- ������
    lt_sales_classification      xxcos_dlv_headers.sales_classification%TYPE;     -- ���㕪�ދ敪
    lt_sales_invoice             xxcos_dlv_headers.sales_invoice%TYPE;            -- ����`�[�敪
    lt_card_sale_class           xxcos_dlv_headers.card_sale_class%TYPE;          -- �J�[�h����敪
    lt_dlv_time                  xxcos_dlv_headers.dlv_time%TYPE;                 -- ����
    lt_customer_number           xxcos_dlv_headers.customer_number%TYPE;          -- �ڋq�R�[�h
    lt_change_out_time_100       xxcos_dlv_headers.change_out_time_100%TYPE;      -- ��K�؂ꎞ��100�~
    lt_change_out_time_10        xxcos_dlv_headers.change_out_time_10%TYPE;       -- ��K�؂ꎞ��10�~
    lt_system_class              xxcos_dlv_headers.system_class%TYPE;             -- �Ƒԋ敪
    lt_input_class               xxcos_dlv_headers.input_class%TYPE;              -- ���͋敪
    lt_consumption_tax_class     xxcos_dlv_headers.consumption_tax_class%TYPE;    -- ����ŋ敪
    lt_total_amount              xxcos_dlv_headers.total_amount%TYPE;             -- ���v���z
    lt_sale_discount_amount      xxcos_dlv_headers.sale_discount_amount%TYPE;     -- ����l���z
    lt_sales_consumption_tax     xxcos_dlv_headers.sales_consumption_tax%TYPE;    -- �������Ŋz
    lt_tax_include               xxcos_dlv_headers.tax_include%TYPE;              -- �ō����z
    lt_keep_in_code              xxcos_dlv_headers.keep_in_code%TYPE;             -- �a����R�[�h
    lt_department_screen_class   xxcos_dlv_headers.department_screen_class%TYPE;  -- �S�ݓX��ʎ��
    lt_stock_forward_flag        xxcos_dlv_headers.stock_forward_flag%TYPE;       -- ���o�ɓ]���t���O
    lt_stock_forward_date        xxcos_dlv_headers.stock_forward_date%TYPE;       -- ���o�ɓ]���ϓ��t
    lt_results_forward_flag      xxcos_dlv_headers.results_forward_flag%TYPE;     -- �̔����јA�g�σt���O
    lt_results_forward_date      xxcos_dlv_headers.results_forward_date%TYPE;     -- �̔����јA�g�ϓ��t
    lt_cancel_correct_class      xxcos_dlv_headers.cancel_correct_class%TYPE;     -- ����E�����敪
    lt_red_black_flag            xxcos_dlv_headers.red_black_flag%TYPE;           -- �ԍ��t���O
    --�[�i����(HHT)�i�[�p�ϐ�
    lt_lin_order_no_hht          xxcos_dlv_lines.order_no_hht%TYPE;               -- ��No.�iHHT�j
    lt_lin_line_no_hht           xxcos_dlv_lines.line_no_hht%TYPE;                -- �sNo.�iHHT�j
    lt_lin_digestion_ln_number   xxcos_dlv_lines.digestion_ln_number%TYPE;        -- �}��
    lt_lin_order_no_ebs          xxcos_dlv_lines.order_no_ebs%TYPE;               -- ��No.�iEBS�j
    lt_lin_line_number_ebs       xxcos_dlv_lines.line_number_ebs%TYPE;            -- ���הԍ��iEBS�j
    lt_lin_item_code_self        xxcos_dlv_lines.item_code_self%TYPE;             -- �i���R�[�h�i���Ёj
    lt_lin_content               xxcos_dlv_lines.content%TYPE;                    -- ����
    lt_lin_inventory_item_id     xxcos_dlv_lines.inventory_item_id%TYPE;          -- �i��ID
    lt_lin_standard_unit         xxcos_dlv_lines.standard_unit%TYPE;              -- ��P��
    lt_lin_case_number           xxcos_dlv_lines.case_number%TYPE;                -- �P�[�X��
    lt_lin_quantity              xxcos_dlv_lines.quantity%TYPE;                   -- ����
    lt_lin_sale_class            xxcos_dlv_lines.sale_class%TYPE;                 -- ����敪
    lt_lin_wholesale_unit_ploce  xxcos_dlv_lines.wholesale_unit_ploce%TYPE;       -- ���P��
    lt_lin_selling_price         xxcos_dlv_lines.selling_price%TYPE;              -- ���P��
    lt_lin_column_no             xxcos_dlv_lines.column_no%TYPE;                  -- �R����No.
    lt_lin_h_and_c               xxcos_dlv_lines.h_and_c%TYPE;                    -- H/C
    lt_lin_sold_out_class        xxcos_dlv_lines.sold_out_class%TYPE;             -- ���؋敪
    lt_lin_sold_out_time         xxcos_dlv_lines.sold_out_time%TYPE;              -- ���؎���
    lt_lin_replenish_number      xxcos_dlv_lines.replenish_number%TYPE;           -- ��[��
    lt_lin_cash_and_card         xxcos_dlv_lines.cash_and_card%TYPE;              -- �����E�J�[�h���p�z
    -- ���̑�
    lt_dlv_base_code             xxcos_rs_info_v.base_code%TYPE;                  -- ���_�R�[�h
    lt_old_sales_cost            ic_item_mst_b.attribute7%TYPE;                   -- ���c�ƌ���
    lt_new_sales_cost            ic_item_mst_b.attribute8%TYPE;                   -- �V�c�ƌ���
    lt_st_sales_cost             ic_item_mst_b.attribute9%TYPE;                   -- �c�ƌ����K�p�J�n��
--
    ln_line_no                   NUMBER :=  1;                                    -- ���׃`�F�b�N�ϔԍ�
    ln_all_tax_amount            NUMBER :=  0;                                    -- ����ŋ��z���v�l
    ln_max_tax_data              NUMBER :=  0;                                    -- ���׍ő����Ŋz
    ln_actual_id                 NUMBER;                                          -- �̔����уw�b�_ID
--    ln_sales_amount              NUMBER;                                          -- ������z
--    ln_consum_amount             NUMBER;                                          -- ����ŋ��z
--    ln_tax_odd                   NUMBER;                                          -- ����Œ[��
--    ln_up_odd                    NUMBER;                                          -- �[���؂�グ���l
--    ln_amount_data               NUMBER;                                          -- �{�̋��z
--    lt_lin_sale_amount           NUMBER;                                          -- ������z
    ln_sales_exp_line_id         NUMBER;                                          -- ����ID
    ln_max_invoice_num           NUMBER;                                          -- �l�����חp�[�i���הԍ�
    ld_input_date                DATE;                                            -- HHT�[�i���͓���
    lt_tax_odd                   xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE; -- �ŋ�-�[������
    lt_consum_code               fnd_lookup_values.attribute2%TYPE;               -- ����ŃR�[�h
    lt_consum_type               fnd_lookup_values.attribute3%TYPE;               -- �̔����јA�g���̏���ŋ敪
    lt_tax_consum                ar_vat_tax_all_b.tax_rate%TYPE;                  -- ����ŗ�
    lt_stand_unit                mtl_system_items_b.primary_unit_of_measure%TYPE; -- ��P��
--    lt_lin_not_tax_amount        xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE; --�Ŕ���P��
    lt_location_type_code        fnd_lookup_values.meaning%TYPE;                  -- �ۊǏꏊ���ރR�[�h(�c�Ǝ�)
    lt_depart_location_type_code fnd_lookup_values.meaning%TYPE;                  -- �ۊǏꏊ���ރR�[�h(�S�ݓX)
    lt_secondary_inventory_name  mtl_secondary_inventories.secondary_inventory_name%TYPE; -- �ۊǏꏊ�R�[�h
    lt_ins_invoice_type          fnd_lookup_values.attribute4%TYPE;               -- �[�i�`�[�敪
    lv_depart_code               xxcmm_cust_accounts.dept_hht_div%TYPE;           -- HHT�S�ݓX���͋敪
    lt_inc_num                   xxcmm_system_items_b.inc_num%TYPE;               -- �������
    lt_sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE;         -- ���㋒�_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
    lt_cash_receiv_base_code     xxcos_cust_hierarchy_v.cash_receiv_base_code%TYPE;  -- �������_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
    lt_sales_cost                ic_item_mst_b.attribute7%TYPE;                   -- �c�ƌ���
    lt_sale_amount_sum           xxcos_sales_exp_headers.sale_amount_sum%TYPE;    -- ������z���v
    lt_pure_amount_sum           xxcos_sales_exp_headers.pure_amount_sum%TYPE;    -- �{�̋��z���v
    lt_tax_amount_sum            xxcos_sales_exp_headers.tax_amount_sum%TYPE;     -- ����ŋ��z���v
    lt_stand_unit_price_excl     xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE;--�Ŕ���P��
    lt_standard_unit_price       xxcos_sales_exp_lines.standard_unit_price%TYPE;  -- ��P��
    lt_sale_amount               xxcos_sales_exp_lines.sale_amount%TYPE;          -- ������z
    lt_pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE;          -- �{�̋��z
    lt_tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE;           -- ����ŋ��z
--    lt_cust_acct_site_id         hz_cust_acct_sites_all.cust_acct_site_id%TYPE;   -- �ڋq�T�C�gID
--    lt_site_use_code             fnd_lookup_values.meaning%TYPE;                  -- �g�p�敪
    --
    lt_set_replenish_number      xxcos_sales_exp_lines.standard_qty%TYPE;         -- �o�^�p�����(�[�i����)
    lt_set_sale_amount           xxcos_sales_exp_lines.sale_amount%TYPE;          -- �o�^�p������z
    lt_set_pure_amount           xxcos_sales_exp_lines.pure_amount%TYPE;          -- �o�^�p�{�̋��z
    lt_set_tax_amount            xxcos_sales_exp_lines.tax_amount%TYPE;           -- �o�^�p����ŋ��z
    lt_set_sale_amount_sum       xxcos_sales_exp_headers.sale_amount_sum%TYPE;    -- �o�^�p������z���v
    lt_set_pure_amount_sum       xxcos_sales_exp_headers.pure_amount_sum%TYPE;    -- �o�^�p�{�̋��z���v
    lt_set_tax_amount_sum        xxcos_sales_exp_headers.tax_amount_sum%TYPE;     -- �o�^�p����ŋ��z���v
    ln_discount_tax              NUMBER;                                          -- �l������Ŋz
    ln_tax_data                  NUMBER;                                          -- �ō��z�Z�o�p
    ln_max_no_data               NUMBER;                                          -- �w�b�_�ő����Ŗ��׍s�ԍ�
    lv_delivery_type             VARCHAR2(100);                                   -- �[�i�`�ԋ敪
    lv_key_name1                 VARCHAR2(500);                                   -- �L�[�f�[�^����1
    lv_key_name2                 VARCHAR2(500);                                   -- �L�[�f�[�^����2
    lv_key_data1                 VARCHAR2(500);                                   -- �L�[�f�[�^1
    lv_key_data2                 VARCHAR2(500);                                   -- �L�[�f�[�^2
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
    lt_row_id                    ROWID;                                           -- �X�V�p�sID
    lv_state_flg                 VARCHAR2(1);                                     -- �f�[�^�x���m�F�t���O
    ln_line_data_count           NUMBER;                                          -- ���׌���(�w�b�_�P��)
    lv_dept_hht_div_flg          VARCHAR2(1);                                     -- HHT�S�ݓX�敪�G���[�t���O
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--************************** 2009/03/18 1.5 T.kitajima ADD START ************************************
  ln_amount                      NUMBER;                                          -- ��Ɨp���z�ϐ�
--************************** 2009/03/18 1.5 T.kitajima ADD  END  ************************************
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�v�J�n�F�w�b�_��
    <<header_loop>>
    FOR ck_no IN 1..gn_target_cnt LOOP
--
      -- ���הԍ��̏�����
      ln_sales_exp_line_id            := 0;
      -- �Ϗ����ł̏�����
      ln_all_tax_amount               := 0;
      -- �ő����Ŋz�̏�����
      ln_max_tax_data                 := 0;
      -- �ő�sNo
      ln_max_invoice_num              := 0;
      -- �ő喾�הԍ�
      ln_max_no_data                  := 0;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      -- ���׌����J�E���g(������)
      ln_line_data_count              := 0;
      -- �f�[�^�x���m�F�t���O(������)
      lv_state_flg                    := cv_status_normal;
      -- HHT�S�ݓX�敪�G���[(������)
      lv_dept_hht_div_flg             := cv_status_normal;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      lt_row_id                    := gt_dlv_hht_headers_data( ck_no ).row_id;                   -- �sID
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
      lt_order_no_hht              := gt_dlv_hht_headers_data( ck_no ).order_no_hht;             -- ��No.(HHT)
      lt_digestion_ln_number       := gt_dlv_hht_headers_data( ck_no ).digestion_ln_number;      -- �}��
      lt_order_no_ebs              := gt_dlv_hht_headers_data( ck_no ).order_no_ebs;             -- ��No.�iEBS�j
      lt_base_code                 := gt_dlv_hht_headers_data( ck_no ).base_code;                -- ���_�R�[�h
      lt_performance_by_code       := gt_dlv_hht_headers_data( ck_no ).performance_by_code;      -- ���ю҃R�[�h
      lt_dlv_by_code               := gt_dlv_hht_headers_data( ck_no ).dlv_by_code;              -- �[�i�҃R�[�h
      lt_hht_invoice_no            := gt_dlv_hht_headers_data( ck_no ).hht_invoice_no;           -- HHT�`�[No.
      lt_dlv_date                  := gt_dlv_hht_headers_data( ck_no ).dlv_date;                 -- �[�i��
      lt_inspect_date              := gt_dlv_hht_headers_data( ck_no ).inspect_date;             -- ������
      lt_sales_classification      := gt_dlv_hht_headers_data( ck_no ).sales_classification;     -- ���㕪�ދ敪
      lt_sales_invoice             := gt_dlv_hht_headers_data( ck_no ).sales_invoice;            -- ����`�[�敪
      lt_card_sale_class           := gt_dlv_hht_headers_data( ck_no ).card_sale_class;          -- �J�[�h����敪
      lt_dlv_time                  := gt_dlv_hht_headers_data( ck_no ).dlv_time;                 -- ����
      lt_customer_number           := gt_dlv_hht_headers_data( ck_no ).customer_number;          -- �ڋq�R�[�h
      lt_change_out_time_100       := gt_dlv_hht_headers_data( ck_no ).change_out_time_100;      -- ��K�؂ꎞ��100�~
      lt_change_out_time_10        := gt_dlv_hht_headers_data( ck_no ).change_out_time_10;       -- ��K�؂ꎞ��10�~
      lt_system_class              := gt_dlv_hht_headers_data( ck_no ).system_class;             -- �Ƒԋ敪
      lt_input_class               := gt_dlv_hht_headers_data( ck_no ).input_class;              -- ���͋敪
      lt_consumption_tax_class     := gt_dlv_hht_headers_data( ck_no ).consumption_tax_class;    -- ����ŋ敪
      lt_total_amount              := gt_dlv_hht_headers_data( ck_no ).total_amount;             -- ���v���z
      lt_sale_discount_amount      := gt_dlv_hht_headers_data( ck_no ).sale_discount_amount;     -- ����l���z
      lt_sales_consumption_tax     := gt_dlv_hht_headers_data( ck_no ).sales_consumption_tax;    -- �������Ŋz
      lt_tax_include               := gt_dlv_hht_headers_data( ck_no ).tax_include;              -- �ō����z
      lt_keep_in_code              := gt_dlv_hht_headers_data( ck_no ).keep_in_code;             -- �a����R�[�h
      lt_department_screen_class   := gt_dlv_hht_headers_data( ck_no ).department_screen_class;  -- �S�ݓX��ʎ��
      lt_red_black_flag            := gt_dlv_hht_headers_data( ck_no ).red_black_flag;           -- �ԍ��t���O
      lt_stock_forward_flag        := gt_dlv_hht_headers_data( ck_no ).stock_forward_flag;       -- ���o�ɓ]���t���O
      lt_stock_forward_date        := gt_dlv_hht_headers_data( ck_no ).stock_forward_date;       -- ���o�ɓ]���ϓ��t
      lt_results_forward_flag      := gt_dlv_hht_headers_data( ck_no ).results_forward_flag;     -- �̔����јA�g�σt���O
      lt_results_forward_date      := gt_dlv_hht_headers_data( ck_no ).results_forward_date;     -- �̔����јA�g�ϓ��t
      lt_cancel_correct_class      := gt_dlv_hht_headers_data( ck_no ).cancel_correct_class;     -- ����E�����敪
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--      --================================
--      --�̔����уw�b�_ID(�V�[�P���X�擾)
--      --================================
--      SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
--      INTO ln_actual_id
--      FROM DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
--
      --=========================
      --�ڋq�}�X�^�t�я��̓��o
      --=========================
      BEGIN
        SELECT  xca.sale_base_code, --���㋒�_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
                xch.cash_receiv_base_code,  --�������_�R�[�h
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
                --hca.tax_rounding_rule --�ŋ�-�[������
                xch.bill_tax_round_rule -- �ŋ�-�[������(�T�C�g)
        INTO    lt_sale_base_code,
-- ************** 2009/04/16 1.12 N.Maeda ADD START ****************************************************************
                lt_cash_receiv_base_code,
-- ************** 2009/04/16 1.12 N.Maeda ADD  END  ****************************************************************
                lt_tax_odd
        FROM    hz_cust_accounts hca,  --�ڋq�}�X�^
                xxcmm_cust_accounts xca, --�ڋq�ǉ����
                xxcos_cust_hierarchy_v xch -- �ڋq�K�w�r���[
        WHERE   hca.cust_account_id = xca.customer_id
        AND     xch.ship_account_id = hca.cust_account_id
        AND     xch.ship_account_id = xca.customer_id
        AND     hca.account_number = TO_CHAR( lt_customer_number )
        AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
        AND     hca.party_id IN ( SELECT  hpt.party_id
                                  FROM    hz_parties hpt
                                  WHERE   hpt.duns_number_c   IN ( cv_cust_s , cv_cust_v , cv_cost_p ) );
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
          --�L�[�ҏW����
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
--          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code );
--          lv_key_data1 := cv_customer_type_c||cv_con_char||cv_customer_type_u;
--          lv_key_data2 := lt_customer_number;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type ), -- ���ږ��̂P
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code ), -- ���ږ��̂Q
            iv_data_value1 => (cv_customer_type_c||cv_con_char||cv_customer_type_u),         -- �f�[�^�̒l�P
            iv_data_value2 => lt_customer_number,   -- �f�[�^�̒l�Q
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
      END;
--
      -- ========================
      -- ����ŃR�[�h�̓��o(HHT)
      -- ========================
      BEGIN
        SELECT  look_val.attribute2,  --����ŃR�[�h
                look_val.attribute3   --�̔����јA�g���̏���ŋ敪
        INTO    lt_consum_code,
                lt_consum_type
        FROM    fnd_lookup_values     look_val,
                fnd_lookup_types_tl   types_tl,
                fnd_lookup_types      types,
                fnd_application_tl    appl,
                fnd_application       app
        WHERE   appl.application_id   = types.application_id
        AND     app.application_id    = appl.application_id
        AND     types_tl.lookup_type  = look_val.lookup_type
        AND     types.lookup_type     = types_tl.lookup_type
        AND     types.security_group_id   = types_tl.security_group_id
        AND     types.view_application_id = types_tl.view_application_id
        AND     types_tl.language = USERENV( 'LANG' )
        AND     look_val.language = USERENV( 'LANG' )
        AND     appl.language     = USERENV( 'LANG' )
        AND     app.application_short_name = cv_application
        AND     gd_process_date      >= look_val.start_date_active
        AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
        AND     look_val.enabled_flag = cv_tkn_yes
        AND     look_val.lookup_type = cv_lookup_type
        AND     look_val.lookup_code = lt_consumption_tax_class;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��          
          gv_tkn1   := xxccp_common_pkg.get_msg(cv_application, cv_msg_lookup_mst );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
          --�L�[�ҏW����
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code );
--          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type );
--          lv_key_data1 := lt_consumption_tax_class;
--          lv_key_data2 := cv_lookup_type;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code ), -- ���ږ��̂P
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type ), -- ���ږ��̂Q
            iv_data_value1 => lt_consumption_tax_class,         -- �f�[�^�̒l�P
            iv_data_value2 => cv_lookup_type,                   -- �f�[�^�̒l�Q
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
      END;
--
      --====================
      --����Ń}�X�^���擾
      --====================
      BEGIN
        SELECT avtab.tax_rate           -- ����ŗ�
        INTO   lt_tax_consum 
        FROM   ar_vat_tax_all_b avtab   -- AR����Ń}�X�^
        WHERE  avtab.tax_code = lt_consum_code
        AND    avtab.set_of_books_id = TO_NUMBER( gv_bks_id )
/*--==============2009/2/4-START=========================--*/
        AND    NVL( avtab.start_date, gd_process_date ) <= gd_process_date
        AND    NVL( avtab.end_date, gd_max_date ) >= gd_process_date
/*--==============2009/2/4-END==========================--*/
/*--==============2009/2/17-START=========================--*/
        AND    avtab.enabled_flag = cv_tkn_yes;
/*--==============2009/2/17--END==========================--*/
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��          
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_ar_tax_mst );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
          --�L�[�ҏW����
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax );
--          lv_key_name2 := NULL;
--          lv_key_data1 := lt_consum_code;
--          lv_key_data2 := NULL;
--          RAISE no_data_extract;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax ), -- ���ږ��̂P
            iv_data_value1 => lt_consum_code,         -- �f�[�^�̒l�P
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
      END;
        -- ����ŗ��Z�o
        ln_tax_data := ( (100 + lt_tax_consum) / 100 );
--
      -- =========================
      -- HHT�[�i���͓����̐��^����
      -- =========================
      ld_input_date :=TO_DATE(TO_CHAR( lt_dlv_date, cv_short_day )||cv_space_char||
                              SUBSTR(lt_dlv_time,1,2)||cv_tkn_ti||SUBSTR(lt_dlv_time,3,2), cv_stand_date );
--
      -- ==================================
      -- �o�׌��ۊǏꏊ�̓��o
      -- ==================================
--
      --�o�׌��ۊǏꏊ�̓��o
      BEGIN
        SELECT xca.dept_hht_div   -- HHT�S�ݓX���͋敪
        INTO   lv_depart_code
        FROM   hz_cust_accounts hca,  -- �ڋq�}�X�^
               xxcmm_cust_accounts xca  -- �ڋq�ǉ����
        WHERE  hca.cust_account_id = xca.customer_id
        AND    hca.account_number = lt_base_code
        AND    hca.customer_class_code = cv_bace_branch;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
          --�L�[�ҏW����
--          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
--          lv_key_data1 := lt_base_code;
--          lv_key_data2 := cv_bace_branch;
--        RAISE no_data_extract;
          lv_dept_hht_div_flg := cv_status_warn;
          lv_state_flg    := cv_status_warn;
          gn_wae_data_num := gn_wae_data_num + 1 ;
          xxcos_common_pkg.makeup_key_info(
            iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- ���ږ��̂P
            iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type ), -- ���ږ��̂Q
            iv_data_value1 => lt_base_code,         -- �f�[�^�̒l�P
            iv_data_value2 => cv_bace_branch,       -- �f�[�^�̒l�Q
            ov_key_info    => gv_tkn2,              -- �L�[���
            ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
            ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
            ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
          gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
      END;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      IF (lv_dept_hht_div_flg <> cv_status_warn) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
/*--==============2009/2/3-START=========================--*/
--      IF ( lv_depart_code = cv_depart_car ) THEN
        IF ( lv_depart_code IS NULL )
          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_base ) ) THEN
/*--==============2009/2/3-END==========================--*/
          --�Q�ƃR�[�h�}�X�^�F�c�ƎԂ̕ۊǏꏊ���ރR�[�h�擾
          BEGIN
            SELECT  look_val.meaning      --�ۊǏꏊ���ރR�[�h
            INTO    lt_location_type_code
            FROM    fnd_lookup_values     look_val,
                    fnd_lookup_types_tl   types_tl,
                    fnd_lookup_types      types,
                    fnd_application_tl    appl,
                    fnd_application       app
            WHERE   appl.application_id   = types.application_id
            AND     app.application_id    = appl.application_id
            AND     types_tl.lookup_type  = look_val.lookup_type
            AND     types.lookup_type     = types_tl.lookup_type
            AND     types.security_group_id   = types_tl.security_group_id
            AND     types.view_application_id = types_tl.view_application_id
            AND     types_tl.language = USERENV( 'LANG' )
            AND     look_val.language = USERENV( 'LANG' )
            AND     appl.language     = USERENV( 'LANG' )
            AND     gd_process_date      >= look_val.start_date_active
            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
            AND     app.application_short_name = cv_application
            AND     look_val.enabled_flag = cv_tkn_yes
            AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
            AND     look_val.lookup_code = cv_xxcos_001_a05_05;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
              --�L�[�ҏW�����p�ϐ�
              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_type );
              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_code );
              lv_key_data1 := cv_xxcos1_hokan_mst_001_a05;
              lv_key_data2 := cv_xxcos_001_a05_05;
            RAISE no_data_extract;
          END;
--
          --�ۊǏꏊ�}�X�^�f�[�^�擾
          BEGIN
            SELECT msi.secondary_inventory_name     -- �ۊǏꏊ�R�[�h
            INTO   lt_secondary_inventory_name
            FROM   mtl_secondary_inventories msi    --�ۊǏꏊ�}�X�^
            WHERE  msi.attribute7 = lt_base_code
            AND    msi.attribute13 = lt_location_type_code
            AND    msi.attribute3 = lt_dlv_by_code;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
              --�L�[�ҏW�����p�ϐ�
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--            lv_key_data1 := lt_base_code;
--            lv_key_data2 := cv_xxcos_001_a05_05;
--            RAISE no_data_extract;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            xxcos_common_pkg.makeup_key_info(
              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- ���ږ��̂P
              iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- ���ږ��̂Q
              iv_data_value1 => lt_base_code,         -- �f�[�^�̒l�P
              iv_data_value2 => cv_xxcos_001_a05_05,       -- �f�[�^�̒l�Q
              ov_key_info    => gv_tkn2,              -- �L�[���
              ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
              ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
              ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                  iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                  iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                  iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                  iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                  iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                  iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
          END;
--
/*--==============2009/2/3-START=========================--*/
        ELSIF ( lv_depart_code = cv_depart_type ) 
          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_dep ) )THEN
--        ELSIF ( lv_depart_code IS NOT NULL ) THEN
/*--==============2009/2/3-END==========================--*/
          --�Q�ƃR�[�h�}�X�^�F�S�ݓX�̕ۊǏꏊ���ރR�[�h�擾
          BEGIN
            SELECT  look_val.meaning    --�ۊǏꏊ���ރR�[�h
            INTO    lt_depart_location_type_code
            FROM    fnd_lookup_values     look_val,
                    fnd_lookup_types_tl   types_tl,
                    fnd_lookup_types      types,
                    fnd_application_tl    appl,
                    fnd_application       app
            WHERE   appl.application_id   = types.application_id
            AND     app.application_id    = appl.application_id
            AND     types_tl.lookup_type  = look_val.lookup_type
            AND     types.lookup_type     = types_tl.lookup_type
            AND     types.security_group_id   = types_tl.security_group_id
            AND     types.view_application_id = types_tl.view_application_id
            AND     types_tl.language = USERENV( 'LANG' )
            AND     look_val.language = USERENV( 'LANG' )
            AND     appl.language     = USERENV( 'LANG' )
            AND     gd_process_date      >= look_val.start_date_active
            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
            AND     app.application_short_name = cv_application
            AND     look_val.enabled_flag = cv_tkn_yes
            AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
            AND     look_val.lookup_code = cv_xxcos_001_a05_09;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
              --�L�[�ҏW�����p�ϐ��ݒ�
              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_type );
              lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_code );
              lv_key_data1 := cv_xxcos1_hokan_mst_001_a05;
              lv_key_data2 := cv_xxcos_001_a05_09;
            RAISE no_data_extract;
          END;
--
          --�ۊǏꏊ�}�X�^�f�[�^�擾
          BEGIN
            SELECT msi.secondary_inventory_name           -- �ۊǏꏊ����
            INTO   lt_secondary_inventory_name
            FROM   mtl_secondary_inventories msi,         -- �ۊǏꏊ�}�X�^
                   mtl_parameters mp                      -- �g�D�p�����[�^
            WHERE  msi.organization_id=mp.organization_id
            AND    mp.organization_code = gv_orga_code
            AND    msi.attribute4       = lt_keep_in_code
            AND    msi.attribute13      = lt_depart_location_type_code;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
              --�L�[�ҏW�����p�ϐ��ݒ�
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--            lv_key_data1 := lt_base_code;
--            lv_key_data2 := cv_xxcos_001_a05_09;
--            RAISE no_data_extract;
              lv_state_flg    := cv_status_warn;
              gn_wae_data_num := gn_wae_data_num + 1 ;
              xxcos_common_pkg.makeup_key_info(
                iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code ), -- ���ږ��̂P
                iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type ), -- ���ږ��̂Q
                iv_data_value1 => lt_base_code,         -- �f�[�^�̒l�P
                iv_data_value2 => cv_xxcos_001_a05_09,       -- �f�[�^�̒l�Q
                ov_key_info    => gv_tkn2,              -- �L�[���
                ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
                ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
                ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
              gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                  iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                  iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                  iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                  iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                  iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                  iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
          END;
--
        END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
--
      -- =============
      -- �[�i�`�ԋ敪�̓��o
      -- =============
      xxcos_common_pkg.get_delivered_from( lt_secondary_inventory_name,
                                           lt_base_code, 
                                           lt_base_code, 
                                           gv_orga_code,
                                           gn_orga_id,
                                           lv_delivery_type,
                                           lv_errbuf,
                                           lv_retcode,
                                           lv_errmsg );
      IF ( lv_retcode <> cv_status_normal ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--        RAISE delivered_from_err_expt;
        lv_state_flg    := cv_status_warn;
        gn_wae_data_num := gn_wae_data_num + 1 ;
        gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,
                                                iv_name          => cv_msg_delivered_from_err );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
      END IF;
--
      -- ===================
      -- �[�i���_�̓��o
      -- ===================
      BEGIN
        SELECT rin_v.base_code  --���_�R�[�h
        INTO lt_dlv_base_code
        FROM xxcos_rs_info_v rin_v   --�]�ƈ����view
        WHERE rin_v.employee_number = lt_dlv_by_code
/*--==============2009/2/3-START=========================--*/
        AND   NVL( rin_v.effective_start_date, lt_dlv_date) <= lt_dlv_date
        AND   NVL( rin_v.effective_end_date, lt_dlv_date)  >= lt_dlv_date;
/*--==============2009/2/3-END=========================--*/
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- ���O�o��
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_emp_data_mst );
            --�L�[�ҏW�p�ϐ��ݒ�
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv );
--            lv_key_name2 := NULL;
--            lv_key_data1 := lt_dlv_by_code;
--            lv_key_data2 := NULL;
--          RAISE no_data_extract;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            xxcos_common_pkg.makeup_key_info(
              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv ), -- ���ږ��̂P
              iv_data_value1 => lt_dlv_by_code,         -- �f�[�^�̒l�P
              ov_key_info    => gv_tkn2,              -- �L�[���
              ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
              ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
              ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
      END;
--
        -- =====================
        -- �[�i�`�[���͋敪�̓��o
        -- =====================
          BEGIN
            SELECT  DECODE( lt_cancel_correct_class, 
                            cv_stand_class, look_val.attribute4,    -- ����E�����敪���NULL�(�ʏ펞)(�̔����ѓ��͋敪)
                            cn_correct_class, look_val.attribute5,  -- ����E�����敪���1�(����)(�̔����ѓ��͋敪)
                            cn_cancel_class, look_val.attribute5)   -- ����E�����敪���2�(���)(�̔����ѓ��͋敪)
            INTO    lt_ins_invoice_type
            FROM    fnd_lookup_values     look_val,
                    fnd_lookup_types_tl   types_tl,
                    fnd_lookup_types      types,
                    fnd_application_tl    appl,
                    fnd_application       app
            WHERE   appl.application_id   = types.application_id
            AND     app.application_id    = appl.application_id
            AND     types_tl.lookup_type  = look_val.lookup_type
            AND     types.lookup_type     = types_tl.lookup_type
            AND     types.security_group_id   = types_tl.security_group_id
            AND     types.view_application_id = types_tl.view_application_id
            AND     types_tl.language = USERENV( 'LANG' )
            AND     look_val.language = USERENV( 'LANG' )
            AND     appl.language     = USERENV( 'LANG' )
            AND     gd_process_date      >= look_val.start_date_active
            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
            AND     app.application_short_name = cv_application
            AND     look_val.enabled_flag = cv_tkn_yes
            AND     look_val.lookup_type = cv_xxcos1_input_class
            AND     look_val.lookup_code = lt_input_class;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- ���O�o��          
              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
              --�L�[�ҏW�\�ϐ��ݒ�
--              lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
--              lv_key_name2 := NULL;
--              lv_key_data1 := lt_input_class;
--              lv_key_data2 := NULL;
--            RAISE no_data_extract;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            xxcos_common_pkg.makeup_key_info(
              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp ), -- ���ږ��̂P
              iv_data_value1 => lt_input_class,         -- �f�[�^�̒l�P
              ov_key_info    => gv_tkn2,              -- �L�[���
              ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
              ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
              ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                  iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                  iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                  iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                  iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                  iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                  iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
          END;
--
      --���׃f�[�^�擾
      <<line_loop>>
      FOR line_no IN ln_line_no..gn_line_cnt LOOP
        lt_lin_order_no_hht          := gt_dlv_hht_lines_data( line_no ).order_no_hht;          -- ��No.�iHHT�j
        lt_lin_line_no_hht           := gt_dlv_hht_lines_data( line_no ).line_no_hht;           -- �sNo.�iHHT�j
        lt_lin_digestion_ln_number   := gt_dlv_hht_lines_data( line_no ).digestion_ln_number;   -- �}��
        lt_lin_order_no_ebs          := gt_dlv_hht_lines_data( line_no ).order_no_ebs;          -- ��No.�iEBS�j
        lt_lin_line_number_ebs       := gt_dlv_hht_lines_data( line_no ).line_number_ebs;       -- ���הԍ��iEBS�j
        lt_lin_item_code_self        := gt_dlv_hht_lines_data( line_no ).item_code_self;        -- �i���R�[�h�i���Ёj
        lt_lin_content               := gt_dlv_hht_lines_data( line_no ).content;               -- ����
        lt_lin_inventory_item_id     := gt_dlv_hht_lines_data( line_no ).inventory_item_id;     -- �i��ID
        lt_lin_standard_unit         := gt_dlv_hht_lines_data( line_no ).standard_unit;         -- ��P��
        lt_lin_case_number           := gt_dlv_hht_lines_data( line_no ).case_number;           -- �P�[�X��
        lt_lin_quantity              := gt_dlv_hht_lines_data( line_no ).quantity;              -- ����
        lt_lin_sale_class            := gt_dlv_hht_lines_data( line_no ).sale_class;            -- ����敪
        lt_lin_wholesale_unit_ploce  := gt_dlv_hht_lines_data( line_no ).wholesale_unit_ploce;  -- ���P��
        lt_lin_selling_price         := gt_dlv_hht_lines_data( line_no ).selling_price;         -- ���P��
        lt_lin_column_no             := gt_dlv_hht_lines_data( line_no ).column_no;             -- �R����No.
        lt_lin_h_and_c               := gt_dlv_hht_lines_data( line_no ).h_and_c;               -- H/C
        lt_lin_sold_out_class        := gt_dlv_hht_lines_data( line_no ).sold_out_class;        -- ���؋敪
        lt_lin_sold_out_time         := gt_dlv_hht_lines_data( line_no ).sold_out_time;         -- ���؎���
        lt_lin_replenish_number      := gt_dlv_hht_lines_data( line_no ).replenish_number;      -- ��[��
        lt_lin_cash_and_card         := gt_dlv_hht_lines_data( line_no ).cash_and_card;         -- �����E�J�[�h���p�z
--
        EXIT WHEN ( ( lt_order_no_hht || lt_digestion_ln_number ) <> ( lt_lin_order_no_hht || lt_lin_digestion_ln_number ) );
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        ln_line_data_count := ln_line_data_count + 1;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--        -- ===================
--        -- �o�^�p����ID�擾
--        -- ===================
--        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
--        INTO   ln_sales_exp_line_id
--        FROM   DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
--
        --====================================
        --�c�ƌ����̓��o(�̔����і���(�R����))
        --====================================
        BEGIN
          SELECT ic_item.attribute7,              -- ���c�ƌ���
                 ic_item.attribute8,              -- �V�c�ƌ���
                 ic_item.attribute9,              -- �c�ƌ����K�p�J�n��
                 mtl_item.primary_unit_of_measure,     -- ��P��
                 cmm_item.inc_num                  -- �������
          INTO   lt_old_sales_cost,
                 lt_new_sales_cost,
                 lt_st_sales_cost,
                 lt_stand_unit,
                 lt_inc_num
          FROM   mtl_system_items_b    mtl_item,    -- �i��
                 ic_item_mst_b         ic_item,     -- OPM�i��
                 xxcmm_system_items_b  cmm_item     -- Disc�i�ڃA�h�I��
          WHERE  mtl_item.organization_id   = gn_orga_id
          AND  mtl_item.segment1 = lt_lin_item_code_self
          AND  mtl_item.segment1 = ic_item.item_no
          AND  mtl_item.segment1 = cmm_item.item_code
          AND  cmm_item.item_id  = ic_item.item_id
/*--==============2009/2/4-START=========================--*/
          AND    NVL( mtl_item.start_date_active, gd_process_date) <= gd_process_date
          AND    NVL( mtl_item.end_date_active, gd_max_date ) >= gd_process_date;
/*--==============2009/2/4-END==========================--*/
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���O�o��
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_inv_item_mst );
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
--            lv_key_data1 := lt_lin_item_code_self;
--            lv_key_data2 := gn_orga_id;
--            RAISE no_data_extract;
            lv_state_flg    := cv_status_warn;
            gn_wae_data_num := gn_wae_data_num + 1 ;
            xxcos_common_pkg.makeup_key_info(
              iv_item_name1  => xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code ), -- ���ږ��̂P
              iv_item_name2  => xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id ), -- ���ږ��̂Q
              iv_data_value1 => lt_lin_item_code_self,         -- �f�[�^�̒l�P
              iv_data_value2 => gn_orga_id,       -- �f�[�^�̒l�Q
              ov_key_info    => gv_tkn2,              -- �L�[���
              ov_errbuf      => lv_errbuf,            -- �G���[�E���b�Z�[�W�G���[
              ov_retcode     => lv_retcode,           -- ���^�[���E�R�[�h
              ov_errmsg      => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
            gt_msg_war_data(gn_wae_data_num) := xxccp_common_pkg.get_msg(
                                                iv_application   => cv_application,    --�A�v���P�[�V�����Z�k��
                                                iv_name          => cv_msg_no_data,    --���b�Z�[�W�R�[�h
                                                iv_token_name1   => cv_tkn_table_name, --�g�[�N���R�[�h1
                                                iv_token_value1  => gv_tkn1,           --�g�[�N���l1
                                                iv_token_name2   => cv_key_data,       --�g�[�N���R�[�h2
                                                iv_token_value2  => gv_tkn2 );         --�g�[�N���l2
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END *****************************************
        END;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        IF ( lv_state_flg <> cv_status_warn ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
          -- ===================================
          -- �c�ƌ�������
          -- ===================================
          IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_dlv_date ) THEN
            lt_sales_cost := lt_old_sales_cost;
          ELSE
            lt_sales_cost := lt_new_sales_cost;
          END IF;
--
          -- ============
          -- ���׋��z�Z�o
          -- ============
          -- ��P��
          lt_standard_unit_price   := lt_lin_wholesale_unit_ploce;
--
          IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- ��ې�
--
            -- ������z
            lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
            -- �{�̋��z
            lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- ����ŋ��z
            lt_tax_amount            := cn_cons_tkn_zero;
--
          ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
            -- ������z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_sale_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
--                                        * ln_tax_data );
--          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_sale_amount := TRUNC( lt_sale_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount := ROUND( lt_sale_amount );
--            END IF;
--          END IF;
            ln_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_sale_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_sale_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_sale_amount   := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
            -- �{�̋��z
            lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- ����ŋ��z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_tax_amount            := (  ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
--          IF ( lt_tax_amount <> TRUNC( lt_tax_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_tax_amount := ( TRUNC( lt_tax_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_tax_amount := TRUNC( lt_tax_amount );
--          -- �l�̌ܓ�
--          ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--            lt_tax_amount := ROUND( lt_tax_amount );
--          END IF;
--        END IF;
--        ln_amount            := (  ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
            ln_amount            := lt_pure_amount * ( ln_tax_data - 1 );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_tax_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_tax_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_tax_amount   := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
--
          ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
          -- ������z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_sale_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
--                                        * ln_tax_data );
--          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_sale_amount := TRUNC( lt_sale_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount := ROUND( lt_sale_amount );
--            END IF;
--          END IF;
            ln_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_sale_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_sale_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_sale_amount   := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
           -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
            -- �{�̋��z
            lt_pure_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- ����ŋ��z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_tax_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
--          IF ( lt_tax_amount <> TRUNC( lt_tax_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_tax_amount := ( TRUNC( lt_tax_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_tax_amount := TRUNC( lt_tax_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_tax_amount := ROUND( lt_tax_amount );
--            END IF;
--          END IF;
--          ln_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
            ln_amount            := lt_pure_amount * ( ln_tax_data - 1 );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_tax_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_tax_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_tax_amount   := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
--
          ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--
            -- ������z
            lt_sale_amount           := TRUNC( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
            -- �Ŕ���P��
            lt_stand_unit_price_excl := ( lt_lin_wholesale_unit_ploce / ln_tax_data );
            IF ( lt_stand_unit_price_excl <> TRUNC( lt_stand_unit_price_excl ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_stand_unit_price_excl := ( TRUNC( lt_stand_unit_price_excl ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_stand_unit_price_excl := TRUNC( lt_stand_unit_price_excl );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_stand_unit_price_excl := ROUND( lt_stand_unit_price_excl );
              END IF;
            END IF;
            -- �{�̋��z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_pure_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
--          IF ( lt_pure_amount <> TRUNC( lt_pure_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_pure_amount := ( TRUNC( lt_pure_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_pure_amount := TRUNC( lt_pure_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_pure_amount := ROUND( lt_pure_amount );
--            END IF;
--          END IF;
            ln_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_pure_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_pure_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_pure_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_pure_amount   := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- ����ŋ��z
            lt_tax_amount            := TRUNC( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
                                         - lt_pure_amount );
--
          END IF;
--
          -- ��ېŎ��ȊO
          IF ( lt_consumption_tax_class <> cv_non_tax ) THEN
            -- ����ō��v�Ϗグ
              ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
            -- ���׍ő����Ŏ擾
            IF ( ln_max_tax_data < lt_tax_amount ) THEN
              ln_max_tax_data := lt_tax_amount;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--              ln_max_no_data  := gn_line_data_no;
              ln_max_no_data  := ln_line_data_count;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
            END IF;
          END IF;
--
          -- ���׍ő�sNo�m�F
          IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
            IF ( ln_max_invoice_num IS NULL) OR ( ln_max_invoice_num < lt_lin_line_no_hht ) THEN
              ln_max_invoice_num := lt_lin_line_no_hht;
            END IF;
          END IF;
--
          -- �ԁE���̋��z���Z
          --���̎�
          IF ( lt_red_black_flag = cv_black_flag) THEN
            -- �����(�[�i����)
            lt_set_replenish_number := lt_lin_replenish_number;
            -- ������z
            lt_set_sale_amount := lt_sale_amount;
            -- �{�̋��z
            lt_set_pure_amount := lt_pure_amount;
            -- ����ŋ��z
            lt_set_tax_amount := lt_tax_amount;
          -- �Ԃ̎�
          ELSIF ( lt_red_black_flag = cv_red_flag) THEN
            -- �����(�[�i����)
            lt_set_replenish_number := ( lt_lin_replenish_number * ( -1 ) );
            -- ������z
            lt_set_sale_amount := ( lt_sale_amount * ( -1 ) );
            -- �{�̋��z
            lt_set_pure_amount := ( lt_pure_amount * ( -1 ) );
            -- ����ŋ��z
            lt_set_tax_amount := ( lt_tax_amount * ( -1 ) );
          END IF;
        --====================
        --���׃f�[�^�̕ϐ��}��
        --====================
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--        gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- �̔����і���ID
--        gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- �̔����уw�b�_ID
--        gt_line_dlv_invoice_number( gn_line_data_no )      := lt_hht_invoice_no;            -- �[�i�`�[�ԍ�
--        gt_line_dlv_invoice_l_num( gn_line_data_no )       := lt_lin_line_no_hht;           -- �[�i���הԍ�
--        gt_line_sales_class( gn_line_data_no )             := lt_lin_sale_class;            -- ����敪
--        gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;            -- �ԍ��t���O
--        gt_line_item_code( gn_line_data_no )               := lt_lin_item_code_self;        -- �i�ڃR�[�h
--        gt_line_standard_qty( gn_line_data_no )            := lt_set_replenish_number;      -- �����
--        gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;                -- ��P��
--        gt_line_standard_unit_price( gn_line_data_no )     := lt_standard_unit_price;       -- ��P��
--        gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero ); -- �c�ƌ���
--        gt_line_sale_amount( gn_line_data_no )             := lt_set_sale_amount;           -- ������z
--        gt_line_pure_amount( gn_line_data_no )             := lt_set_pure_amount;           -- �{�̋��z
--        gt_line_tax_amount( gn_line_data_no )              := lt_set_tax_amount;            -- ����ŋ��z
--        gt_line_cash_and_card( gn_line_data_no )           := lt_lin_cash_and_card;         -- �����E�J�[�h���p�z
--        gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_secondary_inventory_name;  -- �o�׌��ۊǏꏊ
--        gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;             -- �[�i���_�R�[�h
--        gt_line_hot_cold_class( gn_line_data_no )          := lt_lin_h_and_c;               -- �g���b
--        gt_line_column_no( gn_line_data_no )               := lt_lin_column_no;             -- �R����No
--        gt_line_sold_out_class( gn_line_data_no )          := lt_lin_sold_out_class;        -- ���؋敪
--        gt_line_sold_out_time( gn_line_data_no )           := lt_lin_sold_out_time;         -- ���؎���
--        gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                     -- �萔���v�Z-IF�σt���O
--        gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                     -- �P���}�X�^�쐬�σt���O
--        gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                     -- INV-IF�σt���O
--        gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;                  -- �������הԍ�(NULL�ݒ�)
--        gt_line_not_tax_amount( gn_line_data_no )          := lt_stand_unit_price_excl;     -- �Ŕ���P��
--        gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;             -- �[�i�`�ԋ敪
--        gt_line_dlv_qty( gn_line_data_no )                 := lt_set_replenish_number;      -- �[�i����
--        gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;                -- �[�i�P��
--        gt_dlv_unit_price( gn_line_data_no )               := lt_standard_unit_price;       -- �[�i�P��
--        gn_line_data_no := gn_line_data_no + 1;
          -- ===================
          -- �ꎞ�i�[�p
          -- ===================
          gt_accumulation_data(ln_line_data_count).dlv_invoice_number         := lt_hht_invoice_no;             -- �[�i�`�[�ԍ�
          gt_accumulation_data(ln_line_data_count).dlv_invoice_line_number    := lt_lin_line_no_hht;            -- �[�i���הԍ�
          gt_accumulation_data(ln_line_data_count).sales_class                := lt_lin_sale_class;             -- ����敪
          gt_accumulation_data(ln_line_data_count).red_black_flag             := lt_red_black_flag;             -- �ԍ��t���O
          gt_accumulation_data(ln_line_data_count).item_code                  := lt_lin_item_code_self;         -- �i�ڃR�[�h
          gt_accumulation_data(ln_line_data_count).dlv_qty                    := lt_set_replenish_number;       -- �[�i����
          gt_accumulation_data(ln_line_data_count).standard_qty               := lt_set_replenish_number;       -- �����
          gt_accumulation_data(ln_line_data_count).dlv_uom_code               := lt_stand_unit;                 -- �[�i�P��
          gt_accumulation_data(ln_line_data_count).standard_uom_code          := lt_stand_unit;                 -- ��P��
          gt_accumulation_data(ln_line_data_count).dlv_unit_price             := lt_standard_unit_price;        -- �[�i�P��
          gt_accumulation_data(ln_line_data_count).standard_unit_price        := lt_standard_unit_price;        -- ��P��
          gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- �c�ƌ���
          gt_accumulation_data(ln_line_data_count).sale_amount                := lt_set_sale_amount;            -- ������z
          gt_accumulation_data(ln_line_data_count).pure_amount                := lt_set_pure_amount;            -- �{�̋��z
          gt_accumulation_data(ln_line_data_count).tax_amount                 := lt_set_tax_amount;             -- ����ŋ��z
          gt_accumulation_data(ln_line_data_count).cash_and_card              := lt_lin_cash_and_card;          -- �����E�J�[�h���p�z
          gt_accumulation_data(ln_line_data_count).ship_from_subinventory_code := lt_secondary_inventory_name;  -- �o�׌��ۊǏꏊ
          gt_accumulation_data(ln_line_data_count).delivery_base_code         := lt_dlv_base_code;              -- �[�i���_�R�[�h
          gt_accumulation_data(ln_line_data_count).hot_cold_class             := lt_lin_h_and_c;                -- �g���b
          gt_accumulation_data(ln_line_data_count).column_no                  := lt_lin_column_no;              -- �R����No
          gt_accumulation_data(ln_line_data_count).sold_out_class             := lt_lin_sold_out_class;         -- ���؋敪
          gt_accumulation_data(ln_line_data_count).sold_out_time              := lt_lin_sold_out_time;          -- ���؎���
          gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                      -- �萔���v�Z�C���^�t�F�[�X�σt���O
          gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                      -- �P���}�X�^�쐬�σt���O
          gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                      -- INV�C���^�t�F�[�X�σt���O
          gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;                   -- �������הԍ�(NULL�ݒ�)
          gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := lt_stand_unit_price_excl;    -- �Ŕ���P��
          gt_accumulation_data(ln_line_data_count).delivery_pattern_class     :=   lv_delivery_type;            -- �[�i�`�ԋ敪(���o)
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
        ln_line_no := ln_line_no + 1;
--
      END LOOP line_loop;
--
      -- =======================================
      -- �l�����z���א���(A-8)
      -- =======================================
      -- �l�������������Ă���ꍇ
      IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        ln_line_data_count := ln_line_data_count + 1;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--        -- ===================
--        -- �o�^�p����ID�擾
--        -- ===================
--        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
--        INTO   ln_sales_exp_line_id
--        FROM   DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
--
        -- =================================
        -- �c�ƌ����A��P�ʂ𓱏o
        -- =================================
        BEGIN
          SELECT ic_item.attribute7,              -- ���c�ƌ���
                 ic_item.attribute8,              -- �V�c�ƌ���
                 ic_item.attribute9,              -- �c�ƌ����K�p�J�n��
                 mtl_item.primary_unit_of_measure -- ��P��
          INTO   lt_old_sales_cost,
                 lt_new_sales_cost,
                 lt_st_sales_cost,
                 lt_stand_unit
          FROM   mtl_system_items_b    mtl_item,    -- �i��
                 ic_item_mst_b         ic_item,     -- OPM�i��
                 xxcmm_system_items_b  cmm_item     -- Disc�i�ڃA�h�I��
          WHERE  mtl_item.organization_id   = gn_orga_id
          AND  mtl_item.segment1 = gv_disc_item
          AND  mtl_item.segment1 = ic_item.item_no
          AND  mtl_item.segment1 = cmm_item.item_code
          AND  cmm_item.item_id  = ic_item.item_id
/*--==============2009/2/4-START=========================--*/
          AND    NVL( mtl_item.start_date_active, gd_process_date) <= gd_process_date
          AND    NVL( mtl_item.end_date_active, gd_max_date ) >= gd_process_date;
/*--==============2009/2/4-END==========================--*/
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --�L�[�ҏW����
            -- ���O�o��
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_inv_item_mst );
            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
            lv_key_data1 := gv_disc_item;
            lv_key_data2 := gn_orga_id;
            RAISE no_data_extract;
        END;
        -- ===================================
        -- �c�ƌ�������
        -- ===================================
        IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > lt_dlv_date ) THEN
          lt_sales_cost := lt_old_sales_cost;
        ELSE
          lt_sales_cost := lt_new_sales_cost;
        END IF;
--
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--/*--==============2009/2/3-START=========================--*/
----        IF ( lv_depart_code = cv_depart_car ) THEN
--        IF ( lv_depart_code IS NULL )
--          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_base ) ) THEN
--/*--==============2009/2/3-END==========================--*/
----
--          --�ۊǏꏊ�}�X�^�f�[�^�擾
--          BEGIN
--            SELECT msi.secondary_inventory_name     -- �ۊǏꏊ�R�[�h
--            INTO   lt_secondary_inventory_name
--            FROM   mtl_secondary_inventories msi    --�ۊǏꏊ�}�X�^
--            WHERE  msi.attribute7 = lt_base_code
--            AND    msi.attribute13 = lt_location_type_code;
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              -- ���O�o��          
--              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
--            --�L�[�ҏW�����p�ϐ�
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--            lv_key_data1 := lt_base_code;
--            lv_key_data2 := cv_xxcos_001_a05_05;
--          RAISE no_data_extract;
--          END;
--
--/*--==============2009/2/3-START=========================--*/
----        ELSIF ( lv_depart_code = cv_depart_type ) THEN
----        ELSIF ( lv_depart_code IS NOT NULL ) THEN
--        ELSIF ( lv_depart_code = cv_depart_type ) 
--          OR (( lv_depart_code = cv_depart_type_k ) AND ( lt_department_screen_class = cv_depart_screen_class_dep ) )THEN
--/*--==============2009/2/3-END==========================--*/
----
--          --�ۊǏꏊ�}�X�^�f�[�^�擾
--          BEGIN
--            SELECT msi.secondary_inventory_name           -- �ۊǏꏊ����
--            INTO   lt_secondary_inventory_name
--            FROM   mtl_secondary_inventories msi,         -- �ۊǏꏊ�}�X�^
--                   mtl_parameters mp                      -- �g�D�p�����[�^
--            WHERE  msi.organization_id=mp.organization_id
--            AND    mp.organization_code = gv_orga_code
--            AND    msi.attribute4       = lt_keep_in_code
--            AND    msi.attribute13      = lt_depart_location_type_code;
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              -- ���O�o��
--              gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
--              --�L�[�ҏW�����p�ϐ��ݒ�
--            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_base_code );
--            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
--            lv_key_data1 := lt_base_code;
--            lv_key_data2 := cv_xxcos_001_a05_09;
--          RAISE no_data_extract;
--          END;
--
--        END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END *****************************************
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        IF ( lv_state_flg <> cv_status_warn ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END *****************************************
          -- ================
          -- ���z�Z�o����
          -- ================
          IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- ��ې�
--
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_sale_discount_amount;
            -- ��P��
            lt_standard_unit_price   := lt_sale_discount_amount;
            -- ������z
            lt_sale_amount           := TRUNC( lt_sale_discount_amount );
            -- �{�̋��z
            lt_pure_amount           := TRUNC( lt_sale_discount_amount );
            -- ����ŋ��z
            lt_tax_amount            := cn_cons_tkn_zero;
--
          ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_sale_discount_amount;
            -- ��P��
            lt_standard_unit_price   := lt_sale_discount_amount;
            -- ������z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_sale_amount           := ( lt_sale_discount_amount * ln_tax_data);
--          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_sale_amount := TRUNC( lt_sale_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount := ROUND( lt_sale_amount );
--            END IF;
--          END IF;
            ln_amount           := lt_sale_discount_amount;
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_sale_amount := TRUNC( ln_amount );
             -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_sale_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_sale_amount   := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- �{�̋��z
            lt_pure_amount           := TRUNC( lt_sale_discount_amount );
            -- ����ŋ��z
            ln_amount            := ( lt_sale_discount_amount * ( ln_tax_data - 1 ) );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_tax_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_tax_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_tax_amount   := ln_amount;
            END IF;
--
          ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
            -- �Ŕ���P��
            lt_stand_unit_price_excl := lt_sale_discount_amount;
            -- ��P��
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_standard_unit_price   := ( lt_sale_discount_amount * ln_tax_data );
--          IF ( lt_standard_unit_price <> TRUNC( lt_standard_unit_price ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_standard_unit_price := ( TRUNC( lt_standard_unit_price ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_standard_unit_price := TRUNC( lt_standard_unit_price );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_standard_unit_price := ROUND( lt_standard_unit_price );
--            END IF;
--          END IF;
--          ln_amount   := ( lt_sale_discount_amount * ln_tax_data );
--          IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_standard_unit_price := ( TRUNC( ln_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_standard_unit_price := TRUNC( ln_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_standard_unit_price := ROUND( ln_amount );
--            END IF;
--          END IF;
            lt_standard_unit_price := ( lt_sale_discount_amount );
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
          -- ������z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_sale_amount           := ( lt_sale_discount_amount * ln_tax_data);
--          IF ( lt_sale_amount <> TRUNC( lt_sale_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount := ( TRUNC( lt_sale_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_sale_amount := TRUNC( lt_sale_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_sale_amount := ROUND( lt_sale_amount );
--            END IF;
--          END IF;
            ln_amount           := lt_sale_discount_amount;
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_sale_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_sale_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_sale_amount   := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- �{�̋��z
            lt_pure_amount           := TRUNC( lt_sale_discount_amount );
            -- ����ŋ��z
            ln_amount            := ( lt_sale_discount_amount * ( ln_tax_data - 1 ) );
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_tax_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_tax_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_tax_amount   := ln_amount;
            END IF;
--
          ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--
            -- �Ŕ���P��
            lt_stand_unit_price_excl := ( lt_sale_discount_amount / ln_tax_data);
            IF ( lt_stand_unit_price_excl <> TRUNC( lt_stand_unit_price_excl ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_stand_unit_price_excl := ( TRUNC( lt_stand_unit_price_excl ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_stand_unit_price_excl := TRUNC( lt_stand_unit_price_excl );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_stand_unit_price_excl := ROUND( lt_stand_unit_price_excl );
              END IF;
            END IF;
            -- ��P��
            lt_standard_unit_price   := lt_sale_discount_amount;
            -- ������z
            lt_sale_amount           := TRUNC( lt_sale_discount_amount );
            -- �{�̋��z
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--          lt_pure_amount           := ( lt_sale_discount_amount / ln_tax_data);
--          IF ( lt_pure_amount <> TRUNC( lt_pure_amount ) ) THEN
--            IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_pure_amount := ( TRUNC( lt_pure_amount ) + 1 );
--            -- �؎̂�
--            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--              lt_pure_amount := TRUNC( lt_pure_amount );
--            -- �l�̌ܓ�
--            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--              lt_pure_amount := ROUND( lt_pure_amount );
--            END IF;
--          END IF;
            ln_amount           := ( lt_sale_discount_amount / ln_tax_data);
            IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
              IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_pure_amount := ( TRUNC( ln_amount ) + 1 );
              -- �؎̂�
              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                lt_pure_amount := TRUNC( ln_amount );
              -- �l�̌ܓ�
              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                lt_pure_amount := ROUND( ln_amount );
              END IF;
            ELSE
              lt_pure_amount   := ln_amount;
            END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- ����ŋ��z
            lt_tax_amount            := TRUNC( lt_sale_amount - lt_pure_amount );
          END IF;
--
          -- �l���p�[�i���הԍ��ݒ�
          ln_max_invoice_num := ln_max_invoice_num + 1;
          -- �o�^�p�l�����z�ݒ�
          lt_sale_amount := ( lt_sale_amount * ( -1 ) );
          lt_pure_amount := ( lt_pure_amount * ( -1 ) );
          lt_tax_amount  := ( lt_tax_amount * ( -1 ) );
--
          -- �ԁE���̋��z���Z
          --���̎�
          IF ( lt_red_black_flag = cv_black_flag) THEN
            -- �����(�[�i����)
            lt_set_replenish_number := cn_disc_standard_qty;
            -- ������z
            lt_set_sale_amount := lt_sale_amount;
            -- �{�̋��z
            lt_set_pure_amount := lt_pure_amount;
            -- ����ŋ��z
            lt_set_tax_amount := lt_tax_amount;
          -- �Ԃ̎�
          ELSIF ( lt_red_black_flag = cv_red_flag) THEN
            -- �����(�[�i����)
            lt_set_replenish_number := ( cn_disc_standard_qty * ( -1 ) );
            -- ������z
            lt_set_sale_amount := ( lt_sale_amount * ( -1 ) );
            -- �{�̋��z
            lt_set_pure_amount := ( lt_pure_amount * ( -1 ) );
            -- ����ŋ��z
            lt_set_tax_amount := ( lt_tax_amount * ( -1 ) );
          END IF;
          -- =========================================
          -- �l�������׃f�[�^�Z�b�g
          -- =========================================
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--          gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- �̔����і���ID
--          gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- �̔����уw�b�_ID
--          gt_line_dlv_invoice_number( gn_line_data_no )      := lt_hht_invoice_no;            -- �[�i�`�[�ԍ�
--          gt_line_dlv_invoice_l_num( gn_line_data_no )       := ln_max_invoice_num;           -- �[�i���הԍ�
--          gt_line_sales_class( gn_line_data_no )             := cv_sales_st_class;            -- ����敪
--          gt_line_red_black_flag( gn_line_data_no )          := lt_red_black_flag;            -- �ԍ��t���O
--          gt_line_item_code( gn_line_data_no )               := gv_disc_item;                 -- �i�ڃR�[�h
--          gt_line_standard_qty( gn_line_data_no )            := lt_set_replenish_number;      -- �����
--          gt_line_standard_uom_code( gn_line_data_no )       := lt_stand_unit;                -- ��P��
--          gt_line_standard_unit_price( gn_line_data_no )     := lt_standard_unit_price;       -- ��P��
--          gt_line_business_cost( gn_line_data_no )           := NVL ( lt_sales_cost , cn_tkn_zero ); -- �c�ƌ���
--          gt_line_sale_amount( gn_line_data_no )             := lt_set_sale_amount;           -- ������z
--          gt_line_pure_amount( gn_line_data_no )             := lt_set_pure_amount;           -- �{�̋��z
--          gt_line_tax_amount( gn_line_data_no )              := lt_set_tax_amount;            -- ����ŋ��z
--          gt_line_cash_and_card( gn_line_data_no )           := cn_tkn_zero;                  -- �����E�J�[�h���p�z
--          gt_line_ship_from_subinv_co( gn_line_data_no )     := lt_secondary_inventory_name;  -- �o�׌��ۊǏꏊ
--          gt_line_delivery_base_code( gn_line_data_no )      := lt_dlv_base_code;             -- �[�i���_�R�[�h
--          gt_line_hot_cold_class( gn_line_data_no )          := cv_tkn_null;                  -- �g���b
--          gt_line_column_no( gn_line_data_no )               := cv_tkn_null;                  -- �R����No
--          gt_line_sold_out_class( gn_line_data_no )          := cv_tkn_null;                  -- ���؋敪
--          gt_line_sold_out_time( gn_line_data_no )           := cv_tkn_null;                  -- ���؎���
--          gt_line_to_calculate_fees_flag( gn_line_data_no )  := cv_tkn_n;                     -- �萔���v�ZIF�σt���O
--          gt_line_unit_price_mst_flag( gn_line_data_no )     := cv_tkn_n;                     -- �P���}�X�^�쐬�σt���O
--          gt_line_inv_interface_flag( gn_line_data_no )      := cv_tkn_n;                     -- INV�C���^�t�F�[�X�σt���O
--          gt_line_order_invoice_l_num( gn_line_data_no )     := cv_tkn_null;                  -- �������הԍ�(NULL�ݒ�)
--          gt_line_not_tax_amount( gn_line_data_no )          := lt_stand_unit_price_excl;     -- �Ŕ���P��
--          gt_line_delivery_pat_class( gn_line_data_no )      := lv_delivery_type;             -- �[�i�`�ԋ敪
--          gt_line_dlv_qty( gn_line_data_no )                 := lt_set_replenish_number;      -- �[�i����
--          gt_line_dlv_uom_code( gn_line_data_no )            := lt_stand_unit;                -- �[�i�P��
--          gt_dlv_unit_price( gn_line_data_no )               := lt_standard_unit_price;       -- �[�i�P��
--          gn_line_data_no := gn_line_data_no + 1;
          -- ===================
          -- �ꎞ�i�[�p
          -- ===================
          gt_accumulation_data(ln_line_data_count).dlv_invoice_number         := lt_hht_invoice_no;             -- �[�i�`�[�ԍ�
          gt_accumulation_data(ln_line_data_count).dlv_invoice_line_number    := ln_max_invoice_num;            -- �[�i���הԍ�
          gt_accumulation_data(ln_line_data_count).sales_class                := cv_sales_st_class;             -- ����敪
          gt_accumulation_data(ln_line_data_count).red_black_flag             := lt_red_black_flag;             -- �ԍ��t���O
          gt_accumulation_data(ln_line_data_count).item_code                  := gv_disc_item;                  -- �i�ڃR�[�h
          gt_accumulation_data(ln_line_data_count).dlv_qty                    := lt_set_replenish_number;       -- �[�i����
          gt_accumulation_data(ln_line_data_count).standard_qty               := lt_set_replenish_number;       -- �����
          gt_accumulation_data(ln_line_data_count).dlv_uom_code               := lt_stand_unit;                 -- �[�i�P��
          gt_accumulation_data(ln_line_data_count).standard_uom_code          := lt_stand_unit;                 -- ��P��
          gt_accumulation_data(ln_line_data_count).dlv_unit_price             := lt_standard_unit_price;        -- �[�i�P��
          gt_accumulation_data(ln_line_data_count).standard_unit_price        := lt_standard_unit_price;        -- ��P��
          gt_accumulation_data(ln_line_data_count).business_cost              := NVL ( lt_sales_cost , cn_tkn_zero );-- �c�ƌ���
          gt_accumulation_data(ln_line_data_count).sale_amount                := lt_set_sale_amount;            -- ������z
          gt_accumulation_data(ln_line_data_count).pure_amount                := lt_set_pure_amount;            -- �{�̋��z
          gt_accumulation_data(ln_line_data_count).tax_amount                 := lt_set_tax_amount;             -- ����ŋ��z
          gt_accumulation_data(ln_line_data_count).cash_and_card              := cn_tkn_zero;                   -- �����E�J�[�h���p�z
          gt_accumulation_data(ln_line_data_count).ship_from_subinventory_code := lt_secondary_inventory_name;  -- �o�׌��ۊǏꏊ
          gt_accumulation_data(ln_line_data_count).delivery_base_code         := lt_dlv_base_code;              -- �[�i���_�R�[�h
          gt_accumulation_data(ln_line_data_count).hot_cold_class             := cv_tkn_null;                   -- �g���b
          gt_accumulation_data(ln_line_data_count).column_no                  := cv_tkn_null;                   -- �R����No
          gt_accumulation_data(ln_line_data_count).sold_out_class             := cv_tkn_null;                   -- ���؋敪
          gt_accumulation_data(ln_line_data_count).sold_out_time              := cv_tkn_null;                   -- ���؎���
          gt_accumulation_data(ln_line_data_count).to_calculate_fees_flag     := cv_tkn_n;                      -- �萔���v�Z�C���^�t�F�[�X�σt���O
          gt_accumulation_data(ln_line_data_count).unit_price_mst_flag        := cv_tkn_n;                      -- �P���}�X�^�쐬�σt���O
          gt_accumulation_data(ln_line_data_count).inv_interface_flag         := cv_tkn_n;                      -- INV�C���^�t�F�[�X�σt���O
          gt_accumulation_data(ln_line_data_count).order_invoice_line_number  := cv_tkn_null;                   -- �������הԍ�(NULL�ݒ�)
          gt_accumulation_data(ln_line_data_count).standard_unit_price_excluded := lt_stand_unit_price_excl;    -- �Ŕ���P��
          gt_accumulation_data(ln_line_data_count).delivery_pattern_class     := lv_delivery_type;              -- �[�i�`�ԋ敪(���o)
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--
      END IF;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
      IF ( lv_state_flg <> cv_status_warn ) THEN
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--
        -- ==================
        -- �w�b�_�o�^�p���z�Z�o
        -- ==================
        IF ( lt_consumption_tax_class = cv_non_tax ) THEN           -- ��ې�
--
          -- ������z���v
          lt_sale_amount_sum := lt_total_amount;
          -- �{�̋��z���v
          lt_pure_amount_sum := lt_total_amount;
          -- ����ŋ��z���v
          lt_tax_amount_sum  := lt_sales_consumption_tax;
        ELSE
         --�l��������
          IF ( lt_sale_discount_amount <> 0 ) AND ( lt_sale_discount_amount IS NOT NULL ) THEN
--
            IF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
              -- ������z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_sale_amount_sum := ( lt_tax_include * ln_tax_data );
--              IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
--                IF ( lt_tax_odd = cv_amount_up ) THEN
--                lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
--                -- �؎̂�
--                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                  lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
--                -- �l�̌ܓ�
--                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
--                END IF;
--              END IF;
              ln_amount := lt_tax_include;
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
                  lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                  -- �؎̂�
                  ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                    lt_sale_amount_sum := TRUNC( ln_amount );
                  -- �l�̌ܓ�
                  ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                    lt_sale_amount_sum := ROUND( ln_amount );
                  END IF;
                ELSE
                  lt_sale_amount_sum := ln_amount;
                END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
                -- �{�̋��z���v
                lt_pure_amount_sum := lt_tax_include;
                -- ����ŋ��z���v
                ln_amount  := ( lt_sale_amount_sum * ( ln_tax_data - 1 ) );
                IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                  IF ( lt_tax_odd = cv_amount_up ) THEN
                  lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
                  -- �؎̂�
                  ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                    lt_tax_amount_sum := TRUNC( ln_amount );
                  -- �l�̌ܓ�
                  ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                    lt_tax_amount_sum := ROUND( ln_amount );
                  END IF;
                ELSE
                  lt_tax_amount_sum := ln_amount;
                END IF;
--
            ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
              -- ������z���v
              lt_sale_amount_sum := lt_tax_include;
              -- �{�̋��z���v
              lt_pure_amount_sum := ( lt_total_amount - lt_sale_discount_amount );
              -- ����ŋ��z���v
              lt_tax_amount_sum  := lt_sales_consumption_tax;
--
            ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--
              -- ������z���v
              lt_sale_amount_sum := lt_tax_include;
              -- �{�̋��z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_pure_amount_sum := ( lt_tax_include / ln_tax_data );
--            IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--                lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                 lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
--              END IF;
--            END IF;
              ln_amount := ( lt_tax_include / ln_tax_data );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                  lt_pure_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_pure_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_pure_amount_sum:= ROUND( ln_amount );
                END IF;
              ELSE
                lt_pure_amount_sum   := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- �l������ŎZ�o
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            ln_discount_tax    := ( lt_sale_discount_amount - ( lt_sale_discount_amount / ln_tax_data ) );
--            IF ( ln_discount_tax <> TRUNC( ln_discount_tax ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--                ln_discount_tax := ( TRUNC( ln_discount_tax ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                ln_discount_tax := TRUNC( ln_discount_tax );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                 ln_discount_tax:= ROUND( ln_discount_tax );
--              END IF;
--            END IF;
              ln_amount    := ( lt_sale_discount_amount - ( lt_sale_discount_amount / ln_tax_data ) );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                  ln_discount_tax := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  ln_discount_tax := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  ln_discount_tax := ROUND( ln_amount );
                END IF;
              ELSE
                ln_discount_tax   := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- ����ŋ��z���v
              lt_tax_amount_sum  := ( ln_all_tax_amount - ln_discount_tax );
--
            END IF;
          --�l�������������z�Z�o
          ELSE
--
            IF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
              -- ������z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
--            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
--              END IF;
--            END IF;
              ln_amount := lt_total_amount;
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_sale_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_sale_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_sale_amount_sum   := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- �{�̋��z���v
              lt_pure_amount_sum := lt_total_amount;
              -- ����ŋ��z���v
              ln_amount  := ( lt_sale_amount_sum * ( ln_tax_data - 1 ) );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_tax_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_tax_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_tax_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_tax_amount_sum := ln_amount;
              END IF;
--
            ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
              -- ������z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
--            IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--              lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
--              END IF;
--            END IF;
              ln_amount := ( lt_total_amount * ln_tax_data );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                lt_sale_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_sale_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_sale_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_sale_amount_sum   := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
              -- �{�̋��z���v
              lt_pure_amount_sum := lt_total_amount;
              -- ����ŋ��z���v
              lt_tax_amount_sum  := ( lt_sale_amount_sum - lt_pure_amount_sum );
--
            ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--
              -- ������z���v
              lt_sale_amount_sum := lt_total_amount;
              -- �{�̋��z���v
--************************** 2009/03/18 1.5 T.kitajima MOD START ************************************
--            lt_pure_amount_sum := ( lt_total_amount / ln_tax_data );
--            IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
--              IF ( lt_tax_odd = cv_amount_up ) THEN
--                lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
--              -- �؎̂�
--              ELSIF ( lt_tax_odd = cv_amount_down ) THEN
--                lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
--              -- �l�̌ܓ�
--              ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
--                lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
--              END IF;
--            END IF;
              ln_amount := ( lt_total_amount / ln_tax_data );
              IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
                IF ( lt_tax_odd = cv_amount_up ) THEN
                  lt_pure_amount_sum := ( TRUNC( ln_amount ) + 1 );
                -- �؎̂�
                ELSIF ( lt_tax_odd = cv_amount_down ) THEN
                  lt_pure_amount_sum := TRUNC( ln_amount );
                -- �l�̌ܓ�
                ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
                  lt_pure_amount_sum := ROUND( ln_amount );
                END IF;
              ELSE
                lt_pure_amount_sum   := ln_amount;
              END IF;
--************************** 2009/03/18 1.5 T.kitajima MOD  END  ************************************
            -- ����ŋ��z���v
            lt_tax_amount_sum  := ln_all_tax_amount;
--
            END IF;
          END IF;
        END IF;
--
        --��ېňȊO�̎�
        IF (lt_consumption_tax_class <> cv_non_tax) THEN
          -- ================================================
          -- �w�b�_�������Ŋz�Ɩ��ה������Ŋz��r���f����
          -- ================================================
--          -- �l�����ׂ�null�ȊO�̎�
          IF ( lt_sale_discount_amount IS NOT NULL ) AND ( lt_sale_discount_amount <> 0 ) 
          AND ( lt_consumption_tax_class <> cv_ins_bid_tax ) THEN
            ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
          END IF;
          IF ( lt_tax_amount_sum <> ln_all_tax_amount ) THEN
            -- �O�� OR ����(�`�[�ېł̎�)
            IF ( lt_consumption_tax_class = cv_out_tax ) OR ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN
--******************************* 2009/04/21 N.Maeda Var1.10 MOD START ***************************************
              IF ( lt_red_black_flag = cv_black_flag) THEN
--                gt_line_tax_amount( ln_max_no_data ) := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
                gt_accumulation_data(ln_max_no_data).tax_amount := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
              ELSIF ( lt_red_black_flag = cv_red_flag) THEN
--                gt_line_tax_amount( ln_max_no_data ) := ( ( ln_max_tax_data 
--                                                          + ( lt_tax_amount_sum - ln_all_tax_amount ) ) * ( -1 ) );
                gt_accumulation_data(ln_max_no_data).tax_amount := ( ( ln_max_tax_data 
                                                                      + ( lt_tax_amount_sum - ln_all_tax_amount ) ) * ( -1 ) );
              END IF;
--******************************* 2009/04/21 N.Maeda Var1.10 MOD END   ***************************************
            END IF;
          END IF;
        END IF;
--
        -- �ԁE���̋��z���Z
        --���̎�
        IF ( lt_red_black_flag = cv_black_flag) THEN
          -- ������z���v
          lt_set_sale_amount_sum := lt_sale_amount_sum;
          -- �{�̋��z���v
          lt_set_pure_amount_sum := lt_pure_amount_sum;
          -- ����ŋ��z���v
          lt_set_tax_amount_sum := lt_tax_amount_sum;
        -- �Ԃ̎�
        ELSIF ( lt_red_black_flag = cv_red_flag) THEN
          -- ������z���v
          lt_set_sale_amount_sum := ( lt_sale_amount_sum * ( -1 ) );
          -- �{�̋��z���v
          lt_set_pure_amount_sum := ( lt_pure_amount_sum * ( -1 ) );
          -- ����ŋ��z���v
          lt_set_tax_amount_sum := ( lt_tax_amount_sum * ( -1 ) );
        END IF;
--
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        --================================
        --�̔����уw�b�_ID(�V�[�P���X�擾)
        --================================
        SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
        INTO ln_actual_id
        FROM DUAL;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
--
        --==========================
        -- �w�b�_�f�[�^�̕ϐ��}��
        --==========================
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
        gt_dlv_hht_head_row_id( gn_head_data_no )          := lt_row_id;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
        gt_head_id( gn_head_data_no )                      := ln_actual_id;                 -- �̔����уw�b�_ID
        gt_head_order_no_ebs( gn_head_data_no )            := lt_order_no_ebs;              -- �󒍔ԍ�
        gt_head_hht_invoice_no( gn_head_data_no )          := lt_hht_invoice_no;            -- �[�i�`�[�ԍ�
        gt_head_order_no_hht( gn_head_data_no )            := lt_order_no_hht;              -- ��No(HHT)
        gt_head_digestion_ln_number( gn_head_data_no )     := lt_digestion_ln_number;       -- �}��(��No(HHT)�}��)
        gt_head_dlv_invoice_class( gn_head_data_no )       := lt_ins_invoice_type;          -- �[�i�`�[�敪(���o)
        gt_head_cancel_cor_cls( gn_head_data_no )          := lt_cancel_correct_class;      -- ����E�����敪
        gt_head_system_class( gn_head_data_no )            := lt_system_class;              -- �Ƒԋ敪(�Ƒԏ�����)
        gt_head_dlv_date( gn_head_data_no )                := lt_dlv_date;                  -- �[�i��
        gt_head_inspect_date( gn_head_data_no )            := lt_inspect_date;              -- ������(����v���)
        gt_head_customer_number( gn_head_data_no )         := lt_customer_number;           -- �ڋq�y�[�i��
        gt_head_tax_include( gn_head_data_no )             := lt_set_sale_amount_sum;       -- ������z���v
        gt_head_total_amount( gn_head_data_no )            := lt_set_pure_amount_sum;       -- �{�̋��z���v
        gt_head_sales_consump_tax( gn_head_data_no )       := lt_set_tax_amount_sum;        -- ����ŋ��z���v(�����o)
        gt_head_consump_tax_class( gn_head_data_no )       := lt_consum_type;               -- ����ŋ敪(���o)
        gt_head_tax_code( gn_head_data_no )                := lt_consum_code;               -- �ŋ��R�[�h(���o)
        gt_head_tax_rate( gn_head_data_no )                := lt_tax_consum;                -- ����ŗ�(���o)
        gt_head_performance_by_code( gn_head_data_no )     := lt_performance_by_code;       -- ���ьv��҃R�[�h
        gt_head_sales_base_code( gn_head_data_no )         := lt_sale_base_code;            -- ���㋒�_�R�[�h(���o)
        gt_head_card_sale_class( gn_head_data_no )         := lt_card_sale_class;           -- �J�[�h����敪
--      gt_head_sales_classification( gn_head_data_no )    := lt_sales_classification;      -- �`�[�敪
--      gt_head_invoice_class( gn_head_data_no )           := lt_sales_invoice;             -- �`�[���ރR�[�h
        gt_head_sales_classification( gn_head_data_no )    := lt_sales_invoice;             -- �`�[�敪
        gt_head_invoice_class( gn_head_data_no )           := lt_sales_classification;      -- �`�[���ރR�[�h
-- ************** 2009/04/16 1.12 N.Maeda MO START ****************************************************************
--      gt_head_receiv_base_code( gn_head_data_no )        := lt_sale_base_code;          -- �������_�R�[�h(���o)
        gt_head_receiv_base_code( gn_head_data_no )        := lt_cash_receiv_base_code;   -- �������_�R�[�h(���o)
-- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
        gt_head_change_out_time_100( gn_head_data_no )     := lt_change_out_time_100;       -- ��K�؂ꎞ��100�~
        gt_head_change_out_time_10( gn_head_data_no )      := lt_change_out_time_10;        -- ��K�؂ꎞ��10�~
        gt_head_hht_dlv_input_date( gn_head_data_no )      := ld_input_date;                -- HHT�[�i���͓���(���^����)
        gt_head_dlv_by_code( gn_head_data_no )             := lt_dlv_by_code;               -- �[�i�҃R�[�h
        gt_head_business_date( gn_head_data_no )           := gd_process_date;              -- �o�^�Ɩ����t(���������擾)
        gt_head_order_source_id( gn_head_data_no )         := cv_tkn_null;                  -- �󒍃\�[�XID(NULL�ݒ�)
        gt_head_order_invoice_number( gn_head_data_no )    := cv_tkn_null;                  -- �����`�[�ԍ�(NULL�ݒ�)
        gt_head_order_connection_num( gn_head_data_no )    := cv_tkn_null;                  -- �󒍊֘A�ԍ�(NULL�ݒ�)
        gt_head_ar_interface_flag( gn_head_data_no )       := cv_tkn_n;                     -- AR-IF�σt���O('N')
        gt_head_gl_interface_flag( gn_head_data_no )       := cv_tkn_n;                     -- GL-IF�σt���O('N')
        gt_head_dwh_interface_flag( gn_head_data_no )      := cv_tkn_n;                     -- ���V�X�e��IF�σt���O('N')
        gt_head_edi_interface_flag( gn_head_data_no )      := cv_tkn_n;                     -- EDI���M�ς݃t���O('N'�ݒ�)
        gt_head_edi_send_date( gn_head_data_no )           := cv_tkn_null;                  -- EDI���M����(NULL�ݒ�)
-- ************** 2009/04/16 1.12 N.Maeda MO START ****************************************************************
--        gt_head_create_class( gn_head_data_no )            := cn_tkn_shipping_chk;          -- �쐬���敪(�4��ݒ�)
        gt_head_create_class( gn_head_data_no )            := cv_tkn_shipping_chk;          -- �쐬���敪(�4��ݒ�)
-- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
        gt_head_input_class( gn_head_data_no )             := lt_input_class;               -- ���͋敪
        gn_head_data_no := gn_head_data_no + 1;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD START ***************************************
--
        <<line_set_loop>>
        FOR in_data_num IN 1..ln_line_data_count LOOP
--
          -- ===================
          -- �o�^�p����ID�擾
          -- ===================
          SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
          INTO   ln_sales_exp_line_id
          FROM   DUAL;
--
          gt_line_sales_exp_line_id( gn_line_data_no )       := ln_sales_exp_line_id;         -- �̔����і���ID
          gt_line_sales_exp_header_id( gn_line_data_no )     := ln_actual_id;                 -- �̔����уw�b�_ID
          gt_line_dlv_invoice_number( gn_line_data_no )      := gt_accumulation_data(in_data_num).dlv_invoice_number;    -- �[�i�`�[�ԍ�
          gt_line_dlv_invoice_l_num( gn_line_data_no )       := gt_accumulation_data(in_data_num).dlv_invoice_line_number; -- �[�i���הԍ�
          gt_line_sales_class( gn_line_data_no )             := gt_accumulation_data(in_data_num).sales_class;           -- ����敪
          gt_line_red_black_flag( gn_line_data_no )          := gt_accumulation_data(in_data_num).red_black_flag;        -- �ԍ��t���O
          gt_line_item_code( gn_line_data_no )               := gt_accumulation_data(in_data_num).item_code;             -- �i�ڃR�[�h
          gt_line_standard_qty( gn_line_data_no )            := gt_accumulation_data(in_data_num).standard_qty;          -- �����
          gt_line_standard_uom_code( gn_line_data_no )       := gt_accumulation_data(in_data_num).standard_uom_code;     -- ��P��
          gt_line_standard_unit_price( gn_line_data_no )     := gt_accumulation_data(in_data_num).standard_unit_price;   -- ��P��
          gt_line_business_cost( gn_line_data_no )           := gt_accumulation_data(in_data_num).business_cost;         -- �c�ƌ���
          gt_line_sale_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).sale_amount;           -- ������z
          gt_line_pure_amount( gn_line_data_no )             := gt_accumulation_data(in_data_num).pure_amount;           -- �{�̋��z
          gt_line_tax_amount( gn_line_data_no )              := gt_accumulation_data(in_data_num).tax_amount;            -- ����ŋ��z
          gt_line_cash_and_card( gn_line_data_no )           := gt_accumulation_data(in_data_num).cash_and_card;         -- �����E�J�[�h���p�z
          gt_line_ship_from_subinv_co( gn_line_data_no )     := gt_accumulation_data(in_data_num).ship_from_subinventory_code; -- �o�׌��ۊǏꏊ
          gt_line_delivery_base_code( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_base_code;    -- �[�i���_�R�[�h
          gt_line_hot_cold_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).hot_cold_class;        -- �g���b
          gt_line_column_no( gn_line_data_no )               := gt_accumulation_data(in_data_num).column_no;             -- �R����No
          gt_line_sold_out_class( gn_line_data_no )          := gt_accumulation_data(in_data_num).sold_out_class;        -- ���؋敪
          gt_line_sold_out_time( gn_line_data_no )           := gt_accumulation_data(in_data_num).sold_out_time;         -- ���؎���
          gt_line_to_calculate_fees_flag( gn_line_data_no )  := gt_accumulation_data(in_data_num).to_calculate_fees_flag;-- �萔���v�ZIF�σt���O
          gt_line_unit_price_mst_flag( gn_line_data_no )     := gt_accumulation_data(in_data_num).unit_price_mst_flag;   -- �P���}�X�^�쐬�σt���O
          gt_line_inv_interface_flag( gn_line_data_no )      := gt_accumulation_data(in_data_num).inv_interface_flag;    -- INV�C���^�t�F�[�X�σt���O
          gt_line_order_invoice_l_num( gn_line_data_no )     := gt_accumulation_data(in_data_num).order_invoice_line_number;   -- �������הԍ�
          gt_line_not_tax_amount( gn_line_data_no )          := gt_accumulation_data(in_data_num).standard_unit_price_excluded;-- �Ŕ���P��
          gt_line_delivery_pat_class( gn_line_data_no )      := gt_accumulation_data(in_data_num).delivery_pattern_class;      -- �[�i�`�ԋ敪
          gt_line_dlv_qty( gn_line_data_no )                 := gt_accumulation_data(in_data_num).dlv_qty;                     -- �[�i����
          gt_line_dlv_uom_code( gn_line_data_no )            := gt_accumulation_data(in_data_num).dlv_uom_code;                -- �[�i�P��
          gt_dlv_unit_price( gn_line_data_no )               := gt_accumulation_data(in_data_num).dlv_unit_price;              -- �[�i�P��
          gn_line_data_no := gn_line_data_no + 1;
        END LOOP line_set_loop;
      END IF;
--******************************* 2009/04/16 N.Maeda Var1.12 ADD END   ***************************************
    END LOOP header_loop;
--
  EXCEPTION
    WHEN no_data_extract THEN
      --�L�[�ҏW�֐�
      xxcos_common_pkg.makeup_key_info(
                                         lv_key_name1, lv_key_data1, lv_key_name2, lv_key_data2,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         cv_key_name_null, cv_tkn_null, cv_key_name_null, cv_tkn_null,
                                         gv_tkn2, lv_errbuf, lv_retcode, lv_errmsg);  
      --���b�Z�[�W����
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_no_data,
                                             cv_tkn_table_name, gv_tkn1,
                                             cv_key_data, gv_tkn2 );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� # 
--******************************* 2009/04/16 N.Maeda Var1.12 DEL START ***************************************
--    WHEN delivered_from_err_expt THEN
--      --
--      lv_errmsg := xxccp_common_pkg.get_msg( cv_application,cv_msg_delivered_from_err );
----      lv_errbuf := lv_errmsg;
--      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
--      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;                                            --# �C�� #
--******************************* 2009/04/16 N.Maeda Var1.12 DEL END   ***************************************
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
  END proc_molded_hht;
--
  /**********************************************************************************
   * Procedure Name   : proc_extract
   * Description      : �Ώۃf�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE proc_extract(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_extract'; -- �v���O������
    --
    -- ===============================
    -- ���[�U�[��`�ϐ�
    -- ===============================
    lv_no_data_msg VARCHAR2(5000);
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
    -- �[�i�w�b�_(HHT)
    CURSOR dlv_head_hht_cur
    IS
      SELECT dhs.ROWID,                    -- �sID
             dhs.order_no_hht,             -- ��No.(HHT)
             dhs.digestion_ln_number,      -- �}��
             dhs.order_no_ebs,             -- ��No.�iEBS�j
             dhs.base_code,                -- ���_�R�[�h
             dhs.performance_by_code,      -- ���ю҃R�[�h
             dhs.dlv_by_code,              -- �[�i�҃R�[�h
             dhs.hht_invoice_no,           -- HHT�`�[No.
             dhs.dlv_date,                 -- �[�i��
             dhs.inspect_date,             -- ������
             dhs.sales_classification,     -- ���㕪�ދ敪
             dhs.sales_invoice,            -- ����`�[�敪
             dhs.card_sale_class,          -- �J�[�h����敪
             dhs.dlv_time,                 -- ����
             dhs.customer_number,          -- �ڋq�R�[�h
             dhs.change_out_time_100,      -- ��K�؂ꎞ��100�~
             dhs.change_out_time_10,       -- ��K�؂ꎞ��10�~
             dhs.system_class,             -- �Ƒԋ敪
             dhs.input_class,              -- ���͋敪
             dhs.consumption_tax_class,    -- ����ŋ敪
             dhs.total_amount,             -- ���v���z
             dhs.sale_discount_amount,     -- ����l���z
             dhs.sales_consumption_tax,    -- �������Ŋz
             dhs.tax_include,              -- �ō����z
             dhs.keep_in_code,             -- �a����R�[�h
             dhs.department_screen_class,  -- �S�ݓX��ʎ��
             dhs.red_black_flag,           -- �ԁE���t���O
             dhs.stock_forward_flag,       -- ���o�ɓ]���t���O
             dhs.stock_forward_date,       -- ���o�ɓ]���ϓ��t
             dhs.results_forward_flag,     -- �̔����јA�g�σt���O
             dhs.results_forward_date,     -- �̔����јA�g�ϓ��t
             dhs.cancel_correct_class      -- ����E�����敪
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
      FROM   xxcos_dlv_headers dhs,
             xxcos_dlv_lines dls
      WHERE  dhs.order_no_hht = dls.order_no_hht
      AND    dhs.digestion_ln_number = dls.digestion_ln_number
      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
      AND    dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
--      AND    dhs.results_forward_flag = cn_tkn_zero
      AND    dhs.results_forward_flag = cv_untreated_flg
      AND    dhs.order_no_ebs = cn_tkn_zero 
      AND    dhs.program_application_id IS NOT NULL
      AND    dls.program_application_id  IS NOT NULL
      GROUP BY dhs.ROWID,dhs.order_no_hht,dhs.digestion_ln_number,dhs.order_no_ebs,
                      dhs.base_code,dhs.performance_by_code,dhs.dlv_by_code,dhs.hht_invoice_no,
                      dhs.dlv_date,dhs.inspect_date,dhs.sales_classification,dhs.sales_invoice,
                      dhs.card_sale_class,dhs.dlv_time,dhs.customer_number,dhs.change_out_time_100,
                      dhs.change_out_time_10,dhs.system_class,dhs.input_class,dhs.consumption_tax_class,
                      dhs.total_amount,dhs.sale_discount_amount,dhs.sales_consumption_tax,dhs.tax_include,
                      dhs.keep_in_code,dhs.department_screen_class,dhs.red_black_flag,dhs.stock_forward_flag,
                      dhs.stock_forward_date,dhs.results_forward_flag,dhs.results_forward_date,dhs.cancel_correct_class
--      FROM   xxcos_dlv_headers dhs           --�[�i�w�b�_
--      WHERE  dhs.order_no_hht IN (SELECT dls.order_no_hht
--                                  FROM   xxcos_dlv_lines dls              --�[�i����
--                                  WHERE  dls.program_application_id IS NOT NULL )
--      AND    dhs.digestion_ln_number IN (SELECT dhs.digestion_ln_number
--                                         FROM   xxcos_dlv_lines dls              --�[�i����
--                                         WHERE  dls.program_application_id IS NOT NULL )
--      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
--      AND    dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
--      AND    dhs.results_forward_flag = cn_tkn_zero
----      AND    dhs.order_no_ebs IS NULL 
--      AND    dhs.order_no_ebs = cn_tkn_zero 
--      AND    dhs.program_application_id IS NOT NULL --�ʏ�f�[�^
      ORDER BY dhs.order_no_hht,dhs.digestion_ln_number;
--    FOR UPDATE NOWAIT;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END   ***************************************
--
    --�[�i����(HHT)
    CURSOR dlv_line_hht_cur
    IS
      SELECT dls.order_no_hht,          -- ��No.�iHHT�j
             dls.line_no_hht,           -- �sNo.�iHHT�j
             dls.digestion_ln_number,   -- �}��
             dls.order_no_ebs,          -- ��No.�iEBS�j
             dls.line_number_ebs,       -- ���הԍ��iEBS�j
             dls.item_code_self,        -- �i���R�[�h�i���Ёj
             dls.content,               -- ����
             dls.inventory_item_id,     -- �i��ID
             dls.standard_unit,         -- ��P��
             dls.case_number,           -- �P�[�X��
             dls.quantity,              -- ����
             dls.sale_class,            -- ����敪
             dls.wholesale_unit_ploce,  -- ���P��
             dls.selling_price,         -- ���P��
             dls.column_no,             -- �R����No.
             dls.h_and_c,               -- H/C
             dls.sold_out_class,        -- ���؋敪
             dls.sold_out_time,         -- ���؎���
             dls.replenish_number,      -- ��[��
             dls.cash_and_card          -- �����E�J�[�h���p�z
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
      FROM   xxcos_dlv_headers dhs,
             xxcos_dlv_lines dls
      WHERE  dhs.order_no_hht = dls.order_no_hht
      AND    dhs.digestion_ln_number = dls.digestion_ln_number
      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
      AND    dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
--      AND    dhs.results_forward_flag = cn_tkn_zero
      AND    dhs.results_forward_flag = cv_untreated_flg
      AND    dhs.order_no_ebs = cn_tkn_zero
      AND    dhs.program_application_id IS NOT NULL
      AND    dls.program_application_id  IS NOT NULL
--      FROM   xxcos_dlv_lines dls           -- �[�i����
--      WHERE  dls.order_no_hht IN ( SELECT  dhs.order_no_hht
--                                   FROM    xxcos_dlv_headers dhs
--                                   WHERE   dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
--                                   AND    dhs.input_class  
--                                            NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
--                                   AND    dhs.results_forward_flag = cn_tkn_zero
--                                   --AND    dhs.order_no_ebs IS NULL 
--                                   AND    dhs.order_no_ebs = cn_tkn_zero
--                                   AND    dhs.program_application_id IS NOT NULL)
--      AND    dls.digestion_ln_number IN ( SELECT dhs.digestion_ln_number
--                                          FROM    xxcos_dlv_headers dhs
--                                          WHERE   dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
--                                          AND    dhs.input_class  
--                                                   NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return )
--                                          AND    dhs.results_forward_flag = cn_tkn_zero
--                                          --AND    dhs.order_no_ebs IS NULL
--                                          AND    dhs.order_no_ebs = cn_tkn_zero
--                                          AND    dhs.program_application_id IS NOT NULL)
--      AND    dls.program_application_id IS NOT NULL --�ʏ�f�[�^
      ORDER BY dls.order_no_hht,dls.digestion_ln_number,dls.line_no_hht
    FOR UPDATE NOWAIT;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
--
    -- �[�i�w�b�_(�󒍉�ʓ��̓f�[�^)
    CURSOR dlv_inp_head_hht_cur
    IS
      SELECT dhs.ROWID,                    -- �sID
             dhs.order_no_hht,             -- ��No.(HHT)
             dhs.digestion_ln_number,      -- �}��
             dhs.order_no_ebs,             -- ��No.�iEBS�j
             dhs.base_code,                -- ���_�R�[�h
             dhs.performance_by_code,      -- ���ю҃R�[�h
             dhs.dlv_by_code,              -- �[�i�҃R�[�h
             dhs.hht_invoice_no,           -- HHT�`�[No.
             dhs.dlv_date,                 -- �[�i��
             dhs.inspect_date,             -- ������
             dhs.sales_classification,     -- ���㕪�ދ敪
             dhs.sales_invoice,            -- ����`�[�敪
             dhs.card_sale_class,          -- �J�[�h����敪
             dhs.dlv_time,                 -- ����
             dhs.customer_number,          -- �ڋq�R�[�h
             dhs.change_out_time_100,      -- ��K�؂ꎞ��100�~
             dhs.change_out_time_10,       -- ��K�؂ꎞ��10�~
             dhs.system_class,             -- �Ƒԋ敪
             dhs.input_class,              -- ���͋敪
             dhs.consumption_tax_class,    -- ����ŋ敪
             dhs.total_amount,             -- ���v���z
             dhs.sale_discount_amount,     -- ����l���z
             dhs.sales_consumption_tax,    -- �������Ŋz
             dhs.tax_include,              -- �ō����z
             dhs.keep_in_code,             -- �a����R�[�h
             dhs.department_screen_class,  -- �S�ݓX��ʎ��
             dhs.red_black_flag,           -- �ԁE���t���O
             dhs.stock_forward_flag,       -- ���o�ɓ]���t���O
             dhs.stock_forward_date,       -- ���o�ɓ]���ϓ��t
             dhs.results_forward_flag,     -- �̔����јA�g�σt���O
             dhs.results_forward_date,     -- �̔����јA�g�ϓ��t
             dhs.cancel_correct_class      -- ����E�����敪
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
      FROM   xxcos_dlv_headers dhs,           --�[�i�w�b�_
             xxcos_dlv_lines dls              --�[�i����
      WHERE  dhs.order_no_hht = dls.order_no_hht
      AND    dhs.digestion_ln_number = dls.digestion_ln_number
      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
      AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
          AND dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
        OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero ) 
          AND ( dhs.input_class  = cv_input_delivery ) ) )
--      AND    dhs.results_forward_flag = cn_tkn_zero
      AND    dhs.results_forward_flag = cv_untreated_flg
      AND    dhs.program_application_id IS NULL
      AND    dls.program_application_id IS NULL
      GROUP BY  dhs.ROWID,dhs.order_no_hht,dhs.digestion_ln_number,dhs.order_no_ebs,
                dhs.base_code,dhs.performance_by_code,dhs.dlv_by_code,dhs.hht_invoice_no,
                dhs.dlv_date,dhs.inspect_date,dhs.sales_classification,dhs.sales_invoice,
                dhs.card_sale_class,dhs.dlv_time,dhs.customer_number,dhs.change_out_time_100,
                dhs.change_out_time_10,dhs.system_class,dhs.input_class,dhs.consumption_tax_class,
                dhs.total_amount,dhs.sale_discount_amount,dhs.sales_consumption_tax,dhs.tax_include,
                dhs.keep_in_code,dhs.department_screen_class,dhs.red_black_flag,dhs.stock_forward_flag,
                dhs.stock_forward_date,dhs.results_forward_flag,dhs.results_forward_date,dhs.cancel_correct_class
--      FROM   xxcos_dlv_headers dhs           --�[�i�w�b�_
--      WHERE  dhs.order_no_hht IN (SELECT dls.order_no_hht
--                                  FROM   xxcos_dlv_lines dls              --�[�i����
--                                  WHERE  dls.program_application_id IS NULL )
--      AND    dhs.digestion_ln_number IN (SELECT dhs.digestion_ln_number
--                                         FROM   xxcos_dlv_lines dls              --�[�i����
--                                         WHERE  dls.program_application_id IS NULL )
---- ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
----      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
----      AND ( ( ( dhs.order_no_ebs = cn_tkn_zero )
----          AND dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
----        OR ( ( dhs.order_no_ebs <> cn_tkn_zero ) 
----          AND ( dhs.input_class  = cv_input_delivery ) ) )
--      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
--      AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
--          AND dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
--        OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero ) 
--          AND ( dhs.input_class  = cv_input_delivery ) ) )
---- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
--      AND    dhs.results_forward_flag = cn_tkn_zero
--      AND    dhs.program_application_id IS NULL --�ʏ�f�[�^
      ORDER BY dhs.order_no_hht,dhs.digestion_ln_number;
--    FOR UPDATE NOWAIT;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
--
    --�[�i����(�󒍉�ʓ��̓f�[�^)
    CURSOR dlv_inp_line_hht_cur
    IS
      SELECT dls.order_no_hht,          -- ��No.�iHHT�j
             dls.line_no_hht,           -- �sNo.�iHHT�j
             dls.digestion_ln_number,   -- �}��
             dls.order_no_ebs,          -- ��No.�iEBS�j
             dls.line_number_ebs,       -- ���הԍ��iEBS�j
             dls.item_code_self,        -- �i���R�[�h�i���Ёj
             dls.content,               -- ����
             dls.inventory_item_id,     -- �i��ID
             dls.standard_unit,         -- ��P��
             dls.case_number,           -- �P�[�X��
             dls.quantity,              -- ����
             dls.sale_class,            -- ����敪
             dls.wholesale_unit_ploce,  -- ���P��
             dls.selling_price,         -- ���P��
             dls.column_no,             -- �R����No.
             dls.h_and_c,               -- H/C
             dls.sold_out_class,        -- ���؋敪
             dls.sold_out_time,         -- ���؎���
             dls.replenish_number,      -- ��[��
             dls.cash_and_card          -- �����E�J�[�h���p�z
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
      FROM   xxcos_dlv_headers dhs,     --�[�i�w�b�_
             xxcos_dlv_lines dls        -- �[�i����
      WHERE  dhs.order_no_hht = dls.order_no_hht
      AND    dhs.digestion_ln_number = dls.digestion_ln_number
      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
      AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
          AND dhs.input_class  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
        OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero ) 
          AND ( dhs.input_class  = cv_input_delivery ) ) )
--      AND    dhs.results_forward_flag = cn_tkn_zero
      AND    dhs.results_forward_flag = cv_untreated_flg
      AND    dhs.program_application_id IS NULL
      AND    dls.program_application_id IS NULL
--      FROM   xxcos_dlv_lines dls           -- �[�i����
--      WHERE  dls.order_no_hht IN ( SELECT  dhs.order_no_hht
--                                   FROM    xxcos_dlv_headers dhs
--                                   WHERE   dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
---- ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
----                                   AND ( ( ( dhs.order_no_ebs = cn_tkn_zero )
----                                       AND dhs.input_class  
----                                             NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
----                                     OR ( ( dhs.order_no_ebs <> cn_tkn_zero )
----                                       AND ( dhs.input_class  = cv_input_delivery ) ) ) 
--                                   AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
--                                       AND dhs.input_class  
--                                             NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
--                                     OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero )
--                                       AND ( dhs.input_class  = cv_input_delivery ) ) ) 
-- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
--                                   AND    dhs.program_application_id IS NULL
--                                   AND    dhs.results_forward_flag = cn_tkn_zero )
--      AND    dls.digestion_ln_number IN ( SELECT dhs.digestion_ln_number
--                                          FROM    xxcos_dlv_headers dhs
--                                          WHERE   dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
---- ************** 2009/04/16 1.12 N.Maeda MOD START ****************************************************************
----                                          AND ( ( ( dhs.order_no_ebs = cn_tkn_zero )
----                                              AND dhs.input_class  
----                                                  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
----                                            OR ( ( dhs.order_no_ebs <> cn_tkn_zero )
----                                              AND ( dhs.input_class  = cv_input_delivery ) ) )
--                                          AND ( ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) = cn_tkn_zero )
--                                              AND dhs.input_class  
--                                                  NOT IN ( cv_input_return, cv_input_vd_return,cv_input_fs_vd_return ))
--                                            OR ( ( NVL ( dhs.order_no_ebs , cn_tkn_zero ) <> cn_tkn_zero )
--                                              AND ( dhs.input_class  = cv_input_delivery ) ) )
---- ************** 2009/04/16 1.12 N.Maeda MOD  END  ****************************************************************
--                                              AND    dhs.program_application_id IS NULL 
--                                              AND    dhs.results_forward_flag = cn_tkn_zero )
--      AND    dls.program_application_id IS NULL --�󒍉�ʓ��̓f�[�^
      ORDER BY dls.order_no_hht,dls.digestion_ln_number,dls.line_no_hht
    FOR UPDATE NOWAIT;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD END ***************************************
--
    -- �[�i�w�b�_(EDI)
    CURSOR dlv_head_edi_cur
    IS
      SELECT dhs.ROWID,                    -- �sID
             dhs.order_no_hht,             -- ��No.(HHT)
             dhs.digestion_ln_number,      -- �}��
             dhs.order_no_ebs,             -- ��No.�iEBS�j
             dhs.base_code,                -- ���_�R�[�h
             dhs.performance_by_code,      -- ���ю҃R�[�h
             dhs.dlv_by_code,              -- �[�i�҃R�[�h
             dhs.hht_invoice_no,           -- HHT�`�[No.
             dhs.dlv_date,                 -- �[�i��
             dhs.inspect_date,             -- ������
             dhs.sales_classification,     -- ���㕪�ދ敪
             dhs.sales_invoice,            -- ����`�[�敪
             dhs.card_sale_class,          -- �J�[�h����敪
             dhs.dlv_time,                 -- ����
             dhs.customer_number,          -- �ڋq�R�[�h
             dhs.change_out_time_100,      -- ��K�؂ꎞ��100�~
             dhs.change_out_time_10,       -- ��K�؂ꎞ��10�~
             dhs.system_class,             -- �Ƒԋ敪
             dhs.input_class,              -- ���͋敪
             dhs.consumption_tax_class,    -- ����ŋ敪
             dhs.total_amount,             -- ���v���z
             dhs.sale_discount_amount,     -- ����l���z
             dhs.sales_consumption_tax,    -- �������Ŋz
             dhs.tax_include,              -- �ō����z
             dhs.keep_in_code,             -- �a����R�[�h
             dhs.department_screen_class,  -- �S�ݓX��ʎ��
             dhs.red_black_flag,           -- �ԁE���t���O
             dhs.stock_forward_flag,       -- ���o�ɓ]���t���O
             dhs.stock_forward_date,       -- ���o�ɓ]���ϓ��t
             dhs.results_forward_flag,     -- �̔����јA�g�σt���O
             dhs.results_forward_date,     -- �̔����јA�g�ϓ��t
             dhs.cancel_correct_class      -- ����E�����敪
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
      FROM   xxcos_dlv_headers dhs,           --�[�i�w�b�_
             xxcos_dlv_lines dls              -- �[�i����
      WHERE  dhs.order_no_hht = dls.order_no_hht
      AND    dhs.digestion_ln_number = dls.digestion_ln_number
      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
      AND    dhs.input_class  = cv_input_delivery
--      AND    dhs.results_forward_flag = cn_tkn_zero
      AND    dhs.results_forward_flag = cv_untreated_flg
      AND    dhs.order_no_ebs <> cn_tkn_zero
      AND    dhs.program_application_id IS NOT NULL
      AND    dls.program_application_id IS NOT NULL
      GROUP BY dhs.ROWID,dhs.order_no_hht,dhs.digestion_ln_number,dhs.order_no_ebs,
               dhs.base_code,dhs.performance_by_code,dhs.dlv_by_code,dhs.hht_invoice_no,
               dhs.dlv_date,dhs.inspect_date,dhs.sales_classification,dhs.sales_invoice,
               dhs.card_sale_class,dhs.dlv_time,dhs.customer_number,dhs.change_out_time_100,
               dhs.change_out_time_10,dhs.system_class,dhs.input_class,dhs.consumption_tax_class,
               dhs.total_amount,dhs.sale_discount_amount,dhs.sales_consumption_tax,
               dhs.tax_include,dhs.keep_in_code,dhs.department_screen_class,dhs.red_black_flag,
               dhs.stock_forward_flag,dhs.stock_forward_date,dhs.results_forward_flag,
               dhs.results_forward_date,dhs.cancel_correct_class
--      FROM   xxcos_dlv_headers dhs           --�[�i�w�b�_
--      WHERE  dhs.order_no_hht IN (SELECT dls.order_no_hht
--                                  FROM   xxcos_dlv_lines dls              --�[�i����
--                                  WHERE   dls.program_application_id IS NOT NULL )
--      AND    dhs.digestion_ln_number IN (SELECT dhs.digestion_ln_number
--                                         FROM   xxcos_dlv_lines dls              --�[�i����
--                                         WHERE  dls.program_application_id IS NOT NULL )
--      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
--      AND    dhs.input_class  = cv_input_delivery
--      AND    dhs.results_forward_flag = cn_tkn_zero
--      AND    dhs.order_no_ebs <> cn_tkn_zero
--      AND    dhs.program_application_id IS NOT NULL
      ORDER BY dhs.order_no_hht,dhs.digestion_ln_number;
--    FOR UPDATE NOWAIT;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--
    --�[�i����(EDI)
    CURSOR dlv_line_edi_cur
    IS
      SELECT dls.order_no_hht,          -- ��No.�iHHT�j
             dls.line_no_hht,           -- �sNo.�iHHT�j
             dls.digestion_ln_number,   -- �}��
             dls.order_no_ebs,          -- ��No.�iEBS�j
             dls.line_number_ebs,       -- ���הԍ��iEBS�j
             dls.item_code_self,        -- �i���R�[�h�i���Ёj
             dls.content,               -- ����
             dls.inventory_item_id,     -- �i��ID
             dls.standard_unit,         -- ��P��
             dls.case_number,           -- �P�[�X��
             dls.quantity,              -- ����
             dls.sale_class,            -- ����敪
             dls.wholesale_unit_ploce,  -- ���P��
             dls.selling_price,         -- ���P��
             dls.column_no,             -- �R����No.
             dls.h_and_c,               -- H/C
             dls.sold_out_class,        -- ���؋敪
             dls.sold_out_time,         -- ���؎���
             dls.replenish_number,      -- ��[��
             dls.cash_and_card          -- �����E�J�[�h���p�z
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
      FROM   xxcos_dlv_headers dhs,           --�[�i�w�b�_
             xxcos_dlv_lines dls              -- �[�i����
      WHERE  dhs.order_no_hht = dls.order_no_hht
      AND    dhs.digestion_ln_number = dls.digestion_ln_number
      AND    dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
      AND    dhs.input_class  = cv_input_delivery
--      AND    dhs.results_forward_flag = cn_tkn_zero
      AND    dhs.results_forward_flag = cv_untreated_flg
      AND    dhs.order_no_ebs <> cn_tkn_zero
      AND    dhs.program_application_id IS NOT NULL
      AND    dls.program_application_id IS NOT NULL
--      FROM   xxcos_dlv_lines dls        -- �[�i����
--      WHERE  dls.order_no_hht IN ( SELECT dhs.order_no_hht
--                                   FROM   xxcos_dlv_headers dhs        -- �[�i�w�b�_
--                                   WHERE  dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
--                                   AND    dhs.input_class  = cv_input_delivery
--                                   AND    dhs.results_forward_flag = cn_tkn_zero
--                                   AND    dhs.order_no_ebs <> cn_tkn_zero
--                                   AND    dhs.program_application_id IS NOT NULL )
--      AND    dls.digestion_ln_number IN ( SELECT dhs.digestion_ln_number
--                                          FROM   xxcos_dlv_headers dhs        -- �[�i�w�b�_
--                                          WHERE  dhs.system_class NOT IN ( cv_fs_vd, cv_fs_vd_s )
--                                          AND    dhs.input_class  = cv_input_delivery
--                                          AND    dhs.results_forward_flag = cn_tkn_zero
--                                          AND    dhs.order_no_ebs <> cn_tkn_zero
--                                          AND    dhs.program_application_id IS NOT NULL )
--      AND    dls.program_application_id IS NOT NULL 
      ORDER BY dls.order_no_hht,dls.digestion_ln_number,dls.line_no_hht
    FOR UPDATE NOWAIT;
--******************************* 2009/04/16 N.Maeda Var1.12 MOD START ***************************************
--
    --HHT���o�Ɉꎞ�w�b�_�p���o
    CURSOR transaction_head_cur
    IS
      SELECT   hit.employee_num,                    -- �c�ƈ��R�[�h
               hit.invoice_no,                      -- �`�[��
               hit.invoice_type,                    -- �`�[�敪
               hit.inside_code,                     -- ���ɑ��R�[�h
               hit.invoice_date,                    -- �`�[���t
               hit.record_type,                     -- ���R�[�h���
               hit.inside_cust_code,                -- ���ɑ��ڋq�R�[�h
               hit.inside_business_low_type,        -- ���ɑ��Ƒԋ敪
               hit.column_no                        -- �R����No.
      FROM     xxcoi_hht_inv_transactions hit         -- HHT���o�Ɉꎞ�\
      WHERE    hit.record_type = cv_record_type_sample
      AND      hit.sample_if_flag = cv_sample_if_flag
      GROUP BY hit.employee_num, hit.invoice_no, hit.invoice_type,
               hit.inside_code, hit.invoice_date, hit.record_type,
               hit.inside_cust_code, hit.inside_business_low_type,
               hit.column_no
      ORDER BY hit.invoice_no, hit.column_no;
--
    --HHT���o�Ɉꎞ�e�[�u��
    CURSOR transaction_cur
    IS
      SELECT hit.ROWID,                           -- �sID
             hit.transaction_id,                  -- ���o�Ɉꎞ�\ID
             hit.interface_id,                    -- �C���^�[�t�F�[�XID
             hit.form_header_id,                  -- ��ʓ��͗p�w�b�_ID
             hit.base_code,                       -- ���_�R�[�h
             hit.record_type,                     -- ���R�[�h���
             hit.employee_num,                    -- �c�ƈ��R�[�h
             hit.invoice_no,                      -- �`�[��
             hit.item_code,                       -- �i�ڃR�[�h�i�i���R�[�h�j
             hit.case_quantity,                   -- �P�[�X��
             hit.case_in_quantity,                -- ����
             hit.quantity,                        -- �{��
             hit.invoice_type,                    -- �`�[�敪
             hit.base_delivery_flag,              -- ���_�ԑq�փt���O
             hit.outside_code,                    -- �o�ɑ��R�[�h
             hit.inside_code,                     -- ���ɑ��R�[�h
             hit.invoice_date,                    -- �`�[���t
             hit.column_no,                       -- �R������
             hit.unit_price,                      -- �P��
             hit.hot_cold_div,                    -- H/C
             hit.department_flag,                 -- �S�ݓX�t���O
             hit.interface_date,                  -- ��M����
             hit.other_base_code,                 -- �����_�R�[�h
             hit.outside_subinv_code,             -- �o�ɑ��ۊǏꏊ
             hit.inside_subinv_code,              -- ���ɑ��ۊǏꏊ
             hit.outside_base_code,               -- �o�ɑ����_
             hit.inside_base_code,                -- ���ɑ����_
             hit.total_quantity,                  -- ���{��
             hit.inventory_item_id,               -- �i��ID
             hit.primary_uom_code,                -- ��P��
             hit.outside_subinv_code_conv_div,    -- �o�ɑ��ۊǏꏊ�ϊ��敪
             hit.inside_subinv_code_conv_div,     -- ���ɑ��ۊǏꏊ�ϊ��敪
             hit.outside_business_low_type,       -- �o�ɑ��Ƒԋ敪
             hit.inside_business_low_type,        -- ���ɑ��Ƒԋ敪
             hit.outside_cust_code,               -- �o�ɑ��ڋq�R�[�h
             hit.inside_cust_code,                -- ���ɑ��ڋq�R�[�h
             hit.hht_program_div,                 -- ���o�ɃW���[�i�������敪
             hit.consume_vd_flag,                 -- ����VD��[�Ώۃt���O
             hit.item_convert_div,                -- ���i�U�֋敪
             hit.stock_uncheck_list_div,          -- ���ɖ��m�F���X�g�Ώۋ敪
             hit.stock_balance_list_div,          -- ���ɍ��يm�F���X�g�Ώۋ敪
             hit.status,                          -- �����X�e�[�^�X
             hit.column_if_flag,                  -- �R�����ʓ]���σt���O
             hit.column_if_date,                  -- �R�����ʓ]����
             hit.sample_if_flag,                  -- ���{�]���σt���O
             hit.sample_if_date,                  -- ���{�]����
             hit.output_flag                      -- �o�͍σt���O
      FROM   xxcoi_hht_inv_transactions hit         -- HHT���o�Ɉꎞ�\
      WHERE  hit.record_type = cv_record_type_sample
      AND    hit.sample_if_flag = cv_sample_if_flag
      ORDER BY hit.invoice_no,hit.column_no
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
    BEGIN
--
      -- ========================
      -- �[�i�w�b�_(HHT)���擾
      -- ========================
      -- �J�[�\��OPEN
      OPEN  dlv_head_hht_cur;
      -- �o���N�t�F�b�`
      FETCH dlv_head_hht_cur BULK COLLECT INTO gt_dlv_hht_headers_data;
      -- ���o�����Z�b�g
      gn_target_cnt := dlv_head_hht_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE dlv_head_hht_cur;
--
      -- ==============================
      -- �[�i��ʓ��̓f�[�^�[�i�w�b�_(HHT)���擾
      -- ==============================
      -- �J�[�\��OPEN
      OPEN  dlv_inp_head_hht_cur;
      -- �o���N�t�F�b�`
      FETCH dlv_inp_head_hht_cur BULK COLLECT INTO gt_inp_dlv_hht_headers_data;
      -- ���o�����Z�b�g
      gn_inp_target_cnt := dlv_inp_head_hht_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE dlv_inp_head_hht_cur;
--
      -- ==============================
      -- �[�i�w�b�_(EDI)���擾
      -- ==============================
      -- �J�[�\��OPEN
      OPEN  dlv_head_edi_cur;
      -- �o���N�t�F�b�`
      FETCH dlv_head_edi_cur BULK COLLECT INTO gt_dlv_edi_headers_data;
      -- ���o�����Z�b�g
      gn_target_edi_cnt := dlv_head_edi_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE dlv_head_edi_cur;
--
    EXCEPTION
      WHEN lock_err_expt THEN
        IF( dlv_head_hht_cur%ISOPEN ) THEN
          CLOSE dlv_head_hht_cur;
        END IF;
        IF( dlv_head_edi_cur%ISOPEN ) THEN
          CLOSE dlv_head_edi_cur;
        END IF;
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_tab );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_table, gv_tkn1 );
        RAISE;
      WHEN OTHERS THEN
        IF( dlv_head_hht_cur%ISOPEN ) THEN
          CLOSE dlv_head_hht_cur;
        END IF;
        IF( dlv_head_edi_cur%ISOPEN ) THEN
          CLOSE dlv_head_edi_cur;
        END IF;
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_extract_err, cv_tkn_table, gv_tkn1 );
        RAISE data_extract_err_expt;
    END;
--
    BEGIN
--
      -- ========================
      -- �[�i����(HHT)���擾
      -- ========================
      -- �J�[�\��OPEN
      OPEN  dlv_line_hht_cur;
      -- �o���N�t�F�b�`
      FETCH dlv_line_hht_cur BULK COLLECT INTO gt_dlv_hht_lines_data;
      -- ���o�����Z�b�g
      gn_line_cnt := dlv_line_hht_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE dlv_line_hht_cur;
--
      -- ===========================
      -- �[�i��ʓ��̓f�[�^�[�i����(HHT)���擾
      -- ===========================
      -- �J�[�\��OPEN
      OPEN  dlv_inp_line_hht_cur;
      -- �o���N�t�F�b�`
      FETCH dlv_inp_line_hht_cur BULK COLLECT INTO gt_inp_dlv_hht_lines_data;
      -- ���o�����Z�b�g
      gn_inp_line_cnt := dlv_inp_line_hht_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE dlv_inp_line_hht_cur;
--
      -- ===========================
      -- �[�i����(EDI)���擾
      -- ===========================
      -- �J�[�\��OPEN
      OPEN  dlv_line_edi_cur;
      -- �o���N�t�F�b�`
      FETCH dlv_line_edi_cur BULK COLLECT INTO gt_dlv_edi_lines_data;
      -- ���o�����Z�b�g
      gn_line_edi_cnt := dlv_line_edi_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE dlv_line_edi_cur;
--
    EXCEPTION
      WHEN lock_err_expt THEN
        IF( dlv_line_hht_cur%ISOPEN ) THEN
          CLOSE dlv_line_hht_cur;
        END IF;
        IF( dlv_line_edi_cur%ISOPEN ) THEN
          CLOSE dlv_line_edi_cur;
        END IF;
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_tab );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_table, gv_tkn1 );
        RAISE;
      WHEN OTHERS THEN
        IF( dlv_line_hht_cur%ISOPEN ) THEN
          CLOSE dlv_line_hht_cur;
        END IF;
        IF( dlv_line_edi_cur%ISOPEN ) THEN
          CLOSE dlv_line_edi_cur;
        END IF;
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_extract_err, cv_tkn_table, gv_tkn1 );
        RAISE data_extract_err_expt;
    END;
--
    BEGIN
      -- =====================================
      -- �w�b�_�pHHT���o�Ɉꎞ�e�[�u�����擾
      -- =====================================
      OPEN  transaction_head_cur;
      -- �o���N�t�F�b�`
      FETCH transaction_head_cur BULK COLLECT INTO gt_inv_trans_head;
      -- ���o�����Z�b�g
      gn_transaction_head_cnt := transaction_head_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE transaction_head_cur;
--
      -- =====================================
      -- HHT���o�Ɉꎞ�e�[�u�����擾
      -- =====================================
      -- �J�[�\��OPEN
      OPEN  transaction_cur;
      -- �o���N�t�F�b�`
      FETCH transaction_cur BULK COLLECT INTO gt_inv_transactions_data;
      -- ���o�����Z�b�g
      gn_transaction_cnt := transaction_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE transaction_cur;
--
    EXCEPTION
      WHEN lock_err_expt THEN
        IF( dlv_line_hht_cur%ISOPEN ) THEN
          CLOSE dlv_line_hht_cur;
        END IF;
        IF( dlv_line_edi_cur%ISOPEN ) THEN
          CLOSE dlv_line_edi_cur;
        END IF;
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_transactions );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_table, gv_tkn1 );
        RAISE;
      WHEN OTHERS THEN
        IF( dlv_line_hht_cur%ISOPEN ) THEN
          CLOSE dlv_line_hht_cur;
        END IF;
        IF( dlv_line_edi_cur%ISOPEN ) THEN
          CLOSE dlv_line_edi_cur;
        END IF;
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_transactions );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_extract_err, cv_tkn_table, gv_tkn1 );
        RAISE data_extract_err_expt;
    END;
--
    -- �Ώƃf�[�^�����݂��Ȃ��ꍇ
    IF ( (gn_target_cnt + gn_target_edi_cnt + gn_transaction_cnt + gn_inp_target_cnt ) = 0 ) THEN
      lv_no_data_msg := xxccp_common_pkg.get_msg ( cv_application, cv_msg_target_no_data );
      ov_errmsg := lv_no_data_msg;
      ov_errbuf := lv_no_data_msg;
--      lv_errbuf := lv_no_data_msg;
    END IF;
--
  EXCEPTION
    -- ���b�N�擾�G���[
    WHEN lock_err_expt THEN
--      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    WHEN data_extract_err_expt THEN
--      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
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
  END proc_extract;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ====================================================
    -- ���[�U�[��`�ϐ�
    -- ====================================================
    --
    lv_max_date      VARCHAR2(50);      -- MAX���t
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
  --==================
  -- �݌ɑg�DID�̎擾
  --==================
  --�݌ɑg�D�R�[�h�擾
  gv_orga_code := FND_PROFILE.VALUE( cv_prf_orga_code );
--
  --�v���t�@�C���G���[
  IF ( gv_orga_code IS NULL ) THEN
    gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga_code );
    lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--    lv_errbuf := lv_errmsg;
    RAISE global_api_expt;
  END IF;
  --�݌ɑg�DID�擾
  gn_orga_id := xxcoi_common_pkg.get_organization_id( gv_orga_code );
--
  -- �݌ɑg�DID�擾�G���[�̏ꍇ
  IF ( gn_orga_id IS NULL ) THEN
    lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga );
--    lv_errbuf := lv_errmsg;
    RAISE global_api_expt;
  END IF;
--
  --======================
  -- MO:�c�ƒP�ʎ擾
  --======================
  gv_salse_unit := FND_PROFILE.VALUE( cv_org_id );
--
  IF ( gv_salse_unit IS NULL ) THEN
    gv_tkn1   := xxccp_common_pkg.get_msg( cv_application,cv_msg_selse_unit );
    lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--    lv_errbuf := lv_errmsg;
    RAISE global_api_expt;
  END IF;
--
  --=======================
  -- ����l���i�ڃR�[�h�擾
  --=======================
  gv_disc_item := FND_PROFILE.VALUE( cv_disc_item_code );
--
  IF ( gv_disc_item IS NULL ) THEN
    gv_tkn1   := xxccp_common_pkg.get_msg( cv_application,cv_msg_disc_item );
    lv_errmsg := xxccp_common_pkg.get_msg( cv_application,cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--    lv_errbuf := lv_errmsg;
    RAISE global_api_expt;
  END IF;
--
  --=======================
  -- �Ɩ����t�擾
  --=======================
  gd_process_date := xxccp_common_pkg2.get_process_date;
--
  -- �Ɩ��������擾�G���[�̏ꍇ
  IF ( gd_process_date IS NULL ) THEN
    lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
--    lv_errbuf := lv_errmsg;
    RAISE global_api_expt;
  END IF;
--
    gd_process_date := TRUNC( gd_process_date );
--
    --==================================
    -- �v���t�@�C���̎擾(XXCOS:MAX���t)
    --==================================
    lv_max_date := FND_PROFILE.VALUE( cv_prf_max_date );
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( lv_max_date IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_max_date );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_max_date := TO_DATE( lv_max_date, cv_short_day );--
--
    END IF;
    --====================================
    -- �v���t�@�C���̎擾(��v����ID)
    --====================================
    gv_bks_id := FND_PROFILE.VALUE( cv_prf_bks_id ); 
--
    IF ( gv_bks_id IS NULL) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_gl_books);
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

  EXCEPTION
--#####################################  �Œ蕔 START ##########################################
    WHEN global_api_expt THEN                             --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_inp_target_cnt :=0;
    gn_inp_line_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    proc_init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �f�[�^���o����(A-2)
    -- ===============================
    proc_extract(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    IF ( gn_target_cnt <> 0 ) AND ( gn_line_cnt <> 0 ) THEN
      -- ================================
      -- �̔����уf�[�^(HHT)���^����(A-3)
      -- ================================
      proc_molded_hht(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF ( gn_inp_target_cnt <> 0 ) AND ( gn_inp_line_cnt <> 0 ) THEN
      -- ================================
      -- �̔����уf�[�^(�[�i�`�[���͉��)���^����(A-9)
      -- ================================
      proc_inp_molded_hht(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF ( gn_target_edi_cnt <> 0 ) AND ( gn_line_edi_cnt <> 0 ) THEN
      -- ================================
      -- �̔����уf�[�^(EDI)���^����(A-4)
      -- ================================
      proc_molded_edi(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF ( gn_transaction_cnt <> 0 ) THEN
      -- ======================================
      --  �̔����уf�[�^�i���o�Ɂj���^����(A-5)
      -- ======================================
      proc_molded_trans(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF ( ( gn_target_cnt <> 0 ) AND ( gn_line_cnt <> 0 ) ) 
      OR ( ( gn_inp_target_cnt <> 0 ) AND ( gn_inp_line_cnt <> 0 ) )
      OR ( ( gn_target_edi_cnt <> 0 ) AND ( gn_line_edi_cnt <> 0 ) )
      OR ( gn_transaction_cnt <> 0 ) 
      OR ( ( gn_inp_target_cnt <> 0 ) AND ( gn_inp_line_cnt <> 0 ) )THEN
      -- =======================================
      -- �̔����уf�[�^�o�^����(A-6)
      -- =======================================
      proc_insert(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--******************************* 2009/05/12 N.Maeda Var1.13 MOD START ***************************************
--    IF ( gn_target_edi_cnt <> 0 ) AND ( gn_line_edi_cnt <> 0 ) THEN
    IF ( gt_oe_order_number.COUNT <> 0 ) THEN
--******************************* 2009/05/12 N.Maeda Var1.13 MOD  END  ***************************************
      -- =======================================
      -- OM�N���[�Y����(A-7)
      -- =======================================
      proc_om_close(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF ( ( gn_target_cnt + gn_target_edi_cnt + gn_transaction_cnt + gn_inp_target_cnt ) > 0 ) THEN
      -- ======================================
      -- �擾���e�[�u���t���O�X�V(A-10)
      -- ======================================
      proc_flg_update(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
--******************************* 2009/04/16 N.Maeda Var1. ADD START ***************************************
    IF ( gn_wae_data_num <> 0 ) THEN
      ov_retcode := cv_status_warn;
      <<war_msg_loop>>
      FOR war_num IN 1..gn_wae_data_num LOOP
        --���b�Z�[�W����
        lv_errmsg := gt_msg_war_data(war_num);
        lv_errbuf := lv_errmsg;
        --���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg);
        --���O�o��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf);
        --��s�}��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
          ,buff   => ''
          );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
          ,buff   => ''
          );
      END LOOP war_msg_loop;
    END IF;
--******************************* 2009/04/16 N.Maeda Var1. ADD END   ***************************************
    IF ( lv_retcode <> cv_status_error ) 
    AND ( ( gn_target_cnt + gn_target_edi_cnt + gn_transaction_cnt + gn_inp_target_cnt ) = 0 ) THEN
      ov_retcode := cv_status_warn;
--      ov_errbuf  := lv_errbuf;
      ov_errmsg  := lv_errbuf;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o�́F�u�x���v���umain�Ń��b�Z�[�W���o�́v����v���̂���ꍇ
    IF (lv_retcode != cv_status_normal) THEN
      --��s�}��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
        ,buff   => ''
        );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      --��s�}��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
        ,buff   => ''
        );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      IF ( lv_retcode <> cv_status_warn ) THEN
        --��s�}��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
          ,buff   => ''
          );
      END IF;
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
    --�w�b�_�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_count_he_target
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt + gn_target_edi_cnt 
                                                   + gn_inp_target_cnt + gn_transaction_head_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���בΏی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_count_li_target
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_line_cnt + gn_line_edi_cnt + gn_transaction_cnt + gn_inp_line_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�w�b�_���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_count_he_update
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���א��������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_count_li_update
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_line_ins_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1 ;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
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
END XXCOS001A05C;
/

