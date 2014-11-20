CREATE OR REPLACE
PACKAGE BODY XXCOK014A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A01C(body)
 * Description      : �̔����я��E�萔���v�Z��������̔̔��萔���v�Z����
 * MD.050           : �����ʔ̎�̋��v�Z���� MD050_COK_014_A01
 * Version          : 1.3
 *
 * Program List
 * -------------------------- ------------------------------------------------------------
 *  Name                       Description
 * -------------------------- ------------------------------------------------------------
 *  main                      �̔����я��E�萔���v�Z��������̔̔��萔���v�Z����
 *  submain                   ���C�������v���V�[�W��
 *  init_proc                 ��������(A-1)
 *  del_bm_support_info       �̎�̋��ێ����ԊO�f�[�^�̍폜(A-2)
 *  chk_customer_info         �����Ώیڋq�f�[�^�̔��f(A-4,A-22,A-40)
 *  get_bm_support_add_info   �̎�̋��v�Z�t�����̎擾(A-5,A-23,A-41)
 *  del_bm_contract_err_info  �̎�����G���[�f�[�^�̍폜(A-6,A-24)
 *  get_active_vendor_info    �x����f�[�^�̎擾(A-9,A-27)
 *  cal_bm_contract10_info    �����ʏ����̌v�Z(A-10,A-28)
 *  cal_bm_contract20_info    �e��敪�ʏ����̌v�Z(A-11,A-29)
 *  cal_bm_contract30_info    �ꗥ�����̌v�Z(A-12,A-30)
 *  cal_bm_contract40_info    ��z�����̌v�Z(A-13,A-31)
 *  cal_bm_contract50_info    �d�C�������̌v�Z(A-14,A-32)
 *  ins_bm_contract_err_info  �̎�����G���[�f�[�^�̓o�^(A-17,A-35)
 *  upd_sales_exp_lines_info  �̔����јA�g���ʂ̍X�V(A-17,A-35,A-46)
 *  del_pre_bm_support_info   �O��̎�̋��v�Z���ʃf�[�^�̍폜(A-18,A-36,A-47)
 *  ins_bm_support_info       �����ʔ̎�̋��v�Z�f�[�^�̓o�^(A-20,A-38,A-49)
 *  
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   K.Ezaki          �V�K�쐬
 *  2009/02/13    1.1   K.Ezaki          ��QCOK_039 �x���������ݒ�ڋq�X�L�b�v
 *  2009/02/17    1.2   K.Ezaki          ��QCOK_040 �t���x���_�[�T�C�g�Œ�C��
 *  2009/02/26    1.3   K.Ezaki          ��QCOK_060 �ꗥ�����v�Z���ʗݐ�
 *  2009/02/26    1.3   K.Ezaki          ��QCOK_061 �ꗥ������z�v�Z
 *  2009/02/25    1.3   K.Ezaki          ��QCOK_062 ��z�������ߗ��E���ߊz���ݒ�
 *  2009/03/25    1.4   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *****************************************************************************************/
--
  ------------------------------------------------------------
  -- ���[�U�[��`�O���[�o���萔
  ------------------------------------------------------------
  -- �p�b�P�[�W��`
  cv_pkg_name       CONSTANT VARCHAR2(12) := 'XXCOK014A01C';                     -- �p�b�P�[�W��
  -- �����l
  cv_msg_part       CONSTANT VARCHAR2(3)  := ' : ';                              -- ���b�Z�[�W�f���~�^
  cv_msg_cont       CONSTANT VARCHAR2(1)  := '.';                                -- �J���}
  cn_zero           CONSTANT NUMBER       := 0;                                  -- ���l:0
  cn_one            CONSTANT NUMBER       := 1;                                  -- ���l:1
  cn_two            CONSTANT NUMBER       := 2;                                  -- ���l:2
  cv_zero           CONSTANT VARCHAR2(1)  := '0';                                -- ����:0
  cv_one            CONSTANT VARCHAR2(1)  := '1';                                -- ����:1
  cv_msg_wq         CONSTANT VARCHAR2(1)  := '"';                                -- �_�u���N�H�[�e�C�V����
  cv_msg_c          CONSTANT VARCHAR2(1)  := ',';                                -- �R���}
  cv_csv_sep        CONSTANT VARCHAR2(1)  := ',';                                -- CSV�Z�p���[�^
  cv_yes            CONSTANT VARCHAR2(1)  := 'Y';                                -- ����:Y
  cv_no             CONSTANT VARCHAR2(1)  := 'N';                                -- ����:N
  cv_output         CONSTANT VARCHAR2(6)  := 'OUTPUT';                           -- �w�b�_���O�o��
  cv_language       CONSTANT VARCHAR2(4)  := 'LANG';                             -- ����
  -- ���t����
  cv_format1        CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';                       -- �����P
  cv_format2        CONSTANT VARCHAR2(6)  := 'YYYYMM';                           -- �����Q
  cv_format3        CONSTANT VARCHAR2(2)  := 'MM';                               -- �����R
  -- �x���_�[�敪
  cv_vendor_type1   CONSTANT VARCHAR2(1)  := '1';                                -- �t���x���_�[
  cv_vendor_type2   CONSTANT VARCHAR2(1)  := '2';                                -- �t���x���_�[����
  cv_vendor_type3   CONSTANT VARCHAR2(1)  := '3';                                -- ���
  -- �ڋq�敪
  cv_cust_type1     CONSTANT VARCHAR2(2)  := '10';                               -- �ڋq
  cv_cust_type2     CONSTANT VARCHAR2(2)  := '13';                               -- �����ڋq
  -- �Ƒԋ敪
  cv_bus_type       CONSTANT VARCHAR2(2)  := '11';                               -- �x���_�[
  -- �Ƒԏ����ދ敪
  cv_bus_type1      CONSTANT VARCHAR2(2)  := '25';                               -- �t���x���_�[
  cv_bus_type2      CONSTANT VARCHAR2(2)  := '24';                               -- �t���x���_�[����
  -- �����敪
  cv_bill_site_use  CONSTANT VARCHAR2(7)  := 'BILL_TO';                          -- ����
  -- �e��Q�_�~�[�R�[�h
  cv_ves_dmmy       CONSTANT VARCHAR2(4)  := '9999';                             -- �e��Q�_�~�[�R�[�h
  -- ��v�J�����_�X�e�[�^�X
  cv_cal_op_status  CONSTANT VARCHAR2(1)  := 'O';                                -- �I�[�v��
  -- �A�g�X�e�[�^�X
  cv_if_status0     CONSTANT VARCHAR2(1)  := '0';                                -- ������
  cv_if_status1     CONSTANT VARCHAR2(1)  := '1';                                -- ������
  cv_if_status2     CONSTANT VARCHAR2(1)  := '2';                                -- �s�v
  -- �x����ޔ�
  cn_bm1_set        CONSTANT PLS_INTEGER  := 1;                                  -- BM1�ޔ�
  cn_bm2_set        CONSTANT PLS_INTEGER  := 2;                                  -- BM2�ޔ�
  cn_bm3_set        CONSTANT PLS_INTEGER  := 3;                                  -- BM3�ޔ�
  -- �x���敪
  cv_bm1_type       CONSTANT VARCHAR2(3)  := 'BM1';                              -- �_��Ҏd����R�[�h
  cv_bm2_type       CONSTANT VARCHAR2(3)  := 'BM2';                              -- �Љ��BM�x���d����R�[�h�P
  cv_bm3_type       CONSTANT VARCHAR2(3)  := 'BM3';                              -- �Љ��BM�x���d����R�[�h�Q
  cv_en1_type       CONSTANT VARCHAR2(3)  := 'EN1';                              -- �d�C��
  -- �x����
  cv_month_type1    CONSTANT VARCHAR2(2)  := '40';                               -- ����
  cv_month_type2    CONSTANT VARCHAR2(2)  := '50';                               -- ����
  -- �T�C�g
  cv_site_type1     CONSTANT VARCHAR2(2)  := '00';                               -- ����
  cv_site_type2     CONSTANT VARCHAR2(2)  := '01';                               -- ����
  -- BM�x���敪
  cv_bm_pay1_type   CONSTANT VARCHAR2(1)  := '1';                                -- FB�x���ē��L
  cv_bm_pay2_type   CONSTANT VARCHAR2(1)  := '2';                                -- FB�x���ē���
  cv_bm_pay3_type   CONSTANT VARCHAR2(1)  := '3';                                -- AP�x��
  cv_bm_pay4_type   CONSTANT VARCHAR2(1)  := '4';                                -- �������Q
  -- �v�Z����
  cv_cal_type10     CONSTANT VARCHAR2(2)  := '10';                               -- �����ʏ���
  cv_cal_type20     CONSTANT VARCHAR2(2)  := '20';                               -- �e��敪�ʏ���
  cv_cal_type30     CONSTANT VARCHAR2(2)  := '30';                               -- �ꗥ����
  cv_cal_type40     CONSTANT VARCHAR2(2)  := '40';                               -- ��z����
  cv_cal_type50     CONSTANT VARCHAR2(2)  := '50';                               -- �d�C��(�Œ�)�^�d�C���i�ϓ��j
  cv_cal_type60     CONSTANT VARCHAR2(2)  := '60';                               -- �����l���z
  -- WHO�J����
  cn_created_by     CONSTANT NUMBER       := fnd_global.user_id;                 -- �쐬�҂̃��[�U�[ID
  cn_last_upd_by    CONSTANT NUMBER       := fnd_global.user_id;                 -- �ŏI�X�V�҂̃��[�U�[ID
  cn_last_upd_login CONSTANT NUMBER       := fnd_global.login_id;                -- �ŏI�X�V�҂̃��O�C��ID
  cn_request_id     CONSTANT NUMBER       := fnd_global.conc_request_id;         -- �v��ID
  cn_prg_appl_id    CONSTANT NUMBER       := fnd_global.prog_appl_id;            -- �R���J�����g�A�v���P�[�V����ID
  cn_program_id     CONSTANT NUMBER       := fnd_global.conc_program_id;         -- �R���J�����g�v���O����ID
  -- �A�v���P�[�V�����Z�k��
  cv_ap_type_xxccp  CONSTANT VARCHAR2(5)  := 'XXCCP';                            -- ����
  cv_ap_type_xxcok  CONSTANT VARCHAR2(5)  := 'XXCOK';                            -- �ʊJ��
  cv_ap_type_sqlgl  CONSTANT VARCHAR2(5)  := 'SQLGL';                            -- ��v
  cv_ap_type_ar     CONSTANT VARCHAR2(2)  := 'AR';                               -- ����
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal  CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn    CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  cv_customer_err   CONSTANT VARCHAR2(1)  := 8;                                  -- �����ΏۊO�ڋq�G���[:8
  cv_contract_err   CONSTANT VARCHAR2(1)  := 9;                                  -- �̎�����G���[:9
  -- ���ʃ��b�Z�[�W��`
  cv_normal_msg     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';                 -- ����I�����b�Z�[�W
  cv_warn_msg       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005';                 -- �x���I�����b�Z�[�W
  cv_error_msg      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90007';                 -- �G���[�I�����b�Z�[�W
  cv_mainmsg_90000  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';                 -- �Ώی����o��
  cv_mainmsg_90001  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';                 -- ���������o��
  cv_mainmsg_90002  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';                 -- �G���[�����o��
  cv_mainmsg_90003  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003';                 -- �X�L�b�v�����o��
  -- �ʃ��b�Z�[�W��`
  cv_prmmsg_00022   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00022';                 -- �Ɩ����t���̓p�����[�^
  cv_prmmsg_00044   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00044';                 -- ���s�敪���̓p�����[�^
  cv_prmmsg_00028   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028';                 -- �Ɩ����t�擾�G���[
  cv_prmmsg_00003   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003';                 -- �v���t�@�C���l�擾�G���[
  cv_prmmsg_00051   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00051';                 -- �̎�̋��ێ����ԊO��񃍃b�N�G���[
  cv_prmmsg_10398   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10398';                 -- �̎�̋��ێ����ԊO���폜�G���[
  cv_prmmsg_10399   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10399';                 -- �_����擾�G���[
  cv_prmmsg_00036   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00036';                 -- ���߁E�x�����擾�G���[
  cv_prmmsg_00027   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00027';                 -- �c�Ɠ��擾�G���[
  cv_prmmsg_00079   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00079';                 -- ������ڋq�擾�G���[
  cv_prmmsg_00011   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00011';                 -- ��v�J�����_���擾�G���[
  cv_prmmsg_00080   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00080';                 -- �̎�����G���[��񃍃b�N�G���[
  cv_prmmsg_10400   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10400';                 -- �̎�����G���[���폜�G���[
  cv_prmmsg_10401   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10401';                 -- �̎�����G���[���o�^�G���[
  cv_prmmsg_10426   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10426';                 -- �̎�����擾�G���[
  cv_prmmsg_10427   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10427';                 -- �x������擾�G���[
  cv_prmmsg_00081   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00081';                 -- �̔����јA�g���ʍX�V���b�N�G���[
  cv_prmmsg_10402   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10402';                 -- �̔����јA�g���ʍX�V�G���[
  cv_prmmsg_10403   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10403';                 -- �̎�̋��O��v�Z���폜�G���[
  cv_prmmsg_10404   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10404';                 -- �̎�̋��v�Z���o�^�G���[
  cv_prmmsg_10405   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10405';                 -- �̔����ю擾�G���[
  cv_prmmsg_00100   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00100';                 -- �@�\��O�G���[
  cv_prmmsg_00101   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00101';                 -- ���ʋ@�\��O�G���[
  -- ���b�Z�[�W�g�[�N����`
  cv_tkn_bis_date   CONSTANT VARCHAR2(13) := 'BUSINESS_DATE';                    -- �Ɩ����t�g�[�N��
  cv_tkn_proc_date  CONSTANT VARCHAR2(9)  := 'PROC_DATE';                        -- �������g�[�N��
  cv_tkn_proc_type  CONSTANT VARCHAR2(9)  := 'PROC_TYPE';                        -- ���s�敪�g�[�N��
  cv_tkn_profile    CONSTANT VARCHAR2(7)  := 'PROFILE';                          -- �v���t�@�C���g�[�N��
  cv_tkn_dept_code  CONSTANT VARCHAR2(9)  := 'DEPT_CODE';                        -- ����R�[�h�g�[�N��
  cv_tkn_cust_code  CONSTANT VARCHAR2(9)  := 'CUST_CODE';                        -- �ڋq�R�[�h�g�[�N��
  cv_tkn_vend_code  CONSTANT VARCHAR2(11) := 'VENDOR_CODE';                      -- �d����R�[�h�g�[�N��
  cv_tkn_close_date CONSTANT VARCHAR2(10) := 'CLOSE_DATE';                       -- ���ߓ��g�[�N��
  cv_tkn_pay_date   CONSTANT VARCHAR2(8)  := 'PAY_DATE';                         -- �x�����g�[�N��
  cv_tkn_sales_amt  CONSTANT VARCHAR2(9)  := 'SALES_AMT';                        -- �����g�[�N��
  cv_tkn_cont_type  CONSTANT VARCHAR2(14) := 'CONTAINER_TYPE';                   -- �e��敪�g�[�N��
  cv_tkn_count      CONSTANT VARCHAR2(5)  := 'COUNT';                            -- �����o�̓g�[�N��
  cv_tkn_errmsg     CONSTANT VARCHAR2(6)  := 'ERRMSG';                           -- �G���[���b�Z�[�W�g�[�N��
  -- �v���t�@�C����`
  cv_pro_org_code   CONSTANT VARCHAR2(30) := 'ORG_ID';                           -- �g�DID
  cv_pro_books_code CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';                 -- ��v����ID
  cv_pro_bm_sup_fm  CONSTANT VARCHAR2(30) := 'XXCOK1_BM_SUPPORT_PERIOD_FROM';    -- �����ʔ̎�̋��v�Z��������(From)
  cv_pro_bm_sup_to  CONSTANT VARCHAR2(30) := 'XXCOK1_BM_SUPPORT_PERIOD_TO';      -- �����ʔ̎�̋��v�Z��������(To)
  cv_pro_sales_ret  CONSTANT VARCHAR2(30) := 'XXCOK1_SALES_RETENTION_PERIOD';    -- �̎�̋��v�Z���ʕێ�����
  cv_pro_elec_ch    CONSTANT VARCHAR2(30) := 'XXCOK1_ELEC_CHANGE_ITEM_CODE';     -- �d�C��(�ϓ�)�i�ڃR�[�h
  cv_pro_vendor     CONSTANT VARCHAR2(30) := 'XXCOK1_VENDOR_DUMMY_CODE';         -- �d����_�~�[�R�[�h
  -- �Q�ƕ\��`
  cv_lk_bm_dis_type CONSTANT VARCHAR2(30) := 'XXCOK1_BM_DISTRICT_PARA_MST';      -- �̎�̋��v�Z���s�敪
  cv_lk_itm_yk_type CONSTANT VARCHAR2(30) := 'XXCMM_ITM_YOKIGUN';                -- �e��Q�敪
  cv_lk_cust_type   CONSTANT VARCHAR2(30) := 'XXCMM_CUST_GYOTAI_SHO';            -- �ڋq�Ƒԏ����ދ敪
  cv_lk_no_inv_type CONSTANT VARCHAR2(30) := 'XXCOK1_NO_INV_ITEM_MST';           -- ��݌ɕi�ڋ敪
  ------------------------------------------------------------
  -- ���[�U�[��`�O���[�o���ϐ�
  ------------------------------------------------------------
  gv_language       fnd_languages.iso_language%TYPE DEFAULT NULL;                -- ����
  gd_proc_date      DATE                            DEFAULT NULL;                -- �Ɩ����t
  gv_proc_type      VARCHAR2(1)                     DEFAULT NULL;                -- ���s�敪
  gn_target_cnt     NUMBER                          DEFAULT 0;                   -- �Ώی���
  gn_normal_cnt     NUMBER                          DEFAULT 0;                   -- ���팏��
  gn_warning_cnt    NUMBER                          DEFAULT 0;                   -- �x������
  gn_error_cnt      NUMBER                          DEFAULT 0;                   -- �G���[����
  gn_customer_cnt   NUMBER                          DEFAULT 0;                   -- �ڋq����
  gn_contract_cnt   NUMBER                          DEFAULT 0;                   -- �̎�����G���[����
  gd_limit_date     DATE                            DEFAULT NULL;                -- �̎�̋��ێ�������
  gn_pro_org_id     NUMBER                          DEFAULT NULL;                -- �g�DID
  gn_pro_books_id   NUMBER                          DEFAULT NULL;                -- ��v����ID
  gn_pro_bm_sup_fm  NUMBER                          DEFAULT NULL;                -- �����ʔ̎�̋��v�Z��������(From)
  gn_pro_bm_sup_to  NUMBER                          DEFAULT NULL;                -- �����ʔ̎�̋��v�Z��������(To)
  gn_pro_sales_ret  NUMBER                          DEFAULT NULL;                -- �̎�̋��v�Z���ʕێ�����
  gv_pro_elec_ch    VARCHAR2(7)                     DEFAULT NULL;                -- �d�C��(�ϓ�)�i�ڃR�[�h
  gv_pro_vendor     VARCHAR2(9)                     DEFAULT NULL;                -- �d����_�~�[�R�[�h
  gv_pro_vendor_s   VARCHAR2(9)                     DEFAULT NULL;                -- �d����T�C�g�_�~�[�R�[�h
  gv_bm1_vendor     VARCHAR2(9)                     DEFAULT NULL;                -- BM1�d����R�[�h
  gv_bm1_vendor_s   VARCHAR2(9)                     DEFAULT NULL;                -- BM1�d����T�C�g�R�[�h
  gv_sales_upd_flg  VARCHAR2(1)                     DEFAULT NULL;                -- �̔����эX�V�t���O
  ------------------------------------------------------------
  -- ���[�U�[��`�O���[�o���e�[�u���E���R�[�h�^
  ------------------------------------------------------------
  -- �x�������ޔ��e�[�u���^
  TYPE g_term_name_ttype IS TABLE OF ra_terms_tl.name%TYPE INDEX BY BINARY_INTEGER;
  -- ���ߓ����ޔ����R�[�h�^
  TYPE g_close_date_rtype IS RECORD (
     start_date xxcok_cond_bm_support.closing_date%TYPE                          -- �̎�v�Z�J�n��
    ,end_date   xxcok_cond_bm_support.closing_date%TYPE                          -- �̎�v�Z�I����
    ,close_date xxcok_cond_bm_support.closing_date%TYPE                          -- ���ߓ�
    ,pay_date   xxcok_cond_bm_support.expect_payment_date%TYPE                   -- �x����
    ,term_name  ra_terms_tl.name%TYPE                                            -- �x������
  );
  -- ���ߓ����ޔ��e�[�u���^
  TYPE g_close_date_ttype IS TABLE OF g_close_date_rtype INDEX BY BINARY_INTEGER;
  -- �����x���������ޔ����R�[�h�^
  TYPE g_many_term_rtype IS RECORD (
     to_close_date xxcok_cond_bm_support.closing_date%TYPE                       -- ������ߓ�
    ,to_pay_date   xxcok_cond_bm_support.expect_payment_date%TYPE                -- ����x����
    ,to_term_name  ra_terms_tl.name%TYPE                                         -- ����x������
    ,fm_close_date xxcok_cond_bm_support.closing_date%TYPE                       -- �O����ߓ�
    ,fm_pay_date   xxcok_cond_bm_support.expect_payment_date%TYPE                -- �O��x����
    ,fm_term_name  ra_terms_tl.name%TYPE                                         -- �O��x������
    ,end_date      xxcok_cond_bm_support.closing_date%TYPE                       -- �̎�v�Z�I����
  );
  -- �����x���������ޔ��e�[�u���^
  TYPE g_many_term_ttype IS TABLE OF g_many_term_rtype INDEX BY BINARY_INTEGER;
  -- �v�Z�����ޔ��e�[�u���^
  TYPE g_calculation_ttype IS TABLE OF xxcok_mst_bm_contract.calc_type%TYPE INDEX BY BINARY_INTEGER;
  -- �x����`�F�b�N�ޔ����R�[�h�^
  TYPE g_vendor_rtype IS RECORD (
     bm_type     VARCHAR2(3)                                                     -- �x���敪
    ,vendor_code po_vendors.segment1%TYPE                                        -- �d����R�[�h
  );
  -- �x����`�F�b�N�ޔ��e�[�u���^
  TYPE g_vendor_ttype IS TABLE OF g_vendor_rtype INDEX BY BINARY_INTEGER;
  -- �̎�̋��v�Z�o�^���ޔ����R�[�h�^
  TYPE g_bm_support_rtype IS RECORD (
     bm_type              VARCHAR2(3)                                            -- �x���敪
    ,base_code            xxcok_cond_bm_support.base_code%TYPE                   -- ���_�R�[�h
    ,emp_code             xxcok_cond_bm_support.emp_code%TYPE                    -- �S���҃R�[�h
    ,delivery_cust_code   xxcok_cond_bm_support.delivery_cust_code%TYPE          -- �ڋq�y�[�i��z
    ,demand_to_cust_code  xxcok_cond_bm_support.demand_to_cust_code%TYPE         -- �ڋq�y������z
    ,acctg_year           xxcok_cond_bm_support.acctg_year%TYPE                  -- ��v�N�x
    ,chain_store_code     xxcok_cond_bm_support.chain_store_code%TYPE            -- �`�F�[���X�R�[�h
    ,supplier_code        xxcok_cond_bm_support.supplier_code%TYPE               -- �d����R�[�h
    ,supplier_site_code   xxcok_cond_bm_support.supplier_site_code%TYPE          -- �d����T�C�g�R�[�h
    ,calc_type            xxcok_cond_bm_support.calc_type%TYPE                   -- �v�Z����
    ,delivery_date        xxcok_cond_bm_support.delivery_date%TYPE               -- �[�i���N��
    ,delivery_qty         xxcok_cond_bm_support.delivery_qty%TYPE                -- �[�i����
    ,delivery_unit_type   xxcok_cond_bm_support.delivery_unit_type%TYPE          -- �[�i�P��
    ,selling_amt_tax      xxcok_cond_bm_support.selling_amt_tax%TYPE             -- ������z(�ō�)
    ,rebate_rate          xxcok_cond_bm_support.rebate_rate%TYPE                 -- ���ߗ�
    ,rebate_amt           xxcok_cond_bm_support.rebate_amt%TYPE                  -- ���ߊz
    ,container_type       xxcok_cond_bm_support.container_type_code%TYPE         -- �e��敪�R�[�h
    ,selling_price        xxcok_cond_bm_support.selling_price%TYPE               -- �������z
    ,cond_bm_amt_tax      xxcok_cond_bm_support.cond_bm_amt_tax%TYPE             -- �����ʎ萔���z(�ō�)
    ,cond_bm_amt_no_tax   xxcok_cond_bm_support.cond_bm_amt_no_tax%TYPE          -- �����ʎ萔���z(�Ŕ�)
    ,cond_tax_amt         xxcok_cond_bm_support.cond_tax_amt%TYPE                -- �����ʏ���Ŋz
    ,electric_amt_tax     xxcok_cond_bm_support.electric_amt_tax%TYPE            -- �d�C��(�ō�)
    ,electric_amt_no_tax  xxcok_cond_bm_support.electric_amt_no_tax%TYPE         -- �d�C��(�Ŕ�)
    ,electric_tax_amt     xxcok_cond_bm_support.electric_tax_amt%TYPE            -- �d�C������Ŋz
    ,csh_rcpt_dis_amt     xxcok_cond_bm_support.csh_rcpt_discount_amt%TYPE       -- �����l���z
    ,csh_rcpt_dis_amt_tax xxcok_cond_bm_support.csh_rcpt_discount_amt_tax%TYPE   -- �����l������Ŋz
    ,tax_class            xxcok_cond_bm_support.consumption_tax_class%TYPE       -- ����ŋ敪
    ,tax_code             xxcok_cond_bm_support.tax_code%TYPE                    -- �ŋ��R�[�h
    ,tax_rate             xxcok_cond_bm_support.tax_rate%TYPE                    -- ����ŗ�
    ,term_code            xxcok_cond_bm_support.term_code%TYPE                   -- �x������
    ,closing_date         xxcok_cond_bm_support.closing_date%TYPE                -- ���ߓ�
    ,expect_payment_date  xxcok_cond_bm_support.expect_payment_date%TYPE         -- �x���\���
    ,calc_period_from     xxcok_cond_bm_support.calc_target_period_from%TYPE     -- �v�Z�Ώۊ���(From)
    ,calc_period_to       xxcok_cond_bm_support.calc_target_period_to%TYPE       -- �v�Z�Ώۊ���(To)
    ,cond_bm_if_status    xxcok_cond_bm_support.cond_bm_interface_status%TYPE    -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)
    ,cond_bm_if_date      xxcok_cond_bm_support.cond_bm_interface_date%TYPE      -- �A�g��(�����ʔ̎�̋�)
    ,bm_interface_status  xxcok_cond_bm_support.bm_interface_status%TYPE         -- �A�g�X�e�[�^�X(�̎�c��)
    ,bm_interface_date    xxcok_cond_bm_support.bm_interface_date%TYPE           -- �A�g��(�̎�c��)
    ,ar_interface_status  xxcok_cond_bm_support.ar_interface_status%TYPE         -- �A�g�X�e�[�^�X(AR)
    ,ar_interface_date    xxcok_cond_bm_support.ar_interface_date%TYPE           -- �A�g��(AR)
  );
  -- �̎�̋��v�Z�o�^���ޔ��e�[�u���^
  TYPE g_bm_support_ttype IS TABLE OF g_bm_support_rtype INDEX BY BINARY_INTEGER;
  ------------------------------------------------------------
  -- ���[�U�[��`��O
  ------------------------------------------------------------
  -- ���ʗ�O
  global_process_expt    EXCEPTION;                                              -- ���������ʗ�O
  global_api_expt        EXCEPTION;                                              -- ���ʊ֐���O
  global_api_others_expt EXCEPTION;                                              -- ���ʊ֐�OTHERS��O
  global_lock_expt       EXCEPTION;                                              -- �O���[�o����O
  -- �v���O�}
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
  --
  /**********************************************************************************
   * Procedure Name   : ins_bm_support_info
   * Description      : �����ʔ̎�̋��v�Z�f�[�^�̓o�^(A-20,A-38,A-49)
   ***********************************************************************************/
  PROCEDURE ins_bm_support_info(
     ov_errbuf        OUT VARCHAR2                                -- �G���[���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2                                -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2                                -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_vendor_type   IN  VARCHAR2                                -- �x���_�[�敪
    ,id_fm_close_date IN  xxcok_cond_bm_support.closing_date%TYPE -- �O����ߓ�
    ,id_to_close_date IN  xxcok_cond_bm_support.closing_date%TYPE -- ������ߓ�
    ,it_bm_support    IN  g_bm_support_ttype                      -- �̎�̋��v�Z�o�^���
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'ins_bm_support_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000);   -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000);   -- ���b�Z�[�W
    lb_retcode  BOOLEAN;          -- ���b�Z�[�W�߂�l
    ln_cnt      PLS_INTEGER := 0; -- �J�E���^
    ln_ins_cnt  PLS_INTEGER := 0; -- �o�^�����J�E���^
  --
  BEGIN
  --
    --===============================================
    -- A-0.������
    --===============================================
    lv_retcode := cv_status_normal;
    --===============================================
    -- A-1.�����ʔ̎�̋��v�Z�o�^
    --===============================================
    BEGIN
      << bm_support_all_loop >>
      FOR ln_cnt IN it_bm_support.FIRST..it_bm_support.LAST LOOP
        -------------------------------------------------
        -- �����ʔ̎�̋��v�Z�o�^
        -------------------------------------------------
        INSERT INTO xxcok_cond_bm_support(
           cond_bm_support_id        -- �����ʔ̎�̋�ID
          ,base_code                 -- ���_�R�[�h
          ,emp_code                  -- �S���҃R�[�h
          ,delivery_cust_code        -- �ڋq�y�[�i��z
          ,demand_to_cust_code       -- �ڋq�y������z
          ,acctg_year                -- ��v�N�x
          ,chain_store_code          -- �`�F�[���X�R�[�h
          ,supplier_code             -- �d����R�[�h
          ,supplier_site_code        -- �d����T�C�g�R�[�h
          ,calc_type                 -- �v�Z����
          ,delivery_date             -- �[�i���N��
          ,delivery_qty              -- �[�i����
          ,delivery_unit_type        -- �[�i�P��
          ,selling_amt_tax           -- ������z(�ō�)
          ,rebate_rate               -- ���ߗ�
          ,rebate_amt                -- ���ߊz
          ,container_type_code       -- �e��敪�R�[�h
          ,selling_price             -- �������z
          ,cond_bm_amt_tax           -- �����ʎ萔���z(�ō�)
          ,cond_bm_amt_no_tax        -- �����ʎ萔���z(�Ŕ�)
          ,cond_tax_amt              -- �����ʏ���Ŋz
          ,electric_amt_tax          -- �d�C��(�ō�)
          ,electric_amt_no_tax       -- �d�C��(�Ŕ�)
          ,electric_tax_amt          -- �d�C������Ŋz
          ,csh_rcpt_discount_amt     -- �����l���z
          ,csh_rcpt_discount_amt_tax -- �����l������Ŋz
          ,consumption_tax_class     -- ����ŋ敪
          ,tax_code                  -- �ŋ��R�[�h
          ,tax_rate                  -- ����ŗ�
          ,term_code                 -- �x������
          ,closing_date              -- ���ߓ�
          ,expect_payment_date       -- �x���\���
          ,calc_target_period_from   -- �v�Z�Ώۊ���(From)
          ,calc_target_period_to     -- �v�Z�Ώۊ���(To)
          ,cond_bm_interface_status  -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)
          ,cond_bm_interface_date    -- �A�g��(�����ʔ̎�̋�)
          ,bm_interface_status       -- �A�g�X�e�[�^�X(�̎�c��)
          ,bm_interface_date         -- �A�g��(�̎�c��)
          ,ar_interface_status       -- �A�g�X�e�[�^�X(AR)
          ,ar_interface_date         -- �A�g��(AR)
          ,created_by                -- �쐬��
          ,creation_date             -- �쐬��
          ,last_updated_by           -- �ŏI�X�V��
          ,last_update_date          -- �ŏI�X�V��
          ,last_update_login         -- �ŏI�X�V���O�C��
          ,request_id                -- �v��ID
          ,program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id                -- �R���J�����g�E�v���O����ID
          ,program_update_date       -- �v���O�����X�V��
        ) VALUES (
           xxcok_cond_bm_support_s01.NEXTVAL            -- �����ʔ̎�̋�ID
          ,it_bm_support( ln_cnt ).base_code            -- ���_�R�[�h
          ,it_bm_support( ln_cnt ).emp_code             -- �S���҃R�[�h
          ,it_bm_support( ln_cnt ).delivery_cust_code   -- �ڋq�y�[�i��z
          ,it_bm_support( ln_cnt ).demand_to_cust_code  -- �ڋq�y������z
          ,it_bm_support( ln_cnt ).acctg_year           -- ��v�N�x
          ,it_bm_support( ln_cnt ).chain_store_code     -- �`�F�[���X�R�[�h
          ,it_bm_support( ln_cnt ).supplier_code        -- �d����R�[�h
          ,it_bm_support( ln_cnt ).supplier_site_code   -- �d����T�C�g�R�[�h
          ,it_bm_support( ln_cnt ).calc_type            -- �v�Z����
          ,it_bm_support( ln_cnt ).delivery_date        -- �[�i���N��
          ,it_bm_support( ln_cnt ).delivery_qty         -- �[�i����
          ,it_bm_support( ln_cnt ).delivery_unit_type   -- �[�i�P��
          ,it_bm_support( ln_cnt ).selling_amt_tax      -- ������z(�ō�)
          ,it_bm_support( ln_cnt ).rebate_rate          -- ���ߗ�
          ,it_bm_support( ln_cnt ).rebate_amt           -- ���ߊz
          ,it_bm_support( ln_cnt ).container_type       -- �e��敪�R�[�h
          ,it_bm_support( ln_cnt ).selling_price        -- �������z
          ,it_bm_support( ln_cnt ).cond_bm_amt_tax      -- �����ʎ萔���z(�ō�)
          ,it_bm_support( ln_cnt ).cond_bm_amt_no_tax   -- �����ʎ萔���z(�Ŕ�)
          ,it_bm_support( ln_cnt ).cond_tax_amt         -- �����ʏ���Ŋz
          ,it_bm_support( ln_cnt ).electric_amt_tax     -- �d�C��(�ō�)
          ,it_bm_support( ln_cnt ).electric_amt_no_tax  -- �d�C��(�Ŕ�)
          ,it_bm_support( ln_cnt ).electric_tax_amt     -- �d�C������Ŋz
          ,it_bm_support( ln_cnt ).csh_rcpt_dis_amt     -- �����l���z
          ,it_bm_support( ln_cnt ).csh_rcpt_dis_amt_tax -- �����l������Ŋz
          ,it_bm_support( ln_cnt ).tax_class            -- ����ŋ敪
          ,it_bm_support( ln_cnt ).tax_code             -- �ŋ��R�[�h
          ,it_bm_support( ln_cnt ).tax_rate             -- ����ŗ�
          ,it_bm_support( ln_cnt ).term_code            -- �x������
          ,it_bm_support( ln_cnt ).closing_date         -- ���ߓ�
          ,it_bm_support( ln_cnt ).expect_payment_date  -- �x���\���
          ,it_bm_support( ln_cnt ).calc_period_from     -- �v�Z�Ώۊ���(From)
          ,it_bm_support( ln_cnt ).calc_period_to       -- �v�Z�Ώۊ���(To)
          ,it_bm_support( ln_cnt ).cond_bm_if_status    -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)
          ,it_bm_support( ln_cnt ).cond_bm_if_date      -- �A�g��(�����ʔ̎�̋�)
          ,it_bm_support( ln_cnt ).bm_interface_status  -- �A�g�X�e�[�^�X(�̎�c��)
          ,it_bm_support( ln_cnt ).bm_interface_date    -- �A�g��(�̎�c��)
          ,it_bm_support( ln_cnt ).ar_interface_status  -- �A�g�X�e�[�^�X(AR)
          ,it_bm_support( ln_cnt ).ar_interface_date    -- �A�g��(AR)
          ,cn_created_by                                -- �쐬��
          ,SYSDATE                                      -- �쐬��
          ,cn_last_upd_by                               -- �ŏI�X�V��
          ,SYSDATE                                      -- �ŏI�X�V��
          ,cn_last_upd_login                            -- �ŏI�X�V���O�C��
          ,cn_request_id                                -- �v��ID
          ,cn_prg_appl_id                               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,cn_program_id                                -- �R���J�����g�E�v���O����ID
          ,SYSDATE                                      -- �v���O�����X�V��
        );
        -- �o�^�������C���N�������g
        ln_ins_cnt := ln_ins_cnt + 1;
      END LOOP bm_support_all_loop;
    EXCEPTION
      ----------------------------------------------------------
      -- �����ʔ̎�̋��v�Z�o�^��O
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_10404
                        ,iv_token_name1  => cv_tkn_cust_code
                        ,iv_token_value1 => it_bm_support( ln_ins_cnt ).delivery_cust_code
                        ,iv_token_name2  => cv_tkn_close_date
                        ,iv_token_value2 => TO_CHAR( id_to_close_date,cv_format1 )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- �o�͋敪
                        ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line => cn_zero         -- ���s
                      );
        ov_errmsg  := lv_out_msg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
    END;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END ins_bm_support_info;
  --
  /**********************************************************************************
   * Procedure Name   : del_pre_bm_support_info
   * Description      : �O��̎�̋��v�Z���ʃf�[�^�̍폜(A-18,A-36,A-47)
   ***********************************************************************************/
  PROCEDURE del_pre_bm_support_info(
     ov_errbuf        OUT VARCHAR2                                -- �G���[���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2                                -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2                                -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE    -- �ڋq�R�[�h
    ,id_close_date    IN  xxcok_cond_bm_support.closing_date%TYPE -- ���ߓ�
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'del_pre_bm_support_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- API���^�[���E���b�Z�[�W�p
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �����ʔ̎�̋��e�[�u�����b�N
    CURSOR bm_support_del_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE    -- �ڋq�R�[�h
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE -- ���ߓ�
    )
    IS
      SELECT xcs.cond_bm_support_id AS bm_support_id -- �O��̎�̋��v�Z����
      FROM   xxcok_cond_bm_support xcs -- �����ʔ̎�̋��e�[�u��
      WHERE  xcs.delivery_cust_code = iv_customer_code
      AND    xcs.closing_date       = id_close_date
      FOR UPDATE NOWAIT;
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.�O��̎�̋��v�Z���ʃf�[�^�폜���b�N����
    -------------------------------------------------
    -- ���b�N����
    OPEN bm_support_del_cur(
       iv_customer_code -- �ڋq�R�[�h
      ,id_close_date    -- ���ߓ�
    );
    CLOSE bm_support_del_cur;
    -------------------------------------------------
    -- 2.�O��̎�̋��v�Z���ʃf�[�^�폜����
    -------------------------------------------------
    BEGIN
      DELETE FROM xxcok_cond_bm_support xcs
      WHERE  xcs.delivery_cust_code = iv_customer_code
      AND    xcs.closing_date       = id_close_date;
    EXCEPTION
      ----------------------------------------------------------
      -- �O��̎�̋��v�Z���ʃf�[�^�폜��O
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_10403
                        ,iv_token_name1  => cv_tkn_cust_code
                        ,iv_token_value1 => iv_customer_code
                        ,iv_token_name2  => cv_tkn_close_date
                        ,iv_token_value2 => TO_CHAR( id_close_date,cv_format1 )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- �o�͋敪
                        ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line => cn_zero         -- ���s
                      );
        ov_errmsg  := lv_out_msg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
        ov_retcode := cv_status_error;
    END;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ���b�N��O�n���h��
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00051
                    );    
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END del_pre_bm_support_info;
  --
  /**********************************************************************************
   * Procedure Name   : upd_sales_exp_lines_info
   * Description      : �̔����јA�g���ʂ̍X�V(A-17,A-35,A-46)
   ***********************************************************************************/
  PROCEDURE upd_sales_exp_lines_info(
     ov_errbuf           OUT VARCHAR2                                           -- �G���[���b�Z�[�W
    ,ov_retcode          OUT VARCHAR2                                           -- ���^�[���E�R�[�h
    ,ov_errmsg           OUT VARCHAR2                                           -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_if_status        IN  xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE  -- �萔���v�Z�C���^�t�F�[�X�σt���O
    ,iv_customer_code    IN  hz_cust_accounts.account_number%TYPE               -- �ڋq�R�[�h
    ,iv_invoice_num      IN  xxcos_sales_exp_lines.dlv_invoice_number%TYPE      -- �[�i�`�[�ԍ�
    ,iv_invoice_line_num IN  xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE -- �[�i���הԍ�
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_sales_exp_lines_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- API���^�[���E���b�Z�[�W�p
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �̔����і��׃e�[�u�����b�N
    CURSOR sales_exp_lines_upd_cur(
       iv_invoice_num      IN xxcos_sales_exp_lines.dlv_invoice_number%TYPE      -- �[�i�`�[�ԍ�
      ,iv_invoice_line_num IN xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE -- �[�i���הԍ�
    )
    IS
      SELECT xsl.sales_exp_line_id AS sales_exp_line_id -- �̔����і���
      FROM   xxcos_sales_exp_lines xsl -- �̔����і��׃e�[�u��
      WHERE  xsl.dlv_invoice_number      = iv_invoice_num
      AND    xsl.dlv_invoice_line_number = iv_invoice_line_num
      FOR UPDATE NOWAIT;
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.�̔����і��׃e�[�u�����b�N����
    -------------------------------------------------
    -- ���b�N����
    OPEN sales_exp_lines_upd_cur(
       iv_invoice_num      -- �[�i�`�[�ԍ�
      ,iv_invoice_line_num -- �[�i���הԍ�
    );
    CLOSE sales_exp_lines_upd_cur;
    -------------------------------------------------
    -- 2.�̔����јA�g���ʍX�V����
    -------------------------------------------------
    BEGIN
      UPDATE xxcos_sales_exp_lines -- �̔����і��׃e�[�u��
      SET    to_calculate_fees_flag = iv_if_status      -- �萔���v�Z�C���^�t�F�[�X�σt���O
            ,last_updated_by        = cn_last_upd_by    -- �ŏI�X�V��
            ,last_update_date       = SYSDATE           -- �ŏI�X�V��
            ,last_update_login      = cn_last_upd_login -- �ŏI�X�V���O�C��
            ,request_id             = cn_request_id     -- �v��ID
            ,program_application_id = cn_prg_appl_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id             = cn_program_id     -- �R���J�����g�E�v���O����ID
            ,program_update_date    = SYSDATE           -- �v���O�����X�V��
      WHERE  dlv_invoice_number      = iv_invoice_num
      AND    dlv_invoice_line_number = iv_invoice_line_num;
    EXCEPTION
      ----------------------------------------------------------
      -- �̔����јA�g���ʍX�V��O
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_10402
                        ,iv_token_name1  => cv_tkn_cust_code
                        ,iv_token_value1 => iv_customer_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- �o�͋敪
                        ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line => cn_zero         -- ���s
                      );
        ov_errmsg  := lv_out_msg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
        ov_retcode := cv_status_error;
    END;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ���b�N��O�n���h��
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00081
                    );    
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END upd_sales_exp_lines_info;
  --
  /**********************************************************************************
   * Procedure Name   : ins_bm_contract_err_info
   * Description      : �̎�����G���[�f�[�^�̓o�^(A-17,A-35)
   ***********************************************************************************/
  PROCEDURE ins_bm_contract_err_info(
     ov_errbuf         OUT VARCHAR2                                     -- �G���[���b�Z�[�W
    ,ov_retcode        OUT VARCHAR2                                     -- ���^�[���E�R�[�h
    ,ov_errmsg         OUT VARCHAR2                                     -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_base_code      IN  xxcos_sales_exp_headers.sales_base_code%TYPE -- ���_�R�[�h
    ,iv_customer_code  IN  hz_cust_accounts.account_number%TYPE         -- �ڋq�R�[�h
    ,iv_item_code      IN  xxcos_sales_exp_lines.item_code%TYPE         -- �i�ڃR�[�h
    ,iv_container_type IN  fnd_lookup_values.attribute1%TYPE            -- �e��敪�R�[�h
    ,in_retail_amount  IN  xxcos_sales_exp_lines.dlv_unit_price%TYPE    -- ����
    ,in_sales_amount   IN  xxcos_sales_exp_lines.sale_amount%TYPE       -- ������z(�ō�)
    ,id_close_date     IN  xxcok_cond_bm_support.closing_date%TYPE      -- ���ߓ�
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(30) := 'ins_bm_contract_err_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- ���b�Z�[�W�߂�l
  --
  BEGIN
  --
    --===============================================
    -- A-0.������
    --===============================================
    ov_retcode := cv_status_normal;
    --===============================================
    -- A-1.�̎�����G���[�o�^
    --===============================================
    BEGIN
      INSERT INTO xxcok_bm_contract_err(
         base_code              -- ���_�R�[�h
        ,cust_code              -- �ڋq�R�[�h
        ,item_code              -- �i�ڃR�[�h
        ,container_type_code    -- �e��敪�R�[�h
        ,selling_price          -- ����
        ,selling_amt_tax        -- ������z(�ō�)
        ,closing_date           -- ���ߓ�
        ,created_by             -- �쐬��
        ,creation_date          -- �쐬��
        ,last_updated_by        -- �ŏI�X�V��
        ,last_update_date       -- �ŏI�X�V��
        ,last_update_login      -- �ŏI�X�V���O�C��
        ,request_id             -- �v��ID
        ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id             -- �R���J�����g�E�v���O����ID
        ,program_update_date    -- �v���O�����X�V��
      ) VALUES (
         iv_base_code      -- ���_�R�[�h
        ,iv_customer_code  -- �ڋq�R�[�h
        ,iv_item_code      -- �i�ڃR�[�h
        ,iv_container_type -- �e��敪�R�[�h
        ,in_retail_amount  -- ����
        ,in_sales_amount   -- ������z(�ō�)
        ,id_close_date     -- ���ߓ�
        ,cn_created_by     -- �쐬��
        ,SYSDATE           -- �쐬��
        ,cn_last_upd_by    -- �ŏI�X�V��
        ,SYSDATE           -- �ŏI�X�V��
        ,cn_last_upd_login -- �ŏI�X�V���O�C��
        ,cn_request_id     -- �v��ID
        ,cn_prg_appl_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,cn_program_id     -- �R���J�����g�E�v���O����ID
        ,SYSDATE           -- �v���O�����X�V��
      );
    EXCEPTION
      ----------------------------------------------------------
      -- �̎�����G���[�o�^��O
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_10401
                        ,iv_token_name1  => cv_tkn_dept_code
                        ,iv_token_value1 => iv_base_code
                        ,iv_token_name2  => cv_tkn_cust_code
                        ,iv_token_value2 => iv_customer_code
                        ,iv_token_name3  => cv_tkn_close_date
                        ,iv_token_value3 => TO_CHAR( id_close_date,cv_format1 )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- �o�͋敪
                        ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line => cn_zero         -- ���s
                      );
        ov_errmsg  := lv_out_msg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
    END;
    --===============================================
    -- A-2.�̎�����G���[���b�Z�[�W�o��
    --===============================================
    IF ( ov_retcode = cv_status_normal ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_10426
                      ,iv_token_name1  => cv_tkn_cust_code
                      ,iv_token_value1 => iv_customer_code
                      ,iv_token_name2  => cv_tkn_sales_amt
                      ,iv_token_value2 => TO_CHAR( in_retail_amount )
                      ,iv_token_name3  => cv_tkn_cont_type
                      ,iv_token_value3 => iv_container_type
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
    END IF;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END ins_bm_contract_err_info;
  --
  /**********************************************************************************
   * Procedure Name   : cal_bm_contract60_info
   * Description      : �����l���z�̌v�Z(A-43)
   ***********************************************************************************/
  PROCEDURE cal_bm_contract60_info(
     ov_errbuf        OUT VARCHAR2                                             -- �G���[���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2                                             -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2                                             -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE                 -- �ڋq�R�[�h
    ,id_close_date    IN  xxcok_cond_bm_support.closing_date%TYPE              -- ���ߓ�
    ,in_sale_amount   IN  xxcos_sales_exp_lines.sale_amount%TYPE               -- ������z
    ,in_tax_rate      IN  xxcos_sales_exp_headers.tax_rate%TYPE                -- ����ŗ�
    ,in_discount_rate IN  xxcmm_cust_accounts.receiv_discount_rate%TYPE        -- �����l����
    ,on_rc_amount     OUT xxcok_cond_bm_support.csh_rcpt_discount_amt%TYPE     -- �����l���z
    ,on_rc_amount_tax OUT xxcok_cond_bm_support.csh_rcpt_discount_amt_tax%TYPE -- �����l������Ŋz
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'cal_bm_contract60_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- API���^�[���E���b�Z�[�W�p
    -- �v�Z���ʑޔ�
    ln_rc_amount     xxcok_cond_bm_support.csh_rcpt_discount_amt%TYPE     := NULL; -- �����l���z
    ln_rc_amount_tax xxcok_cond_bm_support.csh_rcpt_discount_amt_tax%TYPE := NULL; -- �����l������Ŋz
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.�����l���z�v�Z
    -------------------------------------------------
    -- �����l���z��������z�~�����l����
    ln_rc_amount := NVL( in_sale_amount,cn_zero ) * ( NVL( in_discount_rate,cn_zero ) / 100 );
    -- �����l���z�Ŕ����������l���z��(1�{(100/�̔����я��.����ŗ�))
    ln_rc_amount_tax := ROUND( NVL( ln_rc_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
    -- �����l������Ŋz���̔��萔���|�̔��萔���Ŕ���
    ln_rc_amount_tax := ln_rc_amount - ln_rc_amount_tax;
    -------------------------------------------------
    -- 3.�߂�l�ݒ�
    -------------------------------------------------
    on_rc_amount     := ln_rc_amount;     -- �����l���z
    on_rc_amount_tax := ln_rc_amount_tax; -- �����l������Ŋz
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END cal_bm_contract60_info;
  --
  /**********************************************************************************
   * Procedure Name   : cal_bm_contract50_info
   * Description      : �d�C�������̌v�Z(A-14,A-32)
   ***********************************************************************************/
  PROCEDURE cal_bm_contract50_info(
     ov_errbuf        OUT VARCHAR2                                           -- �G���[���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2                                           -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2                                           -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE               -- �ڋq�R�[�h
    ,id_close_date    IN  xxcok_cond_bm_support.closing_date%TYPE            -- ���ߓ�
    ,iv_calculat_type IN  xxcok_mst_bm_contract.calc_type%TYPE               -- �v�Z����
    ,in_tax_rate      IN  xxcos_sales_exp_headers.tax_rate%TYPE              -- ����ŗ�
    ,iv_con_tax_class IN  xxcos_sales_exp_headers.consumption_tax_class%TYPE -- ����ŋ敪
    ,on_el_amount     OUT xxcok_cond_bm_support.electric_amt_tax%TYPE        -- �d�C��
    ,on_el_amount_tax OUT xxcok_cond_bm_support.electric_tax_amt%TYPE        -- �d�C������Ŋz
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'cal_bm_contract50_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- API���^�[���E���b�Z�[�W�p
    -- �v�Z���ʑޔ�
    ln_el_amount     xxcok_cond_bm_support.electric_amt_tax%TYPE := NULL; -- �d�C��
    ln_el_amount_tax xxcok_cond_bm_support.electric_tax_amt%TYPE := NULL; -- �d�C������Ŋz
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �̎�������J�[�\����`
    CURSOR contract_mst_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE    -- �ڋq�R�[�h
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE -- ���ߓ�
      ,iv_calculat_type IN xxcok_mst_bm_contract.calc_type%TYPE    -- �v�Z����
    )
    IS
      SELECT xmb.calc_type AS calc_type -- �v�Z����
            ,xmb.bm1_amt   AS bm1_amt   -- BM1���z
      FROM   xxcok_mst_bm_contract xmb
      WHERE  xmb.cust_code        = iv_customer_code
      AND    xmb.calc_target_flag = cv_yes -- Y�F�v�Z�Ώ�
      AND    xmb.calc_type        = iv_calculat_type
      AND    id_close_date BETWEEN NVL( xmb.start_date_active,id_close_date )
                           AND     NVL( xmb.end_date_active,id_close_date );
    -- �̎������񃌃R�[�h��`
    contract_mst_rec contract_mst_cur%ROWTYPE;
    --===============================
    -- ���[�J����O
    --===============================
    contract_err_expt EXCEPTION; -- �̎�����G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.�d�C����������
    -------------------------------------------------
    OPEN contract_mst_cur(
       iv_customer_code -- �ڋq�R�[�h
      ,id_close_date    -- ���ߓ��F������ߓ�
      ,iv_calculat_type -- �v�Z����
    );
    FETCH contract_mst_cur INTO contract_mst_rec;
    -- �������݃`�F�b�N
    IF ( contract_mst_cur%NOTFOUND ) THEN
      -- �J�[�\���N���[�Y
      CLOSE contract_mst_cur;
      -- �̎�����G���[
      RAISE contract_err_expt;
    END IF;
    -- �J�[�\���N���[�Y
    CLOSE contract_mst_cur;
    -------------------------------------------------
    -- 2.�d�C�������v�Z
    -------------------------------------------------
    -- �ŋ敪����ېł̏ꍇ
    IF ( iv_con_tax_class = cv_zero ) THEN
      -- �d�C����0
      ln_el_amount := cn_zero;
      -- �d�C������Ŋz��0
      ln_el_amount_tax := cn_zero;
    -- �ŋ敪����ېňȊO�̏ꍇ
    ELSE
      -- �d�C����BM1���z
      ln_el_amount := NVL( contract_mst_rec.bm1_amt,cn_zero );
      -- �d�C���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
      ln_el_amount_tax := ROUND( NVL( ln_el_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
      -- �d�C������Ŋz���̔��萔���|�̔��萔���Ŕ���
      ln_el_amount_tax := ln_el_amount - ln_el_amount_tax;
    END IF;
    -------------------------------------------------
    -- 3.�߂�l�ݒ�
    -------------------------------------------------
    on_el_amount     := ln_el_amount;     -- �d�C��
    on_el_amount_tax := ln_el_amount_tax; -- �d�C������Ŋz
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- �̎�����G���[��O�n���h��
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_contract_err;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END cal_bm_contract50_info;
  --
  /**********************************************************************************
   * Procedure Name   : cal_bm_contract40_info
   * Description      : ��z�����̌v�Z(A-13,A-31)
   ***********************************************************************************/
  PROCEDURE cal_bm_contract40_info(
     ov_errbuf        OUT VARCHAR2                                -- �G���[���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2                                -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2                                -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE    -- �ڋq�R�[�h
    ,id_close_date    IN  xxcok_cond_bm_support.closing_date%TYPE -- ���ߓ�
    ,iv_bm_type       IN  VARCHAR2                                -- �x���敪
    ,iv_calculat_type IN  xxcok_mst_bm_contract.calc_type%TYPE    -- �v�Z����
    ,in_tax_rate      IN  xxcos_sales_exp_headers.tax_rate%TYPE   -- ����ŗ�
    ,on_bm_amt        OUT xxcok_mst_bm_contract.bm1_amt%TYPE      -- ���ߊz
    ,on_bm_amount     OUT xxcos_sales_exp_lines.sale_amount%TYPE  -- �̔��萔��
    ,on_bm_amount_tax OUT xxcos_sales_exp_lines.tax_amount%TYPE   -- �̔��萔������Ŋz
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'cal_bm_contract40_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- API���^�[���E���b�Z�[�W�p
    -- �v�Z���ʑޔ�
    ln_bm_amt        xxcok_mst_bm_contract.bm1_amt%TYPE     := NULL; -- ���ߊz
    ln_bm_amount     xxcos_sales_exp_lines.sale_amount%TYPE := NULL; -- �̔��萔��
    ln_bm_amount_tax xxcos_sales_exp_lines.tax_amount%TYPE  := NULL; -- �̔��萔������Ŋz
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �̎�������J�[�\����`
    CURSOR contract_mst_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE    -- �ڋq�R�[�h
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE -- ���ߓ�
      ,iv_calculat_type IN xxcok_mst_bm_contract.calc_type%TYPE    -- �v�Z����
    )
    IS
      SELECT xmb.calc_type AS calc_type -- �v�Z����
            ,xmb.bm1_amt   AS bm1_amt   -- BM1���z
            ,xmb.bm2_amt   AS bm2_amt   -- BM2���z
            ,xmb.bm3_amt   AS bm3_amt   -- BM3���z
      FROM   xxcok_mst_bm_contract xmb
      WHERE  xmb.cust_code        = iv_customer_code
      AND    xmb.calc_target_flag = cv_yes -- Y�F�v�Z�Ώ�
      AND    xmb.calc_type        = iv_calculat_type
      AND    id_close_date BETWEEN NVL( xmb.start_date_active,id_close_date )
                           AND     NVL( xmb.end_date_active,id_close_date );
    -- �̎������񃌃R�[�h��`
    contract_mst_rec contract_mst_cur%ROWTYPE;
    --===============================
    -- ���[�J����O
    --===============================
    contract_err_expt EXCEPTION; -- �̎�����G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.��z��������
    -------------------------------------------------
    OPEN contract_mst_cur(
       iv_customer_code -- �ڋq�R�[�h
      ,id_close_date    -- ���ߓ��F������ߓ�
      ,iv_calculat_type -- �v�Z����
    );
    FETCH contract_mst_cur INTO contract_mst_rec;
    -- �������݃`�F�b�N
    IF ( contract_mst_cur%NOTFOUND ) THEN
      -- �J�[�\���N���[�Y
      CLOSE contract_mst_cur;
      -- �̎�����G���[
      RAISE contract_err_expt;
    END IF;
    -- �J�[�\���N���[�Y
    CLOSE contract_mst_cur;
    -------------------------------------------------
    -- 2.��z�����v�Z
    -------------------------------------------------
    -- �_��Ҏd���攻��
    IF ( iv_bm_type = cv_bm1_type ) THEN
      -- ���ߊz�ޔ�
      ln_bm_amt := NVL( contract_mst_rec.bm1_amt,cn_zero );
      -- �̔��萔����BM1���z
      ln_bm_amount := NVL( contract_mst_rec.bm1_amt,cn_zero );
      -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
      ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
      -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
      ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
    -- �Љ��BM�x���d����P����
    ELSIF ( iv_bm_type = cv_bm2_type ) THEN
      -- ���ߊz�ޔ�
      ln_bm_amt := NVL( contract_mst_rec.bm2_amt,cn_zero );
      -- �̔��萔����BM2���z
      ln_bm_amount := NVL( contract_mst_rec.bm2_amt,cn_zero );
      -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
      ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
      -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
      ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
    -- �Љ��BM�x���d����R����
    ELSIF ( iv_bm_type = cv_bm3_type ) THEN
      -- ���ߊz�ޔ�
      ln_bm_amt := NVL( contract_mst_rec.bm3_amt,cn_zero );
      -- �̔��萔����BM3���z
      ln_bm_amount := NVL( contract_mst_rec.bm3_amt,cn_zero );
      -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
      ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
      -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
      ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
    END IF;
    -------------------------------------------------
    -- 3.�߂�l�ݒ�
    -------------------------------------------------
    on_bm_amt        := ln_bm_amt;        -- ���ߊz
    on_bm_amount     := ln_bm_amount;     -- �̔��萔��
    on_bm_amount_tax := ln_bm_amount_tax; -- �̔��萔������Ŋz
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- �̎�����G���[��O�n���h��
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_contract_err;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END cal_bm_contract40_info;
  --
  /**********************************************************************************
   * Procedure Name   : cal_bm_contract30_info
   * Description      : �ꗥ�����̌v�Z(A-12,A-30)
   ***********************************************************************************/
  PROCEDURE cal_bm_contract30_info(
     ov_errbuf        OUT VARCHAR2                                -- �G���[���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2                                -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2                                -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE    -- �ڋq�R�[�h
    ,id_close_date    IN  xxcok_cond_bm_support.closing_date%TYPE -- ���ߓ�
    ,iv_bm_type       IN  VARCHAR2                                -- �x���敪
    ,iv_calculat_type IN  xxcok_mst_bm_contract.calc_type%TYPE    -- �v�Z����
    ,in_sales_amount  IN  xxcos_sales_exp_lines.sale_amount%TYPE  -- ������z
    ,in_tax_rate      IN  xxcos_sales_exp_headers.tax_rate%TYPE   -- ����ŗ�
    ,in_dlv_quantity  IN  xxcos_sales_exp_lines.dlv_qty%TYPE      -- �[�i����
    ,on_bm_pct        OUT xxcok_mst_bm_contract.bm1_pct%TYPE      -- ���ߗ�
    ,on_bm_amt        OUT xxcok_mst_bm_contract.bm1_amt%TYPE      -- ���ߊz
    ,on_bm_amount     OUT xxcos_sales_exp_lines.sale_amount%TYPE  -- �̔��萔��
    ,on_bm_amount_tax OUT xxcos_sales_exp_lines.tax_amount%TYPE   -- �̔��萔������Ŋz
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'cal_bm_contract30_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- API���^�[���E���b�Z�[�W�p
    -- �v�Z���ʑޔ�
    ln_bm_pct        xxcok_mst_bm_contract.bm1_pct%TYPE       := NULL; -- ���ߗ�
    ln_bm_amt        xxcok_mst_bm_contract.bm1_amt%TYPE       := NULL; -- ���ߊz
    ln_bm_amount     xxcos_sales_exp_lines.sale_amount%TYPE := NULL; -- �̔��萔��
    ln_bm_amount_tax xxcos_sales_exp_lines.tax_amount%TYPE  := NULL; -- �̔��萔������Ŋz
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �̎�������J�[�\����`
    CURSOR contract_mst_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE    -- �ڋq�R�[�h
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE -- ���ߓ�
      ,iv_calculat_type IN xxcok_mst_bm_contract.calc_type%TYPE    -- �v�Z����
    )
    IS
      SELECT xmb.calc_type AS calc_type -- �v�Z����
            ,xmb.bm1_pct   AS bm1_pct   -- BM1��(%)
            ,xmb.bm1_amt   AS bm1_amt   -- BM1���z
            ,xmb.bm2_pct   AS bm2_pct   -- BM2��(%)
            ,xmb.bm2_amt   AS bm2_amt   -- BM2���z
            ,xmb.bm3_pct   AS bm3_pct   -- BM3��(%)
            ,xmb.bm3_amt   AS bm3_amt   -- BM3���z
      FROM   xxcok_mst_bm_contract xmb
      WHERE  xmb.cust_code        = iv_customer_code
      AND    xmb.calc_target_flag = cv_yes -- Y�F�v�Z�Ώ�
      AND    xmb.calc_type        = iv_calculat_type
      AND    id_close_date BETWEEN NVL( xmb.start_date_active,id_close_date )
                           AND     NVL( xmb.end_date_active,id_close_date );
    -- �̎������񃌃R�[�h��`
    contract_mst_rec contract_mst_cur%ROWTYPE;
    --===============================
    -- ���[�J����O
    --===============================
    contract_err_expt EXCEPTION; -- �̎�����G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.�ꗥ��������
    -------------------------------------------------
    OPEN contract_mst_cur(
       iv_customer_code -- �ڋq�R�[�h
      ,id_close_date    -- ���ߓ��F������ߓ�
      ,iv_calculat_type -- �v�Z����
    );
    FETCH contract_mst_cur INTO contract_mst_rec;
    -- �������݃`�F�b�N
    IF ( contract_mst_cur%NOTFOUND ) THEN
      -- �J�[�\���N���[�Y
      CLOSE contract_mst_cur;
      -- �̎�����G���[
      RAISE contract_err_expt;
    END IF;
    -- �J�[�\���N���[�Y
    CLOSE contract_mst_cur;
    -------------------------------------------------
    -- 2.�ꗥ�����v�Z
    -------------------------------------------------
    -- �_��Ҏd���攻��
    IF ( iv_bm_type = cv_bm1_type ) THEN
      -- �v�Z���@�i���E���z�j����
      IF ( contract_mst_rec.bm1_pct IS NOT NULL ) THEN
        -- ���ߗ��ޔ�
        ln_bm_pct := NVL( contract_mst_rec.bm1_pct,cn_zero );
        -- �̔��萔�����̔����я��.������z�~BM1���i%�j
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm1_pct,cn_zero ) / 100 ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- ���ߊz�ޔ�
        ln_bm_amt := NVL( contract_mst_rec.bm1_amt,cn_zero );
        -- �̔��萔�����̔����я��.�[�i���ʁ~BM1���z
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm1_amt,cn_zero ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    -- �Љ��BM�x���d����P����
    ELSIF ( iv_bm_type = cv_bm2_type ) THEN
      -- �v�Z���@�i���E���z�j����
      IF ( contract_mst_rec.bm2_pct IS NOT NULL ) THEN
        -- ���ߗ��ޔ�
        ln_bm_pct := NVL( contract_mst_rec.bm2_pct,cn_zero );
        -- �̔��萔�����̔����я��.������z�~BM2���i%�j
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm2_pct,cn_zero ) / 100 ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- ���ߊz�ޔ�
        ln_bm_amt := NVL( contract_mst_rec.bm2_amt,cn_zero );
        -- �̔��萔�����̔����я��.�[�i���ʁ~BM2���z
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm2_amt,cn_zero ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    -- �Љ��BM�x���d����R����
    ELSIF ( iv_bm_type = cv_bm3_type ) THEN
      -- �v�Z���@�i���E���z�j����
      IF ( contract_mst_rec.bm3_pct IS NOT NULL ) THEN
        -- ���ߗ��ޔ�
        ln_bm_pct := NVL( contract_mst_rec.bm3_pct,cn_zero );
        -- �̔��萔�����̔����я��.������z�~BM3���i%�j
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm3_pct,cn_zero ) / 100 ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- ���ߊz�ޔ�
        ln_bm_amt := NVL( contract_mst_rec.bm3_amt,cn_zero );
        -- �̔��萔�����̔����я��.�[�i���ʁ~BM3���z
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm3_amt,cn_zero ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    END IF;
    -------------------------------------------------
    -- 3.�߂�l�ݒ�
    -------------------------------------------------
    on_bm_pct        := ln_bm_pct;        -- ���ߗ�
    on_bm_amt        := ln_bm_amt;        -- ���ߊz
    on_bm_amount     := ln_bm_amount;     -- �̔��萔��
    on_bm_amount_tax := ln_bm_amount_tax; -- �̔��萔������Ŋz
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- �̎�����G���[��O�n���h��
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_contract_err;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END cal_bm_contract30_info;
  --
  /**********************************************************************************
   * Procedure Name   : cal_bm_contract20_info
   * Description      : �e��敪�ʏ����̌v�Z(A-11,A-29)
   ***********************************************************************************/
  PROCEDURE cal_bm_contract20_info(
     ov_errbuf         OUT VARCHAR2                                -- �G���[���b�Z�[�W
    ,ov_retcode        OUT VARCHAR2                                -- ���^�[���E�R�[�h
    ,ov_errmsg         OUT VARCHAR2                                -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_customer_code  IN  hz_cust_accounts.account_number%TYPE    -- �ڋq�R�[�h
    ,id_close_date     IN  xxcok_cond_bm_support.closing_date%TYPE -- ���ߓ�
    ,iv_bm_type        IN  VARCHAR2                                -- �x���敪
    ,iv_calculat_type  IN  xxcok_mst_bm_contract.calc_type%TYPE    -- �v�Z����
    ,iv_container_type IN  fnd_lookup_values.attribute1%TYPE       -- �e��敪
    ,in_sales_amount   IN  xxcos_sales_exp_lines.sale_amount%TYPE  -- ������z
    ,in_tax_rate       IN  xxcos_sales_exp_headers.tax_rate%TYPE   -- ����ŗ�
    ,in_dlv_quantity   IN  xxcos_sales_exp_lines.dlv_qty%TYPE      -- �[�i����
    ,on_bm_pct         OUT xxcok_mst_bm_contract.bm1_pct%TYPE      -- ���ߗ�
    ,on_bm_amt         OUT xxcok_mst_bm_contract.bm1_amt%TYPE      -- ���ߊz
    ,on_bm_amount      OUT xxcos_sales_exp_lines.sale_amount%TYPE  -- �̔��萔��
    ,on_bm_amount_tax  OUT xxcos_sales_exp_lines.tax_amount%TYPE   -- �̔��萔������Ŋz
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'cal_bm_contract20_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- API���^�[���E���b�Z�[�W�p
    -- �v�Z���ʑޔ�
    ln_bm_pct        xxcok_mst_bm_contract.bm1_pct%TYPE     := NULL; -- ���ߗ�
    ln_bm_amt        xxcok_mst_bm_contract.bm1_amt%TYPE     := NULL; -- ���ߊz
    ln_bm_amount     xxcos_sales_exp_lines.sale_amount%TYPE := NULL; -- �̔��萔��
    ln_bm_amount_tax xxcos_sales_exp_lines.tax_amount%TYPE  := NULL; -- �̔��萔������Ŋz
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �̎�������J�[�\����`
    CURSOR contract_mst_cur(
       iv_customer_code  IN hz_cust_accounts.account_number%TYPE           -- �ڋq�R�[�h
      ,id_close_date     IN xxcok_cond_bm_support.closing_date%TYPE        -- ���ߓ�
      ,iv_calculat_type  IN xxcok_mst_bm_contract.calc_type%TYPE           -- �v�Z����
      ,iv_container_type IN xxcok_mst_bm_contract.container_type_code%TYPE -- �e��敪
    )
    IS
      SELECT xmb.calc_type           AS calc_type           -- �v�Z����
            ,xmb.container_type_code AS container_type_code -- �e��敪
            ,xmb.bm1_pct             AS bm1_pct             -- BM1��(%)
            ,xmb.bm1_amt             AS bm1_amt             -- BM1���z
            ,xmb.bm2_pct             AS bm2_pct             -- BM2��(%)
            ,xmb.bm2_amt             AS bm2_amt             -- BM2���z
            ,xmb.bm3_pct             AS bm3_pct             -- BM3��(%)
            ,xmb.bm3_amt             AS bm3_amt             -- BM3���z
      FROM   xxcok_mst_bm_contract xmb
      WHERE  xmb.cust_code           = iv_customer_code
      AND    xmb.calc_target_flag    = cv_yes -- Y�F�v�Z�Ώ�
      AND    xmb.calc_type           = iv_calculat_type
      AND    xmb.container_type_code = iv_container_type
      AND    id_close_date BETWEEN NVL( xmb.start_date_active,id_close_date )
                           AND     NVL( xmb.end_date_active,id_close_date );
    -- �̎������񃌃R�[�h��`
    contract_mst_rec contract_mst_cur%ROWTYPE;
    --===============================
    -- ���[�J����O
    --===============================
    contract_err_expt EXCEPTION; -- �̎�����G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.�e��敪�ʏ�������
    -------------------------------------------------
    OPEN contract_mst_cur(
       iv_customer_code  -- �ڋq�R�[�h
      ,id_close_date     -- ���ߓ��F������ߓ�
      ,iv_calculat_type  -- �v�Z����
      ,iv_container_type -- �e��敪
    );
    FETCH contract_mst_cur INTO contract_mst_rec;
    -- �������݃`�F�b�N
    IF ( contract_mst_cur%NOTFOUND ) THEN
      -- �J�[�\���N���[�Y
      CLOSE contract_mst_cur;
      -- �̎�����G���[
      RAISE contract_err_expt;
    END IF;
    -- �J�[�\���N���[�Y
    CLOSE contract_mst_cur;
    -------------------------------------------------
    -- 2.�e��敪�ʏ����v�Z
    -------------------------------------------------
    -- �_��Ҏd���攻��
    IF ( iv_bm_type = cv_bm1_type ) THEN
      -- �v�Z���@�i���E���z�j����
      IF ( contract_mst_rec.bm1_pct IS NOT NULL ) THEN
        -- ���ߗ��ޔ�
        ln_bm_pct := NVL( contract_mst_rec.bm1_pct,cn_zero );
        -- �̔��萔�����̔����я��.������z�~BM1���i%�j
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm1_pct,cn_zero ) / 100 ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- ���ߊz�ޔ�
        ln_bm_amt := NVL( contract_mst_rec.bm1_amt,cn_zero );
        -- �̔��萔�����̔����я��.�[�i���ʁ~BM1���z
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm1_amt,cn_zero ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    -- �Љ��BM�x���d����P����
    ELSIF ( iv_bm_type = cv_bm2_type ) THEN
      -- �v�Z���@�i���E���z�j����
      IF ( contract_mst_rec.bm2_pct IS NOT NULL ) THEN
        -- ���ߗ��ޔ�
        ln_bm_pct := NVL( contract_mst_rec.bm2_pct,cn_zero );
        -- �̔��萔�����̔����я��.������z�~BM2���i%�j
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm2_pct,cn_zero ) / 100 ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- ���ߊz�ޔ�
        ln_bm_amt := NVL( contract_mst_rec.bm2_amt,cn_zero );
        -- �̔��萔�����̔����я��.�[�i���ʁ~BM2���z
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm2_amt,cn_zero ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    -- �Љ��BM�x���d����R����
    ELSIF ( iv_bm_type = cv_bm3_type ) THEN
      -- �v�Z���@�i���E���z�j����
      IF ( contract_mst_rec.bm3_pct IS NOT NULL ) THEN
        -- ���ߗ��ޔ�
        ln_bm_pct := NVL( contract_mst_rec.bm3_pct,cn_zero );
        -- �̔��萔�����̔����я��.������z�~BM3���i%�j
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm3_pct,cn_zero ) / 100 ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- ���ߊz�ޔ�
        ln_bm_amt := NVL( contract_mst_rec.bm3_amt,cn_zero );
        -- �̔��萔�����̔����я��.�[�i���ʁ~BM3���z
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm3_amt,cn_zero ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    END IF;
    -------------------------------------------------
    -- 3.�߂�l�ݒ�
    -------------------------------------------------
    on_bm_pct        := ln_bm_pct;        -- ���ߗ�
    on_bm_amt        := ln_bm_amt;        -- ���ߊz
    on_bm_amount     := ln_bm_amount;     -- �̔��萔��
    on_bm_amount_tax := ln_bm_amount_tax; -- �̔��萔������Ŋz
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- �̎�����G���[��O�n���h��
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_contract_err;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END cal_bm_contract20_info;
  --
  /**********************************************************************************
   * Procedure Name   : cal_bm_contract10_info
   * Description      : �����ʏ����̌v�Z(A-10,A-28)
   ***********************************************************************************/
  PROCEDURE cal_bm_contract10_info(
     ov_errbuf        OUT VARCHAR2                                  -- �G���[���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2                                  -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2                                  -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE      -- �ڋq�R�[�h
    ,id_close_date    IN  xxcok_cond_bm_support.closing_date%TYPE   -- ���ߓ�
    ,iv_bm_type       IN  VARCHAR2                                  -- �x���敪
    ,iv_calculat_type IN  xxcok_mst_bm_contract.calc_type%TYPE      -- �v�Z����
    ,in_retail_amount IN  xxcos_sales_exp_lines.dlv_unit_price%TYPE -- ����
    ,in_sales_amount  IN  xxcos_sales_exp_lines.sale_amount%TYPE    -- ������z
    ,in_tax_rate      IN  xxcos_sales_exp_headers.tax_rate%TYPE     -- ����ŗ�
    ,in_dlv_quantity  IN  xxcos_sales_exp_lines.dlv_qty%TYPE        -- �[�i����
    ,on_bm_pct        OUT xxcok_mst_bm_contract.bm1_pct%TYPE        -- ���ߗ�
    ,on_bm_amt        OUT xxcok_mst_bm_contract.bm1_amt%TYPE        -- ���ߊz
    ,on_bm_amount     OUT xxcos_sales_exp_lines.sale_amount%TYPE    -- �̔��萔��
    ,on_bm_amount_tax OUT xxcos_sales_exp_lines.tax_amount%TYPE     -- �̔��萔������Ŋz
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'cal_bm_contract10_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- API���^�[���E���b�Z�[�W�p
    -- �v�Z���ʑޔ�
    ln_bm_pct        xxcok_mst_bm_contract.bm1_pct%TYPE     := NULL; -- ���ߗ�
    ln_bm_amt        xxcok_mst_bm_contract.bm1_amt%TYPE     := NULL; -- ���ߊz
    ln_bm_amount     xxcos_sales_exp_lines.sale_amount%TYPE := NULL; -- �̔��萔��
    ln_bm_amount_tax xxcos_sales_exp_lines.tax_amount%TYPE  := NULL; -- �̔��萔������Ŋz
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �̎�������J�[�\����`
    CURSOR contract_mst_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE      -- �ڋq�R�[�h
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE   -- ���ߓ�
      ,iv_calculat_type IN xxcok_mst_bm_contract.calc_type%TYPE      -- �v�Z����
      ,in_retail        IN xxcos_sales_exp_lines.dlv_unit_price%TYPE -- ����
    )
    IS
      SELECT xmb.calc_type     AS calc_type     -- �v�Z����
            ,xmb.selling_price AS selling_price -- ����
            ,xmb.bm1_pct       AS bm1_pct       -- BM1��(%)
            ,xmb.bm1_amt       AS bm1_amt       -- BM1���z
            ,xmb.bm2_pct       AS bm2_pct       -- BM2��(%)
            ,xmb.bm2_amt       AS bm2_amt       -- BM2���z
            ,xmb.bm3_pct       AS bm3_pct       -- BM3��(%)
            ,xmb.bm3_amt       AS bm3_amt       -- BM3���z
      FROM   xxcok_mst_bm_contract xmb
      WHERE  xmb.cust_code        = iv_customer_code
      AND    xmb.calc_target_flag = cv_yes -- Y�F�v�Z�Ώ�
      AND    xmb.calc_type        = iv_calculat_type
      AND    xmb.selling_price    = in_retail
      AND    id_close_date BETWEEN NVL( xmb.start_date_active,id_close_date )
                           AND     NVL( xmb.end_date_active,id_close_date );
    -- �̎������񃌃R�[�h��`
    contract_mst_rec contract_mst_cur%ROWTYPE;
    --===============================
    -- ���[�J����O
    --===============================
    contract_err_expt EXCEPTION; -- �̎�����G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.�����ʏ�������
    -------------------------------------------------
    OPEN contract_mst_cur(
       iv_customer_code -- �ڋq�R�[�h
      ,id_close_date    -- ���ߓ��F������ߓ�
      ,iv_calculat_type -- �v�Z����
      ,in_retail_amount -- �����F�[�i�P��
    );
    FETCH contract_mst_cur INTO contract_mst_rec;
    -- �������݃`�F�b�N
    IF ( contract_mst_cur%NOTFOUND ) THEN
      -- �J�[�\���N���[�Y
      CLOSE contract_mst_cur;
      -- �̎�����G���[
      RAISE contract_err_expt;
    END IF;
    -- �J�[�\���N���[�Y
    CLOSE contract_mst_cur;
    --
    -------------------------------------------------
    -- 2.�����ʏ����v�Z
    -------------------------------------------------
    -- �_��Ҏd���攻��
    IF ( iv_bm_type = cv_bm1_type ) THEN
      -- �v�Z���@�i���E���z�j����
      IF ( contract_mst_rec.bm1_pct IS NOT NULL ) THEN
        -- ���ߗ��ޔ�
        ln_bm_pct := NVL( contract_mst_rec.bm1_pct,cn_zero );
        -- �̔��萔�����̔����я��.������z�~BM1���i%�j
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm1_pct,cn_zero ) / 100 ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- ���ߊz�ޔ�
        ln_bm_amt := NVL( contract_mst_rec.bm1_amt,cn_zero );
        -- �̔��萔�����̔����я��.�[�i���ʁ~BM1���z
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm1_amt,cn_zero ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    -- �Љ��BM�x���d����P����
    ELSIF ( iv_bm_type = cv_bm2_type ) THEN
      -- �v�Z���@�i���E���z�j����
      IF ( contract_mst_rec.bm2_pct IS NOT NULL ) THEN
        -- ���ߗ��ޔ�
        ln_bm_pct := NVL( contract_mst_rec.bm2_pct,cn_zero );
        -- �̔��萔�����̔����я��.������z�~BM2���i%�j
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm2_pct,cn_zero ) / 100 ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- ���ߊz�ޔ�
        ln_bm_amt := NVL( contract_mst_rec.bm2_amt,cn_zero );
        -- �̔��萔�����̔����я��.�[�i���ʁ~BM2���z
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm2_amt,cn_zero ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    -- �Љ��BM�x���d����R����
    ELSIF ( iv_bm_type = cv_bm3_type ) THEN
      -- �v�Z���@�i���E���z�j����
      IF ( contract_mst_rec.bm3_pct IS NOT NULL ) THEN
        -- ���ߗ��ޔ�
        ln_bm_pct := NVL( contract_mst_rec.bm3_pct,cn_zero );
        -- �̔��萔�����̔����я��.������z�~BM3���i%�j
        ln_bm_amount := ROUND( NVL( in_sales_amount,cn_zero ) * ( NVL( contract_mst_rec.bm3_pct,cn_zero ) / 100 ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      ELSE
        -- ���ߊz�ޔ�
        ln_bm_amt := NVL( contract_mst_rec.bm3_amt,cn_zero );
        -- �̔��萔�����̔����я��.�[�i���ʁ~BM3���z
        ln_bm_amount := ROUND( NVL( in_dlv_quantity,cn_zero ) * NVL( contract_mst_rec.bm3_amt,cn_zero ) );
        -- �̔��萔���Ŕ������̔��萔����(1�{(100/�̔����я��.����ŗ�))
        ln_bm_amount_tax := ROUND( NVL( ln_bm_amount,cn_zero ) / ( cn_one + ( NVL( in_tax_rate,cn_zero ) / 100 ) ) );
        -- �̔��萔������Ŋz���̔��萔���|�̔��萔���Ŕ���
        ln_bm_amount_tax := ln_bm_amount - ln_bm_amount_tax;
      END IF;
    END IF;
    -------------------------------------------------
    -- 3.�߂�l�ݒ�
    -------------------------------------------------
    on_bm_pct        := ln_bm_pct;        -- ���ߗ�
    on_bm_amt        := ln_bm_amt;        -- ���ߊz
    on_bm_amount     := ln_bm_amount;     -- �̔��萔��
    on_bm_amount_tax := ln_bm_amount_tax; -- �̔��萔������Ŋz
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- �̎�����G���[��O�n���h��
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_contract_err;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END cal_bm_contract10_info;
  --
  /**********************************************************************************
   * Procedure Name   : get_active_vendor_info
   * Description      : �x����f�[�^�̎擾(A-9,A-27)
   ***********************************************************************************/
  PROCEDURE get_active_vendor_info(
     ov_errbuf        OUT VARCHAR2                                          -- �G���[���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2                                          -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2                                          -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_vendor_type   IN  VARCHAR2                                          -- �x���_�[�敪
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE              -- �ڋq�R�[�h
    ,id_pay_work_date IN  xxcok_cond_bm_support.expect_payment_date%TYPE    -- �x���\���
    ,iv_vendor_code1  IN  xxcmm_cust_accounts.contractor_supplier_code%TYPE -- �_��Ҏd����R�[�h
    ,iv_vendor_code2  IN  xxcmm_cust_accounts.bm_pay_supplier_code1%TYPE    -- �Љ��BM�x���d����R�[�h�P
    ,iv_vendor_code3  IN  xxcmm_cust_accounts.bm_pay_supplier_code2%TYPE    -- �Љ��BM�x���d����R�[�h�Q
    ,in_elc_cnt       IN  NUMBER                                            -- �d�C���v�Z�����L��
    ,ot_bm_support    OUT g_bm_support_ttype                                -- �x������
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_active_vendor_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000);   -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000);   -- ���b�Z�[�W
    lb_retcode  BOOLEAN;          -- API���^�[���E���b�Z�[�W�p
    ln_cnt      PLS_INTEGER := 0; -- �J�E���^
    ln_vend_cnt PLS_INTEGER := 0; -- �d����J�E���^
    ln_pay_cnt  PLS_INTEGER := 0; -- �x����J�E���^
    -- �x����e�[�u����`
    lt_vendor_chk g_vendor_ttype;     -- �x����`�F�b�N
    lt_bm_support g_bm_support_ttype; -- �x������
    -- �d������ޔ�
    lv_vendor_code1 po_vendors.segment1%TYPE := NULL; -- �d����R�[�h�P
    lv_vendor_code2 po_vendors.segment1%TYPE := NULL; -- �d����R�[�h�Q
    lv_vendor_code3 po_vendors.segment1%TYPE := NULL; -- �d����R�[�h�R
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �x������J�[�\����`
    CURSOR vendor_info_cur(
       iv_vendor_code   IN po_vendors.segment1%TYPE                       -- �d����R�[�h
      ,id_pay_work_date IN xxcok_cond_bm_support.expect_payment_date%TYPE -- ���ߓ�
    )
    IS
      SELECT pvd.segment1         AS vendor_code      -- �d����R�[�h
            ,pvs.vendor_site_code AS vendor_site_code -- �d����T�C�g�R�[�h
      FROM   po_vendors          pvd -- �d����}�X�^
            ,po_vendor_sites_all pvs -- �d����T�C�g�}�X�^
      WHERE  pvd.segment1     = iv_vendor_code
      AND    pvd.enabled_flag = cv_yes -- Y�F�L��
      AND    pvd.vendor_id    = pvs.vendor_id
      AND    pvs.attribute4   IN ( cv_bm_pay1_type
                                  ,cv_bm_pay2_type
                                  ,cv_bm_pay3_type
                                  ,cv_bm_pay4_type )
      AND    NVL( pvs.inactive_date,id_pay_work_date ) >= id_pay_work_date
      AND    id_pay_work_date BETWEEN NVL( pvd.start_date_active,id_pay_work_date )
                              AND     NVL( pvd.end_date_active,id_pay_work_date );
    --===============================
    -- ���[�J����O
    --===============================
    contract_err_expt EXCEPTION; -- �̎�����G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -- �����ޔ�
    lv_vendor_code1 := iv_vendor_code1; -- �d����P�ޔ�
    lv_vendor_code2 := iv_vendor_code2; -- �d����Q�ޔ�
    lv_vendor_code3 := iv_vendor_code3; -- �d����R�ޔ�
    -- �e�[�u����`������
    lt_vendor_chk.DELETE;
    lt_bm_support.DELETE;
    -- BM1�ޔ�
    lt_vendor_chk( cn_bm1_set ).bm_type := cv_bm1_type;
    -- �_��Ҏd����R�[�h�ޔ�
    lt_vendor_chk( cn_bm1_set ).vendor_code := lv_vendor_code1;
    -- BM2�ޔ�
    lt_vendor_chk( cn_bm2_set ).bm_type := cv_bm2_type;
    -- �Љ��BM�x���d����R�[�h�P�ޔ�
    lt_vendor_chk( cn_bm2_set ).vendor_code := lv_vendor_code2;
    -- BM3�ޔ�
    lt_vendor_chk( cn_bm3_set ).bm_type := cv_bm3_type;
    -- �Љ��BM�x���d����R�[�h�Q�ޔ�
    lt_vendor_chk( cn_bm3_set ).vendor_code := lv_vendor_code3;
    -------------------------------------------------
    -- 1.�t���x���_�[�x����擾
    -------------------------------------------------
    IF ( iv_vendor_type = cv_vendor_type1 ) THEN
      -------------------------------------------------
      -- �x������`�F�b�N���[�v
      -------------------------------------------------
      << vendor_chk_all_loop >>
      FOR ln_vend_cnt IN lt_vendor_chk.FIRST..lt_vendor_chk.LAST LOOP
        -- �x������擾
        << payment_chk_all_loop >>
        FOR vendor_info_rec IN vendor_info_cur(
           lt_vendor_chk( ln_vend_cnt ).vendor_code -- �d����R�[�h�FBM1�`BM3
          ,id_pay_work_date                         -- �x���\���
          )
        LOOP
          -- �x���敪�FBM1�`BM3
          lt_bm_support( ln_pay_cnt ).bm_type := lt_vendor_chk( ln_vend_cnt ).bm_type;
          -- �d����R�[�h
          lt_bm_support( ln_pay_cnt ).supplier_code := vendor_info_rec.vendor_code;
          -- �d����T�C�g�R�[�h
          lt_bm_support( ln_pay_cnt ).supplier_site_code := vendor_info_rec.vendor_site_code;
          -- BM1�̎d�������ޔ�����
          IF ( lt_bm_support( ln_pay_cnt ).bm_type = cv_bm1_type ) THEN
            -- BM1�d����R�[�h
            gv_bm1_vendor := lt_bm_support( ln_pay_cnt ).supplier_code;
            -- BM1�d����T�C�g�R�[�h
            gv_bm1_vendor_s := lt_bm_support( ln_pay_cnt ).supplier_site_code;
          END IF;
          -- �C���N�������g
          ln_pay_cnt := ln_pay_cnt + cn_one;
        END LOOP payment_chk_all_loop;
      END LOOP vendor_chk_all_loop;
    -------------------------------------------------
    -- 2.�t���x���_�[�i�����j�x����擾
    -------------------------------------------------
    ELSIF ( iv_vendor_type = cv_vendor_type2 ) THEN
      -------------------------------------------------
      -- �x���_�[�`�F�b�N
      -------------------------------------------------
      << vendor_chk_point_loop >>
      FOR ln_vend_cnt IN lt_vendor_chk.FIRST..lt_vendor_chk.LAST LOOP
        -- �_��Ҏd����R�[�h�`�F�b�N
        IF ( lv_vendor_code1 IS NOT NULL ) THEN
          -- BM1�ޔ�
          lt_bm_support( ln_pay_cnt ).bm_type := cv_bm1_type;
          -- �_��Ҏd����R�[�h�ޔ�
          lt_bm_support( ln_pay_cnt ).supplier_code := lv_vendor_code1;
          -- �d����T�C�g�R�[�h
          lt_bm_support( ln_pay_cnt ).supplier_site_code := lv_vendor_code1;
          -- BM1�d����R�[�h
          gv_bm1_vendor := lv_vendor_code1;
          -- BM1�d����T�C�g�R�[�h
          gv_bm1_vendor_s := lv_vendor_code1;
          -- �C���N�������g
          ln_pay_cnt := ln_pay_cnt + cn_one;
          -- �d����N���A
          lv_vendor_code1 := NULL;
        -- �Љ��BM�x���d����R�[�h�P�`�F�b�N
        ELSIF ( lv_vendor_code2 IS NOT NULL ) THEN
          -- BM2�ޔ�
          lt_bm_support( ln_pay_cnt ).bm_type := cv_bm2_type;
          -- �Љ��BM�x���d����R�[�h�P�ޔ�
          lt_bm_support( ln_pay_cnt ).supplier_code := lv_vendor_code2;
          -- �d����T�C�g�R�[�h
          lt_bm_support( ln_pay_cnt ).supplier_site_code := lv_vendor_code2;
          -- �C���N�������g
          ln_pay_cnt := ln_pay_cnt + cn_one;
          -- �d����N���A
          lv_vendor_code2 := NULL;
        -- �Љ��BM�x���d����R�[�h�Q�`�F�b�N
        ELSIF ( lv_vendor_code3 IS NOT NULL ) THEN
          -- BM2�ޔ�
          lt_bm_support( ln_pay_cnt ).bm_type := cv_bm3_type;
          -- �Љ��BM�x���d����R�[�h�Q�ޔ�
          lt_bm_support( ln_pay_cnt ).supplier_code := lv_vendor_code3;
          -- �d����T�C�g�R�[�h
          lt_bm_support( ln_pay_cnt ).supplier_site_code := lv_vendor_code3;
          -- �C���N�������g
          ln_pay_cnt := ln_pay_cnt + cn_one;
          -- �d����N���A
          lv_vendor_code3 := NULL;
        END IF;
      END LOOP vendor_chk_point_loop;
    END IF;
    -------------------------------------------------
    -- 3.�d�C�������ݒ�
    -------------------------------------------------
    -- �d�C���v�Z�L��̏ꍇ�͔z����g��
    IF ( ln_pay_cnt <> cn_zero ) AND
       ( in_elc_cnt <> cn_zero ) THEN
      -- �x���敪�FEN1
      lt_bm_support( lt_bm_support.LAST + 1 ).bm_type := cv_en1_type;
      -- �d����_�~�[�R�[�h
      lt_bm_support( lt_bm_support.LAST + 1 ).supplier_code := gv_bm1_vendor;
      -- �d����T�C�g�_�~�[�R�[�h
      lt_bm_support( lt_bm_support.LAST + 1 ).supplier_site_code := gv_bm1_vendor_s;
    END IF;
    -------------------------------------------------
    -- 4.�x����`�F�b�N
    -------------------------------------------------
    IF ( ln_pay_cnt = cn_zero ) OR
       ( gv_bm1_vendor IS NULL ) THEN
      -- �x������擾�G���[
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_10427
                      ,iv_token_name1  => cv_tkn_vend_code
                      ,iv_token_value1 => iv_customer_code
                      ,iv_token_name2  => cv_tkn_pay_date
                      ,iv_token_value2 => id_pay_work_date
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_warn;
    END IF;
    -------------------------------------------------
    -- 5.�߂�l�ݒ�
    -------------------------------------------------
    ot_bm_support := lt_bm_support; -- �x������
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- �̎�����G���[��O�n���h��
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_contract_err;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END get_active_vendor_info;
  --
  /**********************************************************************************
   * Procedure Name   : del_bm_contract_err_info
   * Description      : �̎�����G���[�f�[�^�̍폜(A-6,A-24)
   ***********************************************************************************/
  PROCEDURE del_bm_contract_err_info(
     ov_errbuf        OUT VARCHAR2                             -- �G���[���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2                             -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2                             -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE -- �ڋq�R�[�h
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'del_bm_contract_err_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- API���^�[���E���b�Z�[�W�p
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �̎�����G���[�e�[�u�����b�N
    CURSOR bm_contract_err_del_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE -- �ڋq�R�[�h
    )
    IS
      SELECT xbe.cust_code AS bm_contract_err -- �̎����
      FROM   xxcok_bm_contract_err xbe -- �̎�����G���[�e�[�u��
      WHERE  xbe.cust_code = iv_customer_code
      FOR UPDATE NOWAIT;
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.�̎�����G���[�f�[�^�폜���b�N����
    -------------------------------------------------
    -- ���b�N����
    OPEN bm_contract_err_del_cur(
       iv_customer_code -- �ڋq�R�[�h
    );
    CLOSE bm_contract_err_del_cur;
    -------------------------------------------------
    -- 2.�̎�����G���[�f�[�^�폜����
    -------------------------------------------------
    BEGIN
      DELETE FROM xxcok_bm_contract_err xbe
      WHERE xbe.cust_code = iv_customer_code;
    EXCEPTION
      ----------------------------------------------------------
      -- �̎�����G���[�f�[�^�폜��O
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_10400
                        ,iv_token_name1  => cv_tkn_cust_code
                        ,iv_token_value1 => iv_customer_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- �o�͋敪
                        ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line => cn_zero         -- ���s
                      );
        ov_errmsg  := lv_out_msg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
        ov_retcode := cv_status_error;
    END;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ���b�N��O�n���h��
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00080
                    );    
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END del_bm_contract_err_info;
  --
  /**********************************************************************************
   * Procedure Name   : get_bm_support_add_info
   * Description      : �̎�̋��v�Z�t�����̎擾(A-5,A-23,A-41)
   ***********************************************************************************/
  PROCEDURE get_bm_support_add_info(
     ov_errbuf        OUT VARCHAR2                                       -- �G���[���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2                                       -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2                                       -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_vendor_type   IN  VARCHAR2                                       -- �x���_�[�敪
    ,iv_customer_code IN  hz_cust_accounts.account_number%TYPE           -- �ڋq�R�[�h
    ,id_pay_date      IN  xxcok_cond_bm_support.expect_payment_date%TYPE -- �x����
    ,od_pay_work_date OUT xxcok_cond_bm_support.expect_payment_date%TYPE -- �x���\���
    ,ov_period_year   OUT gl_period_statuses.period_year%TYPE            -- ��v�N�x
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_bm_support_add_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- API���^�[���E���b�Z�[�W�p
    -- �t�����ޔ�
    ld_pay_work_date   xxcok_cond_bm_support.expect_payment_date%TYPE := NULL; -- �c�Ɠ����l�������x����
    lv_appl_short_name fnd_application.application_short_name%TYPE    := NULL; -- �A�v���P�[�V�����Z�k��
    lv_period_year     gl_period_statuses.period_year%TYPE            := NULL; -- ��v�N�x
    lv_period_name     gl_period_statuses.period_name%TYPE            := NULL; -- ��v���Ԗ�
    lv_closing_status  gl_period_statuses.closing_status%TYPE         := NULL; -- ��v�J�����_�X�e�[�^�X
    --===============================
    -- ���[�J����O
    --===============================
    work_date_err_expt EXCEPTION; -- �c�Ɠ��擾�G���[
    calendar_err_expt  EXCEPTION; -- ��v�J�����_���擾�G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.�x���\����擾�i���ʁj
    -------------------------------------------------
    BEGIN
      -- �c�Ɠ��擾
      ld_pay_work_date := xxcok_common_pkg.get_operating_day_f(
         id_proc_date => id_pay_date -- �������F����x����
        ,in_days      => cn_zero     -- �����F�����ʔ̎�̋��v�Z��������(From)
        ,in_proc_type => cn_one      -- �����敪�F�O
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- �c�Ɠ��擾�G���[
        RAISE work_date_err_expt;
    END;
    -------------------------------------------------
    -- 2.��v�N�x�擾�i���ʁj
    -------------------------------------------------
    IF ( iv_vendor_type = cv_vendor_type1 ) THEN
      lv_appl_short_name := cv_ap_type_sqlgl; -- �A�v���P�[�V�����Z�k���FSQLGL
    ELSE
      lv_appl_short_name := cv_ap_type_ar;    -- �A�v���P�[�V�����Z�k���FAR
    END IF;
    -- ��v�J�����_���擾
    xxcok_common_pkg.get_acctg_calendar_p(
       ov_errbuf                 => lv_errbuf          -- �G���[���b�Z�[�W
      ,ov_retcode                => lv_retcode         -- ���^�[���E�R�[�h
      ,ov_errmsg                 => lv_errmsg          -- ���[�U�[�E�G���[���b�Z�[�W
      ,in_set_of_books_id        => gn_pro_books_id    -- ��v����ID
      ,iv_application_short_name => lv_appl_short_name -- �A�v���P�[�V�����Z�k��
      ,id_object_date            => ld_pay_work_date   -- �Ώۓ�
      ,on_period_year            => lv_period_year     -- ��v�N�x
      ,ov_period_name            => lv_period_name     -- ��v���Ԗ�
      ,ov_closing_status         => lv_closing_status  -- �X�e�[�^�X
    );
    -- �X�e�[�^�X�G���[����
    IF ( lv_retcode = cv_status_error ) OR
       ( lv_closing_status <> cv_cal_op_status ) THEN
      RAISE calendar_err_expt;
    END IF;
    -------------------------------------------------
    -- 3.�߂�l�ݒ�
    -------------------------------------------------
    od_pay_work_date := ld_pay_work_date; -- �x���\���
    ov_period_year   := lv_period_year;   -- ��v�N�x
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- �c�Ɠ��擾��O�n���h��
    ----------------------------------------------------------
    WHEN work_date_err_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00027
                    );    
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- ��v�J�����_���擾��O�n���h��
    ----------------------------------------------------------
    WHEN calendar_err_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00011
                      ,iv_token_name1  => cv_tkn_proc_date
                      ,iv_token_value1 => TO_CHAR( ld_pay_work_date,cv_format1 )
                    );    
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END get_bm_support_add_info;
  --
  /**********************************************************************************
   * Procedure Name   : chk_customer_info
   * Description      : �����Ώیڋq�f�[�^�̔��f(A-4,A-22,A-40)
   ***********************************************************************************/
  PROCEDURE chk_customer_info(
     ov_errbuf         OUT VARCHAR2                             -- �G���[���b�Z�[�W
    ,ov_retcode        OUT VARCHAR2                             -- ���^�[���E�R�[�h
    ,ov_errmsg         OUT VARCHAR2                             -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_vendor_type    IN  VARCHAR2                             -- �x���_�[�敪
    ,iv_customer_code  IN  hz_cust_accounts.account_number%TYPE -- �ڋq�R�[�h
    ,ov_bill_cust_code OUT hz_cust_accounts.account_number%TYPE -- ������ڋq�R�[�h
    ,ot_many_term      OUT g_many_term_ttype                    -- �����x������
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_customer_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- API���^�[���E���b�Z�[�W�p
    -- �J�E���^
    ln_term_cnt  PLS_INTEGER := 0; -- �x�������J�E���^
    ln_close_cnt PLS_INTEGER := 0; -- ���ߓ��J�E���^
    ln_match_cnt PLS_INTEGER := 0; -- ���ߓ��\�[�g�p�J�E���^
    -- ��������
    ld_pre_month1 DATE   := NULL; -- �O���������ޔ�
    ld_pre_month2 DATE   := NULL; -- �O�X���������ޔ�
    ln_bill_cycle NUMBER := NULL; -- ���������s�T�C�N���ޔ�
    -- �x�����e�[�u����`
    lt_term_name  g_term_name_ttype;  -- �x�������ޔ�
    lt_close_date g_close_date_ttype; -- ���ߓ����ޔ�
    -- �������ʃ^�C�v��`
    lv_bill_cust_code hz_cust_accounts.account_number%TYPE           := NULL; -- ������ڋq�R�[�h
    ld_close_date     xxcok_cond_bm_support.closing_date%TYPE        := NULL; -- ���ߓ�
    ld_pay_date       xxcok_cond_bm_support.expect_payment_date%TYPE := NULL; -- �x����
    ld_to_close_date  xxcok_cond_bm_support.closing_date%TYPE        := NULL; -- ������ߓ�
    ld_to_pay_date    xxcok_cond_bm_support.expect_payment_date%TYPE := NULL; -- ����x����
    ld_fm_close_date  xxcok_cond_bm_support.closing_date%TYPE        := NULL; -- �O����ߓ�
    ld_fm_pay_date    xxcok_cond_bm_support.expect_payment_date%TYPE := NULL; -- �O��x����
    ld_stert_date     xxcok_cond_bm_support.closing_date%TYPE        := NULL; -- �̎�̋��v�Z�J�n��
    ld_end_date       xxcok_cond_bm_support.closing_date%TYPE        := NULL; -- �̎�̋��v�Z�I����
    lv_term_name1     ra_terms_tl.name%TYPE                          := NULL; -- �x������1
    lv_term_name2     ra_terms_tl.name%TYPE                          := NULL; -- �x������2
    lv_term_name3     ra_terms_tl.name%TYPE                          := NULL; -- �x������3
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �_����J�[�\����`
    CURSOR contract_info_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE -- �ڋq�R�[�h
    )
    IS
      SELECT xcm.install_account_number AS in_account_number -- �ݒu��ڋq�R�[�h
            ,xcm.close_day_code         AS close_day_code      -- ���ߓ�
            ,xcm.transfer_day_code      AS transfer_day_code   -- �U����
            ,xcm.transfer_month_code    AS transfer_month_code -- �U����
      FROM   xxcso_contract_managements xcm
            ,( SELECT MAX( contract_number ) AS contract_number   -- �_��ԍ�
                     ,install_account_id     AS in_account_number -- �ݒu��ڋqID
               FROM   xxcso_contract_managements xcm -- �_��Ǘ��e�[�u��
                     ,hz_cust_accounts           hca -- �ڋq�}�X�^
                     ,xxcmm_cust_accounts        xca -- �ڋq�}�X�^�A�h�I��
               WHERE  hca.account_number      = iv_customer_code
               AND    hca.customer_class_code = cv_cust_type1 -- �ڋq�敪�F�ڋq
               AND    hca.cust_account_id     = xca.customer_id
               AND    xca.business_low_type   = cv_bus_type1 -- �Ƒԏ����ދ敪�F�t���x���_�[
               AND    hca.cust_account_id     = xcm.install_account_id
               AND    xcm.status              = cv_one -- �m���
               GROUP BY install_account_id ) ina
      WHERE  xcm.contract_number    = ina.contract_number
      AND    xcm.install_account_id = ina.in_account_number
      AND    xcm.status             = cv_one -- �m���
      AND    ROWNUM                 = 1;
    -- �_���񃌃R�[�h��`
    contract_info_rec contract_info_cur%ROWTYPE;
    -- ������ڋq���J�[�\����`
    CURSOR bill_cust_info_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE -- �ڋq�R�[�h
      ,in_org_id        IN hz_cust_acct_sites_all.org_id%TYPE   -- �g�DID
      ,iv_language      IN ra_terms_tl.language%TYPE            -- ����
    )
    IS
      SELECT hca.account_number AS customer_code -- �ڋq�R�[�h
            ,rt1.name           AS term_name1    -- �x�������P
            ,rt2.name           AS term_name2    -- �x�������Q
            ,rt3.name           AS term_name3    -- �x�������R
            ,hcu.attribute8     AS bill_cycle    -- ���������s�T�C�N��
      FROM   hz_cust_accounts       hca -- �ڋq�}�X�^
            ,hz_cust_acct_sites_all hcs -- �ڋq�T�C�g�}�X�^
            ,hz_cust_site_uses_all  hcu -- �ڋq�T�C�g�g�p�ړI
            ,ra_terms_tl            rt1 -- �x�������}�X�^�P
            ,ra_terms_tl            rt2 -- �x�������}�X�^�Q
            ,ra_terms_tl            rt3 -- �x�������}�X�^�R
      WHERE  hca.account_number    = iv_customer_code
      AND    hca.cust_account_id   = hcs.cust_account_id
      AND    hcs.org_id            = in_org_id
      AND    hcs.cust_acct_site_id = hcu.cust_acct_site_id
      AND    hcu.org_id            = in_org_id
      AND    hcu.site_use_code     = cv_bill_site_use -- ������
      AND    hcu.payment_term_id   = rt1.term_id
      AND    rt1.language          = iv_language
      AND    hcu.attribute2        = rt2.term_id(+)
      AND    rt2.language(+)       = iv_language
      AND    hcu.attribute3        = rt3.term_id(+)
      AND    rt3.language(+)       = iv_language
      AND    ROWNUM                = 1;
    -- ������ڋq��񃌃R�[�h��`
    bill_cust_info_rec bill_cust_info_cur%ROWTYPE;
    --===============================
    -- ���[�J����O
    --===============================
    contract_err_expt   EXCEPTION; -- �_����擾�G���[
    bill_cust_err_expt  EXCEPTION; -- ������ڋq�擾�G���[
    close_date_err_expt EXCEPTION; -- ���߁E�x�����擾�G���[
    work_date_err_expt  EXCEPTION; -- �c�Ɠ��擾�G���[
    customer_err_expt   EXCEPTION; -- �����ΏۊO�ڋq�G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -- �O���̏��������擾
    ld_pre_month1 := ADD_MONTHS( gd_proc_date , - cn_one );
    -- �O�X���̏��������擾
    ld_pre_month2 := ADD_MONTHS( gd_proc_date , - cn_two );
    -------------------------------------------------
    -- 1.�t���x���_�[�_����擾
    -------------------------------------------------
    IF ( iv_vendor_type = cv_vendor_type1 ) THEN
      -------------------------------------------------
      -- �_����擾
      -------------------------------------------------
      OPEN contract_info_cur(
         iv_customer_code -- �ڋq�R�[�h
      );
      FETCH contract_info_cur INTO contract_info_rec;
      -- �_����`�F�b�N
      IF ( contract_info_cur%NOTFOUND ) THEN
        RAISE contract_err_expt;
      END IF;
      -- �����U��������
      IF ( contract_info_rec.transfer_month_code = cv_month_type1 ) THEN
        -- �����x����������
        lt_term_name( cn_bm1_set ) :=
             TO_CHAR( TO_NUMBER( contract_info_rec.close_day_code ) ,'FM00' )    || '_' ||
             TO_CHAR( TO_NUMBER( contract_info_rec.transfer_day_code ) ,'FM00' ) || '_' ||
             cv_site_type1;
      -- �����U��������
      ELSIF ( contract_info_rec.transfer_month_code = cv_month_type2 ) THEN
        -- �����x����������
        lt_term_name( cn_bm1_set ) :=
             TO_CHAR( TO_NUMBER( contract_info_rec.close_day_code ) ,'FM00' )    || '_' ||
             TO_CHAR( TO_NUMBER( contract_info_rec.transfer_day_code ) ,'FM00' ) || '_' ||
             cv_site_type2;
      -- �U�����擾����
      ELSIF ( contract_info_rec.transfer_month_code IS NULL ) OR
            ( contract_info_rec.transfer_month_code <> cv_month_type1 ) OR
            ( contract_info_rec.transfer_month_code <> cv_month_type2 ) THEN
        -- �_����擾�G���[
        RAISE contract_err_expt;
      END IF;
    -------------------------------------------------
    -- 2.�t���x���_�[(����)�E��ʌ_����擾
    -------------------------------------------------
    ELSIF ( iv_vendor_type = cv_vendor_type2 ) OR
          ( iv_vendor_type = cv_vendor_type3 ) THEN
      -------------------------------------------------
      -- ������ڋq�R�[�h�擾
      -------------------------------------------------
      lv_bill_cust_code := xxcok_common_pkg.get_bill_to_cust_code_f(
         iv_ship_to_cust_code => iv_customer_code -- �[�i��ڋq�R�[�h
      );
      -- ������ڋq�R�[�h�擾����
      IF ( lv_bill_cust_code IS NULL ) THEN
        RAISE bill_cust_err_expt;
      END IF;
      -------------------------------------------------
      -- ������ڋq���擾
      -------------------------------------------------
      OPEN bill_cust_info_cur(
         lv_bill_cust_code -- ������ڋq�R�[�h
        ,gn_pro_org_id     -- �g�DID
        ,gv_language       -- ����
      );
      FETCH bill_cust_info_cur INTO bill_cust_info_rec;
      -- ������ڋq���`�F�b�N
      IF ( bill_cust_info_cur%NOTFOUND ) THEN
        RAISE bill_cust_err_expt;
      END IF;
      -- �x�������ޔ�
      lv_term_name1 := bill_cust_info_rec.term_name1;
      lv_term_name2 := bill_cust_info_rec.term_name2;
      lv_term_name3 := bill_cust_info_rec.term_name3;
      -- ���������s�T�C�N���ޔ�
      ln_bill_cycle := TO_NUMBER( bill_cust_info_rec.bill_cycle );
      -------------------------------------------------
      -- �L���x�������`�F�b�N
      -------------------------------------------------
      << vendor_chk_point_loop >>
      FOR ln_term_cnt IN cn_bm1_set..cn_bm3_set LOOP
        -- �_��Ҏx�������`�F�b�N
        IF ( lv_term_name1 IS NOT NULL ) THEN
          -- BM1�ޔ�
          lt_term_name( ln_match_cnt ) := lv_term_name1;
          -- �x�������N���A
          lv_term_name1 := NULL;
          -- �z��C���N�������g
          ln_match_cnt := ln_match_cnt + cn_one;
        -- �Љ��BM�Q�x�������`�F�b�N
        ELSIF ( lv_term_name2 IS NOT NULL ) THEN
          -- BM2�ޔ�
          lt_term_name( ln_match_cnt ) := lv_term_name2;
          -- �x�������N���A
          lv_term_name2 := NULL;
          -- �z��C���N�������g
          ln_match_cnt := ln_match_cnt + cn_one;
        -- �Љ��BM�R�x�������`�F�b�N
        ELSIF ( lv_term_name3 IS NOT NULL ) THEN
          -- BM3�ޔ�
          lt_term_name( ln_match_cnt ) := lv_term_name3;
          -- �x�������N���A
          lv_term_name3 := NULL;
          -- �z��C���N�������g
          ln_match_cnt := ln_match_cnt + cn_one;
        END IF;
      END LOOP vendor_chk_point_loop;
    END IF;
    -------------------------------------------------
    -- 3.�x�������ϊ�����
    -------------------------------------------------
    << term_change_loop >>
    FOR ln_term_cnt IN lt_term_name.FIRST..lt_term_name.LAST LOOP
      -------------------------------------------------
      -- ������߁E�x�����擾
      -------------------------------------------------
      BEGIN
        -- ���߁E�x�����擾
        xxcok_common_pkg.get_close_date_p(
           ov_errbuf     => lv_errbuf                                -- �G���[���b�Z�[�W
          ,ov_retcode    => lv_retcode                               -- ���^�[���E�R�[�h
          ,ov_errmsg     => lv_errmsg                                -- ���[�U�[�E�G���[���b�Z�[�W
          ,id_proc_date  => gd_proc_date                             -- ������
          ,iv_pay_cond   => lt_term_name( ln_term_cnt )              -- �x������
          ,od_close_date => lt_close_date( ln_close_cnt ).close_date -- ���ߓ�
          ,od_pay_date   => lt_close_date( ln_close_cnt ).pay_date   -- �x����
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- ���߁E�x�����擾�G���[
          RAISE close_date_err_expt;
      END;
      -- �x�������ޔ�
      lt_close_date( ln_close_cnt ).term_name := lt_term_name( ln_term_cnt );
      -- �C���N�������g
      ln_close_cnt := ln_close_cnt + cn_one;
      -------------------------------------------------
      -- �O����߁E�x�����擾
      -------------------------------------------------
      BEGIN
        -- ���߁E�x�����擾
        xxcok_common_pkg.get_close_date_p(
           ov_errbuf     => lv_errbuf                                -- �G���[���b�Z�[�W
          ,ov_retcode    => lv_retcode                               -- ���^�[���E�R�[�h
          ,ov_errmsg     => lv_errmsg                                -- ���[�U�[�E�G���[���b�Z�[�W
          ,id_proc_date  => ld_pre_month1                            -- ������
          ,iv_pay_cond   => lt_term_name( ln_term_cnt )              -- �x������
          ,od_close_date => lt_close_date( ln_close_cnt ).close_date -- ���ߓ�
          ,od_pay_date   => lt_close_date( ln_close_cnt ).pay_date   -- �x����
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- ���߁E�x�����擾�G���[
          RAISE close_date_err_expt;
      END;
      -- �x�������ޔ�
      lt_close_date( ln_close_cnt ).term_name := lt_term_name( ln_term_cnt );
      -- �C���N�������g
      ln_close_cnt := ln_close_cnt + cn_one;
      -------------------------------------------------
      -- �O�X����߁E�x�����擾
      -------------------------------------------------
      BEGIN
        -- ���߁E�x�����擾
        xxcok_common_pkg.get_close_date_p(
           ov_errbuf     => lv_errbuf                                -- �G���[���b�Z�[�W
          ,ov_retcode    => lv_retcode                               -- ���^�[���E�R�[�h
          ,ov_errmsg     => lv_errmsg                                -- ���[�U�[�E�G���[���b�Z�[�W
          ,id_proc_date  => ld_pre_month2                            -- ������
          ,iv_pay_cond   => lt_term_name( ln_term_cnt )              -- �x������
          ,od_close_date => lt_close_date( ln_close_cnt ).close_date -- ���ߓ�
          ,od_pay_date   => lt_close_date( ln_close_cnt ).pay_date   -- �x����
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- ���߁E�x�����擾�G���[
          RAISE close_date_err_expt;
      END;
      -- �x�������ޔ�
      lt_close_date( ln_close_cnt ).term_name := lt_term_name( ln_term_cnt );
      -- �C���N�������g
      ln_close_cnt := ln_close_cnt + cn_one;
    END LOOP term_change_loop;
    -------------------------------------------------
    -- 4.�̎�̋��v�Z�Z�o
    -------------------------------------------------
    << close_change_loop >>
    FOR ln_close_cnt IN lt_close_date.FIRST..lt_close_date.LAST LOOP
      -------------------------------------------------
      -- �̎�̋��v�Z�J�n���擾
      -------------------------------------------------
      BEGIN
        -- �c�Ɠ��擾
        lt_close_date( ln_close_cnt ).start_date := xxcok_common_pkg.get_operating_day_f(
           id_proc_date => lt_close_date( ln_close_cnt ).close_date -- �������F���ߓ�
          ,in_days      => gn_pro_bm_sup_fm                         -- �����F�����ʔ̎�̋��v�Z��������(From)
          ,in_proc_type => cn_one                                   -- �����敪�F�O
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- �c�Ɠ��擾�G���[
          RAISE work_date_err_expt;
      END;
      -------------------------------------------------
      -- �̎�̋��v�Z�I�����擾
      -------------------------------------------------
      BEGIN
        -------------------------------------------------
        -- �t���x���_�[�̎�̋��v�Z�I�����擾
        -------------------------------------------------
        IF ( iv_vendor_type = cv_vendor_type1 ) THEN
          -- �c�Ɠ��擾
          lt_close_date( ln_close_cnt ).end_date := xxcok_common_pkg.get_operating_day_f(
             id_proc_date => lt_close_date( ln_close_cnt ).close_date -- �������F���ߓ�
            ,in_days      => gn_pro_bm_sup_to                         -- �����F�����ʔ̎�̋��v�Z��������(To)
            ,in_proc_type => cn_one                                   -- �����敪�F�O
          );
        --------------------------------------------------------
        -- �t���x���_�[(����)�E��ʔ̎�̋��v�Z�I�����擾
        --------------------------------------------------------
        ELSIF ( iv_vendor_type = cv_vendor_type2 ) OR
              ( iv_vendor_type = cv_vendor_type3 ) THEN
          -- �c�Ɠ��擾
          lt_close_date( ln_close_cnt ).end_date := xxcok_common_pkg.get_operating_day_f(
             id_proc_date => lt_close_date( ln_close_cnt ).close_date -- �������F���ߓ�
            ,in_days      => ln_bill_cycle                            -- �����F���������s�T�C�N��
            ,in_proc_type => cn_one                                   -- �����敪�F�O
          );
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          -- �c�Ɠ��擾�G���[
          RAISE work_date_err_expt;
      END;
      ---------------------------------------------------------
      -- �̎�̋��v�Z�J�n�����Ɩ����t���̎�̋��v�Z�I��������
      ---------------------------------------------------------
      IF ( lt_close_date( ln_close_cnt ).start_date <= gd_proc_date ) AND
         ( lt_close_date( ln_close_cnt ).end_date >= gd_proc_date ) THEN
        -- ������߁E����x�����E�x�������ޔ�
        ot_many_term( ln_term_cnt ).to_close_date := lt_close_date( ln_close_cnt ).close_date;
        ot_many_term( ln_term_cnt ).to_pay_date   := lt_close_date( ln_close_cnt ).pay_date;
        ot_many_term( ln_term_cnt ).to_term_name  := lt_close_date( ln_close_cnt ).term_name;
        ot_many_term( ln_term_cnt ).end_date      := lt_close_date( ln_close_cnt ).end_date;
        -- �x�������C���N�������g
        ln_term_cnt := ln_term_cnt + cn_one;
      END IF;
    END LOOP close_change_loop;
    -------------------------------------------------
    -- 5.�����Ώیڋq���݃`�F�b�N
    -------------------------------------------------
    IF ( ot_many_term.COUNT = cn_zero ) THEN
      RAISE customer_err_expt;
    END IF;
    -------------------------------------------------
    -- 6.���ߓ��N�C�b�N�\�[�g
    -------------------------------------------------
    << close_date_all_loop >>
    FOR ln_close_cnt IN lt_close_date.FIRST..lt_close_date.LAST LOOP
      << close_date_point_loop >>
      FOR ln_match_cnt IN lt_close_date.FIRST..lt_close_date.LAST LOOP
        -- ���ߓ��召����
        IF ( lt_close_date( ln_close_cnt ).close_date < lt_close_date( ln_match_cnt ).close_date ) THEN
          -- ���R�[�h�ޔ�
          ld_stert_date := lt_close_date( ln_close_cnt ).start_date;
          ld_end_date   := lt_close_date( ln_close_cnt ).end_date;
          ld_close_date := lt_close_date( ln_close_cnt ).close_date;
          ld_pay_date   := lt_close_date( ln_close_cnt ).pay_date;
          lv_term_name1 := lt_close_date( ln_close_cnt ).term_name;
          -- ��f�[�^�u��
          lt_close_date( ln_close_cnt ).start_date := lt_close_date( ln_match_cnt ).start_date;
          lt_close_date( ln_close_cnt ).end_date   := lt_close_date( ln_match_cnt ).end_date;
          lt_close_date( ln_close_cnt ).close_date := lt_close_date( ln_match_cnt ).close_date;
          lt_close_date( ln_close_cnt ).pay_date   := lt_close_date( ln_match_cnt ).pay_date;
          lt_close_date( ln_close_cnt ).term_name  := lt_close_date( ln_match_cnt ).term_name;
          -- ���f�[�^�u��
          lt_close_date( ln_match_cnt ).start_date := ld_stert_date;
          lt_close_date( ln_match_cnt ).end_date   := ld_end_date;
          lt_close_date( ln_match_cnt ).close_date := ld_close_date;
          lt_close_date( ln_match_cnt ).pay_date   := ld_pay_date;
          lt_close_date( ln_match_cnt ).term_name  := lv_term_name1;
        END IF;
      END LOOP close_date_point_loop;
    END LOOP close_date_all_loop;
    -------------------------------------------------
    -- 7.�O����ߎx�����擾
    -------------------------------------------------
    << many_term_all_loop >>
    FOR ln_term_cnt IN ot_many_term.FIRST..ot_many_term.LAST LOOP
      << close_date_point_loop >>
      FOR ln_close_cnt IN lt_close_date.FIRST..lt_close_date.LAST LOOP
        -- ���ߓ���v����
        IF ( ot_many_term( ln_term_cnt ).to_close_date = lt_close_date( ln_close_cnt ).close_date ) THEN
          -- �P���O�̃��R�[�h�i�O����ߓ��j�ޔ�
          ot_many_term( ln_term_cnt ).fm_close_date := lt_close_date( ln_close_cnt - cn_one ).close_date;
          ot_many_term( ln_term_cnt ).fm_pay_date   := lt_close_date( ln_close_cnt - cn_one ).pay_date;
          ot_many_term( ln_term_cnt ).fm_term_name  := lt_close_date( ln_close_cnt - cn_one ).term_name;
        END IF;
      END LOOP close_date_point_loop;
    END LOOP many_term_all_loop;
    -------------------------------------------------
    -- 8.�x�������N�C�b�N�\�[�g
    -------------------------------------------------
    << many_term_sort_all_loop >>
    FOR ln_close_cnt IN ot_many_term.FIRST..ot_many_term.LAST LOOP
      << many_term_sort_point_loop >>
      FOR ln_match_cnt IN ot_many_term.FIRST..ot_many_term.LAST LOOP
        -- ���ߓ��召����
        IF ( ot_many_term( ln_close_cnt ).to_close_date < ot_many_term( ln_match_cnt ).to_close_date ) THEN
          -- ���R�[�h�ޔ�
          ld_to_close_date := ot_many_term( ln_close_cnt ).to_close_date;
          ld_to_pay_date   := ot_many_term( ln_close_cnt ).to_pay_date;
          lv_term_name1    := ot_many_term( ln_close_cnt ).to_term_name;
          ld_fm_close_date := ot_many_term( ln_close_cnt ).fm_close_date;
          ld_fm_pay_date   := ot_many_term( ln_close_cnt ).fm_pay_date;
          lv_term_name2    := ot_many_term( ln_close_cnt ).fm_term_name;
          ld_end_date      := ot_many_term( ln_close_cnt ).end_date;
          -- ��f�[�^�u��
          ot_many_term( ln_close_cnt ).to_close_date := ot_many_term( ln_match_cnt ).to_close_date;
          ot_many_term( ln_close_cnt ).to_pay_date   := ot_many_term( ln_match_cnt ).to_pay_date;
          ot_many_term( ln_close_cnt ).to_term_name  := ot_many_term( ln_match_cnt ).to_term_name;
          ot_many_term( ln_close_cnt ).fm_close_date := ot_many_term( ln_match_cnt ).fm_close_date;
          ot_many_term( ln_close_cnt ).fm_pay_date   := ot_many_term( ln_match_cnt ).fm_pay_date;
          ot_many_term( ln_close_cnt ).fm_term_name  := ot_many_term( ln_match_cnt ).fm_term_name;
          ot_many_term( ln_close_cnt ).end_date      := ot_many_term( ln_match_cnt ).end_date;
          -- ���f�[�^�u��
          ot_many_term( ln_match_cnt ).to_close_date := ld_to_close_date;
          ot_many_term( ln_match_cnt ).to_pay_date   := ld_to_pay_date;
          ot_many_term( ln_match_cnt ).to_term_name  := lv_term_name1;
          ot_many_term( ln_match_cnt ).fm_close_date := ld_fm_close_date;
          ot_many_term( ln_match_cnt ).fm_pay_date   := ld_fm_pay_date;
          ot_many_term( ln_match_cnt ).fm_term_name  := lv_term_name2;
          ot_many_term( ln_match_cnt ).end_date      := ld_end_date;
        END IF;
      END LOOP many_term_sort_point_loop;
    END LOOP many_term_sort_all_loop;
    -------------------------------------------------
    -- 9.�߂�l�ݒ�
    -------------------------------------------------
    ov_bill_cust_code := lv_bill_cust_code; -- ������ڋq�R�[�h
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ������ڋq�擾��O�n���h��
    ----------------------------------------------------------
    WHEN bill_cust_err_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00079
                      ,iv_token_name1  => cv_tkn_cust_code
                      ,iv_token_value1 => iv_customer_code
                    );    
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- �_����擾��O�n���h��
    ----------------------------------------------------------
    WHEN contract_err_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_10399
                      ,iv_token_name1  => cv_tkn_cust_code
                      ,iv_token_value1 => iv_customer_code
                    );
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- ���߁E�x�����擾��O�n���h��
    ----------------------------------------------------------
    WHEN close_date_err_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00036
                    );
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- �c�Ɠ��擾��O�n���h��
    ----------------------------------------------------------
    WHEN work_date_err_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00027
                    );
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_warn;
    ----------------------------------------------------------
    -- �����ΏۊO�ڋq��O�n���h��
    ----------------------------------------------------------
    WHEN customer_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_customer_err;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END chk_customer_info;
  --
  /**********************************************************************************
   * Procedure Name   : del_bm_support_info
   * Description      : �̎�̋��ێ����ԊO�f�[�^�̍폜(A-2)
   ***********************************************************************************/
  PROCEDURE del_bm_support_info(
     ov_errbuf  OUT VARCHAR2 -- �G���[���b�Z�[�W
    ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[���b�Z�[�W
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'del_bm_support_info'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- API���^�[���E���b�Z�[�W�p
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �����ʔ̎�̋��e�[�u�����b�N
    CURSOR bm_support_del_cur(
       in_proc_date IN DATE -- �Ɩ����t
    )
    IS
      SELECT xbs.cond_bm_support_id AS bm_support_id -- �����ʔ̎�̋�ID
      FROM   xxcok_cond_bm_support xbs -- �����ʔ̎�̋��e�[�u��
      WHERE  xbs.closing_date < in_proc_date
      FOR UPDATE NOWAIT;
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.�̎�̋��ێ����ԊO�f�[�^�폜���b�N����
    -------------------------------------------------
    -- ���b�N����
    OPEN bm_support_del_cur(
       gd_limit_date -- �̎�̋��ێ��������擾
    );
    CLOSE bm_support_del_cur;
    -------------------------------------------------
    -- 2.�̎�̋��ێ����ԊO�f�[�^�폜����
    -------------------------------------------------
    BEGIN
      DELETE FROM xxcok_cond_bm_support xbs
      WHERE xbs.closing_date < gd_limit_date;
    EXCEPTION
      ----------------------------------------------------------
      -- �̎�̋��ێ����ԊO�f�[�^�폜��O
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_10398
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- �o�͋敪
                        ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line => cn_zero         -- ���s
                      );
        ov_errmsg  := lv_out_msg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
        ov_retcode := cv_status_error;
    END;
  --
  EXCEPTION
    ----------------------------------------------------------
    -- ���b�N��O�n���h��
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00051
                    );    
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END del_bm_support_info;
  --
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
     ov_errbuf    OUT VARCHAR2 -- �G���[���b�Z�[�W
    ,ov_retcode   OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,ov_errmsg    OUT VARCHAR2 -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_proc_date IN  VARCHAR2 -- �Ɩ����t
    ,iv_proc_type IN  VARCHAR2 -- ���s�敪
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- ���b�Z�[�W�߂�l
    -- �G���[���b�Z�[�W�p
    lv_prof_err fnd_profile_options.profile_option_name%TYPE := NULL; -- �v���t�@�C���ޔ�
    ln_user_err fnd_user.user_id%TYPE                        := NULL; -- ���[�UID�ޔ�
    --===============================
    -- ���[�J����O
    --===============================
    get_date_err_expt EXCEPTION; -- �Ɩ��������t�擾�G���[
    get_prof_err_expt EXCEPTION; -- �v���t�@�C���擾�G���[
    get_dept_err_expt EXCEPTION; -- ��������擾�G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -- �����敪�ޔ�
    gv_proc_type := iv_proc_type;
    -- ����ݒ�
    gv_language  := USERENV( cv_language );
    -------------------------------------------------
    -- 1.�R���J�����g���̓p�����[�^���b�Z�[�W�o��
    -------------------------------------------------
    -- �R���J�����g�p�����[�^.�Ɩ����t���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_prmmsg_00022
                    ,iv_token_name1  => cv_tkn_bis_date
                    ,iv_token_value1 => iv_proc_date
                  );
    -- �R���J�����g�p�����[�^.�Ɩ����t���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- �o�͋敪
                    ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line => cn_zero         -- ���s
                  );
    -- �R���J�����g�p�����[�^.���s�敪�p�^�[�����b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_prmmsg_00044
                    ,iv_token_name1  => cv_tkn_proc_type
                    ,iv_token_value1 => iv_proc_type
                  );
    -- �R���J�����g�p�����[�^.���s�敪�p�^�[�����b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- �o�͋敪
                    ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line => cn_one          -- ���s
                  );
    -------------------------------------------------
    -- 2.���t�ϊ�
    -------------------------------------------------
    IF ( iv_proc_date IS NOT NULL ) THEN
      gd_proc_date := fnd_date.canonical_to_date( iv_proc_date );
    -------------------------------------------------
    -- 3.�Ɩ��������t�擾
    -------------------------------------------------
    ELSE
      gd_proc_date := xxccp_common_pkg2.get_process_date;
    END IF;
    -- NULL�̏ꍇ�̓G���[
    IF( gd_proc_date IS NULL ) THEN
      RAISE get_date_err_expt;
    END IF;
    -------------------------------------------------
    -- 4.�g�DID�v���t�@�C���擾
    -------------------------------------------------
    gn_pro_org_id := TO_NUMBER( fnd_profile.value( cv_pro_org_code ) );
    -- NULL�̏ꍇ�̓G���[
    IF ( gn_pro_org_id IS NULL ) THEN
      lv_prof_err := cv_pro_org_code;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 5.��v����ID�v���t�@�C���擾
    -------------------------------------------------
    gn_pro_books_id := TO_NUMBER( fnd_profile.value( cv_pro_books_code ) );
    -- NULL�̏ꍇ�̓G���[
    IF ( gn_pro_books_id IS NULL ) THEN
      lv_prof_err := cv_pro_books_code;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 6.�����ʔ̎�̋��v�Z��������(From)�v���t�@�C���擾
    -------------------------------------------------
    gn_pro_bm_sup_fm := TO_NUMBER( fnd_profile.value( cv_pro_bm_sup_fm ) );
    -- NULL�̏ꍇ�̓G���[
    IF ( gn_pro_bm_sup_fm IS NULL ) THEN
      lv_prof_err := cv_pro_bm_sup_fm;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 7.�����ʔ̎�̋��v�Z��������(To)�v���t�@�C���擾
    -------------------------------------------------
    gn_pro_bm_sup_to := TO_NUMBER( fnd_profile.value( cv_pro_bm_sup_to ) );
    -- NULL�̏ꍇ�̓G���[
    IF ( gn_pro_bm_sup_to IS NULL ) THEN
      lv_prof_err := cv_pro_bm_sup_to;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 8.�̎�̋��v�Z���ʕێ����ԃv���t�@�C���擾
    -------------------------------------------------
    gn_pro_sales_ret := TO_NUMBER( fnd_profile.value( cv_pro_sales_ret ) );
    -- NULL�̏ꍇ�̓G���[
    IF ( gn_pro_sales_ret IS NULL ) THEN
      lv_prof_err := cv_pro_sales_ret;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 9.�d�C��(�ϓ�)�i�ڃR�[�h�v���t�@�C���擾
    -------------------------------------------------
    gv_pro_elec_ch := fnd_profile.value( cv_pro_elec_ch );
    -- NULL�̏ꍇ�̓G���[
    IF ( gv_pro_elec_ch IS NULL ) THEN
      lv_prof_err := cv_pro_elec_ch;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 10.�d����_�~�[�R�[�h�v���t�@�C���擾
    -------------------------------------------------
    gv_pro_vendor := fnd_profile.value( cv_pro_vendor );
    -- NULL�̏ꍇ�̓G���[
    IF ( gv_pro_vendor IS NULL ) THEN
      lv_prof_err := cv_pro_vendor;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 11.�d����T�C�g�_�~�[�R�[�h�v���t�@�C���擾
    -------------------------------------------------
    gv_pro_vendor_s := fnd_profile.value( cv_pro_vendor );
    -- NULL�̏ꍇ�̓G���[
    IF ( gv_pro_vendor_s IS NULL ) THEN
      lv_prof_err := cv_pro_vendor;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 12.�̎�̋��ێ��������擾
    -------------------------------------------------
    gd_limit_date := ADD_MONTHS( TRUNC( gd_proc_date,cv_format3 ), - gn_pro_sales_ret );
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- �Ɩ��������t�擾��O�n���h��
    ----------------------------------------------------------
    WHEN get_date_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00028
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- �v���t�@�C���擾��O�n���h��
    ----------------------------------------------------------
    WHEN get_prof_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_prmmsg_00003
                      ,iv_token_name1  => cv_tkn_profile
                      ,iv_token_value1 => lv_prof_err
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_zero         -- ���s
                    );
      ov_errmsg  := lv_out_msg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
  --
  END init_proc;
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf    OUT VARCHAR2 -- �G���[���b�Z�[�W
    ,ov_retcode   OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,ov_errmsg    OUT VARCHAR2 -- ���[�U�[�E�G���[���b�Z�[�W
    ,iv_proc_date IN  VARCHAR2 -- �Ɩ����t
    ,iv_proc_type IN  VARCHAR2 -- ���s�敪
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg  VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode  BOOLEAN;        -- ���b�Z�[�W�߂�l
    -- �J�E���^
    ln_full_cnt PLS_INTEGER := 0; -- �t���x���_�[�J�E���^
    ln_term_cnt PLS_INTEGER := 0; -- �x�������J�E���^
    ln_calc_cnt PLS_INTEGER := 0; -- �v�Z�����J�E���^
    ln_vend_cnt PLS_INTEGER := 0; -- �d����J�E���^
    ln_pay_cnt  PLS_INTEGER := 0; -- �x����J�E���^
    ln_chk_cnt  PLS_INTEGER := 0; -- �x����`�F�b�N�J�E���^
    ln_sup_cnt  PLS_INTEGER := 0; -- �̋��v�Z���ʓo�^�J�E���^
    ln_sale_cnt PLS_INTEGER := 0; -- �̔����у��[�v�J�E���^
    ln_elc_cnt  PLS_INTEGER := 0; -- �d�C���v�Z�J�E���^
    -- �t���O
    ln_row_flg   NUMBER      := 0;     -- �z��g���t���O
    lv_vend_type VARCHAR2(1) := NULL;  -- �x���_�[�敪
    lv_bus_type  VARCHAR2(2) := NULL;  -- �Ƒԏ����ދ敪
    lv_el_flg1   VARCHAR2(1) := cv_no; -- �d�C��(�Œ�)�Z�o�σt���O
    lv_el_flg2   VARCHAR2(1) := cv_no; -- �d�C��(�ϓ�)�Z�o�σt���O
    -- �e�[�u���^��`
    lt_many_term   g_many_term_ttype;   -- �����x������
    lt_calculation g_calculation_ttype; -- �v�Z����
    lt_bm_vendor   g_bm_support_ttype;  -- �x������
    lt_bm_support  g_bm_support_ttype;  -- �̎�v�Z���
    -- �^�C�v��`
    lv_bill_cust_code hz_cust_accounts.account_number%TYPE                 := NULL; -- ������ڋq�R�[�h
    ld_pay_work_date  xxcok_cond_bm_support.expect_payment_date%TYPE       := NULL; -- �c�Ɠ����l�������x����
    ld_period_fm_date xxcok_cond_bm_support.calc_target_period_from%TYPE   := NULL; -- �v�Z�Ώۊ���(From)
    lv_period_year    gl_period_statuses.period_year%TYPE                  := NULL; -- ��v�N�x
    ln_bm_pct         xxcok_mst_bm_contract.bm1_pct%TYPE                   := NULL; -- ���ߗ�
    ln_bm_amt         xxcok_mst_bm_contract.bm1_amt%TYPE                   := NULL; -- ���ߊz
    ln_bm_amount      xxcos_sales_exp_lines.sale_amount%TYPE               := NULL; -- �̔��萔��
    ln_bm_amount_tax  xxcos_sales_exp_lines.tax_amount%TYPE                := NULL; -- �̔��萔������Ŋz
    ln_el_amount      xxcok_cond_bm_support.electric_amt_tax%TYPE          := NULL; -- �d�C��
    ln_el_amount_tax  xxcok_cond_bm_support.electric_tax_amt%TYPE          := NULL; -- �d�C������Ŋz
    ln_rc_amount      xxcok_cond_bm_support.csh_rcpt_discount_amt%TYPE     := NULL; -- �����l���z
    ln_rc_amount_tax  xxcok_cond_bm_support.csh_rcpt_discount_amt_tax%TYPE := NULL; -- �����l������Ŋz
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �ڋq���J�[�\����`�i�t���x���_�[�E�t���x���_�[(����)�j
    CURSOR customer_main_cur(
       iv_proc_type IN fnd_lookup_values.lookup_code%TYPE -- ���s�敪
      ,iv_bus_type  IN fnd_lookup_values.lookup_code%TYPE -- �Ƒԏ����ދ敪
      ,in_org_id    IN hz_cust_acct_sites_all.org_id%TYPE -- �g�DID
      ,iv_language  IN fnd_lookup_values.language%TYPE    -- ����
    )
    IS
      SELECT hca.account_number           AS customer_code  -- �ڋq�R�[�h
            ,xca.contractor_supplier_code AS bm_vend_code1  -- �_��Ҏd����R�[�h
            ,xca.bm_pay_supplier_code1    AS bm_vend_code2  -- �Љ��BM�x���d����R�[�h�P
            ,xca.bm_pay_supplier_code2    AS bm_vend_code3  -- �Љ��BM�x���d����R�[�h�Q
            ,xca.delivery_chain_code      AS del_chain_code -- �[�i��`�F�[���R�[�h
      FROM   hz_cust_accounts       hca -- �ڋq�}�X�^
            ,xxcmm_cust_accounts    xca -- �ڋq�}�X�^�A�h�I��
            ,hz_cust_acct_sites_all hcs -- �ڋq�T�C�g�}�X�^
            ,hz_party_sites         hzp -- �ڋq�p�[�e�B�T�C�g
            ,hz_locations           hls -- ���Ə��}�X�^
            ,fnd_lookup_values      flv -- �N�C�b�N�R�[�h
      WHERE  hca.customer_class_code = cv_cust_type1 -- �ڋq�敪�F�ڋq
      AND    hca.cust_account_id     = xca.customer_id
      AND    xca.business_low_type   = iv_bus_type
      AND    hca.cust_account_id     = hcs.cust_account_id
      AND    hcs.org_id              = in_org_id
      AND    hcs.party_site_id       = hzp.party_site_id
      AND    hzp.location_id         = hls.location_id
      AND    flv.lookup_type         = cv_lk_bm_dis_type -- �̎�̋��v�Z���s�敪
      AND    flv.language            = iv_language
      AND    flv.lookup_code         = iv_proc_type
      AND    SUBSTR ( hls.address3,1,2 ) IN ( flv.attribute1
                                             ,flv.attribute2
                                             ,flv.attribute3
                                             ,flv.attribute4
                                             ,flv.attribute5
                                             ,flv.attribute6
                                             ,flv.attribute7
                                             ,flv.attribute8
                                             ,flv.attribute9
                                             ,flv.attribute10
                                             ,flv.attribute11
                                             ,flv.attribute12
                                             ,flv.attribute13
                                             ,flv.attribute14
                                             ,flv.attribute15 );
    -- �ڋq��񃌃R�[�h��`
    customer_main_rec customer_main_cur%ROWTYPE;
    -- �ڋq���J�[�\����`�i��ʁj
    CURSOR customer_ip_main_cur(
       iv_proc_type IN fnd_lookup_values.lookup_code%TYPE -- ���s�敪
      ,in_org_id    IN hz_cust_acct_sites_all.org_id%TYPE -- �g�DID
      ,iv_language  IN fnd_lookup_values.language%TYPE    -- ����
    )
    IS
      SELECT hca.account_number                      AS customer_code  -- �ڋq�R�[�h
            ,xca.delivery_chain_code                 AS del_chain_code -- �[�i��`�F�[���R�[�h
            ,NVL( xca.receiv_discount_rate,cn_zero ) AS discount_rate  -- �����l����
      FROM   hz_cust_accounts       hca -- �ڋq�}�X�^
            ,xxcmm_cust_accounts    xca -- �ڋq�}�X�^�A�h�I��
            ,hz_cust_acct_sites_all hcs -- �ڋq�T�C�g�}�X�^
            ,hz_party_sites         hzp -- �ڋq�p�[�e�B�T�C�g
            ,hz_locations           hls -- ���Ə��}�X�^
            ,fnd_lookup_values      fl1 -- �N�C�b�N�R�[�h�P
            ,fnd_lookup_values      fl2 -- �N�C�b�N�R�[�h
      WHERE  hca.customer_class_code = cv_cust_type1 -- �ڋq�敪�F�ڋq
      AND    hca.cust_account_id     = xca.customer_id
      AND    hca.cust_account_id     = hcs.cust_account_id
      AND    hcs.org_id              = in_org_id
      AND    hcs.party_site_id       = hzp.party_site_id
      AND    hzp.location_id         = hls.location_id
      AND    fl1.lookup_type         = cv_lk_bm_dis_type -- �̎�̋��v�Z���s�敪
      AND    fl1.language            = iv_language
      AND    fl1.lookup_code         = iv_proc_type
      AND    SUBSTR ( hls.address3,1,2 ) IN ( fl1.attribute1
                                             ,fl1.attribute2
                                             ,fl1.attribute3
                                             ,fl1.attribute4
                                             ,fl1.attribute5
                                             ,fl1.attribute6
                                             ,fl1.attribute7
                                             ,fl1.attribute8
                                             ,fl1.attribute9
                                             ,fl1.attribute10
                                             ,fl1.attribute11
                                             ,fl1.attribute12
                                             ,fl1.attribute13
                                             ,fl1.attribute14
                                             ,fl1.attribute15 )
      AND    fl2.lookup_type         = cv_lk_cust_type -- �ڋq�Ƒԋ敪
      AND    fl2.language            = iv_language
      AND    fl2.attribute1          <> cv_bus_type -- 11�FVD�ȊO
      AND    xca.business_low_type   = fl2.lookup_code;
    -- �ڋq��񃌃R�[�h��`
    customer_ip_main_rec customer_ip_main_cur%ROWTYPE;
    -- �̔����я��J�[�\����`�i�t���x���_�[�E�t���x���_�[�����j
    CURSOR sales_exp_main_cur(
       iv_bus_type      IN fnd_lookup_values.lookup_code%TYPE      -- �Ƒԏ����ދ敪
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE -- ���ߓ�
      ,iv_customer_code IN hz_cust_accounts.account_number%TYPE    -- �ڋq�R�[�h
      ,iv_language      IN fnd_lookup_values.language%TYPE         -- ����
    )
    IS
      SELECT xsh.dlv_invoice_number            AS invoice_num      -- �[�i�`�[�ԍ�
            ,xsh.sales_base_code               AS sales_base_code  -- ���㋒�_�R�[�h
            ,xsh.results_employee_code         AS employee_code    -- ���ьv��҃R�[�h
            ,xsh.ship_to_customer_code         AS ship_cust_code   -- �ڋq�y�[�i��z
            ,xsh.consumption_tax_class         AS con_tax_class    -- ����ŋ敪
            ,xsh.tax_code                      AS tax_code         -- �ŋ��R�[�h
            ,NVL( xsh.tax_rate,cn_zero )       AS tax_rate         -- ����ŗ�
            ,xsl.dlv_invoice_line_number       AS invoice_line_num -- �[�i���הԍ�
            ,xsl.item_code                     AS item_code        -- �i�ڃR�[�h
            ,NVL( xsl.dlv_qty,cn_zero )        AS dlv_quantity     -- �[�i����
            ,xsl.dlv_uom_code                  AS dlv_uom_code     -- �[�i�P��
            ,NVL( xsl.dlv_unit_price,cn_zero ) AS dlv_unit_price   -- �[�i�P��
            ,NVL( xsl.sale_amount,cn_zero )    AS sales_amount     -- ������z
            ,NVL( xsl.pure_amount,cn_zero )    AS body_amount      -- �{�̋��z
            ,NVL( xsl.tax_amount,cn_zero )     AS tax_amount       -- ����ŋ��z
            ,NVL( fl1.attribute1,cv_ves_dmmy ) AS container_type   -- �e��敪
      FROM   xxcos_sales_exp_headers xsh -- �̔����уw�b�_�[�e�[�u��
            ,xxcos_sales_exp_lines   xsl -- �̔����і��׃e�[�u��
            ,xxcmm_system_items_b    xsi -- disc�i�ڃ}�X�^�A�h�I��
            ,fnd_lookup_values       fl1 -- �N�C�b�N�R�[�h�P
      WHERE  xsh.cust_gyotai_sho        = iv_bus_type
      AND    xsh.delivery_date         <= id_close_date
      AND    xsh.dlv_invoice_number     = xsl.dlv_invoice_number
      AND    xsh.ship_to_customer_code  = iv_customer_code
      AND    xsl.to_calculate_fees_flag = cv_no -- N�F������
      AND    xsl.item_code              = xsi.item_code
      AND    xsi.vessel_group           = fl1.lookup_code(+)
      AND    fl1.lookup_type(+)         = cv_lk_itm_yk_type -- �e��Q�敪
      AND    fl1.language(+)            = iv_language
      AND    NOT EXISTS ( SELECT 'X'
                          FROM   fnd_lookup_values fl2 -- �N�C�b�N�R�[�h�Q
                          WHERE  xsl.item_code   = fl2.lookup_code
                          AND    fl2.lookup_type = cv_lk_no_inv_type -- ��݌ɕi�ڋ敪
                          AND    fl2.language    = iv_language );
    -- �̔����я�񃌃R�[�h��`
    sales_exp_main_rec sales_exp_main_cur%ROWTYPE;
    -- �̔����я��J�[�\����`�i��ʁj
    CURSOR sales_exp_ip_main_cur(
       id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE -- ���ߓ�
      ,iv_customer_code IN hz_cust_accounts.account_number%TYPE    -- �ڋq�R�[�h
      ,iv_language      IN fnd_lookup_values.language%TYPE         -- ����
    )
    IS
      SELECT xsh.dlv_invoice_number            AS invoice_num      -- �[�i�`�[�ԍ�
            ,xsh.sales_base_code               AS sales_base_code  -- ���㋒�_�R�[�h
            ,xsh.results_employee_code         AS employee_code    -- ���ьv��҃R�[�h
            ,xsh.ship_to_customer_code         AS ship_cust_code   -- �ڋq�y�[�i��z
            ,xsh.consumption_tax_class         AS con_tax_class    -- ����ŋ敪
            ,xsh.tax_code                      AS tax_code         -- �ŋ��R�[�h
            ,NVL( xsh.tax_rate,cn_zero )       AS tax_rate         -- ����ŗ�
            ,xsl.dlv_invoice_line_number       AS invoice_line_num -- �[�i���הԍ�
            ,xsl.item_code                     AS item_code        -- �i�ڃR�[�h
            ,NVL( xsl.dlv_qty,cn_zero )        AS dlv_quantity     -- �[�i����
            ,xsl.dlv_uom_code                  AS dlv_uom_code     -- �[�i�P��
            ,NVL( xsl.dlv_unit_price,cn_zero ) AS dlv_unit_price   -- �[�i�P��
            ,NVL( xsl.sale_amount,cn_zero )    AS sales_amount     -- ������z
            ,NVL( xsl.pure_amount,cn_zero )    AS body_amount      -- �{�̋��z
            ,NVL( xsl.tax_amount,cn_zero )     AS tax_amount       -- ����ŋ��z
            ,NVL( fl1.attribute1,cv_ves_dmmy ) AS container_type   -- �e��敪
      FROM   xxcos_sales_exp_headers xsh -- �̔����уw�b�_�[�e�[�u��
            ,xxcos_sales_exp_lines   xsl -- �̔����і��׃e�[�u��
            ,xxcmm_system_items_b    xsi -- disc�i�ڃ}�X�^�A�h�I��
            ,fnd_lookup_values       fl1 -- �N�C�b�N�R�[�h�P
      WHERE  xsh.delivery_date         <= id_close_date
      AND    xsh.dlv_invoice_number     = xsl.dlv_invoice_number
      AND    xsh.ship_to_customer_code  = iv_customer_code
      AND    xsl.to_calculate_fees_flag = cv_no -- N�F������
      AND    xsl.item_code              = xsi.item_code
      AND    xsi.vessel_group           = fl1.lookup_code(+)
      AND    fl1.lookup_type(+)         = cv_lk_itm_yk_type -- �e��Q�敪
      AND    fl1.language(+)            = iv_language
      AND    NOT EXISTS ( SELECT 'X'
                          FROM   fnd_lookup_values fl2 -- �N�C�b�N�R�[�h�Q
                          WHERE  xsh.cust_gyotai_sho = fl2.lookup_code
                          AND    fl2.lookup_type     = cv_lk_cust_type -- �ڋq�Ƒԏ����ދ敪
                          AND    fl2.language        = iv_language
                          AND    fl2.attribute1      = cv_bus_type ) -- 11�FVD�ȊO
      AND    NOT EXISTS ( SELECT 'X'
                          FROM   fnd_lookup_values fl3 -- �N�C�b�N�R�[�h�R
                          WHERE  xsl.item_code   = fl3.lookup_code
                          AND    fl3.lookup_type = cv_lk_no_inv_type -- ��݌ɕi�ڋ敪
                          AND    fl3.language    = iv_language );
    -- �̔����я�񃌃R�[�h��`
    sales_exp_ip_main_rec sales_exp_ip_main_cur%ROWTYPE;
    -- �̎�����W����J�[�\����`
    CURSOR contract_mst_grp_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE         -- �ڋq�R�[�h
      ,id_close_date    IN xxcok_cond_bm_support.closing_date%TYPE      -- ���ߓ�
    )
    IS
      SELECT xmb.calc_type AS calc_type -- �v�Z����
      FROM   xxcok_mst_bm_contract xmb -- �̎�����}�X�^
      WHERE  xmb.cust_code        = iv_customer_code
      AND    xmb.calc_target_flag = cv_yes -- Y�F�v�Z�Ώ�
      AND    id_close_date BETWEEN NVL( xmb.start_date_active,id_close_date )
                           AND     NVL( xmb.end_date_active,id_close_date )
      GROUP BY xmb.calc_type;
    -- �̎�����W���񃌃R�[�h��`
    contract_mst_grp_rec contract_mst_grp_cur%ROWTYPE;
    --===============================
    -- ���[�J����O
    --===============================
    customer_chk_expt  EXCEPTION; -- �ΏۊO�ڋq���G���[
    customer_err_expt  EXCEPTION; -- �ڋq���G���[
    sales_exp_err_expt EXCEPTION; -- �̔����я��G���[
    contract_err_expt  EXCEPTION; -- �̎�����G���[
  --
  BEGIN
  --
    --===============================================
    -- A-0.������
    --===============================================
    lv_retcode := cv_status_normal;
    --===============================================
    -- A-01.��������
    --===============================================
    init_proc(
       ov_errbuf    => lv_errbuf    -- �G���[���b�Z�[�W
      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[���b�Z�[�W
      ,iv_proc_date => iv_proc_date -- �Ɩ����t
      ,iv_proc_type => iv_proc_type -- ���s�敪
    );
    -- �X�e�[�^�X�G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --===============================================
    -- A-02.�̎�̋��ێ����ԊO�f�[�^�̍폜
    --===============================================
    del_bm_support_info(
       ov_errbuf  => lv_errbuf  -- �G���[���b�Z�[�W
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[���b�Z�[�W 
    );
    -- �X�e�[�^�X�G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -------------------------------------------------
    -- �t���x���_�[��񃋁[�v
    -------------------------------------------------
    << full_vendor_loop >>
    FOR ln_full_cnt IN cn_one..cn_two LOOP
      --***************************************************************************************************************
      -- �x���_�[�ؑ֎��ϐ�����������
      --***************************************************************************************************************
      ln_term_cnt := 0;     -- �x�������J�E���^
      ln_calc_cnt := 0;     -- �v�Z�����J�E���^
      ln_vend_cnt := 0;     -- �d����J�E���^
      ln_pay_cnt  := 0;     -- �x����J�E���^
      ln_sale_cnt := 0;     -- �̔����у��[�v�J�E���^
      lv_el_flg1  := cv_no; -- �d�C��(�Œ�)�Z�o�σt���O
      lv_el_flg2  := cv_no; -- �d�C��(�ϓ�)�Z�o�σt���O
      -- �^�C�v��`
      lv_bill_cust_code := NULL; -- ������ڋq�R�[�h
      ld_pay_work_date  := NULL; -- �c�Ɠ����l�������x����
      ld_period_fm_date := NULL; -- �v�Z�Ώۊ���(From)
      lv_period_year    := NULL; -- ��v�N�x
      ln_bm_pct         := NULL; -- ���ߗ�
      ln_bm_amt         := NULL; -- ���ߊz
      ln_bm_amount      := NULL; -- �̔��萔��
      ln_bm_amount_tax  := NULL; -- �̔��萔������Ŋz
      ln_el_amount      := NULL; -- �d�C��
      ln_el_amount_tax  := NULL; -- �d�C������Ŋz
      -- �O���[�o���ϐ�
      gn_contract_cnt   := 0;    -- �̎�����G���[����
      gv_sales_upd_flg  := NULL; -- �̔����эX�V�t���O
      -- �e�[�u���^��`
      lt_many_term.DELETE;   -- �����x������
      lt_calculation.DELETE; -- �v�Z����
      lt_bm_vendor.DELETE;   -- �x������
      lt_bm_support.DELETE;  -- �̎�v�Z���
      -- �J�[�\���N���[�Y
      IF ( customer_main_cur%ISOPEN ) THEN
        CLOSE customer_main_cur;
      END IF;
      IF ( sales_exp_main_cur%ISOPEN  ) THEN
        CLOSE sales_exp_main_cur;
      END IF;
      --===============================================
      -- A-03.�ڋq�f�[�^�̎擾�i�t���x���_�[�j
      -- A-21.�ڋq�f�[�^�̎擾�i�t���x���_�[�����j
      --===============================================
      -- ���s�x���_�[�̔���
      IF ( ln_full_cnt = cn_one ) THEN
        -- �t���x���_�[�ݒ�
        lv_vend_type := cv_vendor_type1;-- �x���_�[�敪
        lv_bus_type  := cv_bus_type1;   -- �Ƒԏ����ދ敪
      ELSIF ( ln_full_cnt = cn_two ) THEN
        -- �t���x���_�[�����ݒ�
        lv_vend_type := cv_vendor_type2;-- �x���_�[�敪
        lv_bus_type  := cv_bus_type2;   -- �Ƒԏ����ދ敪
      END IF;
      -------------------------------------------------
      -- �ڋq��񃋁[�v
      -------------------------------------------------
      OPEN customer_main_cur(
         iv_proc_type  -- ���s�敪
        ,lv_bus_type   -- �Ƒԏ����ދ敪
        ,gn_pro_org_id -- �g�DID
        ,gv_language   -- ����
      );
      << customer_main_loop2 >>
      LOOP
        FETCH customer_main_cur INTO customer_main_rec;
        EXIT WHEN customer_main_cur%NOTFOUND;
        --*************************************************************************************************************
        -- �ڋq���P�ʂ̏��� START
        --*************************************************************************************************************
        BEGIN
          -------------------------------------------------
          -- ��������
          -------------------------------------------------
          -- �ڋq�̌������C���N�������g
          gn_customer_cnt := gn_customer_cnt + cn_one;
          -- �̔����у��[�v������
          ln_sale_cnt := 0;
          -- �̎�����v�Z�z��|�C���^������
          ln_sup_cnt := 0;
          -- �̔����эX�V�s�v
          gv_sales_upd_flg := cv_no;
          -- �d�C��(�Œ�)���Z�o
          lv_el_flg1 := cv_no;
          -- BM1�d����R�[�h������
          gv_bm1_vendor := NULL;
          -- BM1�d����T�C�g�R�[�h������
          gv_bm1_vendor_s := NULL;
          -- �x������z�񏉊���
          lt_bm_vendor.DELETE;
          -- �̎�����v�Z���ʔz�񏉊���
          lt_bm_support.DELETE;
          -- �����x�������z�񏉊���
          lt_many_term.DELETE;
          -- �̔����уJ�[�\���N���[�Y
          IF ( sales_exp_main_cur%ISOPEN ) THEN
            CLOSE sales_exp_main_cur;
          END IF;
          --===================================================
          -- A-04.�����Ώیڋq�f�[�^�̔��f�i�t���x���_�[�j
          -- A-22.�����Ώیڋq�f�[�^�̔��f�i�t���x���_�[�����j
          --===================================================
          chk_customer_info(
             ov_errbuf         => lv_errbuf                       -- �G���[���b�Z�[�W
            ,ov_retcode        => lv_retcode                      -- ���^�[���E�R�[�h
            ,ov_errmsg         => lv_errmsg                       -- ���[�U�[�E�G���[���b�Z�[�W ����
            ,iv_vendor_type    => lv_vend_type                    -- �x���_�[�敪
            ,iv_customer_code  => customer_main_rec.customer_code -- �ڋq�R�[�h
            ,ov_bill_cust_code => lv_bill_cust_code               -- ������ڋq�R�[�h
            ,ot_many_term      => lt_many_term                    -- �����x������
          );
          -- �����ΏۊO�ڋq����
          IF ( lv_retcode = cv_customer_err ) THEN
            -- �ڋq���X�L�b�v
            RAISE customer_chk_expt;
          -- �X�e�[�^�X�x������
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            -- �ڋq���X�L�b�v
            RAISE customer_err_expt;
          -- �X�e�[�^�X�G���[����
          ELSIF ( lv_retcode = cv_status_error ) THEN
            -- ���������ʃG���[
            RAISE global_process_expt;
          END IF;
          -------------------------------------------------
          -- �����x���������[�v
          -------------------------------------------------
          << many_term_all_loop >>
          FOR ln_term_cnt IN lt_many_term.FIRST..lt_many_term.LAST LOOP
            -------------------------------------------------
            -- ��������
            -------------------------------------------------
            -- �̔����у��[�v������
            ln_sale_cnt := 0;
            -- �̎�����v�Z�z��|�C���^������
            ln_sup_cnt := 0;
            -- �̔����эX�V�s�v
            gv_sales_upd_flg := cv_no;
            -- �d�C��(�Œ�)���Z�o
            lv_el_flg1 := cv_no;
            -- BM1�d����R�[�h������
            gv_bm1_vendor := NULL;
            -- BM1�d����T�C�g�R�[�h������
            gv_bm1_vendor_s := NULL;
            -- �x������z�񏉊���
            lt_bm_vendor.DELETE;
            -- �̎�����v�Z���ʔz�񏉊���
            lt_bm_support.DELETE;
            -- �̔����уJ�[�\���N���[�Y
            IF ( sales_exp_main_cur%ISOPEN ) THEN
              CLOSE sales_exp_main_cur;
            END IF;
            -------------------------------------------------
            -- �̎�̋��v�Z�I�������Ɩ����t����
            -------------------------------------------------
            IF ( lt_many_term( ln_term_cnt ).end_date = gd_proc_date ) THEN
              -- �̔����эX�V�v
              gv_sales_upd_flg := cv_yes;
            END IF;
            --=====================================================
            -- A-05.�̎�̋��v�Z�t�����̎擾�i�t���x���_�[�j
            -- A-23.�̎�̋��v�Z�t�����̎擾�i�t���x���_�[�����j
            --=====================================================
            get_bm_support_add_info(
               ov_errbuf        => lv_errbuf                               -- �G���[���b�Z�[�W
              ,ov_retcode       => lv_retcode                              -- ���^�[���E�R�[�h
              ,ov_errmsg        => lv_errmsg                               -- ���[�U�[�E�G���[���b�Z�[�W 
              ,iv_vendor_type   => lv_vend_type                            -- �x���_�[�敪
              ,iv_customer_code => customer_main_rec.customer_code         -- �ڋq�R�[�h
              ,id_pay_date      => lt_many_term( ln_term_cnt ).to_pay_date -- ����x����
              ,od_pay_work_date => ld_pay_work_date                        -- �x���\���
              ,ov_period_year   => lv_period_year                          -- ��v�N�x
            );
            -- �X�e�[�^�X�x������
            IF ( lv_retcode = cv_status_warn ) THEN
              -- �ڋq���X�L�b�v
              RAISE customer_err_expt;
            ELSIF ( lv_retcode = cv_status_error ) THEN
              -- ���������ʃG���[
              RAISE global_process_expt;
            END IF;
            --=====================================================
            -- A-06.�̎�����G���[�f�[�^�̍폜�i�t���x���_�[�j
            -- A-24.�̎�����G���[�f�[�^�̍폜�i�t���x���_�[�����j
            --=====================================================
            del_bm_contract_err_info(
               ov_errbuf        => lv_errbuf                       -- �G���[���b�Z�[�W
              ,ov_retcode       => lv_retcode                      -- ���^�[���E�R�[�h
              ,ov_errmsg        => lv_errmsg                       -- ���[�U�[�E�G���[���b�Z�[�W 
              ,iv_customer_code => customer_main_rec.customer_code -- �ڋq�R�[�h
            );
            -- �X�e�[�^�X�x������
            IF ( lv_retcode = cv_status_warn ) THEN
              -- �ڋq���X�L�b�v
              RAISE customer_err_expt;
            -- �X�e�[�^�X�G���[����
            ELSIF ( lv_retcode = cv_status_error ) THEN
              -- ���������ʃG���[
              RAISE global_process_expt;
            END IF;
            --===============================================
            -- A-07.�̔����уf�[�^�̎擾�i�t���x���_�[�j
            -- A-25.�̔����уf�[�^�̎擾�i�t���x���_�[�����j
            --===============================================
            OPEN sales_exp_main_cur(
               lv_bus_type                               -- �Ƒԏ����ދ敪
              ,lt_many_term( ln_term_cnt ).to_close_date -- ���ߓ��F������ߓ�
              ,customer_main_rec.customer_code           -- �ڋq�R�[�h
              ,gv_language                               -- ����
            );
            << sales_exp_main_loop >>
            LOOP
              FETCH sales_exp_main_cur INTO sales_exp_main_rec;
              EXIT WHEN sales_exp_main_cur%NOTFOUND;
              --*******************************************************************************************************
              -- �̔����я��P�ʂ̏��� START
              --*******************************************************************************************************
              BEGIN
                -------------------------------------------------
                -- ��������
                -------------------------------------------------
                -- �Ώی����C���N�������g
                gn_target_cnt := gn_target_cnt + cn_one;
                -- �̔����у��[�v�C���N�������g
                ln_sale_cnt := ln_sale_cnt + cn_one;
                -- �d�C��(�ϓ�)���Z�o
                lv_el_flg2 := cv_no;
                -------------------------------------------------
                -- �v�Z�����E�x����擾����
                -------------------------------------------------
                -- �̔����у��[�v�̏���܂��͎x�����񂪑��݂��Ȃ��ꍇ
                IF ( ln_sale_cnt = cn_one ) OR
                   ( lt_bm_vendor.COUNT = cn_zero ) THEN
                  --===============================================
                  -- A-08.�v�Z�����̎擾�i�t���x���_�[�j
                  -- A-26.�v�Z�����̎擾�i�t���x���_�[�����j
                  --===============================================
                  -------------------------------------------------
                  -- �v�Z������������
                  -------------------------------------------------
                  -- �v�Z�����J�E���^������
                  ln_calc_cnt := cn_zero;
                  -- �v�Z�����z�񏉊���
                  lt_calculation.DELETE;
                  -- �v�Z�����J�[�\���N���[�Y
                  IF ( contract_mst_grp_cur%ISOPEN ) THEN
                    CLOSE contract_mst_grp_cur;
                  END IF;
                  -------------------------------------------------
                  -- �v�Z�����W����擾���[�v
                  -------------------------------------------------
                  OPEN contract_mst_grp_cur(
                     customer_main_rec.customer_code           -- �ڋq�R�[�h
                    ,lt_many_term( ln_term_cnt ).to_close_date -- ���ߓ��F������ߓ�
                  );
                  << contract_mst_grp_loop >>
                  LOOP
                    FETCH contract_mst_grp_cur INTO contract_mst_grp_rec;
                    EXIT WHEN contract_mst_grp_cur%NOTFOUND;
                    -- �v�Z�����J�E���^�C���N�������g
                    ln_calc_cnt := ln_calc_cnt + cn_one;
                    -- �v�Z�����ޔ�
                    lt_calculation( ln_calc_cnt ) := contract_mst_grp_rec.calc_type;
                    -- �d�C���v�Z�`�F�b�N
                    IF ( contract_mst_grp_rec.calc_type = cv_cal_type50 ) THEN
                      -- �d�C���v�Z�C���N�������g
                      ln_elc_cnt := ln_elc_cnt + cn_one;
                    END IF;
                  END LOOP contract_mst_grp_loop;
                  -------------------------------------------------
                  -- �v�Z�����擾���ʔ���
                  -------------------------------------------------
                  IF ( ln_calc_cnt = cn_zero ) THEN
                    -- �̎�����G���[�X�L�b�v
                    RAISE contract_err_expt;
                  END IF;
                  --===============================================
                  -- A-09.�x����f�[�^�̎擾�i�t���x���_�[�j
                  -- A-27.�x����f�[�^�̎擾�i�t���x���_�[�����j
                  --===============================================
                  get_active_vendor_info(
                     ov_errbuf        => lv_errbuf                       -- �G���[���b�Z�[�W
                    ,ov_retcode       => lv_retcode                      -- ���^�[���E�R�[�h
                    ,ov_errmsg        => lv_errmsg                       -- ���[�U�[�E�G���[���b�Z�[�W 
                    ,iv_vendor_type   => lv_vend_type                    -- �x���_�[�敪
                    ,iv_customer_code => customer_main_rec.customer_code -- �ڋq�R�[�h
                    ,id_pay_work_date => ld_pay_work_date                -- �x���\���
                    ,iv_vendor_code1  => customer_main_rec.bm_vend_code1 -- �_��Ҏd����R�[�h
                    ,iv_vendor_code2  => customer_main_rec.bm_vend_code2 -- �Љ��BM�x���d����R�[�h�P
                    ,iv_vendor_code3  => customer_main_rec.bm_vend_code3 -- �Љ��BM�x���d����R�[�h�Q
                    ,in_elc_cnt       => ln_elc_cnt                      -- �d�C���v�Z�����L��
                    ,ot_bm_support    => lt_bm_vendor                    -- �x������
                  );
                  -- �X�e�[�^�X�x������
                  IF ( lv_retcode = cv_status_warn ) THEN
                    -- �ڋq���X�L�b�v
                    RAISE customer_err_expt;
                  -- �X�e�[�^�X�G���[����
                  ELSIF ( lv_retcode = cv_status_error ) THEN
                    -- ���������ʃG���[
                    RAISE global_process_expt;
                  END IF;
                END IF;
                -------------------------------------------------
                -- �x�����񃋁[�v
                -------------------------------------------------
                << bm_vendor_all_loop >>
                FOR ln_vend_cnt IN lt_bm_vendor.FIRST..lt_bm_vendor.LAST LOOP
                  --***************************************************************************************************
                  -- �x������P�ʂ̏��� START
                  --***************************************************************************************************
                  BEGIN
                    -------------------------------------------------
                    -- �v�Z�����W���񃋁[�v
                    -------------------------------------------------
                    << calculation_all_loop >>
                    FOR ln_calc_cnt IN lt_calculation.FIRST..lt_calculation.LAST LOOP
                      --***********************************************************************************************
                      -- �v�Z�����W����P�ʂ̏��� START
                      --***********************************************************************************************
                      BEGIN
                        -------------------------------------------------
                        -- ��������
                        -------------------------------------------------
                        -- �`�F�b�N�p�t���O������
                        ln_row_flg := cn_zero;
                        --===============================================
                        -- A-10.�����ʏ����̌v�Z�i�t���x���_�[�j
                        -- A-28.�����ʏ����̌v�Z�i�t���x���_�[�����j
                        --===============================================
                        -- �v�Z������10:�����ʏ������i�ڂ��d�C���i�ϓ��j�ȊO����
                        -- �x���敪���d�C���ȊO�̏ꍇ
                        IF ( lt_calculation( ln_calc_cnt ) = cv_cal_type10 ) AND
                           ( lt_bm_vendor( ln_vend_cnt ).bm_type <> cv_en1_type ) AND
                           ( sales_exp_main_rec.item_code <> gv_pro_elec_ch ) THEN
                          -------------------------------------------------
                          -- �����ʌv�Z����
                          -------------------------------------------------
                          cal_bm_contract10_info(
                             ov_errbuf        => lv_errbuf                                 -- �G���[���b�Z�[�W
                            ,ov_retcode       => lv_retcode                                -- ���^�[���E�R�[�h
                            ,ov_errmsg        => lv_errmsg                                 -- ���[�U�[���b�Z�[�W 
                            ,iv_customer_code => customer_main_rec.customer_code           -- �ڋq�R�[�h
                            ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- ���ߓ��F������ߓ�
                            ,iv_bm_type       => lt_bm_vendor( ln_vend_cnt ).bm_type       -- �x���敪�FBM1�`BM3
                            ,iv_calculat_type => lt_calculation( ln_calc_cnt )             -- �v�Z����
                            ,in_retail_amount => sales_exp_main_rec.dlv_unit_price         -- �����F�[�i�P��
                            ,in_sales_amount  => sales_exp_main_rec.sales_amount           -- ������z
                            ,in_tax_rate      => sales_exp_main_rec.tax_rate               -- ����ŗ�
                            ,in_dlv_quantity  => sales_exp_main_rec.dlv_quantity           -- �[�i����
                            ,on_bm_pct        => ln_bm_pct                                 -- ���ߗ�
                            ,on_bm_amt        => ln_bm_amt                                 -- ���ߊz
                            ,on_bm_amount     => ln_bm_amount                              -- �̔��萔��
                            ,on_bm_amount_tax => ln_bm_amount_tax                          -- �̔��萔������Ŋz
                          );
                          -- �̎�����G���[����
                          IF ( lv_retcode = cv_contract_err ) THEN
                            RAISE contract_err_expt;
                          -- �X�e�[�^�X�G���[����
                          ELSIF ( lv_retcode = cv_status_error ) THEN
                            RAISE global_process_expt;
                          END IF;
                          ----------------------------------------------------------
                          -- �z�񑶍݃`�F�b�N
                          ----------------------------------------------------------
                          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                            ln_row_flg := cn_one;
                          END IF;
                          ----------------------------------------------------------
                          -- �������݃`�F�b�N���[�v
                          ----------------------------------------------------------
                          IF ( ln_row_flg = cn_one ) THEN
                            << bm_sup_type10_chk_loop >>
                            FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                              -- ��������v���A���x���敪����v����ꍇ�͈�v�������_�̔z�񍀖ڂɗݐς���
                              IF ( lt_bm_support( ln_chk_cnt ).selling_price =
                                                               sales_exp_main_rec.dlv_unit_price ) AND
                                 ( lt_bm_support( ln_chk_cnt ).bm_type =
                                                               lt_bm_vendor( ln_vend_cnt ).bm_type ) THEN
                                -- ���������L��
                                ln_row_flg := cn_two;
                                -- ���݂̔z��֗ݐ�
                                ln_sup_cnt := ln_chk_cnt;
                                -- ���[�vEXIT
                                EXIT;
                              END IF;
                            END LOOP bm_sup_type10_chk_loop;
                          END IF;
                          ----------------------------------------------------------
                          -- �z��ݒ�
                          ----------------------------------------------------------
                          -- ������s��
                          IF ( ln_row_flg = cn_zero ) THEN
                            -- �z�񏉊��l�Z�b�g
                            ln_sup_cnt := cn_zero;
                          -- ��v���Ȃ��ꍇ
                          ELSIF ( ln_row_flg = cn_one ) THEN
                            -- �z����g��
                            ln_sup_cnt := lt_bm_support.LAST + 1;
                          END IF;
                          -------------------------------------------------
                          -- �v�Z���ʑޔ�
                          -------------------------------------------------
                          -- �x���敪�FBM1�`BM3
                          lt_bm_support( ln_sup_cnt ).bm_type := lt_bm_vendor( ln_vend_cnt ).bm_type;
                          -- �d����R�[�h
                          lt_bm_support( ln_sup_cnt ).supplier_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_code;
                          -- �d����T�C�g�R�[�h
                          lt_bm_support( ln_sup_cnt ).supplier_site_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_site_code;
                          -- �v�Z����
                          lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type10;
                          -- �[�i����
                          lt_bm_support( ln_sup_cnt ).delivery_qty :=
                            NVL( lt_bm_support( ln_sup_cnt ).delivery_qty,cn_zero ) +
                              sales_exp_main_rec.dlv_quantity;
                          -- �[�i�P��
                          lt_bm_support( ln_sup_cnt ).delivery_unit_type := sales_exp_main_rec.dlv_uom_code;
                          -- ������z
                          lt_bm_support( ln_sup_cnt ).selling_amt_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).selling_amt_tax,cn_zero ) +
                              sales_exp_main_rec.sales_amount;
                          -- ���ߗ�
                          lt_bm_support( ln_sup_cnt ).rebate_rate := ln_bm_pct;
                          -- ���ߊz
                          lt_bm_support( ln_sup_cnt ).rebate_amt := ln_bm_amt;
                          -- �������z
                          lt_bm_support( ln_sup_cnt ).selling_price := sales_exp_main_rec.dlv_unit_price;
                          -- �t���x���_�[�̏ꍇ
                          IF ( lv_vend_type = cv_vendor_type1 ) THEN
                            -- �����ʎ萔���z(�ō�)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax,cn_zero ) +
                                ln_bm_amount;
                            -- �����ʎ萔���z(�Ŕ�)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax,cn_zero ) +
                                ln_bm_amount - ln_bm_amount_tax;
                            -- �����ʏ���Ŋz
                            lt_bm_support( ln_sup_cnt ).cond_tax_amt :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_tax_amt,cn_zero ) +
                                ln_bm_amount_tax;
                          -- �t���x���_�[�����̏ꍇ
                          ELSIF ( lv_vend_type = cv_vendor_type2 ) THEN
                            -- �����l���z
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt :=
                              NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt,cn_zero ) +
                                ln_bm_amount;
                            -- �����l������Ŋz
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax,cn_zero ) +
                                ln_bm_amount_tax;
                          END IF;
                        --===============================================
                        -- A-11.�e��敪�ʏ����̌v�Z�i�t���x���_�[�j
                        -- A-29.�e��敪�ʏ����̌v�Z�i�t���x���_�[�����j
                        --===============================================
                        -- �v�Z������20:�e��敪�ʏ������i�ڂ��d�C���i�ϓ��j�ȊO����
                        -- �x���敪���d�C���ȊO�̏ꍇ
                        ELSIF ( lt_calculation( ln_calc_cnt ) = cv_cal_type20 ) AND
                              ( lt_bm_vendor( ln_vend_cnt ).bm_type <> cv_en1_type ) AND
                              ( sales_exp_main_rec.item_code <> gv_pro_elec_ch ) THEN
                          -------------------------------------------------
                          -- �e��敪�ʌv�Z����
                          -------------------------------------------------
                          cal_bm_contract20_info(
                             ov_errbuf         => lv_errbuf                                 -- �G���[���b�Z�[�W
                            ,ov_retcode        => lv_retcode                                -- ���^�[���E�R�[�h
                            ,ov_errmsg         => lv_errmsg                                 -- ���[�U�[���b�Z�[�W 
                            ,iv_customer_code  => customer_main_rec.customer_code           -- �ڋq�R�[�h
                            ,id_close_date     => lt_many_term( ln_term_cnt ).to_close_date -- ���ߓ��F������ߓ�
                            ,iv_bm_type        => lt_bm_vendor( ln_vend_cnt ).bm_type       -- �x���敪�FBM1�`BM3
                            ,iv_calculat_type  => lt_calculation( ln_calc_cnt )             -- �v�Z����
                            ,iv_container_type => sales_exp_main_rec.container_type         -- �e��敪
                            ,in_sales_amount   => sales_exp_main_rec.sales_amount           -- ������z
                            ,in_tax_rate       => sales_exp_main_rec.tax_rate               -- ����ŗ�
                            ,in_dlv_quantity   => sales_exp_main_rec.dlv_quantity           -- �[�i����
                            ,on_bm_pct         => ln_bm_pct                                 -- ���ߗ�
                            ,on_bm_amt         => ln_bm_amt                                 -- ���ߊz
                            ,on_bm_amount      => ln_bm_amount                              -- �̔��萔��
                            ,on_bm_amount_tax  => ln_bm_amount_tax                          -- �̔��萔������Ŋz
                          );
                          -- �̎�����G���[����
                          IF ( lv_retcode = cv_contract_err ) THEN
                            RAISE contract_err_expt;
                          -- �X�e�[�^�X�G���[����
                          ELSIF ( lv_retcode = cv_status_error ) THEN
                            RAISE global_process_expt;
                          END IF;
                          ----------------------------------------------------------
                          -- �z�񑶍݃`�F�b�N
                          ----------------------------------------------------------
                          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                            ln_row_flg := cn_one;
                          END IF;
                          ----------------------------------------------------------
                          -- �e��敪���݃`�F�b�N���[�v
                          ----------------------------------------------------------
                          IF ( ln_row_flg = cn_one ) THEN
                            << bm_sup_type20_chk_loop >>
                            FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                              -- �e��敪����v���A���x���敪����v����ꍇ�͈�v�������_�̔z�񍀖ڂɗݐς���
                              IF ( lt_bm_support( ln_chk_cnt ).container_type =
                                                               sales_exp_main_rec.container_type ) AND
                                 ( lt_bm_support( ln_chk_cnt ).bm_type =
                                                               lt_bm_vendor( ln_vend_cnt ).bm_type ) THEN
                                -- �����e��敪�L��
                                ln_row_flg := cn_two;
                                -- ���݂̔z��֗ݐ�
                                ln_sup_cnt := ln_chk_cnt;
                                -- ���[�vEXIT
                                EXIT;
                              END IF;
                            END LOOP bm_sup_type20_chk_loop;
                          END IF;
                          ----------------------------------------------------------
                          -- �z��ݒ�
                          ----------------------------------------------------------
                          -- ������s��
                          IF ( ln_row_flg = cn_zero ) THEN
                            -- �z�񏉊��l�Z�b�g
                            ln_sup_cnt := cn_zero;
                          -- ��v���Ȃ��ꍇ
                          ELSIF ( ln_row_flg = cn_one ) THEN
                            -- �z����g��
                            ln_sup_cnt := lt_bm_support.LAST + 1;
                          END IF;
                          -------------------------------------------------
                          -- �v�Z���ʑޔ�
                          -------------------------------------------------
                          -- �x���敪�FBM1�`BM3
                          lt_bm_support( ln_sup_cnt ).bm_type := lt_bm_vendor( ln_vend_cnt ).bm_type;
                          -- �d����R�[�h
                          lt_bm_support( ln_sup_cnt ).supplier_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_code;
                          -- �d����T�C�g�R�[�h
                          lt_bm_support( ln_sup_cnt ).supplier_site_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_site_code;
                          -- �v�Z����
                          lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type20;
                          -- �[�i����
                          lt_bm_support( ln_sup_cnt ).delivery_qty :=
                            NVL( lt_bm_support( ln_sup_cnt ).delivery_qty,cn_zero ) +
                              sales_exp_main_rec.dlv_quantity;
                          -- �[�i�P��
                          lt_bm_support( ln_sup_cnt ).delivery_unit_type := sales_exp_main_rec.dlv_uom_code;
                          -- ������z
                          lt_bm_support( ln_sup_cnt ).selling_amt_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).selling_amt_tax,cn_zero ) +
                              sales_exp_main_rec.sales_amount;
                          -- ���ߗ�
                          lt_bm_support( ln_sup_cnt ).rebate_rate := ln_bm_pct;
                          -- ���ߊz
                          lt_bm_support( ln_sup_cnt ).rebate_amt := ln_bm_amt;
                          -- �e��敪
                          lt_bm_support( ln_sup_cnt ).container_type := sales_exp_main_rec.container_type;
                          -- �t���x���_�[�̏ꍇ
                          IF ( lv_vend_type = cv_vendor_type1 ) THEN
                            -- �����ʎ萔���z(�ō�)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax,cn_zero ) +
                                ln_bm_amount;
                            -- �����ʎ萔���z(�Ŕ�)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax,cn_zero ) +
                                ln_bm_amount - ln_bm_amount_tax;
                            -- �����ʏ���Ŋz
                            lt_bm_support( ln_sup_cnt ).cond_tax_amt :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_tax_amt,cn_zero ) +
                                ln_bm_amount_tax;
                          -- �t���x���_�[�����̏ꍇ
                          ELSIF ( lv_vend_type = cv_vendor_type2 ) THEN
                            -- �����l���z
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt :=
                              NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt,cn_zero ) +
                                ln_bm_amount;
                            -- �����l������Ŋz
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax,cn_zero ) +
                                ln_bm_amount_tax;
                          END IF;
                        --===============================================
                        -- A-12.�ꗥ�����̌v�Z�i�t���x���_�[�j
                        -- A-30.�ꗥ�����̌v�Z�i�t���x���_�[�����j
                        --===============================================
                        -- �v�Z������30:�ꗥ�������i�ڂ��d�C���i�ϓ��j�ȊO����
                        -- �x���敪���d�C���ȊO�̏ꍇ
                        ELSIF ( lt_calculation( ln_calc_cnt ) = cv_cal_type30 ) AND
                              ( lt_bm_vendor( ln_vend_cnt ).bm_type <> cv_en1_type ) AND
                              ( sales_exp_main_rec.item_code <> gv_pro_elec_ch ) THEN
                          -------------------------------------------------
                          -- �ꗥ�v�Z����
                          -------------------------------------------------
                          cal_bm_contract30_info(
                             ov_errbuf        => lv_errbuf                                 -- �G���[���b�Z�[�W
                            ,ov_retcode       => lv_retcode                                -- ���^�[���E�R�[�h
                            ,ov_errmsg        => lv_errmsg                                 -- ���[�U�[���b�Z�[�W 
                            ,iv_customer_code => customer_main_rec.customer_code           -- �ڋq�R�[�h
                            ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- ���ߓ��F������ߓ�
                            ,iv_bm_type       => lt_bm_vendor( ln_vend_cnt ).bm_type       -- �x���敪�FBM1�`BM3
                            ,iv_calculat_type => lt_calculation( ln_calc_cnt )             -- �v�Z����
                            ,in_sales_amount  => sales_exp_main_rec.sales_amount           -- ������z
                            ,in_tax_rate      => sales_exp_main_rec.tax_rate               -- ����ŗ�
                            ,in_dlv_quantity  => sales_exp_main_rec.dlv_quantity           -- �[�i����
                            ,on_bm_pct        => ln_bm_pct                                 -- ���ߗ�
                            ,on_bm_amt        => ln_bm_amt                                 -- ���ߊz
                            ,on_bm_amount     => ln_bm_amount                              -- �̔��萔��
                            ,on_bm_amount_tax => ln_bm_amount_tax                          -- �̔��萔������Ŋz
                          );
                          -- �̎�����G���[����
                          IF ( lv_retcode = cv_contract_err ) THEN
                            RAISE contract_err_expt;
                          -- �X�e�[�^�X�G���[����
                          ELSIF ( lv_retcode = cv_status_error ) THEN
                            RAISE global_process_expt;
                          END IF;
                          ----------------------------------------------------------
                          -- �z�񑶍݃`�F�b�N
                          ----------------------------------------------------------
                          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                            ln_row_flg := cn_one;
                          END IF;
                          ----------------------------------------------------------
                          -- �x���敪���݃`�F�b�N���[�v
                          ----------------------------------------------------------
                          IF ( ln_row_flg = cn_one ) THEN
                            << bm_sup_type30_chk_loop >>
                            FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                              -- �x���敪����v����ꍇ�͈�v�������_�̔z�񍀖ڂɗݐς���
                              IF ( lt_bm_support( ln_chk_cnt ).bm_type =
                                                               lt_bm_vendor( ln_vend_cnt ).bm_type ) THEN
                                -- �����e��敪�L��
                                ln_row_flg := cn_two;
                                -- ���݂̔z��֗ݐ�
                                ln_sup_cnt := ln_chk_cnt;
                                -- ���[�vEXIT
                                EXIT;
                              END IF;
                            END LOOP bm_sup_type30_chk_loop;
                          END IF;
                          ----------------------------------------------------------
                          -- �z��ݒ�
                          ----------------------------------------------------------
                          -- ������s��
                          IF ( ln_row_flg = cn_zero ) THEN
                            -- �z�񏉊��l�Z�b�g
                            ln_sup_cnt := cn_zero;
                          -- ��v���Ȃ��ꍇ
                          ELSIF ( ln_row_flg = cn_one ) THEN
                            -- �z����g��
                            ln_sup_cnt := lt_bm_support.LAST + 1;
                          END IF;
                          -------------------------------------------------
                          -- �v�Z���ʑޔ�
                          -------------------------------------------------
                          -- �x���敪�FBM1�`BM3
                          lt_bm_support( ln_sup_cnt ).bm_type := lt_bm_vendor( ln_vend_cnt ).bm_type;
                          -- �d����R�[�h
                          lt_bm_support( ln_sup_cnt ).supplier_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_code;
                          -- �d����T�C�g�R�[�h
                          lt_bm_support( ln_sup_cnt ).supplier_site_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_site_code;
                          -- �v�Z����
                          lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type30;
                          -- �[�i����
                          lt_bm_support( ln_sup_cnt ).delivery_qty :=
                            NVL( lt_bm_support( ln_sup_cnt ).delivery_qty,cn_zero ) +
                              sales_exp_main_rec.dlv_quantity;
                          -- �[�i�P��
                          lt_bm_support( ln_sup_cnt ).delivery_unit_type := sales_exp_main_rec.dlv_uom_code;
                          -- ������z
                          lt_bm_support( ln_sup_cnt ).selling_amt_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).selling_amt_tax,cn_zero ) +
                              sales_exp_main_rec.sales_amount;
                          -- ���ߗ�
                          lt_bm_support( ln_sup_cnt ).rebate_rate := ln_bm_pct;
                          -- ���ߊz
                          lt_bm_support( ln_sup_cnt ).rebate_amt := ln_bm_amt;
                          -- �t���x���_�[�̏ꍇ
                          IF ( lv_vend_type = cv_vendor_type1 ) THEN
                            -- �����ʎ萔���z(�ō�)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax,cn_zero ) +
                                ln_bm_amount;
                            -- �����ʎ萔���z(�Ŕ�)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax,cn_zero ) +
                                ln_bm_amount - ln_bm_amount_tax;
                            -- �����ʏ���Ŋz
                            lt_bm_support( ln_sup_cnt ).cond_tax_amt :=
                              NVL( lt_bm_support( ln_sup_cnt ).cond_tax_amt,cn_zero ) +
                                ln_bm_amount_tax;
                          -- �t���x���_�[�����̏ꍇ
                          ELSIF ( lv_vend_type = cv_vendor_type2 ) THEN
                            -- �����l���z
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt :=
                              NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt,cn_zero ) +
                                ln_bm_amount;
                            -- �����l������Ŋz
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax :=
                              NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax,cn_zero ) +
                                ln_bm_amount_tax;
                          END IF;
                        --===============================================
                        -- A-13.��z�����̌v�Z�i�t���x���_�[�j
                        -- A-31.��z�����̌v�Z�i�t���x���_�[�����j
                        --===============================================
                        -- �v�Z������40:��z�������i�ڂ��d�C���i�ϓ��j�ȊO����
                        -- �x���敪���d�C���ȊO�̏ꍇ
                        ELSIF ( lt_calculation( ln_calc_cnt ) = cv_cal_type40 ) AND
                              ( lt_bm_vendor( ln_vend_cnt ).bm_type <> cv_en1_type ) AND
                              ( sales_exp_main_rec.item_code <> gv_pro_elec_ch ) THEN
                          -------------------------------------------------
                          -- ��z�v�Z����
                          -------------------------------------------------
                          cal_bm_contract40_info(
                             ov_errbuf        => lv_errbuf                                 -- �G���[���b�Z�[�W
                            ,ov_retcode       => lv_retcode                                -- ���^�[���E�R�[�h
                            ,ov_errmsg        => lv_errmsg                                 -- ���[�U�[���b�Z�[�W 
                            ,iv_customer_code => customer_main_rec.customer_code           -- �ڋq�R�[�h
                            ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- ���ߓ��F������ߓ�
                            ,iv_bm_type       => lt_bm_vendor( ln_vend_cnt ).bm_type       -- �x���敪�FBM1�`BM3
                            ,iv_calculat_type => lt_calculation( ln_calc_cnt )             -- �v�Z����
                            ,in_tax_rate      => sales_exp_main_rec.tax_rate               -- ����ŗ�
                            ,on_bm_amt        => ln_bm_amt                                 -- ���ߊz
                            ,on_bm_amount     => ln_bm_amount                              -- �̔��萔��
                            ,on_bm_amount_tax => ln_bm_amount_tax                          -- �̔��萔������Ŋz
                          );
                          -- �̎�����G���[����
                          IF ( lv_retcode = cv_contract_err ) THEN
                            RAISE contract_err_expt;
                          -- �X�e�[�^�X�G���[����
                          ELSIF ( lv_retcode = cv_status_error ) THEN
                            RAISE global_process_expt;
                          END IF;
                          ----------------------------------------------------------
                          -- �z�񑶍݃`�F�b�N
                          ----------------------------------------------------------
                          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                            ln_row_flg := cn_one;
                          END IF;
                          ----------------------------------------------------------
                          -- �x���敪���݃`�F�b�N���[�v
                          ----------------------------------------------------------
                          IF ( ln_row_flg = cn_one ) THEN
                            << bm_sup_type40_chk_loop >>
                            FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                              -- �x���敪����v����ꍇ�͈�v�������_�̔z�񍀖ڂɗݐς���
                              IF ( lt_bm_support( ln_chk_cnt ).bm_type =
                                                               lt_bm_vendor( ln_vend_cnt ).bm_type ) THEN
                                -- �����e��敪�L��
                                ln_row_flg := cn_two;
                                -- ���݂̔z��֗ݐ�
                                ln_sup_cnt := ln_chk_cnt;
                                -- ���[�vEXIT
                                EXIT;
                              END IF;
                            END LOOP bm_sup_type40_chk_loop;
                          END IF;
                          ----------------------------------------------------------
                          -- �z��ݒ�
                          ----------------------------------------------------------
                          -- ������s��
                          IF ( ln_row_flg = cn_zero ) THEN
                            -- �z�񏉊��l�Z�b�g
                            ln_sup_cnt := cn_zero;
                          -- ��v���Ȃ��ꍇ
                          ELSIF ( ln_row_flg = cn_one ) THEN
                            -- �z����g��
                            ln_sup_cnt := lt_bm_support.LAST + 1;
                          END IF;
                          -------------------------------------------------
                          -- �v�Z���ʑޔ�
                          -------------------------------------------------
                          -- �x���敪�FBM1�`BM3
                          lt_bm_support( ln_sup_cnt ).bm_type := lt_bm_vendor( ln_vend_cnt ).bm_type;
                          -- �d����R�[�h
                          lt_bm_support( ln_sup_cnt ).supplier_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_code;
                          -- �d����T�C�g�R�[�h
                          lt_bm_support( ln_sup_cnt ).supplier_site_code :=
                            lt_bm_vendor( ln_vend_cnt ).supplier_site_code;
                          -- �v�Z����
                          lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type40;
                          -- �[�i����
                          lt_bm_support( ln_sup_cnt ).delivery_qty :=
                            NVL( lt_bm_support( ln_sup_cnt ).delivery_qty,cn_zero ) +
                              sales_exp_main_rec.dlv_quantity;
                          -- �[�i�P��
                          lt_bm_support( ln_sup_cnt ).delivery_unit_type := sales_exp_main_rec.dlv_uom_code;
                          -- ������z
                          lt_bm_support( ln_sup_cnt ).selling_amt_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).selling_amt_tax,cn_zero ) +
                              sales_exp_main_rec.sales_amount;
                          -- �t���x���_�[�̏ꍇ
                          IF ( lv_vend_type = cv_vendor_type1 ) THEN
                            -- �����ʎ萔���z(�ō�)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_tax := ln_bm_amount;
                            -- �����ʎ萔���z(�Ŕ�)
                            lt_bm_support( ln_sup_cnt ).cond_bm_amt_no_tax := ln_bm_amount - ln_bm_amount_tax;
                            -- �����ʏ���Ŋz
                            lt_bm_support( ln_sup_cnt ).cond_tax_amt := ln_bm_amount_tax;
                          -- �t���x���_�[�����̏ꍇ
                          ELSIF ( lv_vend_type = cv_vendor_type2 ) THEN
                            -- �����l���z
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt := ln_bm_amount;
                            -- �����l������Ŋz
                            lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax := ln_bm_amount_tax;
                          END IF;
                        --===============================================
                        -- A-14.�d�C�������̌v�Z�i�t���x���_�[�j
                        -- A-32.�d�C�������̌v�Z�i�t���x���_�[�����j
                        --===============================================
                        -- �v�Z������50:�d�C���i�Œ�j���i�ڂ��d�C���i�ϓ��j�ȊO����
                        -- �d�C���i�Œ�j�v�Z���ڋq�����ŏ���̏ꍇ
                        ELSIF ( lt_calculation( ln_calc_cnt ) = cv_cal_type50 ) AND
                              ( sales_exp_main_rec.item_code <> gv_pro_elec_ch ) AND
                              ( lv_el_flg1 = cv_no ) THEN
                          -------------------------------------------------
                          -- �d�C���i�Œ�j�v�Z����
                          -------------------------------------------------
                          cal_bm_contract50_info(
                             ov_errbuf        => lv_errbuf                                 -- �G���[���b�Z�[�W
                            ,ov_retcode       => lv_retcode                                -- ���^�[���E�R�[�h
                            ,ov_errmsg        => lv_errmsg                                 -- ���[�U�[�E�G���[���b�Z�[�W 
                            ,iv_customer_code => customer_main_rec.customer_code           -- �ڋq�R�[�h
                            ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- ���ߓ��F������ߓ�
                            ,iv_calculat_type => lt_calculation( ln_calc_cnt )             -- �v�Z����
                            ,in_tax_rate      => sales_exp_main_rec.tax_rate               -- ����ŗ�
                            ,iv_con_tax_class => sales_exp_main_rec.con_tax_class          -- ����ŋ敪
                            ,on_el_amount     => ln_el_amount                              -- �d�C��
                            ,on_el_amount_tax => ln_el_amount_tax                          -- �d�C������Ŋz
                          );
                          -- �̎�����G���[����
                          IF ( lv_retcode = cv_contract_err ) THEN
                            RAISE contract_err_expt;
                          -- �X�e�[�^�X�G���[����
                          ELSIF ( lv_retcode = cv_status_error ) THEN
                            RAISE global_process_expt;
                          END IF;
                          ----------------------------------------------------------
                          -- �z�񑶍݃`�F�b�N
                          ----------------------------------------------------------
                          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                            ln_row_flg := cn_one;
                          END IF;
                          ----------------------------------------------------------
                          -- �d�C���x���敪���݃`�F�b�N���[�v
                          ----------------------------------------------------------
                          IF ( ln_row_flg = cn_one ) THEN
                            << bm_sup_type50_chk_loop >>
                            FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                              -- �x���敪����v����ꍇ�͈�v�������_�̔z�񍀖ڂɗݐς���
                              IF ( lt_bm_support( ln_chk_cnt ).bm_type = cv_en1_type ) THEN
                                -- �����d�C���L��
                                ln_row_flg := cn_two;
                                -- ���݂̔z��֗ݐ�
                                ln_sup_cnt := ln_chk_cnt;
                                -- ���[�vEXIT
                                EXIT;
                              END IF;
                            END LOOP bm_sup_type50_chk_loop;
                          END IF;
                          ----------------------------------------------------------
                          -- �z��ݒ�
                          ----------------------------------------------------------
                          -- ������s��
                          IF ( ln_row_flg = cn_zero ) THEN
                            -- �z�񏉊��l�Z�b�g
                            ln_sup_cnt := cn_zero;
                          -- ��v���Ȃ��ꍇ
                          ELSIF ( ln_row_flg = cn_one ) THEN
                            -- �z����g��
                            ln_sup_cnt := lt_bm_support.LAST + 1;
                          END IF;
                          -------------------------------------------------
                          -- �v�Z���ʑޔ�
                          -------------------------------------------------
                          -- �x���敪�FEN1
                          lt_bm_support( ln_sup_cnt ).bm_type := cv_en1_type;
                          -- �v�Z����
                          lt_bm_support( ln_sup_cnt ).calc_type := lt_calculation( ln_calc_cnt );
                          -- �d����R�[�h
                          lt_bm_support( ln_sup_cnt ).supplier_code := gv_bm1_vendor;
                          -- �d����T�C�g�R�[�h
                          lt_bm_support( ln_sup_cnt ).supplier_site_code := gv_bm1_vendor_s;
                          -- ������z
                          lt_bm_support( ln_sup_cnt ).selling_amt_tax := cn_zero;
                          -- �d�C��(�ō�)
                          lt_bm_support( ln_sup_cnt ).electric_amt_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).electric_amt_tax,cn_zero ) +
                              ln_el_amount;
                          -- �d�C��(�Ŕ�)
                          lt_bm_support( ln_sup_cnt ).electric_amt_no_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).electric_amt_no_tax,cn_zero ) +
                              ln_el_amount - ln_el_amount_tax;
                          -- �d�C������Ŋz
                          lt_bm_support( ln_sup_cnt ).electric_tax_amt :=
                            NVL( lt_bm_support( ln_sup_cnt ).electric_tax_amt,cn_zero ) +
                              ln_el_amount_tax;
                          -- �d�C��(�Œ�)�Z�o��
                          lv_el_flg1 := cv_yes;
                        --===============================================
                        -- A-15.�d�C���i�ϓ��j�̌v�Z�i�t���x���_�[�j
                        -- A-33.�d�C���i�ϓ��j�̌v�Z�i�t���x���_�[�����j
                        --===============================================
                        -- �i�ڂ��d�C���i�ϓ��j���d�C���i�ϓ��j�v�Z��
                        -- �̔����я����ŏ���̏ꍇ
                        ELSIF ( sales_exp_main_rec.item_code = gv_pro_elec_ch ) AND
                              ( lv_el_flg2 = cv_no ) THEN
                          ----------------------------------------------------------
                          -- �z�񑶍݃`�F�b�N
                          ----------------------------------------------------------
                          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                            ln_row_flg := cn_one;
                          END IF;
                          ----------------------------------------------------------
                          -- �d�C���x���敪���݃`�F�b�N���[�v
                          ----------------------------------------------------------
                          IF ( ln_row_flg = cn_one ) THEN
                            << bm_elc_type50_chk_loop >>
                            FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                              -- �x���敪����v����ꍇ�͈�v�������_�̔z�񍀖ڂɗݐς���
                              IF ( lt_bm_support( ln_chk_cnt ).bm_type = cv_en1_type ) THEN
                                -- �����d�C���L��
                                ln_row_flg := cn_two;
                                -- ���݂̔z��֗ݐ�
                                ln_sup_cnt := ln_chk_cnt;
                                -- ���[�vEXIT
                                EXIT;
                              END IF;
                            END LOOP bm_elc_type50_chk_loop;
                          END IF;
                          ----------------------------------------------------------
                          -- �z��ݒ�
                          ----------------------------------------------------------
                          -- ������s��
                          IF ( ln_row_flg = cn_zero ) THEN
                            -- �z�񏉊��l�Z�b�g
                            ln_sup_cnt := cn_zero;
                          -- ��v���Ȃ��ꍇ
                          ELSIF ( ln_row_flg = cn_one ) THEN
                            -- �z����g��
                            ln_sup_cnt := lt_bm_support.LAST + 1;
                          END IF;
                          -------------------------------------------------
                          -- �v�Z���ʑޔ�
                          -------------------------------------------------
                          -- �x���敪�FEN1
                          lt_bm_support( ln_sup_cnt ).bm_type := cv_en1_type;
                          -- �d����R�[�h
                          lt_bm_support( ln_sup_cnt ).supplier_code := gv_bm1_vendor;
                          -- �d����T�C�g�R�[�h
                          lt_bm_support( ln_sup_cnt ).supplier_site_code := gv_bm1_vendor_s;
                          -- �v�Z����
                          lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type50;
                          -- ������z
                          lt_bm_support( ln_sup_cnt ).selling_amt_tax := cn_zero;
                          -- �d�C��(�ō�)
                          lt_bm_support( ln_sup_cnt ).electric_amt_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).electric_amt_tax,cn_zero ) +
                              sales_exp_main_rec.sales_amount;
                          -- �d�C��(�Ŕ�)
                          lt_bm_support( ln_sup_cnt ).electric_amt_no_tax :=
                            NVL( lt_bm_support( ln_sup_cnt ).electric_amt_no_tax,cn_zero ) +
                              sales_exp_main_rec.body_amount;
                          -- �d�C������Ŋz
                          lt_bm_support( ln_sup_cnt ).electric_tax_amt :=
                            NVL( lt_bm_support( ln_sup_cnt ).electric_tax_amt,cn_zero ) +
                              sales_exp_main_rec.tax_amount;
                          -- �d�C��(�ϓ�)�Z�o��
                          lv_el_flg2 := cv_yes;
                        END IF;
                      --***********************************************************************************************
                      -- �v�Z�����W����P�ʂ̏��� END
                      --***********************************************************************************************
                      EXCEPTION
                        ----------------------------------------------------------
                        -- �̎�����G���[��O�n���h��
                        ----------------------------------------------------------
                        WHEN contract_err_expt THEN
                          --=====================================================
                          -- A-16.�̎�����G���[�f�[�^�̓o�^�i�t���x���_�[�j
                          -- A-34.�̎�����G���[�f�[�^�̓o�^�i�t���x���_�[�����j
                          --=====================================================
                          ins_bm_contract_err_info(
                             ov_errbuf         => lv_errbuf                                 -- �G���[���b�Z�[�W
                            ,ov_retcode        => lv_retcode                                -- ���^�[���E�R�[�h
                            ,ov_errmsg         => lv_errmsg                                 -- ���[�U�[���b�Z�[�W 
                            ,iv_base_code      => sales_exp_main_rec.sales_base_code        -- ���_�R�[�h
                            ,iv_customer_code  => customer_main_rec.customer_code           -- �ڋq�R�[�h
                            ,iv_item_code      => sales_exp_main_rec.item_code              -- �i�ڃR�[�h
                            ,iv_container_type => sales_exp_main_rec.container_type         -- �e��敪�R�[�h
                            ,in_retail_amount  => sales_exp_main_rec.dlv_unit_price         -- ����
                            ,in_sales_amount   => sales_exp_main_rec.sales_amount           -- ������z(�ō�)
                            ,id_close_date     => lt_many_term( ln_term_cnt ).to_close_date -- ���ߓ�
                          );
                          -- �X�e�[�^�X�G���[����
                          IF ( lv_retcode = cv_status_error ) THEN
                            -- �x������̏��������ʗ�O��
                            RAISE global_process_expt;
                          END IF;
                          -- �̎�����G���[�������C���N�������g
                          gn_contract_cnt := gn_contract_cnt + cn_one;
                        ----------------------------------------------------------
                        -- ���������ʗ�O�n���h��
                        ----------------------------------------------------------
                        WHEN global_process_expt THEN
                          -- �x������̏��������ʗ�O��
                          RAISE global_process_expt;
                      END;
                      -- BM1�i����̎x�����j�Ŕ̎�����G���[�����������ꍇ�A�㑱�̎x������X�L�b�v����
                      IF ( gn_contract_cnt <> cn_zero ) THEN
                        -- �x������̔̎�����G���[��O��
                        RAISE contract_err_expt;
                      END IF;
                    ----------------------------------------------------------
                    -- �̎�̋��v�Z���[�v
                    ----------------------------------------------------------
                    END LOOP calculation_all_loop;
                  --***************************************************************************************************
                  -- �x������P�ʂ̏��� END
                  --***************************************************************************************************
                  EXCEPTION
                    ----------------------------------------------------------
                    -- �̎�����G���[��O�n���h��
                    ----------------------------------------------------------
                    WHEN contract_err_expt THEN
                      -- �̔����я��̃X�L�b�v��O��
                      RAISE sales_exp_err_expt;
                    ----------------------------------------------------------
                    -- ���������ʗ�O�n���h��
                    ----------------------------------------------------------
                    WHEN global_process_expt THEN
                      -- �̔����я��̏��������ʗ�O��
                      RAISE global_process_expt;
                  END;
                ----------------------------------------------------------
                -- �x�����񃋁[�v
                ----------------------------------------------------------
                END LOOP bm_vendor_all_loop;
                --=================================================
                -- A-17.�̔����јA�g���ʂ̍X�V�i�t���x���_�[�j
                -- A-35.�̔����јA�g���ʂ̍X�V�i�t���x���_�[�����j
                --=================================================
                -- �̎�̋��v�Z�I�������Ɩ����t�̏ꍇ�A
                -- �̎�����G���[���������Ă��Ȃ��ꍇ�͍X�V
                IF ( gv_sales_upd_flg = cv_yes ) AND
                   ( gn_contract_cnt = cn_zero ) THEN
                  -- �̔����јA�g���ʂ̍X�V
                  upd_sales_exp_lines_info(
                     ov_errbuf           => lv_errbuf                           -- �G���[���b�Z�[�W
                    ,ov_retcode          => lv_retcode                          -- ���^�[���E�R�[�h
                    ,ov_errmsg           => lv_errmsg                           -- ���[�U�[�E�G���[���b�Z�[�W 
                    ,iv_if_status        => cv_yes                              -- �萔���v�Z�C���^�t�F�[�X�σt���O
                    ,iv_customer_code    => customer_main_rec.customer_code     -- �ڋq�R�[�h
                    ,iv_invoice_num      => sales_exp_main_rec.invoice_num      -- �[�i�`�[�ԍ�
                    ,iv_invoice_line_num => sales_exp_main_rec.invoice_line_num -- �[�i���הԍ�
                  );
                END IF;
                -- �X�e�[�^�X�x������
                IF ( lv_retcode = cv_status_warn ) THEN
                  -- �̔����я��X�L�b�v
                  RAISE sales_exp_err_expt;
                -- �X�e�[�^�X�G���[����
                ELSIF ( lv_retcode = cv_status_error ) THEN
                  -- ���������ʃG���[
                  RAISE global_process_expt;
                END IF;
                -- �̎�����G���[�������N���A
                gn_contract_cnt := cn_zero;
              --*******************************************************************************************************
              -- �̔����я��P�ʂ̏��� END
              --*******************************************************************************************************
              EXCEPTION
                ----------------------------------------------------------
                -- �ڋq���X�L�b�v������O�n���h��
                ----------------------------------------------------------
                WHEN customer_err_expt THEN
                  -- �ڋq���̃X�L�b�v��O��
                  RAISE customer_err_expt;
                ----------------------------------------------------------
                -- �̔����я��X�L�b�v������O�n���h��
                ----------------------------------------------------------
                WHEN sales_exp_err_expt THEN
                  IF ( gn_contract_cnt <> cn_zero ) THEN
                    -- �̎�����G���[���������Z
                    gn_warning_cnt := gn_warning_cnt + gn_contract_cnt;
                  ELSE
                    -- �x���������C���N�������g
                    gn_warning_cnt := gn_warning_cnt + cn_one;
                  END IF;
                  -- �̎�����G���[�������N���A
                  gn_contract_cnt := cn_zero;
                ----------------------------------------------------------
                -- �̎�����G���[�i�v�Z�����W����擾���j��O�n���h��
                ----------------------------------------------------------
                WHEN contract_err_expt THEN
                  --=====================================================
                  -- A-16.�̎�����G���[�f�[�^�̓o�^�i�t���x���_�[�j
                  -- A-34.�̎�����G���[�f�[�^�̓o�^�i�t���x���_�[�����j
                  --=====================================================
                  ins_bm_contract_err_info(
                     ov_errbuf         => lv_errbuf                                 -- �G���[���b�Z�[�W
                    ,ov_retcode        => lv_retcode                                -- ���^�[���E�R�[�h
                    ,ov_errmsg         => lv_errmsg                                 -- ���[�U�[�E�G���[���b�Z�[�W 
                    ,iv_base_code      => sales_exp_main_rec.sales_base_code        -- ���_�R�[�h
                    ,iv_customer_code  => customer_main_rec.customer_code           -- �ڋq�R�[�h
                    ,iv_item_code      => sales_exp_main_rec.item_code              -- �i�ڃR�[�h
                    ,iv_container_type => sales_exp_main_rec.container_type         -- �e��敪�R�[�h
                    ,in_retail_amount  => sales_exp_main_rec.dlv_unit_price         -- ����
                    ,in_sales_amount   => sales_exp_main_rec.sales_amount           -- ������z(�ō�)
                    ,id_close_date     => lt_many_term( ln_term_cnt ).to_close_date -- ���ߓ�
                  );
                  -- �X�e�[�^�X�G���[����
                  IF ( lv_retcode = cv_status_error ) THEN
                    RAISE global_process_expt;
                  END IF;
                  -- �x���������C���N�������g
                  gn_warning_cnt := gn_warning_cnt + cn_one;
                ----------------------------------------------------------
                -- ���������ʗ�O�n���h��
                ----------------------------------------------------------
                WHEN global_process_expt THEN
                  -- �ڋq���̏��������ʗ�O��
                  RAISE global_process_expt;
              END;
            ----------------------------------------------------------
            -- �̔����уf�[�^���[�v
            ----------------------------------------------------------
            END LOOP sales_exp_main_loop;
            ----------------------------------------------------------
            -- �v�Z���ʓo�^����
            ----------------------------------------------------------
            -- �̔����т����݂��Ȃ��ꍇ�͏������s��Ȃ�
            IF ( lt_bm_support.COUNT <> cn_zero ) THEN
              --============================================================
              -- A-18.�O��̎�̋��v�Z���ʃf�[�^�̍폜�i�t���x���_�[�j
              -- A-36.�O��̎�̋��v�Z���ʃf�[�^�̍폜�i�t���x���_�[�����j
              --============================================================
              del_pre_bm_support_info(
                 ov_errbuf        => lv_errbuf                                 -- �G���[���b�Z�[�W
                ,ov_retcode       => lv_retcode                                -- ���^�[���E�R�[�h
                ,ov_errmsg        => lv_errmsg                                 -- ���[�U�[�E�G���[���b�Z�[�W 
                ,iv_customer_code => customer_main_rec.customer_code           -- �ڋq�R�[�h
                ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- ���ߓ�
              );
              -- �X�e�[�^�X�x������
              IF ( lv_retcode = cv_status_warn ) THEN
                -- �ڋq���X�L�b�v
                RAISE customer_err_expt;
              -- �X�e�[�^�X�G���[����
              ELSIF ( lv_retcode = cv_status_error ) THEN
                -- ���������ʃG���[
                RAISE global_process_expt;
              END IF;
              --==============================================================
              -- A-19.�̎�̋��v�Z�o�^���̕t�����ݒ�i�t���x���_�[�j
              -- A-37.�̎�̋��v�Z�o�^���̕t�����ݒ�i�t���x���_�[�����j
              --==============================================================
              << bm_support_all_loop >>
              FOR ln_vend_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                -------------------------------------------------
                -- �v�Z���ʑޔ�
                -------------------------------------------------
                -- ���_�R�[�h
                lt_bm_support( ln_vend_cnt ).base_code := sales_exp_main_rec.sales_base_code;
                -- �S���҃R�[�h
                lt_bm_support( ln_vend_cnt ).emp_code := sales_exp_main_rec.employee_code;
                -- �ڋq�y�[�i��z
                lt_bm_support( ln_vend_cnt ).delivery_cust_code := sales_exp_main_rec.ship_cust_code;
                -- �ڋq�y������z
                lt_bm_support( ln_vend_cnt ).demand_to_cust_code := lv_bill_cust_code;
                -- ��v�N�x
                lt_bm_support( ln_vend_cnt ).acctg_year := lv_period_year;
                -- �`�F�[���X�R�[�h
                lt_bm_support( ln_vend_cnt ).chain_store_code := customer_main_rec.del_chain_code;
                -- �[�i���N��
                lt_bm_support( ln_vend_cnt ).delivery_date :=
                  TO_CHAR( lt_many_term( ln_term_cnt ).to_close_date,cv_format2 );
                -- ����ŋ敪
                lt_bm_support( ln_vend_cnt ).tax_class := sales_exp_main_rec.con_tax_class;
                -- �ŋ��R�[�h
                lt_bm_support( ln_vend_cnt ).tax_code := sales_exp_main_rec.tax_code;
                -- ����ŗ�
                lt_bm_support( ln_vend_cnt ).tax_rate := sales_exp_main_rec.tax_rate;
                -- �x������
                lt_bm_support( ln_vend_cnt ).term_code := lt_many_term( ln_term_cnt ).to_term_name;
                -- ���ߓ�
                lt_bm_support( ln_vend_cnt ).closing_date := lt_many_term( ln_term_cnt ).to_close_date;
                -- �x���\���
                lt_bm_support( ln_vend_cnt ).expect_payment_date := ld_pay_work_date;
                -- �v�Z�Ώۊ���(From)�{�P��
                ld_period_fm_date := lt_many_term( ln_term_cnt ).fm_close_date + cn_one;
                lt_bm_support( ln_vend_cnt ).calc_period_from := ld_period_fm_date; 
                -- �v�Z�Ώۊ���(To)
                lt_bm_support( ln_vend_cnt ).calc_period_to := lt_many_term( ln_term_cnt ).to_close_date;
                -- �t���x���_�[�̏ꍇ
                IF ( lv_vend_type = cv_vendor_type1 ) THEN
                  -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)
                  lt_bm_support( ln_vend_cnt ).cond_bm_if_status := cv_if_status0;
                  -- �A�g��(�����ʔ̎�̋�)
                  lt_bm_support( ln_vend_cnt ).cond_bm_if_date := NULL;
                  -- �A�g�X�e�[�^�X(�̎�c��)
                  lt_bm_support( ln_vend_cnt ).bm_interface_status := cv_if_status0;
                  -- �A�g��(�̎�c��)
                  lt_bm_support( ln_vend_cnt ).bm_interface_date := NULL;
                  -- �A�g�X�e�[�^�X(AR)
                  lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status2;
                  -- �A�g��(AR)
                  lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
                -- �t���x���_�[�����̏ꍇ
                ELSIF ( lv_vend_type = cv_vendor_type2 ) THEN
                  -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)
                  lt_bm_support( ln_vend_cnt ).cond_bm_if_status := cv_if_status2;
                  -- �A�g��(�����ʔ̎�̋�)
                  lt_bm_support( ln_vend_cnt ).cond_bm_if_date := NULL;
                  -- �A�g�X�e�[�^�X(�̎�c��)
                  lt_bm_support( ln_vend_cnt ).bm_interface_status := cv_if_status2;
                  -- �A�g��(�̎�c��)
                  lt_bm_support( ln_vend_cnt ).bm_interface_date := NULL;
                  -- �̎�̋��v�Z�I�������Ɩ����t�̏ꍇ
                  IF ( gv_sales_upd_flg = cv_yes ) THEN
                    -- �x���敪���d�C���̏ꍇ
                    IF ( lt_bm_support( ln_vend_cnt ).bm_type = cv_en1_type ) THEN
                      -- �A�g�X�e�[�^�X(AR)
                      lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status2;
                      -- �A�g��(AR)
                      lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
                    ELSE
                      -- �A�g�X�e�[�^�X(AR)
                      lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status0;
                      -- �A�g��(AR)
                      lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
                    END IF;
                  -- �̎�̋��v�Z�I�������Ɩ����t�łȂ��ꍇ
                  ELSE
                    -- �A�g�X�e�[�^�X(AR)
                    lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status2;
                    -- �A�g��(AR)
                    lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
                  END IF;
                END IF;
              END LOOP bm_support_all_loop;
              --=========================================================
              -- A-20.�����ʔ̎�̋��v�Z�f�[�^�̓o�^�i�t���x���_�[�j
              -- A-38.�����ʔ̎�̋��v�Z�f�[�^�̓o�^�i�t���x���_�[�����j
              --=========================================================
              ins_bm_support_info(
                 ov_errbuf        => lv_errbuf                                 -- �G���[���b�Z�[�W
                ,ov_retcode       => lv_retcode                                -- ���^�[���E�R�[�h
                ,ov_errmsg        => lv_errmsg                                 -- ���[�U�[�E�G���[���b�Z�[�W 
                ,iv_vendor_type   => lv_vend_type                              -- �x���_�[�敪
                ,id_fm_close_date => lt_many_term( ln_term_cnt ).fm_close_date -- �O����ߓ�
                ,id_to_close_date => lt_many_term( ln_term_cnt ).to_close_date -- ������ߓ�
                ,it_bm_support    => lt_bm_support                             -- �̎�̋��v�Z�o�^���
              );
              -- �X�e�[�^�X�G���[����
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
              -- ���폈�������֓o�^�ɐ����������������Z
              gn_normal_cnt := gn_normal_cnt + lt_bm_support.COUNT;
            END IF;
          -------------------------------------------------
          -- �����x���������[�v
          -------------------------------------------------
          END LOOP many_term_all_loop;
          -------------------------------------------------
          -- COMMIT����
          -------------------------------------------------
          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
            -- �ڋq�P�ʂ�COMMIT
            COMMIT;
          END IF;
          -------------------------------------------------
        --*************************************************************************************************************
        -- �ڋq���P�ʂ̏��� END
        --*************************************************************************************************************
        EXCEPTION
          ----------------------------------------------------------
          -- �ڋq���X�L�b�v�����i�����ΏۊO�ڋq�j��O�n���h��
          ----------------------------------------------------------
          WHEN customer_chk_expt THEN
            -- �ڋq�����X�L�b�v
            NULL;
          ----------------------------------------------------------
          -- �ڋq���X�L�b�v������O�n���h��
          ----------------------------------------------------------
          WHEN customer_err_expt THEN
            -- �x���������C���N�������g
            gn_warning_cnt := gn_warning_cnt + cn_one;
          ----------------------------------------------------------
          -- ���������ʗ�O�n���h��
          ----------------------------------------------------------
          WHEN global_process_expt THEN
            -- submain�̏��������ʗ�O��
            RAISE global_process_expt;
        END;
      ----------------------------------------------------------
      -- �ڋq��񃋁[�v
      ----------------------------------------------------------
      END LOOP customer_main_loop2;
    ----------------------------------------------------------
    -- �t���x���_�[��񃋁[�v
    ----------------------------------------------------------
    END LOOP full_vendor_loop;
    --*****************************************************************************************************************
    -- ��ʐؑ֎��ϐ�����������
    --*****************************************************************************************************************
    ln_term_cnt := 0;     -- �x�������J�E���^
    ln_calc_cnt := 0;     -- �v�Z�����J�E���^
    ln_vend_cnt := 0;     -- �d����J�E���^
    ln_pay_cnt  := 0;     -- �x����J�E���^
    ln_sale_cnt := 0;     -- �̔����у��[�v�J�E���^
    lv_el_flg1  := cv_no; -- �d�C��(�Œ�)�Z�o�σt���O
    lv_el_flg2  := cv_no; -- �d�C��(�ϓ�)�Z�o�σt���O
    -- �^�C�v��`
    lv_bill_cust_code := NULL; -- ������ڋq�R�[�h
    ld_pay_work_date  := NULL; -- �c�Ɠ����l�������x����
    ld_period_fm_date := NULL; -- �v�Z�Ώۊ���(From)
    lv_period_year    := NULL; -- ��v�N�x
    ln_bm_pct         := NULL; -- ���ߗ�
    ln_bm_amt         := NULL; -- ���ߊz
    ln_bm_amount      := NULL; -- �̔��萔��
    ln_bm_amount_tax  := NULL; -- �̔��萔������Ŋz
    ln_el_amount      := NULL; -- �d�C��
    ln_el_amount_tax  := NULL; -- �d�C������Ŋz
    -- �O���[�o���ϐ�
    gn_contract_cnt   := 0;    -- �̎�����G���[����
    gv_sales_upd_flg  := NULL; -- �̔����эX�V�t���O
    -- �e�[�u���^��`
    lt_many_term.DELETE;   -- �����x������
    lt_calculation.DELETE; -- �v�Z����
    lt_bm_vendor.DELETE;   -- �x������
    lt_bm_support.DELETE;  -- �̎�v�Z���
    -- �J�[�\���N���[�Y
    IF ( customer_main_cur%ISOPEN ) THEN
      CLOSE customer_main_cur;
    END IF;
    IF ( sales_exp_main_cur%ISOPEN  ) THEN
      CLOSE sales_exp_main_cur;
    END IF;
    --===============================================
    -- A-39.�ڋq�f�[�^�̎擾�i��ʁj
    --===============================================
    OPEN customer_ip_main_cur(
       iv_proc_type  -- ���s�敪
      ,gn_pro_org_id -- �g�DID
      ,gv_language   -- ����
    );
    << customer_main_loop3 >>
    LOOP
      FETCH customer_ip_main_cur INTO customer_ip_main_rec;
      EXIT WHEN customer_ip_main_cur%NOTFOUND;
      --***************************************************************************************************************
      -- �ڋq���P�ʂ̏��� START
      --***************************************************************************************************************
      BEGIN
        -------------------------------------------------
        -- ��������
        -------------------------------------------------
        -- �ڋq�̌������C���N�������g
        gn_customer_cnt := gn_customer_cnt + cn_one;
        -- �̔����у��[�v������
        ln_sale_cnt := 0;
        -- �̎�����v�Z�z��|�C���^������
        ln_sup_cnt := 0;
        -- �̔����эX�V�s�v
        gv_sales_upd_flg := cv_no;
        -- �d�C��(�ϓ�)���Z�o
        lv_el_flg2 := cv_no;
        -- �̎�����v�Z���ʔz�񏉊���
        lt_bm_support.DELETE;
        -- �����x�������z�񏉊���
        lt_many_term.DELETE;   
        -- �̔����уJ�[�\���N���[�Y
        IF ( sales_exp_ip_main_cur%ISOPEN ) THEN
          CLOSE sales_exp_ip_main_cur;
        END IF;
        --===============================================
        -- A-40.�����Ώیڋq�f�[�^�̔��f�i��ʁj
        --===============================================
        chk_customer_info(
           ov_errbuf         => lv_errbuf                          -- �G���[���b�Z�[�W
          ,ov_retcode        => lv_retcode                         -- ���^�[���E�R�[�h
          ,ov_errmsg         => lv_errmsg                          -- ���[�U�[�E�G���[���b�Z�[�W 
          ,iv_vendor_type    => cv_vendor_type3                    -- �x���_�[�敪�F���
          ,iv_customer_code  => customer_ip_main_rec.customer_code -- �ڋq�R�[�h
          ,ov_bill_cust_code => lv_bill_cust_code                  -- ������ڋq�R�[�h
          ,ot_many_term      => lt_many_term                       -- �����x������
        );
        -- �����ΏۊO�ڋq����
        IF ( lv_retcode = cv_customer_err ) THEN
          -- �ڋq���X�L�b�v
          RAISE customer_chk_expt;
        -- �X�e�[�^�X�x������
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- �ڋq���X�L�b�v
          RAISE customer_err_expt;
        -- �X�e�[�^�X�G���[����
        ELSIF ( lv_retcode = cv_status_error ) THEN
          -- ���������ʃG���[
          RAISE global_process_expt;
        END IF;
        -------------------------------------------------
        -- �����x���������[�v
        -------------------------------------------------
        << many_term_all_loop >>
        FOR ln_term_cnt IN lt_many_term.FIRST..lt_many_term.LAST LOOP
          -------------------------------------------------
          -- ��������
          -------------------------------------------------
          -- �̔����у��[�v������
          ln_sale_cnt := 0;
          -- �̎�����v�Z�z��|�C���^������
          ln_sup_cnt := 0;
          -- �̔����эX�V�s�v
          gv_sales_upd_flg := cv_no;
          -- �d�C��(�ϓ�)���Z�o
          lv_el_flg2 := cv_no;
          -- �̎�����v�Z���ʔz�񏉊���
          lt_bm_support.DELETE;
          -- �̔����уJ�[�\���N���[�Y
          IF ( sales_exp_ip_main_cur%ISOPEN ) THEN
            CLOSE sales_exp_ip_main_cur;
          END IF;
          -------------------------------------------------
          -- �̎�̋��v�Z�I�������Ɩ����t����
          -------------------------------------------------
          IF ( lt_many_term( ln_term_cnt ).end_date = gd_proc_date ) THEN
            -- �̔����эX�V�v
            gv_sales_upd_flg := cv_yes;
          END IF;
          --=================================================
          -- A-41.�̎�̋��v�Z�t�����̎擾�i��ʁj
          --=================================================
          get_bm_support_add_info(
             ov_errbuf        => lv_errbuf                               -- �G���[���b�Z�[�W
            ,ov_retcode       => lv_retcode                              -- ���^�[���E�R�[�h
            ,ov_errmsg        => lv_errmsg                               -- ���[�U�[�E�G���[���b�Z�[�W 
            ,iv_vendor_type   => cv_vendor_type3                         -- �x���_�[�敪�F���
            ,iv_customer_code => customer_ip_main_rec.customer_code      -- �ڋq�R�[�h
            ,id_pay_date      => lt_many_term( ln_term_cnt ).to_pay_date -- ����x����
            ,od_pay_work_date => ld_pay_work_date                        -- �x���\���
            ,ov_period_year   => lv_period_year                          -- ��v�N�x
          );
          -- �X�e�[�^�X�G���[����
          IF ( lv_retcode = cv_status_warn ) THEN
            -- �ڋq���X�L�b�v
            RAISE customer_err_expt;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            -- ���������ʃG���[
            RAISE global_process_expt;
          END IF;
          --===============================================
          -- A-42.�̔����уf�[�^�̎擾�i��ʁj
          --===============================================
          OPEN sales_exp_ip_main_cur(
             lt_many_term( ln_term_cnt ).to_close_date -- ���ߓ��F������ߓ�
            ,customer_ip_main_rec.customer_code        -- �ڋq�R�[�h
            ,gv_language                               -- ����
          );
          << sales_exp_main_loop >>
          LOOP
            FETCH sales_exp_ip_main_cur INTO sales_exp_ip_main_rec;
            EXIT WHEN sales_exp_ip_main_cur%NOTFOUND;
            --*********************************************************************************************************
            -- �̔����я��P�ʂ̏��� START
            --*********************************************************************************************************
            BEGIN
              -------------------------------------------------
              -- ��������
              -------------------------------------------------
              -- �Ώی����C���N�������g
              gn_target_cnt := gn_target_cnt + cn_one;
              -- �̔����у��[�v�C���N�������g
              ln_sale_cnt := ln_sale_cnt + cn_one;
              -- �`�F�b�N�p�t���O������
              ln_row_flg := cn_zero;
              --===============================================
              -- A-43.�l���z�̌v�Z�i��ʁj
              --===============================================
              -- �i�ڂ��d�C���i�ϓ��j�ȊO�������l�������ݒ肳��Ă���ڋq�̂�
              IF ( customer_ip_main_rec.discount_rate <> cn_zero ) AND
                 ( sales_exp_ip_main_rec.item_code <> gv_pro_elec_ch ) THEN
                -------------------------------------------------
                -- �����l���z�v�Z����
                -------------------------------------------------
                cal_bm_contract60_info(
                   ov_errbuf        => lv_errbuf                                 -- �G���[���b�Z�[�W
                  ,ov_retcode       => lv_retcode                                -- ���^�[���E�R�[�h
                  ,ov_errmsg        => lv_errmsg                                 -- ���[�U�[�E�G���[���b�Z�[�W 
                  ,iv_customer_code => customer_ip_main_rec.customer_code        -- �ڋq�R�[�h
                  ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- ���ߓ��F������ߓ�
                  ,in_sale_amount   => sales_exp_ip_main_rec.sales_amount        -- ������z
                  ,in_tax_rate      => sales_exp_ip_main_rec.tax_rate            -- ����ŗ�
                  ,in_discount_rate => customer_ip_main_rec.discount_rate        -- �����l����
                  ,on_rc_amount     => ln_rc_amount                              -- �����l���z
                  ,on_rc_amount_tax => ln_rc_amount_tax                          -- �����l������Ŋz
                );
                -- �̎�����G���[����
                IF ( lv_retcode = cv_contract_err ) THEN
                  RAISE contract_err_expt;
                -- �X�e�[�^�X�G���[����
                ELSIF ( lv_retcode = cv_status_error ) THEN
                  RAISE global_process_expt;
                END IF;
                ----------------------------------------------------------
                -- �z�񑶍݃`�F�b�N
                ----------------------------------------------------------
                IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                  ln_row_flg := cn_one;
                END IF;
                ----------------------------------------------------------
                -- �l���z�x���敪���݃`�F�b�N���[�v
                ----------------------------------------------------------
                IF ( ln_row_flg = cn_one ) THEN
                  << bm_rcpt_type60_chk_loop >>
                  FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                    -- �x���敪����v����ꍇ�͈�v�������_�̔z�񍀖ڂɗݐς���
                    IF ( lt_bm_support( ln_chk_cnt ).bm_type = cv_bm1_type ) THEN
                      -- ���������L��
                      ln_row_flg := cn_two;
                      -- ���݂̔z��֗ݐ�
                      ln_sup_cnt := ln_chk_cnt;
                      -- ���[�vEXIT
                      EXIT;
                    END IF;
                  END LOOP bm_rcpt_type60_chk_loop;
                END IF;
                ----------------------------------------------------------
                -- �z��ݒ�
                ----------------------------------------------------------
                -- ������s��
                IF ( ln_row_flg = cn_zero ) THEN
                  -- �z�񏉊��l�Z�b�g
                  ln_sup_cnt := cn_zero;
                -- ��v���Ȃ��ꍇ
                ELSIF ( ln_row_flg = cn_one ) THEN
                  -- �z����g��
                  ln_sup_cnt := lt_bm_support.LAST + 1;
                END IF;
                -------------------------------------------------
                -- �v�Z���ʑޔ�
                -------------------------------------------------
                -- �x���敪�FBM1
                lt_bm_support( ln_sup_cnt ).bm_type := cv_bm1_type;
                -- �d����_�~�[�R�[�h
                lt_bm_support( ln_sup_cnt ).supplier_code := gv_pro_vendor;
                -- �d����T�C�g�_�~�[�R�[�h
                lt_bm_support( ln_sup_cnt ).supplier_site_code := gv_pro_vendor_s;
                -- �v�Z����
                lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type60;
                -- �[�i����
                lt_bm_support( ln_sup_cnt ).delivery_qty :=
                  NVL( lt_bm_support( ln_sup_cnt ).delivery_qty,cn_zero ) +
                    sales_exp_ip_main_rec.dlv_quantity;
                -- �[�i�P��
                lt_bm_support( ln_sup_cnt ).delivery_unit_type := sales_exp_ip_main_rec.dlv_uom_code;
                -- ������z
                lt_bm_support( ln_sup_cnt ).selling_amt_tax :=
                  NVL( lt_bm_support( ln_sup_cnt ).selling_amt_tax,cn_zero ) +
                    sales_exp_ip_main_rec.sales_amount;
                -- �����l���z
                lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt :=
                  NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt,cn_zero ) +
                    ln_rc_amount;
                -- �����l������Ŋz
                lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax :=
                  NVL( lt_bm_support( ln_sup_cnt ).csh_rcpt_dis_amt_tax,cn_zero ) +
                    ln_rc_amount_tax;
              --===============================================
              -- A-44.�d�C���i�ϓ��j�̌v�Z�i��ʁj
              --===============================================
              -- �i�ڂ��d�C���i�ϓ��j�̏ꍇ
              ELSIF ( sales_exp_ip_main_rec.item_code = gv_pro_elec_ch ) THEN
                ----------------------------------------------------------
                -- �z�񑶍݃`�F�b�N
                ----------------------------------------------------------
                IF ( lt_bm_support.COUNT <> cn_zero ) THEN
                  ln_row_flg := cn_one;
                END IF;
                ----------------------------------------------------------
                -- �d�C���x���敪���݃`�F�b�N���[�v
                ----------------------------------------------------------
                IF ( ln_row_flg = cn_one ) THEN
                  << bm_rcpt_type50_chk_loop >>
                  FOR ln_chk_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
                    -- �x���敪����v����ꍇ�͈�v�������_�̔z�񍀖ڂɗݐς���
                    IF ( lt_bm_support( ln_chk_cnt ).bm_type = cv_en1_type ) THEN
                      -- ���������L��
                      ln_row_flg := cn_two;
                      -- ���݂̔z��֗ݐ�
                      ln_sup_cnt := ln_chk_cnt;
                      -- ���[�vEXIT
                      EXIT;
                    END IF;
                  END LOOP bm_rcpt_type50_chk_loop;
                END IF;
                ----------------------------------------------------------
                -- �z��ݒ�
                ----------------------------------------------------------
                -- ������s��
                IF ( ln_row_flg = cn_zero ) THEN
                  -- �z�񏉊��l�Z�b�g
                  ln_sup_cnt := cn_zero;
                -- ��v���Ȃ��ꍇ
                ELSIF ( ln_row_flg = cn_one ) THEN
                  -- �z����g��
                  ln_sup_cnt := lt_bm_support.LAST + 1;
                END IF;
                -------------------------------------------------
                -- �v�Z���ʑޔ�
                -------------------------------------------------
                -- �x���敪�FEN1
                lt_bm_support( ln_sup_cnt ).bm_type := cv_en1_type;
                -- �d����_�~�[�R�[�h
                lt_bm_support( ln_sup_cnt ).supplier_code := gv_pro_vendor;
                -- �d����T�C�g�_�~�[�R�[�h
                lt_bm_support( ln_sup_cnt ).supplier_site_code := gv_pro_vendor_s;
                -- �v�Z����
                lt_bm_support( ln_sup_cnt ).calc_type := cv_cal_type50;
                -- ������z
                lt_bm_support( ln_sup_cnt ).selling_amt_tax := cn_zero;
                -- �d�C��(�ō�)
                lt_bm_support( ln_sup_cnt ).electric_amt_tax :=
                  NVL( lt_bm_support( ln_sup_cnt ).electric_amt_tax,cn_zero ) +
                    sales_exp_ip_main_rec.sales_amount;
                -- �d�C��(�Ŕ�)
                lt_bm_support( ln_sup_cnt ).electric_amt_no_tax :=
                  NVL( lt_bm_support( ln_sup_cnt ).electric_amt_no_tax,cn_zero ) +
                    sales_exp_ip_main_rec.body_amount;
                -- �d�C������Ŋz
                lt_bm_support( ln_sup_cnt ).electric_tax_amt :=
                  NVL( lt_bm_support( ln_sup_cnt ).electric_tax_amt,cn_zero ) +
                    sales_exp_ip_main_rec.tax_amount;
                -- �d�C��(�ϓ�)�Z�o��
                lv_el_flg2 := cv_yes;
              END IF;
              --===============================================
              -- A-45.�̔����јA�g���ʂ̍X�V�i��ʁj
              --===============================================
              -- �̎�̋��v�Z�I�������Ɩ����t�̏ꍇ�͍X�V
              IF ( gv_sales_upd_flg = cv_yes ) THEN
                -- �����l�������ݒ肳��Ă���܂���
                -- �����l�������ݒ肳�ꂸ�A�ϓ��d�C���̌v�Z���s��ꂽ�ꍇ
                IF ( customer_ip_main_rec.discount_rate <> cn_zero ) OR
                   ( (customer_ip_main_rec.discount_rate = cn_zero ) AND ( lv_el_flg2 = cv_yes ) ) THEN
                  -- �̔����јA�g���ʍX�V
                  upd_sales_exp_lines_info(
                     ov_errbuf           => lv_errbuf                              -- �G���[���b�Z�[�W
                    ,ov_retcode          => lv_retcode                             -- ���^�[���E�R�[�h
                    ,ov_errmsg           => lv_errmsg                              -- ���[�U�[�E�G���[���b�Z�[�W
                    ,iv_if_status        => cv_yes                                 -- �萔���v�Z�C���^�t�F�[�X�σt���O
                    ,iv_customer_code    => customer_ip_main_rec.customer_code     -- �ڋq�R�[�h
                    ,iv_invoice_num      => sales_exp_ip_main_rec.invoice_num      -- �[�i�`�[�ԍ�
                    ,iv_invoice_line_num => sales_exp_ip_main_rec.invoice_line_num -- �[�i���הԍ�
                  );
                -- �����l�������ݒ肳��Ă��Ȃ��ꍇ
                ELSE
                  -- �̔����јA�g�s�v�X�V
                  upd_sales_exp_lines_info(
                     ov_errbuf           => lv_errbuf                              -- �G���[���b�Z�[�W
                    ,ov_retcode          => lv_retcode                             -- ���^�[���E�R�[�h
                    ,ov_errmsg           => lv_errmsg                              -- ���[�U�[�E�G���[���b�Z�[�W
                    ,iv_if_status        => cv_yes                                 -- �萔���v�Z�C���^�t�F�[�X�σt���O
                    ,iv_customer_code    => customer_ip_main_rec.customer_code     -- �ڋq�R�[�h
                    ,iv_invoice_num      => sales_exp_ip_main_rec.invoice_num      -- �[�i�`�[�ԍ�
                    ,iv_invoice_line_num => sales_exp_ip_main_rec.invoice_line_num -- �[�i���הԍ�
                  );
                END IF;
                -- �X�e�[�^�X�x������
                IF ( lv_retcode = cv_status_warn ) THEN
                  -- �̔����я��X�L�b�v
                  RAISE sales_exp_err_expt;
                -- �X�e�[�^�X�G���[����
                ELSIF ( lv_retcode = cv_status_error ) THEN
                  -- ���������ʃG���[
                  RAISE global_process_expt;
                END IF;
              END IF;
            --*********************************************************************************************************
            -- �̔����я��P�ʂ̏��� END
            --*********************************************************************************************************
            EXCEPTION
              ----------------------------------------------------------
              -- �ڋq���X�L�b�v������O�n���h��
              ----------------------------------------------------------
              WHEN customer_err_expt THEN
                -- �ڋq���̃X�L�b�v��O��
                RAISE customer_err_expt;
              ----------------------------------------------------------
              -- �̔����я��X�L�b�v������O�n���h��
              ----------------------------------------------------------
              WHEN sales_exp_err_expt THEN
                -- �x���������C���N�������g
                gn_warning_cnt := gn_warning_cnt + cn_one;
              ----------------------------------------------------------
              -- ���������ʗ�O�n���h��
              ----------------------------------------------------------
              WHEN global_process_expt THEN
                -- �ڋq���̏��������ʗ�O��
                RAISE global_process_expt;
            END;
          ----------------------------------------------------------
          -- �̔����уf�[�^���[�v
          ----------------------------------------------------------
          END LOOP sales_exp_main_loop;
          ----------------------------------------------------------
          -- �v�Z���ʓo�^����
          ----------------------------------------------------------
          -- �̔����т����݂��Ȃ��ꍇ�͏������s��Ȃ�
          IF ( lt_bm_support.COUNT <> cn_zero ) THEN
            --========================================================
            -- A-46.�O��̎�̋��v�Z���ʃf�[�^�̍폜�i��ʁj
            --========================================================
            -- �O��̎�̋��v�Z���ʃf�[�^�̍폜
            del_pre_bm_support_info(
               ov_errbuf        => lv_errbuf                                 -- �G���[���b�Z�[�W
              ,ov_retcode       => lv_retcode                                -- ���^�[���E�R�[�h
              ,ov_errmsg        => lv_errmsg                                 -- ���[�U�[�E�G���[���b�Z�[�W 
              ,iv_customer_code => customer_ip_main_rec.customer_code        -- �ڋq�R�[�h
              ,id_close_date    => lt_many_term( ln_term_cnt ).to_close_date -- ���ߓ�
            );
            -- �X�e�[�^�X�x������
            IF ( lv_retcode = cv_status_warn ) THEN
              -- �ڋq���X�L�b�v
              RAISE customer_err_expt;
            -- �X�e�[�^�X�G���[����
            ELSIF ( lv_retcode = cv_status_error ) THEN
              -- ���������ʃG���[
              RAISE global_process_expt;
            END IF;
            --=========================================================
            -- A-47.�̎�̋��v�Z�o�^���̕t�����ݒ�i��ʁj
            --=========================================================
            << bm_support_all_loop >>
            FOR ln_vend_cnt IN lt_bm_support.FIRST..lt_bm_support.LAST LOOP
              -------------------------------------------------
              -- �v�Z���ʑޔ�
              -------------------------------------------------
              -- ���_�R�[�h
              lt_bm_support( ln_vend_cnt ).base_code := sales_exp_ip_main_rec.sales_base_code;
              -- �S���҃R�[�h
              lt_bm_support( ln_vend_cnt ).emp_code := sales_exp_ip_main_rec.employee_code;
              -- �ڋq�y�[�i��z
              lt_bm_support( ln_vend_cnt ).delivery_cust_code := sales_exp_ip_main_rec.ship_cust_code;
              -- �ڋq�y������z
              lt_bm_support( ln_vend_cnt ).demand_to_cust_code := lv_bill_cust_code;
              -- ��v�N�x
              lt_bm_support( ln_vend_cnt ).acctg_year := lv_period_year;
              -- �`�F�[���X�R�[�h
              lt_bm_support( ln_vend_cnt ).chain_store_code := customer_ip_main_rec.del_chain_code;
              -- �[�i���N��
              lt_bm_support( ln_vend_cnt ).delivery_date :=
                TO_CHAR( lt_many_term( ln_term_cnt ).to_close_date,cv_format2 );
              -- ����ŋ敪
              lt_bm_support( ln_vend_cnt ).tax_class := sales_exp_ip_main_rec.con_tax_class;
              -- �ŋ��R�[�h
              lt_bm_support( ln_vend_cnt ).tax_code := sales_exp_ip_main_rec.tax_code;
              -- ����ŗ�
              lt_bm_support( ln_vend_cnt ).tax_rate := sales_exp_ip_main_rec.tax_rate;
              -- �x������
              lt_bm_support( ln_vend_cnt ).term_code := lt_many_term( ln_term_cnt ).to_term_name;
              -- ���ߓ�
              lt_bm_support( ln_vend_cnt ).closing_date := lt_many_term( ln_term_cnt ).to_close_date;
              -- �x���\���
              lt_bm_support( ln_vend_cnt ).expect_payment_date := ld_pay_work_date;
              -- �v�Z�Ώۊ���(From)�{�P��
              ld_period_fm_date := lt_many_term( ln_term_cnt ).fm_close_date + cn_one;
              lt_bm_support( ln_vend_cnt ).calc_period_from := ld_period_fm_date; 
              -- �v�Z�Ώۊ���(To)
              lt_bm_support( ln_vend_cnt ).calc_period_to := lt_many_term( ln_term_cnt ).to_close_date;
              -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)
              lt_bm_support( ln_vend_cnt ).cond_bm_if_status := cv_if_status2;
              -- �A�g��(�����ʔ̎�̋�)
              lt_bm_support( ln_vend_cnt ).cond_bm_if_date := NULL;
              -- �A�g�X�e�[�^�X(�̎�c��)
              lt_bm_support( ln_vend_cnt ).bm_interface_status := cv_if_status2;
              -- �A�g��(�̎�c��)
              lt_bm_support( ln_vend_cnt ).bm_interface_date := NULL;
              -- �̎�̋��v�Z�I�������Ɩ����t�̏ꍇ
              IF ( gv_sales_upd_flg = cv_yes ) THEN
                -- �x���敪���d�C���̏ꍇ
                IF ( lt_bm_support( ln_vend_cnt ).bm_type = cv_en1_type ) THEN
                  -- �A�g�X�e�[�^�X(AR)
                  lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status2;
                  -- �A�g��(AR)
                  lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
                ELSE
                  -- �A�g�X�e�[�^�X(AR)
                  lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status0;
                  -- �A�g��(AR)
                  lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
                END IF;
              -- �̎�̋��v�Z�I�������Ɩ����t�łȂ��ꍇ
              ELSE
                -- �A�g�X�e�[�^�X(AR)
                lt_bm_support( ln_vend_cnt ).ar_interface_status := cv_if_status2;
                -- �A�g��(AR)
                lt_bm_support( ln_vend_cnt ).ar_interface_date := NULL;
              END IF;
            END LOOP bm_support_all_loop;
            --=====================================================
            -- A-48.�����ʔ̎�̋��v�Z�f�[�^�̓o�^�i��ʁj
            --=====================================================
            ins_bm_support_info(
               ov_errbuf        => lv_errbuf                                 -- �G���[���b�Z�[�W
              ,ov_retcode       => lv_retcode                                -- ���^�[���E�R�[�h
              ,ov_errmsg        => lv_errmsg                                 -- ���[�U�[�E�G���[���b�Z�[�W 
              ,iv_vendor_type   => cv_vendor_type1                           -- �x���_�[�敪�F���
              ,id_fm_close_date => lt_many_term( ln_term_cnt ).fm_close_date -- �O����ߓ�
              ,id_to_close_date => lt_many_term( ln_term_cnt ).to_close_date -- ������ߓ�
              ,it_bm_support    => lt_bm_support                             -- �̎�̋��v�Z�o�^���
            );
            -- �X�e�[�^�X�G���[����
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
            -- ���폈���������C���N�������g
            gn_normal_cnt := gn_normal_cnt + lt_bm_support.COUNT;
          END IF;
        -------------------------------------------------
        -- �����x���������[�v
        -------------------------------------------------
        END LOOP many_term_all_loop;
        -------------------------------------------------
        -- COMMIT����
        -------------------------------------------------
        IF ( lt_bm_support.COUNT <> cn_zero ) THEN
          -- �ڋq�P�ʂ�COMMIT
          COMMIT;
        END IF;
      --***************************************************************************************************************
      -- �ڋq���P�ʂ̏��� END
      --***************************************************************************************************************
      EXCEPTION
        ----------------------------------------------------------
        -- �ڋq���X�L�b�v�����i�����ΏۊO�ڋq�j��O�n���h��
        ----------------------------------------------------------
        WHEN customer_chk_expt THEN
          -- �ڋq�����X�L�b�v
          NULL;
        ----------------------------------------------------------
        -- �ڋq���X�L�b�v������O�n���h��
        ----------------------------------------------------------
        WHEN customer_err_expt THEN
          -- �x���������C���N�������g
          gn_warning_cnt := gn_warning_cnt + cn_one;
        ----------------------------------------------------------
        -- ���������ʗ�O�n���h��
        ----------------------------------------------------------
        WHEN global_process_expt THEN
          -- submain�̏��������ʗ�O��
          RAISE global_process_expt;
      END;
    ----------------------------------------------------------
    -- �ڋq��񃋁[�v
    ----------------------------------------------------------
    END LOOP customer_main_loop3;
    --=====================================================
    -- �I������
    --=====================================================
    -- �x�����������Ă���ꍇ
    IF ( gn_warning_cnt <> cn_zero ) THEN
      -- �x���I��
      ov_retcode := cv_status_warn;
    ELSE
      -- ����I��
      ov_retcode := cv_status_normal;
    END IF;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      IF ( lv_errmsg IS NULL ) THEN
        -- ���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_00100
                        ,iv_token_name1  => cv_tkn_errmsg
                        ,iv_token_value1 => SUBSTRB( SQLERRM,1,5000 )
                      );
        -- ���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- �o�͋敪
                        ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line => cn_zero         -- ���s
                      );
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
        ov_retcode := cv_status_error;
      ELSE
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
        ov_retcode := cv_status_error;
      END IF;
      -- �G���[�������C���N�������g
      gn_error_cnt := gn_error_cnt + cn_one;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      IF ( lv_errmsg IS NULL ) THEN
        -- ���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_00101
                        ,iv_token_name1  => cv_tkn_errmsg
                        ,iv_token_value1 => SUBSTRB( SQLERRM,1,5000 )
                      );
        -- ���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- �o�͋敪
                        ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line => cn_zero         -- ���s
                      );
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
      ELSE
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
      END IF;
      -- �G���[�������C���N�������g
      gn_error_cnt := gn_error_cnt + cn_one;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      IF ( lv_errmsg IS NULL ) THEN
        -- ���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_prmmsg_00100
                        ,iv_token_name1  => cv_tkn_errmsg
                        ,iv_token_value1 => SUBSTRB( SQLERRM,1,5000 )
                      );
        -- ���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    => fnd_file.output -- �o�͋敪
                        ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line => cn_zero         -- ���s
                      );
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
      ELSE
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
        ov_retcode := cv_status_error;
      END IF;
      -- �G���[�������C���N�������g
      gn_error_cnt := gn_error_cnt + cn_one;
  --
  END submain;
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
     errbuf       OUT VARCHAR2 -- �G���[���b�Z�[�W
    ,retcode      OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,iv_proc_date IN  VARCHAR2 -- �Ɩ����t
    ,iv_proc_type IN  VARCHAR2 -- ���s�敪
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf  VARCHAR2(5000); -- �G���[���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[���b�Z�[�W
    lv_out_msg VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode BOOLEAN;        -- ���b�Z�[�W�߂�l
    -- ���b�Z�[�W�ޔ�
    lv_message_code VARCHAR2(5000); -- �����I�����b�Z�[�W
  --
  BEGIN
  --
    --===============================================
    -- ������
    --===============================================
    lv_out_msg := NULL;
    --===============================================
    -- �R���J�����g�w�b�_�o��
    --===============================================
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --===============================================
    -- �T�u���C������
    --===============================================
    submain(
       ov_errbuf    => lv_errbuf    -- �G���[���b�Z�[�W
      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[���b�Z�[�W
      ,iv_proc_date => iv_proc_date -- �Ɩ����t
      ,iv_proc_type => iv_proc_type -- ���s�敪
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_errmsg       -- ���b�Z�[�W
                      ,in_new_line => cn_one          -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.log    -- �o�͋敪
                      ,iv_message  => lv_errbuf       -- ���b�Z�[�W
                      ,in_new_line => cn_one          -- ���s
                    );
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      -- �x�������s�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => NULL            -- ���b�Z�[�W
                      ,in_new_line => cn_one          -- ���s
                    );
    END IF;
    --===============================================
    -- A-50.�I������
    --===============================================
    -------------------------------------------------
    -- 1.�̔����ю擾�G���[���b�Z�[�W�o��
    -------------------------------------------------
    IF ( lv_retcode = cv_status_normal ) AND
       ( gn_target_cnt = cn_zero ) THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application => cv_ap_type_xxcok
                      ,iv_name        => cv_prmmsg_10405
                    );
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => fnd_file.output -- �o�͋敪
                      ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line => cn_one          -- ���s
                    );
    END IF;
    -------------------------------------------------
    -- 2.�Ώی������b�Z�[�W�o��
    -------------------------------------------------
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- �o�͋敪
                    ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line => cn_zero         -- ���s
                  );
    -------------------------------------------------
    -- 3.�����������b�Z�[�W�o��
    -------------------------------------------------
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- �o�͋敪
                    ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line => cn_zero         -- ���s
                  );
    -------------------------------------------------
    -- 4.�G���[�������b�Z�[�W�o��
    -------------------------------------------------
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- �o�͋敪
                    ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line => cn_zero         -- ���s
                  );
    -------------------------------------------------
    -- 5.�X�L�b�v�������b�Z�[�W�o��
    -------------------------------------------------
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90003
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_warning_cnt )
                   );
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- �o�͋敪
                    ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line => cn_one          -- ���s
                  );
    -------------------------------------------------
    -- 6.�I�����b�Z�[�W�o��
    -------------------------------------------------
    -- �I�����b�Z�[�W���f
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => lv_message_code
                   );
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => fnd_file.output -- �o�͋敪
                    ,iv_message  => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line => cn_zero         -- ���s
                  );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
  --
  END main;
  --
END XXCOK014A01C;
/
