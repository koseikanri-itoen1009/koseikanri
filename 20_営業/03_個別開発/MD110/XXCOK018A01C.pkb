CREATE OR REPLACE PACKAGE BODY XXCOK018A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK018A01C(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �A�h�I���FAR�C���^�[�t�F�C�X�iAR I/F�j�̔����� MD050_COK_018_A01
 * Version          : 1.12
 *
 * Program List
 * ------------------------------       ----------------------------------------------------------
 *  Name                                 Description
 * ------------------------------       ----------------------------------------------------------
 *  init                                 ��������(A-1)
 *  get_discnt_amount_ar_data_p          AR�A�g�f�[�^�̎擾(�������l����)(A-2)
 *  chk_discnt_amount_ar_info_p          �Ó����`�F�b�N�̏���(�������l����)(A-3)
 *  get_discnt_amnt_add_ar_data_p        AR�A�g�f�[�^�t�����̎擾(�������l����)(A-4)
 *  ins_discnt_amount_ar_data_p          AR�A�g�f�[�^�̓o�^(�������l����)(A-5)
 *  ins_ra_if_lines_all_p                �������OIF�o�^(A-6)
 *  ins_ra_if_distributions_all_p        �����z��OIF�o�^(A-7)
 *  upd_ coordination_result_p           �A�g���ʂ̍X�V(A-8)
 *  submain                              ���C�������v���V�[�W��
 *  main                                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/1/7      1.0   K.Suenaga        �V�K�쐬
 *  2009/3/17     1.1   M.Hiruta         [��QT1_0073]�������OIF�֓o�^����ڋqID���C���A�ڋq�T�C�gID��ǉ�
 *  2009/3/24     1.2   T.Taniguchi      [��QT1_0118]�������OIF�֓o�^������z���C���A�O�ŁE���ł��l��
 *  2009/4/14     1.3   M.Hiruta         [��QT1_0396]�������OIF�֓o�^����d��v�������ߓ��ɕύX
 *                                                    AR��v���ԗL���`�F�b�N�̏���������ߓ��ɕύX
 *                                       [��QT1_0503]�������OIF�֓o�^���鐿����ID�Əo�א�ID�𐳊m�Ȓl�ɕύX
 *  2009/4/15     1.4   M.Hiruta         [��QT1_0554]�o�א�ڋq�T�C�gID�E������ڋq���E������ڋq�T�C�gID��
 *                                                    �擾����ۂ̒��o������ύX
 *  2009/4/20     1.5   M.Hiruta         [��QT1_0512]�����z��OIF�֓o�^����f�[�^�̊���Ȗڂ����������E���|���̏ꍇ�A
 *                                                    ���ד`�[�ԍ���'1'��ݒ肷��B
 *  2009/4/24     1.6   M.Hiruta         [��QT1_0736]����^�C�v�ɂ�萿�����ۗ��X�e�[�^�X��ݒ�
 *  2009/10/05    1.7   K.Yamaguchi      [�d�l�ύXI_E_566] ����^�C�v���Ƒԁi�����ށj���ɐݒ�\�ɕύX
 *  2009/10/19    1.8   K.Yamaguchi      [��QE_T3_00631] ����ŃR�[�h�擾���@��ύX
 *  2010/04/26    1.9   S.Arizumi        [E_�{�ғ�_02268] �������l���ɑ΂���ېŎ��̊���Ȗڂ͉������ł�ݒ�
 *  2010/07/09    1.10  S.Arizumi        [E_�{�ғ�_02001] AR Web Inquiry�ɍ��ڂ�ǉ����錏
 *  2010/12/07    1.11  S.Niki           [E_�{�ғ�_05823] �ڋq���̎擾�Ɏ��s�����ꍇ�A�x���I��������
 *                                                        AR�A�g�t���O�X�V�����A����OIF�o�^�������o�͂���
 *  2021/04/15    1.12  SCSK Y.Koh       [E_�{�ғ�_16026]
 *
 *****************************************************************************************/
--
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn             CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by              CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
-- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
--  cd_creation_date           CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
-- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
  cn_last_updated_by         CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
-- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
--  cd_last_update_date        CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
-- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
  cn_last_update_login       CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
-- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
--  cd_program_update_date     CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE  
-- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
  --�L��
  cv_msg_part                CONSTANT VARCHAR2(1)  := ':';
  cv_msg_cont                CONSTANT VARCHAR2(1)  := '.';
  --�p�b�P�[�W��
  cv_pkg_name                CONSTANT VARCHAR2(15) := 'XXCOK018A01C';                       --�p�b�P�[�W��
  --�v���t�@�C��
  cv_set_of_bks_id           CONSTANT VARCHAR2(20) := 'GL_SET_OF_BKS_ID';                   --��v����ID
  cv_org_id                  CONSTANT VARCHAR2(10) := 'ORG_ID';                             --�g�DID
  cv_aff1_company_code       CONSTANT VARCHAR2(25) := 'XXCOK1_AFF1_COMPANY_CODE';           --��ЃR�[�h
  cv_aff2_dept_fin           CONSTANT VARCHAR2(20) := 'XXCOK1_AFF2_DEPT_FIN';               --����R�[�h�F�����o����
  cv_aff5_customer_dummy     CONSTANT VARCHAR2(26) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';         --�_�~�[�l:�ڋq�R�[�h
  cv_aff6_compuny_dummy      CONSTANT VARCHAR2(25) := 'XXCOK1_AFF6_COMPANY_DUMMY';          --�_�~�[�l:��ƃR�[�h
  cv_aff7_preliminary1_dummy CONSTANT VARCHAR2(30) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';     --�_�~�[�l:�\���P
  cv_aff8_preliminary2_dummy CONSTANT VARCHAR2(30) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';     --�_�~�[�l:�\���Q
  cv_aff3_allowance_payment  CONSTANT VARCHAR2(30) := 'XXCOK1_AFF3_ALLOWANCE_PAYMENT';      --����Ȗ�:�������l����
-- 2010/04/26 Ver.1.9 [E_�{�ғ�_02268] SCS S.Arizumi REPAIR START
--  cv_aff3_payment_excise_tax CONSTANT VARCHAR2(30) := 'XXCOK1_AFF3_PAYMENT_EXCISE_TAX';     --����Ȗ�:��������œ�
  cv_aff3_receive_excise_tax CONSTANT VARCHAR2(30) := 'XXCOK1_AFF3_RECEIVE_EXCISE_TAX';     --����Ȗ�:�������œ�
-- 2010/04/26 Ver.1.9 [E_�{�ғ�_02268] SCS S.Arizumi REPAIR END
  cv_aff3_receivable         CONSTANT VARCHAR2(22) := 'XXCOK1_AFF3_RECEIVABLE';             --����Ȗ�:��������
  cv_aff3_account_receivable CONSTANT VARCHAR2(30) := 'XXCOK1_AFF3_ACCOUNT_RECEIVABLE';     --����Ȗ�:���|��
  cv_aff4_receivable_vd      CONSTANT VARCHAR2(25) := 'XXCOK1_AFF4_RECEIVABLE_VD';          --�⏕�Ȗ�:��������VD����
  cv_aff4_subacct_dummy      CONSTANT VARCHAR2(25) := 'XXCOK1_AFF4_SUBACCT_DUMMY';          --�⏕�Ȗ�:�_�~�[�l
  cv_sales_category          CONSTANT VARCHAR2(21) := 'XXCOK1_GL_CATEGORY_BM';              --�̔��萔��:�d��J�e�S��
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--  cv_cust_trx_type_vd        CONSTANT VARCHAR2(35) := 'XXCOK1_CUST_TRX_TYPE_RECEIVABLE_VD'; --����^�C�v:VD������������
---- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
----  cv_cust_trx_type_elec_cost CONSTANT VARCHAR2(30) := 'XXCOK1_CUST_TRX_TYPE_ELEC_COST';     --����^�C�v:�d�C�����E
--  cv_cust_trx_type_gnrl      CONSTANT VARCHAR2(35) := 'XXCOK1_CUST_TRX_TYPE_ALL_PAY';       --����^�C�v:�����l����
---- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
  cv_ra_trx_type_f_digestion_vd CONSTANT VARCHAR2(50) := 'XXCOK1_RA_TRX_TYPE_FULL_DIGESTION_VD';  -- ����^�C�v_�����l��_�t���T�[�r�X�i�����jVD
  cv_ra_trx_type_delivery_vd    CONSTANT VARCHAR2(50) := 'XXCOK1_RA_TRX_TYPE_DELIVERY_VD';        -- ����^�C�v_�����l��_�[�iVD
  cv_ra_trx_type_digestion_vd   CONSTANT VARCHAR2(50) := 'XXCOK1_RA_TRX_TYPE_DIGESTION_VD';       -- ����^�C�v_�����l��_����VD
  cv_ra_trx_type_general        CONSTANT VARCHAR2(50) := 'XXCOK1_RA_TRX_TYPE_GENERAL';            -- ����^�C�v_�����l��_��ʓX
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
-- 2021/04/15 Ver1.12 ADD Start
  cv_aff3_equipment_costs       CONSTANT VARCHAR2(50) := 'XXCOK1_AFF3_EQUIPMENT_COSTS';           -- ����Ȗ�_�ݔ���
  cv_aff4_equipment_costs       CONSTANT VARCHAR2(50) := 'XXCOK1_AFF4_EQUIPMENT_COSTS';           -- �⏕�Ȗ�_�ݔ���
  cv_ra_trx_type_equipment      CONSTANT VARCHAR2(50) := 'XXCOK1_RA_TRX_TYPE_EQUIPMENT_COSTS';    -- ����^�C�v_�����l��_�ݔ���
-- 2021/04/15 Ver1.12 ADD End
  --���b�Z�[�W
  cv_90008_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90008'; --���̓p�����[�^�Ȃ�
  cv_00003_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003'; --�v���t�@�C���l�擾�G���[
  cv_00028_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028'; --�Ɩ��������t�擾�G���[
  cv_00029_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00029'; --�ʉ݃R�[�h�擾�G���[
  cv_00042_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00042'; --��v���ԃ`�F�b�N�G���[
  cv_00025_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00025'; --�`�[�ԍ��擾�G���[
  cv_00035_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00035'; --�ڋq���擾�G���[
  cv_00090_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00090'; --����^�C�v���擾�G���[
  cv_00032_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00032'; --�x���������擾�G���[
  cv_00034_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00034'; --����Ȗڏ��擾�G���[
  cv_10280_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10280'; --AR�l���A�g�f�[�^�o�^�G���[
  cv_00051_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00051'; --AR�A�g���ʍX�V���b�N�G���[
  cv_10283_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10283'; --AR�A�g���ʍX�V�G���[
  cv_90000_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000'; --�Ώی������b�Z�[�W
  cv_90002_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002'; --�G���[�������b�Z�[�W
  cv_90001_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001'; --�����������b�Z�[�W
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
  cv_90005_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005'; --�x���I�����b�Z�[�W
  cv_10284_msg               CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10284'; --�����ʔ̎�̋��e�[�u�����������o�͗p���b�Z�[�W
  cv_10285_msg               CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10285'; --����OIF�o�^�����o�͗p���b�Z�[�W
  cv_10286_msg               CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10286'; --�����ʔ̎�̋��e�[�u�������o�͗p���b�Z�[�W
  cv_10287_msg               CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10287'; --�A�g�t���OF�X�V�����o�͗p���b�Z�[�W
  cv_10288_msg               CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10288'; --�������OIF�o�^�����o�͗p���b�Z�[�W
  cv_10289_msg               CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10289'; --�����z��OIF�o�^�����o�͗p���b�Z�[�W
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
  cv_90004_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004'; --����I�����b�Z�[�W
  cv_00058_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00058'; --AR�A�g���擾�G���[
  cv_90006_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006'; --�S���[���o�b�N���b�Z�[�W
  --�g�[�N��
  cv_profile_token           CONSTANT VARCHAR2(7)  := 'PROFILE';        --�v���t�@�C��
  cv_proc_date_token         CONSTANT VARCHAR2(9)  := 'PROC_DATE';      --������
  cv_dept_code_token         CONSTANT VARCHAR2(9)  := 'DEPT_CODE';      --���_�R�[�h
  cv_cust_code_token         CONSTANT VARCHAR2(9)  := 'CUST_CODE';      --�ڋq�R�[�h
-- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
--  cv_vend_code_token         CONSTANT VARCHAR2(9)  := 'VEND_CODE';      --�d����R�[�h
--  cv_vend_site_code_token    CONSTANT VARCHAR2(14) := 'VEND_SITE_CODE'; --�d����T�C�g�R�[�h
  cv_ship_cust_code_token    CONSTANT VARCHAR2(16) := 'SHIP_CUST_CODE'; --�[�i��ڋq�R�[�h
  cv_bill_cust_code_token    CONSTANT VARCHAR2(16) := 'BILL_CUST_CODE'; --������ڋq�R�[�h
-- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
  cv_account_date_token      CONSTANT VARCHAR2(12) := 'ACCOUNT_DATE';   --�v���
  cv_cust_trx_type_token     CONSTANT VARCHAR2(13) := 'CUST_TRX_TYPE';  --����^�C�v
  cv_count_token             CONSTANT VARCHAR2(5)  := 'COUNT';          --����
  --�A�v���P�[�V�����Z�k��
  cv_appli_xxccp_name        CONSTANT VARCHAR2(5)  := 'XXCCP';    --XXCCP
  cv_appli_ar_name           CONSTANT VARCHAR2(2)  := 'AR';       --AR
  cv_appli_xxcok_name        CONSTANT VARCHAR2(5)  := 'XXCOK';    --XXCOK
  --�X�e�[�^�X
  cv_untreated_ar_status     CONSTANT VARCHAR2(1)  := '0';       --�A�g�X�e�[�^�X������(AR)
  cv_finished_ar_status      CONSTANT VARCHAR2(1)  := '1';       --�A�g�X�e�[�^�X������(AR)
  cv_hold                    CONSTANT VARCHAR2(4)  := 'HOLD';    --�������ۗ��X�e�[�^�X:�t���T�[�r�XVD
  cv_open                    CONSTANT VARCHAR2(4)  := 'OPEN';    --�������ۗ��X�e�[�^�X:�t���T�[�r�XVD�ȊO
  --����
  cv_language                CONSTANT VARCHAR2(4)  := 'LANG';    --����
  --�^�C�v
  cv_user_type               CONSTANT VARCHAR2(4)  := 'User';    --�ʉ݊��Z�^�C�v
  cv_rev_class               CONSTANT VARCHAR2(3)  := 'REV';     --�z���^�C�v:���v
  cv_tax_class               CONSTANT VARCHAR2(3)  := 'TAX';     --�z���^�C�v:�ŋ�/���׃^�C�v:�ŋ��s
  cv_rec_class               CONSTANT VARCHAR2(3)  := 'REC';     --�z���^�C�v:��
  cv_line_type               CONSTANT VARCHAR2(4)  := 'LINE';    --���׃^�C�v:���v�s
  --���̑�
  cn_quantity                CONSTANT NUMBER       := 1;         --����:���v�s
  cv_rate                    CONSTANT VARCHAR2(1)  := '1';       --���Z���[�g
  cv_waiting                 CONSTANT VARCHAR2(7)  := 'WAITING'; --�ʐ��������/�ꊇ���������
  cv_percent                 CONSTANT NUMBER       := 100;       --����
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--  cv_low_type                CONSTANT VARCHAR2(2)  := '24';      --�Ƒԁi�����ށj�t���t���x���_�[
  cv_low_type_f_digestion_vd CONSTANT VARCHAR2(2)  := '24';      -- �t���T�[�r�X�i�����j
  cv_low_type_delivery_vd    CONSTANT VARCHAR2(2)  := '26';      -- �[�iVD
  cv_low_type_digestion_vd   CONSTANT VARCHAR2(2)  := '27';      -- ����VD
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi REPAIR START
--  cv_validate_flag           CONSTANT VARCHAR2(1)  := 'N';       --�L���t���O
  cv_tax_validate_flag_valid CONSTANT VARCHAR2(1)  := 'Y';          --AR�ŋ��}�X�^    �F�L���t���O
  cv_cust_status_available   CONSTANT VARCHAR2(1)  := 'A';          --�ڋq�T�C�g�}�X�^�F�L��
  cn_account_name_len        CONSTANT NUMBER       := 150;          --�ڋq���� �ő啶����
  cv_fmt_yyyy_mm_dd          CONSTANT VARCHAR2(10) := 'YYYY/MM/DD'; --�����FYYYY/MM/DD
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi REPAIR END
  cn_no_tax                  CONSTANT NUMBER       := 0;         --����ŗ�
  cn_rev_num                 CONSTANT NUMBER       := 1;         --���הԍ�
-- 2009/3/24     ver1.2   T.Taniguchi  ADD STR
  cv_tax_flag_y              CONSTANT VARCHAR2(1)  := 'Y';       --���Ńt���O
-- 2009/3/24     ver1.2   T.Taniguchi  ADD END
-- Start 2009/04/20 Ver_1.5 T1_0512 M.Hiruta
  cv_line_slip_rec           CONSTANT VARCHAR2(1)  := '1';       --���׍s�`�[�ԍ�
-- End   2009/04/20 Ver_1.5 T1_0512 M.Hiruta
-- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
  cv_submit_bill_type_yes    CONSTANT VARCHAR2(1)  := 'Y';       --�������o�͑ΏہFYes
-- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
  cv_null                    CONSTANT VARCHAR2(1)  := 'X';       --NULL�̑�֕���
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gn_target_cnt              NUMBER         DEFAULT 0;    --�Ώی���
  gn_normal_cnt              NUMBER         DEFAULT 0;    --���팏��
  gn_error_cnt               NUMBER         DEFAULT 0;    --�G���[����
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
  gn_target_line_cnt         NUMBER         DEFAULT 0;    --�����ʔ̎�̋����R�[�h����
  gn_flag_upd_cnt            NUMBER         DEFAULT 0;    --AR�A�g�t���O�X�V����
  gn_lines_cnt               NUMBER         DEFAULT 0;    --�������OIF�o�^����
  gn_distributions_cnt       NUMBER         DEFAULT 0;    --�����z��OIF�o�^����
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
  gn_set_of_bks_id           NUMBER         DEFAULT NULL; --��v����ID
  gn_org_id                  VARCHAR2(50)   DEFAULT NULL; --�g�DID
  gv_aff1_company_code       VARCHAR2(50)   DEFAULT NULL; --��ЃR�[�h
  gv_aff2_dept_fin           VARCHAR2(50)   DEFAULT NULL; --����R�[�h�F�����o����
  gv_aff5_customer_dummy     VARCHAR2(50)   DEFAULT NULL; --�_�~�[�l:�ڋq�R�[�h
  gv_aff6_compuny_dummy      VARCHAR2(50)   DEFAULT NULL; --�_�~�[�l:��ƃR�[�h
  gv_aff7_preliminary1_dummy VARCHAR2(50)   DEFAULT NULL; --�_�~�[�l:�\���P
  gv_aff8_preliminary2_dummy VARCHAR2(50)   DEFAULT NULL; --�_�~�[�l:�\���Q
  gv_aff3_allowance_payment  VARCHAR2(50)   DEFAULT NULL; --����Ȗ�:�������l����
-- 2010/04/26 Ver.1.9 [E_�{�ғ�_02268] SCS S.Arizumi REPAIR START
--  gv_aff3_payment_excise_tax VARCHAR2(50)   DEFAULT NULL; --����Ȗ�:��������œ�
  gv_aff3_receive_excise_tax VARCHAR2(50)   DEFAULT NULL; --����Ȗ�:�������œ�
-- 2010/04/26 Ver.1.9 [E_�{�ғ�_02268] SCS S.Arizumi REPAIR END
  gv_aff3_receivable         VARCHAR2(50)   DEFAULT NULL; --����Ȗ�:��������
  gv_aff3_account_receivable VARCHAR2(50)   DEFAULT NULL; --����Ȗ�:���|��
  gv_aff4_receivable_vd      VARCHAR2(50)   DEFAULT NULL; --�⏕�Ȗ�:��������VD����
  gv_aff4_subacct_dummy      VARCHAR2(50)   DEFAULT NULL; --�⏕�Ȗ�:�_�~�[�l
  gv_sales_category          VARCHAR2(50)   DEFAULT NULL; --�̔��萔��:�d��J�e�S��
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--  gv_cust_trx_type_vd        VARCHAR2(50)   DEFAULT NULL; --����^�C�v:VD������������
---- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
----  gv_cust_trx_type_elec_cost VARCHAR2(50)   DEFAULT NULL; --����^�C�v:�d�C�����E
----  gn_vd_trx_type_id          NUMBER         DEFAULT NULL; --����^�C�vID:VD������������
----  gn_cust_trx_elec_id        NUMBER         DEFAULT NULL; --����^�C�vID:�d�C�����E
--  gv_cust_trx_type_gnrl      VARCHAR2(50)   DEFAULT NULL; --����^�C�v:�����l����
---- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
  gv_ra_trx_type_f_digestion_vd VARCHAR2(50) DEFAULT NULL; -- ����^�C�v_�����l��_�t���T�[�r�X�i�����jVD
  gv_ra_trx_type_delivery_vd    VARCHAR2(50) DEFAULT NULL; -- ����^�C�v_�����l��_�[�iVD
  gv_ra_trx_type_digestion_vd   VARCHAR2(50) DEFAULT NULL; -- ����^�C�v_�����l��_����VD
  gv_ra_trx_type_general        VARCHAR2(50) DEFAULT NULL; -- ����^�C�v_�����l��_��ʓX
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
-- 2021/04/15 Ver1.12 ADD Start
  gv_aff3_equipment_costs       VARCHAR2(50);             -- ����Ȗ�_�ݔ���
  gv_aff4_equipment_costs       VARCHAR2(50);             -- �⏕�Ȗ�_�ݔ���
  gv_ra_trx_type_equipment      VARCHAR2(50);             -- ����^�C�v_�����l��_�ݔ���
-- 2021/04/15 Ver1.12 ADD End
  gn_csh_rcpt                NUMBER         DEFAULT NULL; --�����l���z�|�����l������Ŋz
  gd_operation_date          DATE           DEFAULT NULL; --�Ɩ��������t
  gv_currency_code           VARCHAR2(50)   DEFAULT NULL; --�@�\�ʉ݃R�[�h
  gv_slip_number             VARCHAR2(50)   DEFAULT NULL; --�`�[�ԍ�
  gv_cash_receiv_base_code   VARCHAR2(50)   DEFAULT NULL; --�������_�R�[�h
  gv_business_low_type       VARCHAR2(50)   DEFAULT NULL; --�Ƒԁi�����ށj
  gn_term_id                 NUMBER         DEFAULT NULL; --�x������ID
  gv_language                VARCHAR2(10)   DEFAULT NULL; --����
  gn_ship_account_id         NUMBER         DEFAULT NULL; --�o�א�ڋqID
  gn_ship_address_id         NUMBER         DEFAULT NULL; --�o�א�ڋq�T�C�gID
  gn_bill_account_id         NUMBER         DEFAULT NULL; --������ڋqID
  gn_bill_address_id         NUMBER         DEFAULT NULL; --������ڋq�T�C�gID
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi ADD START
  gt_ship_account_code       hz_cust_accounts.account_number%TYPE DEFAULT NULL; -- �o�א�ڋq�R�[�h
  gt_ship_account_name       hz_parties.party_name%TYPE           DEFAULT NULL; -- �o�א�ڋq��
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi ADD END
  gv_tax_flag                VARCHAR2(1)    DEFAULT NULL; --����ŐŃt���O
  gn_tax_rate                NUMBER         DEFAULT NULL; --����ŗ�
  gn_tax_amt                 NUMBER         DEFAULT NULL; --����Ŋz
  -- ===============================
  -- �O���[�o���J�[�\���FAR�A�g�f�[�^�̎擾(�������l����)
  -- ===============================
  CURSOR g_discnt_amount_cur
  IS
    SELECT   xcbs.base_code                      AS base_code                     -- ���_�R�[�h
           , xcbs.supplier_code                  AS supplier_code                 -- �d����R�[�h
           , xcbs.supplier_site_code             AS supplier_site_code            -- �d����T�C�g�R�[�h
           , xcbs.delivery_cust_code             AS delivery_cust_code            -- �[�i�ڋq�R�[�h
           , xcbs.demand_to_cust_code            AS demand_to_cust_code           -- �����ڋq�R�[�h
           , xcbs.emp_code                       AS emp_code                      -- ���ьv��S���҃R�[�h
           , SUM(xcbs.csh_rcpt_discount_amt)     AS sum_csh_rcpt_discount_amt     -- �����l���z
           , SUM(xcbs.csh_rcpt_discount_amt_tax) AS sum_csh_rcpt_discount_amt_tax -- �����l������Ŋz
           , xcbs.closing_date                   AS closing_date                  -- ���ߓ�
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--           , xcbs.expect_payment_date            AS expect_payment_date           -- �x���\���
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
           , xcbs.tax_code                       AS tax_code                      -- �ŋ��R�[�h
           , xcbs.term_code                      AS term_code                     -- �x������
    FROM     xxcok_cond_bm_support               xcbs                             -- �����ʔ̎�̋��e�[�u��
    WHERE    xcbs.ar_interface_status            = cv_untreated_ar_status         -- �A�g�X�e�[�^�X(AR) = ������
    AND      xcbs.csh_rcpt_discount_amt          IS NOT NULL                      -- �����l���z����
    GROUP BY xcbs.base_code                                                       -- ���_�R�[�h
           , xcbs.supplier_code                                                   -- �d����R�[�h
           , xcbs.supplier_site_code                                              -- �d����T�C�g�R�[�h
           , xcbs.delivery_cust_code                                              -- �[�i�ڋq�R�[�h
           , xcbs.demand_to_cust_code                                             -- �����ڋq�R�[�h
           , xcbs.emp_code                                                        -- ���ьv��S���҃R�[�h
           , xcbs.closing_date                                                    -- ���ߓ�
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--           , xcbs.expect_payment_date                                             -- �x���\���
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
           , xcbs.tax_code                                                        -- �ŋ��R�[�h
           , xcbs.term_code;                                                      -- �x������
--
-- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
    --����^�C�v���
    CURSOR g_cust_trx_type_cur(
      iv_cust_trx_type IN VARCHAR2
    )
    IS
      SELECT   rctta.cust_trx_type_id AS cust_trx_type_id      --����^�C�vID
             , rctta.attribute1       AS submit_bill_type      --�������o�͑Ώۋ敪
             , CASE rctta.attribute1
                 WHEN cv_submit_bill_type_yes THEN
                   cv_open
                 ELSE
                   cv_hold
               END                    AS charge_waiting_status --�������ۗ��X�e�[�^�X
      FROM     ra_cust_trx_types_all  rctta               --��������^�C�v�}�X�^
      WHERE    rctta.name         = iv_cust_trx_type  --�d��\�[�X�� = ���������Ŏ擾��������^�C�v
      AND      rctta.org_id       = gn_org_id         --�g�DID       = �g�DID
      AND      gd_operation_date  BETWEEN rctta.start_date
                                      AND NVL( rctta.end_date, gd_operation_date )
    ;
-- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
  -- ===============================
  -- �O���[�o�����R�[�h�^�C�v
  -- ===============================
  g_discnt_amount_rtype g_discnt_amount_cur%ROWTYPE;
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
---- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
--  g_cust_trx_type_vd    g_cust_trx_type_cur%ROWTYPE;
--  g_cust_trx_type_gnrl  g_cust_trx_type_cur%ROWTYPE;
---- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
  g_ra_trx_type_f_digestion_vd g_cust_trx_type_cur%ROWTYPE; -- ����^�C�v_�����l��_�t���T�[�r�X�i�����jVD
  g_ra_trx_type_delivery_vd    g_cust_trx_type_cur%ROWTYPE; -- ����^�C�v_�����l��_�[�iVD
  g_ra_trx_type_digestion_vd   g_cust_trx_type_cur%ROWTYPE; -- ����^�C�v_�����l��_����VD
  g_ra_trx_type_general        g_cust_trx_type_cur%ROWTYPE; -- ����^�C�v_�����l��_��ʓX
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
-- 2021/04/15 Ver1.12 ADD Start
  g_ra_trx_type_equipment      g_cust_trx_type_cur%ROWTYPE; -- ����^�C�v_�ݔ���
-- 2021/04/15 Ver1.12 ADD End
  -- ===============================
  -- ���ʗ�O
  -- ===============================
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** ���b�N�G���[ **
  lock_err_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_err_expt, -54 );
--
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki MOD START
--  /**********************************************************************************
--   * Procedure Name   : upd_ coordination_result_p
--   * Description      : �A�g���ʂ̍X�V(A-8)
--   ***********************************************************************************/
--  PROCEDURE upd_coordination_result_p(
--    ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
--  , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
--  , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
--  )
--  IS
--    -- ===============================
--    -- ���[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_coordination_result_p'; -- �v���O������
--    -- ===============================
--    -- ���[�J���ϐ�
--    -- ===============================
--    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
--    lb_retcode BOOLEAN        DEFAULT NULL; -- ���b�Z�[�W�o�͕ϐ�
--    lv_out_msg VARCHAR2(5000) DEFAULT NULL; -- ���b�Z�[�W�o�͕ϐ�
--    --==============================================================
--    --���b�N�擾�p�J�[�\��
--    --==============================================================
--  CURSOR l_upd_cur
--  IS
--    SELECT 'X'
--    FROM   xxcok_cond_bm_support    xcbs                     -- �����ʔ̎�̋��e�[�u��
--    WHERE  xcbs.ar_interface_status = cv_untreated_ar_status -- �A�g�X�e�[�^�X������(AR)
--    AND    xcbs.csh_rcpt_discount_amt IS NOT NULL
--    FOR UPDATE OF xcbs.cond_bm_support_id NOWAIT;
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    --==============================================================
--    --�J�[�\���I�[�v��
--    --==============================================================
--    OPEN  l_upd_cur;
--    CLOSE l_upd_cur;
--    --==============================================================
--    --���������̃J�E���g
--    --==============================================================
--    BEGIN 
----
--      SELECT COUNT(*)
--      INTO   gn_normal_cnt
--      FROM   xxcok_cond_bm_support    xcbs                     -- �����ʔ̎�̋��e�[�u��
--      WHERE  xcbs.ar_interface_status = cv_untreated_ar_status -- �A�g�X�e�[�^�X������(AR)
--      AND    xcbs.csh_rcpt_discount_amt IS NOT NULL;
--    END;
--    --==============================================================
--    --�����ʔ̎�̋��e�[�u���̍X�V����
--    --==============================================================
--    BEGIN
----
--      UPDATE xxcok_cond_bm_support xcbs
--      SET    xcbs.ar_interface_status = cv_finished_ar_status  -- �A�g�X�e�[�^�X�iAR�j= 1�F������
--           , xcbs.ar_interface_date   = gd_operation_date      -- �A�g��(AR) = �Ɩ��������t
--           , xcbs.last_updated_by     = cn_last_updated_by     -- �ŏI�X�V�� = WHO�J�������.���[�UID
--           , xcbs.last_update_date    = SYSDATE                -- �ŏI�X�V�� = SYSDATE
--           , xcbs.last_update_login   = cn_last_update_login   -- �ŏI�X�V���O�C��ID=WHO�J�������. ���O�C��ID
---- 2010/04/26 Ver.1.9 [E_�{�ғ�_02268] SCS S.Arizumi ADD START
--           , xcbs.request_id              = cn_request_id
--           , xcbs.program_application_id  = cn_program_application_id
--           , xcbs.program_id              = cn_program_id
--           , xcbs.program_update_date     = SYSDATE
---- 2010/04/26 Ver.1.9 [E_�{�ғ�_02268] SCS S.Arizumi ADD END
--      WHERE  xcbs.ar_interface_status = cv_untreated_ar_status -- �A�g�X�e�[�^�X (AR) = 0: ������
--      AND    xcbs.csh_rcpt_discount_amt IS NOT NULL;
----
--    EXCEPTION
--      -- *** AR�A�g���ʍX�V�G���[ ***
--      WHEN OTHERS THEN
--        lv_out_msg := xxccp_common_pkg.get_msg(
--                        cv_appli_xxcok_name
--                      , cv_10283_err_msg
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f( 
--                        FND_FILE.OUTPUT    -- �o�͋敪
--                      , lv_out_msg         -- ���b�Z�[�W
--                      , 0                  -- ���s
--                      );
--        ov_errmsg  := NULL;
--        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--        ov_retcode := cv_status_error;
--    END;
----
--  EXCEPTION
--    -- *** ���b�N�G���[���b�Z�[�W ***
--    WHEN lock_err_expt THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                      cv_appli_xxcok_name
--                    , cv_00051_err_msg
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f( 
--                      FND_FILE.OUTPUT    -- �o�͋敪
--                    , lv_out_msg         -- ���b�Z�[�W
--                    , 0                  -- ���s
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END upd_coordination_result_p;
--
  /**********************************************************************************
   * Procedure Name   : upd_ coordination_result_p
   * Description      : �A�g���ʂ̍X�V(A-8)
   ***********************************************************************************/
  PROCEDURE upd_coordination_result_p(
    ov_errbuf  OUT VARCHAR2                             -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2                             -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2                             -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_discnt_amount_rec IN  g_discnt_amount_cur%ROWTYPE -- ���R�[�h����
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_coordination_result_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode BOOLEAN        DEFAULT NULL; -- ���b�Z�[�W�o�͕ϐ�
    lv_out_msg VARCHAR2(5000) DEFAULT NULL; -- ���b�Z�[�W�o�͕ϐ�
    --==============================================================
    --���b�N�擾�p�J�[�\��
    --==============================================================
  CURSOR l_upd_cur
  IS
    SELECT xcbs.cond_bm_support_id
    FROM   xxcok_cond_bm_support  xcbs
    WHERE  xcbs.ar_interface_status               = cv_untreated_ar_status                                  -- �A�g�X�e�[�^�X������(AR)
    AND    xcbs.csh_rcpt_discount_amt             IS NOT NULL                                               -- �����l���z
    AND    xcbs.base_code                         = i_discnt_amount_rec.base_code                           -- ���_�R�[�h
    AND    NVL(xcbs.supplier_code, cv_null)       = NVL(i_discnt_amount_rec.supplier_code, cv_null)         -- �d����R�[�h
    AND    NVL(xcbs.supplier_site_code, cv_null)  = NVL(i_discnt_amount_rec.supplier_site_code, cv_null)    -- �d����T�C�g�R�[�h
    AND    xcbs.delivery_cust_code                = i_discnt_amount_rec.delivery_cust_code                  -- �[�i�ڋq�R�[�h
    AND    NVL(xcbs.demand_to_cust_code, cv_null) = NVL(i_discnt_amount_rec.demand_to_cust_code, cv_null)   -- �����ڋq�R�[�h
    AND    xcbs.emp_code                          = i_discnt_amount_rec.emp_code                            -- ���ьv��S���҃R�[�h
    AND    xcbs.closing_date                      = i_discnt_amount_rec.closing_date                        -- ���ߓ�
    AND    xcbs.tax_code                          = i_discnt_amount_rec.tax_code                            -- �ŋ��R�[�h
    AND    xcbs.term_code                         = i_discnt_amount_rec.term_code                           -- �x������
    FOR UPDATE OF xcbs.cond_bm_support_id NOWAIT
    ;
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --�J�[�\���I�[�v��
    --==============================================================
    OPEN  l_upd_cur;
    CLOSE l_upd_cur;
    --==============================================================
    --�����ʔ̎�̋��e�[�u���X�V���[�v
    --==============================================================
    BEGIN
      << l_upd_loop >>
      FOR l_upd_rec IN l_upd_cur LOOP
        --==============================================================
        --�����ʔ̎�̋��e�[�u���̍X�V����
        --==============================================================
        UPDATE xxcok_cond_bm_support  xcbs
        SET    xcbs.ar_interface_status               = cv_finished_ar_status   -- �A�g�X�e�[�^�X�iAR�j= 1�F������
             , xcbs.ar_interface_date                 = gd_operation_date       -- �A�g��(AR) = �Ɩ��������t
             , xcbs.last_updated_by                   = cn_last_updated_by      -- �ŏI�X�V�� = WHO�J�������.���[�UID
             , xcbs.last_update_date                  = SYSDATE                 -- �ŏI�X�V�� = SYSDATE
             , xcbs.last_update_login                 = cn_last_update_login    -- �ŏI�X�V���O�C��ID=WHO�J�������. ���O�C��ID
             , xcbs.request_id                        = cn_request_id
             , xcbs.program_application_id            = cn_program_application_id
             , xcbs.program_id                        = cn_program_id
             , xcbs.program_update_date               = SYSDATE
        WHERE xcbs.cond_bm_support_id = l_upd_rec.cond_bm_support_id
        ;
        --==============================================================
        --AR�A�g���ʍX�V�����̃J�E���g
        --==============================================================
        gn_flag_upd_cnt := gn_flag_upd_cnt + 1;
      END LOOP l_upd_loop;
--
    EXCEPTION
      -- *** AR�A�g���ʍX�V�G���[ ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_10283_err_msg
                      );
        lb_retcode := xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT    -- �o�͋敪
                      , lv_out_msg         -- ���b�Z�[�W
                      , 0                  -- ���s
                      );
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    -- *** ���b�N�G���[���b�Z�[�W ***
    WHEN lock_err_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00051_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_coordination_result_p;
--
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki MOD END
--
  /**********************************************************************************
   * Procedure Name   : ins_ra_if_distributions_all_p
   * Description      : �����z��OIF�o�^(A-7)
   ***********************************************************************************/
  PROCEDURE ins_ra_if_distributions_all_p(
    ov_errbuf           OUT VARCHAR2                                                      -- �G���[�E���b�Z�[�W
  , ov_retcode          OUT VARCHAR2                                                      -- ���^�[���E�R�[�h
  , ov_errmsg           OUT VARCHAR2                                                      -- ���[�U�[�G���[���b�Z�[�W
  , i_discnt_amount_rec IN  g_discnt_amount_cur%ROWTYPE                                   -- ���R�[�h����(�����l����)
  , it_count            IN  ra_interface_distributions_all.interface_line_attribute2%TYPE -- ���׍s�`�[�ԍ�
  , it_account_class    IN  ra_interface_distributions_all.account_class%TYPE             -- �z���^�C�v
  , it_amount           IN  ra_interface_distributions_all.amount%TYPE                    -- ���׋��z
  , it_ccid             IN  ra_interface_distributions_all.code_combination_id%TYPE       -- ����Ȗ�ID
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ra_if_distributions_all_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(5000) DEFAULT NULL; -- ���b�Z�[�W�ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL; -- ���b�Z�[�W�o�͖߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==================================================================
    --�����z��OIF�o�^
    --==================================================================
    BEGIN
      INSERT INTO ra_interface_distributions_all( 
        interface_line_context    -- ���׃R���e�L�X�g
      , interface_line_attribute1 -- �`�[�ԍ�
      , interface_line_attribute2 -- ���׍s�`�[�ԍ�
      , account_class             -- �z���^�C�v
      , amount                    -- ���׋��z
      , percent                   -- ����
      , code_combination_id       -- ����Ȗ�ID
      , attribute_category        -- DFF�R���e�L�X�g
      , creation_date             -- �V�K�쐬���t
      , org_id                    -- �I���OID
      )
      VALUES(
        gv_sales_category         -- ���׃R���e�L�X�g:���������Ŏ擾�����d��J�e�S��
      , gv_slip_number            -- �`�[�ԍ�        :�t�����擾�ɂĎ擾�����`�[�ԍ�
      , it_count                  -- ���׍s�`�[�ԍ�  :���R�[�h�o�^���ɓ���`�[���ŃJ�E���g
      , it_account_class          -- �z���^�C�v      :�z���^�C�v
      , it_amount                 -- ���׋��z        :���z
      , cv_percent                -- ����            :100
      , it_ccid                   -- ����Ȗ�ID      :��L�Ŏ擾��������Ȗ�ID
      , gn_org_id                 -- DFF�R���e�L�X�g :���������Ŏ擾�����g�DID
      , SYSDATE                   -- �V�K�쐬���t    :SYSDATE
      , gn_org_id                 -- �I���OID        :���������Ŏ擾�����g�DID
      );
    EXCEPTION
      WHEN  OTHERS THEN
-- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
--          -- *** AR�����l���A�g�f�[�^�o�^�G���[ ***
--          lv_out_msg := xxccp_common_pkg.get_msg(
--                          cv_appli_xxcok_name
--                        , cv_10280_err_msg
--                        , cv_dept_code_token
--                        , i_discnt_amount_rec.base_code
--                        , cv_vend_code_token
--                        , i_discnt_amount_rec.supplier_code
--                        , cv_vend_site_code_token
--                        , i_discnt_amount_rec.supplier_site_code
--                        , cv_account_date_token
--                        , TO_CHAR( i_discnt_amount_rec.closing_date, 'YYYYY/MM/DD' )
--                        );
          -- *** AR�����l���A�g�f�[�^�o�^�G���[ ***
          lv_out_msg := xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                        , cv_10280_err_msg
                        , cv_dept_code_token
                        , i_discnt_amount_rec.base_code
                        , cv_ship_cust_code_token
                        , i_discnt_amount_rec.delivery_cust_code
                        , cv_bill_cust_code_token
                        , i_discnt_amount_rec.demand_to_cust_code
                        , cv_account_date_token
                        , TO_CHAR( i_discnt_amount_rec.closing_date, 'YYYYY/MM/DD' )
                        );
-- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
          lb_retcode := xxcok_common_pkg.put_message_f( 
                          FND_FILE.OUTPUT    -- �o�͋敪
                        , lv_out_msg         -- ���b�Z�[�W
                        , 0                  -- ���s
                        );
          ov_errmsg  := NULL;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
          ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_ra_if_distributions_all_p;
--
  /**********************************************************************************
   * Procedure Name   : ins_ra_if_lines_all_p
   * Description      : �������OIF�o�^(A-6)
   ***********************************************************************************/
  PROCEDURE ins_ra_if_lines_all_p(
    ov_errbuf                  OUT VARCHAR2                                              -- �G���[�E���b�Z�[�W
  , ov_retcode                 OUT VARCHAR2                                              -- ���^�[���E�R�[�h
  , ov_errmsg                  OUT VARCHAR2                                              -- ���[�U�[�G���[���b�Z�[�W
  , i_discnt_amount_rec        IN  g_discnt_amount_cur%ROWTYPE                           -- ���R�[�h����(�����l����)
  , it_spare                   IN  ra_interface_lines_all.interface_line_attribute3%TYPE -- �J�E���g
  , it_line_type               IN  ra_interface_lines_all.line_type%TYPE                 -- ���׃^�C�v
  , it_amont                   IN  ra_interface_lines_all.amount%TYPE                    -- ���׋��z
  , it_cust_trx_type_id        IN  ra_interface_lines_all.cust_trx_type_id%TYPE          -- ����^�C�vID
  , it_link_to_line_context    IN  ra_interface_lines_all.link_to_line_context%TYPE      -- �����N���׃R���e�L�X�g
  , it_link_to_line_attribute1 IN  ra_interface_lines_all.link_to_line_attribute1%TYPE   -- �����N�`�[�ԍ�
  , it_link_to_line_attribute2 IN  ra_interface_lines_all.link_to_line_attribute2%TYPE   -- �����N���׍s�ԍ�
  , it_trx_date                IN  ra_interface_lines_all.trx_date%TYPE                  -- ���������t�i���ߓ��j
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--  , it_gl_date                 IN  ra_interface_lines_all.gl_date%TYPE                   -- �d��v���
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
  , it_quantity                IN  ra_interface_lines_all.quantity%TYPE                  -- ����
  , it_unit_selling_price      IN  ra_interface_lines_all.unit_selling_price%TYPE        -- �P��
  , it_tax_code                IN  ra_interface_lines_all.tax_code%TYPE                  -- �ŃR�[�h
  , it_form_base               IN  ra_interface_lines_all.header_attribute5%TYPE         -- �N�[����
  , it_form_typist             IN  ra_interface_lines_all.header_attribute6%TYPE         -- �`�[���͎�
  , it_charge_waiting_status   IN  ra_interface_lines_all.header_attribute7%TYPE         -- �������ۗ��X�e�[�^�X
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ra_if_lines_all_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(5000) DEFAULT NULL; -- ���b�Z�[�W�ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL; -- ���b�Z�[�W�o�͖߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    --==================================================================
    --�������OIF�o�^
    --==================================================================
    BEGIN
      INSERT INTO ra_interface_lines_all( 
        interface_line_context       -- ���׃R���e�L�X�g
      , interface_line_attribute1    -- �`�[�ԍ�
      , interface_line_attribute2    -- ���׍s�`�[�ԍ�
      , batch_source_name            -- �\�[�X
      , set_of_books_id              -- ��v����ID
      , line_type                    -- ���׃^�C�v
      , description                  -- ���������דE�v
      , currency_code                -- �ʉ݃R�[�h
      , amount                       -- ���׋��z
      , cust_trx_type_id             -- ����^�C�vID
      , term_id                      -- �x������ID
      , orig_system_bill_customer_id -- ������ڋqID
      , orig_system_bill_address_id  -- ������T�C�gID
      , orig_system_ship_customer_id -- �[�i��ڋqID
      , orig_system_ship_address_id  -- �[�i��T�C�gID
      , link_to_line_context         -- �����N���׃R���e�L�X�g
      , link_to_line_attribute1      -- �����N�`�[�ԍ�
      , link_to_line_attribute2      -- �����N���׍s�ԍ�
      , conversion_type              -- �ʉ݊��Z�^�C�v
      , conversion_rate              -- ���Z���[�g
      , trx_date                     -- ���������t
      , gl_date                      -- �d��v���
      , trx_number                   -- �`�[�ԍ�
      , quantity                     -- ����
      , unit_selling_price           -- �P��
      , tax_code                     -- �ŋ敪
      , header_attribute_category    -- DFF�R���e�L�X�g
      , header_attribute5            -- �N�[����
      , header_attribute6            -- �`�[���͎�
      , header_attribute7            -- �������ۗ��X�e�[�^�X
      , header_attribute8            -- �ʐ��������
      , header_attribute9            -- �ꊇ���������
      , header_attribute11           -- �������_�R�[�h
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi ADD START
      , header_attribute12           -- �o�א�ڋq�R�[�h
      , header_attribute13           -- �o�א�ڋq����
      , header_attribute14           -- �`�[�ԍ�
      , header_attribute15           -- GL�L����
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi ADD END
      , creation_date                -- �V�K�쐬���t
      , org_id                       -- �I���OID
      , amount_includes_tax_flag     -- ���Ńt���O
      )
      VALUES(
        gv_sales_category            -- ���׃R���e�L�X�g      :���������Ŏ擾�����d��J�e�S��
      , gv_slip_number               -- �`�[�ԍ�              :�t�����擾�ɂĎ擾�����`�[�ԍ�
      , it_spare                     -- �\��                  :�J�E���g
      , gv_sales_category            -- �\�[�X                :���������Ŏ擾�����d��J�e�S��
      , gn_set_of_bks_id             -- ��v����ID            :���������Ŏ擾������v����ID
      , it_line_type                 -- ���׃^�C�v            :���v�s�F'LINE'�ŋ��s�F'TAX'
      , gv_sales_category            -- ���������דE�v        :���������Ŏ擾�����d��J�e�S��
      , gv_currency_code             -- �ʉ݃R�[�h            :���������Ŏ擾�����ʉ݃R�[�h
      , it_amont                     -- ���׋��z              :���v�s:�����l���z/�d�C�� �ŋ��s:����Ŋz/����Ŋz
      , it_cust_trx_type_id          -- ����^�C�vID          :���������ɂĎ擾��������ȖڂɑΉ��������^�C�vID
      , gn_term_id                   -- �x������ID            :�t�����擾�ɂĎ擾�����x������ID
-- Start 2009/04/14 Ver_1.3 T1_0503 M.Hiruta
--      , gn_ship_account_id           -- ������ڋqID          :�ڋq���Q.������ڋqID
--      , gn_ship_address_id           -- ������ڋq�T�C�gID    :�ڋq���Q.������ڋqID�ɕR�Â����ڋq�T�C�gID
--      , gn_bill_account_id           -- �o�א�ڋqID          :�ڋq���P.�o�א�ڋqID
--      , gn_bill_address_id           -- �o�א�ڋq�T�C�gID    :�ڋq���P.�o�א�ڋqID�ɕR�Â����ڋq�T�C�gID
      , gn_bill_account_id           -- ������ڋqID          :�ڋq���Q.������ڋqID
      , gn_bill_address_id           -- ������ڋq�T�C�gID    :�ڋq���Q.������ڋqID�ɕR�Â����ڋq�T�C�gID
      , gn_ship_account_id           -- �o�א�ڋqID          :�ڋq���P.�o�א�ڋqID
      , gn_ship_address_id           -- �o�א�ڋq�T�C�gID    :�ڋq���P.�o�א�ڋqID�ɕR�Â����ڋq�T�C�gID
-- End   2009/04/14 Ver_1.3 T1_0503 M.Hiruta
      , it_link_to_line_context      -- �����N���׃R���e�L�X�g:�ŋ��s:���v�s�ɂĎw�肵�����׃R���e�L�X�g�l
      , it_link_to_line_attribute1   -- �����N�`�[�ԍ�        :�ŋ��s:���v�s�ɂĎw�肵���`�[�ԍ��l
      , it_link_to_line_attribute2   -- �����N���׍s�ԍ�      :�ŋ��s:���v�s�ɂĎw�肵�����׍s�`�[�ԍ��l
      , cv_user_type                 -- �ʉ݊��Z�^�C�v        :'User'
      , cv_rate                      -- ���Z���[�g            :'1'
      , it_trx_date                  -- ���������t            :���ߓ�
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--      , it_gl_date                   -- �d��v���            :�x���\���
      , it_trx_date                  -- �d��v���            :���ߓ�
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
      , gv_slip_number               -- �`�[�ԍ�              :�t�����擾�ɂĎ擾�����`�[�ԍ�
      , it_quantity                  -- ����                  :���v�s�F'1' �ŋ��s�FNULL
      , it_unit_selling_price        -- �P��                  :���׋��z�Ɠ����l
      , it_tax_code                  -- �ŋ敪                :����ŃR�[�h
      , gn_org_id                    -- DFF�R���e�L�X�g       :���������Ŏ擾�����g�DID
      , it_form_base                 -- �N�[����              :���_�R�[�h
      , it_form_typist               -- �`�[���͎�            :���ьv��S���҃R�[�h
      , it_charge_waiting_status     -- �������ۗ��X�e�[�^�X  :�t��VD'HOLD'��ݒ�B�ȊO��'OPEN'��ݒ�
      , cv_waiting                   -- �ʐ��������        :'WAITING'
      , cv_waiting                   -- �ꊇ���������        :'WAITING'
      , gv_cash_receiv_base_code     -- �������_�R�[�h        :�ڋq���P.�������_�R�[�h
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi ADD START
      , gt_ship_account_code                                    -- �o�א�ڋq�R�[�h
      , SUBSTRB( gt_ship_account_name, 1, cn_account_name_len ) -- �o�א�ڋq����
      , NULL                                                    -- �`�[�ԍ�
      , TO_CHAR( it_trx_date, cv_fmt_yyyy_mm_dd )               -- GL�L����
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi ADD END
      , SYSDATE                      -- �V�K�쐬���t          :SYSDATE
      , gn_org_id                    -- �I���OID              :���������Ŏ擾�����g�DID
      , gv_tax_flag                  -- ���Ńt���O            :AR�ŋ��}�X�^����擾
      );
    EXCEPTION
      WHEN  OTHERS THEN
-- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
--          -- *** AR�����l���A�g�f�[�^�o�^�G���[ ***
--          lv_out_msg := xxccp_common_pkg.get_msg(
--                          cv_appli_xxcok_name
--                        , cv_10280_err_msg
--                        , cv_dept_code_token
--                        , i_discnt_amount_rec.base_code
--                        , cv_vend_code_token
--                        , i_discnt_amount_rec.supplier_code
--                        , cv_vend_site_code_token
--                        , i_discnt_amount_rec.supplier_site_code
--                        , cv_account_date_token
--                        , TO_CHAR(i_discnt_amount_rec.closing_date, 'YYYYY/MM/DD' )
--                        );
          -- *** AR�����l���A�g�f�[�^�o�^�G���[ ***
          lv_out_msg := xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                        , cv_10280_err_msg
                        , cv_dept_code_token
                        , i_discnt_amount_rec.base_code
                        , cv_ship_cust_code_token
                        , i_discnt_amount_rec.delivery_cust_code
                        , cv_bill_cust_code_token
                        , i_discnt_amount_rec.demand_to_cust_code
                        , cv_account_date_token
                        , TO_CHAR( i_discnt_amount_rec.closing_date, 'YYYYY/MM/DD' )
                        );
-- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
          lb_retcode := xxcok_common_pkg.put_message_f( 
                          FND_FILE.OUTPUT    -- �o�͋敪
                        , lv_out_msg         -- ���b�Z�[�W
                        , 0                  -- ���s
                        );
          ov_errmsg  := NULL;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
          ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_ra_if_lines_all_p;
--
  /**********************************************************************************
   * Procedure Name   : ins_discnt_amount_ar_data_p
   * Description      : AR�A�g�f�[�^�̓o�^�i�������l�����j(A-5)
   ***********************************************************************************/
  PROCEDURE ins_discnt_amount_ar_data_p(
    ov_errbuf           OUT VARCHAR2                    -- �G���[�E���b�Z�[�W
  , ov_retcode          OUT VARCHAR2                    -- ���^�[���E�R�[�h
  , ov_errmsg           OUT VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_discnt_amount_rec IN  g_discnt_amount_cur%ROWTYPE -- ���R�[�h����
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_discnt_amount_ar_data_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                             -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;                             -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                 VARCHAR2(5000) DEFAULT NULL;                             -- ���b�Z�[�W�ϐ�
    lb_retcode                 BOOLEAN        DEFAULT NULL;                             -- ���b�Z�[�W�o�͖߂�l
    lt_charge_waiting_status   ra_interface_lines_all.header_attribute7%TYPE;           -- �������ۗ��X�e�[�^�X�i�[�ϐ�
    lt_line_type               ra_interface_lines_all.line_type%TYPE;                   -- ���׃^�C�v
    lt_line_amount             ra_interface_lines_all.amount%TYPE;                      -- ���׋��z
    lt_cust_trx_type_id        ra_interface_lines_all.cust_trx_type_id%TYPE;            -- ����^�C�vID
    lt_link_to_line_context    ra_interface_lines_all.link_to_line_context%TYPE;        -- �����N���׃R���e�L�X�g
    lt_link_to_line_attribute1 ra_interface_lines_all.link_to_line_attribute1%TYPE;     -- �����N�`�[�ԍ�
    lt_link_to_line_attribute2 ra_interface_lines_all.link_to_line_attribute2%TYPE;     -- �����N���׍s�ԍ�
    lt_quantity                ra_interface_lines_all.quantity%TYPE;                    -- ����
    lt_unit_selling_price      ra_interface_lines_all.unit_selling_price%TYPE;          -- �P��
    lv_segment2                VARCHAR2(100)  DEFAULT NULL;                             -- ����R�[�h
    lv_segment3                VARCHAR2(100)  DEFAULT NULL;                             -- ����ȖڃR�[�h
    lv_segment4                VARCHAR2(100)  DEFAULT NULL;                             -- �⏕�ȖڃR�[�h
    lt_distributions_amount    ra_interface_distributions_all.amount%TYPE;              -- ���׋��z
    lt_ccid                    ra_interface_distributions_all.code_combination_id%TYPE; -- CCID�̖߂�l
    lt_account_class           ra_interface_distributions_all.account_class%TYPE;       -- �z���^�C�v
    ln_cnt                     NUMBER         DEFAULT NULL;                             -- �J�E���g
    -- ===============================
    -- ���[�J���E��O
    -- ===============================
    ccid_expt EXCEPTION; -- ����Ȗڏ��擾�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
--
-- 2009/3/24     ver1.2   T.Taniguchi  DEL STR
--    gn_csh_rcpt := i_discnt_amount_rec.sum_csh_rcpt_discount_amt - i_discnt_amount_rec.sum_csh_rcpt_discount_amt_tax;
-- 2009/3/24     ver1.2   T.Taniguchi  DEL END
--
    <<ins_ra_if_lines_all_loop>>
    FOR ln_cnt IN 1..2 LOOP
--
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
---- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
----      IF( gv_business_low_type = cv_low_type ) THEN
----        lt_charge_waiting_status := cv_hold;             -- �����ނ̋敪HOLD
----        lt_cust_trx_type_id      := gn_vd_trx_type_id;   -- ����^�C�vID:VD������������
----      ELSE
----        lt_charge_waiting_status := cv_open;             -- �����ނ̋敪OPEN
----        lt_cust_trx_type_id      := gn_cust_trx_elec_id; -- ����^�C�vID:�d�C�����E
----      END IF;
----
--      IF( gv_business_low_type = cv_low_type ) THEN
--        lt_cust_trx_type_id      := g_cust_trx_type_vd.cust_trx_type_id;        -- VD������������F����^�C�vID
--        lt_charge_waiting_status := g_cust_trx_type_vd.charge_waiting_status;   -- VD������������F�������ۗ��X�e�[�^�X
--      ELSE
--        lt_cust_trx_type_id      := g_cust_trx_type_gnrl.cust_trx_type_id;      -- �����l�����F����^�C�vID
--        lt_charge_waiting_status := g_cust_trx_type_gnrl.charge_waiting_status; -- �����l�����F�������ۗ��X�e�[�^�X
--      END IF;
---- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
      -- �t��VD�i�����j
-- 2021/04/15 Ver1.12 MOD Start
      IF  gv_business_low_type  IN  ( cv_low_type_f_digestion_vd, cv_low_type_digestion_vd )
      AND i_discnt_amount_rec.closing_date  >=  TO_DATE('2021/05/01','YYYY/MM/DD')  THEN
        lt_cust_trx_type_id      := g_ra_trx_type_equipment.cust_trx_type_id;
        lt_charge_waiting_status := g_ra_trx_type_equipment.charge_waiting_status;
      ELSIF(    gv_business_low_type = cv_low_type_f_digestion_vd ) THEN
--      IF(    gv_business_low_type = cv_low_type_f_digestion_vd ) THEN
-- 2021/04/15 Ver1.12 MOD End
        lt_cust_trx_type_id      := g_ra_trx_type_f_digestion_vd.cust_trx_type_id;
        lt_charge_waiting_status := g_ra_trx_type_f_digestion_vd.charge_waiting_status;
      -- �[�iVD
      ELSIF( gv_business_low_type = cv_low_type_delivery_vd    ) THEN
        lt_cust_trx_type_id      := g_ra_trx_type_delivery_vd.cust_trx_type_id;
        lt_charge_waiting_status := g_ra_trx_type_delivery_vd.charge_waiting_status;
      -- ����VD
      ELSIF( gv_business_low_type = cv_low_type_digestion_vd   ) THEN
        lt_cust_trx_type_id      := g_ra_trx_type_digestion_vd.cust_trx_type_id;
        lt_charge_waiting_status := g_ra_trx_type_digestion_vd.charge_waiting_status;
      -- ��ʓX
      ELSE
        lt_cust_trx_type_id      := g_ra_trx_type_general.cust_trx_type_id;
        lt_charge_waiting_status := g_ra_trx_type_general.charge_waiting_status;
      END IF;
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
      --================================================================
      --���Ńt���O�̎擾����
      --================================================================
      BEGIN
        SELECT amount_includes_tax_flag   AS tax_flag                    -- ���Ńt���O
             , tax_rate                   AS tax_rate                    -- ����ŗ�
        INTO   gv_tax_flag
             , gn_tax_rate
        FROM   ar_vat_tax_all_b           avtab                          -- AR�ŋ��}�X�^
        WHERE  avtab.set_of_books_id      = gn_set_of_bks_id             -- ��v����ID
        AND    avtab.tax_code             = i_discnt_amount_rec.tax_code -- �ŃR�[�h
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi REPAIR START
--        AND    avtab.validate_flag       <> cv_validate_flag             -- �L���t���O
        AND    avtab.validate_flag        = cv_tax_validate_flag_valid     -- �L���t���O
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi REPAIR END
        AND    avtab.org_id               = gn_org_id                    -- �c�ƒP��ID
-- 2009/10/19 Ver.1.8 [��QE_T3_00631] SCS K.Yamaguchi REPAIR START
--        AND    gd_operation_date BETWEEN avtab.start_date AND NVL( avtab.end_date, ( gd_operation_date ) )
        AND    i_discnt_amount_rec.closing_date BETWEEN avtab.start_date
                                                    AND NVL( avtab.end_date, i_discnt_amount_rec.closing_date )
-- 2009/10/19 Ver.1.8 [��QE_T3_00631] SCS K.Yamaguchi REPAIR END
        ;
      END;
-- 2009/3/24     ver1.2   T.Taniguchi  ADD STR
      --================================================================
      --���z�̐ݒ�
      --================================================================
      -- ���ł̏ꍇ
      IF gv_tax_flag = cv_tax_flag_y THEN
        gn_csh_rcpt := ( i_discnt_amount_rec.sum_csh_rcpt_discount_amt ) * -1; -- (�ō����z) * -1
      -- �O�ł̏ꍇ
      ELSE
        gn_csh_rcpt := ( i_discnt_amount_rec.sum_csh_rcpt_discount_amt
                        - i_discnt_amount_rec.sum_csh_rcpt_discount_amt_tax ) * -1; -- (�ō����z - ����Ŋz) * -1
      END IF;
      -- ����Ŋz�̐ݒ�
      gn_tax_amt := ( i_discnt_amount_rec.sum_csh_rcpt_discount_amt_tax ) * -1;
-- 2009/3/24     ver1.2   T.Taniguchi  ADD END
      --================================================================
      --���v/�d��p�^�[���F�ؕ�
      --================================================================
      IF ( ln_cnt = 1 ) THEN
        lt_line_type               := cv_line_type;                                      -- ���׃^�C�v:���v�s
        lt_line_amount             := gn_csh_rcpt;                                       -- �����l���z�|�����l������Ŋz
        lt_link_to_line_context    := NULL;                                              -- �����N���׃R���e�L�X�g
        lt_link_to_line_attribute1 := NULL;                                              -- �����N�`�[�ԍ�
        lt_link_to_line_attribute2 := NULL;                                              -- �����N���׍s�ԍ�
        lt_quantity                := cn_quantity;                                       -- ����:���v�s1
        lt_unit_selling_price      := gn_csh_rcpt;                                       -- �����l���z�|�����l������Ŋz
        --================================================================
        --ins_ra_if_lines_all_p�̌Ăяo��(�����l���z)
        --================================================================
        ins_ra_if_lines_all_p(
          ov_errbuf                  => lv_errbuf
        , ov_retcode                 => lv_retcode
        , ov_errmsg                  => lv_errmsg
        , i_discnt_amount_rec        => i_discnt_amount_rec                     -- ���R�[�h����(�����l����)
        , it_spare                   => ln_cnt                                  -- �J�E���g
        , it_line_type               => lt_line_type                            -- ���׃^�C�v
        , it_amont                   => lt_line_amount                          -- ���׋��z
        , it_cust_trx_type_id        => lt_cust_trx_type_id                     -- ����^�C�vID
        , it_link_to_line_context    => lt_link_to_line_context                 -- �����N���׃R���e�L�X�g
        , it_link_to_line_attribute1 => lt_link_to_line_attribute1              -- �����N�`�[�ԍ�
        , it_link_to_line_attribute2 => lt_link_to_line_attribute2              -- �����N���׍s�ԍ�
        , it_trx_date                => i_discnt_amount_rec.closing_date        -- ���������t
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--        , it_gl_date                 => i_discnt_amount_rec.expect_payment_date -- �d��v���
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
        , it_quantity                => lt_quantity                             -- ����
        , it_unit_selling_price      => lt_unit_selling_price                   -- �P��
        , it_tax_code                => i_discnt_amount_rec.tax_code            -- �ŃR�[�h
        , it_form_base               => i_discnt_amount_rec.base_code           -- �N�[����
        , it_form_typist             => i_discnt_amount_rec.emp_code            -- �`�[���͎�
        , it_charge_waiting_status   => lt_charge_waiting_status                -- �������ۗ��X�e�[�^�X
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
        ELSIF( lv_retcode = cv_status_normal ) THEN
          gn_lines_cnt := gn_lines_cnt + 1;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
        END IF;
        --================================================================
      --�ŋ�/�d��p�^�[���F�ؕ�
      --================================================================
      ELSIF ( ln_cnt = 2 )
        AND ( gn_tax_rate <> 0 ) THEN
        lt_line_type               := cv_tax_class;                                      -- ���׃^�C�v:�ŋ��s
-- 2009/3/24     ver1.2   T.Taniguchi  MOD STR
--        lt_line_amount             := i_discnt_amount_rec.sum_csh_rcpt_discount_amt_tax; -- �����l������Ŋz
        lt_line_amount             := gn_tax_amt;                                          -- �����l������Ŋz
-- 2009/3/24     ver1.2   T.Taniguchi  MOD END
        lt_link_to_line_context    := gv_sales_category;                                 -- ���v�s�̖��׃R���e�L�X�g�l
        lt_link_to_line_attribute1 := gv_slip_number;                                    -- ���v�s�̓`�[�ԍ��l
        lt_link_to_line_attribute2 := cn_rev_num;                                        -- ���v�s�̖��׍s�`�[�ԍ��l
        lt_quantity                := NULL;                                              -- ����:�ŋ��sNULL
        lt_unit_selling_price      := NULL;                                              -- �P��:�ŋ��sNULL
        --================================================================
        --ins_ra_if_lines_all_p�̌Ăяo��(�����l���z)
        --================================================================
        ins_ra_if_lines_all_p(
          ov_errbuf                  => lv_errbuf
        , ov_retcode                 => lv_retcode
        , ov_errmsg                  => lv_errmsg
        , i_discnt_amount_rec        => i_discnt_amount_rec                     -- ���R�[�h����(�����l����)
        , it_spare                   => ln_cnt                                  -- �J�E���g
        , it_line_type               => lt_line_type                            -- ���׃^�C�v
        , it_amont                   => lt_line_amount                          -- ���׋��z
        , it_cust_trx_type_id        => lt_cust_trx_type_id                     -- ����^�C�vID
        , it_link_to_line_context    => lt_link_to_line_context                 -- �����N���׃R���e�L�X�g
        , it_link_to_line_attribute1 => lt_link_to_line_attribute1              -- �����N�`�[�ԍ�
        , it_link_to_line_attribute2 => lt_link_to_line_attribute2              -- �����N���׍s�ԍ�
        , it_trx_date                => i_discnt_amount_rec.closing_date        -- ���������t
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--        , it_gl_date                 => i_discnt_amount_rec.expect_payment_date -- �d��v���
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
        , it_quantity                => lt_quantity                             -- ����
        , it_unit_selling_price      => lt_unit_selling_price                   -- �P��
        , it_tax_code                => i_discnt_amount_rec.tax_code            -- �ŃR�[�h
        , it_form_base               => i_discnt_amount_rec.base_code           -- �N�[����
        , it_form_typist             => i_discnt_amount_rec.emp_code            -- �`�[���͎�
        , it_charge_waiting_status   => lt_charge_waiting_status                -- �������ۗ��X�e�[�^�X
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
        ELSIF( lv_retcode = cv_status_normal ) THEN
          gn_lines_cnt := gn_lines_cnt + 1;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
        END IF;
      END IF;
--
    END LOOP ins_ra_if_lines_all_loop;
--
    <<ins_ra_if_distributions_loop>>
    FOR ln_cnt IN 1..3 LOOP
      --================================================================
      --���v/�d��p�^�[���F�ؕ�
      --================================================================
      IF ( ln_cnt = 1 ) THEN
        lv_segment2             := i_discnt_amount_rec.base_code;                     -- ����R�[�h     :���_�R�[�h
-- 2021/04/15 Ver1.12 MOD Start
        IF  gv_business_low_type  IN  ( cv_low_type_f_digestion_vd, cv_low_type_digestion_vd )
        AND i_discnt_amount_rec.closing_date  >=  TO_DATE('2021/05/01','YYYY/MM/DD')  THEN
          lv_segment3             := gv_aff3_equipment_costs;                           -- ����ȖڃR�[�h :�ݔ���
          lv_segment4             := gv_aff4_equipment_costs;                           -- �⏕�ȖڃR�[�h :�ݔ���
        ELSE
          lv_segment3             := gv_aff3_allowance_payment;                         -- ����ȖڃR�[�h :�������l����
          lv_segment4             := gv_aff4_subacct_dummy;                             -- �⏕�ȖڃR�[�h :�_�~�[�l
        END IF;
--        lv_segment3             := gv_aff3_allowance_payment;                         -- ����ȖڃR�[�h :�������l����
--        lv_segment4             := gv_aff4_subacct_dummy;                             -- �⏕�ȖڃR�[�h :�_�~�[�l
-- 2021/04/15 Ver1.12 MOD End
        lt_account_class        := cv_rev_class;                                      -- �z���^�C�v(���v)
        lt_distributions_amount := gn_csh_rcpt;                                       -- ���׋��z:�����l���z�|�����l������Ŋz
        --================================================================
        --CCID�擾
        --================================================================
        lt_ccid := xxcok_common_pkg.get_code_combination_id_f( 
                     i_discnt_amount_rec.closing_date -- ������
                   , gv_aff1_company_code             -- ��ЃR�[�h
                   , lv_segment2                      -- ����R�[�h
                   , lv_segment3                      -- ����ȖڃR�[�h
                   , lv_segment4                      -- �⏕�ȖڃR�[�h
                   , gv_aff5_customer_dummy           -- �ڋq�R�[�h�_�~�[�l
                   , gv_aff6_compuny_dummy            -- ��ƃR�[�h�_�~�[�l
                   , gv_aff7_preliminary1_dummy       -- �\��1�_�~�[�l
                   , gv_aff8_preliminary2_dummy       -- �\��2�_�~�[�l
                   );
--
        IF lt_ccid IS NULL THEN
          RAISE ccid_expt;
        END IF;
        --================================================================
        --ins_ra_if_distributions_all_p�̌Ăяo��
        --================================================================
        ins_ra_if_distributions_all_p(
          ov_errbuf           => lv_errbuf
        , ov_retcode          => lv_retcode
        , ov_errmsg           => lv_errmsg
        , i_discnt_amount_rec => i_discnt_amount_rec     -- ���R�[�h����(�����l����)
        , it_count            => ln_cnt                  -- ���׍s�`�[�ԍ�
        , it_account_class    => lt_account_class        -- �z���^�C�v
        , it_amount           => lt_distributions_amount -- ���׋��z
        , it_ccid             => lt_ccid                 -- ����Ȗ�ID
        );
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF( lv_retcode = cv_status_normal ) THEN
          gn_distributions_cnt := gn_distributions_cnt + 1;
        END IF;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
      --================================================================
      --�ŋ�/�d��p�^�[���F�ؕ�
      --================================================================
      ELSIF ( ln_cnt = 2 )
        AND ( gn_tax_rate <> cn_no_tax ) THEN
        lv_segment2             := gv_aff2_dept_fin;                                  -- ����R�[�h     :�����o����
-- 2010/04/26 Ver.1.9 [E_�{�ғ�_02268] SCS S.Arizumi REPAIR START
--        lv_segment3             := gv_aff3_payment_excise_tax;                        -- ����ȖڃR�[�h :��������œ�
        lv_segment3             := gv_aff3_receive_excise_tax;                        -- ����ȖڃR�[�h :�������œ�
-- 2010/04/26 Ver.1.9 [E_�{�ғ�_02268] SCS S.Arizumi REPAIR END
        lv_segment4             := gv_aff4_subacct_dummy;                             -- �⏕�ȖڃR�[�h :�_�~�[�l
        lt_account_class        := cv_tax_class;                                      -- �z���^�C�v(�ŋ�)
-- 2009/3/24     ver1.2   T.Taniguchi  MOD STR
--        lt_distributions_amount := i_discnt_amount_rec.sum_csh_rcpt_discount_amt_tax; -- ���׋��z:�����l������Ŋz
        lt_distributions_amount := gn_tax_amt;                                       -- (���׋��z:�����l������Ŋz) * -1
-- 2009/3/24     ver1.2   T.Taniguchi  MOD END
        --================================================================
        --CCID�擾
        --================================================================
        lt_ccid := xxcok_common_pkg.get_code_combination_id_f( 
                   i_discnt_amount_rec.closing_date -- ������
                 , gv_aff1_company_code             -- ��ЃR�[�h
                 , lv_segment2                      -- ����R�[�h
                 , lv_segment3                      -- ����ȖڃR�[�h
                 , lv_segment4                      -- �⏕�ȖڃR�[�h
                 , gv_aff5_customer_dummy           -- �ڋq�R�[�h�_�~�[�l
                 , gv_aff6_compuny_dummy            -- ��ƃR�[�h�_�~�[�l
                 , gv_aff7_preliminary1_dummy       -- �\��1�_�~�[�l
                 , gv_aff8_preliminary2_dummy       -- �\��2�_�~�[�l
                 );
--
        IF lt_ccid IS NULL THEN
          RAISE ccid_expt;
        END IF;
        --================================================================
        --ins_ra_if_distributions_all_p�̌Ăяo��
        --================================================================
        ins_ra_if_distributions_all_p(
          ov_errbuf           => lv_errbuf
        , ov_retcode          => lv_retcode
        , ov_errmsg           => lv_errmsg
        , i_discnt_amount_rec => i_discnt_amount_rec     -- ���R�[�h����(�����l����)
        , it_count            => ln_cnt                  -- ���׍s�`�[�ԍ�
        , it_account_class    => lt_account_class        -- �z���^�C�v
        , it_amount           => lt_distributions_amount -- ���׋��z
        , it_ccid             => lt_ccid                 -- ����Ȗ�ID
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
        ELSIF( lv_retcode = cv_status_normal ) THEN
          gn_distributions_cnt := gn_distributions_cnt + 1;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
        END IF;
      --================================================================
      --���v/�d��p�^�[���F�ݕ�(�t���x���_�[(����))
      --================================================================
      ELSIF ( ln_cnt = 3 )
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--        AND ( gv_business_low_type = cv_low_type ) THEN
        AND ( gv_business_low_type = cv_low_type_f_digestion_vd ) THEN
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
        lv_segment2             := gv_aff2_dept_fin;                                  -- ����R�[�h     :�����o����
        lv_segment3             := gv_aff3_receivable;                                -- ����ȖڃR�[�h :��������
        lv_segment4             := gv_aff4_receivable_vd;                             -- �⏕�ȖڃR�[�h :��������VD����
        lt_account_class        := cv_rec_class;                                      -- �z���^�C�v(��)
        lt_distributions_amount := NULL;                                              -- ���׋��z:NULL
        --================================================================
        --CCID�擾
        --================================================================
        lt_ccid := xxcok_common_pkg.get_code_combination_id_f( 
                   i_discnt_amount_rec.closing_date -- ������
                 , gv_aff1_company_code             -- ��ЃR�[�h
                 , lv_segment2                      -- ����R�[�h
                 , lv_segment3                      -- ����ȖڃR�[�h
                 , lv_segment4                      -- �⏕�ȖڃR�[�h
                 , gv_aff5_customer_dummy           -- �ڋq�R�[�h�_�~�[�l
                 , gv_aff6_compuny_dummy            -- ��ƃR�[�h�_�~�[�l
                 , gv_aff7_preliminary1_dummy       -- �\��1�_�~�[�l
                 , gv_aff8_preliminary2_dummy       -- �\��2�_�~�[�l
                 );
--
        IF lt_ccid IS NULL THEN
          RAISE ccid_expt;
        END IF;
        --================================================================
        --ins_ra_if_distributions_all_p�̌Ăяo��
        --================================================================
        ins_ra_if_distributions_all_p(
          ov_errbuf           => lv_errbuf
        , ov_retcode          => lv_retcode
        , ov_errmsg           => lv_errmsg
        , i_discnt_amount_rec => i_discnt_amount_rec     -- ���R�[�h����(�����l����)
-- Start 2009/04/20 Ver_1.5 T1_0512 M.Hiruta
--        , it_count            => ln_cnt                  -- ���׍s�`�[�ԍ�
        , it_count            => cv_line_slip_rec        -- ���׍s�`�[�ԍ�
-- End   2009/04/20 Ver_1.5 T1_0512 M.Hiruta
        , it_account_class    => lt_account_class        -- �z���^�C�v
        , it_amount           => lt_distributions_amount -- ���׋��z
        , it_ccid             => lt_ccid                 -- ����Ȗ�ID
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
        ELSIF( lv_retcode = cv_status_normal ) THEN
          gn_distributions_cnt := gn_distributions_cnt + 1;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
        END IF;
      --================================================================
      --���v/�d��p�^�[���F�ݕ�(���)
      --================================================================
      ELSIF ( ln_cnt = 3 )
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--        AND  ( gv_business_low_type <> cv_low_type ) THEN
        AND  ( gv_business_low_type <> cv_low_type_f_digestion_vd ) THEN
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
        lv_segment2             := gv_aff2_dept_fin;                                  -- ����R�[�h     :�����o����
        lv_segment3             := gv_aff3_account_receivable;                        -- ����ȖڃR�[�h :���|��
        lv_segment4             := gv_aff4_subacct_dummy;                             -- �⏕�ȖڃR�[�h :�_�~�[�l
        lt_account_class        := cv_rec_class;                                      -- �z���^�C�v(��)
        lt_distributions_amount := NULL;                                              -- ���׋��z:NULL
        --================================================================
        --CCID�擾
        --================================================================
        lt_ccid := xxcok_common_pkg.get_code_combination_id_f( 
                   i_discnt_amount_rec.closing_date -- ������
                 , gv_aff1_company_code             -- ��ЃR�[�h
                 , lv_segment2                      -- ����R�[�h
                 , lv_segment3                      -- ����ȖڃR�[�h
                 , lv_segment4                      -- �⏕�ȖڃR�[�h
                 , gv_aff5_customer_dummy           -- �ڋq�R�[�h�_�~�[�l
                 , gv_aff6_compuny_dummy            -- ��ƃR�[�h�_�~�[�l
                 , gv_aff7_preliminary1_dummy       -- �\��1�_�~�[�l
                 , gv_aff8_preliminary2_dummy       -- �\��2�_�~�[�l
                 );
--
        IF lt_ccid IS NULL THEN
          RAISE ccid_expt;
        END IF;
        --================================================================
        --ins_ra_if_distributions_all_p�̌Ăяo��
        --================================================================
        ins_ra_if_distributions_all_p(
          ov_errbuf           => lv_errbuf
        , ov_retcode          => lv_retcode
        , ov_errmsg           => lv_errmsg
        , i_discnt_amount_rec => i_discnt_amount_rec     -- ���R�[�h����(�����l����)
-- Start 2009/04/20 Ver_1.5 T1_0512 M.Hiruta
--        , it_count            => ln_cnt                  -- ���׍s�`�[�ԍ�
        , it_count            => cv_line_slip_rec        -- ���׍s�`�[�ԍ�
-- End   2009/04/20 Ver_1.5 T1_0512 M.Hiruta
        , it_account_class    => lt_account_class        -- �z���^�C�v
        , it_amount           => lt_distributions_amount -- ���׋��z
        , it_ccid             => lt_ccid                 -- ����Ȗ�ID
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
        ELSIF( lv_retcode = cv_status_normal ) THEN
          gn_distributions_cnt := gn_distributions_cnt + 1;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
        END IF;
--
      END IF;
--
    END LOOP ins_ra_if_distributions_loop;
--
  EXCEPTION
    -- *** ����Ȗڏ��擾�G���[ ****
    WHEN ccid_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00034_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_discnt_amount_ar_data_p;
--
  /**********************************************************************************
   * Procedure Name   : get_discnt_amnt_add_ar_data_p
   * Description      : AR�A�g�f�[�^�t�����̎擾(�������l����)(A-4)
   ***********************************************************************************/
  PROCEDURE get_discnt_amnt_add_ar_data_p(
    ov_errbuf           OUT VARCHAR2                    -- �G���[�E���b�Z�[�W
  , ov_retcode          OUT VARCHAR2                    -- ���^�[���E�R�[�h
  , ov_errmsg           OUT VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_discnt_amount_rec IN  g_discnt_amount_cur%ROWTYPE -- ���R�[�h����
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_discnt_amnt_add_ar_data_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg         VARCHAR2(5000) DEFAULT NULL; -- ���b�Z�[�W�ϐ�
    lb_retcode         BOOLEAN        DEFAULT NULL; -- ���b�Z�[�W�o�͖߂�l
    -- ===============================
    -- ���[�J���E��O
    -- ===============================
    get_slip_number_expt EXCEPTION; -- �`�[�ԍ��擾�G���[
    get_cust_info_expt   EXCEPTION; -- �ڋq���擾�G���[
    get_term_info_expt   EXCEPTION; -- �x���������擾�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==================================================================
    --�o�^�t�����擾
    --==================================================================
    gv_slip_number := xxcok_common_pkg.get_slip_number_f(
                        cv_pkg_name -- �{�@�\�̃p�b�P�[�W��
                      );
    IF( gv_slip_number IS NULL ) THEN
      RAISE get_slip_number_expt;
    END IF;
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi REPAIR START
--    --==================================================================
--    --�[�i�ڋq�R�[�h�ɕR�Â��ڋq�����擾
--    --==================================================================
--    BEGIN
--      SELECT xhv.ship_account_id       AS ship_account_id                       -- �o�א�ڋqID
--           , xhv.cash_receiv_base_code AS cash_receiv_base_code                 -- �������_�R�[�h
--           , xca.business_low_type     AS business_low_type                     -- �Ƒԁi�����ށj
--      INTO   gn_ship_account_id
--           , gv_cash_receiv_base_code
--           , gv_business_low_type
--      FROM   xxcfr_cust_hierarchy_v    xhv                                      -- �ڋq�K�w�r���[
--           , hz_cust_accounts          hca                                      -- �ڋq�}�X�^
--           , xxcmm_cust_accounts       xca                                      -- ������ڋq�ǉ����
--      WHERE  hca.cust_account_id       = xca.customer_id                        -- �ڋqID = �ڋqID
--      AND    xhv.ship_account_number   = i_discnt_amount_rec.delivery_cust_code -- �ڋq�R�[�h = �[�i�ڋq�R�[�h
--      AND    xhv.ship_account_number   = xca.customer_code;                     -- �ڋq�R�[�h = �ڋq�R�[�h
----
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        RAISE get_cust_info_expt;
--    END;
--    --==================================================================
--    --�o�א�ڋqID�ɕR�Â��ڋq�T�C�gID���擾
--    --==================================================================
--    BEGIN
--      SELECT hcasa.cust_acct_site_id AS cust_acct_site_id                       -- �ڋq�T�C�gID
--      INTO   gn_ship_address_id
--      FROM   hz_cust_acct_sites_all  hcasa                                      -- �ڋq�T�C�g�}�X�^
--      WHERE  hcasa.cust_account_id   = gn_ship_account_id                       -- �o�א�ڋqID
---- Start 2009/04/15 Ver_1.4 T1_0554 M.Hiruta
--      AND    hcasa.org_id            = gn_org_id;                               -- �g�DID
---- End   2009/04/15 Ver_1.4 T1_0554 M.Hiruta
----
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        RAISE get_cust_info_expt;
--    END;
--    --==================================================================
--    --�����ڋq�R�[�h�ɕR�Â��ڋq�����擾
--    --==================================================================
--    BEGIN
--      SELECT xhv.bill_account_id     AS bill_account_id                         -- ������ڋqID
--      INTO   gn_bill_account_id
--      FROM   xxcfr_cust_hierarchy_v  xhv                                        -- �ڋq�K�w�r���[
--      WHERE  xhv.bill_account_number = i_discnt_amount_rec.demand_to_cust_code  -- �����ڋq�R�[�h
---- Start 2009/04/15 Ver_1.4 T1_0554 M.Hiruta
--      AND    xhv.ship_account_number = i_discnt_amount_rec.delivery_cust_code;  -- �[�i�ڋq�R�[�h
---- End   2009/04/15 Ver_1.4 T1_0554 M.Hiruta
----
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        RAISE get_cust_info_expt;
--    END;
--    --==================================================================
--    --������ڋqID�ɕR�Â��ڋq�T�C�gID���擾
--    --==================================================================
--    BEGIN
--      SELECT hcasa.cust_acct_site_id AS cust_acct_site_id                       -- �ڋq�T�C�gID
--      INTO   gn_bill_address_id
--      FROM   hz_cust_acct_sites_all  hcasa                                      -- �ڋq�T�C�g�}�X�^
--      WHERE  hcasa.cust_account_id   = gn_bill_account_id                       -- ������ڋqID
---- Start 2009/04/15 Ver_1.4 T1_0554 M.Hiruta
--      AND    hcasa.org_id            = gn_org_id;                               -- �g�DID
---- End   2009/04/15 Ver_1.4 T1_0554 M.Hiruta
----
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        RAISE get_cust_info_expt;
--    END;
    --==================================================================
    -- �ڋq�����擾
    --==================================================================
    BEGIN
      SELECT    xchv.cash_receiv_base_code  AS cash_receiv_base_code  -- �������_�R�[�h
              , ship_xca.business_low_type  AS ship_business_low_type -- �y�o�א�z�Ƒ�(������)
              , xchv.ship_account_id        AS ship_account_id        -- �y�o�א�z�ڋqID
              , ship_hcas.cust_acct_site_id AS ship_acct_site_id      -- �y�o�א�z�ڋq�T�C�gID
              , xchv.ship_account_number    AS ship_account_number    -- �y�o�א�z�ڋq�R�[�h
              , xchv.ship_account_name      AS ship_account_name      -- �y�o�א�z�ڋq��
              , xchv.bill_account_id        AS bill_account_id        -- �y������z�ڋqID
              , bill_hcas.cust_acct_site_id AS bill_acct_site_id      -- �y������z�ڋq�T�C�gID
      INTO  gv_cash_receiv_base_code  -- �������_�R�[�h
          , gv_business_low_type      -- �Ƒ�(������)
          , gn_ship_account_id        -- �o�א�ڋqID
          , gn_ship_address_id        -- �o�א�ڋq�T�C�gID
          , gt_ship_account_code      -- �o�א�ڋq�R�[�h
          , gt_ship_account_name      -- �o�א�ڋq��
          , gn_bill_account_id        -- ������ڋqID
          , gn_bill_address_id        -- ������ڋq�T�C�gID
      FROM      xxcfr_cust_hierarchy_v  xchv      -- �ڋq�K�w�r���[
              , xxcmm_cust_accounts     ship_xca  -- �y�o�א�z�ڋq�A�h�I��
              , hz_cust_acct_sites      ship_hcas -- �y�o�א�z�ڋq�T�C�g�}�X�^
              , hz_cust_acct_sites      bill_hcas -- �y������z�ڋq�T�C�g�}�X�^
      WHERE     xchv.ship_account_number  =  i_discnt_amount_rec.delivery_cust_code
        AND     xchv.bill_account_number  =  i_discnt_amount_rec.demand_to_cust_code
        AND     ship_xca.customer_id      =  xchv.ship_account_id
        AND     ship_hcas.cust_account_id =  ship_xca.customer_id
        AND     ship_hcas.status          =  cv_cust_status_available -- �X�e�[�^�X�F�L��
        AND     bill_hcas.cust_account_id =  xchv.bill_account_id
        AND     bill_hcas.status          =  cv_cust_status_available -- �X�e�[�^�X�F�L��
      ;
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi REPAIR END
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_cust_info_expt;
    END;
    --==================================================================
    --�x�������ɕR�Â��x�����������擾
    --==================================================================
    BEGIN
      SELECT rtt.term_id  AS term_id                      -- �x������ID
      INTO   gn_term_id
      FROM   ra_terms_tl  rtt                             -- �x�������e�[�u��
      WHERE  rtt.name     = i_discnt_amount_rec.term_code -- �x�������� = �x������
      AND    rtt.language = gv_language;                  -- ���� = 'JA'
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_term_info_expt;
    END;
--
  EXCEPTION
    -- *** �`�[�ԍ��擾�G���[ ***
    WHEN get_slip_number_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00025_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �ڋq���擾�G���[ ***
    WHEN get_cust_info_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00035_err_msg
                    , cv_cust_code_token
                    , i_discnt_amount_rec.delivery_cust_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki MOD START
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_warn;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki MOD END
    -- *** �x���������擾�G���[ ***
    WHEN get_term_info_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00032_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_discnt_amnt_add_ar_data_p;
--
  /**********************************************************************************
   * Procedure Name   : chk_discnt_amount_ar_info_p
   * Description      : �Ó����`�F�b�N�̏���(�������l����)(A-3)
   ***********************************************************************************/
  PROCEDURE chk_discnt_amount_ar_info_p(
    ov_errbuf           OUT VARCHAR2                    -- �G���[�E���b�Z�[�W
  , ov_retcode          OUT VARCHAR2                    -- ���^�[���E�R�[�h
  , ov_errmsg           OUT VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_discnt_amount_rec IN  g_discnt_amount_cur%ROWTYPE -- ���R�[�h����
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_discnt_amount_ar_info_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg    VARCHAR2(5000) DEFAULT NULL; -- ���b�Z�[�W�ϐ�
    lb_retcode    BOOLEAN        DEFAULT NULL; -- ���b�Z�[�W�o�͖߂�l
    lb_set_of_bks BOOLEAN        DEFAULT NULL; -- ��v���ԃ`�F�b�N�߂�l
    -- ===============================
    -- ���[�J����O
    -- ===============================
    chk_acctg_period_expt EXCEPTION; -- ��v���ԃ`�F�b�N�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --��v���ԃ`�F�b�N
    --==============================================================
    lb_set_of_bks := xxcok_common_pkg.check_acctg_period_f(
                       gn_set_of_bks_id                        -- ��v����ID
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--                     , i_discnt_amount_rec.expect_payment_date -- ������(�x���\���)
                     , i_discnt_amount_rec.closing_date        -- ������(���ߓ�)
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
                     , cv_appli_ar_name                        -- �A�v���P�[�V�����Z�k��
                     );
    IF( lb_set_of_bks = FALSE ) THEN
      RAISE chk_acctg_period_expt;
    END IF;
--
  EXCEPTION
    -- *** ��v���ԃ`�F�b�N�G���[ ****
    WHEN chk_acctg_period_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00042_err_msg
                    , cv_proc_date_token
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--                    , TO_CHAR( i_discnt_amount_rec.expect_payment_date, 'YYYY/MM/DD' )
                    , TO_CHAR( i_discnt_amount_rec.closing_date, 'YYYY/MM/DD' )
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END chk_discnt_amount_ar_info_p;
--
  /**********************************************************************************
   * Procedure Name   : get_discnt_amount_ar_data_p
   * Description      : AR�A�g�f�[�^�̎擾(�������l����)(A-2)
   ***********************************************************************************/
  PROCEDURE get_discnt_amount_ar_data_p(
    ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_discnt_amount_ar_data_p'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(5000) DEFAULT NULL; -- ���b�Z�[�W�ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL; -- ���b�Z�[�W�o�͖߂�l
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
    lv_sub_retcode VARCHAR2(1) DEFAULT NULL; -- �ޔ����^�[���E�R�[�h
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
--
  BEGIN
    ov_retcode := cv_status_normal;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
    lv_sub_retcode:= cv_status_normal;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
--
    <<ar_coordination_data_loop>>
    FOR g_discnt_amount_rec IN g_discnt_amount_cur LOOP
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi ADD START
      --================================================================
      --�O���[�o���ϐ��̏�����
      --================================================================
      gv_slip_number            := NULL;  -- �`�[�ԍ�
      gv_cash_receiv_base_code  := NULL;  -- �������_�R�[�h
      gv_business_low_type      := NULL;  -- �Ƒ�(������)
      gn_ship_account_id        := NULL;  -- �o�א�ڋqID
      gn_ship_address_id        := NULL;  -- �o�א�ڋq�T�C�gID
      gt_ship_account_code      := NULL;  -- �o�א�ڋq�R�[�h
      gt_ship_account_name      := NULL;  -- �o�א�ڋq��
      gn_bill_account_id        := NULL;  -- ������ڋqID
      gn_bill_address_id        := NULL;  -- ������ڋq�T�C�gID
      gn_term_id                := NULL;  -- �x������ID
      gv_tax_flag               := NULL;  -- ����ŐŃt���O
      gn_tax_rate               := NULL;  -- ����ŗ�
      gn_tax_amt                := NULL;  -- ����Ŋz
-- 2010/07/09 Ver.1.10 [E_�{�ғ�_02001] SCS S.Arizumi ADD START
      --================================================================
      --�������l���̒��o����
      --================================================================
      gn_target_cnt :=  gn_target_cnt + 1;
      --================================================================
      --chk_discnt_amount_ar_info_p�̌Ăяo��(A-3)
      --================================================================
      chk_discnt_amount_ar_info_p(
        ov_errbuf              => lv_errbuf
      , ov_retcode             => lv_retcode
      , ov_errmsg              => lv_errmsg
      , i_discnt_amount_rec    => g_discnt_amount_rec
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki MOD START
--      --================================================================
--      --get_discnt_amnt_add_ar_data_p�̌Ăяo��(A-4)
--      --================================================================
--      get_discnt_amnt_add_ar_data_p(
--        ov_errbuf              => lv_errbuf
--      , ov_retcode             => lv_retcode
--      , ov_errmsg              => lv_errmsg
--      , i_discnt_amount_rec    => g_discnt_amount_rec
--      );
----
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      --================================================================
--      --ins_discnt_amount_ar_data_p�̌Ăяo��(A-5)
--      --================================================================
--      ins_discnt_amount_ar_data_p(
--        ov_errbuf              => lv_errbuf 
--      , ov_retcode             => lv_retcode
--      , ov_errmsg              => lv_errmsg 
--      , i_discnt_amount_rec    => g_discnt_amount_rec 
--      );
----
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
----
      --================================================================
      --get_discnt_amnt_add_ar_data_p�̌Ăяo��(A-4)
      --================================================================
      get_discnt_amnt_add_ar_data_p(
        ov_errbuf              => lv_errbuf
      , ov_retcode             => lv_retcode
      , ov_errmsg              => lv_errmsg
      , i_discnt_amount_rec    => g_discnt_amount_rec
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        gn_error_cnt   := gn_error_cnt + 1;
        -- ���^�[���E�R�[�h��ޔ�
        lv_sub_retcode := lv_retcode;
      ELSIF( lv_retcode = cv_status_normal ) THEN
        --================================================================
        --ins_discnt_amount_ar_data_p�̌Ăяo��(A-5)
        --================================================================
        ins_discnt_amount_ar_data_p(
          ov_errbuf              => lv_errbuf 
        , ov_retcode             => lv_retcode
        , ov_errmsg              => lv_errmsg 
        , i_discnt_amount_rec    => g_discnt_amount_rec 
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        --==============================================================
        --upd_ coordination_result_p(�A�g���ʂ̍X�V(A-8))�̌Ăяo��
        --==============================================================
        upd_coordination_result_p(
          ov_errbuf              => lv_errbuf
        , ov_retcode             => lv_retcode
        , ov_errmsg              => lv_errmsg
        , i_discnt_amount_rec    => g_discnt_amount_rec 
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF( lv_retcode = cv_status_normal ) THEN
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
      END IF;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki MOD END
--
    END LOOP ar_coordination_data_loop;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
    IF( lv_sub_retcode <> cv_status_normal ) THEN
        ov_retcode := lv_sub_retcode;
    END IF;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_discnt_amount_ar_data_p;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg     VARCHAR2(5000) DEFAULT NULL; -- ���b�Z�[�W�ϐ�
    lb_retcode     BOOLEAN        DEFAULT NULL; -- ���b�Z�[�W�o�͖߂�l
    lv_token_value VARCHAR2(5000) DEFAULT NULL; -- �g�[�N���o�����[
    -- ===============================
    -- ���[�J����O
    -- ===============================
    profile_expt        EXCEPTION; -- �v���t�@�C���擾�G���[
    operation_date_expt EXCEPTION; -- �Ɩ��������t�擾�G���[
    get_trx_type_expt   EXCEPTION; -- ����^�C�v���擾�G���[
    currency_code_expt  EXCEPTION; -- �ʉ݃R�[�h�擾�G���[
-- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
--    -- ===============================
--    -- ���[�J���E�J�[�\��
--    -- ===============================
--    CURSOR l_cust_trx_type_cur(
--      iv_cust_trx_type IN VARCHAR2
--    )
--    IS
--      SELECT rctta.cust_trx_type_id AS cust_trx_type_id --����^�C�vID
--      FROM   ra_cust_trx_types_all  rctta               --��������^�C�v�}�X�^
--      WHERE  rctta.name             = iv_cust_trx_type  --�d��\�[�X�� = ���������Ŏ擾��������^�C�v
--      AND    rctta.org_id           = gn_org_id         --�g�DID       = �g�DID
--      AND    gd_operation_date  BETWEEN rctta.start_date AND NVL( rctta.end_date, gd_operation_date );
-- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --�R���J�����g���̓p�����[�^�Ȃ����ڂ����b�Z�[�W�o��
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_90008_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.LOG       -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
    --==============================================================
    --�Ɩ��������t���擾
    --==============================================================
    gd_operation_date := xxccp_common_pkg2.get_process_date;
--
    IF( gd_operation_date IS NULL ) THEN
      RAISE operation_date_expt;
    END IF;
    --==============================================================
    --�v���t�@�C�����擾
    --==============================================================
    gn_set_of_bks_id           := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id )); -- ��v����ID
    gn_org_id                  := TO_NUMBER(FND_PROFILE.VALUE( cv_org_id        )); -- �g�DID
    gv_aff1_company_code       := FND_PROFILE.VALUE( cv_aff1_company_code       );  -- ��ЃR�[�h
    gv_aff2_dept_fin           := FND_PROFILE.VALUE( cv_aff2_dept_fin           );  -- ����R�[�h�F�����o����
    gv_aff5_customer_dummy     := FND_PROFILE.VALUE( cv_aff5_customer_dummy     );  -- �_�~�[�l:�ڋq�R�[�h
    gv_aff6_compuny_dummy      := FND_PROFILE.VALUE( cv_aff6_compuny_dummy      );  -- �_�~�[�l:��ƃR�[�h
    gv_aff7_preliminary1_dummy := FND_PROFILE.VALUE( cv_aff7_preliminary1_dummy );  -- �_�~�[�l:�\���P
    gv_aff8_preliminary2_dummy := FND_PROFILE.VALUE( cv_aff8_preliminary2_dummy );  -- �_�~�[�l:�\���Q
    gv_aff3_allowance_payment  := FND_PROFILE.VALUE( cv_aff3_allowance_payment  );  -- ����Ȗ�:�������l����
-- 2010/04/26 Ver.1.9 [E_�{�ғ�_02268] SCS S.Arizumi REPAIR START
--    gv_aff3_payment_excise_tax := FND_PROFILE.VALUE( cv_aff3_payment_excise_tax );  -- ����Ȗ�:��������œ�
    gv_aff3_receive_excise_tax := FND_PROFILE.VALUE( cv_aff3_receive_excise_tax );  -- ����Ȗ�:�������œ�
-- 2010/04/26 Ver.1.9 [E_�{�ғ�_02268] SCS S.Arizumi REPAIR END
    gv_aff3_receivable         := FND_PROFILE.VALUE( cv_aff3_receivable         );  -- ����Ȗ�:��������
    gv_aff3_account_receivable := FND_PROFILE.VALUE( cv_aff3_account_receivable );  -- ����Ȗ�:���|��
    gv_aff4_receivable_vd      := FND_PROFILE.VALUE( cv_aff4_receivable_vd      );  -- �⏕�Ȗ�:��������VD����
    gv_aff4_subacct_dummy      := FND_PROFILE.VALUE( cv_aff4_subacct_dummy      );  -- �⏕�Ȗ�:�_�~�[�l
    gv_sales_category          := FND_PROFILE.VALUE( cv_sales_category          );  -- �̔��萔��:�d��J�e�S��
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--    gv_cust_trx_type_vd        := FND_PROFILE.VALUE( cv_cust_trx_type_vd        );  -- ����^�C�v:VD������������
---- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
----    gv_cust_trx_type_elec_cost := FND_PROFILE.VALUE( cv_cust_trx_type_elec_cost );  -- ����^�C�v:�d�C�����E
--    gv_cust_trx_type_gnrl      := FND_PROFILE.VALUE( cv_cust_trx_type_gnrl      );  -- ����^�C�v:�����l����
---- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
    gv_ra_trx_type_f_digestion_vd := FND_PROFILE.VALUE( cv_ra_trx_type_f_digestion_vd  );  -- ����^�C�v_�����l��_�t��VD�i�����j
    gv_ra_trx_type_delivery_vd    := FND_PROFILE.VALUE( cv_ra_trx_type_delivery_vd     );  -- ����^�C�v_�����l��_�[�iVD
    gv_ra_trx_type_digestion_vd   := FND_PROFILE.VALUE( cv_ra_trx_type_digestion_vd    );  -- ����^�C�v_�����l��_����VD
    gv_ra_trx_type_general        := FND_PROFILE.VALUE( cv_ra_trx_type_general         );  -- ����^�C�v_�����l��_��ʓX
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
-- 2021/04/15 Ver1.12 ADD Start
    gv_aff3_equipment_costs    := FND_PROFILE.VALUE( cv_aff3_equipment_costs );     -- ����Ȗ�_�ݔ���
    gv_aff4_equipment_costs    := FND_PROFILE.VALUE( cv_aff4_equipment_costs );     -- �⏕�Ȗ�_�ݔ���
    gv_ra_trx_type_equipment   := FND_PROFILE.VALUE( cv_ra_trx_type_equipment );    -- ����^�C�v_�ݔ���
-- 2021/04/15 Ver1.12 ADD End
--
    IF( gn_set_of_bks_id IS NULL ) THEN
      lv_token_value := cv_set_of_bks_id;
      RAISE profile_expt;
--
    ELSIF( gn_org_id IS NULL ) THEN
      lv_token_value := cv_org_id;
      RAISE profile_expt;
--
    ELSIF( gv_aff1_company_code IS NULL ) THEN
      lv_token_value := cv_aff1_company_code;
      RAISE profile_expt;
--
    ELSIF( gv_aff2_dept_fin IS NULL ) THEN
      lv_token_value := cv_aff2_dept_fin;
      RAISE profile_expt;
--
    ELSIF( gv_aff5_customer_dummy IS NULL ) THEN
      lv_token_value := cv_aff5_customer_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff6_compuny_dummy IS NULL ) THEN
      lv_token_value := cv_aff6_compuny_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff7_preliminary1_dummy IS NULL ) THEN
      lv_token_value := cv_aff7_preliminary1_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff8_preliminary2_dummy IS NULL ) THEN
      lv_token_value := cv_aff8_preliminary2_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff3_allowance_payment IS NULL ) THEN
      lv_token_value := cv_aff3_allowance_payment;
      RAISE profile_expt;
--
-- 2010/04/26 Ver.1.9 [E_�{�ғ�_02268] SCS S.Arizumi REPAIR START
--    ELSIF( gv_aff3_payment_excise_tax IS NULL ) THEN
--      lv_token_value := cv_aff3_payment_excise_tax;
--      RAISE profile_expt;
    ELSIF( gv_aff3_receive_excise_tax IS NULL ) THEN
      lv_token_value := cv_aff3_receive_excise_tax;
      RAISE profile_expt;
-- 2010/04/26 Ver.1.9 [E_�{�ғ�_02268] SCS S.Arizumi REPAIR END
--
    ELSIF( gv_aff3_receivable IS NULL ) THEN
      lv_token_value := cv_aff3_receivable;
      RAISE profile_expt;
--
    ELSIF( gv_aff3_account_receivable IS NULL ) THEN
      lv_token_value := cv_aff3_account_receivable;
      RAISE profile_expt;
--
    ELSIF( gv_aff4_subacct_dummy IS NULL ) THEN
      lv_token_value := cv_aff4_subacct_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff4_receivable_vd IS NULL ) THEN
      lv_token_value := cv_aff4_receivable_vd;
      RAISE profile_expt;
--
    ELSIF( gv_sales_category IS NULL ) THEN
      lv_token_value := cv_sales_category;
      RAISE profile_expt;
--
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--    ELSIF( gv_cust_trx_type_vd IS NULL ) THEN
--      lv_token_value := cv_cust_trx_type_vd;
--      RAISE profile_expt;
----      
---- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
----    ELSIF( gv_cust_trx_type_elec_cost IS NULL ) THEN
----      lv_token_value := cv_cust_trx_type_elec_cost;
----      RAISE profile_expt;
--    ELSIF( gv_cust_trx_type_gnrl IS NULL ) THEN
--      lv_token_value := cv_cust_trx_type_gnrl;
--      RAISE profile_expt;
---- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
----
    -- ����^�C�v_�����l��_�t��VD�i�����j
    ELSIF( gv_ra_trx_type_f_digestion_vd IS NULL ) THEN
      lv_token_value := cv_ra_trx_type_f_digestion_vd;
      RAISE profile_expt;
    -- ����^�C�v_�����l��_�[�iVD
    ELSIF( gv_ra_trx_type_delivery_vd IS NULL ) THEN
      lv_token_value := cv_ra_trx_type_delivery_vd;
      RAISE profile_expt;
    -- ����^�C�v_�����l��_����VD
    ELSIF( gv_ra_trx_type_digestion_vd IS NULL ) THEN
      lv_token_value := cv_ra_trx_type_digestion_vd;
      RAISE profile_expt;
    -- ����^�C�v_�����l��_��ʓX
    ELSIF( gv_ra_trx_type_general IS NULL ) THEN
      lv_token_value := cv_ra_trx_type_general;
      RAISE profile_expt;
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
-- 2021/04/15 Ver1.12 ADD Start
    ELSIF( gv_aff3_equipment_costs IS NULL ) THEN
      lv_token_value := cv_aff3_equipment_costs;
      RAISE profile_expt;
    ELSIF( gv_aff4_equipment_costs IS NULL ) THEN
      lv_token_value := cv_aff4_equipment_costs;
      RAISE profile_expt;
    ELSIF( gv_ra_trx_type_equipment IS NULL ) THEN
      lv_token_value := cv_ra_trx_type_equipment;
      RAISE profile_expt;
-- 2021/04/15 Ver1.12 ADD End
    END IF;
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
---- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
----    --==============================================================
----    --VD������������̎���^�C�vID���擾
----    --==============================================================    
----    OPEN l_cust_trx_type_cur(
----           gv_cust_trx_type_vd -- VD������������̎���^�C�v
----         );
----    FETCH l_cust_trx_type_cur INTO gn_vd_trx_type_id;
----    CLOSE l_cust_trx_type_cur;
----    IF( gn_vd_trx_type_id IS NULL ) THEN
----      lv_token_value := gv_cust_trx_type_vd;
----      RAISE get_trx_type_expt;
----    END IF;
----    --==============================================================
----    --�d�C�����E�̎���^�C�vID���擾
----    --==============================================================    
----    OPEN l_cust_trx_type_cur(
----           gv_cust_trx_type_elec_cost -- �d�C�����E�̎���^�C�v
----         );
----    FETCH l_cust_trx_type_cur INTO gn_cust_trx_elec_id;
----    CLOSE l_cust_trx_type_cur;
----    IF( gn_cust_trx_elec_id IS NULL ) THEN
----      lv_token_value := gv_cust_trx_type_elec_cost;
----      RAISE get_trx_type_expt;
----    END IF;
--    --==============================================================
--    --VD������������̎���^�C�v�����擾
--    --==============================================================
--    OPEN g_cust_trx_type_cur(
--           gv_cust_trx_type_vd -- VD������������̎���^�C�v
--         );
--    FETCH g_cust_trx_type_cur INTO g_cust_trx_type_vd;
--    CLOSE g_cust_trx_type_cur;
--    IF( g_cust_trx_type_vd.cust_trx_type_id IS NULL ) THEN
--      lv_token_value := gv_cust_trx_type_vd;
--      RAISE get_trx_type_expt;
--    END IF;
--    --==============================================================
--    --�����l�����̎���^�C�v�����擾
--    --==============================================================
--    OPEN g_cust_trx_type_cur(
--           gv_cust_trx_type_gnrl -- �����l�����̎���^�C�v
--         );
--    FETCH g_cust_trx_type_cur INTO g_cust_trx_type_gnrl;
--    CLOSE g_cust_trx_type_cur;
--    IF( g_cust_trx_type_gnrl.cust_trx_type_id IS NULL ) THEN
--      lv_token_value := cv_cust_trx_type_gnrl;
--      RAISE get_trx_type_expt;
--    END IF;
---- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
    --==============================================================
    -- ����^�C�v�����擾�i�t��VD�i�����j�j
    --==============================================================
    OPEN g_cust_trx_type_cur(
           gv_ra_trx_type_f_digestion_vd
         );
    FETCH g_cust_trx_type_cur INTO g_ra_trx_type_f_digestion_vd;
    CLOSE g_cust_trx_type_cur;
    IF( g_ra_trx_type_f_digestion_vd.cust_trx_type_id IS NULL ) THEN
      lv_token_value := gv_ra_trx_type_f_digestion_vd;
      RAISE get_trx_type_expt;
    END IF;
    --==============================================================
    -- ����^�C�v�����擾�i�[�iVD�j
    --==============================================================
    OPEN g_cust_trx_type_cur(
           gv_ra_trx_type_delivery_vd
         );
    FETCH g_cust_trx_type_cur INTO g_ra_trx_type_delivery_vd;
    CLOSE g_cust_trx_type_cur;
    IF( g_ra_trx_type_delivery_vd.cust_trx_type_id IS NULL ) THEN
      lv_token_value := gv_ra_trx_type_delivery_vd;
      RAISE get_trx_type_expt;
    END IF;
    --==============================================================
    -- ����^�C�v�����擾�i����VD�j
    --==============================================================
    OPEN g_cust_trx_type_cur(
           gv_ra_trx_type_digestion_vd
         );
    FETCH g_cust_trx_type_cur INTO g_ra_trx_type_digestion_vd;
    CLOSE g_cust_trx_type_cur;
    IF( g_ra_trx_type_digestion_vd.cust_trx_type_id IS NULL ) THEN
      lv_token_value := gv_ra_trx_type_digestion_vd;
      RAISE get_trx_type_expt;
    END IF;
    --==============================================================
    -- ����^�C�v�����擾�i��ʓX�j
    --==============================================================
    OPEN g_cust_trx_type_cur(
           gv_ra_trx_type_general
         );
    FETCH g_cust_trx_type_cur INTO g_ra_trx_type_general;
    CLOSE g_cust_trx_type_cur;
    IF( g_ra_trx_type_general.cust_trx_type_id IS NULL ) THEN
      lv_token_value := gv_ra_trx_type_general;
      RAISE get_trx_type_expt;
    END IF;
-- 2009/10/05 Ver.1.7 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
-- 2021/04/15 Ver1.12 ADD Start
    --==============================================================
    -- ����^�C�v�����擾�i�ݔ���j
    --==============================================================
    OPEN g_cust_trx_type_cur(
           gv_ra_trx_type_equipment
         );
    FETCH g_cust_trx_type_cur INTO g_ra_trx_type_equipment;
    CLOSE g_cust_trx_type_cur;
    IF( g_ra_trx_type_equipment.cust_trx_type_id IS NULL ) THEN
      lv_token_value := gv_ra_trx_type_equipment;
      RAISE get_trx_type_expt;
    END IF;
-- 2021/04/15 Ver1.12 ADD End
    --==============================================================
    --�ʉ݃R�[�h�̎擾
    --==============================================================
    BEGIN
      SELECT gsob.currency_code   AS currency_code    -- �@�\�ʉ݃R�[�h
      INTO   gv_currency_code
      FROM   gl_sets_of_books     gsob                -- ��v����}�X�^
      WHERE  gsob.set_of_books_id = gn_set_of_bks_id; -- ��v����ID = ��L�Ŏ擾��������ID
--
    EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        RAISE currency_code_expt;
    END;
    --==============================================================
    --������擾
    --==============================================================
    gv_language := USERENV( cv_language );
--
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
    --==============================================================
    --�����ʔ̎�����e�[�u���̃J�E���g
    --==============================================================
    SELECT COUNT(*)
    INTO   gn_target_line_cnt
    FROM   xxcok_cond_bm_support    xcbs                     -- �����ʔ̎�̋��e�[�u��
    WHERE  xcbs.ar_interface_status = cv_untreated_ar_status -- �A�g�X�e�[�^�X������(AR)
    AND    xcbs.csh_rcpt_discount_amt IS NOT NULL;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
--
  EXCEPTION
    -- *** �v���t�@�C���擾�G���[ ***
    WHEN profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00003_err_msg
                    , cv_profile_token
                    , lv_token_value
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �Ɩ��������t�擾�G���[ ***
    WHEN operation_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00028_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ����^�C�v���擾�G���[ ***
    WHEN get_trx_type_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00090_err_msg
                    , cv_cust_trx_type_token
                    , lv_token_value
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �ʉ݃R�[�h�擾�G���[ ***
    WHEN currency_code_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00029_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
  , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
  , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(5000) DEFAULT NULL; -- ���b�Z�[�W�ϐ�
    lb_retcode BOOLEAN        DEFAULT NULL; -- ���b�Z�[�W�o�͖߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --init(��������(A-1))�̌Ăяo��
    --==============================================================
    init(
      ov_errbuf  => lv_errbuf      -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode     -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --get_discnt_amount_ar_data_p(AR�A�g�f�[�^�̎擾(�������l����)(A-2))�̌Ăяo��
    --==============================================================
    get_discnt_amount_ar_data_p(
      ov_errbuf  => lv_errbuf      -- �G���[�E���b�Z�[�W
    , ov_retcode => lv_retcode     -- ���^�[���E�R�[�h
    , ov_errmsg  => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
      ov_retcode := lv_retcode;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki DEL START
--    --==============================================================
--    --upd_ coordination_result_p(�A�g���ʂ̍X�V(A-8))�̌Ăяo��
--    --==============================================================
--    upd_coordination_result_p(
--      ov_errbuf  => lv_errbuf      -- �G���[�E���b�Z�[�W
--    , ov_retcode => lv_retcode     -- ���^�[���E�R�[�h
--    , ov_errmsg  => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
--    );
----
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki DEL END
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf  OUT VARCHAR2 --�G���[�E���b�Z�[�W
  , retcode OUT VARCHAR2 --���^�[���E�R�[�h
  )
  IS
--
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main'; -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL; -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT NULL; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL; -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100)  DEFAULT NULL; -- ���b�Z�[�W�R�[�h
    lv_out_msg      VARCHAR2(5000) DEFAULT NULL; -- ���b�Z�[�W�o�͕ϐ�
    lb_retcode      BOOLEAN        DEFAULT NULL; -- ���b�Z�[�W�o�͕ϐ�
--
  BEGIN
    --================================================================
    --�R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    --================================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , NULL               -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
    ,  ov_retcode => lv_retcode -- ���^�[���E�R�[�h
    ,  ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --================================================================
    --�G���[�o��
    --================================================================
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_errmsg          -- ���b�Z�[�W
                    , 1                  -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.LOG       -- �o�͋敪
                    , lv_errbuf          -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
    -- �x���I�������ꍇ�͋󔒍s�̂ݏo�͂���
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , NULL               -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
    END IF;
    --================================================================
    --�Ώی����o��
    --================================================================
    IF( gn_target_cnt = 0 )
      AND ( lv_retcode = cv_status_normal ) THEN
      -- *** AR�A�g���擾�G���[���b�Z�[�W ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00058_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 1                  -- ���s
                    );
    END IF;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
    --================================================================
    --�����ʔ̎�̋��e�[�u�����������o�͗p���b�Z�[�W�o��
    --================================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxcok_name
                  , cv_10284_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
--
    IF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
      gn_target_line_cnt   := 0; 
      gn_lines_cnt         := 0;
      gn_distributions_cnt := 0;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
    END IF;
--
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_90000_msg
                    , cv_count_token
                    , TO_CHAR( gn_target_cnt )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- �o�͋敪
                    , lv_out_msg         -- ���b�Z�[�W
                    , 0                  -- ���s
                    );
    -- ===============================================
    --���������o��
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_90001_msg
                  , cv_count_token
                  , TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
    -- ===============================================
    -- �����ʔ̎�̋����׌����o��
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxcok_name
                  , cv_10286_msg
                  , cv_count_token
                  , TO_CHAR( gn_target_line_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    -- ===============================================
    -- �A�g�t���O�X�V���׌����o��
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxcok_name
                  , cv_10287_msg
                  , cv_count_token
                  , TO_CHAR( gn_flag_upd_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
    -- ===============================================
    -- �G���[�����o��
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_90002_msg
                  , cv_count_token
                  , TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD START
    --================================================
    --����OIF�o�^�����o�͗p���b�Z�[�W�o��
    --================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxcok_name
                  , cv_10285_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    -- ===============================================
    -- �������OIF�o�^�����o��
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxcok_name
                  , cv_10288_msg
                  , cv_count_token
                  , TO_CHAR( gn_lines_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    -- ===============================================
    -- �����z��OIF�o�^�����o��
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxcok_name
                  , cv_10289_msg
                  , cv_count_token
                  , TO_CHAR( gn_distributions_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 1                  -- ���s
                  );
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki ADD END
    -- ===============================================
    -- �I�����b�Z�[�W
    -- ===============================================
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki MOD START
--    IF( lv_retcode = cv_status_normal ) THEN
--      lv_message_code := cv_90004_msg;
--      retcode         := cv_status_normal;
--    ELSIF( lv_retcode = cv_status_error ) THEN
--      lv_message_code := cv_90006_msg;
--      retcode         := cv_status_error;
--    END IF;
    --
    IF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_90005_msg;
      retcode         := cv_status_warn;
    ELSIF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_90004_msg;
      retcode         := cv_status_normal;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_90006_msg;
      retcode         := cv_status_error;
    END IF;
-- 2010/12/07 Ver.1.11 [E_�{�ғ�_05823] SCS S.Niki MOD END
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- �o�͋敪
                  , lv_out_msg         -- ���b�Z�[�W
                  , 0                  -- ���s
                  );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      errbuf     := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      retcode    := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf     := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode    := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf     := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode    := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK018A01C;
/
