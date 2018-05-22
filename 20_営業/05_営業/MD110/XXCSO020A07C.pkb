CREATE OR REPLACE PACKAGE BODY APPS.XXCSO020A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO020A07C (body)
 * Description      : SP�ꌈ�����CSV�o��
 * MD.050           : SP�ꌈ�����CSV�o�� (MD050_CSO_020A07)
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  output_sp_data         SP�ꌈ�����o��(A-2)
 *  output_csv             CSV�t�@�C���o��(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/02/23    1.0   S.Yamashita      �V�K�쐬
 *  2018/05/16    1.1   K.Kiriu          E_�{�ғ�_14989�Ή�
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCSO020A07C';              -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcso          CONSTANT VARCHAR2(10)  := 'XXCSO';                     -- XXCSO
  -- ���t����
  cv_format_fmt1              CONSTANT VARCHAR2(50)  := 'YYYYMMDD';
  cv_format_fmt2              CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  --
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                         -- �����񊇂�
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- �J���}
  cv_colon                    CONSTANT VARCHAR2(2)   := '�F';                        -- �R����
  cv_prt_line                 CONSTANT VARCHAR2(4)   := ' �| ';                      -- �n�C�t��
  -- ���b�Z�[�W�R�[�h
  cv_msg_cso_00011            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00011';          -- �Ɩ��������t�擾�G���[
  cv_msg_cso_00671            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00671';          -- ���̓p�����[�^�p������
  cv_msg_cso_00644            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00644';          -- ���o�Ώۓ����ԑ召�`�F�b�N�G���[
  cv_msg_cso_00723            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00723';          -- SP�ꌈ�����CSV�w�b�_1
  cv_msg_cso_00724            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00724';          -- SP�ꌈ�����CSV�w�b�_2
  cv_msg_cso_00731            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00731';          -- �N
  cv_msg_cso_00732            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00732';          -- ��
  cv_msg_cso_00733            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00733';          -- ��
  cv_msg_cso_00734            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00734';          -- �L
  cv_msg_cso_00735            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00735';          -- ��
--
  -- �g�[�N��
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                -- ���ږ�
  cv_tkn_param_value          CONSTANT VARCHAR2(20)  := 'PARAM_VALUE';               -- ���ڒl
  cv_tkn_date_from            CONSTANT VARCHAR2(20)  := 'DATE_FROM';                 -- �Ώۓ�(FROM)
  cv_tkn_date_to              CONSTANT VARCHAR2(20)  := 'DATE_TO';                   -- �Ώۓ�(TO)
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- ����
--
  cv_tkn_val_00697            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00697';          -- ���㋒�_
  cv_tkn_val_00707            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00707';          -- �ڋq�R�[�h
  cv_tkn_val_00725            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00725';          -- �\�����_
  cv_tkn_val_00726            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00726';          -- �\����(FROM)
  cv_tkn_val_00727            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00727';          -- �\����(TO)
  cv_tkn_val_00728            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00728';          -- �X�e�[�^�X
  cv_tkn_val_00729            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00729';          -- ����敪
--
  -- �Q�ƃ^�C�v��
  cv_lookup_type_01           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_STATUS_CD';          -- SP�ꌈ�X�e�[�^�X
  cv_lookup_type_02           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_APPLICATION_TYPE';   -- SP�ꌈ�\���敪
  cv_lookup_type_03           CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_SHO';        -- �Ƒԏ�����
  cv_lookup_type_04           CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_KBN';        -- �Ƒԋ敪
  cv_lookup_type_05           CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_VD_SECCHI_BASYO';   -- �ݒu�ꏊ
  cv_lookup_type_06           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_OPEN_CLOSE_TYPE';    -- SP�ꌈ�����I�[�v���N���[�Y�敪
  cv_lookup_type_07           CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_KOKYAKU_STATUS';    -- �ڋq�X�e�[�^�X
  cv_lookup_type_08           CONSTANT VARCHAR2(30)  := 'XXCSO1_CSI_JOB_KBN';           -- ��Ƌ敪�^�C�v
  cv_lookup_type_09           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_STANDARD_TYPE';      -- SP�ꌈ�K�i���O�敪
  cv_lookup_type_10           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_BUSINESS_COND';      -- SP�ꌈ��������敪
  cv_lookup_type_11           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_ALL_CONTAINER_TYPE'; -- SP�ꌈ�S�e��敪
  cv_lookup_type_12           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_BIDDING_ITEM_TYPE';  -- SP�ꌈ���D�Č��敪
  cv_lookup_type_13           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_PRESENCE_OR_ABSENCE';-- SP�ꌈ�L���敪
  cv_lookup_type_14           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_TAX_DIVISION';       -- SP�ꌈ�ŋ敪
  cv_lookup_type_15           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_INST_SUPP_PAY_TYPE'; -- SP�ꌈ�x�������i�ݒu���^���j
  cv_lookup_type_16           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_ERECTRIC_PRESENCE';  -- SP�ꌈ�L���敪�i�d�C��j
  cv_lookup_type_17           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_ELECTRIC_PAY_TYPE';  -- SP�ꌈ�x�������i�d�C��j
  cv_lookup_type_18           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_ELEC_PAY_CNG_TYPE';  -- SP�ꌈ�x�������i�ϓ��d�C��j
  cv_lookup_type_19           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_ELECTRIC_BILL_TYPE'; -- SP�ꌈ�d�C��敪
  cv_lookup_type_20           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_ELEC_PAY_CYCLE';     -- SP�ꌈ�x���T�C�N���i�d�C��j
  cv_lookup_type_21           CONSTANT VARCHAR2(30)  := 'XXCSO1_MONTHS_TYPE';           -- ���^�C�v
  cv_lookup_type_22           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_INTRO_CHG_PAY_TYPE'; -- SP�ꌈ�x�������i�Љ�萔���j
  cv_lookup_type_23           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_TRANSFER_FEE_TYPE';  -- SP�ꌈ�U���萔�����S�敪
  cv_lookup_type_24           CONSTANT VARCHAR2(30)  := 'XXCSO1_DETAILS_OF_PAYMENT';    -- �x�����׏��^�C�v
  cv_lookup_type_25           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_WORK_REQUEST_TYPE';  -- SP�ꌈ��ƈ˗��敪
  cv_lookup_type_26           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_APPROVAL_STATE_TYPE';-- SP�ꌈ�񑗏�ԋ敪
  cv_lookup_type_27           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_DECISION_CONTENT';   -- SP�ꌈ���ٓ��e
--
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- �L��
  cv_output_log               CONSTANT VARCHAR2(3)   := 'LOG';                       -- �o�͋敪�F���O
--
  cv_presence_kbn_0           CONSTANT VARCHAR2(1)   := '0';                         -- �L���敪:0�i���j
  cv_kbn_1                    CONSTANT VARCHAR2(1)   := '1';                         -- ����敪:1
  cv_kbn_2                    CONSTANT VARCHAR2(1)   := '2';                         -- ����敪:2
  cv_status_3                 CONSTANT VARCHAR2(1)   := '3';                         -- SP�ꌈ�X�e�[�^�X:3�i�L���j
  cv_cust_class_1             CONSTANT VARCHAR2(1)   := '1';                         -- �ڋq�敪:1
  cv_cust_class_2             CONSTANT VARCHAR2(1)   := '2';                         -- �ڋq�敪:2
  cv_cust_class_3             CONSTANT VARCHAR2(1)   := '3';                         -- �ڋq�敪:3
  cv_cust_class_4             CONSTANT VARCHAR2(1)   := '4';                         -- �ڋq�敪:4
  cv_cust_class_5             CONSTANT VARCHAR2(1)   := '5';                         -- �ڋq�敪:5
  cv_decision_sends_10        CONSTANT VARCHAR2(2)   := '10';                        -- �񑗐�:10�i�m�F�ҁj
  cv_decision_sends_20        CONSTANT VARCHAR2(2)   := '20';                        -- �񑗐�:20�i���F�ҁj
  cv_decision_sends_30        CONSTANT VARCHAR2(2)   := '30';                        -- �񑗐�:30�i�n��c�ƊǗ��ے��j
  cv_decision_sends_40        CONSTANT VARCHAR2(2)   := '40';                        -- �񑗐�:40�i�n��c�ƕ����j
  cv_decision_sends_50        CONSTANT VARCHAR2(2)   := '50';                        -- �񑗐�:50�i�֌W��j
  cv_decision_sends_60        CONSTANT VARCHAR2(2)   := '60';                        -- �񑗐�:60�i���̋@���ے��j
  cv_decision_sends_70        CONSTANT VARCHAR2(2)   := '70';                        -- �񑗐�:70�i���̋@�����j
  cv_decision_sends_80        CONSTANT VARCHAR2(2)   := '80';                        -- �񑗐�:80�i���_�Ǘ������j
  cv_decision_sends_90        CONSTANT VARCHAR2(2)   := '90';                        -- �񑗐�:90�i�c�Ɩ{�����j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_base_code                xxcso_sp_decision_headers.app_base_code%TYPE; -- �\��(����)���_
  gd_date_from                DATE;                                         -- �\����(FROM)
  gd_date_to                  DATE;                                         -- �\����(TO)
  gt_status                   xxcso_sp_decision_headers.status%TYPE;        -- �X�e�[�^�X
  gt_customer_cd              xxcso_cust_accounts_v.account_number%TYPE;    -- �ڋq�R�[�h
  gv_kbn                      VARCHAR2(1);                                  -- ����敪
  gd_process_date             DATE;                                         -- �Ɩ����t
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- SP�ꌈ�����J�[�\��
  CURSOR get_sp_cur
  IS
    SELECT /*+ INDEX(xsdh XXCSO_SP_DECISION_HEADERS_N01) */
     TO_CHAR(xsdh.last_update_date,cv_format_fmt2)           AS last_update_date              -- �ŏI�X�V����
    ,xsdh.sp_decision_number                                 AS sp_decision_number            -- SP�ꌈ���ԍ�
    ,xsdh.status                                             AS status                        -- �X�e�[�^�X
    ,xsdh.application_type                                   AS application_type              -- �\���敪
    ,TO_CHAR(xsdh.application_date,cv_format_fmt2)           AS application_date              -- �\����
    ,TO_CHAR(xsdh.approval_complete_date,cv_format_fmt2)     AS approval_complete_date        -- ���F������
    ,xsdh.application_code                                   AS application_code              -- �\����
    ,xsdh.app_base_code                                      AS app_base_code                 -- �\�����_
    ,xca.account_number                                      AS account_number                -- �ڋq�R�[�h
    ,DECODE(xsdh.status,cv_status_3,xca.party_name
                                   ,xsdc1.party_name)        AS account_name                  -- �ڋq��
    ,DECODE(xsdh.status,cv_status_3,xca.organization_name_phonetic
                                   ,xsdc1.party_name_alt)    AS account_name_alt              -- �ڋq���J�i
    ,DECODE(xsdh.status,cv_status_3,xca.established_site_name
                                   ,xsdc1.install_name)      AS install_name                  -- �ݒu�於
    ,DECODE(xsdh.status,cv_status_3,hl.postal_code
                                   ,xsdc1.postal_code)       AS install_postal_code           -- �ݒu��X�֔ԍ�
    ,DECODE(xsdh.status,cv_status_3,hl.state
                                   ,xsdc1.state)             AS install_state                 -- �ݒu��s���{��
    ,DECODE(xsdh.status,cv_status_3,hl.city
                                   ,xsdc1.city)              AS install_city                  -- �ݒu��s�E��
    ,DECODE(xsdh.status,cv_status_3,hl.address1
                                   ,xsdc1.address1)          AS install_address1              -- �ݒu��Z��1
    ,DECODE(xsdh.status,cv_status_3,hl.address2
                                   ,xsdc1.address2)          AS install_address2              -- �ݒu��Z��2
    ,DECODE(xsdh.status,cv_status_3,hl.address_lines_phonetic
                             ,xsdc1.address_lines_phonetic)  AS install_phone_number          -- �ݒu��d�b�ԍ�
    ,DECODE(xsdh.status,cv_status_3,xca.business_low_type
                            ,xsdc1.business_condition_type)  AS business_low_type             -- �Ƒԁi�����ށj
    ,DECODE(xsdh.status,cv_status_3,xca.industry_div
                                  ,xsdc1.business_type)      AS business_type                 -- �Ǝ�
    ,DECODE(xsdh.status,cv_status_3,xca.establishment_location
                                    ,xsdc1.install_location) AS install_location              -- �ݒu�ꏊ
    ,DECODE(xsdh.status,cv_status_3,xca.open_close_div
                        ,xsdc1.external_reference_opcl_type) AS open_close_div                -- �I�[�v��/�N���[�Y
    ,DECODE(xsdh.status,cv_status_3,xca.employees
                                   ,xsdc1.employee_number)   AS employee                      -- �Ј���
    ,DECODE(xsdh.status,cv_status_3,xca.sale_base_code
                                   ,xsdc1.publish_base_code) AS sale_base_code                -- �S�����_
    ,TO_CHAR(xsdh.install_date,cv_format_fmt2)               AS install_date                  -- �ݒu��
    ,xsdh.lease_company                                      AS lease_company                 -- ���[�X������
    ,xca.customer_status                                     AS customer_status               -- �ڋq�X�e�[�^�X
    ,(SELECT employee_number AS employee_number
      FROM   xxcso_cust_resources_v2 xcrv2
      WHERE  xcrv2.cust_account_id = xca.cust_account_id
      )                                                      AS sale_employee_number          -- �S���c�ƈ��R�[�h
    ,(SELECT full_name AS full_name
      FROM   xxcso_employees_v2 xev2
      WHERE  xev2.user_name = (SELECT employee_number AS employee_number
                               FROM   xxcso_cust_resources_v2 xcrv2
                               WHERE  xcrv2.cust_account_id = xca.cust_account_id
                               )
      )                                                      AS sale_employee_name            -- �S���c�ƈ���
    ,xcc.contract_number                                     AS contract_number               -- �_���R�[�h
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.party_name,
                                   xcc.contract_name)        AS contract_name                 -- �_��於
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.party_name_alt,
                                   xcc.contract_name_kana)   AS contract_name_alt             -- �_��於�J�i
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.postal_code,
                                   xcc.post_code)            AS contract_post_code            -- �_���X�֔ԍ�
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.state,
                                   xcc.prefectures)          AS contract_state                -- �_���s���{��
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.city,
                                   xcc.city_ward)            AS contract_city                 -- �_���s�E��
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.address1,
                                   xcc.address_1)            AS contract_address_1            -- �_���Z��1
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.address2,
                                   xcc.address_2)            AS contract_address_2            -- �_���Z��2
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.address_lines_phonetic,
                                   xcc.phone_number)         AS contract_phone_number         -- �_���d�b�ԍ�
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.representative_name,
                                   xcc.delegate_name)        AS contract_delegate_name        -- �_����\�Җ�
    ,xsdh.newold_type                                        AS newold_type                   -- �V�䋌��敪
    ,xsdh.maker_code                                         AS maker_code                    -- ���[�J�[�R�[�h
    ,xsdh.un_number                                          AS un_number                     -- �@��R�[�h
    ,xsdh.sele_number                                        AS sele_number                   -- �Z����
    ,xsdh.standard_type                                      AS standard_type                 -- �K�i���O�敪
    ,xsdh.condition_business_type                            AS condition_business_type       -- ��������敪
    ,xsdh.all_container_type                                 AS all_container_type            -- �S�e��敪
    ,xsdh.contract_year_date                                 AS contract_year_date            -- �_��N��
    ,xsdh.contract_year_month                                AS contract_year_month           -- �_�񌎐�
    ,xsdh.contract_start_year                                AS contract_start_year           -- �_����ԊJ�n�i�N�j
    ,xsdh.contract_start_month                               AS contract_start_month          -- �_����ԊJ�n�i���j
    ,xsdh.contract_end_year                                  AS contract_end_year             -- �_����ԏI���i�N�j
    ,xsdh.contract_end_month                                 AS contract_end_month            -- �_����ԏI���i���j
-- Ver1.1 Add Start
    ,xsdh.construction_start_year                            AS construction_start_year       -- �H���J�n�i�N�j
    ,xsdh.construction_start_month                           AS construction_start_month      -- �H���J�n�i���j
    ,xsdh.construction_end_year                              AS construction_end_year         -- �H���I���i�N�j
    ,xsdh.construction_end_month                             AS construction_end_month        -- �H���I���i���j
    ,xsdh.installation_start_year                            AS installation_start_year       -- �ݒu�����݊��ԊJ�n�i�N�j
    ,xsdh.installation_start_month                           AS installation_start_month      -- �ݒu�����݊��ԊJ�n�i���j
    ,xsdh.installation_end_year                              AS installation_end_year         -- �ݒu�����݊��ԏI���i�N�j
    ,xsdh.installation_end_month                             AS installation_end_month        -- �ݒu�����݊��ԏI���i���j
-- Ver1.1 Add End
    ,xsdh.bidding_item                                       AS bidding_item                  -- ���D�Č�
    ,xsdh.cancell_before_maturity                            AS cancell_before_maturity       -- ���r������
    ,xsdh.ad_assets_type                                     AS ad_assets_type                -- �s�����Y�g�p��
    ,xsdh.ad_assets_amt                                      AS ad_assets_amt                 -- �s�����Y�g�p�����z
    ,xsdh.ad_assets_this_time                                AS ad_assets_this_time           -- �s�����Y�g�p���i����x���j
    ,xsdh.ad_assets_payment_year                             AS ad_assets_payment_year        -- �s�����Y�g�p���N��
    ,TO_CHAR(xsdh.ad_assets_payment_date,cv_format_fmt2)     AS ad_assets_payment_date        -- �s�����Y�g�p���x������
    ,xsdh.tax_type                                           AS tax_type                      -- �o�����ŋ敪
    ,xsdh.install_supp_type                                  AS install_supp_type             -- �ݒu���^��
    ,xsdh.install_supp_payment_type                          AS install_supp_payment_type     -- �ݒu���^���敪
    ,xsdh.install_supp_amt                                   AS install_supp_amt              -- �ݒu���^�����z
    ,xsdh.install_supp_this_time                             AS install_supp_this_time        -- �ݒu���^���i����x���j
    ,xsdh.install_supp_payment_year                          AS install_supp_payment_year     -- �ݒu���^���N��
    ,TO_CHAR(xsdh.install_supp_payment_date,cv_format_fmt2)  AS install_supp_payment_date     -- �ݒu���^���x������
    ,xsdh.electricity_type                                   AS electricity_type              -- �d�C��
    ,xsdh.electric_payment_type                              AS electric_payment_type         -- �d�C��_���
    ,xsdh.electric_payment_change_type                       AS electric_payment_change_type  -- �d�C��敪
    ,xsdh.electricity_amount                                 AS electricity_amount            -- �d�C����z
    ,xsdh.electricity_type                                   AS electricity_change_type       -- �d�C��ϓ��敪
    ,xsdh.electric_payment_cycle                             AS electric_payment_cycle        -- �d�C��x���T�C�N��
    ,xsdh.electric_closing_date                              AS electric_closing_date         -- �d�C����ߓ�
    ,xsdh.electric_trans_month                               AS electric_trans_month          -- �d�C��U����
    ,xsdh.electric_trans_date                                AS electric_trans_date           -- �d�C��U����
    ,xsdh.electric_trans_name                                AS electric_trans_name           -- �d�C��_���ȊO��
    ,xsdh.electric_trans_name_alt                            AS electric_trans_name_alt       -- �d�C��_���ȊO���i�J�i�j
    ,xsdh.intro_chg_type                                     AS intro_chg_type                -- �Љ�萔��
    ,xsdh.intro_chg_payment_type                             AS cust_cointro_chg_payment_type -- �Љ�萔���敪
    ,xsdh.intro_chg_amt                                      AS intro_chg_amt                 -- �Љ�萔�����z
    ,xsdh.intro_chg_this_time                                AS intro_chg_this_time           -- �Љ�萔���i����x���j
    ,xsdh.intro_chg_payment_year                             AS intro_chg_payment_year        -- �Љ�萔���N��
    ,TO_CHAR(xsdh.intro_chg_payment_date,cv_format_fmt2)     AS intro_chg_payment_date        -- �Љ�萔���x������
    ,xsdh.intro_chg_per_sales_price                          AS intro_chg_per_sales_price     -- �Љ�萔����
    ,xsdh.intro_chg_per_piece                                AS intro_chg_per_piece           -- �Љ�萔���~
    ,xsdh.intro_chg_closing_date                             AS intro_chg_closing_date        -- �Љ�萔�����ߓ�
    ,xsdh.intro_chg_trans_month                              AS intro_chg_trans_month         -- �Љ�萔���U����
    ,xsdh.intro_chg_trans_date                               AS intro_chg_trans_date          -- �Љ�萔���U����
    ,xsdh.intro_chg_trans_name                               AS intro_chg_trans_name          -- �Љ�萔���_���ȊO��
    ,xsdh.intro_chg_trans_name_alt                           AS intro_chg_trans_name_alt      -- �Љ�萔���_���ȊO���i�J�i�j
    ,xsdh.condition_reason                                   AS condition_reason              -- ���ʏ����̗��R
    ,xsdh.bm1_send_type                                      AS bm1_send_type                 -- BM1���t��敪
    ,pv1.segment1                                            AS bm1_send_code                 -- BM1���t��R�[�h
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.party_name,
                                   pvs1.attribute1)          AS bm1_send_name                 -- BM1���t�於
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.party_name_alt,
                                   pv1.vendor_name_alt)      AS bm1_send_name_alt             -- BM1���t��J�i
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.postal_code,
                                   pvs1.zip)                 AS bm1_postal_code               -- BM1�X�֔ԍ�
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.address1,
                                   pvs1.address_line1)       AS bm1_address1                  -- BM1�Z��1
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.address2,
                                   pvs1.address_line2)       AS bm1_address2                  -- BM1�Z��2
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.address_lines_phonetic,
                                   pvs1.phone)               AS bm1_phone_number              -- BM1�d�b�ԍ�
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.transfer_commission_type
                                  ,pvs1.bank_charge_bearer)  AS bm1_bank_charge_bearer        -- BM1�U���萔�����S
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.bm_payment_type
                                  ,pvs1.attribute4)          AS bm1_bm_payment_type           -- BM1�x�����@�E���׏�
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.inquiry_base_code,
                                   pvs1.attribute5)          AS bm1_inquiry_base_code         -- BM1�⍇���S�����_�R�[�h
    ,pv2.segment1                                            AS bm2_send_code                 -- BM2���t��R�[�h
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.party_name,
                                   pvs2.attribute1)          AS bm2_send_name                 -- BM2���t�於
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.party_name_alt,
                                   pv2.vendor_name_alt)      AS bm2_send_name_alt             -- BM2���t��J�i
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.postal_code,
                                   pvs2.zip)                 AS bm2_postal_code               -- BM2�X�֔ԍ�
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.address1,
                                   pvs2.address_line1)       AS bm2_address1                  -- BM2�Z��1
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.address2,
                                   pvs2.address_line2)       AS bm2_address2                  -- BM2�Z��2
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.address_lines_phonetic,
                                   pvs2.phone)               AS bm2_phone_number              -- BM2�d�b�ԍ�
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.transfer_commission_type
                                  ,pvs2.bank_charge_bearer)  AS bm2_bank_charge_bearer        -- BM2�U���萔�����S
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.bm_payment_type
                                  ,pvs2.attribute4)          AS bm2_bm_payment_type           -- BM2�x�����@�E���׏�
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.inquiry_base_code,
                                   pvs2.attribute5)          AS bm2_inquiry_base_code         -- BM2�⍇���S�����_�R�[�h
    ,pv3.segment1                                            AS bm3_send_code                 -- BM3���t��R�[�h
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.party_name,
                                   pvs3.attribute1)          AS bm3_send_name                 -- BM3���t�於
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.party_name_alt,
                                   pv3.vendor_name_alt)      AS bm3_send_name_alt             -- BM3���t��J�i
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.postal_code,
                                   pvs3.zip)                 AS bm3_postal_code               -- BM3�X�֔ԍ�
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.address1,
                                   pvs3.address_line1)       AS bm3_address1                  -- BM3�Z��1
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.address2,
                                   pvs3.address_line2)       AS bm3_address2                  -- BM3�Z��2
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.address_lines_phonetic,
                                   pvs3.phone)               AS bm3_phone_number              -- BM3�d�b�ԍ�
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.transfer_commission_type
                                  ,pvs3.bank_charge_bearer)  AS bm3_bank_charge_bearer        -- BM3�U���萔�����S
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.bm_payment_type
                                  ,pvs3.attribute4)          AS bm3_bm_payment_type           -- BM3�x�����@�E���׏�
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.inquiry_base_code,
                                   pvs3.attribute5)          AS bm3_inquiry_base_code         -- BM3�⍇���S�����_�R�[�h
    ,xsdh.sales_month                                        AS sales_month                   -- ���Ԕ���
    ,xsdh.sales_year                                         AS sales_year                    -- �N�Ԕ���
    ,xsdh.sales_gross_margin_rate                            AS sales_gross_margin_rate       -- ����e����
    ,xsdh.year_gross_margin_amt                              AS year_gross_margin_amt         -- �N�ԑe�����z
    ,xsdh.bm_rate                                            AS bm_rate                       -- �a�l��
    ,xsdh.vd_sales_charge                                    AS vd_sales_charge               -- �u�c�̔��萔��
    ,xsdh.install_support_amt_year                           AS install_support_amt_year      -- �ݒu���^���^�N
    ,xsdh.lease_charge_month                                 AS lease_charge_month            -- ���[�X���i���z�j
    ,xsdh.construction_charge                                AS construction_charge           -- �H����
    ,xsdh.vd_lease_charge                                    AS vd_lease_charge               -- �u�c���[�X��
    ,xsdh.electricity_amt_month                              AS electricity_amt_month         -- �d�C��i���j
    ,xsdh.electricity_amt_year                               AS electricity_amt_year          -- �d�C��i�N�j
    ,xsdh.transportation_charge                              AS transportation_charge         -- �^����`
    ,xsdh.labor_cost_other                                   AS labor_cost_other              -- �l���
    ,xsdh.total_cost                                         AS total_cost                    -- ��p���v
    ,xsdh.operating_profit                                   AS operating_profit              -- �c�Ɨ��v
    ,xsdh.operating_profit_rate                              AS operating_profit_rate         -- �c�Ɨ��v��
    ,xsdh.break_even_point                                   AS break_even_point              -- ���v����_
    ,xsds1.approve_code                                      AS approve_code_10               -- ���F�҃R�[�h(�m�F��)
    ,xsds1.work_request_type                                 AS work_request_type_10          -- ��ƈ˗��敪(�m�F��)
    ,xsds1.approval_state_type                               AS approval_state_type_10        -- ���ُ�ԋ敪(�m�F��)
    ,TO_CHAR(xsds1.approval_date,cv_format_fmt2)             AS approval_date_10              -- ���ٓ�(�m�F��)
    ,xsds1.approval_content                                  AS approval_content_10           -- ���ٓ��e(�m�F��)
    ,xsds1.approval_comment                                  AS approval_comment_10           -- ���F�R�����g(�m�F��)
    ,xsds2.approve_code                                      AS approve_code_20               -- ���F�҃R�[�h(���F��)
    ,xsds2.work_request_type                                 AS work_request_type_20          -- ��ƈ˗��敪(���F��)
    ,xsds2.approval_state_type                               AS approval_state_type_20        -- ���ُ�ԋ敪(���F��)
    ,TO_CHAR(xsds2.approval_date,cv_format_fmt2)             AS approval_date_20              -- ���ٓ�(���F��)
    ,xsds2.approval_content                                  AS approval_content_20           -- ���ٓ��e(���F��)
    ,xsds2.approval_comment                                  AS approval_comment_20           -- ���F�R�����g(���F��)
    ,xsds3.approve_code                                      AS approve_code_30               -- ���F�҃R�[�h(�n��c�ƊǗ��ے�)
    ,xsds3.work_request_type                                 AS work_request_type_30          -- ��ƈ˗��敪(�n��c�ƊǗ��ے�)
    ,xsds3.approval_state_type                               AS approval_state_type_30        -- ���ُ�ԋ敪(�n��c�ƊǗ��ے�)
    ,TO_CHAR(xsds3.approval_date,cv_format_fmt2)             AS approval_date_30              -- ���ٓ�(�n��c�ƊǗ��ے�)
    ,xsds3.approval_content                                  AS approval_content_30           -- ���ٓ��e(�n��c�ƊǗ��ے�)
    ,xsds3.approval_comment                                  AS approval_comment_30           -- ���F�R�����g(�n��c�ƊǗ��ے�)
    ,xsds4.approve_code                                      AS approve_code_40               -- ���F�҃R�[�h(�n��c�ƕ���)
    ,xsds4.work_request_type                                 AS work_request_type_40          -- ��ƈ˗��敪(�n��c�ƕ���)
    ,xsds4.approval_state_type                               AS approval_state_type_40        -- ���ُ�ԋ敪(�n��c�ƕ���)
    ,TO_CHAR(xsds4.approval_date,cv_format_fmt2)             AS approval_date_40              -- ���ٓ�(�n��c�ƕ���)
    ,xsds4.approval_content                                  AS approval_content_40           -- ���ٓ��e(�n��c�ƕ���)
    ,xsds4.approval_comment                                  AS approval_comment_40           -- ���F�R�����g(�n��c�ƕ���)
    ,xsds5.approve_code                                      AS approve_code_50               -- ���F�҃R�[�h(�֌W��)
    ,xsds5.work_request_type                                 AS work_request_type_50          -- ��ƈ˗��敪(�֌W��)
    ,xsds5.approval_state_type                               AS approval_state_type_50        -- ���ُ�ԋ敪(�֌W��)
    ,TO_CHAR(xsds5.approval_date,cv_format_fmt2)             AS approval_date_50              -- ���ٓ�(�֌W��)
    ,xsds5.approval_content                                  AS approval_content_50           -- ���ٓ��e(�֌W��)
    ,xsds5.approval_comment                                  AS approval_comment_50           -- ���F�R�����g(�֌W��)
    ,xsds6.approve_code                                      AS approve_code_60               -- ���F�҃R�[�h(���̋@���ے�)
    ,xsds6.work_request_type                                 AS work_request_type_60          -- ��ƈ˗��敪(���̋@���ے�)
    ,xsds6.approval_state_type                               AS approval_state_type_60        -- ���ُ�ԋ敪(���̋@���ے�)
    ,TO_CHAR(xsds6.approval_date,cv_format_fmt2)             AS approval_date_60              -- ���ٓ�(���̋@���ے�)
    ,xsds6.approval_content                                  AS approval_content_60           -- ���ٓ��e(���̋@���ے�)
    ,xsds6.approval_comment                                  AS approval_comment_60           -- ���F�R�����g(���̋@���ے�)
    ,xsds7.approve_code                                      AS approve_code_70               -- ���F�҃R�[�h(���̋@����)
    ,xsds7.work_request_type                                 AS work_request_type_70          -- ��ƈ˗��敪(���̋@����)
    ,xsds7.approval_state_type                               AS approval_state_type_70        -- ���ُ�ԋ敪(���̋@����)
    ,TO_CHAR(xsds7.approval_date,cv_format_fmt2)             AS approval_date_70              -- ���ٓ�(���̋@����)
    ,xsds7.approval_content                                  AS approval_content_70           -- ���ٓ��e(���̋@����)
    ,xsds7.approval_comment                                  AS approval_comment_70           -- ���F�R�����g(���̋@����)
    ,xsds8.approve_code                                      AS approve_code_80               -- ���F�҃R�[�h(���_�Ǘ�����)
    ,xsds8.work_request_type                                 AS work_request_type_80          -- ��ƈ˗��敪(���_�Ǘ�����)
    ,xsds8.approval_state_type                               AS approval_state_type_80        -- ���ُ�ԋ敪(���_�Ǘ�����)
    ,TO_CHAR(xsds8.approval_date,cv_format_fmt2)             AS approval_date_80              -- ���ٓ�(���_�Ǘ�����)
    ,xsds8.approval_content                                  AS approval_content_80           -- ���ٓ��e(���_�Ǘ�����)
    ,xsds8.approval_comment                                  AS approval_comment_80           -- ���F�R�����g(���_�Ǘ�����)
    ,xsds9.approve_code                                      AS approve_code_90               -- ���F�҃R�[�h(�c�Ɩ{����)
    ,xsds9.work_request_type                                 AS work_request_type_90          -- ��ƈ˗��敪(�c�Ɩ{����)
    ,xsds9.approval_state_type                               AS approval_state_type_90        -- ���ُ�ԋ敪(�c�Ɩ{����)
    ,TO_CHAR(xsds9.approval_date,cv_format_fmt2)             AS approval_date_90              -- ���ٓ�(�c�Ɩ{����)
    ,xsds9.approval_content                                  AS approval_content_90           -- ���ٓ��e(�c�Ɩ{����)
    ,xsds9.approval_comment                                  AS approval_comment_90           -- ���F�R�����g(�c�Ɩ{����)
  FROM
    xxcso_sp_decision_headers  xsdh   -- SP�ꌈ�w�b�_�e�[�u��
   ,xxcso_sp_decision_custs    xsdc1  -- SP�ꌈ�ڋq�e�[�u���i�ݒu��j
   ,xxcso_sp_decision_custs    xsdc2  -- SP�ꌈ�ڋq�e�[�u���i�_���j
   ,xxcso_sp_decision_custs    xsdc3  -- SP�ꌈ�ڋq�e�[�u���i�a�l�P�j
   ,xxcso_sp_decision_custs    xsdc4  -- SP�ꌈ�ڋq�e�[�u���i�a�l�Q�j
   ,xxcso_sp_decision_custs    xsdc5  -- SP�ꌈ�ڋq�e�[�u���i�a�l�R�j
   ,xxcso_cust_accounts_v      xca    -- �ڋq�}�X�^�r���[
   ,hz_party_sites             hps    -- �p�[�e�B�T�C�g�}�X�^
   ,hz_locations               hl     -- �ڋq���ݒn�}�X�^
   ,xxcso_contract_customers   xcc    -- �_���e�[�u��
   ,po_vendors                 pv1    -- �d����}�X�^�i�a�l�P�j
   ,po_vendors                 pv2    -- �d����}�X�^�i�a�l�Q�j
   ,po_vendors                 pv3    -- �d����}�X�^�i�a�l�R�j
   ,po_vendor_sites_all        pvs1   -- �d����T�C�g�}�X�^�i�a�l�P�j
   ,po_vendor_sites_all        pvs2   -- �d����T�C�g�}�X�^�i�a�l�Q�j
   ,po_vendor_sites_all        pvs3   -- �d����T�C�g�}�X�^�i�a�l�R�j
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_10
    )                                xsds1  -- SP�ꌈ�񑗐�e�[�u���i�m�F�ҁj
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_20
    )                                xsds2  -- SP�ꌈ�񑗐�e�[�u���i���F�ҁj
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_30
    )                                xsds3  -- SP�ꌈ�񑗐�e�[�u���i�n��c�ƊǗ��ے��j
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_40
    )                                xsds4  -- SP�ꌈ�񑗐�e�[�u���i�n��c�ƕ����j
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_50
    )                                xsds5  -- SP�ꌈ�񑗐�e�[�u���i�֌W��j
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_60
    )                                xsds6  -- SP�ꌈ�񑗐�e�[�u���i���̋@���ے��j
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_70
    )                                xsds7 -- SP�ꌈ�񑗐�e�[�u���i���̋@�����j
   ,(SELECT/*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_80
    )                                xsds8  -- SP�ꌈ�񑗐�e�[�u���i���_�Ǘ������j
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_90
    )                                xsds9 -- SP�ꌈ�񑗐�e�[�u���i�c�Ɩ{�����j
  WHERE
      xsdc1.sp_decision_header_id      = xsdh.sp_decision_header_id    -- SP�ꌈ�w�b�_ID
  AND xsdc1.sp_decision_customer_class = cv_cust_class_1               -- �ڋq�敪
  AND xsdc1.customer_id                = xca.cust_account_id           -- �ڋqID
  AND hps.party_id                     = xca.party_id                  -- �p�[�e�BID
  AND hl.location_id                   = hps.location_id               -- �ݒu��ID
  AND xsdc2.sp_decision_header_id      = xsdh.sp_decision_header_id    -- SP�ꌈ�w�b�_ID
  AND xsdc2.sp_decision_customer_class = cv_cust_class_2               -- �ڋq�敪
  AND xsdc2.customer_id                = xcc.contract_customer_id(+)   -- �ڋqID
  AND xsdc3.sp_decision_header_id      = xsdh.sp_decision_header_id    -- SP�ꌈ�w�b�_ID
  AND xsdc3.sp_decision_customer_class = cv_cust_class_3               -- �ڋq�敪
  AND xsdc3.customer_id                = pv1.vendor_id(+)              -- �d����ID
  AND xsdc3.customer_id                = pvs1.vendor_id(+)             -- �d����ID
  AND xsdc4.sp_decision_header_id      = xsdh.sp_decision_header_id    -- SP�ꌈ�w�b�_ID
  AND xsdc4.sp_decision_customer_class = cv_cust_class_4               -- �ڋq�敪
  AND xsdc4.customer_id                = pv2.vendor_id(+)              -- �d����ID
  AND xsdc4.customer_id                = pvs2.vendor_id(+)             -- �d����ID
  AND xsdc5.sp_decision_header_id      = xsdh.sp_decision_header_id    -- SP�ꌈ�w�b�_ID
  AND xsdc5.sp_decision_customer_class = cv_cust_class_5               -- �ڋq�敪
  AND xsdc5.customer_id                = pv3.vendor_id(+)              -- �d����ID
  AND xsdc5.customer_id                = pvs3.vendor_id(+)             -- �d����ID
  AND xsdh.sp_decision_header_id       = xsds1.sp_decision_header_id   -- SP�ꌈ�w�b�_ID
  AND xsdh.sp_decision_header_id       = xsds2.sp_decision_header_id   -- SP�ꌈ�w�b�_ID
  AND xsdh.sp_decision_header_id       = xsds3.sp_decision_header_id   -- SP�ꌈ�w�b�_ID
  AND xsdh.sp_decision_header_id       = xsds4.sp_decision_header_id   -- SP�ꌈ�w�b�_ID
  AND xsdh.sp_decision_header_id       = xsds5.sp_decision_header_id   -- SP�ꌈ�w�b�_ID
  AND xsdh.sp_decision_header_id       = xsds6.sp_decision_header_id   -- SP�ꌈ�w�b�_ID
  AND xsdh.sp_decision_header_id       = xsds7.sp_decision_header_id   -- SP�ꌈ�w�b�_ID
  AND xsdh.sp_decision_header_id       = xsds8.sp_decision_header_id   -- SP�ꌈ�w�b�_ID
  AND xsdh.sp_decision_header_id       = xsds9.sp_decision_header_id   -- SP�ꌈ�w�b�_ID
  AND (((gv_kbn = cv_kbn_1)                                                 -- ����敪��'1'�̏ꍇ
      AND ((gt_base_code IS NOT NULL AND xsdh.app_base_code = gt_base_code) -- ���̓p�����[�^.�\��(����)���_��NOT NULL�̏ꍇ
        OR (gt_base_code IS NULL                                            -- ���̓p�����[�^.�\��(����)���_��NULL�̏ꍇ
              AND gt_customer_cd IS NULL                                    -- ���̓p�����[�^.�ڋq�R�[�h��NULL�̏ꍇ
              AND EXISTS(SELECT 'X'
                         FROM   xxcso_sp_sec_base_info_v xssbi
                         WHERE  xsdh.app_base_code = xssbi.base_code
                         )                                                  -- SP�ꌈ�Z�L�����e�B���_�r���[�̋��_���擾
           )
        OR (gt_base_code IS NULL AND gt_customer_cd IS NOT NULL)            -- �ڋq�̂ݎw�肳�ꂽ�ꍇ
          )
         )
     OR ((gv_kbn = cv_kbn_2)                                                -- ����敪��'2'�̏ꍇ
      AND ((gt_base_code IS NOT NULL                                        -- ���̓p�����[�^.�\��(����)���_��NOT NULL�̏ꍇ
             AND DECODE(xsdh.status,cv_status_3,xca.sale_base_code
                                   ,xsdc1.publish_base_code) = gt_base_code)
       OR (gt_base_code IS NULL                                             -- ���̓p�����[�^.�\��(����)���_��NULL�̏ꍇ
            AND gt_customer_cd IS NULL                                      -- ���̓p�����[�^.�ڋq�R�[�h��NULL�̏ꍇ
            AND EXISTS(SELECT 'X'
                       FROM   xxcso_sp_sec_base_info_v xssbi
                       WHERE  (DECODE(xsdh.status,cv_status_3,xca.sale_base_code
                             ,xsdc1.publish_base_code) = xssbi.base_code)   -- SP�ꌈ�Z�L�����e�B���_�r���[�̋��_���擾
                      )
          )
       OR (gt_base_code IS NULL AND gt_customer_cd IS NOT NULL)             -- �ڋq�̂ݎw�肳�ꂽ�ꍇ
         )
        )
      )
  AND xsdh.application_date >= gd_date_from       -- �\�����iFROM)
  AND xsdh.application_date <= gd_date_to         -- �\�����iTO)
  AND ((gt_status IS NOT NULL                     -- ���̓p�����[�^.�X�e�[�^�X��NOT NULL�̏ꍇ
          AND xsdh.status = gt_status)
       OR (gt_status IS NULL)                     -- ���̓p�����[�^.�X�e�[�^�X��NULL�̏ꍇ
      )
  AND ((gt_customer_cd IS NOT NULL                -- ���̓p�����[�^.�ڋq�R�[�h��NOT NULL�̏ꍇ
          AND xca.account_number = gt_customer_cd)
       OR (gt_customer_cd IS NULL)                -- ���̓p�����[�^.�ڋq�R�[�h��NULL�̏ꍇ
      )
  ORDER BY xsdh.sp_decision_number ASC
  ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code     IN  VARCHAR2     -- �\��(����)���_
   ,iv_app_date_from IN  VARCHAR2     -- �\����(FROM)
   ,iv_app_date_to   IN  VARCHAR2     -- �\����(TO)
   ,iv_status        IN  VARCHAR2     -- �X�e�[�^�X
   ,iv_customer_cd   IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_kbn           IN  VARCHAR2     -- ����敪
   ,ov_errbuf        OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode       OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg        OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_base_code       VARCHAR2(1000);  -- 1.�\��(����)���_
    lv_app_date_from   VARCHAR2(1000);  -- 2.�\����(FROM)
    lv_app_date_to     VARCHAR2(1000);  -- 3.�\����(TO)
    lv_status          VARCHAR2(1000);  -- 4.�X�e�[�^�X
    lv_customer_cd     VARCHAR2(1000);  -- 5.�ڋq�R�[�h
    lv_kbn             VARCHAR2(1000);  -- 6.����敪
    lv_csv_header      VARCHAR2(5000);  -- CSV�w�b�_���ڏo�͗p
--
    lv_status_name     VARCHAR2(30);    -- SP�ꌈ�X�e�[�^�X��
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
    gt_base_code   := iv_base_code;
    gd_date_from   := TO_DATE( iv_app_date_from , cv_format_fmt1 );
    gd_date_to     := TO_DATE( iv_app_date_to   , cv_format_fmt1 );
    gt_status      := iv_status;
    gt_customer_cd := iv_customer_cd;
    gv_kbn         := iv_kbn;
    --==============================================================
    --���[�J���ϐ���������
    --==============================================================
    lv_base_code     := NULL;
    lv_app_date_from := NULL;
    lv_app_date_to   := NULL;
    lv_status        := NULL;
    lv_customer_cd   := NULL;
    lv_kbn           := NULL;
    lv_csv_header    := NULL;
    lv_status_name   := NULL;
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
    -- SP�ꌈ�X�e�[�^�X�����擾
    --==================================================
    IF ( gt_status IS NOT NULL ) THEN
      BEGIN
        SELECT flvv.meaning AS status_name  -- SP�ꌈ�X�e�[�^�X��
        INTO   lv_status_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type  = cv_lookup_type_01  -- SP�ꌈ�X�e�[�^�X
        AND    flvv.enabled_flag = cv_flag_y
        AND    gd_process_date  >= NVL(flvv.start_date_active, gd_process_date)
        AND    gd_process_date  <= NVL(flvv.end_date_active  , gd_process_date)
        AND    flvv.lookup_code  = gt_status
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_status_name := NULL;
      END;
--
      -- �R������ǉ�
      IF ( lv_status_name IS NOT NULL ) THEN
        lv_status_name := cv_colon || lv_status_name;
      END IF;
    END IF;
--
    --==================================================
    --���̓p�����[�^�����b�Z�[�W�o��
    --==================================================
    -- ����(�\��)���_
    IF ( gv_kbn = cv_cust_class_1 ) THEN
      -- �\�����_
      lv_base_code   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_val_00725              -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                         ,iv_token_value2 => iv_base_code                  -- �g�[�N���l2
                        );
    ELSE
      -- ���㋒�_
      lv_base_code   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_val_00697              -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                         ,iv_token_value2 => iv_base_code                  -- �g�[�N���l2
                        );
    END IF;
    -- �\����(FROM)
    lv_app_date_from := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_val_00726              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_app_date_from              -- �g�[�N���l2
                      );
    -- �\����(TO)
    lv_app_date_to := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_val_00727              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_app_date_to                -- �g�[�N���l2
                      );
    -- �X�e�[�^�X
      lv_status      := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_tkn_val_00728              -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                         ,iv_token_value2 => iv_status                     -- �g�[�N���l2
                        ) || lv_status_name
                        ;
    -- �ڋq�R�[�h
    lv_customer_cd := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_val_00707              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_customer_cd                -- �g�[�N���l2
                      );
    -- ����敪
    lv_kbn         := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00671              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_val_00729              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_param_value            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_kbn                        -- �g�[�N���l2
                      );
--
    -- ���O�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''               || CHR(10) ||
                 lv_base_code     || CHR(10) ||      -- 1.�\��(����)���_
                 lv_app_date_from || CHR(10) ||      -- 2.�\����(FROM)
                 lv_app_date_to   || CHR(10) ||      -- 3.�\����(TO)
                 lv_status        || CHR(10) ||      -- 4.�X�e�[�^�X
                 lv_customer_cd   || CHR(10) ||      -- 5.�ڋq�R�[�h
                 lv_kbn                              -- 6.����敪
    );
--
    --==================================================
    -- ���t�t�]�`�F�b�N
    --==================================================
    -- �\����(TO)�Ɛ\����(TO)�̔�r
    IF ( gd_date_from > gd_date_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso
         ,iv_name         => cv_msg_cso_00644
         ,iv_token_name1  => cv_tkn_date_from
         ,iv_token_value1 => cv_tkn_val_00726
         ,iv_token_name2  => cv_tkn_date_to
         ,iv_token_value2 => cv_tkn_val_00727
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- CSV�w�b�_���ڏo��
    --==================================================
    lv_csv_header := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcso
                      ,iv_name         => cv_msg_cso_00723
                     ) ||
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcso
                      ,iv_name         => cv_msg_cso_00724
                     )
                     ;
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
--#################################  �Œ��O������ START   ####################################--
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
   * Procedure Name   : output_sp_data
   * Description      : SP�ꌈ�����擾�E�o��(A-2,A-3)
   ***********************************************************************************/
  PROCEDURE output_sp_data(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sp_data'; -- �v���O������
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
    lv_output_str                     VARCHAR2(5000);-- �o�͕�����i�[�p�ϐ�
    -- ���ڕҏW�p�ϐ�
    lv_status                         VARCHAR2(100); -- �X�e�[�^�X
    lv_application_type               VARCHAR2(100); -- �\���敪
    lv_application_code               VARCHAR2(360); -- �\����
    lv_app_base_code                  VARCHAR2(100); -- �\�����_
    lv_business_low_type              VARCHAR2(100); -- �Ƒԁi�����ށj
    lv_business_type                  VARCHAR2(100); -- �Ǝ�
    lv_install_location               VARCHAR2(100); -- �ݒu�ꏊ
    lv_open_close_div                 VARCHAR2(100); -- �I�[�v��/�N���[�Y
    lv_sale_base_code                 VARCHAR2(100); -- �S�����_
    lv_customer_status                VARCHAR2(200); -- �ڋq�X�e�[�^�X
    lv_newold_type                    VARCHAR2(100); -- �V�䋌��敪
    lv_standard_type                  VARCHAR2(100); -- �K�i���O�敪
    lv_condition_business_type        VARCHAR2(100); -- ��������敪
    lv_all_container_type             VARCHAR2(100); -- �S�e��敪
    lv_contract_period                VARCHAR2(100); -- �_�����
-- Ver1.1 Add Start
    lv_construction_period            VARCHAR2(100); -- �H��
    lv_installation_period            VARCHAR2(100); -- �ݒu�����݊���
-- Ver1.1 Add End
    lv_bidding_item                   VARCHAR2(100); -- ���D�Č�
    lv_cancell_before_maturity        VARCHAR2(100); -- ���r������
    lv_ad_assets_type                 VARCHAR2(100); -- �s�����Y�g�p��
    lv_tax_type                       VARCHAR2(100); -- �o�����ŋ敪
    lv_install_supp_type              VARCHAR2(100); -- �ݒu���^��
    lv_install_supp_payment_type      VARCHAR2(100); -- �ݒu���^���敪
    lv_electricity_type               VARCHAR2(100); -- �d�C��
    lv_electric_payment_type          VARCHAR2(100); -- �d�C��_���
    lv_electric_pay_change_type       VARCHAR2(100); -- �d�C��敪
    lv_electricity_change_type        VARCHAR2(100); -- �d�C��ϓ��敪
    lv_electric_payment_cycle         VARCHAR2(100); -- �d�C��x���T�C�N��
    lv_electric_trans_date            VARCHAR2(100); -- �d�C��U����
    lv_intro_chg_type                 VARCHAR2(100); -- �Љ�萔��
    lv_cust_cointro_chg_pay_type      VARCHAR2(100); -- �Љ�萔���敪
    lv_intro_chg_trans_date           VARCHAR2(100); -- �Љ�萔���U����
    lv_bm1_bank_charge_bearer         VARCHAR2(100); -- BM1�U���萔�����S
    lv_bm1_bm_payment_type            VARCHAR2(100); -- BM1�x�����@�E���׏�
    lv_bm2_bank_charge_bearer         VARCHAR2(100); -- BM2�U���萔�����S
    lv_bm2_bm_payment_type            VARCHAR2(100); -- BM2�x�����@�E���׏�
    lv_bm3_bank_charge_bearer         VARCHAR2(100); -- BM3�U���萔�����S
    lv_bm3_bm_payment_type            VARCHAR2(100); -- BM3�x�����@�E���׏�
    lv_approve_10                     VARCHAR2(300); -- �񑗐�E�m�F��
    lv_approve_20                     VARCHAR2(300); -- �񑗐�E���F��
    lv_approve_30                     VARCHAR2(300); -- �񑗐�E�n��c�ƊǗ��ے�
    lv_approve_40                     VARCHAR2(300); -- �񑗐�E�n��c�ƕ���
    lv_approve_50                     VARCHAR2(300); -- �񑗐�E�֌W��
    lv_approve_60                     VARCHAR2(300); -- �񑗐�E���̋@���ے�
    lv_approve_70                     VARCHAR2(300); -- �񑗐�E���̋@����
    lv_approve_80                     VARCHAR2(300); -- �񑗐�E���_�Ǘ�����
    lv_approve_90                     VARCHAR2(300); -- �񑗐�E�c�Ɩ{����
--
    -- �Q�ƃ^�C�v�擾�l�i�[�p�ϐ�
    lv_status_name                    VARCHAR2(100); -- �X�e�[�^�X��
    lv_application_type_name          VARCHAR2(100); -- �\���敪��
    lv_application_code_name          VARCHAR2(360); -- �\���Җ�
    lv_app_base_code_name             VARCHAR2(100); -- �\�����_��
    lv_business_low_type_name         VARCHAR2(100); -- �Ƒԁi�����ށj��
    lv_business_type_name             VARCHAR2(100); -- �Ǝ햼
    lv_install_location_name          VARCHAR2(100); -- �ݒu�ꏊ��
    lv_open_close_div_name            VARCHAR2(100); -- �I�[�v��/�N���[�Y��
    lv_sale_base_code_name            VARCHAR2(100); -- �S�����_��
    lv_customer_status_name           VARCHAR2(200); -- �ڋq�X�e�[�^�X��
    lv_newold_type_name               VARCHAR2(100); -- �V�䋌��敪��
    lv_standard_type_name             VARCHAR2(100); -- �K�i���O�敪��
    lv_condition_business_tp_name     VARCHAR2(100); -- ��������敪��
    lv_all_container_type_name        VARCHAR2(100); -- �S�e��敪��
    lv_bidding_item_name              VARCHAR2(100); -- ���D�Č���
    lv_cancell_before_matur_name      VARCHAR2(100); -- ���r��������
    lv_ad_assets_type_name            VARCHAR2(100); -- �s�����Y�g�p����
    lv_tax_type_name                  VARCHAR2(100); -- �o�����ŋ敪��
    lv_install_supp_type_name         VARCHAR2(100); -- �ݒu���^����
    lv_install_supp_pay_type_name     VARCHAR2(100); -- �ݒu���^���敪��
    lv_electric_pay_type_name         VARCHAR2(100); -- �d�C��_��於
    lv_electric_pay_change_tp_name    VARCHAR2(100); -- �d�C��敪��
    lv_electricity_change_tp_name     VARCHAR2(100); -- �d�C��ϓ��敪��
    lv_electric_pay_cycle_name        VARCHAR2(100); -- �d�C��x���T�C�N����
    lv_electric_trans_date_name       VARCHAR2(100); -- �d�C��U������
    lv_intro_chg_type_name            VARCHAR2(100); -- �Љ�萔����
    lv_cust_intro_chg_pay_tp_name     VARCHAR2(100); -- �Љ�萔���敪��
    lv_intro_chg_trans_date_name      VARCHAR2(100); -- �Љ�萔���U������
    lv_bm1_bank_charge_bearer_name    VARCHAR2(100); -- BM1�U���萔�����S��
    lv_bm1_bm_payment_type_name       VARCHAR2(100); -- BM1�x�����@�E���׏���
    lv_bm2_bank_charge_bearer_name    VARCHAR2(100); -- BM2�U���萔�����S��
    lv_bm2_bm_payment_type_name       VARCHAR2(100); -- BM2�x�����@�E���׏���
    lv_bm3_bank_charge_bearer_name    VARCHAR2(100); -- BM3�U���萔�����S��
    lv_bm3_bm_payment_type_name       VARCHAR2(100); -- BM3�x�����@�E���׏���
    lv_work_request_type_name_10      VARCHAR2(100); -- ��ƈ˗��敪��(�m�F��)
    lv_approval_state_type_name_10    VARCHAR2(100); -- ���ُ�ԋ敪(�m�F��)
    lv_approval_content_name_10       VARCHAR2(100); -- ���ٓ��e(�m�F��)
    lv_work_request_type_name_20      VARCHAR2(100); -- ��ƈ˗��敪��(���F��)
    lv_approval_state_type_name_20    VARCHAR2(100); -- ���ُ�ԋ敪(���F��)
    lv_approval_content_name_20       VARCHAR2(100); -- ���ٓ��e(���F��)
    lv_work_request_type_name_30      VARCHAR2(100); -- ��ƈ˗��敪��(�n��c�ƊǗ��ے�)
    lv_approval_state_type_name_30    VARCHAR2(100); -- ���ُ�ԋ敪(�n��c�ƊǗ��ے�)
    lv_approval_content_name_30       VARCHAR2(100); -- ���ٓ��e(�n��c�ƊǗ��ے�)
    lv_work_request_type_name_40      VARCHAR2(100); -- ��ƈ˗��敪��(�n��c�ƕ���)
    lv_approval_state_type_name_40    VARCHAR2(100); -- ���ُ�ԋ敪(�n��c�ƕ���)
    lv_approval_content_name_40       VARCHAR2(100); -- ���ٓ��e(�n��c�ƕ���)
    lv_work_request_type_name_50      VARCHAR2(100); -- ��ƈ˗��敪��(�֌W��)
    lv_approval_state_type_name_50    VARCHAR2(100); -- ���ُ�ԋ敪(�֌W��)
    lv_approval_content_name_50       VARCHAR2(100); -- ���ٓ��e(�֌W��)
    lv_work_request_type_name_60      VARCHAR2(100); -- ��ƈ˗��敪��(���̋@���ے�)
    lv_approval_state_type_name_60    VARCHAR2(100); -- ���ُ�ԋ敪(���̋@���ے�)
    lv_approval_content_name_60       VARCHAR2(100); -- ���ٓ��e(���̋@���ے�)
    lv_work_request_type_name_70      VARCHAR2(100); -- ��ƈ˗��敪��(���̋@����)
    lv_approval_state_type_name_70    VARCHAR2(100); -- ���ُ�ԋ敪(���̋@����)
    lv_approval_content_name_70       VARCHAR2(100); -- ���ٓ��e(���̋@����)
    lv_work_request_type_name_80      VARCHAR2(100); -- ��ƈ˗��敪��(���_�Ǘ�����)
    lv_approval_state_type_name_80    VARCHAR2(100); -- ���ُ�ԋ敪(���_�Ǘ�����)
    lv_approval_content_name_80       VARCHAR2(100); -- ���ٓ��e(���_�Ǘ�����)
    lv_work_request_type_name_90      VARCHAR2(100); -- ��ƈ˗��敪��(�c�Ɩ{����)
    lv_approval_state_type_name_90    VARCHAR2(100); -- ���ُ�ԋ敪(�c�Ɩ{����)
    lv_approval_content_name_90       VARCHAR2(100); -- ���ٓ��e(�c�Ɩ{����)
--
    lv_year                           VARCHAR2(2);   -- ������:�N
    lv_month                          VARCHAR2(2);   -- ������:��
    lv_day                            VARCHAR2(2);   -- ������:��
    lv_ari                            VARCHAR2(2);   -- ������:�L
    lv_nashi                          VARCHAR2(2);   -- ������:��
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
    -- �o�͗p�̃��b�Z�[�W���擾
    -- ������F�N
    lv_year := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00731              -- ���b�Z�[�W�R�[�h
                        );
    -- ������F��
    lv_month := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00732              -- ���b�Z�[�W�R�[�h
                        );
    -- ������F��
    lv_day  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00733              -- ���b�Z�[�W�R�[�h
                        );
    -- ������F�L
    lv_ari  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00734              -- ���b�Z�[�W�R�[�h
                        );
    -- ������F��
    lv_nashi := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00735              -- ���b�Z�[�W�R�[�h
                        );
--
    --SP�ꌈ�����J�[�\�����[�v
    << sp_loop >>
    FOR get_sp_rec IN get_sp_cur
    LOOP
      -- �ϐ�������
      lv_output_str                   := NULL; -- �o�͕�����i�[�p�ϐ�
      lv_status                       := NULL; -- SP�ꌈ�X�e�[�^�X
      lv_application_type             := NULL; -- �\���敪
      lv_application_code             := NULL; -- �\����
      lv_app_base_code                := NULL; -- �\�����_
      lv_business_low_type            := NULL; -- �Ƒԁi�����ށj
      lv_business_type                := NULL; -- �Ǝ�
      lv_install_location             := NULL; -- �ݒu�ꏊ
      lv_open_close_div               := NULL; -- �I�[�v��/�N���[�Y
      lv_sale_base_code               := NULL; -- �S�����_
      lv_customer_status              := NULL; -- �ڋq�X�e�[�^�X
      lv_newold_type                  := NULL; -- �V�䋌��敪
      lv_standard_type                := NULL; -- �K�i���O�敪
      lv_condition_business_type      := NULL; -- ��������敪
      lv_all_container_type           := NULL; -- �S�e��敪
      lv_contract_period              := NULL; -- �_�����
-- Ver1.1 Add Start
      lv_construction_period          := NULL; -- �H��
      lv_installation_period          := NULL; -- �ݒu�����݊���
-- Ver1.1 Add End
      lv_bidding_item                 := NULL; -- ���D�Č�
      lv_cancell_before_maturity      := NULL; -- ���r������
      lv_ad_assets_type               := NULL; -- �s�����Y�g�p��
      lv_tax_type                     := NULL; -- �o�����ŋ敪
      lv_install_supp_type            := NULL; -- �ݒu���^��
      lv_install_supp_payment_type    := NULL; -- �ݒu���^���敪
      lv_electricity_type             := NULL; -- �d�C��
      lv_electric_payment_type        := NULL; -- �d�C��_���
      lv_electric_pay_change_type     := NULL; -- �d�C��敪
      lv_electricity_change_type      := NULL; -- �d�C��ϓ��敪
      lv_electric_payment_cycle       := NULL; -- �d�C��x���T�C�N��
      lv_electric_trans_date          := NULL; -- �d�C��U����
      lv_intro_chg_type               := NULL; -- �Љ�萔��
      lv_cust_cointro_chg_pay_type    := NULL; -- �Љ�萔���敪
      lv_intro_chg_trans_date         := NULL; -- �Љ�萔���U����
      lv_bm1_bank_charge_bearer       := NULL; -- BM1�U���萔�����S
      lv_bm1_bm_payment_type          := NULL; -- BM1�x�����@�E���׏�
      lv_bm2_bank_charge_bearer       := NULL; -- BM2�U���萔�����S
      lv_bm2_bm_payment_type          := NULL; -- BM2�x�����@�E���׏�
      lv_bm3_bank_charge_bearer       := NULL; -- BM3�U���萔�����S
      lv_bm3_bm_payment_type          := NULL; -- BM3�x�����@�E���׏�
      lv_approve_10                   := NULL; -- �񑗐�E�m�F��
      lv_approve_20                   := NULL; -- �񑗐�E���F��
      lv_approve_30                   := NULL; -- �񑗐�E�n��c�ƊǗ��ے�
      lv_approve_40                   := NULL; -- �񑗐�E�n��c�ƕ���
      lv_approve_50                   := NULL; -- �񑗐�E�֌W��
      lv_approve_60                   := NULL; -- �񑗐�E���̋@���ے�
      lv_approve_70                   := NULL; -- �񑗐�E���̋@����
      lv_approve_80                   := NULL; -- �񑗐�E���_�Ǘ�����
      lv_approve_90                   := NULL; -- �񑗐�E�c�Ɩ{����
--
      lv_status_name                  := NULL; -- SP�ꌈ�X�e�[�^�X��
      lv_application_type_name        := NULL; -- �\���敪��
      lv_application_code_name        := NULL; -- �\���Җ�
      lv_app_base_code_name           := NULL; -- �\�����_��
      lv_business_low_type_name       := NULL; -- �Ƒԁi�����ށj��
      lv_business_type_name           := NULL; -- �Ǝ햼
      lv_install_location_name        := NULL; -- �ݒu�ꏊ��
      lv_open_close_div_name          := NULL; -- �I�[�v��/�N���[�Y�敪��
      lv_sale_base_code_name          := NULL; -- �S�����_��
      lv_customer_status_name         := NULL; -- �ڋq�X�e�[�^�X��
      lv_newold_type_name             := NULL; -- �V�䋌��敪��
      lv_standard_type_name           := NULL; -- �K�i���O�敪��
      lv_condition_business_tp_name   := NULL; -- ��������敪��
      lv_all_container_type_name      := NULL; -- �S�e��敪��
      lv_bidding_item_name            := NULL; -- ���D�Č��敪��
      lv_cancell_before_matur_name    := NULL; -- ���r�������L��
      lv_ad_assets_type_name          := NULL; -- �s�����Y�g�p���L��
      lv_tax_type_name                := NULL; -- �o�����ŋ敪��
      lv_install_supp_type_name       := NULL; -- �ݒu���^���L��
      lv_install_supp_pay_type_name   := NULL; -- �ݒu���^���敪��
      lv_electric_pay_type_name       := NULL; -- �d�C��_���敪��
      lv_electric_pay_change_tp_name  := NULL; -- �d�C��敪��
      lv_electricity_change_tp_name   := NULL; -- �d�C��ϓ��敪��
      lv_electric_pay_cycle_name      := NULL; -- �d�C��x���T�C�N����
      lv_electric_trans_date_name     := NULL; -- �d�C��U�����^�C�v
      lv_intro_chg_type_name          := NULL; -- �Љ�萔���L��
      lv_cust_intro_chg_pay_tp_name   := NULL; -- �Љ�萔���敪��
      lv_intro_chg_trans_date_name    := NULL; -- �Љ�萔���U�����^�C�v
      lv_bm1_bank_charge_bearer_name  := NULL; -- BM1�U���萔�����S��
      lv_bm1_bm_payment_type_name     := NULL; -- BM1�x�����@�E���׏���
      lv_bm2_bank_charge_bearer_name  := NULL; -- BM2�U���萔�����S��
      lv_bm2_bm_payment_type_name     := NULL; -- BM2�x�����@�E���׏���
      lv_bm3_bank_charge_bearer_name  := NULL; -- BM3�U���萔�����S��
      lv_bm3_bm_payment_type_name     := NULL; -- BM3�x�����@�E���׏���
      lv_work_request_type_name_10    := NULL; -- ��ƈ˗��敪��(�m�F��)
      lv_approval_state_type_name_10  := NULL; -- ���ُ�ԋ敪��(�m�F��)
      lv_approval_content_name_10     := NULL; -- ���ٓ��e��(�m�F��)
      lv_work_request_type_name_20    := NULL; -- ��ƈ˗��敪��(���F��)
      lv_approval_state_type_name_20  := NULL; -- ���ُ�ԋ敪��(���F��)
      lv_approval_content_name_20     := NULL; -- ���ٓ��e��(���F��)
      lv_work_request_type_name_30    := NULL; -- ��ƈ˗��敪��(�n��c�ƊǗ��ے�)
      lv_approval_state_type_name_30  := NULL; -- ���ُ�ԋ敪��(�n��c�ƊǗ��ے�)
      lv_approval_content_name_30     := NULL; -- ���ٓ��e��(�n��c�ƊǗ��ے�)
      lv_work_request_type_name_40    := NULL; -- ��ƈ˗��敪��(�n��c�ƕ���)
      lv_approval_state_type_name_40  := NULL; -- ���ُ�ԋ敪��(�n��c�ƕ���)
      lv_approval_content_name_40     := NULL; -- ���ٓ��e��(�n��c�ƕ���)
      lv_work_request_type_name_50    := NULL; -- ��ƈ˗��敪��(�֌W��)
      lv_approval_state_type_name_50  := NULL; -- ���ُ�ԋ敪��(�֌W��)
      lv_approval_content_name_50     := NULL; -- ���ٓ��e��(�֌W��)
      lv_work_request_type_name_60    := NULL; -- ��ƈ˗��敪��(���̋@���ے�)
      lv_approval_state_type_name_60  := NULL; -- ���ُ�ԋ敪��(���̋@���ے�)
      lv_approval_content_name_60     := NULL; -- ���ٓ��e��(���̋@���ے�)
      lv_work_request_type_name_70    := NULL; -- ��ƈ˗��敪��(���̋@����)
      lv_approval_state_type_name_70  := NULL; -- ���ُ�ԋ敪��(���̋@����)
      lv_approval_content_name_70     := NULL; -- ���ٓ��e��(���̋@����)
      lv_work_request_type_name_80    := NULL; -- ��ƈ˗��敪��(���_�Ǘ�����)
      lv_approval_state_type_name_80  := NULL; -- ���ُ�ԋ敪��(���_�Ǘ�����)
      lv_approval_content_name_80     := NULL; -- ���ٓ��e��(���_�Ǘ�����)
      lv_work_request_type_name_90    := NULL; -- ��ƈ˗��敪��(�c�Ɩ{����)
      lv_approval_state_type_name_90  := NULL; -- ���ُ�ԋ敪��(�c�Ɩ{����)
      lv_approval_content_name_90     := NULL; -- ���ٓ��e��(�c�Ɩ{����)
--
      -- ===============================
      -- �Q�ƃ^�C�v��荀�ږ��̂��擾
      -- ===============================
      -- SP�ꌈ�X�e�[�^�X��
      BEGIN
        SELECT meaning AS status_name
        INTO   lv_status_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_01
        AND    flvv.lookup_code = get_sp_rec.status
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_status_name := NULL;
      END;
--
      -- �\���敪��
      BEGIN
        SELECT meaning AS application_type_name
        INTO   lv_application_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_02
        AND    flvv.lookup_code = get_sp_rec.application_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_application_type_name := NULL;
      END;
--
      -- �\���Җ�
      BEGIN
        SELECT full_name AS full_name
        INTO   lv_application_code_name
        FROM   xxcso_employees_v2 xev2
        WHERE  xev2.user_name = get_sp_rec.application_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_application_code_name := NULL;
      END;
--
      -- �\�����_��
      BEGIN
        SELECT location_name AS location_name
        INTO   lv_app_base_code_name
        FROM   xxcso_locations_v2 xlv2
        WHERE  xlv2.dept_code = get_sp_rec.app_base_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_app_base_code_name := NULL;
      END;
--
      -- �Ƒԁi�����ށj��
      BEGIN
        SELECT meaning AS business_low_type_name
        INTO   lv_business_low_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_03
        AND    flvv.lookup_code = get_sp_rec.business_low_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_business_low_type_name := NULL;
      END;
--
      -- �Ǝ햼
      BEGIN
        SELECT meaning AS business_type_name
        INTO   lv_business_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_04
        AND    flvv.lookup_code = get_sp_rec.business_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_business_type_name := NULL;
      END;
--
      -- �ݒu�ꏊ��
      BEGIN
        SELECT meaning AS install_location_name
        INTO   lv_install_location_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_05
        AND    flvv.lookup_code = get_sp_rec.install_location
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_install_location_name := NULL;
      END;
--
      -- �I�[�v��/�N���[�Y�敪��
      BEGIN
        SELECT meaning AS open_close_div
        INTO   lv_open_close_div_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_06
        AND    flvv.lookup_code = get_sp_rec.open_close_div
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_open_close_div_name := NULL;
      END;
--
      -- �S�����_��
      BEGIN
        SELECT location_name AS sale_base_code_name
        INTO   lv_sale_base_code_name
        FROM   xxcso_locations_v2 xlv2
        WHERE  xlv2.dept_code = get_sp_rec.sale_base_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_sale_base_code_name := NULL;
      END;
--
      -- �ڋq�X�e�[�^�X��
      BEGIN
        SELECT meaning AS customer_status_name
        INTO   lv_customer_status_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_07
        AND    flvv.lookup_code = get_sp_rec.customer_status
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date) 
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_customer_status_name := NULL;
      END;
--
      -- �V�䋌��敪��
      BEGIN
        SELECT meaning AS newold_type_name
        INTO   lv_newold_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_08
        AND    flvv.lookup_code = get_sp_rec.newold_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_newold_type_name := NULL;
      END;
--
      -- �K�i���O�敪��
      BEGIN
        SELECT meaning AS standard_type_name
        INTO   lv_standard_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_09
        AND    flvv.lookup_code = get_sp_rec.standard_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_standard_type_name := NULL;
      END;
--
      -- ��������敪��
      BEGIN
        SELECT meaning AS condition_business_type_name
        INTO   lv_condition_business_tp_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_10
        AND    flvv.lookup_code = get_sp_rec.condition_business_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_condition_business_tp_name := NULL;
      END;
--
      -- �S�e��敪��
      BEGIN
        SELECT meaning AS all_container_type_name
        INTO   lv_all_container_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_11
        AND    flvv.lookup_code = get_sp_rec.all_container_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_all_container_type_name := NULL;
      END;
--
      -- ���D�Č��敪��
      BEGIN
        SELECT meaning AS bidding_item_name
        INTO   lv_bidding_item_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_12
        AND    flvv.lookup_code = get_sp_rec.bidding_item
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bidding_item_name := NULL;
      END;
--
      -- ���r�������L��
      BEGIN
        SELECT meaning AS cancell_before_maturity_name
        INTO   lv_cancell_before_matur_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_13
        AND    flvv.lookup_code = get_sp_rec.cancell_before_maturity
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_cancell_before_matur_name := NULL;
      END;
--
      -- �s�����Y�g�p���L��
      BEGIN
        SELECT meaning AS ad_assets_type_name
        INTO   lv_ad_assets_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_13
        AND    flvv.lookup_code = get_sp_rec.ad_assets_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_ad_assets_type_name := NULL;
      END;
--
      -- �o�����ŋ敪��
      BEGIN
        SELECT meaning AS tax_type_name
        INTO   lv_tax_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_14
        AND    flvv.lookup_code = get_sp_rec.tax_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_tax_type_name := NULL;
      END;
--
      -- �ݒu���^���L��
      BEGIN
        SELECT meaning AS install_supp_type_name
        INTO   lv_install_supp_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_13
        AND    flvv.lookup_code = get_sp_rec.install_supp_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_install_supp_type_name := NULL;
      END;
--
      -- �ݒu���^���敪��
      BEGIN
        SELECT meaning AS install_supp_payment_type_name
        INTO   lv_install_supp_pay_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_15
        AND    flvv.lookup_code = get_sp_rec.install_supp_payment_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_install_supp_pay_type_name := NULL;
      END;
--
      -- �d�C��_���敪��
      BEGIN
        SELECT meaning AS electric_payment_type_name
        INTO   lv_electric_pay_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_17
        AND    flvv.lookup_code = get_sp_rec.electric_payment_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_electric_pay_type_name := NULL;
      END;
--
      -- �d�C��敪��
      BEGIN
        SELECT meaning AS electric_change_type_name
        INTO   lv_electric_pay_change_tp_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_18
        AND    flvv.lookup_code = get_sp_rec.electric_payment_change_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(start_date_active),gd_process_date)
                   AND NVL(TRUNC(end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_electric_pay_change_tp_name := NULL;
      END;
--
      -- �d�C��ϓ��敪��
      BEGIN
        SELECT meaning AS electricity_change_type_name
        INTO   lv_electricity_change_tp_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_19
        AND    flvv.lookup_code = get_sp_rec.electricity_change_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_electricity_change_tp_name := NULL;
      END;
--
      -- �d�C��x���T�C�N����
      BEGIN
        SELECT meaning AS electric_payment_cycle_name
        INTO   lv_electric_pay_cycle_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_20
        AND    flvv.lookup_code = get_sp_rec.electric_payment_cycle
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_electric_pay_cycle_name := NULL;
      END;
--
      -- �d�C��U�����^�C�v
      BEGIN
        SELECT meaning AS electric_trans_date_name
        INTO   lv_electric_trans_date_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_21
        AND    flvv.lookup_code = get_sp_rec.electric_trans_month
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_electric_trans_date_name := NULL;
      END;
--
      -- �Љ�萔���L��
      BEGIN
        SELECT meaning AS intro_chg_type_name
        INTO   lv_intro_chg_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_13
        AND    flvv.lookup_code = get_sp_rec.intro_chg_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_intro_chg_type_name := NULL;
      END;
--
      -- �Љ�萔���敪��
      BEGIN
       SELECT meaning AS cust_payment_type_name
       INTO   lv_cust_intro_chg_pay_tp_name
       FROM   fnd_lookup_values_vl flvv
       WHERE  flvv.lookup_type = cv_lookup_type_22
       AND    flvv.lookup_code = get_sp_rec.cust_cointro_chg_payment_type
       AND    flvv.enabled_flag  = cv_flag_y
       AND    gd_process_date
              BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                  AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_cust_intro_chg_pay_tp_name := NULL;
      END;
--
      -- �Љ�萔���U�����^�C�v
      BEGIN
        SELECT meaning AS intro_chg_trans_date_name
        INTO   lv_intro_chg_trans_date_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_21
        AND    flvv.lookup_code = get_sp_rec.intro_chg_trans_month
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_intro_chg_trans_date_name := NULL;
      END;
--
      -- BM1�U���萔�����S��
      BEGIN
        SELECT meaning AS bm1_bank_charge_bearer
        INTO   lv_bm1_bank_charge_bearer_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_23
        AND    flvv.lookup_code = get_sp_rec.bm1_bank_charge_bearer
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm1_bank_charge_bearer_name := NULL;
      END;
--
      -- BM1�x�����@�E���׏���
      BEGIN
        SELECT meaning AS bm1_bm_payment_type
        INTO   lv_bm1_bm_payment_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_24
        AND    flvv.lookup_code = get_sp_rec.bm1_bm_payment_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm1_bm_payment_type_name := NULL;
      END;
--
      -- BM2�U���萔�����S��
      BEGIN
        SELECT meaning AS bm1_bank_charge_bearer
        INTO   lv_bm2_bank_charge_bearer_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_23
        AND    flvv.lookup_code = get_sp_rec.bm2_bank_charge_bearer
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm2_bank_charge_bearer_name := NULL;
      END;
--
      -- BM2�x�����@�E���׏���
      BEGIN
        SELECT meaning AS bm2_bm_payment_type
        INTO   lv_bm2_bm_payment_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_24
        AND    flvv.lookup_code = get_sp_rec.bm2_bm_payment_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm2_bm_payment_type_name := NULL;
      END;
--
      -- BM3�U���萔�����S��
      BEGIN
        SELECT meaning AS bm1_bank_charge_bearer
        INTO   lv_bm3_bank_charge_bearer_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_23
        AND    flvv.lookup_code = get_sp_rec.bm3_bank_charge_bearer
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm3_bank_charge_bearer_name := NULL;
      END;
--
      -- BM3�x�����@�E���׏���
      BEGIN
        SELECT meaning AS bm3_bm_payment_type
        INTO   lv_bm3_bm_payment_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_24
        AND    flvv.lookup_code = get_sp_rec.bm3_bm_payment_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm3_bm_payment_type_name := NULL;
      END;
--
      -- ��ƈ˗��敪��(�m�F��)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_10
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_10
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_10 := NULL;
      END;
--
      -- ���ُ�ԋ敪��(�m�F��)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_10
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_10
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_10 := NULL;
      END;
--
      -- ���ٓ��e��(�m�F��)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_10
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_10
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_10 := NULL;
      END;
--
      -- ��ƈ˗��敪��(���F��)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_20
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_20
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_20 := NULL;
      END;
--
      -- ���ُ�ԋ敪��(���F��)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_20
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_20
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_20 := NULL;
      END;
--
      -- ���ٓ��e��(���F��)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_20
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_20
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_20 := NULL;
      END;
--
      -- ��ƈ˗��敪��(�n��c�ƊǗ��ے�)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_30
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_30
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_30 := NULL;
      END;
--
      -- ���ُ�ԋ敪��(�n��c�ƊǗ��ے�)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_30
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_30
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_30 := NULL;
      END;
--
      -- ���ٓ��e��(�n��c�ƊǗ��ے�)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_30
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_30
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_30 := NULL;
      END;
--
      -- ��ƈ˗��敪��(�n��c�ƕ���)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_40
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_40
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_40 := NULL;
      END;
--
      -- ���ُ�ԋ敪��(�n��c�ƕ���)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_40
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_40
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_40 := NULL;
      END;
--
      -- ���ٓ��e��(�n��c�ƕ���)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_40
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_40
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_40 := NULL;
      END;
--
      -- ��ƈ˗��敪��(�֌W��)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_50
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_50
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_50 := NULL;
      END;
--
      -- ���ُ�ԋ敪��(�֌W��)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_50
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_50
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_50 := NULL;
      END;
--
      -- ���ٓ��e��(�֌W��)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_50
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_50
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_50 := NULL;
      END;
--
      -- ��ƈ˗��敪��(���̋@���ے�)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_60
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_60
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_60 := NULL;
      END;
--
      -- ���ُ�ԋ敪��(���̋@���ے�)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_60
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_60
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_60 := NULL;
      END;
--
      -- ���ٓ��e��(���̋@���ے�)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_60
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_60
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_60 := NULL;
      END;
--
      -- ��ƈ˗��敪��(���̋@����)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_70
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_70
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_70 := NULL;
      END;
--
      -- ���ُ�ԋ敪��(���̋@����)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_70
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_70
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_70 := NULL;
      END;
--
      -- ���ٓ��e��(���̋@����)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_70
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_70
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_70 := NULL;
      END;
--
      -- ��ƈ˗��敪��(���_�Ǘ�����)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_80
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_80
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_80 := NULL;
      END;
--
      -- ���ُ�ԋ敪��(���_�Ǘ�����)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_80
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_80
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_80 := NULL;
      END;
--
      -- ���ٓ��e��(���_�Ǘ�����)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_80
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_80
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_80 := NULL;
      END;
--
      -- ��ƈ˗��敪��(�c�Ɩ{����)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_90
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_90
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_90 := NULL;
      END;
--
      -- ���ُ�ԋ敪��(�c�Ɩ{����)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_90
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_90
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_90 := NULL;
      END;
--
      -- ���ٓ��e��(�c�Ɩ{����)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_90
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_90
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_90 := NULL;
      END;
--
      -- ===============================
      -- ���ڂ�ҏW
      -- ===============================
      -- SP�ꌈ�X�e�[�^�X
      IF ( get_sp_rec.status IS NOT NULL ) THEN
        lv_status 
          := get_sp_rec.status 
             || cv_colon
             || lv_status_name;
      END IF;
--      
      -- �\���敪
      IF ( get_sp_rec.application_type IS NOT NULL ) THEN
        lv_application_type
          := get_sp_rec.application_type
             || cv_colon
             || lv_application_type_name;
      END IF;
--
      -- �\����
      IF ( get_sp_rec.application_code IS NOT NULL ) THEN
        lv_application_code
          := get_sp_rec.application_code
             || ' '
             || lv_application_code_name;
      END IF;
--
      -- �\�����_
      IF ( get_sp_rec.app_base_code IS NOT NULL ) THEN
        lv_app_base_code
          := get_sp_rec.app_base_code
             || ' '
             || lv_app_base_code_name;
      END IF;
--
      -- �Ƒԁi�����ށj
      IF ( get_sp_rec.business_low_type IS NOT NULL ) THEN
        lv_business_low_type
          := get_sp_rec.business_low_type
             || ' '
             || lv_business_low_type_name;
      END IF;
--
      -- �Ǝ�
      IF ( get_sp_rec.business_type IS NOT NULL ) THEN
        lv_business_type
          := get_sp_rec.business_type
             || ' '
             || lv_business_type_name;
      END IF;
--
      -- �ݒu�ꏊ
      IF ( get_sp_rec.install_location IS NOT NULL ) THEN
        lv_install_location
          := get_sp_rec.install_location
             || ' '
             || lv_install_location_name;
      END IF;
--
      -- �I�[�v��/�N���[�Y
      IF ( get_sp_rec.open_close_div IS NOT NULL ) THEN
        lv_open_close_div
          := get_sp_rec.open_close_div
             || ' '
             || lv_open_close_div_name;
      END IF;
--
      -- �S�����_
      IF ( get_sp_rec.sale_base_code IS NOT NULL ) THEN
        lv_sale_base_code
          := get_sp_rec.sale_base_code
              || ' '
              || lv_sale_base_code_name;
      END IF;
--
      -- �ڋq�X�e�[�^�X
      IF ( get_sp_rec.customer_status IS NOT NULL ) THEN
        lv_customer_status
          := get_sp_rec.customer_status
             || cv_colon
             || lv_customer_status_name;
      END IF;
--
      -- �V�䋌��敪
      IF ( get_sp_rec.newold_type IS NOT NULL ) THEN
        lv_newold_type
          := get_sp_rec.newold_type
             || cv_colon
             || lv_newold_type_name;
      END IF;
--
      -- �K�i���O�敪
      IF ( get_sp_rec.standard_type IS NOT NULL ) THEN
        lv_standard_type
          := get_sp_rec.standard_type
             || cv_colon
             || lv_standard_type_name;
      END IF;
--
      -- ��������敪
      IF ( get_sp_rec.condition_business_type IS NOT NULL ) THEN
        lv_condition_business_type
          := get_sp_rec.condition_business_type
             || cv_colon
             || lv_condition_business_tp_name;
      END IF;
--
      -- �S�e��敪
      IF ( get_sp_rec.all_container_type IS NOT NULL ) THEN
        lv_all_container_type
          := get_sp_rec.all_container_type
             || cv_colon
             || lv_all_container_type_name;
      END IF;
--
      -- �_�����
      IF ( get_sp_rec.contract_start_year IS NOT NULL ) THEN
        lv_contract_period
          := get_sp_rec.contract_start_year
             || lv_year
             || get_sp_rec.contract_start_month
             || lv_month || cv_prt_line
             || get_sp_rec.contract_end_year 
             || lv_year
             || get_sp_rec.contract_end_month
             || lv_month;
      END IF;
--
-- Ver1.1 Add Start
      -- �H��
      if ( get_sp_rec.construction_start_year IS NOT NULL ) THEN
        lv_construction_period
          := TO_CHAR( get_sp_rec.construction_start_year )
                 || lv_year
                 || TO_CHAR( get_sp_rec.construction_start_month )
                 || lv_month || cv_prt_line
                 || TO_CHAR( get_sp_rec.construction_end_year )
                 || lv_year
                 || TO_CHAR( get_sp_rec.construction_end_month )
                 || lv_month;
      END IF;
--
      -- �ݒu�����݊���
      if ( get_sp_rec.installation_start_year IS NOT NULL ) THEN
        lv_installation_period
          := TO_CHAR( get_sp_rec.installation_start_year )
                 || lv_year
                 || TO_CHAR( get_sp_rec.installation_start_month )
                 || lv_month || cv_prt_line
                 || TO_CHAR( get_sp_rec.installation_end_year )
                 || lv_year
                 || TO_CHAR( get_sp_rec.installation_end_month )
                 || lv_month;
      END IF;
--
-- Ver1.1 Add End
      -- ���D�Č�
      IF ( get_sp_rec.bidding_item IS NOT NULL ) THEN
        lv_bidding_item
          := get_sp_rec.bidding_item
             || cv_colon
             || lv_bidding_item_name;
      END IF;
--
      -- ���r������
      IF ( get_sp_rec.cancell_before_maturity IS NOT NULL ) THEN
        lv_cancell_before_maturity
          := get_sp_rec.cancell_before_maturity
             || cv_colon
             || lv_cancell_before_matur_name;
      END IF;
--
      -- �s�����Y�g�p��
      IF ( get_sp_rec.ad_assets_type IS NOT NULL ) THEN
        lv_ad_assets_type
          := get_sp_rec.ad_assets_type
             || cv_colon
             || lv_ad_assets_type_name;
      END IF;
--
      -- �o�����ŋ敪
      IF ( get_sp_rec.tax_type IS NOT NULL ) THEN
        lv_tax_type
          := get_sp_rec.tax_type
             || cv_colon
             || lv_tax_type_name;
      END IF;
--
      -- �ݒu���^��
      IF ( get_sp_rec.install_supp_type IS NOT NULL ) THEN
        lv_install_supp_type
          := get_sp_rec.install_supp_type
             || cv_colon
             || lv_install_supp_type_name;
      END IF;
--
      -- �ݒu���^���敪
      IF ( get_sp_rec.install_supp_payment_type IS NOT NULL ) THEN
        lv_install_supp_payment_type
          := get_sp_rec.install_supp_payment_type
             || cv_colon
             || lv_install_supp_pay_type_name;
      END IF;
--
      -- �d�C��
      IF ( get_sp_rec.electricity_type IS NOT NULL ) THEN
        IF ( get_sp_rec.electricity_type =  cv_presence_kbn_0) THEN
          lv_electricity_type
            := get_sp_rec.electricity_type
             || cv_colon
             || lv_nashi;
        ELSE
          lv_electricity_type
            := get_sp_rec.electricity_type
             || cv_colon
             || lv_ari;
        END IF;
      END IF;
--
      -- �d�C��_���
      IF ( get_sp_rec.electric_payment_type IS NOT NULL ) THEN
        lv_electric_payment_type
          := get_sp_rec.electric_payment_type
             || cv_colon
             || lv_electric_pay_type_name;
      END IF;
--
      -- �d�C��敪
      IF ( get_sp_rec.electric_payment_change_type IS NOT NULL ) THEN
        lv_electric_pay_change_type
          := get_sp_rec.electric_payment_change_type
             || cv_colon
             || lv_electric_pay_change_tp_name;
      END IF;
--
      -- �d�C��ϓ��敪
      IF ( get_sp_rec.electricity_change_type IS NOT NULL ) THEN
        lv_electricity_change_type
          := get_sp_rec.electricity_change_type
             || cv_colon
             || lv_electricity_change_tp_name;
      END IF;
--
      -- �d�C��x���T�C�N��
      IF ( get_sp_rec.electric_payment_cycle IS NOT NULL ) THEN
        lv_electric_payment_cycle
          := get_sp_rec.electric_payment_cycle
             || cv_colon
             || lv_electric_pay_cycle_name;
      END IF;
--
      -- �d�C��U����
      IF ( get_sp_rec.electric_trans_month IS NOT NULL ) THEN
        lv_electric_trans_date
          := lv_electric_trans_date_name
             || get_sp_rec.electric_trans_date
             || lv_day;
      END IF;
--
      -- �Љ�萔��
      IF ( get_sp_rec.intro_chg_type IS NOT NULL ) THEN
        lv_intro_chg_type
          := get_sp_rec.intro_chg_type
             || cv_colon
             || lv_intro_chg_type_name;
      END IF;
--
      -- �Љ�萔���敪
      IF ( get_sp_rec.cust_cointro_chg_payment_type IS NOT NULL ) THEN
        lv_cust_cointro_chg_pay_type
          := get_sp_rec.cust_cointro_chg_payment_type
             || cv_colon
             || lv_cust_intro_chg_pay_tp_name;
      END IF;
--
      -- �Љ�萔���U����
      IF ( get_sp_rec.intro_chg_trans_month IS NOT NULL ) THEN
        lv_intro_chg_trans_date
          := lv_intro_chg_trans_date_name
             || get_sp_rec.intro_chg_trans_date
             || lv_day;
      END IF;
--
      -- BM1�U���萔�����S
      IF ( get_sp_rec.bm1_bank_charge_bearer IS NOT NULL ) THEN
        lv_bm1_bank_charge_bearer
          := lv_bm1_bank_charge_bearer_name;
      END IF;
--
      -- BM1�x�����@�E���׏�
      IF ( get_sp_rec.bm1_bm_payment_type IS NOT NULL ) THEN
        lv_bm1_bm_payment_type
          := get_sp_rec.bm1_bm_payment_type
             || cv_colon
             || lv_bm1_bm_payment_type_name;
      END IF;
--
      -- BM2�U���萔�����S
      IF ( get_sp_rec.bm2_bank_charge_bearer IS NOT NULL ) THEN
        lv_bm2_bank_charge_bearer
          := lv_bm2_bank_charge_bearer_name;
      END IF;
--
      -- BM2�x�����@�E���׏�
      IF ( get_sp_rec.bm2_bm_payment_type IS NOT NULL ) THEN
        lv_bm2_bm_payment_type
          := get_sp_rec.bm2_bm_payment_type
             || cv_colon
             || lv_bm2_bm_payment_type_name;
      END IF;
--
      -- BM3�U���萔�����S
      IF ( get_sp_rec.bm3_bank_charge_bearer IS NOT NULL ) THEN
        lv_bm3_bank_charge_bearer
          := lv_bm3_bank_charge_bearer_name;
      END IF;
--
      -- BM3�x�����@�E���׏�
      IF ( get_sp_rec.bm3_bm_payment_type IS NOT NULL ) THEN
        lv_bm3_bm_payment_type
          := get_sp_rec.bm3_bm_payment_type
             || cv_colon
             || lv_bm3_bm_payment_type_name;
      END IF;
--
      -- �񑗐�E�m�F��
      lv_approve_10
        := get_sp_rec.approve_code_10
           || ' '
           || get_sp_rec.work_request_type_10
           || cv_colon
           || lv_work_request_type_name_10
           || ' '
           || get_sp_rec.approval_state_type_10
           || cv_colon
           || lv_approval_state_type_name_10
           || ' '
           || get_sp_rec.approval_date_10
           || ' '
           || get_sp_rec.approval_content_10
           || cv_colon
           || lv_approval_content_name_10
           || ' '
           || get_sp_rec.approval_comment_10;
--
      -- �񑗐�E���F��
      lv_approve_20
        := get_sp_rec.approve_code_20
           || ' '
           || get_sp_rec.work_request_type_20
           || cv_colon
           || lv_work_request_type_name_20
           || ' '
           || get_sp_rec.approval_state_type_20
           || cv_colon
           || lv_approval_state_type_name_20
           || ' '
           || get_sp_rec.approval_date_20
           || ' '
           || get_sp_rec.approval_content_20
           || cv_colon
           || lv_approval_content_name_20
           || ' '
           || get_sp_rec.approval_comment_20;
      -- �񑗐�E�n��c�ƊǗ��ے�
      lv_approve_30
        := get_sp_rec.approve_code_30
           || ' '
           || get_sp_rec.work_request_type_30
           || cv_colon
           || lv_work_request_type_name_30
           || ' '
           || get_sp_rec.approval_state_type_30
           || cv_colon
           || lv_approval_state_type_name_30
           || ' '
           || get_sp_rec.approval_date_30
           || ' '
           || get_sp_rec.approval_content_30
           || cv_colon
           || lv_approval_content_name_30
           || ' '
           || get_sp_rec.approval_comment_30;
      -- �񑗐�E�n��c�ƕ���
      lv_approve_40
        := get_sp_rec.approve_code_40
           || ' '
           || get_sp_rec.work_request_type_40
           || cv_colon
           || lv_work_request_type_name_40
           || ' '
           || get_sp_rec.approval_state_type_40
           || cv_colon
           || lv_approval_state_type_name_40
           || ' '
           || get_sp_rec.approval_date_40
           || ' '
           || get_sp_rec.approval_content_40
           || cv_colon
           || lv_approval_content_name_40
           || ' '
           || get_sp_rec.approval_comment_40;
      -- �񑗐�E�֌W��
      lv_approve_50
        := get_sp_rec.approve_code_50
           || ' '
           || get_sp_rec.work_request_type_50
           || cv_colon
           || lv_work_request_type_name_50
           || ' '
           || get_sp_rec.approval_state_type_50
           || cv_colon
           || lv_approval_state_type_name_50
           || ' '
           || get_sp_rec.approval_date_50
           || ' '
           || get_sp_rec.approval_content_50
           || cv_colon
           || lv_approval_content_name_50
           || ' '
           || get_sp_rec.approval_comment_50;
      -- �񑗐�E���̋@���ے�
      lv_approve_60
        := get_sp_rec.approve_code_60
           || ' '
           || get_sp_rec.work_request_type_60
           || cv_colon
           || lv_work_request_type_name_60
           || ' '
           || get_sp_rec.approval_state_type_60
           || cv_colon
           || lv_approval_state_type_name_60
           || ' '
           || get_sp_rec.approval_date_60
           || ' '
           || get_sp_rec.approval_content_60
           || cv_colon
           || lv_approval_content_name_60
           || ' '
           || get_sp_rec.approval_comment_60;
      -- �񑗐�E���̋@����
      lv_approve_70
        := get_sp_rec.approve_code_70
           || ' '
           || get_sp_rec.work_request_type_70
           || cv_colon
           || lv_work_request_type_name_70
           || ' '
           || get_sp_rec.approval_state_type_70
           || cv_colon
           || lv_approval_state_type_name_70
           || ' '
           || get_sp_rec.approval_date_70
           || ' '
           || get_sp_rec.approval_content_70
           || cv_colon
           || lv_approval_content_name_70
           || ' '
           || get_sp_rec.approval_comment_70;
      -- �񑗐�E���_�Ǘ�����
      lv_approve_80
        := get_sp_rec.approve_code_80
           || ' '
           || get_sp_rec.work_request_type_80
           || cv_colon
           || lv_work_request_type_name_80
           || ' '
           || get_sp_rec.approval_state_type_80
           || cv_colon
           || lv_approval_state_type_name_80
           || ' '
           || get_sp_rec.approval_date_80
           || ' '
           || get_sp_rec.approval_content_80
           || cv_colon
           || lv_approval_content_name_80
           || ' '
           || get_sp_rec.approval_comment_80;
      -- �񑗐�E�c�Ɩ{����
      lv_approve_90
        := get_sp_rec.approve_code_90
           || ' '
           || get_sp_rec.work_request_type_90
           || cv_colon
           || lv_work_request_type_name_90
           || ' '
           || get_sp_rec.approval_state_type_90
           || cv_colon
           || lv_approval_state_type_name_90
           || ' '
           || get_sp_rec.approval_date_90
           || ' '
           || get_sp_rec.approval_content_90
           || cv_colon
           || lv_approval_content_name_90
           || ' '
           || get_sp_rec.approval_comment_90;
--
      -- ===============================
      -- �J���}��؂�Ńf�[�^�쐬
      -- ===============================
      lv_output_str :=                              cv_dqu || get_sp_rec.last_update_date             || cv_dqu ;  -- �ŏI�X�V����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sp_decision_number           || cv_dqu ;  -- SP�ꌈ���ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_status                               || cv_dqu ;  -- �X�e�[�^�X
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_application_type                     || cv_dqu ;  -- �\���敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.application_date             || cv_dqu ;  -- �\����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.approval_complete_date       || cv_dqu ;  -- ���F������
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_application_code                     || cv_dqu ;  -- �\����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_app_base_code                        || cv_dqu ;  -- �\�����_
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.account_number               || cv_dqu ;  -- �ڋq�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.account_name                 || cv_dqu ;  -- �ڋq��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.account_name_alt             || cv_dqu ;  -- �ڋq���J�i
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_name                 || cv_dqu ;  -- �ݒu�於
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_postal_code          || cv_dqu ;  -- �ݒu��X�֔ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_state                || cv_dqu ;  -- �ݒu��s���{��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_city                 || cv_dqu ;  -- �ݒu��s�E��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_address1             || cv_dqu ;  -- �ݒu��Z��1
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_address2             || cv_dqu ;  -- �ݒu��Z��2
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_phone_number         || cv_dqu ;  -- �ݒu��d�b�ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_business_low_type                    || cv_dqu ;  -- �Ƒԁi�����ށj
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_business_type                        || cv_dqu ;  -- �Ǝ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_install_location                     || cv_dqu ;  -- �ݒu�ꏊ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_open_close_div                       || cv_dqu ;  -- �I�[�v��/�N���[�Y
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.employee                     || cv_dqu ;  -- �Ј���
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_sale_base_code                       || cv_dqu ;  -- �S�����_
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_date                 || cv_dqu ;  -- �ݒu��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.lease_company                || cv_dqu ;  -- ���[�X������
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_customer_status                      || cv_dqu ;  -- �ڋq�X�e�[�^�X
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sale_employee_number         || cv_dqu ;  -- �S���c�ƈ��R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sale_employee_name           || cv_dqu ;  -- �S���c�ƈ���
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_number              || cv_dqu ;  -- �_���R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_name                || cv_dqu ;  -- �_��於
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_name_alt            || cv_dqu ;  -- �_��於�J�i
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_post_code           || cv_dqu ;  -- �_���X�֔ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_state               || cv_dqu ;  -- �_���s���{��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_city                || cv_dqu ;  -- �_���s�E��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_address_1           || cv_dqu ;  -- �_���Z��1
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_address_2           || cv_dqu ;  -- �_���Z��2
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_phone_number        || cv_dqu ;  -- �_���d�b�ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_delegate_name       || cv_dqu ;  -- �_����\�Җ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_newold_type                          || cv_dqu ;  -- �V�䋌��敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.maker_code                   || cv_dqu ;  -- ���[�J�[�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.un_number                    || cv_dqu ;  -- �@��R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sele_number                  || cv_dqu ;  -- �Z����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_standard_type                        || cv_dqu ;  -- �K�i���O�敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_condition_business_type              || cv_dqu ;  -- ��������敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_all_container_type                   || cv_dqu ;  -- �S�e��敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_year_date           || cv_dqu ;  -- �_��N��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_year_month          || cv_dqu ;  -- �_�񌎐�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_contract_period                      || cv_dqu ;  -- �_�����
-- Ver1.1 Add Start
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_construction_period                  || cv_dqu ;  -- �H��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_installation_period                  || cv_dqu ;  -- �ݒu�����݊���
-- Ver1.1 Add End
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bidding_item                         || cv_dqu ;  -- ���D�Č�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_cancell_before_maturity              || cv_dqu ;  -- ���r������
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_ad_assets_type                       || cv_dqu ;  -- �s�����Y�g�p��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.ad_assets_amt                || cv_dqu ;  -- �s�����Y�g�p�����z
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.ad_assets_this_time          || cv_dqu ;  -- �s�����Y�g�p���i����x���j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.ad_assets_payment_year       || cv_dqu ;  -- �s�����Y�g�p���N��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.ad_assets_payment_date       || cv_dqu ;  -- �s�����Y�g�p���x������
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_tax_type                             || cv_dqu ;  -- �o�����ŋ敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_install_supp_type                    || cv_dqu ;  -- �ݒu���^��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_install_supp_payment_type            || cv_dqu ;  -- �ݒu���^���敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_supp_amt             || cv_dqu ;  -- �ݒu���^�����z
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_supp_this_time       || cv_dqu ;  -- �ݒu���^���i����x���j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_supp_payment_year    || cv_dqu ;  -- �ݒu���^���N��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_supp_payment_date    || cv_dqu ;  -- �ݒu���^���x������
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_electricity_type                     || cv_dqu ;  -- �d�C��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_electric_payment_type                || cv_dqu ;  -- �d�C��_���
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_electric_pay_change_type             || cv_dqu ;  -- �d�C��敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.electricity_amount           || cv_dqu ;  -- �d�C����z
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_electricity_change_type              || cv_dqu ;  -- �d�C��ϓ��敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_electric_payment_cycle               || cv_dqu ;  -- �d�C��x���T�C�N��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.electric_closing_date        || cv_dqu ;  -- �d�C����ߓ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_electric_trans_date                  || cv_dqu ;  -- �d�C��U����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.electric_trans_name          || cv_dqu ;  -- �d�C��_���ȊO��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.electric_trans_name_alt      || cv_dqu ;  -- �d�C��_���ȊO���i�J�i�j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_intro_chg_type                       || cv_dqu ;  -- �Љ�萔��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_cust_cointro_chg_pay_type            || cv_dqu ;  -- �Љ�萔���敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_amt                || cv_dqu ;  -- �Љ�萔�����z
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_this_time          || cv_dqu ;  -- �Љ�萔���i����x���j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_payment_year       || cv_dqu ;  -- �Љ�萔���N��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_payment_date       || cv_dqu ;  -- �Љ�萔���x������
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_per_sales_price    || cv_dqu ;  -- �Љ�萔����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_per_piece          || cv_dqu ;  -- �Љ�萔���~
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_closing_date       || cv_dqu ;  -- �Љ�萔�����ߓ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_intro_chg_trans_date                 || cv_dqu ;  -- �Љ�萔���U����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_trans_name         || cv_dqu ;  -- �Љ�萔���_���ȊO��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_trans_name_alt     || cv_dqu ;  -- �Љ�萔���_���ȊO���i�J�i�j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.condition_reason             || cv_dqu ;  -- ���ʏ����̗��R
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_send_type                || cv_dqu ;  -- BM1���t��敪
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_send_code                || cv_dqu ;  -- BM1���t��R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_send_name                || cv_dqu ;  -- BM1���t�於
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_send_name_alt            || cv_dqu ;  -- BM1���t��J�i
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_postal_code              || cv_dqu ;  -- BM1�X�֔ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_address1                 || cv_dqu ;  -- BM1�Z��1
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_address2                 || cv_dqu ;  -- BM1�Z��2
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_phone_number             || cv_dqu ;  -- BM1�d�b�ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bm1_bank_charge_bearer               || cv_dqu ;  -- BM1�U���萔�����S
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bm1_bm_payment_type                  || cv_dqu ;  -- BM1�x�����@�E���׏�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_inquiry_base_code        || cv_dqu ;  -- BM1�⍇���S�����_�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_send_code                || cv_dqu ;  -- BM2���t��R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_send_name                || cv_dqu ;  -- BM2���t�於
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_send_name_alt            || cv_dqu ;  -- BM2���t��J�i
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_postal_code              || cv_dqu ;  -- BM2�X�֔ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_address1                 || cv_dqu ;  -- BM2�Z��1
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_address2                 || cv_dqu ;  -- BM2�Z��2
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_phone_number             || cv_dqu ;  -- BM2�d�b�ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bm2_bank_charge_bearer               || cv_dqu ;  -- BM2�U���萔�����S
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bm2_bm_payment_type                  || cv_dqu ;  -- BM2�x�����@�E���׏�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_inquiry_base_code        || cv_dqu ;  -- BM2�⍇���S�����_�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_send_code                || cv_dqu ;  -- BM3���t��R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_send_name                || cv_dqu ;  -- BM3���t�於
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_send_name_alt            || cv_dqu ;  -- BM3���t��J�i
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_postal_code              || cv_dqu ;  -- BM3�X�֔ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_address1                 || cv_dqu ;  -- BM3�Z��1
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_address2                 || cv_dqu ;  -- BM3�Z��2
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_phone_number             || cv_dqu ;  -- BM3�d�b�ԍ�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bm3_bank_charge_bearer               || cv_dqu ;  -- BM3�U���萔�����S
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bm3_bm_payment_type                  || cv_dqu ;  -- BM3�x�����@�E���׏�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_inquiry_base_code        || cv_dqu ;  -- BM3�⍇���S�����_�R�[�h
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sales_month                  || cv_dqu ;  -- ���Ԕ���
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sales_year                   || cv_dqu ;  -- �N�Ԕ���
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sales_gross_margin_rate      || cv_dqu ;  -- ����e����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.year_gross_margin_amt        || cv_dqu ;  -- �N�ԑe�����z
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm_rate                      || cv_dqu ;  -- �a�l��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.vd_sales_charge              || cv_dqu ;  -- �u�c�̔��萔��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_support_amt_year     || cv_dqu ;  -- �ݒu���^���^�N
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.lease_charge_month           || cv_dqu ;  -- ���[�X���i���z�j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.construction_charge          || cv_dqu ;  -- �H����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.vd_lease_charge              || cv_dqu ;  -- �u�c���[�X��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.electricity_amt_month        || cv_dqu ;  -- �d�C��i���j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.electricity_amt_year         || cv_dqu ;  -- �d�C��i�N�j
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.transportation_charge        || cv_dqu ;  -- �^����`
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.labor_cost_other             || cv_dqu ;  -- �l���
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.total_cost                   || cv_dqu ;  -- ��p���v
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.operating_profit             || cv_dqu ;  -- �c�Ɨ��v
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.operating_profit_rate        || cv_dqu ;  -- �c�Ɨ��v��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.break_even_point             || cv_dqu ;  -- ���v����_
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_10                           || cv_dqu ;  -- �񑗐�E�m�F��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_20                           || cv_dqu ;  -- �񑗐�E���F��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_30                           || cv_dqu ;  -- �񑗐�E�n��c�ƊǗ��ے�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_40                           || cv_dqu ;  -- �񑗐�E�n��c�ƕ���
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_50                           || cv_dqu ;  -- �񑗐�E�֌W��
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_60                           || cv_dqu ;  -- �񑗐�E���̋@���ے�
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_70                           || cv_dqu ;  -- �񑗐�E���̋@����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_80                           || cv_dqu ;  -- �񑗐�E���_�Ǘ�����
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_90                           || cv_dqu ;  -- �񑗐�E�c�Ɩ{����
--
      -- �Ώی���
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �f�[�^�o��
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_sp_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code       IN  VARCHAR2     -- �\��(����)���_
   ,iv_app_date_from   IN  VARCHAR2     -- �\����(FROM)
   ,iv_app_date_to     IN  VARCHAR2     -- �\����(TO)
   ,iv_status          IN  VARCHAR2     -- �X�e�[�^�X
   ,iv_customer_cd     IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_kbn             IN  VARCHAR2     -- ����敪
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
      iv_base_code     => iv_base_code       -- ����(�\��)���_
     ,iv_app_date_from => iv_app_date_from   -- �\����(FROM)
     ,iv_app_date_to   => iv_app_date_to     -- �\����(TO)
     ,iv_status        => iv_status          -- �X�e�[�^�X
     ,iv_customer_cd   => iv_customer_cd     -- �ڋq�R�[�h
     ,iv_kbn           => iv_kbn             -- ����敪
     ,ov_errbuf        => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- SP�ꌈ�����擾�E�o��(A-2,A-3)
    -- ===============================
    output_sp_data(
      ov_errbuf          => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
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
    errbuf           OUT    VARCHAR2     -- �G���[���b�Z�[�W #�Œ�#
   ,retcode          OUT    VARCHAR2     -- �G���[�R�[�h     #�Œ�#
   ,iv_base_code     IN     VARCHAR2     -- �\��(����)���_
   ,iv_app_date_from IN     VARCHAR2     -- �\����(FROM)
   ,iv_app_date_to   IN     VARCHAR2     -- �\����(TO)
   ,iv_status        IN     VARCHAR2     -- �X�e�[�^�X
   ,iv_customer_cd   IN     VARCHAR2     -- �ڋq�R�[�h
   ,iv_kbn           IN     VARCHAR2     -- ����敪
  )
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
       iv_base_code     => iv_base_code     -- ����(�\��)���_
      ,iv_app_date_from => iv_app_date_from -- �\����(FROM)
      ,iv_app_date_to   => iv_app_date_to   -- �\����(TO)
      ,iv_status        => iv_status        -- �X�e�[�^�X
      ,iv_customer_cd   => iv_customer_cd   -- �ڋq�R�[�h
      ,iv_kbn           => iv_kbn           -- ����敪
      ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[���b�Z�[�W���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ������ݒ�
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
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
END XXCSO020A07C;
/
