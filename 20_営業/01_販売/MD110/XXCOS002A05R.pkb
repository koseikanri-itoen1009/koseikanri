CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A05R (body)
 * Description      : �[�i���`�F�b�N���X�g
 * MD.050           : �[�i���`�F�b�N���X�g MD050_COS_002_A05
 * Version          : 1.21
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-0)
 *  sales_per_data_entry   �̔����уf�[�^���o(A-3)�A�[�i�f�[�^�o�^�i�̔����сj(A-4)
 *  money_data_entry       �����f�[�^���o(A-5)�A�[�i�f�[�^�o�^�i�����f�[�^�j(A-6)
 *  execute_svf            SVF�N��(A-7)
 *  delete_rpt_wrk_data    ���[���[�N�e�[�u���f�[�^�폜(A-8)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   S.Miyakoshi      �V�K�쐬
 *  2009/02/17    1.1   S.Miyakoshi      get_msg�̃p�b�P�[�W���C��
 *  2009/02/26    1.2   S.Miyakoshi      �]�ƈ��̗����Ǘ��Ή�(xxcos_rs_info_v)
 *  2009/02/26    1.3   S.Miyakoshi      ���[�R���J�����g�N����̃��[�N�e�[�u���폜�����̃R�����g��������
 *  2009/02/27    1.4   S.Miyakoshi      [COS_150]�̔����уf�[�^���o�����C��
 *  2009/03/04    1.5   N.Maeda          ���[�o�͎��̔[�i���}�b�s���O���ڂ̕ύX
 *                                       �E�C���O
 *                                          �˔̔�����.�[�i�����g�p
 *                                       �E�C����
 *                                          �˔̔�����.���������g�p
 *                                       ���P���A�����̃}�b�s���O���ڂ̕ύX
 *                                       �E�C���O
 *                                          �ˉ��P��:�艿�P��
 *                                          �˔���:�[�i�P���~����
 *                                       �E�C����
 *                                          �ˉ��P��:�[�i�P���i����P)
 *                                          �˔���:�艿�P��
 *  2009/05/01    1.6   N.Maeda          [T1_0885]���o�Ώۂɢ��l�ڋq���ǉ�
 *  2009/05/18    1.7   Kin              ��Q[T1_0434],[T1_0435],[T1_0930]�Ή�
 *  2009/05/27    1.8   Kin              ��Q[T1_0433]�Ή�
 *  2009/06/05    1.9   T.Tominaga       ��Q[T1_1148]�Ή�
 *                                       ���C���J�[�\���̕ύX
 *                                       "�m�F"�̔�������ύX
 *                                         �E�i�艿(�V)�j�艿�K�p�J�n >= �[�i���˒艿�K�p�J�n <= �[�i��
 *                                         �E�i���艿�j�艿�K�p�J�n < �[�i��   �˒艿�K�p�J�n > �[�i��
 *                                       ��Q[T1_1361]�Ή�
 *                                       delete_rpt_wrk_data�R�[�������̃R�����g�폜
 *  2009/06/10    1.10  T.Tominaga       ��Q[T1_1404]�Ή�
 *                                       ���C���J�[�\���̕ύX�i�[�������敪�̎擾��ύX�j
 *  2009/06/11    1.11  T.Tominaga       ��Q[T1_1420]�Ή�
 *                                       �ŏ����ɂ����āA����ŋ敪��"2","3"�ȊO�̏ꍇ�̏�����"3"�ȊO�ɕύX
 *  2009/06/19    1.12  K.Kiriu          ��Q[T1_1437]�Ή�
 *                                       �f�[�^�p�[�W�̕s����C��
 *  2009/07/13    1.13  T.Tominaga       ��Q[0000651]�Ή�
 *                                       �ŏ������s���Ώۂ�ύX�iVD�ȊO��VD�j�A�m�F���ڂ̏�����VD,VD�ȊO�̗����ōs���悤�ɕύX
 *  2009/08/24    1.14  M.Sano           ��Q[0001162]�Ή�
 *                                       �]�ƈ��}�X�^�̒��o�����̒ǉ�
 *  2009/09/01    1.15  M.Sano           ��Q[0000900]�Ή�
 *                                       MainSQL,INSERT���Ƀq���g��̒ǉ��A���������̍œK��
 *  2009/09/30    1.16  S.Miyakoshi      ��Q[0001378]���[�e�[�u���̌����ӂ�Ή�
 *  2009/11/27    1.17  K.Atsushiba      [E_�{�ғ�_00128]�c�ƈ����w�莞�ɑ��c�ƈ��̃f�[�^���o�͂���Ȃ��悤�ɕύX
 *  2009/12/12    1.18  N.Maeda          [E_�{�ғ�_00140]�\�[�g���C���ɔ����擾���ځA�ݒ荀�ڂ̒ǉ�
 *  2009/12/17    1.19  K.Atsushiba      [E_�{�ғ�_00521]�����f�[�^���[�i���т̓������ɕ\������Ȃ��Ή�
 *                                       [E_�{�ғ�_00522]����l�������\������Ȃ��Ή�
 *                                       [E_�{�ғ�_00532]�[�i���уf�[�^�̏d���\���Ή�
 *  2010/01/07    1.20  N.Maeda          [E_�{�ғ�_00849] �l���̂݃f�[�^�Ή�
 *  2011/03/07    1.21  S.Ochiai         [E_�{�ғ�_06590]�I�[�_�[���ǉ��A�g�Ή�
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
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
  data_get_err EXCEPTION;
-- ******* 2010/01/07 1.20 N.Maeda ADD  END  ****** --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOS002A05R';       -- �p�b�P�[�W��
--
  -- ���[�֘A
  cv_conc_name                  CONSTANT VARCHAR2(100) := 'XXCOS002A05R';       -- �R���J�����g��
  cv_file_id                    CONSTANT VARCHAR2(100) := 'XXCOS002A05R';       -- ���[�h�c
  cv_extension_pdf              CONSTANT VARCHAR2(100) := '.pdf';               -- �g���q�i�o�c�e�j
  cv_frm_file                   CONSTANT VARCHAR2(100) := 'XXCOS002A05S.xml';   -- �t�H�[���l���t�@�C����
  cv_vrq_file                   CONSTANT VARCHAR2(100) := 'XXCOS002A05S.vrq';   -- �N�G���[�l���t�@�C����
  cv_output_mode_pdf            CONSTANT VARCHAR2(1)   := '1';                  -- �o�͋敪�i�o�c�e�j
--
  -- �A�v���P�[�V�����Z�k��
  cv_application                CONSTANT VARCHAR2(5)   := 'XXCOS';
--
  -- ���b�Z�[�W
  cv_msg_lock_err               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';   -- ���b�N�G���[
  cv_msg_get_profile_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';   -- �v���t�@�C���擾�G���[
  cv_msg_in_param_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00006';   -- �K�{���̓p�����[�^���ݒ�G���[
  cv_msg_insert_data_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';   -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_delete_data_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00012';   -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_get_err                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';   -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_call_api_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00017';   -- API�ďo�G���[���b�Z�[�W
  cv_msg_nodata_err             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00018';   -- ����0���p���b�Z�[�W
  cv_msg_svf_api                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00041';   -- SVF�N��API
  cv_msg_mst_qck                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00066';   -- �N�C�b�N�R�[�h�}�X�^
  cv_msg_request_id             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00088';   -- �v��ID
  cv_msg_form_error             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10601';   -- �[�i���̌^�Ⴂ���b�Z�[�W
  cv_msg_in_parameter           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10602';   -- ���̓p�����[�^
  cv_msg_check_list_work_table  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10603';   -- �[�i���`�F�b�N���X�g���[�e�[�u��
  cv_msg_dlv_date               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10604';   -- �[�i��
  cv_msg_base                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10605';   -- ���_
  cv_msg_type                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10606';   -- �^�C�v
  cv_msg_check_mark             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10607';   -- �`�F�b�N�}�[�N
  cv_msg_dlv_by_code            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10608';   -- �c�ƈ�
  cv_msg_hht_invoice_no         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10609';   -- HHT�`�[No
  cv_msg_sale_header_table      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10610';   -- �̔����уw�b�_�e�[�u��
-- 2009/12/17 Ver.1.19 Add Start
  cv_msg_payment_update_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10611';   -- �����f�[�^�X�V
-- 2009/12/17 Ver.1.19 Add End
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
  cv_msg_name_lookup            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00075';
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
--
  -- �g�[�N��
  cv_tkn_in_param               CONSTANT VARCHAR2(100) := 'IN_PARAM';           -- ���̓p�����[�^
  cv_tkn_table                  CONSTANT VARCHAR2(100) := 'TABLE_NAME';         -- �e�[�u����
  cv_tkn_key_data               CONSTANT VARCHAR2(100) := 'KEY_DATA';           -- �L�[���
  cv_tkn_profile                CONSTANT VARCHAR2(100) := 'PROFILE';            -- �v���t�@�C����
  cv_tkn_api_name               CONSTANT VARCHAR2(100) := 'API_NAME';           -- API����
  cv_tkn_para_delivery_date     CONSTANT VARCHAR2(100) := 'PARAM1';             -- �[�i��
  cv_tkn_para_delivery_base     CONSTANT VARCHAR2(100) := 'PARAM2';             -- ���_
  cv_tkn_para_dlv_by_code       CONSTANT VARCHAR2(100) := 'PARAM3';             -- �c�ƈ�
  cv_tkn_para_hht_invoice       CONSTANT VARCHAR2(100) := 'PARAM4';             -- HHT�`�[No
-- 2009/12/17 Ver.1.19 Add Start
  cv_tkn_hht_invoice_no         CONSTANT VARCHAR2(100) := 'HHT_INVOICE_NO';     -- �[�i�`�[�ԍ�
  cv_tkn_customer_number        CONSTANT VARCHAR2(100) := 'CUSTOMER_NUMBER';    -- �ڋq
  cv_tkn_payment_date           CONSTANT VARCHAR2(100) := 'PAYMENT_DATE';       -- ������
-- 2009/12/17 Ver.1.19 Add End

--
  -- �N�C�b�N�R�[�h�i�쐬���敪�j
  ct_qck_org_cls_type           CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_MK_ORG_CLS_MST_002_A05';
--
  -- �N�C�b�N�R�[�h�i�l���i�ځj
  ct_qck_discount_item_type     CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_DISCOUNT_ITEM_CODE';
--
  -- �N�C�b�N�R�[�h�i���͋敪�j
  ct_qck_input_class            CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_INPUT_CLASS';
--
  -- �N�C�b�N�R�[�h�i�J�[�h���敪�j
  ct_qck_card_sale_class        CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_CARD_SALE_CLASS';
--
  -- �N�C�b�N�R�[�h�i����敪�j
  ct_qck_sale_class             CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_SALE_CLASS';
--
  -- �N�C�b�N�R�[�h�iHHT����ŋ敪�j
  ct_qck_tax_class              CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_CONSUMPTION_TAX_CLASS';
--
  -- �N�C�b�N�R�[�h�i�����敪�j
  ct_qck_money_class            CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_RECEIPT_MONEY_CLASS';
--
  -- �N�C�b�N�R�[�h�iH/C�敪�j
  ct_qck_hc_class               CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_HC_CLASS';
--
  -- �N�C�b�N�R�[�h�i�Ƒԏ����ޓ���}�X�^�j
  ct_qck_gyotai_sho_mst         CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_GYOTAI_SHO_MST_002_A03';
  ct_qck_gyotai_sho_mst1        CONSTANT fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_GYOTAI_SHO_MST_002_A05';
--
  -- Yes/No
  cv_yes                        CONSTANT VARCHAR2(1)   := 'Y';
  cv_no                         CONSTANT VARCHAR2(1)   := 'N';
--
  -- NULL���萔
  cv_x                          CONSTANT VARCHAR2(1)   := 'X';
--
  -- �f�t�H���g�l
  cn_zero                       CONSTANT NUMBER        := 0;
  cn_one                        CONSTANT NUMBER        := 1;
  cn_two                        CONSTANT NUMBER        := 2;
  cn_thr                        CONSTANT NUMBER        := 3;
--
  -- �J�[�h����敪
  ct_cash                       CONSTANT xxcos_sales_exp_headers.card_sale_class%TYPE := '0';   -- ����
  ct_card                       CONSTANT xxcos_sales_exp_headers.card_sale_class%TYPE := '1';   -- �J�[�h
--
  -- �p�����[�^���t�w�菑��
  cv_fmt_date_default           CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_date                   CONSTANT VARCHAR2(8)   := 'YYYYMMDD';
--
  -- �ڋq�敪
  ct_cust_class_base            CONSTANT hz_cust_accounts.customer_class_code%TYPE    := '1';   -- ���_
  ct_cust_class_customer        CONSTANT hz_cust_accounts.customer_class_code%TYPE    := '10';  -- �ڋq
-- ******************** 2009/05/01 Var.1.6 N.Maeda ADD START  ******************************************
  ct_cust_class_customer_u      CONSTANT hz_cust_accounts.customer_class_code%TYPE    := '12';  -- ��l�ڋq
-- ******************** 2009/05/01 Var.1.6 N.Maeda ADD  END   ******************************************
-- ******************** 2009/05/27 Var.1.7 K.KIN ADD START  ******************************************
  cv_round_rule_up         CONSTANT  VARCHAR2(10)  := 'UP';                             -- �؂�グ
  cv_round_rule_down       CONSTANT  VARCHAR2(10)  := 'DOWN';                           -- �؂艺��
  cv_round_rule_nearest    CONSTANT  VARCHAR2(10)  := 'NEAREST';                        -- �l�̌ܓ�
-- ******************** 2009/05/27 Var.1.7 K.KIN ADD START  ******************************************
-- ******************** 2009/06/05 Var.1.9 T.Tominaga ADD START  ******************************************
  cv_obsolete_class_one         CONSTANT VARCHAR2(1)   := '1';
-- ******************** 2009/06/05 Var.1.9 T.Tominaga ADD END    ******************************************
-- 2009/09/01 Ver.1.15 M.Sano Add Start
  -- ����R�[�h
  ct_lang                       CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
-- 2009/09/01 Ver.1.15 M.Sano Add End
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
  cv_fmt_time_default           CONSTANT  VARCHAR2(7)                                     :=  'HH24:MI';
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �̔����уf�[�^�o�^
  TYPE g_dlv_chk_list_tab       IS TABLE OF xxcos_rep_dlv_chk_list%ROWTYPE
    INDEX BY PLS_INTEGER;
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
  TYPE disc_item          IS RECORD(  disc_item_code fnd_lookup_values.lookup_code%TYPE );    -- �l���i�ڃR�[�h
  TYPE g_disc_item_work_ttype  IS TABLE OF disc_item INDEX BY BINARY_INTEGER;
  TYPE g_disc_item_ttype  IS TABLE OF disc_item INDEX BY fnd_lookup_values.lookup_code%TYPE;
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �̔����уf�[�^�o�^
  gt_dlv_chk_list               g_dlv_chk_list_tab;             -- �̔����уf�[�^�o�^
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
  gt_disc_item_work_tab         g_disc_item_work_ttype;         -- �l���i�ڃR�[�h�ꎞ�i�[�p
  gt_disc_item_tab              g_disc_item_ttype;              -- �l���i�ڃR�[�h�i�[�p
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
  
--
  gv_tkn1                       VARCHAR2(5000);                 -- �G���[���b�Z�[�W�p�g�[�N���P
  gv_tkn2                       VARCHAR2(5000);                 -- �G���[���b�Z�[�W�p�g�[�N���Q
  gv_tkn3                       VARCHAR2(5000);                 -- �G���[���b�Z�[�W�p�g�[�N���R
  gv_tkn4                       VARCHAR2(5000);                 -- �G���[���b�Z�[�W�p�g�[�N���S
  gv_key_info                   VARCHAR2(5000);                 -- �L�[���
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_delivery_date      IN      VARCHAR2,         -- �[�i��
    iv_delivery_base_code IN      VARCHAR2,         -- ���_
    iv_dlv_by_code        IN      VARCHAR2,         -- �c�ƈ�
    iv_hht_invoice_no     IN      VARCHAR2,         -- HHT�`�[No
    ov_errbuf             OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode            OUT     VARCHAR2,         -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg             OUT     VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
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
    -- �L�[���
    lv_key_info                 VARCHAR2(5000);
    --�p�����[�^�o�͗p
    lv_para_msg                 VARCHAR2(5000);
--
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
    --  �p�����[�^�o��
    lv_para_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_in_parameter,
                     iv_token_name1  => cv_tkn_para_delivery_date,
                     iv_token_value1 => iv_delivery_date,
                     iv_token_name2  => cv_tkn_para_delivery_base,
                     iv_token_value2 => iv_delivery_base_code,
                     iv_token_name3  => cv_tkn_para_dlv_by_code,
                     iv_token_value3 => iv_dlv_by_code,
                     iv_token_name4  => cv_tkn_para_hht_invoice,
                     iv_token_value4 => iv_hht_invoice_no
                     );
--
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => lv_para_msg
    );
--
    --  1�s��
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => NULL
    );
--
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
    BEGIN
      SELECT  look_val.lookup_code        lookup_code
      BULK COLLECT INTO
              gt_disc_item_work_tab
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.lookup_type       = ct_qck_discount_item_type  -- XXCOS1_DISCOUNT_ITEM_CODE
      AND     look_val.enabled_flag      = cv_yes                     -- Y
      AND     TO_DATE(iv_delivery_date,cv_fmt_date_default)
                >= NVL( look_val.start_date_active, TO_DATE(iv_delivery_date,cv_fmt_date_default) )
      AND     TO_DATE(iv_delivery_date,cv_fmt_date_default)
                <= NVL( look_val.end_date_active, TO_DATE(iv_delivery_date,cv_fmt_date_default) )
      AND     look_val.language          = ct_lang;
      --
      IF ( gt_disc_item_work_tab.COUNT = 0 ) THEN
        RAISE data_get_err;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE data_get_err;
    END;
    --
    FOR d IN 1..gt_disc_item_work_tab.COUNT LOOP
      gt_disc_item_tab(gt_disc_item_work_tab(d).disc_item_code) := gt_disc_item_work_tab(d);
    END LOOP;
-- ******* 2010/01/07 1.20 N.Maeda ADD  END  ****** --
--
  EXCEPTION
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
    WHEN data_get_err THEN
      -- �e�[�u����:�N�C�b�N�R�[�h�}�X�^
      gv_tkn1 := xxccp_common_pkg.get_msg( iv_application  => cv_application
                                          ,iv_name         => cv_msg_mst_qck  );
      -- ���ږ�:�N�C�b�N�R�[�h
      gv_tkn2 := xxccp_common_pkg.get_msg( iv_application  => cv_application
                                          ,iv_name         => cv_msg_name_lookup  );
      -- �L�[���ҏW
      xxcos_common_pkg.makeup_key_info(
                                   ov_errbuf      => lv_errbuf           -- �G���[�E���b�Z�[�W
                                  ,ov_retcode     => lv_retcode          -- ���^�[���E�R�[�h
                                  ,ov_errmsg      => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
                                  ,ov_key_info    => gv_key_info         -- �L�[���
                                  ,iv_item_name1  => gv_tkn1             -- �v��ID
                                  ,iv_data_value1 => ct_qck_discount_item_type
                                  );
      --
      lv_errbuf := xxccp_common_pkg.get_msg( iv_application  => cv_application
                                            ,iv_name         => cv_msg_get_err
                                            ,iv_token_name1  => cv_tkn_table
                                            ,iv_token_value1 => gv_tkn1
                                            ,iv_token_name2  => cv_tkn_key_data
                                            ,iv_token_value2 => gv_key_info
                                              );
      -- ���O�o��
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
-- ******* 2010/01/07 1.20 N.Maeda ADD  END  ****** --
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
   * Procedure Name   : sales_per_data_entry
   * Description      : �̔����уf�[�^���o(A-3)�A�[�i�f�[�^�o�^�i�̔����сj(A-4)
   ***********************************************************************************/
  PROCEDURE sales_per_data_entry(
    iv_delivery_date      IN      VARCHAR2,         -- �[�i��
    iv_delivery_base_code IN      VARCHAR2,         -- ���_
    iv_dlv_by_code        IN      VARCHAR2,         -- �c�ƈ�
    iv_hht_invoice_no     IN      VARCHAR2,         -- HHT�`�[No
    ov_errbuf             OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT     VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT     VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sales_per_data_entry'; -- �v���O������
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
    ld_delivery_date       DATE;                                            -- �p�����[�^�ϊ���̔[�i��
    lv_check_mark          VARCHAR2(2);                                     -- �`�F�b�N�}�[�N
    ln_target_cnt          NUMBER;                                          -- �Ώی���
    lt_enabled_flag        fnd_lookup_values.enabled_flag%TYPE;             -- �Ƒԏ����ގg�p��
    lt_standard_unit_price xxcos_sales_exp_lines.standard_unit_price%TYPE;  -- ��P��
    lt_business_cost       xxcos_sales_exp_lines.business_cost%TYPE;        -- �c�ƌ���
    lt_st_date             ic_item_mst_b.attribute6%TYPE;                   -- �艿�K�p�J�n
    lt_plice_new           ic_item_mst_b.attribute5%TYPE;                   -- �艿(�V)
    lt_plice_old           ic_item_mst_b.attribute4%TYPE;                   -- ���艿
    lt_plice_new_no_tax    ic_item_mst_b.attribute5%TYPE;                   -- �艿(�V)
    lt_plice_old_no_tax    ic_item_mst_b.attribute4%TYPE;                   -- ���艿
    lt_confirmation        xxcos_rep_dlv_chk_list.confirmation%TYPE;        -- �m�F
    lt_set_plice           xxcos_rep_dlv_chk_list.ploce%TYPE;               -- ���l
    lt_tax_amount          NUMBER;                                          -- �ŋ�
    lt_tax_rate            xxcos_sales_exp_headers.tax_rate%TYPE;           -- ����Őŗ�
--
    -- *** ���[�J���E�J�[�\�� ***
-- ******************** 2009/06/05 Var.1.9 T.Tominaga MOD START  ******************************************
--    -- �̔����уf�[�^���o
--    CURSOR get_sale_data_cur(
--                               icp_delivery_date       DATE       -- �[�i��
--                              ,icp_delivery_base_code  VARCHAR2   -- ���_
--                              ,icp_dlv_by_code         VARCHAR2   -- �c�ƈ�
--                              ,icp_hht_invoice_no      VARCHAR2   -- HHT�`�[No
--                            )
--    IS
--      SELECT
--         infh.delivery_date                     AS target_date                     -- �Ώۓ��t
--        ,infh.sales_base_code                   AS base_code                       -- ���_�R�[�h
--        ,MIN( SUBSTRB( parb.party_name, 1, 40 ) )
--                                                AS base_name                       -- ���_����
--        ,riv.employee_number                    AS employee_num                    -- �[�i�҃R�[�h
--        ,MIN( riv.employee_name )               AS employee_name                   -- �c�ƈ�����
--        ,MIN( riv.group_code )                  AS group_code                      -- �O���[�v�ԍ�
--        ,MIN( riv.group_in_sequence )           AS group_in_sequence               -- �O���[�v������
--        ,infh.dlv_invoice_number                AS invoice_no                      -- �`�[�ԍ�
--        ,infh.inspect_date                      AS dlv_date                        -- �[�i��
--        ,infh.ship_to_customer_code             AS party_num                       -- �ڋq�R�[�h
--        ,MIN( SUBSTRB( parc.party_name, 1, 40 ) )
--                                                AS customer_name                   -- �ڋq��
--        ,incl.meaning                           AS input_class                     -- ���͋敪
--        ,infh.results_employee_code             AS performance_by_code             -- ���ьv��҃R�[�h
--        ,MIN( ppf.per_information18 || ' ' || ppf.per_information19 )
--                                                AS performance_by_name             -- ���юҖ�
--        ,CASE gysm1.vd_gyotai
--           WHEN  cv_yes  THEN MIN( cscl.meaning )
--           ELSE  NULL
--         END                                    AS card_sale_class                 -- �J�[�h����敪
--        ,MIN( infh.sale_amount_sum )            AS sudstance_total_amount          -- ����z
--        ,MIN( disc.sale_discount_amount )       AS sale_discount_amount            -- ����l���z
--        ,MIN( infh.tax_amount_sum )             AS consumption_tax_total_amount    -- ����ŋ��z���v
--        ,MIN( tacl.meaning )                    AS consumption_tax_class_mst       -- ����ŋ敪�i�}�X�^�j
--        ,infh.invoice_classification_code       AS invoice_classification_code     -- �`�[���ރR�[�h
--        ,infh.invoice_class                     AS invoice_class                   -- �`�[�敪
--        ,MIN( sacl.meaning )                    AS sale_class                      -- ����敪
--        ,sel.item_code                          AS item_code                       -- �i�ڃR�[�h
--        ,MIN( ximb.item_short_name )            AS item_name                       -- ���i��
--        ,SUM( sel.standard_qty )                AS quantity                        -- ����
--        ,sel.standard_unit_price                AS wholesale_unit_ploce            -- ���P��
--        ,MIN( gysm.enabled_flag )               AS enabled_flag                    -- �Ƒԏ����ގg�p��
--        ,MIN( sel.standard_unit_price )         AS standard_unit_price             -- ��P��
--        ,MIN( sel.business_cost )               AS business_cost                   -- �c�ƌ���
--        ,MIN( iimb.attribute6 )                 AS st_date                         -- �艿�K�p�J�n
--        ,MIN( iimb.attribute5 )                 AS plice_new                       -- �艿(�V)
--        ,MIN( iimb.attribute4 )                 AS plice_old                       -- ���艿
--        ,htcl.meaning                           AS consum_tax_calss_entered        -- ����ŋ敪�i���́j
--        ,CASE infh.card_sale_class
--           WHEN  ct_cash  THEN MIN( sel.cash_and_card )
--           WHEN  ct_card  THEN MIN( sel.sale_amount )
--           ELSE  cn_zero
--         END                                    AS card_amount                     -- �J�[�h���z
--        ,sel.column_no                          AS column_no                       -- �R����
--        ,hccl.meaning                           AS h_and_c                         -- H/C
--        ,pacl.meaning                           AS payment_class                   -- �����敪
----        ,pay.payment_amount                     AS payment_amount                  -- �����z
--        ,CASE gysm1.vd_gyotai
--           WHEN  cv_yes  THEN SUM( sel.standard_qty ) * sel.standard_unit_price 
--                                              -DECODE( infh.card_sale_class
--                                                , ct_cash, MIN( sel.cash_and_card )
--                                                , ct_card, MIN( sel.sale_amount )
--                                                , cn_zero )
--           ELSE  NULL
--         END                                    AS payment_amount                  -- �����z
--        ,MIN( cust.tax_rounding_rule )          AS tax_rounding_rule
--        ,MIN( infh.tax_rate )                   AS tax_rate                        -- ����Őŗ�
--        ,MIN( infh.consumption_tax_class )      AS consumption_tax_class           -- ����ŋ敪
--      FROM
--         xxcos_sales_exp_lines    sel           -- �̔����і��׃e�[�u��
--        ,hz_cust_accounts         base          -- �ڋq�}�X�^_���_
--        ,hz_cust_accounts         cust          -- �ڋq�}�X�^_�ڋq
--        ,xxcmm_cust_accounts      cuac          -- �ڋq�ǉ����
--        ,hz_parties               parb          -- �p�[�e�B_���_
--        ,hz_parties               parc          -- �p�[�e�B_�ڋq
--        ,xxcos_payment            pay           -- �����e�[�u��
--        ,ic_item_mst_b            iimb          -- OPM�i��
--        ,xxcmn_item_mst_b         ximb          -- OPM�i�ڃA�h�I��
--        ,per_people_f             ppf           -- �]�ƈ��}�X�^_�[�i
--        ,xxcos_rs_info_v          riv           -- �c�ƈ����view
--        ,(
--           SELECT
--              seh.delivery_date               AS delivery_date                -- �Ώۓ��t
--             ,seh.sales_base_code             AS sales_base_code              -- ���_�R�[�h
--             ,seh.dlv_by_code                 AS dlv_by_code                  -- �[�i�҃R�[�h
--             ,seh.dlv_invoice_number          AS dlv_invoice_number           -- �`�[�ԍ�
--             ,seh.delivery_date               AS dlv_date                     -- �[�i��
--             ,seh.ship_to_customer_code       AS ship_to_customer_code        -- �ڋq�R�[�h
--             ,seh.input_class                 AS input_class                  -- ���͋敪
--             ,seh.results_employee_code       AS results_employee_code        -- ���ьv��҃R�[�h
--             ,seh.card_sale_class             AS card_sale_class              -- �J�[�h����敪
--             ,seh.consumption_tax_class       AS consumption_tax_class        -- ����ŋ敪
--             ,seh.invoice_classification_code AS invoice_classification_code  -- �`�[���ރR�[�h
--             ,seh.invoice_class               AS invoice_class                -- �`�[�敪
--             ,SUM(
--               CASE sel.item_code
--                 WHEN diit.lookup_code THEN sel.sale_amount
--                 ELSE cn_zero
--               END
--              )                               AS sale_discount_amount         -- ����l���z
--           FROM
--              xxcos_sales_exp_headers   seh           -- �̔����уw�b�_�e�[�u��
--             ,xxcos_sales_exp_lines     sel           -- �̔����і��׃e�[�u��
--             ,(
--                SELECT  look_val.lookup_code        lookup_code
--                       ,look_val.meaning            meaning
--                FROM    fnd_lookup_values     look_val
--                       ,fnd_lookup_types_tl   types_tl
--                       ,fnd_lookup_types      types
--                       ,fnd_application_tl    appl
--                       ,fnd_application       app
--                WHERE   app.application_short_name = cv_application             -- XXCOS
--                AND     look_val.lookup_type       = ct_qck_discount_item_type  -- XXCOS1_DISCOUNT_ITEM_CODE
--                AND     look_val.enabled_flag      = cv_yes                     -- Y
--                AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--                AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--                AND     types_tl.language          = USERENV( 'LANG' )
--                AND     look_val.language          = USERENV( 'LANG' )
--                AND     appl.language              = USERENV( 'LANG' )
--                AND     appl.application_id        = types.application_id
--                AND     app.application_id         = appl.application_id
--                AND     types_tl.lookup_type       = look_val.lookup_type
--                AND     types.lookup_type          = types_tl.lookup_type
--                AND     types.security_group_id    = types_tl.security_group_id
--                AND     types.view_application_id  = types_tl.view_application_id
--              ) diit    -- �l���i��
--           WHERE
--             seh.delivery_date           = icp_delivery_date                        -- �p�����[�^�̔[�i��
--           AND seh.sales_base_code       = icp_delivery_base_code                   -- �p�����[�^�̋��_
--           AND seh.dlv_by_code           = NVL( icp_dlv_by_code, seh.dlv_by_code )  -- �p�����[�^�̉c�ƈ�
--           AND seh.dlv_invoice_number    = NVL( icp_hht_invoice_no, seh.dlv_invoice_number )
--                                                                                  -- �p�����[�^�̓`�[�ԍ�
--           AND seh.sales_exp_header_id   = sel.sales_exp_header_id
--           AND sel.item_code             = diit.lookup_code(+)
--           GROUP BY
--              seh.delivery_date                      -- �[�i��
--             ,seh.sales_base_code                    -- ���_�R�[�h
--             ,seh.dlv_by_code                        -- �[�i�҃R�[�h
--             ,seh.dlv_invoice_number                 -- �`�[�ԍ�
--             ,seh.ship_to_customer_code              -- �ڋq�R�[�h
--             ,seh.input_class                        -- ���͋敪
--             ,seh.results_employee_code              -- ���ьv��҃R�[�h
--             ,seh.card_sale_class                    -- �J�[�h����敪
--             ,seh.consumption_tax_class              -- ����ŋ敪
--             ,seh.invoice_classification_code        -- �`�[���ރR�[�h
--             ,seh.invoice_class                      -- �`�[�敪
--         ) disc         -- ����l���z
--        ,(
--           SELECT
--              MIN( seh.sales_exp_header_id )         AS sales_exp_header_id             -- �̔����уw�b�_ID
--             ,seh.delivery_date                      AS delivery_date                   -- �Ώۓ��t
--             ,seh.sales_base_code                    AS sales_base_code                 -- ���_�R�[�h
--             ,seh.dlv_by_code                        AS dlv_by_code                     -- �[�i�҃R�[�h
--             ,seh.dlv_invoice_number                 AS dlv_invoice_number              -- �`�[�ԍ�
--             ,seh.delivery_date                      AS dlv_date                        -- �[�i��
--             ,seh.inspect_date                       AS inspect_date                    -- ������
--             ,seh.ship_to_customer_code              AS ship_to_customer_code           -- �ڋq�R�[�h
--             ,seh.input_class                        AS input_class                     -- ���͋敪
--             ,MIN( seh.cust_gyotai_sho )             AS cust_gyotai_sho                 -- �Ƒԏ�����
--             ,seh.results_employee_code              AS results_employee_code           -- ���ьv��҃R�[�h
--             ,seh.card_sale_class                    AS card_sale_class                 -- �J�[�h����敪
--             ,SUM( seh.sale_amount_sum )             AS sale_amount_sum                 -- ����z
--             ,SUM( seh.tax_amount_sum  )             AS tax_amount_sum                  -- ����ŋ��z���v
--             ,seh.consumption_tax_class              AS consumption_tax_class           -- ����ŋ敪
--             ,seh.invoice_classification_code        AS invoice_classification_code     -- �`�[���ރR�[�h
--             ,seh.invoice_class                      AS invoice_class                   -- �`�[�敪
--             ,MIN( seh.create_class )                AS create_class                    -- �쐬���敪
--             ,MIN( seh.tax_rate )                    AS tax_rate                        -- ����Őŗ�
--           FROM
--             xxcos_sales_exp_headers   seh           -- �̔����уw�b�_�e�[�u��
--           WHERE
--             seh.delivery_date           = icp_delivery_date                        -- �p�����[�^�̔[�i��
--           AND seh.sales_base_code       = icp_delivery_base_code                   -- �p�����[�^�̋��_
--           AND seh.dlv_by_code           = NVL( icp_dlv_by_code, seh.dlv_by_code )  -- �p�����[�^�̉c�ƈ�
--           AND seh.dlv_invoice_number    = NVL( icp_hht_invoice_no, seh.dlv_invoice_number )
--                                                                                  -- �p�����[�^�̓`�[�ԍ�
--           GROUP BY
--              seh.delivery_date                      -- �[�i��
--             ,seh.sales_base_code                    -- ���_�R�[�h
--             ,seh.dlv_by_code                        -- �[�i�҃R�[�h
--             ,seh.inspect_date                       -- ������
--             ,seh.dlv_invoice_number                 -- �`�[�ԍ�
--             ,seh.ship_to_customer_code              -- �ڋq�R�[�h
--             ,seh.input_class                        -- ���͋敪
--             ,seh.results_employee_code              -- ���ьv��҃R�[�h
--             ,seh.card_sale_class                    -- �J�[�h����敪
--             ,seh.consumption_tax_class              -- ����ŋ敪
--             ,seh.invoice_classification_code        -- �`�[���ރR�[�h
--             ,seh.invoice_class                      -- �`�[�敪
--         ) infh         -- �w�b�_���
--        ,(
--            SELECT  look_val.meaning      meaning 
--            FROM    fnd_lookup_values     look_val
--                   ,fnd_lookup_types_tl   types_tl
--                   ,fnd_lookup_types      types
--                   ,fnd_application_tl    appl
--                   ,fnd_application       app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_org_cls_type     -- XXCOS1_MK_ORG_CLS_MST_002_A05
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  orct    -- �쐬���敪
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_input_class      -- XXCOS1_INPUT_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  incl    -- ���͋敪
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_card_sale_class  -- XXCOS1_CARD_SALE_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  cscl    -- �J�[�h���敪
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_sale_class       -- XXCOS1_SALE_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  sacl    -- ����敪
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--                   ,look_val.attribute3         attribute3
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_tax_class        -- XXCOS1_CONSUMPTION_TAX_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  htcl    -- HHT����ŋ敪
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_money_class      -- XXCOS1_RECEIPT_MONEY_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  pacl    -- �����敪
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_hc_class         -- XXCOS1_HC_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  hccl    -- H/C�敪
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--                   ,look_val.attribute3         attribute3
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_tax_class        -- XXCOS1_CONSUMPTION_TAX_CLASS
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  tacl    -- ����ŋ敪
--        ,(
--            SELECT  look_val.lookup_code        lookup_code
--                   ,look_val.meaning            meaning
--                   ,look_val.enabled_flag       enabled_flag
--            FROM    fnd_lookup_values           look_val
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_gyotai_sho_mst   -- XXCOS1_GYOTAI_SHO_MST_002_A03
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
--         )  gysm    -- �Ƒԏ����ޓ���}�X�^
--        ,(
--            SELECT  look_val.meaning            meaning
--                   ,look_val.attribute1         vd_gyotai
--            FROM    fnd_lookup_values           look_val
--            WHERE   look_val.lookup_type       = ct_qck_gyotai_sho_mst1   -- XXCOS1_GYOTAI_SHO_MST_002_A05
--            AND     look_val.enabled_flag      = cv_yes                  -- Y
--            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
--            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
--            AND     look_val.language          = USERENV( 'LANG' )
--         )  gysm1    -- �Ƒԏ����ޓ���}�X�^
--      WHERE
--        infh.delivery_date           = icp_delivery_date               -- �p�����[�^�̔[�i��
--      AND infh.sales_base_code       = icp_delivery_base_code          -- �p�����[�^�̋��_
--      AND infh.sales_exp_header_id   = sel.sales_exp_header_id          -- �̔����уw�b�_������.�̔����уw�b�_ID
--      AND base.customer_class_code   = ct_cust_class_base              -- �ڋq�敪�����_
--      AND infh.sales_base_code       = base.account_number             -- �̔����уw�b�_���ڋq�}�X�^_���_
--      AND base.party_id              = parb.party_id                   -- �ڋq�}�X�^_���_���p�[�e�B_���_
---- ******************** 2009/05/01 Var.1.6 N.Maeda MOD START  ******************************************
----      AND cust.customer_class_code   = ct_cust_class_customer          -- �ڋq�敪���ڋq
--      AND cust.customer_class_code   IN ( ct_cust_class_customer , ct_cust_class_customer_u ) -- �ڋq�敪IN �ڋq,��l�ڋq
---- ******************** 2009/05/01 Var.1.6 N.Maeda MOD  END   ******************************************
--      AND infh.ship_to_customer_code = cust.account_number             -- �̔����уw�b�_���ڋq�}�X�^_�ڋq
--      AND cust.cust_account_id       = cuac.customer_id                -- �ڋq�}�X�^_�ڋq���ڋq�ǉ����
--      AND cust.party_id              = parc.party_id                   -- �ڋq�}�X�^_�ڋq���p�[�e�B_�ڋq
--      AND infh.create_class IN ( orct.meaning )                        -- �쐬���敪���N�C�b�N�R�[�h
--      AND infh.results_employee_code = ppf.employee_number(+)
--      AND sel.item_code              = iimb.item_no
--      AND iimb.item_id               = ximb.item_id
--      AND infh.sales_base_code       = riv.base_code
--      AND riv.employee_number        = NVL( icp_dlv_by_code, riv.employee_number )
--      AND infh.delivery_date        >= NVL( riv.effective_start_date, infh.delivery_date )
--      AND infh.delivery_date        <= NVL( riv.effective_end_date, infh.delivery_date )
--      AND infh.delivery_date        >= riv.per_effective_start_date
--      AND infh.delivery_date        <= riv.per_effective_end_date
--      AND infh.delivery_date        >= riv.paa_effective_start_date
--      AND infh.delivery_date        <= riv.paa_effective_end_date
--      AND infh.dlv_invoice_number    = NVL( icp_hht_invoice_no, infh.dlv_invoice_number )
--      AND infh.dlv_invoice_number    = pay.hht_invoice_no(+)
--      AND incl.lookup_code           = infh.input_class
--      AND cscl.lookup_code           = NVL( infh.card_sale_class, cv_x )
--      AND sacl.lookup_code           = sel.sales_class
--      AND htcl.attribute3            = infh.consumption_tax_class
--      AND pacl.lookup_code(+)        = pay.payment_class
--      AND hccl.lookup_code(+)        = NVL( sel.hot_cold_class, cv_x )
--      AND tacl.attribute3            = cuac.tax_div
--      AND gysm.meaning(+)            = infh.cust_gyotai_sho
--      AND infh.delivery_date         = disc.delivery_date                -- �w�b�_���A����l���z.�[�i��
--      AND infh.sales_base_code       = disc.sales_base_code              -- �w�b�_���A����l���z.���_�R�[�h
--      AND riv.employee_number        = infh.dlv_by_code                  -- �c�ƈ����A�w�b�_���.�[�i�҃R�[�h
--      AND infh.dlv_invoice_number    = disc.dlv_invoice_number           -- �w�b�_���A����l���z.�`�[�ԍ�
--      AND infh.dlv_date              = disc.dlv_date                     -- �w�b�_���A����l���z.�[�i��
--      AND infh.ship_to_customer_code = disc.ship_to_customer_code        -- �w�b�_���A����l���z.�ڋq�R�[�h
--      AND infh.results_employee_code = disc.results_employee_code        -- �w�b�_���A����l���z.���ьv��҃R�[�h
--      AND NVL( infh.invoice_classification_code, cv_x )
--            = NVL( disc.invoice_classification_code, cv_x )              -- �w�b�_���A����l���z.�`�[���ރR�[�h
--      AND NVL( infh.invoice_class, cv_x )
--                                     = NVL( disc.invoice_class, cv_x )   -- �w�b�_���A����l���z.�`�[�敪
--      AND NVL( infh.card_sale_class, cv_x )
--                                     = NVL( disc.card_sale_class, cv_x ) -- �w�b�_���A����l���z.�J�[�h����敪
--      AND cuac.business_low_type     = gysm1.meaning( + )
--      GROUP BY
--         infh.delivery_date                      -- �Ώۓ��t
--        ,infh.sales_base_code                    -- ���_�R�[�h
--        ,riv.employee_number                     -- �[�i�҃R�[�h
--        ,infh.dlv_invoice_number                 -- �`�[�ԍ�
--        ,infh.dlv_date                           -- �[�i��
--        ,infh.inspect_date                       -- ������(�[�i��)
--        ,infh.ship_to_customer_code              -- �ڋq�R�[�h
--        ,incl.meaning                            -- ���͋敪
--        ,infh.results_employee_code              -- ���ьv��҃R�[�h
--        ,infh.card_sale_class                    -- �J�[�h����敪
--        ,htcl.meaning                            -- ����ŋ敪
--        ,infh.invoice_classification_code        -- �`�[���ރR�[�h
--        ,infh.invoice_class                      -- �`�[�敪
--        ,sel.item_code                           -- �i�ڃR�[�h
--        ,sel.standard_unit_price                 -- ���P��
--        ,sel.column_no                           -- �R����
--        ,sel.red_black_flag                      -- �ԍ��t���O
--        ,hccl.meaning                            -- H/C
--        ,pacl.meaning                            -- �����敪
----        ,pay.payment_amount                      -- �����z
--        ,gysm1.vd_gyotai
--      HAVING
--        ( SUM( sel.sale_amount )  != 0           -- ������z
--          OR
--          SUM( sel.standard_qty ) != 0 )         -- �[�i����
--      ;
--
    -- �̔����уf�[�^���o
    CURSOR get_sale_data_cur(
                               icp_delivery_date       DATE       -- �[�i��
                              ,icp_delivery_base_code  VARCHAR2   -- ���_
                              ,icp_dlv_by_code         VARCHAR2   -- �c�ƈ�
                              ,icp_hht_invoice_no      VARCHAR2   -- HHT�`�[No
                            )
    IS
      SELECT
-- 2009/09/01 Ver.1.15 M.Sano Add Start
         /*+
           LEADING ( riv.jrrx_n )
           INDEX   ( riv.jrgm_n jtf_rs_group_members_n2)
           INDEX   ( riv.jrgb_n jtf_rs_groups_b_u1 )
           INDEX   ( riv.jrrx_n xxcso_jrre_n02 )
           USE_NL  ( riv.papf_n )
           USE_NL  ( riv.pept_n )
           USE_NL  ( riv.paaf_n )
           USE_NL  ( riv.jrgm_n )
           USE_NL  ( riv.jrgb_n )
           LEADING ( riv.jrrx_o )
           INDEX   ( riv.jrrx_o xxcso_jrre_n02 )
           INDEX   ( riv.jrgm_o jtf_rs_group_members_n2)
           INDEX   ( riv.jrgb_o jtf_rs_groups_b_u1 )
           USE_NL  ( riv.papf_o )
           USE_NL  ( riv.pept_o )
           USE_NL  ( riv.paaf_o )
           USE_NL  ( riv.jrgm_o )
           USE_NL  ( riv.jrgb_o )
           USE_NL  ( riv )
           USE_NL  ( disc )
           USE_NL  ( infd )
         */
-- 2009/09/01 Ver.1.15 M.Sano Add End
         infh.delivery_date                        AS target_date                     -- �Ώۓ��t
        ,infh.sales_base_code                      AS base_code                       -- ���_�R�[�h
        ,SUBSTRB( parb.party_name, 1, 40 )         AS base_name                       -- ���_����
        ,riv.employee_number                       AS employee_num                    -- �[�i�҃R�[�h
-- ************************ 2009/09/30 S.Miyakoshi Var1.16 MOD START ************************ --
--        ,riv.employee_name                         AS employee_name                   -- �c�ƈ�����
        ,SUBSTRB( riv.employee_name, 1, 40 )       AS employee_name                   -- �c�ƈ�����
-- ************************ 2009/09/30 S.Miyakoshi Var1.16 MOD  END  ************************ --
        ,riv.group_code                            AS group_code                      -- �O���[�v�ԍ�
        ,riv.group_in_sequence                     AS group_in_sequence               -- �O���[�v������
        ,infh.dlv_invoice_number                   AS invoice_no                      -- �`�[�ԍ�
        ,infh.inspect_date                         AS dlv_date                        -- ������
        ,infh.ship_to_customer_code                AS party_num                       -- �ڋq�R�[�h
        ,SUBSTRB( parc.party_name, 1, 40 )         AS customer_name                   -- �ڋq��
        ,incl.meaning                              AS input_class                     -- ���͋敪
        ,infh.results_employee_code                AS performance_by_code             -- ���ьv��҃R�[�h
-- ************************ 2009/09/30 S.Miyakoshi Var1.16 MOD START ************************ --
--        ,ppf.per_information18 || ' ' || ppf.per_information19
        ,SUBSTRB( ppf.per_information18 || ' ' || ppf.per_information19, 1, 40 )
-- ************************ 2009/09/30 S.Miyakoshi Var1.16 MOD  END  ************************ --
                                                   AS performance_by_name             -- ���юҖ�
        ,CASE gysm1.vd_gyotai
           WHEN  cv_yes  THEN cscl.meaning
           ELSE  NULL
         END                                       AS card_sale_class                 -- �J�[�h����敪
        ,infh.sale_amount_sum                      AS sudstance_total_amount          -- ����z
        ,disc.sale_discount_amount                 AS sale_discount_amount            -- ����l���z
        ,infh.tax_amount_sum                       AS consumption_tax_total_amount    -- ����ŋ��z���v
        ,tacl.meaning                              AS consumption_tax_class_mst       -- ����ŋ敪�i�}�X�^�j
        ,infh.invoice_classification_code          AS invoice_classification_code     -- �`�[���ރR�[�h
        ,infh.invoice_class                        AS invoice_class                   -- �`�[�敪
        ,sacl.meaning                              AS sale_class                      -- ����敪
        ,infd.item_code                            AS item_code                       -- �i�ڃR�[�h
        ,ximb.item_short_name                      AS item_name                       -- ���i��
        ,infd.quantity                             AS quantity                        -- ����
        ,infd.wholesale_unit_ploce                 AS wholesale_unit_ploce            -- ���P��
        ,gysm.enabled_flag                         AS enabled_flag                    -- �Ƒԏ����ގg�p��
        ,infd.standard_unit_price                  AS standard_unit_price             -- ��P��
        ,infd.business_cost                        AS business_cost                   -- �c�ƌ���
        ,iimb.attribute6                           AS st_date                         -- �艿�K�p�J�n
        ,iimb.attribute5                           AS plice_new                       -- �艿(�V)
        ,iimb.attribute4                           AS plice_old                       -- ���艿
        ,htcl.meaning                              AS consum_tax_calss_entered        -- ����ŋ敪�i���́j
        ,infd.card_amount                          AS card_amount                     -- �J�[�h���z
        ,infd.column_no                            AS column_no                       -- �R����
        ,hccl.meaning                              AS h_and_c                         -- H/C
        ,infd.payment_class                        AS payment_class                   -- �����敪
        ,infd.payment_amount                       AS payment_amount                  -- �����z
        ,infd.tax_rounding_rule                    AS tax_rounding_rule               -- �[�������敪
        ,infd.tax_rate                             AS tax_rate                        -- ����Őŗ�
        ,infd.consumption_tax_class                AS consumption_tax_class           -- ����ŋ敪
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
        ,infh.hht_dlv_input_date                   AS hht_dlv_input_date              -- HHT�[�i���͓���
        ,infd.dlv_invoice_line_number              AS dlv_invoice_line_number         -- �[�i���הԍ�
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
-- 2011/03/07 Ver.1.21 S.Ochiai ADD Start
        ,infh.order_invoice_number                 AS order_number                    -- �I�[�_�[No
-- 2011/03/07 Ver.1.21 S.Ochiai ADD End
      FROM
         hz_cust_accounts         base          -- �ڋq�}�X�^_���_
        ,hz_cust_accounts         cust          -- �ڋq�}�X�^_�ڋq
        ,xxcmm_cust_accounts      cuac          -- �ڋq�ǉ����
        ,hz_parties               parb          -- �p�[�e�B_���_
        ,hz_parties               parc          -- �p�[�e�B_�ڋq
-- 2009/08/24 Ver.1.14 M.Sano Mod Start
--        ,per_people_f             ppf           -- �]�ƈ��}�X�^_���юҖ�
        ,per_all_people_f         ppf           -- �]�ƈ��}�X�^_���юҖ�
-- 2009/08/24 Ver.1.14 M.Sano Mod End
        ,ic_item_mst_b            iimb          -- OPM�i��
        ,xxcmn_item_mst_b         ximb          -- OPM�i�ڃA�h�I��
        ,xxcos_rs_info_v          riv           -- �c�ƈ����view
        ,(
           SELECT
              seh.delivery_date               AS delivery_date                -- �Ώۓ��t
             ,seh.sales_base_code             AS sales_base_code              -- ���_�R�[�h
             ,seh.dlv_by_code                 AS dlv_by_code                  -- �[�i�҃R�[�h
             ,seh.dlv_invoice_number          AS dlv_invoice_number           -- �`�[�ԍ�
             ,seh.delivery_date               AS dlv_date                     -- �[�i��
             ,seh.inspect_date                AS inspect_date                 -- ������
             ,seh.ship_to_customer_code       AS ship_to_customer_code        -- �ڋq�R�[�h
             ,seh.input_class                 AS input_class                  -- ���͋敪
             ,seh.results_employee_code       AS results_employee_code        -- ���ьv��҃R�[�h
             ,seh.card_sale_class             AS card_sale_class              -- �J�[�h����敪
             ,seh.invoice_classification_code AS invoice_classification_code  -- �`�[���ރR�[�h
             ,seh.consumption_tax_class       AS consumption_tax_class        -- ����ŋ敪
             ,seh.invoice_class               AS invoice_class                -- �`�[�敪
             ,seh.create_class                AS create_class                 -- �쐬���敪
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
             ,seh.hht_dlv_input_date          AS hht_dlv_input_date           -- HHT�[�i���͓���
-- 2009/12/17 Ver.1.19 Del Start
--             ,sel.dlv_invoice_line_number     AS dlv_invoice_line_number      -- �[�i���הԍ�
-- 2009/12/17 Ver.1.19 Del End
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
             ,SUM(
               CASE sel.item_code
                 WHEN diit.lookup_code THEN sel.sale_amount
                 ELSE cn_zero
               END
              )                               AS sale_discount_amount         -- ����l���z
           FROM
              xxcos_sales_exp_headers   seh           -- �̔����уw�b�_�e�[�u��
             ,xxcos_sales_exp_lines     sel           -- �̔����і��׃e�[�u��
             ,(
                SELECT  look_val.lookup_code        lookup_code
                       ,look_val.meaning            meaning
                FROM    fnd_lookup_values     look_val
                WHERE   look_val.lookup_type       = ct_qck_discount_item_type  -- XXCOS1_DISCOUNT_ITEM_CODE
                AND     look_val.enabled_flag      = cv_yes                     -- Y
                AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
                AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--                AND     look_val.language          = USERENV( 'LANG' )
                AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
              ) diit    -- �l���i��
           WHERE
               seh.delivery_date         = icp_delivery_date                                    -- �p�����[�^�̔[�i��
           AND seh.sales_base_code       = icp_delivery_base_code                               -- �p�����[�^�̋��_
           AND seh.dlv_by_code           = NVL( icp_dlv_by_code, seh.dlv_by_code )              -- �p�����[�^�̉c�ƈ�
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--           AND seh.dlv_invoice_number    = NVL( icp_hht_invoice_no, seh.dlv_invoice_number )    -- �p�����[�^�̓`�[�ԍ�
           AND (   (    icp_hht_invoice_no    IS NOT NULL
                    AND seh.dlv_invoice_number = icp_hht_invoice_no )
                OR (    icp_hht_invoice_no    IS NULL ) )                                       -- �p�����[�^�̓`�[�ԍ�
-- 2009/09/01 Ver.1.15 M.Sano Mod End
           AND seh.sales_exp_header_id   = sel.sales_exp_header_id
           AND sel.item_code             = diit.lookup_code(+)
           GROUP BY
              seh.delivery_date                      -- �[�i��
             ,seh.sales_base_code                    -- ���_�R�[�h
             ,seh.dlv_by_code                        -- �[�i�҃R�[�h
             ,seh.dlv_invoice_number                 -- �`�[�ԍ�
             ,seh.inspect_date                       -- ������
             ,seh.ship_to_customer_code              -- �ڋq�R�[�h
             ,seh.input_class                        -- ���͋敪
             ,seh.results_employee_code              -- ���ьv��҃R�[�h
             ,seh.card_sale_class                    -- �J�[�h����敪
             ,seh.invoice_classification_code        -- �`�[���ރR�[�h
             ,seh.consumption_tax_class              -- ����ŋ敪
             ,seh.invoice_class                      -- �`�[�敪
             ,seh.create_class                       -- �쐬���敪
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
             ,seh.hht_dlv_input_date                 -- HHT�[�i���͓���
-- 2009/12/17 Ver.1.19 Del Start
--             ,sel.dlv_invoice_line_number            -- �[�i���הԍ�
-- 2009/12/17 Ver.1.19 Del End
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
         ) disc         -- ����l���z
        ,(
           SELECT
              seh.delivery_date               AS delivery_date                -- �Ώۓ��t
-- 2011/03/07 Ver.1.21 S.Ochiai ADD Start
             ,seh.order_invoice_number        AS order_invoice_number         -- �����`�[�ԍ�
-- 2011/03/07 Ver.1.21 S.Ochiai ADD End
             ,seh.sales_base_code             AS sales_base_code              -- ���_�R�[�h
             ,seh.dlv_by_code                 AS dlv_by_code                  -- �[�i�҃R�[�h
             ,seh.dlv_invoice_number          AS dlv_invoice_number           -- �`�[�ԍ�
             ,seh.delivery_date               AS dlv_date                     -- �[�i��
             ,seh.inspect_date                AS inspect_date                 -- ������
             ,seh.ship_to_customer_code       AS ship_to_customer_code        -- �ڋq�R�[�h
             ,seh.input_class                 AS input_class                  -- ���͋敪
             ,seh.results_employee_code       AS results_employee_code        -- ���ьv��҃R�[�h
             ,seh.card_sale_class             AS card_sale_class              -- �J�[�h����敪
             ,seh.invoice_classification_code AS invoice_classification_code  -- �`�[���ރR�[�h
             ,seh.consumption_tax_class       AS consumption_tax_class        -- ����ŋ敪
             ,seh.invoice_class               AS invoice_class                -- �`�[�敪
             ,seh.create_class                AS create_class                 -- �쐬���敪
             ,SUM( seh.sale_amount_sum )      AS sale_amount_sum              -- ����z
             ,SUM( seh.tax_amount_sum  )      AS tax_amount_sum               -- ����ŋ��z���v
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
             ,seh.hht_dlv_input_date          AS hht_dlv_input_date           -- HHT�[�i���͓���
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
           FROM
              xxcos_sales_exp_headers   seh          -- �̔����уw�b�_�e�[�u��
           WHERE
               seh.delivery_date         = icp_delivery_date                                   -- �p�����[�^�̔[�i��
           AND seh.sales_base_code       = icp_delivery_base_code                              -- �p�����[�^�̋��_
           AND seh.dlv_by_code           = NVL( icp_dlv_by_code, seh.dlv_by_code )             -- �p�����[�^�̉c�ƈ�
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--           AND seh.dlv_invoice_number    = NVL( icp_hht_invoice_no, seh.dlv_invoice_number )   -- �p�����[�^�̓`�[�ԍ�
           AND (   (    icp_hht_invoice_no    IS NOT NULL
                    AND seh.dlv_invoice_number = icp_hht_invoice_no )
                OR (    icp_hht_invoice_no    IS NULL ) )                                      -- �p�����[�^�̓`�[�ԍ�
-- 2009/09/01 Ver.1.15 M.Sano Mod End
           GROUP BY
              seh.delivery_date                      -- �[�i��
-- 2011/03/07 Ver.1.21 S.Ochiai ADD Start
             ,seh.order_invoice_number               -- �����`�[�ԍ�
-- 2011/03/07 Ver.1.21 S.Ochiai ADD End
             ,seh.sales_base_code                    -- ���_�R�[�h
             ,seh.dlv_by_code                        -- �[�i�҃R�[�h
             ,seh.dlv_invoice_number                 -- �`�[�ԍ�
             ,seh.inspect_date                       -- ������
             ,seh.ship_to_customer_code              -- �ڋq�R�[�h
             ,seh.input_class                        -- ���͋敪
             ,seh.results_employee_code              -- ���ьv��҃R�[�h
             ,seh.card_sale_class                    -- �J�[�h����敪
             ,seh.invoice_classification_code        -- �`�[���ރR�[�h
             ,seh.consumption_tax_class              -- ����ŋ敪
             ,seh.invoice_class                      -- �`�[�敪
             ,seh.create_class                       -- �쐬���敪
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
             ,seh.hht_dlv_input_date                 -- HHT�[�i���͓���
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
         ) infh         -- �w�b�_���
        ,(
           SELECT
              seh.delivery_date                      AS delivery_date                   -- �Ώۓ��t
             ,seh.sales_base_code                    AS sales_base_code                 -- ���_�R�[�h
             ,seh.dlv_by_code                        AS dlv_by_code                     -- �[�i�҃R�[�h
             ,seh.dlv_invoice_number                 AS dlv_invoice_number              -- �`�[�ԍ�
             ,seh.delivery_date                      AS dlv_date                        -- �[�i��
             ,seh.inspect_date                       AS inspect_date                    -- ������
             ,seh.ship_to_customer_code              AS ship_to_customer_code           -- �ڋq�R�[�h
             ,seh.input_class                        AS input_class                     -- ���͋敪
             ,seh.results_employee_code              AS results_employee_code           -- ���ьv��҃R�[�h
             ,seh.card_sale_class                    AS card_sale_class                 -- �J�[�h����敪
             ,seh.invoice_classification_code        AS invoice_classification_code     -- �`�[���ރR�[�h
             ,seh.consumption_tax_class              AS consumption_tax_class           -- ����ŋ敪
             ,seh.invoice_class                      AS invoice_class                   -- �`�[�敪
             ,seh.create_class                       AS create_class                    -- �쐬���敪
-- 2009/12/17 Ver.1.19 Mod Start
             ,sel.sales_class                        AS sale_class                      -- ����敪
--             ,MAX( sel.sales_class )                 AS sale_class                      -- ����敪
-- 2009/12/17 Ver.1.19 Mod End
             ,sel.item_code                          AS item_code                       -- �i�ڃR�[�h
             ,SUM( sel.standard_qty )                AS quantity                        -- ����
             ,sel.standard_unit_price                AS wholesale_unit_ploce            -- ���P��
             ,MAX( sel.standard_unit_price )         AS standard_unit_price             -- ��P��
             ,MAX( sel.business_cost )               AS business_cost                   -- �c�ƌ���
             ,CASE seh.card_sale_class
                WHEN  ct_cash  THEN SUM( sel.cash_and_card )
                WHEN  ct_card  THEN SUM( sel.sale_amount )
                ELSE  cn_zero
              END                                    AS card_amount                     -- �J�[�h���z
             ,sel.column_no                          AS column_no                       -- �R����
             ,sel.hot_cold_class                     AS h_and_c                         -- H/C�敪
             ,NULL                                   AS payment_class                   -- �����敪
             ,CASE MAX(gysm.vd_gyotai)
                WHEN  cv_yes  THEN SUM( sel.standard_qty ) * MAX( sel.standard_unit_price )
                                                   -DECODE( seh.card_sale_class
                                                     , ct_cash, SUM( sel.cash_and_card )
                                                     , ct_card, SUM( sel.sale_amount )
                                                     , cn_zero )
                ELSE  NULL
              END                                    AS payment_amount                  -- �����z
-- ******************** 2009/06/10 Var.1.10 T.Tominaga MOD START  *****************************************
--             ,MAX( cust.tax_rounding_rule )          AS tax_rounding_rule
             ,MAX( xchv.bill_tax_round_rule )          AS tax_rounding_rule             -- �[�������敪
-- ******************** 2009/06/10 Var.1.10 T.Tominaga MOD END    *****************************************
             ,MAX( seh.tax_rate )                    AS tax_rate                        -- ����Őŗ�
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
             ,seh.hht_dlv_input_date          AS hht_dlv_input_date           -- HHT�[�i���͓���
             ,sel.dlv_invoice_line_number     AS dlv_invoice_line_number      -- �[�i���הԍ�
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
-- **************** 2010/01/07 1.20 N.Maeda MOL START **************** --
             ,SUM(sel.sale_amount)             AS line_sale_amount
-- **************** 2010/01/07 1.20 N.Maeda MOL  END  **************** --
           FROM
               xxcos_sales_exp_lines     sel           -- �̔����і��׃e�[�u��
              ,xxcos_sales_exp_headers   seh           -- �̔����уw�b�_�e�[�u��
              ,hz_cust_accounts          cust          -- �ڋq�}�X�^_�ڋq
              ,xxcmm_cust_accounts       cuac          -- �ڋq�ǉ����
-- ******************** 2009/06/10 Var.1.10 T.Tominaga ADD START  *****************************************
              ,xxcos_cust_hierarchy_v    xchv          -- �ڋq�r���[
-- ******************** 2009/06/10 Var.1.10 T.Tominaga ADD END    *****************************************
              ,hz_parties                parc          -- �p�[�e�B_�ڋq
              ,(
                  SELECT  look_val.meaning            meaning
                         ,look_val.attribute1         vd_gyotai
                  FROM    fnd_lookup_values           look_val
                  WHERE   look_val.lookup_type       = ct_qck_gyotai_sho_mst1       -- XXCOS1_GYOTAI_SHO_MST_002_A05
                  AND     look_val.enabled_flag      = cv_yes                       -- Y
                  AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
                  AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--                  AND     look_val.language          = USERENV( 'LANG' )
                  AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
               )  gysm     -- �Ƒԏ����ޓ���}�X�^
           WHERE
               seh.sales_exp_header_id   = sel.sales_exp_header_id                  -- �̔����уw�b�_������.�̔����уw�b�_ID
           AND seh.delivery_date         = icp_delivery_date                        -- �p�����[�^�̔[�i��
           AND seh.sales_base_code       = icp_delivery_base_code                   -- �p�����[�^�̋��_
           AND seh.dlv_by_code           = NVL( icp_dlv_by_code, seh.dlv_by_code )  -- �p�����[�^�̉c�ƈ�
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--           AND seh.dlv_invoice_number    = NVL( icp_hht_invoice_no, seh.dlv_invoice_number )   -- �p�����[�^�̓`�[�ԍ�
           AND (   (    icp_hht_invoice_no    IS NOT NULL
                    AND seh.dlv_invoice_number = icp_hht_invoice_no )
                OR (    icp_hht_invoice_no    IS NULL ) )                           -- �p�����[�^�̓`�[�ԍ�
-- 2009/09/01 Ver.1.15 M.Sano Mod End
           AND seh.ship_to_customer_code = cust.account_number                      -- �̔����уw�b�_���ڋq�}�X�^_�ڋq
           AND cust.customer_class_code  IN ( ct_cust_class_customer , ct_cust_class_customer_u )  
                                                                                    -- �ڋq�敪IN �ڋq,��l�ڋq
           AND cust.cust_account_id      = cuac.customer_id                         -- �ڋq�}�X�^_�ڋq���ڋq�ǉ����
           AND cust.party_id             = parc.party_id                            -- �ڋq�}�X�^_�ڋq���p�[�e�B_�ڋq
-- ******************** 2009/06/10 Var.1.10 T.Tominaga ADD START  *****************************************
           AND xchv.ship_account_number  = seh.ship_to_customer_code
-- ******************** 2009/06/10 Var.1.10 T.Tominaga ADD END    *****************************************
           AND cuac.business_low_type    = gysm.meaning( + )                        -- �Ƒԏ�����
           GROUP BY
              seh.delivery_date                      -- �[�i��
             ,seh.sales_base_code                    -- ���_�R�[�h
             ,seh.dlv_by_code                        -- �[�i�҃R�[�h
             ,seh.dlv_invoice_number                 -- �`�[�ԍ�
             ,seh.inspect_date                       -- ������
             ,seh.ship_to_customer_code              -- �ڋq�R�[�h
             ,seh.input_class                        -- ���͋敪
             ,seh.results_employee_code              -- ���ьv��҃R�[�h
             ,seh.card_sale_class                    -- �J�[�h����敪
             ,seh.invoice_classification_code        -- �`�[���ރR�[�h
             ,seh.consumption_tax_class              -- ����ŋ敪
             ,seh.invoice_class                      -- �`�[�敪
             ,seh.create_class                       -- �쐬���敪
             ,sel.item_code                          -- �i�ڃR�[�h
             ,sel.standard_unit_price                -- ���P��
             ,sel.column_no                          -- �R����
             ,sel.hot_cold_class                     -- H/C�敪
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
             ,seh.hht_dlv_input_date                 -- HHT�[�i���͓���
             ,sel.dlv_invoice_line_number            -- �[�i���הԍ�
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
-- 2009/12/17 Ver.1.19 Add Start
             ,sel.sales_class
-- 2009/12/17 Ver.1.19 Add End
         ) infd     -- ���׏��
        ,(
            SELECT  look_val.meaning      meaning 
            FROM    fnd_lookup_values     look_val
            WHERE   look_val.lookup_type       = ct_qck_org_cls_type      -- XXCOS1_MK_ORG_CLS_MST_002_A05
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  orct    -- �쐬���敪
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_input_class       -- XXCOS1_INPUT_CLASS
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  incl    -- ���͋敪
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_card_sale_class   -- XXCOS1_CARD_SALE_CLASS
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  cscl    -- �J�[�h���敪
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_sale_class        -- XXCOS1_SALE_CLASS
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  sacl    -- ����敪
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
                   ,look_val.attribute3         attribute3
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_tax_class         -- XXCOS1_CONSUMPTION_TAX_CLASS
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  htcl    -- HHT����ŋ敪
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_hc_class          -- XXCOS1_HC_CLASS
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  hccl    -- H/C�敪
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
                   ,look_val.attribute3         attribute3
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_tax_class         -- XXCOS1_CONSUMPTION_TAX_CLASS
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  tacl    -- ����ŋ敪
        ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
                   ,look_val.enabled_flag       enabled_flag
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_gyotai_sho_mst    -- XXCOS1_GYOTAI_SHO_MST_002_A03
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  gysm    -- �Ƒԏ����ޓ���}�X�^
        ,(
            SELECT  look_val.meaning            meaning
                   ,look_val.attribute1         vd_gyotai
            FROM    fnd_lookup_values           look_val
            WHERE   look_val.lookup_type       = ct_qck_gyotai_sho_mst1   -- XXCOS1_GYOTAI_SHO_MST_002_A05
            AND     look_val.enabled_flag      = cv_yes                   -- Y
            AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
            AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     look_val.language          = USERENV( 'LANG' )
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
         )  gysm1   -- �Ƒԏ����ޓ���}�X�^
      WHERE
          infh.delivery_date                            = disc.delivery_date                             -- [�w�b�_=�l��] �Ώۓ��t
      AND infh.sales_base_code                          = disc.sales_base_code                           --               ���_�R�[�h
      AND infh.dlv_by_code                              = disc.dlv_by_code                               --               �[�i�҃R�[�h
      AND infh.dlv_invoice_number                       = disc.dlv_invoice_number                        --               �`�[�ԍ�
      AND infh.dlv_date                                 = disc.dlv_date                                  --               �[�i��
      AND infh.inspect_date                             = disc.inspect_date                              --               ������
      AND infh.ship_to_customer_code                    = disc.ship_to_customer_code                     --               �ڋq�R�[�h
      AND infh.input_class                              = disc.input_class                               --               ���͋敪
      AND infh.results_employee_code                    = disc.results_employee_code                     --               ���ьv��҃R�[�h
      AND NVL( infh.card_sale_class            , cv_x ) = NVL( disc.card_sale_class            , cv_x )  --               �J�[�h����敪
      AND NVL( infh.invoice_classification_code, cv_x ) = NVL( disc.invoice_classification_code, cv_x )  --               �`�[���ރR�[�h
      AND infh.consumption_tax_class                    = disc.consumption_tax_class                     --               ����ŋ敪
      AND NVL( infh.invoice_class              , cv_x ) = NVL( disc.invoice_class              , cv_x )  --               �`�[�敪
      AND infh.create_class                             = disc.create_class                              --               �쐬���敪
      AND infh.delivery_date                            = infd.delivery_date                             -- [�w�b�_=����] �Ώۓ��t
      AND infh.sales_base_code                          = infd.sales_base_code                           --               ���_�R�[�h
      AND infh.dlv_by_code                              = infd.dlv_by_code                               --               �[�i�҃R�[�h
      AND infh.dlv_invoice_number                       = infd.dlv_invoice_number                        --               �`�[�ԍ�
      AND infh.dlv_date                                 = infd.dlv_date                                  --               �[�i��
      AND infh.inspect_date                             = infd.inspect_date                              --               ������
      AND infh.ship_to_customer_code                    = infd.ship_to_customer_code                     --               �ڋq�R�[�h
      AND infh.input_class                              = infd.input_class                               --               ���͋敪
      AND infh.results_employee_code                    = infd.results_employee_code                     --               ���ьv��҃R�[�h
      AND NVL( infh.card_sale_class            , cv_x ) = NVL( infd.card_sale_class            , cv_x )  --               �J�[�h����敪
      AND NVL( infh.invoice_classification_code, cv_x ) = NVL( infd.invoice_classification_code, cv_x )  --               �`�[���ރR�[�h
      AND infh.consumption_tax_class                    = infd.consumption_tax_class                     --               ����ŋ敪
      AND NVL( infh.invoice_class              , cv_x ) = NVL( infd.invoice_class              , cv_x )  --               �`�[�敪
      AND infh.create_class                             = infd.create_class                              --               �쐬���敪
      AND base.customer_class_code   = ct_cust_class_base                                                -- �ڋq�敪�����_
      AND infh.sales_base_code       = base.account_number                                               -- �̔����уw�b�_���ڋq�}�X�^_���_
      AND base.party_id              = parb.party_id                                                     -- �ڋq�}�X�^_���_���p�[�e�B_���_
      AND cust.customer_class_code   IN ( ct_cust_class_customer , ct_cust_class_customer_u )            -- �ڋq�敪IN �ڋq,��l�ڋq
      AND infh.ship_to_customer_code = cust.account_number                                               -- �̔����уw�b�_���ڋq�}�X�^_�ڋq
      AND cust.cust_account_id       = cuac.customer_id                                                  -- �ڋq�}�X�^_�ڋq���ڋq�ǉ����
      AND cust.party_id              = parc.party_id                                                     -- �ڋq�}�X�^_�ڋq���p�[�e�B_�ڋq
      AND infh.create_class IN ( orct.meaning )                                                          -- �쐬���敪���N�C�b�N�R�[�h
      AND infh.results_employee_code = ppf.employee_number(+)
-- 2009/12/17 Ver.1.19 Add Start
      AND infh.hht_dlv_input_date    = disc.hht_dlv_input_date                                           -- �w�b�_.HHT�[�i���͓��� = �l��.HHT�[�i���͓���
      AND infh.hht_dlv_input_date    = infd.hht_dlv_input_date                                           -- �w�b�_.HHT�[�i���͓��� = ����.HHT�[�i���͓���
-- 2009/12/17 Ver.1.19 Add End
-- 2009/08/24 Ver.1.14 M.Sano Mod Start
      AND infh.delivery_date        >= ppf.effective_start_date(+)
      AND infh.delivery_date        <= ppf.effective_end_date(+)
-- 2009/08/24 Ver.1.14 M.Sano Mod End
      AND infd.item_code             = iimb.item_no
      AND iimb.item_id               = ximb.item_id
      AND ximb.obsolete_class       <> cv_obsolete_class_one
      AND ximb.start_date_active    <= infh.delivery_date
      AND ximb.end_date_active      >= infh.delivery_date
      AND infh.sales_base_code       = riv.base_code
      AND riv.employee_number        = infh.dlv_by_code
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--      AND riv.employee_number        = NVL( icp_dlv_by_code, riv.employee_number )
      AND (   (    icp_dlv_by_code     IS NOT NULL
               AND riv.employee_number = icp_dlv_by_code )
           OR (    icp_dlv_by_code     IS NULL )
          )
-- 2009/09/01 Ver.1.15 M.Sano Mod End
      AND infh.delivery_date        >= NVL( riv.effective_start_date, infh.delivery_date )
      AND infh.delivery_date        <= NVL( riv.effective_end_date, infh.delivery_date )
      AND infh.delivery_date        >= riv.per_effective_start_date
      AND infh.delivery_date        <= riv.per_effective_end_date
      AND infh.delivery_date        >= riv.paa_effective_start_date
      AND infh.delivery_date        <= riv.paa_effective_end_date
      AND infh.dlv_invoice_number    = NVL( icp_hht_invoice_no, infh.dlv_invoice_number )
      AND incl.lookup_code           = infh.input_class
      AND cscl.lookup_code(+)        = NVL( infh.card_sale_class, cv_x )
      AND sacl.lookup_code           = infd.sale_class
      AND htcl.attribute3            = infh.consumption_tax_class
      AND hccl.lookup_code(+)        = NVL( infd.h_and_c, cv_x )
      AND tacl.attribute3            = cuac.tax_div
      AND cuac.business_low_type     = gysm.meaning(+)                                                   -- �Ƒԏ�����
      AND cuac.business_low_type     = gysm1.meaning(+)
-- **************** 2010/01/07 1.20 N.Maeda MOL START **************** --
--      AND infd.quantity             != cn_zero                                                           -- �[�i���� != 0
      AND ( (infd.quantity            = cn_zero
               AND infd.line_sale_amount   != cn_zero          -- ���ה���z���v != 0 
               AND EXISTS (  SELECT  cv_yes
                             FROM    fnd_lookup_values     look_val
                             WHERE   look_val.lookup_type       = ct_qck_discount_item_type  -- XXCOS1_DISCOUNT_ITEM_CODE
                             AND     look_val.enabled_flag      = cv_yes                     -- Y
                             AND     icp_delivery_date         >= NVL( look_val.start_date_active, icp_delivery_date )
                             AND     icp_delivery_date         <= NVL( look_val.end_date_active, icp_delivery_date )
                             AND     look_val.language          = ct_lang
                             AND     look_val.lookup_code       = infd.item_code )
            )
        OR  ( infd.quantity         != cn_zero )
          )
-- **************** 2010/01/07 1.20 N.Maeda MOL  END  **************** --
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
-- 2009/12/17 Ver.1.19 Del Start
--      AND disc.dlv_invoice_line_number = infd.dlv_invoice_line_number                -- �[�i���הԍ�
-- 2009/12/17 Ver.1.19 Del End
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
      ;
-- ******************** 2009/06/02 Var.1.9 T.Tominaga MOD END    ******************************************
--
--
    -- *** ���[�J���E���R�[�h ***
    -- �̔����уf�[�^���o �e�[�u���^
    TYPE l_get_sale_data_tab      IS TABLE OF get_sale_data_cur%ROWTYPE
      INDEX BY PLS_INTEGER;
    -- �`�[�ԍ��i�[�p �e�[�u���^
    TYPE l_invoice_num_tab        IS TABLE OF NUMBER
      INDEX BY xxcos_sales_exp_headers.dlv_invoice_number%TYPE;
--
    -- �̔����уf�[�^���o
    lt_get_sale_data              l_get_sale_data_tab;            -- �̔����уf�[�^���o
    -- �`�[�ԍ��i�[�p
    lt_invoice_num                l_invoice_num_tab;              -- �`�[�ԍ��i�[�p
    -- �z��ԍ�
    ln_num                        NUMBER DEFAULT 0;               -- �`�[�ԍ��i�[�p
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
    --==========================================================
    --�̔����уf�[�^���o(A-3)
    --==========================================================
    BEGIN
      ld_delivery_date  :=  TO_DATE(iv_delivery_date, cv_fmt_date_default);
--
      -- �`�F�b�N�}�[�N�擾
      lv_check_mark := xxccp_common_pkg.get_msg( cv_application, cv_msg_check_mark );
--
      -- �J�[�\��OPEN
      OPEN  get_sale_data_cur(
                                ld_delivery_date        -- �[�i��
                               ,iv_delivery_base_code   -- ���_
                               ,iv_dlv_by_code          -- �c�ƈ�
                               ,iv_hht_invoice_no       -- HHT�`�[No
                             );
      -- �o���N�t�F�b�`
      FETCH get_sale_data_cur BULK COLLECT INTO lt_get_sale_data;
      -- �Ώی����擾
      ln_target_cnt := get_sale_data_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE get_sale_data_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE
        IF ( get_sale_data_cur%ISOPEN ) THEN
          CLOSE get_sale_data_cur;
        END IF;
--
        -- �L�[���ҏW
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_date );
        gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_base );
        gv_tkn3   := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_by_code );
        gv_tkn4   := xxccp_common_pkg.get_msg( cv_application, cv_msg_hht_invoice_no );
        xxcos_common_pkg.makeup_key_info(
                                         ov_errbuf      => lv_errbuf           -- �G���[�E���b�Z�[�W
                                        ,ov_retcode     => lv_retcode          -- ���^�[���E�R�[�h
                                        ,ov_errmsg      => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    => gv_key_info         -- �L�[���
                                        ,iv_item_name1  => gv_tkn1             -- �[�i��
                                        ,iv_data_value1 => iv_delivery_date
                                        ,iv_item_name2  => gv_tkn2             -- ���_
                                        ,iv_data_value2 => iv_delivery_base_code
                                        ,iv_item_name3  => gv_tkn3             -- �c�ƈ�
                                        ,iv_data_value3 => iv_dlv_by_code
                                        ,iv_item_name4  => gv_tkn4             -- HHT�`�[No
                                        ,iv_data_value4 => iv_hht_invoice_no
                                        );
--
        -- �f�[�^���o�G���[���b�Z�[�W
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_sale_header_table );
        lv_errmsg := xxccp_common_pkg.get_msg(
                                               cv_application
                                              ,cv_msg_get_err
                                              ,cv_tkn_table
                                              ,gv_tkn1
                                              ,cv_tkn_key_data
                                              ,NULL
                                             );
        lv_errbuf  := lv_errmsg;
--
        RAISE global_api_expt;
    END;
--
    -- �Ώی����Z�b�g
    gn_target_cnt := ln_target_cnt;
--
    --==========================================================
    --�[�i�f�[�^�o�^�i�̔����сj(A-4)
    --==========================================================
    --  �Ώی�����0���̏ꍇ�o�^�������X�L�b�v
    IF ( ln_target_cnt != 0 ) THEN
--
      FOR in_no IN 1..ln_target_cnt LOOP
--
        -- �z��ԍ��擾
        ln_num := ln_num + 1;
--
        --  ���R�[�hID�擾
        SELECT
          xxcos_rep_dlv_chk_list_s01.nextval
        INTO
          gt_dlv_chk_list(ln_num).record_id
        FROM
          DUAL;
--
        -- �f�[�^�擾
        lt_enabled_flag        := lt_get_sale_data(in_no).enabled_flag;          -- �Ƒԏ����ގg�p��
        lt_standard_unit_price := lt_get_sale_data(in_no).standard_unit_price;   -- ��P��--���P��
        lt_business_cost       := lt_get_sale_data(in_no).business_cost;         -- �c�ƌ���
        lt_st_date             := lt_get_sale_data(in_no).st_date;               -- �艿�K�p�J�n
        lt_plice_new           := lt_get_sale_data(in_no).plice_new;             -- �艿(�V)
        lt_plice_old           := lt_get_sale_data(in_no).plice_old;             -- ���艿
        lt_plice_new_no_tax    := lt_get_sale_data(in_no).plice_new;             -- �艿(�V)
        lt_plice_old_no_tax    := lt_get_sale_data(in_no).plice_old;             -- ���艿
        lt_tax_rate            := lt_get_sale_data(in_no).tax_rate;              --�ŗ�
--
        -- ����
        IF ( lt_enabled_flag = cv_yes ) THEN
-- ******************** 2009/07/13 Var.1.13 T.Tominaga DEL START  *****************************************
--          lt_confirmation := NULL;
----
--        ELSE
-- ******************** 2009/07/13 Var.1.13 T.Tominaga DEL START  *****************************************
          --�c�ƌ����̐ŏ���
          lt_tax_amount          := lt_business_cost * lt_tax_rate / 100;
          -- �[������
          IF ( lt_get_sale_data(in_no).tax_rounding_rule    = cv_round_rule_up ) THEN
            -- �؂�グ�̏ꍇ
            IF ( lt_tax_amount - TRUNC( lt_tax_amount ) <> 0 ) THEN
              lt_tax_amount := TRUNC( lt_tax_amount ) + 1;
            END IF;
          ELSIF ( lt_get_sale_data(in_no).tax_rounding_rule = cv_round_rule_down ) THEN
            -- �؂艺���̏ꍇ
            lt_tax_amount := TRUNC( lt_tax_amount );
          ELSIF ( lt_get_sale_data(in_no).tax_rounding_rule = cv_round_rule_nearest ) THEN
            -- �l�̌ܓ��̏ꍇ
            lt_tax_amount := ROUND( lt_tax_amount );
          END IF;
          IF ( lt_get_sale_data(in_no).consumption_tax_class IS NULL
-- ******************** 2009/06/11 Var.1.11 T.Tominaga MOD START  *****************************************
--             OR ( lt_get_sale_data(in_no).consumption_tax_class <> cn_two 
--             AND lt_get_sale_data(in_no).consumption_tax_class <> cn_thr ) ) THEN
            OR lt_get_sale_data(in_no).consumption_tax_class <> cn_thr ) THEN
-- ******************** 2009/06/11 Var.1.11 T.Tominaga MOD END    *****************************************
            lt_tax_amount := 0;
          END IF;
          lt_business_cost  := lt_business_cost + lt_tax_amount;
--
          --�艿�i�V�j�̐ŏ���
          lt_tax_amount          := lt_plice_new * lt_tax_rate / 100;
          -- �[������
          IF ( lt_get_sale_data(in_no).tax_rounding_rule    = cv_round_rule_up ) THEN
            -- �؂�グ�̏ꍇ
            IF ( lt_tax_amount - TRUNC( lt_tax_amount ) <> 0 ) THEN
              lt_tax_amount := TRUNC( lt_tax_amount ) + 1;
            END IF;
          ELSIF ( lt_get_sale_data(in_no).tax_rounding_rule = cv_round_rule_down ) THEN
            -- �؂艺���̏ꍇ
            lt_tax_amount := TRUNC( lt_tax_amount );
          ELSIF ( lt_get_sale_data(in_no).tax_rounding_rule = cv_round_rule_nearest ) THEN
            -- �l�̌ܓ��̏ꍇ
            lt_tax_amount := ROUND( lt_tax_amount );
          END IF;
          IF ( lt_get_sale_data(in_no).consumption_tax_class IS NULL
-- ******************** 2009/06/11 Var.1.11 T.Tominaga MOD START  *****************************************
--             OR ( lt_get_sale_data(in_no).consumption_tax_class <> cn_two 
--             AND lt_get_sale_data(in_no).consumption_tax_class <> cn_thr ) ) THEN
            OR lt_get_sale_data(in_no).consumption_tax_class <> cn_thr ) THEN
-- ******************** 2009/06/11 Var.1.11 T.Tominaga MOD END    *****************************************
              lt_tax_amount := 0;
          END IF;
          lt_plice_new  := lt_plice_new + lt_tax_amount;
--
          --�艿�i���j�̐ŏ���
          lt_tax_amount          := lt_plice_old * lt_tax_rate / 100;
          -- �[������
          IF ( lt_get_sale_data(in_no).tax_rounding_rule    = cv_round_rule_up ) THEN
            -- �؂�グ�̏ꍇ
            IF ( lt_tax_amount - TRUNC( lt_tax_amount ) <> 0 ) THEN
              lt_tax_amount := TRUNC( lt_tax_amount ) + 1;
            END IF;
          ELSIF ( lt_get_sale_data(in_no).tax_rounding_rule = cv_round_rule_down ) THEN
            -- �؂艺���̏ꍇ
            lt_tax_amount := TRUNC( lt_tax_amount );
          ELSIF ( lt_get_sale_data(in_no).tax_rounding_rule = cv_round_rule_nearest ) THEN
            -- �l�̌ܓ��̏ꍇ
            lt_tax_amount := ROUND( lt_tax_amount );
          END IF;
          IF ( lt_get_sale_data(in_no).consumption_tax_class IS NULL
-- ******************** 2009/06/11 Var.1.11 T.Tominaga MOD START  *****************************************
--             OR ( lt_get_sale_data(in_no).consumption_tax_class <> cn_two 
--             AND lt_get_sale_data(in_no).consumption_tax_class <> cn_thr ) ) THEN
            OR lt_get_sale_data(in_no).consumption_tax_class <> cn_thr ) THEN
-- ******************** 2009/06/11 Var.1.11 T.Tominaga MOD END    *****************************************
              lt_tax_amount := 0;
          END IF;
          lt_plice_old  := lt_plice_old + lt_tax_amount;
--
-- ******************** 2009/07/13 Var.1.13 T.Tominaga MOD START  *****************************************
--          IF ( lt_standard_unit_price < lt_business_cost ) THEN    -- ��P�� < �c�ƌ���
--            lt_confirmation := lv_check_mark;
----
---- ******************** 2009/06/05 Var.1.9 T.Tominaga MOD START  ******************************************
----          ELSIF ( lt_st_date >= iv_delivery_date ) THEN            -- �艿�K�p�J�n >= �[�i��
--          ELSIF ( lt_st_date <= iv_delivery_date ) THEN            -- �艿�K�p�J�n <= �[�i��
---- ******************** 2009/06/05 Var.1.9 T.Tominaga MOD START  ******************************************
--            IF ( lt_plice_new < lt_standard_unit_price ) THEN      -- �艿(�V) < ��P��
--              lt_confirmation := lv_check_mark;
--            ELSE
--              lt_confirmation := NULL;
--            END IF;
----
---- ******************** 2009/06/05 Var.1.9 T.Tominaga MOD START  ******************************************
----          ELSIF ( lt_st_date < iv_delivery_date ) THEN             -- �艿�K�p�J�n < �[�i��
--          ELSIF ( lt_st_date > iv_delivery_date ) THEN             -- �艿�K�p�J�n > �[�i��
---- ******************** 2009/06/05 Var.1.9 T.Tominaga MOD START  ******************************************
--            IF ( lt_plice_old < lt_standard_unit_price ) THEN      -- ���艿 < ��P��
--              lt_confirmation := lv_check_mark;
--            ELSE
--              lt_confirmation := NULL;
--            END IF;
----
--          ELSE
--            lt_confirmation := NULL;
--          END IF;
--
        ELSE
          NULL;
-- ******************** 2009/07/13 Var.1.13 T.Tominaga MOD END    *****************************************
        END IF;
--
-- ******************** 2009/07/13 Var.1.13 T.Tominaga ADD START  *****************************************
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
        IF ( gt_disc_item_tab.EXISTS(lt_get_sale_data(in_no).item_code) ) THEN
        -- �Ώۃf�[�^���l�����i�ڂ̏ꍇ
          lt_confirmation := NULL;
        ELSE
-- ******* 2010/01/07 1.20 N.Maeda ADD  END  ****** --
          -- �m�F���ڂ̕ҏW
          IF ( lt_standard_unit_price < lt_business_cost ) THEN    -- ��P�� < �c�ƌ���
            lt_confirmation := lv_check_mark;
--
          ELSIF ( lt_st_date <= iv_delivery_date ) THEN            -- �艿�K�p�J�n <= �[�i��
            IF ( lt_plice_new < lt_standard_unit_price ) THEN      -- �艿(�V) < ��P��
              lt_confirmation := lv_check_mark;
            ELSE
              lt_confirmation := NULL;
            END IF;
--
          ELSIF ( lt_st_date > iv_delivery_date ) THEN             -- �艿�K�p�J�n > �[�i��
            IF ( lt_plice_old < lt_standard_unit_price ) THEN      -- ���艿 < ��P��
              lt_confirmation := lv_check_mark;
            ELSE
              lt_confirmation := NULL;
            END IF;
--
          ELSE
            lt_confirmation := NULL;
          END IF;
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
        END IF;
-- ******* 2010/01/07 1.20 N.Maeda ADD  END  ****** --
-- ******************** 2009/07/13 Var.1.13 T.Tominaga ADD END    *****************************************
--
        -- ���l����
        IF ( lt_st_date <= iv_delivery_date ) THEN
          lt_set_plice := lt_plice_new_no_tax;
        ELSE
          lt_set_plice := lt_plice_old_no_tax;
        END IF;
--
-- ******* 2010/01/07 1.20 N.Maeda ADD START ****** --
        IF ( gt_disc_item_tab.EXISTS(lt_get_sale_data(in_no).item_code) ) THEN
        -- �Ώۃf�[�^���l�����i�ڂ̏ꍇ
          -- ����
          gt_dlv_chk_list(ln_num).quantity                     := NULL;
          -- ����
          gt_dlv_chk_list(ln_num).ploce                        := NULL;
          -- �J�[�h���z
          gt_dlv_chk_list(ln_num).card_amount                  := NULL;
        ELSE
          -- ����
          gt_dlv_chk_list(ln_num).quantity                     := lt_get_sale_data(in_no).quantity;
          -- ����
          gt_dlv_chk_list(ln_num).ploce                        := lt_set_plice;
          -- �J�[�h���z
          gt_dlv_chk_list(ln_num).card_amount                  := lt_get_sale_data(in_no).card_amount;
        END IF;
-- ******* 2010/01/07 1.20 N.Maeda ADD  END  ****** --
        -- �Ώۓ��t
        gt_dlv_chk_list(ln_num).target_date                  := lt_get_sale_data(in_no).target_date;
        -- ���_�R�[�h
        gt_dlv_chk_list(ln_num).base_code                    := lt_get_sale_data(in_no).base_code;
        -- ���_����
        gt_dlv_chk_list(ln_num).base_name                    := lt_get_sale_data(in_no).base_name;
        -- �c�ƈ��R�[�h
        gt_dlv_chk_list(ln_num).employee_num                 := lt_get_sale_data(in_no).employee_num;
        -- �c�ƈ�����
        gt_dlv_chk_list(ln_num).employee_name                := lt_get_sale_data(in_no).employee_name;
        -- �O���[�v�ԍ�
        gt_dlv_chk_list(ln_num).group_code                   := lt_get_sale_data(in_no).group_code;
        -- �O���[�v������
        gt_dlv_chk_list(ln_num).group_in_sequence            := lt_get_sale_data(in_no).group_in_sequence;
        -- �`�[�ԍ�
        gt_dlv_chk_list(ln_num).entry_number                 := lt_get_sale_data(in_no).invoice_no;
        -- �[�i��
        gt_dlv_chk_list(ln_num).dlv_date                     := lt_get_sale_data(in_no).dlv_date;
        -- �ڋq�R�[�h
        gt_dlv_chk_list(ln_num).party_num                    := lt_get_sale_data(in_no).party_num;
        -- �ڋq��
        gt_dlv_chk_list(ln_num).customer_name                := lt_get_sale_data(in_no).customer_name;
        -- ���͋敪
        gt_dlv_chk_list(ln_num).input_class                  := lt_get_sale_data(in_no).input_class;
        -- ���ю҃R�[�h
        gt_dlv_chk_list(ln_num).performance_by_code          := lt_get_sale_data(in_no).performance_by_code;
        -- ���юҖ�
        gt_dlv_chk_list(ln_num).performance_by_name          := lt_get_sale_data(in_no).performance_by_name;
        -- �J�[�h����敪
        gt_dlv_chk_list(ln_num).card_sale_class              := lt_get_sale_data(in_no).card_sale_class;
        -- ����z
        gt_dlv_chk_list(ln_num).sudstance_total_amount       := lt_get_sale_data(in_no).sudstance_total_amount;
        -- ����l���z
        gt_dlv_chk_list(ln_num).sale_discount_amount         := lt_get_sale_data(in_no).sale_discount_amount;
        -- ����ŋ��z���v
        gt_dlv_chk_list(ln_num).consumption_tax_total_amount := lt_get_sale_data(in_no).consumption_tax_total_amount;
        -- ����ŋ敪�i�}�X�^)
        gt_dlv_chk_list(ln_num).consumption_tax_class_mst    := lt_get_sale_data(in_no).consumption_tax_class_mst;
        -- �`�[���ރR�[�h
        gt_dlv_chk_list(ln_num).invoice_classification_code  := lt_get_sale_data(in_no).invoice_classification_code;
        -- �`�[�敪
        gt_dlv_chk_list(ln_num).invoice_class                := lt_get_sale_data(in_no).invoice_class;
        -- ����敪
        gt_dlv_chk_list(ln_num).sale_class                   := lt_get_sale_data(in_no).sale_class;
        -- �i�ڃR�[�h
        gt_dlv_chk_list(ln_num).item_code                    := lt_get_sale_data(in_no).item_code;
        -- ���i��
        gt_dlv_chk_list(ln_num).item_name                    := lt_get_sale_data(in_no).item_name;
-- ******* 2010/01/07 1.20 N.Maeda DEL START ****** --
--        -- ����
--        gt_dlv_chk_list(ln_num).quantity                     := lt_get_sale_data(in_no).quantity;
-- ******* 2010/01/07 1.20 N.Maeda DEL  END  ****** --
        -- ���P��
        gt_dlv_chk_list(ln_num).wholesale_unit_ploce         := lt_get_sale_data(in_no).wholesale_unit_ploce;
-- **
        -- �m�F
        gt_dlv_chk_list(ln_num).confirmation                 := lt_confirmation;
        -- ����ŋ敪�i����)
        gt_dlv_chk_list(ln_num).consum_tax_calss_entered     := lt_get_sale_data(in_no).consum_tax_calss_entered;
-- ******* 2010/01/07 1.20 N.Maeda DEL START ****** --
--        -- ����
--        gt_dlv_chk_list(ln_num).ploce                        := lt_set_plice;
----        gt_dlv_chk_list(ln_num).ploce                        := lt_get_sale_data(in_no).ploce;
--        -- �J�[�h���z
--        gt_dlv_chk_list(ln_num).card_amount                  := lt_get_sale_data(in_no).card_amount;
-- ******* 2010/01/07 1.20 N.Maeda DEL  END  ****** --
        -- �R����
        gt_dlv_chk_list(ln_num).column_no                    := lt_get_sale_data(in_no).column_no;
        -- HC
        gt_dlv_chk_list(ln_num).h_and_c                      := lt_get_sale_data(in_no).h_and_c;
        -- �����敪
        gt_dlv_chk_list(ln_num).payment_class                := lt_get_sale_data(in_no).payment_class;
        -- �����z
        gt_dlv_chk_list(ln_num).payment_amount               := lt_get_sale_data(in_no).payment_amount;
        -- �쐬��
        gt_dlv_chk_list(ln_num).created_by                   := cn_created_by;
        -- �쐬��
        gt_dlv_chk_list(ln_num).creation_date                := cd_creation_date;
        -- �ŏI�X�V��
        gt_dlv_chk_list(ln_num).last_updated_by              := cn_last_updated_by;
        -- �ŏI�X�V��
        gt_dlv_chk_list(ln_num).last_update_date             := cd_last_update_date;
        -- �ŏI�X�V���O�C��
        gt_dlv_chk_list(ln_num).last_update_login            := cn_last_update_login;
        -- �v���h�c
        gt_dlv_chk_list(ln_num).request_id                   := cn_request_id;
        -- �ݶ��ĥ��۸��ѥ���ع����ID
        gt_dlv_chk_list(ln_num).program_application_id       := cn_program_application_id;
        -- �ݶ��ĥ��۸���ID
        gt_dlv_chk_list(ln_num).program_id                   := cn_program_id;
        -- ��۸��эX�V��
        gt_dlv_chk_list(ln_num).program_update_date          := cd_program_update_date;
--
-- **************** 2009/12/12 1.18 N.Maeda ADD START **************** --
        -- �K�⎞��
        gt_dlv_chk_list(ln_num).visit_time                := TO_CHAR(lt_get_sale_data(in_no).hht_dlv_input_date,cv_fmt_time_default);
        -- ���הԍ�
        gt_dlv_chk_list(ln_num).dlv_invoice_line_number   := lt_get_sale_data(in_no).dlv_invoice_line_number;
-- **************** 2009/12/12 1.18 N.Maeda ADD  END  **************** --
-- 2011/03/07 Ver.1.21 S.Ochiai ADD Start
        gt_dlv_chk_list(ln_num).order_number              := lt_get_sale_data(in_no).order_number;
-- 2011/03/07 Ver.1.21 S.Ochiai ADD End
/*        IF ( lt_get_sale_data(in_no).payment_amount IS NOT NULL
          AND
             lt_invoice_num.EXISTS( lt_get_sale_data(in_no).invoice_no ) = FALSE ) THEN
--
          -- �z��ԍ��擾
          ln_num := ln_num + 1;
--
          --  ���R�[�hID�擾
          SELECT
            xxcos_rep_dlv_chk_list_s01.nextval
          INTO
            gt_dlv_chk_list(ln_num).record_id
          FROM
            DUAL;
--
          -- �Ώۓ��t
          gt_dlv_chk_list(ln_num).target_date                  := lt_get_sale_data(in_no).target_date;
          -- ���_�R�[�h
          gt_dlv_chk_list(ln_num).base_code                    := lt_get_sale_data(in_no).base_code;
          -- ���_����
          gt_dlv_chk_list(ln_num).base_name                    := lt_get_sale_data(in_no).base_name;
          -- �c�ƈ��R�[�h
          gt_dlv_chk_list(ln_num).employee_num                 := lt_get_sale_data(in_no).employee_num;
          -- �c�ƈ�����
          gt_dlv_chk_list(ln_num).employee_name                := lt_get_sale_data(in_no).employee_name;
          -- �O���[�v�ԍ�
          gt_dlv_chk_list(ln_num).group_code                   := lt_get_sale_data(in_no).group_code;
          -- �O���[�v������
          gt_dlv_chk_list(ln_num).group_in_sequence            := lt_get_sale_data(in_no).group_in_sequence;
          -- �`�[�ԍ�
          gt_dlv_chk_list(ln_num).entry_number                 := lt_get_sale_data(in_no).invoice_no;
          -- �[�i��
          gt_dlv_chk_list(ln_num).dlv_date                     := lt_get_sale_data(in_no).dlv_date;
          -- �ڋq�R�[�h
          gt_dlv_chk_list(ln_num).party_num                    := lt_get_sale_data(in_no).party_num;
          -- �ڋq��
          gt_dlv_chk_list(ln_num).customer_name                := lt_get_sale_data(in_no).customer_name;
          -- ���͋敪
          gt_dlv_chk_list(ln_num).input_class                  := lt_get_sale_data(in_no).input_class;
          -- ���ю҃R�[�h
          gt_dlv_chk_list(ln_num).performance_by_code          := lt_get_sale_data(in_no).performance_by_code;
          -- ���юҖ�
          gt_dlv_chk_list(ln_num).performance_by_name          := lt_get_sale_data(in_no).performance_by_name;
          -- �J�[�h����敪
          gt_dlv_chk_list(ln_num).card_sale_class              := lt_get_sale_data(in_no).card_sale_class;
          -- ����z
          gt_dlv_chk_list(ln_num).sudstance_total_amount       := lt_get_sale_data(in_no).sudstance_total_amount;
          -- ����l���z
          gt_dlv_chk_list(ln_num).sale_discount_amount         := lt_get_sale_data(in_no).sale_discount_amount;
          -- ����ŋ��z���v
          gt_dlv_chk_list(ln_num).consumption_tax_total_amount := lt_get_sale_data(in_no).consumption_tax_total_amount;
          -- ����ŋ敪�i�}�X�^)
          gt_dlv_chk_list(ln_num).consumption_tax_class_mst    := lt_get_sale_data(in_no).consumption_tax_class_mst;
          -- �`�[���ރR�[�h
          gt_dlv_chk_list(ln_num).invoice_classification_code  := lt_get_sale_data(in_no).invoice_classification_code;
          -- �`�[�敪
          gt_dlv_chk_list(ln_num).invoice_class                := lt_get_sale_data(in_no).invoice_class;
          -- ����敪
          gt_dlv_chk_list(ln_num).sale_class                   := NULL;
          -- �i�ڃR�[�h
          gt_dlv_chk_list(ln_num).item_code                    := NULL;
          -- ���i��
          gt_dlv_chk_list(ln_num).item_name                    := NULL;
          -- ����
          gt_dlv_chk_list(ln_num).quantity                     := 0;
          -- ���P��
          gt_dlv_chk_list(ln_num).wholesale_unit_ploce         := 0;
          -- �m�F
          gt_dlv_chk_list(ln_num).confirmation                 := NULL;
          -- ����ŋ敪�i����)
          gt_dlv_chk_list(ln_num).consum_tax_calss_entered     := lt_get_sale_data(in_no).consum_tax_calss_entered;
          -- ����
          gt_dlv_chk_list(ln_num).ploce                        := 0;
          -- �J�[�h���z
          gt_dlv_chk_list(ln_num).card_amount                  := 0;
          -- �R����
          gt_dlv_chk_list(ln_num).column_no                    := NULL;
          -- HC
          gt_dlv_chk_list(ln_num).h_and_c                      := NULL;
          -- �����敪
          gt_dlv_chk_list(ln_num).payment_class                := lt_get_sale_data(in_no).payment_class;
          -- �����z
          gt_dlv_chk_list(ln_num).payment_amount               := lt_get_sale_data(in_no).payment_amount;
          -- �쐬��
          gt_dlv_chk_list(ln_num).created_by                   := cn_created_by;
          -- �쐬��
          gt_dlv_chk_list(ln_num).creation_date                := cd_creation_date;
          -- �ŏI�X�V��
          gt_dlv_chk_list(ln_num).last_updated_by              := cn_last_updated_by;
          -- �ŏI�X�V��
          gt_dlv_chk_list(ln_num).last_update_date             := cd_last_update_date;
          -- �ŏI�X�V���O�C��
          gt_dlv_chk_list(ln_num).last_update_login            := cn_last_update_login;
          -- �v���h�c
          gt_dlv_chk_list(ln_num).request_id                   := cn_request_id;
          -- �ݶ��ĥ��۸��ѥ���ع����ID
          gt_dlv_chk_list(ln_num).program_application_id       := cn_program_application_id;
          -- �ݶ��ĥ��۸���ID
          gt_dlv_chk_list(ln_num).program_id                   := cn_program_id;
          -- ��۸��эX�V��
          gt_dlv_chk_list(ln_num).program_update_date          := cd_program_update_date;
--
          -- �`�[�ԍ��i�[
          lt_invoice_num( lt_get_sale_data(in_no).invoice_no ) := in_no;
--
        END IF;*/
--
      END LOOP;
--
      -- �Ώی����Z�b�g
      gn_target_cnt := ln_target_cnt + lt_invoice_num.COUNT;
--
      -- �[�i���`�F�b�N���X�g���[�N�e�[�u���֓o�^
      BEGIN
        FORALL into_no IN INDICES OF gt_dlv_chk_list SAVE EXCEPTIONS
          INSERT INTO
            xxcos_rep_dlv_chk_list
          VALUES
            gt_dlv_chk_list(into_no);
--
      EXCEPTION
        WHEN OTHERS THEN
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_check_list_work_table );
          gv_tkn2   := NULL;
          lv_errmsg := xxccp_common_pkg.get_msg(
                                                 cv_application
                                                ,cv_msg_insert_data_err
                                                ,cv_tkn_table
                                                ,gv_tkn1
                                                ,cv_tkn_key_data
                                                ,gv_tkn2
                                               );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
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
  END sales_per_data_entry;
--
  /**********************************************************************************
   * Procedure Name   : money_data_entry
   * Description      : �����f�[�^���o(A-5)�A�[�i�f�[�^�o�^�i�����f�[�^�j(A-6)
   ***********************************************************************************/
  PROCEDURE money_data_entry(
    iv_delivery_date      IN      VARCHAR2,         -- �[�i��
    iv_delivery_base_code IN      VARCHAR2,         -- ���_
    iv_dlv_by_code        IN      VARCHAR2,         -- �c�ƈ�
    iv_hht_invoice_no     IN      VARCHAR2,         -- HHT�`�[No
    ov_errbuf             OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT     VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT     VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'money_data_entry'; -- �v���O������
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
    ld_delivery_date  DATE;       -- �p�����[�^�ϊ���̔[�i��
-- 2009/12/17 Ver.1.19 Add Start
    ln_payment_cnt         NUMBER;    -- �擾��������
    ln_no_dlv_data         NUMBER;    -- �[�i�f�[�^�L���t���O
-- 2009/12/17 Ver.1.19 Add End
--
    -- *** ���[�J���E�J�[�\�� ***
-- 2009/12/17 Ver.1.19 Add Start
    -- �����f�[�^���o
    CURSOR get_payment_cur (
      id_delivery_date  IN  DATE        -- �[�i��
    )
    IS
      SELECT  xrdcl.rowid         row_id
             ,xrdcl.employee_num  employee_num                        -- �c�ƈ��R�[�h
             ,xrdcl.dlv_date      dlv_date                            -- �[�i��
             ,xrdcl.party_num     party_num                           -- �ڋq�R�[�h
             ,xrdcl.entry_number  entry_number                        -- �`�[�ԍ�
             ,xrdcl.base_code     base_code                           -- ���_�R�[�h
             ,xrdcl.target_date   target_date                         -- �Ώۓ���
             ,NULL                dlv_card_sale_class                 -- �J�[�h����敪
             ,NULL                dlv_input_class                     -- ���͋敪
             ,NULL                dlv_invoice_class                   -- �`�[�敪
             ,NULL                dlv_invoice_class_code              -- �`�[�敪�R�[�h
             ,NULL                dlv_visit_time                      -- �K�����
             ,NULL                dlv_dlv_date                        -- �[�i��
      FROM    xxcos_rep_dlv_chk_list    xrdcl           -- �[�i���`�F�b�N���X�g���[���[�N�e�[�u��
             ,fnd_lookup_values         flv             -- ���b�N�A�b�v
      WHERE  xrdcl.request_id      = cn_request_id
      AND    xrdcl.payment_class   = flv.meaning
      AND    flv.lookup_type       = ct_qck_money_class
      AND    flv.enabled_flag      = cv_yes
      AND    flv.language          = ct_lang
      AND    id_delivery_date      >= NVL( flv.start_date_active, id_delivery_date )
      AND    id_delivery_date      <= NVL( flv.end_date_active, id_delivery_date )
      ;
      --
-- 2009/12/17 Ver.1.19 Add Start
--
    -- *** ���[�J���E���R�[�h ***
-- 2009/12/17 Ver.1.19 Add Start
    TYPE g_payment_data_ttype IS TABLE OF get_payment_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    gt_payment_tbl            g_payment_data_ttype;
-- 2009/12/17 Ver.1.19 Add End
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
    --========================================================
    --�����f�[�^���o(A-5)�A�[�i�f�[�^�o�^�i�����f�[�^�j(A-6)
    --========================================================
    ld_delivery_date  :=  TO_DATE(iv_delivery_date, cv_fmt_date_default);
--
    BEGIN
      INSERT INTO
        xxcos_rep_dlv_chk_list
          (
              record_id                           -- ���R�[�hID
             ,target_date                         -- �Ώۓ��t
             ,base_code                           -- ���_�R�[�h
             ,base_name                           -- ���_����
             ,employee_num                        -- �c�ƈ��R�[�h
             ,employee_name                       -- �c�ƈ�����
             ,group_code                          -- �O���[�v�ԍ�
             ,group_in_sequence                   -- �O���[�v������
             ,entry_number                        -- �`�[�ԍ�
             ,dlv_date                            -- �[�i��
             ,party_num                           -- �ڋq�R�[�h
             ,customer_name                       -- �ڋq��
             ,input_class                         -- ���͋敪
             ,performance_by_code                 -- ���ю҃R�[�h
             ,performance_by_name                 -- ���юҖ�
             ,card_sale_class                     -- �J�[�h����敪
             ,sudstance_total_amount              -- ����z
             ,sale_discount_amount                -- ����l���z
             ,consumption_tax_total_amount        -- ����ŋ��z���v
             ,consumption_tax_class_mst           -- ����ŋ敪�i�}�X�^�j
             ,invoice_classification_code         -- �`�[���ރR�[�h
             ,invoice_class                       -- �`�[�敪
             ,sale_class                          -- ����敪
             ,item_code                           -- �i�ڃR�[�h
             ,item_name                           -- ���i��
             ,quantity                            -- ����
             ,wholesale_unit_ploce                -- ���P��
             ,confirmation                        -- �m�F
             ,consum_tax_calss_entered            -- ����ŋ敪�i���́j
             ,ploce                               -- ����
             ,card_amount                         -- �J�[�h���z
             ,column_no                           -- �R����
             ,h_and_c                             -- H/C
             ,payment_class                       -- �����敪
             ,payment_amount                      -- �����z
             ,created_by                          -- �쐬��
             ,creation_date                       -- �쐬��
             ,last_updated_by                     -- �ŏI�X�V��
             ,last_update_date                    -- �ŏI�X�V��
             ,last_update_login                   -- �ŏI�X�V���O�C��
             ,request_id                          -- �v���h�c
             ,program_application_id              -- �ݶ��ĥ��۸��ѥ���ع����ID
             ,program_id                          -- �ݶ��ĥ��۸���ID
             ,program_update_date                 -- ��۸��эX�V��
          )
        SELECT
-- 2009/09/01 Ver.1.15 M.Sano Add Start
           /*+
             leading ( riv.jrrx_n )
             index   ( riv.jrgm_n jtf_rs_group_members_n2)
             index   ( riv.jrgb_n jtf_rs_groups_b_u1 )
             index   ( riv.jrrx_n xxcso_jrre_n02 )
             use_nl  ( riv.papf_n )
             use_nl  ( riv.pept_n )
             use_nl  ( riv.paaf_n )
             use_nl  ( riv.jrgm_n )
             use_nl  ( riv.jrgb_n )
             leading ( riv.jrrx_o )
             index   ( riv.jrrx_o xxcso_jrre_n02 )
             index   ( riv.jrgm_o jtf_rs_group_members_n2)
             index   ( riv.jrgb_o jtf_rs_groups_b_u1 )
             use_nl  ( riv.papf_o )
             use_nl  ( riv.pept_o )
             use_nl  ( riv.paaf_o )
             use_nl  ( riv.jrgm_o )
             use_nl  ( riv.jrgb_o )
           */
-- 2009/09/01 Ver.1.15 M.Sano Add End
           xxcos_rep_dlv_chk_list_s01.nextval   -- ���R�[�hID
          ,pay.payment_date                       -- �Ώۓ��t
          ,pay.base_code                          -- ���_�R�[�h
          ,SUBSTRB( parb.party_name, 1, 40 )      -- ���_����
          ,riv.employee_number                    -- �c�ƈ��R�[�h
-- ************************ 2009/09/30 S.Miyakoshi Var1.16 MOD START ************************ --
--          ,riv.employee_name                      -- �c�ƈ�����
          ,SUBSTRB( riv.employee_name, 1, 40 )    -- �c�ƈ�����
-- ************************ 2009/09/30 S.Miyakoshi Var1.16 MOD  END  ************************ --
          ,riv.group_code                         -- �O���[�v�ԍ�
          ,riv.group_in_sequence                  -- �O���[�v������
          ,pay.hht_invoice_no                     -- �`�[�ԍ�
          ,pay.payment_date                       -- �[�i��
          ,pay.customer_number                    -- �ڋq�R�[�h
          ,SUBSTRB( parc.party_name, 1, 40 )      -- �ڋq��
          ,NULL                                   -- ���͋敪
          ,NULL                                   -- ���ю҃R�[�h
          ,NULL                                   -- ���юҖ�
          ,NULL                                   -- �J�[�h����敪
          ,0                                      -- ����z
          ,0                                      -- ����l���z
          ,0                                      -- ����ŋ��z���v
          ,NULL                                   -- ����ŋ敪�i�}�X�^�j
          ,NULL                                   -- �`�[���ރR�[�h
          ,NULL                                   -- �`�[�敪
          ,NULL                                   -- ����敪
          ,NULL                                   -- �i�ڃR�[�h
          ,NULL                                   -- ���i��
-- ******* 2010/01/07 1.20 N.Maeda MOD START ****** --
--          ,0                                      -- ����
          ,NULL                                      -- ����
-- ******* 2010/01/07 1.20 N.Maeda MOD START ****** --
          ,0                                      -- ���P��
          ,NULL                                   -- �m�F
          ,NULL                                   -- ����ŋ敪�i���́j
-- ******* 2010/01/07 1.20 N.Maeda MOD START ****** --
--          ,0                                      -- ����
          ,NULL                                      -- ����
-- ******* 2010/01/07 1.20 N.Maeda MOD START ****** --
-- ******* 2010/01/07 1.20 N.Maeda MOD START ****** --
--          ,0                                      -- �J�[�h���z----
          ,NULL                                      -- �J�[�h���z
-- ******* 2010/01/07 1.20 N.Maeda MOD START ****** --
          ,NULL                                   -- �R����
          ,NULL                                   -- H/C
          ,pacl.meaning                           -- �����敪
          ,pay.payment_amount                     -- �����z
          ,cn_created_by                          -- �쐬��
          ,cd_creation_date                       -- �쐬��
          ,cn_last_updated_by                     -- �ŏI�X�V��
          ,cd_last_update_date                    -- �ŏI�X�V��
          ,cn_last_update_login                   -- �ŏI�X�V���O�C��
          ,cn_request_id                          -- �v���h�c
          ,cn_program_application_id              -- �ݶ��ĥ��۸��ѥ���ع����ID
          ,cn_program_id                          -- �ݶ��ĥ��۸���ID
          ,cd_program_update_date                 -- ��۸��эX�V��
        FROM
           xxcos_payment            pay           -- �����e�[�u��
          ,hz_cust_accounts         base          -- �ڋq�}�X�^_���_
          ,hz_cust_accounts         cust          -- �ڋq�}�X�^_�ڋq
          ,hz_parties               parb          -- �p�[�e�B_���_
          ,hz_parties               parc          -- �p�[�e�B_�ڋq
          ,xxcos_rs_info_v          riv           -- �c�ƈ����view
          ,xxcos_salesreps_v        salv          -- �S���c�ƈ�view
          ,xxcmm_cust_accounts      cuac          -- �ڋq�ǉ����
          ,(
            SELECT  look_val.lookup_code        lookup_code
                   ,look_val.meaning            meaning
            FROM    fnd_lookup_values           look_val
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--                   ,fnd_lookup_types_tl         types_tl
--                   ,fnd_lookup_types            types
--                   ,fnd_application_tl          appl
--                   ,fnd_application             app
--            WHERE   app.application_short_name = cv_application          -- XXCOS
--            AND     look_val.lookup_type       = ct_qck_money_class      -- XXCOS1_RECEIPT_MONEY_CLASS
            WHERE   look_val.lookup_type       = ct_qck_money_class      -- XXCOS1_RECEIPT_MONEY_CLASS
-- 2009/09/01 Ver.1.15 M.Sano Mod End
            AND     look_val.enabled_flag      = cv_yes                  -- Y
            AND     ld_delivery_date          >= NVL( look_val.start_date_active, ld_delivery_date )
            AND     ld_delivery_date          <= NVL( look_val.end_date_active, ld_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--            AND     types_tl.language          = USERENV( 'LANG' )
--            AND     look_val.language          = USERENV( 'LANG' )
--            AND     appl.language              = USERENV( 'LANG' )
--            AND     appl.application_id        = types.application_id
--            AND     app.application_id         = appl.application_id
--            AND     types_tl.lookup_type       = look_val.lookup_type
--            AND     types.lookup_type          = types_tl.lookup_type
--            AND     types.security_group_id    = types_tl.security_group_id
--            AND     types.view_application_id  = types_tl.view_application_id
            AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
           )  pacl   -- �����敪
        WHERE
          pay.payment_date       = ld_delivery_date
        AND pay.base_code        = iv_delivery_base_code
        AND salv.account_number  = pay.customer_number
        AND pay.payment_date    >= NVL( salv.effective_start_date, pay.payment_date )
        AND pay.payment_date    <= NVL( salv.effective_end_date, pay.payment_date )
        AND riv.base_code        = pay.base_code
        AND riv.employee_number  = NVL( iv_dlv_by_code, salv.employee_number )
-- 2009/11/27 Ver.1.17 K.Atsushiba Add Start
        AND ( iv_dlv_by_code IS NULL OR iv_dlv_by_code  = salv.employee_number )
-- 2009/11/27 Ver.1.17 K.Atsushiba Add End
        AND pay.payment_date    >= NVL( riv.effective_start_date, pay.payment_date )
        AND pay.payment_date    <= NVL( riv.effective_end_date, pay.payment_date )
        AND pay.payment_date    >= riv.per_effective_start_date
        AND pay.payment_date    <= riv.per_effective_end_date
        AND pay.payment_date    >= riv.paa_effective_start_date
        AND pay.payment_date    <= riv.paa_effective_end_date
        AND pay.hht_invoice_no   = NVL( iv_hht_invoice_no, pay.hht_invoice_no )
        AND pay.payment_class    = pacl.lookup_code
--        AND NOT EXISTS
--          (
--            SELECT
--              ROWID
--            FROM
--              xxcos_sales_exp_headers  sale       -- �̔����уw�b�_�e�[�u��
--            WHERE
--              sale.dlv_invoice_number      = pay.hht_invoice_no
--            AND sale.delivery_date         = pay.payment_date
--            AND sale.ship_to_customer_code = pay.customer_number
--            AND sale.sales_base_code       = pay.base_code
--            AND ROWNUM = 1
--          )
        AND pay.base_code            = base.account_number
        AND base.customer_class_code = ct_cust_class_base
        AND base.party_id            = parb.party_id
        AND pay.customer_number      = cust.account_number
-- ******************** 2009/05/01 Var.1.6 N.Maeda MOD START  ******************************************
--      AND cust.customer_class_code = ct_cust_class_customer
        AND cust.customer_class_code   IN ( ct_cust_class_customer , ct_cust_class_customer_u )
-- ******************** 2009/05/01 Var.1.6 N.Maeda MOD  END   ******************************************
        AND cust.party_id            = parc.party_id
        AND cust.cust_account_id     = cuac.customer_id                -- �ڋq�}�X�^_�ڋq���ڋq�ǉ����
        AND NOT EXISTS
          (
             SELECT  look_val.attribute1         vd_gyotai
             FROM    fnd_lookup_values           look_val
             WHERE   look_val.lookup_type       = ct_qck_gyotai_sho_mst1   -- XXCOS1_GYOTAI_SHO_MST_002_A05
             AND     look_val.enabled_flag      = cv_yes                  -- Y
             AND     ld_delivery_date          >= NVL( look_val.start_date_active, ld_delivery_date )
             AND     ld_delivery_date          <= NVL( look_val.end_date_active, ld_delivery_date )
-- 2009/09/01 Ver.1.15 M.Sano Mod Start
--             AND     look_val.language          = USERENV( 'LANG' )
             AND     look_val.language          = ct_lang
-- 2009/09/01 Ver.1.15 M.Sano Mod End
             AND     look_val.meaning           = cuac.business_low_type
          )  -- �Ƒԏ����ޓ���}�X�^
        ;
--
      -- �Ώی����擾
      gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_check_list_work_table );
        gv_tkn2   := NULL;
        lv_errmsg := xxccp_common_pkg.get_msg(
                                                cv_application
                                               ,cv_msg_insert_data_err
                                               ,cv_tkn_table
                                               ,gv_tkn1
                                               ,cv_tkn_key_data
                                               ,gv_tkn2
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
-- 2009/12/17 Ver.1.19 Add Start
  -- �o�^���������f�[�^���o
  -- �J�[�\���E�I�[�v��
  OPEN get_payment_cur (
           id_delivery_date  => ld_delivery_date             -- �[�i��
       );
  --
  -- ���R�[�h�Ǎ�
  FETCH get_payment_cur BULK COLLECT INTO gt_payment_tbl;
  --
  -- ���R�[�h�����擾
  ln_payment_cnt := gt_payment_tbl.COUNT;
  --
  IF ( ln_payment_cnt > 0 ) THEN
    <<payment_loop>>
    FOR ln_idx IN 1..ln_payment_cnt LOOP
      ln_no_dlv_data := 0;
      -- �����f�[�^������ꍇ
      BEGIN
        -- ����ڋq�A�[�i�`�[�ԍ��ŁA��L�Ŏ擾�������������ōŏ��̖K��������擾
        SELECT MIN(xrdcl.visit_time)
        INTO   gt_payment_tbl(ln_idx).dlv_visit_time
        FROM   xxcos_rep_dlv_chk_list    xrdcl                -- �[�i���`�F�b�N���X�g���[���[�N�e�[�u��
        WHERE  xrdcl.request_id      = cn_request_id
        AND    xrdcl.target_date     = gt_payment_tbl(ln_idx).target_date       -- �Ώۓ��t
        AND    xrdcl.base_code       = gt_payment_tbl(ln_idx).base_code         -- ���_�R�[�h
        AND    xrdcl.employee_num    = gt_payment_tbl(ln_idx).employee_num      -- �c�ƈ��R�[�h
        AND    xrdcl.entry_number    = gt_payment_tbl(ln_idx).entry_number      -- �`�[�ԍ�
        AND    xrdcl.party_num       = gt_payment_tbl(ln_idx).party_num         -- �ڋq�R�[�h
        AND    xrdcl.visit_time      IS NOT NULL
        ;
        -- ����ڋq�A�[�i�`�[�ԍ��ōŏ��̌��������擾
        SELECT MIN(xrdcl.dlv_date)
        INTO   gt_payment_tbl(ln_idx).dlv_dlv_date
        FROM   xxcos_rep_dlv_chk_list    xrdcl                -- �[�i���`�F�b�N���X�g���[���[�N�e�[�u��
        WHERE  xrdcl.request_id      = cn_request_id
        AND    xrdcl.target_date     = gt_payment_tbl(ln_idx).target_date       -- �Ώۓ��t
        AND    xrdcl.base_code       = gt_payment_tbl(ln_idx).base_code         -- ���_�R�[�h
        AND    xrdcl.employee_num    = gt_payment_tbl(ln_idx).employee_num      -- �c�ƈ��R�[�h
        AND    xrdcl.entry_number    = gt_payment_tbl(ln_idx).entry_number      -- �`�[�ԍ�
        AND    xrdcl.party_num       = gt_payment_tbl(ln_idx).party_num         -- �ڋq�R�[�h
        AND    xrdcl.visit_time      = gt_payment_tbl(ln_idx).dlv_visit_time    -- �K�����
        AND    xrdcl.visit_time      IS NOT NULL
        AND    rownum  = 1
        ;
        --
        SELECT   xrdcl.card_sale_class                          -- �J�[�h����敪
                ,xrdcl.input_class                              -- ���͋敪
                ,xrdcl.invoice_class                            -- �`�[�敪
                ,xrdcl.invoice_classification_code              -- �`�[���ރR�[�h
        INTO     gt_payment_tbl(ln_idx).dlv_card_sale_class
                ,gt_payment_tbl(ln_idx).dlv_input_class
                ,gt_payment_tbl(ln_idx).dlv_invoice_class
                ,gt_payment_tbl(ln_idx).dlv_invoice_class_code
        FROM   xxcos_rep_dlv_chk_list    xrdcl           -- �[�i���`�F�b�N���X�g���[���[�N�e�[�u��
        WHERE  xrdcl.request_id      = cn_request_id                            -- �v��ID
        AND    xrdcl.target_date     = gt_payment_tbl(ln_idx).target_date       -- �Ώۓ��t
        AND    xrdcl.base_code       = gt_payment_tbl(ln_idx).base_code         -- ���_�R�[�h
        AND    xrdcl.employee_num    = gt_payment_tbl(ln_idx).employee_num      -- �c�ƈ��R�[�h
        AND    xrdcl.entry_number    = gt_payment_tbl(ln_idx).entry_number      -- �`�[�ԍ�
        AND    xrdcl.party_num       = gt_payment_tbl(ln_idx).party_num         -- �ڋq�R�[�h
        AND    xrdcl.visit_time      = gt_payment_tbl(ln_idx).dlv_visit_time    -- �K�����
        AND    xrdcl.dlv_date        = gt_payment_tbl(ln_idx).dlv_dlv_date      -- ������
        AND    rownum  = 1
        ;
      EXCEPTION
        WHEN OTHERS THEN
          ln_no_dlv_data := 1;
      END;
      --
      IF ( ln_no_dlv_data = 0 ) THEN
        BEGIN
          UPDATE  xxcos_rep_dlv_chk_list   xrdcl
          SET     xrdcl.card_sale_class              = gt_payment_tbl(ln_idx).dlv_card_sale_class                -- �J�[�h����敪
                 ,xrdcl.input_class                  = gt_payment_tbl(ln_idx).dlv_input_class                    -- ���͋敪
                 ,xrdcl.invoice_class                = gt_payment_tbl(ln_idx).dlv_invoice_class                  -- �`�[�敪
                 ,xrdcl.invoice_classification_code  = gt_payment_tbl(ln_idx).dlv_invoice_class_code             -- �`�[���ރR�[�h
                 ,xrdcl.visit_time                   = gt_payment_tbl(ln_idx).dlv_visit_time                     -- �K�����
                 ,xrdcl.dlv_date                     = gt_payment_tbl(ln_idx).dlv_dlv_date                       -- �[�i��
          WHERE  xrdcl.rowid                         = gt_payment_tbl(ln_idx).row_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
               iv_application  => cv_application
              ,iv_name         => cv_msg_payment_update_err
              ,iv_token_name1  => cv_tkn_hht_invoice_no                          -- �[�i�`�[�ԍ�
              ,iv_token_value1 => gt_payment_tbl(ln_idx).entry_number
              ,iv_token_name2  => cv_tkn_customer_number                              -- �ڋq
              ,iv_token_value2 => gt_payment_tbl(ln_idx).party_num
              ,iv_token_name3  => cv_tkn_payment_date                               -- ������
              ,iv_token_value3 => TO_CHAR(gt_payment_tbl(ln_idx).dlv_date,cv_fmt_date_default)
            );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END;
      END IF;
    END LOOP payment_loop;
  END IF;
-- 2009/12/17 Ver.1.19 Add End
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
  END money_data_entry;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF�N��(A-7)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_nodata_msg    VARCHAR2(5000);
    lv_file_name     VARCHAR2(5000);
    lv_api_name      VARCHAR2(5000);
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
    --==================================
    -- 1.����0���p���b�Z�[�W�擾
    --==================================
    lv_nodata_msg := xxccp_common_pkg.get_msg( cv_application, cv_msg_nodata_err );
--
    --�o�̓t�@�C���ҏW
    lv_file_name  := cv_file_id || TO_CHAR( SYSDATE, cv_fmt_date )
                                || TO_CHAR( cn_request_id )
                                || cv_extension_pdf
                                ;
    --==================================
    -- 2.SVF�N��
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
                                          ov_retcode      => lv_retcode,
                                          ov_errbuf       => lv_errbuf,
                                          ov_errmsg       => lv_errmsg,
                                          iv_conc_name    => cv_conc_name,
                                          iv_file_name    => lv_file_name,
                                          iv_file_id      => cv_file_id,
                                          iv_output_mode  => cv_output_mode_pdf,
                                          iv_frm_file     => cv_frm_file,
                                          iv_vrq_file     => cv_vrq_file,
                                          iv_org_id       => NULL,
                                          iv_user_name    => NULL,
                                          iv_resp_name    => NULL,
                                          iv_doc_name     => NULL,
                                          iv_printer_name => NULL,
                                          iv_request_id   => TO_CHAR( cn_request_id ),
                                          iv_nodata_msg   => lv_nodata_msg,
                                          iv_svf_param1   => NULL,
                                          iv_svf_param2   => NULL,
                                          iv_svf_param3   => NULL,
                                          iv_svf_param4   => NULL,
                                          iv_svf_param5   => NULL,
                                          iv_svf_param6   => NULL,
                                          iv_svf_param7   => NULL,
                                          iv_svf_param8   => NULL,
                                          iv_svf_param9   => NULL,
                                          iv_svf_param10  => NULL,
                                          iv_svf_param11  => NULL,
                                          iv_svf_param12  => NULL,
                                          iv_svf_param13  => NULL,
                                          iv_svf_param14  => NULL,
                                          iv_svf_param15  => NULL
                                          );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      --  �Ǘ��җp���b�Z�[�W�ޔ�
      lv_errbuf := SUBSTRB( lv_errmsg || lv_errbuf, 5000 );
--
      --  ���[�U�[�p���b�Z�[�W�擾
      lv_api_name := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_application,
                                             iv_name         => cv_msg_svf_api
                                             );
      lv_errmsg   := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_application,
                                             iv_name         => cv_msg_call_api_err,
                                             iv_token_name1  => cv_tkn_api_name,
                                             iv_token_value1 => lv_api_name
                                             );
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
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : ���[���[�N�e�[�u���f�[�^�폜(A-8)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- �v���O������
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
    --  ���b�N�擾�p
    CURSOR  lock_cur
    IS
      SELECT  rdcl.ROWID
      FROM    xxcos_rep_dlv_chk_list   rdcl
      WHERE   rdcl.request_id = cn_request_id
      FOR UPDATE NOWAIT;
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
    --== ���[���[�N�e�[�u���f�[�^���b�N ==--
    --  ���b�N�p�J�[�\���I�[�v��
    OPEN  lock_cur;
    --  ���b�N�p�J�[�\���N���[�Y
    CLOSE lock_cur;
--
    --== ���[���[�N�e�[�u���f�[�^�폜 ==--
    BEGIN
--
      DELETE FROM
        xxcos_rep_dlv_chk_list  dcl         -- �[�i���`�F�b�N���X�g���[���[�N�e�[�u��
      WHERE
        dcl.request_id = cn_request_id;     -- �v��ID
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �f�[�^�폜�G���[���b�Z�[�W
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_request_id );
        xxcos_common_pkg.makeup_key_info(
                                         ov_errbuf      => lv_errbuf           -- �G���[�E���b�Z�[�W
                                        ,ov_retcode     => lv_retcode          -- ���^�[���E�R�[�h
                                        ,ov_errmsg      => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    => gv_key_info         -- �L�[���
                                        ,iv_item_name1  => gv_tkn1             -- �v��ID
                                        ,iv_data_value1 => cn_request_id
                                        );
--
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_check_list_work_table );
        lv_errmsg := xxccp_common_pkg.get_msg(
                                               cv_application
                                              ,cv_msg_delete_data_err
                                              ,cv_tkn_table
                                              ,gv_tkn1
                                              ,cv_tkn_key_data
                                              ,gv_key_info
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
    -- ���b�N�G���[
    WHEN lock_expt THEN
      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_check_list_work_table );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock_err, cv_tkn_table, gv_tkn1 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
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
  END delete_rpt_wrk_data;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_delivery_date      IN      VARCHAR2,         -- �[�i��
    iv_delivery_base_code IN      VARCHAR2,         -- ���_
    iv_dlv_by_code        IN      VARCHAR2,         -- �c�ƈ�
    iv_hht_invoice_no     IN      VARCHAR2,         -- HHT�`�[No
    ov_errbuf             OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT     VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT     VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
/* 2009/06/19 Ver1.12 Add Start */
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h(SVF���s���ʕێ��p)
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
/* 2009/06/19 Ver1.12 Add End   */
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    --  ===============================
    --  ��������(A-0)
    --  ===============================
    init(
       iv_delivery_date        -- �[�i��
      ,iv_delivery_base_code   -- ���_
      ,iv_dlv_by_code          -- �c�ƈ�
      ,iv_hht_invoice_no       -- HHT�`�[No
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
--
    --  ===============================
    --  �̔����уf�[�^���o(A-3)�A�[�i�f�[�^�o�^�i�̔����сj(A-4)
    --  ===============================
    sales_per_data_entry(
       iv_delivery_date        -- �[�i��
      ,iv_delivery_base_code   -- ���_
      ,iv_dlv_by_code          -- �c�ƈ�
      ,iv_hht_invoice_no       -- HHT�`�[No
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  �����f�[�^���o(A-5)�A�[�i�f�[�^�o�^�i�����f�[�^�j(A-6)
    --  ===============================
    money_data_entry(
       iv_delivery_date        -- �[�i��
      ,iv_delivery_base_code   -- ���_
      ,iv_dlv_by_code          -- �c�ƈ�
      ,iv_hht_invoice_no       -- HHT�`�[No
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �Ώی�����0���ł������ꍇ�A�u����0���p���b�Z�[�W�v���o�͂��܂��B
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_nodata_err );
      FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
      ov_retcode := cv_status_warn;
    END IF;
--
    --  �R�~�b�g���s
    COMMIT;
--
    --  ===============================
    --  SVF�N��(A-7)
    --  ===============================
    execute_svf(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
/* 2009/06/19 Ver1.12 Mod Start */
--    -- �G���[����
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
    --�G���[�ł����[�N�e�[�u�����폜����ׁA�G���[����ێ�
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
/* 2009/06/19 Ver1.12 Mod End   */
--
    --  ===============================
    --  ���[���[�N�e�[�u���f�[�^�폜(A-8)
    --  ===============================
    delete_rpt_wrk_data(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
/* 2009/06/19 Ver1.12 Add Start */
    --�G���[�̏ꍇ�A���[���o�b�N����̂ł����ŃR�~�b�g
    COMMIT;
--
    --SVF���s���ʊm�F
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
/* 2009/06/19 Ver1.12 Add End   */
--
    -- ���[�͑Ώی��������팏���Ƃ���
    gn_normal_cnt := gn_target_cnt;
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
    errbuf                OUT VARCHAR2,         --  �G���[�E���b�Z�[�W  --# �Œ� #
    retcode               OUT VARCHAR2,         --  ���^�[���E�R�[�h    --# �Œ� #
    iv_delivery_date      IN  VARCHAR2,         --  �[�i��
    iv_delivery_base_code IN  VARCHAR2,         --  ���_
    iv_dlv_by_code        IN  VARCHAR2,         --  �c�ƈ�
    iv_hht_invoice_no     IN  VARCHAR2          --  HHT�`�[No
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[)
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
       iv_delivery_date        -- �[�i��
      ,iv_delivery_base_code   -- ���_
      ,iv_dlv_by_code          -- �c�ƈ�
      ,iv_hht_invoice_no       -- HHT�`�[No
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --*** �G���[�o�͂͗v���ɂ���Ďg�������Ă������� ***--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
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
    --
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
END XXCOS002A05R;
/
