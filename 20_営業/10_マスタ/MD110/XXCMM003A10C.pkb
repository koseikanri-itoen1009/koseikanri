CREATE OR REPLACE PACKAGE BODY xxcmm003a10c
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : xxcmm003a10c(body)
 * Description     : ������q�`�F�b�N���X�g
 * MD.050          : MD050_CMM_003_A10_������q�`�F�b�N���X�g
 * MD.070          : MD050_CMM_003_A10_������q�`�F�b�N���X�g
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 * init              P         ������񒊏o����         (A-1)
 * chk_blance_amount P         ���|�c���`�F�b�N         (A-3)
 * get_inventory     P         ��݌ɐ��擾           (A-4)
 * make_worktable    P         ���[�N�e�[�u���f�[�^�o�^ (A-6)
 * run_svf_api       P         SVF�N������              (A-7)
 * termination       P         �I������                 (A-8)
 * submain           P         ���C�������v���V�[�W��
 * main              P         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- -------------- ------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- -------------- ------------------------------------
 *  2009-02-04    1.0  SCS K.Shirasuna  ����쐬
 *  2009-03-09    1.1  Yutaka.Kuboshima �t�@�C���o�͐�̃v���t�@�C���̍폜
 *                                      �����}�X�^�R�[�h�擾�̒��o������ύX
 *
 ************************************************************************/
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
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
  --===============================================================
  -- �O���[�o���萔
  --===============================================================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM003A10C';              -- �p�b�P�[�W��
  cv_appl_short_name        CONSTANT VARCHAR2(5)   := 'XXCMM';                     -- �A�v���P�[�V�����Z�k��
  cv_file_type_log          CONSTANT VARCHAR2(5)   := 'LOG';                       -- ���O�o��
  cv_customer_class_cust    CONSTANT VARCHAR2(2)   := '10';                        -- �ڋq�敪�F�ڋq
  cv_cust_status_mc_cand    CONSTANT VARCHAR2(2)   := '10';                        -- �ڋq�X�e�[�^�X�FMC���
  cv_cust_status_mc         CONSTANT VARCHAR2(2)   := '20';                        -- �ڋq�X�e�[�^�X�FMC
  cv_cust_status_sp_appr    CONSTANT VARCHAR2(2)   := '25';                        -- �ڋq�X�e�[�^�X�FSP���ٍ�
  cv_cust_status_stoped     CONSTANT VARCHAR2(2)   := '90';                        -- �ڋq�X�e�[�^�X�F���~���ٍ�
  cv_cust_status_except     CONSTANT VARCHAR2(2)   := '99';                        -- �ڋq�X�e�[�^�X�F�ΏۊO
  cv_business_htype_vd      CONSTANT VARCHAR2(2)   := '05';                        -- �Ƒ�(�啪��)�F�x���_�[
  cn_undeal_span_vd         CONSTANT NUMBER        := -1;                          -- ��������ԁF�x���_�[
  cn_undeal_span_not_vd     CONSTANT NUMBER        := -2;                          -- ��������ԁF�x���_�[�ȊO
  cv_lookup_cust_status     CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_KOKYAKU_STATUS'; -- �Q�ƕ\�F�ڋq�X�e�[�^�X
  cv_lookup_gyotai_sho      CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_SHO';     -- �Q�ƕ\�F�Ƒ�(������)
  cv_lookup_gyotai_chu      CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_CHU';     -- �Q�ƕ\�F�Ƒ�(������)
  cv_lookup_gyotai_dai      CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_DAI';     -- �Q�ƕ\�F�Ƒ�(�啪��)
  cv_flex_department        CONSTANT VARCHAR2(30)  := 'XX03_DEPARTMENT';           -- �l�Z�b�g���F����
-- 2009/03/09 modify start
--  cn_instance_stat_deleted  CONSTANT NUMBER        := 6;                           -- �C���X�^���X�X�e�[�^�XID�F�����폜��
  cv_instance_stat_deleted  CONSTANT VARCHAR2(30)  := '�����폜��';                -- �C���X�^���X�X�e�[�^�XID�F�����폜��
-- 2009/03/09 modify end
  cv_currency_jpy           CONSTANT VARCHAR2(3)   := 'JPY';                       -- �ʉ݃R�[�h�F���{�~
  cv_svf_output_mode_pdf    CONSTANT VARCHAR2(1)   := '1';                         -- SVF�o�͋敪�FPDF�o��
  cv_svf_form_name          CONSTANT VARCHAR2(20)  := 'XXCMM003A10S.xml';          -- �t�H�[���l���t�@�C����
  cv_svf_form_name_nodata   CONSTANT VARCHAR2(20)  := 'XXCMM003A10S2.xml';         -- �t�H�[���l���t�@�C����(0���p)
  cv_svf_query_name         CONSTANT VARCHAR2(20)  := 'XXCMM003A10S.vrq';          -- �N�G���[�l���t�@�C����
  cv_svf_param1             CONSTANT VARCHAR2(20)  := '[REQUEST_ID]=';             -- SVF�p�����[�^�p�F�v��ID
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';                         -- �t���O�iY�j
  cv_flag_n                 CONSTANT VARCHAR2(1)   := 'N';                         -- �t���O�iN�j
  cv_flag_c                 CONSTANT VARCHAR2(1)   := 'C';                         -- �t���O�iC�j
  cv_format_date_ymd        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                -- ���t�t�H�[�}�b�g�i�N�����j
  cv_format_date_ym         CONSTANT VARCHAR2(7)   := 'YYYY/MM';                   -- ���t�t�H�[�}�b�g�i�N���j
  cv_trunc_month            CONSTANT VARCHAR2(5)   := 'MONTH';                     -- TRUNC�֐��p
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_cmm_00002          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002'; -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_cmm_00047          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00047'; -- ��v����NULL�G���[
  cv_msg_cmm_00339          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00339'; -- ���[�N�e�[�u���o�^�G���[
  cv_msg_cmm_00340          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00340'; -- ���[�N�e�[�u���폜�G���[
  cv_msg_cmm_00001          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001'; -- �Ώۃf�[�^�Ȃ����O���b�Z�[�W
  cv_msg_cmm_00334          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00334'; -- ����0���p���b�Z�[�W
  cv_msg_cmm_00014          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00014'; -- API�ďo�G���[
--
  -- �g�[�N��
  cv_tkn_ng_profile         CONSTANT VARCHAR2(15)  := 'NG_PROFILE';                                  -- �G���[�v���t�@�C����
  cv_tkn_err_msg            CONSTANT VARCHAR2(15)  := 'ERR_MSG';                                     -- �G���[���b�Z�[�W
  cv_tkn_ng_api             CONSTANT VARCHAR2(15)  := 'API_NAME';                                    -- API����
  cv_tkn_ng_word            CONSTANT VARCHAR2(15)  := 'NG_WORD';                                     -- �G���[���[�h
  cv_tkn_ng_data            CONSTANT VARCHAR2(15)  := 'NG_DATA';                                     -- �G���[�f�[�^
  cv_tkn_set_of_bks         CONSTANT VARCHAR2(50)  := '��v����ID';                                  -- �v���t�@�C�����F��v����ID
  cv_tkn_account_cd         CONSTANT VARCHAR2(100) := '������q�`�F�b�N���X�g�p_����ȖڃR�[�h';     -- �v���t�@�C�����F����ȖڃR�[�h
  cv_tkn_resp_key           CONSTANT VARCHAR2(100) := '������q�`�F�b�N���X�g�p_���_�������E�ӃL�['; -- �v���t�@�C�����F����ȖڃR�[�h
  cv_tkn_period_sets_mn     CONSTANT VARCHAR2(100) := '�ڋq�A�h�I���@�\�p��v�J�����_��';            -- �v���t�@�C�����F�J�����_��
  cv_tkn_out_file_dir       CONSTANT VARCHAR2(100) := '������q�`�F�b�N���X�g�p_�t�@�C���o�͐�';     -- �v���t�@�C�����F�t�@�C���o�͐�
  cv_tkn_out_file_fil       CONSTANT VARCHAR2(100) := '������q�`�F�b�N���X�g�p_�t�@�C����';         -- �v���t�@�C�����F�t�@�C����
  cv_tkn_ng_base_cd         CONSTANT VARCHAR2(50)  := '���_�R�[�h';                                  -- ���b�Z�[�W�F���_�R�[�h
  cv_tkn_ng_cust_cd         CONSTANT VARCHAR2(50)  := '�ڋq�R�[�h';                                  -- ���b�Z�[�W�F�ڋq�R�[�h
  cv_tkn_ng_inst_cd         CONSTANT VARCHAR2(50)  := '�����R�[�h';                                  -- ���b�Z�[�W�F�����R�[�h
  cv_tkn_ng_req_id          CONSTANT VARCHAR2(50)  := '�v��ID';                                      -- ���b�Z�[�W�F�v��ID
  cv_tkn_ng_api_nm          CONSTANT VARCHAR2(50)  := 'SVF �N��';                                    -- API���FSVF�N���R���J�����g
--
  --�v���t�@�C����
  cv_prof_resp_id           CONSTANT VARCHAR2(50)  := 'RESP_ID';                         -- �E��ID
  cv_prof_set_of_bks_id     CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';                -- ��v����ID
  cv_prof_account_value_cd  CONSTANT VARCHAR2(50)  := 'XXCMM1_003A10_ACCOUNT_VALUE_CD';  -- ������q�`�F�b�N���X�g�p����ȖڃR�[�h
  cv_prof_domestic_resp_key CONSTANT VARCHAR2(50)  := 'XXCMM1_003A10_DOMESTIC_RESP_KEY'; -- ������q�`�F�b�N���X�g�p���_�������E�ӃL�[
  cv_prof_period_sets_mn    CONSTANT VARCHAR2(50)  := 'XXCMM1_003A00_GL_PERIOD_MN';      -- ������q�`�F�b�N���X�g�p�J�����_��
-- 2009/03/09 delete start
--  cv_prof_out_file_dir      CONSTANT VARCHAR2(50)  := 'XXCMM1_003A10_OUT_FILE_DIR';      -- ������q�`�F�b�N���X�g�p�t�@�C���o�͐�
-- 2009/03/09 delete end
  cv_prof_out_file_fil      CONSTANT VARCHAR2(50)  := 'XXCMM1_003A10_OUT_FILE_FIL';      -- ������q�`�F�b�N���X�g�p�t�@�C����
--
  --===============================================================
  -- �O���[�o���ϐ�
  --===============================================================
  gn_user_id                   NUMBER;                                              -- ���[�U�[ID
  gn_resp_id                   NUMBER;                                              -- �E��ID
  gt_responsibility_key        fnd_responsibility.responsibility_key%TYPE;          -- �E�ӃL�[
  gn_resp_appl_id              NUMBER;                                              -- �E�ӃA�v���P�[�V����ID
  gt_sale_base_code            per_all_assignments_f.ass_attribute3%TYPE;           -- ���_�R�[�h
  gn_set_of_bks_id             NUMBER;                                              -- ��v����ID
  gt_account_value_cd          fnd_profile_option_values.profile_option_value%TYPE; -- ����ȖڃR�[�h
  gt_domestic_resp_key         fnd_profile_option_values.profile_option_value%TYPE; -- ���_�������E�ӃL�[
  gt_period_sets_mn            fnd_profile_option_values.profile_option_value%TYPE; -- �J�����_��
-- 2009/03/09 delete start
--  gt_out_file_dir              fnd_profile_option_values.profile_option_value%TYPE; -- �t�@�C���o�͐�
-- 2009/03/09 delete end
  gt_out_file_fil              fnd_profile_option_values.profile_option_value%TYPE; -- �t�@�C����
  gd_process_date              DATE;                                                -- �Ɩ����t
  gt_p_customer_status_name    fnd_lookup_values.meaning%TYPE;                      -- �ڋq�X�e�[�^�X��(�p�����[�^)
  gt_p_sale_base_name          per_all_assignments_f.ass_attribute3%TYPE;           -- ���_��(�p�����[�^)
  gt_instance_number           csi_item_instances.instance_number%TYPE;             -- �����R�[�h�i�[�p
  gn_inventory_quantity_sum    NUMBER;                                              -- ��݌ɐ��i�[�p
  gt_period_name               gl_period_statuses.period_name%TYPE;                 -- ��v���Ԋi�[�p
  gt_balance_month             xxcmm_rep_undeal_list.balance_month%TYPE;            -- ���|�c�����x�i�[�p
  gn_balance_amount            NUMBER;                                              -- ���|�c���i�[�p
  gt_no_data_msg               xxcfo_rep_standard_po.data_empty_message%TYPE;       -- 0�����b�Z�[�W
  gv_svf_form_name             VARCHAR2(100);                                       -- �t�H�[���l���t�@�C����
--
  --===============================================================
  -- �O���[�o���e�[�u���^�C�v
  --===============================================================
--
  --===============================================================
  -- �O���[�o���e�[�u��
  --===============================================================
--
  --===============================================================
  -- �O���[�o���J�[�\��
  --===============================================================
--
  -- ������q��񒊏o�J�[�\��
  CURSOR undeal_cust_cur(
    iv_customer_status IN VARCHAR2  -- �ڋq�X�e�[�^�X
   ,iv_sale_base_code  IN VARCHAR2) -- ���_�R�[�h
  IS
    SELECT
           hca.cust_account_id                              cust_account_id         -- �ڋqID
          ,hca.account_number                               account_number          -- �ڋq�R�[�h
          ,hp.party_name                                    account_name            -- �ڋq����
          ,xcgd.lookup_code                                 business_high_type      -- �Ƒԕ���(�啪��)
          ,xcgd.meaning                                     business_high_type_name -- �Ƒԕ���(�啪��)��
          ,TO_CHAR(xca.final_call_date, cv_format_date_ymd) final_call_date         -- �ŏI�K���
          ,TO_CHAR(xca.final_tran_date, cv_format_date_ymd) final_tran_date         -- �ŏI�����
          ,xca.sale_base_code                               sale_base_code          -- ���_�R�[�h
          ,xdnm.sale_base_name                              sale_base_name          -- ���_��
          ,hp.duns_number_c                                 status                  -- �ڋq�X�e�[�^�X
          ,xcks.meaning                                     status_name             -- �ڋq�X�e�[�^�X��
          ,NVL(xca.change_amount,0)                         change_amount           -- �ޑK��z
    FROM
           hz_cust_accounts    hca                          -- �ڋq�}�X�^
          ,xxcmm_cust_accounts xca                          -- �ڋq�ǉ����}�X�^
          ,hz_parties          hp                           -- �p�[�e�B�}�X�^
          ,(SELECT
                   flv.lookup_code lookup_code              -- �Q�ƃR�[�h
                  ,flv.meaning     meaning                  -- ���e
            FROM
                   fnd_lookup_values flv
            WHERE
                   flv.language     = 'JA'
            AND    flv.lookup_type  = cv_lookup_cust_status
            AND    flv.enabled_flag = cv_flag_y) xcks       -- �Q�ƕ\�F�ڋq�X�e�[�^�X
          ,(SELECT
                   flv.lookup_code lookup_code              -- �Q�ƃR�[�h
                  ,flv.meaning     meaning                  -- ���e
                  ,flv.attribute1  attribute1               -- DFF1
            FROM
                   fnd_lookup_values flv
            WHERE
                   flv.language     = 'JA'
            AND    flv.lookup_type  = cv_lookup_gyotai_sho
            AND    flv.enabled_flag = cv_flag_y) xcgs       -- �Q�ƕ\�F�Ƒ�(������)
          ,(SELECT
                   flv.lookup_code lookup_code              -- �Q�ƃR�[�h
                  ,flv.meaning     meaning                  -- ���e
                  ,flv.attribute1  attribute1               -- DFF1
            FROM
                   fnd_lookup_values flv
            WHERE
                   flv.language     = 'JA'
            AND    flv.lookup_type  = cv_lookup_gyotai_chu
            AND    flv.enabled_flag = cv_flag_y) xcgc       -- �Q�ƕ\�F�Ƒ�(������)
          ,(SELECT
                   flv.lookup_code lookup_code              -- �Q�ƃR�[�h
                  ,flv.meaning     meaning                  -- ���e
            FROM
                   fnd_lookup_values flv
            WHERE
                   flv.language     = 'JA'
            AND    flv.lookup_type  = cv_lookup_gyotai_dai
            AND    flv.enabled_flag = cv_flag_y) xcgd       -- �Q�ƕ\�F�Ƒ�(�啪��)
          ,(SELECT
                   ffv.flex_value      sale_base_code       -- ���_�R�[�h
                  ,ffv.attribute4      sale_base_name       -- ���_��
            FROM
                   fnd_flex_value_sets ffvs                 -- �l�Z�b�g��`�}�X�^
                  ,fnd_flex_values     ffv                  -- �l�Z�b�g�l��`�}�X�^
            WHERE
                   ffvs.flex_value_set_id   = ffv.flex_value_set_id
            AND    ffv.enabled_flag         = cv_flag_y
            AND    ffv.summary_flag         = cv_flag_n
            AND    ffvs.flex_value_set_name = cv_flex_department) xdnm
                                                            -- �l�Z�b�g�F���_��
    WHERE
          hca.customer_class_code = cv_customer_class_cust
    AND   hca.cust_account_id     = xca.customer_id
    AND   hca.party_id            = hp.party_id
    AND   hp.duns_number_c        = xcks.lookup_code(+)
    AND   xcgs.attribute1         = xcgc.lookup_code
    AND   xcgc.attribute1         = xcgd.lookup_code
    AND   xcgs.lookup_code        = xca.business_low_type
    AND   xdnm.sale_base_code     = xca.sale_base_code
    AND   ((iv_customer_status IS NOT NULL
            AND hp.duns_number_c = iv_customer_status)
       OR  (iv_customer_status IS NULL
            AND (hp.duns_number_c NOT IN (cv_cust_status_mc_cand
                                         ,cv_cust_status_mc
                                         ,cv_cust_status_sp_appr
                                         ,cv_cust_status_stoped
                                         ,cv_cust_status_except)
               OR hp.duns_number_c IS NULL)))
    AND   ((iv_sale_base_code IS NOT NULL
            AND xca.sale_base_code = iv_sale_base_code)
       OR ((iv_sale_base_code IS NULL
            AND gt_responsibility_key  = gt_domestic_resp_key
            AND xca.sale_base_code     = gt_sale_base_code)
       OR  (iv_sale_base_code IS NULL
            AND gt_responsibility_key <> gt_domestic_resp_key)))
    AND   ((xcgd.lookup_code  = cv_business_htype_vd
            AND  (xca.final_tran_date < TRUNC(ADD_MONTHS(gd_process_date, cn_undeal_span_vd)
                                             ,cv_trunc_month)
               OR xca.final_tran_date IS NULL))
       OR  (xcgd.lookup_code <> cv_business_htype_vd
            AND  (xca.final_tran_date < TRUNC(ADD_MONTHS(gd_process_date, cn_undeal_span_not_vd)
                                             ,cv_trunc_month)
               OR xca.final_tran_date IS NULL)));
--
  -- �����R�[�h�擾�J�[�\��
-- 2009/03/09 modify start
--  CURSOR get_instance_cur(
--    in_cust_account_id IN NUMBER) -- �ڋqID
--  IS
--    SELECT
--           cii.external_reference install_code -- �����R�[�h
--    FROM
--           csi_item_instances cii              -- �����}�X�^
--    WHERE
--           cii.owner_party_account_id = in_cust_account_id
--    AND    cii.instance_status_id    <> cn_instance_stat_deleted;
  CURSOR get_instance_cur(
    in_cust_account_id IN NUMBER) -- �ڋqID
  IS
    SELECT
           cii.external_reference install_code -- �����R�[�h
    FROM
           csi_item_instances cii              -- �����}�X�^
    WHERE
           cii.owner_party_account_id = in_cust_account_id
    AND    NOT EXISTS (SELECT 'X'
                       FROM csi_instance_statuses cis
                       WHERE cis.name               = cv_instance_stat_deleted
                       AND   cii.instance_status_id = cis.instance_status_id);
-- 2009/03/09 modify end
--
  --===============================================================
  -- �O���[�o�����R�[�h�^�ϐ�
  --===============================================================
--
  --===============================================================
  -- �O���[�o����O
  --===============================================================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ������񒊏o����(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_cust_status             IN         VARCHAR2,     --   �ڋq�X�e�[�^�X
    iv_sale_base_code          IN         VARCHAR2,     --   ���_�R�[�h
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �R���J�����g�p�����[�^���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log             -- ���O�o��
      ,iv_conc_param1  => iv_cust_status               -- �ڋq�X�e�[�^�X
      ,iv_conc_param2  => iv_sale_base_code            -- ���_�R�[�h
      ,ov_errbuf       => lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���[�U�[ID���擾
    gn_user_id      := fnd_global.user_id;
--
    -- �v���t�@�C���F�E�ӃA�v���P�[�V����ID���擾
    gn_resp_appl_id := fnd_global.resp_appl_id;
--
    -- �v���t�@�C���F�E��ID���擾
    gn_resp_id      := fnd_profile.value(cv_prof_resp_id);
--
    -- �Ɩ����t�擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- ���O�C�����[�U�̐E�ӃL�[�擾
    SELECT
           fr.responsibility_key                             -- �E�ӃL�[
    INTO
           gt_responsibility_key                             -- �E�ӃL�[
    FROM
           fnd_responsibility fr                             -- �E�Ӄ}�X�^
    WHERE
           fr.responsibility_id = gn_resp_id
    AND    fr.application_id    = gn_resp_appl_id;           -- �E�ӃA�v���P�[�V����ID
--
    -- ���_�R�[�h�擾
    SELECT
           paaf.ass_attribute5 -- �����R�[�h(�V)
    INTO
           gt_sale_base_code   -- ���_�R�[�h
    FROM
           per_all_people_f      papf -- �]�ƈ��}�X�^
          ,per_all_assignments_f paaf -- �A�T�C�����g�}�X�^
          ,fnd_user              fu   -- ���[�U�[�}�X�^
    WHERE
           fu.user_id           = gn_user_id
    AND    fu.employee_id       = papf.person_id
    AND    papf.person_id       = paaf.person_id
    AND    TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date)
                              AND TRUNC(papf.effective_end_date)
    AND    TRUNC(SYSDATE) BETWEEN TRUNC(paaf.effective_start_date)
                              AND TRUNC(paaf.effective_end_date);
--
    -- �v���t�@�C�������v����ID�擾
    gn_set_of_bks_id    := TO_NUMBER(fnd_profile.value(cv_prof_set_of_bks_id));
--
    -- �v���t�@�C�����擾�ł��Ȃ�������G���[
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00002
                    ,iv_token_name1  => cv_tkn_ng_profile
                    ,iv_token_value1 => cv_tkn_set_of_bks
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- �v���t�@�C�����犨��ȖڃR�[�h�擾
    gt_account_value_cd := fnd_profile.value(cv_prof_account_value_cd);
--
    -- �v���t�@�C�����擾�ł��Ȃ�������G���[
    IF (gt_account_value_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00002
                    ,iv_token_name1  => cv_tkn_ng_profile
                    ,iv_token_value1 => cv_tkn_account_cd
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- �v���t�@�C�����狒�_�������E�ӃL�[�擾
    gt_domestic_resp_key := fnd_profile.value(cv_prof_domestic_resp_key);
--
    -- �v���t�@�C�����擾�ł��Ȃ�������G���[
    IF (gt_domestic_resp_key IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00002
                    ,iv_token_name1  => cv_tkn_ng_profile
                    ,iv_token_value1 => cv_tkn_resp_key
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- �v���t�@�C������J�����_���擾
    gt_period_sets_mn   := fnd_profile.value(cv_prof_period_sets_mn);
--
    -- �v���t�@�C�����擾�ł��Ȃ�������G���[
    IF (gt_period_sets_mn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00002
                    ,iv_token_name1  => cv_tkn_ng_profile
                    ,iv_token_value1 => cv_tkn_period_sets_mn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
-- 2009/03/09 delete start
    -- �v���t�@�C������t�@�C���o�͐�擾
--    gt_out_file_dir     := fnd_profile.value(cv_prof_out_file_dir);
--
    -- �v���t�@�C�����擾�ł��Ȃ�������G���[
--    IF (gt_out_file_dir IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_msg_cmm_00002
--                    ,iv_token_name1  => cv_tkn_ng_profile
--                    ,iv_token_value1 => cv_tkn_out_file_dir
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
    --
-- 2009/03/09 delete end
    -- �v���t�@�C������t�@�C�����擾
    gt_out_file_fil     := fnd_profile.value(cv_prof_out_file_fil);
--
    -- �v���t�@�C�����擾�ł��Ȃ�������G���[
    IF (gt_out_file_fil IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00002
                    ,iv_token_name1  => cv_tkn_ng_profile
                    ,iv_token_value1 => cv_tkn_out_file_fil
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (iv_cust_status IS NOT NULL) THEN
      -- �p�����[�^�F�ڋq�X�e�[�^�X���擾
      SELECT
             MAX(flv.meaning) meaning            -- �ڋq�X�e�[�^�X����MAX�̓G���[�ŗ����Ȃ��悤��
      INTO
             gt_p_customer_status_name           -- �ڋq�X�e�[�^�X��
      FROM
             fnd_lookup_values flv
      WHERE
             flv.language     = 'JA'
      AND    flv.lookup_type  = cv_lookup_cust_status
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.lookup_code  = iv_cust_status;
    END IF;
--
    IF (iv_sale_base_code IS NOT NULL) THEN
      -- �p�����[�^�F���_���擾
      SELECT
             MAX(ffv.attribute4) sale_base_name  -- ���_����MAX�̓G���[�ŗ����Ȃ��悤��
      INTO
             gt_p_sale_base_name                 -- ���_��
      FROM
             fnd_flex_value_sets ffvs            -- �l�Z�b�g��`�}�X�^
            ,fnd_flex_values     ffv             -- �l�Z�b�g�l��`�}�X�^
      WHERE
             ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffv.enabled_flag         = cv_flag_y
      AND    ffv.summary_flag         = cv_flag_n
      AND    ffvs.flex_value_set_name = cv_flex_department
      AND    ffv.flex_value           = iv_sale_base_code;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐��G���[������ ***
    WHEN global_api_expt THEN
      -- �R���J�����g�o�͂�PDF�̂��ߑΏۊO
--      ov_errmsg  := lv_errbuf;
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
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
   * Procedure Name   : chk_blance_amount
   * Description      : ���|�c���`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_blance_amount(
    in_cust_account_id         IN         VARCHAR2,     --   �ڋqID
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_blance_amount'; -- �v���O������
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
    -- �����ŐV�̉�v���Ԏ擾
    BEGIN
      SELECT
             period_name      -- ��v����
            ,balance_month    -- ���|�c�����x
      INTO
             gt_period_name   -- ��v����
            ,gt_balance_month -- ���|�c�����x
      FROM
            (SELECT
                    gps.period_name                            period_name   -- ��v����
                   ,TO_CHAR(gps.start_date, cv_format_date_ym) balance_month -- ���|�c�����x
             FROM
                    gl_periods         gp            -- ��v���ԃ}�X�^
                   ,gl_period_statuses gps           -- ��v���ԃX�e�[�^�X
             WHERE
                    gp.period_name            = gps.period_name
             AND    gp.period_set_name        = gt_period_sets_mn
             AND    gps.application_id        = gn_resp_appl_id
             AND    gps.set_of_books_id       = gn_set_of_bks_id
             AND    gp.adjustment_period_flag = cv_flag_n
             AND    gps.closing_status        = cv_flag_c
             ORDER BY
                    gps.start_date DESC)
      WHERE ROWNUM = 1;
--
      -- ��v���Ԃ�NULL�������ꍇ�G���[
      IF (gt_period_name IS NULL) THEN
        RAISE NO_DATA_FOUND;
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ��v����NULL�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_msg_cmm_00047
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ���|�c���擾
    BEGIN
      SELECT
             SUM((NVL(jzab.begin_bal_entered_dr, 0) -  -- �����c��(�ؕ�)
                  NVL(jzab.begin_bal_entered_cr, 0)) + -- �����c��(�ݕ�)
                 (NVL(jzab.period_net_entered_dr, 0) - -- ���������݌v�z(�ؕ�)
                  NVL(jzab.period_net_entered_cr, 0))) -- ���������݌v�z(�ݕ�)
                                                       -- ���|�c��
      INTO
             gn_balance_amount           -- ���|�c��
      FROM
             jg_zz_ar_balances_v  jzab   -- JG�ڋq�c��
            ,gl_code_combinations gcc    -- ����Ȗڑg�����}�X�^
      WHERE
             jzab.posted_to_gl_flag   = cv_flag_y
      AND    jzab.set_of_books_id     = gn_set_of_bks_id
      AND    jzab.currency_code       = cv_currency_jpy
      AND    jzab.customer_id         = in_cust_account_id
      AND    jzab.code_combination_id = gcc.code_combination_id
      AND    jzab.period_name         = gt_period_name
      AND    gcc.enabled_flag         = cv_flag_y
      AND    gcc.segment3             = gt_account_value_cd
      GROUP BY
             jzab.customer_id;
    EXCEPTION
      -- �Ώۃf�[�^�����F����
      WHEN NO_DATA_FOUND THEN
        gn_balance_amount := NULL;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �R���J�����g�o�͂�PDF�̂��ߑΏۊO
--      ov_errmsg  := lv_errbuf;
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
  END chk_blance_amount;
--
--#####################################  �Œ蕔 END   ##########################################
--
  /**********************************************************************************
   * Procedure Name   : get_inventory
   * Description      : ��݌ɐ��擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_inventory(
    in_cust_account_id         IN         VARCHAR2,     --   �ڋqID
    on_inventory_quantity_sum  OUT        NUMBER,       --   ��݌ɐ�
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inventory'; -- �v���O������
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
    SELECT
           SUM(NVL(xmvc.inventory_quantity, 0)) inventory_quantity -- ��݌ɐ�
    INTO
           on_inventory_quantity_sum                               -- ��݌ɐ�
    FROM
           xxcoi_mst_vd_column xmvc                                -- �u�c�R�����}�X�^
    WHERE
           xmvc.customer_id = in_cust_account_id
    GROUP BY
           xmvc.customer_id;
--
  EXCEPTION
    -- �Ώۃf�[�^�����F����
    WHEN NO_DATA_FOUND THEN
      on_inventory_quantity_sum := NULL;
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
  END get_inventory;
--
  /**********************************************************************************
   * Procedure Name   : make_worktable
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-6)
   ***********************************************************************************/
  PROCEDURE make_worktable(
    iv_sale_base_code          IN         VARCHAR2,     --   ���_�R�[�h
    iv_sale_base_name          IN         VARCHAR2,     --   ���_��
    iv_account_number          IN         VARCHAR2,     --   �ڋq�R�[�h
    iv_account_name            IN         VARCHAR2,     --   �ڋq��
    iv_status                  IN         VARCHAR2,     --   �ڋq�X�e�[�^�X
    iv_status_name             IN         VARCHAR2,     --   �ڋq�X�e�[�^�X��
    iv_business_high_type      IN         VARCHAR2,     --   �Ƒԕ��ށi�啪�ށj
    iv_business_high_type_name IN         VARCHAR2,     --   �Ƒԕ��ށi�啪�ށj��
    iv_final_call_date         IN         VARCHAR2,     --   �ŏI�K���
    iv_final_tran_date         IN         VARCHAR2,     --   �ŏI�����
    iv_instance_number         IN         VARCHAR2,     --   �����R�[�h
    in_inventory_quantity_sum  IN         NUMBER,       --   ��݌ɐ�
    in_change_amount           IN         NUMBER,       --   �ޑK��z
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_worktable'; -- �v���O������
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
      INSERT INTO xxcmm_rep_undeal_list xrul( -- ������q�`�F�b�N���X�g���[�N
        request_id              -- �v��ID
       ,p_customer_status_name  -- �ڋq�X�e�[�^�X��(�p�����[�^)
       ,p_base_cd_name          -- ���_��(�p�����[�^)
       ,base_code               -- ���_�R�[�h
       ,base_cd_name            -- ���_��
       ,customer_code           -- �ڋq�R�[�h
       ,customer_name           -- �ڋq��
       ,customer_status         -- �ڋq�X�e�[�^�X
       ,customer_status_name    -- �ڋq�X�e�[�^�X��
       ,business_high_type      -- �Ƒԕ��ށi�啪�ށj
       ,business_high_type_name -- �Ƒԕ��ށi�啪�ށj��
       ,final_call_date         -- �ŏI�K���
       ,final_tran_date         -- �ŏI�����
       ,install_code            -- �����R�[�h
       ,inventory_quantity      -- �݌�
       ,change_amount           -- �ޑK��z
       ,balance_amount          -- ���|�c��
       ,balance_month           -- ���|�c�����x
       ,undeal_reason           -- ��������R
       ,stop_approval_reason    -- ���~���R
       ,created_by              -- �쐬��
       ,creation_date           -- �쐬��
       ,last_updated_by         -- �ŏI�X�V��
       ,last_update_date        -- �ŏI�X�V��
       ,last_update_login       -- �ŏI�X�V۸޲�
       ,program_application_id  -- �ݶ��ĥ��۸��ѥ���ع����ID
       ,program_id              -- �ݶ��ĥ��۸���ID
       ,program_update_date     -- ��۸��эX�V��
      ) VALUES (
        cn_request_id                             -- �v��ID
       ,gt_p_customer_status_name                 -- �ڋq�X�e�[�^�X��(�p�����[�^)
       ,gt_p_sale_base_name                       -- ���_��(�p�����[�^)
       ,iv_sale_base_code                         -- ���_�R�[�h
       ,iv_sale_base_name                         -- ���_��
       ,iv_account_number                         -- �ڋq�R�[�h
       ,iv_account_name                           -- �ڋq��
       ,iv_status                                 -- �ڋq�X�e�[�^�X
       ,iv_status_name                            -- �ڋq�X�e�[�^�X��
       ,iv_business_high_type                     -- �Ƒԕ��ށi�啪�ށj
       ,iv_business_high_type_name                -- �Ƒԕ��ށi�啪�ށj��
       ,iv_final_call_date                        -- �ŏI�K���
       ,iv_final_tran_date                        -- �ŏI�����
       ,iv_instance_number                        -- �����R�[�h
       ,in_inventory_quantity_sum                 -- �݌�
       ,in_change_amount                          -- �ޑK��z
       ,gn_balance_amount                         -- ���|�c��
       ,gt_balance_month                          -- ���|�c�����x
       ,NULL                                      -- ��������R
       ,NULL                                      -- ���~���R
       ,cn_created_by                             -- �쐬��
       ,cd_creation_date                          -- �쐬��
       ,cn_last_updated_by                        -- �ŏI�X�V��
       ,cd_last_update_date                       -- �ŏI�X�V��
       ,cn_last_update_login                      -- �ŏI�X�V۸޲�
       ,cn_program_application_id                 -- �ݶ��ĥ��۸��ѥ���ع����ID
       ,cn_program_id                             -- �ݶ��ĥ��۸���ID
       ,cd_program_update_date);                  -- ��۸��эX�V��
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_msg_cmm_00339
                      ,iv_token_name1  => cv_tkn_err_msg
                      ,iv_token_value1 => cv_tkn_ng_base_cd || cv_msg_part || iv_sale_base_code || cv_msg_pnt ||
                                          cv_tkn_ng_cust_cd || cv_msg_part || iv_account_number || cv_msg_pnt ||
                                          cv_tkn_ng_inst_cd || cv_msg_part || iv_instance_number || cv_msg_pnt ||
                                          cv_tkn_ng_req_id || cv_msg_part || cn_request_id || cv_msg_pnt ||
                                          SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �����Ώی������Z
    gn_target_cnt := gn_target_cnt + 1;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �R���J�����g�o�͂�PDF�̂��ߑΏۊO
--      ov_errmsg  := lv_errbuf;
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
  END make_worktable;
--
  /**********************************************************************************
   * Procedure Name   : run_svf_api
   * Description      : SVF�N������ (A-7)
   ***********************************************************************************/
  PROCEDURE run_svf_api(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'run_svf_api'; -- �v���O������
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
    lv_svf_param1 VARCHAR2(50); -- SVF�p�����[�^�F�v��ID�i�[�p
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
    -- �p�����[�^�F�v��ID�̐ݒ�
    lv_svf_param1    := cv_svf_param1 || cn_request_id;
--
    -- �t�@�C�����ҏW
    gt_out_file_fil  := gt_out_file_fil ||
                        TO_CHAR(cd_creation_date, 'YYYYMMDD') ||
                        TO_CHAR(cn_request_id);
--
    IF (gn_target_cnt = 0) THEN
    -- �Ώۃf�[�^0���̏ꍇ
--
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
--
      -- 0�����b�Z�[�W�����O�ɏo��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_msg_cmm_00001
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
--
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
--
      -- 0���t�H�[���l���t�@�C�����ݒ�
      gv_svf_form_name := cv_svf_form_name_nodata;
--
    ELSE
    -- �Ώۃf�[�^���������ꍇ
      gv_svf_form_name := cv_svf_form_name;
    END IF;
--
    -- ���[0�����b�Z�[�W�擾
    gt_no_data_msg := xxccp_common_pkg.get_msg(
                        cv_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,cv_msg_cmm_00334   -- ����0���p���b�Z�[�W
                      );
--
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_conc_name    => cv_pkg_name            -- �R���J�����g��
     ,iv_file_name    => gt_out_file_fil        -- �o�̓t�@�C����
     ,iv_file_id      => cv_pkg_name            -- ���[ID
     ,iv_output_mode  => cv_svf_output_mode_pdf -- �o�͋敪(=1�FPDF�o�́j
     ,iv_frm_file     => gv_svf_form_name       -- �t�H�[���l���t�@�C����
     ,iv_vrq_file     => cv_svf_query_name      -- �N�G���[�l���t�@�C����
     ,iv_org_id       => NULL                   -- ORG_ID
     ,iv_user_name    => gn_user_id             -- ���O�C���E���[�U��
     ,iv_resp_name    => gt_responsibility_key  -- ���O�C���E���[�U�̐E�Ӗ�
     ,iv_doc_name     => NULL                   -- ������
     ,iv_printer_name => NULL                   -- �v�����^��
     ,iv_request_id   => cn_request_id          -- �v��ID
     ,iv_nodata_msg   => gt_no_data_msg         -- �f�[�^�Ȃ����b�Z�[�W
     ,iv_svf_param1   => lv_svf_param1          -- svf�σp�����[�^1�F�v��ID
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00014
                    ,iv_token_name1  => cv_tkn_ng_api
                    ,iv_token_value1 => cv_tkn_ng_api_nm
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_tkn_ng_req_id
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => cn_request_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �R���J�����g�o�͂�PDF�̂��ߑΏۊO
--      ov_errmsg  := lv_errbuf;
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
  END run_svf_api;
--
  /**********************************************************************************
   * Procedure Name   : termination
   * Description      : �I������(A-8)
   ***********************************************************************************/
  PROCEDURE termination(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'termination'; -- �v���O������
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
    -- ������q�`�F�b�N���X�g���[�N�폜
    BEGIN
      DELETE FROM xxcmm_rep_undeal_list xrul
      WHERE xrul.request_id = cn_request_id;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_cmm_00340
                    ,iv_token_name1  => cv_tkn_err_msg
                    ,iv_token_value1 => cv_tkn_ng_req_id || cv_msg_part || cn_request_id
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �R���J�����g�o�͂�PDF�̂��ߑΏۊO
--      ov_errmsg  := lv_errbuf;
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
  END termination;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_cust_status             IN         VARCHAR2,     --   �ڋq�X�e�[�^�X
    iv_sale_base_code          IN         VARCHAR2,     --   ���_�R�[�h
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_get_instance_cur_cnt NUMBER DEFAULT 0; -- �����R�[�h�擾�J�[�\�������i�[�p
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt          := 0;     -- �Ώی���
    gn_normal_cnt          := 0;     -- ���팏��
    gn_error_cnt           := 0;     -- �G���[����
--
    -- =====================================================
    --  ������񒊏o����(A-1)
    -- =====================================================
    init(
       iv_cust_status                     -- �ڋq�X�e�[�^�X
      ,iv_sale_base_code                  -- ���_�R�[�h
      ,lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ������q��񒊏o(A-2)
    -- =====================================================
    <<undeal_cust_loop>>
    FOR l_undeal_cust_rec IN undeal_cust_cur(
      iv_cust_status     -- �ڋq�X�e�[�^�X
     ,iv_sale_base_code) -- ���_�R�[�h
    LOOP
--
      -- =====================================================
      -- ���|�c���`�F�b�N(A-3)
      -- =====================================================
      chk_blance_amount(
        l_undeal_cust_rec.cust_account_id  -- �ڋqID
       ,lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
      -- �Ƒ�(�啪��)���x���_�[�̏ꍇ
      IF (l_undeal_cust_rec.business_high_type = cv_business_htype_vd) THEN
--
        -- =====================================================
        -- ��݌ɐ��擾(A-4)
        -- =====================================================
        get_inventory(
          l_undeal_cust_rec.cust_account_id  -- �ڋqID
         ,gn_inventory_quantity_sum          -- ��݌ɐ�
         ,lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
        -- =====================================================
        -- �����R�[�h�擾(A-5)
        -- =====================================================
        -- �����R�[�h�J�[�\������������
        ln_get_instance_cur_cnt := 0;
--
        <<get_instance_loop>>
        FOR l_get_instance_rec IN get_instance_cur(l_undeal_cust_rec.cust_account_id) LOOP
--
          -- =====================================================
          -- ���[�N�e�[�u���f�[�^�o�^(A-6)
          -- =====================================================
          make_worktable(
            l_undeal_cust_rec.sale_base_code          -- ���_�R�[�h
           ,l_undeal_cust_rec.sale_base_name          -- ���_��
           ,l_undeal_cust_rec.account_number          -- �ڋq�R�[�h
           ,l_undeal_cust_rec.account_name            -- �ڋq��
           ,l_undeal_cust_rec.status                  -- �ڋq�X�e�[�^�X
           ,l_undeal_cust_rec.status_name             -- �ڋq�X�e�[�^�X��
           ,l_undeal_cust_rec.business_high_type      -- �Ƒԕ��ށi�啪�ށj
           ,l_undeal_cust_rec.business_high_type_name -- �Ƒԕ��ށi�啪�ށj��
           ,l_undeal_cust_rec.final_call_date         -- �ŏI�K���
           ,l_undeal_cust_rec.final_tran_date         -- �ŏI�����
           ,NVL(l_get_instance_rec.install_code, 0)   -- �����R�[�h
           ,NVL(gn_inventory_quantity_sum, 0)         -- �݌�
           ,l_undeal_cust_rec.change_amount           -- �ޑK��z
           ,lv_errbuf                                 -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode                                -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          ln_get_instance_cur_cnt := get_instance_cur%ROWCOUNT;
--
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
          END IF;
--
        END LOOP get_instance_loop;
--
      END IF;
      -- �Ƒ�(�啪��)���x���_�[�ȊO�̏ꍇ
      IF ((l_undeal_cust_rec.business_high_type <> cv_business_htype_vd)
        OR ((l_undeal_cust_rec.business_high_type = cv_business_htype_vd)
            AND (ln_get_instance_cur_cnt = 0)))
      THEN
--
        -- =====================================================
        -- ���[�N�e�[�u���f�[�^�o�^(A-6)
        -- =====================================================
        make_worktable(
          l_undeal_cust_rec.sale_base_code          -- ���_�R�[�h
         ,l_undeal_cust_rec.sale_base_name          -- ���_��
         ,l_undeal_cust_rec.account_number          -- �ڋq�R�[�h
         ,l_undeal_cust_rec.account_name            -- �ڋq��
         ,l_undeal_cust_rec.status                  -- �ڋq�X�e�[�^�X
         ,l_undeal_cust_rec.status_name             -- �ڋq�X�e�[�^�X��
         ,l_undeal_cust_rec.business_high_type      -- �Ƒԕ��ށi�啪�ށj
         ,l_undeal_cust_rec.business_high_type_name -- �Ƒԕ��ށi�啪�ށj��
         ,l_undeal_cust_rec.final_call_date         -- �ŏI�K���
         ,l_undeal_cust_rec.final_tran_date         -- �ŏI�����
         ,NULL                                      -- �����R�[�h
         ,NULL                                      -- �݌�
         ,NULL                                      -- �ޑK��z
         ,lv_errbuf                                 -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode                                -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END LOOP undeal_cust_loop;
--
    -- =====================================================
    --  SVF�R���J�����g�N��(A-7)
    -- =====================================================
    run_svf_api(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �I������(A-8)
    -- =====================================================
    termination(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- �x���I��
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �R���J�����g�o�͂�PDF�̂��ߑΏۊO
--      ov_errmsg  := lv_errbuf;
      ov_errbuf  := SUBSTRB(lv_errbuf,1,5000);
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
    errbuf                     OUT NOCOPY VARCHAR2,         --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                    OUT NOCOPY VARCHAR2,         --    �G���[�R�[�h        --# �Œ� #
    iv_cust_status             IN         VARCHAR2,         --    �ڋq�X�e�[�^�X
    iv_sale_base_code          IN         VARCHAR2          --    ���_�R�[�h
  )
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCMM';            -- �A�h�I���F�}�X�^
    cv_cpp_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg     CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token           CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
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
       iv_which   => cv_file_type_log
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
       iv_cust_status                     -- �ڋq�X�e�[�^�X
      ,iv_sale_base_code                  -- ���_�R�[�h
      ,lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- =====================================================
    --  �I������(A-8)
    -- =====================================================
    -- �G���[�̏ꍇ�A�G���[����������������ݒ肷��
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;          -- �Ώی���
      gn_normal_cnt := 0;          -- ��������
      gn_error_cnt  := 1;          -- �G���[����
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    ELSE
      gn_normal_cnt := gn_target_cnt;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_cpp_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_cpp_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_cpp_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_cpp_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�G���[�̏ꍇ
    IF (lv_retcode = cv_status_error) THEN
      --�G���[���b�Z�[�W
      errbuf  := lv_errbuf;
      --�X�e�[�^�X�Z�b�g
      retcode := lv_retcode;
      ROLLBACK;
    END IF;
--
--###########################  �Œ蕔 START   #####################################################
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
END xxcmm003a10c;
/
