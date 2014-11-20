CREATE OR REPLACE PACKAGE BODY APPS.XXCSO001A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO001A04C(body)
 * Description      : EBS(�t�@�C���A�b�v���[�hI/F)�Ɏ捞�܂ꂽ����v���
 *                    ���_�ʌ��ʌv��e�[�u��,�c�ƈ��ʌ��ʌv��e�[�u���Ɏ捞�݂܂��B
 *                    
 * MD.050           : MD050_CSO_001_A04_����v��i�[�y���ʁz
 *                    
 * Version          : 1.3
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        ��������                                        (A-1)
 *  get_sales_plan_data         ����v��f�[�^���o����                          (A-2)
 *  get_user_data               ���O�C�����[�U�[�̋��_�R�[�h���o                (A-3)
 *  data_proper_check           �f�[�^�Ó����`�F�b�N                            (A-4)
 *  chk_mst_is_exists           �}�X�^���݃`�F�b�N                              (A-5)
 *  get_dept_month_data         ���_�ʌ��ʌv��f�[�^���o                        (A-6)
 *  inup_dept_month_data        ���_�ʌ��ʌv��f�[�^�o�^�E�X�V                  (A-7)
 *  inupdl_prsn_month_data      �c�ƈ��ʌ��ʌv��f�[�^�o�^�E�X�V�E�폜          (A-8)
 *  delete_if_data              �t�@�C���f�[�^�폜����                          (A-9)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��(
 *                                �I������                                      (A-10)
 *                              )
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-14    1.0   Maruyama.Mio     �V�K�쐬
 *  2009-01-27    1.0   Maruyama.Mio     �P�̃e�X�g������������r���[���ʔ��f
 *  2009-02-27    1.1   Maruyama.Mio     �y��Q�Ή�036�z�G���[�����J�E���g�s��Ή�
 *  2009-02-27    1.1   Maruyama.Mio     �y��Q�Ή�037�z��6�c�Ɠ��߂��G���[���b�Z�[�W�s��Ή�
 *  2009-02-27    1.1   Maruyama.Mio     �y��Q�Ή�038�z�G���[�����������J�E���g�s��Ή�
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897�Ή�
 *  2010-02-22    1.3   Kazuyo.Hosoi     �yE_�{�ғ�_01679�z�c�Ɠ����t�擾�֐��p�p�����[�^��
 *                                       �v���t�@�C���l�Ɏ��悤�ɐݒ�
 *
 *****************************************************************************************/
-- 
-- #######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn             CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  -- WHO�J����
  cn_created_by              CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date           CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by         CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date        CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login       CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date     CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part                CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3) := '.';
--
-- #######################  �Œ�O���[�o���萔�錾�� END   #########################
--
-- #######################  �Œ�O���[�o���ϐ��錾�� START #########################
--
  gv_out_msg             VARCHAR2(2000);
  gn_target_cnt          NUMBER;                    -- �Ώی���
  gn_normal_cnt          NUMBER;                    -- ���팏��
  gn_error_cnt           NUMBER;                    -- �G���[����
  gn_warn_cnt            NUMBER;                    -- �X�L�b�v����
--
-- #######################  �Œ�O���[�o���ϐ��錾�� END   #########################
--
-- #######################  �Œ苤�ʗ�O�錾�� START       #########################
--
  --*** ���������ʗ�O ***
  global_process_expt    EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt        EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
-- #######################  �Œ苤�ʗ�O�錾�� END         #########################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO001A04C';      -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  cv_comma               CONSTANT VARCHAR2(1)   := ',';
  cv_enabled_flag        CONSTANT VARCHAR2(1)   := 'Y';                 -- �L��
  cn_effective_val       CONSTANT NUMBER(2)     := 1;                   -- �t���O�Z�b�g�p�L���l
  cn_ineffective_val     CONSTANT NUMBER(2)     := 0;                   -- �t���O�Z�b�g�p�����l
    -- �`�F�b�N�p��l
  cn_inp_knd_rt          CONSTANT NUMBER        := 1;   -- ���͋敪���e�l:���[�g�c�Ɨp
  cn_inp_knd_hnb         CONSTANT NUMBER        := 2;   -- ���͋敪���e�l:�{���c�Ɨp
  cn_dt_knd_dpt          CONSTANT NUMBER        := 1;   -- �f�[�^��ʋ��e�l�F���_
  cn_dt_knd_prsn         CONSTANT NUMBER        := 2;   -- �f�[�^��ʋ��e�l�F�c�ƈ�
--
  -- ���b�Z�[�W�R�[�h
    -- ��������
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00026';  -- �p�����[�^NULL�G���[
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00175';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00200';  -- �o�[�W�����ԍ��G���[
    -- �f�[�^���o�G���[
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00201';  -- ���O�C���҂̋��_CD���o�G���[
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- �f�[�^���o�G���[
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00202';  -- �f�[�^���o�G���[(���_�ʌ��ʌv��)
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00203';  -- �f�[�^���o�G���[(�c�ƈ��ʌ��ʌv��)
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00025';  -- �f�[�^���o�G���[(�t�@�C���A�b�v���[�h)
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00204';  -- ���b�N�G���[(���_�ʌ��ʌv��)
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00035';  -- ���b�N�G���[(�t�@�C���A�b�v���[�h)
    -- �f�[�^�o�^�E�폜�E�X�V�G���[
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00205';  -- �o�^�s�G���[(�������c�ƈ�)
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00206';  -- �폜�s�G���[(��v��������)
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00207';  -- �o�^�G���[(���_�ʌ��ʌv��)
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00209';  -- �X�V�G���[(���_�ʌ��ʌv��)
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00208';  -- �o�^�G���[(�c�ƈ��ʌ��ʌv��)
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00210';  -- �X�V�G���[(�c�ƈ��ʌ��ʌv��)
  cv_tkn_number_17       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00211';  -- �폜�G���[(�c�ƈ��ʌ��ʌv��)
  cv_tkn_number_18       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00033';  -- �폜�G���[(�t�@�C���A�b�v���[�h)
    -- �f�[�^�`�F�b�N�G���[
  cv_tkn_number_19       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00212';  -- �K�{�`�F�b�N�G���[
  cv_tkn_number_20       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00213';  -- �N�x�擾�G���[
  cv_tkn_number_21       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00401';  -- �N�x�s��v�G���[
  cv_tkn_number_22       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00214';  -- NUMBER�^�`�F�b�N�G���[
  cv_tkn_number_23       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00215';  -- �T�C�Y�`�F�b�N�G���[
  cv_tkn_number_24       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00216';  -- ���t�����G���[
  cv_tkn_number_25       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00217';  -- ���͋敪�`�F�b�N�G���[
  cv_tkn_number_26       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00218';  -- �f�[�^��ʃ`�F�b�N�G���[
  cv_tkn_number_27       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00219';  -- ���_�R�[�h����G���[
  cv_tkn_number_28       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00220';  -- �}�X�^���݃`�F�b�N�G���[
  cv_tkn_number_29       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00221';  -- �c�ƈ������G���[
  cv_tkn_number_30       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00277';  -- �ߋ������Ȃ��c�ƈ����̓G���[
    -- ���b�Z�[�W�o�͗p
  cv_tkn_number_31       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00274';  -- �t�@�C���A�b�v���[�h���̒��o�G���[
  cv_tkn_number_32       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00271';  -- �t�@�C��ID
  cv_tkn_number_33       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00275';  -- �t�H�[�}�b�g�p�^�[��
  cv_tkn_number_34       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00276';  -- �t�@�C���A�b�v���[�h����
  cv_tkn_number_35       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- CSV�t�@�C����
  cv_tkn_number_36       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00399';  -- �Ώی���0��
  cv_tkn_number_37       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00400';  -- ��6�c�Ɠ��ȍ~��{�v��ύX�ύX�����{
    -- �ǉ�
  -- ����v��f�[�^�t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W
  cv_tkn_number_38       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00512';
  -- �V�X�e���I�ɏo�͂��Ă��鍀�ڂ�NULL�̏ꍇ�̃G���[���b�Z�[�W
  cv_tkn_number_39       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00519';
  -- �O���[�v���敪�l�`�F�b�N�G���[���b�Z�[�W
  cv_tkn_number_40       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00531';
--
  -- �g�[�N���R�[�h
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_file_id         CONSTANT VARCHAR2(20) := 'FILE_ID';
  cv_tkn_fmt_ptn         CONSTANT VARCHAR2(20) := 'FORMAT_PATTERN';
  cv_tkn_file_upload_nm  CONSTANT VARCHAR2(20) := 'UPLOAD_FILE_NAME';
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';  
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_file_nm     CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_clmn            CONSTANT VARCHAR2(20) := 'COLMUN';
  cv_tkn_val             CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_cnt             CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_date            CONSTANT VARCHAR2(20) := 'DATE';
  cv_tkn_insrt_kbn       CONSTANT VARCHAR2(20) := 'INSERT_KUBUN';
  cv_tkn_dt_kbn          CONSTANT VARCHAR2(20) := 'DATA_KUBUN';
  cv_tkn_lctn_cd         CONSTANT VARCHAR2(20) := 'LOCATION_CD';
  cv_tkn_yr_mnth         CONSTANT VARCHAR2(20) := 'YEAR_MONTH';
  cv_tkn_bsinss_yr       CONSTANT VARCHAR2(20) := 'BUSINESS_YEAR';
  cv_tkn_sls_prsn_cd     CONSTANT VARCHAR2(20) := 'SALES_PERSON_CD';
  cv_tkn_sls_prsn_nm     CONSTANT VARCHAR2(20) := 'SALES_PERSON_NAME';
  cv_tkn_base_val        CONSTANT VARCHAR2(20) := 'BASE_VALUE';
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1          CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�擾 >>';
  cv_debug_msg2          CONSTANT VARCHAR2(200) := '�G�N�Z���v���O�����o�[�W�����ԍ��y���[�g�Z�[���X�z = ';
  cv_debug_msg3          CONSTANT VARCHAR2(200) := '�G�N�Z���v���O�����o�[�W�����ԍ��y�{���c�Ɓz = ';
  cv_debug_msg4          CONSTANT VARCHAR2(200) := '����v��f�[�^�𒊏o���܂����B';
  cv_debug_msg5          CONSTANT VARCHAR2(200) := '<< ���O�C���ҋ��_�R�[�h�擾 >>';
  cv_debug_msg6          CONSTANT VARCHAR2(200) := '���_�R�[�h = ';
  cv_debug_msg11         CONSTANT VARCHAR2(200) := '<< ����v��f�[�^���o >>';
  cv_debug_msg13         CONSTANT VARCHAR2(200) := '���[���o�b�N���܂����B';
  cv_debug_msg14         CONSTANT VARCHAR2(200) := '<< ����v��f�[�^�`�F�b�N���� >>';
  cv_debug_msg15         CONSTANT VARCHAR2(200) := '�S������Ƀ`�F�b�N�������I�����܂����B';
  /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
  cv_debug_msg16         CONSTANT VARCHAR2(200) := '����v��A�b�v���[�h���c�Ɠ� = ';
  /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */

  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================

  -- �s�P�ʃf�[�^���i�[����z��
  TYPE g_col_data_ttype IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;

  -- ����v��f�[�^���֘A��񒊏o�f�[�^�i�[�p���R�[�h
  TYPE g_sls_pln_data_rtype IS RECORD(
    input_division           NUMBER(2),                                               -- ���͋敪
    data_kind                NUMBER(2),                                               -- �f�[�^���
    fiscal_year              xxcso_dept_monthly_plans.fiscal_year%TYPE,               -- �N�x
    year_month               xxcso_dept_monthly_plans.year_month%TYPE,                -- �N��
    base_code                xxcso_dept_monthly_plans.base_code%TYPE,                 -- ���_CD
    bsc_nw_srvc_mt           xxcso_dept_monthly_plans.basic_new_service_amt%TYPE,     -- ��{�V�K�v��
    bsc_nxt_srvc_mt          xxcso_dept_monthly_plans.basic_next_service_amt%TYPE,    -- ��{���N�v��
    bsc_xst_srvc_mt          xxcso_dept_monthly_plans.basic_exist_service_amt%TYPE,   -- ��{��������
    bsc_dscnt_mt             xxcso_dept_monthly_plans.basic_discount_amt%TYPE,        -- ��{�l����
    bsc_sls_ttl_mt_nlm       xxcso_dept_monthly_plans.basic_sales_total_amt%TYPE,     -- ��{���v����(��{�m���})
    visit                    xxcso_dept_monthly_plans.visit%TYPE,                     -- �K��
    trgt_nw_srvc_mt          xxcso_dept_monthly_plans.target_new_service_amt%TYPE,    -- �ڕW�V�K�v��
    trgt_nxt_srvc_mt         xxcso_dept_monthly_plans.target_next_service_amt%TYPE,   -- �ڕW���N�v��
    trgt_xst_srvc_mt         xxcso_dept_monthly_plans.target_exist_service_amt%TYPE,  -- �ڕW��������
    trgt_dscnt_mt            xxcso_dept_monthly_plans.target_discount_amt%TYPE,       -- �ڕW�l��
    trgt_sls_ttl_mt          xxcso_dept_monthly_plans.target_sales_total_amt%TYPE,    -- �ڕW���v����(�ڕW�m���})
    emply_nmbr               xxcso_sls_prsn_mnthly_plns.employee_number%TYPE,                -- �c�ƈ�CD
    emply_nm                 VARCHAR2(42),                                                   -- �c�ƈ���
    offc_rnk_nm              xxcso_sls_prsn_mnthly_plns.office_rank_name%TYPE,               -- �E�ʖ�
    grp_nmbr                 xxcso_sls_prsn_mnthly_plns.group_number%TYPE,                   -- �O���[�v�ԍ�
    grp_ldr_flg              xxcso_sls_prsn_mnthly_plns.group_leader_flag%TYPE,              -- �O���[�v���敪
    grp_grd                  xxcso_sls_prsn_mnthly_plns.group_grade%TYPE,                    -- �O���[�v������
    pr_rslt_vd_nw_srv_mt     xxcso_sls_prsn_mnthly_plns.pri_rslt_vd_new_serv_amt%TYPE,       -- �O�N����(VD:�V�K�v��)
    pr_rslt_vd_nxt_srv_mt    xxcso_sls_prsn_mnthly_plns.pri_rslt_vd_next_serv_amt%TYPE,      -- �O�N����(VD:���N�v��)
    pr_rslt_vd_xst_srv_mt    xxcso_sls_prsn_mnthly_plns.pri_rslt_vd_exist_serv_amt%TYPE,     -- �O�N����(VD:��������)
    pr_rslt_vd_ttl_mt        xxcso_sls_prsn_mnthly_plns.pri_rslt_vd_total_amt%TYPE,          -- �O�N����(VD:�v)
    pr_rslt_nw_srv_mt        xxcso_sls_prsn_mnthly_plns.pri_rslt_new_serv_amt%TYPE,          -- �O�N����(VD�ȊO:�V�K�v��)
    pr_rslt_nxt_srv_mt       xxcso_sls_prsn_mnthly_plns.pri_rslt_next_serv_amt%TYPE,         -- �O�N����(VD�ȊO:���N�v��)
    pr_rslt_xst_srv_mt       xxcso_sls_prsn_mnthly_plns.pri_rslt_exist_serv_amt%TYPE,        -- �O�N����(VD�ȊO:��������)
    pr_rslt_ttl_mt           xxcso_sls_prsn_mnthly_plns.pri_rslt_total_amt%TYPE,             -- �O�N����(VD�ȊO:�v)
    pr_rslt_prsn_nw_srv_mt   xxcso_sls_prsn_mnthly_plns.pri_rslt_prsn_new_serv_amt%TYPE,     -- �O�N����(�c�ƈ��v:�V�K�v��)
    pr_rslt_prsn_nxt_srv_mt  xxcso_sls_prsn_mnthly_plns.pri_rslt_prsn_next_serv_amt%TYPE,    -- �O�N����(�c�ƈ��v:���N�v��)
    pr_rslt_prsn_xst_srv_mt  xxcso_sls_prsn_mnthly_plns.pri_rslt_prsn_exist_serv_amt%TYPE,   -- �O�N����(�c�ƈ��v:��������)
    pr_rslt_prsn_ttl_mt      xxcso_sls_prsn_mnthly_plns.pri_rslt_prsn_total_amt%TYPE,        -- �O�N����(�c�ƈ��v:�v)
    bsc_sls_vd_nw_srv_mt     xxcso_sls_prsn_mnthly_plns.bsc_sls_vd_new_serv_amt%TYPE,        -- ��{����(VD:�V�K�v��)
    bsc_sls_vd_nxt_srv_mt    xxcso_sls_prsn_mnthly_plns.bsc_sls_vd_next_serv_amt%TYPE,       -- ��{����(VD:���N�v��)
    bsc_sls_vd_xst_srv_mt    xxcso_sls_prsn_mnthly_plns.bsc_sls_vd_exist_serv_amt%TYPE,      -- ��{����(VD:��������)
    bsc_sls_vd_ttl_mt        xxcso_sls_prsn_mnthly_plns.bsc_sls_vd_total_amt%TYPE,           -- ��{����(VD:�v)
    bsc_sls_nw_srv_mt        xxcso_sls_prsn_mnthly_plns.bsc_sls_new_serv_amt%TYPE,           -- ��{����(VD�ȊO:�V�K�v��)
    bsc_sls_nxt_srv_mt       xxcso_sls_prsn_mnthly_plns.bsc_sls_next_serv_amt%TYPE,          -- ��{����(VD�ȊO:���N�v��)
    bsc_sls_xst_srv_mt       xxcso_sls_prsn_mnthly_plns.bsc_sls_exist_serv_amt%TYPE,         -- ��{����(VD�ȊO:��������)
    bsc_sls_ttl_mt           xxcso_sls_prsn_mnthly_plns.bsc_sls_total_amt%TYPE,              -- ��{����(VD�ȊO:�v)
    bsc_sls_prsn_nw_srv_mt   xxcso_sls_prsn_mnthly_plns.bsc_sls_prsn_new_serv_amt%TYPE,      -- ��{����(�c�ƈ��v:�V�K�v��)
    bsc_sls_prsn_nxt_srv_mt  xxcso_sls_prsn_mnthly_plns.bsc_sls_prsn_next_serv_amt%TYPE,     -- ��{����(�c�ƈ��v:���N�v��)
    bsc_sls_prsn_xst_srv_mt  xxcso_sls_prsn_mnthly_plns.bsc_sls_prsn_exist_serv_amt%TYPE,    -- ��{����(�c�ƈ��v:��������)
    bsc_sls_prsn_ttl_mt      xxcso_sls_prsn_mnthly_plns.bsc_sls_prsn_total_amt%TYPE,         -- ��{����(�c�ƈ��v:�v)
    tgt_sls_vd_nw_srv_mt     xxcso_sls_prsn_mnthly_plns.tgt_sales_vd_new_serv_amt%TYPE,      -- �ڕW����(VD:�V�K�v��)
    tgt_sls_vd_nxt_srv_mt    xxcso_sls_prsn_mnthly_plns.tgt_sales_vd_next_serv_amt%TYPE,     -- �ڕW����(VD:���N�v��)
    tgt_sls_vd_xst_srv_mt    xxcso_sls_prsn_mnthly_plns.tgt_sales_vd_exist_serv_amt%TYPE,    -- �ڕW����(VD:��������)
    tgt_sls_vd_ttl_mt        xxcso_sls_prsn_mnthly_plns.tgt_sales_vd_total_amt%TYPE,         -- �ڕW����(VD:�v)
    tgt_sls_nw_srv_mt        xxcso_sls_prsn_mnthly_plns.tgt_sales_new_serv_amt%TYPE,         -- �ڕW����(VD�ȊO:�V�K�v��)
    tgt_sls_nxt_srv_mt       xxcso_sls_prsn_mnthly_plns.tgt_sales_next_serv_amt%TYPE,        -- �ڕW����(VD�ȊO:���N�v��)
    tgt_sls_xst_srv_mt       xxcso_sls_prsn_mnthly_plns.tgt_sales_exist_serv_amt%TYPE,       -- �ڕW����(VD�ȊO:��������)
    tgt_sls_ttl_mt           xxcso_sls_prsn_mnthly_plns.tgt_sales_total_amt%TYPE,            -- �ڕW����(VD�ȊO:�v)
    tgt_sls_prsn_nw_srv_mt   xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_new_serv_amt%TYPE,    -- �ڕW����(�c�ƈ��v:�V�K�v��)
    tgt_sls_prsn_nxt_srv_mt  xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_next_serv_amt%TYPE,   -- �ڕW����(�c�ƈ��v:���N�v��)
    tgt_sls_prsn_xst_srv_mt  xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_exist_serv_amt%TYPE,  -- �ڕW����(�c�ƈ��v:��������)
    tgt_sls_prsn_ttl_mt      xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_total_amt%TYPE,       -- �ڕW����(�c�ƈ��v:�v)
    rslt_vd_nw_srv_mt        xxcso_sls_prsn_mnthly_plns.rslt_vd_new_serv_amt%TYPE,           -- ����(VD:�V�K�v��)
    rslt_vd_nxt_srv_mt       xxcso_sls_prsn_mnthly_plns.rslt_vd_next_serv_amt%TYPE,          -- ����(VD:���N�v��)
    rslt_vd_xst_srv_mt       xxcso_sls_prsn_mnthly_plns.rslt_vd_exist_serv_amt%TYPE,         -- ����(VD:��������)
    rslt_vd_total_amt        xxcso_sls_prsn_mnthly_plns.rslt_vd_total_amt%TYPE,              -- ����(VD:�v)
    rslt_nw_srv_mt           xxcso_sls_prsn_mnthly_plns.rslt_new_serv_amt%TYPE,              -- ����(VD�ȊO:�V�K�v��)
    rslt_nxt_srv_mt          xxcso_sls_prsn_mnthly_plns.rslt_next_serv_amt%TYPE,             -- ����(VD�ȊO:���N�v��)
    rslt_xst_srv_mt          xxcso_sls_prsn_mnthly_plns.rslt_exist_serv_amt%TYPE,            -- ����(VD�ȊO:��������)
    rslt_ttl_mt              xxcso_sls_prsn_mnthly_plns.rslt_total_amt%TYPE,                 -- ����(VD�ȊO:�v)
    rslt_prsn_nw_srv_mt      xxcso_sls_prsn_mnthly_plns.rslt_prsn_new_serv_amt%TYPE,         -- ����(�c�ƈ��v:�V�K�v��)
    rslt_prsn_nxt_srv_mt     xxcso_sls_prsn_mnthly_plns.rslt_prsn_next_serv_amt%TYPE,        -- ����(�c�ƈ��v:���N�v��)
    rslt_prsn_xst_srv_mt     xxcso_sls_prsn_mnthly_plns.rslt_prsn_exist_serv_amt%TYPE,       -- ����(�c�ƈ��v:��������)
    rslt_prsn_ttl_mt         xxcso_sls_prsn_mnthly_plns.rslt_prsn_total_amt%TYPE,            -- ����(�c�ƈ��v:�v)
    vis_vd_nw_srv_mt         xxcso_sls_prsn_mnthly_plns.vis_vd_new_serv_amt%TYPE,            -- �K��(VD:�V�K�v��)
    vis_vd_nxt_srv_mt        xxcso_sls_prsn_mnthly_plns.vis_vd_next_serv_amt%TYPE,           -- �K��(VD:���N�v��)
    vis_vd_xst_srv_mt        xxcso_sls_prsn_mnthly_plns.vis_vd_exist_serv_amt%TYPE,          -- �K��(VD:��������)
    vis_vd_ttl_mt            xxcso_sls_prsn_mnthly_plns.vis_vd_total_amt%TYPE,               -- �K��(VD:�v)
    vis_nw_srv_mt            xxcso_sls_prsn_mnthly_plns.vis_new_serv_amt%TYPE,               -- �K��(VD�ȊO:�V�K�v��)
    vis_nxt_srv_mt           xxcso_sls_prsn_mnthly_plns.vis_next_serv_amt%TYPE,              -- �K��(VD�ȊO:���N�v��)
    vis_xst_srv_mt           xxcso_sls_prsn_mnthly_plns.vis_exist_serv_amt%TYPE,             -- �K��(VD�ȊO:��������)
    vis_ttl_mt               xxcso_sls_prsn_mnthly_plns.vis_total_amt%TYPE,                  -- �K��(VD�ȊO:�v)
    vis_prsn_nw_srv_mt       xxcso_sls_prsn_mnthly_plns.vis_prsn_new_serv_amt%TYPE,          -- �K��(�c�ƈ��v:�V�K�v��)
    vis_prsn_nxt_srv_mt      xxcso_sls_prsn_mnthly_plns.vis_prsn_next_serv_amt%TYPE,         -- �K��(�c�ƈ��v:���N�v��)
    vis_prsn_xst_srv_mt      xxcso_sls_prsn_mnthly_plns.vis_prsn_exist_serv_amt%TYPE,        -- �K��(�c�ƈ��v:��������)
    vis_prsn_ttl_mt          xxcso_sls_prsn_mnthly_plns.vis_prsn_total_amt%TYPE,             -- �K��(�c�ƈ��v:�v)
    sls_prsn_ffctv_flg       NUMBER(2),    -- �c�ƈ��L���t���O
    inpt_dt_is_nll_flg       NUMBER(2),    -- ���͍���NULL�t���O
    db_dt_xst_flg            NUMBER(2),    -- DB�f�[�^���݃t���O
    bs_pln_chng_flg          NUMBER(2)     -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
  );
--
  -- ����v��f�[�^���֘A��񒊏o�f�[�^�i�[�p���R�[�h�����z��
  TYPE g_sls_pln_data_ttype IS TABLE OF g_sls_pln_data_rtype INDEX BY BINARY_INTEGER;
--
  -- *** ���[�U�[��`�O���[�o����O ***
  global_data_check_error_expt    EXCEPTION;  -- �f�[�^�`�F�b�N���G���[��O
  global_data_check_skip_expt     EXCEPTION;  -- �f�[�^�`�F�b�N���G���[��O
  global_inupdel_data_error_expt  EXCEPTION;  -- �f�[�^�o�^�E�X�V�E�폜���G���[��O
  global_inupdel_data_skip_expt   EXCEPTION;  -- �f�[�^�o�^�E�X�V�E�폜���G���[��O
  global_lock_expt                EXCEPTION;  -- ���b�N��O
  global_skip_expt                EXCEPTION;  -- ���S�����X�L�b�v��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --
  gd_now_date              DATE;                                      -- ���ݓ��t���i�[
  gv_now_date              VARCHAR2(8);                               -- ��r�p���ݓ��t
  g_file_data_tab          xxccp_common_pkg2.g_file_data_tbl;         -- �s�P�ʃf�[�^�i�[�p�z��
  g_sls_pln_data_tab       g_sls_pln_data_ttype;                      -- ����v��f�[�^���֘A��񒊏o�f�[�^�i�[�p�z��
--
  gt_file_id               xxccp_mrp_file_ul_interface.file_id%TYPE;  -- �t�@�C��ID
  gv_fmt_ptn               VARCHAR2(20);                              -- �t�H�[�}�b�g�p�^�[��
  gn_dt_chck_err_cnt       NUMBER := 0;                               -- �e��f�[�^�Ó����`�F�b�N�G���[�J�E���g
  gn_dpt_mnth_pln_cnt_num  NUMBER := 0;                               -- ���_�ʌ��ʌv��f�[�^�J�E���g����
  g_rec_count              NUMBER := 0;                               -- ���[�v�J�E���^
--
  gb_msg_already_out_flag        BOOLEAN := FALSE;       -- TRUE : main�����ł̍ŏI�G���[���b�Z�[�W���o�͂��Ȃ�
  gb_sls_pln_inup_rollback_flag  BOOLEAN := FALSE;       -- TRUE : ���[���o�b�N
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     ov_xls_ver_rt   OUT NOCOPY VARCHAR2   -- ����v��ҏW�y���[�g�Z�[���X�z�G�N�Z���v���O�����o�[�W�����ԍ�
    ,ov_xls_ver_hnb  OUT NOCOPY VARCHAR2   -- ����v��ҏW�y�{���c�Ɓz�G�N�Z���v���O�����o�[�W�����ԍ�
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
    ,ov_sls_pln_upld_cls_dy  OUT NOCOPY VARCHAR2   -- ����v��A�b�v���[�h���c�Ɠ�
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
    ,ov_errbuf       OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode      OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg       OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'init';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf        VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �N���p�����[�^
    cv_file_upload_lookup_type   CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ';
    cv_sls_pln_data_lookup_code  CONSTANT VARCHAR2(30)  := '600';
    -- �v���t�@�C����
    -- XXCSO: ����v��y���[�g�Z�[���X�z�G�N�Z���v���O�����o�[�W�����ԍ�
    cv_excel_ver_slspln_route    CONSTANT VARCHAR2(30)   := 'XXCSO1_EXCEL_VER_SLSPLN_ROUTE';
    -- XXCSO: ����v��y�{���c�Ɓz�G�N�Z���v���O�����o�[�W�����ԍ�
    cv_excel_ver_slspln_honbu    CONSTANT VARCHAR2(30)   := 'XXCSO1_EXCEL_VER_SLSPLN_HONBU';
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
    -- XXCSO:����v��A�b�v���[�h���c�Ɠ�
    cv_sls_pln_upld_cls_dy         CONSTANT VARCHAR2(30)   := 'XXCSO1_SLS_PLN_UPLD_CLS_DY';
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
--
    -- *** ���[�J���ϐ� ***
    -- �N���p�����[�^�߂�l�i�[�p
    lv_file_upload_nm            VARCHAR2(30);      -- �t�@�C���A�b�v���[�h����
    -- �v���t�@�C���l�擾�߂�l�i�[�p
    lv_xls_ver_rt                VARCHAR2(2000);    -- ����v��ҏW�y���[�g�Z�[���X�z�G�N�Z���v���O�����o�[�W�����ԍ�
    lv_xls_ver_hnb               VARCHAR2(2000);    -- ����v��ҏW�y�{���c�Ɓz�G�N�Z���v���O�����o�[�W�����ԍ�
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
    lv_sls_pln_upld_cls_dy       VARCHAR2(2000);    -- ����v��A�b�v���[�h���c�Ɠ�
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value                 VARCHAR2(1000);    -- �v���t�@�C�����i�[�p�ϐ�
--
    -- *** ���[�J����O ***
    init_expt                    EXCEPTION;         -- �����������G���[��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ɩ��������t�擾
    gd_now_date  := xxcso_util_common_pkg.get_online_sysdate;  -- ���ݓ��t���i�[
    gv_now_date  := TO_CHAR(gd_now_date,'YYYYMMDD');           -- ��r�p���ݓ��t
--
    -- 1)���̓p�����[�^���b�Z�[�W�o��
    -- �t�@�C��ID���b�Z�[�W
    lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_32     -- ���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_file_id       -- �g�[�N���R�[�h1
                ,iv_token_value1 => TO_CHAR(gt_file_id)  -- �g�[�N���l1
              );
--
    -- �t�@�C��ID���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '' || CHR(10) || lv_errmsg || CHR(10)
    );
    -- �t�@�C��ID���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' || CHR(10) || lv_errmsg || CHR(10)
    );
--
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name       -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_33  -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_fmt_ptn    -- �g�[�N���R�[�h1
                   ,iv_token_value1 => gv_fmt_ptn        -- �g�[�N���l1
                 );
--
    -- �t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => lv_errmsg || CHR(10)
    );
--
    -- 2)���̓p�����[�^�t�@�C��ID��NULL�`�F�b�N
    IF gt_file_id IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name       -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01  -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
--
      RAISE init_expt;
    END IF;
--
    -- 3)�v���t�@�C���I�v�V�����l�擾
       -- �ϐ�������
    lv_tkn_value := NULL;
    
    FND_PROFILE.GET(
       cv_excel_ver_slspln_route
      ,lv_xls_ver_rt
    ); -- ����v��ҏW�y���[�g�Z�[���X�z�G�N�Z���v���O�����o�[�W�����ԍ�
    FND_PROFILE.GET(
       cv_excel_ver_slspln_honbu
      ,lv_xls_ver_hnb
    ); -- ����v��ҏW�y�{���c�Ɓz�G�N�Z���v���O�����o�[�W�����ԍ�
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
    FND_PROFILE.GET(
       cv_sls_pln_upld_cls_dy
      ,lv_sls_pln_upld_cls_dy
    ); -- ����v��A�b�v���[�h���c�Ɠ�
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    IF (lv_xls_ver_rt IS NULL) THEN
      lv_tkn_value := cv_excel_ver_slspln_route;
    ELSIF (lv_xls_ver_hnb IS NULL) THEN
      lv_tkn_value := cv_excel_ver_slspln_honbu;
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
    ELSIF (lv_sls_pln_upld_cls_dy IS NULL) THEN
      lv_tkn_value := cv_sls_pln_upld_cls_dy;
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name       -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_02  -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_prof_nm    -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_tkn_value      -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE init_expt;
    END IF;
--
    -- �擾�����v���t�@�C���l��OUT�p�����[�^�ɐݒ�
    ov_xls_ver_rt  := lv_xls_ver_rt;    -- ����v��ҏW�y���[�g�Z�[���X�z�G�N�Z���v���O�����o�[�W�����ԍ�
    ov_xls_ver_hnb := lv_xls_ver_hnb;   -- ����v��ҏW�y�{���c�Ɓz�G�N�Z���v���O�����o�[�W�����ԍ�
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
    ov_sls_pln_upld_cls_dy := lv_sls_pln_upld_cls_dy;   -- ����v��A�b�v���[�h���c�Ɠ�
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
--
      -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1 || CHR(10) ||
                 cv_debug_msg2 || lv_xls_ver_rt  || CHR(10) ||
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
--                 cv_debug_msg3 || lv_xls_ver_hnb || CHR(10)
                 cv_debug_msg3 || lv_xls_ver_hnb || CHR(10) ||
                 cv_debug_msg16 || lv_sls_pln_upld_cls_dy   || CHR(10)
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
    );
--
    -- 4)�t�@�C���A�b�v���[�h���̒��o
    BEGIN
--
      -- �Q�ƃ^�C�v�e�[�u������t�@�C���A�b�v���[�h���̒��o
      SELECT lvvl.meaning meaning       -- ���e
      INTO   lv_file_upload_nm          -- �t�@�C���A�b�v���[�h����
      FROM   fnd_lookup_values_vl lvvl  -- �N�C�b�N�R�[�h
      WHERE  lvvl.lookup_type = cv_file_upload_lookup_type
        AND TRUNC(gd_now_date) BETWEEN TRUNC(lvvl.start_date_active)
            AND TRUNC(NVL(lvvl.end_date_active, gd_now_date))
        AND lvvl.enabled_flag = cv_enabled_flag
        AND lvvl.lookup_code = cv_sls_pln_data_lookup_code;
--    
      -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_34       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_file_upload_nm  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_file_upload_nm      -- �g�[�N���l1
                   );
--
      -- �t�@�C���A�b�v���[�h���̃��b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg || CHR(10)
      );
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg || CHR(10)
      );
--
    EXCEPTION
    -- �t�@�C���A�b�v���[�h���̒��o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_31    -- ���b�Z�[�W�R�[�h
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE init_expt;
    END;
--
  EXCEPTION
    -- *** ����������������O�n���h�� ***
    WHEN init_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
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
   * Procedure Name   : get_sales_plan_data
   * Description      : ����v��f�[�^���o���� (A-2)
   ***********************************************************************************/
--
  PROCEDURE get_sales_plan_data(
     ov_errbuf            OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100)   := 'get_sales_plan_data';   -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf             VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode            VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg             VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_if_table_nm        CONSTANT VARCHAR2(100)  := '�t�@�C���A�b�v���[�hI/F�e�[�u��';
    -- *** ���[�J���ϐ� ***
    lt_file_name          xxccp_mrp_file_ul_interface.file_name%TYPE;          -- �t�@�C����
    lt_file_content_type  xxccp_mrp_file_ul_interface.file_content_type%TYPE;  -- �t�@�C���敪
    lt_file_data          xxccp_mrp_file_ul_interface.file_data%TYPE;          -- �t�@�C���f�[�^
    lt_file_format        xxccp_mrp_file_ul_interface.file_format%TYPE;        -- �t�@�C���t�H�[�}�b�g
--
    -- *** ���[�J����O ***
    get_sales_plan_data_expt  EXCEPTION; -- ����v��f�[�^���o�������G���[��O
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
      -- �t�@�C���f�[�^���o
      SELECT xmfui.file_name         file_name          -- �t�@�C����
            ,xmfui.file_content_type file_content_type  -- �t�@�C���敪
            ,xmfui.file_data         file_date          -- �t�@�C���f�[�^
            ,xmfui.file_format       file_format        -- �t�@�C���t�H�[�}�b�g
      INTO   lt_file_name          -- �t�@�C����
            ,lt_file_content_type  -- �t�@�C���敪
            ,lt_file_data          -- �t�@�C���f�[�^
            ,lt_file_format        -- �t�@�C���t�H�[�}�b�g
      FROM   xxccp_mrp_file_ul_interface xmfui  -- �t�@�C���A�b�v���[�hI/F�e�[�u��
      WHERE  xmfui.file_id = gt_file_id
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      -- ���b�N���s�����ꍇ�̗�O
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_10     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_if_table_nm       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_file_id       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)  -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE get_sales_plan_data_expt;
      -- ���o�Ɏ��s�����ꍇ�̗�O
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08     -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_if_table_nm       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM              -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_file_id       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(gt_file_id)  -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE get_sales_plan_data_expt;
    END;
--
    -- BLOB�f�[�^�ϊ��֐��ɂ��s�P�ʃf�[�^�𒊏o
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => gt_file_id       -- �t�@�C��ID
      ,ov_file_data => g_file_data_tab  -- �t�@�C���f�[�^
      ,ov_errbuf    => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode   => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg    => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_08     -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_tbl           -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_if_table_nm       -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_err_msg       -- �g�[�N���R�[�h2
                     ,iv_token_value2 => SQLERRM              -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_file_id       -- �g�[�N���R�[�h3
                     ,iv_token_value3 => TO_CHAR(gt_file_id)  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE get_sales_plan_data_expt;
    END IF;
--
    -- �f�[�^���o���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg11 || CHR(10) || cv_debug_msg4 || CHR(10)
    );
    -- CSV�t�@�C�������b�Z�[�W
    lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_35    -- ���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_csv_file_nm  -- �g�[�N���R�[�h1
                ,iv_token_value1 => lt_file_name        -- �g�[�N���l1
              );
    -- CSV�t�@�C�������b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg || CHR(10)
    );
    -- CSV�t�@�C�������O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg || CHR(10)
    );
--
  EXCEPTION
    -- *** ����v��f�[�^���o�������G���[��O�n���h�� ***
    WHEN get_sales_plan_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
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
  END get_sales_plan_data;
--
  /**********************************************************************************
   * Procedure Name   : get_user_data
   * Description      : ���O�C�����[�U�[�̋��_�R�[�h���o (A-3)
   ***********************************************************************************/
--
  PROCEDURE get_user_data(
     ov_user_base_code   OUT NOCOPY VARCHAR2  -- ���O�C�����[�U�[�̋��_�R�[�h
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_user_data';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_user_base_code    VARCHAR2(100);    -- ���O�C�����[�U�[�̋��_�R�[�h
--
    -- *** ���[�J����O ***
    get_user_data_expt   EXCEPTION;       -- ���O�C�����[�U�[�̋��_�R�[�h���o�������G���[��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- 1)���O�C�����[�U�[�̋��_�R�[�h���]�ƈ��}�X�^(�ŐV)�r���[����擾
    BEGIN
      SELECT (CASE WHEN  issue_date > gv_now_date THEN -- ���ߓ��Ɣ�r
                     xev2.work_base_code_old  -- �Ζ��n���_�R�[�h(��)
                   ELSE
                     xev2.work_base_code_new  -- �Ζ��n���_�R�[�h(�V)
                   END
             ) user_base_code
      INTO   lv_user_base_code                -- ���O�C�����[�U�[�̋��_�R�[�h
      FROM   xxcso_employees_v2 xev2          -- �]�ƈ��}�X�^(�ŐV)�r���[
      WHERE  xev2.user_id = fnd_global.user_id;
      
      ov_user_base_code := lv_user_base_code; -- ���O�C�����[�U�[�̋��_�R�[�h���A�E�g�p�����[�^�ɃZ�b�g
--
        -- ���O�C�����[�U�[�̋��_�R�[�h�����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg5 || CHR(10)
                   || cv_debug_msg6 || ov_user_base_code || CHR(10)
      );
--
    EXCEPTION
      -- ���o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04    -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_err_msg  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => SQLERRM             -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE get_user_data_expt;
    END;
--
  EXCEPTION
    -- *** ���O�C�����[�U�[�̋��_�R�[�h���o������O�n���h�� ***
    WHEN get_user_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
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
  END get_user_data;
--
/**********************************************************************************
   * Function Name    : chk_number
   * Description      : ����v��i�[�p���p�����`�F�b�N�֐�
   ***********************************************************************************/

  FUNCTION chk_number(
             iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
                     )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'chk_number'; -- �v���O������
    cv_check_char_period  CONSTANT VARCHAR2(1) := '.';
    cv_check_char_space   CONSTANT VARCHAR2(1) := ' ';
    cv_check_char_plus    CONSTANT VARCHAR2(1) := '+';
    -- *** ���[�J���ϐ� ***
    ln_convert_temp       NUMBER;   -- �ϊ��`�F�b�N�p�ꎞ�̈�
--
  BEGIN
    -- NULL�`�F�b�N
    IF (iv_check_char IS NULL) THEN
       RETURN NULL;
    END IF;
--
    -- ���l�ϊ����s���A��O�����������琔�l�ȊO�̕������܂܂�Ă���Ɣ��f����
    BEGIN
      ln_convert_temp := TO_NUMBER(iv_check_char);
    EXCEPTION
      WHEN OTHERS THEN  -- ��{�I�ɁuINVALID_NUMBER�v����������
        RETURN FALSE;
    END;
--
    -- �s���I�h�A�O��̋󔒁A�v���X�A�}�C�i�X�`�F�b�N
    IF  ((INSTR(iv_check_char,cv_check_char_period) > 0)
      OR (INSTR(iv_check_char,cv_check_char_space) > 0)
      OR (INSTR(iv_check_char,cv_check_char_plus) > 0))
    THEN
      RETURN FALSE;
    END IF;
--
    RETURN TRUE;
  END chk_number;
--
  /**********************************************************************************
   * Procedure Name   : data_proper_check
   * Description      : �Ó����`�F�b�N (A-4)
   ***********************************************************************************/
--
  PROCEDURE data_proper_check(
     iv_xls_ver_rt         IN  VARCHAR2                 -- ����v��ҏW�y���[�g�Z�[���X�z�G�N�Z���v���O�����o�[�W�����ԍ�
    ,iv_xls_ver_hnb        IN  VARCHAR2                 -- ����v��ҏW�y�{���c�Ɓz�G�N�Z���v���O�����o�[�W�����ԍ�
    ,iv_base_value         IN  VARCHAR2                 -- ���Y�s�f�[�^
    ,o_col_data_tab        OUT NOCOPY g_col_data_ttype  -- �����㍀�ڃf�[�^���i�[����z��
    ,ov_errbuf             OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W           -- # �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h             -- # �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
  )
  IS
  
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(20)   := 'data_proper_check';  -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf              VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �i�[�f�[�^��ʎ��ʗp�ԍ�
    cn_xls_num_data_rec    CONSTANT NUMBER        := 1;   -- �G�N�Z���v���O�����o�[�W�����ԍ����i�[���ꂽ���R�[�h�̔ԍ�
    cn_format_col_cnt_xls  CONSTANT NUMBER        := 2;   -- 1�s�ڂ̍��ڐ�
    cn_sls_pln_data_rec    CONSTANT NUMBER        := 2;   -- ����v��f�[�^���i�[���ꂽ���R�[�h�̊J�n�ԍ�
    cn_format_col_cnt_pln  CONSTANT NUMBER        := 82;  -- 2�s�ڈȍ~�̍��ڐ�
    -- �`�F�b�N�p�J�E���^�[(�`�F�b�N�J�n�E�I�����ڔԍ�)
    cn_inrt_dtbs_cnt_st    CONSTANT NUMBER        := 6;   -- ���͋敪=1[���[�g] ���� �f�[�^���=2[���_��]�̂Ƃ��J�n�ʒu
    cn_inrt_dtbs_cnt_ed    CONSTANT NUMBER        := 16;  -- ���͋敪=1[���[�g] ���� �f�[�^���=2[���_��]�̂Ƃ��I���ʒu
    cn_inrt_dtprsn_cnt_st  CONSTANT NUMBER        := 23;  -- ���͋敪=1[���[�g] ���� �f�[�^���=2[�c�ƈ���]�̂Ƃ��J�n�ʒu
    cn_inrt_dtprsn_cnt_ed  CONSTANT NUMBER        := 82;  -- ���͋敪=1[���[�g] ���� �f�[�^���=2[�c�ƈ���]�̂Ƃ��I���ʒu
    cn_befor_visit         CONSTANT NUMBER        := 70;  -- ���̔ԍ��܂ŖK��ȊO�̃f�[�^���i�[����Ă���
    -- �`�F�b�N�p��l:�l�̋��e�l
    cn_dt_knd_base         CONSTANT NUMBER        := 1;   -- �f�[�^��ʋ��e�l:���_��
    cn_dt_knd_prsn         CONSTANT NUMBER        := 2;   -- �f�[�^��ʋ��e�l:�c�ƈ���
    cv_grprd_flg_vl_1      CONSTANT VARCHAR2(10)  := 'Y'; -- �O���[�v���敪���e�l1
    cv_grprd_flg_vl_2      CONSTANT VARCHAR2(10)  := 'N'; -- �O���[�v���敪���e�l2
    -- �`�F�b�N�p��l:�T�C�Y
    cn_base_code_len       CONSTANT NUMBER        := 4;   -- ���_�R�[�h�`�F�b�N�p�o�C�g��
    cn_base_pln_len        CONSTANT NUMBER        := 12;  -- ���_�ʌ��ʌv��o�C�g��
    cn_emply_num_len       CONSTANT NUMBER        := 5;   -- �c�ƈ��R�[�h�o�C�g��
    cn_group_len           CONSTANT NUMBER        := 2;   -- �O���[�v�ԍ��E�O���[�v�������o�C�g��
    cn_group_leader_len    CONSTANT NUMBER        := 1;   -- �O���[�v���敪�o�C�g��
    cn_sls_prsn_pln_len    CONSTANT NUMBER        := 9;   -- �c�ƈ��ʌ��ʌv��o�C�g��(�K��ȊO)
    cn_sls_prsn_vst_len    CONSTANT NUMBER        := 4;   -- �c�ƈ��ʌ��ʌv��o�C�g��(�K��)
    -- �`�F�b�N�p��l:���t����
    cv_fiscal_year_fmt     CONSTANT VARCHAR2(100) := 'YYYY';    -- �N�x���e��DATE�^
    cv_year_month_fmt      CONSTANT VARCHAR2(100) := 'YYYYMM';  -- �N�����e��DATE�^
--
    -- *** ���[�J���ϐ� ***
    -- �f�[�^�i�[�p
    lv_rt_sls_ver_num      VARCHAR2(100);  -- ���[�g�Z�[���X�p�o�[�W�����ԍ��i�[�p�ϐ�
    lv_hnb_sls_ver_num     VARCHAR2(100);  -- �{���p�o�[�W�����ԍ��i�[�p�ϐ�
    lv_item_nm             VARCHAR2(100);  -- �Y�����ږ�
    ln_null_flag           NUMBER;         -- NULL�t���O
    ln_null_count          NUMBER;         -- NULL�J�E���^
    -- �T�u���C�����[�v�J�E���^�i�[�p
    i                      NUMBER;         -- A-4���g�p�z��Y����
    -- ���[�v�J�E���^
    ln_i                   NUMBER;
    ln_j                   NUMBER;
    -- �`�F�b�N�p�X�e�[�^�X
--
    lb_null_chck           BOOLEAN;        -- NULL�`�F�b�N�p�X�e�[�^�X
    lb_inpk_chck           BOOLEAN;        -- ���͋敪�`�F�b�N�p�X�e�[�^�X
    lb_dtk_chck            BOOLEAN;        -- �f�[�^��ʃ`�F�b�N�p�X�e�[�^�X
    lb_num_chck            BOOLEAN;        -- NUMBER�^�`�F�b�N�p�X�e�[�^�X
    lb_date_chck           BOOLEAN;        -- ���t�����`�F�b�N�p�X�e�[�^�X
    lb_len_chck            BOOLEAN;        -- �T�C�Y�`�F�b�N�p�X�e�[�^�X
    lb_loop_chck           BOOLEAN;        -- ���[�v�p�X�e�[�^�X
    lb_gl_val_chck         BOOLEAN;        -- �O���[�v���[�_�l�`�F�b�N�p�X�e�[�^�X
--
    lv_tmp                 VARCHAR2(2000);
    ln_pos                 NUMBER;
    ln_cnt                 NUMBER  := 1;
    lb_format_flag         BOOLEAN := TRUE;
--
    -- *** ���[�J��TABLE�^ *** --
    TYPE l_item_name_ttype      IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER; -- ���b�Z�[�W�p���ږ��p�z��
    TYPE l_null_chck_num_ttype  IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER; -- NULL�`�F�b�N���{���ڔԍ��p�z��
--
    -- *** ���[�J��TABLE�萔 *** --
    c_item_name_tab        l_item_name_ttype;      -- ���b�Z�[�W�p���ږ��p�z��
    c_null_chck_num_tab    l_null_chck_num_ttype;  -- NULL�`�F�b�N���{���ڔԍ��p�z��
--
    -- *** ���[�J��TABLE�ϐ� *** --
    l_col_data_tab         g_col_data_ttype;       -- �����㍀�ڃf�[�^���i�[����z��
--
    -- *** ���[�J����O ***
    data_proper_check_error_expt  EXCEPTION;       -- �Ó����`�F�b�N�������G���[��O
    data_proper_check_skip_expt   EXCEPTION;       -- �Ó����`�F�b�N�������X�L�b�v��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    i := g_rec_count;  -- A-4���g�p�z��Y�����ɃT�u���C���`�F�b�N�p���[�v�J�E���^���i�[
--
    -- =====================================
    -- �G���[���b�Z�[�W�g�[�N���p���ږ��i�[
    -- =====================================
    c_item_name_tab.delete; 
    c_item_name_tab(1)   := '���͋敪';
    c_item_name_tab(2)   := '�f�[�^���';
    c_item_name_tab(3)   := '�N�x';
    c_item_name_tab(4)   := '�N��';
    c_item_name_tab(5)   := '���_CD';
    c_item_name_tab(6)   := '��{�V�K�v��';
    c_item_name_tab(7)   := '��{���N�v��';
    c_item_name_tab(8)   := '��{��������';
    c_item_name_tab(9)   := '��{�l��';
    c_item_name_tab(10)  := '��{���v����(��{�m���})';
    c_item_name_tab(11)  := '�K��';
    c_item_name_tab(12)  := '�ڕW�V�K�v��';
    c_item_name_tab(13)  := '�ڕW���N�v��';
    c_item_name_tab(14)  := '�ڕW��������';
    c_item_name_tab(15)  := '�ڕW�l��';
    c_item_name_tab(16)  := '�ڕW���v����(�ڕW�m���})';
    c_item_name_tab(17)  := '�c�ƈ�CD';
    c_item_name_tab(18)  := '�c�ƈ���';
    c_item_name_tab(19)  := '�E�ʖ�';
    c_item_name_tab(20)  := '�O���[�v�ԍ�';
    c_item_name_tab(21)  := '�O���[�v���敪';
    c_item_name_tab(22)  := '�O���[�v������';
    c_item_name_tab(23)  := '�O�N����(VD:�V�K�v��)';
    c_item_name_tab(24)  := '�O�N����(VD:���N�v��)';
    c_item_name_tab(25)  := '�O�N����(VD:��������)';
    c_item_name_tab(26)  := '�O�N����(VD:�v)';
    c_item_name_tab(27)  := '�O�N����(VD�ȊO:�V�K�v��)';
    c_item_name_tab(28)  := '�O�N����(VD�ȊO:���N�v��)';
    c_item_name_tab(29)  := '�O�N����(VD�ȊO:��������)';
    c_item_name_tab(30)  := '�O�N����(VD�ȊO:�v)';
    c_item_name_tab(31)  := '�O�N����(�c�ƈ��v:�V�K�v��)';
    c_item_name_tab(32)  := '�O�N����(�c�ƈ��v:���N�v��)';
    c_item_name_tab(33)  := '�O�N����(�c�ƈ��v:��������)';
    c_item_name_tab(34)  := '�O�N����(�c�ƈ��v:�v)';
    c_item_name_tab(35)  := '��{����(VD:�V�K�v��)';
    c_item_name_tab(36)  := '��{����(VD:���N�v��)';
    c_item_name_tab(37)  := '��{����(VD:��������)';
    c_item_name_tab(38)  := '��{����(VD:�v)';
    c_item_name_tab(39)  := '��{����(VD�ȊO:�V�K�v��)';
    c_item_name_tab(40)  := '��{����(VD�ȊO:���N�v��)';
    c_item_name_tab(41)  := '��{����(VD�ȊO:��������)';
    c_item_name_tab(42)  := '��{����(VD�ȊO:�v)';
    c_item_name_tab(43)  := '��{����(�c�ƈ��v:�V�K�v��)';
    c_item_name_tab(44)  := '��{����(�c�ƈ��v:���N�v��)';
    c_item_name_tab(45)  := '��{����(�c�ƈ��v:��������)';
    c_item_name_tab(46)  := '��{����(�c�ƈ��v:�v)';
    c_item_name_tab(47)  := '�ڕW����(VD:�V�K�v��)';
    c_item_name_tab(48)  := '�ڕW����(VD:���N�v��)';
    c_item_name_tab(49)  := '�ڕW����(VD:��������)';
    c_item_name_tab(50)  := '�ڕW����(VD:�v)';
    c_item_name_tab(51)  := '�ڕW����(VD�ȊO:�V�K�v��)';
    c_item_name_tab(52)  := '�ڕW����(VD�ȊO:���N�v��)';
    c_item_name_tab(53)  := '�ڕW����(VD�ȊO:��������)';
    c_item_name_tab(54)  := '�ڕW����(VD�ȊO:�v)';
    c_item_name_tab(55)  := '�ڕW����(�c�ƈ��v:�V�K�v��)';
    c_item_name_tab(56)  := '�ڕW����(�c�ƈ��v:���N�v��)';
    c_item_name_tab(57)  := '�ڕW����(�c�ƈ��v:��������)';
    c_item_name_tab(58)  := '�ڕW����(�c�ƈ��v:�v)';
    c_item_name_tab(59)  := '����(VD:�V�K�v��)';
    c_item_name_tab(60)  := '����(VD:���N�v��)';
    c_item_name_tab(61)  := '����(VD:��������)';
    c_item_name_tab(62)  := '����(VD:�v)';
    c_item_name_tab(63)  := '����(VD�ȊO:�V�K�v��)';
    c_item_name_tab(64)  := '����(VD�ȊO:���N�v��)';
    c_item_name_tab(65)  := '����(VD�ȊO:��������)';
    c_item_name_tab(66)  := '����(VD�ȊO:�v)';
    c_item_name_tab(67)  := '����(�c�ƈ��v:�V�K�v��)';
    c_item_name_tab(68)  := '����(�c�ƈ��v:���N�v��)';
    c_item_name_tab(69)  := '����(�c�ƈ��v:��������)';
    c_item_name_tab(70)  := '����(�c�ƈ��v:�v)';
    c_item_name_tab(71)  := '�K��(VD:�V�K�v��)';
    c_item_name_tab(72)  := '�K��(VD:���N�v��)';
    c_item_name_tab(73)  := '�K��(VD:��������)';
    c_item_name_tab(74)  := '�K��(VD:�v)';
    c_item_name_tab(75)  := '�K��(VD�ȊO:�V�K�v��)';
    c_item_name_tab(76)  := '�K��(VD�ȊO:���N�v��)';
    c_item_name_tab(77)  := '�K��(VD�ȊO:��������)';
    c_item_name_tab(78)  := '�K��(VD�ȊO:�v)';
    c_item_name_tab(79)  := '�K��(�c�ƈ��v:�V�K�v��)';
    c_item_name_tab(80)  := '�K��(�c�ƈ��v:���N�v��)';
    c_item_name_tab(81)  := '�K��(�c�ƈ��v:��������)';
    c_item_name_tab(82)  := '�K��(�c�ƈ��v:�v)';
    
    -- =============================
    -- NULL�`�F�b�N���{���ڔԍ��i�[
    -- =============================
    c_null_chck_num_tab.delete; 
    c_null_chck_num_tab(1)  := 23;  -- l_col_data_tab(23) = �O�N����(VD:�V�K�v��)
    c_null_chck_num_tab(2)  := 24;  -- l_col_data_tab(24) = �O�N����(VD:���N�v��)
    c_null_chck_num_tab(3)  := 25;  -- l_col_data_tab(25) = �O�N����(VD:��������)
    c_null_chck_num_tab(4)  := 27;  -- l_col_data_tab(27) = �O�N����(VD�ȊO:�V�K�v��)
    c_null_chck_num_tab(5)  := 28;  -- l_col_data_tab(28) = �O�N����(VD�ȊO:���N�v��)
    c_null_chck_num_tab(6)  := 29;  -- l_col_data_tab(29) = �O�N����(VD�ȊO:��������)
    c_null_chck_num_tab(7)  := 35;  -- l_col_data_tab(35) = ��{����(VD:�V�K�v��)
    c_null_chck_num_tab(8)  := 36;  -- l_col_data_tab(36) = ��{����(VD:���N�v��)
    c_null_chck_num_tab(9)  := 37;  -- l_col_data_tab(37) = ��{����(VD:��������)
    c_null_chck_num_tab(10) := 39;  -- l_col_data_tab(39) = ��{����(VD�ȊO:�V�K�v��)
    c_null_chck_num_tab(11) := 40;  -- l_col_data_tab(40) = ��{����(VD�ȊO:���N�v��)
    c_null_chck_num_tab(12) := 46;  -- l_col_data_tab(46) = ��{����(�c�ƈ��v:�v)
    c_null_chck_num_tab(13) := 47;  -- l_col_data_tab(47) = �ڕW����(VD:�V�K�v��)
    c_null_chck_num_tab(14) := 48;  -- l_col_data_tab(48) = �ڕW����(VD:���N�v��)
    c_null_chck_num_tab(15) := 49;  -- l_col_data_tab(49) = �ڕW����(VD:��������)
    c_null_chck_num_tab(16) := 51;  -- l_col_data_tab(51) = �ڕW����(VD�ȊO:���N�v��)
    c_null_chck_num_tab(17) := 52;  -- l_col_data_tab(52) = �ڕW����(VD�ȊO:��������)
    c_null_chck_num_tab(18) := 58;  -- l_col_data_tab(58) = �ڕW����(�c�ƈ��v:�v)
    c_null_chck_num_tab(19) := 59;  -- l_col_data_tab(59) = ����(VD:�V�K�v��)
    c_null_chck_num_tab(20) := 61;  -- l_col_data_tab(61) = ����(VD:��������)
    c_null_chck_num_tab(21) := 62;  -- l_col_data_tab(62) = ����(VD:�v)
    c_null_chck_num_tab(22) := 63;  -- l_col_data_tab(63) = ����(VD�ȊO:�V�K�v��
    c_null_chck_num_tab(23) := 65;  -- l_col_data_tab(65) = ����(VD�ȊO:��������)
    c_null_chck_num_tab(24) := 70;  -- l_col_data_tab(70) = ����(�c�ƈ��v:�v)
    c_null_chck_num_tab(25) := 74;  -- l_col_data_tab(74) = �K��(VD:�v)
    c_null_chck_num_tab(26) := 82;  -- l_col_data_tab(82) = �K��(�c�ƈ��v:�v)
  
    -- =============================
    -- �Ó����`�F�b�N����
    -- =============================

    -- 1.�擾�f�[�^1�s�ڂ̏ꍇ
    IF(i = cn_xls_num_data_rec) THEN
--
      -- ���ʊ֐��ɂ���ĕ����������ڃf�[�^�e�[�u���̎擾
      FOR j IN 1..cn_format_col_cnt_xls LOOP
         l_col_data_tab(j) := REPLACE(xxccp_common_pkg.char_delim_partition(iv_base_value, cv_comma, j), '"');
      END LOOP;
--
      -- �f�[�^���i�[
      lv_rt_sls_ver_num  := l_col_data_tab(1);  -- ���[�g�Z�[���X�p�o�[�W�����ԍ�
      lv_hnb_sls_ver_num := l_col_data_tab(2);  -- �{���p�o�[�W�����ԍ�
--
      -- 1)�o�[�W�����ԍ��`�F�b�N:A-1-3�Ŏ擾�����v���t�@�C���E�I�v�V�����l�Ɣ�r
      IF ((lv_rt_sls_ver_num <> iv_xls_ver_rt)
      OR (lv_hnb_sls_ver_num <> iv_xls_ver_hnb)) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03             -- ���b�Z�[�W�R�[�h
                     );
        lv_errbuf := lv_errmsg;
        RAISE data_proper_check_error_expt;
      ELSIF ((lv_rt_sls_ver_num IS NULL)
      AND (lv_hnb_sls_ver_num IS NULL)) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03             -- ���b�Z�[�W�R�[�h
                     );
        lv_errbuf := lv_errmsg;
        RAISE data_proper_check_error_expt;
      END IF;
--
    END IF;
--
    -- 2.�擾�f�[�^2�s�ڈȍ~�̏ꍇ
    IF(i >= cn_sls_pln_data_rec) THEN
--
      -- ���ڐ����擾
      IF (iv_base_value IS NULL) THEN
      lb_format_flag := FALSE;
      END IF;
--
      -- 2)���ڐ��`�F�b�N
      IF lb_format_flag THEN
        lv_tmp := iv_base_value;
        LOOP
          ln_pos := INSTR(lv_tmp, cv_comma);
          IF ((ln_pos IS NULL) OR (ln_pos = 0)) THEN
            EXIT;
          ELSE
            ln_cnt := ln_cnt + 1;
            lv_tmp := SUBSTR(lv_tmp, ln_pos + 1);
            ln_pos := 0;
          END IF;
        END LOOP;
      END IF;
--
      IF ((lb_format_flag = FALSE) 
        OR (ln_cnt <> cn_format_col_cnt_pln)) 
      THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_38             -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_base_val              -- �g�[�N���R�[�h1
                         ,iv_token_value1 => iv_base_value                -- �g�[�N���l1
                       );
          lv_errbuf  := lv_errmsg;
          RAISE data_proper_check_skip_expt;
--
      ELSE
        -- ���ʊ֐��ɂ���ĕ����������ڃf�[�^�e�[�u���̎擾
        FOR k IN 1..cn_format_col_cnt_pln LOOP
           l_col_data_tab(k) := REPLACE(xxccp_common_pkg.char_delim_partition(iv_base_value, cv_comma, k), '"');
        END LOOP;
--
        -- �`�F�b�N�p�ϐ�������
        lb_null_chck    := TRUE;  -- NULL�`�F�b�N�p�X�e�[�^�X
        lb_inpk_chck    := TRUE;  -- ���͋敪�`�F�b�N�p�X�e�[�^�X
        lb_dtk_chck     := TRUE;  -- �f�[�^��ʃ`�F�b�N�p�X�e�[�^�X
        lb_num_chck     := TRUE;  -- NUMBER�^�`�F�b�N�p�X�e�[�^�X
        lb_date_chck    := TRUE;  -- ���t�����`�F�b�N�p�X�e�[�^�X
        lb_len_chck     := TRUE;  -- �T�C�Y�`�F�b�N�p�X�e�[�^�X
        lb_loop_chck    := TRUE;  -- ���[�v�p�X�e�[�^�X
        lb_gl_val_chck  := TRUE;  -- �O���[�v���敪�l�`�F�b�N�p�X�e�[�^�X
        lv_item_nm      := '';    -- �G���[���b�Z�[�W�g�[�N���p���ږ�
        ln_i            := 0;     -- ���[�v�J�E���^
        ln_j            := 0;     -- ���[�v�J�E���^
        ln_null_count   := 0;     -- ���͋敪=1[���[�g]�E�f�[�^���=2[�c�ƈ�]�̂Ƃ�NULL�`�F�b�N�p
        ln_null_flag    := 0;     -- ���͋敪=1[���[�g]�E�f�[�^���=2[�c�ƈ�]�̂Ƃ�NULL�`�F�b�N�p
--
        -- 3)�K�{���ڂ̃`�F�b�N
        IF (l_col_data_tab(1) IS NULL) THEN
          -- ���͋敪NULL�`�F�b�N
          lb_null_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(1);
        ELSIF ((l_col_data_tab(1) <> cn_inp_knd_rt) 
          AND  (l_col_data_tab(1) <> cn_inp_knd_hnb))
        THEN
          -- ���͋敪���e�l�`�F�b�N
          lb_inpk_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(1);
        ELSIF (l_col_data_tab(2) IS NULL) THEN
          -- �f�[�^���NULL�`�F�b�N
          lb_null_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(2);
        ELSIF ((l_col_data_tab(2) <> cn_dt_knd_base) 
          AND  (l_col_data_tab(2) <> cn_dt_knd_prsn))
        THEN
          -- �f�[�^��ʋ��e�l�`�F�b�N
          lb_dtk_chck   := FALSE;
          lv_item_nm    := c_item_name_tab(2);
        ELSIF (l_col_data_tab(3) IS NULL) THEN
          -- �N�xNULL�`�F�b�N
          lb_null_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(3);
        ELSIF (xxcso_util_common_pkg.check_date(l_col_data_tab(3), cv_fiscal_year_fmt) = FALSE) THEN
          lb_date_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(3);
          -- �N�x���t�����`�F�b�N
        ELSIF (l_col_data_tab(4) IS NULL) THEN
          -- �N��NULL�`�F�b�N
          lb_null_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(4);
        ELSIF (xxcso_util_common_pkg.check_date(l_col_data_tab(4), cv_year_month_fmt) = FALSE) THEN
          lb_date_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(4);
          -- �N�����t�����`�F�b�N
        ELSIF (xxcso_util_common_pkg.get_business_year(l_col_data_tab(4)) IS NULL) THEN
          -- �N�x�擾���s�̏ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(  -- �N�x�擾�G���[
                          iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_20    -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_insrt_kbn    -- �g�[�N���R�[�h1
                         ,iv_token_value1 => l_col_data_tab(1)   -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_dt_kbn       -- �g�[�N���R�[�h2
                         ,iv_token_value2 => l_col_data_tab(2)   -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_lctn_cd      -- �g�[�N���R�[�h3
                         ,iv_token_value3 => l_col_data_tab(5)   -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_yr_mnth      -- �g�[�N���R�[�h4
                         ,iv_token_value4 => l_col_data_tab(4)   -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_sls_prsn_cd  -- �g�[�N���R�[�h5
                         ,iv_token_value5 => l_col_data_tab(17)  -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_sls_prsn_nm  -- �g�[�N���R�[�h6
                         ,iv_token_value6 => l_col_data_tab(18)  -- �g�[�N���l6
                       );
          lv_errbuf  := lv_errmsg;
          RAISE data_proper_check_skip_expt;
        ELSIF (l_col_data_tab(3) <> xxcso_util_common_pkg.get_business_year(l_col_data_tab(4))) THEN
          -- �N������N�x���擾���A���͂��ꂽ�N�x�Ƃ̈�v���`�F�b�N
          lv_errmsg := xxccp_common_pkg.get_msg(  -- �N�x�s��v�G���[
                          iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_21    -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_insrt_kbn    -- �g�[�N���R�[�h1
                         ,iv_token_value1 => l_col_data_tab(1)   -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_dt_kbn       -- �g�[�N���R�[�h2
                         ,iv_token_value2 => l_col_data_tab(2)   -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_lctn_cd      -- �g�[�N���R�[�h3
                         ,iv_token_value3 => l_col_data_tab(5)   -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_bsinss_yr    -- �g�[�N���R�[�h4
                         ,iv_token_value4 => l_col_data_tab(3)   -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_yr_mnth      -- �g�[�N���R�[�h5
                         ,iv_token_value5 => l_col_data_tab(4)   -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_sls_prsn_cd  -- �g�[�N���R�[�h6
                         ,iv_token_value6 => l_col_data_tab(17)  -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_sls_prsn_nm  -- �g�[�N���R�[�h7
                         ,iv_token_value7 => l_col_data_tab(18)  -- �g�[�N���l7
                       );
          lv_errbuf  := lv_errmsg;
          RAISE data_proper_check_skip_expt;
        ELSIF (l_col_data_tab(5) IS NULL) THEN
          -- ���_�R�[�hNULL�`�F�b�N
          lb_null_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(5);
        ELSIF (chk_number(l_col_data_tab(5)) = FALSE) THEN
          -- ���_�R�[�hNUMBER�^�`�F�b�N
          lb_num_chck    := FALSE;
          lv_item_nm     := c_item_name_tab(5);
        ELSIF (LENGTHB(l_col_data_tab(5)) <> cn_base_code_len) THEN
          -- ���_�R�[�h�T�C�Y�`�F�b�N
          lb_len_chck    := FALSE;
          lv_item_nm     := c_item_name_tab(5);
        END IF;
--
        IF ((lb_null_chck   = TRUE)     -- �G���[���������Ȃ������ꍇ�A���̃`�F�b�N��
          AND (lb_inpk_chck   = TRUE)
          AND (lb_dtk_chck    = TRUE)
          AND (lb_num_chck    = TRUE)
          AND (lb_date_chck   = TRUE)
          AND (lb_len_chck    = TRUE)
          AND (lb_loop_chck   = TRUE)
          AND (lb_gl_val_chck = TRUE))
        THEN
          -- 4)���͋敪�E�f�[�^��ʕʍ��ڃ`�F�b�N
          IF ((l_col_data_tab(1) = cn_inp_knd_rt)
            AND (l_col_data_tab(2) = cn_dt_knd_base))
          THEN
          -- �@���͋敪=1[���[�g] ���� �f�[�^���=1[���_��]�̂Ƃ�
            ln_i := cn_inrt_dtbs_cnt_st;        -- �`�F�b�N�p�J�E���^�[(���ڔԍ�[�J�n])�Z�b�g
--
            <<inp_rt_data_bs_chck_loop>>
            WHILE (lb_loop_chck = TRUE) LOOP
              --*** 1:�V�K�v��(�z��6�Ԗ�)�`11:�ڕW���v����(�ڕW�m���})(�z��16�Ԗ�)�`�F�b�N ***--
              IF (chk_number(l_col_data_tab(ln_i)) = FALSE) THEN
                -- NUMBER�^�`�F�b�N
                lb_loop_chck  := FALSE;
                lb_num_chck   := FALSE;
                lv_item_nm    := c_item_name_tab(ln_i);
              ELSIF (LENGTHB(l_col_data_tab(ln_i)) > cn_base_pln_len) THEN
                -- �T�C�Y�`�F�b�N
                lb_loop_chck  := FALSE;
                lb_len_chck   := FALSE;
                lv_item_nm    := c_item_name_tab(ln_i);
              END IF;
              IF ln_i = cn_inrt_dtbs_cnt_ed THEN  -- �`�F�b�N�p�J�E���^�[(���ڔԍ�[�I��])����
                lb_loop_chck  := FALSE;
              END IF;
--
              ln_i := ln_i + 1;
            END LOOP inp_rt_data_bs_chck_loop;
--
          ELSIF ((l_col_data_tab(1) = cn_inp_knd_rt)
            AND (l_col_data_tab(2) = cn_dt_knd_prsn))
          THEN
          -- �A���͋敪=1[���[�g] ���� �f�[�^���=2[�c�ƈ���]�̂Ƃ�
--
            --*** 1:�c�ƈ��R�[�h�`�F�b�N ***--
            IF (l_col_data_tab(17) IS NULL) THEN
              -- �c�ƈ��R�[�hNULL�`�F�b�N
              lb_null_chck  := FALSE;
              lv_item_nm    := c_item_name_tab(17);
            ELSIF (LENGTHB(l_col_data_tab(17)) <> cn_emply_num_len) THEN
              -- �c�ƈ��R�[�h�T�C�Y�`�F�b�N
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(17);
            --*** 2:�O���[�v�ԍ��`�F�b�N ***--
            ELSIF (l_col_data_tab(20) IS NULL) THEN
              -- �O���[�v�ԍ�NULL�`�F�b�N
              lb_null_chck  := FALSE;
              lv_item_nm    := c_item_name_tab(20);
            ELSIF (LENGTHB(l_col_data_tab(20)) > cn_group_len) THEN
              -- �O���[�v�ԍ��T�C�Y�`�F�b�N
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(20);
            --*** 3:�O���[�v���敪�T�C�Y�`�F�b�N ***--
            ELSIF (LENGTHB(l_col_data_tab(21)) > cn_group_leader_len) THEN
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(21);
              -- �O���[�v���敪�l�`�F�b�N
            ELSIF (l_col_data_tab(21) IS NOT NULL)
              AND ((l_col_data_tab(21) <> cv_grprd_flg_vl_1)
              AND (l_col_data_tab(21) <> cv_grprd_flg_vl_2)) THEN
                  lb_gl_val_chck  := FALSE;
                  lv_item_nm      := c_item_name_tab(21);
            --*** 4:�O���[�v�������T�C�Y�`�F�b�N ***--
            ELSIF (LENGTHB(l_col_data_tab(22)) > cn_group_len) THEN
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(22);
            ELSE
              ln_i := cn_inrt_dtprsn_cnt_st;        -- �`�F�b�N�p�J�E���^�[(���ڔԍ�[�J�n])�Z�b�g
--
              <<inp_rt_data_prsn_chck_loop>>
              WHILE (lb_loop_chck = TRUE) LOOP
                --*** 5:�O�N����(VD:�V�K�v��)(�z��23�Ԗ�)�`�K��(�c�ƈ��v:�v)(�z��82�Ԗ�)�`�F�b�N ***--
                IF (chk_number(l_col_data_tab(ln_i)) = FALSE) THEN
                  -- NUMBER�^�`�F�b�N
                  lb_loop_chck   := FALSE;
                  lb_num_chck    := FALSE;
                  lv_item_nm     := c_item_name_tab(ln_i);
                ELSIF (ln_i <= cn_befor_visit)
                  AND (LENGTHB(l_col_data_tab(ln_i)) > cn_sls_prsn_pln_len)
                THEN
                  -- �K��ȊO�T�C�Y�`�F�b�N
                  lb_loop_chck   := FALSE;
                  lb_len_chck    := FALSE;
                  lv_item_nm     := c_item_name_tab(ln_i);
                ELSIF (ln_i > cn_befor_visit)
                  AND (LENGTHB(l_col_data_tab(ln_i)) > cn_sls_prsn_vst_len)
                THEN
                  -- �K��T�C�Y�`�F�b�N
                  lb_loop_chck   := FALSE;
                  lb_len_chck    := FALSE;
                  lv_item_nm     := c_item_name_tab(ln_i);
--
                ELSE
                  -- �w�荀�ڂ�NULL���ǂ����`�F�b�N
                  <<null_check_loop>>
                  FOR ln_j IN 1..c_null_chck_num_tab.count LOOP
                    IF (ln_i = c_null_chck_num_tab(ln_j)) THEN  -- ���݂̍��ړY�����w��̍��ڂƈ�v���邩
                      IF (l_col_data_tab(ln_i) IS NULL) THEN
                        ln_null_count := ln_null_count + 1;     -- ��v�����ꍇ�́A�J�E���g
--
                      END IF;
                    END IF;
                  END LOOP null_check_loop;
--
                END IF;
--
                IF ln_i = cn_inrt_dtprsn_cnt_ed THEN  -- �`�F�b�N�p�J�E���^�[(���ڔԍ�[�I��])����
                  lb_loop_chck   := FALSE;
                END IF;
--
                ln_i := ln_i + 1;
--
              END LOOP inp_rt_data_prsn_chck_loop;
--
              IF (ln_null_count = c_null_chck_num_tab.COUNT) THEN  
              -- NULL�̍��ڐ�����v���Ă����ꍇ�ANULL�t���O�ɗL���l���Z�b�g
                 ln_null_flag   := cn_effective_val;
              END IF;
--
            END IF;
--
          ELSIF ((l_col_data_tab(1) = cn_inp_knd_hnb)
            AND (l_col_data_tab(2) = cn_dt_knd_base))
          THEN
          -- �B���͋敪=2[�{��] ���� �f�[�^���=1[���_��]�̂Ƃ�
        
            --*** 1:��{���v����(��{�m���})�`�F�b�N ***--
            IF (chk_number(l_col_data_tab(10)) = FALSE) THEN
              -- NUMBER�^�`�F�b�N
              lb_num_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(10);
            ELSIF (LENGTHB(l_col_data_tab(10)) > cn_base_pln_len) THEN
              -- �T�C�Y�`�F�b�N
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(10);
            --*** 3:�ڕW�l���`�F�b�N ***--
            ELSIF (chk_number(l_col_data_tab(15)) = FALSE) THEN
              -- NUMBER�^�`�F�b�N
              lb_num_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(15);
            ELSIF (LENGTHB(l_col_data_tab(15)) > cn_base_pln_len) THEN
              -- �T�C�Y�`�F�b�N
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(15);
            --*** 4:�ڕW���v����(�ڕW�m���})�`�F�b�N ***--
            ELSIF (chk_number(l_col_data_tab(16)) = FALSE) THEN
              -- NUMBER�^�`�F�b�N
              lb_num_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(16);
            ELSIF (LENGTHB(l_col_data_tab(16)) > cn_base_pln_len) THEN
              -- �T�C�Y�`�F�b�N
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(16);
            END IF;
--
          ELSIF ((l_col_data_tab(1) = cn_inp_knd_hnb)
            AND (l_col_data_tab(2) = cn_dt_knd_prsn))
          THEN
          -- �C���͋敪=2[�{��] ���� �f�[�^���=2[�c�ƈ���]�̂Ƃ�

            --*** 1:�c�ƈ��R�[�h�`�F�b�N ***--
            IF (l_col_data_tab(17) IS NULL) THEN
              -- �c�ƈ��R�[�hNULL�`�F�b�N
              lb_null_chck  := FALSE;
              lv_item_nm    := c_item_name_tab(17);
            ELSIF (LENGTHB(l_col_data_tab(17)) <> cn_emply_num_len) THEN
              -- �c�ƈ��R�[�h�T�C�Y�`�F�b�N
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(17);
            --*** 2:�O���[�v�ԍ��`�F�b�N ***--
            ELSIF (l_col_data_tab(20) IS NULL) THEN
              -- �O���[�v�ԍ�NULL�`�F�b�N
              lb_null_chck  := FALSE;
              lv_item_nm    := c_item_name_tab(20);
            ELSIF (LENGTHB(l_col_data_tab(20)) > cn_group_len) THEN
              -- �O���[�v�ԍ��T�C�Y�`�F�b�N
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(20);
            --*** 3:�O���[�v���敪�T�C�Y�`�F�b�N ***--
            ELSIF (LENGTHB(l_col_data_tab(21)) > cn_group_leader_len) THEN
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(21);
              -- �O���[�v���敪�l�`�F�b�N
            ELSIF (l_col_data_tab(21) IS NOT NULL)
              AND ((l_col_data_tab(21) <> cv_grprd_flg_vl_1)
              AND (l_col_data_tab(21) <> cv_grprd_flg_vl_2)) THEN
                  lb_gl_val_chck  := FALSE;
                  lv_item_nm      := c_item_name_tab(21);
            --*** 4:�O���[�v�������T�C�Y�`�F�b�N ***--
            ELSIF (LENGTHB(l_col_data_tab(22)) > cn_group_len) THEN
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(22);
            --*** 5:��{����(�c�ƈ��v:�v)�`�F�b�N ***--
            ELSIF (chk_number(l_col_data_tab(46)) = FALSE) THEN
              -- NUMBER�^�`�F�b�N
              lb_num_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(46);
            ELSIF (LENGTHB(l_col_data_tab(46)) > cn_sls_prsn_pln_len) THEN
              -- �T�C�Y�`�F�b�N
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(46);
            --*** 6:�ڕW����(�c�ƈ��v:�v)�`�F�b�N ***--
            ELSIF (chk_number(l_col_data_tab(58)) = FALSE) THEN
              -- NUMBER�^�`�F�b�N
              lb_num_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(58);
            ELSIF (LENGTHB(l_col_data_tab(58)) > cn_sls_prsn_pln_len) THEN
              -- �T�C�Y�`�F�b�N
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(58);
            --*** 7:�K��(�c�ƈ��v:�v)�`�F�b�N ***--
            ELSIF (chk_number(l_col_data_tab(82)) = FALSE) THEN
              -- NUMBER�^�`�F�b�N
              lb_num_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(82);
            ELSIF (LENGTHB(l_col_data_tab(82)) > cn_sls_prsn_vst_len) THEN
              -- �T�C�Y�`�F�b�N
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(82);
            END IF;
            
            -- ��{����(�c�ƈ��v:�v)�E�ڕW����(�c�ƈ��v:�v)�E�K��(�c�ƈ��v:�v)NULL�`�F�b�N
            IF ((l_col_data_tab(46) IS NULL) AND
                (l_col_data_tab(58) IS NULL) AND
                (l_col_data_tab(82) IS NULL)) THEN
              ln_null_flag := cn_effective_val;
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      IF (lb_null_chck = FALSE) THEN  -- �V�X�e���I�ɏo�͂��Ă��鍀�ڂ�NULL�̏ꍇ�̃G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_39    -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm          -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn    -- �g�[�N���R�[�h2
                       ,iv_token_value2 => l_col_data_tab(1)   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_lctn_cd      -- �g�[�N���R�[�h3
                       ,iv_token_value3 => l_col_data_tab(5)   -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_dt_kbn       -- �g�[�N���R�[�h4
                       ,iv_token_value4 => l_col_data_tab(2)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth      -- �g�[�N���R�[�h5
                       ,iv_token_value5 => l_col_data_tab(4)   -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd  -- �g�[�N���R�[�h6
                       ,iv_token_value6 => l_col_data_tab(17)  -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm  -- �g�[�N���R�[�h7
                       ,iv_token_value7 => l_col_data_tab(18)  -- �g�[�N���l7
                     );
        lv_errbuf  := lv_errmsg;
        RAISE data_proper_check_skip_expt;
--
      ELSIF (lb_inpk_chck = FALSE) THEN  -- ���͋敪�`�F�b�N�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_25    -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_insrt_kbn    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => l_col_data_tab(1)   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_dt_kbn       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => l_col_data_tab(2)   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_lctn_cd      -- �g�[�N���R�[�h3
                       ,iv_token_value3 => l_col_data_tab(5)   -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_yr_mnth      -- �g�[�N���R�[�h4
                       ,iv_token_value4 => l_col_data_tab(4)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_sls_prsn_cd  -- �g�[�N���R�[�h5
                       ,iv_token_value5 => l_col_data_tab(17)  -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_nm  -- �g�[�N���R�[�h6
                       ,iv_token_value6 => l_col_data_tab(18)  -- �g�[�N���l6
                     );
        lv_errbuf  := lv_errmsg;
        RAISE data_proper_check_skip_expt;
--
      ELSIF (lb_dtk_chck = FALSE) THEN  -- �f�[�^��ʃ`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_26    -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_insrt_kbn    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => l_col_data_tab(1)   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_dt_kbn       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => l_col_data_tab(2)   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_lctn_cd      -- �g�[�N���R�[�h3
                       ,iv_token_value3 => l_col_data_tab(5)   -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_yr_mnth      -- �g�[�N���R�[�h4
                       ,iv_token_value4 => l_col_data_tab(4)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_sls_prsn_cd  -- �g�[�N���R�[�h5
                       ,iv_token_value5 => l_col_data_tab(17)  -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_nm  -- �g�[�N���R�[�h6
                       ,iv_token_value6 => l_col_data_tab(18)  -- �g�[�N���l6
                     );
        lv_errbuf  := lv_errmsg;
        RAISE data_proper_check_skip_expt;
--
      ELSIF (lb_num_chck = FALSE) THEN  -- NUMBER�^�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_22    -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm          -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn    -- �g�[�N���R�[�h2
                       ,iv_token_value2 => l_col_data_tab(1)   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => l_col_data_tab(2)   -- �g�[�N���l3                       
                       ,iv_token_name4  => cv_tkn_lctn_cd      -- �g�[�N���R�[�h4
                       ,iv_token_value4 => l_col_data_tab(5)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth      -- �g�[�N���R�[�h5
                       ,iv_token_value5 => l_col_data_tab(4)   -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd  -- �g�[�N���R�[�h6
                       ,iv_token_value6 => l_col_data_tab(17)  -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm  -- �g�[�N���R�[�h7
                       ,iv_token_value7 => l_col_data_tab(18)  -- �g�[�N���l7
                     );
        lv_errbuf := lv_errmsg;
        RAISE data_proper_check_skip_expt;
--
      ELSIF (lb_date_chck = FALSE) THEN  -- ���t�����`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_24    -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm          -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn    -- �g�[�N���R�[�h2
                       ,iv_token_value2 => l_col_data_tab(1)   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => l_col_data_tab(2)   -- �g�[�N���l3                       
                       ,iv_token_name4  => cv_tkn_lctn_cd      -- �g�[�N���R�[�h4
                       ,iv_token_value4 => l_col_data_tab(5)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth      -- �g�[�N���R�[�h5
                       ,iv_token_value5 => l_col_data_tab(4)   -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd  -- �g�[�N���R�[�h6
                       ,iv_token_value6 => l_col_data_tab(17)  -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm  -- �g�[�N���R�[�h7
                       ,iv_token_value7 => l_col_data_tab(18)  -- �g�[�N���l7
                     );
        lv_errbuf := lv_errmsg;
        RAISE data_proper_check_skip_expt;
--
      ELSIF (lb_len_chck = FALSE) THEN  -- �T�C�Y�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_23    -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm          -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn    -- �g�[�N���R�[�h2
                       ,iv_token_value2 => l_col_data_tab(1)   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => l_col_data_tab(2)   -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_lctn_cd      -- �g�[�N���R�[�h4
                       ,iv_token_value4 => l_col_data_tab(5)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth      -- �g�[�N���R�[�h5
                       ,iv_token_value5 => l_col_data_tab(4)   -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd  -- �g�[�N���R�[�h6
                       ,iv_token_value6 => l_col_data_tab(17)  -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm  -- �g�[�N���R�[�h7
                       ,iv_token_value7 => l_col_data_tab(18)  -- �g�[�N���l7
                     );
        lv_errbuf := lv_errmsg;
        RAISE data_proper_check_skip_expt;
--
      ELSIF (lb_gl_val_chck = FALSE) THEN -- �O���[�v���敪�l�`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_40    -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_insrt_kbn    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => l_col_data_tab(1)   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_dt_kbn       -- �g�[�N���R�[�h2
                       ,iv_token_value2 => l_col_data_tab(2)   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_lctn_cd      -- �g�[�N���R�[�h3
                       ,iv_token_value3 => l_col_data_tab(5)   -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_yr_mnth      -- �g�[�N���R�[�h4
                       ,iv_token_value4 => l_col_data_tab(4)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_sls_prsn_cd  -- �g�[�N���R�[�h5
                       ,iv_token_value5 => l_col_data_tab(17)  -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_nm  -- �g�[�N���R�[�h6
                       ,iv_token_value6 => l_col_data_tab(18)  -- �g�[�N���l6
                     );
        lv_errbuf  := lv_errmsg;
        RAISE data_proper_check_skip_expt;
      END IF;
--
      -- �s�P�ʃf�[�^�����R�[�h�ɃZ�b�g
      IF ((l_col_data_tab(1) = cn_inp_knd_rt) AND (l_col_data_tab(2) = cn_dt_knd_base)) THEN
      -- ���[�g�c�Ɨp�E���_�ʃf�[�^�̏ꍇ
        g_sls_pln_data_tab(i).input_division           :=  TO_NUMBER(l_col_data_tab(1));   -- ���͋敪
        g_sls_pln_data_tab(i).data_kind                :=  TO_NUMBER(l_col_data_tab(2));   -- �f�[�^���
        g_sls_pln_data_tab(i).fiscal_year              :=  l_col_data_tab(3);              -- �N�x
        g_sls_pln_data_tab(i).year_month               :=  l_col_data_tab(4);              -- �N��
        g_sls_pln_data_tab(i).base_code                :=  l_col_data_tab(5);              -- ���_CD
        g_sls_pln_data_tab(i).bsc_nw_srvc_mt           :=  TO_NUMBER(l_col_data_tab(6));   -- ��{�V�K�v��
        g_sls_pln_data_tab(i).bsc_nxt_srvc_mt          :=  TO_NUMBER(l_col_data_tab(7));   -- ��{���N�v��
        g_sls_pln_data_tab(i).bsc_xst_srvc_mt          :=  TO_NUMBER(l_col_data_tab(8));   -- ��{��������
        g_sls_pln_data_tab(i).bsc_dscnt_mt             :=  TO_NUMBER(l_col_data_tab(9));   -- ��{�l����
        g_sls_pln_data_tab(i).bsc_sls_ttl_mt_nlm       :=  TO_NUMBER(l_col_data_tab(10));  -- ��{���v����(��{�m���})
        g_sls_pln_data_tab(i).visit                    :=  TO_NUMBER(l_col_data_tab(11));  -- �K��
        g_sls_pln_data_tab(i).trgt_nw_srvc_mt          :=  TO_NUMBER(l_col_data_tab(12));  -- �ڕW�V�K�v��
        g_sls_pln_data_tab(i).trgt_nxt_srvc_mt         :=  TO_NUMBER(l_col_data_tab(13));  -- �ڕW���N�v��
        g_sls_pln_data_tab(i).trgt_xst_srvc_mt         :=  TO_NUMBER(l_col_data_tab(14));  -- �ڕW��������
        g_sls_pln_data_tab(i).trgt_dscnt_mt            :=  TO_NUMBER(l_col_data_tab(15));  -- �ڕW�l��
        g_sls_pln_data_tab(i).trgt_sls_ttl_mt          :=  TO_NUMBER(l_col_data_tab(16));  -- �ڕW���v����(�ڕW�m���})
        g_sls_pln_data_tab(i).sls_prsn_ffctv_flg       :=  cn_ineffective_val;              -- �c�ƈ��L���t���O
        g_sls_pln_data_tab(i).inpt_dt_is_nll_flg       :=  ln_null_flag;        -- ���͍���NULL�t���O
        g_sls_pln_data_tab(i).db_dt_xst_flg            :=  cn_ineffective_val;  -- DB�f�[�^���݃t���O
        g_sls_pln_data_tab(i).bs_pln_chng_flg          :=  cn_ineffective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
--
      ELSIF ((l_col_data_tab(1) = cn_inp_knd_hnb) AND (l_col_data_tab(2) = cn_dt_knd_base)) THEN
      -- �{���c�Ɨp�E���_�ʃf�[�^�̏ꍇ
        g_sls_pln_data_tab(i).input_division           :=  TO_NUMBER(l_col_data_tab(1));   -- ���͋敪
        g_sls_pln_data_tab(i).data_kind                :=  TO_NUMBER(l_col_data_tab(2));   -- �f�[�^���
        g_sls_pln_data_tab(i).fiscal_year              :=  l_col_data_tab(3);              -- �N�x
        g_sls_pln_data_tab(i).year_month               :=  l_col_data_tab(4);              -- �N��
        g_sls_pln_data_tab(i).base_code                :=  l_col_data_tab(5);              -- ���_CD
        g_sls_pln_data_tab(i).bsc_sls_ttl_mt_nlm       :=  TO_NUMBER(l_col_data_tab(10));  -- ��{���v����(��{�m���})
        g_sls_pln_data_tab(i).trgt_dscnt_mt            :=  TO_NUMBER(l_col_data_tab(15));  -- �ڕW�l��
        g_sls_pln_data_tab(i).trgt_sls_ttl_mt          :=  TO_NUMBER(l_col_data_tab(16));  -- �ڕW���v����(�ڕW�m���})
        g_sls_pln_data_tab(i).sls_prsn_ffctv_flg       :=  cn_ineffective_val;              -- �c�ƈ��L���t���O
        g_sls_pln_data_tab(i).inpt_dt_is_nll_flg       :=  ln_null_flag;        -- ���͍���NULL�t���O
        g_sls_pln_data_tab(i).db_dt_xst_flg            :=  cn_ineffective_val;  -- DB�f�[�^���݃t���O
        g_sls_pln_data_tab(i).bs_pln_chng_flg          :=  cn_ineffective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
--
      ELSIF ((l_col_data_tab(1) = cn_inp_knd_rt) AND (l_col_data_tab(2) = cn_dt_knd_prsn)) THEN
      -- ���[�g�c�Ɨp�E�c�ƈ��ʃf�[�^�̏ꍇ
        g_sls_pln_data_tab(i).input_division           :=  TO_NUMBER(l_col_data_tab(1));   -- ���͋敪
        g_sls_pln_data_tab(i).data_kind                :=  TO_NUMBER(l_col_data_tab(2));   -- �f�[�^���
        g_sls_pln_data_tab(i).fiscal_year              :=  l_col_data_tab(3);              -- �N�x
        g_sls_pln_data_tab(i).year_month               :=  l_col_data_tab(4);              -- �N��
        g_sls_pln_data_tab(i).base_code                :=  l_col_data_tab(5);              -- ���_CD
        g_sls_pln_data_tab(i).emply_nmbr               :=  l_col_data_tab(17);             -- �c�ƈ�CD
        g_sls_pln_data_tab(i).emply_nm                 :=  l_col_data_tab(18);             -- �c�ƈ���
        g_sls_pln_data_tab(i).offc_rnk_nm              :=  l_col_data_tab(19);             -- �E�ʖ�
        g_sls_pln_data_tab(i).grp_nmbr                 :=  l_col_data_tab(20);             -- �O���[�v�ԍ�
        g_sls_pln_data_tab(i).grp_ldr_flg              :=  l_col_data_tab(21);             -- �O���[�v���敪
        g_sls_pln_data_tab(i).grp_grd                  :=  l_col_data_tab(22);             -- �O���[�v������
        g_sls_pln_data_tab(i).pr_rslt_vd_nw_srv_mt     :=  TO_NUMBER(l_col_data_tab(23));  -- �O�N����(VD:�V�K�v��)
        g_sls_pln_data_tab(i).pr_rslt_vd_nxt_srv_mt    :=  TO_NUMBER(l_col_data_tab(24));  -- �O�N����(VD:���N�v��)
        g_sls_pln_data_tab(i).pr_rslt_vd_xst_srv_mt    :=  TO_NUMBER(l_col_data_tab(25));  -- �O�N����(VD:��������)
        g_sls_pln_data_tab(i).pr_rslt_vd_ttl_mt        :=  TO_NUMBER(l_col_data_tab(26));    -- �O�N����(VD:�v)
        g_sls_pln_data_tab(i).pr_rslt_nw_srv_mt        :=  TO_NUMBER(l_col_data_tab(27));    -- �O�N����(VD�ȊO:�V�K�v��)
        g_sls_pln_data_tab(i).pr_rslt_nxt_srv_mt       :=  TO_NUMBER(l_col_data_tab(28));    -- �O�N����(VD�ȊO:���N�v��)
        g_sls_pln_data_tab(i).pr_rslt_xst_srv_mt       :=  TO_NUMBER(l_col_data_tab(29));    -- �O�N����(VD�ȊO:��������)
        g_sls_pln_data_tab(i).pr_rslt_ttl_mt           :=  TO_NUMBER(l_col_data_tab(30));    -- �O�N����(VD�ȊO:�v)
        g_sls_pln_data_tab(i).pr_rslt_prsn_nw_srv_mt   :=  TO_NUMBER(l_col_data_tab(31));    -- �O�N����(�c�ƈ��v:�V�K�v��)
        g_sls_pln_data_tab(i).pr_rslt_prsn_nxt_srv_mt  :=  TO_NUMBER(l_col_data_tab(32));    -- �O�N����(�c�ƈ��v:���N�v��)
        g_sls_pln_data_tab(i).pr_rslt_prsn_xst_srv_mt  :=  TO_NUMBER(l_col_data_tab(33));    -- �O�N����(�c�ƈ��v:��������)
        g_sls_pln_data_tab(i).pr_rslt_prsn_ttl_mt      :=  TO_NUMBER(l_col_data_tab(34));    -- �O�N����(�c�ƈ��v:�v)
        g_sls_pln_data_tab(i).bsc_sls_vd_nw_srv_mt     :=  TO_NUMBER(l_col_data_tab(35));    -- ��{����(VD:�V�K�v��)
        g_sls_pln_data_tab(i).bsc_sls_vd_nxt_srv_mt    :=  TO_NUMBER(l_col_data_tab(36));    -- ��{����(VD:���N�v��)
        g_sls_pln_data_tab(i).bsc_sls_vd_xst_srv_mt    :=  TO_NUMBER(l_col_data_tab(37));    -- ��{����(VD:��������)
        g_sls_pln_data_tab(i).bsc_sls_vd_ttl_mt        :=  TO_NUMBER(l_col_data_tab(38));    -- ��{����(VD:�v)
        g_sls_pln_data_tab(i).bsc_sls_nw_srv_mt        :=  TO_NUMBER(l_col_data_tab(39));    -- ��{����(VD�ȊO:�V�K�v��)
        g_sls_pln_data_tab(i).bsc_sls_nxt_srv_mt       :=  TO_NUMBER(l_col_data_tab(40));    -- ��{����(VD�ȊO:���N�v��)
        g_sls_pln_data_tab(i).bsc_sls_xst_srv_mt       :=  TO_NUMBER(l_col_data_tab(41));    -- ��{����(VD�ȊO:��������)
        g_sls_pln_data_tab(i).bsc_sls_ttl_mt           :=  TO_NUMBER(l_col_data_tab(42));    -- ��{����(VD�ȊO:�v)
        g_sls_pln_data_tab(i).bsc_sls_prsn_nw_srv_mt   :=  TO_NUMBER(l_col_data_tab(43));    -- ��{����(�c�ƈ��v:�V�K�v��)
        g_sls_pln_data_tab(i).bsc_sls_prsn_nxt_srv_mt  :=  TO_NUMBER(l_col_data_tab(44));    -- ��{����(�c�ƈ��v:���N�v��)
        g_sls_pln_data_tab(i).bsc_sls_prsn_xst_srv_mt  :=  TO_NUMBER(l_col_data_tab(45));    -- ��{����(�c�ƈ��v:��������)
        g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt      :=  TO_NUMBER(l_col_data_tab(46));    -- ��{����(�c�ƈ��v:�v)
        g_sls_pln_data_tab(i).tgt_sls_vd_nw_srv_mt     :=  TO_NUMBER(l_col_data_tab(47));    -- �ڕW����(VD:�V�K�v��)
        g_sls_pln_data_tab(i).tgt_sls_vd_nxt_srv_mt    :=  TO_NUMBER(l_col_data_tab(48));    -- �ڕW����(VD:���N�v��)
        g_sls_pln_data_tab(i).tgt_sls_vd_xst_srv_mt    :=  TO_NUMBER(l_col_data_tab(49));    -- �ڕW����(VD:��������)
        g_sls_pln_data_tab(i).tgt_sls_vd_ttl_mt        :=  TO_NUMBER(l_col_data_tab(50));    -- �ڕW����(VD:�v)
        g_sls_pln_data_tab(i).tgt_sls_nw_srv_mt        :=  TO_NUMBER(l_col_data_tab(51));    -- �ڕW����(VD�ȊO:�V�K�v��)
        g_sls_pln_data_tab(i).tgt_sls_nxt_srv_mt       :=  TO_NUMBER(l_col_data_tab(52));    -- �ڕW����(VD�ȊO:���N�v��)
        g_sls_pln_data_tab(i).tgt_sls_xst_srv_mt       :=  TO_NUMBER(l_col_data_tab(53));    -- �ڕW����(VD�ȊO:��������)
        g_sls_pln_data_tab(i).tgt_sls_ttl_mt           :=  TO_NUMBER(l_col_data_tab(54));    -- �ڕW����(VD�ȊO:�v)
        g_sls_pln_data_tab(i).tgt_sls_prsn_nw_srv_mt   :=  TO_NUMBER(l_col_data_tab(55));    -- �ڕW����(�c�ƈ��v:�V�K�v��)
        g_sls_pln_data_tab(i).tgt_sls_prsn_nxt_srv_mt  :=  TO_NUMBER(l_col_data_tab(56));    -- �ڕW����(�c�ƈ��v:���N�v��)
        g_sls_pln_data_tab(i).tgt_sls_prsn_xst_srv_mt  :=  TO_NUMBER(l_col_data_tab(57));    -- �ڕW����(�c�ƈ��v:��������)
        g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt      :=  TO_NUMBER(l_col_data_tab(58));    -- �ڕW����(�c�ƈ��v:�v)
        g_sls_pln_data_tab(i).rslt_vd_nw_srv_mt        :=  TO_NUMBER(l_col_data_tab(59));    -- ����(VD:�V�K�v��)
        g_sls_pln_data_tab(i).rslt_vd_nxt_srv_mt       :=  TO_NUMBER(l_col_data_tab(60));    -- ����(VD:���N�v��)
        g_sls_pln_data_tab(i).rslt_vd_xst_srv_mt       :=  TO_NUMBER(l_col_data_tab(61));    -- ����(VD:��������)
        g_sls_pln_data_tab(i).rslt_vd_total_amt        :=  TO_NUMBER(l_col_data_tab(62));    -- ����(VD:�v)
        g_sls_pln_data_tab(i).rslt_nw_srv_mt           :=  TO_NUMBER(l_col_data_tab(63));    -- ����(VD�ȊO:�V�K�v��)
        g_sls_pln_data_tab(i).rslt_nxt_srv_mt          :=  TO_NUMBER(l_col_data_tab(64));    -- ����(VD�ȊO:���N�v��)
        g_sls_pln_data_tab(i).rslt_xst_srv_mt          :=  TO_NUMBER(l_col_data_tab(65));    -- ����(VD�ȊO:��������)
        g_sls_pln_data_tab(i).rslt_ttl_mt              :=  TO_NUMBER(l_col_data_tab(66));    -- ����(VD�ȊO:�v)
        g_sls_pln_data_tab(i).rslt_prsn_nw_srv_mt      :=  TO_NUMBER(l_col_data_tab(67));    -- ����(�c�ƈ��v:�V�K�v��)
        g_sls_pln_data_tab(i).rslt_prsn_nxt_srv_mt     :=  TO_NUMBER(l_col_data_tab(68));    -- ����(�c�ƈ��v:���N�v��)
        g_sls_pln_data_tab(i).rslt_prsn_xst_srv_mt     :=  TO_NUMBER(l_col_data_tab(69));    -- ����(�c�ƈ��v:��������)
        g_sls_pln_data_tab(i).rslt_prsn_ttl_mt         :=  TO_NUMBER(l_col_data_tab(70));    -- ����(�c�ƈ��v:�v)
        g_sls_pln_data_tab(i).vis_vd_nw_srv_mt         :=  TO_NUMBER(l_col_data_tab(71));    -- �K��(VD:�V�K�v��)
        g_sls_pln_data_tab(i).vis_vd_nxt_srv_mt        :=  TO_NUMBER(l_col_data_tab(72));    -- �K��(VD:���N�v��)
        g_sls_pln_data_tab(i).vis_vd_xst_srv_mt        :=  TO_NUMBER(l_col_data_tab(73));    -- �K��(VD:��������)
        g_sls_pln_data_tab(i).vis_vd_ttl_mt            :=  TO_NUMBER(l_col_data_tab(74));    -- �K��(VD:�v)
        g_sls_pln_data_tab(i).vis_nw_srv_mt            :=  TO_NUMBER(l_col_data_tab(75));    -- �K��(VD�ȊO:�V�K�v��)
        g_sls_pln_data_tab(i).vis_nxt_srv_mt           :=  TO_NUMBER(l_col_data_tab(76));    -- �K��(VD�ȊO:���N�v��)
        g_sls_pln_data_tab(i).vis_xst_srv_mt           :=  TO_NUMBER(l_col_data_tab(77));    -- �K��(VD�ȊO:��������)
        g_sls_pln_data_tab(i).vis_ttl_mt               :=  TO_NUMBER(l_col_data_tab(78));    -- �K��(VD�ȊO:�v)
        g_sls_pln_data_tab(i).vis_prsn_nw_srv_mt       :=  TO_NUMBER(l_col_data_tab(79));    -- �K��(�c�ƈ��v:�V�K�v��)
        g_sls_pln_data_tab(i).vis_prsn_nxt_srv_mt      :=  TO_NUMBER(l_col_data_tab(80));    -- �K��(�c�ƈ��v:���N�v��)
        g_sls_pln_data_tab(i).vis_prsn_xst_srv_mt      :=  TO_NUMBER(l_col_data_tab(81));    -- �K��(�c�ƈ��v:��������)
        g_sls_pln_data_tab(i).vis_prsn_ttl_mt          :=  TO_NUMBER(l_col_data_tab(82));    -- �K��(�c�ƈ��v:�v)
        g_sls_pln_data_tab(i).sls_prsn_ffctv_flg       :=  cn_ineffective_val;              -- �c�ƈ��L���t���O
        g_sls_pln_data_tab(i).inpt_dt_is_nll_flg       :=  ln_null_flag;        -- ���͍���NULL�t���O
        g_sls_pln_data_tab(i).db_dt_xst_flg            :=  cn_ineffective_val;  -- DB�f�[�^���݃t���O
        g_sls_pln_data_tab(i).bs_pln_chng_flg          :=  cn_ineffective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O

--
      ELSIF ((l_col_data_tab(1) = cn_inp_knd_hnb) AND (l_col_data_tab(2) = cn_dt_knd_prsn)) THEN
      -- �{���c�Ɨp�E�c�ƈ��ʃf�[�^�̏ꍇ
        g_sls_pln_data_tab(i).input_division           :=  TO_NUMBER(l_col_data_tab(1));   -- ���͋敪
        g_sls_pln_data_tab(i).data_kind                :=  TO_NUMBER(l_col_data_tab(2));   -- �f�[�^���
        g_sls_pln_data_tab(i).fiscal_year              :=  l_col_data_tab(3);              -- �N�x
        g_sls_pln_data_tab(i).year_month               :=  l_col_data_tab(4);              -- �N��
        g_sls_pln_data_tab(i).base_code                :=  l_col_data_tab(5);              -- ���_CD
        g_sls_pln_data_tab(i).emply_nmbr               :=  l_col_data_tab(17);             -- �c�ƈ�CD
        g_sls_pln_data_tab(i).emply_nm                 :=  l_col_data_tab(18);             -- �c�ƈ���
        g_sls_pln_data_tab(i).offc_rnk_nm              :=  l_col_data_tab(19);             -- �E�ʖ�
        g_sls_pln_data_tab(i).grp_nmbr                 :=  l_col_data_tab(20);             -- �O���[�v�ԍ�
        g_sls_pln_data_tab(i).grp_ldr_flg              :=  l_col_data_tab(21);             -- �O���[�v���敪
        g_sls_pln_data_tab(i).grp_grd                  :=  l_col_data_tab(22);             -- �O���[�v������
        g_sls_pln_data_tab(i).pr_rslt_prsn_ttl_mt      :=  TO_NUMBER(l_col_data_tab(34));    -- �O�N����(�c�ƈ��v:�v)
        g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt      :=  TO_NUMBER(l_col_data_tab(46));    -- ��{����(�c�ƈ��v:�v)
        g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt      :=  TO_NUMBER(l_col_data_tab(58));    -- �ڕW����(�c�ƈ��v:�v)
        g_sls_pln_data_tab(i).vis_prsn_ttl_mt          :=  TO_NUMBER(l_col_data_tab(82));    -- �K��(�c�ƈ��v:�v)
        g_sls_pln_data_tab(i).sls_prsn_ffctv_flg       :=  cn_ineffective_val;              -- �c�ƈ��L���t���O
        g_sls_pln_data_tab(i).inpt_dt_is_nll_flg       :=  ln_null_flag;        -- ���͍���NULL�t���O
        g_sls_pln_data_tab(i).db_dt_xst_flg            :=  cn_ineffective_val;  -- DB�f�[�^���݃t���O
        g_sls_pln_data_tab(i).bs_pln_chng_flg          :=  cn_ineffective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** �Ó����`�F�b�N�����G���[��O�n���h�� ***
    WHEN data_proper_check_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    
    -- *** �Ó����`�F�b�N�����X�L�b�v��O�n���h�� ***
    WHEN data_proper_check_skip_expt THEN
      gn_dt_chck_err_cnt := gn_dt_chck_err_cnt + 1;  -- �G���[�J�E���g���Z
      ov_errmsg          := lv_errmsg;
      ov_errbuf          := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode         := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
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
  END data_proper_check;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_is_exists
   * Description      : �}�X�^���݃`�F�b�N (A-5)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_is_exists(
     iv_user_base_code  IN  VARCHAR2         -- ���O�C�����[�U�[�̋��_�R�[�h
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
    ,in_sls_pln_upld_cls_dy IN  NUMBER       -- ����v��A�b�v���[�h���c�Ɠ�
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
    ,ov_errbuf          OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode         OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg          OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'chk_mst_is_exists';  -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf           VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    ---- *** ���[�J���萔 ***
      -- �G���[���b�Z�[�W�p�萔
    cv_resource_table_nm            CONSTANT VARCHAR2(100) := '���\�[�X�}�X�^';
    cv_rsrc_and_grp_table_nm        CONSTANT VARCHAR2(100) := '���\�[�X�֘A�}�X�^(�ŐV�r���[)';
    cv_sls_prsn_mnthly_plns_nm      CONSTANT VARCHAR2(100) := '�c�ƈ��ʌ��ʌv��e�[�u��';
    cv_employee_number_nm           CONSTANT VARCHAR2(100) := '�c�ƈ��R�[�h';
    cv_bsc_sls_prsn_ttl_mt_nm       CONSTANT VARCHAR2(100) := '��{����(�c�ƈ��v:�v)';
    cv_tgt_sls_prsn_ttl_mt_nm       CONSTANT VARCHAR2(100) := '�ڕW����(�c�ƈ��v:�v)';
    cv_vis_prsn_ttl_mt_nm           CONSTANT VARCHAR2(100) := '�K��(�c�ƈ��v:�v)';
      -- �`�F�b�N�p��l:���t����
    cv_year_month_fmt               CONSTANT VARCHAR2(100) := 'YYYYMM';  -- �N�����e��DATE�^
--
    ---- *** ���[�J���ϐ� ***
      -- �T�u���C�����[�v�J�E���^�i�[�p
    i                               NUMBER;  -- A-5���g�p�z��Y����
      -- �}�X�^���݃`�F�b�N�p�ϐ�
    lv_base_code                    VARCHAR2(100);  -- ���o���_�ꎞ�i�[�ϐ�
    ld_standard_work_day            DATE;           -- ���(��5�c�Ɠ�)�i�[�p�ϐ�
    ln_emply_nmbr_num               NUMBER;         -- �c�ƈ��R�[�h��v����
    ln_emply_nmbr_nw_num            NUMBER;         -- �c�ƈ��R�[�h���݈�v����
    ln_sls_prsn_mnthly_pln_num      NUMBER;         -- �c�ƈ��ʌ��ʌv��e�[�u����v����
    ln_bsc_sls_vd_new_serv_amt      NUMBER;         -- ��{����(VD:�V�K�v��)�i�[�p�ϐ�
    ln_bsc_sls_vd_next_serv_amt     NUMBER;         -- ��{����(VD:���N�v��)�i�[�p�ϐ�
    ln_bsc_sls_vd_exist_serv_amt    NUMBER;         -- ��{����(VD:��������)�i�[�p�ϐ�
    ln_bsc_sls_vd_total_amt         NUMBER;         -- ��{����(VD:�v)�i�[�p�ϐ�
    ln_bsc_sls_new_serv_amt         NUMBER;         -- ��{����(VD�ȊO:�V�K�v��)�i�[�p�ϐ�
    ln_bsc_sls_next_serv_amt        NUMBER;         -- ��{����(VD�ȊO:���N�v��)�i�[�p�ϐ�
    ln_bsc_sls_exist_serv_amt       NUMBER;         -- ��{����(VD�ȊO:��������)�i�[�p�ϐ�
    ln_bsc_sls_total_amt            NUMBER;         -- ��{����(VD�ȊO:�v)�i�[�p�ϐ�
    ln_bsc_sls_prsn_new_serv_amt    NUMBER;         -- ��{����(�c�ƈ��v:�V�K�v��)�i�[�p�ϐ�
    ln_bsc_sls_prsn_next_serv_amt   NUMBER;         -- ��{����(�c�ƈ��v:���N�v��)�i�[�p�ϐ�
    ln_bsc_sls_prsn_exist_serv_amt  NUMBER;         -- ��{����(�c�ƈ��v:��������)�i�[�p�ϐ�
    ln_bsc_sls_prsn_total_amt       NUMBER;         -- ��{����(�c�ƈ��v:�v)�i�[�p�ϐ�
      -- �G���[���b�Z�[�W�p�ϐ�
    lv_item_nm                      VARCHAR2(100);  -- NULL�`�F�b�N�G���[���ږ�
      -- NULL�`�F�b�N�p�ϐ�
    lb_null_flag                    BOOLEAN := TRUE;
--
    -- *** ���[�J����O ***
    chk_mst_is_exists_skip_expt     EXCEPTION;      -- �}�X�^���݃`�F�b�N�������X�L�b�v��O
    count_num_zero_skip_expt        EXCEPTION;      -- �}�X�^���݃`�F�b�N���������o0�����X�L�b�v��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    i := g_rec_count;  -- A-5���g�p�z��Y�����ɃT�u���C���`�F�b�N�p���[�v�J�E���^���i�[
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
--    ld_standard_work_day := xxccp_common_pkg2.get_working_day((last_day(add_months(gd_now_date,-1))),5);
    ld_standard_work_day := xxccp_common_pkg2.get_working_day((last_day(add_months(gd_now_date,-1))),in_sls_pln_upld_cls_dy);
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
    -- ��5�c�Ɠ��擾
--
    -- 1)���_�R�[�h�����O�C�����[�U�[�̋��_�R�[�h�ƈ�v���邩�`�F�b�N
    IF (iv_user_base_code <> g_sls_pln_data_tab(i).base_code) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_27                       -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_insrt_kbn                       -- �g�[�N���R�[�h1
                     ,iv_token_value1 => g_sls_pln_data_tab(i).input_division   -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_dt_kbn                          -- �g�[�N���R�[�h2
                     ,iv_token_value2 => g_sls_pln_data_tab(i).data_kind        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_lctn_cd                         -- �g�[�N���R�[�h3
                     ,iv_token_value3 => g_sls_pln_data_tab(i).base_code        -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_yr_mnth                         -- �g�[�N���R�[�h4
                     ,iv_token_value4 => g_sls_pln_data_tab(i).year_month       -- �g�[�N���l4
                     ,iv_token_name5  => cv_tkn_sls_prsn_cd                     -- �g�[�N���R�[�h5
                     ,iv_token_value5 => g_sls_pln_data_tab(i).emply_nmbr       -- �g�[�N���l5
                     ,iv_token_name6  => cv_tkn_sls_prsn_nm                     -- �g�[�N���R�[�h6
                     ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nm         -- �g�[�N���l6
                    );
        lv_errbuf := lv_errmsg;
        RAISE chk_mst_is_exists_skip_expt;
    END IF;
--
    IF (g_sls_pln_data_tab(i).data_kind = cn_dt_knd_prsn) THEN  -- �ȍ~�͉c�ƈ��ʃf�[�^�̂݃`�F�b�N
--
      BEGIN
        -- 2)�c�ƈ��R�[�h�����\�[�X�}�X�^�ɑ��݂��邩�`�F�b�N
        SELECT COUNT(jrre.resource_id) resource_id_num  -- ���\�[�XID�J�E���g��
        INTO  ln_emply_nmbr_num                    -- �c�ƈ��R�[�h��v����
        FROM  jtf_rs_resource_extns_vl jrre        -- ���\�[�X�}�X�^
        WHERE jrre.source_number = g_sls_pln_data_tab(i).emply_nmbr
        AND   jrre.category = 'EMPLOYEE';
--
        IF (ln_emply_nmbr_num = 0) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_28                      -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_clmn                           -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_employee_number_nm                 -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_tbl                            -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_resource_table_nm                  -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h7
                         ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h8
                         ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l8
                       );
          lv_errbuf := lv_errmsg;
          RAISE count_num_zero_skip_expt;
        END IF;
--
      EXCEPTION
        WHEN count_num_zero_skip_expt THEN
        RAISE chk_mst_is_exists_skip_expt;
--
        -- ���o�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_07                      -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_resource_table_nm                  -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_err_msg                        -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                               -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h7
                         ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h8
                         ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l8
                       );
          lv_errbuf := lv_errmsg;
          RAISE chk_mst_is_exists_skip_expt;
      END;
--
      BEGIN
      -- 3)���Y�c�ƈ��̌��ݏ����`�F�b�N�Ɠ��Y����v��f�[�^���݃`�F�b�N
        -- �@���Y�c�ƈ������ݓ��Y���_�ɏ������Ă��邩�`�F�b�N
        SELECT
        CASE
          WHEN   issue_date > gv_now_date                     -- ���ߓ��Ɣ�r
          THEN   xrrv.work_base_code_old                      -- �Ζ��n���_�R�[�h(��)
          ELSE   xrrv.work_base_code_new                      -- �Ζ��n���_�R�[�h(�V)
          END
        INTO   lv_base_code
        FROM   xxcso_resource_relations_v2  xrrv           -- ���\�[�X�}�X�^�֘A(�ŐV)�r���[
        WHERE  xrrv.employee_number = g_sls_pln_data_tab(i).emply_nmbr;        
--
        IF (lv_base_code = g_sls_pln_data_tab(i).base_code) THEN
        -- ���_�R�[�h����v����Ήc�ƈ��L���t���O�ɗL���l���Z�b�g
          g_sls_pln_data_tab(i).sls_prsn_ffctv_flg := cn_effective_val;
        END IF;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  -- ���݂��Ȃ��ꍇ�́A�����������̏����֐i��
          NULL;
--
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_07                      -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_rsrc_and_grp_table_nm             -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_err_msg                        -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                               -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h7
                         ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h8
                         ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l8
                       );
          lv_errbuf := lv_errmsg;
          RAISE chk_mst_is_exists_skip_expt;
      END;
--
      BEGIN
        IF ( g_sls_pln_data_tab(i).sls_prsn_ffctv_flg = cn_ineffective_val ) THEN
          -- �A���Y����v��f�[�^�����Y�N�x���̉c�ƈ��ʌ��ʌv��e�[�u���ɑ��݂��Ă��邩�`�F�b�N
          SELECT COUNT(xspmp.sls_prsn_mnthly_pln_id) sls_prsn_mnthly_pln_id_num  -- �c�ƈ��ʌ��ʌv��ID�J�E���g��
          INTO  ln_sls_prsn_mnthly_pln_num             -- �c�ƈ��ʌ��ʌv���v����
          FROM  xxcso_sls_prsn_mnthly_plns xspmp       -- �c�ƈ��ʌ��ʌv��e�[�u��
          WHERE xspmp.base_code = g_sls_pln_data_tab(i).base_code 
          AND   xspmp.employee_number = g_sls_pln_data_tab(i).emply_nmbr
          AND   xspmp.fiscal_year = g_sls_pln_data_tab(i).fiscal_year;
        END IF;
--
        IF (ln_sls_prsn_mnthly_pln_num = 0) THEN
        -- 0���̏ꍇ�̓G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_29                      -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h1
                         ,iv_token_value1 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h2
                         ,iv_token_value2 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l6
                       );
          lv_errbuf := lv_errmsg;
          RAISE count_num_zero_skip_expt;
        END IF;
--
      EXCEPTION
        WHEN count_num_zero_skip_expt THEN
        RAISE chk_mst_is_exists_skip_expt;
--
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_07                      -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_err_msg                        -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                               -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h7
                         ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h8
                         ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l8
                       );
          lv_errbuf := lv_errmsg;
          RAISE chk_mst_is_exists_skip_expt;
      END;
--
      BEGIN
        -- 4)���Y�f�[�^���c�ƈ��ʌ��ʌv��e�[�u���ɑ��݂��邩���`�F�b�N
        SELECT COUNT(xspmp.sls_prsn_mnthly_pln_id) sls_prsn_mnthly_pln_id_num  -- �c�ƈ��ʌ��ʌv��ID�J�E���g��
        INTO   ln_sls_prsn_mnthly_pln_num             -- �c�ƈ��ʌ��ʌv���v����
        FROM   xxcso_sls_prsn_mnthly_plns xspmp       -- �c�ƈ��ʌ��ʌv��e�[�u��
        WHERE  xspmp.base_code       = g_sls_pln_data_tab(i).base_code
        AND    xspmp.employee_number = g_sls_pln_data_tab(i).emply_nmbr
        AND    xspmp.year_month      = g_sls_pln_data_tab(i).year_month;
--
        -- 1���ȏ�擾�ł���΁ADB�f�[�^�L���t���O�ɗL���l���Z�b�g
        IF (ln_sls_prsn_mnthly_pln_num >= 1) THEN
          g_sls_pln_data_tab(i).db_dt_xst_flg := cn_effective_val;
        END IF;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_07                      -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm              -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_err_msg                        -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                               -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h7
                         ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h8
                         ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l8
                       );
          lv_errbuf := lv_errmsg;
          RAISE chk_mst_is_exists_skip_expt;
      END;
--
      IF (g_sls_pln_data_tab(i).sls_prsn_ffctv_flg = cn_effective_val) THEN
        -- 5)�c�ƈ��L���t���O=1:�L���l�̏ꍇ�K�{����NULL�`�F�b�N
        IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
          -- �@���͋敪���u1:���[�g�v�̏ꍇ
          IF (TO_CHAR(gd_now_date,cv_year_month_fmt) <= g_sls_pln_data_tab(i).year_month) THEN
            IF (g_sls_pln_data_tab(i).year_month <= TO_CHAR((ADD_MONTHS(gd_now_date,2)),cv_year_month_fmt)) THEN
              -- ���Y�N��=���ݓ��t�̔N���`+2�����̏ꍇ
              IF (g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt IS NULL) THEN     -- ��{����(�c�ƈ��v:�v)
                lv_item_nm := cv_bsc_sls_prsn_ttl_mt_nm;
                lb_null_flag := FALSE;
              ELSIF (g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt IS NULL) THEN  -- �ڕW����(�c�ƈ��v:�v)
                lv_item_nm := cv_tgt_sls_prsn_ttl_mt_nm;
                lb_null_flag := FALSE;
              ELSIF (g_sls_pln_data_tab(i).vis_prsn_ttl_mt IS NULL) THEN      -- �K��(�c�ƈ��v:�v)
                lv_item_nm := cv_vis_prsn_ttl_mt_nm;
                lb_null_flag := FALSE;
              END IF;
            END IF;
          END IF;
--
        ELSIF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
        -- �@���͋敪���u2:�{���v�̏ꍇ
          IF ((TO_CHAR(gd_now_date,cv_year_month_fmt) = g_sls_pln_data_tab(i).year_month) 
            OR (g_sls_pln_data_tab(i).year_month = TO_CHAR((ADD_MONTHS(gd_now_date,1)),cv_year_month_fmt)))
          THEN
            -- ���Y�N��=���ݓ��t�̔N���`+1�����̏ꍇ
            IF (g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt IS NULL) THEN   -- ��{����(�c�ƈ��v:�v)
              lv_item_nm := cv_bsc_sls_prsn_ttl_mt_nm;
              lb_null_flag := FALSE;
            ELSIF (g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt IS NULL) THEN     -- �ڕW����(�c�ƈ��v:�v)
              lv_item_nm := cv_tgt_sls_prsn_ttl_mt_nm;
              lb_null_flag := FALSE;
            END IF;
          END IF;
        END IF;
      END IF;
--
      IF (lb_null_flag = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_19                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                           -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_item_nm                            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h7
                       ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l7
                     );
        lv_errbuf := lv_errmsg;
        RAISE chk_mst_is_exists_skip_expt;
      END IF;
--
--
      BEGIN
--
        IF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_effective_val) THEN
          IF (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_ineffective_val) THEN
            IF ((g_sls_pln_data_tab(i).year_month = TO_CHAR(gd_now_date,cv_year_month_fmt))
              AND (ld_standard_work_day < gd_now_date))
            THEN
--
            -- 6)DB���݃t���O=1:�L���l,���͍���NULL�t���O=0:�����l,���Y�N��=�����`����+2����,��5�c�Ɠ�<���ݓ��t�̏ꍇ�A
            --   ��{�v��l���ύX����Ă��Ȃ����`�F�b�N
              SELECT  xspmp.bsc_sls_vd_new_serv_amt      bsc_sls_vd_new_serv_amt      -- ��{����(VD:�V�K�v��)
                     ,xspmp.bsc_sls_vd_next_serv_amt     bsc_sls_vd_next_serv_amt     -- ��{����(VD:���N�v��)
                     ,xspmp.bsc_sls_vd_exist_serv_amt    bsc_sls_vd_exist_serv_amt    -- ��{����(VD:��������)
                     ,xspmp.bsc_sls_vd_total_amt         bsc_sls_vd_total_amt         -- ��{����(VD:�v)
                     ,xspmp.bsc_sls_new_serv_amt         bsc_sls_new_serv_amt         -- ��{����(VD�ȊO:�V�K�v��)
                     ,xspmp.bsc_sls_next_serv_amt        bsc_sls_next_serv_amt        -- ��{����(VD�ȊO:���N�v��)
                     ,xspmp.bsc_sls_exist_serv_amt       bsc_sls_exist_serv_amt       -- ��{����(VD�ȊO:��������)
                     ,xspmp.bsc_sls_total_amt            bsc_sls_total_amt            -- ��{����(VD�ȊO:�v)
                     ,xspmp.bsc_sls_prsn_new_serv_amt    bsc_sls_prsn_new_serv_amt    -- ��{����(�c�ƈ��v:�V�K�v��)
                     ,xspmp.bsc_sls_prsn_next_serv_amt   bsc_sls_prsn_next_serv_amt   -- ��{����(�c�ƈ��v:���N�v��)
                     ,xspmp.bsc_sls_prsn_exist_serv_amt  bsc_sls_prsn_exist_serv_amt  -- ��{����(�c�ƈ��v:��������)
                     ,xspmp.bsc_sls_prsn_total_amt       bsc_sls_prsn_total_amt       -- ��{����(�c�ƈ��v:�v)
              INTO    ln_bsc_sls_vd_new_serv_amt         -- ��{����(VD:�V�K�v��)
                     ,ln_bsc_sls_vd_next_serv_amt        -- ��{����(VD:���N�v��)
                     ,ln_bsc_sls_vd_exist_serv_amt       -- ��{����(VD:��������)
                     ,ln_bsc_sls_vd_total_amt            -- ��{����(VD:�v)
                     ,ln_bsc_sls_new_serv_amt            -- ��{����(VD�ȊO:�V�K�v��)
                     ,ln_bsc_sls_next_serv_amt           -- ��{����(VD�ȊO:���N�v��)
                     ,ln_bsc_sls_exist_serv_amt          -- ��{����(VD�ȊO:��������)
                     ,ln_bsc_sls_total_amt               -- ��{����(VD�ȊO:�v)
                     ,ln_bsc_sls_prsn_new_serv_amt       -- ��{����(�c�ƈ��v:�V�K�v��)
                     ,ln_bsc_sls_prsn_next_serv_amt      -- ��{����(�c�ƈ��v:���N�v��)
                     ,ln_bsc_sls_prsn_exist_serv_amt     -- ��{����(�c�ƈ��v:��������)
                     ,ln_bsc_sls_prsn_total_amt          -- ��{����(�c�ƈ��v:�v)
              FROM   xxcso_sls_prsn_mnthly_plns xspmp    -- �c�ƈ��ʌ��ʌv��e�[�u��
              WHERE  xspmp.base_code = g_sls_pln_data_tab(i).base_code 
              AND    xspmp.employee_number = g_sls_pln_data_tab(i).emply_nmbr
              AND    xspmp.year_month = g_sls_pln_data_tab(i).year_month;
--              
              IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
              -- �@���͋敪���u1�v�̏ꍇ�̃`�F�b�N
                IF (g_sls_pln_data_tab(i).bsc_sls_vd_nw_srv_mt                -- ��{����(VD:�V�K�v��)
                  <> ln_bsc_sls_vd_new_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_vd_nxt_srv_mt            -- ��{����(VD:���N�v��)
                  <> ln_bsc_sls_vd_next_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_vd_xst_srv_mt            -- ��{����(VD:��������)
                  <> ln_bsc_sls_vd_exist_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_vd_ttl_mt                -- ��{����(VD:�v)
                  <> ln_bsc_sls_vd_total_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_nw_srv_mt                -- ��{����(VD�ȊO:�V�K�v��)
                  <> ln_bsc_sls_new_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_nxt_srv_mt               -- ��{����(VD�ȊO:���N�v��)
                  <> ln_bsc_sls_next_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_nw_srv_mt                -- ��{����(VD�ȊO:�V�K�v��)
                  <> ln_bsc_sls_new_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_xst_srv_mt               -- ��{����(VD�ȊO:��������)
                  <> ln_bsc_sls_exist_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_ttl_mt                   -- ��{����(VD�ȊO:�v)
                  <> ln_bsc_sls_total_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_prsn_nw_srv_mt           -- ��{����(�c�ƈ��v:�V�K�v��)
                  <> ln_bsc_sls_prsn_new_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_prsn_nxt_srv_mt          -- ��{����(�c�ƈ��v:���N�v��)
                  <> ln_bsc_sls_prsn_next_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_prsn_xst_srv_mt          -- ��{����(�c�ƈ��v:��������)
                  <> ln_bsc_sls_prsn_exist_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt              -- ��{����(�c�ƈ��v:�v)
                  <> ln_bsc_sls_prsn_total_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                END IF;
              ELSIF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
              -- �A���͋敪���u2�v�̏ꍇ�̃`�F�b�N
                IF (g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt <> ln_bsc_sls_prsn_total_amt) THEN  -- ��{����(�c�ƈ��v:�v)
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_07                      -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_err_msg                        -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                               -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h7
                         ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h8
                         ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l8
                       );
          lv_errbuf := lv_errmsg;
          RAISE chk_mst_is_exists_skip_expt;
      END;
--
      IF ((g_sls_pln_data_tab(i).sls_prsn_ffctv_flg = cn_ineffective_val)
        AND (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_ineffective_val)
        AND (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_ineffective_val)
        AND (g_sls_pln_data_tab(i).year_month >= TO_CHAR(gd_now_date,cv_year_month_fmt)))
      THEN
      -- 7)�c�ƈ��L���t���O=0:�����l,NULL�t���O=0:�����l,DB�f�[�^���݃t���O=0:�����l,���Y�N��=�����ȍ~�̏ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_11                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h1
                       ,iv_token_value1 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l6
                     );
        lv_errbuf := lv_errmsg;
        RAISE chk_mst_is_exists_skip_expt;
      END IF;
--
      IF ((g_sls_pln_data_tab(i).sls_prsn_ffctv_flg = cn_ineffective_val)
        AND (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_effective_val)
        AND (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_effective_val)
        AND (g_sls_pln_data_tab(i).year_month = TO_CHAR(gd_now_date,cv_year_month_fmt))
        AND (ld_standard_work_day < gd_now_date))
      THEN
      -- 8)�c�ƈ��L���t���O=0:�����l,���͍���NULL�t���O=1:�L���l,DB���݃t���O=0,���Y�N��=��������5�c�Ɠ�<���ݓ��t�̏ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_12                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h1
                       ,iv_token_value1 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l6
                     );
        lv_errbuf := lv_errmsg;
        RAISE chk_mst_is_exists_skip_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** �}�X�^���݃`�F�b�N�������X�L�b�v��O�n���h�� ***
    WHEN chk_mst_is_exists_skip_expt THEN
      gn_dt_chck_err_cnt := gn_dt_chck_err_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
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
  END chk_mst_is_exists;
----
  /**********************************************************************************
   * Procedure Name   : get_dept_month_data
   * Description      : ���_�ʌ��ʌv��f�[�^���o (A-6)
   ***********************************************************************************/
--
  PROCEDURE get_dept_month_data(
     on_dpt_mnth_pln_cnt  OUT NOCOPY NUMBER    -- ���o����
    ,ov_errbuf            OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100)   := 'get_dept_month_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf             VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode            VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg             VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    ---- *** ���[�J���萔 ***
      -- �G���[���b�Z�[�W�p�萔
    cv_dpt_mnth_plns_nm     CONSTANT VARCHAR2(100)   := '���_�ʌ��ʌv��e�[�u��';
      -- *** ���[�J���ϐ� ***
      -- �f�[�^���o�����J�E���g�p�ϐ�
    ln_dept_monthly_plan_id_cnt     NUMBER;     -- ���_�ʌ��ʌv��ID�i�[�p
      -- �T�u���C�����[�v�J�E���^�i�[�p
    i                               NUMBER;     -- A-6���g�p�z��Y����
      --�f�[�^���b�N���g�p
    lt_dpt_monthly_plan_id  xxcso_dept_monthly_plans.dept_monthly_plan_id%TYPE;
--
    -- *** ���[�J����O ***
    get_dept_month_data_error_expt  EXCEPTION;  -- ���_�ʌ��ʌv��f�[�^���o�������G���[��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    i := g_rec_count;  -- A-6���g�p�z��Y�����ɃT�u���C���`�F�b�N�p���[�v�J�E���^���i�[
--
    BEGIN
      SELECT xdmp.dept_monthly_plan_id dept_monthly_plan_id  -- ���_�ʌ��ʌv��e�[�u��ID���J�E���g
      INTO   ln_dept_monthly_plan_id_cnt
      FROM   xxcso_dept_monthly_plans xdmp                          -- ���_�ʌ��ʌv��e�[�u��
      WHERE  xdmp.base_code   = g_sls_pln_data_tab(i).base_code
      AND    xdmp.year_month  = g_sls_pln_data_tab(i).year_month
      AND    xdmp.fiscal_year = g_sls_pln_data_tab(i).fiscal_year
      FOR UPDATE NOWAIT;
--
      on_dpt_mnth_pln_cnt := 1;
--
    EXCEPTION
          -- ���b�N���s�����ꍇ�̗�O
      WHEN NO_DATA_FOUND THEN
        on_dpt_mnth_pln_cnt := 0;
      
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_dpt_mnth_plns_nm                   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l5
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE get_dept_month_data_error_expt;
--
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_dpt_mnth_plns_nm                   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_err_msg                        -- �g�[�N���R�[�h6
                       ,iv_token_value6 => SQLERRM                               -- �g�[�N���l6
                     );
        lv_errbuf := lv_errmsg;
        RAISE get_dept_month_data_error_expt;
--
    END;
--
  EXCEPTION
    -- *** ������O�n���h�� ***
    WHEN get_dept_month_data_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
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
  END get_dept_month_data;
----
  /**********************************************************************************
   * Procedure Name   : inup_dept_month_data
   * Description      : ���_�ʌ��ʌv��f�[�^�o�^�E�X�V (A-7)
   ***********************************************************************************/
--
  PROCEDURE inup_dept_month_data(
     in_dpt_mnth_pln_cnt  IN  VARCHAR2                    -- ���o����
    ,ov_errbuf            OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'inup_dept_month_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf                  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    ---- *** ���[�J���萔 ***
    cn_sls_pln_rl_dv           CONSTANT NUMBER         := 1;  -- ����J���敪�f�t�H���g�l
    cv_dpt_mnth_plns_nm        CONSTANT VARCHAR2(100)  := '���_�ʌ��ʌv��e�[�u��';
    ---- *** ���[�J���ϐ� ***
    -- �T�u���C�����[�v�J�E���^�i�[�p
    i                          NUMBER;      -- A-7���g�p�z��Y����
    ln_dpt_mnth_pln_cnt        NUMBER;      -- ���o����
    ---- *** ���[�J����O ***
    inup_dpt_mnth_dt_err_expt  EXCEPTION;   -- ���_�ʌ��ʌv��f�[�^�o�^�E�X�V�������G���[��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    i := g_rec_count;  -- A-7���g�p�z��Y�����ɃT�u���C���`�F�b�N�p���[�v�J�E���^���i�[
--
    -- ���o�������擾
    ln_dpt_mnth_pln_cnt := in_dpt_mnth_pln_cnt;
--
    -- ==========================
    -- ���_�ʌ��ʌv��f�[�^�o�^
    -- ==========================
    BEGIN
      IF (ln_dpt_mnth_pln_cnt = 0) THEN       -- 1)A-6�f�[�^���o����0�̏ꍇ�A�o�^����
        IF(g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN  -- ���͋敪:1[���[�g]�̏ꍇ
          INSERT INTO xxcso_dept_monthly_plans  -- ���_�ʌ��ʌv��e�[�u��
            ( dept_monthly_plan_id      -- ���_�ʌ��ʌv��ID
             ,base_code                 -- ���_CD
             ,year_month                -- �N��
             ,fiscal_year               -- �N�x
             ,input_div                 -- ���͋敪
             ,basic_new_service_amt     -- ��{�V�K�v��
             ,basic_next_service_amt    -- ��{���N�v��
             ,basic_exist_service_amt   -- ��{��������
             ,basic_discount_amt        -- ��{�l��
             ,basic_sales_total_amt     -- ��{���v����(��{�m���})
             ,visit                     -- �K��
             ,target_new_service_amt    -- �ڕW�V�K�v��
             ,target_next_service_amt   -- �ڕW���N�v��
             ,target_exist_service_amt  -- �ڕW��������
             ,target_discount_amt       -- �ڕW�l��
             ,target_sales_total_amt    -- �ڕW���v����
             ,sales_plan_rel_div        -- ����v��J���敪
             ,created_by                -- �쐬��
             ,creation_date             -- �쐬��
             ,last_updated_by           -- �ŏI�X�V��
             ,last_update_date          -- �ŏI�X�V��
             ,last_update_login         -- �ŏI�X�V���O�C��
             ,request_id                -- �v��ID
             ,program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,program_id                -- �R���J�����g�E�v���O����ID
             ,program_update_date       -- �v���O�����X�V��
             )
          VALUES
            ( xxcso_dept_monthly_plans_s01.NEXTVAL  -- ���_�ʌ��ʌv��ID
             ,g_sls_pln_data_tab(i).base_code        -- ���_CD
             ,g_sls_pln_data_tab(i).year_month       -- �N��
             ,g_sls_pln_data_tab(i).fiscal_year      -- �N�x
             ,g_sls_pln_data_tab(i).input_division   -- ���͋敪
             ,g_sls_pln_data_tab(i).bsc_nw_srvc_mt   -- ��{�V�K�v��
             ,g_sls_pln_data_tab(i).bsc_nxt_srvc_mt  -- ��{���N�v��
             ,g_sls_pln_data_tab(i).bsc_xst_srvc_mt  -- ��{��������
             ,g_sls_pln_data_tab(i).bsc_dscnt_mt     -- ��{�l��
             ,g_sls_pln_data_tab(i).bsc_sls_ttl_mt_nlm   -- ��{���v����(��{�m���})
             ,g_sls_pln_data_tab(i).visit            -- �K��
             ,g_sls_pln_data_tab(i).trgt_nw_srvc_mt  -- �ڕW�V�K�v��
             ,g_sls_pln_data_tab(i).trgt_nxt_srvc_mt -- �ڕW���N�v��
             ,g_sls_pln_data_tab(i).trgt_xst_srvc_mt -- �ڕW��������
             ,g_sls_pln_data_tab(i).trgt_dscnt_mt    -- �ڕW�l��
             ,g_sls_pln_data_tab(i).trgt_sls_ttl_mt  -- �ڕW���v����
             ,cn_sls_pln_rl_dv                       -- ����v��J���敪
             ,cn_created_by                          -- �쐬��
             ,cd_creation_date                       -- �쐬��
             ,cn_last_updated_by                     -- �ŏI�X�V��
             ,cd_last_update_date                    -- �ŏI�X�V��
             ,cn_last_update_login                   -- �ŏI�X�V���O�C��
             ,cn_request_id                          -- �v��ID
             ,cn_program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,cn_program_id                          -- �R���J�����g�E�v���O����ID
             ,cd_program_update_date                 -- �v���O�����X�V��
            );
--
        ELSIF(g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN  -- ���͋敪:2[�{��]�̏ꍇ
          INSERT INTO xxcso_dept_monthly_plans  -- ���_�ʌ��ʌv��e�[�u��
            ( dept_monthly_plan_id      -- ���_�ʌ��ʌv��ID
             ,base_code                 -- ���_CD
             ,year_month                -- �N��
             ,fiscal_year               -- �N�x
             ,input_div                 -- ���͋敪
             ,basic_new_service_amt     -- ��{�V�K�v��
             ,basic_next_service_amt    -- ��{���N�v��
             ,basic_exist_service_amt   -- ��{��������
             ,basic_discount_amt        -- ��{�l��
             ,basic_sales_total_amt     -- ��{���v����(��{�m���})
             ,visit                     -- �K��
             ,target_new_service_amt    -- �ڕW�V�K�v��
             ,target_next_service_amt   -- �ڕW���N�v��
             ,target_exist_service_amt  -- �ڕW��������
             ,target_discount_amt       -- �ڕW�l��
             ,target_sales_total_amt    -- �ڕW���v����
             ,sales_plan_rel_div        -- ����v��J���敪
             ,created_by                -- �쐬��
             ,creation_date             -- �쐬��
             ,last_updated_by           -- �ŏI�X�V��
             ,last_update_date          -- �ŏI�X�V��
             ,last_update_login         -- �ŏI�X�V���O�C��
             ,request_id                -- �v��ID
             ,program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,program_id                -- �R���J�����g�E�v���O����ID
             ,program_update_date       -- �v���O�����X�V��
             )
          VALUES
            ( xxcso_dept_monthly_plans_s01.NEXTVAL  -- ���_�ʌ��ʌv��ID
             ,g_sls_pln_data_tab(i).base_code        -- ���_CD
             ,g_sls_pln_data_tab(i).year_month       -- �N��
             ,g_sls_pln_data_tab(i).fiscal_year      -- �N�x
             ,g_sls_pln_data_tab(i).input_division   -- ���͋敪
             ,NULL                                   -- ��{�V�K�v��
             ,NULL                                   -- ��{���N�v��
             ,NULL                                   -- ��{��������
             ,NULL                                   -- ��{�l��
             ,g_sls_pln_data_tab(i).bsc_sls_ttl_mt_nlm   -- ��{���v����(��{�m���})
             ,NULL                                   -- �K��
             ,NULL                                   -- �ڕW�V�K�v��
             ,NULL                                   -- �ڕW���N�v��
             ,NULL                                   -- �ڕW��������
             ,g_sls_pln_data_tab(i).trgt_dscnt_mt    -- �ڕW�l��
             ,g_sls_pln_data_tab(i).trgt_sls_ttl_mt  -- �ڕW���v����
             ,cn_sls_pln_rl_dv                       -- ����v��J���敪
             ,cn_created_by                          -- �쐬��
             ,cd_creation_date                       -- �쐬��
             ,cn_last_updated_by                     -- �ŏI�X�V��
             ,cd_last_update_date                    -- �ŏI�X�V��
             ,cn_last_update_login                   -- �ŏI�X�V���O�C��
             ,cn_request_id                          -- �v��ID
             ,cn_program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,cn_program_id                          -- �R���J�����g�E�v���O����ID
             ,cd_program_update_date                 -- �v���O�����X�V��
            );
        END IF;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_13                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_dpt_mnth_plns_nm                   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_err_msg                        -- �g�[�N���R�[�h6
                       ,iv_token_value6 => SQLERRM                               -- �g�[�N���l6
                     );
        lv_errbuf := lv_errmsg;
        RAISE inup_dpt_mnth_dt_err_expt;
    END;
--
    -- ==========================
    -- ���_�ʌ��ʌv��f�[�^�X�V 
    -- ==========================
    BEGIN
      IF (ln_dpt_mnth_pln_cnt = 1) THEN     -- 2)A-6�f�[�^���o����1�ȏ�̏ꍇ�A�X�V����
        IF(g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN  -- ���͋敪:1[���[�g]�̏ꍇ
          UPDATE xxcso_dept_monthly_plans xdmp -- ���_�ʌ��ʌv��e�[�u��
          SET
             base_code                =  g_sls_pln_data_tab(i).base_code         -- ���_CD
            ,year_month               =  g_sls_pln_data_tab(i).year_month        -- �N��
            ,fiscal_year              =  g_sls_pln_data_tab(i).fiscal_year       -- �N�x
            ,input_div                =  g_sls_pln_data_tab(i).input_division    -- ���͋敪
            ,basic_new_service_amt    =  g_sls_pln_data_tab(i).bsc_nw_srvc_mt    -- ��{�V�K�v��
            ,basic_next_service_amt   =  g_sls_pln_data_tab(i).bsc_nxt_srvc_mt   -- ��{���N�v��
            ,basic_exist_service_amt  =  g_sls_pln_data_tab(i).bsc_xst_srvc_mt   -- ��{��������
            ,basic_discount_amt       =  g_sls_pln_data_tab(i).bsc_dscnt_mt      -- ��{�l��            
            ,basic_sales_total_amt    =  g_sls_pln_data_tab(i).bsc_sls_ttl_mt_nlm  -- ��{���v����(��{�m���})
            ,visit                    =  g_sls_pln_data_tab(i).visit             -- �K��
            ,target_new_service_amt   =  g_sls_pln_data_tab(i).trgt_nw_srvc_mt   -- �ڕW�V�K�v��
            ,target_next_service_amt  =  g_sls_pln_data_tab(i).trgt_nxt_srvc_mt  -- �ڕW���N�v��
            ,target_exist_service_amt =  g_sls_pln_data_tab(i).trgt_xst_srvc_mt  -- �ڕW��������
            ,target_discount_amt      =  g_sls_pln_data_tab(i).trgt_dscnt_mt     -- �ڕW�l��
            ,target_sales_total_amt   =  g_sls_pln_data_tab(i).trgt_sls_ttl_mt   -- �ڕW���v����
            ,last_updated_by          =  cn_last_updated_by                      -- �ŏI�X�V��
            ,last_update_date         =  cd_last_update_date                     -- �ŏI�X�V��
            ,last_update_login        =  cn_last_update_login                    -- �ŏI�X�V���O�C��
            ,request_id               =  cn_request_id                           -- �v��ID
            ,program_application_id   =  cn_program_application_id               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id               =  cn_program_id                           -- �R���J�����g�E�v���O����ID
            ,program_update_date      =  cd_program_update_date                  -- �v���O�����X�V��
          WHERE  xdmp.base_code   = g_sls_pln_data_tab(i).base_code
          AND    xdmp.year_month  = g_sls_pln_data_tab(i).year_month
          AND    xdmp.fiscal_year = g_sls_pln_data_tab(i).fiscal_year;
--
        ELSIF(g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN  -- ���͋敪:2[�{��]�̏ꍇ
          UPDATE xxcso_dept_monthly_plans xdmp -- ���_�ʌ��ʌv��e�[�u��
          SET
             base_code               =  g_sls_pln_data_tab(i).base_code        -- ���_CD
            ,year_month              =  g_sls_pln_data_tab(i).year_month       -- �N��
            ,fiscal_year             =  g_sls_pln_data_tab(i).fiscal_year      -- �N�x
            ,input_div               =  g_sls_pln_data_tab(i).input_division   -- ���͋敪
            ,basic_sales_total_amt   =  g_sls_pln_data_tab(i).bsc_sls_ttl_mt_nlm   -- ��{���v����(��{�m���})
            ,target_discount_amt     =  g_sls_pln_data_tab(i).trgt_dscnt_mt    -- �ڕW�l��
            ,target_sales_total_amt  =  g_sls_pln_data_tab(i).trgt_sls_ttl_mt  -- �ڕW���v����
            ,last_updated_by         =  cn_last_updated_by                     -- �ŏI�X�V��
            ,last_update_date        =  cd_last_update_date                    -- �ŏI�X�V��
            ,last_update_login       =  cn_last_update_login                   -- �ŏI�X�V���O�C��
            ,request_id              =  cn_request_id                          -- �v��ID
            ,program_application_id  =  cn_program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id              =  cn_program_id                          -- �R���J�����g�E�v���O����ID
            ,program_update_date     =  cd_program_update_date                 -- �v���O�����X�V��
          WHERE  xdmp.base_code   = g_sls_pln_data_tab(i).base_code
          AND    xdmp.year_month  = g_sls_pln_data_tab(i).year_month
          AND    xdmp.fiscal_year = g_sls_pln_data_tab(i).fiscal_year;
        END IF;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_14                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_dpt_mnth_plns_nm                   -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_err_msg                        -- �g�[�N���R�[�h6
                       ,iv_token_value6 => SQLERRM                               -- �g�[�N���l6
                     );
        lv_errbuf := lv_errmsg;
        RAISE inup_dpt_mnth_dt_err_expt;
    END;
--
  EXCEPTION
    -- *** ������O�n���h�� ***
    WHEN inup_dpt_mnth_dt_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
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
  END inup_dept_month_data;
--
  /**********************************************************************************
   * Procedure Name   : inupdl_prsn_month_data
   * Description      : �c�ƈ��ʌ��ʌv��f�[�^�o�^�E�X�V�E�폜 (A-8)
   ***********************************************************************************/
--
  PROCEDURE inupdl_prsn_month_data(
     iv_base_value        IN  VARCHAR2                    -- ���Y�s�f�[�^
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
    ,in_sls_pln_upld_cls_dy IN  NUMBER                  -- ����v��A�b�v���[�h���c�Ɠ�
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
    ,ov_errbuf            OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'inupdl_prsn_month_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    ---- *** ���[�J���萔 ***
    cv_year_month_fmt              CONSTANT VARCHAR2(100) := 'YYYYMM';  -- �N�����e��DATE�^
    cv_sls_prsn_mnthly_plns_nm     CONSTANT VARCHAR2(100) := '�c�ƈ��ʌ��ʌv��e�[�u��';
    cn_stndrd_wrkng_dy             CONSTANT NUMBER        := 5;         -- �o�^�E�X�V�E�폜����c�Ɠ�
--
    ---- *** ���[�J���ϐ� ***
    -- �T�u���C�����[�v�J�E���^�i�[�p
    i                              NUMBER;            -- A-8���g�p�z��Y����
    -- �N����r���ԕʃt���O
    lb_old                         BOOLEAN := FALSE;   --  �ߋ����ʃt���O
    lb_nw_month                    BOOLEAN := FALSE;   --  �������ʃt���O
    lb_necessary                   BOOLEAN := FALSE;   --  �K�{���Ԕ��ʃt���O
    lb_after                       BOOLEAN := FALSE;   --  �K�{���Ԉȍ~���ʃt���O
    -- ��5�c�Ɠ�����t���O
    lb_after_standard_day          BOOLEAN := FALSE;   --  ���ݑ�5�c�Ɠ��߂����ʃt���O
    lb_befor_standard_day          BOOLEAN := FALSE;   --  ���ݑ�5�c�Ɠ��܂Ŕ��ʃt���O
    -- �������򔻕ʃt���O
    lb_all_ignore_skip             BOOLEAN := FALSE;   --  �yA-8-1�z���S�����X�L�b�v�ɐi�ރt���O
    lb_skip                        BOOLEAN := FALSE;   --  �yA-8-2�z�X�L�b�v�ɐi�ރt���O
    lb_insert                      BOOLEAN := FALSE;   --  �yA-8-3�z�V�K�o�^�ɐi�ރt���O    
    lb_all_update                  BOOLEAN := FALSE;   --  �yA-8-4-1�z�S���ڍX�V�ɐi�ރt���O
    lb_bsc_sls_nt_update           BOOLEAN := FALSE;   --  �yA-8-4-2�z��{����̂ݍX�V���Ȃ��X�V�ɐi�ރt���O
    lb_part_update                 BOOLEAN := FALSE;   --  �yA-8-4-3�z��{����E�ڕW����E�K��f�[�^�͍X�V���Ȃ������X�V�ɐi�ރt���O
    lb_delete                      BOOLEAN := FALSE;   --  �yA-8-5�z�폜�ɐi�ރt���O
--
    lr_row_id                      ROWID;             -- ���b�N�p�擾ID
    ld_standard_work_day           DATE;              -- ���(��5�c�Ɠ�)�i�[�p�ϐ�
--
    ---- *** ���[�J����O ***
    all_ignore_skip_error_expt     EXCEPTION;         -- ���S�����X�L�b�v��O
    part_update_hnb_skip_expt      EXCEPTION;         -- ��{����E�ڕW����E�K��f�[�^�X�V���Ȃ������X�V[�{���X�L�b�v]��O
    inupdl_prsn_mnth_dt_err_expt   EXCEPTION;         -- �c�ƈ��ʌ��ʌv��f�[�^�o�^�E�X�V�E�폜�������G���[��O
    inupdl_prsn_mnth_dt_skp_expt   EXCEPTION;         -- �c�ƈ��ʌ��ʌv��f�[�^�o�^�E�X�V�E�폜�������X�L�b�v��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    i := g_rec_count;  -- A-8���g�p�z��Y�����ɃT�u���C���`�F�b�N�p���[�v�J�E���^���i�[
--
    -- ==================
    --  �K�{���ԃ`�F�b�N
    -- ==================
--
    IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
      -- ���͋敪:1:���[�g�̏ꍇ
      IF (g_sls_pln_data_tab(i).year_month < TO_CHAR(gd_now_date,cv_year_month_fmt)) THEN
        lb_old := TRUE;        -- �ߋ�
      ELSIF (g_sls_pln_data_tab(i).year_month = TO_CHAR(gd_now_date,cv_year_month_fmt)) THEN
        lb_nw_month := TRUE;  -- ����
      ELSIF (g_sls_pln_data_tab(i).year_month <= 
      TO_CHAR((ADD_MONTHS(gd_now_date,2)),cv_year_month_fmt)) THEN
        lb_necessary := TRUE;  -- �K�{����
      ELSIF (g_sls_pln_data_tab(i).year_month 
      >= TO_CHAR((ADD_MONTHS(gd_now_date,3)),cv_year_month_fmt)) THEN
        lb_after := TRUE;      -- �K�{���Ԉȍ~
      END IF;
    ELSIF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
      -- ���͋敪:2:�{���̏ꍇ
      IF (g_sls_pln_data_tab(i).year_month < TO_CHAR(gd_now_date,cv_year_month_fmt)) THEN
        lb_old := TRUE;        -- �ߋ�
      ELSIF (g_sls_pln_data_tab(i).year_month = TO_CHAR(gd_now_date,cv_year_month_fmt)) THEN
        lb_nw_month := TRUE;  -- ����
      ELSIF (g_sls_pln_data_tab(i).year_month 
      <= TO_CHAR((ADD_MONTHS(gd_now_date,1)),cv_year_month_fmt)) THEN
        lb_necessary := TRUE;  -- �K�{����
      ELSIF (g_sls_pln_data_tab(i).year_month 
      >= TO_CHAR((ADD_MONTHS(gd_now_date,2)),cv_year_month_fmt)) THEN
        lb_after := TRUE;      -- �K�{���Ԉȍ~
      END IF;
    END IF;
--
    -- =============
    --  �c�Ɠ�����
    -- =============
--
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
    -- ��5�c�Ɠ��擾
--    ld_standard_work_day := xxccp_common_pkg2.get_working_day((last_day(add_months(gd_now_date,-1))),5);
    ld_standard_work_day := xxccp_common_pkg2.get_working_day((last_day(add_months(gd_now_date,-1))),in_sls_pln_upld_cls_dy);
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
--
    -- ���ݓ��t����5�c�Ɠ����߂��Ă��邩�`�F�b�N
    IF (lb_nw_month = TRUE) THEN
      IF (TRUNC(gd_now_date) > ld_standard_work_day) THEN
        lb_after_standard_day := TRUE;
      ELSIF (TRUNC(gd_now_date) <= ld_standard_work_day) THEN
        lb_befor_standard_day := TRUE;
      END IF;
    END IF;
--
    -- ===============
    --  ��������ݒ�
    -- ===============
--
    
    IF (g_sls_pln_data_tab(i).sls_prsn_ffctv_flg = cn_effective_val) THEN         -- �c�ƈ��L���t���O:1[�L��]
      IF (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_effective_val) THEN       -- NULL�t���O:1[�L��]
        IF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_effective_val) THEN          -- DB�f�[�^���݃t���O:1[�L��]
          IF (lb_old = TRUE) THEN
            -- �N��=�ߋ��yA-8-4-3�z��{����E�ڕW����E�K��f�[�^�͍X�V���Ȃ������X�V
            lb_part_update := TRUE;
          ELSIF (lb_after = TRUE) THEN
            -- �N��=�K�{���Ԉȍ~�yA-8-5�z�폜
            lb_delete := TRUE;
          END IF;
        ELSIF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_ineffective_val) THEN     -- DB�f�[�^���݃t���O:0[����]
          IF ((lb_old = TRUE) OR (lb_after = TRUE)) THEN
            -- �N��=�ߋ��E�K�{���Ԉȍ~�yA-8-1�z���S�����X�L�b�v
            lb_all_ignore_skip := TRUE;
          END IF;
        END IF;
      ELSIF (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_ineffective_val) THEN  -- NULL�t���O:0[����]
        IF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_effective_val) THEN          -- DB�f�[�^���݃t���O:1[�L��]
          IF (lb_old = TRUE) THEN
            -- �N��=�ߋ��yA-8-4-3�z��{����E�ڕW����E�K��f�[�^�͍X�V���Ȃ������X�V
            lb_part_update := TRUE;
          ELSIF (lb_nw_month = TRUE) THEN
            -- �N��=����
            IF (lb_befor_standard_day = TRUE) THEN
            -- ���ݓ��t����5�c�Ɠ����߂��Ă��Ȃ������ꍇ�yA-8-4-1�z�S���ڍX�V
              lb_all_update := TRUE;
            ELSIF (lb_after_standard_day = TRUE) THEN
            -- ���ݓ��t����5�c�Ɠ����߂��Ă����ꍇ�yA-8-4-2�z��{����̂ݍX�V���Ȃ��X�V
              lb_bsc_sls_nt_update := TRUE;
            END IF;
          ELSIF (lb_necessary = TRUE) THEN
            -- �N��=�K�{���ԁyA-8-4-1�z�S���ڍX�V
            lb_all_update := TRUE;
          ELSIF (lb_after = TRUE) THEN
            -- �N��=�K�{���Ԉȍ~�yA-8-4-1�z�S���ڍX�V
            lb_all_update := TRUE;
          END IF;
        ELSIF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_ineffective_val) THEN     -- DB�f�[�^���݃t���O:0[����]
          IF (lb_old = TRUE) THEN
            -- �N��=�ߋ��yA-8-2�z�X�L�b�v
            lb_skip := TRUE;
          ELSIF (lb_nw_month = TRUE) THEN
            -- �N��=�����yA-8-3�z�V�K�o�^
            lb_insert := TRUE;            
          ELSIF ((lb_necessary = TRUE) OR (lb_after = TRUE)) THEN
            -- �N��=�K�{���ԁE�K�{���Ԉȍ~�yA-8-3�z�V�K�o�^
            lb_insert := TRUE;
          END IF;
        END IF;
      END IF;
    ELSIF (g_sls_pln_data_tab(i).sls_prsn_ffctv_flg = cn_ineffective_val) THEN    -- �c�ƈ��L���t���O:0[����]
      IF (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_effective_val) THEN       -- NULL�t���O:1[�L��]
        IF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_effective_val) THEN          -- DB�f�[�^���݃t���O:1[�L��]
          IF (lb_old = TRUE) THEN
            -- �N��=�ߋ��yA-8-4-3�z��{����E�ڕW����E�K��f�[�^�͍X�V���Ȃ������X�V
            lb_part_update := TRUE;
          ELSIF (lb_nw_month = TRUE) THEN
            -- �N��=�����yA-8-5�z�폜
            lb_delete := TRUE;          
          ELSIF ((lb_necessary = TRUE) OR (lb_after = TRUE)) THEN
            -- �N��=�K�{���ԁE�K�{���Ԉȍ~�yA-8-5�z�폜
            lb_delete := TRUE;
          END IF;
        ELSIF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_ineffective_val) THEN     -- DB�f�[�^���݃t���O:0[����]
            -- �yA-8-1�z���S�����X�L�b�v
            lb_all_ignore_skip := TRUE;
        END IF;
      ELSIF (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_ineffective_val) THEN  -- NULL�t���O:0[����]
        IF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_effective_val) THEN          -- DB�f�[�^���݃t���O:1[�L��]
          IF (lb_old = TRUE) THEN
            -- �N��=�ߋ��yA-8-4-3�z��{����E�ڕW����E�K��f�[�^�͍X�V���Ȃ������X�V
            lb_part_update := TRUE;
          ELSIF (lb_nw_month = TRUE) THEN
            -- �N��=����
            IF (lb_befor_standard_day = TRUE) THEN
            -- ���ݓ��t����5�c�Ɠ����߂��Ă��Ȃ������ꍇ�yA-8-4-1�z�S���ڍX�V
              lb_all_update := TRUE;
            ELSIF (lb_after_standard_day = TRUE) THEN
            -- ���ݓ��t����5�c�Ɠ����߂��Ă����ꍇ�yA-8-4-2�z��{����̂ݍX�V���Ȃ��X�V
              lb_bsc_sls_nt_update := TRUE;
            END IF;
          ELSIF (lb_necessary = TRUE) THEN
            -- �N��=�K�{���ԁyA-8-4-1�z�S���ڍX�V
            lb_all_update := TRUE;
          ELSIF (lb_after = TRUE) THEN
            -- �N��=�K�{���Ԉȍ~�yA-8-4-1�z�S���ڍX�V
            lb_all_update := TRUE;
          END IF;
        ELSIF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_ineffective_val) THEN     -- DB�f�[�^���݃t���O:0[����]
          IF (lb_old = TRUE) THEN
            -- �N��=�ߋ��yA-8-2�z�X�L�b�v
            lb_skip := TRUE;
          END IF;
        END IF;
      END IF;    
    END IF;
--
    -- ===================
    --  �������s:�X�L�b�v
    -- ===================
--
    IF (lb_all_ignore_skip = TRUE) THEN
    -- �yA-8-1�z���S�����X�L�b�v
      RAISE all_ignore_skip_error_expt;
--
    ELSIF (lb_skip = TRUE) THEN
    -- �yA-8-2�z�X�L�b�v
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_30                      -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h1
                     ,iv_token_value1 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h2
                     ,iv_token_value2 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h4
                     ,iv_token_value4 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l4
                     ,iv_token_name5  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h5
                     ,iv_token_value5 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l5
                     ,iv_token_name6  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h6
                     ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l6
                   );
      lv_errbuf := lv_errmsg;
      RAISE inupdl_prsn_mnth_dt_skp_expt;
--
    ELSIF (lb_part_update = TRUE) THEN
    -- �yA-8-4-3�z��{����E�ڕW����E�K��f�[�^�͍X�V���Ȃ������X�V[�{���̏ꍇ:���������ɃJ�E���g]
      IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
        RAISE part_update_hnb_skip_expt;
      END IF;
    END IF;
--
    -- =================================================
    -- �������s�F�c�ƈ��ʌ��ʌv��f�[�^�o�^�E�X�V�E�폜 
    -- =================================================
--
    -- �yA-8-3�z�o�^����
    BEGIN
      IF (lb_insert = TRUE) THEN
        IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
          -- ���͋敪1:���[�g�c�Ɨp�̏ꍇ
          INSERT INTO xxcso_sls_prsn_mnthly_plns  -- �c�ƈ��ʌ��ʌv��e�[�u��
            ( sls_prsn_mnthly_pln_id         -- �c�ƈ��ʌ��ʌv��ID
             ,base_code                      -- ���_CD
             ,employee_number                -- �c�ƈ�CD
             ,year_month                     -- �N��
             ,fiscal_year                    -- �N�x
             ,input_type                     -- ���͋敪
             ,group_number                   -- �O���[�v�ԍ�
             ,group_leader_flag              -- �O���[�v���敪
             ,group_grade                    -- �O���[�v������
             ,office_rank_name               -- �E�ʖ�
             ,pri_rslt_vd_new_serv_amt       -- �O�N����(VD:�V�K�v��)
             ,pri_rslt_vd_next_serv_amt      -- �O�N����(VD:���N�v��)
             ,pri_rslt_vd_exist_serv_amt     -- �O�N����(VD:��������)
             ,pri_rslt_vd_total_amt          -- �O�N����(VD:�v)
             ,pri_rslt_new_serv_amt          -- �O�N����(VD�ȊO:�V�K�v��)
             ,pri_rslt_next_serv_amt         -- �O�N����(VD�ȊO:���N�v��)
             ,pri_rslt_exist_serv_amt        -- �O�N����(VD�ȊO:��������)
             ,pri_rslt_total_amt             -- �O�N����(VD�ȊO:�v)
             ,pri_rslt_prsn_new_serv_amt     -- �O�N����(�c�ƈ��v:�V�K�v��)
             ,pri_rslt_prsn_next_serv_amt    -- �O�N����(�c�ƈ��v:���N�v��)
             ,pri_rslt_prsn_exist_serv_amt   -- �O�N����(�c�ƈ��v:��������)
             ,pri_rslt_prsn_total_amt        -- �O�N����(�c�ƈ��v:�v)
             ,bsc_sls_vd_new_serv_amt        -- ��{����(VD:�V�K�v��)
             ,bsc_sls_vd_next_serv_amt       -- ��{����(VD:���N�v��)
             ,bsc_sls_vd_exist_serv_amt      -- ��{����(VD:��������)
             ,bsc_sls_vd_total_amt           -- ��{����(VD:�v)
             ,bsc_sls_new_serv_amt           -- ��{����(VD�ȊO:�V�K�v��)
             ,bsc_sls_next_serv_amt          -- ��{����(VD�ȊO:���N�v��)
             ,bsc_sls_exist_serv_amt         -- ��{����(VD�ȊO:��������)
             ,bsc_sls_total_amt              -- ��{����(VD�ȊO:�v)
             ,bsc_sls_prsn_new_serv_amt      -- ��{����(�c�ƈ��v:�V�K�v��)
             ,bsc_sls_prsn_next_serv_amt     -- ��{����(�c�ƈ��v:���N�v��)
             ,bsc_sls_prsn_exist_serv_amt    -- ��{����(�c�ƈ��v:��������)
             ,bsc_sls_prsn_total_amt         -- ��{����(�c�ƈ��v:�v)
             ,tgt_sales_vd_new_serv_amt      -- �ڕW����(VD:�V�K�v��)
             ,tgt_sales_vd_next_serv_amt     -- �ڕW����(VD:���N�v��)
             ,tgt_sales_vd_exist_serv_amt    -- �ڕW����(VD:��������)
             ,tgt_sales_vd_total_amt         -- �ڕW����(VD:�v)
             ,tgt_sales_new_serv_amt         -- �ڕW����(VD�ȊO:�V�K�v��)
             ,tgt_sales_next_serv_amt        -- �ڕW����(VD�ȊO:���N�v��)
             ,tgt_sales_exist_serv_amt       -- �ڕW����(VD�ȊO:��������)
             ,tgt_sales_total_amt            -- �ڕW����(VD�ȊO:�v)
             ,tgt_sales_prsn_new_serv_amt    -- �ڕW����(�c�ƈ��v:�V�K�v��)
             ,tgt_sales_prsn_next_serv_amt   -- �ڕW����(�c�ƈ��v:���N�v��)
             ,tgt_sales_prsn_exist_serv_amt  -- �ڕW����(�c�ƈ��v:��������)
             ,tgt_sales_prsn_total_amt       -- �ڕW����(�c�ƈ��v:�v)
             ,rslt_vd_new_serv_amt           -- ����(VD:�V�K�v��)
             ,rslt_vd_next_serv_amt          -- ����(VD:���N�v��)
             ,rslt_vd_exist_serv_amt         -- ����(VD:��������)
             ,rslt_vd_total_amt              -- ����(VD:�v)
             ,rslt_new_serv_amt              -- ����(VD�ȊO:�V�K�v��)
             ,rslt_next_serv_amt             -- ����(VD�ȊO:���N�v��)
             ,rslt_exist_serv_amt            -- ����(VD�ȊO:��������)
             ,rslt_total_amt                 -- ����(VD�ȊO:�v)
             ,rslt_prsn_new_serv_amt         -- ����(�c�ƈ��v:�V�K�v��)
             ,rslt_prsn_next_serv_amt        -- ����(�c�ƈ��v:���N�v��)
             ,rslt_prsn_exist_serv_amt       -- ����(�c�ƈ��v:��������)
             ,rslt_prsn_total_amt            -- ����(�c�ƈ��v:�v)
             ,vis_vd_new_serv_amt            -- �K��(VD:�V�K�v��)
             ,vis_vd_next_serv_amt           -- �K��(VD:���N�v��)
             ,vis_vd_exist_serv_amt          -- �K��(VD:��������)
             ,vis_vd_total_amt               -- �K��(VD:�v)
             ,vis_new_serv_amt               -- �K��(VD�ȊO:�V�K�v��)
             ,vis_next_serv_amt              -- �K��(VD�ȊO:���N�v��)
             ,vis_exist_serv_amt             -- �K��(VD�ȊO:��������)
             ,vis_total_amt                  -- �K��(VD�ȊO:�v)
             ,vis_prsn_new_serv_amt          -- �K��(�c�ƈ��v:�V�K�v��)
             ,vis_prsn_next_serv_amt         -- �K��(�c�ƈ��v:���N�v��)
             ,vis_prsn_exist_serv_amt        -- �K��(�c�ƈ��v:��������)
             ,vis_prsn_total_amt             -- �K��(�c�ƈ��v:�v)
             ,created_by                     -- �쐬��
             ,creation_date                  -- �쐬��
             ,last_updated_by                -- �ŏI�X�V��
             ,last_update_date               -- �ŏI�X�V��
             ,last_update_login              -- �ŏI�X�V���O�C��
             ,request_id                     -- �v��ID
             ,program_application_id         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,program_id                     -- �R���J�����g�E�v���O����ID
             ,program_update_date            -- �v���O�����X�V��
              )
          VALUES
            ( xxcso_sls_prsn_mnthly_plns_s01.NEXTVAL           -- �c�ƈ��ʌ��ʌv��ID
             ,g_sls_pln_data_tab(i).base_code                  -- ���_CD
             ,g_sls_pln_data_tab(i).emply_nmbr                 -- �c�ƈ�CD
             ,g_sls_pln_data_tab(i).year_month                 -- �N��
             ,g_sls_pln_data_tab(i).fiscal_year                -- �N�x
             ,g_sls_pln_data_tab(i).input_division             -- ���͋敪
             ,g_sls_pln_data_tab(i).grp_nmbr                   -- �O���[�v�ԍ�
             ,g_sls_pln_data_tab(i).grp_ldr_flg                -- �O���[�v���敪
             ,g_sls_pln_data_tab(i).grp_grd                    -- �O���[�v������
             ,SUBSTRB(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)  -- �E�ʖ�
             ,g_sls_pln_data_tab(i).pr_rslt_vd_nw_srv_mt       -- �O�N����(VD:�V�K�v��)
             ,g_sls_pln_data_tab(i).pr_rslt_vd_nxt_srv_mt      -- �O�N����(VD:���N�v��)
             ,g_sls_pln_data_tab(i).pr_rslt_vd_xst_srv_mt      -- �O�N����(VD:��������)
             ,g_sls_pln_data_tab(i).pr_rslt_vd_ttl_mt          -- �O�N����(VD:�v)
             ,g_sls_pln_data_tab(i).pr_rslt_nw_srv_mt          -- �O�N����(VD�ȊO:�V�K�v��)
             ,g_sls_pln_data_tab(i).pr_rslt_nxt_srv_mt         -- �O�N����(VD�ȊO:���N�v��)
             ,g_sls_pln_data_tab(i).pr_rslt_xst_srv_mt         -- �O�N����(VD�ȊO:��������)
             ,g_sls_pln_data_tab(i).pr_rslt_ttl_mt             -- �O�N����(VD�ȊO:�v)
             ,g_sls_pln_data_tab(i).pr_rslt_prsn_nw_srv_mt     -- �O�N����(�c�ƈ��v:�V�K�v��)
             ,g_sls_pln_data_tab(i).pr_rslt_prsn_nxt_srv_mt    -- �O�N����(�c�ƈ��v:���N�v��)
             ,g_sls_pln_data_tab(i).pr_rslt_prsn_xst_srv_mt    -- �O�N����(�c�ƈ��v:��������)
             ,g_sls_pln_data_tab(i).pr_rslt_prsn_ttl_mt        -- �O�N����(�c�ƈ��v:�v)
             ,g_sls_pln_data_tab(i).bsc_sls_vd_nw_srv_mt       -- ��{����(VD:�V�K�v��)
             ,g_sls_pln_data_tab(i).bsc_sls_vd_nxt_srv_mt      -- ��{����(VD:���N�v��)
             ,g_sls_pln_data_tab(i).bsc_sls_vd_xst_srv_mt      -- ��{����(VD:��������)
             ,g_sls_pln_data_tab(i).bsc_sls_vd_ttl_mt          -- ��{����(VD:�v)
             ,g_sls_pln_data_tab(i).bsc_sls_nw_srv_mt          -- ��{����(VD�ȊO:�V�K�v��)
             ,g_sls_pln_data_tab(i).bsc_sls_nxt_srv_mt         -- ��{����(VD�ȊO:���N�v��)
             ,g_sls_pln_data_tab(i).bsc_sls_xst_srv_mt         -- ��{����(VD�ȊO:��������)
             ,g_sls_pln_data_tab(i).bsc_sls_ttl_mt             -- ��{����(VD�ȊO:�v)
             ,g_sls_pln_data_tab(i).bsc_sls_prsn_nw_srv_mt     -- ��{����(�c�ƈ��v:�V�K�v��)
             ,g_sls_pln_data_tab(i).bsc_sls_prsn_nxt_srv_mt    -- ��{����(�c�ƈ��v:���N�v��)
             ,g_sls_pln_data_tab(i).bsc_sls_prsn_xst_srv_mt    -- ��{����(�c�ƈ��v:��������)
             ,g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt        -- ��{����(�c�ƈ��v:�v)
             ,g_sls_pln_data_tab(i).tgt_sls_vd_nw_srv_mt       -- �ڕW����(VD:�V�K�v��)
             ,g_sls_pln_data_tab(i).tgt_sls_vd_nxt_srv_mt      -- �ڕW����(VD:���N�v��)
             ,g_sls_pln_data_tab(i).tgt_sls_vd_xst_srv_mt      -- �ڕW����(VD:��������)
             ,g_sls_pln_data_tab(i).tgt_sls_vd_ttl_mt          -- �ڕW����(VD:�v)
             ,g_sls_pln_data_tab(i).tgt_sls_nw_srv_mt          -- �ڕW����(VD�ȊO:�V�K�v��)
             ,g_sls_pln_data_tab(i).tgt_sls_nxt_srv_mt         -- �ڕW����(VD�ȊO:���N�v��)
             ,g_sls_pln_data_tab(i).tgt_sls_xst_srv_mt         -- �ڕW����(VD�ȊO:��������)
             ,g_sls_pln_data_tab(i).tgt_sls_ttl_mt             -- �ڕW����(VD�ȊO:�v)
             ,g_sls_pln_data_tab(i).tgt_sls_prsn_nw_srv_mt     -- �ڕW����(�c�ƈ��v:�V�K�v��)
             ,g_sls_pln_data_tab(i).tgt_sls_prsn_nxt_srv_mt    -- �ڕW����(�c�ƈ��v:���N�v��)
             ,g_sls_pln_data_tab(i).tgt_sls_prsn_xst_srv_mt    -- �ڕW����(�c�ƈ��v:��������)
             ,g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt        -- �ڕW����(�c�ƈ��v:�v)
             ,g_sls_pln_data_tab(i).rslt_vd_nw_srv_mt          -- ����(VD:�V�K�v��)
             ,g_sls_pln_data_tab(i).rslt_vd_nxt_srv_mt         -- ����(VD:���N�v��)
             ,g_sls_pln_data_tab(i).rslt_vd_xst_srv_mt         -- ����(VD:��������)
             ,g_sls_pln_data_tab(i).rslt_vd_total_amt          -- ����(VD:�v)
             ,g_sls_pln_data_tab(i).rslt_nw_srv_mt             -- ����(VD�ȊO:�V�K�v��)
             ,g_sls_pln_data_tab(i).rslt_nxt_srv_mt            -- ����(VD�ȊO:���N�v��)
             ,g_sls_pln_data_tab(i).rslt_xst_srv_mt            -- ����(VD�ȊO:��������)
             ,g_sls_pln_data_tab(i).rslt_ttl_mt                -- ����(VD�ȊO:�v)
             ,g_sls_pln_data_tab(i).rslt_prsn_nw_srv_mt        -- ����(�c�ƈ��v:�V�K�v��)
             ,g_sls_pln_data_tab(i).rslt_prsn_nxt_srv_mt       -- ����(�c�ƈ��v:���N�v��)
             ,g_sls_pln_data_tab(i).rslt_prsn_xst_srv_mt       -- ����(�c�ƈ��v:��������)
             ,g_sls_pln_data_tab(i).rslt_prsn_ttl_mt           -- ����(�c�ƈ��v:�v)
             ,NULL                                             -- �K��(VD:�V�K�v��)
             ,NULL                                             -- �K��(VD:���N�v��)
             ,NULL                                             -- �K��(VD:��������)
             ,g_sls_pln_data_tab(i).vis_vd_ttl_mt              -- �K��(VD:�v)
             ,NULL                                             -- �K��(VD�ȊO:�V�K�v��)
             ,NULL                                             -- �K��(VD�ȊO:���N�v��)
             ,NULL                                             -- �K��(VD�ȊO:��������)
             ,g_sls_pln_data_tab(i).vis_ttl_mt                 -- �K��(VD�ȊO:�v)
             ,NULL                                             -- �K��(�c�ƈ��v:�V�K�v��)
             ,NULL                                             -- �K��(�c�ƈ��v:���N�v��)
             ,NULL                                             -- �K��(�c�ƈ��v:��������)
             ,g_sls_pln_data_tab(i).vis_prsn_ttl_mt            -- �K��(�c�ƈ��v:�v)
             ,cn_created_by                     -- �쐬��
             ,cd_creation_date                  -- �쐬��
             ,cn_last_updated_by                -- �ŏI�X�V��
             ,cd_last_update_date               -- �ŏI�X�V��
             ,cn_last_update_login              -- �ŏI�X�V���O�C��
             ,cn_request_id                     -- �v��ID
             ,cn_program_application_id         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,cn_program_id                     -- �R���J�����g�E�v���O����ID
             ,cd_program_update_date            -- �v���O�����X�V��
              );
--
        ELSIF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
          -- ���͋敪2:�{���c�Ɨp�̏ꍇ
          INSERT INTO xxcso_sls_prsn_mnthly_plns  -- �c�ƈ��ʌ��ʌv��e�[�u��
            ( sls_prsn_mnthly_pln_id         -- �c�ƈ��ʌ��ʌv��ID
             ,base_code                      -- ���_CD
             ,employee_number                -- �c�ƈ�CD
             ,year_month                     -- �N��
             ,fiscal_year                    -- �N�x
             ,input_type                     -- ���͋敪
             ,group_number                   -- �O���[�v�ԍ�
             ,group_leader_flag              -- �O���[�v���敪
             ,group_grade                    -- �O���[�v������
             ,office_rank_name               -- �E�ʖ�
             ,bsc_sls_prsn_total_amt         -- ��{����(�c�ƈ��v:�v)
             ,tgt_sales_prsn_total_amt       -- �ڕW����(�c�ƈ��v:�v)
             ,vis_prsn_total_amt             -- �K��(�c�ƈ��v:�v)
             ,created_by                     -- �쐬��
             ,creation_date                  -- �쐬��
             ,last_updated_by                -- �ŏI�X�V��
             ,last_update_date               -- �ŏI�X�V��
             ,last_update_login              -- �ŏI�X�V���O�C��
             ,request_id                     -- �v��ID
             ,program_application_id         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,program_id                     -- �R���J�����g�E�v���O����ID
             ,program_update_date            -- �v���O�����X�V��
              )
          VALUES
            ( xxcso_sls_prsn_mnthly_plns_s01.NEXTVAL               -- �c�ƈ��ʌ��ʌv��ID
             ,g_sls_pln_data_tab(i).base_code                      -- ���_CD
             ,g_sls_pln_data_tab(i).emply_nmbr                     -- �c�ƈ�CD
             ,g_sls_pln_data_tab(i).year_month                     -- �N��
             ,g_sls_pln_data_tab(i).fiscal_year                    -- �N�x
             ,g_sls_pln_data_tab(i).input_division                 -- ���͋敪
             ,g_sls_pln_data_tab(i).grp_nmbr                       -- �O���[�v�ԍ�
             ,g_sls_pln_data_tab(i).grp_ldr_flg                    -- �O���[�v���敪
             ,g_sls_pln_data_tab(i).grp_grd                        -- �O���[�v������
             ,SUBSTRB(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)     -- �E�ʖ�
             ,g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt            -- ��{����(�c�ƈ��v:�v)
             ,g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt            -- �ڕW����(�c�ƈ��v:�v)
             ,g_sls_pln_data_tab(i).vis_prsn_ttl_mt                -- �K��(�c�ƈ��v:�v)
             ,cn_created_by                                        -- �쐬��
             ,cd_creation_date                                     -- �쐬��
             ,cn_last_updated_by                                   -- �ŏI�X�V��
             ,cd_last_update_date                                  -- �ŏI�X�V��
             ,cn_last_update_login                                 -- �ŏI�X�V���O�C��
             ,cn_request_id                                        -- �v��ID
             ,cn_program_application_id                            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,cn_program_id                                        -- �R���J�����g�E�v���O����ID
             ,cd_program_update_date                               -- �v���O�����X�V��
              );
        END IF;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_15                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h7
                       ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_err_msg                        -- �g�[�N���R�[�h8
                       ,iv_token_value8 => SQLERRM                               -- �g�[�N���l8
                     );
        lv_errbuf := lv_errmsg;
        RAISE inupdl_prsn_mnth_dt_err_expt;
    END;
--
    -- ==================
    --  �e�[�u�����b�N
    -- ==================
    BEGIN
      IF ((lb_all_update = TRUE) 
        OR (lb_bsc_sls_nt_update = TRUE)
        OR ((lb_part_update = TRUE)
        AND (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt))
        OR (lb_delete = TRUE))
      THEN
        SELECT  ROWID row_id  -- �c�ƈ��ʌ��ʌv��ID
        INTO    lr_row_id     -- �c�ƈ��ʌ��ʌv��ID�i�[
        FROM    xxcso_sls_prsn_mnthly_plns xspmp  -- �c�ƈ��ʌ��ʌv��e�[�u��
        WHERE   xspmp.base_code       = g_sls_pln_data_tab(i).base_code
        AND     xspmp.employee_number = g_sls_pln_data_tab(i).emply_nmbr
        AND     xspmp.year_month      = g_sls_pln_data_tab(i).year_month
        AND     xspmp.fiscal_year     = g_sls_pln_data_tab(i).fiscal_year
        FOR UPDATE NOWAIT;  -- �e�[�u�����b�N
      END IF;
--
    EXCEPTION
          -- ���b�N���s�����ꍇ�̗�O
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l5
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE inupdl_prsn_mnth_dt_err_expt;
--
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_07                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg                        -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                               -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h7
                       ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h8
                       ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l8
                     );
        lv_errbuf := lv_errmsg;
        RAISE inupdl_prsn_mnth_dt_err_expt;
    END;
--
    -- �yA-8-4-1�z�S���ڍX�V����
    BEGIN
      IF (lb_all_update = TRUE) THEN
        IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
          -- ���͋敪1:���[�g�c�Ɨp�̏ꍇ
          UPDATE xxcso_sls_prsn_mnthly_plns xspmp  -- �c�ƈ��ʌ��ʌv��e�[�u��
          SET
             base_code                      =  g_sls_pln_data_tab(i).base_code                  -- ���_CD
            ,year_month                     =  g_sls_pln_data_tab(i).year_month                 -- �N��
            ,fiscal_year                    =  g_sls_pln_data_tab(i).fiscal_year                -- �N�x
            ,input_type                     =  g_sls_pln_data_tab(i).input_division             -- ���͋敪
            ,group_number                   =  g_sls_pln_data_tab(i).grp_nmbr                   -- �O���[�v�ԍ�
            ,group_leader_flag              =  g_sls_pln_data_tab(i).grp_ldr_flg                -- �O���[�v���敪
            ,group_grade                    =  g_sls_pln_data_tab(i).grp_grd                    -- �O���[�v������
            ,office_rank_name               =  SUBSTR(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)  -- �E�ʖ�
            ,pri_rslt_vd_new_serv_amt       =  g_sls_pln_data_tab(i).pr_rslt_vd_nw_srv_mt       -- �O�N����(VD:�V�K�v��)
            ,pri_rslt_vd_next_serv_amt      =  g_sls_pln_data_tab(i).pr_rslt_vd_nxt_srv_mt      -- �O�N����(VD:���N�v��)
            ,pri_rslt_vd_exist_serv_amt     =  g_sls_pln_data_tab(i).pr_rslt_vd_xst_srv_mt      -- �O�N����(VD:��������)
            ,pri_rslt_vd_total_amt          =  g_sls_pln_data_tab(i).pr_rslt_vd_ttl_mt          -- �O�N����(VD:�v)
            ,pri_rslt_new_serv_amt          =  g_sls_pln_data_tab(i).pr_rslt_nw_srv_mt          -- �O�N����(VD�ȊO:�V�K�v��)
            ,pri_rslt_next_serv_amt         =  g_sls_pln_data_tab(i).pr_rslt_nxt_srv_mt         -- �O�N����(VD�ȊO:���N�v��)
            ,pri_rslt_exist_serv_amt        =  g_sls_pln_data_tab(i).pr_rslt_xst_srv_mt         -- �O�N����(VD�ȊO:��������)
            ,pri_rslt_total_amt             =  g_sls_pln_data_tab(i).pr_rslt_ttl_mt             -- �O�N����(VD�ȊO:�v)
            ,pri_rslt_prsn_new_serv_amt     =  g_sls_pln_data_tab(i).pr_rslt_prsn_nw_srv_mt     -- �O�N����(�c�ƈ��v:�V�K�v��)
            ,pri_rslt_prsn_next_serv_amt    =  g_sls_pln_data_tab(i).pr_rslt_prsn_nxt_srv_mt    -- �O�N����(�c�ƈ��v:���N�v��)
            ,pri_rslt_prsn_exist_serv_amt   =  g_sls_pln_data_tab(i).pr_rslt_prsn_xst_srv_mt    -- �O�N����(�c�ƈ��v:��������)
            ,pri_rslt_prsn_total_amt        =  g_sls_pln_data_tab(i).pr_rslt_prsn_ttl_mt        -- �O�N����(�c�ƈ��v:�v)
            ,bsc_sls_vd_new_serv_amt        =  g_sls_pln_data_tab(i).bsc_sls_vd_nw_srv_mt       -- ��{����(VD:�V�K�v��)
            ,bsc_sls_vd_next_serv_amt       =  g_sls_pln_data_tab(i).bsc_sls_vd_nxt_srv_mt      -- ��{����(VD:���N�v��)
            ,bsc_sls_vd_exist_serv_amt      =  g_sls_pln_data_tab(i).bsc_sls_vd_xst_srv_mt      -- ��{����(VD:��������)
            ,bsc_sls_vd_total_amt           =  g_sls_pln_data_tab(i).bsc_sls_vd_ttl_mt          -- ��{����(VD:�v)
            ,bsc_sls_new_serv_amt           =  g_sls_pln_data_tab(i).bsc_sls_nw_srv_mt          -- ��{����(VD�ȊO:�V�K�v��)
            ,bsc_sls_next_serv_amt          =  g_sls_pln_data_tab(i).bsc_sls_nxt_srv_mt         -- ��{����(VD�ȊO:���N�v��)
            ,bsc_sls_exist_serv_amt         =  g_sls_pln_data_tab(i).bsc_sls_xst_srv_mt         -- ��{����(VD�ȊO:��������)
            ,bsc_sls_total_amt              =  g_sls_pln_data_tab(i).bsc_sls_ttl_mt             -- ��{����(VD�ȊO:�v)
            ,bsc_sls_prsn_new_serv_amt      =  g_sls_pln_data_tab(i).bsc_sls_prsn_nw_srv_mt     -- ��{����(�c�ƈ��v:�V�K�v��)
            ,bsc_sls_prsn_next_serv_amt     =  g_sls_pln_data_tab(i).bsc_sls_prsn_nxt_srv_mt    -- ��{����(�c�ƈ��v:���N�v��)
            ,bsc_sls_prsn_exist_serv_amt    =  g_sls_pln_data_tab(i).bsc_sls_prsn_xst_srv_mt    -- ��{����(�c�ƈ��v:��������)
            ,bsc_sls_prsn_total_amt         =  g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt        -- ��{����(�c�ƈ��v:�v)
            ,tgt_sales_vd_new_serv_amt      =  g_sls_pln_data_tab(i).tgt_sls_vd_nw_srv_mt       -- �ڕW����(VD:�V�K�v��)
            ,tgt_sales_vd_next_serv_amt     =  g_sls_pln_data_tab(i).tgt_sls_vd_nxt_srv_mt      -- �ڕW����(VD:���N�v��)
            ,tgt_sales_vd_exist_serv_amt    =  g_sls_pln_data_tab(i).tgt_sls_vd_xst_srv_mt      -- �ڕW����(VD:��������)
            ,tgt_sales_vd_total_amt         =  g_sls_pln_data_tab(i).tgt_sls_vd_ttl_mt          -- �ڕW����(VD:�v)
            ,tgt_sales_new_serv_amt         =  g_sls_pln_data_tab(i).tgt_sls_nw_srv_mt          -- �ڕW����(VD�ȊO:�V�K�v��)
            ,tgt_sales_next_serv_amt        =  g_sls_pln_data_tab(i).tgt_sls_nxt_srv_mt         -- �ڕW����(VD�ȊO:���N�v��)
            ,tgt_sales_exist_serv_amt       =  g_sls_pln_data_tab(i).tgt_sls_xst_srv_mt         -- �ڕW����(VD�ȊO:��������)
            ,tgt_sales_total_amt            =  g_sls_pln_data_tab(i).tgt_sls_ttl_mt             -- �ڕW����(VD�ȊO:�v)
            ,tgt_sales_prsn_new_serv_amt    =  g_sls_pln_data_tab(i).tgt_sls_prsn_nw_srv_mt     -- �ڕW����(�c�ƈ��v:�V�K�v��)
            ,tgt_sales_prsn_next_serv_amt   =  g_sls_pln_data_tab(i).tgt_sls_prsn_nxt_srv_mt    -- �ڕW����(�c�ƈ��v:���N�v��)
            ,tgt_sales_prsn_exist_serv_amt  =  g_sls_pln_data_tab(i).tgt_sls_prsn_xst_srv_mt    -- �ڕW����(�c�ƈ��v:��������)
            ,tgt_sales_prsn_total_amt       =  g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt        -- �ڕW����(�c�ƈ��v:�v)
            ,rslt_vd_new_serv_amt           =  g_sls_pln_data_tab(i).rslt_vd_nw_srv_mt          -- ����(VD:�V�K�v��)
            ,rslt_vd_next_serv_amt          =  g_sls_pln_data_tab(i).rslt_vd_nxt_srv_mt         -- ����(VD:���N�v��)
            ,rslt_vd_exist_serv_amt         =  g_sls_pln_data_tab(i).rslt_vd_xst_srv_mt         -- ����(VD:��������)
            ,rslt_vd_total_amt              =  g_sls_pln_data_tab(i).rslt_vd_total_amt          -- ����(VD:�v)
            ,rslt_new_serv_amt              =  g_sls_pln_data_tab(i).rslt_nw_srv_mt             -- ����(VD�ȊO:�V�K�v��)
            ,rslt_next_serv_amt             =  g_sls_pln_data_tab(i).rslt_nxt_srv_mt            -- ����(VD�ȊO:���N�v��)
            ,rslt_exist_serv_amt            =  g_sls_pln_data_tab(i).rslt_xst_srv_mt            -- ����(VD�ȊO:��������)
            ,rslt_total_amt                 =  g_sls_pln_data_tab(i).rslt_ttl_mt                -- ����(VD�ȊO:�v)
            ,rslt_prsn_new_serv_amt         =  g_sls_pln_data_tab(i).rslt_prsn_nw_srv_mt        -- ����(�c�ƈ��v:�V�K�v��)
            ,rslt_prsn_next_serv_amt        =  g_sls_pln_data_tab(i).rslt_prsn_nxt_srv_mt       -- ����(�c�ƈ��v:���N�v��)
            ,rslt_prsn_exist_serv_amt       =  g_sls_pln_data_tab(i).rslt_prsn_xst_srv_mt       -- ����(�c�ƈ��v:��������)
            ,rslt_prsn_total_amt            =  g_sls_pln_data_tab(i).rslt_prsn_ttl_mt           -- ����(�c�ƈ��v:�v)
            ,vis_vd_new_serv_amt            =  NULL                                             -- �K��(VD:�V�K�v��)
            ,vis_vd_next_serv_amt           =  NULL                                             -- �K��(VD:���N�v��)
            ,vis_vd_exist_serv_amt          =  NULL                                             -- �K��(VD:��������)
            ,vis_vd_total_amt               =  g_sls_pln_data_tab(i).vis_vd_ttl_mt              -- �K��(VD:�v)
            ,vis_new_serv_amt               =  NULL                                             -- �K��(VD�ȊO:�V�K�v��)
            ,vis_next_serv_amt              =  NULL                                             -- �K��(VD�ȊO:���N�v��)
            ,vis_exist_serv_amt             =  NULL                                             -- �K��(VD�ȊO:��������)
            ,vis_total_amt                  =  g_sls_pln_data_tab(i).vis_ttl_mt                 -- �K��(VD�ȊO:�v)
            ,vis_prsn_new_serv_amt          =  NULL                                             -- �K��(�c�ƈ��v:�V�K�v��)
            ,vis_prsn_next_serv_amt         =  NULL                                             -- �K��(�c�ƈ��v:���N�v��)
            ,vis_prsn_exist_serv_amt        =  NULL                                             -- �K��(�c�ƈ��v:��������)
            ,vis_prsn_total_amt             =  g_sls_pln_data_tab(i).vis_prsn_ttl_mt            -- �K��(�c�ƈ��v:�v)
            ,last_updated_by                =  cn_last_updated_by                               -- �ŏI�X�V��
            ,last_update_date               =  cd_last_update_date                              -- �ŏI�X�V��
            ,last_update_login              =  cn_last_update_login                             -- �ŏI�X�V���O�C��
            ,request_id                     =  cn_request_id                                    -- �v��ID
            ,program_application_id         =  cn_program_application_id                        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id                     =  cn_program_id                                    -- �R���J�����g�E�v���O����ID
            ,program_update_date            =  cd_program_update_date                           -- �v���O�����X�V��
          WHERE  ROWID = lr_row_id;
--
        ELSIF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
          -- ���͋敪2:�{���c�Ɨp�̏ꍇ
          UPDATE xxcso_sls_prsn_mnthly_plns xspmp  -- �c�ƈ��ʌ��ʌv��e�[�u��
          SET
             base_code                      =  g_sls_pln_data_tab(i).base_code                  -- ���_CD
            ,year_month                     =  g_sls_pln_data_tab(i).year_month                 -- �N��
            ,fiscal_year                    =  g_sls_pln_data_tab(i).fiscal_year                -- �N�x
            ,input_type                     =  g_sls_pln_data_tab(i).input_division             -- ���͋敪
            ,group_number                   =  g_sls_pln_data_tab(i).grp_nmbr                   -- �O���[�v�ԍ�
            ,group_leader_flag              =  g_sls_pln_data_tab(i).grp_ldr_flg                -- �O���[�v���敪
            ,group_grade                    =  g_sls_pln_data_tab(i).grp_grd                    -- �O���[�v������
            ,office_rank_name               =  SUBSTRB(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)  -- �E�ʖ�
            ,bsc_sls_prsn_total_amt         =  g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt        -- ��{����(�c�ƈ��v:�v)
            ,tgt_sales_prsn_total_amt       =  g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt        -- �ڕW����(�c�ƈ��v:�v)
            ,vis_prsn_total_amt             =  g_sls_pln_data_tab(i).vis_prsn_ttl_mt            -- �K��(�c�ƈ��v:�v)
            ,last_updated_by                =  cn_last_updated_by                               -- �ŏI�X�V��
            ,last_update_date               =  cd_last_update_date                              -- �ŏI�X�V��
            ,last_update_login              =  cn_last_update_login                             -- �ŏI�X�V���O�C��
            ,request_id                     =  cn_request_id                                    -- �v��ID
            ,program_application_id         =  cn_program_application_id                        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id                     =  cn_program_id                                    -- �R���J�����g�E�v���O����ID
            ,program_update_date            =  cd_program_update_date                           -- �v���O�����X�V��
          WHERE  ROWID = lr_row_id;
        END IF;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_16                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h7
                       ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_err_msg                        -- �g�[�N���R�[�h8
                       ,iv_token_value8 => SQLERRM                               -- �g�[�N���l8
                     );
        lv_errbuf := lv_errmsg;
        RAISE inupdl_prsn_mnth_dt_err_expt;
    END;
--
    -- �yA-8-4-2�z��{����̂ݍX�V���Ȃ��X�V
    BEGIN
      IF (lb_bsc_sls_nt_update = TRUE) THEN
        IF (g_sls_pln_data_tab(i).bs_pln_chng_flg = cn_effective_val) THEN
          -- ��6�c�Ɠ��ȍ~��{�v��ύX�t���O���L���̏ꍇ�A���b�Z�[�W���o��
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_37                      -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h1
                         ,iv_token_value1 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h2
                         ,iv_token_value2 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l3
                       );
          lv_errbuf := lv_errmsg;
--
          -- ���b�Z�[�W�A�E�g�t�@�C���֏o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- ���b�Z�[�W���O�t�@�C���֏o��
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg
          );
        END IF;
--
        IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
          -- ���͋敪1:���[�g�c�Ɨp�̏ꍇ
          UPDATE xxcso_sls_prsn_mnthly_plns xspmp  -- �c�ƈ��ʌ��ʌv��e�[�u��
          SET
             base_code                      =  g_sls_pln_data_tab(i).base_code                   -- ���_CD
            ,year_month                     =  g_sls_pln_data_tab(i).year_month                  -- �N��
            ,fiscal_year                    =  g_sls_pln_data_tab(i).fiscal_year                 -- �N�x
            ,input_type                     =  g_sls_pln_data_tab(i).input_division              -- ���͋敪
            ,group_number                   =  g_sls_pln_data_tab(i).grp_nmbr                    -- �O���[�v�ԍ�
            ,group_leader_flag              =  g_sls_pln_data_tab(i).grp_ldr_flg                 -- �O���[�v���敪
            ,group_grade                    =  g_sls_pln_data_tab(i).grp_grd                     -- �O���[�v������
            ,office_rank_name               =  SUBSTRB(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)  -- �E�ʖ�
            ,pri_rslt_vd_new_serv_amt       =  g_sls_pln_data_tab(i).pr_rslt_vd_nw_srv_mt        -- �O�N����(VD:�V�K�v��)
            ,pri_rslt_vd_next_serv_amt      =  g_sls_pln_data_tab(i).pr_rslt_vd_nxt_srv_mt       -- �O�N����(VD:���N�v��)
            ,pri_rslt_vd_exist_serv_amt     =  g_sls_pln_data_tab(i).pr_rslt_vd_xst_srv_mt       -- �O�N����(VD:��������)
            ,pri_rslt_vd_total_amt          =  g_sls_pln_data_tab(i).pr_rslt_vd_ttl_mt           -- �O�N����(VD:�v)
            ,pri_rslt_new_serv_amt          =  g_sls_pln_data_tab(i).pr_rslt_nw_srv_mt           -- �O�N����(VD�ȊO:�V�K�v��)
            ,pri_rslt_next_serv_amt         =  g_sls_pln_data_tab(i).pr_rslt_nxt_srv_mt          -- �O�N����(VD�ȊO:���N�v��)
            ,pri_rslt_exist_serv_amt        =  g_sls_pln_data_tab(i).pr_rslt_xst_srv_mt          -- �O�N����(VD�ȊO:��������)
            ,pri_rslt_total_amt             =  g_sls_pln_data_tab(i).pr_rslt_ttl_mt              -- �O�N����(VD�ȊO:�v)
            ,pri_rslt_prsn_new_serv_amt     =  g_sls_pln_data_tab(i).pr_rslt_prsn_nw_srv_mt      -- �O�N����(�c�ƈ��v:�V�K�v��)
            ,pri_rslt_prsn_next_serv_amt    =  g_sls_pln_data_tab(i).pr_rslt_prsn_nxt_srv_mt     -- �O�N����(�c�ƈ��v:���N�v��)
            ,pri_rslt_prsn_exist_serv_amt   =  g_sls_pln_data_tab(i).pr_rslt_prsn_xst_srv_mt     -- �O�N����(�c�ƈ��v:��������)
            ,pri_rslt_prsn_total_amt        =  g_sls_pln_data_tab(i).pr_rslt_prsn_ttl_mt         -- �O�N����(�c�ƈ��v:�v)
            ,tgt_sales_vd_new_serv_amt      =  g_sls_pln_data_tab(i).tgt_sls_vd_nw_srv_mt        -- �ڕW����(VD:�V�K�v��)
            ,tgt_sales_vd_next_serv_amt     =  g_sls_pln_data_tab(i).tgt_sls_vd_nxt_srv_mt       -- �ڕW����(VD:���N�v��)
            ,tgt_sales_vd_exist_serv_amt    =  g_sls_pln_data_tab(i).tgt_sls_vd_xst_srv_mt       -- �ڕW����(VD:��������)
            ,tgt_sales_vd_total_amt         =  g_sls_pln_data_tab(i).tgt_sls_vd_ttl_mt           -- �ڕW����(VD:�v)
            ,tgt_sales_new_serv_amt         =  g_sls_pln_data_tab(i).tgt_sls_nw_srv_mt           -- �ڕW����(VD�ȊO:�V�K�v��)
            ,tgt_sales_next_serv_amt        =  g_sls_pln_data_tab(i).tgt_sls_nxt_srv_mt          -- �ڕW����(VD�ȊO:���N�v��)
            ,tgt_sales_exist_serv_amt       =  g_sls_pln_data_tab(i).tgt_sls_xst_srv_mt          -- �ڕW����(VD�ȊO:��������)
            ,tgt_sales_total_amt            =  g_sls_pln_data_tab(i).tgt_sls_ttl_mt              -- �ڕW����(VD�ȊO:�v)
            ,tgt_sales_prsn_new_serv_amt    =  g_sls_pln_data_tab(i).tgt_sls_prsn_nw_srv_mt      -- �ڕW����(�c�ƈ��v:�V�K�v��)
            ,tgt_sales_prsn_next_serv_amt   =  g_sls_pln_data_tab(i).tgt_sls_prsn_nxt_srv_mt     -- �ڕW����(�c�ƈ��v:���N�v��)
            ,tgt_sales_prsn_exist_serv_amt  =  g_sls_pln_data_tab(i).tgt_sls_prsn_xst_srv_mt     -- �ڕW����(�c�ƈ��v:��������)
            ,tgt_sales_prsn_total_amt       =  g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt         -- �ڕW����(�c�ƈ��v:�v)
            ,rslt_vd_new_serv_amt           =  g_sls_pln_data_tab(i).rslt_vd_nw_srv_mt           -- ����(VD:�V�K�v��)
            ,rslt_vd_next_serv_amt          =  g_sls_pln_data_tab(i).rslt_vd_nxt_srv_mt          -- ����(VD:���N�v��)
            ,rslt_vd_exist_serv_amt         =  g_sls_pln_data_tab(i).rslt_vd_xst_srv_mt          -- ����(VD:��������)
            ,rslt_vd_total_amt              =  g_sls_pln_data_tab(i).rslt_vd_total_amt           -- ����(VD:�v)
            ,rslt_new_serv_amt              =  g_sls_pln_data_tab(i).rslt_nw_srv_mt              -- ����(VD�ȊO:�V�K�v��)
            ,rslt_next_serv_amt             =  g_sls_pln_data_tab(i).rslt_nxt_srv_mt             -- ����(VD�ȊO:���N�v��)
            ,rslt_exist_serv_amt            =  g_sls_pln_data_tab(i).rslt_xst_srv_mt             -- ����(VD�ȊO:��������)
            ,rslt_total_amt                 =  g_sls_pln_data_tab(i).rslt_ttl_mt                 -- ����(VD�ȊO:�v)
            ,rslt_prsn_new_serv_amt         =  g_sls_pln_data_tab(i).rslt_prsn_nw_srv_mt         -- ����(�c�ƈ��v:�V�K�v��)
            ,rslt_prsn_next_serv_amt        =  g_sls_pln_data_tab(i).rslt_prsn_nxt_srv_mt        -- ����(�c�ƈ��v:���N�v��)
            ,rslt_prsn_exist_serv_amt       =  g_sls_pln_data_tab(i).rslt_prsn_xst_srv_mt        -- ����(�c�ƈ��v:��������)
            ,rslt_prsn_total_amt            =  g_sls_pln_data_tab(i).rslt_prsn_ttl_mt            -- ����(�c�ƈ��v:�v)
            ,vis_vd_new_serv_amt            =  NULL                                              -- �K��(VD:�V�K�v��)
            ,vis_vd_next_serv_amt           =  NULL                                              -- �K��(VD:���N�v��)
            ,vis_vd_exist_serv_amt          =  NULL                                              -- �K��(VD:��������)
            ,vis_vd_total_amt               =  g_sls_pln_data_tab(i).vis_vd_ttl_mt               -- �K��(VD:�v)
            ,vis_new_serv_amt               =  NULL                                              -- �K��(VD�ȊO:�V�K�v��)
            ,vis_next_serv_amt              =  NULL                                              -- �K��(VD�ȊO:���N�v��)
            ,vis_exist_serv_amt             =  NULL                                              -- �K��(VD�ȊO:��������)
            ,vis_total_amt                  =  g_sls_pln_data_tab(i).vis_ttl_mt                  -- �K��(VD�ȊO:�v)
            ,vis_prsn_new_serv_amt          =  NULL                                              -- �K��(�c�ƈ��v:�V�K�v��)
            ,vis_prsn_next_serv_amt         =  NULL                                              -- �K��(�c�ƈ��v:���N�v��)
            ,vis_prsn_exist_serv_amt        =  NULL                                              -- �K��(�c�ƈ��v:��������)
            ,vis_prsn_total_amt             =  g_sls_pln_data_tab(i).vis_prsn_ttl_mt             -- �K��(�c�ƈ��v:�v)
            ,last_updated_by                =  cn_last_updated_by                                -- �ŏI�X�V��
            ,last_update_date               =  cd_last_update_date                               -- �ŏI�X�V��
            ,last_update_login              =  cn_last_update_login                              -- �ŏI�X�V���O�C��
            ,request_id                     =  cn_request_id                                     -- �v��ID
            ,program_application_id         =  cn_program_application_id                         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id                     =  cn_program_id                                     -- �R���J�����g�E�v���O����ID
            ,program_update_date            =  cd_program_update_date                            -- �v���O�����X�V��
          WHERE  ROWID = lr_row_id;
--
        ELSIF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
          -- ���͋敪2:�{���c�Ɨp�̏ꍇ
          UPDATE xxcso_sls_prsn_mnthly_plns xspmp  -- �c�ƈ��ʌ��ʌv��e�[�u��
          SET
             base_code                      =  g_sls_pln_data_tab(i).base_code                   -- ���_CD
            ,year_month                     =  g_sls_pln_data_tab(i).year_month                  -- �N��
            ,fiscal_year                    =  g_sls_pln_data_tab(i).fiscal_year                 -- �N�x
            ,input_type                     =  g_sls_pln_data_tab(i).input_division              -- ���͋敪
            ,group_number                   =  g_sls_pln_data_tab(i).grp_nmbr                    -- �O���[�v�ԍ�
            ,group_leader_flag              =  g_sls_pln_data_tab(i).grp_ldr_flg                 -- �O���[�v���敪
            ,group_grade                    =  g_sls_pln_data_tab(i).grp_grd                     -- �O���[�v������
            ,office_rank_name               =  SUBSTRB(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)  -- �E�ʖ�
            ,tgt_sales_prsn_total_amt       =  g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt         -- �ڕW����(�c�ƈ��v:�v)
            ,vis_prsn_total_amt             =  g_sls_pln_data_tab(i).vis_prsn_ttl_mt             -- �K��(�c�ƈ��v:�v)
            ,last_updated_by                =  cn_last_updated_by                                -- �ŏI�X�V��
            ,last_update_date               =  cd_last_update_date                               -- �ŏI�X�V��
            ,last_update_login              =  cn_last_update_login                              -- �ŏI�X�V���O�C��
            ,request_id                     =  cn_request_id                                     -- �v��ID
            ,program_application_id         =  cn_program_application_id                         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id                     =  cn_program_id                                     -- �R���J�����g�E�v���O����ID
            ,program_update_date            =  cd_program_update_date                            -- �v���O�����X�V��
          WHERE  ROWID = lr_row_id;
        END IF;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_16                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h7
                       ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_err_msg                        -- �g�[�N���R�[�h8
                       ,iv_token_value8 => SQLERRM                               -- �g�[�N���l8
                     );
        lv_errbuf := lv_errmsg;
        RAISE inupdl_prsn_mnth_dt_err_expt;
    END;
--
    -- �yA-8-4-3�z��{����E�ڕW����E�K��f�[�^�͍X�V���Ȃ������X�V
    BEGIN
      IF (lb_part_update = TRUE) THEN
        IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
          -- ���͋敪1:���[�g�c�Ɨp�̏ꍇ
          UPDATE xxcso_sls_prsn_mnthly_plns xspmp  -- �c�ƈ��ʌ��ʌv��e�[�u��
          SET
             base_code                      =  g_sls_pln_data_tab(i).base_code                   -- ���_CD
            ,year_month                     =  g_sls_pln_data_tab(i).year_month                  -- �N��
            ,fiscal_year                    =  g_sls_pln_data_tab(i).fiscal_year                 -- �N�x
            ,input_type                     =  g_sls_pln_data_tab(i).input_division              -- ���͋敪
            ,group_number                   =  g_sls_pln_data_tab(i).grp_nmbr                    -- �O���[�v�ԍ�
            ,group_leader_flag              =  g_sls_pln_data_tab(i).grp_ldr_flg                 -- �O���[�v���敪
            ,group_grade                    =  g_sls_pln_data_tab(i).grp_grd                     -- �O���[�v������
            ,office_rank_name               =  SUBSTRB(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)  -- �E�ʖ�
            ,pri_rslt_vd_new_serv_amt       =  g_sls_pln_data_tab(i).pr_rslt_vd_nw_srv_mt        -- �O�N����(VD:�V�K�v��)
            ,pri_rslt_vd_next_serv_amt      =  g_sls_pln_data_tab(i).pr_rslt_vd_nxt_srv_mt       -- �O�N����(VD:���N�v��)
            ,pri_rslt_vd_exist_serv_amt     =  g_sls_pln_data_tab(i).pr_rslt_vd_xst_srv_mt       -- �O�N����(VD:��������)
            ,pri_rslt_vd_total_amt          =  g_sls_pln_data_tab(i).pr_rslt_vd_ttl_mt           -- �O�N����(VD:�v)
            ,pri_rslt_new_serv_amt          =  g_sls_pln_data_tab(i).pr_rslt_nw_srv_mt           -- �O�N����(VD�ȊO:�V�K�v��)
            ,pri_rslt_next_serv_amt         =  g_sls_pln_data_tab(i).pr_rslt_nxt_srv_mt          -- �O�N����(VD�ȊO:���N�v��)
            ,pri_rslt_exist_serv_amt        =  g_sls_pln_data_tab(i).pr_rslt_xst_srv_mt          -- �O�N����(VD�ȊO:��������)
            ,pri_rslt_total_amt             =  g_sls_pln_data_tab(i).pr_rslt_ttl_mt              -- �O�N����(VD�ȊO:�v)
            ,pri_rslt_prsn_new_serv_amt     =  g_sls_pln_data_tab(i).pr_rslt_prsn_nw_srv_mt      -- �O�N����(�c�ƈ��v:�V�K�v��)
            ,pri_rslt_prsn_next_serv_amt    =  g_sls_pln_data_tab(i).pr_rslt_prsn_nxt_srv_mt     -- �O�N����(�c�ƈ��v:���N�v��)
            ,pri_rslt_prsn_exist_serv_amt   =  g_sls_pln_data_tab(i).pr_rslt_prsn_xst_srv_mt     -- �O�N����(�c�ƈ��v:��������)
            ,pri_rslt_prsn_total_amt        =  g_sls_pln_data_tab(i).pr_rslt_prsn_ttl_mt         -- �O�N����(�c�ƈ��v:�v)
            ,rslt_vd_new_serv_amt           =  g_sls_pln_data_tab(i).rslt_vd_nw_srv_mt           -- ����(VD:�V�K�v��)
            ,rslt_vd_next_serv_amt          =  g_sls_pln_data_tab(i).rslt_vd_nxt_srv_mt          -- ����(VD:���N�v��)
            ,rslt_vd_exist_serv_amt         =  g_sls_pln_data_tab(i).rslt_vd_xst_srv_mt          -- ����(VD:��������)
            ,rslt_vd_total_amt              =  g_sls_pln_data_tab(i).rslt_vd_total_amt           -- ����(VD:�v)
            ,rslt_new_serv_amt              =  g_sls_pln_data_tab(i).rslt_nw_srv_mt              -- ����(VD�ȊO:�V�K�v��)
            ,rslt_next_serv_amt             =  g_sls_pln_data_tab(i).rslt_nxt_srv_mt             -- ����(VD�ȊO:���N�v��)
            ,rslt_exist_serv_amt            =  g_sls_pln_data_tab(i).rslt_xst_srv_mt             -- ����(VD�ȊO:��������)
            ,rslt_total_amt                 =  g_sls_pln_data_tab(i).rslt_ttl_mt                 -- ����(VD�ȊO:�v)
            ,rslt_prsn_new_serv_amt         =  g_sls_pln_data_tab(i).rslt_prsn_nw_srv_mt         -- ����(�c�ƈ��v:�V�K�v��)
            ,rslt_prsn_next_serv_amt        =  g_sls_pln_data_tab(i).rslt_prsn_nxt_srv_mt        -- ����(�c�ƈ��v:���N�v��)
            ,rslt_prsn_exist_serv_amt       =  g_sls_pln_data_tab(i).rslt_prsn_xst_srv_mt        -- ����(�c�ƈ��v:��������)
            ,rslt_prsn_total_amt            =  g_sls_pln_data_tab(i).rslt_prsn_ttl_mt            -- ����(�c�ƈ��v:�v)
            ,last_updated_by                =  cn_last_updated_by                                -- �ŏI�X�V��
            ,last_update_date               =  cd_last_update_date                               -- �ŏI�X�V��
            ,last_update_login              =  cn_last_update_login                              -- �ŏI�X�V���O�C��
            ,request_id                     =  cn_request_id                                     -- �v��ID
            ,program_application_id         =  cn_program_application_id                         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id                     =  cn_program_id                                     -- �R���J�����g�E�v���O����ID
            ,program_update_date            =  cd_program_update_date                            -- �v���O�����X�V��
          WHERE  ROWID = lr_row_id;
        END IF;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_16                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd                    -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nmbr      -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm                    -- �g�[�N���R�[�h7
                       ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nm        -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_err_msg                        -- �g�[�N���R�[�h8
                       ,iv_token_value8 => SQLERRM                               -- �g�[�N���l8
                     );
        lv_errbuf := lv_errmsg;
        RAISE inupdl_prsn_mnth_dt_err_expt;
    END;
--
    -- �yA-8-5�z�폜
    BEGIN
      
      IF (lb_delete = TRUE) THEN
        DELETE    -- �c�ƈ��ʌ��ʌv��e�[�u���폜����
        FROM   xxcso_sls_prsn_mnthly_plns xspmp    -- �c�ƈ��ʌ��ʌv��e�[�u��
        WHERE  ROWID = lr_row_id;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_17                      -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_err_msg                        -- �g�[�N���R�[�h6
                       ,iv_token_value6 => SQLERRM                               -- �g�[�N���l6
                     );
        lv_errbuf := lv_errmsg;
        RAISE inupdl_prsn_mnth_dt_err_expt;
    END;
--
  EXCEPTION
    -- *** ���S�����X�L�b�v��O�n���h�� ***
    WHEN all_ignore_skip_error_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := NULL;
    -- ��{����E�ڕW����E�K��f�[�^�͍X�V���Ȃ������X�V[�{���X�L�b�v]��O�n���h�� ***
    WHEN part_update_hnb_skip_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_normal;
    -- *** �c�ƈ��ʌ��ʌv��f�[�^�o�^�E�X�V�E�폜�������G���[��O�n���h�� ***
    WHEN inupdl_prsn_mnth_dt_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �c�ƈ��ʌ��ʌv��f�[�^�o�^�E�X�V�E�폜�������X�L�b�v��O�n���h�� ***
    WHEN inupdl_prsn_mnth_dt_skp_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
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
  END inupdl_prsn_month_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : �t�@�C���f�[�^�폜���� (A-9)
   ***********************************************************************************/
--
  PROCEDURE delete_if_data(
     ov_errbuf            OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'delete_if_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_if_table_nm       CONSTANT VARCHAR2(100)  := '�t�@�C���A�b�v���[�hI/F�e�[�u��';
    delete_if_data       EXCEPTION;       -- �t�@�C���f�[�^�폜�������G���[��O
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
      -- �t�@�C���f�[�^�폜
      DELETE FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = gt_file_id;
--
    EXCEPTION
      -- �폜�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                        -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_18                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                         -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_if_table_nm                     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_file_id                     -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg                     -- �g�[�N���R�[�h2
                       ,iv_token_value3 => SQLERRM                            -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE delete_if_data;                                                    -- # �C�� #
    END;
--
  EXCEPTION
    -- *** ������O�n���h�� ***
    WHEN delete_if_data THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
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
  END delete_if_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
--
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_sub_retcode VARCHAR2(1);     -- �T�[�u���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    -- OUT�p�����[�^�i�[�p
    l_col_data_tab       g_col_data_ttype;       -- �����㍀�ڃf�[�^���i�[����z��
    lv_xls_ver_rt        VARCHAR2(100);          -- ����v��ҏW�y���[�g�Z�[���X�z�G�N�Z���v���O�����o�[�W�����ԍ�
    lv_xls_ver_hnb       VARCHAR2(100);          -- ����v��ҏW�y�{���c�Ɓz�G�N�Z���v���O�����o�[�W�����ԍ�
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
    lv_sls_pln_upld_cls_dy  VARCHAR2(100);       -- ����v��A�b�v���[�h���c�Ɠ�
    /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
    lv_user_base_code    VARCHAR2(100);          -- ���O�C�����[�U�[�̋��_�R�[�h
    lv_base_value        VARCHAR2(5000);         -- ���Y�s�f�[�^
    ln_dpt_mnth_pln_cnt  NUMBER;                 -- ���o����
--
    -- *** ���[�J����O ***
--
  BEGIN
--
-- ##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ================================
    -- A-1.�������� 
    -- ================================
    init(
       ov_xls_ver_rt  => lv_xls_ver_rt   -- ����v��ҏW�y���[�g�Z�[���X�z�G�N�Z���v���O�����o�[�W�����ԍ�
      ,ov_xls_ver_hnb => lv_xls_ver_hnb  -- ����v��ҏW�y�{���c�Ɓz�G�N�Z���v���O�����o�[�W�����ԍ�
      /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
      ,ov_sls_pln_upld_cls_dy => lv_sls_pln_upld_cls_dy    -- ����v��A�b�v���[�h���c�Ɠ�
      /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
      ,ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.����v��f�[�^���o���� 
    -- ========================================
    get_sales_plan_data(
       ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- A-3.���O�C�����[�U�[�̋��_�R�[�h���o 
    -- ==================================================
    get_user_data(
       ov_user_base_code => lv_user_base_code  -- ���O�C�����[�U�[�̋��_�R�[�h
      ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
      -- �`�F�b�N��i�[�p�z��N���A
      g_sls_pln_data_tab.DELETE;
--
      -- �t�@�C���f�[�^���o�E�`�F�b�N���[�v
      <<get_sales_plan_data_loop>>
      FOR i IN 1..g_file_data_tab.COUNT LOOP
--
        BEGIN
--
          -- ���[�v�J�E���^�i�[
          g_rec_count := i;
--
          -- 2�s�ڈȍ~�̃f�[�^�̏ꍇ�A�Ώی����J�E���g
          IF i >= 2 THEN
            gn_target_cnt := gn_target_cnt + 1;
          END IF;
--
          -- �擾����1�s���̃f�[�^���i�[
          lv_base_value := g_file_data_tab(i);
--


          -- =================================================
          -- A-4.�f�[�^�Ó����`�F�b�N (�z��Ƀf�[�^�Z�b�g)
          -- =================================================
          data_proper_check(
             iv_xls_ver_rt    => lv_xls_ver_rt   -- ����v��ҏW�y���[�g�Z�[���X�z�G�N�Z���v���O�����o�[�W�����ԍ�
            ,iv_xls_ver_hnb   => lv_xls_ver_hnb  -- ����v��ҏW�y�{���c�Ɓz�G�N�Z���v���O�����o�[�W�����ԍ�
            ,iv_base_value    => lv_base_value   -- ���Y�s�f�[�^
            ,o_col_data_tab   => l_col_data_tab  -- �t�@�C���f�[�^(�s�f�[�^)
            ,ov_errbuf        => lv_errbuf       -- �G���[�E���b�Z�[�W            -- # �Œ� #
            ,ov_retcode       => lv_sub_retcode  -- ���^�[���E�R�[�h              -- # �Œ� #
            ,ov_errmsg        => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_data_check_error_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE global_data_check_skip_expt;
          END IF;
--
          IF i >= 2 THEN
          -- 2�s�ڈȍ~�̃f�[�^�̏ꍇ
          
            -- =============================
            -- A-5.�}�X�^���݃`�F�b�N 
            -- =============================
            chk_mst_is_exists(
              iv_user_base_code  => lv_user_base_code  -- ���O�C�����[�U�[�̋��_�R�[�h
              /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
              ,in_sls_pln_upld_cls_dy => TO_NUMBER(lv_sls_pln_upld_cls_dy)
                                                    -- ����v��A�b�v���[�h���c�Ɠ�
              /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
              ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W            -- # �Œ� #
              ,ov_retcode        => lv_sub_retcode     -- ���^�[���E�R�[�h              -- # �Œ� #
              ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              RAISE global_data_check_error_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              RAISE global_data_check_skip_expt;
            END IF;
--
          END IF;
--
          -- 2�s�ڈȍ~�̃f�[�^�̏ꍇ�A���������J�E���g
          IF i >= 2 THEN
            gn_normal_cnt := gn_normal_cnt + 1;
          END IF;
--
        EXCEPTION
          WHEN global_data_check_error_expt THEN
          -- *** �f�[�^�`�F�b�N�G���[��O�n���h�� ***
            gn_error_cnt := gn_error_cnt + 1;           -- �G���[�����J�E���g
            RAISE global_process_expt;                  -- ���[�v�𔲂��ăt�@�C���f�[�^�폜������
--
          -- *** �f�[�^�`�F�b�N�X�L�b�v��O�n���h�� ***
          WHEN global_data_check_skip_expt THEN
            gn_error_cnt := gn_error_cnt + 1;            -- �X�L�b�v�����J�E���g
            lv_retcode   := cv_status_error;
--
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which     => FND_FILE.OUTPUT
              ,buff      => lv_errmsg                   -- ���[�U�[�E�G���[���b�Z�[�W
            );
            -- ���O�o��
            fnd_file.put_line(
               which     => FND_FILE.LOG
              ,buff      => cv_pkg_name||cv_msg_cont||
                            cv_prg_name||cv_msg_part||
                            lv_errbuf                   -- �G���[���b�Z�[�W
            );
--
            gb_msg_already_out_flag := TRUE;            -- main�����ł̍ŏI�G���[���b�Z�[�W�͏o�͂��Ȃ�
--
        END;
      END LOOP get_sales_plan_data_loop;  -- �f�[�^���o�E�`�F�b�N���[�v�I��
--
    IF (gn_dt_chck_err_cnt = 0) THEN  -- A-4�EA-5�ł̏����ŃG���[������0���̏ꍇ
--
      -- ��������������
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 0;
      gn_warn_cnt   := 0;
--
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which     => FND_FILE.OUTPUT
        ,buff      => cv_debug_msg14 || CHR(10) ||
                      cv_debug_msg15 || CHR(10)      -- �f�[�^�`�F�b�N���튮�����b�Z�[�W
      );
--
      -- �t�@�C���f�[�^���o�E�o�^�E�X�V���[�v
      <<sales_plan_data_inup_loop>>
      FOR i IN g_sls_pln_data_tab.FIRST..g_sls_pln_data_tab.LAST LOOP      -- 1�s�ڂ̓o�[�W�����ԍ��Ńf�[�^�Ȃ��̂���
--
        BEGIN
--
          -- ���[�v�J�E���^�i�[
          g_rec_count := i;
--
          -- �Ώی����J�E���g
          gn_target_cnt := gn_target_cnt + 1;
--
          -- SAVEPOINT���s
          SAVEPOINT sls_pln;
--
          
          IF (g_sls_pln_data_tab(i).data_kind = cn_dt_knd_dpt) THEN
          -- A-6-1)�f�[�^��ʂ��u1:���_�v�̏ꍇ�A���_�ʌ��ʔ���v��̃f�[�^�擾�E�o�^�E�X�V
            -- =============================
            -- A-6.���_�ʌ��ʌv��f�[�^���o 
            -- =============================
            get_dept_month_data(
               on_dpt_mnth_pln_cnt  => ln_dpt_mnth_pln_cnt  -- ���o����
              ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W            -- # �Œ� #
              ,ov_retcode           => lv_sub_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
              ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              gb_sls_pln_inup_rollback_flag := TRUE;
              RAISE global_inupdel_data_error_expt;
            END IF;
--
            -- ===================================
            -- A-7.���_�ʌ��ʌv��f�[�^�o�^�E�X�V 
            -- ===================================
            inup_dept_month_data(
               in_dpt_mnth_pln_cnt  => ln_dpt_mnth_pln_cnt  -- ���o����
              ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W            -- # �Œ� #
              ,ov_retcode           => lv_sub_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
              ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              gb_sls_pln_inup_rollback_flag := TRUE;
              RAISE global_inupdel_data_error_expt;
            END IF;
--
          ELSIF (g_sls_pln_data_tab(i).data_kind = cn_dt_knd_prsn) THEN
          -- A-8)�f�[�^��ʂ��u2:�c�ƈ��v�̏ꍇ�A�c�ƈ��ʌ��ʌv��e�[�u���̓o�^�E�X�V�E�폜
            -- ===========================================
            -- A-8.�c�ƈ��ʌ��ʌv��f�[�^�o�^�E�X�V�E�폜 
            -- ===========================================
            inupdl_prsn_month_data(
               iv_base_value    => lv_base_value    -- ���Y�s�f�[�^
              /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� START */
              ,in_sls_pln_upld_cls_dy => TO_NUMBER(lv_sls_pln_upld_cls_dy)
                                                    -- ����v��A�b�v���[�h���c�Ɠ�
              /* 2010.02.22 K.Hosoi E_�{�ғ�_01679�Ή� END */
              ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
              ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
              ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
            );
            IF    (lv_sub_retcode IS NULL) THEN
              RAISE global_skip_expt;
            ELSIF (lv_sub_retcode = cv_status_error) THEN
              gb_sls_pln_inup_rollback_flag := TRUE;
              RAISE global_inupdel_data_error_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              gb_sls_pln_inup_rollback_flag := TRUE;
              RAISE global_inupdel_data_skip_expt;
            END IF;
          END IF;
--
          -- ���������J�E���g
          gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
          -- *** ���S�����X�L�b�v��O�n���h�� ***
          WHEN global_skip_expt THEN
            gn_target_cnt := gn_target_cnt - 1;         -- �Ώی������������܂��B
          
          WHEN global_inupdel_data_error_expt THEN
          -- *** �f�[�^�o�^�E�X�V�E�폜�G���[��O�n���h�� ***                 -- �G���[�I�����܂��B
            gn_error_cnt := gn_error_cnt + 1;           -- �G���[�����J�E���g
            lv_retcode   := cv_status_error;
--
            -- ���[���o�b�N
            IF gb_sls_pln_inup_rollback_flag = TRUE THEN
              ROLLBACK TO SAVEPOINT sls_pln;            -- ROLLBACK
              gb_sls_pln_inup_rollback_flag := FALSE;
              -- ���O�o��
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => CHR(10) ||cv_debug_msg13|| CHR(10)
              );
            END IF;
--
            RAISE global_process_expt;                  -- ���[�v�𔲂��ăt�@�C���f�[�^�폜������
--
          -- *** �f�[�^�o�^�E�X�V�E�폜�X�L�b�v��O�n���h�� ***
          WHEN global_inupdel_data_skip_expt THEN
            gn_warn_cnt  := gn_warn_cnt + 1;            -- �X�L�b�v�����J�E���g
            lv_retcode   := cv_status_normal;
--
            -- ���b�Z�[�W�o��
            fnd_file.put_line(
               which     => FND_FILE.OUTPUT
              ,buff      => lv_errmsg                   -- ���[�U�[�E�G���[���b�Z�[�W
            );
            fnd_file.put_line(
               which     => FND_FILE.LOG
              ,buff      => cv_pkg_name||cv_msg_cont||
                            cv_prg_name||cv_msg_part||
                            lv_errbuf                   -- �G���[���b�Z�[�W
            );
--
            -- ���[���o�b�N
            IF gb_sls_pln_inup_rollback_flag = TRUE THEN
              ROLLBACK TO SAVEPOINT sls_pln;            -- ROLLBACK
              gb_sls_pln_inup_rollback_flag := FALSE;
              IF (g_rec_count = g_sls_pln_data_tab.LAST) THEN
                -- ���O�o��
                fnd_file.put_line(
                   which  => FND_FILE.LOG
                  ,buff   => CHR(10) ||cv_debug_msg13|| CHR(10)
                );
              END IF;
            END IF;
--
          -- *** OTHERS��O�n���h�� ***                 -- �G���[�I�����܂��B
          WHEN OTHERS THEN
            gn_error_cnt := gn_error_cnt + 1;           -- �G���[�����J�E���g
            lv_retcode   := cv_status_error;
--
            -- ���[���o�b�N
            IF gb_sls_pln_inup_rollback_flag = TRUE THEN
              ROLLBACK TO SAVEPOINT sls_pln;            -- ROLLBACK
              gb_sls_pln_inup_rollback_flag := FALSE;
              -- ���O�o��
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => CHR(10) ||cv_debug_msg13|| CHR(10)
              );
            END IF;
--
            RAISE global_process_expt;                  -- ���[�v�𔲂��ăt�@�C���f�[�^�폜������
--
        END;
--
      END LOOP get_sales_plan_data_loop;
--
    ov_retcode := lv_retcode;              -- ���^�[���E�R�[�h
--
    ELSIF (gn_dt_chck_err_cnt >= 1) THEN   -- �G���[�`�F�b�N�J�E���^��1�ȏ�̏ꍇ�̓G���[�I��
     RAISE global_process_expt;
    END IF;
--
    -- =============================
    -- A-9.�t�@�C���f�[�^�폜���� 
    -- =============================
    delete_if_data(
       ov_errbuf        => lv_errbuf       -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode       => lv_retcode      -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg        => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
--
      RAISE global_process_expt;
    END IF;

--
  EXCEPTION
--
-- #################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
      
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W  -- # �Œ� #
    ,retcode       OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h    -- # �Œ� #
    ,in_file_id    IN         NUMBER            -- �t�@�C��ID
    ,in_fmt_ptn    IN         NUMBER            -- �t�H�[�}�b�g�p�^�[��
  )    
--
-- ###########################  �Œ蕔 START   ###########################
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
-- ###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
-- ###########################  �Œ蕔 END   #############################
--
    -- *** ���̓p�����[�^���Z�b�g
    gt_file_id := in_file_id;
    gv_fmt_ptn := in_fmt_ptn;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       IF (gb_msg_already_out_flag = FALSE) THEN
         --�G���[�o��
         fnd_file.put_line(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
         );
         fnd_file.put_line(
            which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --�G���[���b�Z�[�W
         );
       END IF;
    END IF;
--
    -- =======================
    -- A-10.�I������ 
    -- =======================
    -- ��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''               -- ��s
    );
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �I�����b�Z�[�W
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--
-- #################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END main;
--
END XXCSO001A04C;
/
