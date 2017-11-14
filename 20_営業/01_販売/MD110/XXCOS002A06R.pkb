CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A06R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS002A06R(body)
 * Description      : ���̋@�̔��񍐏�
 * MD.050           : ���̋@�̔��񍐏� <MD050_COS_002_A06>
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_relation_data      �֘A�f�[�^�擾����(A-2)
 *  get_cust_info_data     �ڋq���擾����(A-3)
 *  get_sales_exp_data     �̔����擾����(A-4)
 *  ins_rep_work_data      ���[���[�N�e�[�u���쐬����(A-5)
 *  execute_svf            SVF�N������(A-6)
 *  del_rep_work_data      ���[���[�N�e�[�u���폜����(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2012/02/16    1.0   K.Kiriu          �V�K�쐬
 * 2012/12/19    1.1   K.Onotsuka       E_�{�ғ�_10275�Ή�[���̓p�����[�^.�ڋq�R�[�h(�d����R�[�h)�ŏd�����Ă���f�[�^�́A
 *                                                         �z��i�[�������珜�O����]
 * 2013/11/12    1.2   T.Ishiwata       E_�{�ғ�_11134�Ή�
 *                                        ���̓p�����[�^�Ɂu�[�i��FROM�v�Ɓu�[�i��TO�v��ǉ�����
 * 2017/11/01    1.3   N.Koyama         E_�{�ғ�_14702�Ή�
 *                                        �����Z���^�[�Ή��ɂ��⍇�����_�w���ǉ�
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  select_expt          EXCEPTION;         -- �f�[�^���o��O
  insert_expt          EXCEPTION;         -- �f�[�^�o�^��O
  delete_proc_expt     EXCEPTION;         -- �f�[�^�폜��O
  lock_expt            EXCEPTION;         -- ���b�N��O
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCOS002A06R';              -- �p�b�P�[�W��
--
  cv_application           CONSTANT VARCHAR2(5)   := 'XXCOS';                     -- �A�v���P�[�V����
--
  --SVF�p����
  cv_frm_name              CONSTANT VARCHAR2(16)  := 'XXCOS002A06S.xml';          -- �t�H�[���l����
  cv_vrq_name              CONSTANT VARCHAR2(16)  := 'XXCOS002A06S.vrq';          -- �N�G���[��
  cv_extension_pdf         CONSTANT VARCHAR2(4)   := '.pdf';                      -- �g���q(PDF)
  cv_output_mode_pdf       CONSTANT VARCHAR2(1)   := '1';                         -- �o�͋敪
--
  --�������Ŏg�p
  cv_bus_low_type_24       CONSTANT VARCHAR2(2)   := '24';                        -- �Ƒԏ�����(�t��VD����)
  cv_bus_low_type_25       CONSTANT VARCHAR2(2)   := '25';                        -- �Ƒԏ�����(�t��VD)
  cv_1                     CONSTANT VARCHAR2(1)   := '1';                         -- VARCHAR�^�ėp�Œ�l1
  cv_2                     CONSTANT VARCHAR2(1)   := '2';                         -- VARCHAR�^�ėp�Œ�l2
  cv_3                     CONSTANT VARCHAR2(1)   := '3';                         -- VARCHAR�^�ėp�Œ�l3
-- Ver.1.3 Add Start
  cv_10                    CONSTANT VARCHAR2(2)   := '10';                        -- VARCHAR�^�ėp�Œ�l10
-- Ver.1.3 Add End
  cv_30                    CONSTANT VARCHAR2(2)   := '30';                        -- VARCHAR�^�ėp�Œ�l30
  cv_y                     CONSTANT VARCHAR2(1)   := 'Y';                         -- VARCHAR�^�ėp�Œ�lY
  cv_n                     CONSTANT VARCHAR2(1)   := 'N';                         -- VARCHAR�^�ėp�Œ�lN
--
  --����
  cv_date_yyyymm           CONSTANT VARCHAR2(8)   := 'RRRR/MM/';                  -- ���t����'RRRR/MM/'
  cv_date_yyyymmdd         CONSTANT VARCHAR2(10)  := 'RRRR/MM/DD';                -- ���t����'RRRR/MM/DD'
  cv_date_yyyymmdd2        CONSTANT VARCHAR2(8)   := 'RRRRMMDD';                  -- ���t����'RRRRMMDD'
  cv_date_dd               CONSTANT VARCHAR2(2)   := 'DD';                        -- ���t����'DD'
  cv_slash                 CONSTANT VARCHAR2(1)   := '/';                         -- ���t�����Ŏg�p
  cv_date_time             CONSTANT VARCHAR2(21)  := 'RRRR/MM/DD HH24:MI:SS';     -- ���t����'����'(���O�p)
--
  --���b�Z�[�W�R�[�h
  cv_msg_param_cust_1      CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14351';          -- ���b�Z�[�W�o��(�ڋq)--10param��
  cv_msg_param_cust_2      CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14352';          -- ���b�Z�[�W�o��(�ڋq)--11param�ȍ~
  cv_msg_param_vend        CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14353';          -- ���b�Z�[�W�o��(�d����)
  cv_msg_prf_err           CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00004';          -- �v���t�@�C���擾�G���[
  cv_msg_organization_err  CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00091';          -- �݌ɑg�DID�擾�G���[
  cv_msg_select_err        CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00013';          -- �f�[�^���o�G���[
  cv_msg_insert_err        CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00010';          -- �f�[�^�o�^�G���[
  cv_msg_lock_err          CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00001';          -- �f�[�^���b�N�G���[
  cv_msg_delete_err        CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00012';          -- �f�[�^�폜�G���[
  cv_msg_nodata_err        CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00018';          -- ����0���G���[���b�Z�[�W
  cv_msg_api_err           CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00017';          -- API�G���[���b�Z�[�W
  cv_msg_price_wrn         CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14359';          -- ���������_���b�Z�[�W
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD START
  cv_msg_date_rever_err    CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00005';          -- ���t�t�]�G���[
  cv_msg_prim_chk          CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14361';          -- �p�����[�^�[�i���D�惁�b�Z�[�W
  cv_msg_pram_set_err      CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14362';          -- �p�����[�^���ԏ�񖢐ݒ�G���[���b�Z�[�W
  cv_msg_required_err      CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14363';          -- �p�����[�^�[�i��FROM-TO�ݒ�`�F�b�N
  cv_msg_range_err         CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14364';          -- �p�����[�^�[�i��FROM-TO�͈̓`�F�b�N
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD END
-- Ver.1.3 Add Start
  cv_msg_param_base        CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14367';          -- ���b�Z�[�W�o��(�⍇�����_)
-- Ver.1.3 Add End
  --���b�Z�[�W�g�[�N���p
  cv_msg_tkn_org           CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00047';          -- MO:�c�ƒP��
  cv_msg_tkn_organization  CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00048';          -- XXCOI:�݌ɑg�D�R�[�h
  cv_msg_tkn_app_mst       CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14354';          -- �A�v���P�[�V�����}�X�^
  cv_msg_tkn_ct_set_mst    CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14355';          -- �J�e�S���Z�b�g�}�X�^(����Q)
  cv_msg_tkn_policy_group  CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14356';          -- XXCOS:����Q
  cv_msg_tkn_tmp_table     CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14357';          -- ���̋@�̔��񍐏��ڋq���ꎞ�\
  cv_msg_tkn_rep_table     CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14358';          -- ���̋@�̔��񍐏����[���[�N�e�[�u��
  cv_msg_tkn_emp_table     CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14360';          -- �S���c��
  cv_msg_tkn_svf_api       CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-00041';          -- SVF�N��API
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD START
  cv_msg_date_from         CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14365';          -- �[�i��FROM
  cv_msg_date_to           CONSTANT VARCHAR2(16)  := 'APP-XXCOS1-14366';          -- �[�i��TO
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD END
--
  --�g�[�N���R�[�h
  cv_tkn_manager_flag      CONSTANT VARCHAR2(12)  := 'MANAGER_FLAG';              -- �Ǘ��҃t���O
  cv_tkn_proc_type         CONSTANT VARCHAR2(12)  := 'EXECUTE_TYPE';              -- ���s�敪
  cv_tkn_trget_date        CONSTANT VARCHAR2(11)  := 'TARGET_DATE';               -- �N��
  cv_tkn_sales_base        CONSTANT VARCHAR2(15)  := 'SALES_BASE_CODE';           -- ���㋒�_�R�[�h
  cv_tkn_cust_01           CONSTANT VARCHAR2(12)  := 'CUST_CODE_01';              -- �ڋq�R�[�h1
  cv_tkn_cust_02           CONSTANT VARCHAR2(12)  := 'CUST_CODE_02';              -- �ڋq�R�[�h2
  cv_tkn_cust_03           CONSTANT VARCHAR2(12)  := 'CUST_CODE_03';              -- �ڋq�R�[�h3
  cv_tkn_cust_04           CONSTANT VARCHAR2(12)  := 'CUST_CODE_04';              -- �ڋq�R�[�h4
  cv_tkn_cust_05           CONSTANT VARCHAR2(12)  := 'CUST_CODE_05';              -- �ڋq�R�[�h5
  cv_tkn_cust_06           CONSTANT VARCHAR2(12)  := 'CUST_CODE_06';              -- �ڋq�R�[�h6
  cv_tkn_cust_07           CONSTANT VARCHAR2(12)  := 'CUST_CODE_07';              -- �ڋq�R�[�h7
  cv_tkn_cust_08           CONSTANT VARCHAR2(12)  := 'CUST_CODE_08';              -- �ڋq�R�[�h8
  cv_tkn_cust_09           CONSTANT VARCHAR2(12)  := 'CUST_CODE_09';              -- �ڋq�R�[�h9
  cv_tkn_cust_10           CONSTANT VARCHAR2(12)  := 'CUST_CODE_10';              -- �ڋq�R�[�h10
  cv_tkn_vend_01           CONSTANT VARCHAR2(12)  := 'VEND_CODE_01';              -- �d����R�[�h1
  cv_tkn_vend_02           CONSTANT VARCHAR2(12)  := 'VEND_CODE_02';              -- �d����R�[�h2
  cv_tkn_vend_03           CONSTANT VARCHAR2(12)  := 'VEND_CODE_03';              -- �d����R�[�h3
  cv_tkn_prf               CONSTANT VARCHAR2(7)   := 'PROFILE';                   -- �v���t�@�C��
  cv_tkn_organization      CONSTANT VARCHAR2(12)  := 'ORG_CODE_TOK';              -- �݌ɑg�D�R�[�h
  cv_tkn_table_name        CONSTANT VARCHAR2(10)  := 'TABLE_NAME';                -- �e�[�u����
  cv_tkn_key_data          CONSTANT VARCHAR2(8)   := 'KEY_DATA';                  -- �G���[���e
  cv_tkn_api_name          CONSTANT VARCHAR2(8)   := 'API_NAME';                  -- API����
  cv_tkn_table             CONSTANT VARCHAR2(5)   := 'TABLE';                     -- �e�[�u��
  cv_tkn_cust              CONSTANT VARCHAR2(9)   := 'CUST_CODE';                 -- �ڋq�R�[�h
  cv_tkn_item              CONSTANT VARCHAR2(9)   := 'ITEM_CODE';                 -- �i�ڃR�[�h
  cv_tkn_dlv_price         CONSTANT VARCHAR2(9)   := 'DLV_PRICE';                 -- ����
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD START
  cv_tkn_dlv_date_from     CONSTANT VARCHAR2(15)  := 'DLV_DATE_FROM';             -- �[�i��FROM
  cv_tkn_dlv_date_to       CONSTANT VARCHAR2(15)  := 'DLV_DATE_TO';               -- �[�i��TO
  cv_tkn_date_from         CONSTANT VARCHAR2(15)  := 'DATE_FROM';                 -- ������u�[�i��FROM�v
  cv_tkn_date_to           CONSTANT VARCHAR2(15)  := 'DATE_TO';                   -- ������u�[�i��TO�v
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD END
--
  --�v���t�@�C��
  cv_prf_org               CONSTANT VARCHAR2(6)   := 'ORG_ID';                    -- MO:�c�ƒP��
  cv_prf_organization      CONSTANT VARCHAR2(24)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:�݌ɑg�D�R�[�h
  cv_prf_policy_group      CONSTANT VARCHAR2(24)  := 'XXCOS1_POLICY_GROUP_CODE';  -- XXCOS:����Q�R�[�h
  --���O�p
  cv_proc_end              CONSTANT VARCHAR2(3)   := 'END';
--
  --LANGUAGE
  ct_lang                  CONSTANT mtl_category_sets_tl.language%TYPE := USERENV( 'LANG' );
  --�Ɩ����t
  gd_proc_date             CONSTANT DATE := TRUNC( xxccp_common_pkg2.get_process_date );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���̓p�����[�^���(����)
  TYPE g_input_rtype IS RECORD (
     manager_flag      VARCHAR2(1)                             -- �Ǘ��҃t���O
    ,execute_type      VARCHAR2(1)                             -- ���s�敪
    ,target_date       VARCHAR2(7)                             -- �Ώ۔N��
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD START
    ,dlv_date_from     DATE                                    -- �[�i��FROM
    ,dlv_date_to       DATE                                    -- �[�i��TO
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD END
    ,sales_base_code   xxcmm_cust_accounts.sale_base_code%TYPE -- ���㋒�_�R�[�h
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
  g_input_rec  g_input_rtype;  --���̓p�����[�^���
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���e�[�u��
  -- ===============================
  TYPE g_cust_ttype  IS TABLE OF hz_cust_accounts.account_number%TYPE INDEX BY BINARY_INTEGER; -- �ڋq�w��Ŏ��s���p
  TYPE g_vend_ttype  IS TABLE OF po_vendors.segment1%TYPE             INDEX BY BINARY_INTEGER; -- �d����w��Ŏ��s���p
  TYPE g_sales_ttype IS TABLE OF xxcos_rep_vd_sales_list%ROWTYPE      INDEX BY BINARY_INTEGER; -- ���[���[�N�e�[�u��
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD START
  TYPE g_chk_ttype   IS TABLE OF NUMBER INDEX BY VARCHAR2(30); --�p�����[�^�`�F�b�N�p
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD END
  -- ===============================
  -- ���[�U�[��`�O���[�o���z��
  -- ===============================
  g_cust_tab       g_cust_ttype;
  g_vend_tab       g_vend_ttype;
  g_sales_tab      g_sales_ttype;
  g_sales_tab_work g_sales_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_org_id            NUMBER;                                    --�c�ƒP��ID
  gn_organization_id   NUMBER;                                    --�݌ɑg�DID
  gt_apprication_id    fnd_application.application_id%TYPE;       --�A�v���P�[�V����ID
  gt_category_set_id   mtl_category_sets_tl.category_set_id%TYPE; --�J�e�S���Z�b�gID
  gn_warn              NUMBER;                                    --�����x���I���p
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --�N�C�b�N�R�[�h
    cv_lk_proc_type    CONSTANT VARCHAR2(29)  := 'XXCOS1_REP_VD_SALES_EXEC_TYPE';  -- ���s�敪
--
    -- *** ���[�J���ϐ� ***
    lv_param_msg       VARCHAR2(5000);                 -- �p�����[�^�[�o�͗p
    lv_proc_type_name  fnd_lookup_values.meaning%TYPE; -- �N�C�b�N�R�[�h���e
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
    --=========================================
    -- �p�����[�^�̏o��
    --=========================================
    --���s�敪�̖��̎擾
    lv_proc_type_name := xxcos_common_pkg.get_specific_master(
                           cv_lk_proc_type
                          ,g_input_rec.execute_type
                         );
--
    --���s�敪��1�i�ڋq�w��Ŏ��s���j�̏ꍇ
    IF ( g_input_rec.execute_type = cv_1 ) THEN
      --���b�Z�[�W�ҏW(10parameter��)
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_application               -- �A�v���P�[�V����
                        ,iv_name          => cv_msg_param_cust_1          -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   => cv_tkn_manager_flag          -- �g�[�N���R�[�h�P
                        ,iv_token_value1  => g_input_rec.manager_flag     -- �Ǘ��҃t���O
                        ,iv_token_name2   => cv_tkn_proc_type             -- �g�[�N���R�[�h�Q
                        ,iv_token_value2  => lv_proc_type_name            -- ���s�敪
                        ,iv_token_name3   => cv_tkn_trget_date            -- �g�[�N���R�[�h�R
                        ,iv_token_value3  => g_input_rec.target_date      -- �N��
                        ,iv_token_name4   => cv_tkn_sales_base            -- �g�[�N���R�[�h�S
                        ,iv_token_value4  => g_input_rec.sales_base_code  -- ���㋒�_
                        ,iv_token_name5   => cv_tkn_cust_01               -- �g�[�N���R�[�h�T
                        ,iv_token_value5  => g_cust_tab(1)                -- �ڋq�R�[�h1
                        ,iv_token_name6   => cv_tkn_cust_02               -- �g�[�N���R�[�h�U
                        ,iv_token_value6  => g_cust_tab(2)                -- �ڋq�R�[�h2
                        ,iv_token_name7   => cv_tkn_cust_03               -- �g�[�N���R�[�h�V
                        ,iv_token_value7  => g_cust_tab(3)                -- �ڋq�R�[�h3
                        ,iv_token_name8   => cv_tkn_cust_04               -- �g�[�N���R�[�h�W
                        ,iv_token_value8  => g_cust_tab(4)                -- �ڋq�R�[�h4
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 MOD START
--                        ,iv_token_name9   => cv_tkn_cust_05               -- �g�[�N���R�[�h�X
--                        ,iv_token_value9  => g_cust_tab(5)                -- �ڋq�R�[�h5
--                        ,iv_token_name10  => cv_tkn_cust_06               -- �g�[�N���R�[�h�P�O
--                        ,iv_token_value10 => g_cust_tab(6)                -- �ڋq�R�[�h6
                        ,iv_token_name9   => cv_tkn_dlv_date_from                                     -- �g�[�N���R�[�h�X
                        ,iv_token_value9  => TO_CHAR( g_input_rec.dlv_date_from , cv_date_yyyymmdd )  -- �[�i��FROM
                        ,iv_token_name10  => cv_tkn_dlv_date_to                                       -- �g�[�N���R�[�h�P�O
                        ,iv_token_value10 => TO_CHAR( g_input_rec.dlv_date_to   , cv_date_yyyymmdd )  -- �[�i��TO
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 MOD END
                      );
      --1�`10�̃p�����[�^�����O�֏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_param_msg
      );
      --���b�Z�[�W�ҏW(10parameter�ȍ~)
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_application                -- �A�v���P�[�V����
                        ,iv_name          => cv_msg_param_cust_2           -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   => cv_tkn_cust_07                -- �g�[�N���R�[�h�P
                        ,iv_token_value1  => g_cust_tab(7)                 -- �ڋq�R�[�h7
                        ,iv_token_name2   => cv_tkn_cust_08                -- �g�[�N���R�[�h�Q
                        ,iv_token_value2  => g_cust_tab(8)                 -- �ڋq�R�[�h8
                        ,iv_token_name3   => cv_tkn_cust_09                -- �g�[�N���R�[�h�R
                        ,iv_token_value3  => g_cust_tab(9)                 -- �ڋq�R�[�h9
                        ,iv_token_name4   => cv_tkn_cust_10                -- �g�[�N���R�[�h�S
                        ,iv_token_value4  => g_cust_tab(10)                -- �ڋq�R�[�h10
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD START
                        ,iv_token_name5   => cv_tkn_cust_05               -- �g�[�N���R�[�h�T
                        ,iv_token_value5  => g_cust_tab(5)                -- �ڋq�R�[�h5
                        ,iv_token_name6   => cv_tkn_cust_06               -- �g�[�N���R�[�h�U
                        ,iv_token_value6  => g_cust_tab(6)                -- �ڋq�R�[�h6
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD END
                      );
      --11�`13�̃p�����[�^�����O�֏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_param_msg
      );
    --���s�敪��2�i�d����w��Ŏ��s���j�̏ꍇ
    ELSIF ( g_input_rec.execute_type = cv_2 ) THEN
      --���b�Z�[�W�ҏW
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_application                -- �A�v���P�[�V����
                        ,iv_name          => cv_msg_param_vend             -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   => cv_tkn_manager_flag           -- �g�[�N���R�[�h�P
                        ,iv_token_value1  => g_input_rec.manager_flag      -- �Ǘ��҃t���O
                        ,iv_token_name2   => cv_tkn_proc_type              -- �g�[�N���R�[�h�Q
                        ,iv_token_value2  => lv_proc_type_name             -- ���s�敪
                        ,iv_token_name3   => cv_tkn_trget_date             -- �g�[�N���R�[�h�R
                        ,iv_token_value3  => g_input_rec.target_date       -- �N��
                        ,iv_token_name4   => cv_tkn_vend_01                -- �g�[�N���R�[�h�S
                        ,iv_token_value4  => g_vend_tab(1)                 -- �d����R�[�h1
                        ,iv_token_name5   => cv_tkn_vend_02                -- �g�[�N���R�[�h�T
                        ,iv_token_value5  => g_vend_tab(2)                 -- �d����R�[�h2
                        ,iv_token_name6   => cv_tkn_vend_03                -- �g�[�N���R�[�h�U
                        ,iv_token_value6  => g_vend_tab(3)                 -- �d����R�[�h3
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD START
                        ,iv_token_name7   => cv_tkn_dlv_date_from                                     -- �g�[�N���R�[�h�X
                        ,iv_token_value7  => TO_CHAR( g_input_rec.dlv_date_from , cv_date_yyyymmdd )  -- �[�i��FROM
                        ,iv_token_name8   => cv_tkn_dlv_date_to                                       -- �g�[�N���R�[�h�P�O
                        ,iv_token_value8  => TO_CHAR( g_input_rec.dlv_date_to   , cv_date_yyyymmdd )  -- �[�i��TO
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD END
                      );
      --���O�֏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_param_msg
      );
-- Ver.1.3 Add Start
    --���s�敪��3�i�⍇�����_�w��Ŏ��s���j�̏ꍇ
    ELSIF ( g_input_rec.execute_type = cv_3 ) THEN
      --���b�Z�[�W�ҏW
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_application                -- �A�v���P�[�V����
                        ,iv_name          => cv_msg_param_base             -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   => cv_tkn_manager_flag           -- �g�[�N���R�[�h�P
                        ,iv_token_value1  => g_input_rec.manager_flag      -- �Ǘ��҃t���O
                        ,iv_token_name2   => cv_tkn_proc_type              -- �g�[�N���R�[�h�Q
                        ,iv_token_value2  => lv_proc_type_name             -- ���s�敪
                        ,iv_token_name3   => cv_tkn_trget_date             -- �g�[�N���R�[�h�R
                        ,iv_token_value3  => g_input_rec.target_date       -- �N��
                        ,iv_token_name4   => cv_tkn_dlv_date_from                                     -- �g�[�N���R�[�h�X
                        ,iv_token_value4  => TO_CHAR( g_input_rec.dlv_date_from , cv_date_yyyymmdd )  -- �[�i��FROM
                        ,iv_token_name5   => cv_tkn_dlv_date_to                                       -- �g�[�N���R�[�h�P�O
                        ,iv_token_value5  => TO_CHAR( g_input_rec.dlv_date_to   , cv_date_yyyymmdd )  -- �[�i��TO
                        ,iv_token_name6   => cv_tkn_sales_base                                        -- �g�[�N���R�[�h�P�O
                        ,iv_token_value6  => g_input_rec.sales_base_code   -- �⍇�����_
                      );
      --���O�֏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_param_msg
      );
-- Ver.1.3 Add End
    END IF;
--
    --���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
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
   * Procedure Name   : get_relation_data
   * Description      : �֘A�f�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_relation_data(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_relation_data'; -- �v���O������
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
    cv_application_ar     CONSTANT fnd_application.application_short_name%TYPE := 'AR';              -- �A�v���P�[�V������
--
    -- *** ���[�J���ϐ� ***
    lv_msg_tnk            VARCHAR2(100);                                        -- ���b�Z�[�W�g�[�N���p
    lv_err_msg            VARCHAR2(5000);                                       -- ���b�Z�[�W�p
    lt_organization_code  mtl_parameters.organization_code%TYPE;                -- �݌ɑg�D�R�[�h
    lt_policy_group_code  fnd_profile_option_values.profile_option_value%TYPE;  -- �A�v���P�[�V������(����Q)
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
    --=========================================
    -- �v���t�@�C���̎擾
    --=========================================
    ------------------------
    -- �c�ƒP�ʂ̎擾
    ------------------------
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_org ) );  -- �c�ƒP��
    IF ( gn_org_id IS NULL ) THEN
      -- �g�[�N���擾
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_org        -- MO:�c�ƒP��
                    );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_prf_err  -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_prf
                      ,iv_token_value1 => lv_msg_tnk      -- �v���t�@�C����
                    );
      --���O�֏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_err_msg
      );
      --���^�[���R�[�h�ɃG���[��ݒ�
      ov_retcode := cv_status_error;
    END IF;
--
    ------------------------
    --�݌ɑg�D�R�[�h�̎擾
    ------------------------
    lt_organization_code := FND_PROFILE.VALUE( cv_prf_organization );
    IF ( lt_organization_code IS NULL ) THEN
      -- �v���t�@�C�����擾
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_organization  -- XXCOI:�݌ɑg�D�R�[�h
                    );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_prf_err           -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_prf
                      ,iv_token_value1 => lv_msg_tnk               -- �v���t�@�C����
                    );
      --���O�֏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_err_msg
      );
      --���^�[���R�[�h�ɃG���[��ݒ�
      ov_retcode := cv_status_error;
    END IF;
--
    --------------------------------
    --�J�e�S���Z�b�g��(����Q)�̎擾
    --------------------------------
    lt_policy_group_code := FND_PROFILE.VALUE( cv_prf_policy_group );
    IF ( lt_policy_group_code IS NULL ) THEN
      -- �v���t�@�C�����擾
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_policy_group  -- XXCOS:����Q
                    );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_prf_err           -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_prf
                      ,iv_token_value1 => lv_msg_tnk               -- �v���t�@�C����
                    );
      --���O�֏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_err_msg
      );
      --���^�[���R�[�h�ɃG���[��ݒ�
      ov_retcode := cv_status_error;
    END IF;
--
    --=========================================
    -- �݌ɑg�DID�̎擾
    --=========================================
    gn_organization_id :=xxcoi_common_pkg.get_organization_id( lt_organization_code );
    IF ( gn_organization_id IS NULL ) THEN
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_organization_err  -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_organization
                      ,iv_token_value1 => lt_organization_code     -- �݌ɑg�D�R�[�h
                    );
      --���O�֏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_err_msg
      );
      --���^�[���R�[�h�ɃG���[��ݒ�
      ov_retcode := cv_status_error;
    END IF;
--
    --=========================================
    -- �A�v���P�[�V����ID�̎擾
    --=========================================
    BEGIN
      SELECT fa.application_id application_id
      INTO   gt_apprication_id
      FROM   fnd_application fa
      WHERE  fa.application_short_name = cv_application_ar
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �e�[�u�����擾
        lv_msg_tnk := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_tkn_app_mst   -- �A�v���P�[�V�����}�X�^
                      );
        --���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_select_err    --���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_table_name
                        ,iv_token_value1 => lv_msg_tnk           -- �e�[�u����
                        ,iv_token_name2  => cv_tkn_key_data
                        ,iv_token_value2 => SQLERRM              -- SQLERRM
                      );
        --���O�֏o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_err_msg
        );
        --���^�[���R�[�h�ɃG���[��ݒ�
        ov_retcode := cv_status_error;
    END;
--
    --=========================================
    -- �J�e�S���Z�b�gID�̎擾
    --=========================================
    BEGIN
      SELECT  mcst.category_set_id category_set_id
      INTO    gt_category_set_id
      FROM    mtl_category_sets_tl   mcst
      WHERE   mcst.category_set_name = lt_policy_group_code
      AND     mcst.language          = ct_lang
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �e�[�u�����擾
        lv_msg_tnk := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_tkn_ct_set_mst  -- �A�v���P�[�V�����}�X�^
                      );
        --���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_select_err      --���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_table_name
                        ,iv_token_value1 => lv_msg_tnk             -- �e�[�u����
                        ,iv_token_name2  => cv_tkn_key_data
                        ,iv_token_value2 => SQLERRM                -- SQLERRM
                      );
        --���O�֏o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_err_msg
        );
        --���^�[���R�[�h�ɃG���[��ݒ�
        ov_retcode := cv_status_error;
    END;
--
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD START
    --=========================================
    -- ���ԃp�����[�^�D��m�F���b�Z�[�W�̏o��
    --=========================================
    IF(    g_input_rec.target_date   IS NOT NULL 
       AND g_input_rec.dlv_date_from IS NOT NULL 
       AND g_input_rec.dlv_date_to   IS NOT NULL ) THEN   -- �N���A�[�i��FROM�A�[�i��TO�ݒ肠��
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_prim_chk      --���b�Z�[�W�R�[�h
                    );
      --���O�֏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_err_msg
      );
      --���^�[���R�[�h�ɃG���[��ݒ�
      ov_retcode := cv_status_warn;
    END IF;
    --=========================================
    -- ���ԃp�����[�^�̓��̓`�F�b�N
    --=========================================
    IF(    g_input_rec.target_date   IS NULL
       AND g_input_rec.dlv_date_from IS NULL
       AND g_input_rec.dlv_date_to   IS NULL ) THEN   -- �N���A�[�i��FROM�A�[�i��TO�ݒ�Ȃ�
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_pram_set_err      --���b�Z�[�W�R�[�h
                    );
      --���O�֏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_err_msg
      );
      --���^�[���R�[�h�ɃG���[��ݒ�
      ov_retcode := cv_status_error;
    END IF;
    --
    --=========================================
    -- ���̓p�����[�^�u�[�i���v�̕K�{�`�F�b�N
    --=========================================
    --�u�[�i��FROM�v�Ɓu�[�i��TO�v���Ƃ��ɖ��ݒ�̏ꍇ
    IF (   (( g_input_rec.dlv_date_from IS NOT NULL ) AND ( g_input_rec.dlv_date_to   IS     NULL ))
        OR (( g_input_rec.dlv_date_from IS     NULL ) AND ( g_input_rec.dlv_date_to   IS NOT NULL ))
       )  THEN
      --���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_required_err      --���b�Z�[�W�R�[�h
                    );
      --���O�֏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_err_msg
      );
      --���^�[���R�[�h�ɃG���[��ݒ�
      ov_retcode := cv_status_error;
    ELSE
      --=========================================
      -- ���̓p�����[�^�u�[�i���v���t�t�]�`�F�b�N
      --=========================================
      --�u�[�i��FROM�v���u�[�i��TO�v�ł���ꍇ
      IF ( g_input_rec.dlv_date_from  >  g_input_rec.dlv_date_to ) THEN
        --���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_date_rever_err      --���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_date_from
                        ,iv_token_value1 => cv_msg_date_from           -- �[�i��FROM
                        ,iv_token_name2  => cv_tkn_date_to
                        ,iv_token_value2 => cv_msg_date_to             -- �[�i��TO
                      );
        --���O�֏o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_err_msg
        );
        --���^�[���R�[�h�ɃG���[��ݒ�
        ov_retcode := cv_status_error;
      ELSE
        --=========================================
        -- ���̓p�����[�^�u�[�i���v���t�͈̓`�F�b�N
        --=========================================
        --�p�����[�^�u�[�i��FROM�v�� �p�����[�^�u�[�i��TO�v�̂P�����O���ߋ��̏ꍇ
        IF ( g_input_rec.dlv_date_from  < ADD_MONTHS( g_input_rec.dlv_date_to, -1 ) ) THEN
          --���b�Z�[�W�擾
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_range_err      --���b�Z�[�W�R�[�h
                        );
          --���O�֏o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_err_msg
          );
          --���^�[���R�[�h�ɃG���[��ݒ�
          ov_retcode := cv_status_error;
        END IF;
      END IF;
    END IF;
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD END
    --�G���[�̏ꍇ�A���O�o�͗p��ERRBUF��ݒ�
    IF ( ov_retcode = cv_status_error ) THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    END IF;
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
  END get_relation_data;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_info_data
   * Description      : �ڋq���擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_cust_info_data(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_info_data'; -- �v���O������
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
    -- *** ���[�J���z�� ***
    l_cust_tab  g_cust_ttype;        -- �ڋq�w��p
    l_vend_tab  g_vend_ttype;        -- �d����w��p
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD START
    l_chk_tab   g_chk_ttype;         -- �p�����[�^�`�F�b�N�p
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD END
--
    -- *** ���[�J���ϐ� ***
    ln_cnt        BINARY_INTEGER := 0; -- �z��Y����
    lv_sqlerrm    VARCHAR2(5000);      -- SQLERRM�i�[�p
    lv_msg_tnk    VARCHAR2(100);       -- ���b�Z�[�W�g�[�N���p
    ld_first_date DATE;                -- �p�����[�^�w�����1��
    ld_last_date  DATE;                -- �p�����^�[�w����̖���
--
    -- ===============================
    -- ���[�J���E�J�[�\��
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- 1���Ɩ����̎擾
    ld_first_date := TO_DATE( g_input_rec.target_date, cv_date_yyyymm );
    ld_last_date  := LAST_DAY( TO_DATE( g_input_rec.target_date, cv_date_yyyymm ) );
--
    -- =======================================
    -- ���s�敪��1�i�ڋq�w��Ŏ��s�j�̏ꍇ
    -- =======================================
    IF ( g_input_rec.execute_type = cv_1 ) THEN
--
      -----------------------------------------
      -- �w�肪����ڋq�R�[�h�̂݊i�[(�z��F�a�˖�)
      -----------------------------------------
      << cust_loop >>
      FOR i IN 1.. g_cust_tab.COUNT LOOP
        IF ( g_cust_tab(i) IS NOT NULL ) THEN
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD START
          --�p�����[�^�ɓ���ڋq��2�ȏ�ݒ肳��Ă��Ȃ����`�F�b�N
          IF ( l_chk_tab.EXISTS( g_cust_tab(i) ) ) THEN
            --����ڋq�����ɑ��݂���ꍇ�A�ݒ肵�Ȃ�
            NULL;
          ELSE
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD END
            ln_cnt             := ln_cnt + 1;
            l_cust_tab(ln_cnt) := g_cust_tab(i);
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD START
            l_chk_tab( g_cust_tab(i) ) := 1; --�`�F�b�N�p�z��Ƀ_�~�[�l�ݒ�
          END IF;
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD END
        END IF;
      END LOOP cust_loop;
      -- �O���[�o���z��폜
      g_cust_tab.DELETE;
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD START
      -- �`�F�b�N�p�̔z��폜
      l_chk_tab.DELETE;
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD END
--
      BEGIN
        -----------------------------------------
        -- ���̋@�̔��񍐏��ڋq���ꎞ�\�쐬
        -----------------------------------------
        FORALL i IN 1.. l_cust_tab.COUNT
          INSERT INTO xxcos_tmp_vd_cust_info (
             customer_code        -- �ڋq�R�[�h
            ,customer_name        -- �ڋq����
            ,party_id             -- �p�[�e�BID
            ,sales_base_name      -- ���㋒�_����
            ,sales_base_city      -- �s���{���s��i���㋒�_
            ,sales_base_address1  -- �Z���P�i���㋒�_�j
            ,sales_base_address2  -- �Z���Q�i���㋒�_�j
            ,sales_base_tel       -- �d�b�ԍ��i���㋒�_�j
            ,vendor_code          -- �d����R�[�h
            ,vendor_name          -- �d���於�́i���t��j
            ,vendor_zip           -- �X�֔ԍ��i���t��j
            ,vendor_address1      -- �Z���P�i���t��j
            ,vendor_address2      -- �Z���Q�i���t��j
            ,date_from            -- �Ώۊ��ԊJ�n��
            ,date_to              -- �Ώۊ��ԏI����
          )
          SELECT /*+
                   USE_NL(hca xca hp)
                   USE_NL(xac hcab hpb)
                 */
                 hca.account_number         customer_code       -- �ڋq�R�[�h
                ,hp.party_name              customer_name       -- �ڋq����
                ,hp.party_id                party_id            -- �p�[�e�BID
                ,hpb.party_name             sales_base_name     -- ���㋒�_����
                ,hlb.state || hlb.city      sales_base_city     -- �s���{���s��(���㋒�_)
                ,hlb.address1               sales_base_address1 -- �Z���P(���㋒�_)
                ,hlb.address2               sales_base_address2 -- �Z���Q(���㋒�_)
                ,hlb.address_lines_phonetic sales_base_tel      -- �d�b�ԍ�(���㋒�_)
                ,pv.segment1                vendor_code         -- �d����R�[�h
                ,CASE
                  -- �d���悪����ꍇ
                  WHEN ( pv.segment1 IS NOT NULL ) THEN
                    pvs.attribute1
                  -- �d���悪�Ȃ��A�Ƒԏ����ނ�25�̏ꍇ
                  WHEN ( pv.segment1 IS NULL AND xca.business_low_type = cv_bus_low_type_25 ) THEN
                    SUBSTRB( hp.party_name, 1, 240 )
                  ELSE
                    NULL
                 END                        vendor_name         -- �d���於��
                ,CASE
                  -- �d���悪����ꍇ
                  WHEN ( pv.segment1 IS NOT NULL ) THEN
                    pvs.zip
                  -- �d���悪�Ȃ��A�Ƒԏ����ނ�25�̏ꍇ
                  WHEN ( pv.segment1 IS NULL AND xca.business_low_type = cv_bus_low_type_25 ) THEN
                    hl.postal_code
                  ELSE
                    NULL
                 END                        zip                 -- �X�֔ԍ�
                ,CASE
                  -- �d���悪����ꍇ
                  WHEN ( pv.segment1 IS NOT NULL ) THEN
                    pvs.address_line1
                  -- �d���悪�Ȃ��A�Ƒԏ����ނ�25�̏ꍇ
                  WHEN ( pv.segment1 IS NULL AND xca.business_low_type = cv_bus_low_type_25 ) THEN
                    SUBSTRB( hl.state || hl.city || hl.address1 , 1, 240 )
                  ELSE
                    NULL
                 END                        address_line1       -- �Z���P
                ,CASE
                  -- �d���悪����ꍇ
                  WHEN ( pv.segment1 IS NOT NULL ) THEN
                    pvs.address_line2
                  -- �d���悪�Ȃ��A�Ƒԏ����ނ�25�̏ꍇ
                  WHEN ( pv.segment1 IS NULL AND xca.business_low_type = cv_bus_low_type_25 ) THEN
                    hl.address2
                  ELSE
                    NULL
                 END                        address_line2       -- �Z���Q
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 MOD START
--                ,CASE
--                   -- �����̏ꍇ(NULL=�̔��萔���Ȃ��̏ꍇ��)
--                   WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
--                     -- �w�茎��1��
--                     ld_first_date
--                   -- 2����28��,29�����l��
--                   WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ),cv_date_dd ) ) THEN
--                     TO_DATE(    TO_CHAR( ADD_MONTHS( ld_first_date, -1 ), cv_date_yyyymm )
--                              || xcm.close_day_code, cv_date_yyyymmdd) + 1
--                   -- �����ȊO
--                   ELSE
--                     -- �O������+1��
--                     ADD_MONTHS(TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd ),-1 ) + 1
--                 END                        date_from           -- �Ώۊ��ԊJ�n��
                ,CASE
                   -- ���̓p�����[�^�u�N���v�Ō���
                   WHEN g_input_rec.dlv_date_from IS NULL THEN
                     --
                     CASE
                       -- �����̏ꍇ(NULL=�̔��萔���Ȃ��̏ꍇ��)
                       WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
                         -- �w�茎��1��
                         ld_first_date
                       -- 2����28��,29�����l��
                       WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ),cv_date_dd ) ) THEN
                         TO_DATE(    TO_CHAR( ADD_MONTHS( ld_first_date, -1 ), cv_date_yyyymm )
                                  || xcm.close_day_code, cv_date_yyyymmdd) + 1
                       -- �����ȊO
                       ELSE
                         -- �O������+1��
                         ADD_MONTHS(TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd ),-1 ) + 1
                     END
                   -- ���̓p�����[�^�u�[�i��FROM/TO�v�Ō���
                   ELSE
                     -- ���̓p�����[�^�u�[�i��FROM�v
                     g_input_rec.dlv_date_from 
                 END                        date_from           -- �Ώۊ��ԊJ�n��
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 MOD END
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 MOD START
--                ,CASE
--                   -- �����̏ꍇ(NULL=�̔��萔���Ȃ��̏ꍇ��)
--                   WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
--                     -- �w�茎�̍ŏI��
--                     ld_last_date
--                   --2����28��,29�����l��
--                   WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ), cv_date_dd ) ) THEN
--                     -- �w�茎�̍ŏI��(2��28 or 29)
--                     ld_last_date
--                   -- �����ȊO
--                   ELSE
--                     --�w�茎�̒���
--                     TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd )
--                 END                        date_to             -- �Ώۊ��ԏI����
                ,CASE
                   -- ���̓p�����[�^�u�N���v�Ō���
                   WHEN g_input_rec.dlv_date_to IS NULL THEN
                     CASE
                       -- �����̏ꍇ(NULL=�̔��萔���Ȃ��̏ꍇ��)
                       WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
                         -- �w�茎�̍ŏI��
                         ld_last_date
                       --2����28��,29�����l��
                       WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ), cv_date_dd ) ) THEN
                         -- �w�茎�̍ŏI��(2��28 or 29)
                         ld_last_date
                       -- �����ȊO
                       ELSE
                         --�w�茎�̒���
                         TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd )
                     END
                   -- ���̓p�����[�^�u�[�i��FROM/TO�v�Ō���
                   ELSE
                     -- ���̓p�����[�^�u�[�i��TO�v
                     g_input_rec.dlv_date_to
                 END                        date_to             -- �Ώۊ��ԏI����
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 MOD END
          FROM   hz_cust_accounts           hca       -- �ڋq�}�X�^(�ڋq)
                ,xxcmm_cust_accounts        xca       -- �ڋq�ǉ����(�ڋq)
                ,hz_parties                 hp        -- �p�[�e�B�}�X�^(�ڋq)
                ,hz_cust_acct_sites_all     hcasa     -- �ڋq���ݒn�}�X�^(�ڋq)
                ,hz_party_sites             hps       -- �p�[�e�B�T�C�g�}�X�^(�ڋq)
                ,hz_locations               hl        -- �ڋq���Ə��}�X�^(�ڋq)
                ,xxcso_contract_managements xcm       -- �_��Ǘ�
                ,hz_cust_accounts           hcab      -- �ڋq�}�X�^(���㋒�_)
                ,hz_parties                 hpb       -- �p�[�e�B�}�X�^(���㋒�_)
                ,hz_cust_acct_sites_all     hcasab    -- �ڋq���ݒn�}�X�^(���㋒�_)
                ,hz_party_sites             hpsb      -- �p�[�e�B�T�C�g�}�X�^(���㋒�_)
                ,hz_locations               hlb       -- �ڋq���Ə��}�X�^(���㋒�_)
                ,po_vendors                 pv        -- �d����}�X�^(���t��)
                ,po_vendor_sites_all        pvs       -- �d����T�C�g(���t��)
          WHERE  hca.account_number            = l_cust_tab(i)      --�w�肳�ꂽ�ڋq
          AND    hca.cust_account_id           = xca.customer_id
          AND    hca.party_id                  = hp.party_id
          AND    hca.cust_account_id           = hcasa.cust_account_id
          AND    hcasa.party_site_id           = hps.party_site_id
          AND    hcasa.org_id                  = gn_org_id
          AND    hps.location_id               = hl.location_id
          AND    hca.cust_account_id           = xcm.install_account_id
          AND    xcm.contract_management_id    = (
                   SELECT /*+
                            INDEX( xcms xxcso_contract_managements_n06 )
                          */
                          MAX(xcms.contract_management_id) contract_management_id
                   FROM   xxcso_contract_managements xcms
                   WHERE  xcms.install_account_id     = hca.cust_account_id
                   AND    xcms.status                 = cv_1
                   AND    xcms.cooperate_flag         = cv_1
                 )                                   --�m��ρE�}�X�^�A�g�ς̍ŐV�_��
          AND    xca.sale_base_code            = hcab.account_number
          AND    hcab.party_id                 = hpb.party_id
          AND    hcab.cust_account_id          = hcasab.cust_account_id
          AND    hcasab.party_site_id          = hpsb.party_site_id
          AND    hcasab.org_id                 = gn_org_id
          AND    hpsb.location_id              = hlb.location_id
          AND    xca.contractor_supplier_code  = pv.segment1(+)
          AND    pv.vendor_id                  = pvs.vendor_id(+)
          AND    pv.segment1                   = pvs.vendor_site_code(+)
          AND    pvs.org_id(+)                 = gn_org_id
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SUBSTRB( SQLERRM, 1, 5000 );  --SQLERRM�i�[
          RAISE insert_expt;
      END;
--
      --�z����폜
      l_cust_tab.DELETE;
--
    -- =======================================
    -- ���s�敪��2�i�d����w��Ŏ��s�j�̏ꍇ
    -- =======================================
    ELSIF ( g_input_rec.execute_type = cv_2 ) THEN
--
      -------------------------------------------
      -- �w�肪����d����R�[�h�̂݊i�[(�z��F�a�˖�)
      -------------------------------------------
      << vend_loop >>
      FOR i IN 1.. g_vend_tab.COUNT LOOP
        IF ( g_vend_tab(i) IS NOT NULL ) THEN
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD START
          --�p�����[�^�ɓ���d���悪2�ȏ�ݒ肳��Ă��Ȃ����`�F�b�N
          IF ( l_chk_tab.EXISTS( g_vend_tab(i) ) ) THEN
            --����d���悪���ɑ��݂���ꍇ�A�ݒ肵�Ȃ�
            NULL;
          ELSE
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD END
            ln_cnt             := ln_cnt + 1;
            l_vend_tab(ln_cnt) := g_vend_tab(i);
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD START
            l_chk_tab( g_vend_tab(i) ) := 1; --�`�F�b�N�p�z��Ƀ_�~�[�l�ݒ�
          END IF;
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD END
        END IF;
      END LOOP vend_loop;
      -- �O���[�o���z��폜
      g_vend_tab.DELETE;
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD START
      -- �`�F�b�N�p�̔z��폜
      l_chk_tab.DELETE;
-- 2012/12/19 Ver.1.1 Onotsuka E_�{�ғ�_10275 ADD END
--
      BEGIN
        -----------------------------------------
        -- ���̋@�̔��񍐏��ڋq���ꎞ�\�쐬
        -----------------------------------------
        FORALL i IN 1.. l_vend_tab.COUNT
          INSERT INTO xxcos_tmp_vd_cust_info (
             customer_code        -- �ڋq�R�[�h
            ,customer_name        -- �ڋq����
            ,party_id             -- �p�[�e�BID
            ,sales_base_name      -- ���㋒�_����
            ,sales_base_city      -- �s���{���s��i���㋒�_
            ,sales_base_address1  -- �Z���P�i���㋒�_�j
            ,sales_base_address2  -- �Z���Q�i���㋒�_�j
            ,sales_base_tel       -- �d�b�ԍ��i���㋒�_�j
            ,vendor_code          -- �d����R�[�h
            ,vendor_name          -- �d���於�́i���t��j
            ,vendor_zip           -- �X�֔ԍ��i���t��j
            ,vendor_address1      -- �Z���P�i���t��j
            ,vendor_address2      -- �Z���Q�i���t��j
            ,date_from            -- �Ώۊ��ԊJ�n��
            ,date_to              -- �Ώۊ��ԏI����
          )
          SELECT /*+
                   USE_NL(hca xca hp)
                   USE_NL(xac hcab hpb)
                 */
                 hca.account_number         customer_code       -- �ڋq�R�[�h
                ,hp.party_name              customer_name       -- �ڋq����
                ,hp.party_id                party_id            -- �p�[�e�BID
                ,hpb.party_name             sales_base_name     -- ���㋒�_����
                ,hlb.state || hlb.city      sales_base_city     -- �s���{���s��(���㋒�_)
                ,hlb.address1               sales_base_address1 -- �Z���P(���㋒�_)
                ,hlb.address2               sales_base_address2 -- �Z���Q(���㋒�_)
                ,hlb.address_lines_phonetic sales_base_tel      -- �d�b�ԍ�(���㋒�_)
                ,pv.segment1                vendor_code         -- �d����R�[�h
                ,pvs.attribute1             vendor_name         -- �d���於��
                ,pvs.zip                    vendor_zip          -- �X�֔ԍ�
                ,pvs.address_line1          address_line1       -- �Z���P
                ,pvs.address_line2          address_line2       -- �Z���Q
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 MOD START
--                ,CASE
--                   -- �����̏ꍇ
--                   WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
--                     -- �w�茎��1��
--                     ld_first_date
--                   -- 2����28��,29�����l��
--                   WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ),cv_date_dd ) ) THEN
--                     TO_DATE(    TO_CHAR( ADD_MONTHS( ld_first_date, -1 ), cv_date_yyyymm )
--                              || xcm.close_day_code, cv_date_yyyymmdd) + 1
--                   -- �����ȊO
--                   ELSE
--                     -- �O������+1��
--                     ADD_MONTHS(TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd ),-1 ) + 1
--                 END                        date_from           -- �Ώۊ��ԊJ�n��
                ,CASE
                   -- ���̓p�����[�^�u�N���v�Ō���
                   WHEN g_input_rec.dlv_date_from IS NULL THEN
                     --
                     CASE
                       -- �����̏ꍇ
                       WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
                         -- �w�茎��1��
                         ld_first_date
                       -- 2����28��,29�����l��
                       WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ),cv_date_dd ) ) THEN
                         TO_DATE(    TO_CHAR( ADD_MONTHS( ld_first_date, -1 ), cv_date_yyyymm )
                                  || xcm.close_day_code, cv_date_yyyymmdd) + 1
                       -- �����ȊO
                       ELSE
                         -- �O������+1��
                         ADD_MONTHS(TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd ),-1 ) + 1
                     END
                   -- ���̓p�����[�^�u�[�i��FROM/TO�v�Ō���
                   ELSE
                     -- ���̓p�����[�^�u�[�i��FROM�v
                     g_input_rec.dlv_date_from 
                 END                        date_from           -- �Ώۊ��ԊJ�n��
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 MOD END
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 MOD START
--                ,CASE
--                   -- �����̏ꍇ
--                   WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
--                     -- �w�茎�̍ŏI��
--                     ld_last_date
--                   --2����28��,29�����l��
--                   WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ), cv_date_dd ) ) THEN
--                     -- �w�茎�̍ŏI��(2��28 or 29)
--                     ld_last_date
--                   -- �����ȊO
--                   ELSE
--                     --�w�茎�̒���
--                     TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd )
--                 END                        date_to             -- �Ώۊ��ԏI����
                ,CASE
                   -- ���̓p�����[�^�u�N���v�Ō���
                   WHEN g_input_rec.dlv_date_to IS NULL THEN
                     --
                     CASE
                       -- �����̏ꍇ
                       WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
                         -- �w�茎�̍ŏI��
                         ld_last_date
                       --2����28��,29�����l��
                       WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ), cv_date_dd ) ) THEN
                         -- �w�茎�̍ŏI��(2��28 or 29)
                         ld_last_date
                       -- �����ȊO
                       ELSE
                         --�w�茎�̒���
                         TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd )
                     END
                   -- ���̓p�����[�^�u�[�i��FROM/TO�v�Ō���
                   ELSE
                     -- ���̓p�����[�^�u�[�i��TO�v
                     g_input_rec.dlv_date_to
                 END                        date_to             -- �Ώۊ��ԏI����
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 MOD END
          FROM   hz_cust_accounts           hca       -- �ڋq�}�X�^(�ڋq)
                ,xxcmm_cust_accounts        xca       -- �ڋq�ǉ����(�ڋq)
                ,hz_parties                 hp        -- �p�[�e�B�}�X�^(�ڋq)
                ,xxcso_contract_managements xcm       -- �_��Ǘ�
                ,hz_cust_accounts           hcab      -- �ڋq�}�X�^(���㋒�_)
                ,hz_parties                 hpb       -- �p�[�e�B�}�X�^(���㋒�_)
                ,hz_cust_acct_sites_all     hcasab    -- �ڋq���ݒn�}�X�^(���㋒�_)
                ,hz_party_sites             hpsb      -- �p�[�e�B�T�C�g�}�X�^(���㋒�_)
                ,hz_locations               hlb       -- �ڋq���Ə��}�X�^(���㋒�_)
                ,po_vendors                 pv        -- �d����}�X�^(���t��)
                ,po_vendor_sites_all        pvs       -- �d����T�C�g(���t��)
          WHERE  pv.segment1                   = l_vend_tab(i)      --�w�肳�ꂽ�d����
          AND    hca.account_number            = xca.customer_code
          AND    hca.party_id                  = hp.party_id
          AND    hca.cust_account_id           = xcm.install_account_id
          AND    xcm.contract_management_id    = (
                   SELECT /*+
                            INDEX( xcms xxcso_contract_managements_n06 )
                          */
                          MAX(xcms.contract_management_id) contract_management_id
                   FROM   xxcso_contract_managements xcms
                   WHERE  xcms.install_account_id     = hca.cust_account_id
                   AND    xcms.status                 = cv_1
                   AND    xcms.cooperate_flag         = cv_1
                 )                                   --�m��ρE�}�X�^�A�g�ς̍ŐV�_��
          AND    xca.sale_base_code            = hcab.account_number
          AND    hcab.party_id                 = hpb.party_id
          AND    hcab.cust_account_id          = hcasab.cust_account_id
          AND    hcasab.party_site_id          = hpsb.party_site_id
          AND    hcasab.org_id                 = gn_org_id
          AND    hpsb.location_id              = hlb.location_id
          AND    xca.contractor_supplier_code  = pv.segment1
          AND    pv.vendor_id                  = pvs.vendor_id
          AND    pv.segment1                   = pvs.vendor_site_code
          AND    pvs.org_id                    = gn_org_id
          AND    (
                   (
                        ( g_input_rec.manager_flag = cv_n )
                    AND ( pvs.attribute5     NOT IN ( SELECT xlbiv1.base_code base_code
                                                      FROM   xxcos_login_base_info_v xlbiv1
                                                    )
                        )
                    AND (
                          xca.sale_base_code  IN    ( SELECT xlbiv2.base_code base_code
                                                      FROM   xxcos_login_base_info_v xlbiv2
                                                    )
                        )
                   )                                                -- �⍇���S�����_�Ŗ����ꍇ�A�����_���̂�
                   OR
                   (
                        ( g_input_rec.manager_flag = cv_n )
                    AND 
                        (
                          pvs.attribute5      IN    ( SELECT xlbiv3.base_code base_code
                                                      FROM   xxcos_login_base_info_v xlbiv3
                                                    )
                        )
                   )                                                -- �⍇���S�����_�̏ꍇ�A�z���̑S��
                   OR
                   (
                      g_input_rec.manager_flag = cv_y
                   )                                                -- �Ǘ��҂̏ꍇ�S��
                 )
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SUBSTRB( SQLERRM, 1, 5000 ); --SQLERRM�i�[
          RAISE insert_expt;
      END;
--
      --�z����폜
      l_vend_tab.DELETE;
--
-- Ver.1.3 Add Start
    -- =======================================
    -- ���s�敪��3�i�⍇�����_�w��Ŏ��s�j�̏ꍇ
    -- =======================================
    ELSIF ( g_input_rec.execute_type = cv_3 ) THEN
--
      BEGIN
        -----------------------------------------
        -- ���̋@�̔��񍐏��ڋq���ꎞ�\�쐬
        -----------------------------------------
        INSERT INTO xxcos_tmp_vd_cust_info (
           customer_code        -- �ڋq�R�[�h
          ,customer_name        -- �ڋq����
          ,party_id             -- �p�[�e�BID
          ,sales_base_name      -- ���㋒�_����
          ,sales_base_city      -- �s���{���s��i���㋒�_
          ,sales_base_address1  -- �Z���P�i���㋒�_�j
          ,sales_base_address2  -- �Z���Q�i���㋒�_�j
          ,sales_base_tel       -- �d�b�ԍ��i���㋒�_�j
          ,vendor_code          -- �d����R�[�h
          ,vendor_name          -- �d���於�́i���t��j
          ,vendor_zip           -- �X�֔ԍ��i���t��j
          ,vendor_address1      -- �Z���P�i���t��j
          ,vendor_address2      -- �Z���Q�i���t��j
          ,date_from            -- �Ώۊ��ԊJ�n��
          ,date_to              -- �Ώۊ��ԏI����
        )
        SELECT /*+
                 LEADING(pvs)
                 USE_NL(pvs pv xca hca)
               */
               hca.account_number         customer_code       -- �ڋq�R�[�h
              ,hp.party_name              customer_name       -- �ڋq����
              ,hp.party_id                party_id            -- �p�[�e�BID
              ,hpb.party_name             sales_base_name     -- ���㋒�_����
              ,hlb.state || hlb.city      sales_base_city     -- �s���{���s��(���㋒�_)
              ,hlb.address1               sales_base_address1 -- �Z���P(���㋒�_)
              ,hlb.address2               sales_base_address2 -- �Z���Q(���㋒�_)
              ,hlb.address_lines_phonetic sales_base_tel      -- �d�b�ԍ�(���㋒�_)
              ,pv.segment1                vendor_code         -- �d����R�[�h
              ,pvs.attribute1             vendor_name         -- �d���於��
              ,pvs.zip                    vendor_zip          -- �X�֔ԍ�
              ,pvs.address_line1          address_line1       -- �Z���P
              ,pvs.address_line2          address_line2       -- �Z���Q
              ,CASE
                 -- ���̓p�����[�^�u�N���v�Ō���
                 WHEN g_input_rec.dlv_date_from IS NULL THEN
                   --
                   CASE
                     -- �����̏ꍇ
                     WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
                       -- �w�茎��1��
                       ld_first_date
                     -- 2����28��,29�����l��
                     WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ),cv_date_dd ) ) THEN
                       TO_DATE(    TO_CHAR( ADD_MONTHS( ld_first_date, -1 ), cv_date_yyyymm )
                                || xcm.close_day_code, cv_date_yyyymmdd) + 1
                     -- �����ȊO
                     ELSE
                       -- �O������+1��
                       ADD_MONTHS(TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd ),-1 ) + 1
                   END
                 -- ���̓p�����[�^�u�[�i��FROM/TO�v�Ō���
                 ELSE
                   -- ���̓p�����[�^�u�[�i��FROM�v
                   g_input_rec.dlv_date_from 
               END                        date_from           -- �Ώۊ��ԊJ�n��
              ,CASE
                 -- ���̓p�����[�^�u�N���v�Ō���
                 WHEN g_input_rec.dlv_date_to IS NULL THEN
                   --
                   CASE
                     -- �����̏ꍇ
                     WHEN NVL( xcm.close_day_code, cv_30 ) = cv_30 THEN
                       -- �w�茎�̍ŏI��
                       ld_last_date
                     --2����28��,29�����l��
                     WHEN TO_NUMBER( xcm.close_day_code ) >= TO_NUMBER( TO_CHAR( LAST_DAY( ld_first_date ), cv_date_dd ) ) THEN
                       -- �w�茎�̍ŏI��(2��28 or 29)
                       ld_last_date
                     -- �����ȊO
                     ELSE
                       --�w�茎�̒���
                       TO_DATE( g_input_rec.target_date || cv_slash || xcm.close_day_code, cv_date_yyyymmdd )
                   END
                 -- ���̓p�����[�^�u�[�i��FROM/TO�v�Ō���
                 ELSE
                   -- ���̓p�����[�^�u�[�i��TO�v
                   g_input_rec.dlv_date_to
               END                        date_to             -- �Ώۊ��ԏI����
        FROM   hz_cust_accounts           hca       -- �ڋq�}�X�^(�ڋq)
              ,xxcmm_cust_accounts        xca       -- �ڋq�ǉ����(�ڋq)
              ,hz_parties                 hp        -- �p�[�e�B�}�X�^(�ڋq)
              ,xxcso_contract_managements xcm       -- �_��Ǘ�
              ,hz_cust_accounts           hcab      -- �ڋq�}�X�^(���㋒�_)
              ,hz_parties                 hpb       -- �p�[�e�B�}�X�^(���㋒�_)
              ,hz_cust_acct_sites_all     hcasab    -- �ڋq���ݒn�}�X�^(���㋒�_)
              ,hz_party_sites             hpsb      -- �p�[�e�B�T�C�g�}�X�^(���㋒�_)
              ,hz_locations               hlb       -- �ڋq���Ə��}�X�^(���㋒�_)
              ,po_vendors                 pv        -- �d����}�X�^(���t��)
              ,po_vendor_sites_all        pvs       -- �d����T�C�g(���t��)
        WHERE  pvs.attribute5                = g_input_rec.sales_base_code   --�w�肳�ꂽ�⍇�����_
        AND    xca.business_low_type         IN ( cv_bus_low_type_24, cv_bus_low_type_25 )  --�Ƒԏ����ށF24(�t��VD����)�A25�i�t��VD�j
        AND    hca.customer_class_code       = cv_10
        AND    hca.cust_account_id           = xca.customer_id
        AND    hca.party_id                  = hp.party_id
        AND    hca.cust_account_id           = xcm.install_account_id
        AND    xcm.contract_management_id    = (
                 SELECT /*+
                          INDEX( xcms xxcso_contract_managements_n06 )
                        */
                        MAX(xcms.contract_management_id) contract_management_id
                 FROM   xxcso_contract_managements xcms
                 WHERE  xcms.install_account_id     = hca.cust_account_id
                 AND    xcms.status                 = cv_1
                 AND    xcms.cooperate_flag         = cv_1
               )                                   --�m��ρE�}�X�^�A�g�ς̍ŐV�_��
        AND    xca.sale_base_code            = hcab.account_number
        AND    hcab.party_id                 = hpb.party_id
        AND    hcab.cust_account_id          = hcasab.cust_account_id
        AND    hcasab.party_site_id          = hpsb.party_site_id
        AND    hcasab.org_id                 = gn_org_id
        AND    hpsb.location_id              = hlb.location_id
        AND    xca.contractor_supplier_code  = pv.segment1
        AND    pv.vendor_id                  = pvs.vendor_id
        AND    pv.segment1                   = pvs.vendor_site_code
        AND    pvs.org_id                    = gn_org_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SUBSTRB( SQLERRM, 1, 5000 );  --SQLERRM�i�[
          RAISE insert_expt;
      END;
-- Ver.1.3 Add End
    END IF;
--
    --�����I�����������O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_date_time )
    );
    --���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
    -- *** �f�[�^�o�^��O ***
    WHEN insert_expt THEN
      -- �e�[�u�����擾
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_tmp_table   -- ���̋@�̔��񍐏��ڋq���ꎞ�\
                    );
      -- ���b�Z�[�W�擾
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_insert_err      -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table_name
                      ,iv_token_value1 => lv_msg_tnk             -- �e�[�u����
                      ,iv_token_name2  => cv_tkn_key_data
                      ,iv_token_value2 => lv_sqlerrm             -- SQLERRM
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END get_cust_info_data;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp_data
   * Description      : �̔����擾����(A-4)
   ***********************************************************************************/
  PROCEDURE get_sales_exp_data(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_exp_data'; -- �v���O������
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
    cv_prof_group   CONSTANT VARCHAR2(21) := 'HZ_ORG_PROFILES_GROUP';   -- �v���t�@�C���O���[�v
    cv_resource     CONSTANT VARCHAR2(8)  := 'RESOURCE';                -- ���\�[�X
    cv_no_item      CONSTANT VARCHAR2(23) := 'XXCOS1_NO_INV_ITEM_CODE'; -- �N�C�b�N�R�[�h(��݌ɕi)
--
    -- *** ���[�J���ϐ� ***
    lv_sqlerrm        VARCHAR2(5000);                                  -- SQLERRM�i�[�p
    lv_msg_tnk        VARCHAR2(100);                                   -- ���b�Z�[�W�g�[�N���p
    lv_wrnmsg         VARCHAR2(5000);                                  -- �`�F�b�N���b�Z�[�W�p
    lv_salesrep_name  VARCHAR2(300);                                   -- �ڋq�S���Җ���
    lv_output_flag    VARCHAR2(1);                                     -- �o�͑Ώۃt���O
    lt_cust_code      hz_cust_accounts.account_number%TYPE;            -- �ڋq�u���[�N�p
    lt_party_id       hz_parties.party_id%TYPE;                        -- �ڋq�u���[�N���̒S���c�Ǝ擾�p
    ln_work_ind       BINARY_INTEGER;                                  -- �ꎞ�i�[�f�[�^�p�̍���
    ln_create_ind     BINARY_INTEGER;                                  -- �쐬�f�[�^�p�̍���
    lt_dlv_date       xxcos_sales_exp_headers.delivery_date%TYPE;      -- �ڋq�ʊ��ԍő�[�i���擾�p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �̔����ю擾�J�[�\��
    CURSOR get_vd_sales_cur
    IS
      SELECT /*+
               LEADING(xtvci)
               USE_NL(xseh)
               USE_NL(iimb)
               USE_NL(ximb)
               INDEX( xseh xxcos_sales_exp_headers_n08 )
               INDEX( mcb mtl_categories_b_u1)
             */
             xtvci.vendor_zip                     vendor_zip              -- �X�֔ԍ��i���t��j
            ,xtvci.vendor_address1                vendor_address1         -- �Z���P�i���t��j
            ,xtvci.vendor_address2                vendor_address2         -- �Z���Q�i���t��j
            ,xtvci.vendor_name                    vendor_name             -- �d���於�́i���t��j
            ,xtvci.customer_code                  customer_code           -- �ڋq�R�[�h
            ,xtvci.vendor_code                    vendor_code             -- �d����R�[�h
            ,xtvci.sales_base_city                sales_base_city         -- �s���{���s��i���㋒�_�j
            ,xtvci.sales_base_address1            sales_base_address1     -- �Z���P�i���㋒�_�j
            ,xtvci.sales_base_address2            sales_base_address2     -- �Z���Q�i���㋒�_�j
            ,xtvci.sales_base_name                sales_base_name         -- ���㋒�_����
            ,xtvci.sales_base_tel                 sales_base_tel          -- �d�b�ԍ��i���㋒�_�j
            ,xtvci.date_from                      date_from               -- �Ώۊ��ԊJ�n��
            ,xtvci.date_to                        date_to                 -- �Ώۊ��ԏI����
            ,xtvci.customer_name                  customer_name           -- �ڋq����
            ,ximb.item_short_name                 item_short_name         -- ����
            ,xsel.dlv_unit_price                  dlv_unit_price          -- �[�i�P��
            ,SUM( xsel.dlv_qty )                  sum_dlv_qty             -- �[�i���ʍ��v
            ,SUM( xsel.sale_amount )              sum_sale_amount         -- ������z���v
            ,xtvci.party_id                       party_id                -- �p�[�e�BID(�S���c�Ǝ擾����)
            ,MAX(xseh.delivery_date )             delivery_date           -- �[�i��
            ,iimb.item_no                         item_no                 -- �i�ڃR�[�h(���b�Z�[�W�o�͗p)
      FROM   xxcos_tmp_vd_cust_info      xtvci --���̋@�̔��񍐏��ڋq���ꎞ�\
            ,xxcos_sales_exp_headers     xseh  --�̔����уw�b�_
            ,xxcos_sales_exp_lines       xsel  --�̔����і���
            ,ic_item_mst_b               iimb  --OPM�i�ڃ}�X�^
            ,xxcmn_item_mst_b            ximb  --OPM�i�ڃA�h�I��
            ,mtl_system_items_b          msib  --Disc�i�ڃ}�X�^
            ,mtl_item_categories         mic   --�i�ڃJ�e�S��
            ,mtl_categories_b            mcb   --�J�e�S��
      WHERE xtvci.customer_code                        = xseh.ship_to_customer_code
      AND   xseh.delivery_date                        >= xtvci.date_from                             -- �ڋq���̒����͈̔�
      AND   xseh.delivery_date                        <= xtvci.date_to                               -- �ڋq���̒����͈̔�
      AND   xseh.cust_gyotai_sho                      IN ( cv_bus_low_type_24, cv_bus_low_type_25 )  -- �Ƒԏ�����
      AND   xseh.sales_exp_header_id                   = xsel.sales_exp_header_id
      AND   NOT EXISTS (
              SELECT 1
              FROM   fnd_lookup_values flv
              WHERE  flv.lookup_type  = cv_no_item
              AND    flv.lookup_code  = xsel.item_code
              AND    flv.language     = ct_lang
              AND    flv.enabled_flag = cv_y
              AND    gd_proc_date BETWEEN flv.start_date_active
                                  AND     NVL(  flv.end_date_active, gd_proc_date )
            )                                                                                       -- ��݌ɕi�ȊO
      AND   xsel.sales_class                         IN ( cv_1, cv_3 )                              -- �ʏ�ƃx���_����̂�
      AND   xsel.item_code                            = iimb.item_no
      AND   iimb.item_id                              = ximb.item_id
      AND   ximb.start_date_active                   <= gd_proc_date                                -- �Ɩ����t���_�ŗL��
      AND   NVL(ximb.end_date_active, gd_proc_date)  >= gd_proc_date                                -- �Ɩ����t���_�ŗL��
      AND   iimb.item_no                              = msib.segment1
      AND   msib.organization_id                      = gn_organization_id
      AND   msib.inventory_item_id                    = mic.inventory_item_id
      AND   mic.category_set_id                       = gt_category_set_id
      AND   mic.organization_id                       = gn_organization_id
      AND   mic.category_id                           = mcb.category_id
      GROUP BY
             xtvci.vendor_zip              --�X�֔ԍ��i���t��j
            ,xtvci.vendor_address1         --�Z���P�i���t��j
            ,xtvci.vendor_address2         --�Z���Q�i���t��j
            ,xtvci.vendor_name             --�d���於�́i���t��j
            ,xtvci.customer_code           --�ڋq�R�[�h
            ,xtvci.vendor_code             --�d����R�[�h
            ,xtvci.sales_base_city         --�s���{���s��i���㋒�_�j
            ,xtvci.sales_base_address1     --�Z���P�i���㋒�_�j
            ,xtvci.sales_base_address2     --�Z���Q�i���㋒�_�j
            ,xtvci.sales_base_name         --���㋒�_����
            ,xtvci.sales_base_tel          --�d�b�ԍ��i���㋒�_�j
            ,xtvci.date_from               --�Ώۊ��ԊJ�n��
            ,xtvci.date_to                 --�Ώۊ��ԏI����
            ,xtvci.customer_name           --�ڋq����
            ,mcb.segment1                  --����Q�R�[�h
            ,iimb.item_no                  --�i�ڃR�[�h
            ,ximb.item_short_name          --����
            ,xsel.dlv_unit_price           --�[�i�P��
            ,xtvci.party_id                --�p�[�e�BID
      HAVING
            ( SUM( xsel.dlv_qty ) <> 0 OR SUM( xsel.sale_amount ) <> 0 )  --�T�}�����ʂ��T�}�����z��0�ȊO
      ORDER BY
            xtvci.vendor_code    --�d����R�[�h
           ,xtvci.customer_code  --�ڋq�R�[�h
           ,mcb.segment1         --����Q�R�[�h
           ,iimb.item_no         --�i�ڃR�[�h
      ;
    -- *** ���[�J���e�[�u�� ***
    TYPE l_vd_sales_ttype IS TABLE OF get_vd_sales_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    -- *** ���[�J���z�� ***
    l_vd_sales_tab l_vd_sales_ttype;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- �����P�ʂ̏�����
    gn_warn       := cv_status_normal;  --�x���I���p�ϐ�
    ln_work_ind   := 0;                 --�ꎞ�z��p����������
    ln_create_ind := 0;                 --�쐬�p����������
--
    -- �I�[�v��
    OPEN get_vd_sales_cur;
    -- �f�[�^�擾
    FETCH get_vd_sales_cur BULK COLLECT INTO l_vd_sales_tab;
    -- �N���[�Y
    CLOSE get_vd_sales_cur;
    -- �Ώی����擾
    gn_target_cnt := l_vd_sales_tab.COUNT;
--
    --------------------------------
    -- �f�[�^�̎擾�A�y�сA�ҏW����
    --------------------------------
    <<sales_loop>>
    FOR i IN 1.. gn_target_cnt LOOP
--
      -- 1���R�[�h�P�ʂ̏�����
      lv_output_flag := cv_y;  -- �o�͑Ώ�
      lv_wrnmsg      := NULL;  -- �`�F�b�N���b�Z�[�W�p
--
      --�ŏ���1���̏ꍇ�A�u���[�N�ϐ��ɒl��ݒ�
      IF ( lt_party_id IS NULL ) THEN
        lt_cust_code := l_vd_sales_tab(i).customer_code;
        lt_party_id  := l_vd_sales_tab(i).party_id;
      END IF;
      -----------------------------
      -- �[�i�P���̏����_�`�F�b�N
      -----------------------------
      IF ( TRUNC( l_vd_sales_tab(i).dlv_unit_price ) <> l_vd_sales_tab(i).dlv_unit_price ) THEN
        -- �o�͑ΏۊO�Ƃ���
        lv_output_flag := cv_n;
        -- ���b�Z�[�W�o��
        lv_wrnmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_price_wrn                  --���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_cust
                        ,iv_token_value1 => l_vd_sales_tab(i).customer_code   --�ڋq�R�[�h
                        ,iv_token_name2  => cv_tkn_item
                        ,iv_token_value2 => l_vd_sales_tab(i).item_no         --�i�ڃR�[�h
                        ,iv_token_name3  => cv_tkn_dlv_price
                        ,iv_token_value3 => l_vd_sales_tab(i).dlv_unit_price  --����
                      );
        -- ���O�֏o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_wrnmsg
        );
        -- �x���I���p�̃O���[�o���ϐ��Ɍx����ݒ�
        gn_warn     := cv_status_warn;
        -- �x�������J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
      -- �o�͑Ώۂ̂ݏo�͂���
      IF ( lv_output_flag = cv_y ) THEN
--
        -- �ꎞ�i�[�p�����̃C���N�������g
        ln_work_ind := ln_work_ind + 1;
--
        -- ���R�[�hID�擾
        SELECT xxcos_rep_vd_sales_list_s01.NEXTVAL
        INTO   g_sales_tab_work(ln_work_ind).record_id
        FROM   dual
        ;
--
        -- �ő�[�i���擾�p�̕ϐ��ɒl��ݒ�
        IF ( lt_dlv_date IS NULL ) OR ( lt_dlv_date < l_vd_sales_tab(i).delivery_date ) THEN
          lt_dlv_date := l_vd_sales_tab(i).delivery_date;
        END IF;
--
        -- �ꎞ�p�z��ɒl��ݒ�
        g_sales_tab_work(ln_work_ind).vendor_zip              :=  l_vd_sales_tab(i).vendor_zip;            -- �X�֔ԍ��i���t��j
        g_sales_tab_work(ln_work_ind).vendor_address1         :=  l_vd_sales_tab(i).vendor_address1;       -- �Z���P�i���t��j
        g_sales_tab_work(ln_work_ind).vendor_address2         :=  l_vd_sales_tab(i).vendor_address2;       -- �Z���Q�i���t��j
        g_sales_tab_work(ln_work_ind).vendor_name             :=  l_vd_sales_tab(i).vendor_name;           -- �d���於�́i���t��j
        g_sales_tab_work(ln_work_ind).customer_code           :=  l_vd_sales_tab(i).customer_code;         -- �ڋq�R�[�h
        g_sales_tab_work(ln_work_ind).vendor_code             :=  l_vd_sales_tab(i).vendor_code;           -- �d����R�[�h
        g_sales_tab_work(ln_work_ind).sales_base_city         :=  l_vd_sales_tab(i).sales_base_city;       -- �s���{���s��i���㋒�_
        g_sales_tab_work(ln_work_ind).sales_base_address1     :=  l_vd_sales_tab(i).sales_base_address1;   -- �Z���P�i���㋒�_�j
        g_sales_tab_work(ln_work_ind).sales_base_address2     :=  l_vd_sales_tab(i).sales_base_address2;   -- �Z���Q�i���㋒�_�j
        g_sales_tab_work(ln_work_ind).sales_base_name         :=  l_vd_sales_tab(i).sales_base_name;       -- ���㋒�_����
        g_sales_tab_work(ln_work_ind).sales_base_tel          :=  l_vd_sales_tab(i).sales_base_tel;        -- �d�b�ԍ��i���㋒�_�j
        g_sales_tab_work(ln_work_ind).date_from               :=  l_vd_sales_tab(i).date_from;             -- �Ώۊ��ԊJ�n��
        g_sales_tab_work(ln_work_ind).date_to                 :=  l_vd_sales_tab(i).date_to;               -- �Ώۊ��ԏI����
        g_sales_tab_work(ln_work_ind).install_location        :=  l_vd_sales_tab(i).customer_name;         -- �ݒu��ꏊ
        g_sales_tab_work(ln_work_ind).item_name               :=  l_vd_sales_tab(i).item_short_name;       -- ���i��
        g_sales_tab_work(ln_work_ind).sales_price             :=  l_vd_sales_tab(i).dlv_unit_price;        -- ����
        g_sales_tab_work(ln_work_ind).sales_qty               :=  l_vd_sales_tab(i).sum_dlv_qty;           -- �̔��{��
        g_sales_tab_work(ln_work_ind).sales_amount            :=  l_vd_sales_tab(i).sum_sale_amount;       -- �̔����z
        g_sales_tab_work(ln_work_ind).created_by              :=  cn_created_by;                           -- WHO�J����
        g_sales_tab_work(ln_work_ind).creation_date           :=  cd_creation_date;                        -- WHO�J����
        g_sales_tab_work(ln_work_ind).last_updated_by         :=  cn_last_updated_by;                      -- WHO�J����
        g_sales_tab_work(ln_work_ind).last_update_date        :=  cd_last_update_date;                     -- WHO�J����
        g_sales_tab_work(ln_work_ind).last_update_login       :=  cn_last_update_login;                    -- WHO�J����
        g_sales_tab_work(ln_work_ind).request_id              :=  cn_request_id;                           -- WHO�J����
        g_sales_tab_work(ln_work_ind).program_application_id  :=  cn_program_application_id;               -- WHO�J����
        g_sales_tab_work(ln_work_ind).program_id              :=  cn_program_id;                           -- WHO�J����
        g_sales_tab_work(ln_work_ind).program_update_date     :=  cd_program_update_date;                  -- WHO�J����
--
      END IF;
--
      -- �O���R�[�h�ƈقȂ�ꍇ�A�������́A�ŏI���R�[�h�̏ꍇ
      IF (
           ( lt_cust_code <> l_vd_sales_tab(i).customer_code )
           OR
           (
                 ( i = gn_target_cnt )
             AND ( g_sales_tab_work.COUNT <> 0 )
           )
         ) THEN
        ----------------------------------------------
        --�ڋq�S���Җ��̎擾(�͈͓��ōő�̔[�i�����_)
        ----------------------------------------------
        BEGIN
          SELECT ppf.per_information18 || ppf.per_information19  salesrep_name -- �S���c�ƈ�����
          INTO   lv_salesrep_name
          FROM   hz_organization_profiles   hop       -- �g�D�v���t�@�C��(�c�ƒS��)
                ,ego_fnd_dsc_flx_ctx_ext    efdfce    -- �g���t���t���b�N�X�R���e�L�X�g(�c�ƒS��)
                ,hz_org_profiles_ext_b      hopeb     -- �g�D�v���t�@�C���g���e�[�u��(�c�ƒS��)
                ,per_all_people_f           ppf       -- �]�ƈ��}�X�^(�c�ƒS��)
          WHERE  hop.party_id                               = lt_party_id
          AND    hop.effective_end_date                     IS NULL
          AND    hop.organization_profile_id                = hopeb.organization_profile_id
          AND    hopeb.attr_group_id                        = efdfce.attr_group_id
          AND    efdfce.application_id                      = gt_apprication_id
          AND    efdfce.descriptive_flexfield_name          = cv_prof_group
          AND    efdfce.descriptive_flex_context_code       = cv_resource
          AND    hopeb.d_ext_attr1                         <= lt_dlv_date
          AND    NVL( hopeb.d_ext_attr2, lt_dlv_date )     >= lt_dlv_date
          AND    hopeb.c_ext_attr1                          = ppf.employee_number
          AND    ppf.effective_start_date                  <= lt_dlv_date
          AND    ppf.effective_end_date                    >= lt_dlv_date
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_salesrep_name := NULL;  --�擾�ł��Ȃ��ꍇ��NULL��ݒ�
          WHEN OTHERS THEN
            lv_sqlerrm := SUBSTRB( SQLERRM, 1, 5000 ); --SQLERRM�i�[
            -- �e�[�u�����擾
            lv_msg_tnk := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => cv_msg_tkn_emp_table   -- �]�ƈ��}�X�^
                          );
            RAISE select_expt;
        END;
--
        -- �쐬�p�z��ɃZ�b�g
        <<ins_set_loop>>
        FOR i2 IN 1.. g_sales_tab_work.COUNT LOOP
--
          --�쐬�p�z��̍����̃C���N�������g
          ln_create_ind := ln_create_ind + 1;
--
          g_sales_tab(ln_create_ind).record_id               :=  g_sales_tab_work(i2).record_id;               -- ���R�[�hID
          g_sales_tab(ln_create_ind).vendor_zip              :=  g_sales_tab_work(i2).vendor_zip;              -- �X�֔ԍ��i���t��j
          g_sales_tab(ln_create_ind).vendor_address1         :=  g_sales_tab_work(i2).vendor_address1;         -- �Z���P�i���t��j
          g_sales_tab(ln_create_ind).vendor_address2         :=  g_sales_tab_work(i2).vendor_address2;         -- �Z���Q�i���t��j
          g_sales_tab(ln_create_ind).vendor_name             :=  g_sales_tab_work(i2).vendor_name;             -- �d���於�́i���t��j
          g_sales_tab(ln_create_ind).customer_code           :=  g_sales_tab_work(i2).customer_code;           -- �ڋq�R�[�h
          g_sales_tab(ln_create_ind).vendor_code             :=  g_sales_tab_work(i2).vendor_code;             -- �d����R�[�h
          g_sales_tab(ln_create_ind).sales_base_city         :=  g_sales_tab_work(i2).sales_base_city;         -- �s���{���s��i���㋒�_
          g_sales_tab(ln_create_ind).sales_base_address1     :=  g_sales_tab_work(i2).sales_base_address1;     -- �Z���P�i���㋒�_�j
          g_sales_tab(ln_create_ind).sales_base_address2     :=  g_sales_tab_work(i2).sales_base_address2;     -- �Z���Q�i���㋒�_�j
          g_sales_tab(ln_create_ind).sales_base_name         :=  g_sales_tab_work(i2).sales_base_name;         -- ���㋒�_����
          g_sales_tab(ln_create_ind).sales_base_tel          :=  g_sales_tab_work(i2).sales_base_tel;          -- �d�b�ԍ��i���㋒�_�j
          g_sales_tab(ln_create_ind).salesrep_name           :=  lv_salesrep_name;                             -- �ڋq�S���Җ���
          g_sales_tab(ln_create_ind).date_from               :=  g_sales_tab_work(i2).date_from;               -- �Ώۊ��ԊJ�n��
          g_sales_tab(ln_create_ind).date_to                 :=  g_sales_tab_work(i2).date_to;                 -- �Ώۊ��ԏI����
          g_sales_tab(ln_create_ind).install_location        :=  g_sales_tab_work(i2).install_location;        -- �ݒu��ꏊ
          g_sales_tab(ln_create_ind).item_name               :=  g_sales_tab_work(i2).item_name;               -- ���i��
          g_sales_tab(ln_create_ind).sales_price             :=  g_sales_tab_work(i2).sales_price;             -- ����
          g_sales_tab(ln_create_ind).sales_qty               :=  g_sales_tab_work(i2).sales_qty;               -- �̔��{��
          g_sales_tab(ln_create_ind).sales_amount            :=  g_sales_tab_work(i2).sales_amount;            -- �̔����z
          g_sales_tab(ln_create_ind).created_by              :=  g_sales_tab_work(i2).created_by;              -- WHO�J����
          g_sales_tab(ln_create_ind).creation_date           :=  g_sales_tab_work(i2).creation_date;           -- WHO�J����
          g_sales_tab(ln_create_ind).last_updated_by         :=  g_sales_tab_work(i2).last_updated_by;         -- WHO�J����
          g_sales_tab(ln_create_ind).last_update_date        :=  g_sales_tab_work(i2).last_update_date;        -- WHO�J����
          g_sales_tab(ln_create_ind).last_update_login       :=  g_sales_tab_work(i2).last_update_login;       -- WHO�J����
          g_sales_tab(ln_create_ind).request_id              :=  g_sales_tab_work(i2).request_id;              -- WHO�J����
          g_sales_tab(ln_create_ind).program_application_id  :=  g_sales_tab_work(i2).program_application_id;  -- WHO�J����
          g_sales_tab(ln_create_ind).program_id              :=  g_sales_tab_work(i2).program_id;              -- WHO�J����
          g_sales_tab(ln_create_ind).program_update_date     :=  g_sales_tab_work(i2).program_update_date;     -- WHO�J����
--
        END LOOP ins_set_loop;
--
        -- �u���[�N�p�ϐ��ɒl��ݒ�
        lt_cust_code := l_vd_sales_tab(i).customer_code;
        -- �ڋq�擾�p�Ƀp�[�e�BID�ێ�
        lt_party_id  := l_vd_sales_tab(i).party_id;
        -- �ő�[�i���擾�̕ϐ���������
        lt_dlv_date  := NULL;
        -- �ꎞ�p�z�����������
        ln_work_ind  := 0;
        -- �ꎞ�z��̍폜
        g_sales_tab_work.DELETE;
--
      END IF;
--
    END LOOP sales_loop;
--
    --���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�����I�����������O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_date_time )
    );
    --���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
    -- *** �f�[�^���o��O ***
    WHEN select_expt THEN
      -- ���b�Z�[�W�擾
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_select_err      -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table_name
                      ,iv_token_value1 => lv_msg_tnk             -- �e�[�u����
                      ,iv_token_name2  => cv_tkn_key_data
                      ,iv_token_value2 => lv_sqlerrm             -- SQLERRM
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      -- �J�[�\���N���[�Y
      IF ( get_vd_sales_cur%ISOPEN ) THEN
        CLOSE get_vd_sales_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sales_exp_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_rep_work_data
   * Description      : ���[���[�N�e�[�u���쐬����(A-5)
   ***********************************************************************************/
  PROCEDURE ins_rep_work_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_rep_work_data'; -- �v���O������
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
    lv_sqlerrm  VARCHAR2(5000);      -- SQLERRM�i�[�p
    lv_msg_tnk  VARCHAR2(100);       -- ���b�Z�[�W�g�[�N���p
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
    BEGIN
      --=================================================
      -- ���̋@�̔��񍐏����[���[�N�e�[�u���f�[�^�}������
      --=================================================
      FORALL i IN 1..g_sales_tab.COUNT
        INSERT INTO xxcos_rep_vd_sales_list
        VALUES g_sales_tab(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm := SUBSTRB( SQLERRM, 1, 5000 ); -- SQLERRM�i�[
        RAISE insert_expt;
    END;
--
    -- ���������J�E���g
    gn_normal_cnt := g_sales_tab.COUNT;
    -- �z����폜
    g_sales_tab.DELETE;
--
    -- SVF���s�ׁ̈A������COMMIT
    COMMIT;
--
  EXCEPTION
    -- *** �f�[�^�o�^��O ***
    WHEN insert_expt THEN
      -- �e�[�u�����擾
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_rep_table   -- ���̋@�̔��񍐏����[���[�N�e�[�u��
                    );
      -- ���b�Z�[�W�擾
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_insert_err      -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table_name
                      ,iv_token_value1 => lv_msg_tnk             -- �e�[�u����
                      ,iv_token_name2  => cv_tkn_key_data
                      ,iv_token_value2 => lv_sqlerrm             -- SQLERRM
                    );
      ov_errmsg  := lv_errmsg;
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
  END ins_rep_work_data;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF�N������(A-6)
   ***********************************************************************************/
  PROCEDURE execute_svf(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- �v���O������
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
    lv_nodata_msg    VARCHAR2(5000); -- 0�����b�Z�[�W
    lv_file_name     VARCHAR2(5000); -- �t�@�C����
    lv_msg_tnk       VARCHAR2(100);  -- ���b�Z�[�W�g�[�N���p
    lv_err_msg       VARCHAR2(5000); -- ���b�Z�[�W�p
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
    -- ����0���p���b�Z�[�W�擾
    lv_nodata_msg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_nodata_err --���b�Z�[�W�R�[�h
                      );
    --�o�̓t�@�C�����ҏW
    lv_file_name  := cv_pkg_name                                    || -- �v���O����ID(�p�b�P�[�W��)
                     TO_CHAR( cd_creation_date, cv_date_yyyymmdd2 ) || -- ���t
                     TO_CHAR( cn_request_id )                       || -- �v��ID
                     cv_extension_pdf                                  -- �g���q(PDF)
                     ;
    --==================================
    -- SVF�N��
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_retcode         => lv_retcode                -- ���^�[���R�[�h
      ,ov_errbuf          => lv_errbuf                 -- �G���[���b�Z�[�W
      ,ov_errmsg          => lv_errmsg                 -- ���[�U�[�E�G���[���b�Z�[�W
      ,iv_conc_name       => cv_pkg_name               -- �R���J�����g��
      ,iv_file_name       => lv_file_name              -- �o�̓t�@�C����
      ,iv_file_id         => cv_pkg_name               -- ���[ID
      ,iv_output_mode     => cv_output_mode_pdf        -- �o�͋敪
      ,iv_frm_file        => cv_frm_name               -- �t�H�[���l���t�@�C����
      ,iv_vrq_file        => cv_vrq_name               -- �N�G���[�l���t�@�C����
      ,iv_org_id          => NULL                      -- ORG_ID
      ,iv_user_name       => NULL                      -- ���O�C���E���[�U��
      ,iv_resp_name       => NULL                      -- ���O�C���E���[�U�̐E�Ӗ�
      ,iv_doc_name        => NULL                      -- ������
      ,iv_printer_name    => NULL                      -- �v�����^��
      ,iv_request_id      => TO_CHAR( cn_request_id )  -- �v��ID
      ,iv_nodata_msg      => lv_nodata_msg             -- �f�[�^�Ȃ����b�Z�[�W
      ,iv_svf_param1      => NULL                      -- svf�σp�����[�^1
      ,iv_svf_param2      => NULL                      -- svf�σp�����[�^2
      ,iv_svf_param3      => NULL                      -- svf�σp�����[�^3
      ,iv_svf_param4      => NULL                      -- svf�σp�����[�^4
      ,iv_svf_param5      => NULL                      -- svf�σp�����[�^5
      ,iv_svf_param6      => NULL                      -- svf�σp�����[�^6
      ,iv_svf_param7      => NULL                      -- svf�σp�����[�^7
      ,iv_svf_param8      => NULL                      -- svf�σp�����[�^8
      ,iv_svf_param9      => NULL                      -- svf�σp�����[�^9
      ,iv_svf_param10     => NULL                      -- svf�σp�����[�^10
      ,iv_svf_param11     => NULL                      -- svf�σp�����[�^11
      ,iv_svf_param12     => NULL                      -- svf�σp�����[�^12
      ,iv_svf_param13     => NULL                      -- svf�σp�����[�^13
      ,iv_svf_param14     => NULL                      -- svf�σp�����[�^14
      ,iv_svf_param15     => NULL                      -- svf�σp�����[�^15
    );
    --SVF�������ʊm�F
    IF  ( lv_retcode  <> cv_status_normal ) THEN
      -- �g�[�N���擾
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_svf_api  -- SVF�N��API
                    );
      -- ���b�Z�[�W�擾
      lv_err_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_api_err      -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_api_name
                      ,iv_token_value1 => lv_msg_tnk          -- �v���t�@�C����
                    );
      -- ���O�o�͗p���b�Z�[�W(SVF�̃G���[���b�Z�[�W)
      lv_errbuf := SUBSTRB( lv_errmsg || cv_msg_part || lv_errbuf, 1, 5000 );
      -- ���[�U�p���b�Z�[�W
      lv_errmsg := lv_err_msg;
      RAISE global_api_expt;
    END IF;
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
  END execute_svf;
--
--
  /**********************************************************************************
   * Procedure Name   : del_rep_work_data
   * Description      : ���[���[�N�e�[�u���폜����(A-7)
   ***********************************************************************************/
  PROCEDURE del_rep_work_data(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_rep_work_data'; -- �v���O������
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
    lv_sqlerrm  VARCHAR2(5000); -- SQLERRM�i�[�p
    lv_msg_tnk  VARCHAR2(100);  -- ���b�Z�[�W�g�[�N���p
    lv_msg_code VARCHAR2(16);   -- ���b�Z�[�W�؂�ւ��p
    lv_tkn_code VARCHAR2(10);   -- �g�[�N���؂�ւ��p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���̋@�̔��񍐏����[���[�N�e�[�u���폜�p�J�[�\��
    CURSOR del_rep_table_cur
    IS
      SELECT 1
      FROM   xxcos_rep_vd_sales_list xrvsl
      WHERE  xrvsl.request_id = cn_request_id
      FOR UPDATE NOWAIT
      ;
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
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    BEGIN
     --=========================================
     -- ���̋@�̔��񍐏����[���[�N�e�[�u�����b�N
     --=========================================
      -- �I�[�v��
      OPEN del_rep_table_cur;
      -- �N���[�Y
      CLOSE del_rep_table_cur;
    EXCEPTION
      WHEN lock_expt THEN
        lv_sqlerrm   := SUBSTRB( SQLERRM, 1, 5000 );  -- SQLERRM�i�[
        lv_msg_code  := cv_msg_lock_err;              -- ���b�Z�[�W�R�[�h(���b�N�G���[)
        lv_tkn_code  := cv_tkn_table;                 -- �g�[�N��(TABLE)
        RAISE delete_proc_expt;
    END;
--
   BEGIN
     --=========================================
     -- ���̋@�̔��񍐏����[���[�N�e�[�u���폜
     --=========================================
     DELETE
     FROM   xxcos_rep_vd_sales_list xrvsl
     WHERE  xrvsl.request_id = cn_request_id
     ;
   EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm   := SUBSTRB( SQLERRM, 1, 5000 );  -- SQLERRM�i�[
        lv_msg_code  := cv_msg_delete_err;            -- ���b�Z�[�W�R�[�h(�폜�G���[)
        lv_tkn_code  := cv_tkn_table_name;            -- �g�[�N��(TABLE_NAME)
        RAISE delete_proc_expt;
   END;
--
   --SVF���G���[�ƂȂ����Ƃ��AROLLBACK�����̂ł����ŃR�~�b�g
   COMMIT;
--
  EXCEPTION
    --*** �폜�����ėp��O ***
    WHEN delete_proc_expt THEN
      -- �e�[�u�����擾
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tkn_rep_table   -- ���̋@�̔��񍐏����[���[�N�e�[�u��
                    );
      -- ���b�Z�[�W�擾
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => lv_msg_code            -- ���b�Z�[�W�R�[�h(���b�Nor�폜)
                      ,iv_token_name1  => lv_tkn_code            -- �g�[�N��
                      ,iv_token_value1 => lv_msg_tnk             -- �e�[�u����
                      ,iv_token_name2  => cv_tkn_key_data
                      ,iv_token_value2 => lv_sqlerrm             -- SQLERRM
                    );
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END del_rep_work_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     iv_manager_flag     IN  VARCHAR2  --  1.�Ǘ��҃t���O(Y:�Ǘ��� N:���_ A:�����Z���^�[)
    ,iv_execute_type     IN  VARCHAR2  --  2.���s�敪(1:�ڋq�w�� 2:�d����w�� 3:�⍇�����_�w��)
    ,iv_target_date      IN  VARCHAR2  --  3.�Ώ۔N��
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD START
    ,iv_dlv_date_from    IN  VARCHAR2  --    �[�i��FROM
    ,iv_dlv_date_to      IN  VARCHAR2  --    �[�i��TO
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD END
    ,iv_sales_base_code  IN  VARCHAR2  --  4.���㋒�_�R�[�h(�ڋq�w�莞�E�⍇�����_�w�莞)
    ,iv_customer_code_01 IN  VARCHAR2  --  5.�ڋq�R�[�h1(�ڋq�w�莞�̂�)
    ,iv_customer_code_02 IN  VARCHAR2  --  6.�ڋq�R�[�h2(�ڋq�w�莞�̂�)
    ,iv_customer_code_03 IN  VARCHAR2  --  7.�ڋq�R�[�h3(�ڋq�w�莞�̂�)
    ,iv_customer_code_04 IN  VARCHAR2  --  8.�ڋq�R�[�h4(�ڋq�w�莞�̂�)
    ,iv_customer_code_05 IN  VARCHAR2  --  9.�ڋq�R�[�h5(�ڋq�w�莞�̂�)
    ,iv_customer_code_06 IN  VARCHAR2  -- 10.�ڋq�R�[�h6(�ڋq�w�莞�̂�)
    ,iv_customer_code_07 IN  VARCHAR2  -- 11.�ڋq�R�[�h7(�ڋq�w�莞�̂�)
    ,iv_customer_code_08 IN  VARCHAR2  -- 12.�ڋq�R�[�h8(�ڋq�w�莞�̂�)
    ,iv_customer_code_09 IN  VARCHAR2  -- 13.�ڋq�R�[�h9(�ڋq�w�莞�̂�)
    ,iv_customer_code_10 IN  VARCHAR2  -- 14.�ڋq�R�[�h10(�ڋq�w�莞�̂�)
    ,iv_vendor_code_01   IN  VARCHAR2  -- 15.�d����R�[�h1(�d����w�莞�̂�)
    ,iv_vendor_code_02   IN  VARCHAR2  -- 16.�d����R�[�h2(�d����w�莞�̂�)
    ,iv_vendor_code_03   IN  VARCHAR2  -- 17.�d����R�[�h3(�d����w�莞�̂�)
    ,ov_errbuf           OUT VARCHAR2  --    �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode          OUT VARCHAR2  --    ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg           OUT VARCHAR2  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W(SVF�G���[���ޔ�p)
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h(SVF�G���[���ޔ�p)
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W(SVF�G���[���ޔ�p)
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
    -- ���[�J���E�J�[�\��
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -------------------------------------------------
    -- ���̓p�����[�^���O���[�o�����R�[�h�E�z��ɕێ�
    -------------------------------------------------
    g_input_rec.manager_flag     := iv_manager_flag;     --  1.�Ǘ��҃t���O(Y:�Ǘ��� N:���_ A:�����Z���^�[)
    g_input_rec.execute_type     := iv_execute_type;     --  2.���s�敪(1:�ڋq�w�� 2:�d����w�� 3:�⍇�����_�w��)
    g_input_rec.target_date      := iv_target_date;      --  3.�Ώ۔N��
    g_input_rec.sales_base_code  := iv_sales_base_code;  --  4.���㋒�_�R�[�h(�ڋq�w�莞�̂�)
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD START
    g_input_rec.dlv_date_from    := fnd_date.string_to_date( iv_dlv_date_from, cv_date_yyyymmdd );    -- �[�i��FROM
    g_input_rec.dlv_date_to      := fnd_date.string_to_date( iv_dlv_date_to  , cv_date_yyyymmdd );    --    �[�i��TO
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD END
--
    --���s�敪��1(�ڋq�w��Ŏ��s�j�̏ꍇ
    IF ( g_input_rec.execute_type = cv_1 ) THEN
      g_cust_tab(1)  := iv_customer_code_01; --  4.�ڋq�R�[�h1(�ڋq�w�莞�̂�)
      g_cust_tab(2)  := iv_customer_code_02; --  5.�ڋq�R�[�h2(�ڋq�w�莞�̂�)
      g_cust_tab(3)  := iv_customer_code_03; --  6.�ڋq�R�[�h3(�ڋq�w�莞�̂�)
      g_cust_tab(4)  := iv_customer_code_04; --  7.�ڋq�R�[�h4(�ڋq�w�莞�̂�)
      g_cust_tab(5)  := iv_customer_code_05; --  8.�ڋq�R�[�h5(�ڋq�w�莞�̂�)
      g_cust_tab(6)  := iv_customer_code_06; --  9.�ڋq�R�[�h6(�ڋq�w�莞�̂�)
      g_cust_tab(7)  := iv_customer_code_07; -- 10.�ڋq�R�[�h7(�ڋq�w�莞�̂�)
      g_cust_tab(8)  := iv_customer_code_08; -- 11.�ڋq�R�[�h8(�ڋq�w�莞�̂�)
      g_cust_tab(9)  := iv_customer_code_09; -- 12.�ڋq�R�[�h9(�ڋq�w�莞�̂�)
      g_cust_tab(10) := iv_customer_code_10; -- 13.�ڋq�R�[�h10(�ڋq�w�莞�̂�)
    --���s�敪��2(�d����w��Ŏ��s�j�̏ꍇ
    ELSIF ( g_input_rec.execute_type = cv_2 ) THEN
      g_vend_tab(1)  := iv_vendor_code_01;   -- 14.�d����R�[�h1(�d����w�莞�̂�)
      g_vend_tab(2)  := iv_vendor_code_02;   -- 15.�d����R�[�h2(�d����w�莞�̂�)
      g_vend_tab(3)  := iv_vendor_code_03;   -- 16.�d����R�[�h3(�d����w�莞�̂�)
    END IF;
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
      lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �֘A�f�[�^�擾����(A-2)
    -- ===============================
    get_relation_data(
      lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD START
    ELSIF (lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD END
    END IF;
--
    -- ===============================
    -- �ڋq���擾����(A-3)
    -- ===============================
    get_cust_info_data(
      lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �̔����擾����(A-4)
    -- ===============================
    get_sales_exp_data(
      lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���[�p���[�N�e�[�u���쐬(A-5)
    -- ===============================
    ins_rep_work_data(
      lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- SVF�N������(A-6)
    -- ===============================
    execute_svf(
      lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      --���[�N�폜�ׁ̈A�����ŗ�O�Ƃ������ʂ�ޔ�
      lv_errbuf_svf  := lv_errbuf;
      lv_retcode_svf := lv_retcode;
      lv_errmsg_svf  := lv_errmsg;
    END IF;
--
    -- ===============================
    -- ���[���[�N�e�[�u���폜����(A-7)
    -- ===============================
    del_rep_work_data(
      lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- SVF���s���ʊm�F
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf     := lv_errbuf_svf;
      lv_errmsg_svf := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
--
    --����0�����X�e�[�^�X���䏈��
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
    --�o�͑ΏۊO�f�[�^�����݂���ꍇ�̃X�e�[�^�X���䏈��
    ELSIF ( gn_warn = cv_status_warn ) THEN
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
     errbuf              OUT VARCHAR2  --    �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode             OUT VARCHAR2  --    ���^�[���E�R�[�h    --# �Œ� #
    ,iv_manager_flag     IN  VARCHAR2  --  1.�Ǘ��҃t���O(Y:�Ǘ��� N:���_ A:�����Z���^�[)
    ,iv_execute_type     IN  VARCHAR2  --  2.���s�敪(1:�ڋq�w�� 2:�d����w�� 3:�⍇�����_�w��)
    ,iv_target_date      IN  VARCHAR2  --  3.�Ώ۔N��
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD START
    ,iv_dlv_date_from    IN  VARCHAR2  --    �[�i��FROM
    ,iv_dlv_date_to      IN  VARCHAR2  --    �[�i��TO
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD END
    ,iv_sales_base_code  IN  VARCHAR2  --  4.���㋒�_�R�[�h(�ڋq�w�莞�E�⍇�����_�w�莞)
    ,iv_customer_code_01 IN  VARCHAR2  --  5.�ڋq�R�[�h1(�ڋq�w�莞�̂�)
    ,iv_customer_code_02 IN  VARCHAR2  --  6.�ڋq�R�[�h2(�ڋq�w�莞�̂�)
    ,iv_customer_code_03 IN  VARCHAR2  --  7.�ڋq�R�[�h3(�ڋq�w�莞�̂�)
    ,iv_customer_code_04 IN  VARCHAR2  --  8.�ڋq�R�[�h4(�ڋq�w�莞�̂�)
    ,iv_customer_code_05 IN  VARCHAR2  --  9.�ڋq�R�[�h5(�ڋq�w�莞�̂�)
    ,iv_customer_code_06 IN  VARCHAR2  -- 10.�ڋq�R�[�h6(�ڋq�w�莞�̂�)
    ,iv_customer_code_07 IN  VARCHAR2  -- 11.�ڋq�R�[�h7(�ڋq�w�莞�̂�)
    ,iv_customer_code_08 IN  VARCHAR2  -- 12.�ڋq�R�[�h8(�ڋq�w�莞�̂�)
    ,iv_customer_code_09 IN  VARCHAR2  -- 13.�ڋq�R�[�h9(�ڋq�w�莞�̂�)
    ,iv_customer_code_10 IN  VARCHAR2  -- 14.�ڋq�R�[�h10(�ڋq�w�莞�̂�)
    ,iv_vendor_code_01   IN  VARCHAR2  -- 15.�d����R�[�h1(�d����w�莞�̂�)
    ,iv_vendor_code_02   IN  VARCHAR2  -- 16.�d����R�[�h2(�d����w�莞�̂�)
    ,iv_vendor_code_03   IN  VARCHAR2  -- 17.�d����R�[�h3(�d����w�莞�̂�)
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_log  CONSTANT VARCHAR2(3)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O
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
       iv_which   => cv_log_header_log
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
       iv_manager_flag     --�Ǘ��҃t���O
      ,iv_execute_type     --���s�敪
      ,iv_target_date      --�Ώ۔N��
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD START
      ,iv_dlv_date_from    --�[�i��FROM
      ,iv_dlv_date_to      --�[�i��TO
-- 2013/11/12 Ver.1.2 T.Ishiwata E_�{�ғ�_11134 ADD END
      ,iv_sales_base_code  --���㋒�_�R�[�h
      ,iv_customer_code_01 --�ڋq�R�[�h1
      ,iv_customer_code_02 --�ڋq�R�[�h2
      ,iv_customer_code_03 --�ڋq�R�[�h3
      ,iv_customer_code_04 --�ڋq�R�[�h4
      ,iv_customer_code_05 --�ڋq�R�[�h5
      ,iv_customer_code_06 --�ڋq�R�[�h6
      ,iv_customer_code_07 --�ڋq�R�[�h7
      ,iv_customer_code_08 --�ڋq�R�[�h8
      ,iv_customer_code_09 --�ڋq�R�[�h9
      ,iv_customer_code_10 --�ڋq�R�[�h10
      ,iv_vendor_code_01   --�d����R�[�h1
      ,iv_vendor_code_02   --�d����R�[�h2
      ,iv_vendor_code_03   --�d����R�[�h3
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
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
                     iv_application  => cv_appl_short_name
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
       which  => FND_FILE.LOG
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
END XXCOS002A06R;
/
