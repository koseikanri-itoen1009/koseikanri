CREATE OR REPLACE PACKAGE BODY XXCSO010A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO010A05C (body)
 * Description      : �_�񏑊m���CSV�o��
 * MD.050           : �_�񏑊m���CSV�o�� (MD050_CSO_010A05)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  output_csv             CSV�t�@�C���o��(A-5)
 *  get_contract_data1     �_�񏑏��̎擾�y�V�K�z(A-2)
 *  get_contract_data2     �_�񏑏��̎擾�y�����ύX�z(A-3)
 *  get_contract_data3     �_�񏑏��̎擾�y�m��ρz(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/08/06    1.0   S.Niki           main�V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
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
  init_err_expt               EXCEPTION;      -- ���������G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCSO010A05C';              -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcso          CONSTANT VARCHAR2(10)  := 'XXCSO';                     -- XXCSO
  -- ���t����
  cv_format_fmt1              CONSTANT VARCHAR2(50)  := 'YYYYMMDD';
  cv_format_fmt2              CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD HH24:MI:SS';
  --
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                         -- �����񊇂�
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- �J���}
  -- ���b�Z�[�W�R�[�h
  cv_msg_cso_00011            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00011';          -- �Ɩ��������t�擾�G���[
  cv_msg_cso_00640            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00640';          -- ���㋒�_
  cv_msg_cso_00641            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00641';          -- �_���
  cv_msg_cso_00642            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00642';          -- ���o�Ώۓ�(FROM)
  cv_msg_cso_00643            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00643';          -- ���o�Ώۓ�(TO)
  cv_msg_cso_00644            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00644';          -- ���o�Ώۓ����ԑ召�`�F�b�N�G���[
  cv_msg_cso_00645            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00645';          -- �_�񏑊m���CSV�w�b�_
--
  -- �g�[�N��
  cv_tkn_base_code            CONSTANT VARCHAR2(20)  := 'BASE_CODE';                 -- ���㋒�_
  cv_tkn_status               CONSTANT VARCHAR2(20)  := 'STATUS';                    -- �_���
  cv_tkn_date_from            CONSTANT VARCHAR2(20)  := 'DATE_FROM';                 -- ���o�Ώۓ�(FROM)
  cv_tkn_date_to              CONSTANT VARCHAR2(20)  := 'DATE_TO';                   -- ���o�Ώۓ�(TO)
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- ����
  cv_tkn_val_process_date     CONSTANT VARCHAR2(50)  := '�Ɩ��������t';
  cv_tkn_val_date_from        CONSTANT VARCHAR2(50)  := '���o�Ώۓ��iFROM�j';
  cv_tkn_val_date_to          CONSTANT VARCHAR2(50)  := '���o�Ώۓ��iTO�j';
--
  -- �Q�ƃ^�C�v��
  cv_lookup_type_01           CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_SHO';     -- �Ƒԏ�����
  cv_lookup_type_02           CONSTANT VARCHAR2(30)  := 'XXCSO1_010A05_CSV_HEADER';  -- �_�񏑊m���CSV�w�b�_
  cv_lookup_type_03           CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_KOKYAKU_STATUS'; -- �ڋq�X�e�[�^�X
  cv_lookup_type_04           CONSTANT VARCHAR2(30)  := 'XXCSO1_CONTRACT_STATUS';    -- �_��X�e�[�^�X
  cv_lookup_type_05           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_STATUS_CD';       -- SP�ꌈ�X�e�[�^�X
--
  -- �l�Z�b�g��
  cv_flex_value_01            CONSTANT VARCHAR2(30)  := 'XXCSO1_CONTRACT_STATUS';    -- �_���
--
  cv_flag_yes                 CONSTANT VARCHAR2(1)   := 'Y';                         -- �L��
  cv_language_ja              CONSTANT VARCHAR2(2)  := 'JA';                         -- ���{��
  -- �p�����[�^
  cv_para_status_1            CONSTANT VARCHAR2(1)   := '1';                         -- ���m��
  cv_para_status_2            CONSTANT VARCHAR2(1)   := '2';                         -- �m���
  --
  cv_output_log               CONSTANT VARCHAR2(3)   := 'LOG';
  --
  -- �敪
  cv_rec_kbn_1                CONSTANT VARCHAR2(10)  := '�V�K';                      -- �敪�F�V�K
  cv_rec_kbn_2                CONSTANT VARCHAR2(10)  := '�����ύX';                  -- �敪�F�����ύX
  cv_rec_kbn_3                CONSTANT VARCHAR2(10)  := '�m���';                    -- �敪�F�m���
  -- SP�ꌈ�w�b�_�e�[�u��
  cv_sp_dec_status_3          CONSTANT xxcso_sp_decision_headers.status%TYPE                   := '3';  -- SP�ꌈ���F�ς�
  -- SP�ꌈ�ڋq�e�[�u��
  cv_sp_dec_cust_class_1      CONSTANT xxcso_sp_decision_custs.sp_decision_customer_class%TYPE := '1';  -- �ݒu��ڋq
  -- �_��Ǘ��e�[�u��
  cv_cooperate_flag_1         CONSTANT xxcso_contract_managements.cooperate_flag%TYPE          := '1';  -- �A�g�ς�
  cv_cont_mng_status_0        CONSTANT xxcso_contract_managements.status%TYPE                  := '0';  -- �쐬��
  cv_cont_mng_status_1        CONSTANT xxcso_contract_managements.status%TYPE                  := '1';  -- �m���
  cv_cont_mng_status_9        CONSTANT xxcso_contract_managements.status%TYPE                  := '9';  -- �����
  -- �ڋq�ǉ����
  cv_stop_app_reason_9        CONSTANT xxcmm_cust_accounts.stop_approval_reason%TYPE           := '9';  -- ���~���R(��d�o�^)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �_��f�[�^�i�[�p�ϐ�
  TYPE g_rec_contract_data IS RECORD
    (
      rec_kbn                 VARCHAR2(10)                                            -- �敪
    , cust_code               hz_cust_accounts.account_number%TYPE                    -- �ڋq�R�[�h
    , cust_name               hz_parties.party_name%TYPE                              -- �ڋq��
    , cust_status             VARCHAR2(2)                                             -- �ڋq�X�e�[�^�X
    , cust_status_name        VARCHAR2(20)                                            -- �ڋq�X�e�[�^�X��
    , gyotai_sho              VARCHAR2(2)                                             -- �Ƒԏ�����
    , gyotai_sho_name         fnd_lookup_values_vl.meaning%TYPE                       -- �Ƒԏ����ޖ�
    , sale_base_code          xxcmm_cust_accounts.sale_base_code%TYPE                 -- ���㋒�_
    , sale_base_name          xxcmn_locations_all.location_name%TYPE                  -- ���㋒�_��
    , cnvs_biz_person         xxcmm_cust_accounts.cnvs_business_person%TYPE           -- �l����
    , cnvs_biz_person_name    VARCHAR2(100)                                           -- �l���Җ�
    , cnvs_base_code          xxcmm_cust_accounts.cnvs_base_code%TYPE                 -- �l�����_
    , cnvs_base_name          xxcmn_locations_all.location_name%TYPE                  -- �l�����_��
    , contract_number         xxcso_contract_managements.contract_number%TYPE         -- �_��ԍ�
    , contract_management_id  xxcso_contract_managements.contract_management_id%TYPE  -- �_��ID
    , sp_dec_number           xxcso_sp_decision_headers.sp_decision_number%TYPE       -- SP�ꌈ���ԍ�
    , sp_status               xxcso_sp_decision_headers.status%TYPE                   -- SP�ꌈ�X�e�[�^�X
    , sp_status_name          VARCHAR2(20)                                            -- SP�ꌈ�X�e�[�^�X��
    , cont_creation_date      VARCHAR2(30)                                            -- �_�񏑍쐬��
    , cont_last_update_date   VARCHAR2(30)                                            -- �_�񏑍ŏI�X�V��
    , cont_status             xxcso_contract_managements.status%TYPE                  -- �_�񏑃X�e�[�^�X
    , cont_status_name        VARCHAR2(20)                                            -- �_�񏑃X�e�[�^�X��
    );
  TYPE g_tab_contract_data IS TABLE OF g_rec_contract_data INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_contract_data            g_tab_contract_data;                      -- �����z��̒�`
  gv_base_code                xxcmm_cust_accounts.sale_base_code%TYPE;  -- ���㋒�_
  gv_status                   VARCHAR2(10)   DEFAULT NULL;              -- �_���
  gd_date_from                DATE;                                     -- ���o�Ώۓ�(FROM)
  gd_date_to                  DATE;                                     -- ���o�Ώۓ�(TO)
  gd_process_date             DATE;                                     -- �Ɩ����t
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- �V�K�ڋq�_�񏑏��J�[�\��
  CURSOR get_contract_cur1
  IS
    --SP�ꌈ�݂̂Ō_��Ȃ�(�V�K�_��Ȃ�)
    SELECT /*+
             LEADING(XCA)
             INDEX(XSDC XXCSO_SP_DECISION_CUSTS_N01)
             INDEX(XSDH XXCSO_SP_DECISION_HEADERS_PK)
           */
           cv_rec_kbn_1                        rec_kbn                                -- �敪
         , hca.account_number                  cust_code                              -- �ڋq�R�[�h
         , hp.party_name                       cust_name                              -- �ڋq��
         , hp.duns_number_c                    cust_status                            -- �ڋq�X�e�[�^�X
         , custs.cust_status_name              cust_status_name                       -- �ڋq�X�e�[�^�X��
         , xca.business_low_type               gyotai_sho                             -- �Ƒԏ�����
         , gyo.business_low_type_name          gyotai_sho_name                        -- �Ƒԏ����ޖ�
         , xca.sale_base_code                  sale_base_code                         -- ���㋒�_
         , xlv1.location_name                  sale_base_name                         -- ���㋒�_��
         , xca.cnvs_business_person            cnvs_biz_person                        -- �l����
         , emp.cnvs_business_person_name       cnvs_biz_person_name                   -- �l���Җ�
         , xca.cnvs_base_code                  cnvs_base_code                         -- �l�����_
         , xlv2.location_name                  cnvs_base_name                         -- �l�����_��
         , NULL                                contract_number                        -- �_�񏑔ԍ�
         , NULL                                contract_management_id                 -- �_��ID
         , xsdh.sp_decision_number             sp_dec_number                          -- SP�ꌈ���ԍ�
         , xsdh.status                         sp_status                              -- SP�ꌈ�X�e�[�^�X
         , spsts.sp_status_name                sp_status_name                         -- SP�ꌈ�X�e�[�^�X��
         , NULL                                cont_creation_date                     -- �_�񏑍쐬��
         , NULL                                cont_last_update_date                  -- �_�񏑍ŏI�X�V��
         , NULL                                cont_status                            -- �_�񏑃X�e�[�^�X
         , NULL                                cont_status_name                       -- �_�񏑃X�e�[�^�X��
    FROM   hz_cust_accounts           hca   -- �ڋq�}�X�^
         , hz_parties                 hp    -- �p�[�e�B�}�X�^
         , xxcmm_cust_accounts        xca   -- �ڋq�ǉ����
         , xxcso_sp_decision_custs    xsdc  -- SP�ꌈ�ڋq�e�[�u��
         , xxcso_sp_decision_headers  xsdh  -- SP�ꌈ�w�b�_�e�[�u��
         , xxcso_locations_v2         xlv1  -- ���Ə��}�X�^(���㋒�_)
         , xxcso_locations_v2         xlv2  -- ���Ə��}�X�^(�l�����_)
         , ( SELECT flv.lookup_code   business_low_type
                  , flv.meaning       business_low_type_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_01
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          gyo   -- �Ƒԏ�����(LOOKUP�\)
         , ( SELECT flv.lookup_code   cust_status
                  , flv.meaning       cust_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_03
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          custs -- �ڋq�X�e�[�^�X(LOOKUP�\)
         , ( SELECT flv.lookup_code   sp_status
                  , flv.meaning       sp_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_05
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          spsts -- SP�ꌈ�X�e�[�^�X(LOOKUP�\)
         , ( SELECT papf.employee_number    cnvs_business_person
                  , papf.per_information18
                 || papf.per_information19  cnvs_business_person_name
             FROM   per_all_people_f      papf
                  , per_all_assignments_f paaf
             WHERE  papf.person_id = paaf.person_id
             AND    gd_process_date
                    BETWEEN papf.effective_start_date
                        AND papf.effective_end_date
             AND    gd_process_date
                    BETWEEN paaf.effective_start_date
                        AND paaf.effective_end_date
           )                          emp   -- �l���ҏ��
    WHERE  hca.party_id                    = hp.party_id
    AND    hca.cust_account_id             = xca.customer_id
    AND    xca.sale_base_code              = gv_base_code
    AND    hca.cust_account_id             = xsdc.customer_id
    AND    xca.business_low_type           = gyo.business_low_type(+)
    AND    hp.duns_number_c                = custs.cust_status(+)
    AND    xsdh.status                     = spsts.sp_status(+)
    AND    xca.cnvs_business_person        = emp.cnvs_business_person(+)
    AND    xca.start_tran_date             IS NOT NULL                            -- ��������
    AND    (
             ( xca.stop_approval_reason    IS NULL )
             OR
             ( xca.stop_approval_reason    <> cv_stop_app_reason_9 )
           )                                                                      -- ���~���R:��d�o�^�ȊO
    AND    xsdc.sp_decision_customer_class = cv_sp_dec_cust_class_1               -- �ݒu��ڋq
    AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
    AND    xca.sale_base_code              = xlv1.dept_code
    AND    xca.cnvs_base_code              = xlv2.dept_code
    AND    xsdh.status                     = cv_sp_dec_status_3                   -- SP�ꌈ���F��
    AND    xsdh.approval_complete_date    >= gd_date_from                         -- ���F������FROM
    AND    xsdh.approval_complete_date    <= NVL( gd_date_to , gd_process_date )  -- ���F������TO
    AND    NOT EXISTS (
             SELECT 1
             FROM   xxcso.xxcso_contract_managements xcm
             WHERE  xcm.install_account_id = xsdc.customer_id
           )                                                                      -- ����ڋq�ŉߋ��Ɍ_�񂪖��쐬
    UNION ALL
    --�m�肵�Ă��Ȃ��_��ŐV�K(�V�K�_�񂠂�)
    SELECT /*+
             LEADING(XCA)
             INDEX(XSDC XXCSO_SP_DECISION_CUSTS_N01)
             INDEX(XSDH XXCSO_SP_DECISION_HEADERS_PK)
             INDEX(XCM1 XXCSO_CONTRACT_MANAGEMENTS_N01)
           */
           cv_rec_kbn_1                                       rec_kbn                 -- �敪
         , hca.account_number                                 cust_code               -- �ڋq�R�[�h
         , hp.party_name                                      cust_name               -- �ڋq��
         , hp.duns_number_c                                   cust_status             -- �ڋq�X�e�[�^�X
         , custs.cust_status_name                             cust_status_name        -- �ڋq�X�e�[�^�X��
         , xca.business_low_type                              gyotai_sho              -- �Ƒԏ�����
         , gyo.business_low_type_name                         gyotai_sho_name         -- �Ƒԏ����ޖ�
         , xca.sale_base_code                                 sale_base_code          -- ���㋒�_
         , xlv1.location_name                                 sale_base_name          -- ���㋒�_��
         , xca.cnvs_business_person                           cnvs_biz_person         -- �l����
         , emp.cnvs_business_person_name                      cnvs_biz_person_name    -- �l���Җ�
         , xca.cnvs_base_code                                 cnvs_base_code          -- �l�����_
         , xlv2.location_name                                 cnvs_base_name          -- �l�����_��
         , xcm1.contract_number                               contract_number         -- �_�񏑔ԍ�
         , xcm1.contract_management_id                        contract_management_id  -- �_��ID
         , xsdh.sp_decision_number                            sp_dec_number           -- SP�ꌈ���ԍ�
         , xsdh.status                                        sp_status               -- SP�ꌈ�X�e�[�^�X
         , spsts.sp_status_name                               sp_status_name          -- SP�ꌈ�X�e�[�^�X��
         , TO_CHAR( xcm1.creation_date    , cv_format_fmt2 )  cont_creation_date      -- �_�񏑍쐬��
         , TO_CHAR( xcm1.last_update_date , cv_format_fmt2 )  cont_last_update_date   -- �_�񏑍ŏI�X�V��
         , xcm1.status                                        cont_status             -- �_�񏑃X�e�[�^�X
         , costs.cont_status_name                             cont_status_name        -- �_�񏑃X�e�[�^�X��
    FROM   hz_cust_accounts           hca   -- �ڋq�}�X�^
         , hz_parties                 hp    -- �p�[�e�B�}�X�^
         , xxcmm_cust_accounts        xca   -- �ڋq�ǉ����
         , xxcso_sp_decision_custs    xsdc  -- SP�ꌈ�ڋq�e�[�u��
         , xxcso_sp_decision_headers  xsdh  -- SP�ꌈ�w�b�_�e�[�u��
         , xxcso_contract_managements xcm1  -- �_��Ǘ��e�[�u��
         , xxcso_locations_v2         xlv1  -- ���Ə��}�X�^(���㋒�_)
         , xxcso_locations_v2         xlv2  -- ���Ə��}�X�^(�l�����_)
         , ( SELECT flv.lookup_code   business_low_type
                  , flv.meaning       business_low_type_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_01
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          gyo   -- �Ƒԏ�����(LOOKUP�\)
         , ( SELECT flv.lookup_code   cust_status
                  , flv.meaning       cust_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_03
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          custs -- �ڋq�X�e�[�^�X(LOOKUP�\)
         , ( SELECT flv.lookup_code   cont_status
                  , flv.meaning       cont_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_04
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          costs -- �_�񏑃X�e�[�^�X(LOOKUP�\)
         , ( SELECT flv.lookup_code   sp_status
                  , flv.meaning       sp_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_05
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          spsts -- SP�ꌈ�X�e�[�^�X(LOOKUP�\)
         , ( SELECT papf.employee_number    cnvs_business_person
                  , papf.per_information18
                 || papf.per_information19  cnvs_business_person_name
             FROM   per_all_people_f      papf
                  , per_all_assignments_f paaf
             WHERE  papf.person_id = paaf.person_id
             AND    gd_process_date
                    BETWEEN papf.effective_start_date
                        AND papf.effective_end_date
             AND    gd_process_date
                    BETWEEN paaf.effective_start_date
                        AND paaf.effective_end_date
           )                          emp  -- �l���ҏ��
    WHERE  hca.party_id                    = hp.party_id
    AND    hca.cust_account_id             = xca.customer_id
    AND    xca.sale_base_code              = gv_base_code
    AND    hca.cust_account_id             = xsdc.customer_id
    AND    xca.business_low_type           = gyo.business_low_type(+)
    AND    hp.duns_number_c                = custs.cust_status(+)
    AND    xcm1.status                     = costs.cont_status(+)
    AND    xsdh.status                     = spsts.sp_status(+)
    AND    xca.cnvs_business_person        = emp.cnvs_business_person(+)
    AND    xca.start_tran_date             IS NOT NULL                            -- ��������
    AND    xsdc.sp_decision_customer_class = cv_sp_dec_cust_class_1               -- �ݒu��ڋq
    AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
    AND    xsdh.sp_decision_header_id      = xcm1.sp_decision_header_id
    AND    xca.sale_base_code              = xlv1.dept_code
    AND    xca.cnvs_base_code              = xlv2.dept_code
    AND      (
               ( xca.stop_approval_reason  IS NULL )
               OR
               ( xca.stop_approval_reason  <> cv_stop_app_reason_9 )
             )                                                                    -- ���~���R:��d�o�^�ȊO
    AND    xcm1.contract_management_id = ( SELECT MAX( xcm2.contract_management_id )
                                           FROM   xxcso_contract_managements xcm2
                                           WHERE  xcm2.install_account_id = xcm1.install_account_id
                                           AND    xcm2.status             = cv_cont_mng_status_0 -- �쐬��
                                         )
    AND    NOT EXISTS (
             SELECT 1
             FROM   xxcso_contract_managements xcm3
             WHERE  xcm3.install_account_id = xcm1.install_account_id
             AND    xcm3.status             = cv_cont_mng_status_1            -- �m���
             AND    xcm3.cooperate_flag     = cv_cooperate_flag_1             -- �}�X�^�A�g��
           )
    AND    TRUNC( xcm1.creation_date )    >= gd_date_from                         -- �_��쐬��FROM
    AND    TRUNC( xcm1.creation_date )    <= NVL( gd_date_to , gd_process_date )  -- �_��쐬��TO
    ORDER BY sp_dec_number   -- SP�ꌈ���ԍ�
  ;
  -- �����ύX���m��_�񏑏��J�[�\��
  CURSOR get_contract_cur2
  IS
    --�ߋ��Ɋm��ό_�񂪂���A�Y����SP�ꌈ�͊m�肵�Ă��邪�_��Ȃ�(�����ύX�_��Ȃ�)
    SELECT /*+
             LEADING(XCA)
             INDEX(XSDC XXCSO_SP_DECISION_CUSTS_N01)
             INDEX(XSDH XXCSO_SP_DECISION_HEADERS_PK)
           */
           cv_rec_kbn_2                        rec_kbn                                -- �敪
         , hca.account_number                  cust_code                              -- �ڋq�R�[�h
         , hp.party_name                       cust_name                              -- �ڋq��
         , hp.duns_number_c                    cust_status                            -- �ڋq�X�e�[�^�X
         , custs.cust_status_name              cust_status_name                       -- �ڋq�X�e�[�^�X��
         , xca.business_low_type               gyotai_sho                             -- �Ƒԏ�����
         , gyo.business_low_type_name          gyotai_sho_name                        -- �Ƒԏ����ޖ�
         , xca.sale_base_code                  sale_base_code                         -- ���㋒�_
         , xlv1.location_name                  sale_base_name                         -- ���㋒�_��
         , xca.cnvs_business_person            cnvs_biz_person                        -- �l����
         , emp.cnvs_business_person_name       cnvs_biz_person_name                   -- �l���Җ�
         , xca.cnvs_base_code                  cnvs_base_code                         -- �l�����_
         , xlv2.location_name                  cnvs_base_name                         -- �l�����_��
         , NULL                                contract_number                        -- �_�񏑔ԍ�
         , NULL                                contract_management_id                 -- �_��ID
         , xsdh.sp_decision_number             sp_dec_number                          -- SP�ꌈ���ԍ�
         , xsdh.status                         sp_status                              -- SP�ꌈ�X�e�[�^�X
         , spsts.sp_status_name                sp_status_name                         -- SP�ꌈ�X�e�[�^�X��
         , NULL                                cont_creation_date                     -- �_�񏑍쐬��
         , NULL                                cont_last_update_date                  -- �_�񏑍ŏI�X�V��
         , NULL                                cont_status                            -- �_�񏑃X�e�[�^�X
         , NULL                                cont_status_name                       -- �_�񏑃X�e�[�^�X��
    FROM   hz_cust_accounts           hca   -- �ڋq�}�X�^
         , hz_parties                 hp    -- �p�[�e�B�}�X�^
         , xxcmm_cust_accounts        xca   -- �ڋq�ǉ����
         , xxcso_sp_decision_custs    xsdc  -- SP�ꌈ�ڋq�e�[�u��
         , xxcso_sp_decision_headers  xsdh  -- SP�ꌈ�w�b�_�e�[�u��
         , xxcso_locations_v2         xlv1  -- ���Ə��}�X�^(���㋒�_)
         , xxcso_locations_v2         xlv2  -- ���Ə��}�X�^(�l�����_)
         , ( SELECT flv.lookup_code   business_low_type
                  , flv.meaning       business_low_type_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_01
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          gyo   -- �Ƒԏ�����(LOOKUP�\)
         , ( SELECT flv.lookup_code   cust_status
                  , flv.meaning       cust_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_03
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          custs -- �ڋq�X�e�[�^�X(LOOKUP�\)
         , ( SELECT flv.lookup_code   sp_status
                  , flv.meaning       sp_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_05
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          spsts -- SP�ꌈ�X�e�[�^�X(LOOKUP�\)
         , ( SELECT papf.employee_number    cnvs_business_person
                  , papf.per_information18
                 || papf.per_information19  cnvs_business_person_name
             FROM   per_all_people_f      papf
                  , per_all_assignments_f paaf
             WHERE  papf.person_id = paaf.person_id
             AND    gd_process_date
                    BETWEEN papf.effective_start_date
                        AND papf.effective_end_date
             AND    gd_process_date
                    BETWEEN paaf.effective_start_date
                        AND paaf.effective_end_date
           )                          emp   -- �l���ҏ��
    WHERE  hca.party_id                    = hp.party_id
    AND    hca.cust_account_id             = xca.customer_id
    AND    xca.sale_base_code              = gv_base_code
    AND    (
             ( xca.stop_approval_reason    IS NULL )
             OR
             ( xca.stop_approval_reason    <> cv_stop_app_reason_9 )
           )                                                                      -- ���~���R:��d�o�^�ȊO
    AND    hca.cust_account_id             = xsdc.customer_id
    AND    xca.business_low_type           = gyo.business_low_type(+)
    AND    hp.duns_number_c                = custs.cust_status(+)
    AND    xsdh.status                     = spsts.sp_status(+)
    AND    xca.cnvs_business_person        = emp.cnvs_business_person(+)
    AND    xca.start_tran_date             IS NOT NULL                            -- ��������
    AND    xsdc.sp_decision_customer_class = cv_sp_dec_cust_class_1               -- �ݒu��ڋq
    AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
    AND    xca.sale_base_code              = xlv1.dept_code
    AND    xca.cnvs_base_code              = xlv2.dept_code
    AND    xsdh.status                     = cv_sp_dec_status_3                   -- SP�ꌈ���F��
    AND    xsdh.approval_complete_date    >= gd_date_from                         -- ���F������FROM
    AND    xsdh.approval_complete_date    <= NVL( gd_date_to , gd_process_date )  -- ���F������TO
    AND    EXISTS (
             SELECT /*+
                      INDEX( XCM1 XXCSO_CONTRACT_MANAGEMENTS_N06 )
                    */
                    1
             FROM   xxcso_contract_managements xcm1
             WHERE  xcm1.install_account_id = xsdc.customer_id
             AND    xcm1.status                 = cv_cont_mng_status_1            -- �m���
             AND    xcm1.cooperate_flag         = cv_cooperate_flag_1             -- �}�X�^�A�g��
             AND    ROWNUM                      = 1
           )                                                                      -- ����ڋq�ŉߋ��Ɍ_��쐬��
    AND    NOT EXISTS (
             SELECT 1
             FROM   xxcso_contract_managements xcm2
             WHERE  xcm2.sp_decision_header_id = xsdh.sp_decision_header_id
           )                                                                      -- �Y��SP�̌_�񖢍쐬
    UNION ALL
    --�ŐV�_�񂪊m�肵�Ă��Ȃ������ύX(�����ύX�_�񂠂�)
    SELECT /*+
             LEADING(XCA)
             INDEX(XSDC XXCSO_SP_DECISION_CUSTS_N01)
             INDEX(XSDH XXCSO_SP_DECISION_HEADERS_PK)
             INDEX(XCM1 XXCSO_CONTRACT_MANAGEMENTS_N01)
           */
           cv_rec_kbn_2                        rec_kbn                                -- �敪
         , xcm1.install_account_number         cust_code                              -- �ڋq�R�[�h
         , xcm1.install_party_name             cust_name                              -- �ڋq��
         , hp.duns_number_c                    cust_status                            -- �ڋq�X�e�[�^�X
         , custs.cust_status_name              cust_status_name                       -- �ڋq�X�e�[�^�X��
         , xca.business_low_type               gyotai_sho                             -- �Ƒԏ�����
         , gyo.business_low_type_name          gyotai_sho_name                        -- �Ƒԏ����ޖ�
         , xca.sale_base_code                  sale_base_code                         -- ���㋒�_
         , xlv1.location_name                  sale_base_name                         -- ���㋒�_��
         , xca.cnvs_business_person            cnvs_biz_person                        -- �l����
         , emp.cnvs_business_person_name       cnvs_biz_person_name                   -- �l���Җ�
         , xca.cnvs_base_code                  cnvs_base_code                         -- �l�����_
         , xlv2.location_name                  cnvs_base_name                         -- �l�����_��
         , xcm1.contract_number                contract_number                        -- �_�񏑔ԍ�
         , xcm1.contract_management_id         contract_management_id                 -- �_��ID
         , xsdh.sp_decision_number             sp_dec_number                          -- SP�ꌈ���ԍ�
         , xsdh.status                         sp_status                              -- SP�ꌈ�X�e�[�^�X
         , spsts.sp_status_name                sp_status_name                         -- SP�ꌈ�X�e�[�^�X��
         , TO_CHAR( xcm1.creation_date    , cv_format_fmt2 )  cont_creation_date      -- �_�񏑍쐬��
         , TO_CHAR( xcm1.last_update_date , cv_format_fmt2 )  cont_last_update_date   -- �_�񏑍ŏI�X�V��
         , xcm1.status                         cont_status                            -- �_�񏑃X�e�[�^�X
         , costs.cont_status_name              cont_status_name                       -- �_�񏑃X�e�[�^�X��
    FROM   hz_cust_accounts           hca   -- �ڋq�}�X�^
         , hz_parties                 hp    -- �p�[�e�B�}�X�^
         , xxcmm_cust_accounts        xca   -- �ڋq�ǉ����
         , xxcso_sp_decision_custs    xsdc  -- SP�ꌈ�ڋq�e�[�u��
         , xxcso_sp_decision_headers  xsdh  -- SP�ꌈ�w�b�_�e�[�u��
         , xxcso_contract_managements xcm1  -- �_��Ǘ��e�[�u��
         , xxcso_locations_v2         xlv1  -- ���Ə��}�X�^(���㋒�_)
         , xxcso_locations_v2         xlv2  -- ���Ə��}�X�^(�l�����_)
         , ( SELECT flv.lookup_code   business_low_type
                  , flv.meaning       business_low_type_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_01
             AND    flv.enabled_flag  = cv_flag_yes
             AND   gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          gyo   -- �Ƒԏ�����(LOOKUP�\)
         , ( SELECT flv.lookup_code   cust_status
                  , flv.meaning       cust_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_03
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          custs -- �ڋq�X�e�[�^�X(LOOKUP�\)
         , ( SELECT flv.lookup_code   cont_status
                  , flv.meaning       cont_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_04
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          costs -- �_�񏑃X�e�[�^�X(LOOKUP�\)
         , ( SELECT flv.lookup_code   sp_status
                  , flv.meaning       sp_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_05
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          spsts -- SP�ꌈ�X�e�[�^�X(LOOKUP�\)
         , ( SELECT papf.employee_number    cnvs_business_person
                  , papf.per_information18
                 || papf.per_information19  cnvs_business_person_name
             FROM   per_all_people_f      papf
                  , per_all_assignments_f paaf
             WHERE  papf.person_id = paaf.person_id
             AND    gd_process_date
                    BETWEEN papf.effective_start_date
                        AND papf.effective_end_date
             AND    gd_process_date
                    BETWEEN paaf.effective_start_date
                        AND paaf.effective_end_date
           )                          emp   -- �l���ҏ��
    WHERE  hca.party_id                    = hp.party_id
    AND    hca.cust_account_id             = xca.customer_id
    AND    xca.sale_base_code              = gv_base_code
    AND    (
             ( xca.stop_approval_reason IS NULL )
             OR
             ( xca.stop_approval_reason <> cv_stop_app_reason_9 )
           )                                                                      -- ���~���R:��d�o�^�ȊO
    AND    hca.cust_account_id             = xsdc.customer_id
    AND    xca.business_low_type           = gyo.business_low_type(+)
    AND    hp.duns_number_c                = custs.cust_status(+)
    AND    xcm1.status                     = costs.cont_status(+)
    AND    xsdh.status                     = spsts.sp_status(+)
    AND    xca.cnvs_business_person        = emp.cnvs_business_person(+)
    AND    xca.start_tran_date             IS NOT NULL                            -- ��������
    AND    xsdc.sp_decision_customer_class = cv_sp_dec_cust_class_1               -- �ݒu��ڋq
    AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
    AND    xsdh.sp_decision_header_id      = xcm1.sp_decision_header_id
    AND    xca.sale_base_code              = xlv1.dept_code
    AND    xca.cnvs_base_code              = xlv2.dept_code 
    AND    xcm1.contract_management_id = ( SELECT MAX( xcm2.contract_management_id )
                                           FROM   xxcso_contract_managements xcm2
                                           WHERE  xcm2.install_account_id = xcm1.install_account_id
                                           AND    xcm2.status             = cv_cont_mng_status_0 -- �쐬��
                                         )                                        -- �ŐV�̌_�񂪖��m��
    AND    EXISTS (
             SELECT 1
             FROM   xxcso_contract_managements xcm3
             WHERE  xcm3.install_account_id = xcm1.install_account_id
             AND    xcm3.status             = cv_cont_mng_status_1            -- �m���
             AND    xcm3.cooperate_flag     = cv_cooperate_flag_1             -- �}�X�^�A�g��
           )                                                                      -- �ߋ��Ɋm��ς݂̌_�񂠂�
    AND    TRUNC( xcm1.creation_date )    >= gd_date_from                         -- �_��쐬��FROM
    AND    TRUNC( xcm1.creation_date )    <= NVL( gd_date_to , gd_process_date )  -- �_��쐬��TO
    ORDER BY sp_dec_number   -- SP�ꌈ���ԍ�
  ;
  -- �m��ς݌_�񏑏��J�[�\��
  CURSOR get_contract_cur3
  IS
    SELECT /*+
             LEADING(XCA)
             INDEX(XSDC XXCSO_SP_DECISION_CUSTS_N01)
             INDEX(XSDH XXCSO_SP_DECISION_HEADERS_PK)
             INDEX(XCM1 XXCSO_CONTRACT_MANAGEMENTS_N01)
           */
           cv_rec_kbn_3                        rec_kbn                                -- �敪
         , xcm1.install_account_number         cust_code                              -- �ڋq�R�[�h
         , xcm1.install_party_name             cust_name                              -- �ڋq��
         , hp.duns_number_c                    cust_status                            -- �ڋq�X�e�[�^�X
         , custs.cust_status_name              cust_status_name                       -- �ڋq�X�e�[�^�X��
         , xca.business_low_type               gyotai_sho                             -- �Ƒԏ�����
         , gyo.business_low_type_name          gyotai_sho_name                        -- �Ƒԏ����ޖ�
         , xca.sale_base_code                  sale_base_code                         -- ���㋒�_
         , xlv1.location_name                  sale_base_name                         -- ���㋒�_��
         , xca.cnvs_business_person            cnvs_biz_person                        -- �l����
         , emp.cnvs_business_person_name       cnvs_biz_person_name                   -- �l���Җ�
         , xca.cnvs_base_code                  cnvs_base_code                         -- �l�����_
         , xlv2.location_name                  cnvs_base_name                         -- �l�����_��
         , xcm1.contract_number                contract_number                        -- �_�񏑔ԍ�
         , xcm1.contract_management_id         contract_management_id                 -- �_��ID
         , xsdh.sp_decision_number             sp_dec_number                          -- SP�ꌈ���ԍ�
         , xsdh.status                         sp_status                              -- SP�ꌈ�X�e�[�^�X
         , spsts.sp_status_name                sp_status_name                         -- SP�ꌈ�X�e�[�^�X��
         , TO_CHAR( xcm1.creation_date    , cv_format_fmt2 )  cont_creation_date      -- �_�񏑍쐬��
         , TO_CHAR( xcm1.last_update_date , cv_format_fmt2 )  cont_last_update_date   -- �_�񏑍ŏI�X�V��
         , xcm1.status                         cont_status                            -- �_�񏑃X�e�[�^�X
         , costs.cont_status_name              cont_status_name                       -- �_�񏑃X�e�[�^�X��
    FROM   hz_cust_accounts           hca   -- �ڋq�}�X�^
         , hz_parties                 hp    -- �p�[�e�B�}�X�^
         , xxcmm_cust_accounts        xca   -- �ڋq�ǉ����
         , xxcso_sp_decision_custs    xsdc  -- SP�ꌈ�ڋq�e�[�u��
         , xxcso_sp_decision_headers  xsdh  -- SP�ꌈ�w�b�_�e�[�u��
         , xxcso_contract_managements xcm1  -- �_��Ǘ��e�[�u��
         , xxcso_locations_v2         xlv1  -- ���Ə��}�X�^(���㋒�_)
         , xxcso_locations_v2         xlv2  -- ���Ə��}�X�^(�l�����_)
         , ( SELECT flv.lookup_code   business_low_type
                  , flv.meaning       business_low_type_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_01
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          gyo   -- �Ƒԏ�����(LOOKUP�\)
         , ( SELECT flv.lookup_code   cust_status
                  , flv.meaning       cust_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_03
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          custs -- �ڋq�X�e�[�^�X(LOOKUP�\)
         , ( SELECT flv.lookup_code   cont_status
                  , flv.meaning       cont_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_04
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          costs -- �_�񏑃X�e�[�^�X(LOOKUP�\)
         , ( SELECT flv.lookup_code   sp_status
                  , flv.meaning       sp_status_name
             FROM   fnd_lookup_values_vl flv
             WHERE  flv.lookup_type   = cv_lookup_type_05
             AND    flv.enabled_flag  = cv_flag_yes
             AND    gd_process_date
                    BETWEEN NVL( flv.start_date_active , gd_process_date )
                        AND NVL( flv.end_date_active   , gd_process_date )
           )                          spsts -- SP�ꌈ�X�e�[�^�X(LOOKUP�\)
         , ( SELECT papf.employee_number    cnvs_business_person
                  , papf.per_information18
                 || papf.per_information19  cnvs_business_person_name
             FROM   per_all_people_f      papf
                  , per_all_assignments_f paaf
             WHERE  papf.person_id = paaf.person_id
             AND    gd_process_date
                    BETWEEN papf.effective_start_date
                        AND papf.effective_end_date
             AND    gd_process_date
                    BETWEEN paaf.effective_start_date
                        AND paaf.effective_end_date
           )                          emp   -- �l���ҏ��
    WHERE  hca.party_id                    = hp.party_id
    AND    hca.cust_account_id             = xca.customer_id
    AND    xca.sale_base_code              = gv_base_code
    AND    (
             ( xca.stop_approval_reason IS NULL )
             OR
             ( xca.stop_approval_reason <> cv_stop_app_reason_9 )
           )                                                                      -- ���~���R:��d�o�^�ȊO
    AND    hca.cust_account_id             = xsdc.customer_id
    AND    xca.business_low_type           = gyo.business_low_type(+)
    AND    hp.duns_number_c                = custs.cust_status(+)
    AND    xcm1.status                     = costs.cont_status(+)
    AND    xsdh.status                     = spsts.sp_status(+)
    AND    xca.cnvs_business_person        = emp.cnvs_business_person(+)
    AND    xca.start_tran_date             IS NOT NULL                            -- ��������
    AND    xsdc.sp_decision_customer_class = cv_sp_dec_cust_class_1               -- �ݒu��ڋq
    AND    xsdc.sp_decision_header_id      = xsdh.sp_decision_header_id
    AND    xsdh.sp_decision_header_id      = xcm1.sp_decision_header_id
    AND    xca.sale_base_code              = xlv1.dept_code 
    AND    xca.cnvs_base_code              = xlv2.dept_code
    AND    xcm1.contract_management_id = ( SELECT MAX( xcm2.contract_management_id )
                                           FROM   xxcso_contract_managements xcm2
                                           WHERE  xcm2.install_account_id = xcm1.install_account_id
                                           AND    xcm2.status             = cv_cont_mng_status_1      -- �m���
                                           AND    xcm2.cooperate_flag     = cv_cooperate_flag_1       -- �}�X�^�A�g��
                                         )                                        -- �ŐV���m��ς̌_��
    AND    TRUNC( xcm1.creation_date )    >= gd_date_from                         -- �_��쐬��FROM
    AND    TRUNC( xcm1.creation_date )    <= NVL( gd_date_to , gd_process_date )  -- �_��쐬��TO
    ORDER BY sp_dec_number   -- SP�ꌈ���ԍ�
  ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code  IN  VARCHAR2      --   ���㋒�_
   ,iv_status     IN  VARCHAR2      --   �_���
   ,iv_date_from  IN  VARCHAR2      --   ���o�Ώۓ�(FROM)
   ,iv_date_to    IN  VARCHAR2      --   ���o�Ώۓ�(TO)
   ,ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_base_code              VARCHAR2(1000);  -- ���㋒�_�o�͗p
    lv_status                 VARCHAR2(1000);  -- �_��󋵏o�͗p
    lv_date_from              VARCHAR2(1000);  -- ���o�Ώۓ�(FROM)�o�͗p
    lv_date_to                VARCHAR2(1000);  -- ���o�Ώۓ�(TO)�o�͗p
    lv_csv_header             VARCHAR2(5000);  -- CSV�w�b�_���ڏo�͗p
--
    lv_status_name            VARCHAR2(30);    -- �_��󋵃X�e�[�^�X��
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
--
    --==============================================================
    --���̓p�����[�^���O���[�o���ϐ��Ɋi�[
    --==============================================================
    gv_base_code   := iv_base_code;
    gv_status      := iv_status;
    gd_date_from   := TO_DATE( iv_date_from , cv_format_fmt1 );
    gd_date_to     := TO_DATE( iv_date_to   , cv_format_fmt1 );
--
    --==============================================================
    --���̓p�����[�^�����b�Z�[�W�o��
    --==============================================================
    -- �_��󋵂̖��̂��擾
    BEGIN
      SELECT ffvt.description     status_name  -- �_��󋵖�
      INTO   lv_status_name
      FROM   fnd_flex_values      ffv
           , fnd_flex_values_tl   ffvt
           , fnd_flex_value_sets  ffvs
      WHERE  ffv.flex_value_id        = ffvt.flex_value_id
      AND    ffvt.language            = cv_language_ja
      AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffvs.flex_value_set_name = cv_flex_value_01
      AND    ffv.flex_value           = gv_status
      AND    ffv.enabled_flag         = cv_flag_yes
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_status_name := NULL;
    END;
--
    -- ���㋒�_
    lv_base_code   := xxccp_common_pkg.get_msg(                          -- �A�b�v���[�h���̂̏o��
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00640              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_base_code              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => iv_base_code                  -- �g�[�N���l1
                      );
    -- �_���
    lv_status      := xxccp_common_pkg.get_msg(                          -- �t�@�C��ID�̏o��
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00641              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_status                 -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_status_name                -- �g�[�N���l1
                      );
    -- ���o�Ώۓ�(FROM)
    lv_date_from   := xxccp_common_pkg.get_msg(                          -- �t�@�C��ID�̏o��
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00642              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_date_from              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => iv_date_from                  -- �g�[�N���l1
                      );
    -- ���o�Ώۓ�(TO)
    lv_date_to     := xxccp_common_pkg.get_msg(                          -- �t�H�[�}�b�g�̏o��
                       iv_application  => cv_appl_name_xxcso             -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_cso_00643               -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_date_to                 -- �g�[�N���R�[�h1
                      ,iv_token_value1 => iv_date_to                     -- �g�[�N���l1
                      );
--
    -- ���O�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''           || CHR(10) ||
                 lv_base_code || CHR(10) ||      -- ���㋒�_
                 lv_status    || CHR(10) ||      -- �_���
                 lv_date_from || CHR(10) ||      -- ���o�Ώۓ�(FROM)
                 lv_date_to   || CHR(10)         -- ���o�Ώۓ�(TO)
    );
--
    --==================================================
    -- �Ɩ����t�擾
    --==================================================
    gd_process_date := xxccp_common_pkg2.get_process_date ;
    -- �Ɩ����t�̎擾�Ɏ��s�����ꍇ�̓G���[
    IF( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso
         ,iv_name         => cv_msg_cso_00011
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- ���o�Ώۓ�(FROM)�̎w��`�F�b�N
    --==================================================
    -- ���o�Ώۓ�(TO)�ƋƖ����t�̔�r
    IF ( gd_date_from > gd_process_date ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso
         ,iv_name         => cv_msg_cso_00644
         ,iv_token_name1  => cv_tkn_date_from
         ,iv_token_value1 => cv_tkn_val_date_from
         ,iv_token_name2  => cv_tkn_date_to
         ,iv_token_value2 => cv_tkn_val_process_date
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- ���o�Ώۓ�(TO)�̎w��`�F�b�N
    --==================================================
    -- ���o�Ώۓ�(TO)���w�肳��Ă����ꍇ�Ƀ`�F�b�N����
    IF  ( gd_date_to IS NOT NULL ) THEN
      -- ���o�Ώۓ�(FROM)�ƒ��o�Ώۓ�(TO)�̔�r
      IF ( gd_date_from > gd_date_to ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso
         ,iv_name         => cv_msg_cso_00644
         ,iv_token_name1  => cv_tkn_date_from
         ,iv_token_value1 => cv_tkn_val_date_from
         ,iv_token_name2  => cv_tkn_date_to
         ,iv_token_value2 => cv_tkn_val_date_to
        );
        lv_errbuf  := lv_errmsg;
        RAISE init_err_expt;
      END IF;
    END IF;
--
    --==================================================
    -- CSV�w�b�_���ڏo��
    --==================================================
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcso
                    ,iv_name         => cv_msg_cso_00645
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSV�t�@�C���o��(A-5)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_output_str   VARCHAR2(5000)  := NULL;  -- �o�͕�����i�[�p�ϐ�
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_data_expt  EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- CSV�`���̃f�[�^�o��
    -- ===============================
    FOR i IN 1..gt_contract_data.COUNT LOOP
      lv_output_str :=                              cv_dqu || gt_contract_data( i ).rec_kbn                 || cv_dqu ;  -- �敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).sp_dec_number           || cv_dqu ;  -- SP�ꌈ���ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).sp_status               || cv_dqu ;  -- SP�ꌈ�X�e�[�^�X
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).sp_status_name          || cv_dqu ;  -- SP�ꌈ�X�e�[�^�X��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cust_code               || cv_dqu ;  -- �ڋq�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cust_name               || cv_dqu ;  -- �ڋq��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cust_status             || cv_dqu ;  -- �ڋq�X�e�[�^�X
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cust_status_name        || cv_dqu ;  -- �ڋq�X�e�[�^�X��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).gyotai_sho              || cv_dqu ;  -- �Ƒԏ�����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).gyotai_sho_name         || cv_dqu ;  -- �Ƒԏ����ޖ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).sale_base_code          || cv_dqu ;  -- ���㋒�_
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).sale_base_name          || cv_dqu ;  -- ���㋒�_��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cnvs_biz_person         || cv_dqu ;  -- �l����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cnvs_biz_person_name    || cv_dqu ;  -- �l���Җ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cnvs_base_code          || cv_dqu ;  -- �l�����_
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cnvs_base_name          || cv_dqu ;  -- �l�����_��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).contract_number         || cv_dqu ;  -- �_�񏑔ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).contract_management_id  || cv_dqu ;  -- �_��ID
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cont_creation_date      || cv_dqu ;  -- �_�񏑍쐬��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cont_last_update_date   || cv_dqu ;  -- �_�񏑍ŏI�X�V��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cont_status             || cv_dqu ;  -- �_�񏑃X�e�[�^�X
      lv_output_str := lv_output_str || cv_comma || cv_dqu || gt_contract_data( i ).cont_status_name        || cv_dqu ;  -- �_�񏑃X�e�[�^�X��
--
      -- �쐬����CSV�f�[�^���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_output_str
      );
      -- ��������
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : get_contract_data1
   * Description      : �_�񏑏��y�V�K�z�̎擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_contract_data1(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_data1'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
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
      -- ������
      gt_contract_data.DELETE;
      --
      -- ===============================
      -- �_�񏑏��y�V�K�z�̎擾
      -- ===============================
      -- �J�[�\��OPEN
      OPEN  get_contract_cur1;
      -- �o���N�t�F�b�`
      FETCH get_contract_cur1 BULK COLLECT INTO gt_contract_data;
      -- �J�[�\��CLOSE
      CLOSE get_contract_cur1;
      -- �����J�E���g
      gn_target_cnt := gn_target_cnt + gt_contract_data.COUNT;
--
      -- ===============================
      -- CSV�t�@�C���o��(A-5)
      -- ===============================
      output_csv(
        ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE
        IF ( get_contract_cur1%ISOPEN ) THEN
          CLOSE get_contract_cur1;
          RAISE global_process_expt;
        END IF;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_contract_data1;


--
  /**********************************************************************************
   * Procedure Name   : get_contract_data2
   * Description      : �_�񏑏��y�����ύX�z�̎擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_contract_data2(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_data2'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
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
      -- ������
      gt_contract_data.DELETE;
      --
      -- ===============================
      -- �_�񏑏��y�����ύX�z�̎擾
      -- ===============================
      -- �J�[�\��OPEN
      OPEN  get_contract_cur2;
      -- �o���N�t�F�b�`
      FETCH get_contract_cur2 BULK COLLECT INTO gt_contract_data;
      -- �J�[�\��CLOSE
      CLOSE get_contract_cur2;
      -- �����J�E���g
      gn_target_cnt := gn_target_cnt + gt_contract_data.COUNT;
--
      -- ===============================
      -- CSV�t�@�C���o��(A-5)
      -- ===============================
      output_csv(
        ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE
        IF ( get_contract_cur2%ISOPEN ) THEN
          CLOSE get_contract_cur2;
          RAISE global_process_expt;
        END IF;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_contract_data2;
--
  /**********************************************************************************
   * Procedure Name   : get_contract_data3
   * Description      : �_�񏑏��y�m��ρz�̎擾(A-4)
   ***********************************************************************************/
  PROCEDURE get_contract_data3(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_data3'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
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
      -- ������
      gt_contract_data.DELETE;
      --
      -- ===============================
      -- �_�񏑏��y�m��ρz�̎擾
      -- ===============================
      -- �J�[�\��OPEN
      OPEN  get_contract_cur3;
      -- �o���N�t�F�b�`
      FETCH get_contract_cur3 BULK COLLECT INTO gt_contract_data;
      -- �J�[�\��CLOSE
      CLOSE get_contract_cur3;
      -- �����J�E���g
      gn_target_cnt := gn_target_cnt + gt_contract_data.COUNT;
--
      -- ===============================
      -- CSV�t�@�C���o��(A-5)
      -- ===============================
      output_csv(
        ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE
        IF ( get_contract_cur3%ISOPEN ) THEN
          CLOSE get_contract_cur3;
          RAISE global_process_expt;
        END IF;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[����
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_contract_data3;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code       IN  VARCHAR2     -- ���㋒�_
   ,iv_status          IN  VARCHAR2     -- �_���
   ,iv_date_from       IN  VARCHAR2     -- ���o�Ώۓ��iFROM�j
   ,iv_date_to         IN  VARCHAR2     -- ���o�Ώۓ��iTO�j
   ,ov_errbuf          OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      iv_base_code       => iv_base_code     -- ���㋒�_
     ,iv_status          => iv_status        -- �_���
     ,iv_date_from       => iv_date_from     -- �Ώۊ���FROM
     ,iv_date_to         => iv_date_to       -- �Ώۊ���TO
     ,ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���̓p�����[�^.�_��󋵂��u���m��v�̏ꍇ
    -- ===============================
    IF ( gv_status = cv_para_status_1 ) THEN
      -- ===============================
      -- �_�񏑏��y�V�K�z�̎擾(A-2)�ACSV�t�@�C���o��(A-5)
      -- ===============================
      get_contract_data1(
        ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- 
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �_�񏑏��y�����ύX�z�̎擾(A-3)�ACSV�t�@�C���o��(A-5)
      -- ===============================
      get_contract_data2(
        ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- 
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- ===============================
    -- ���̓p�����[�^.�_��󋵂��u�m��ρv�̏ꍇ
    -- ===============================
    ELSIF ( gv_status = cv_para_status_2 ) THEN
      -- ===============================
      -- �_�񏑏��y�m��ρz�̎擾(A-4)�ACSV�t�@�C���o��(A-5)
      -- ===============================
      get_contract_data3(
        ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- 
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
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
    errbuf             OUT VARCHAR2     -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode            OUT VARCHAR2     -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_base_code       IN  VARCHAR2     -- ���㋒�_
   ,iv_status          IN  VARCHAR2     -- �_���
   ,iv_date_from       IN  VARCHAR2     -- ���o�Ώۓ��iFROM�j
   ,iv_date_to         IN  VARCHAR2     -- ���o�Ώۓ��iTO�j
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
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output_log
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
       iv_base_code    => iv_base_code   -- ���㋒�_
      ,iv_status       => iv_status      -- �_���
      ,iv_date_from    => iv_date_from   -- ���o�Ώۓ�(FROM)
      ,iv_date_to      => iv_date_to     -- ���o�Ώۓ�(TO)
      ,ov_errbuf       => lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================================
    -- �Ώی����o��
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- ���������o��
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- �G���[�����o��
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCSO010A05C;
/
