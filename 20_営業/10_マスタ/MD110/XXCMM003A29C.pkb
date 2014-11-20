CREATE OR REPLACE PACKAGE BODY XXCMM003A29C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A29C(body)
 * Description      : �ڋq�ꊇ�X�V
 * MD.050           : MD050_CMM_003_A29_�ڋq�ꊇ�X�V
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  cust_data_make_wk      �t�@�C���A�b�v���[�hI/F�e�[�u���擾����(A-1)�E�ڋq�ꊇ�X�V�p���[�N�e�[�u���o�^����(A-2)
 *  rock_and_update_cust   �e�[�u�����b�N����(A-3)�E�ڋq�ꊇ�X�V����(A-4)
 *  close_process          �I������(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   ���� �S��        �V�K�쐬
 *  2009/03/24    1.1   Yutaka.Kuboshima �S�p���p�`�F�b�N������ǉ�
 *  2009/10/23    1.2   Yutaka.Kuboshima ��Q0001350�̑Ή�
 *  2010/01/04    1.3   Yutaka.Kuboshima ��QE_�{�ғ�_00778�̑Ή�
 *  2010/01/27    1.4   Yutaka.Kuboshima ��QE_�{�ғ�_01279,E_�{�ғ�_01280�̑Ή�
 *  2010/02/15    1.5   Yutaka.Kuboshima ��QE_�{�ғ�_01582 �ڋq�X�e�[�^�X�ύX�`�F�b�N�̈����C��
 *                                                          (lv_customer_status -> lv_business_low_type_now)
 *  2010/04/23    1.6   Yutaka.Kuboshima ��QE_�{�ғ�_02295 �o�׌��ۊǏꏊ�̍��ڒǉ�
 *                                                          CSV���ڐ��̃`�F�b�N��ǉ�
 *                                                          ���s�����E�ӂɂ��Z�L�����e�B��ǉ�
 *  2011/11/28    1.7   �E �a�d          ��QE_�{�ғ�_07553�Ή� EDI�֘A�̍��ڒǉ�
 *  2012/04/19    1.8   �m�� �d�l        ��QE_�{�ғ�_09272�Ή� �K��Ώۋ敪�̍��ڒǉ�
 *                                                               ��񗓂��ŏI���ڂɏC��
 *  2013/04/17    1.9   ���� �O��        ��QE_�{�ғ�_09963�ǉ��Ή� ���ڒǉ�����юg�p�����ύX
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  gv_xxcmm_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCMM'; --���b�Z�[�W�敪
  gv_xxccp_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCCP'; --���b�Z�[�W�敪
--
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_org_id        NUMBER(15)  :=  fnd_global.org_id; --org_id
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
  get_csv_err_expt          EXCEPTION; --�ڋq�ꊇ�X�V�pCSV�擾�G���[
  invalid_data_expt         EXCEPTION; --�ڋq�ꊇ�X�V���s����O
--
  update_cust_err_expt      EXCEPTION; --�ڋq�}�X�^�X�V�G���[
  update_party_err_expt     EXCEPTION; --�p�[�e�B�}�X�^�X�V�G���[
  update_csu_err_expt       EXCEPTION; --�ڋq�g�p�ړI�}�X�^�X�V�G���[
  update_location_err_expt  EXCEPTION; --�ڋq���Ə��}�X�^�X�V�G���[
--
  cust_rock_err_expt        EXCEPTION; --���b�N�G���[
--
  PRAGMA EXCEPTION_INIT(cust_rock_err_expt,-54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(12)  := 'XXCMM003A29C';                    --�p�b�P�[�W��
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                               --�J���}
  --
  cv_header_str_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00332';                --CSV�t�@�C���w�b�_������
  cv_no_csv_msg               CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00312';                --�ڋq�ꊇ�X�V�pCSV�擾���s���b�Z�[�W
  cv_parameter_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00038';                --���̓p�����[�^�m�[�g
  cv_file_name_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';                --�t�@�C�����m�[�g
  --�G���[���b�Z�[�W
  cv_required_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00342';                --�K�{���ڃG���[
  cv_val_form_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00322';                --�^�E�����G���[���b�Z�[�W
  cv_lookup_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00314';                --�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W
  cv_mst_err_msg              CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00316';                --�}�X�^���݃`�F�b�N�G���[���b�Z�[�W
  cv_double_byte_kana_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00317';                --�S�p�J�^�J�i�`�F�b�N�G���[���b�Z�[�W
  cv_status_func_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00336';                --�ڋq�X�e�[�^�X�ύX�G���[�i�J�ڕs�j
  cv_status_modify_err_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00319';                --�ڋq�X�e�[�^�X�ύX�`�F�b�N�G���[���b�Z�[�W
  cv_trust_val_invalid        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00315';                --�l�G���[
  cv_cust_addon_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00320';                --�ڋq�ǉ����}�X�^���݃`�F�b�N�G���[
  cv_corp_err_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00321';                --�ڋq�@�l���}�X�^���݃`�F�b�N�G���[
  cv_invalid_data_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00337';                --�f�[�^�G���[���o�̓��b�Z�[�W
  cv_invalid_header_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00338';                --�w�b�_�G���[�����b�Z�[�W
  cv_rock_err_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00313';                --���b�N�G���[�����b�Z�[�W
  cv_update_cust_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00323';                --�ڋq�}�X�^�X�V�G���[�����b�Z�[�W
  cv_update_party_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00324';                --�p�[�e�B�}�X�^�X�V�G���[�����b�Z�[�W
  cv_update_csu_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00325';                --�ڋq�g�p�ړI�G���[�����b�Z�[�W
  cv_update_location_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00326';                --�ڋq���Ə��G���[�����b�Z�[�W
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
  cv_double_byte_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00344';                --�S�p�����`�F�b�N�G���[�����b�Z�[�W
  cv_single_byte_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00345';                --���p�����`�F�b�N�G���[�����b�Z�[�W
  cv_postal_code_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00346';                --�X�֔ԍ��`�F�b�N�G���[�����b�Z�[�W
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
  cv_correlation_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00351';                --���փ`�F�b�N�G���[�����b�Z�[�W
  cv_flex_value_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00352';                --�l�Z�b�g���݃`�F�b�N�G���[�����b�Z�[�W
  cv_set_item_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00353';                --���ڐݒ�`�F�b�N�G���[�����b�Z�[�W
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add start by Yutaka.Kuboshima
  cv_profile_err_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';                --�v���t�@�C���擾�G���[
  cv_stop_date_val_err_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00354';                --���~���ٓ��Ó����`�F�b�N�G���[
  cv_stop_date_future_err_msg CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00355';                --���~���ٓ��������`�F�b�N�G���[
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add start by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
  cv_item_num_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00028';                --�f�[�^���ڐ��G���[
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
  cv_cust_class_kbn_err_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00357';                --�ڋq�敪�X�e�[�^�X�`�F�b�N�G���[
  cv_code_person_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00358';                --�l�����_�c�ƈ����փ`�F�b�N�G���[
  cv_code_relation_err_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00359';                --�l�����_�]�ƈ��R�t���`�F�b�N�G���[
  cv_person_relation_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00360';                --�l���]�ƈ����_�R�t���`�F�b�N�G���[
  cv_new_point_err_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00361';                --�V�K�|�C���g�͈̓`�F�b�N�G���[
  cv_intro_err_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00362';                --���o�^�`�F�b�N�G���[
  cv_intro_person_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00363';                --�l���c�ƈ��Љ�҃`�F�b�N�G���[
  cv_mst_intro_per_err_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00364';                --�Љ�҃}�X�^�`�F�b�N�G���[
  cv_base_code_err_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00365';                --�{���S�����_�K�{�G���[
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
--
  cv_param                    CONSTANT VARCHAR2(5)   := 'PARAM';                           --�p�����[�^�g�[�N��
  cv_value                    CONSTANT VARCHAR2(5)   := 'VALUE';                           --�p�����[�^�l�g�[�N��
  cv_item                     CONSTANT VARCHAR2(4)   := 'ITEM';                            --ITEM�g�[�N��
  cv_file_id                  CONSTANT VARCHAR2(7)   := 'FILE_ID';                         --�p�����[�^�E�t�@�C��ID
  cv_file_content_type        CONSTANT VARCHAR2(17)  := 'FILE_CONTENT_TYPE';               --�p�����[�^�E�t�@�C���^�C�v
  cv_file_name                CONSTANT VARCHAR2(9)   := 'FILE_NAME';                       --�t�@�C�����g�[�N��
  cv_element_vc2              CONSTANT VARCHAR2(1)   := '0';                               --���ڑ����E���؂Ȃ�
  cv_element_num              CONSTANT VARCHAR2(1)   := '1';                               --���ڑ����E���l
  cv_element_dat              CONSTANT VARCHAR2(1)   := '2';                               --���ڑ����E���t
  cv_null_bar                 CONSTANT VARCHAR2(1)   := '-';                               --NULL�X�V����
  cv_null_ng                  CONSTANT VARCHAR2(7)   := 'NULL_NG';                         --�K�{�t���O�E�K�{
  cv_null_ok                  CONSTANT VARCHAR2(7)   := 'NULL_OK';                         --�K�{�t���O�E�C��
  cv_customer_class           CONSTANT VARCHAR2(14)  := 'CUSTOMER CLASS';                  --�Q�ƃ^�C�v�E�ڋq�敪
  cv_cust_code                CONSTANT VARCHAR2(9)   := 'CUST_CODE';                       --�ڋq�R�[�h�g�[�N��
  cv_cust                     CONSTANT VARCHAR2(10)  := '�ڋq�R�[�h';                      --�ڋq�R�[�h
  cv_business_low_type        CONSTANT VARCHAR2(21)  := 'XXCMM_CUST_GYOTAI_SHO';           --�Q�ƃ^�C�v�E�Ƒԁi�����ށj
  cv_bus_low_type             CONSTANT VARCHAR2(14)  := '�Ƒԁi�����ށj';                  --�Ƒԁi�����ށj
  cv_customer_status          CONSTANT VARCHAR2(25)  := 'XXCMM_CUST_KOKYAKU_STATUS';       --�Q�ƃ^�C�v�E�ڋq�X�e�[�^�X
  cv_cust_status              CONSTANT VARCHAR2(14)  := '�ڋq�X�e�[�^�X';                  --�ڋq�X�e�[�^�X
  cv_pre_status               CONSTANT VARCHAR2(10)  := 'PRE_STATUS';                      --�ڋq�X�e�[�^�X�ύX�O�g�[�N��
  cv_will_status              CONSTANT VARCHAR2(11)  := 'WILL_STATUS';                     --�ڋq�X�e�[�^�X�ύX��g�[�N��
  cv_modify_err               CONSTANT VARCHAR2(1)   := '0';                               --�X�e�[�^�X�ύX�`�F�b�N�E�X�e�[�^�X�G���[
  cv_ret_code                 CONSTANT VARCHAR2(8)   := 'RET_CODE';                        --�X�e�[�^�X�ύX�`�F�b�N�E�X�e�[�^�X�g�[�N��
  cv_ret_msg                  CONSTANT VARCHAR2(7)   := 'RET_MSG';                         --�X�e�[�^�X�ύX�`�F�b�N�E���b�Z�[�W�g�[�N��
  cv_stop_approved            CONSTANT VARCHAR2(2)   := '90';                              --�ڋq�X�e�[�^�X�E���~���ύ�
  cv_approval_reason          CONSTANT VARCHAR2(22)  := 'XXCMM_CUST_CHUSHI_RIYU';          --�Q�ƃ^�C�v�E���~���R
  cv_appr_reason              CONSTANT VARCHAR2(8)   := '���~���R';                        --���~���R
  cv_appr_date                CONSTANT VARCHAR2(10)  := '���~���ϓ�';                      --���~���ϓ�
  cv_ar_invoice_code          CONSTANT VARCHAR2(22)  := 'XXCMM_INVOICE_GRP_CODE';          --�Q�ƃR�[�h�E���|�R�[�h�P�i�������j
  cv_ar_invoice               CONSTANT VARCHAR2(22)  := '���|�R�[�h�P�i�������j';          --���|�R�[�h�P�i�������j
  cv_ar_location_code         CONSTANT VARCHAR2(22)  := '���|�R�[�h�Q�i���Ə��j';          --���|�R�[�h�Q�i���Ə��j
  cv_ar_others_code           CONSTANT VARCHAR2(22)  := '���|�R�[�h�R�i���̑��j';          --���|�R�[�h�R�i���̑��j
  cv_table                    CONSTANT VARCHAR2(5)   := 'TABLE';                           --�e�[�u���g�[�N��
-- 2009/10/23 Ver1.2 modify start by Yutaka.Kuboshima
--  cv_invoice_class            CONSTANT VARCHAR2(29)  := 'XXCMM_CUST_SEKYUSYO_HAKKO_KBN';   --�Q�ƃR�[�h�E���������s�敪
--  cv_invoice_kbn              CONSTANT VARCHAR2(14)  := '���������s�敪';                  --���������s�敪
  cv_invoice_class            CONSTANT VARCHAR2(30)  := 'XXCMM_INVOICE_PRINTING_UNIT';     --�Q�ƃR�[�h�E����������P��
  cv_invoice_kbn              CONSTANT VARCHAR2(14)  := '����������P��';                  --����������P��
  cv_industry_div             CONSTANT VARCHAR2(4)   := '�Ǝ�';                            --�Ǝ�
  cv_bill_base_code           CONSTANT VARCHAR2(8)   := '�������_';                        --�������_
  cv_receiv_base_code         CONSTANT VARCHAR2(8)   := '�������_';                        --�������_
  cv_delivery_base_code       CONSTANT VARCHAR2(8)   := '�[�i���_';                        --�[�i���_
  cv_selling_transfer_div     CONSTANT VARCHAR2(12)  := '������ѐU��';                    --������ѐU��
  cv_card_company             CONSTANT VARCHAR2(16)  := '�J�[�h��ЃR�[�h';                --�J�[�h��ЃR�[�h
  cv_wholesale_ctrl_code      CONSTANT VARCHAR2(14)  := '�≮�Ǘ��R�[�h';                  --�≮�Ǘ��R�[�h
  cv_price_list               CONSTANT VARCHAR2(6)   := '���i�\';                          --���i�\
-- 2009/10/23 Ver1.2 modify end by Yutaka.Kuboshima
  cv_invoice_issue_cycle      CONSTANT VARCHAR2(25)  := 'XXCMM_INVOICE_ISSUE_CYCLE';       --�Q�ƃR�[�h�E���������s�T�C�N��
  cv_invoice_cycle            CONSTANT VARCHAR2(18)  := '���������s�T�C�N��';              --���������s�T�C�N��
  cv_invoice_form             CONSTANT VARCHAR2(28)  := 'XXCMM_CUST_SEKYUSYO_SHUT_KSK';    --�Q�ƃR�[�h�E�������o�͌`��
  cv_invoice_ksk              CONSTANT VARCHAR2(14)  := '�������o�͌`��';                  --�������o�͌`��
  cv_payment_term_id          CONSTANT VARCHAR2(8)   := '�x������';                        --�x������
  cv_payment_term_second      CONSTANT VARCHAR2(11)  := '��2�x������';                     --��2�x������
  cv_payment_term_third       CONSTANT VARCHAR2(11)  := '��3�x������';                     --��3�x������
  cv_payment_term             CONSTANT VARCHAR2(14)  := '�x�������}�X�^';                  --�x������
  cv_xxcmm_chain_code         CONSTANT VARCHAR2(16)  := 'XXCMM_CHAIN_CODE';                --�Q�ƃR�[�h�E�`�F�[���X
  cv_sales_chain_code         CONSTANT VARCHAR2(26)  := '�`�F�[���X�R�[�h�i�̔���j';      --�`�F�[���X�R�[�h�i�̔���j
  cv_delivery_chain_code      CONSTANT VARCHAR2(26)  := '�`�F�[���X�R�[�h�i�[�i��j';      --�`�F�[���X�R�[�h�i�[�i��j
  cv_policy_chain_code        CONSTANT VARCHAR2(26)  := '�`�F�[���X�R�[�h�i�����p�j';      --�`�F�[���X�R�[�h�i�����p�j
  cv_edi_chain                CONSTANT VARCHAR2(26)  := '�`�F�[���X�R�[�h�i�d�c�h�j';      --�`�F�[���X�R�[�h�i�d�c�h�j
  cv_addon_cust_mst           CONSTANT VARCHAR2(18)  := '�ڋq�ǉ����}�X�^';              --�ڋq�ǉ����}�X�^�i������j
  cv_edi_class                CONSTANT VARCHAR2(2)   := '18';                              --�ڋq�敪�E�`�F�[���X
  cv_trust_corp               CONSTANT VARCHAR2(2)   := '13';                              --�ڋq�敪�E�@�l�ڋq�i�^�M�Ǘ���j
  cv_store_code               CONSTANT VARCHAR2(10)  := '�X�܃R�[�h';                      --�X�܃R�[�h
  cv_postal_code              CONSTANT VARCHAR2(8)   := '�X�֔ԍ�';                        --�X�֔ԍ�
  cv_state                    CONSTANT VARCHAR2(8)   := '�s���{��';                        --�s���{��
  cv_city                     CONSTANT VARCHAR2(6)   := '�s�E��';                          --�s�E��
  cv_address1                 CONSTANT VARCHAR2(5)   := '�Z��1';                           --�Z��1
  cv_address2                 CONSTANT VARCHAR2(5)   := '�Z��2';                           --�Z��2
  cv_address3                 CONSTANT VARCHAR2(10)  := '�n��R�[�h';                      --�n��R�[�h
  cv_cust_chiku_code          CONSTANT VARCHAR2(21)  := 'XXCMM_CUST_CHIKU_CODE';           --�Q�ƃR�[�h�E�n��R�[�h
  cv_credit_limit             CONSTANT VARCHAR2(21)  := '�^�M���x�z';                      --�^�M���x�z
  cv_decide_div               CONSTANT VARCHAR2(20)  := 'XXCMM_CUST_SOHYO_KBN';            --�Q�ƃR�[�h�E����敪
  cv_decide                   CONSTANT VARCHAR2(8)   := '����敪';                        --����敪
--
  cv_cust_acct_table          CONSTANT VARCHAR2(16)  := 'HZ_CUST_ACCOUNTS';                --�ڋq�}�X�^
  cv_lookup_values            CONSTANT VARCHAR2(20)  := 'FND_LOOKUP_VALUES_VL';            --�Q�ƕ\�g�[�N��
  cv_col_name                 CONSTANT VARCHAR2(14)  := 'INPUT_COL_NAME';                  --�񖼃g�[�N��
  cv_input_val                CONSTANT VARCHAR2(15)  := 'INPUT_COL_VALUE';                 --�l�g�[�N��
  cv_cust_class               CONSTANT VARCHAR2(8)   := '�ڋq�敪';                        --�ڋq�敪�i�񖼁j
  cv_cust_class_us            CONSTANT VARCHAR2(10)  := 'CUST_CLASS';                      --�ڋq�敪�g�[�N��
  cv_cust_name                CONSTANT VARCHAR2(8)   := '�ڋq����';                        --�ڋq���́i�񖼁j
  cv_cust_name_kana           CONSTANT VARCHAR2(12)  := '�ڋq���̃J�i';                    --�ڋq���̃J�i�i�񖼁j
  cv_ryaku                    CONSTANT VARCHAR2(4)   := '����';                            --����
  cv_date_format              CONSTANT VARCHAR2(10)  := 'YYYY-MM-DD';                      --���t����
--
  cv_conc_request_id          CONSTANT VARCHAR2(15)  := 'CONC_REQUEST_ID';                 --�v��ID�擾�p������
  cv_prog_appl_id             CONSTANT VARCHAR2(12)  := 'PROG_APPL_ID';                    --�R���J�����g�E�v���O������A�v���P�[�V����ID�擾�p������
  cv_conc_program_id          CONSTANT VARCHAR2(15)  := 'CONC_PROGRAM_ID';                 --�R���J�����g�E�v���O����ID�擾�p������
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
  cv_invoice_code             CONSTANT VARCHAR2(14)  := '�������p�R�[�h';                  --�������p�R�[�h
  cv_cond_col_name            CONSTANT VARCHAR2(15)  := 'COND_COL_NAME';                   --���֗񖼃g�[�N��
  cv_cond_col_val             CONSTANT VARCHAR2(15)  := 'COND_COL_VALUE';                  --���֒l�g�[�N��
  cv_kokyaku_kbn              CONSTANT VARCHAR2(2)   := '10';                              --�ڋq�敪(�ڋq)
  cv_uesama_kbn               CONSTANT VARCHAR2(2)   := '12';                              --�ڋq�敪(��l�ڋq)
  cv_urikake_kbn              CONSTANT VARCHAR2(2)   := '14';                              --�ڋq�敪(���|�Ǘ���)
  cv_tenpo_kbn                CONSTANT VARCHAR2(2)   := '15';                              --�ڋq�敪(�X�܉c��)
  cv_tonya_kbn                CONSTANT VARCHAR2(2)   := '16';                              --�ڋq�敪(�≮������)
  cv_keikaku_kbn              CONSTANT VARCHAR2(2)   := '17';                              --�ڋq�敪(�v�旧�ėp)
  cv_hyakkaten_kbn            CONSTANT VARCHAR2(2)   := '19';                              --�ڋq�敪(�S�ݓX�`��)
  cv_seikyusho_kbn            CONSTANT VARCHAR2(2)   := '20';                              --�ڋq�敪(�������p)
  cv_toukatu_kbn              CONSTANT VARCHAR2(2)   := '21';                              --�ڋq�敪(�����������p)
  cv_yes                      CONSTANT VARCHAR2(1)   := 'Y';                               --Y�t���O
  cv_no                       CONSTANT VARCHAR2(1)   := 'N';                               --N�t���O
  cv_language_ja              CONSTANT VARCHAR2(2)   := 'JA';                              --����E���{��
  cv_list_type_prl            CONSTANT VARCHAR2(3)   := 'PRL';                             --���X�g�^�C�v�EPRL
  cv_card_company_div         CONSTANT VARCHAR2(1)   := '1';                               --�J�[�h��Ћ敪
  cv_gyotai_full_syoka_vd     CONSTANT VARCHAR2(2)   := '24';                              --�Ƒԁi�����ށj�F�t���T�[�r�X(����)VD
  cv_gyotai_full_vd           CONSTANT VARCHAR2(2)   := '25';                              --�Ƒԁi�����ށj�F�t���T�[�r�XVD
  cv_aff_dept                 CONSTANT VARCHAR2(15)  := 'XX03_DEPARTMENT';                 --AFF����}�X�^�Q�ƃ^�C�v
  cv_gyotai_kbn               CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_KBN';           --�Q�ƃR�[�h�E�Ǝ�
  cv_uriage_jisseki_furi      CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_URIAGE_JISSEKI_FURI';  --�Q�ƃR�[�h�E������ѐU��
  cv_tonya_code               CONSTANT VARCHAR2(30)  := 'XXCMM_TONYA_CODE';                --�Q�ƃR�[�h�E�≮�Ǘ��R�[�h
  cv_qp_list_headers_table    CONSTANT VARCHAR2(30)  := 'QP_LIST_HEADERS_B';               --���i�\�}�X�^
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/01/04v Ver1.3 E_�{�ғ�_00778 add start by Yutaka.Kuboshima
  cv_profile_gl_cal           CONSTANT VARCHAR2(30)  := 'XXCMM1_003A00_GL_PERIOD_MN';      --��v�J�����_����`���̧��
  cv_profile_ar_bks           CONSTANT VARCHAR2(30)  := 'XXCMM1_003A15_AR_BOOKS_NM';       --�c�ƒ����`�����̧��
  cv_tkn_ng_profile           CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                      --�v���t�@�C�����g�[�N��
  cv_gl_cal_name              CONSTANT VARCHAR2(30)  := '��v�J�����_��';                  --��v�J�����_��
  cv_set_of_books_name        CONSTANT VARCHAR2(30)  := '�c�ƒ����`��';                  --�c�ƒ����`��
  cv_close_status             CONSTANT VARCHAR2(1)   := 'C';                               --��v���ԁF�N���[�Y
  cv_apl_short_nm_ar          CONSTANT VARCHAR2(2)   := 'AR';                              --�A�v���P�[�V�����FAR
-- 2010/01/04v Ver1.3 E_�{�ғ�_00778 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
  cv_organization_code        CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';        --�݌ɑg�D�R�[�h�v���t�@�C��
  cv_profile_org_code         CONSTANT VARCHAR2(30)  := '�݌ɑg�D�R�[�h';                  --�݌ɑg�D�R�[�h�v���t�@�C����
  cv_ship_storage_code        CONSTANT VARCHAR2(14)  := '�o�׌��ۊǏꏊ';                  --�o�׌��ۊǏꏊ
  cv_second_inv_mst           CONSTANT VARCHAR2(14)  := '�ۊǏꏊ�}�X�^';                  --�ۊǏꏊ�}�X�^
  cv_csv_item_num             CONSTANT VARCHAR2(30)  := 'XXCMM1_003A29_ITEM_NUM';          --�ڋq�ꊇ�X�V�f�[�^���ڐ�
  cv_csv_item_num_name        CONSTANT VARCHAR2(30)  := '�ڋq�ꊇ�X�V�f�[�^���ڐ�';        --�ڋq�ꊇ�X�V�f�[�^���ڐ���
  cv_management_resp          CONSTANT VARCHAR2(30)  := 'XXCMM1_MANAGEMENT_RESP';          --�E�ӊǗ��v���t�@�C��
  cv_management_resp_name     CONSTANT VARCHAR2(30)  := '�E�ӊǗ��v���t�@�C��';            --�E�ӊǗ��v���t�@�C����
  cv_joho_kanri_resp          CONSTANT VARCHAR2(30)  := 'XXCMM_RESP_011';                  --�E�ӊǗ��v���t�@�C���l(���Ǘ�_�S����)
  cv_count_token              CONSTANT VARCHAR2(30)  := 'COUNT';                           --�����g�[�N��
  cv_xxcmm_003_a29c_name      CONSTANT VARCHAR2(30)  := '�ڋq�ꊇ�X�V';                    --�ڋq�ꊇ�X�V��
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add start by K.Kubo
  cv_delivery_order           CONSTANT VARCHAR2(13)  := '�z�����iEDI�j';                   --�z�����iEDI�j
  cv_edi_district_code        CONSTANT VARCHAR2(20)  := 'EDI�n��R�[�h�iEDI�j';            --EDI�n��R�[�h�iEDI�j
  cv_edi_district_name        CONSTANT VARCHAR2(16)  := 'EDI�n�於�iEDI�j';                --EDI�n�於�iEDI�j
  cv_edi_district_kana        CONSTANT VARCHAR2(20)  := 'EDI�n�於�J�i�iEDI�j';            --EDI�n�於�J�i�iEDI�j
  cv_tsukagatazaiko_div       CONSTANT VARCHAR2(21)  := '�ʉߍ݌Ɍ^�敪�iEDI�j';           --�ʉߍ݌Ɍ^�敪�iEDI�j
  cv_deli_center_code         CONSTANT VARCHAR2(21)  := 'EDI�[�i�Z���^�[�R�[�h';           --EDI�[�i�Z���^�[�R�[�h
  cv_deli_center_name         CONSTANT VARCHAR2(17)  := 'EDI�[�i�Z���^�[��';               --EDI�[�i�Z���^�[��
  cv_edi_forward_number       CONSTANT VARCHAR2(11)  := 'EDI�`���ǔ�';                     --EDI�`���ǔ�
  cv_cust_store_name          CONSTANT VARCHAR2(12)  := '�ڋq�X�ܖ���';                    --�ڋq�X�ܖ���
  cv_torihikisaki_code        CONSTANT VARCHAR2(12)  := '�����R�[�h';                    --�����R�[�h
  cv_tsukagatazaiko_kbn       CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_TSUKAGATAZAIKO_KBN';   --�Q�ƃR�[�h�E�ʉߍ݌Ɍ^�敪
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add start by S.Niki
  cv_vist_target_div          CONSTANT VARCHAR2(30)  := '�K��Ώۋ敪';                    --�K��Ώۋ敪
  cv_homon_taisyo_kbn         CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_HOMON_TAISYO_KBN';     --�Q�ƃR�[�h�E�K��Ώۋ敪
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
  cv_approved_status          CONSTANT VARCHAR2(2)   := '30';                              --�ڋq�X�e�[�^�X�E���F��
  cv_cnvs_base_code           CONSTANT VARCHAR2(30)  := '�l�����_�R�[�h';                  --�l�����_�R�[�h
  cv_cnvs_business_person     CONSTANT VARCHAR2(30)  := '�l���c�ƈ�';                      --�l���c�ƈ�
  cv_new_point_div            CONSTANT VARCHAR2(30)  := '�V�K�|�C���g�敪';                --�V�K�|�C���g�敪
  cv_new_point_div_type       CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_SHINKI_POINT_KBN';     --�Q�ƃ^�C�v�E�V�K�|�C���g�敪
  cv_new_point                CONSTANT VARCHAR2(30)  := '�V�K�|�C���g';                    --�V�K�|�C���g
  cv_intro_base_code          CONSTANT VARCHAR2(30)  := '�Љ�_�R�[�h';                  --�Љ�_�R�[�h
  cv_intro_base_code_val      CONSTANT VARCHAR2(30)  := 'XX03_DEPARTMENT';                 --�l�Z�b�g�E�Љ�_�R�[�h
  cv_intro_business_person    CONSTANT VARCHAR2(30)  := '�Љ�c�ƈ�';                      --�Љ�c�ƈ�
  cv_base_code                CONSTANT VARCHAR2(30)  := '�{���S�����_';                    --�{���S�����_
  cv_tdb_code                 CONSTANT VARCHAR2(30)  := 'TDB�R�[�h';                       --TDB�R�[�h
  cv_approval_date            CONSTANT VARCHAR2(30)  := '���ٓ��t';                        --���ٓ��t
  cv_intro_chain_code1        CONSTANT VARCHAR2(30)  := '�Љ�҃`�F�[���R�[�h�P';          --�Љ�҃`�F�[���R�[�h�P
  cv_intro_chain_code2        CONSTANT VARCHAR2(30)  := '�Љ�҃`�F�[���R�[�h�Q';          --�Љ�҃`�F�[���R�[�h�Q
  cv_sales_head_base_code     CONSTANT VARCHAR2(30)  := '�̔���{���S�����_';              --�̔���{���S�����_
  cn_point_min                CONSTANT NUMBER        := 0;                                 --�V�K�|�C���g�ŏ��l
  cn_point_max                CONSTANT NUMBER        := 999;                               --�V�K�|�C���g�ő�l
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
  gd_process_date             DATE;                                                        --�Ɩ����t
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add start by Yutaka.Kuboshima
  gv_gl_cal_code              VARCHAR2(30);                                                --��v�J�����_�R�[�h�l
  gv_ar_set_of_books          VARCHAR2(30);                                                --�c�ƃV�X�e����v�����`��
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
  gv_organization_code        VARCHAR2(30);                                                --�݌ɑg�D�R�[�h
  gn_item_num                 NUMBER;                                                      --�ڋq�ꊇ�X�V�f�[�^���ڐ�
  gv_management_resp          VARCHAR2(30);                                                --�E�ӊǗ��v���t�@�C��
  gv_resp_flag                VARCHAR2(1);                                                 --�E�ӊǗ��t���O(���Ǘ����F'Y' ���̑��F'N')
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
--
  /**********************************************************************************
   * Procedure Name   : cust_data_make_wk
   * Description      : �t�@�C���A�b�v���[�hI/F�e�[�u���擾����(A-1)�E�ڋq�ꊇ�X�V�p���[�N�e�[�u���o�^����(A-2)
   ***********************************************************************************/
  PROCEDURE cust_data_make_wk(
    in_file_id              IN  NUMBER,       --   �t�@�C��ID
    iv_format_pattern       IN  VARCHAR2,     --   �t�@�C���t�H�[�}�b�g
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cust_data_make_wk'; -- �v���O������
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
    -- �\���̐錾
    lr_cust_data_table       xxccp_common_pkg2.g_file_data_tbl;
--
    lv_item_errbuf           VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_item_retcode          VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_item_errmsg           VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    --�e�i�[�p�ϐ�
    lv_upload_file_name      xxccp_mrp_file_ul_interface.file_name%TYPE := NULL;  --�t�@�C���A�b�v���[�hIF�e�[�u��.�t�@�C����
--
    lv_temp                  VARCHAR2(32767) := NULL;                     --�ڋq�ꊇ�X�V���[�N�e�[�u���o�^�p�ϐ�
    ln_index                 binary_integer;                              --������\���̎Q�Ɨp�Y��
    ln_first_data            NUMBER(1)       := 1;                        --�w�b�_�f�[�^���ʎq
    lr_cust_wk_table         xxcmm_wk_cust_batch_regist%ROWTYPE;          --�t�@�C���A�b�v���[�hIF�e�[�u���^���R�[�h�ϐ�
--
    ln_cust_id               hz_cust_accounts.cust_account_id%TYPE;       --���[�J���ϐ��ڋqID
    ln_party_id              hz_cust_accounts.party_id%TYPE;              --���[�J���ϐ��p�[�e�BID
    lv_customer_code         VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�ڋq�R�[�h
    lv_cust_code_mst         hz_cust_accounts.account_number%TYPE;        --�ڋq�R�[�h���݊m�F�p�ϐ�
    ln_cust_addon_mst        xxcmm_cust_accounts.customer_id%TYPE;        --�ڋq�ǉ���񑶍݊m�F�p�ϐ�
    ln_cust_corp_mst         xxcmm_mst_corporate.customer_id%TYPE;        --�ڋq�@�l��񑶍݊m�F�p�ϐ�
    lv_customer_class        VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�ڋq�敪
    lv_cust_class_mst        hz_cust_accounts.customer_class_code%TYPE;   --�ڋq�敪���݊m�F�p�ϐ�
    lv_customer_name         VARCHAR2(500)   := NULL;                     --���[�J���ϐ��E�ڋq����
    lv_cust_name_kana        VARCHAR2(500)   := NULL;                     --���[�J���ϐ��E�ڋq���̃J�i
    lv_cust_name_ryaku       VARCHAR2(500)   := NULL;                     --���[�J���ϐ��E����
    lv_customer_status       VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�ڋq�X�e�[�^�X
    lv_approval_reason       VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���~���R
    lv_appr_reason_mst       VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���~���R
    lv_approval_date         VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���~���ϓ�
    lv_ar_invoice_code       VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���|�R�[�h�P�i�������j
    lv_ar_invoice_code_mst   VARCHAR2(100)   := NULL;                     --���|�R�[�h�P�i�������j���݊m�F�p�ϐ�
    lv_ar_location_code      VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���|�R�[�h�Q�i���Ə��j
    lv_ar_others_code        VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���|�R�[�h�R�i���̑��j
    lv_invoice_class         VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���������s�敪
    lv_invoice_class_mst     VARCHAR2(100)   := NULL;                     --���������s�敪���݊m�F�p�ϐ�
    lv_invoice_cycle         VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E���������s�T�C�N��
    lv_invoice_cycle_mst     VARCHAR2(100)   := NULL;                     --���������s�T�C�N�����݊m�F�p�ϐ�
    lv_invoice_form          VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�������o�͌`��
    lv_invoice_form_mst      VARCHAR2(100)   := NULL;                     --�������o�͌`�����݊m�F�p�ϐ�
    lv_payment_term_id       VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�x������
    lv_payment_term_id_mst   VARCHAR2(100)   := NULL;                     --�x���������݊m�F�p�ϐ�
    lv_payment_term_second   VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E��2�x������
    lv_payment_second_mst    VARCHAR2(100)   := NULL;                     --��2�x���������݊m�F�p�ϐ�
    lv_payment_term_third    VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E��3�x������
    lv_payment_third_mst     VARCHAR2(100)   := NULL;                     --��3�x���������݊m�F�p�ϐ�
    lv_sales_chain_code      VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�`�F�[���X�R�[�h�i�̔���j
    lv_sales_chain_code_mst  VARCHAR2(100)   := NULL;                     --�`�F�[���X�R�[�h�i�̔���j���݊m�F�p�ϐ�
    lv_delivery_chain_code   VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�`�F�[���X�R�[�h�i�[�i��j
    lv_deliv_chain_code_mst  VARCHAR2(100)   := NULL;                     --�`�F�[���X�R�[�h�i�̔���j���݊m�F�p�ϐ�
    lv_policy_chain_code     VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�`�F�[���X�R�[�h�i�����p�j
    lv_edi_chain_code        VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�`�F�[���X�R�[�h�i�d�c�h�j
    lv_edi_chain_mst         VARCHAR2(100)   := NULL;                     --�`�F�[���X�R�[�h�i�d�c�h�j���݊m�F�p�ϐ�
    lv_store_code            VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�X�܃R�[�h
    lv_postal_code           VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�X�֔ԍ�
    lv_state                 VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�s���{��
    lv_city                  VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�s�E��
    lv_address1              VARCHAR2(500)   := NULL;                     --���[�J���ϐ��E�Z��1
    lv_address2              VARCHAR2(500)   := NULL;                     --���[�J���ϐ��E�Z��2
    lv_address3              VARCHAR2(500)   := NULL;                     --���[�J���ϐ��E�n��R�[�h
    lv_cust_chiku_code_mst   VARCHAR2(100)   := NULL;                     --�n��R�[�h���݊m�F�p�ϐ�
    lv_credit_limit          VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E�^�M���x�z�i�����j
    ln_credit_limit          NUMBER          := NULL;                     --���[�J���ϐ��E�^�M���x�z�i���l�j
    lv_decide_div            VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E����敪
    lv_decide_div_mst        VARCHAR2(100)   := NULL;                     --����敪���݊m�F�p�ϐ�
--
    lv_cust_status_mst       hz_parties.duns_number_c%TYPE;               --�ڋq�X�e�[�^�X���݊m�F�p�ϐ�
    lv_get_cust_status       hz_parties.duns_number_c%TYPE;               --�ڋq�X�e�[�^�X���s�擾�p�ϐ�
--
    lv_business_low_type     VARCHAR2(100)   := NULL;                     --���[�J���ϐ��E������
    lv_business_low_mst      xxcmm_cust_accounts.business_low_type%TYPE;  --�����ޑ��݊m�F�p�ϐ�
-- 2010/02/15 Ver1.5 E_�{�ғ�01582 add start by Yutaka.Kuboshima
    lv_business_low_type_now xxcmm_cust_accounts.business_low_type%TYPE;  --���ݐݒ肳��Ă��鏬����
-- 2010/02/15 Ver1.5 E_�{�ғ�01582 add end by Yutaka.Kuboshima
--
    lv_check_status          VARCHAR2(1)     := NULL;                     --���ڃ`�F�b�N���ʊi�[�p�ϐ�
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
    lv_cust_customer_class      VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�ڋq�敪(�ڋq�}�X�^)
    lv_invoice_required_flag    VARCHAR2(1)     := NULL;                  --���[�J���ϐ��E�������p�R�[�h�K�{�t���O
    lv_invoice_code             VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�������p�R�[�h
    ln_invoice_code_mst         hz_cust_accounts.cust_account_id%TYPE;    --�������p�R�[�h�m�F�p�ϐ�
    lv_industry_div             VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�Ǝ�
    lv_industry_div_mst         VARCHAR2(100)   := NULL;                  --�Ǝ�m�F�p�ϐ�
    lv_bill_base_code           VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�������_
    lv_bill_base_code_mst       VARCHAR2(100)   := NULL;                  --�������_�m�F�p�ϐ�
    lv_receiv_base_code         VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�������_
    lv_receiv_base_code_mst     VARCHAR2(100)   := NULL;                  --�������_�m�F�p�ϐ�
    lv_delivery_base_code       VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�[�i���_
    lv_delivery_base_code_mst   VARCHAR2(100)   := NULL;                  --�[�i���_�m�F�p�ϐ�
    lv_selling_transfer_div     VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E������ѐU��
    lv_selling_transfer_div_mst VARCHAR2(100)   := NULL;                  --������ѐU�֊m�F�p�ϐ�
    lv_card_company             VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�J�[�h���
    lv_card_company_mst         VARCHAR2(100)   := NULL;                  --�J�[�h��Њm�F�p�ϐ�
    lv_wholesale_ctrl_code      VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�≮�Ǘ��R�[�h
    lv_wholesale_ctrl_code_mst  VARCHAR2(100)   := NULL;                  --�≮�Ǘ��R�[�h�m�F�p�ϐ�
    lv_price_list               VARCHAR2(500)   := NULL;                  --���[�J���ϐ��E���i�\
    lv_price_list_mst           qp_list_headers_b.list_header_id%TYPE;    --���i�\�m�F�p�ϐ�
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add start by Yutaka.Kuboshima
    lv_period_status            VARCHAR2(1)     := NULL;                  --���[�J���ϐ��E��v���ԃN���[�Y�X�e�[�^�X
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
    lv_ship_storage_code        VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�o�׌��ۊǏꏊ
    lv_ship_storage_code_mst    VARCHAR2(100)   := NULL;                  --�o�׌��ۊǏꏊ
    ln_item_num                 NUMBER;                                   --CSV���ڐ�
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add start by K.Kubo
    lv_delivery_order           VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�z�����iEDI�j
    lv_edi_district_code        VARCHAR2(100)   := NULL;                  --���[�J���ϐ��EEDI�n��R�[�h�iEDI�j
    lv_edi_district_name        VARCHAR2(100)   := NULL;                  --���[�J���ϐ��EEDI�n�於�iEDI�j
    lv_edi_district_kana        VARCHAR2(100)   := NULL;                  --���[�J���ϐ��EEDI�n�於�J�i�iEDI�j
    lv_tsukagatazaiko_div       VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�ʉߍ݌Ɍ^�敪�iEDI�j
    lv_tsukagatazaiko_div_mst   xxcmm_cust_accounts.tsukagatazaiko_div%TYPE;  --�ʉߍ݌Ɍ^�敪�iEDI�j�m�F�p�ϐ�
    lv_deli_center_code         VARCHAR2(100)   := NULL;                  --���[�J���ϐ��EEDI�[�i�Z���^�[�R�[�h
    lv_deli_center_name         VARCHAR2(100)   := NULL;                  --���[�J���ϐ��EEDI�[�i�Z���^�[��
    lv_edi_forward_number       VARCHAR2(100)   := NULL;                  --���[�J���ϐ��EEDI�`���ǔ�
    lv_cust_store_name          VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�ڋq�X�ܖ���
    lv_torihikisaki_code        VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�����R�[�h
    lv_tsukagatazaiko_flag      VARCHAR2(1)     := NULL;                  --�ʉߍ݌Ɍ^�敪�iEDI�j���̓`�F�b�N�p
    lv_chain_store_db           xxcmm_cust_accounts.chain_store_code%TYPE;    --�ڋq�ǉ���񑶍݊m�F�p�ϐ�
    lv_tsukagatazaiko_div_db    xxcmm_cust_accounts.tsukagatazaiko_div%TYPE;  --�ڋq�ǉ���񑶍݊m�F�p�ϐ�
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add start by S.Niki
    lv_vist_target_div          VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�K��Ώۋ敪
    lv_vist_target_div_mst      xxcmm_cust_accounts.vist_target_div%TYPE; --�K��Ώۋ敪�m�F�p�ϐ�
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
    lv_cnvs_base_code           VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�l�����_�R�[�h
    lv_cnvs_base_code_mst1       xxcmm_cust_accounts.cnvs_base_code%TYPE; --�l�����_�R�[�h�m�F�p�ϐ�1
    lv_cnvs_base_code_mst2       xxcmm_cust_accounts.cnvs_base_code%TYPE; --�l�����_�R�[�h�m�F�p�ϐ�2
    lv_cnvs_business_person     VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�l���c�ƈ�
    lv_cnvs_business_person_mst1 xxcmm_cust_accounts.cnvs_business_person%TYPE;  --�l���c�ƈ��m�F�p�ϐ�1
    lv_cnvs_business_person_mst2 xxcmm_cust_accounts.cnvs_business_person%TYPE;  --�l���c�ƈ��m�F�p�ϐ�2
    lv_base_code_flag1          VARCHAR2(1)     := NULL;                  --�l�����_�R�[�h���̓`�F�b�N�p1
    lv_business_person_flag1    VARCHAR2(1)     := NULL;                  --�l���c�ƈ����̓`�F�b�N�p1
    lv_base_code_flag2          VARCHAR2(1)     := NULL;                  --�l�����_�R�[�h���̓`�F�b�N�p2
    lv_business_person_flag2    VARCHAR2(1)     := NULL;                  --�l���c�ƈ����̓`�F�b�N�p2
    lv_base_code_flag3          VARCHAR2(1)     := NULL;                  --�l�����_�R�[�h���̓`�F�b�N�p3
    lv_business_person_flag3    VARCHAR2(1)     := NULL;                  --�l���c�ƈ����̓`�F�b�N�p3
    lv_base_code_flag4          VARCHAR2(1)     := NULL;                  --�l�����_�R�[�h���̓`�F�b�N�p4
    lv_business_person_flag4    VARCHAR2(1)     := NULL;                  --�l���c�ƈ����̓`�F�b�N�p4
    lv_new_point_div            VARCHAR2(1)     := NULL;                  --���[�J���ϐ��E�V�K�|�C���g�敪
    lv_new_point_div_mst        xxcmm_cust_accounts.new_point_div%TYPE;   --�V�K�|�C���g�敪�m�F�p�ϐ�
    lv_new_point                VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�V�K�|�C���g
    ln_new_point                NUMBER          := NULL;                  --���[�J���ϐ��E�V�K�|�C���g(���l)
    lv_intro_base_code          VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�Љ�_�R�[�h
    lv_intro_base_code_mst1     xxcmm_cust_accounts.intro_base_code%TYPE; --�Љ�_�R�[�h�m�F�p�ϐ�1
    lv_intro_base_code_mst2     xxcmm_cust_accounts.intro_base_code%TYPE; --�Љ�_�R�[�h�m�F�p�ϐ�2
    lv_intro_business_person    VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�Љ�c�ƈ�
    lv_intro_business_person_mst1 xxcmm_cust_accounts.intro_business_person%TYPE; --�Љ�c�ƈ��m�F�p�ϐ�1
    lv_intro_business_person_mst2 xxcmm_cust_accounts.intro_business_person%TYPE; --�Љ�c�ƈ��m�F�p�ϐ�2
    lv_int_bus_per_flag1        VARCHAR2(1)     := NULL;                  --�Љ�c�ƈ��`�F�b�N�p1
    lv_int_bus_per_flag2        VARCHAR2(1)     := NULL;                  --�Љ�c�ƈ��`�F�b�N�p2
    lv_base_code                VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�{���S�����_
    lv_base_code_mst            xxcmm_mst_corporate.base_code%TYPE;       --�Љ�c�ƈ��m�F�p�ϐ�1
    lv_tdb_code                 VARCHAR2(100)   := NULL;                  --���[�J���ϐ��ETDB�R�[�h
    lv_corp_approval_date       VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E���ٓ��t
    lv_intro_chain_code1        VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�Љ�҃`�F�[���R�[�h�P
    lv_intro_chain_code2        VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�Љ�҃`�F�[���R�[�h�Q
    lv_sales_head_base_code     VARCHAR2(100)   := NULL;                  --���[�J���ϐ��E�̔���{���S�����_
    lv_sales_head_base_code_mst xxcmm_cust_accounts.sales_head_base_code%TYPE; --�̔���{���S�����_�m�F�p�ϐ�
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �A�b�v���[�h�t�@�C�����݊m�F�J�[�\��
    CURSOR check_upload_file_cur(
      in_file_id  IN NUMBER,
      iv_format   IN VARCHAR2)
    IS
      SELECT xmf.file_name  file_name
      FROM   xxccp_mrp_file_ul_interface  xmf
      WHERE  xmf.file_id           = in_file_id
      AND    xmf.file_content_type = iv_format
      ;
    -- �A�b�v���[�h�t�@�C�����݊m�F�J�[�\�����R�[�h�^
    check_upload_file_rec  check_upload_file_cur%ROWTYPE;
--
    -- �ڋq�R�[�h���݊m�F�J�[�\��
    CURSOR check_cust_code_cur(
      iv_cust_code IN VARCHAR2)
    IS
      SELECT hca.cust_account_id  cust_id,
             hca.account_number   cust_code,
             hca.party_id         party_id,
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
             hca.customer_class_code cust_kbn
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
      FROM   hz_cust_accounts     hca
      WHERE  hca.account_number = iv_cust_code
      ;
    -- �ڋq�R�[�h���݊m�F�J�[�\�����R�[�h�^
    check_cust_code_rec  check_cust_code_cur%ROWTYPE;
--
    -- �ڋq�ǉ���񑶍݊m�F�J�[�\��
    CURSOR check_cust_addon_cur(
      in_cust_id  IN NUMBER)
    IS
      SELECT xca.customer_id      customer_id
      FROM   xxcmm_cust_accounts  xca
      WHERE  xca.customer_id    = in_cust_id
      ;
    -- �ڋq�ǉ���񑶍݊m�F�J�[�\�����R�[�h�^
    check_cust_addon_rec  check_cust_addon_cur%ROWTYPE;
--
    -- �ڋq�@�l��񑶍݊m�F�J�[�\��
    CURSOR check_cust_corp_cur(
      in_cust_id  IN NUMBER)
    IS
      SELECT xmc.customer_id      customer_id
      FROM   xxcmm_mst_corporate  xmc
      WHERE  xmc.customer_id    = in_cust_id
      ;
    -- �ڋq�@�l��񑶍݊m�F�J�[�\�����R�[�h�^
    check_cust_corp_rec  check_cust_corp_cur%ROWTYPE;
--
    -- �ڋq�敪�`�F�b�N�J�[�\��
    CURSOR check_cust_class_cur(
      iv_cust_class IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      cust_class
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_customer_class
      AND    flvv.lookup_code = iv_cust_class
      ;
    -- �ڋq�敪�`�F�b�N�J�[�\�����R�[�h�^
    check_cust_class_rec  check_cust_class_cur%ROWTYPE;
--
    -- �Ƒԁi�����ށj�`�F�b�N�J�[�\��
    CURSOR check_business_low_cur(
      iv_business_low_type IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      business_low_type
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_business_low_type
      AND    flvv.lookup_code = iv_business_low_type
      ;
    -- �Ƒԁi�����ށj�`�F�b�N�J�[�\�����R�[�h�^
    check_business_low_rec  check_business_low_cur%ROWTYPE;
--
    -- �ڋq�X�e�[�^�X�`�F�b�N�J�[�\��
    CURSOR check_cust_status_cur(
      iv_cust_status IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      cust_status
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_customer_status
      AND    flvv.lookup_code = iv_cust_status
      ;
    -- �ڋq�X�e�[�^�X�`�F�b�N�J�[�\�����R�[�h�^
    check_cust_status_rec  check_cust_status_cur%ROWTYPE;
--
    -- �ڋq�X�e�[�^�X�擾�J�[�\��
    CURSOR get_cust_status_cur(
      in_paty_id IN NUMBER)
    IS
      SELECT duns_number_c  cust_status
      FROM   hz_parties     hp
      WHERE  hp.party_id = in_paty_id
      ;
    -- �ڋq�X�e�[�^�X�擾�J�[�\�����R�[�h�^
    get_cust_status_rec  get_cust_status_cur%ROWTYPE;
--
    -- ���~���R�`�F�b�N�J�[�\��
    CURSOR check_approval_reason_cur(
      iv_approval_reason IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      approval_reason
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_approval_reason
      AND    flvv.lookup_code = iv_approval_reason
      ;
    -- ���~���R�`�F�b�N�J�[�\�����R�[�h�^
    check_approval_reason_rec  check_approval_reason_cur%ROWTYPE;
--
    -- ���|�R�[�h�P�i�������j�`�F�b�N�J�[�\��
    CURSOR check_ar_invoice_code_cur(
      iv_ar_invoice_code IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      ar_invoice_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_ar_invoice_code
      AND    flvv.lookup_code = iv_ar_invoice_code
      ;
    -- ���|�R�[�h�P�i�������j�`�F�b�N�J�[�\�����R�[�h�^
    check_ar_invoice_code_rec  check_ar_invoice_code_cur%ROWTYPE;
--
    -- ����������P�ʃ`�F�b�N�J�[�\��
    CURSOR check_invoice_class_cur(
      iv_invoice_class IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      invoice_class
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
            ,flvv.attribute1       required_flag
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_invoice_class
      AND    flvv.lookup_code = iv_invoice_class
      ;
    -- ����������P�ʃ`�F�b�N�J�[�\�����R�[�h�^
    check_invoice_class_rec  check_invoice_class_cur%ROWTYPE;
--
    -- ���������s�T�C�N���`�F�b�N�J�[�\��
    CURSOR check_invoice_cycle_cur(
      iv_invoice_cycle IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      invoice_cycle
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_invoice_issue_cycle
      AND    flvv.lookup_code = iv_invoice_cycle
      ;
    -- ���������s�T�C�N���`�F�b�N�J�[�\�����R�[�h�^
    check_invoice_cycle_rec  check_invoice_cycle_cur%ROWTYPE;
--
    -- �������o�͌`���`�F�b�N�J�[�\��
    CURSOR check_invoice_form_cur(
      iv_invoice_form IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      invoice_form
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_invoice_form
      AND    flvv.lookup_code = iv_invoice_form
      ;
    -- �������o�͌`���`�F�b�N�J�[�\�����R�[�h�^
    check_invoice_form_rec  check_invoice_form_cur%ROWTYPE;
--
    -- �x�������`�F�b�N�J�[�\��
    CURSOR check_payment_term_cur(
      iv_payment_term IN VARCHAR2)
    IS
      SELECT rt.name   payment_term_id
      FROM   ra_terms  rt
      WHERE  rt.name   = iv_payment_term
      AND    ROWNUM    = 1
      ;
    -- �x�������`�F�b�N�J�[�\�����R�[�h�^
    check_payment_term_rec  check_payment_term_cur%ROWTYPE;
--
    -- �`�F�[���X�R�[�h�i�̔���j�`�F�b�N�J�[�\��
    CURSOR check_chain_code_cur(
      iv_chain_code IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      chain_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_xxcmm_chain_code
      AND    flvv.lookup_code = iv_chain_code
      ;
    -- �`�F�[���X�R�[�h�i�̔���j�`�F�b�N�J�[�\�����R�[�h�^
    check_chain_code_rec  check_chain_code_cur%ROWTYPE;
--
    -- �`�F�[���X�R�[�h�i�d�c�h�j�`�F�b�N�J�[�\��
    CURSOR check_edi_chain_cur(
      iv_edi_chain_code IN VARCHAR2)
    IS
      SELECT xca.edi_chain_code   edi_chain_code
      FROM   hz_cust_accounts     hca,
             xxcmm_cust_accounts  xca
      WHERE  hca.customer_class_code = cv_edi_class
      AND    hca.cust_account_id     = xca.customer_id
      AND    xca.edi_chain_code      = iv_edi_chain_code
      AND    ROWNUM = 1
      ;
    -- �`�F�[���X�R�[�h�i�d�c�h�j�`�F�b�N�J�[�\�����R�[�h�^
    check_edi_chain_rec  check_edi_chain_cur%ROWTYPE;
--
    -- �n��R�[�h�`�F�b�N�J�[�\��
    CURSOR check_cust_chiku_code_cur(
      iv_cust_chiku_code IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      cust_chiku_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_cust_chiku_code
      AND    flvv.lookup_code = iv_cust_chiku_code
      ;
    -- �n��R�[�h�`�F�b�N�J�[�\�����R�[�h�^
    check_cust_chiku_code_rec  check_cust_chiku_code_cur%ROWTYPE;
--
    -- ����敪�`�F�b�N�J�[�\��
    CURSOR check_decide_div_cur(
      iv_decide_div IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      decide_div
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_decide_div
      AND    flvv.lookup_code = iv_decide_div
      ;
    -- ����敪�`�F�b�N�J�[�\�����R�[�h�^
    check_decide_div_rec  check_decide_div_cur%ROWTYPE;
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
    -- �������p�R�[�h�`�F�b�N�J�[�\��
    CURSOR check_invoice_code_cur(
      iv_invoice_code IN VARCHAR2)
    IS
      SELECT hca.cust_account_id cust_id
      FROM   hz_cust_accounts hca
      WHERE  hca.customer_class_code = cv_seikyusho_kbn
      AND    hca.account_number      = iv_invoice_code
      ;
    -- �������p�R�[�h�`�F�b�N�J�[�\�����R�[�h�^
    check_invoice_code_rec  check_invoice_code_cur%ROWTYPE;
--
    -- �Q�ƃ^�C�v�`�F�b�N�J�[�\��
    CURSOR check_lookup_type_cur(
      iv_lookup_code IN VARCHAR2
     ,iv_lookup_type IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      lookup_code
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = iv_lookup_type
      AND    flvv.lookup_code = iv_lookup_code
      ;
    -- �Q�ƃ^�C�v�`�F�b�N�J�[�\�����R�[�h�^
    check_lookup_type_rec  check_lookup_type_cur%ROWTYPE;
--
    -- �l�Z�b�g�`�F�b�N�J�[�\��
    CURSOR check_flex_value_cur(
      iv_flex_value IN VARCHAR2)
    IS
      SELECT ffv.flex_value      flex_value
      FROM   fnd_flex_value_sets ffvs
            ,fnd_flex_values     ffv
      WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffvs.flex_value_set_name = cv_aff_dept
      AND    ffv.summary_flag         = cv_no
      AND    ffv.flex_value           = iv_flex_value
      ;
    -- �l�Z�b�g�`�F�b�N�J�[�\�����R�[�h�^
    check_flex_value_rec  check_flex_value_cur%ROWTYPE;
--
    -- �J�[�h��Ѓ`�F�b�N�J�[�\��
    CURSOR check_card_company_cur(
      iv_card_company IN VARCHAR2)
    IS
      SELECT hca.cust_account_id cust_id
      FROM   hz_cust_accounts hca
            ,xxcmm_cust_accounts xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.customer_class_code = cv_urikake_kbn
      AND    xca.card_company_div    = cv_card_company_div
      AND    hca.account_number      = iv_card_company
      ;
    -- �J�[�h��Ѓ`�F�b�N���R�[�h�^
    check_card_company_rec  check_card_company_cur%ROWTYPE;
--
    -- ���i�\�`�F�b�N�J�[�\��
    CURSOR check_price_list_cur(
      iv_price_list IN VARCHAR2)
    IS
      SELECT qlhb.list_header_id list_header_id
      FROM   qp_list_headers_tl  qlht
            ,qp_list_headers_b   qlhb
      WHERE  qlht.list_header_id    = qlhb.list_header_id
      AND    qlht.source_lang       = cv_language_ja
      AND    qlht.language          = cv_language_ja
      AND    qlhb.orig_org_id       = fnd_global.org_id
      AND    qlhb.list_type_code    = cv_list_type_prl
      AND    gd_process_date BETWEEN NVL(qlhb.start_date_active, gd_process_date)
                                 AND NVL(qlhb.end_date_active, gd_process_date)
      AND    qlht.name              = iv_price_list
      ;
    -- ���i�\�`�F�b�N���R�[�h�^
    check_price_list_rec  check_price_list_cur%ROWTYPE;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add start by Yutaka.Kuboshima
    -- ��v���ԃN���[�Y�X�e�[�^�X�擾�J�[�\��
    CURSOR get_period_status_cur(
      id_stop_approval_date IN DATE)
    IS
      SELECT gps.closing_status period_status
      FROM   gl_periods         gp      -- ��v�J�����_
            ,gl_period_statuses gps     -- ��v�J�����_�X�e�[�^�X
      WHERE  EXISTS( -- AR�A�v���P�[�V�����̃J�����_�𒊏o
                     SELECT 'X'
                     FROM   fnd_application   fa
                     WHERE  fa.application_id         = gps.application_id
                       AND  fa.application_short_name = cv_apl_short_nm_ar
             )
      AND    EXISTS( -- �c�ƃV�X�e����v����ID�̃J�����_�𒊏o
                     SELECT 'X'
                     FROM   gl_sets_of_books  gsob
                     WHERE  gsob.set_of_books_id  = gps.set_of_books_id
                       AND  gsob.name             = gv_ar_set_of_books
             )
      AND    gp.period_name              = gps.period_name
      AND    gp.period_set_name          = gv_gl_cal_code
      AND    gp.adjustment_period_flag   = cv_no
      AND    gps.adjustment_period_flag  = cv_no
      AND    id_stop_approval_date BETWEEN gps.start_date AND gps.end_date
      ;
    -- ��v���ԃN���[�Y�X�e�[�^�X�擾���R�[�h�^
    get_period_status_rec  get_period_status_cur%ROWTYPE;
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add end by Yutaka.Kuboshima
--
-- 2010/02/15 Ver1.5 E_�{�ғ�_01582 add start by Yutaka.Kuboshima
    -- �Ƒ�(������)�擾�J�[�\��
    CURSOR get_business_low_type_cur(
      in_cust_id IN NUMBER)
    IS
    SELECT xca.business_low_type business_low_type
    FROM   xxcmm_cust_accounts xca
    WHERE  xca.customer_id = in_cust_id
    ;
    -- �Ƒ�(������)�擾���R�[�h�^
    get_business_low_type_rec get_business_low_type_cur%ROWTYPE;
-- 2010/02/15 Ver1.5 E_�{�ғ�_01582 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
    -- �o�׌��ۊǏꏊ�`�F�b�N�J�[�\��
    CURSOR check_ship_storage_code_cur(
      iv_ship_storage_code IN VARCHAR2)
    IS
      SELECT msi.secondary_inventory_name secondary_inventory_name
      FROM   mtl_secondary_inventories msi
            ,mtl_parameters            mp
      WHERE  msi.organization_id          = mp.organization_id
        AND  mp.organization_code         = gv_organization_code
        AND  msi.secondary_inventory_name = iv_ship_storage_code
      ;
    -- �o�׌��ۊǏꏊ�`�F�b�N���R�[�h
    check_ship_storage_code_rec check_ship_storage_code_cur%ROWTYPE;
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add start by K.Kubo
    -- �ڋq�ǉ����`�F�b�N�J�[�\��
    CURSOR check_db_customer_cur(
      iv_customer_code IN VARCHAR2)
    IS
      SELECT xca.chain_store_code     chain_store_code
            ,xca.tsukagatazaiko_div   tsukagatazaiko_div
      FROM   hz_cust_accounts     hca,
             xxcmm_cust_accounts  xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.account_number      = iv_customer_code 
      ;
    -- �ڋq�ǉ����`�F�b�N�J�[�\�����R�[�h�^
    check_db_customer_rec  check_db_customer_cur%ROWTYPE;
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add start by S.Niki
    -- �K��Ώۋ敪�`�F�b�N�J�[�\��
    CURSOR check_homon_taisyo_kbn_cur(
      iv_vist_target_div IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      homon_taisyo_kbn
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_homon_taisyo_kbn
      AND    flvv.lookup_code = iv_vist_target_div
      ;
    -- �K��Ώۋ敪�`�F�b�N�J�[�\�����R�[�h�^
    check_homon_taisyo_kbn_rec  check_homon_taisyo_kbn_cur%ROWTYPE;
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
    -- �l�����_�R�[�h�A�c�ƈ��`�F�b�N�J�[�\��
    CURSOR check_db_code_person_cur(
      iv_customer_code IN VARCHAR2)
    IS
      SELECT xca.cnvs_base_code         cnvs_base_code
            ,xca.cnvs_business_person   cnvs_business_person
      FROM   hz_cust_accounts     hca,
             xxcmm_cust_accounts  xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.account_number      = iv_customer_code 
      ;
    -- �l�����_�R�[�h�A�c�ƈ��`�F�b�N�J�[�\�����R�[�h�^
    check_db_code_person_rec  check_db_code_person_cur%ROWTYPE;
--
    -- �l���c�ƈ��Ƌ��_�R�[�h�̕R�t���`�F�b�N�J�[�\��
    CURSOR check_db_person_relation_cur(
      iv_business_person IN VARCHAR2)
    IS
      SELECT paa.ass_attribute5   new_base_code
      FROM   per_all_people_f pap            -- �]�ƈ��}�X�^
            ,per_all_assignments_f paa       -- �A�T�C�������g�}�X�^
      WHERE  pap.person_id       = paa.person_id
      AND    pap.effective_start_date <= gd_process_date
      AND    pap.effective_end_date   >  gd_process_date
      AND    paa.effective_start_date <= gd_process_date
      AND    paa.effective_end_date   >  gd_process_date
      AND    pap.employee_number = iv_business_person
      ;
    -- �l���c�ƈ��Ƌ��_�R�[�h�̕R�t���`�F�b�N�J�[�\�����R�[�h�^
    check_db_person_relation_rec  check_db_person_relation_cur%ROWTYPE;
--
    -- �l���c�ƈ��Ƌ��_�R�[�h�̕R�t�������p�`�F�b�N�J�[�\��
    CURSOR check_db_person_rel_auth_cur(
      iv_business_person IN VARCHAR2)
    IS
      SELECT paa.ass_attribute6   old_base_code
      FROM   per_all_people_f pap            -- �]�ƈ��}�X�^
            ,per_all_assignments_f paa       -- �A�T�C�������g�}�X�^
      WHERE  pap.person_id       = paa.person_id
      AND    pap.effective_start_date <= gd_process_date
      AND    pap.effective_end_date   >  gd_process_date
      AND    paa.effective_start_date <= gd_process_date
      AND    paa.effective_end_date   >  gd_process_date
      AND    ADD_MONTHS(TRUNC(gd_process_date, 'MM') ,-3) <= TO_DATE(paa.ass_attribute2 ,'YYYY/MM/DD')
      AND    pap.employee_number = iv_business_person
      ;
    -- �l���c�ƈ��Ƌ��_�R�[�h�̕R�t�������p�`�F�b�N�J�[�\�����R�[�h�^
    check_db_person_rel_auth_rec  check_db_person_rel_auth_cur%ROWTYPE;
--
    -- ���_�R�[�h�Ɗl���c�ƈ��̕R�t���`�F�b�N�J�[�\��
    CURSOR check_db_code_relation_cur(
      iv_base_code       IN VARCHAR2
     ,iv_business_person IN VARCHAR2)
    IS
      SELECT pap.employee_number   new_employee_number
      FROM   per_all_people_f pap            -- �]�ƈ��}�X�^
            ,per_all_assignments_f paa       -- �A�T�C�������g�}�X�^
      WHERE  pap.person_id       = paa.person_id
      AND    pap.effective_start_date <= gd_process_date
      AND    pap.effective_end_date   >  gd_process_date
      AND    paa.effective_start_date <= gd_process_date
      AND    paa.effective_end_date   >  gd_process_date
      AND    paa.ass_attribute5  = iv_base_code
      AND    pap.employee_number = iv_business_person
      ;
    -- ���_�R�[�h�Ɗl���c�ƈ��̕R�t���`�F�b�N���R�[�h�^
    check_db_code_relation_rec  check_db_code_relation_cur%ROWTYPE;
--
    -- ���_�R�[�h�Ɗl���c�ƈ��̕R�t�������p�`�F�b�N�J�[�\��
    CURSOR check_db_code_rel_auth_cur(
      iv_base_code       IN VARCHAR2
     ,iv_business_person IN VARCHAR2)
    IS
      SELECT pap.employee_number   old_employee_number
      FROM   per_all_people_f pap            -- �]�ƈ��}�X�^
            ,per_all_assignments_f paa       -- �A�T�C�������g�}�X�^
      WHERE  pap.person_id       = paa.person_id
      AND    pap.effective_start_date <= gd_process_date
      AND    pap.effective_end_date   >  gd_process_date
      AND    paa.effective_start_date <= gd_process_date
      AND    paa.effective_end_date   >  gd_process_date
      AND    ADD_MONTHS(TRUNC(gd_process_date, 'MM') ,-3) <= TO_DATE(paa.ass_attribute2 ,'YYYY/MM/DD')
      AND    paa.ass_attribute6  = iv_base_code
      AND    pap.employee_number = iv_business_person
      ;
    -- ���_�R�[�h�Ɗl���c�ƈ��̕R�t�������p�`�F�b�N���R�[�h�^
    check_db_code_rel_auth_rec  check_db_code_rel_auth_cur%ROWTYPE;
--
    -- �V�K�|�C���g�敪�`�F�b�N�J�[�\��
    CURSOR check_new_point_div_cur(
      iv_new_point_div IN VARCHAR2)
    IS
      SELECT flvv.lookup_code      new_point_div
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type = cv_new_point_div_type
      AND    flvv.lookup_code = iv_new_point_div
      ;
    -- �ڋq�X�e�[�^�X�`�F�b�N�J�[�\�����R�[�h�^
    check_new_point_div_rec  check_new_point_div_cur%ROWTYPE;
--
    -- �Љ�c�ƈ����݃`�F�b�N�J�[�\��
    CURSOR check_db_intro_person_cur(
      iv_customer_code IN VARCHAR2)
    IS
      SELECT xca.intro_business_person  intro_business_person
      FROM   hz_cust_accounts     hca,
             xxcmm_cust_accounts  xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.account_number      = iv_customer_code 
      ;
    -- �Љ�c�ƈ����݃`�F�b�N�J�[�\�����R�[�h�^
    check_db_intro_person_rec  check_db_intro_person_cur%ROWTYPE;
--
    -- �]�ƈ��}�X�^�`�F�b�N�J�[�\��
    CURSOR check_db_mst_person_cur(
      iv_business_person IN VARCHAR2)
    IS
      SELECT pap.employee_number      employee_number
      FROM   per_all_people_f pap     -- �]�ƈ��}�X�^
      WHERE  pap.employee_number = iv_business_person
      ;
    -- �]�ƈ��}�X�^�`�F�b�N�J�[�\�����R�[�h�^
    check_db_mst_person_rec  check_db_mst_person_cur%ROWTYPE;
--
    -- �Љ�_���݃`�F�b�N�J�[�\��
    CURSOR check_db_intro_base_code_cur(
      iv_customer_code IN VARCHAR2)
    IS
      SELECT xca.intro_base_code  intro_base_code
      FROM   hz_cust_accounts     hca,
             xxcmm_cust_accounts  xca
      WHERE  hca.cust_account_id     = xca.customer_id
      AND    hca.account_number      = iv_customer_code 
      ;
    -- �Љ�_���݃`�F�b�N�J�[�\�����R�[�h�^
    check_db_intro_base_code_rec  check_db_intro_base_code_cur%ROWTYPE;
--
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ڋq�ꊇ�X�V�pCSV���擾
    << check_upload_file_loop >>
    FOR check_upload_file_rec IN check_upload_file_cur( in_file_id,
                                                        iv_format_pattern)
    LOOP
      lv_upload_file_name := check_upload_file_rec.file_name;
    END LOOP check_upload_file_loop;
    -- �ڋq�ꊇ�X�V�pCSV���擾���s���A�G���[
    IF (lv_upload_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_csv_msg);
      lv_errbuf := lv_errmsg;
      RAISE get_csv_err_expt;
    END IF;
--
    --�\���̏�����
    lr_cust_data_table.delete;
--
    --�t�@�C���A�b�v���[�hIF�e�[�u�����ABLOB�f�[�^��ϊ�����������\���̂��擾����
    xxccp_common_pkg2.blob_to_varchar2(in_file_id,
                                       lr_cust_data_table,
                                       lv_errbuf,
                                       lv_retcode,
                                       lv_errmsg);
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_csv_msg);
      lv_errbuf := lv_errmsg;
      RAISE get_csv_err_expt;
    END IF;
--
    <<cust_data_wk_loop>>
    FOR ln_index IN lr_cust_data_table.first..lr_cust_data_table.last LOOP
      --�G���[�`�F�b�N�ϐ�������
      lv_check_status := cv_status_normal;
      --�擾����������\���̂��G���[�`�F�b�N��A�}��
      lv_temp := lr_cust_data_table(ln_index);
--
      --����̂݃w�b�_�`�F�b�N
      IF (ln_first_data = 1) THEN
        ln_first_data := 0;
        --�ڋq�敪�擾
        lv_customer_class := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
                                                                    ,1);
        --�擾����������\���̂̂P�s�P���ږڂ��u�ڋq�敪�v�ȊO�̏ꍇ�̓G���[�Ƃ���
        IF (lv_customer_class <> cv_cust_class) THEN
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_invalid_header_msg
                         );
          lv_errmsg := gv_out_msg;
          lv_errbuf := gv_out_msg;
          RAISE invalid_data_expt;
        END IF;
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
        -- �w�b�_���ڐ��̃`�F�b�N
        ln_item_num := LENGTH(lv_temp) - LENGTH(REPLACE(lv_temp, cv_comma, NULL)) + 1;
        -- ���ڐ�����v���Ȃ��ꍇ
        IF (gn_item_num <> ln_item_num) THEN
          -- �G���[���b�Z�[�W�\��
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_item_num_err_msg
                          ,iv_token_name1  => cv_table
                          ,iv_token_value1 => cv_xxcmm_003_a29c_name
                          ,iv_token_name2  => cv_count_token
                          ,iv_token_value2 => TO_CHAR(ln_item_num)
                         );
          lv_errmsg := gv_out_msg;
          lv_errbuf := gv_out_msg;
          RAISE invalid_data_expt;
        END IF;
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
      END IF;
--
      --�w�b�_�f�[�^�ǂݔ�΂�
      IF (lv_customer_class = cv_cust_class) THEN
        ln_first_data := 0;
      ELSE
        --�ڋq�R�[�h�擾
        lv_customer_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
                                                                   ,5);
        --�ڋq�R�[�h�̕K�{�`�F�b�N
        IF   (lv_customer_code IS NULL)
          OR (lv_customer_code = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�ڋq�R�[�h�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        IF (lv_customer_code IS NOT NULL) THEN
          --�ڋq�R�[�h���݃`�F�b�N
          << check_cust_code_loop >>
          FOR check_cust_code_rec IN check_cust_code_cur( lv_customer_code )
          LOOP
            lv_cust_code_mst := check_cust_code_rec.cust_code;
            ln_cust_id       := check_cust_code_rec.cust_id;
            ln_party_id      := check_cust_code_rec.party_id;
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
            lv_cust_customer_class := check_cust_code_rec.cust_kbn;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
          END LOOP check_cust_code_loop;
          IF (lv_cust_code_mst IS NULL) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�ڋq�R�[�h�}�X�^�[���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_cust
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_customer_code
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_cust_acct_table
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
        END IF;
--
        --�ڋq�ǉ���񑶍݃`�F�b�N
        IF (ln_cust_id IS NOT NULL) THEN
          --�ڋq�ǉ���񑶍݃`�F�b�N
          << check_cust_addon_loop >>
          FOR check_cust_addon_rec IN check_cust_addon_cur( ln_cust_id )
          LOOP
            ln_cust_addon_mst := check_cust_addon_rec.customer_id;
          END LOOP check_cust_addon_loop;
        END IF;
        IF (ln_cust_addon_mst IS NULL) THEN
          --�ڋq�ǉ����G���[
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�ڋq�R�[�h�}�X�^�[���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_cust_addon_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
        END IF;
--
        --�ڋq�敪�擾
        lv_customer_class := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
                                                                    ,1);
        --�ڋq�敪���݃`�F�b�N
        << check_cust_class_loop >>
        FOR check_cust_class_rec IN check_cust_class_cur( lv_customer_class )
        LOOP
          lv_cust_class_mst := check_cust_class_rec.cust_class;
        END LOOP check_cust_class_loop;
        IF (lv_cust_class_mst IS NULL) THEN
          lv_check_status   := cv_status_error;
          lv_retcode        := cv_status_error;
          --�ڋq�敪�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_lookup_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_class
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_customer_class
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�ڋq�敪�̌^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_cust_class      --���ږ���
                                            ,lv_customer_class  --�ڋq�敪
                                            ,2                  --���ڒ�
                                            ,NULL               --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok         --�K�{�t���O
                                            ,cv_element_vc2     --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf     --�G���[�o�b�t�@
                                            ,lv_item_retcode    --�G���[�R�[�h
                                            ,lv_item_errmsg);   --�G���[���b�Z�[�W
        --�ڋq�敪�����݂��A���^�E�����`�F�b�N�G���[��
        IF (lv_customer_class IS NOT NULL)
          AND (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
--�s�ID007 2007/02/24 add start
          lv_retcode      := cv_status_error;
--add end
          --�ڋq�敪�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_class
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_customer_class
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg);
        END IF;
--
        --�ڋq���̎擾
        lv_customer_name := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
                                                                   ,6);
        --�ڋq���̂̕K�{�`�F�b�N
        IF (lv_customer_name = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�ڋq���̕K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_name
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        IF (lv_customer_name IS NOT NULL) THEN
          --�ڋq���̂̌^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_cust_name      --���ږ���
                                              ,lv_customer_name  --�ڋq����
                                              ,100               --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�ڋq���̂����݂��A���^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�ڋq���̃G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_cust_name
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_customer_name
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg);
          END IF;
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
          --�S�p�����`�F�b�N
          IF (xxccp_common_pkg.chk_double_byte(lv_customer_name) = FALSE) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�S�p�����`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_double_byte_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_cust_name
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_customer_name
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
        END IF;
--
        --�ڋq���̃J�i�擾
        lv_cust_name_kana := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,7);
        --�ڋq���̃J�i�̌^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_cust_name_kana  --���ږ��̃J�i
                                            ,lv_cust_name_kana  --�ڋq���̃J�i
                                            ,50                 --���ڒ�
                                            ,NULL               --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok         --�K�{�t���O
                                            ,cv_element_vc2     --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf     --�G���[�o�b�t�@
                                            ,lv_item_retcode    --�G���[�R�[�h
                                            ,lv_item_errmsg);   --�G���[���b�Z�[�W
        --�ڋq���̃J�i�����݂��A���^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�ڋq���̃J�i�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_name_kana
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_cust_name_kana
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg);
        END IF;
-- 2009/03/25 Ver1.1 modify start by Yutaka.Kuboshima
--        --�ڋq���̃J�i�̑S�p�J�^�J�i�`�F�b�N
--        IF    (lv_cust_name_kana <> cv_null_bar)
--          AND (xxccp_common_pkg.chk_double_byte_kana( lv_cust_name_kana ) = FALSE) THEN
--          lv_check_status := cv_status_error;
--          lv_retcode      := cv_status_error;
--          --�S�p�J�^�J�i�`�F�b�N�G���[���b�Z�[�W�擾
--          gv_out_msg := xxccp_common_pkg.get_msg(
--                           iv_application  => gv_xxcmm_msg_kbn
--                          ,iv_name         => cv_double_byte_kana_msg
--                          ,iv_token_name1  => cv_cust_code
--                          ,iv_token_value1 => lv_customer_code
--                          ,iv_token_name2  => cv_col_name
--                          ,iv_token_value2 => cv_cust_name_kana
--                          ,iv_token_name3  => cv_input_val
--                          ,iv_token_value3 => lv_cust_name_kana
--                         );
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.LOG
--            ,buff   => gv_out_msg);
--        END IF;
        --�ڋq���̃J�i�̔��p�����`�F�b�N
        IF (NVL(xxccp_common_pkg.chk_single_byte(lv_cust_name_kana), TRUE) = FALSE) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --���p�����`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_single_byte_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_name_kana
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_cust_name_kana
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
-- 2009/03/25 Ver1.1 modify end by Yutaka.Kuboshima
--
        --���̎擾
        lv_cust_name_ryaku := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,8);
--
        --���̂̌^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_ryaku            --���ږ��̃J�i
                                            ,lv_cust_name_ryaku  --�ڋq���̃J�i
-- 2010/01/27 Ver1.4 E_�{�ғ�_01279 modify start by Yutaka.Kuboshima
--                                            ,50                  --���ڒ�
                                            ,80                  --���ڒ�
-- 2010/01/27 Ver1.4 E_�{�ғ�_01279 modify end by Yutaka.Kuboshima
                                            ,NULL                --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok          --�K�{�t���O
                                            ,cv_element_vc2      --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf      --�G���[�o�b�t�@
                                            ,lv_item_retcode     --�G���[�R�[�h
                                            ,lv_item_errmsg);    --�G���[���b�Z�[�W
        --���̌^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --���̃G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_ryaku
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_cust_name_ryaku
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg);
        END IF;
--
        --�Ƒԁi�����ށj�擾
        lv_business_low_type := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                       ,30);
                                                                       ,32);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
-- 2009/10/23 Ver1.2 modify start by Yutaka.Kuboshima
--        --�Ƒԁi�����ށj�̕K�{�`�F�b�N
--        IF (lv_business_low_type = cv_null_bar) THEN
--          lv_check_status := cv_status_error;
--          lv_retcode      := cv_status_error;
--          --�Ƒԁi�����ށj�K�{�G���[���b�Z�[�W�擾
--          gv_out_msg := xxccp_common_pkg.get_msg(
--                           iv_application  => gv_xxcmm_msg_kbn
--                          ,iv_name         => cv_required_err_msg
--                          ,iv_token_name1  => cv_cust_code
--                          ,iv_token_value1 => lv_customer_code
--                          ,iv_token_name2  => cv_col_name
--                          ,iv_token_value2 => cv_bus_low_type
--                         );
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.LOG
--            ,buff   => gv_out_msg);
--        END IF;
--        --�Ƒԁi�����ށj��-�łȂ��ꍇ
--        IF (lv_business_low_type <> cv_null_bar) THEN
--          --�Ƒԁi�����ށj���݃`�F�b�N
--          << check_business_low_type_loop >>
--          FOR check_business_low_rec IN check_business_low_cur( lv_business_low_type )
--          LOOP
--            lv_business_low_mst := check_business_low_rec.business_low_type;
--          END LOOP check_business_low_type_loop;
--          IF (lv_business_low_mst IS NULL) THEN
--            lv_check_status   := cv_status_error;
--            lv_retcode        := cv_status_error;
--            --�Ƒԁi�����ށj�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W�擾
--            gv_out_msg := xxccp_common_pkg.get_msg(
--                             iv_application  => gv_xxcmm_msg_kbn
--                            ,iv_name         => cv_lookup_err_msg
--                            ,iv_token_name1  => cv_cust_code
--                            ,iv_token_value1 => lv_customer_code
--                            ,iv_token_name2  => cv_col_name
--                            ,iv_token_value2 => cv_bus_low_type
--                            ,iv_token_name3  => cv_input_val
--                            ,iv_token_value3 => lv_business_low_type
--                           );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => gv_out_msg);
--          END IF;
--          --�Ƒԁi�����ށj�`�F�b�N
--          xxccp_common_pkg2.upload_item_check( cv_bus_low_type       --�Ƒԁi�����ށj
--                                              ,lv_business_low_type  --�Ƒԁi�����ށj
--                                              ,2                     --���ڒ�
--                                              ,NULL                  --���ڒ��i�����_�ȉ��j
--                                              ,cv_null_ok            --�K�{�t���O
--                                              ,cv_element_vc2        --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
--                                              ,lv_item_errbuf        --�G���[�o�b�t�@
--                                              ,lv_item_retcode       --�G���[�R�[�h
--                                              ,lv_item_errmsg);      --�G���[���b�Z�[�W
--          --�Ƒԁi�����ށj�^�E�����`�F�b�N�G���[��
--          IF (lv_item_retcode <> cv_status_normal) THEN
--            lv_check_status := cv_status_error;
--            lv_retcode      := cv_status_error;
--            --�Ƒԁi�����ށj�G���[���b�Z�[�W�擾
--            gv_out_msg := xxccp_common_pkg.get_msg(
--                             iv_application  => gv_xxcmm_msg_kbn
--                            ,iv_name         => cv_val_form_err_msg
--                            ,iv_token_name1  => cv_cust_code
--                            ,iv_token_value1 => lv_customer_code
--                            ,iv_token_name2  => cv_col_name
--                            ,iv_token_value2 => cv_bus_low_type
--                            ,iv_token_name3  => cv_input_val
--                            ,iv_token_value3 => lv_business_low_type
--                           );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => gv_out_msg
--            );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => lv_item_errmsg
--            );
--          END IF;
--        END IF;
        --�Ƒԁi�����ށj�`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_bus_low_type       --�Ƒԁi�����ށj
                                            ,lv_business_low_type  --�Ƒԁi�����ށj
                                            ,2                     --���ڒ�
                                            ,NULL                  --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok            --�K�{�t���O
                                            ,cv_element_vc2        --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf        --�G���[�o�b�t�@
                                            ,lv_item_retcode       --�G���[�R�[�h
                                            ,lv_item_errmsg);      --�G���[���b�Z�[�W
        --�Ƒԁi�����ށj�^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�Ƒԁi�����ށj�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_bus_low_type
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_business_low_type
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        -- �ڋq�敪'10','12','13','14','15','16','17'�̏ꍇ�A�G���[�`�F�b�N���s��
        IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_trust_corp, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn, cv_keikaku_kbn)) THEN
          --�Ƒԁi�����ށj�̑��փ`�F�b�N
          -- �ڋq�敪'10'(�ڋq)�A'12'(��l�ڋq)�A'15'(�X�܉c��)�̏ꍇ�A���͕K�{
          IF (lv_business_low_type = cv_null_bar)
            AND (lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_uesama_kbn, cv_tenpo_kbn ) )
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�Ƒԁi�����ށj���փ`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_bus_low_type
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�Ƒԁi�����ށj��-�łȂ��ꍇ
          IF (lv_business_low_type <> cv_null_bar) THEN
            --�Ƒԁi�����ށj���݃`�F�b�N
            << check_business_low_type_loop >>
            FOR check_business_low_rec IN check_business_low_cur( lv_business_low_type )
            LOOP
              lv_business_low_mst := check_business_low_rec.business_low_type;
            END LOOP check_business_low_type_loop;
            IF (lv_business_low_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --�Ƒԁi�����ށj�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_bus_low_type
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_business_low_type
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
-- 2009/10/23 Ver1.2 modify start by Yutaka.Kuboshima
--
        --�ڋq�X�e�[�^�X�擾
        lv_customer_status := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,9);
        --�ڋq�X�e�[�^�X�̕K�{�`�F�b�N
        IF (lv_customer_status = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�ڋq�X�e�[�^�X�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_status
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
        END IF;
        --�ڋq�X�e�[�^�X��-�łȂ��ꍇ
        IF (lv_customer_status <> cv_null_bar) THEN
          --�ڋq�X�e�[�^�X���݃`�F�b�N
          << check_cust_status_loop >>
          FOR check_cust_status_rec IN check_cust_status_cur( lv_customer_status )
          LOOP
            lv_cust_status_mst := check_cust_status_rec.cust_status;
          END LOOP check_cust_status_loop;
          IF (lv_cust_status_mst IS NULL) THEN
            lv_check_status    := cv_status_error;
            lv_retcode         := cv_status_error;
            --�ڋq�X�e�[�^�X�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_cust_status
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_customer_status
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
          END IF;
          --�ڋq�X�e�[�^�X���Q�ƕ\�ɑ��݂���ꍇ�A�ύX�`�F�b�N
          IF (lv_cust_status_mst IS NOT NULL) THEN
            --���s�ڋq�X�e�[�^�X�擾
            << get_cust_status_loop >>
            FOR get_cust_status_rec IN get_cust_status_cur( ln_party_id )
            LOOP
              lv_get_cust_status := get_cust_status_rec.cust_status;
            END LOOP get_cust_status_loop;
            --�X�e�[�^�X���ύX�\���`�F�b�N
            IF (xxcmm_003common_pkg.cust_status_update_allow( lv_customer_class
                                                             ,lv_get_cust_status
                                                             ,lv_customer_status) <> cv_status_normal) THEN
                lv_check_status  := cv_status_error;
                lv_retcode       := cv_status_error;
                --�ύX�s�\�G���[���b�Z�[�W�擾
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_status_func_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_pre_status
                                ,iv_token_value2 => lv_get_cust_status
                                ,iv_token_name3  => cv_will_status
                                ,iv_token_value3 => lv_customer_status
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
            END IF;
            IF (lv_customer_status = cv_stop_approved) THEN
-- 2010/02/15 Ver1.5 E_�{�ғ�01582 add start by Yutaka.Kuboshima
              -- ���ݐݒ肳��Ă���Ƒ�(������)���擾
              << get_business_low_type_loop >>
              FOR get_business_low_type_rec IN get_business_low_type_cur( ln_cust_id )
              LOOP
                lv_business_low_type_now := get_business_low_type_rec.business_low_type;
              END LOOP get_business_low_type_loop;
              -- �V�����ݒ肷��Ƒ�(������)��NOT NULL ���A'-'�ȊO���A���ݐݒ肳��Ă���Ƒ�(������)�ƈႤ�ꍇ
              IF (lv_business_low_type IS NOT NULL)
                AND (lv_business_low_type <> cv_null_bar)
                AND (lv_business_low_type_now <> lv_business_low_type)
              THEN
                lv_business_low_type_now := lv_business_low_type;
              END IF;
-- 2010/02/15 Ver1.5 E_�{�ғ�01582 add end by Yutaka.Kuboshima
              --�ڋq�X�e�[�^�X�ύX�`�F�b�N
              xxcmm_cust_sts_chg_chk_pkg.main( ln_cust_id
-- 2010/02/15 Ver1.5 E_�{�ғ�01582 modify start by Yutaka.Kuboshima
--                                              ,lv_customer_status
                                              ,lv_business_low_type_now
-- 2010/02/15 Ver1.5 E_�{�ғ�01582 modify end by Yutaka.Kuboshima
                                              ,lv_item_retcode
                                              ,lv_item_errmsg);
              IF (lv_item_retcode = cv_modify_err) THEN
--�s�ID007 2007/02/24 modify start
--                lv_cust_status_mst := cv_status_error;
                lv_check_status  := cv_status_error;
--modify end
                lv_retcode       := cv_status_error;
                --�ڋq�X�e�[�^�X�ύX�`�F�b�N�G���[���b�Z�[�W�擾
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_status_modify_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_input_val
                                ,iv_token_value2 => lv_customer_status
                                ,iv_token_name3  => cv_ret_code
                                ,iv_token_value3 => lv_item_retcode
                                ,iv_token_name4  => cv_ret_msg
                                ,iv_token_value4 => lv_item_errmsg
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              END IF;
            END IF;
          END IF;
        END IF;
--
        --���~���R�擾
        lv_approval_reason := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,10);
        --���~���R��-�łȂ��ꍇ
        IF (lv_approval_reason <> cv_null_bar) THEN
          --���~���R���݃`�F�b�N
          << check_approval_reason_loop >>
          FOR check_approval_reason_rec IN check_approval_reason_cur( lv_approval_reason )
          LOOP
            lv_appr_reason_mst := check_approval_reason_rec.approval_reason;
          END LOOP check_approval_reason_loop;
          IF (lv_appr_reason_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --���~���R�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_appr_reason
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_approval_reason
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --���~���R�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_appr_reason        --���~���R
                                              ,lv_approval_reason    --���~���R
                                              ,1                     --���ڒ�
                                              ,NULL                  --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok            --�K�{�t���O
                                              ,cv_element_vc2        --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf        --�G���[�o�b�t�@
                                              ,lv_item_retcode       --�G���[�R�[�h
                                              ,lv_item_errmsg);      --�G���[���b�Z�[�W
          --���~���R�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --���~���R�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_appr_reason
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_approval_reason
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --���~���ϓ��擾
        lv_approval_date := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
                                                                   ,11);
        --���~���ϓ���NULL�łȂ��ꍇ
        IF (lv_approval_date <> cv_null_bar) THEN
          --���~���ϓ��^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_appr_date      --���~���ϓ�
                                              ,lv_approval_date  --���~���ϓ�
                                              ,NULL              --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_dat    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --���~���ϓ��^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --���~���ϓ��G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_appr_date
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_approval_date
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add start by Yutaka.Kuboshima
          --�ڋq�X�e�[�^�X��'90'(���~���ٍ�)�ɕύX���鏉��̂�
          --�������`�F�b�N�A��v���ԃ`�F�b�N�����{
          IF (lv_customer_status = cv_stop_approved)
            AND (lv_get_cust_status <> lv_customer_status)
            AND (lv_item_retcode = cv_status_normal)
          THEN
            --�������`�F�b�N
            --�Ɩ����t��薢�����̏ꍇ�̓G���[
            IF (TO_DATE(lv_approval_date, cv_date_format) > gd_process_date) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --���~���ϓ����������b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_stop_date_future_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_input_val
                              ,iv_token_value2 => lv_approval_date
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
            ELSE
              --��v���ԃN���[�Y�X�e�[�^�X�擾
              << get_period_status_loop >>
              FOR get_period_status_rec IN get_period_status_cur(TO_DATE(lv_approval_date, cv_date_format))
              LOOP
                lv_period_status := get_period_status_rec.period_status;
              END LOOP get_period_status_loop;
              --
              --��v���Ԃ��N���[�Y���Ă�����t���w�肵�Ă���ꍇ
              IF (lv_period_status = cv_close_status) THEN
                lv_check_status := cv_status_error;
                lv_retcode      := cv_status_error;
                --���~���ϓ��Ó������b�Z�[�W�擾
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_stop_date_val_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_input_val
                                ,iv_token_value2 => lv_approval_date
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => lv_item_errmsg
                );
              END IF;
            END IF;
          END IF;
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add end by Yutaka.Kuboshima
        END IF;
--
        --���|�R�[�h�P�i�������j�擾
        lv_ar_invoice_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,14);
        --���|�R�[�h�P�i�������j��-�łȂ��ꍇ
        IF (lv_ar_invoice_code <> cv_null_bar) THEN
          --���|�R�[�h�P�i�������j���݃`�F�b�N
          << check_ar_invoice_code_loop >>
          FOR check_ar_invoice_code_rec IN check_ar_invoice_code_cur( lv_ar_invoice_code )
          LOOP
            lv_ar_invoice_code_mst := check_ar_invoice_code_rec.ar_invoice_code;
          END LOOP check_ar_invoice_code_loop;
          IF (lv_ar_invoice_code_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --���|�R�[�h�P�i�������j���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ar_invoice
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ar_invoice_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --���|�R�[�h�P�i�������j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_ar_invoice       --���|�R�[�h�P�i�������j
                                              ,lv_ar_invoice_code  --���|�R�[�h�P�i�������j
                                              ,12                  --���ڒ�
                                              ,NULL                --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok          --�K�{�t���O
                                              ,cv_element_vc2      --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf      --�G���[�o�b�t�@
                                              ,lv_item_retcode     --�G���[�R�[�h
                                              ,lv_item_errmsg);    --�G���[���b�Z�[�W
          --���|�R�[�h�P�i�������j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --���|�R�[�h�P�i�������j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ar_invoice
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ar_invoice_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --���|�R�[�h�Q�i���Ə��j�擾
        lv_ar_location_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
                                                                      ,15);
        --���|�R�[�h�Q�i���Ə��j��-�łȂ��ꍇ
        IF (lv_ar_location_code <> cv_null_bar) THEN
          --���|�R�[�h�Q�i���Ə��j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_ar_location_code  --���|�R�[�h�Q�i���Ə��j
                                              ,lv_ar_location_code  --���|�R�[�h�Q�i���Ə��j
                                              ,12                   --���ڒ�
                                              ,NULL                 --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok           --�K�{�t���O
                                              ,cv_element_vc2       --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf       --�G���[�o�b�t�@
                                              ,lv_item_retcode      --�G���[�R�[�h
                                              ,lv_item_errmsg);     --�G���[���b�Z�[�W
          --���|�R�[�h�Q�i���Ə��j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --���|�R�[�h�Q�i���Ə��j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ar_location_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ar_location_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --���|�R�[�h�R�i���̑��j�擾
        lv_ar_others_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
                                                                    ,16);
        --���|�R�[�h�R�i���̑��j��-�łȂ��ꍇ
        IF (lv_ar_others_code <> cv_null_bar) THEN
          --���|�R�[�h�R�i���̑��j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_ar_others_code  --���|�R�[�h�R�i���̑��j
                                              ,lv_ar_others_code  --���|�R�[�h�R�i���̑��j
                                              ,12                 --���ڒ�
                                              ,NULL               --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok         --�K�{�t���O
                                              ,cv_element_vc2     --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf     --�G���[�o�b�t�@
                                              ,lv_item_retcode    --�G���[�R�[�h
                                              ,lv_item_errmsg);   --�G���[���b�Z�[�W
          --���|�R�[�h�R�i���̑��j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --���|�R�[�h�R�i���̑��j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ar_others_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ar_others_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --���������s�敪�擾
-- 2009/10/23 Ver1.2 modify start by Yutaka.Kuboshima
-- �����������s�敪 -> ����������P�ʂɕύX
--
--        lv_invoice_class := xxccp_common_pkg.char_delim_partition(  lv_temp
--                                                                   ,cv_comma
--                                                                   ,17);
--        --���������s�敪�̕K�{�`�F�b�N
--        IF (lv_invoice_class = cv_null_bar) THEN
--          lv_check_status := cv_status_error;
--          lv_retcode      := cv_status_error;
--          --���������s�敪�K�{�G���[���b�Z�[�W�擾
--          gv_out_msg := xxccp_common_pkg.get_msg(
--                           iv_application  => gv_xxcmm_msg_kbn
--                          ,iv_name         => cv_required_err_msg
--                          ,iv_token_name1  => cv_cust_code
--                          ,iv_token_value1 => lv_customer_code
--                          ,iv_token_name2  => cv_col_name
--                          ,iv_token_value2 => cv_invoice_kbn
--                         );
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.LOG
--            ,buff   => gv_out_msg);
--        END IF;
--        IF (lv_invoice_class <> cv_null_bar) THEN
--          --���������s�敪���݃`�F�b�N
--          << check_invoice_class_loop >>
--          FOR check_invoice_class_rec IN check_invoice_class_cur( lv_invoice_class )
--          LOOP
--            lv_invoice_class_mst := check_invoice_class_rec.invoice_class;
--          END LOOP check_invoice_class_loop;
--          IF (lv_invoice_class_mst IS NULL) THEN
--            lv_check_status   := cv_status_error;
--            lv_retcode        := cv_status_error;
--            --���������s�敪���݃`�F�b�N�G���[���b�Z�[�W�擾
--            gv_out_msg := xxccp_common_pkg.get_msg(
--                             iv_application  => gv_xxcmm_msg_kbn
--                            ,iv_name         => cv_lookup_err_msg
--                            ,iv_token_name1  => cv_cust_code
--                            ,iv_token_value1 => lv_customer_code
--                            ,iv_token_name2  => cv_col_name
--                            ,iv_token_value2 => cv_invoice_kbn
--                            ,iv_token_name3  => cv_input_val
--                            ,iv_token_value3 => lv_invoice_class
--                           );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => gv_out_msg);
--          END IF;
--          --���������s�敪�^�E�����`�F�b�N
--          xxccp_common_pkg2.upload_item_check( cv_invoice_kbn    --���������s�敪
--                                              ,lv_invoice_class  --���������s�敪
--                                              ,1                 --���ڒ�
--                                              ,NULL              --���ڒ��i�����_�ȉ��j
--                                              ,cv_null_ok        --�K�{�t���O
--                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
--                                              ,lv_item_errbuf    --�G���[�o�b�t�@
--                                              ,lv_item_retcode   --�G���[�R�[�h
--                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
--          --���������s�敪�^�E�����`�F�b�N�G���[��
--          IF (lv_item_retcode <> cv_status_normal) THEN
--            lv_check_status := cv_status_error;
--            lv_retcode      := cv_status_error;
--            --���������s�敪�G���[���b�Z�[�W�擾
--            gv_out_msg := xxccp_common_pkg.get_msg(
--                             iv_application  => gv_xxcmm_msg_kbn
--                            ,iv_name         => cv_val_form_err_msg
--                            ,iv_token_name1  => cv_cust_code
--                            ,iv_token_value1 => lv_customer_code
--                            ,iv_token_name2  => cv_col_name
--                            ,iv_token_value2 => cv_invoice_kbn
--                            ,iv_token_name3  => cv_input_val
--                            ,iv_token_value3 => lv_invoice_class
--                           );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => gv_out_msg
--            );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.LOG
--              ,buff   => lv_item_errmsg
--            );
--          END IF;
--        END IF;
--
        lv_invoice_class := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
                                                                   ,17);
        --����������P�ʌ^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_invoice_kbn    --����������P��
                                            ,lv_invoice_class  --����������P��
                                            ,1                 --���ڒ�
                                            ,NULL              --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok        --�K�{�t���O
                                            ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf    --�G���[�o�b�t�@
                                            ,lv_item_retcode   --�G���[�R�[�h
                                            ,lv_item_errmsg);  --�G���[���b�Z�[�W
        --����������P�ʌ^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --����������P�ʃG���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_invoice_kbn
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_invoice_class
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        -- �ڋq�敪'10'�̏ꍇ�̂݃G���[�`�F�b�N���s��
        IF (lv_cust_customer_class = cv_kokyaku_kbn) THEN
          --����������P�ʂ̑��փ`�F�b�N
          IF (lv_invoice_class = cv_null_bar) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --����������P�ʑ��փ`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_invoice_kbn
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          IF (lv_invoice_class <> cv_null_bar) THEN
            --����������P�ʑ��݃`�F�b�N
            << check_invoice_class_loop >>
            FOR check_invoice_class_rec IN check_invoice_class_cur( lv_invoice_class )
            LOOP
              lv_invoice_class_mst     := check_invoice_class_rec.invoice_class;
              lv_invoice_required_flag := check_invoice_class_rec.required_flag;
            END LOOP check_invoice_class_loop;
            IF (lv_invoice_class_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --����������P�ʑ��݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_invoice_kbn
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_invoice_class
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
-- 2009/10/23 Ver1.2 modify end by Yutaka.Kuboshima
--
        --���������s�T�C�N���擾
        lv_invoice_cycle := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
                                                                   ,18);
--
        --���������s�T�C�N����-�łȂ��ꍇ
        IF (lv_invoice_cycle <> cv_null_bar) THEN
          --���������s�T�C�N�����݃`�F�b�N
          << check_invoice_cycle_loop >>
          FOR check_invoice_cycle_rec IN check_invoice_cycle_cur( lv_invoice_cycle )
          LOOP
            lv_invoice_cycle_mst := check_invoice_cycle_rec.invoice_cycle;
          END LOOP check_invoice_cycle_loop;
          IF (lv_invoice_cycle_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --���������s�T�C�N�����݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_cycle
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_cycle
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --���������s�T�C�N���^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_invoice_cycle  --���������s�T�C�N��
                                              ,lv_invoice_cycle  --���������s�T�C�N��
                                              ,1                 --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --���������s�T�C�N���^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --���������s�T�C�N���G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_cycle
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_cycle
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�������o�͌`���擾
        lv_invoice_form  := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                   ,cv_comma
                                                                   ,19);
        --�������o�͌`����-�łȂ��ꍇ
        IF (lv_invoice_form <> cv_null_bar) THEN
          --�������o�͌`�����݃`�F�b�N
          << check_invoice_form_loop >>
          FOR check_invoice_form_rec IN check_invoice_form_cur( lv_invoice_form )
          LOOP
            lv_invoice_form_mst := check_invoice_form_rec.invoice_form;
          END LOOP check_invoice_form_loop;
          IF (lv_invoice_form_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�������o�͌`�����݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_ksk
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_form
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�������o�͌`���^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_invoice_ksk    --�������o�͌`��
                                              ,lv_invoice_form   --�������o�͌`��
                                              ,1                 --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�������o�͌`���^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�������o�͌`���G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_invoice_ksk
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_invoice_form
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�x�������擾
        lv_payment_term_id := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,20);
--
        --�x�������̕K�{�`�F�b�N
        IF (lv_payment_term_id = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�x�������K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_payment_term_id
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�x��������-�łȂ��ꍇ
        IF (lv_payment_term_id <> cv_null_bar) THEN
          --�x���������݃`�F�b�N
          << check_payment_term_loop >>
          FOR check_payment_term_rec IN check_payment_term_cur( lv_payment_term_id )
          LOOP
            lv_payment_term_id_mst := check_payment_term_rec.payment_term_id;
          END LOOP check_payment_term_loop;
          IF (lv_payment_term_id_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�x���������݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_id
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_id
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_payment_term
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�x�������^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_payment_term_id  --�x������
                                              ,lv_payment_term_id  --�x������
                                              ,8                   --���ڒ�
                                              ,NULL                --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok          --�K�{�t���O
                                              ,cv_element_vc2      --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf      --�G���[�o�b�t�@
                                              ,lv_item_retcode     --�G���[�R�[�h
                                              ,lv_item_errmsg);    --�G���[���b�Z�[�W
          --�x�������^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�x�������G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_id
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_id
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --��2�x�������擾
        lv_payment_term_second := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
                                                                         ,21);
        --��2�x��������-�łȂ��ꍇ
        IF (lv_payment_term_second <> cv_null_bar) THEN
          --��2�x���������݃`�F�b�N
          << check_payment_term_loop >>
          FOR check_payment_term_rec IN check_payment_term_cur( lv_payment_term_second )
          LOOP
            lv_payment_second_mst := check_payment_term_rec.payment_term_id;
          END LOOP check_payment_term_loop;
          IF (lv_payment_second_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --��2�x���������݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_second
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_second
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_payment_term
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --��2�x�������^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_payment_term_second  --��2�x������
                                              ,lv_payment_term_second  --��2�x������
                                              ,8                       --���ڒ�
                                              ,NULL                    --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok              --�K�{�t���O
                                              ,cv_element_vc2          --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf          --�G���[�o�b�t�@
                                              ,lv_item_retcode         --�G���[�R�[�h
                                              ,lv_item_errmsg);        --�G���[���b�Z�[�W
          --��2�x�������^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --��2�x�������G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_second
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_second
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --��3�x�������擾
        lv_payment_term_third  := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
                                                                         ,22);
        --��3�x��������-�łȂ��ꍇ
        IF (lv_payment_term_third <> cv_null_bar) THEN
          --��3�x���������݃`�F�b�N
          << check_payment_term_loop >>
          FOR check_payment_term_rec IN check_payment_term_cur( lv_payment_term_third )
          LOOP
            lv_payment_third_mst := check_payment_term_rec.payment_term_id;
          END LOOP check_payment_term_loop;
          IF (lv_payment_third_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --��3�x���������݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_third
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_third
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_payment_term
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --��3�x�������^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_payment_term_third  --��3�x������
                                              ,lv_payment_term_third  --��3�x������
                                              ,8                      --���ڒ�
                                              ,NULL                   --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok             --�K�{�t���O
                                              ,cv_element_vc2         --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf         --�G���[�o�b�t�@
                                              ,lv_item_retcode        --�G���[�R�[�h
                                              ,lv_item_errmsg);       --�G���[���b�Z�[�W
          --��3�x�������^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --��3�x�������G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_payment_term_third
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_payment_term_third
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�`�F�[���X�R�[�h�i�̔���j�擾
        lv_sales_chain_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
                                                                      ,23);
        --�`�F�[���X�R�[�h�i�̔���j�̕K�{�`�F�b�N
        IF (lv_sales_chain_code = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�`�F�[���X�R�[�h�i�̔���j�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_sales_chain_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�`�F�[���X�R�[�h�i�̔���j��-�łȂ��ꍇ
        IF (lv_sales_chain_code <> cv_null_bar) THEN
          --�`�F�[���X�R�[�h�i�̔���j���݃`�F�b�N
          << check_chain_code_loop >>
          FOR check_chain_code_rec IN check_chain_code_cur( lv_sales_chain_code )
          LOOP
            lv_sales_chain_code_mst := check_chain_code_rec.chain_code;
          END LOOP check_chain_code_loop;
          IF (lv_sales_chain_code_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�`�F�[���X�R�[�h�i�̔���j�`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_sales_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_sales_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�`�F�[���X�R�[�h�i�̔���j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_sales_chain_code  --�`�F�[���X�R�[�h�i�̔���j
                                              ,lv_sales_chain_code  --�`�F�[���X�R�[�h�i�̔���j
                                              ,9                    --���ڒ�
                                              ,NULL                 --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok           --�K�{�t���O
                                              ,cv_element_vc2       --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf       --�G���[�o�b�t�@
                                              ,lv_item_retcode      --�G���[�R�[�h
                                              ,lv_item_errmsg);     --�G���[���b�Z�[�W
          --�`�F�[���X�R�[�h�i�̔���j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�`�F�[���X�R�[�h�i�̔���j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_sales_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_sales_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�`�F�[���X�R�[�h�i�[�i��j�擾
        lv_delivery_chain_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
                                                                         ,25);
        --�`�F�[���X�R�[�h�i�[�i��j�̕K�{�`�F�b�N
        IF (lv_delivery_chain_code = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�`�F�[���X�R�[�h�i�[�i��j�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_delivery_chain_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�`�F�[���X�R�[�h�i�[�i��j��-�łȂ��ꍇ
        IF (lv_delivery_chain_code <> cv_null_bar) THEN
          --�`�F�[���X�R�[�h�i�[�i��j���݃`�F�b�N
          << check_chain_code_loop >>
          FOR check_chain_code_rec IN check_chain_code_cur( lv_delivery_chain_code )
          LOOP
            lv_deliv_chain_code_mst := check_chain_code_rec.chain_code;
          END LOOP check_chain_code_loop;
          IF (lv_deliv_chain_code_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�`�F�[���X�R�[�h�i�[�i��j�`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_delivery_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_delivery_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�`�F�[���X�R�[�h�i�[�i��j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_delivery_chain_code  --�`�F�[���X�R�[�h�i�[�i��j
                                              ,lv_delivery_chain_code  --�`�F�[���X�R�[�h�i�[�i��j
                                              ,9                       --���ڒ�
                                              ,NULL                    --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok              --�K�{�t���O
                                              ,cv_element_vc2          --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf          --�G���[�o�b�t�@
                                              ,lv_item_retcode         --�G���[�R�[�h
                                              ,lv_item_errmsg);        --�G���[���b�Z�[�W
          --�`�F�[���X�R�[�h�i�[�i��j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�`�F�[���X�R�[�h�i�[�i��j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_delivery_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_delivery_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�`�F�[���X�R�[�h�i�����p�j�擾
        lv_policy_chain_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
                                                                       ,27);
        --�`�F�[���X�R�[�h�i�����p�j��-�łȂ��ꍇ
        IF (lv_policy_chain_code <> cv_null_bar) THEN
          --�`�F�[���X�R�[�h�i�����p�j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_policy_chain_code  --�`�F�[���X�R�[�h�i�����p�j
                                              ,lv_policy_chain_code  --�`�F�[���X�R�[�h�i�����p�j
                                              ,30                    --���ڒ�
                                              ,NULL                  --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok            --�K�{�t���O
                                              ,cv_element_vc2        --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf        --�G���[�o�b�t�@
                                              ,lv_item_retcode       --�G���[�R�[�h
                                              ,lv_item_errmsg);      --�G���[���b�Z�[�W
          --�`�F�[���X�R�[�h�i�����p�j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�`�F�[���X�R�[�h�i�����p�j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_policy_chain_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_policy_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
--
        --�Љ�҃`�F�[��1�擾
        lv_intro_chain_code1 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
                                                                       ,28);
        --�Љ�҃`�F�[��1��-�łȂ��ꍇ
        IF (lv_intro_chain_code1 <> cv_null_bar) THEN
          --�Љ�҃`�F�[��1�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_intro_chain_code1 --�Љ�҃`�F�[��1
                                              ,lv_intro_chain_code1 --�Љ�҃`�F�[��1
                                              ,30                   --���ڒ�
                                              ,NULL                 --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok           --�K�{�t���O
                                              ,cv_element_vc2       --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf       --�G���[�o�b�t�@
                                              ,lv_item_retcode      --�G���[�R�[�h
                                              ,lv_item_errmsg);     --�G���[���b�Z�[�W
          --�Љ�҃`�F�[��1�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�Љ�҃`�F�[��1�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_intro_chain_code1
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_intro_chain_code1
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�Љ�҃`�F�[��2�擾
        lv_intro_chain_code2 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
                                                                       ,29);
        --�Љ�҃`�F�[��2��-�łȂ��ꍇ
        IF (lv_intro_chain_code2 <> cv_null_bar) THEN
          --�Љ�҃`�F�[��2�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_intro_chain_code2 --�Љ�҃`�F�[��2
                                              ,lv_intro_chain_code2 --�Љ�҃`�F�[��2
                                              ,30                   --���ڒ�
                                              ,NULL                 --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok           --�K�{�t���O
                                              ,cv_element_vc2       --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf       --�G���[�o�b�t�@
                                              ,lv_item_retcode      --�G���[�R�[�h
                                              ,lv_item_errmsg);     --�G���[���b�Z�[�W
          --�Љ�҃`�F�[��2�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�Љ�҃`�F�[��2�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_intro_chain_code2
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_intro_chain_code2
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
--
        --�`�F�[���X�R�[�h�i�d�c�h�j�擾
        lv_edi_chain_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                    ,28);
                                                                    ,30);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�`�F�[���X�R�[�h�i�d�c�h�j��-�łȂ��ꍇ
        IF (lv_edi_chain_code <> cv_null_bar) THEN
          --�`�F�[���X�R�[�h�i�d�c�h�j���݃`�F�b�N
          << check_edi_chain_loop >>
          FOR check_edi_chain_rec IN check_edi_chain_cur( lv_edi_chain_code )
          LOOP
            lv_edi_chain_mst := check_edi_chain_rec.edi_chain_code;
          END LOOP check_edi_chain_loop;
          IF (lv_edi_chain_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�`�F�[���X�R�[�h�i�d�c�h�j���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_mst_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_edi_chain
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_edi_chain_code
                            ,iv_token_name4  => cv_table
                            ,iv_token_value4 => cv_addon_cust_mst
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�`�F�[���X�R�[�h�i�d�c�h�j�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_edi_chain       --�`�F�[���X�R�[�h�i�d�c�h�j
                                              ,lv_edi_chain_code  --�`�F�[���X�R�[�h�i�d�c�h�j
                                              ,4                  --���ڒ�
                                              ,NULL               --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok         --�K�{�t���O
                                              ,cv_element_vc2     --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf     --�G���[�o�b�t�@
                                              ,lv_item_retcode    --�G���[�R�[�h
                                              ,lv_item_errmsg);   --�G���[���b�Z�[�W
          --�`�F�[���X�R�[�h�i�d�c�h�j�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�`�F�[���X�R�[�h�i�d�c�h�j�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_edi_chain
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_edi_chain_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�X�܃R�[�h�擾
        lv_store_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                ,29);
                                                                ,31);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�X�܃R�[�h��-�łȂ��ꍇ
        IF (lv_store_code <> cv_null_bar) THEN
          --�X�܃R�[�h�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_store_code     --�X�܃R�[�h
                                              ,lv_store_code     --�X�܃R�[�h
                                              ,10                --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�X�܃R�[�h�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�X�܃R�[�h�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_store_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_store_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        --�X�֔ԍ��擾
        lv_postal_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                 ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                 ,31);
                                                                 ,33);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�X�֔ԍ��̕K�{�`�F�b�N
        IF (lv_postal_code = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�X�֔ԍ��K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_postal_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�X�֔ԍ��擾��-�łȂ��ꍇ
        IF (lv_postal_code <> cv_null_bar) THEN
          --�X�֔ԍ��^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_postal_code    --�X�֔ԍ�
                                              ,lv_postal_code    --�X�֔ԍ�
                                              ,7                 --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�X�֔ԍ��^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�X�֔ԍ��G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_postal_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_postal_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
          --�X�֔ԍ����p����7���`�F�b�N
          IF (xxccp_common_pkg.chk_number(lv_postal_code) = FALSE)
            OR (LENGTHB(lv_postal_code) <> 7)
          THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�X�֔ԍ��`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_postal_code_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_postal_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_postal_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
        END IF;
--
        --�s���{���擾
        lv_state := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                           ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                           ,32);
                                                           ,34);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�s���{���̕K�{�`�F�b�N
        IF (lv_state = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�s���{���K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_state
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�s���{���擾��-�łȂ��ꍇ
        IF (lv_state <> cv_null_bar) THEN
          --�s���{���^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_state          --�s���{��
                                              ,lv_state          --�s���{��
                                              ,30                --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�s���{���^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�s���{���G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_state
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_state
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
          -- �S�p�����`�F�b�N
          IF (xxccp_common_pkg.chk_double_byte(lv_state) = FALSE) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�S�p�����`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_double_byte_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_state
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_state
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
        END IF;
--
        --�s�E��擾
        lv_city := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                          ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                          ,33);
                                                          ,35);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�s�E��̕K�{�`�F�b�N
        IF (lv_city = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�s�E��K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_city
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�s�E��擾��-�łȂ��ꍇ
        IF (lv_city <> cv_null_bar) THEN
          --�s�E��^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_city           --�s�E��
                                              ,lv_city           --�s�E��
                                              ,30                --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�s�E��^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�s�E��G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_city
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_city
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
          -- �S�p�����`�F�b�N
          IF (xxccp_common_pkg.chk_double_byte(lv_city) = FALSE) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�S�p�����`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_double_byte_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_city
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_city
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
        END IF;
--
        --�Z��1�擾
        lv_address1 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                              ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                              ,34);
                                                              ,36);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�Z��1�̕K�{�`�F�b�N
        IF (lv_address1 = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�Z��1�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_address1
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�Z��1�擾��-�łȂ��ꍇ
        IF (lv_address1 <> cv_null_bar) THEN
          --�Z��1�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_address1       --�Z��1
                                              ,lv_address1       --�Z��1
                                              ,240               --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�Z��1�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�Z��1�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address1
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address1
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
          -- �S�p�����`�F�b�N
          IF (xxccp_common_pkg.chk_double_byte(lv_address1) = FALSE) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�S�p�����`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_double_byte_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address1
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address1
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
        END IF;
--
        --�Z��2�擾
        lv_address2 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                              ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                              ,35);
                                                              ,37);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�Z��2�擾��-�łȂ��ꍇ
        IF (lv_address2 <> cv_null_bar) THEN
          --�Z��2�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_address2       --�Z��2
                                              ,lv_address2       --�Z��2
                                              ,240               --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�Z��2�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�Z��2�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address2
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address2
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
-- 2009/03/25 Ver1.1 add start by Yutaka.Kuboshima
          -- �S�p�����`�F�b�N
          IF (xxccp_common_pkg.chk_double_byte(lv_address2) = FALSE) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�S�p�����`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_double_byte_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address2
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address2
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
-- 2009/03/25 Ver1.1 add end by Yutaka.Kuboshima
        END IF;
--
        --�n��R�[�h�擾
        lv_address3 := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                              ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                              ,36);
                                                              ,38);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�n��R�[�h�̕K�{�`�F�b�N
        IF (lv_address3 = cv_null_bar) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�n��R�[�h�K�{�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_required_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_address3
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
        --�n��R�[�h��-�łȂ��ꍇ
        IF (lv_address3 <> cv_null_bar) THEN
          --�n��R�[�h���݃`�F�b�N
          << check_cust_chiku_code_loop >>
          FOR check_cust_chiku_code_rec IN check_cust_chiku_code_cur( lv_address3 )
          LOOP
            lv_cust_chiku_code_mst := check_cust_chiku_code_rec.cust_chiku_code;
          END LOOP check_cust_chiku_code_loop;
          IF (lv_cust_chiku_code_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�n��R�[�h���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address3
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address3
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�n��R�[�h�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_address3       --�n��R�[�h
                                              ,lv_address3       --�n��R�[�h
                                              ,5                 --���ڒ�
                                              ,NULL              --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok        --�K�{�t���O
                                              ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf    --�G���[�o�b�t�@
                                              ,lv_item_retcode   --�G���[�R�[�h
                                              ,lv_item_errmsg);  --�G���[���b�Z�[�W
          --�n��R�[�h�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�n��R�[�h�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_address3
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_address3
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
--
        IF (lv_customer_class = cv_trust_corp) THEN
          --�ڋq�@�l���}�X�^���݃`�F�b�N
          IF (ln_cust_id IS NOT NULL) THEN
            --�ڋq�@�l���}�X�^���݃`�F�b�N
            << check_cust_corp_loop >>
            FOR check_cust_corp_rec IN check_cust_corp_cur( ln_cust_id )
            LOOP
              ln_cust_corp_mst := check_cust_corp_rec.customer_id;
            END LOOP check_cust_corp_loop;
          END IF;
          IF (ln_cust_corp_mst IS NULL)THEN
              --�ڋq�@�l���}�X�^���G���[
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --�ڋq�@�l���}�X�^���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_corp_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
          END IF;
          --�^�M���x�z�擾�i�@�l�ڋq�̂݁j
          lv_credit_limit := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
                                                                    ,12);
          --�^�M���x�z�̕K�{�`�F�b�N
          IF (lv_credit_limit = cv_null_bar) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�^�M���x�z�K�{�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_required_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_credit_limit
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          ELSE
            --�^�M���x�z�^�E�����`�F�b�N
            xxccp_common_pkg2.upload_item_check( cv_credit_limit   --�^�M���x�z
                                                ,lv_credit_limit   --�^�M���x�z
                                                ,11                --���ڒ�
                                                ,0                 --���ڒ��i�����_�ȉ��j
                                                ,cv_null_ok        --�K�{�t���O
                                                ,cv_element_num    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                                ,lv_item_errbuf    --�G���[�o�b�t�@
                                                ,lv_item_retcode   --�G���[�R�[�h
                                                ,lv_item_errmsg);  --�G���[���b�Z�[�W
            --�^�M���x�z�^�E�����`�F�b�N�G���[��
            IF (lv_item_retcode <> cv_status_normal) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --�^�M���x�z�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_credit_limit
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_credit_limit
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
            ELSE
              --�^�E�������펞�̂ݐ��l�Ƃ��Ĉ����A�^�M���x�z���l�͈̓`�F�b�N
              ln_credit_limit := TO_NUMBER(lv_credit_limit);
              IF  ((ln_credit_limit < 0)
                OR (ln_credit_limit > 99999999999)) THEN
                --�^�M���x�z�G���[���b�Z�[�W�擾
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_trust_val_invalid
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_col_name
                                ,iv_token_value2 => cv_credit_limit
                                ,iv_token_name3  => cv_input_val
                                ,iv_token_value3 => lv_credit_limit
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              END IF;
            END IF;
          END IF;
          --����敪�擾�i�@�l�ڋq�̂݁j
          lv_decide_div := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                  ,cv_comma
                                                                  ,13);
          --����敪�̕K�{�`�F�b�N
          IF (lv_decide_div = cv_null_bar) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --����敪�K�{�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_required_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_decide
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --����敪��-�łȂ��ꍇ
          IF (lv_decide_div <> cv_null_bar) THEN
            --����敪���݃`�F�b�N
            << check_decide_div_loop >>
            FOR check_decide_div_rec IN check_decide_div_cur( lv_decide_div )
            LOOP
              lv_decide_div_mst := check_decide_div_rec.decide_div;
            END LOOP check_decide_div_loop;
            IF (lv_decide_div_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --����敪���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_decide
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_decide_div
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
            --����敪�^�E�����`�F�b�N
            xxccp_common_pkg2.upload_item_check( cv_decide         --����敪
                                                ,lv_decide_div     --����敪
                                                ,1                 --���ڒ�
                                                ,NULL              --���ڒ��i�����_�ȉ��j
                                                ,cv_null_ok        --�K�{�t���O
                                                ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                                ,lv_item_errbuf    --�G���[�o�b�t�@
                                                ,lv_item_retcode   --�G���[�R�[�h
                                                ,lv_item_errmsg);  --�G���[���b�Z�[�W
            --����敪�^�E�����`�F�b�N�G���[��
            IF (lv_item_retcode <> cv_status_normal) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --����敪�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_decide
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_decide_div
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
            END IF;
          END IF;
        END IF;
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
        -- �������p�R�[�h�擾
        lv_invoice_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                  ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                  ,37);
                                                                  ,39);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�������p�R�[�h�^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_invoice_code   --�������p�R�[�h
                                            ,lv_invoice_code   --�������p�R�[�h
                                            ,9                 --���ڒ�
                                            ,NULL              --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok        --�K�{�t���O
                                            ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf    --�G���[�o�b�t�@
                                            ,lv_item_retcode   --�G���[�R�[�h
                                            ,lv_item_errmsg);  --�G���[���b�Z�[�W
        --�������p�R�[�h�^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�������p�R�[�h�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_invoice_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_invoice_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        --
        -- �ڋq�敪'10'�̏ꍇ�̂݃G���[�`�F�b�N���s��
        IF (lv_cust_customer_class = cv_kokyaku_kbn) THEN
          -- �������p�R�[�h�̕K�{�`�F�b�N
          -- �������p�K�{�t���O��'Y'�̏ꍇ�A���͕K�{
          IF (lv_invoice_code = cv_null_bar)
            AND (lv_invoice_required_flag = cv_yes)
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�������p�R�[�h���փ`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_invoice_code
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_invoice_kbn
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_invoice_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�������p�R�[�h��-�łȂ��ꍇ
          IF (lv_invoice_code <> cv_null_bar) THEN
            --�������p�R�[�h���݃`�F�b�N
            << check_invoice_class_loop >>
            FOR check_invoice_code_rec IN check_invoice_code_cur( lv_invoice_code )
            LOOP
              ln_invoice_code_mst     := check_invoice_code_rec.cust_id;
            END LOOP check_invoice_class_loop;
            IF (ln_invoice_code_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --�������p�R�[�h���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_mst_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_invoice_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_invoice_code
                              ,iv_token_name4  => cv_table
                              ,iv_token_value4 => cv_cust_acct_table
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
        -- �Ǝ�擾
        lv_industry_div := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                  ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                  ,38);
                                                                  ,40);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�Ǝ�^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_industry_div   --�Ǝ�
                                            ,lv_industry_div   --�Ǝ�
                                            ,2                 --���ڒ�
                                            ,NULL              --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok        --�K�{�t���O
                                            ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf    --�G���[�o�b�t�@
                                            ,lv_item_retcode   --�G���[�R�[�h
                                            ,lv_item_errmsg);  --�G���[���b�Z�[�W
        --�Ǝ�^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�Ǝ�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_industry_div
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_industry_div
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        --
        -- �ڋq�敪'10','12','13','14','15','16','17'�̏ꍇ�A�G���[�`�F�b�N���s��
        IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_trust_corp, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn, cv_keikaku_kbn)) THEN
          -- �Ǝ�̕K�{�`�F�b�N
          -- �ڋq�敪'10'(�ڋq)�A'12'(��l�ڋq)�A'15'(�X�܉c��)�̏ꍇ�A���͕K�{
          IF (lv_industry_div = cv_null_bar)
            AND (lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_uesama_kbn, cv_tenpo_kbn ) )
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�Ǝ푊�փ`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_industry_div
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�Ǝ킪-�łȂ��ꍇ
          IF (lv_industry_div <> cv_null_bar) THEN
            --�Ǝ푶�݃`�F�b�N
            << check_industry_div_loop >>
            FOR check_lookup_type_rec IN check_lookup_type_cur( lv_industry_div, cv_gyotai_kbn )
            LOOP
              lv_industry_div_mst     := check_lookup_type_rec.lookup_code;
            END LOOP check_industry_div_loop;
            IF (lv_industry_div_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --�Ǝ푶�݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_industry_div
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_industry_div
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
        -- �������_�擾
        lv_bill_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                    ,39);
                                                                    ,41);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�������_�^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_bill_base_code --�������_
                                            ,lv_bill_base_code --�������_
                                            ,4                 --���ڒ�
                                            ,NULL              --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok        --�K�{�t���O
                                            ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf    --�G���[�o�b�t�@
                                            ,lv_item_retcode   --�G���[�R�[�h
                                            ,lv_item_errmsg);  --�G���[���b�Z�[�W
        --�������_�^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�������_�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_bill_base_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_bill_base_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        -- �ڋq�敪'10','12','14','20','21'�̏ꍇ�A�G���[�`�F�b�N���s��
        IF (lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn, cv_seikyusho_kbn, cv_toukatu_kbn )) THEN
          -- �������_�̕K�{�`�F�b�N
          IF (lv_bill_base_code = cv_null_bar) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�������_���փ`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_bill_base_code
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�������_��-�łȂ��ꍇ
          IF (lv_bill_base_code <> cv_null_bar) THEN
            --�������_���݃`�F�b�N
            << check_bill_base_code_loop >>
            FOR check_flex_value_rec IN check_flex_value_cur( lv_bill_base_code )
            LOOP
              lv_bill_base_code_mst     := check_flex_value_rec.flex_value;
            END LOOP check_bill_base_code_loop;
            IF (lv_bill_base_code_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --�������_���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_flex_value_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_bill_base_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_bill_base_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
        -- �������_�擾
        lv_receiv_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                      ,40);
                                                                      ,42);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�������_�^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_receiv_base_code --�������_
                                            ,lv_receiv_base_code --�������_
                                            ,4                   --���ڒ�
                                            ,NULL                --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok          --�K�{�t���O
                                            ,cv_element_vc2      --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf      --�G���[�o�b�t�@
                                            ,lv_item_retcode     --�G���[�R�[�h
                                            ,lv_item_errmsg);    --�G���[���b�Z�[�W
        --�������_�^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�������_�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_receiv_base_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_receiv_base_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        -- �ڋq�敪'10','12','14'�̏ꍇ�A�G���[�`�F�b�N���s��
        IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn)) THEN
          -- �������_�̕K�{�`�F�b�N
          IF (lv_receiv_base_code = cv_null_bar) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�������_���փ`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_receiv_base_code
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�������_��-�łȂ��ꍇ
          IF (lv_receiv_base_code <> cv_null_bar) THEN
            --�������_���݃`�F�b�N
            << check_receiv_base_code_loop >>
            FOR check_flex_value_rec IN check_flex_value_cur( lv_receiv_base_code )
            LOOP
              lv_receiv_base_code_mst     := check_flex_value_rec.flex_value;
            END LOOP check_receiv_base_code_loop;
            IF (lv_receiv_base_code_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --�������_���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_flex_value_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_receiv_base_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_receiv_base_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
        -- �[�i���_�擾
        lv_delivery_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                        ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                        ,41);
                                                                        ,43);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�[�i���_�^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_delivery_base_code --�[�i���_
                                            ,lv_delivery_base_code --�[�i���_
                                            ,4                     --���ڒ�
                                            ,NULL                  --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok            --�K�{�t���O
                                            ,cv_element_vc2        --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf        --�G���[�o�b�t�@
                                            ,lv_item_retcode       --�G���[�R�[�h
                                            ,lv_item_errmsg);      --�G���[���b�Z�[�W
        --�[�i���_�^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�[�i���_�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_delivery_base_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_delivery_base_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        -- �ڋq�敪'10','12','14'�̏ꍇ�A�G���[�`�F�b�N���s��
        IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn)) THEN
          -- �[�i���_�̕K�{�`�F�b�N
          -- �ڋq�敪'10'(�ڋq)�A'12'(��l�ڋq)�̏ꍇ�A���͕K�{
          IF (lv_delivery_base_code = cv_null_bar)
            AND (lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_uesama_kbn ) )
          THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�[�i���_���փ`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_correlation_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_delivery_base_code
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cust_class
                            ,iv_token_name3  => cv_cond_col_val
                            ,iv_token_value3 => lv_cust_customer_class
                            ,iv_token_name4  => cv_cust_code
                            ,iv_token_value4 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
          --�[�i���_��-�łȂ��ꍇ
          IF (lv_delivery_base_code <> cv_null_bar) THEN
            --�[�i���_���݃`�F�b�N
            << check_delivery_base_code_loop >>
            FOR check_flex_value_rec IN check_flex_value_cur( lv_delivery_base_code )
            LOOP
              lv_delivery_base_code_mst     := check_flex_value_rec.flex_value;
            END LOOP check_delivery_base_code_loop;
            IF (lv_delivery_base_code_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --�[�i���_���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_flex_value_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_delivery_base_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_delivery_base_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
--
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
        --�ڋq�敪�u10�F�ڋq�v�u14�F���|�Ǘ���ڋq�v�u19�F�S�ݓX�`��v�̏ꍇ
        IF ( lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_urikake_kbn, cv_hyakkaten_kbn) ) THEN
          --
          --�̔���{���S�����_�擾
          lv_sales_head_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                            ,cv_comma
                                                                            ,44);
          --
          --CSV�ɐݒ肳�ꂽ�̔���{���S�����_���C�ӂ̒l�̏ꍇ
          IF (lv_sales_head_base_code <> cv_null_bar) THEN
            --�̔���{���S�����_���݃`�F�b�N
            << check_head_base_code_loop >>
            FOR check_flex_value_rec IN check_flex_value_cur( lv_sales_head_base_code )
            LOOP
              lv_sales_head_base_code_mst := check_flex_value_rec.flex_value;
            END LOOP check_head_base_code_loop;
            IF (lv_sales_head_base_code_mst IS NULL) THEN
              lv_check_status    := cv_status_error;
              lv_retcode         := cv_status_error;
              --�̔���{���S�����_�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_flex_value_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_sales_head_base_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_sales_head_base_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
          --
          END IF;
        --
        END IF;
--
        --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�̏ꍇ
        IF ( lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
        --
          -- �l�����_�R�[�h �擾
          lv_cnvs_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
                                                                      ,45);
--
          -- �l���c�ƈ� �擾
          lv_cnvs_business_person := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                            ,cv_comma
                                                                            ,46);
--
          -- �l�����_�R�[�h�A�l���c�ƈ��̃`�F�b�N
          --
          --CSV�ɐݒ肳�ꂽ�l�����_�R�[�h��NULL�̏ꍇ
          IF ( lv_cnvs_base_code IS NULL ) THEN
            --
            --�l�����_�R�[�h��DB���݃`�F�b�N
            << check_db_base_code_loop >>
            FOR check_db_code_person_rec IN check_db_code_person_cur( lv_customer_code )
            LOOP
              lv_cnvs_base_code_mst1  := check_db_code_person_rec.cnvs_base_code;
            END LOOP check_db_base_code_loop;
            --
            --DB�ɐݒ肳�ꂽ�l�����_�R�[�h��NULL�̏ꍇ
            IF (lv_cnvs_base_code_mst1 IS NULL) THEN
              --
              --CSV�ɐݒ肳�ꂽ�l���c�ƈ���'-'�ł͂Ȃ��ꍇ(�C�ӂ̒l)
              IF ( lv_cnvs_business_person <> cv_null_bar ) THEN
              --
                --�G���[�Ώ�
                lv_business_person_flag3 := cv_yes;
              --
              ELSIF ( lv_cnvs_business_person = cv_null_bar ) THEN
              --CSV�ɐݒ肳�ꂽ�l���c�ƈ���'-'�̏ꍇ
                --
                --�ڋq�敪�u10�F�ڋq�v���ڋq�X�e�[�^�X�u30�F���F�ρv�ȏ�̏ꍇ�A�l���c�ƈ��͕K�{
                IF ( lv_cust_customer_class = cv_kokyaku_kbn  AND
                    TO_NUMBER(cv_approved_status) <= TO_NUMBER(lv_get_cust_status) ) THEN
                    --�G���[�Ώ�
                    lv_business_person_flag1 := cv_yes;
                END IF;
                --
              --
              END IF;
            --
            ELSE
            --DB�ɐݒ肳�ꂽ�l�����_�R�[�h���C�ӂ̒l�̏ꍇ
            --
              --CSV�ɐݒ肳�ꂽ�l���c�ƈ���'-'�̏ꍇ
              IF ( lv_cnvs_business_person = cv_null_bar ) THEN
                --
                --�ڋq�敪�u10�F�ڋq�v���ڋq�X�e�[�^�X�u30�F���F�ρv�ȏ�̏ꍇ�A�l���c�ƈ��͕K�{
                IF ( lv_cust_customer_class = cv_kokyaku_kbn  AND
                    TO_NUMBER(cv_approved_status) <= TO_NUMBER(lv_get_cust_status) ) THEN
                  --
                  --�G���[�Ώ�
                  lv_business_person_flag1 := cv_yes;
                ELSE
                  --�G���[�Ώ�
                  lv_business_person_flag2 := cv_yes;
                END IF;
              --
              END IF;
            --
            END IF;
          --
          ELSIF ( lv_cnvs_base_code = cv_null_bar ) THEN
          --CSV�ɐݒ肳�ꂽ�l�����_�R�[�h��'-'�̏ꍇ
          --
            --�ڋq�敪�u10�F�ڋq�v���ڋq�X�e�[�^�X�u30�F���F�ρv�ȏ�̏ꍇ�A�l�����_�R�[�h�͕K�{
            IF ( lv_cust_customer_class = cv_kokyaku_kbn  AND
                 TO_NUMBER(cv_approved_status) <= TO_NUMBER(lv_get_cust_status) ) THEN
              --�G���[�Ώ�
              lv_base_code_flag1 := cv_yes;
              --
              --�ڋq�敪�u10�F�ڋq�v���ڋq�X�e�[�^�X�u30�F���F�ρv�ȏ�̏ꍇ�A�l���c�ƈ��͕K�{
              IF ( lv_cnvs_business_person = cv_null_bar ) THEN
                --�G���[�Ώ�
                lv_business_person_flag1 := cv_yes;
                --
              END IF;
            --
            ELSE
              --CSV�ɐݒ肳�ꂽ�l���c�ƈ���NULL�̏ꍇ
              IF ( lv_cnvs_business_person IS NULL ) THEN
                --
                --�l���c�ƈ���DB���݃`�F�b�N
                << check_db_business_person_loop >>
                FOR check_db_code_person_rec IN check_db_code_person_cur( lv_customer_code )
                LOOP
                  lv_cnvs_business_person_mst1  := check_db_code_person_rec.cnvs_business_person;
                END LOOP check_db_business_person_loop;
                --
                --DB�ɐݒ肳�ꂽ�l���c�ƈ����C�ӂ̒l�̏ꍇ
                IF (lv_cnvs_business_person_mst1 IS NOT NULL) THEN
                  --
                  --�G���[�Ώ�
                  lv_base_code_flag2 := cv_yes;
                END IF;
              --
              ELSIF ( lv_cnvs_business_person <> cv_null_bar ) THEN
              --CSV�ɐݒ肳�ꂽ�l���c�ƈ���'-'�ł͂Ȃ��ꍇ(�C�ӂ̒l)
                --
                --�G���[�Ώ�
                lv_base_code_flag2 := cv_yes;
              --
              END IF;
            --
            END IF;
          --
          ELSE 
          --CSV�ɐݒ肳�ꂽ�l�����_�R�[�h�ɔC�ӂ̒l���ݒ肳��Ă���ꍇ
          --
            --CSV�ɐݒ肳�ꂽ�l���c�ƈ���NULL�̏ꍇ
            IF ( lv_cnvs_business_person IS NULL ) THEN
              --
              --�l���c�ƈ���DB���݃`�F�b�N
              << check_db_business_person_loop >>
              FOR check_db_code_person_rec IN check_db_code_person_cur( lv_customer_code )
              LOOP
                lv_cnvs_business_person_mst1  := check_db_code_person_rec.cnvs_business_person;
              END LOOP check_db_business_person_loop;
              --
              --DB�ɐݒ肳�ꂽ�l���c�ƈ���NULL�̏ꍇ
              IF (lv_cnvs_business_person_mst1 IS NULL) THEN
                --
                --�G���[�Ώ�
                lv_base_code_flag3 := cv_yes;
              END IF;
            --
            ELSIF ( lv_cnvs_business_person = cv_null_bar ) THEN
            --CSV�ɐݒ肳�ꂽ�l���c�ƈ���'-'�̏ꍇ
              --
              --�ڋq�敪�u10�F�ڋq�v���ڋq�X�e�[�^�X�u30�F���F�ρv�ȏ�̏ꍇ�A�l���c�ƈ��͕K�{
              IF ( lv_cust_customer_class = cv_kokyaku_kbn  AND
                   TO_NUMBER(cv_approved_status) <= TO_NUMBER(lv_get_cust_status) ) THEN
              --
                --�G���[�Ώ�
                lv_business_person_flag1 := cv_yes;
              --
              ELSE
                --�G���[�Ώ�
                lv_business_person_flag2 := cv_yes;
              END IF;
            --
            END IF;
          --
          END IF;
--
          --�ڋq�敪�u10�F�ڋq�v���ڋq�X�e�[�^�X�u30�F���F�ρv�ȏ�ŁA
          --�l�����_�R�[�h��'-'��ݒ肵���ꍇ�A�G���[�Ƃ���
          --�ڋq�敪�u10�F�ڋq�v���ڋq�X�e�[�^�X�u30�F���F�ρv�ȏ�ŁA
          --�l���c�ƈ���'-'��ݒ肵���ꍇ�A�G���[�Ƃ���
          IF ( lv_base_code_flag1 = cv_yes OR lv_business_person_flag1 = cv_yes ) THEN
          --
            --�ڋq�敪�u10�F�ڋq�v���ڋq�X�e�[�^�X�u30�F���F�ρv�ȏ�ŁA
            --�l�����_�R�[�h��'-'��ݒ肵���ꍇ�A�G���[�Ƃ���
            IF ( lv_base_code_flag1 = cv_yes ) THEN
              --�G���[���b�Z�[�W�̐ݒ�
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --�ڋq�敪�X�e�[�^�X�`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_cust_class_kbn_err_msg
                              ,iv_token_name1  => cv_col_name
                              ,iv_token_value1 => cv_cnvs_base_code
                              ,iv_token_name2  => cv_cust_code
                              ,iv_token_value2 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
            --
            --�ڋq�敪�u10�F�ڋq�v���ڋq�X�e�[�^�X�u30�F���F�ρv�ȏ�ŁA
            --�l���c�ƈ���'-'��ݒ肵���ꍇ�A�G���[�Ƃ���
            IF (lv_business_person_flag1 = cv_yes) THEN
              --
              --�G���[���b�Z�[�W�̐ݒ�
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --�ڋq�敪�X�e�[�^�X�`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_cust_class_kbn_err_msg
                              ,iv_token_name1  => cv_col_name
                              ,iv_token_value1 => cv_cnvs_business_person
                              ,iv_token_name2  => cv_cust_code
                              ,iv_token_value2 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          --
          ELSIF (lv_base_code_flag2 = cv_yes) THEN
          --CSV�ɐݒ肳�ꂽ�l�����_�R�[�h��'-'�ŁA
          --CSV�ɐݒ肳�ꂽ�l���c�ƈ��A�܂���DB�ɓo�^���ꂽ�l���c�ƈ����C�ӂ̒l�̏ꍇ�G���[�Ƃ���
            --
            --�G���[���b�Z�[�W�̐ݒ�
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�l�����_�c�ƈ����փ`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_code_person_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_cnvs_base_code
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cnvs_business_person
                            ,iv_token_name3  => cv_cust_code
                            ,iv_token_value3 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          --
          ELSIF (lv_business_person_flag2 = cv_yes) THEN
          --CSV�ɐݒ肳�ꂽ�l���c�ƈ���'-'�̏ꍇ�A
          --CSV�ɐݒ肳�ꂽ�l�����_�R�[�h�A�܂���DB�ɓo�^���ꂽ�l�����_�R�[�h���C�ӂ̒l�̏ꍇ�G���[�Ƃ���
            --
            --�G���[���b�Z�[�W�̐ݒ�
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�l�����_�c�ƈ����փ`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_code_person_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_cnvs_business_person
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cnvs_base_code
                            ,iv_token_name3  => cv_cust_code
                            ,iv_token_value3 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          --
          ELSIF (lv_base_code_flag3 = cv_yes) THEN
          --CSV�ɐݒ肳�ꂽ�l�����_�R�[�h���C�ӂ̒l�ŁA
          --CSV�ɐݒ肳�ꂽ�l���c�ƈ���NULL�ŁADB�ɓo�^���ꂽ�l���c�ƈ���NULL�̏ꍇ�G���[�Ƃ���
            --
            --�G���[���b�Z�[�W�̐ݒ�
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --���o�^�`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_intro_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_cnvs_base_code
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cnvs_business_person
                            ,iv_token_name3  => cv_cust_code
                            ,iv_token_value3 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          --
          ELSIF (lv_business_person_flag3 = cv_yes) THEN
          --CSV�ɐݒ肳�ꂽ�l���c�ƈ����C�ӂ̒l�ŁA
          --CSV�ɐݒ肳�ꂽ�l�����_�R�[�h��NULL�ŁADB�ɓo�^���ꂽ�l�����_�R�[�h��NULL�̏ꍇ�G���[�Ƃ���
            --
            --�G���[���b�Z�[�W�̐ݒ�
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --���o�^�`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_intro_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_cnvs_business_person
                            ,iv_token_name2  => cv_cond_col_name
                            ,iv_token_value2 => cv_cnvs_base_code
                            ,iv_token_name3  => cv_cust_code
                            ,iv_token_value3 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          --
          ELSE
          --
            --CSV�ɐݒ肳�ꂽ�l�����_��NULL�̏ꍇ
            IF ( lv_cnvs_base_code IS NULL ) THEN
            --
              --DB�ɐݒ肳�ꂽ�l�����_���C�ӂ̒l�̏ꍇ
              IF ( lv_cnvs_base_code_mst1 IS NOT NULL ) THEN
              --
                --CSV�ɐݒ肳�ꂽ�l���]�ƈ���NULL�ł͂Ȃ��A����'-'�ȊO�̏ꍇ(�C�ӂ̒l)
                IF ( lv_cnvs_business_person <> cv_null_bar ) THEN
                --
                  --���_�R�[�h�Ɗl���c�ƈ��̕R�t�������p�`�F�b�N
                  << check_db_code_relation_loop >>
                  FOR check_db_code_relation_rec IN check_db_code_relation_cur( lv_cnvs_base_code_mst1,
                                                                                lv_cnvs_business_person )
                  LOOP
                    lv_cnvs_business_person_mst2  := check_db_code_relation_rec.new_employee_number;
                  END LOOP check_db_code_relation_loop;
                  --
                  --�E�ӊǗ��t���O��'N'�̏ꍇ
                  IF (gv_resp_flag = cv_no) THEN
                  --
                    --DB�̊l�����_��CSV�ɐݒ肳�ꂽ�l���]�ƈ����擾�ł��Ȃ��ꍇ
                    IF ( lv_cnvs_business_person_mst2 IS NULL ) THEN
                    --
                      --���_�R�[�h�Ɗl���c�ƈ��̕R�t�������p�`�F�b�N
                      << check_db_code_rel_auth_loop >>
                      FOR check_db_code_rel_auth_rec IN check_db_code_rel_auth_cur( lv_cnvs_base_code_mst1,
                                                                                    lv_cnvs_business_person )
                      LOOP
                        lv_cnvs_business_person_mst2  := check_db_code_rel_auth_rec.old_employee_number;
                      END LOOP check_db_code_rel_auth_loop;
                      --
                      --DB�̊l�����_��CSV�ɐݒ肳�ꂽ�l���]�ƈ����擾�ł��Ȃ��ꍇ(�����p)
                      IF ( lv_cnvs_business_person_mst2 IS NULL ) THEN
                        --
                        --�G���[�Ώ�
                        lv_business_person_flag4 := cv_yes;
                      END IF;
                    --
                    END IF;
                  --
                  ELSE
                  --�E�ӊǗ��t���O��'Y'�̏ꍇ
                    --
                    --DB�̊l�����_��CSV�ɐݒ肳�ꂽ�l���]�ƈ����擾�ł��Ȃ��ꍇ
                    IF ( lv_cnvs_business_person_mst2 IS NULL ) THEN
                      --
                      --�G���[�Ώ�
                      lv_business_person_flag4 := cv_yes;
                    END IF;
                  --
                  END IF;
                --
                END IF;
              --
              END IF;
            --
            ELSIF ( lv_cnvs_base_code <> cv_null_bar ) THEN
            --CSV�ɐݒ肳�ꂽ�l�����_��'-'�ȊO�̏ꍇ(�C�ӂ̒l)
            --
              --CSV�ɐݒ肳�ꂽ�l���]�ƈ���NULL�̏ꍇ
              IF ( lv_cnvs_business_person IS NULL ) THEN
              --
                --DB�ɐݒ肳�ꂽ�l���c�ƈ����C�ӂ̒l�̏ꍇ
                IF ( lv_cnvs_business_person_mst1 IS NOT NULL ) THEN
                --
                  --�l���c�ƈ��Ƌ��_�R�[�h�̕R�t���`�F�b�N
                  << check_db_person_relation_loop >>
                  FOR check_db_person_relation_rec IN check_db_person_relation_cur( lv_cnvs_business_person_mst1 )
                  LOOP
                    lv_cnvs_base_code_mst2  := check_db_person_relation_rec.new_base_code;
                  END LOOP check_db_person_relation_loop;
                  --
                  --�E�ӊǗ��t���O��'N'�̏ꍇ
                  IF (gv_resp_flag = cv_no) THEN
                  --
                    --CSV�ɐݒ肳�ꂽ�l�����_��DB�̊l���]�ƈ��ɕR�t���l�����_���قȂ�ꍇ
                    IF (lv_cnvs_base_code <> lv_cnvs_base_code_mst2) THEN
                    --
                      --�l���c�ƈ��Ƌ��_�R�[�h�̕R�t�������p�`�F�b�N
                      << check_db_person_rel_auth_loop >>
                      FOR check_db_person_rel_auth_rec IN check_db_person_rel_auth_cur( lv_cnvs_business_person_mst1 )
                      LOOP
                        lv_cnvs_base_code_mst2  := check_db_person_rel_auth_rec.old_base_code;
                      END LOOP check_db_person_rel_auth_loop;
                      --
                      --CSV�ɐݒ肳�ꂽ�l�����_��DB�̊l���]�ƈ��ɕR�t���l�����_���قȂ�ꍇ(�����p)
                      IF (lv_cnvs_base_code <> lv_cnvs_base_code_mst2) THEN
                        --
                        --�G���[�Ώ�
                        lv_base_code_flag4 := cv_yes;
                      END IF;
                    --
                    END IF;
                  --
                  ELSE
                  --�E�ӊǗ��t���O��'Y'�̏ꍇ
                  --
                    --CSV�ɐݒ肳�ꂽ�l�����_��DB�̊l���]�ƈ��ɕR�t���l�����_���قȂ�ꍇ
                    IF (lv_cnvs_base_code <> lv_cnvs_base_code_mst2) THEN
                      --
                      --�G���[�Ώ�
                      lv_base_code_flag4 := cv_yes;
                    END IF;
                  --
                  END IF;
                --
                END IF;
              --
              ELSIF ( lv_cnvs_business_person <> cv_null_bar ) THEN
              --CSV�ɐݒ肳�ꂽ�l���]�ƈ���'-'�ȊO�̏ꍇ(�C�ӂ̒l)
              --
                --�l���c�ƈ��Ƌ��_�R�[�h�̕R�t���`�F�b�N
                << check_db_person_relation_loop >>
                FOR check_db_person_relation_rec IN check_db_person_relation_cur( lv_cnvs_business_person )
                LOOP
                  lv_cnvs_base_code_mst2  := check_db_person_relation_rec.new_base_code;
                END LOOP check_db_person_relation_loop;
                --
                --���_�R�[�h�Ɗl���c�ƈ��̕R�t�������p�`�F�b�N
                << check_db_code_relation_loop >>
                FOR check_db_code_relation_rec IN check_db_code_relation_cur( lv_cnvs_base_code,
                                                                              lv_cnvs_business_person )
                LOOP
                  lv_cnvs_business_person_mst2  := check_db_code_relation_rec.new_employee_number;
                END LOOP check_db_code_relation_loop;
                --
                --�E�ӊǗ��t���O��'N'�̏ꍇ
                IF (gv_resp_flag = cv_no) THEN
                --
                  --CSV�ɐݒ肳�ꂽ�l�����_��CSV�ɐݒ肳�ꂽ�l���]�ƈ��ɕR�t���l�����_���قȂ�ꍇ
                  IF (lv_cnvs_base_code <> lv_cnvs_base_code_mst2) THEN
                  --
                    --�l���c�ƈ��Ƌ��_�R�[�h�̕R�t�������p�`�F�b�N
                    << check_db_person_rel_auth_loop >>
                    FOR check_db_person_rel_auth_rec IN check_db_person_rel_auth_cur( lv_cnvs_business_person )
                    LOOP
                      lv_cnvs_base_code_mst2  := check_db_person_rel_auth_rec.old_base_code;
                    END LOOP check_db_person_rel_auth_loop;
                    --
                    --CSV�ɐݒ肳�ꂽ�l�����_��CSV�ɐݒ肳�ꂽ�l���]�ƈ��ɕR�t���l�����_���قȂ�ꍇ(�����p)
                    IF (lv_cnvs_base_code <> lv_cnvs_base_code_mst2) THEN
                      --
                      --�G���[�Ώ�
                      lv_base_code_flag4 := cv_yes;
                    END IF;
                  --
                  END IF;
                  --
                  --CSV�ɐݒ肳�ꂽ�l�����_�l�����_��CSV�ɐݒ肳�ꂽ�l���]�ƈ����擾�ł��Ȃ��ꍇ
                  IF ( lv_cnvs_business_person_mst2 IS NULL ) THEN
                  --
                    --���_�R�[�h�Ɗl���c�ƈ��̕R�t�������p�`�F�b�N�`�F�b�N
                    << check_db_code_rel_auth_loop >>
                    FOR check_db_code_rel_auth_rec IN check_db_code_rel_auth_cur( lv_cnvs_base_code,
                                                                                  lv_cnvs_business_person )
                    LOOP
                      lv_cnvs_business_person_mst2 := check_db_code_rel_auth_rec.old_employee_number;
                    END LOOP check_db_code_rel_auth_loop;
                    --
                    --CSV�ɐݒ肳�ꂽ�l�����_��CSV�ɐݒ肳�ꂽ�l���]�ƈ����擾�ł��Ȃ��ꍇ(�����p)
                    IF ( lv_cnvs_business_person_mst2 IS NULL ) THEN
                      --
                      --�G���[�Ώ�
                      lv_business_person_flag4 := cv_yes;
                    END IF;
                  --
                  END IF;
                --
                ELSE
                --�E�ӊǗ��t���O��'Y'�̏ꍇ
                --
                  --CSV�ɐݒ肳�ꂽ�l�����_��CSV�ɐݒ肳�ꂽ�l���]�ƈ��ɕR�t���l�����_���قȂ�ꍇ
                  IF (lv_cnvs_base_code <> lv_cnvs_base_code_mst2) THEN
                    --
                    --�G���[�Ώ�
                    lv_base_code_flag4 := cv_yes;
                  END IF;
                  --
                  --CSV�ɐݒ肳�ꂽ�l�����_��CSV�ɐݒ肳�ꂽ�l���]�ƈ����擾�ł��Ȃ��ꍇ
                  IF ( lv_cnvs_business_person_mst2 IS NULL ) THEN
                    --
                    --�G���[�Ώ�
                    lv_business_person_flag4 := cv_yes;
                  END IF;
                --
                END IF;
              --
              END IF;
            --
            END IF;
          --
            --CSV�ɐݒ肳�ꂽ�l�����_��DB�̊l���]�ƈ��ɕR�t���l�����_���قȂ�ꍇ
            --�܂��́ACSV�ɐݒ肳�ꂽ�l�����_��CSV�ɐݒ肳�ꂽ�l���]�ƈ��ɕR�t���l�����_���قȂ�ꍇ
            IF ( lv_base_code_flag4 = cv_yes ) THEN
              --�G���[���b�Z�[�W�̐ݒ�
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --�l�����_�]�ƈ��R�t���`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_code_relation_err_msg
                              ,iv_token_name1  => cv_input_val
                              ,iv_token_value1 => lv_cnvs_base_code
                              ,iv_token_name2  => cv_cust_code
                              ,iv_token_value2 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            --
            ELSIF ( lv_business_person_flag4 = cv_yes ) THEN
            --DB�̊l�����_��CSV�ɐݒ肳�ꂽ�l���]�ƈ����擾�ł��Ȃ��ꍇ
            --�܂��́ACSV�ɐݒ肳�ꂽ�l�����_��CSV�ɐݒ肳�ꂽ�l���]�ƈ����擾�ł��Ȃ��ꍇ
              --�G���[���b�Z�[�W�̐ݒ�
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --�l���]�ƈ����_�R�t���`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_person_relation_err_msg
                              ,iv_token_name1  => cv_input_val
                              ,iv_token_value1 => lv_cnvs_business_person
                              ,iv_token_name2  => cv_cust_code
                              ,iv_token_value2 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            --
            END IF;
          --
          END IF;
--
        END IF;
--
        --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�̏ꍇ
        IF ( lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
          --
          --�V�K�|�C���g�敪�擾
          lv_new_point_div := xxccp_common_pkg.char_delim_partition(    lv_temp
                                                                       ,cv_comma
                                                                       ,47);
          --CSV�ɐݒ肳�ꂽ�V�K�|�C���g�敪���C�ӂ̒l�̏ꍇ
          IF (lv_new_point_div <> cv_null_bar) THEN
            --�V�K�|�C���g�敪���݃`�F�b�N
            << check_new_point_div_loop >>
            FOR check_new_point_div_rec IN check_new_point_div_cur( lv_new_point_div )
            LOOP
              lv_new_point_div_mst := check_new_point_div_rec.new_point_div;
            END LOOP check_new_point_div_loop;
            IF (lv_new_point_div_mst IS NULL) THEN
              lv_check_status    := cv_status_error;
              lv_retcode         := cv_status_error;
              --�V�K�|�C���g�敪�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_new_point_div
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_new_point_div
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
          --
          END IF;
        --
        END IF;
--
        --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�̏ꍇ
        IF ( lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
        --
          --�V�K�|�C���g�擾
          lv_new_point     := xxccp_common_pkg.char_delim_partition(    lv_temp
                                                                       ,cv_comma
                                                                       ,48);
          --CSV�ɐݒ肳�ꂽ�V�K�|�C���g���C�ӂ̒l�̏ꍇ
          IF ( lv_new_point <> cv_null_bar ) THEN
            --�V�K�|�C���g�^�E�����`�F�b�N
            xxccp_common_pkg2.upload_item_check( cv_new_point   --�V�K�|�C���g
                                                ,lv_new_point   --�V�K�|�C���g
                                                ,3                 --���ڒ�
                                                ,0                 --���ڒ��i�����_�ȉ��j
                                                ,cv_null_ok        --�K�{�t���O
                                                ,cv_element_num    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                                ,lv_item_errbuf    --�G���[�o�b�t�@
                                                ,lv_item_retcode   --�G���[�R�[�h
                                                ,lv_item_errmsg);  --�G���[���b�Z�[�W
            --�V�K�|�C���g�^�E�����`�F�b�N�G���[��
            IF (lv_item_retcode <> cv_status_normal) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --�V�K�|�C���g�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_new_point
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_new_point
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg
              );
            ELSE
              --�^�E�������펞�̂ݐ��l�Ƃ��Ĉ����A�V�K�|�C���g���l�͈̓`�F�b�N
              ln_new_point := TO_NUMBER(lv_new_point);
              IF  ((ln_new_point < cn_point_min)
                OR (ln_new_point > cn_point_max)) THEN
                lv_check_status   := cv_status_error;
                lv_retcode        := cv_status_error;
                --�V�K�|�C���g�G���[���b�Z�[�W�擾
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_new_point_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_col_name
                                ,iv_token_value2 => cv_new_point
                                ,iv_token_name3  => cv_input_val
                                ,iv_token_value3 => lv_new_point
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              END IF;
            END IF;
          --
          END IF;
        --
        END IF;
--
        --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�̏ꍇ
        IF ( lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
        --
          --�Љ�_�擾
          lv_intro_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
                                                                       ,49);
          --CSV�ɐݒ肳�ꂽ�Љ�_���C�ӂ̒l�̏ꍇ
          IF (lv_intro_base_code <> cv_null_bar) THEN
            --�Љ�_���݃`�F�b�N
            << check_intro_base_code_loop >>
            FOR check_flex_value_rec IN check_flex_value_cur( lv_intro_base_code )
            LOOP
              lv_intro_base_code_mst1 := check_flex_value_rec.flex_value;
            END LOOP check_intro_base_code_loop;
            IF (lv_intro_base_code_mst1 IS NULL) THEN
              lv_check_status    := cv_status_error;
              lv_retcode         := cv_status_error;
              --�Љ�_�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_flex_value_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_intro_base_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_intro_base_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
          --
          END IF;
        --
        END IF;
--
        --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�̏ꍇ
        IF ( lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
          --
          --�Љ�c�ƈ��擾
          lv_intro_business_person := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                             ,cv_comma
                                                                             ,50);
          --CSV�ɐݒ肳�ꂽ�Љ�c�ƈ���NULL�̏ꍇ
          IF ( lv_intro_business_person IS NULL ) THEN
          --
            --�Љ�c�ƈ����݃`�F�b�N
            << check_db_intro_person_loop >>
            FOR check_db_intro_person_rec IN check_db_intro_person_cur( lv_customer_code )
            LOOP
              lv_intro_business_person_mst1 := check_db_intro_person_rec.intro_business_person;
            END LOOP check_db_intro_person_loop;
            IF ( lv_intro_business_person_mst1 IS NOT NULL ) THEN
            --
              --�l�����_�R�[�h�A�l���c�ƈ��̃`�F�b�N�ŃG���[���Ȃ��ꍇ
              IF (  lv_base_code_flag1 IS NULL AND lv_business_person_flag1 IS NULL
                AND lv_base_code_flag2 IS NULL AND lv_business_person_flag2 IS NULL
                AND lv_base_code_flag3 IS NULL AND lv_business_person_flag3 IS NULL
                AND lv_base_code_flag4 IS NULL AND lv_business_person_flag4 IS NULL ) THEN
                --
                --CSV�ɐݒ肳�ꂽ�l���c�ƈ���DB�ɐݒ肳�ꂽ�Љ�c�ƈ��������ꍇ
                IF ( lv_cnvs_business_person_mst2 = lv_intro_business_person_mst1 ) THEN
                --
                  lv_check_status   := cv_status_error;
                  lv_retcode        := cv_status_error;
                  --�l���c�ƈ��Љ�҃`�F�b�N�G���[���b�Z�[�W�擾
                  gv_out_msg := xxccp_common_pkg.get_msg(
                                   iv_application  => gv_xxcmm_msg_kbn
                                  ,iv_name         => cv_intro_person_err_msg
                                  ,iv_token_name1  => cv_cust_code
                                  ,iv_token_value1 => lv_customer_code
                                 );
                  FND_FILE.PUT_LINE(
                     which  => FND_FILE.LOG
                    ,buff   => gv_out_msg
                  );
                --
                END IF;
              --
              END IF;
            --
            END IF;
          --
          ELSIF ( lv_intro_business_person <> cv_null_bar ) THEN
          --CSV�ɐݒ肳�ꂽ�Љ�c�ƈ��擾���C�ӂ̒l�̏ꍇ
          --
            --CSV�ɐݒ肳�ꂽ�Љ�_��NULL�̏ꍇ
            IF ( lv_intro_base_code IS NULL ) THEN
            --
              --�Љ�_�R�[�h���݃`�F�b�N
              << check_intro_base_code_loop >>
              FOR check_db_intro_base_code_rec IN check_db_intro_base_code_cur( lv_customer_code )
              LOOP
                lv_intro_base_code_mst2 := check_db_intro_base_code_rec.intro_base_code;
              END LOOP check_intro_base_code_loop;
              IF (lv_intro_base_code_mst2 IS NULL) THEN
                --�G���[�Ώ�
                lv_int_bus_per_flag1 := cv_yes;
              --
              END IF;
            --
            ELSIF ( lv_intro_base_code = cv_null_bar ) THEN
            --CSV�ɐݒ肳�ꂽ�Љ�_��'-'�̏ꍇ
              --�G���[�Ώ�
              lv_int_bus_per_flag1 := cv_yes;
            --
            END IF;
            --
            --CSV�ɐݒ肳�ꂽ�Љ�c�ƈ����C�ӂ̒l�ŁA
            --CSV�ɐݒ肳�ꂽ�Љ�_��NULL�ADB�ɓo�^���ꂽ�Љ�_��NULL�̏ꍇ
            --�܂��́ACSV�ɐݒ肳�ꂽ�Љ�_��'-'�̏ꍇ
            IF ( lv_int_bus_per_flag1 = cv_yes ) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --���o�^�`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_intro_err_msg
                              ,iv_token_name1  => cv_col_name
                              ,iv_token_value1 => cv_intro_business_person
                              ,iv_token_name2  => cv_cond_col_name
                              ,iv_token_value2 => cv_intro_base_code
                              ,iv_token_name3  => cv_cust_code
                              ,iv_token_value3 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            --
            ELSE
            --
              --�Љ�҃}�X�^�`�F�b�N�J�[�\��
              << check_db_mst_person_loop >>
              FOR check_db_mst_person_rec IN check_db_mst_person_cur( lv_intro_business_person )
              LOOP
                lv_intro_business_person_mst2 := check_db_mst_person_rec.employee_number;
              END LOOP check_db_mst_person_loop;
              --
              IF ( lv_intro_business_person_mst2 IS NULL ) THEN
                lv_check_status   := cv_status_error;
                lv_retcode        := cv_status_error;
                --�Љ�҃}�X�^�`�F�b�N�G���[���b�Z�[�W�擾
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_mst_intro_per_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg
                );
              --
              ELSE
              --
                --�l�����_�R�[�h�A�l���c�ƈ��̃`�F�b�N�ŃG���[���Ȃ��ꍇ
                IF (  lv_base_code_flag1 IS NULL AND lv_business_person_flag1 IS NULL
                  AND lv_base_code_flag2 IS NULL AND lv_business_person_flag2 IS NULL
                  AND lv_base_code_flag3 IS NULL AND lv_business_person_flag3 IS NULL
                  AND lv_base_code_flag4 IS NULL AND lv_business_person_flag4 IS NULL ) THEN
                --
                  --CSV�̊l���c�ƈ���NULL�̏ꍇ
                  IF (lv_cnvs_business_person IS NULL) THEN
                  --
                    --DB�Ɋl���c�ƈ����ݒ肳��Ă���ꍇ(CSV�ɂ�NULL���ݒ肳��Ă���)
                    IF ( lv_cnvs_business_person_mst1 IS NOT NULL ) THEN
                      --
                      --DB�ɐݒ肳�ꂽ�l���c�ƈ���CSV�ɐݒ肳��Ă���Љ�c�ƈ��������ꍇ
                      IF ( lv_cnvs_business_person_mst1 = lv_intro_business_person ) THEN
                        --�G���[�Ώ�
                        lv_int_bus_per_flag2 := cv_yes;
                      END IF;
                    --
                    ELSE
                      --�l�����_�R�[�h�A�l���c�ƈ���CSV�̗����ڂ�NULL���ݒ肳��Ă���ꍇ�A
                      --�l���c�ƈ���DB�ɓo�^���ꂽ�l�͎擾����Ă��Ȃ��ׁADB����擾����
                      --�l���c�ƈ���DB���݃`�F�b�N
                      << check_db_get_bus_per_loop >>
                      FOR check_db_code_person_rec IN check_db_code_person_cur( lv_customer_code )
                      LOOP
                        lv_cnvs_business_person_mst1  := check_db_code_person_rec.cnvs_business_person;
                      END LOOP check_db_get_bus_per_loop;
                      --
                      --DB�ɐݒ肳�ꂽ�l���c�ƈ���CSV�ɐݒ肳��Ă���Љ�c�ƈ��������ꍇ
                      IF ( lv_cnvs_business_person_mst1 = lv_intro_business_person ) THEN
                        --�G���[�Ώ�
                        lv_int_bus_per_flag2 := cv_yes;
                      END IF;
                    --
                    END IF;
                  --
                  ELSIF ( lv_cnvs_business_person_mst2 IS NOT NULL ) THEN
                  --CSV�Ɋl���c�ƈ����ݒ肳��Ă���ꍇ
                    --
                    --CSV�ɐݒ肳�ꂽ�l���c�ƈ���CSV�ɐݒ肳��Ă���Љ�c�ƈ��������ꍇ
                    IF ( lv_cnvs_business_person_mst2 = lv_intro_business_person ) THEN
                      --�G���[�Ώ�
                      lv_int_bus_per_flag2 := cv_yes;
                    END IF;
                  --
                  END IF;
                  --
                  --DB�ɐݒ肳�ꂽ�l���c�ƈ���CSV�ɐݒ肳��Ă���Љ�c�ƈ��������ꍇ
                  --�܂��́ACSV�ɐݒ肳�ꂽ�l���c�ƈ���CSV�ɐݒ肳��Ă���Љ�c�ƈ��������ꍇ
                  IF ( lv_int_bus_per_flag2 = cv_yes ) THEN
                    lv_check_status   := cv_status_error;
                    lv_retcode        := cv_status_error;
                    --�l���c�ƈ��Љ�҃`�F�b�N�G���[���b�Z�[�W�擾
                    gv_out_msg := xxccp_common_pkg.get_msg(
                                     iv_application  => gv_xxcmm_msg_kbn
                                    ,iv_name         => cv_intro_person_err_msg
                                    ,iv_token_name1  => cv_cust_code
                                    ,iv_token_value1 => lv_customer_code
                                   );
                    FND_FILE.PUT_LINE(
                       which  => FND_FILE.LOG
                      ,buff   => gv_out_msg
                    );
                  --
                  END IF;
                --
                END IF;
              --
              END IF;
            --
            END IF;
          --
          END IF;
        --
        END IF;
--
        --�ڋq�敪�u13�F�@�l�ڋq�v�̏ꍇ
        IF ( lv_cust_customer_class = cv_trust_corp ) THEN
        --
          --TDB�R�[�h�擾
          lv_tdb_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                ,cv_comma
                                                                ,51);
          --CSV�ɐݒ肳�ꂽTDB�R�[�h���C�ӂ̒l�̏ꍇ
          IF ( lv_tdb_code <> cv_null_bar ) THEN
            --TDB�R�[�h�̌^�E�����`�F�b�N
            xxccp_common_pkg2.upload_item_check( cv_tdb_code         --���ږ���
                                                ,lv_tdb_code         --TDB�R�[�h
                                                ,12                  --���ڒ�
                                                ,NULL                --���ڒ��i�����_�ȉ��j
                                                ,cv_null_ok          --�K�{�t���O
                                                ,cv_element_vc2      --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                                ,lv_item_errbuf      --�G���[�o�b�t�@
                                                ,lv_item_retcode     --�G���[�R�[�h
                                                ,lv_item_errmsg);    --�G���[���b�Z�[�W
            --TDB�R�[�h�^�E�����`�F�b�N�G���[��
            IF (lv_item_retcode <> cv_status_normal) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --TDB�R�[�h�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_tdb_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_tdb_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg);
            END IF;
          --
          END IF;
        --
        END IF;
--
        --�ڋq�敪�u13�F�@�l�ڋq�v�̏ꍇ
        IF ( lv_cust_customer_class = cv_trust_corp ) THEN
        --
          --���ٓ��t�擾
          lv_corp_approval_date := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
                                                                     ,52);
--
          --CSV�ɐݒ肳�ꂽ���ٓ��t�擾���C�ӂ̒l�̏ꍇ
          IF ( lv_corp_approval_date <> cv_null_bar ) THEN
            --���ٓ��t�̌^�E�����`�F�b�N
            xxccp_common_pkg2.upload_item_check( cv_approval_date    --���ږ���
                                                ,lv_corp_approval_date  --���ٓ��t
                                                ,NULL                --���ڒ�
                                                ,NULL                --���ڒ��i�����_�ȉ��j
                                                ,cv_null_ok          --�K�{�t���O
                                                ,cv_element_dat      --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                                ,lv_item_errbuf      --�G���[�o�b�t�@
                                                ,lv_item_retcode     --�G���[�R�[�h
                                                ,lv_item_errmsg);    --�G���[���b�Z�[�W
            --���ٓ��t�^�E�����`�F�b�N�G���[��
            IF (lv_item_retcode <> cv_status_normal) THEN
              lv_check_status := cv_status_error;
              lv_retcode      := cv_status_error;
              --���ٓ��t�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_val_form_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_approval_date
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_corp_approval_date
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => lv_item_errmsg);
            END IF;
          --
          END IF;
        --
        END IF;
--
        --�ڋq�敪�u13�F�@�l�ڋq�v�̏ꍇ
        IF ( lv_cust_customer_class = cv_trust_corp ) THEN
          --
          --�{���S�����_�擾
          lv_base_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                 ,cv_comma
                                                                 ,53);
          --CSV�ɐݒ肳�ꂽ�{���S�����_���C�ӂ̒l�̏ꍇ
          IF (lv_base_code <> cv_null_bar) THEN
            --�{���S�����_���݃`�F�b�N
            << check_base_code_loop >>
            FOR check_flex_value_rec IN check_flex_value_cur( lv_base_code )
            LOOP
              lv_base_code_mst := check_flex_value_rec.flex_value;
            END LOOP check_base_code_loop;
            IF (lv_base_code_mst IS NULL) THEN
              lv_check_status    := cv_status_error;
              lv_retcode         := cv_status_error;
              --�{���S�����_�Q�ƕ\���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_flex_value_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_base_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_base_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg
              );
            END IF;
          --
          ELSIF (lv_base_code = cv_null_bar) THEN 
          --CSV�ɐݒ肳�ꂽ�{���S�����_��'-'�̏ꍇ
            lv_check_status    := cv_status_error;
            lv_retcode         := cv_status_error;
            --�{���S�����_�K�{�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_base_code_err_msg
                            ,iv_token_name1  => cv_col_name
                            ,iv_token_value1 => cv_base_code
                            ,iv_token_name2  => cv_cust_code
                            ,iv_token_value2 => lv_customer_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
          --
          END IF;
        --
        END IF;
--
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
--
        -- ������ѐU�֎擾
        lv_selling_transfer_div := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                          ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                          ,42);
                                                                          ,54);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --������ѐU�֌^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_selling_transfer_div   --������ѐU��
                                            ,lv_selling_transfer_div   --������ѐU��
                                            ,1                         --���ڒ�
                                            ,NULL                      --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok                --�K�{�t���O
                                            ,cv_element_vc2            --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf            --�G���[�o�b�t�@
                                            ,lv_item_retcode           --�G���[�R�[�h
                                            ,lv_item_errmsg);          --�G���[���b�Z�[�W
        --������ѐU�֌^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --������ѐU�փG���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_selling_transfer_div
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_selling_transfer_div
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        --������ѐU�ւ�-�łȂ��ꍇ
        -- �ڋq�敪'10','12','13','14','15','16','17'�̏ꍇ�A�G���[�`�F�b�N���s��
        IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_trust_corp, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn, cv_keikaku_kbn)) THEN
          IF (lv_selling_transfer_div <> cv_null_bar) THEN
            --������ѐU�֑��݃`�F�b�N
            << check_selling_transfer_loop >>
            FOR check_lookup_type_rec IN check_lookup_type_cur( lv_selling_transfer_div, cv_uriage_jisseki_furi )
            LOOP
              lv_selling_transfer_div_mst     := check_lookup_type_rec.lookup_code;
            END LOOP check_selling_transfer_loop;
            IF (lv_selling_transfer_div_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --������ѐU�֑��݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_selling_transfer_div
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_selling_transfer_div
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
        -- �J�[�h��Ў擾
        lv_card_company := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                  ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                  ,43);
                                                                  ,55);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�J�[�h��Ќ^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_card_company   --�J�[�h���
                                            ,lv_card_company   --�J�[�h���
                                            ,9                 --���ڒ�
                                            ,NULL              --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok        --�K�{�t���O
                                            ,cv_element_vc2    --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf    --�G���[�o�b�t�@
                                            ,lv_item_retcode   --�G���[�R�[�h
                                            ,lv_item_errmsg);  --�G���[���b�Z�[�W
        --�J�[�h��Ќ^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�J�[�h��ЃG���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_card_company
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_card_company
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        -- �ڋq�敪'10'�̏ꍇ�̂݃G���[�`�F�b�N���s��
        IF (lv_cust_customer_class = cv_kokyaku_kbn) THEN
          --�J�[�h��Ђ�-�łȂ��ꍇ
          IF (lv_card_company <> cv_null_bar) THEN
            --�J�[�h��Б��݃`�F�b�N
            << check_card_company_loop >>
            FOR check_card_company_rec IN check_card_company_cur( lv_card_company )
            LOOP
              lv_card_company_mst     := check_card_company_rec.cust_id;
            END LOOP check_card_company_loop;
            IF (lv_card_company_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --�J�[�h��Ѓ}�X�^���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_mst_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_card_company
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_card_company
                              ,iv_token_name4  => cv_table
                              ,iv_token_value4 => cv_cust_acct_table
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
            --�J�[�h��Б��փ`�F�b�N
            --�Ƒԁi�����ށj��'24','25'�ȊO���ݒ肳��Ă���ꍇ
            IF (lv_business_low_type NOT IN (cv_gyotai_full_syoka_vd, cv_gyotai_full_vd)) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --�J�[�h��Б��փ`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_set_item_err_msg
                              ,iv_token_name1  => cv_col_name
                              ,iv_token_value1 => cv_card_company
                              ,iv_token_name2  => cv_cond_col_name
                              ,iv_token_value2 => cv_bus_low_type
                              ,iv_token_name3  => cv_cond_col_val
                              ,iv_token_value3 => lv_business_low_type
                              ,iv_token_name4  => cv_cust_code
                              ,iv_token_value4 => lv_customer_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
        -- �≮�Ǘ��R�[�h�擾
        lv_wholesale_ctrl_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                         ,44);
                                                                         ,56);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�≮�Ǘ��R�[�h�^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_wholesale_ctrl_code   --�≮�Ǘ��R�[�h
                                            ,lv_wholesale_ctrl_code   --�≮�Ǘ��R�[�h
                                            ,9                        --���ڒ�
                                            ,NULL                     --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok               --�K�{�t���O
                                            ,cv_element_vc2           --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf           --�G���[�o�b�t�@
                                            ,lv_item_retcode          --�G���[�R�[�h
                                            ,lv_item_errmsg);         --�G���[���b�Z�[�W
        --�≮�Ǘ��R�[�h�^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�≮�Ǘ��R�[�h�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_wholesale_ctrl_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_wholesale_ctrl_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        -- �ڋq�敪'10','12','13','14','15','16','17'�̏ꍇ�A�G���[�`�F�b�N���s��
        IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_trust_corp, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn, cv_keikaku_kbn)) THEN
          --�≮�Ǘ��R�[�h��-�łȂ��ꍇ
          IF (lv_wholesale_ctrl_code <> cv_null_bar) THEN
            --�≮�Ǘ��R�[�h���݃`�F�b�N
            << check_wholesale_ctrl_code_loop >>
            FOR check_lookup_type_rec IN check_lookup_type_cur( lv_wholesale_ctrl_code, cv_tonya_code )
            LOOP
              lv_wholesale_ctrl_code_mst     := check_lookup_type_rec.lookup_code;
            END LOOP check_wholesale_ctrl_code_loop;
            IF (lv_wholesale_ctrl_code_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --�≮�Ǘ��R�[�h���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_lookup_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_wholesale_ctrl_code
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_wholesale_ctrl_code
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
        -- ���i�\�擾
        lv_price_list := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                ,45);
                                                                ,57);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --���i�\�^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_price_list    --���i�\
                                            ,lv_price_list    --���i�\
                                            ,240              --���ڒ�
                                            ,NULL             --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok       --�K�{�t���O
                                            ,cv_element_vc2   --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf   --�G���[�o�b�t�@
                                            ,lv_item_retcode  --�G���[�R�[�h
                                            ,lv_item_errmsg); --�G���[���b�Z�[�W
        --���i�\�^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --���i�\�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_price_list
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_price_list
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
        -- �ڋq�敪'10','12'�̏ꍇ�A�G���[�`�F�b�N���s��
        IF (lv_cust_customer_class IN ( cv_kokyaku_kbn, cv_uesama_kbn)) THEN
          --���i�\��-�łȂ��ꍇ
          IF (lv_price_list <> cv_null_bar) THEN
            --���i�\���݃`�F�b�N
            << check_price_list_loop >>
            FOR check_price_list_rec IN check_price_list_cur( lv_price_list )
            LOOP
              lv_price_list_mst     := check_price_list_rec.list_header_id;
            END LOOP check_price_list_loop;
            IF (lv_price_list_mst IS NULL) THEN
              lv_check_status   := cv_status_error;
              lv_retcode        := cv_status_error;
              --���i�\�}�X�^���݃`�F�b�N�G���[���b�Z�[�W�擾
              gv_out_msg := xxccp_common_pkg.get_msg(
                               iv_application  => gv_xxcmm_msg_kbn
                              ,iv_name         => cv_mst_err_msg
                              ,iv_token_name1  => cv_cust_code
                              ,iv_token_value1 => lv_customer_code
                              ,iv_token_name2  => cv_col_name
                              ,iv_token_value2 => cv_price_list
                              ,iv_token_name3  => cv_input_val
                              ,iv_token_value3 => lv_price_list
                              ,iv_token_name4  => cv_table
                              ,iv_token_value4 => cv_qp_list_headers_table
                             );
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.LOG
                ,buff   => gv_out_msg);
            END IF;
          END IF;
        END IF;
        --
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--        -- �E�ӊǗ��t���O��'Y'�̏ꍇ
--        IF (gv_resp_flag = cv_yes) THEN
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
          -- �o�׌��ۊǏꏊ�擾
          lv_ship_storage_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                         ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                         ,46);
                                                                         ,58);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
          --�o�׌��ۊǏꏊ�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_ship_storage_code    --�o�׌��ۊǏꏊ
                                              ,lv_ship_storage_code    --�o�׌��ۊǏꏊ
                                              ,10                      --���ڒ�
                                              ,NULL                    --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok              --�K�{�t���O
                                              ,cv_element_vc2          --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf          --�G���[�o�b�t�@
                                              ,lv_item_retcode         --�G���[�R�[�h
                                              ,lv_item_errmsg);        --�G���[���b�Z�[�W
          --�o�׌��ۊǏꏊ�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�o�׌��ۊǏꏊ�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_ship_storage_code
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_ship_storage_code
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
          -- �ڋq�敪'10','12','13','14','15','16','17'�̏ꍇ�A�G���[�`�F�b�N���s��
          IF (lv_cust_customer_class IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_trust_corp, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn, cv_keikaku_kbn)) THEN
            --�o�׌��ۊǏꏊ��-�łȂ��ꍇ
            IF (lv_ship_storage_code <> cv_null_bar) THEN
              --�o�׌��ۊǏꏊ���݃`�F�b�N
              << check_ship_storage_code_loop >>
              FOR check_ship_storage_code_rec IN check_ship_storage_code_cur( lv_ship_storage_code )
              LOOP
                lv_ship_storage_code_mst  := check_ship_storage_code_rec.secondary_inventory_name;
              END LOOP check_price_list_loop;
              IF (lv_ship_storage_code_mst IS NULL) THEN
                lv_check_status   := cv_status_error;
                lv_retcode        := cv_status_error;
                --�o�׌��ۊǏꏊ�}�X�^���݃`�F�b�N�G���[���b�Z�[�W�擾
                gv_out_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => gv_xxcmm_msg_kbn
                                ,iv_name         => cv_mst_err_msg
                                ,iv_token_name1  => cv_cust_code
                                ,iv_token_value1 => lv_customer_code
                                ,iv_token_name2  => cv_col_name
                                ,iv_token_value2 => cv_ship_storage_code
                                ,iv_token_name3  => cv_input_val
                                ,iv_token_value3 => lv_ship_storage_code
                                ,iv_token_name4  => cv_table
                                ,iv_token_value4 => cv_second_inv_mst
                               );
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => gv_out_msg);
              END IF;
            END IF;
          END IF;
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--        ELSE
--          -- �E�ӊǗ��v���t�@�C����'N'�̏ꍇ�A�o�׌��ۊǏꏊ��NULL���Z�b�g
--          lv_ship_storage_code := NULL;
--        END IF;
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add start by K.Kubo
        -- ===========================================
        -- �z�����iEDI�j�̎擾�E�`�F�b�N
        -- ===========================================
        -- �z�����iEDI�j �擾
        lv_delivery_order := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                    ,cv_comma
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod start by S.Niki
--                                                                    ,48);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                    ,47);
                                                                    ,59);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod end by S.Niki
        --�z�����iEDI�j �^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_delivery_order        --�z�����iEDI�j
                                            ,lv_delivery_order        --�z�����iEDI�j
                                            ,14                       --���ڒ�
                                            ,NULL                     --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok               --�K�{�t���O
                                            ,cv_element_vc2           --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf           --�G���[�o�b�t�@
                                            ,lv_item_retcode          --�G���[�R�[�h
                                            ,lv_item_errmsg);         --�G���[���b�Z�[�W
        --�z�����iEDI�j �^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�z�����iEDI�j �G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_delivery_order
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_delivery_order
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        -- ===========================================
        -- EDI�n��R�[�h�iEDI�j�̎擾�E�`�F�b�N
        -- ===========================================
        -- EDI�n��R�[�h�iEDI�j �擾
        lv_edi_district_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod start by S.Niki
--                                                                       ,49);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                       ,48);
                                                                       ,60);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod end by S.Niki
        --EDI�n��R�[�h�iEDI�j �^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_edi_district_code     --EDI�n��R�[�h�iEDI�j
                                            ,lv_edi_district_code     --EDI�n��R�[�h�iEDI�j
                                            ,8                        --���ڒ�
                                            ,NULL                     --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok               --�K�{�t���O
                                            ,cv_element_vc2           --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf           --�G���[�o�b�t�@
                                            ,lv_item_retcode          --�G���[�R�[�h
                                            ,lv_item_errmsg);         --�G���[���b�Z�[�W
        --EDI�n��R�[�h�iEDI�j �^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --EDI�n��R�[�h�iEDI�j �G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_district_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_district_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        --EDI�n��R�[�h�iEDI�j�̔��p�����`�F�b�N
        IF (NVL(xxccp_common_pkg.chk_single_byte(lv_edi_district_code), TRUE) = FALSE) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --���p�����`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_single_byte_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_district_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_district_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        -- ===========================================
        -- EDI�n�於�iEDI�j�̎擾�E�`�F�b�N
        -- ===========================================
        -- EDI�n�於�iEDI�j �擾
        lv_edi_district_name := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod start by S.Niki
--                                                                       ,50);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                       ,49);
                                                                       ,61);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod end by S.Niki
        --EDI�n�於�iEDI�j �^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_edi_district_name     --EDI�n�於�iEDI�j
                                            ,lv_edi_district_name     --EDI�n�於�iEDI�j
                                            ,40                       --���ڒ�
                                            ,NULL                     --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok               --�K�{�t���O
                                            ,cv_element_vc2           --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf           --�G���[�o�b�t�@
                                            ,lv_item_retcode          --�G���[�R�[�h
                                            ,lv_item_errmsg);         --�G���[���b�Z�[�W
        --EDI�n�於�iEDI�j �^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --EDI�n�於�iEDI�j �G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_district_name
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_district_name
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        -- �S�p�����`�F�b�N�i������'-'�͏����j
        IF (NVL(xxccp_common_pkg.chk_double_byte(lv_edi_district_name), TRUE) = FALSE)
          AND (lv_edi_district_name <> cv_null_bar)
        THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�S�p�����`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_double_byte_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_district_name
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_district_name
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        -- ===========================================
        -- EDI�n�於�J�i�iEDI�j�̎擾�E�`�F�b�N
        -- ===========================================
        -- EDI�n�於�J�i�iEDI�j �擾
        lv_edi_district_kana := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod start by S.Niki
--                                                                       ,51);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                       ,50);
                                                                       ,62);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod end by S.Niki
        --EDI�n�於�J�i�iEDI�j �^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_edi_district_kana     --EDI�n�於�J�i�iEDI�j
                                            ,lv_edi_district_kana     --EDI�n�於�J�i�iEDI�j
                                            ,20                       --���ڒ�
                                            ,NULL                     --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok               --�K�{�t���O
                                            ,cv_element_vc2           --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf           --�G���[�o�b�t�@
                                            ,lv_item_retcode          --�G���[�R�[�h
                                            ,lv_item_errmsg);         --�G���[���b�Z�[�W
        --EDI�n�於�J�i�iEDI�j �^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --EDI�n�於�J�i�iEDI�j �G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_district_kana
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_district_kana
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        --���p�����`�F�b�N
        IF (NVL(xxccp_common_pkg.chk_single_byte(lv_edi_district_kana), TRUE) = FALSE) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --���p�����`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_single_byte_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_district_kana
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_district_kana
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        -- ===========================================
        -- �ʉߍ݌Ɍ^�敪�iEDI�j�̎擾�E�`�F�b�N
        -- ===========================================
        -- �ʉߍ݌Ɍ^�敪�iEDI�j �擾
        lv_tsukagatazaiko_div := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                        ,cv_comma
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod start by S.Niki
--                                                                        ,52);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                        ,51);
                                                                        ,63);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod end by S.Niki
        --�ʉߍ݌Ɍ^�敪�iEDI�j �^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_tsukagatazaiko_div    --�ʉߍ݌Ɍ^�敪�iEDI�j
                                            ,lv_tsukagatazaiko_div    --�ʉߍ݌Ɍ^�敪�iEDI�j
                                            ,2                        --���ڒ�
                                            ,NULL                     --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok               --�K�{�t���O
                                            ,cv_element_vc2           --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf           --�G���[�o�b�t�@
                                            ,lv_item_retcode          --�G���[�R�[�h
                                            ,lv_item_errmsg);         --�G���[���b�Z�[�W
        --�ʉߍ݌Ɍ^�敪�iEDI�j �^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�ʉߍ݌Ɍ^�敪�iEDI�j �G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_tsukagatazaiko_div
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_tsukagatazaiko_div
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        --�ʉߍ݌Ɍ^�敪�iEDI�j��'-'�ȊO�̒l�������Ă���ꍇ
        IF (NVL(lv_tsukagatazaiko_div , cv_null_bar) <> cv_null_bar) THEN
          --�Q�ƃ^�C�v �ʉߍ݌Ɍ^�敪�iEDI�j���݃`�F�b�N
          << check_tsukagatazaiko_div_loop >>
          FOR check_lookup_type_rec IN check_lookup_type_cur( lv_tsukagatazaiko_div , cv_tsukagatazaiko_kbn )
          LOOP
            lv_tsukagatazaiko_div_mst  := check_lookup_type_rec.lookup_code;
          END LOOP check_tsukagatazaiko_div_loop;
          IF (lv_tsukagatazaiko_div_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�ʉߍ݌Ɍ^�敪�iEDI�j���݃`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_tsukagatazaiko_div
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_tsukagatazaiko_div
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
--
          --�ʉߍ݌Ɍ^�敪�iEDI�j ����͂���ꍇ�A�`�F�[���X�R�[�h(EDI)�̓��͕K�{
          --CSV�ɐݒ肳�ꂽ�`�F�[���X�R�[�h(EDI)��'-'�̏ꍇ
          IF (lv_edi_chain_code = cv_null_bar) THEN
            --�G���[�Ώ�
            lv_tsukagatazaiko_flag := cv_yes;
          --
          --CSV�ɐݒ肳�ꂽ�`�F�[���X�R�[�h(EDI)��NULL�̏ꍇ
          ELSIF (lv_edi_chain_code IS NULL) THEN
            --�ڋq�ǉ����̃`�F�[���X�R�[�h(EDI)���݃`�F�b�N
            << check_db_chain_store_loop >>
            FOR check_db_customer_rec IN check_db_customer_cur( lv_customer_code )
            LOOP
              lv_chain_store_db  := check_db_customer_rec.chain_store_code;
            END LOOP check_db_chain_store_loop;
            --�ڋq�ǉ����̃`�F�[���X�R�[�h(EDI)��'Y'�̏ꍇ
            IF (lv_chain_store_db IS NULL) THEN
              --�G���[�Ώ�
              lv_tsukagatazaiko_flag := cv_yes;
            END IF;
          END IF;
--
        END IF;
--
        --�ʉߍ݌Ɍ^�敪�iEDI�j ����͂���ꍇ�A�`�F�[���X�R�[�h(EDI)�̓��͕K�{
        --�ʉߍ݌Ɍ^�敪�iEDI�j��NULL �̏ꍇ
        IF (lv_tsukagatazaiko_div IS NULL) THEN
          --�ڋq�ǉ����̒ʉߍ݌Ɍ^�敪�iEDI�j���݃`�F�b�N
          << check_db_tsukagatazaiko_loop >>
          FOR check_db_customer_rec IN check_db_customer_cur( lv_customer_code )
          LOOP
            lv_tsukagatazaiko_div_db  := check_db_customer_rec.tsukagatazaiko_div;
          END LOOP check_db_tsukagatazaiko_loop;
          --�ڋq�ǉ����̒ʉߍ݌Ɍ^�敪�iEDI�j��NULL�łȂ�
          --���A�`�F�[���X�R�[�h(EDI)��'-' �̏ꍇ
          IF (lv_tsukagatazaiko_div_db IS NOT NULL)
            AND (lv_edi_chain_code = cv_null_bar)
          THEN
            --�G���[�Ώ�
            lv_tsukagatazaiko_flag := cv_yes;
          END IF;
        END IF;
--
        --��L�ŃG���[�ΏۂƂȂ����ꍇ�A���ڐݒ�`�F�b�N�G���[
        IF (lv_tsukagatazaiko_flag = cv_yes) THEN
          --�G���[���b�Z�[�W�̐ݒ�
          lv_check_status   := cv_status_error;
          lv_retcode        := cv_status_error;
          --�ʉߍ݌Ɍ^�敪�iEDI�j���݃`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_set_item_err_msg
                          ,iv_token_name1  => cv_col_name
                          ,iv_token_value1 => cv_tsukagatazaiko_div
                          ,iv_token_name2  => cv_cond_col_name
                          ,iv_token_value2 => cv_edi_chain
                          ,iv_token_name3  => cv_cond_col_val
                          ,iv_token_value3 => 'NULL'
                          ,iv_token_name4  => cv_cust_code
                          ,iv_token_value4 => lv_customer_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        -- ===========================================
        -- EDI�[�i�Z���^�[�R�[�h�̎擾�E�`�F�b�N
        -- ===========================================
        -- EDI�[�i�Z���^�[�R�[�h �擾
        lv_deli_center_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod start by S.Niki
--                                                                      ,53);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                      ,52);
                                                                      ,64);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod end by S.Niki
        --EDI�[�i�Z���^�[�R�[�h �^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_deli_center_code      --EDI�[�i�Z���^�[�R�[�h
                                            ,lv_deli_center_code      --EDI�[�i�Z���^�[�R�[�h
                                            ,8                        --���ڒ�
                                            ,NULL                     --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok               --�K�{�t���O
                                            ,cv_element_vc2           --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf           --�G���[�o�b�t�@
                                            ,lv_item_retcode          --�G���[�R�[�h
                                            ,lv_item_errmsg);         --�G���[���b�Z�[�W
        --EDI�[�i�Z���^�[�R�[�h �^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --EDI�[�i�Z���^�[�R�[�h �G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_deli_center_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_deli_center_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        -- ===========================================
        -- EDI�[�i�Z���^�[���̎擾�E�`�F�b�N
        -- ===========================================
        -- EDI�[�i�Z���^�[�� �擾
        lv_deli_center_name := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                      ,cv_comma
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod start by S.Niki
--                                                                      ,54);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                      ,53);
                                                                      ,65);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod end by S.Niki
        --EDI�[�i�Z���^�[�� �^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_deli_center_name      --EDI�[�i�Z���^�[��
                                            ,lv_deli_center_name      --EDI�[�i�Z���^�[��
                                            ,20                       --���ڒ�
                                            ,NULL                     --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok               --�K�{�t���O
                                            ,cv_element_vc2           --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf           --�G���[�o�b�t�@
                                            ,lv_item_retcode          --�G���[�R�[�h
                                            ,lv_item_errmsg);         --�G���[���b�Z�[�W
        --EDI�[�i�Z���^�[�� �^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --EDI�[�i�Z���^�[�� �G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_deli_center_name
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_deli_center_name
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        -- ===========================================
        -- EDI�`���ǔԂ̎擾�E�`�F�b�N
        -- ===========================================
        -- EDI�`���ǔ� �擾
        lv_edi_forward_number := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                        ,cv_comma
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod start by S.Niki
--                                                                        ,55);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                        ,54);
                                                                        ,66);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod end by S.Niki
        --EDI�`���ǔ� �^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_edi_forward_number    --EDI�`���ǔ�
                                            ,lv_edi_forward_number    --EDI�`���ǔ�
                                            ,2                        --���ڒ�
                                            ,NULL                     --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok               --�K�{�t���O
                                            ,cv_element_vc2           --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf           --�G���[�o�b�t�@
                                            ,lv_item_retcode          --�G���[�R�[�h
                                            ,lv_item_errmsg);         --�G���[���b�Z�[�W
        --EDI�`���ǔ� �^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --EDI�`���ǔ� �G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_edi_forward_number
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_edi_forward_number
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        -- ===========================================
        -- �ڋq�X�ܖ��̂̎擾�E�`�F�b�N
        -- ===========================================
        -- �ڋq�X�ܖ��� �擾
        lv_cust_store_name := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod start by S.Niki
--                                                                     ,56);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                     ,55);
                                                                     ,67);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod end by S.Niki
        --�ڋq�X�ܖ��� �^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_cust_store_name       --�ڋq�X�ܖ���
                                            ,lv_cust_store_name       --�ڋq�X�ܖ���
                                            ,30                       --���ڒ�
                                            ,NULL                     --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok               --�K�{�t���O
                                            ,cv_element_vc2           --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf           --�G���[�o�b�t�@
                                            ,lv_item_retcode          --�G���[�R�[�h
                                            ,lv_item_errmsg);         --�G���[���b�Z�[�W
        --�ڋq�X�ܖ��� �^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�ڋq�X�ܖ��� �G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_store_name
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_cust_store_name
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        -- �S�p�����`�F�b�N�i������'-'�͏����j
        IF (NVL(xxccp_common_pkg.chk_double_byte(lv_cust_store_name), TRUE) = FALSE)
          AND (lv_cust_store_name <> cv_null_bar)
        THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�S�p�����`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_double_byte_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_cust_store_name
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_cust_store_name
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
        -- ===========================================
        -- �����R�[�h�̎擾�E�`�F�b�N
        -- ===========================================
        -- �����R�[�h �擾
        lv_torihikisaki_code := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                       ,cv_comma
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod start by S.Niki
--                                                                       ,57);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                       ,56);
                                                                       ,68);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 mod end by S.Niki
        --�����R�[�h �^�E�����`�F�b�N
        xxccp_common_pkg2.upload_item_check( cv_torihikisaki_code     --�����R�[�h
                                            ,lv_torihikisaki_code     --�����R�[�h
                                            ,8                        --���ڒ�
                                            ,NULL                     --���ڒ��i�����_�ȉ��j
                                            ,cv_null_ok               --�K�{�t���O
                                            ,cv_element_vc2           --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                            ,lv_item_errbuf           --�G���[�o�b�t�@
                                            ,lv_item_retcode          --�G���[�R�[�h
                                            ,lv_item_errmsg);         --�G���[���b�Z�[�W
        --�����R�[�h �^�E�����`�F�b�N�G���[��
        IF (lv_item_retcode <> cv_status_normal) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --�����R�[�h �G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_val_form_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_torihikisaki_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_torihikisaki_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_item_errmsg
          );
        END IF;
--
        --�����R�[�h�̔��p�����`�F�b�N
        IF (NVL(xxccp_common_pkg.chk_single_byte(lv_torihikisaki_code), TRUE) = FALSE) THEN
          lv_check_status := cv_status_error;
          lv_retcode      := cv_status_error;
          --���p�����`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => gv_xxcmm_msg_kbn
                          ,iv_name         => cv_single_byte_err_msg
                          ,iv_token_name1  => cv_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_col_name
                          ,iv_token_value2 => cv_torihikisaki_code
                          ,iv_token_name3  => cv_input_val
                          ,iv_token_value3 => lv_torihikisaki_code
                         );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
--
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add start by S.Niki
        --�K��Ώۋ敪�擾
        lv_vist_target_div := xxccp_common_pkg.char_delim_partition(  lv_temp
                                                                     ,cv_comma
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod start by T.Nakano
--                                                                     ,57);
                                                                     ,69);
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� mod end by T.Nakano
        --�K��Ώۋ敪��-�łȂ��ꍇ
        IF (lv_vist_target_div <> cv_null_bar) THEN
          --�K��Ώۋ敪���݃`�F�b�N
          << check_homon_taisyo_kbn_loop >>
          FOR check_homon_taisyo_kbn_rec IN check_homon_taisyo_kbn_cur( lv_vist_target_div )
          LOOP
            lv_vist_target_div_mst := check_homon_taisyo_kbn_rec.homon_taisyo_kbn;
          END LOOP check_homon_taisyo_kbn_loop;
          IF (lv_vist_target_div_mst IS NULL) THEN
            lv_check_status   := cv_status_error;
            lv_retcode        := cv_status_error;
            --�K��Ώۋ敪�`�F�b�N�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_lookup_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_vist_target_div
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_vist_target_div
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
          END IF;
--
          --�K��Ώۋ敪�^�E�����`�F�b�N
          xxccp_common_pkg2.upload_item_check( cv_vist_target_div     --�K��Ώۋ敪
                                              ,lv_vist_target_div     --�K��Ώۋ敪
                                              ,1                      --���ڒ�
                                              ,NULL                   --���ڒ��i�����_�ȉ��j
                                              ,cv_null_ok             --�K�{�t���O
                                              ,cv_element_vc2         --�����i0�E���؂Ȃ��A1�A���l�A2�A���t�j
                                              ,lv_item_errbuf         --�G���[�o�b�t�@
                                              ,lv_item_retcode        --�G���[�R�[�h
                                              ,lv_item_errmsg);       --�G���[���b�Z�[�W
          --�K��Ώۋ敪�^�E�����`�F�b�N�G���[��
          IF (lv_item_retcode <> cv_status_normal) THEN
            lv_check_status := cv_status_error;
            lv_retcode      := cv_status_error;
            --�K��Ώۋ敪�G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => gv_xxcmm_msg_kbn
                            ,iv_name         => cv_val_form_err_msg
                            ,iv_token_name1  => cv_cust_code
                            ,iv_token_value1 => lv_customer_code
                            ,iv_token_name2  => cv_col_name
                            ,iv_token_value2 => cv_vist_target_div
                            ,iv_token_name3  => cv_input_val
                            ,iv_token_value3 => lv_vist_target_div
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => lv_item_errmsg
            );
          END IF;
        END IF;
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add end by S.Niki
        --
        IF (lv_check_status = cv_status_normal) THEN
          BEGIN
            INSERT INTO xxcmm_wk_cust_batch_regist(
               file_id
              ,customer_code
              ,customer_class_code
              ,customer_name
              ,customer_name_kana
              ,customer_name_ryaku
              ,customer_status
              ,approval_reason
              ,approval_date
              ,credit_limit
              ,decide_div
              ,ar_invoice_code
              ,ar_location_code
              ,ar_others_code
              ,invoice_class
              ,invoice_cycle
              ,invoice_form
              ,payment_term_id
              ,payment_term_second
              ,payment_term_third
              ,sales_chain_code
              ,delivery_chain_code
              ,policy_chain_code
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
              ,intro_chain_code1
              ,intro_chain_code2
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
              ,chain_store_code
              ,store_code
              ,business_low_type
              ,postal_code
              ,state
              ,city
              ,address1
              ,address2
              ,address3
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
              ,invoice_code
              ,industry_div
              ,bill_base_code
              ,receiv_base_code
              ,delivery_base_code
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
              ,sales_head_base_code
              ,cnvs_base_code
              ,cnvs_business_person
              ,new_point_div
              ,new_point
              ,intro_base_code
              ,intro_business_person
              ,tdb_code
              ,corp_approval_date
              ,base_code
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
              ,selling_transfer_div
              ,card_company
              ,wholesale_ctrl_code
              ,price_list
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
              ,ship_storage_code
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add start by K.Kubo
              ,delivery_order
              ,edi_district_code
              ,edi_district_name
              ,edi_district_kana
              ,tsukagatazaiko_div
              ,deli_center_code
              ,deli_center_name
              ,edi_forward_number
              ,cust_store_name
              ,torihikisaki_code
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add start by S.Niki
              ,vist_target_div           --�K��Ώۋ敪
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add end by S.Niki
              ,created_by
              ,creation_date
              ,last_updated_by
              ,last_update_date
              ,request_id
              ,program_application_id
              ,program_id
              ,program_update_date
            )
            VALUES(
               in_file_id
              ,lv_customer_code
              ,lv_customer_class
              ,lv_customer_name
              ,lv_cust_name_kana
              ,lv_cust_name_ryaku
              ,lv_customer_status
              ,lv_approval_reason
              ,lv_approval_date
              ,ln_credit_limit
              ,lv_decide_div
              ,lv_ar_invoice_code
              ,lv_ar_location_code
              ,lv_ar_others_code
              ,lv_invoice_class
              ,lv_invoice_cycle
              ,lv_invoice_form
              ,lv_payment_term_id
              ,lv_payment_term_second
              ,lv_payment_term_third
              ,lv_sales_chain_code
              ,lv_delivery_chain_code
              ,lv_policy_chain_code
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
              ,lv_intro_chain_code1
              ,lv_intro_chain_code2
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
              ,lv_edi_chain_code
              ,lv_store_code
              ,lv_business_low_type
              ,lv_postal_code
              ,lv_state
              ,lv_city
              ,lv_address1
              ,lv_address2
              ,lv_address3
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
              ,lv_invoice_code
              ,lv_industry_div
              ,lv_bill_base_code
              ,lv_receiv_base_code
              ,lv_delivery_base_code
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
              ,lv_sales_head_base_code
              ,lv_cnvs_base_code
              ,lv_cnvs_business_person
              ,lv_new_point_div
              ,lv_new_point
              ,lv_intro_base_code
              ,lv_intro_business_person
              ,lv_tdb_code
              ,lv_corp_approval_date
              ,lv_base_code
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
              ,lv_selling_transfer_div
              ,lv_card_company
              ,lv_wholesale_ctrl_code
              ,lv_price_list
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
              ,lv_ship_storage_code
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add start by K.Kubo
              ,lv_delivery_order
              ,lv_edi_district_code
              ,lv_edi_district_name
              ,lv_edi_district_kana
              ,lv_tsukagatazaiko_div
              ,lv_deli_center_code
              ,lv_deli_center_name
              ,lv_edi_forward_number
              ,lv_cust_store_name
              ,lv_torihikisaki_code
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add start by S.Niki
              ,lv_vist_target_div        --�K��Ώۋ敪
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add end by S.Niki
              ,fnd_global.user_id
              ,sysdate
              ,fnd_global.user_id
              ,sysdate
              ,fnd_profile.value(cv_conc_request_id)
              ,fnd_profile.value(cv_prog_appl_id)
              ,fnd_profile.value(cv_conc_program_id)
              ,sysdate
            );
          EXCEPTION
            WHEN OTHERS THEN
              lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              lv_retcode := cv_status_error;
              RAISE invalid_data_expt;
          END;
        END IF;
        --�����J�E���g
        gn_target_cnt    := gn_target_cnt + 1;  -- �Ώی���
        IF (lv_check_status = cv_status_normal) THEN
          gn_normal_cnt  := gn_normal_cnt + 1;  -- ���팏��
        ELSE
          gn_error_cnt   := gn_error_cnt +1;    -- �G���[����
        END IF;
      END IF;
      --�e�i�[�p�ϐ�������
      lv_temp                  := NULL;
      lv_item_retcode          := NULL;
      lv_item_errmsg           := NULL;
      lv_customer_code         := NULL;
      lv_cust_code_mst         := NULL;
      ln_cust_id               := NULL;
      ln_party_id              := NULL;
      ln_cust_addon_mst        := NULL;
      lv_business_low_mst      := NULL;
      lv_get_cust_status       := NULL;
      lv_appr_reason_mst       := NULL;
      ln_cust_corp_mst         := NULL;
      lv_customer_class        := NULL;
      lv_cust_class_mst        := NULL;
      lv_cust_status_mst       := NULL;
      lr_cust_wk_table         := NULL;
      lv_ar_invoice_code_mst   := NULL;
      lv_invoice_class_mst     := NULL;
      lv_invoice_cycle_mst     := NULL;
      lv_invoice_form_mst      := NULL;
      lv_payment_term_id_mst   := NULL;
      lv_payment_second_mst    := NULL;
      lv_payment_third_mst     := NULL;
      lv_sales_chain_code_mst  := NULL;
      lv_deliv_chain_code_mst  := NULL;
      lv_edi_chain_mst         := NULL;
      lv_cust_chiku_code_mst   := NULL;
      lv_credit_limit          := NULL;
      ln_credit_limit          := NULL;
      lv_decide_div_mst        := NULL;
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
      lv_cust_customer_class      := NULL;
      lv_invoice_required_flag    := NULL;
      lv_invoice_code             := NULL;
      ln_invoice_code_mst         := NULL;
      lv_industry_div             := NULL;
      lv_industry_div_mst         := NULL;
      lv_bill_base_code           := NULL;
      lv_bill_base_code_mst       := NULL;
      lv_receiv_base_code         := NULL;
      lv_receiv_base_code_mst     := NULL;
      lv_delivery_base_code       := NULL;
      lv_delivery_base_code_mst   := NULL;
      lv_selling_transfer_div     := NULL;
      lv_selling_transfer_div_mst := NULL;
      lv_card_company             := NULL;
      lv_card_company_mst         := NULL;
      lv_wholesale_ctrl_code      := NULL;
      lv_wholesale_ctrl_code_mst  := NULL;
      lv_price_list               := NULL;
      lv_price_list_mst           := NULL;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
      lv_ship_storage_code        := NULL;
      lv_ship_storage_code_mst    := NULL;
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add start by K.Kubo
      lv_delivery_order           := NULL;
      lv_edi_district_code        := NULL;
      lv_edi_district_name        := NULL;
      lv_edi_district_kana        := NULL;
      lv_tsukagatazaiko_div       := NULL;
      lv_tsukagatazaiko_div_mst   := NULL;
      lv_deli_center_code         := NULL;
      lv_deli_center_name         := NULL;
      lv_edi_forward_number       := NULL;
      lv_cust_store_name          := NULL;
      lv_torihikisaki_code        := NULL;
      lv_tsukagatazaiko_flag      := NULL;
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add start by S.Niki
      lv_vist_target_div          := NULL;  --�K��Ώۋ敪
-- 2012/04/19 Ver1.8 E_�{�ғ�_09272 add start by S.Niki
      lv_vist_target_div_mst      := NULL;  --�K��Ώۋ敪�m�F�p�ϐ�
-- 2012/04/19 Ver1.8 E_�{�ғ�_09272 add end by S.Niki
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
      lv_cnvs_base_code           := NULL;  --�l�����_�R�[�h
      lv_cnvs_base_code_mst1      := NULL;  --�l�����_�R�[�h�m�F�p�ϐ�1
      lv_cnvs_base_code_mst2      := NULL;  --�l�����_�R�[�h�m�F�p�ϐ�2
      lv_cnvs_business_person     := NULL;  --�l���c�ƈ�
      lv_cnvs_business_person_mst1 := NULL; --�l���c�ƈ��m�F�p�ϐ�1
      lv_cnvs_business_person_mst2 := NULL; --�l���c�ƈ��m�F�p�ϐ�2
      lv_base_code_flag1          := NULL;  --�l�����_�R�[�h���̓`�F�b�N�p1
      lv_business_person_flag1    := NULL;  --�l���c�ƈ����̓`�F�b�N�p1
      lv_base_code_flag2          := NULL;  --�l�����_�R�[�h���̓`�F�b�N�p2
      lv_business_person_flag2    := NULL;  --�l���c�ƈ����̓`�F�b�N�p2
      lv_base_code_flag3          := NULL;  --�l�����_�R�[�h���̓`�F�b�N�p3
      lv_business_person_flag3    := NULL;  --�l���c�ƈ����̓`�F�b�N�p3
      lv_base_code_flag4          := NULL;  --�l�����_�R�[�h���̓`�F�b�N�p4
      lv_business_person_flag4    := NULL;  --�l���c�ƈ����̓`�F�b�N�p4
      lv_new_point_div            := NULL;  --�V�K�|�C���g�敪
      lv_new_point_div_mst        := NULL;  --�V�K�|�C���g�敪�`�F�b�N�p
      lv_new_point                := NULL;  --�V�K�|�C���g
      ln_new_point                := NULL;  --�V�K�|�C���g(���l)
      lv_intro_base_code          := NULL;  --�Љ�_
      lv_intro_base_code_mst1     := NULL;  --�Љ�_�R�[�h�m�F�p1
      lv_intro_base_code_mst2     := NULL;  --�Љ�_�R�[�h�m�F�p2
      lv_intro_business_person    := NULL;  --�Љ�c�ƈ�
      lv_intro_business_person_mst1 := NULL;  --�Љ�c�ƈ��`�F�b�N�p1
      lv_intro_business_person_mst2 := NULL;  --�Љ�c�ƈ��`�F�b�N�p2
      lv_int_bus_per_flag1        := NULL;  --�Љ�c�ƈ��`�F�b�N�p1
      lv_int_bus_per_flag2        := NULL;  --�Љ�c�ƈ��`�F�b�N�p2
      lv_base_code                := NULL;  --�{���S�����_
      lv_base_code_mst            := NULL;  --�{���S�����_�`�F�b�N�p
      lv_tdb_code                 := NULL;  --TDB�R�[�h
      lv_corp_approval_date       := NULL;  --���ٓ��t
      lv_intro_chain_code1        := NULL;  --�Љ�҃`�F�[���R�[�h�P
      lv_intro_chain_code2        := NULL;  --�Љ�҃`�F�[���R�[�h�Q
      lv_sales_head_base_code     := NULL;  --�̔���{���S�����_
      lv_sales_head_base_code_mst := NULL;  --�̔���{���S�����_�`�F�b�N�p
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
    END LOOP cust_data_wk_loop;
--
    --�f�[�^�G���[�����b�Z�[�W�ݒ�i�R���J�����g�o�́j
    IF (lv_retcode <> cv_status_normal) THEN
      --�f�[�^�G���[�����b�Z�[�W�擾
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => gv_xxcmm_msg_kbn
                      ,iv_name         => cv_invalid_data_msg
                     );
      lv_errmsg := gv_out_msg;
      lv_errbuf := gv_out_msg;
      RAISE invalid_data_expt;
    END IF;
--
    COMMIT;
--
  EXCEPTION
    WHEN get_csv_err_expt THEN                         --*** �ڋq�ꊇ�X�V�pCSV�擾���s��O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN invalid_data_expt THEN                        --*** �ڋq�ꊇ�X�V���s����O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END cust_data_make_wk;
--
  /**********************************************************************************
   * Procedure Name   : rock_and_update_cust
   * Description      : �e�[�u�����b�N����(A-3)�E�ڋq�ꊇ�X�V����(A-4)
   ***********************************************************************************/
  PROCEDURE rock_and_update_cust(
    in_file_id              IN  NUMBER,              --   �t�@�C��ID
    ov_errbuf               OUT VARCHAR2,            --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode              OUT VARCHAR2,            --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg               OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'rock_and_update_cust'; -- �v���O������
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
    cv_bill_to               CONSTANT VARCHAR2(7)     := 'BILL_TO';               --�g�p�ړI�E������
    cv_other_to              CONSTANT VARCHAR2(8)     := 'OTHER_TO';              --�g�p�ړI�E���̑�
-- 2009/10/23 Ver1.2 delete start by Yutaka.Kuboshima
--    cv_aff_dept              CONSTANT VARCHAR2(15)    := 'XX03_DEPARTMENT';       --AFF����}�X�^�Q�ƃ^�C�v
-- 2009/10/23 Ver1.2 delete end by Yutaka.Kuboshima
    cv_chain_code            CONSTANT VARCHAR2(16)    := 'XXCMM_CHAIN_CODE';      --�Q�ƃR�[�h�F�`�F�[���X�Q�ƃ^�C�v
    cv_null_x                CONSTANT VARCHAR2(1)     := 'X';                     --NVL�p�_�~�[������
    cn_zero                  CONSTANT NUMBER(1)       := 0;                       --NVL�p�_�~�[���l
    cv_customer              CONSTANT VARCHAR2(2)     := '10';                    --�ڋq�敪�E�ڋq
    cv_su_customer           CONSTANT VARCHAR2(2)     := '12';                    --�ڋq�敪�E��l�ڋq
    cv_trust_corp            CONSTANT VARCHAR2(2)     := '13';                    --�ڋq�敪�E�@�l�Ǘ���
    cv_ar_manage             CONSTANT VARCHAR2(2)     := '14';                    --�ڋq�敪�E���|�Ǘ���ڋq
    cv_yes_output            CONSTANT VARCHAR2(1)     := 'Y';                     --�o�͗L���E�L
    cv_no_output             CONSTANT VARCHAR2(1)     := 'N';                     --�o�͗L���E��
    cv_corp_no_data          CONSTANT VARCHAR2(20)    := '�ڋq�@�l��񖢓o�^�B';  --�ڋq�@�l��񖢐ݒ�
    cv_addon_cust_no_data    CONSTANT VARCHAR2(20)    := '�ڋq�ǉ���񖢓o�^�B';  --�ڋq�ǉ���񖢐ݒ�
    cv_sales_base_class      CONSTANT VARCHAR2(1)     := '1';                     --�ڋq�敪�E���_
    cv_ignore                CONSTANT VARCHAR2(1)     := 'I';                     --�ڋq�}�X�^�E�X�e�[�^�X����
    cv_ng_word               CONSTANT VARCHAR2(7)     := 'NG_WORD';               --CSV�o�̓G���[�g�[�N���ENG_WORD
    cv_err_cust_code_msg     CONSTANT VARCHAR2(16)    := '�G���[�ڋq�R�[�h';      --CSV�o�̓G���[������
    cv_ng_data               CONSTANT VARCHAR2(7)     := 'NG_DATA';               --CSV�o�̓G���[�g�[�N���ENG_DATA
    cv_success_api           CONSTANT VARCHAR2(1)     := 'S';                     --API�������ԋp�X�e�[�^�X
    cv_init_list_api         CONSTANT VARCHAR2(1)     := 'T';                     --API�N���������X�g�ݒ�l
    cv_user_entered          CONSTANT VARCHAR2(12)    := 'USER_ENTERED';          --�p�[�e�B�}�X�^�X�V�`�o�h�R���e���c�\�[�X�^�C�v
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
    cv_ship_to               CONSTANT VARCHAR2(7)     := 'SHIP_TO';               --�g�p�ړI�E�o�א�
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/01/27 Ver1.4 E_�{�ғ�_01280 add start by Yutaka.Kuboshima
    cv_a_flag                CONSTANT VARCHAR2(1)     := 'A';                     --�X�e�[�^�X(�L��)
-- 2010/01/27 Ver1.4 E_�{�ғ�_01280 add start by Yutaka.Kuboshima
--
    -- *** ���[�J���ϐ� ***
    lv_header_str                     VARCHAR2(2000)  := NULL;                    --�w�b�_���b�Z�[�W�i�[�p�ϐ�
    lv_output_str                     VARCHAR2(2047)  := NULL;                    --�o�͕�����i�[�p�ϐ�
    ln_output_cnt                     NUMBER          := 0;                       --�o�͌���
    lv_sales_kigyou_code              fnd_flex_values.attribute1%TYPE;            --��ƃR�[�h�i�̔���j�i�[�p�ϐ�
    lv_delivery_kigyou_code           fnd_flex_values.attribute1%TYPE;            --��ƃR�[�h�i�[�i��j�i�[�p�ϐ�
    lv_output_excute                  VARCHAR2(1)     := 'Y';                     --�o�͗L��
    ln_credit_limit                   xxcmm_mst_corporate.credit_limit%TYPE;      --�ڋq�@�l���.�^�M���x�z
    lv_decide_div                     xxcmm_mst_corporate.decide_div%TYPE;        --�ڋq�@�l���.����敪
    lv_information                    VARCHAR2(100)   := NULL;
    lv_sales_base_name                VARCHAR2(50)    := NULL;
--
    --�ڋq�X�V�`�o�h�p�ϐ�
    p_cust_account_rec                HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
    ln_cust_object_version_number     NUMBER;
--
    --�p�[�e�B�X�V�`�o�h�p�ϐ�
    ln_party_id                       NUMBER;
    lv_content_source_type            VARCHAR2(12);
    p_party_rec                       HZ_PARTY_V2PUB.PARTY_REC_TYPE;
    p_organization_rec                HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    ln_party_object_version_number    NUMBER;
    ln_profile_id                     NUMBER;
--
    --�ڋq�g�p�ړI�X�V�`�o�h�p�ϐ�
    p_cust_site_use_rec               HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
    ln_csu_object_version_number      NUMBER;
    ln_payment_term_id                NUMBER;
    ln_payment_term_second_id         NUMBER;
    ln_payment_term_third_id          NUMBER;
--
    --�ڋq���Ə��X�V�`�o�h�p�ϐ�
    p_location_rec                    HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
    ln_location_object_version_num    NUMBER;
--
    --�`�o�h�p�ėp�ϐ�
    lv_return_status                  VARCHAR2(1);
    ln_msg_count                      NUMBER;
    lv_msg_data                       VARCHAR2(2000);
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
    -- �ڋq�g�p�ړI�}�X�^�o�א惌�R�[�h�X�V�`�o�h�p�ϐ�
    p_cust_site_use_ship_rec          HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
    ln_csu_ship_object_number         NUMBER;
    ln_price_list                     NUMBER;
--
    -- �ڋq�ǉ����}�X�^�X�V�p�ϐ�
    l_xxcmm_cust_accounts             xxcmm_cust_accounts%ROWTYPE;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
    -- �ڋq�@�l���}�X�^�X�V�p�ϐ�
    l_xxcmm_mst_corporate             xxcmm_mst_corporate%ROWTYPE;
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
    --
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �ڋq�ꊇ�X�V���J�[�\��
    CURSOR cust_data_cur(
      in_file_id_wk IN NUMBER )
    IS
      SELECT  hca.cust_account_id         customer_id,                --�ڋqID
              hca.account_number          customer_number,            --�ڋq�ԍ�
              hca.object_version_number   cust_ovn,                   --�ڋq�I�u�W�F�N�g����ԍ�
              hca.party_id                party_id,                   --�p�[�e�BID
              hp.object_version_number    party_ovn,                  --�p�[�e�B�I�u�W�F�N�g����ԍ�
              hcsu.site_use_id            site_use_id,                --�ڋq�g�p�ړIID
              hcsu.bill_to_site_use_id    bill_to_site_use_id,        --�ڋq������g�p�ړIID
              hcsu.object_version_number  site_use_ovn,               --�ڋq�g�p�ړI�I�u�W�F�N�g����ԍ�
              hl.location_id              location_id,                --���P�[�V����ID
              hl.object_version_number    location_ovn,               --���P�[�V�����I�u�W�F�N�g����ԍ�
              xca.stop_approval_reason    addon_approval_reason,      --�ڋq�ǉ����E���~���R
              xca.stop_approval_date      addon_approval_date,        --�ڋq�ǉ����E���~���ϓ�
              xca.sales_chain_code        addon_sales_chain_code,     --�ڋq�ǉ����E�`�F�[���X�R�[�h�i�̔���j
              xca.delivery_chain_code     addon_delivery_chain_code,  --�ڋq�ǉ����E�`�F�[���X�R�[�h�i�[�i��j
              xca.policy_chain_code       addon_policy_chain_code,    --�ڋq�ǉ����E�`�F�[���X�R�[�h�i�c�Ɛ����p�j
              xca.business_low_type       addon_business_low_type,    --�ڋq�ǉ����E�Ƒԁi�����ށj
              xca.chain_store_code        addon_chain_store_code,     --�ڋq�ǉ����E�`�F�[���X�R�[�h�i�d�c�h�j
              xca.store_code              addon_store_code,           --�ڋq�ǉ����E���~���ϓ�
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
              xca.invoice_printing_unit   addon_invoice_class,        --�ڋq�ǉ����E����������P��
              xca.invoice_code            addon_invoice_code,         --�ڋq�ǉ����E�������p�R�[�h
              xca.industry_div            addon_industry_div,         --�ڋq�ǉ����E�Ǝ�
              xca.bill_base_code          addon_bill_base_code,       --�ڋq�ǉ����E�������_
              xca.receiv_base_code        addon_receiv_base_code,     --�ڋq�ǉ����E�������_
              xca.delivery_base_code      addon_delivery_base_code,   --�ڋq�ǉ����E�[�i���_
              xca.selling_transfer_div    addon_selling_transfer_div, --�ڋq�ǉ����E������ѐU��
              xca.card_company            addon_card_company,         --�ڋq�ǉ����E�J�[�h���
              xca.wholesale_ctrl_code     addon_wholesale_ctrl_code,  --�ڋq�ǉ����E�≮�Ǘ��R�[�h
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
              xmc.credit_limit            addon_credit_limit,         --�ڋq�@�l���E�^�M���x�z
              xmc.decide_div              addon_decide_div,           --�ڋq�@�l���E����敪
              xwcbr.customer_name         customer_name,              --�ڋq����
              xwcbr.customer_name_kana    customer_name_kana,         --�ڋq���̃J�i
              xwcbr.customer_name_ryaku   customer_name_ryaku,        --����
              xwcbr.customer_status       customer_status,            --�ڋq�X�e�[�^�X
              xwcbr.ar_invoice_code       ar_invoice_code,            --���|�R�[�h�P�i�������j
              xwcbr.ar_location_code      ar_location_code,           --���|�R�[�h�Q�i���Ə��j
              xwcbr.ar_others_code        ar_others_code,             --���|�R�[�h�R�i���̑��j
              xwcbr.invoice_class         invoice_class,              --����������P��
              xwcbr.invoice_cycle         invoice_cycle,              --���������s�T�C�N��
              xwcbr.invoice_form          invoice_form,               --�������o�͌`��
              xwcbr.payment_term_id       payment_term_id,            --�x������
              xwcbr.payment_term_second   payment_term_second,        --��2�x������
              xwcbr.payment_term_third    payment_term_third,         --��3�x������
              xwcbr.postal_code           postal_code,                --�X�֔ԍ�
              xwcbr.state                 state,                      --�s���{��
              xwcbr.city                  city,                       --�s�E��
              xwcbr.address1              address1,                   --�Z��1
              xwcbr.address2              address2,                   --�Z��2
              xwcbr.address3              address3,                   --�n��R�[�h
              xwcbr.approval_reason       approval_reason,            --���~���R
              xwcbr.approval_date         approval_date,              --���~���ϓ�
              xwcbr.sales_chain_code      sales_chain_code,           --�`�F�[���X�R�[�h�i�̔���j
              xwcbr.delivery_chain_code   delivery_chain_code,        --�`�F�[���X�R�[�h�i�[�i��j
              xwcbr.policy_chain_code     policy_chain_code,          --�`�F�[���X�R�[�h�i�c�Ɛ����p�j
              xwcbr.chain_store_code      chain_store_code,           --�`�F�[���X�R�[�h�i�d�c�h�j
              xwcbr.store_code            store_code,                 --�X�܃R�[�h
              xwcbr.business_low_type     business_low_type,          --�Ƒԁi�����ށj
              xwcbr.credit_limit          credit_limit,               --�^�M���x�z
              xwcbr.decide_div            decide_div,                 --����敪
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
              xwcbr.invoice_code          invoice_code,               --�������p�R�[�h
              xwcbr.industry_div          industry_div,               --�Ǝ�
              xwcbr.bill_base_code        bill_base_code,             --�������_
              xwcbr.receiv_base_code      receiv_base_code,           --�������_
              xwcbr.delivery_base_code    delivery_base_code,         --�[�i���_
              xwcbr.selling_transfer_div  selling_transfer_div,       --������ѐU��
              xwcbr.card_company          card_company,               --�J�[�h���
              xwcbr.wholesale_ctrl_code   wholesale_ctrl_code,        --�≮�Ǘ��R�[�h
              xwcbr.price_list            price_list,                 --���i�\
              hcas.cust_acct_site_id      cust_acct_site_id,          --���ݒnID
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
--
-- 2009/10/23 Ver1.2 modify start by Yutaka.Kuboshima
--              xwcbr.customer_class_code   customer_class_code         --�ڋq�敪
              hca.customer_class_code     customer_class_code         --�ڋq�敪
-- 2009/10/23 Ver1.2 modify end by Yutaka.Kuboshima
--
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add start by Yutaka.Kuboshima
             ,xca.past_customer_status    addon_past_customer_status  --�ڋq�ǉ����E�O���ڋq�X�e�[�^�X
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
             ,xwcbr.ship_storage_code     ship_storage_code           --�o�׌��ۊǏꏊ
             ,xca.ship_storage_code       addon_ship_storage_code     --�ڋq�ǉ����E�o�׌��ۊǏꏊ
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add start by K.Kubo
             ,xwcbr.delivery_order        delivery_order              --�z�����iEDI�j
             ,xca.delivery_order          addon_delivery_order        --�ڋq�ǉ����E�z�����iEDI�j
             ,xwcbr.edi_district_code     edi_district_code           --EDI�n��R�[�h�iEDI�j
             ,xca.edi_district_code       addon_edi_district_code     --�ڋq�ǉ����EEDI�n��R�[�h�iEDI�j
             ,xwcbr.edi_district_name     edi_district_name           --EDI�n�於�iEDI�j
             ,xca.edi_district_name       addon_edi_district_name     --�ڋq�ǉ����EEDI�n�於�iEDI�j
             ,xwcbr.edi_district_kana     edi_district_kana           --EDI�n�於�J�i�iEDI�j
             ,xca.edi_district_kana       addon_edi_district_kana     --�ڋq�ǉ����EEDI�n�於�J�i�iEDI�j
             ,xwcbr.tsukagatazaiko_div    tsukagatazaiko_div          --�ʉߍ݌Ɍ^�敪�iEDI�j
             ,xca.tsukagatazaiko_div      addon_tsukagatazaiko_div    --�ڋq�ǉ����E�ʉߍ݌Ɍ^�敪�iEDI�j
             ,xwcbr.deli_center_code      deli_center_code            --EDI�[�i�Z���^�[�R�[�h
             ,xca.deli_center_code        addon_deli_center_code      --�ڋq�ǉ����EEDI�[�i�Z���^�[�R�[�h
             ,xwcbr.deli_center_name      deli_center_name            --EDI�[�i�Z���^�[��
             ,xca.deli_center_name        addon_deli_center_name      --�ڋq�ǉ����EEDI�[�i�Z���^�[��
             ,xwcbr.edi_forward_number    edi_forward_number          --EDI�`���ǔ�
             ,xca.edi_forward_number      addon_edi_forward_number    --�ڋq�ǉ����EEDI�`���ǔ�
             ,xwcbr.cust_store_name       cust_store_name             --�ڋq�X�ܖ���
             ,xca.cust_store_name         addon_cust_store_name       --�ڋq�ǉ����E�ڋq�X�ܖ���
             ,xwcbr.torihikisaki_code     torihikisaki_code           --�����R�[�h
             ,xca.torihikisaki_code       addon_torihikisaki_code     --�ڋq�ǉ����E�����R�[�h
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add start by S.Niki
             ,xwcbr.vist_target_div       vist_target_div             --�K��Ώۋ敪
             ,xca.vist_target_div         addon_vist_target_div       --�ڋq�ǉ����E�K��Ώۋ敪
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
             ,xwcbr.intro_chain_code1      intro_chain_code1         --�Љ�҃`�F�[���R�[�h�P
             ,xca.intro_chain_code1        addon_intro_chain_code1   --�ڋq�ǉ����E�Љ�҃`�F�[���R�[�h�P
             ,xwcbr.intro_chain_code2      intro_chain_code2         --�Љ�҃`�F�[���R�[�h�Q
             ,xca.intro_chain_code2        addon_intro_chain_code2   --�ڋq�ǉ����E�Љ�҃`�F�[���R�[�h�Q
             ,xwcbr.sales_head_base_code   sales_head_base_code      --�̔���{���S�����_
             ,xca.sales_head_base_code     addon_sales_head_base_code  --�ڋq�ǉ����E�̔���{���S�����_
             ,xwcbr.cnvs_base_code         cnvs_base_code            --�l�����_�R�[�h
             ,xca.cnvs_base_code           addon_cnvs_base_code      --�ڋq�ǉ����E�l�����_�R�[�h
             ,xwcbr.cnvs_business_person   cnvs_business_person      --�l���c�ƈ�
             ,xca.cnvs_business_person     addon_cnvs_business_person  --�ڋq�ǉ����E�l���c�ƈ�
             ,xwcbr.new_point_div          new_point_div             --�V�K�|�C���g�敪
             ,xca.new_point_div            addon_new_point_div       --�ڋq�ǉ����E�V�K�|�C���g�敪
             ,xwcbr.new_point              new_point                 --�V�K�|�C���g
             ,xca.new_point                addon_new_point           --�ڋq�ǉ����E�V�K�|�C���g
             ,xwcbr.intro_base_code        intro_base_code           --�Љ�_�R�[�h
             ,xca.intro_base_code          addon_intro_base_code     --�ڋq�ǉ����E�Љ�_�R�[�h
             ,xwcbr.intro_business_person  intro_business_person     --�Љ�c�ƈ�
             ,xca.intro_business_person    addon_intro_business_person  --�ڋq�ǉ����E�Љ�c�ƈ�
             ,xwcbr.tdb_code               tdb_code                  --TDB�R�[�h
             ,xmc.tdb_code                 addon_tdb_code            --�ڋq�@�l���ETDB�R�[�h
             ,xwcbr.corp_approval_date     corp_approval_date        --���ٓ��t
             ,xmc.approval_date            addon_corp_approval_date  --�ڋq�@�l���E���ٓ��t
             ,xwcbr.base_code              base_code                 --�{���S�����_
             ,xmc.base_code                addon_base_code           --�ڋq�@�l���E�{���S�����_
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
      FROM    hz_cust_accounts     hca,
              hz_cust_acct_sites   hcas,
              hz_cust_site_uses    hcsu,
              hz_parties           hp,
              hz_party_sites       hps,
              hz_locations         hl,
              xxcmm_cust_accounts  xca,
              xxcmm_mst_corporate  xmc,
              xxcmm_wk_cust_batch_regist xwcbr
      WHERE   hca.cust_account_id       = hcas.cust_account_id
      AND     hcas.cust_acct_site_id    = hcsu.cust_acct_site_id
      AND     ((hcsu.site_use_code      = cv_bill_to
              AND hca.customer_class_code IN (cv_customer, cv_su_customer, cv_ar_manage))
      OR      (hcsu.site_use_code       = cv_other_to
              AND hca.customer_class_code NOT IN (cv_customer, cv_su_customer, cv_ar_manage)))
      AND     hca.party_id              = hp.party_id
      AND     hp.party_id               = hps.party_id
      AND     hps.location_id           = hl.location_id
      AND     xca.customer_id           = hca.cust_account_id
      AND     xmc.customer_id (+)       = hca.cust_account_id
      AND     hcas.org_id = gv_org_id
      AND     hcsu.org_id = gv_org_id
      AND     hcas.party_site_id        = hps.party_site_id
      AND     hps.location_id           = (SELECT MIN(hpsiv.location_id)
                                           FROM   hz_cust_acct_sites hcasiv,
                                                  hz_party_sites     hpsiv
                                           WHERE  hcasiv.cust_account_id = hca.cust_account_id
                                           AND    hcasiv.party_site_id   = hpsiv.party_site_id)
      AND     hca.account_number        = xwcbr.customer_code
-- 2010/01/27 Ver1.4 E_�{�ғ�_01280 add start by Yutaka.Kuboshima
      AND     hcsu.status               = cv_a_flag
-- 2010/01/27 Ver1.4 E_�{�ғ�_01280 add end by Yutaka.Kuboshima
      AND     xwcbr.file_id             = in_file_id_wk
      FOR UPDATE NOWAIT
      ;
    -- �x�������擾�J�[�\��
    CURSOR get_payment_term_cur(
      iv_payment_term IN VARCHAR2)
    IS
      SELECT rt.term_id  payment_term_id
      FROM   ra_terms    rt
      WHERE  rt.name   = iv_payment_term
      AND    ROWNUM    = 1
      ;
    -- �x�������`�F�b�N�J�[�\�����R�[�h�^
    get_payment_term_rec  get_payment_term_cur%ROWTYPE;
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
    -- �ڋq�g�p�ړI�}�X�^�o�א惌�R�[�h���b�N�J�[�\��
    CURSOR get_rock_hcsu_ship_cur(
      in_cust_acct_site_id IN NUMBER)
    IS
      SELECT hcsu.site_use_id           site_use_id
            ,hcsu.cust_acct_site_id     cust_acct_site_id
            ,hcsu.object_version_number object_version_number
            ,hcsu.price_list_id         price_list_id
      FROM   hz_cust_site_uses hcsu
      WHERE  hcsu.site_use_code     = cv_ship_to
-- 2010/01/27 Ver1.4 E_�{�ғ�_01280 add start by Yutaka.Kuboshima
      AND     hcsu.status           = cv_a_flag
-- 2010/01/27 Ver1.4 E_�{�ғ�_01280 add end by Yutaka.Kuboshima
      AND    hcsu.cust_acct_site_id = in_cust_acct_site_id
      ;
    -- �ڋq�g�p�ړI�}�X�^�o�א惌�R�[�h���b�N�J�[�\�����R�[�h�^
    get_rock_hcsu_ship_rec  get_rock_hcsu_ship_cur%ROWTYPE;
--
    -- ���i�\�擾�J�[�\��
    CURSOR get_price_list_cur(
      iv_price_list IN VARCHAR2)
    IS
      SELECT qlhb.list_header_id list_header_id
      FROM   qp_list_headers_tl  qlht
            ,qp_list_headers_b   qlhb
      WHERE  qlht.list_header_id    = qlhb.list_header_id
      AND    qlht.source_lang       = cv_language_ja
      AND    qlht.language          = cv_language_ja
      AND    qlhb.orig_org_id       = fnd_global.org_id
      AND    qlhb.list_type_code    = cv_list_type_prl
      AND    gd_process_date BETWEEN NVL(qlhb.start_date_active, gd_process_date)
                                 AND NVL(qlhb.end_date_active, gd_process_date)
      AND    qlht.name              = iv_price_list
      ;
    -- ���i�\�`�F�b�N���R�[�h�^
    get_price_list_rec  get_price_list_cur%ROWTYPE;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
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
    --�ڋq�ꊇ�X�V���J�[�\���I�[�v��
    << cust_data_loop >>
    FOR cust_data_rec IN cust_data_cur( in_file_id )
    LOOP
      -- ===============================
      -- �ڋq�}�X�^�X�V
      -- ===============================
      --�ڋq�}�X�^�X�V�l�ݒ�
      p_cust_account_rec.cust_account_id  := cust_data_rec.customer_id;
      IF (cust_data_rec.customer_name_ryaku = cv_null_bar) THEN
        p_cust_account_rec.account_name   := CHR(0);                             --����(NULL)
      ELSE
        p_cust_account_rec.account_name   := cust_data_rec.customer_name_ryaku;  --����
      END IF;
      --�ڋq�X�e�[�^�X���u���~���ٍρv�̂Ƃ��A�ڋq�}�X�^�̗L���t���O�𖳌��ɂ���
      IF (cust_data_rec.customer_status = cv_stop_approved) THEN
        p_cust_account_rec.status         := cv_ignore;                          --�ڋq�X�e�[�^�X����
      END IF;
      ln_cust_object_version_number       := cust_data_rec.cust_ovn;
      --�ڋq�}�X�^�X�VAPI�Ăяo��
      hz_cust_account_v2pub.update_cust_account(
                                          cv_init_list_api,
                                          p_cust_account_rec,
                                          ln_cust_object_version_number,
                                          lv_return_status,
                                          ln_msg_count,
                                          lv_msg_data);
      --�ڋq�}�X�^�X�V�G���[���ARAISE
      IF lv_return_status <> cv_success_api THEN
        gv_out_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcmm_msg_kbn
                         ,iv_name         => cv_update_cust_err_msg
                         ,iv_token_name1  => cv_cust_code
                         ,iv_token_value1 => cust_data_rec.customer_number
                        );
        lv_errmsg := gv_out_msg;
        lv_errbuf := lv_msg_data;
        RAISE update_cust_err_expt;
      END IF;
      --�ϐ�������
      p_cust_account_rec.account_name  := NULL;
      p_cust_account_rec.status        := NULL;
      ln_cust_object_version_number    := NULL;
--
      -- ===============================
      -- �p�[�e�B�}�X�^�X�V
      -- ===============================
      --�p�[�e�B�}�X�^�X�V�l�ݒ�
      ln_party_id            := cust_data_rec.party_id;
      lv_content_source_type := cv_user_entered;
      ln_party_object_version_number := cust_data_rec.party_ovn;
      --�g�D���擾API
      hz_party_v2pub.get_organization_rec(
                                         cv_init_list_api,
                                         ln_party_id,
                                         lv_content_source_type,
                                         p_organization_rec,
                                         lv_return_status,
                                         ln_msg_count,
                                         lv_msg_data);
      --�p�[�e�B���擾API
      hz_party_v2pub.get_party_rec(
                                         cv_init_list_api,
                                         ln_party_id,
                                         p_party_rec,
                                         lv_return_status,
                                         ln_msg_count,
                                         lv_msg_data);
      --�p�[�e�B���X�V�l�ݒ�
      p_organization_rec.organization_name            := cust_data_rec.customer_name;       --�ڋq����
      IF (cust_data_rec.customer_name_kana = cv_null_bar) THEN
        p_organization_rec.organization_name_phonetic := CHR(0);                            --�ڋq���̃J�i(NULL)
      ELSE
        p_organization_rec.organization_name_phonetic := cust_data_rec.customer_name_kana;  --�ڋq���̃J�i
      END IF;
      p_organization_rec.duns_number_c                := cust_data_rec.customer_status;     --�ڋq�X�e�[�^�X
      p_organization_rec.party_rec                    := p_party_rec;
      --�p�[�e�B�}�X�^�X�VAPI�Ăяo��
      hz_party_v2pub.update_organization(
                                         cv_init_list_api,
                                         p_organization_rec,
                                         ln_party_object_version_number,
                                         ln_profile_id,
                                         lv_return_status,
                                         ln_msg_count,
                                         lv_msg_data);
      --�p�[�e�B�}�X�^�X�V�G���[���ARAISE
      IF lv_return_status <> cv_success_api THEN
        gv_out_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcmm_msg_kbn
                         ,iv_name         => cv_update_party_err_msg
                         ,iv_token_name1  => cv_cust_code
                         ,iv_token_value1 => cust_data_rec.customer_number
                        );
        lv_errmsg := gv_out_msg;
        lv_errbuf := lv_msg_data;
        RAISE update_party_err_expt;
      END IF;
      --�ϐ�������
      p_organization_rec.organization_name           := NULL;
      p_organization_rec.organization_name_phonetic  := NULL;
      p_organization_rec.duns_number_c               := NULL;
      p_organization_rec.party_rec                   := NULL;
      ln_party_object_version_number                 := NULL;
--
      -- ===============================
      -- �ڋq�g�p�ړI�X�V
      -- ===============================
      --�ڋq�敪'10'(�ڋq)�A'12'(��l�ڋq)�A'14'(���|�Ǘ���ڋq)�̂Ƃ��̂݁A�ڋq�g�p�ړI�X�V
      IF (cust_data_rec.customer_class_code   = cv_customer)
        OR (cust_data_rec.customer_class_code = cv_su_customer)
        OR (cust_data_rec.customer_class_code = cv_ar_manage) THEN
        --�x�������擾
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_id )
        LOOP
          ln_payment_term_id := get_payment_term_rec.payment_term_id;
        END LOOP get_payment_term_loop;
        --��2�x�������擾
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_second )
        LOOP
          ln_payment_term_second_id := get_payment_term_rec.payment_term_id;
        END LOOP get_payment_term_loop;
        --��3�x�������擾
        << get_payment_term_loop >>
        FOR get_payment_term_rec IN get_payment_term_cur( cust_data_rec.payment_term_third )
        LOOP
          ln_payment_term_third_id := get_payment_term_rec.payment_term_id;
        END LOOP get_payment_term_loop;
        --�ڋq�g�p�ړI�X�V�l�ݒ�
        p_cust_site_use_rec.site_use_id          := cust_data_rec.site_use_id;
        p_cust_site_use_rec.bill_to_site_use_id  := cust_data_rec.bill_to_site_use_id;
        IF (cust_data_rec.ar_invoice_code = cv_null_bar) THEN
          p_cust_site_use_rec.attribute4 := CHR(0);                          --���|�R�[�h�P�i�������j(NULL)
        ELSE
          p_cust_site_use_rec.attribute4 := cust_data_rec.ar_invoice_code;   --���|�R�[�h�P�i�������j
        END IF;
        IF (cust_data_rec.ar_location_code = cv_null_bar) THEN
          p_cust_site_use_rec.attribute5 := CHR(0);                          --���|�R�[�h�Q�i���Ə��j(NULL)
        ELSE
          p_cust_site_use_rec.attribute5 := cust_data_rec.ar_location_code;  --���|�R�[�h�Q�i���Ə��j
        END IF;
        IF (cust_data_rec.ar_others_code = cv_null_bar) THEN
          p_cust_site_use_rec.attribute6 := CHR(0);                          --���|�R�[�h�R�i���̑��j(NULL)
        ELSE
          p_cust_site_use_rec.attribute6 := cust_data_rec.ar_others_code;    --���|�R�[�h�R�i���̑��j
        END IF;
-- 2009/10/23 Ver1.2 delete start by Yutaka.Kuboshima
--       p_cust_site_use_rec.attribute1   := cust_data_rec.invoice_class;     --���������s�敪
-- 2009/10/23 Ver1.2 delete end by Yutaka.Kuboshima
        IF (cust_data_rec.invoice_cycle = cv_null_bar) THEN
          p_cust_site_use_rec.attribute8 := CHR(0);                          --���������s�T�C�N��(NULL)
        ELSE
          p_cust_site_use_rec.attribute8 := cust_data_rec.invoice_cycle;     --���������s�T�C�N��
        END IF;
        IF (cust_data_rec.invoice_form = cv_null_bar) THEN
          p_cust_site_use_rec.attribute7 := CHR(0);                          --�������o�͌`��(NULL)
        ELSE
          p_cust_site_use_rec.attribute7 := cust_data_rec.invoice_form;      --�������o�͌`��
        END IF;
        p_cust_site_use_rec.payment_term_id := ln_payment_term_id;           --�x������
        IF (cust_data_rec.payment_term_second = cv_null_bar) THEN
          p_cust_site_use_rec.attribute2 := CHR(0);                          --��2�x������(NULL)
        ELSE
          p_cust_site_use_rec.attribute2 := ln_payment_term_second_id;       --��2�x������
        END IF;
        IF (cust_data_rec.payment_term_third = cv_null_bar) THEN
          p_cust_site_use_rec.attribute3 := CHR(0);                          --��3�x������(NULL)
        ELSE
          p_cust_site_use_rec.attribute3 := ln_payment_term_third_id;        --��3�x������
        END IF;
        ln_csu_object_version_number     := cust_data_rec.site_use_ovn;      --�ڋq�g�p�ړI�I�u�W�F�N�g����ԍ�
        --�ڋq�g�p�ړI�}�X�^�X�VAPI�Ăяo��
        hz_cust_account_site_v2pub.update_cust_site_use(
                                            cv_init_list_api,
                                            p_cust_site_use_rec,
                                            ln_csu_object_version_number,
                                            lv_return_status,
                                            ln_msg_count,
                                            lv_msg_data);
        --�ڋq�g�p�ړI�}�X�^�X�V�G���[���ARAISE
        IF lv_return_status <> cv_success_api THEN
          gv_out_msg  := xxccp_common_pkg.get_msg(
                            iv_application  => gv_xxcmm_msg_kbn
                           ,iv_name         => cv_update_csu_err_msg
                           ,iv_token_name1  => cv_cust_code
                           ,iv_token_value1 => cust_data_rec.customer_number
                          );
          lv_errmsg := gv_out_msg;
          lv_errbuf := lv_msg_data;
          RAISE update_csu_err_expt;
        END IF;
        --�ϐ�������
        p_cust_site_use_rec.site_use_id          := NULL;
        p_cust_site_use_rec.bill_to_site_use_id  := NULL;
        p_cust_site_use_rec.attribute4           := NULL;
        p_cust_site_use_rec.attribute5           := NULL;
        p_cust_site_use_rec.attribute6           := NULL;
        p_cust_site_use_rec.attribute1           := NULL;
        p_cust_site_use_rec.attribute8           := NULL;
        p_cust_site_use_rec.attribute7           := NULL;
        p_cust_site_use_rec.payment_term_id      := NULL;
        p_cust_site_use_rec.attribute2           := NULL;
        p_cust_site_use_rec.attribute3           := NULL;
        ln_csu_object_version_number             := NULL;
        ln_payment_term_id                       := NULL;
        ln_payment_term_second_id                := NULL;
        ln_payment_term_third_id                 := NULL;
      END IF;
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
      -- �ڋq�g�p�ړI�}�X�^�o�א惌�R�[�h�X�V
      -- �ڋq�敪'10'(�ڋq)�A'12'(��l�ڋq)�̂Ƃ��A�o�א惌�R�[�h�X�V
      IF (cust_data_rec.customer_class_code IN (cv_customer, cv_su_customer)) THEN
        -- �ڋq�g�p�ړI�}�X�^�o�א惌�R�[�h���b�N
        << get_rock_hcsu_ship_loop >>
        FOR get_rock_hcsu_ship_rec IN get_rock_hcsu_ship_cur( cust_data_rec.cust_acct_site_id )
        LOOP
          -- ���i�\�ݒ�
          -- ���i�\��'-'�̏ꍇ
          IF (cust_data_rec.price_list = cv_null_bar) THEN
            -- FND_API.G_MISS_NUM���Z�b�g(���i�\��NULL�ɐݒ肷�邽��)
            ln_price_list := FND_API.G_MISS_NUM;
          ELSIF (cust_data_rec.price_list IS NULL) THEN
            -- �X�V�O�̒l���Z�b�g
            ln_price_list := get_rock_hcsu_ship_rec.price_list_id;
          ELSE
            -- CSV�̍��ڒl���牿�i�\���擾
            << get_price_list_loop >>
            FOR get_price_list_rec IN get_price_list_cur( cust_data_rec.price_list )
            LOOP
              ln_price_list := get_price_list_rec.list_header_id;
            END LOOP get_price_list_loop;
          END IF;
          -- �X�V���ڐݒ�
          p_cust_site_use_ship_rec.site_use_id       := get_rock_hcsu_ship_rec.site_use_id;           --�ڋq�g�p�ړIID
          p_cust_site_use_ship_rec.cust_acct_site_id := get_rock_hcsu_ship_rec.cust_acct_site_id;     --�ڋq���ݒnID
          p_cust_site_use_ship_rec.site_use_code     := cv_ship_to;                                   --�g�p�ړI�R�[�h
          p_cust_site_use_ship_rec.price_list_id     := ln_price_list;                                --���i�\
          ln_csu_ship_object_number                  := get_rock_hcsu_ship_rec.object_version_number; --�ڋq�g�p�ړI�I�u�W�F�N�g����ԍ�
          --�ڋq�g�p�ړI�}�X�^�X�VAPI�Ăяo��
          hz_cust_account_site_v2pub.update_cust_site_use(
                                              cv_init_list_api,
                                              p_cust_site_use_ship_rec,
                                              ln_csu_ship_object_number,
                                              lv_return_status,
                                              ln_msg_count,
                                              lv_msg_data);
          --�ڋq�g�p�ړI�}�X�^�X�V�G���[���ARAISE
          IF lv_return_status <> cv_success_api THEN
            gv_out_msg  := xxccp_common_pkg.get_msg(
                              iv_application  => gv_xxcmm_msg_kbn
                             ,iv_name         => cv_update_csu_err_msg
                             ,iv_token_name1  => cv_cust_code
                             ,iv_token_value1 => cust_data_rec.customer_number
                            );
            lv_errmsg := gv_out_msg;
            lv_errbuf := lv_msg_data;
            RAISE update_csu_err_expt;
          END IF;
        END LOOP get_rock_hcsu_ship_loop;
        -- �ϐ�������
        p_cust_site_use_ship_rec  := NULL;
        ln_csu_ship_object_number := NULL;
        ln_price_list             := NULL;
      END IF;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
      --
      -- ===============================
      -- �ڋq���Ə��X�V
      -- ===============================
      p_location_rec.location_id        := cust_data_rec.location_id;
      p_location_rec.postal_code        := cust_data_rec.postal_code;   --�X�֔ԍ�
      p_location_rec.state              := cust_data_rec.state;         --�s���{��
      p_location_rec.city               := cust_data_rec.city;          --�s�E��
      p_location_rec.address1           := cust_data_rec.address1;      --�Z��1
      IF (cust_data_rec.address2 = cv_null_bar) THEN
        p_location_rec.address2         := CHR(0);                      --�Z��2(NULL)
      ELSE
        p_location_rec.address2         := cust_data_rec.address2;      --�Z��2
      END IF;
      p_location_rec.address3           := cust_data_rec.address3;      --�n��R�[�h
      ln_location_object_version_num    := cust_data_rec.location_ovn;
      --�ڋq���Ə��}�X�^�X�VAPI�Ăяo��
      hz_location_v2pub.update_location(
                                          cv_init_list_api,
                                          p_location_rec,
                                          ln_location_object_version_num,
                                          lv_return_status,
                                          ln_msg_count,
                                          lv_msg_data);
      --�ڋq���Ə��}�X�^�X�V�G���[���ARAISE
      IF lv_return_status <> cv_success_api THEN
        gv_out_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcmm_msg_kbn
                         ,iv_name         => cv_update_location_err_msg
                         ,iv_token_name1  => cv_cust_code
                         ,iv_token_value1 => cust_data_rec.customer_number
                        );
        lv_errmsg := gv_out_msg;
        lv_errbuf := lv_msg_data;
        RAISE update_location_err_expt;
      END IF;
      --�ϐ�������
      p_location_rec.location_id        := NULL;
      p_location_rec.postal_code        := NULL;
      p_location_rec.state              := NULL;
      p_location_rec.city               := NULL;
      p_location_rec.address1           := NULL;
      p_location_rec.address2           := NULL;
      p_location_rec.address3           := NULL;
      ln_location_object_version_num    := NULL;
--
    -- ===============================
    -- �ڋq�ǉ����X�V
    -- ===============================
-- 2009/10/23 modify start by Yutaka.Kuboshima
--    --�ڋq�敪��'10'(�ڋq)�A'14'(���|�Ǘ���ڋq)�̂Ƃ��̂݁A�`�F�[���X�R�[�h�i�̔���j�E�`�F�[���X�R�[�h�i�[�i��j�E
--    --�`�F�[���X�R�[�h�i�c�Ɛ����p�j�E�`�F�[���X�R�[�h�i�d�c�h�j�E�X�܃R�[�h���X�V
--    IF   (cust_data_rec.customer_class_code = cv_customer)
--      OR (cust_data_rec.customer_class_code = cv_ar_manage) THEN
--      UPDATE xxcmm_cust_accounts xca
--      SET    xca.stop_approval_reason   = DECODE(cust_data_rec.approval_reason,            --���~���R
--                                                 NULL,
--                                                 cust_data_rec.addon_approval_reason,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 cust_data_rec.approval_reason),
--             xca.stop_approval_date     = DECODE(cust_data_rec.approval_date,              --���~���ϓ�
--                                                 NULL,
--                                                 cust_data_rec.addon_approval_date,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 TO_DATE(cust_data_rec.approval_date,
--                                                         cv_date_format)),
--             xca.sales_chain_code       = DECODE(cust_data_rec.sales_chain_code,           --�`�F�[���X�R�[�h�i�̔���j
--                                                 NULL,
--                                                 cust_data_rec.addon_sales_chain_code,
--                                                 cust_data_rec.sales_chain_code),
--             xca.delivery_chain_code    = DECODE(cust_data_rec.delivery_chain_code,        --�`�F�[���X�R�[�h�i�[�i��j
--                                                 NULL,
--                                                 cust_data_rec.addon_delivery_chain_code,
--                                                 cust_data_rec.delivery_chain_code),
--             xca.policy_chain_code      = DECODE(cust_data_rec.policy_chain_code,          --�`�F�[���X�R�[�h�i�c�Ɛ����p�j
--                                                 NULL,
--                                                 cust_data_rec.addon_policy_chain_code,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 cust_data_rec.policy_chain_code),
--             xca.chain_store_code       = DECODE(cust_data_rec.chain_store_code,           --�`�F�[���X�R�[�h�i�d�c�h�j
--                                                 NULL,
--                                                 cust_data_rec.addon_chain_store_code,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 cust_data_rec.chain_store_code),
--             xca.store_code             = DECODE(cust_data_rec.store_code,                 --�X�܃R�[�h
--                                                 NULL,
--                                                 cust_data_rec.addon_store_code,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 cust_data_rec.store_code),
--             xca.business_low_type      = DECODE(cust_data_rec.business_low_type,          --�Ƒԁi�����ށj
--                                                 NULL,
--                                                 cust_data_rec.addon_business_low_type,
--                                                 cust_data_rec.business_low_type),
--             xca.last_updated_by        = fnd_global.user_id,                              --�ŏI�X�V��
--             xca.last_update_date       = sysdate,                                         --�ŏI�X�V��
--             xca.request_id             = fnd_profile.value(cv_conc_request_id),           --�v��ID
--             xca.program_application_id = fnd_profile.value(cv_prog_appl_id),              --�R���J�����g�E�v���O������A�v���P�[�V����ID
--             xca.program_id             = fnd_profile.value(cv_conc_program_id),           --�R���J�����g�E�v���O����ID
--             xca.program_update_date    = sysdate                                          --�v���O�����X�V��
--      WHERE  xca.customer_id = cust_data_rec.customer_id
--      ;
--    --����ȊO�̏ꍇ�A�`�F�[���X�R�[�h�i�̔���j�E�`�F�[���X�R�[�h�i�[�i��j�E�`�F�[���X�R�[�h�i�c�Ɛ����p�j�E
--    --�`�F�[���X�R�[�h�i�d�c�h�j�E�X�܃R�[�h�͍X�V���Ȃ�
--    ELSE
--      UPDATE xxcmm_cust_accounts xca
--      SET    xca.stop_approval_reason   = DECODE(cust_data_rec.approval_reason,            --���~���R
--                                                 NULL,
--                                                 cust_data_rec.addon_approval_reason,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 cust_data_rec.approval_reason),
--             xca.stop_approval_date     = DECODE(cust_data_rec.approval_date,              --���~���ϓ�
--                                                 NULL,
--                                                 cust_data_rec.addon_approval_date,
--                                                 cv_null_bar,
--                                                 NULL,
--                                                 TO_DATE(cust_data_rec.approval_date,
--                                                         cv_date_format)),
--             xca.business_low_type      = DECODE(cust_data_rec.business_low_type,          --�Ƒԁi�����ށj
--                                                 NULL,
--                                                 cust_data_rec.addon_business_low_type,
--                                                 cust_data_rec.business_low_type),
--             xca.last_updated_by        = fnd_global.user_id,                              --�ŏI�X�V��
--             xca.last_update_date       = sysdate,                                         --�ŏI�X�V��
--             xca.request_id             = fnd_profile.value(cv_conc_request_id),           --�v��ID
--             xca.program_application_id = fnd_profile.value(cv_prog_appl_id),              --�R���J�����g�E�v���O������A�v���P�[�V����ID
--             xca.program_id             = fnd_profile.value(cv_conc_program_id),           --�R���J�����g�E�v���O����ID
--             xca.program_update_date    = sysdate                                          --�v���O�����X�V��
--      WHERE  xca.customer_id = cust_data_rec.customer_id
--      ;
--    END IF;
--
    -- ===============================
    -- �ڋq�ǉ����}�X�^�X�V���ڐݒ�
    -- ===============================
    --
    -- ===============================
    -- ���~���R
    -- ===============================
    -- ���~���R��'-'�̏ꍇ
    IF (cust_data_rec.approval_reason = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.stop_approval_reason := NULL;
    -- ���~���R��NULL�̏ꍇ
    ELSIF (cust_data_rec.approval_reason IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.stop_approval_reason := cust_data_rec.addon_approval_reason;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.stop_approval_reason := cust_data_rec.approval_reason;
    END IF;
    --
    -- ===============================
    -- ���~���ϓ�
    -- ===============================
    -- ���~���ϓ���'-'�̏ꍇ
    IF (cust_data_rec.approval_date = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.stop_approval_date := NULL;
    -- ���~���ϓ���NULL�̏ꍇ
    ELSIF (cust_data_rec.approval_date IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.stop_approval_date := cust_data_rec.addon_approval_date;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.stop_approval_date := TO_DATE(cust_data_rec.approval_date, cv_date_format);
    END IF;
    --
    -- ===============================
    -- �`�F�[���X�R�[�h�i�̔���j
    -- ===============================
    -- �`�F�[���X�R�[�h�i�̔���j��NULL�܂��́A
    -- �ڋq�敪��'10','12','14','15','16'�ȊO�̏ꍇ
    IF (cust_data_rec.sales_chain_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn))
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.sales_chain_code := cust_data_rec.addon_sales_chain_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.sales_chain_code := cust_data_rec.sales_chain_code;
    END IF;
    --
    -- ===============================
    -- �`�F�[���X�R�[�h�i�[�i��j
    -- ===============================
    -- �`�F�[���X�R�[�h�i�[�i��j��NULL�܂��́A
    -- �ڋq�敪��'10','12','14','15','16'�ȊO�̏ꍇ
    IF (cust_data_rec.delivery_chain_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn, cv_tenpo_kbn, cv_tonya_kbn))
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.delivery_chain_code := cust_data_rec.addon_delivery_chain_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.delivery_chain_code := cust_data_rec.delivery_chain_code;
    END IF;
    --
    -- ===============================
    -- �`�F�[���X�R�[�h�i�c�Ɛ����p�j
    -- ===============================
    -- �`�F�[���X�R�[�h�i�c�Ɛ����p�j��'-'�̏ꍇ
    IF (cust_data_rec.policy_chain_code = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.policy_chain_code := NULL;
    -- �`�F�[���X�R�[�h�i�c�Ɛ����p�j��NULL�܂��́A
    -- �ڋq�敪��'10','14'�ȊO�̏ꍇ
    ELSIF (cust_data_rec.policy_chain_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_urikake_kbn))
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.policy_chain_code := cust_data_rec.addon_policy_chain_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.policy_chain_code := cust_data_rec.policy_chain_code;
    END IF;
    --
    -- ===============================
    -- �`�F�[���X�R�[�h�i�d�c�h�j
    -- ===============================
    -- �`�F�[���X�R�[�h�i�d�c�h�j��'-'�̏ꍇ
    IF (cust_data_rec.chain_store_code = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.chain_store_code := NULL;
    -- �`�F�[���X�R�[�h�i�d�c�h�j��NULL�܂��́A
    -- �ڋq�敪��'10','14'�ȊO�̏ꍇ
    ELSIF (cust_data_rec.chain_store_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_urikake_kbn))
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.chain_store_code := cust_data_rec.addon_chain_store_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.chain_store_code := cust_data_rec.chain_store_code;
    END IF;
    --
    -- ===============================
    -- �X�܃R�[�h
    -- ===============================
    -- �X�܃R�[�h��'-'�̏ꍇ
    IF (cust_data_rec.store_code = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.store_code := NULL;
    -- �X�܃R�[�h��NULL�܂��́A
    -- �ڋq�敪��'10','14','20','21'�ȊO�̏ꍇ
    ELSIF (cust_data_rec.store_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_urikake_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.store_code := cust_data_rec.addon_store_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.store_code := cust_data_rec.store_code;
    END IF;
    --
    -- ===============================
    -- �Ƒԁi�����ށj
    -- ===============================
    -- �Ƒԁi�����ށj��'-'�̏ꍇ
    IF (cust_data_rec.business_low_type = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.business_low_type := NULL;
    -- �Ƒԁi�����ށj��NULL�܂��́A
    -- �ڋq�敪��'18','19','20','21'�̏ꍇ
    ELSIF (cust_data_rec.business_low_type IS NULL)
      OR (cust_data_rec.customer_class_code IN (cv_edi_class, cv_hyakkaten_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.business_low_type := cust_data_rec.addon_business_low_type;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.business_low_type := cust_data_rec.business_low_type;
    END IF;
    --
    -- ===============================
    -- ����������P��
    -- ===============================
    -- ����������P�ʂ�NULL�܂��́A
    -- �ڋq�敪��'10'�ȊO�̏ꍇ
    IF (cust_data_rec.invoice_class IS NULL)
      OR (cust_data_rec.customer_class_code <> cv_kokyaku_kbn)
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.invoice_printing_unit := cust_data_rec.addon_invoice_class;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.invoice_printing_unit := cust_data_rec.invoice_class;
    END IF;
    --
    -- ===============================
    -- �������p�R�[�h
    -- ===============================
    -- �������p�R�[�h��'-'�̏ꍇ
    IF (cust_data_rec.invoice_code = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.invoice_code := NULL;
    -- �������p�R�[�h��NULL�܂��́A
    -- �ڋq�敪��'10'�ȊO�̏ꍇ
    ELSIF (cust_data_rec.invoice_code IS NULL)
      OR (cust_data_rec.customer_class_code <> cv_kokyaku_kbn)
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.invoice_code := cust_data_rec.addon_invoice_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.invoice_code := cust_data_rec.invoice_code;
    END IF;
    --
    -- ===============================
    -- �Ǝ�
    -- ===============================
    -- �Ǝ킪'-'�̏ꍇ
    IF (cust_data_rec.industry_div = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.industry_div := NULL;
    -- �Ǝ킪NULL�܂��́A
    -- �ڋq�敪��'18','19','20','21'�̏ꍇ
    ELSIF (cust_data_rec.industry_div IS NULL)
      OR (cust_data_rec.customer_class_code IN (cv_edi_class, cv_hyakkaten_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.industry_div := cust_data_rec.addon_industry_div;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.industry_div := cust_data_rec.industry_div;
    END IF;
    --
    -- ===============================
    -- �������_
    -- ===============================
    -- �������_��NULL�܂��́A
    -- �ڋq�敪��'10','12','14','20','21'�ȊO�̏ꍇ
    IF (cust_data_rec.bill_base_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.bill_base_code := cust_data_rec.addon_bill_base_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.bill_base_code := cust_data_rec.bill_base_code;
    END IF;
    --
    -- ===============================
    -- �������_
    -- ===============================
    -- �������_��NULL�܂��́A
    -- �ڋq�敪��'10','12','14'�ȊO�̏ꍇ
    IF (cust_data_rec.receiv_base_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn))
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.receiv_base_code := cust_data_rec.addon_receiv_base_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.receiv_base_code := cust_data_rec.receiv_base_code;
    END IF;
    --
    -- ===============================
    -- �[�i���_
    -- ===============================
    -- �[�i���_��'-'�̏ꍇ
    IF (cust_data_rec.delivery_base_code = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.delivery_base_code := NULL;
    -- �[�i���_��NULL�܂��́A
    -- �ڋq�敪��'10','12','14'�ȊO�̏ꍇ
    ELSIF (cust_data_rec.delivery_base_code IS NULL)
      OR (cust_data_rec.customer_class_code NOT IN (cv_kokyaku_kbn, cv_uesama_kbn, cv_urikake_kbn))
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.delivery_base_code := cust_data_rec.addon_delivery_base_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.delivery_base_code := cust_data_rec.delivery_base_code;
    END IF;
    --
    -- ===============================
    -- ������ѐU��
    -- ===============================
    -- ������ѐU�ւ�'-'�̏ꍇ
    IF (cust_data_rec.selling_transfer_div = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.selling_transfer_div := NULL;
    -- ������ѐU�ւ�NULL�܂��́A
    -- �ڋq�敪��'18','19','20','21'�̏ꍇ
    ELSIF (cust_data_rec.selling_transfer_div IS NULL)
      OR (cust_data_rec.customer_class_code IN (cv_edi_class, cv_hyakkaten_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.selling_transfer_div := cust_data_rec.addon_selling_transfer_div;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.selling_transfer_div := cust_data_rec.selling_transfer_div;
    END IF;
    --
    -- ===============================
    -- �J�[�h���
    -- ===============================
    -- �J�[�h��Ђ�'-'�̏ꍇ
    IF (cust_data_rec.card_company = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.card_company := NULL;
    -- �J�[�h��Ђ�NULL�܂��́A
    -- �ڋq�敪��'10'�ȊO�̏ꍇ
    ELSIF (cust_data_rec.card_company IS NULL)
      OR (cust_data_rec.customer_class_code <> cv_kokyaku_kbn)
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.card_company := cust_data_rec.addon_card_company;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.card_company := cust_data_rec.card_company;
    END IF;
    --
    -- ===============================
    -- �≮�Ǘ��R�[�h
    -- ===============================
    -- �≮�Ǘ��R�[�h��'-'�̏ꍇ
    IF (cust_data_rec.wholesale_ctrl_code = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.wholesale_ctrl_code := NULL;
    -- �≮�Ǘ��R�[�h��NULL�܂��́A
    -- �ڋq�敪��'18','19','20','21'�̏ꍇ
    ELSIF (cust_data_rec.wholesale_ctrl_code IS NULL)
      OR (cust_data_rec.customer_class_code IN (cv_edi_class, cv_hyakkaten_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.wholesale_ctrl_code := cust_data_rec.addon_wholesale_ctrl_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.wholesale_ctrl_code := cust_data_rec.wholesale_ctrl_code;
    END IF;
    --
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add start by Yutaka.Kuboshima
    -- ===============================
    -- �O���ڋq�X�e�[�^�X
    -- ===============================
    -- ���~���ٓ���'-'�̏ꍇ
    IF (NVL(cust_data_rec.approval_date, cv_null_bar) = cv_null_bar) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.past_customer_status := cust_data_rec.addon_past_customer_status;
    ELSE
      -- ���~���ٓ����O���̏ꍇ
      IF (TRUNC(TO_DATE(cust_data_rec.approval_date, cv_date_format), 'MM') = ADD_MONTHS(TRUNC(gd_process_date, 'MM'), -1)) THEN
        -- '90'(���~���ٍ�)���Z�b�g
        l_xxcmm_cust_accounts.past_customer_status := cv_stop_approved;
      ELSE
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_cust_accounts.past_customer_status := cust_data_rec.addon_past_customer_status;
      END IF;
    END IF;
    --
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add end by Yutaka.Kuboshima
    --
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
    -- ===============================
    -- �o�׌��ۊǏꏊ
    -- ===============================
    -- �o�׌��ۊǏꏊ��'-'�̏ꍇ
    IF (cust_data_rec.ship_storage_code = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.ship_storage_code := NULL;
    -- �o�׌��ۊǏꏊ��NULL�܂��́A
    -- �ڋq�敪��'18','19','20','21'�̏ꍇ
    ELSIF (cust_data_rec.ship_storage_code IS NULL)
      OR (cust_data_rec.customer_class_code IN (cv_edi_class, cv_hyakkaten_kbn, cv_seikyusho_kbn, cv_toukatu_kbn))
    THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.ship_storage_code := cust_data_rec.addon_ship_storage_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.ship_storage_code := cust_data_rec.ship_storage_code;
    END IF;
    --
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add start by K.Kubo
    -- ===============================
    -- �z�����iEDI�j
    -- ===============================
    -- �z�����iEDI�j��'-'�̏ꍇ
    IF (cust_data_rec.delivery_order = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.delivery_order := NULL;
    -- �z�����iEDI�j��NULL�̏ꍇ
    ELSIF (cust_data_rec.delivery_order IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.delivery_order := cust_data_rec.addon_delivery_order;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.delivery_order := cust_data_rec.delivery_order;
    END IF;
    --
    -- ===============================
    -- EDI�n��R�[�h�iEDI�j
    -- ===============================
    -- EDI�n��R�[�h�iEDI�j��'-'�̏ꍇ
    IF (cust_data_rec.edi_district_code = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.edi_district_code := NULL;
    -- EDI�n��R�[�h�iEDI�j��NULL�̏ꍇ
    ELSIF (cust_data_rec.edi_district_code IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.edi_district_code := cust_data_rec.addon_edi_district_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.edi_district_code := cust_data_rec.edi_district_code;
    END IF;
    --
    -- ===============================
    -- EDI�n�於�iEDI�j
    -- ===============================
    -- EDI�n�於�iEDI�j��'-'�̏ꍇ
    IF (cust_data_rec.edi_district_name = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.edi_district_name := NULL;
    -- EDI�n�於�iEDI�j��NULL�̏ꍇ
    ELSIF (cust_data_rec.edi_district_name IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.edi_district_name := cust_data_rec.addon_edi_district_name;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.edi_district_name := cust_data_rec.edi_district_name;
    END IF;
    --
    -- ===============================
    -- EDI�n�於�J�i�iEDI�j
    -- ===============================
    -- EDI�n�於�J�i�iEDI�j��'-'�̏ꍇ
    IF (cust_data_rec.edi_district_kana = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.edi_district_kana := NULL;
    -- EDI�n�於�J�i�iEDI�j��NULL�̏ꍇ
    ELSIF (cust_data_rec.edi_district_kana IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.edi_district_kana := cust_data_rec.addon_edi_district_kana;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.edi_district_kana := cust_data_rec.edi_district_kana;
    END IF;
    --
    -- ===============================
    -- �ʉߍ݌Ɍ^�敪�iEDI�j
    -- ===============================
    -- �ʉߍ݌Ɍ^�敪�iEDI�j��'-'�̏ꍇ
    IF (cust_data_rec.tsukagatazaiko_div = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.tsukagatazaiko_div := NULL;
    -- �ʉߍ݌Ɍ^�敪�iEDI�j��NULL�̏ꍇ
    ELSIF (cust_data_rec.tsukagatazaiko_div IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.tsukagatazaiko_div := cust_data_rec.addon_tsukagatazaiko_div;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.tsukagatazaiko_div := cust_data_rec.tsukagatazaiko_div;
    END IF;
    --
    -- ===============================
    -- EDI�[�i�Z���^�[�R�[�h
    -- ===============================
    -- EDI�[�i�Z���^�[�R�[�h��'-'�̏ꍇ
    IF (cust_data_rec.deli_center_code = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.deli_center_code := NULL;
    -- EDI�[�i�Z���^�[�R�[�h��NULL�̏ꍇ
    ELSIF (cust_data_rec.deli_center_code IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.deli_center_code := cust_data_rec.addon_deli_center_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.deli_center_code := cust_data_rec.deli_center_code;
    END IF;
    --
    -- ===============================
    -- EDI�[�i�Z���^�[��
    -- ===============================
    -- EDI�[�i�Z���^�[����'-'�̏ꍇ
    IF (cust_data_rec.deli_center_name = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.deli_center_name := NULL;
    -- EDI�[�i�Z���^�[����NULL�̏ꍇ
    ELSIF (cust_data_rec.deli_center_name IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.deli_center_name := cust_data_rec.addon_deli_center_name;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.deli_center_name := cust_data_rec.deli_center_name;
    END IF;
    --
    -- ===============================
    -- EDI�`���ǔ�
    -- ===============================
    -- EDI�`���ǔԂ�'-'�̏ꍇ
    IF (cust_data_rec.edi_forward_number = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.edi_forward_number := NULL;
    -- EDI�`���ǔԂ�NULL�̏ꍇ
    ELSIF (cust_data_rec.edi_forward_number IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.edi_forward_number := cust_data_rec.addon_edi_forward_number;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.edi_forward_number := cust_data_rec.edi_forward_number;
    END IF;
    --
    -- ===============================
    -- �ڋq�X�ܖ���
    -- ===============================
    -- �ڋq�X�ܖ��̂�'-'�̏ꍇ
    IF (cust_data_rec.cust_store_name = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.cust_store_name := NULL;
    -- �ڋq�X�ܖ��̂�NULL�̏ꍇ
    ELSIF (cust_data_rec.cust_store_name IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.cust_store_name := cust_data_rec.addon_cust_store_name;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.cust_store_name := cust_data_rec.cust_store_name;
    END IF;
    --
    -- ===============================
    -- �����R�[�h
    -- ===============================
    -- �����R�[�h��'-'�̏ꍇ
    IF (cust_data_rec.torihikisaki_code = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.torihikisaki_code := NULL;
    -- �����R�[�h��NULL�̏ꍇ
    ELSIF (cust_data_rec.torihikisaki_code IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.torihikisaki_code := cust_data_rec.addon_torihikisaki_code;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.torihikisaki_code := cust_data_rec.torihikisaki_code;
    END IF;
--
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add start by S.Niki
    -- ===============================
    -- �K��Ώۋ敪
    -- ===============================
    -- �K��Ώۋ敪��'-'�̏ꍇ
    IF (cust_data_rec.vist_target_div = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.vist_target_div := NULL;
    -- �K��Ώۋ敪��NULL�̏ꍇ
    ELSIF (cust_data_rec.vist_target_div IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.vist_target_div := cust_data_rec.addon_vist_target_div;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.vist_target_div := cust_data_rec.vist_target_div;
    END IF;
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
    -- ===============================
    -- �Љ�҃`�F�[���R�[�h�P
    -- ===============================
    -- �Љ�҃`�F�[���R�[�h�P��'-'�̏ꍇ
    IF (cust_data_rec.intro_chain_code1 = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.intro_chain_code1 := NULL;
    -- �Љ�҃`�F�[���R�[�h�P��NULL�̏ꍇ
    ELSIF (cust_data_rec.intro_chain_code1 IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.intro_chain_code1 := cust_data_rec.addon_intro_chain_code1;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.intro_chain_code1 := cust_data_rec.intro_chain_code1;
    END IF;
--
    -- ===============================
    -- �Љ�҃`�F�[���R�[�h�Q
    -- ===============================
    -- �Љ�҃`�F�[���R�[�h�Q��'-'�̏ꍇ
    IF (cust_data_rec.intro_chain_code2 = cv_null_bar) THEN
      -- NULL���Z�b�g
      l_xxcmm_cust_accounts.intro_chain_code2 := NULL;
    -- �Љ�҃`�F�[���R�[�h�Q��NULL�̏ꍇ
    ELSIF (cust_data_rec.intro_chain_code2 IS NULL) THEN
      -- �X�V�O�̒l���Z�b�g
      l_xxcmm_cust_accounts.intro_chain_code2 := cust_data_rec.addon_intro_chain_code2;
    ELSE
      -- CSV�̍��ڒl���Z�b�g
      l_xxcmm_cust_accounts.intro_chain_code2 := cust_data_rec.intro_chain_code2;
    END IF;
--
    -- ===============================
    -- �̔���{���S�����_
    -- ===============================
    --�ڋq�敪�u10�F�ڋq�v�u14�F���|�Ǘ���ڋq�v�u19�F�S�ݓX�`��v�̏ꍇ
    IF ( cust_data_rec.customer_class_code IN (cv_kokyaku_kbn, cv_urikake_kbn, cv_hyakkaten_kbn) ) THEN
      -- �̔���{���S�����_��'-'�̏ꍇ
      IF (cust_data_rec.sales_head_base_code = cv_null_bar) THEN
        -- NULL���Z�b�g
        l_xxcmm_cust_accounts.sales_head_base_code := NULL;
      -- �̔���{���S�����_��NULL�̏ꍇ
      ELSIF (cust_data_rec.sales_head_base_code IS NULL) THEN
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_cust_accounts.sales_head_base_code := cust_data_rec.addon_sales_head_base_code;
      ELSE
        -- CSV�̍��ڒl���Z�b�g
        l_xxcmm_cust_accounts.sales_head_base_code := cust_data_rec.sales_head_base_code;
      END IF;
    --
    ELSE
    --�ڋq�敪�u10�F�ڋq�v�u14�F���|�Ǘ���ڋq�v�u19�F�S�ݓX�`��v�ȊO�̏ꍇ�A�ݒ�s��
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_cust_accounts.sales_head_base_code := cust_data_rec.addon_sales_head_base_code;
    --
    END IF;
--
    -- ===============================
    -- �l�����_�R�[�h
    -- ===============================
    --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�̏ꍇ
    IF ( cust_data_rec.customer_class_code IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
      -- �l�����_�R�[�h��'-'�̏ꍇ
      IF (cust_data_rec.cnvs_base_code = cv_null_bar) THEN
        -- NULL���Z�b�g
        l_xxcmm_cust_accounts.cnvs_base_code := NULL;
      -- �l�����_�R�[�h��NULL�̏ꍇ
      ELSIF (cust_data_rec.cnvs_base_code IS NULL) THEN
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_cust_accounts.cnvs_base_code := cust_data_rec.addon_cnvs_base_code;
      ELSE
        -- CSV�̍��ڒl���Z�b�g
        l_xxcmm_cust_accounts.cnvs_base_code := cust_data_rec.cnvs_base_code;
      END IF;
    --
    ELSE
    --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�ȊO�̏ꍇ�A�ݒ�s��
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_cust_accounts.cnvs_base_code := cust_data_rec.addon_cnvs_base_code;
    --
    END IF;
--
    -- ===============================
    -- �l���c�ƈ�
    -- ===============================
    --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�̏ꍇ
    IF ( cust_data_rec.customer_class_code IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
      -- �l���c�ƈ���'-'�̏ꍇ
      IF (cust_data_rec.cnvs_business_person = cv_null_bar) THEN
        -- NULL���Z�b�g
        l_xxcmm_cust_accounts.cnvs_business_person := NULL;
      -- �l���c�ƈ���NULL�̏ꍇ
      ELSIF (cust_data_rec.cnvs_business_person IS NULL) THEN
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_cust_accounts.cnvs_business_person := cust_data_rec.addon_cnvs_business_person;
      ELSE
        -- CSV�̍��ڒl���Z�b�g
        l_xxcmm_cust_accounts.cnvs_business_person := cust_data_rec.cnvs_business_person;
      END IF;
    --
    ELSE
    --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�ȊO�̏ꍇ�A�ݒ�s��
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_cust_accounts.cnvs_business_person := cust_data_rec.addon_cnvs_business_person;
    --
    END IF;
--
    -- ===============================
    -- �V�K�|�C���g�敪
    -- ===============================
    --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�̏ꍇ
    IF ( cust_data_rec.customer_class_code IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
      -- �V�K�|�C���g�敪��'-'�̏ꍇ
      IF (cust_data_rec.new_point_div = cv_null_bar) THEN
        -- NULL���Z�b�g
        l_xxcmm_cust_accounts.new_point_div := NULL;
      -- �V�K�|�C���g�敪��NULL�̏ꍇ
      ELSIF (cust_data_rec.new_point_div IS NULL) THEN
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_cust_accounts.new_point_div := cust_data_rec.addon_new_point_div;
      ELSE
        -- CSV�̍��ڒl���Z�b�g
        l_xxcmm_cust_accounts.new_point_div := cust_data_rec.new_point_div;
      END IF;
    --
    ELSE
    --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�ȊO�̏ꍇ�A�ݒ�s��
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_cust_accounts.new_point_div := cust_data_rec.addon_new_point_div;
    --
    END IF;
--
    -- ===============================
    -- �V�K�|�C���g
    -- ===============================
    --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�̏ꍇ
    IF ( cust_data_rec.customer_class_code IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
      -- �V�K�|�C���g��'-'�̏ꍇ
      IF (cust_data_rec.new_point = cv_null_bar) THEN
        -- NULL���Z�b�g
        l_xxcmm_cust_accounts.new_point := NULL;
      -- �V�K�|�C���g��NULL�̏ꍇ
      ELSIF (cust_data_rec.new_point IS NULL) THEN
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_cust_accounts.new_point := cust_data_rec.addon_new_point;
      ELSE
        -- CSV�̍��ڒl���Z�b�g
        l_xxcmm_cust_accounts.new_point := TO_NUMBER(cust_data_rec.new_point, 999);
      END IF;
    --
    ELSE
    --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�ȊO�̏ꍇ�A�ݒ�s��
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_cust_accounts.new_point := cust_data_rec.addon_new_point;
    --
    END IF;
--
    -- ===============================
    -- �Љ�_�R�[�h
    -- ===============================
    --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�̏ꍇ
    IF ( cust_data_rec.customer_class_code IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
      -- �Љ�_�R�[�h��'-'�̏ꍇ
      IF (cust_data_rec.intro_base_code = cv_null_bar) THEN
        -- NULL���Z�b�g
        l_xxcmm_cust_accounts.intro_base_code := NULL;
      -- �Љ�_�R�[�h��NULL�̏ꍇ
      ELSIF (cust_data_rec.intro_base_code IS NULL) THEN
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_cust_accounts.intro_base_code := cust_data_rec.addon_intro_base_code;
      ELSE
        -- CSV�̍��ڒl���Z�b�g
        l_xxcmm_cust_accounts.intro_base_code := cust_data_rec.intro_base_code;
      END IF;
    ELSE
      --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�ȊO�̏ꍇ�A�ݒ�s��
      l_xxcmm_cust_accounts.intro_base_code := cust_data_rec.addon_intro_base_code;
    END IF;
--
    -- ===============================
    -- �Љ�c�ƈ�
    -- ===============================
    --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�̏ꍇ
    IF ( cust_data_rec.customer_class_code IN ( cv_kokyaku_kbn, cv_tenpo_kbn, cv_keikaku_kbn ) ) THEN
      -- �Љ�c�ƈ���'-'�̏ꍇ
      IF (cust_data_rec.intro_business_person = cv_null_bar) THEN
        -- NULL���Z�b�g
        l_xxcmm_cust_accounts.intro_business_person := NULL;
      -- �Љ�c�ƈ���NULL�̏ꍇ
      ELSIF (cust_data_rec.intro_business_person IS NULL) THEN
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_cust_accounts.intro_business_person := cust_data_rec.addon_intro_business_person;
      ELSE
        -- CSV�̍��ڒl���Z�b�g
        l_xxcmm_cust_accounts.intro_business_person := cust_data_rec.intro_business_person;
      END IF;
    ELSE
      --�ڋq�敪�u10�F�ڋq�v�u15�F�X�܉c�Ɓv�u17�F�v�旧�ėp�v�ȊO�̏ꍇ�A�ݒ�s��
      l_xxcmm_cust_accounts.intro_business_person := cust_data_rec.addon_intro_business_person;
    END IF;
--
    -- ===============================
    -- TDB�R�[�h
    -- ===============================
    --�ڋq�敪�u13�F�@�l�ڋq�v�̏ꍇ
    IF ( cust_data_rec.customer_class_code = cv_trust_corp ) THEN
      -- TDB�R�[�h��'-'�̏ꍇ
      IF (cust_data_rec.tdb_code = cv_null_bar) THEN
        -- NULL���Z�b�g
        l_xxcmm_mst_corporate.tdb_code := NULL;
      -- TDB�R�[�h��NULL�̏ꍇ
      ELSIF (cust_data_rec.tdb_code IS NULL) THEN
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_mst_corporate.tdb_code := cust_data_rec.addon_tdb_code;
      ELSE
        -- CSV�̍��ڒl���Z�b�g
        l_xxcmm_mst_corporate.tdb_code := cust_data_rec.tdb_code;
      END IF;
    ELSE
      --�ڋq�敪�u13�F�@�l�ڋq�v�ȊO�̏ꍇ�A�ݒ�s��
      l_xxcmm_mst_corporate.tdb_code := cust_data_rec.addon_tdb_code;
    END IF;
--
    -- ===============================
    -- ���ٓ��t
    -- ===============================
    --�ڋq�敪�u13�F�@�l�ڋq�v�̏ꍇ
    IF ( cust_data_rec.customer_class_code = cv_trust_corp ) THEN
      -- ���ٓ��t��'-'�̏ꍇ
      IF (cust_data_rec.corp_approval_date = cv_null_bar) THEN
        -- NULL���Z�b�g
        l_xxcmm_mst_corporate.approval_date := NULL;
      -- ���ٓ��t��NULL�̏ꍇ
      ELSIF (cust_data_rec.corp_approval_date IS NULL) THEN
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_mst_corporate.approval_date := cust_data_rec.addon_corp_approval_date;
      ELSE
        -- CSV�̍��ڒl���Z�b�g
        l_xxcmm_mst_corporate.approval_date := TO_DATE(cust_data_rec.corp_approval_date, cv_date_format);
      END IF;
    ELSE
      --�ڋq�敪�u13�F�@�l�ڋq�v�ȊO�̏ꍇ�A�ݒ�s��
      l_xxcmm_mst_corporate.approval_date := cust_data_rec.addon_corp_approval_date;
    END IF;
--
    -- ===============================
    -- �{���S�����_
    -- ===============================
    --�ڋq�敪�u13�F�@�l�ڋq�v�̏ꍇ
    IF ( cust_data_rec.customer_class_code = cv_trust_corp ) THEN
      -- �{���S�����_��NULL�̏ꍇ
      IF (cust_data_rec.base_code IS NULL) THEN
        -- �X�V�O�̒l���Z�b�g
        l_xxcmm_mst_corporate.base_code := cust_data_rec.addon_base_code;
      ELSE
        -- CSV�̍��ڒl���Z�b�g
        l_xxcmm_mst_corporate.base_code := cust_data_rec.base_code;
      END IF;
    ELSE
      --�ڋq�敪�u13�F�@�l�ڋq�v�ȊO�̏ꍇ�A�ݒ�s��
      l_xxcmm_mst_corporate.base_code := cust_data_rec.addon_base_code;
    END IF;
--
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
    --
    -- ===============================
    -- �ڋq�ǉ����}�X�^�X�V
    -- ===============================
    UPDATE xxcmm_cust_accounts xca
    SET    xca.stop_approval_reason   = l_xxcmm_cust_accounts.stop_approval_reason       --���~���R
          ,xca.stop_approval_date     = l_xxcmm_cust_accounts.stop_approval_date         --���~���ϓ�
          ,xca.sales_chain_code       = l_xxcmm_cust_accounts.sales_chain_code           --�`�F�[���X�R�[�h�i�̔���j
          ,xca.delivery_chain_code    = l_xxcmm_cust_accounts.delivery_chain_code        --�`�F�[���X�R�[�h�i�[�i��j
          ,xca.policy_chain_code      = l_xxcmm_cust_accounts.policy_chain_code          --�`�F�[���X�R�[�h�i�c�Ɛ����p�j
          ,xca.chain_store_code       = l_xxcmm_cust_accounts.chain_store_code           --�`�F�[���X�R�[�h�i�d�c�h�j
          ,xca.store_code             = l_xxcmm_cust_accounts.store_code                 --�X�܃R�[�h
          ,xca.business_low_type      = l_xxcmm_cust_accounts.business_low_type          --�Ƒԁi�����ށj
          ,xca.invoice_printing_unit  = l_xxcmm_cust_accounts.invoice_printing_unit      --����������P��
          ,xca.invoice_code           = l_xxcmm_cust_accounts.invoice_code               --�������p�R�[�h
          ,xca.industry_div           = l_xxcmm_cust_accounts.industry_div               --�Ǝ�
          ,xca.bill_base_code         = l_xxcmm_cust_accounts.bill_base_code             --�������_
          ,xca.receiv_base_code       = l_xxcmm_cust_accounts.receiv_base_code           --�������_
          ,xca.delivery_base_code     = l_xxcmm_cust_accounts.delivery_base_code         --�[�i���_
          ,xca.selling_transfer_div   = l_xxcmm_cust_accounts.selling_transfer_div       --������ѐU��
          ,xca.card_company           = l_xxcmm_cust_accounts.card_company               --�J�[�h���
          ,xca.wholesale_ctrl_code    = l_xxcmm_cust_accounts.wholesale_ctrl_code        --�≮�Ǘ��R�[�h
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add start by Yutaka.Kuboshima
          ,xca.past_customer_status   = l_xxcmm_cust_accounts.past_customer_status       --�O���ڋq�X�e�[�^�X
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add end by Yutaka.Kuboshima
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
          ,xca.ship_storage_code      = l_xxcmm_cust_accounts.ship_storage_code          --�o�׌��ۊǏꏊ
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add start by K.Kubo
          ,xca.delivery_order         = l_xxcmm_cust_accounts.delivery_order             --�z�����iEDI�j
          ,xca.edi_district_code      = l_xxcmm_cust_accounts.edi_district_code          --EDI�n��R�[�h�iEDI�j
          ,xca.edi_district_name      = l_xxcmm_cust_accounts.edi_district_name          --EDI�n�於�iEDI�j
          ,xca.edi_district_kana      = l_xxcmm_cust_accounts.edi_district_kana          --EDI�n�於�J�i�iEDI�j
          ,xca.tsukagatazaiko_div     = l_xxcmm_cust_accounts.tsukagatazaiko_div         --�ʉߍ݌Ɍ^�敪�iEDI�j
          ,xca.deli_center_code       = l_xxcmm_cust_accounts.deli_center_code           --EDI�[�i�Z���^�[�R�[�h
          ,xca.deli_center_name       = l_xxcmm_cust_accounts.deli_center_name           --EDI�[�i�Z���^�[��
          ,xca.edi_forward_number     = l_xxcmm_cust_accounts.edi_forward_number         --EDI�`���ǔ�
          ,xca.cust_store_name        = l_xxcmm_cust_accounts.cust_store_name            --�ڋq�X�ܖ���
          ,xca.torihikisaki_code      = l_xxcmm_cust_accounts.torihikisaki_code          --�����R�[�h
-- 2011/12/05 Ver1.7 E_�{�ғ�_07553 add end   by K.Kubo
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add start by S.Niki
          ,xca.vist_target_div        = l_xxcmm_cust_accounts.vist_target_div            --�K��Ώۋ敪
-- 2012/03/13 Ver1.8 E_�{�ғ�_09272 add end by S.Niki
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
          ,xca.intro_chain_code1      = l_xxcmm_cust_accounts.intro_chain_code1          --�Љ�҃`�F�[���R�[�h�P
          ,xca.intro_chain_code2      = l_xxcmm_cust_accounts.intro_chain_code2          --�Љ�҃`�F�[���R�[�h�Q
          ,xca.sales_head_base_code   = l_xxcmm_cust_accounts.sales_head_base_code       --�̔���{���S�����_
          ,xca.cnvs_base_code         = l_xxcmm_cust_accounts.cnvs_base_code             --�l�����_�R�[�h
          ,xca.cnvs_business_person   = l_xxcmm_cust_accounts.cnvs_business_person       --�l���c�ƈ�
          ,xca.new_point_div          = l_xxcmm_cust_accounts.new_point_div              --�V�K�|�C���g�敪
          ,xca.new_point              = l_xxcmm_cust_accounts.new_point                  --�V�K�|�C���g
          ,xca.intro_base_code        = l_xxcmm_cust_accounts.intro_base_code            --�Љ�_�R�[�h
          ,xca.intro_business_person  = l_xxcmm_cust_accounts.intro_business_person      --�Љ�c�ƈ�
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
          ,xca.last_updated_by        = cn_last_updated_by                               --�ŏI�X�V��
          ,xca.last_update_date       = cd_last_update_date                              --�ŏI�X�V��
          ,xca.request_id             = cn_request_id                                    --�v��ID
          ,xca.program_application_id = cn_program_application_id                        --�R���J�����g�E�v���O������A�v���P�[�V����ID
          ,xca.program_id             = cn_program_id                                    --�R���J�����g�E�v���O����ID
          ,xca.program_update_date    = cd_program_update_date                           --�v���O�����X�V��
    WHERE  xca.customer_id = cust_data_rec.customer_id
    ;
    -- �ϐ�������
    l_xxcmm_cust_accounts := NULL;
-- 2009/10/23 modify end by Yutaka.Kuboshima
    --
    -- ===============================
    -- �ڋq�@�l���X�V
    -- ===============================
    --�ڋq�敪��'13'�i�@�l�ڋq�i�^�M�Ǘ���j�j�̂Ƃ��̂݁A�ڋq�@�l���X�V
    IF (cust_data_rec.customer_class_code = cv_trust_corp) THEN
      UPDATE xxcmm_mst_corporate xmc
      SET    xmc.credit_limit           = DECODE(cust_data_rec.credit_limit,        --�^�M���x�z
                                                 NULL,
                                                 cust_data_rec.addon_credit_limit,
                                                 cust_data_rec.credit_limit),
             xmc.decide_div             = DECODE(cust_data_rec.decide_div,          --����敪
                                                 NULL,
                                                 cust_data_rec.addon_decide_div,
                                                 cust_data_rec.decide_div),
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add start by T.Nakano
             xmc.tdb_code               = l_xxcmm_mst_corporate.tdb_code,           --TDB�R�[�h
             xmc.approval_date          = l_xxcmm_mst_corporate.approval_date,      --���ٓ��t
             xmc.base_code              = l_xxcmm_mst_corporate.base_code,          --�{���S�����_
-- 2013/04/17 Ver1.9 E_�{�ғ�_09963�ǉ��Ή� add end by T.Nakano
             xmc.last_updated_by        = fnd_global.user_id,                       --�ŏI�X�V��
             xmc.last_update_date       = sysdate,                                  --�ŏI�X�V��
             xmc.request_id             = fnd_profile.value(cv_conc_request_id),    --�v��ID
             xmc.program_application_id = fnd_profile.value(cv_prog_appl_id),       --�R���J�����g�E�v���O������A�v���P�[�V����ID
             xmc.program_id             = fnd_profile.value(cv_conc_program_id),    --�R���J�����g�E�v���O����ID
             xmc.program_update_date    = sysdate                                   --�v���O�����X�V��
      WHERE  xmc.customer_id  = cust_data_rec.customer_id
      ;
    END IF;
--
  END LOOP cust_data_loop;
--
  EXCEPTION
    WHEN cust_rock_err_expt THEN                       --*** ���b�N�擾���s��O ***
      --���b�N�G���[�����b�Z�[�W�擾
      gv_out_msg    := xxccp_common_pkg.get_msg(
                          iv_application  => gv_xxcmm_msg_kbn
                         ,iv_name         => cv_rock_err_msg
                        );
      lv_errmsg     := gv_out_msg;
      lv_errbuf     := gv_out_msg;
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --���b�N�擾���s��O���A�Ώی����A�G���[�����͑S���Ƃ���
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
    WHEN update_cust_err_expt THEN                       --*** �ڋq�}�X�^�X�V�G���[ ***
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --�ڋq�}�X�^�X�V�G���[���A�Ώی����A�G���[�����͑S���Ƃ���
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
    WHEN update_party_err_expt THEN                      --*** �p�[�e�B�}�X�^�X�V�G���[ ***
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --�p�[�e�B�}�X�^�X�V�G���[���A�Ώی����A�G���[�����͑S���Ƃ���
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
    WHEN update_csu_err_expt THEN                        --*** �ڋq�g�p�ړI�}�X�^�X�V�G���[ ***
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --�ڋq�g�p�ړI�}�X�^�X�V�G���[���A�Ώی����A�G���[�����͑S���Ƃ���
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
    WHEN update_location_err_expt THEN                   --*** �ڋq���Ə��}�X�^�X�V�G���[ ***
      ov_errmsg     := lv_errmsg;
      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode    := cv_status_error;
      --�ڋq���Ə��}�X�^�X�V�G���[���A�Ώی����A�G���[�����͑S���Ƃ���
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
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
  END rock_and_update_cust;
--
  /**********************************************************************************
   * Procedure Name   : close_process
   * Description      : �I������(A-5)
   ***********************************************************************************/
  PROCEDURE close_process(
    in_file_id      IN  NUMBER,              --   �t�@�C��ID
    ov_errbuf       OUT VARCHAR2,            --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode      OUT VARCHAR2,            --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg       OUT VARCHAR2)            --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_process'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    DELETE xxcmm_wk_cust_batch_regist;
    DELETE xxccp_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id;
    COMMIT;
--
  EXCEPTION
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
  END close_process;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id                IN  NUMBER,       --�t�@�C��ID
    iv_format_pattern         IN  VARCHAR2,     --�t�@�C���t�H�[�}�b�g
    ov_errbuf                 OUT VARCHAR2,     --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,     --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2)     --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_real_errbuf   VARCHAR2(5000);  --A-3�EA-4���̃G���[�E���b�Z�[�W
    lv_real_retcode  VARCHAR2(1);     --A-3�EA-4���̃��^�[���E�R�[�h
    lv_real_errmsg   VARCHAR2(5000);  --A-3�EA-4���̃��[�U�[�E�G���[�E���b�Z�[�W
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
    --�p�����[�^�o��
    --�t�@�C��ID
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_file_id
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => TO_CHAR(in_file_id)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�t�@�C���^�C�v
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_file_content_type
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_format_pattern
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
-- 2009/10/23 Ver1.2 add start by Yutaka.Kuboshima
    -- �Ɩ����t�擾
    gd_process_date := xxccp_common_pkg2.get_process_date;
-- 2009/10/23 Ver1.2 add end by Yutaka.Kuboshima
--
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add start by Yutaka.Kuboshima
    -- ��v�J�����_�R�[�h�擾
    gv_gl_cal_code := fnd_profile.value(cv_profile_gl_cal);
    IF (gv_gl_cal_code IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  gv_xxcmm_msg_kbn,     -- �A�v���P�[�V�����Z�k��
                      iv_name           =>  cv_profile_err_msg,   -- �v���t�@�C���擾�G���[
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- �g�[�N��(NG_PROFILE)
                      iv_token_value1   =>  cv_gl_cal_name        -- �v���t�@�C����`��
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- �c�ƃV�X�e����v�����`���擾
    gv_ar_set_of_books := fnd_profile.value(cv_profile_ar_bks);
    IF (gv_ar_set_of_books IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  gv_xxcmm_msg_kbn,     -- �A�v���P�[�V�����Z�k��
                      iv_name           =>  cv_profile_err_msg,   -- �v���t�@�C���擾�G���[
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- �g�[�N��(NG_PROFILE)
                      iv_token_value1   =>  cv_set_of_books_name  -- �v���t�@�C����`��
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
-- 2010/01/04 Ver1.3 E_�{�ғ�_00778 add end by Yutaka.Kuboshima
--
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add start by Yutaka.Kuboshima
    --
    -- �݌ɑg�D�R�[�h�擾
    gv_organization_code := fnd_profile.value(cv_organization_code);
    IF (gv_organization_code IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  gv_xxcmm_msg_kbn,     -- �A�v���P�[�V�����Z�k��
                      iv_name           =>  cv_profile_err_msg,   -- �v���t�@�C���擾�G���[
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- �g�[�N��(NG_PROFILE)
                      iv_token_value1   =>  cv_profile_org_code   -- �v���t�@�C����`��
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- �ڋq�ꊇ�X�V�f�[�^���ڐ��擾
    gn_item_num := TO_NUMBER(fnd_profile.value(cv_csv_item_num));
    IF (gn_item_num IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  gv_xxcmm_msg_kbn,     -- �A�v���P�[�V�����Z�k��
                      iv_name           =>  cv_profile_err_msg,   -- �v���t�@�C���擾�G���[
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- �g�[�N��(NG_PROFILE)
                      iv_token_value1   =>  cv_csv_item_num_name  -- �v���t�@�C����`��
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- �E�ӊǗ��v���t�@�C���擾
    gv_management_resp := fnd_profile.value(cv_management_resp);
    IF (gv_management_resp IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  gv_xxcmm_msg_kbn,       -- �A�v���P�[�V�����Z�k��
                      iv_name           =>  cv_profile_err_msg,     -- �v���t�@�C���擾�G���[
                      iv_token_name1    =>  cv_tkn_ng_profile,      -- �g�[�N��(NG_PROFILE)
                      iv_token_value1   =>  cv_management_resp_name -- �v���t�@�C����`��
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- �E�ӊǗ��v���t�@�C���Ŏ擾�����l��'XXCMM_RESP_011'�ł��邩
    IF (gv_management_resp = cv_joho_kanri_resp) THEN
      -- �E�ӊǗ��t���O��'Y'�ɐݒ�
      gv_resp_flag := cv_yes;
    ELSE
      -- �E�ӊǗ��t���O��'N'�ɐݒ�
      gv_resp_flag := cv_no;
    END IF;
-- 2010/04/23 Ver1.6 E_�{�ғ�_02295 add end by Yutaka.Kuboshima
    --
    -- ===============================
    -- �t�@�C���A�b�v���[�hI/F�e�[�u���擾����(A-1)�E�ڋq�ꊇ�X�V�p���[�N�e�[�u���o�^����(A-2)
    -- ===============================
    cust_data_make_wk(
       in_file_id            -- �t�@�C��ID
      ,iv_format_pattern     -- �t�@�C���t�H�[�}�b�g
      ,lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    --�t�@�C���A�b�v���[�hI/F�e�[�u���擾�����G���[���A
    --���͌ڋq�ꊇ�X�V�p���[�N�e�[�u���o�^�����G���[���͏������X�L�b�v
    IF (lv_retcode = cv_status_error) THEN
      NULL;
    ELSE
      -- ===============================
      -- �e�[�u�����b�N����(A-3)�E�ڋq�ꊇ�X�V����(A-4)
      -- ===============================
      rock_and_update_cust(
         in_file_id              -- �t�@�C��ID
        ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      --�e�[�u�����b�N����(A-3)�E�ڋq�ꊇ�X�V����(A-4)�G���[���A���[���o�b�N
      IF (lv_retcode = cv_status_error) THEN
        --ROLLBACK
        ROLLBACK;
      END IF;
    END IF;
--
    lv_real_errbuf  := lv_errbuf;
    lv_real_retcode := lv_retcode;
    lv_real_errmsg  := lv_errmsg;
--
    -- ===============================
    -- �I������(A-5)
    -- ===============================
    --�X�e�[�^�X�Ɋւ�炸�A�A�b�v���[�h�e�[�u���ƃ��[�N�e�[�u���͍폜����
    close_process(
       in_file_id              -- �t�@�C��ID
      ,lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    --�t�@�C���A�b�v���[�hI/F�e�[�u���擾�����G���[���A
    --���͌ڋq�ꊇ�X�V�p���[�N�e�[�u���o�^�����G���[���A��������
    --�e�[�u�����b�N�����G���[���A
    --�ڋq�ꊇ�X�V�����G���[���ARAISE
    IF (lv_real_retcode = cv_status_error) THEN
      --�G���[����
      lv_errmsg := lv_real_errmsg;
      lv_errbuf := lv_real_errbuf;
      RAISE global_process_expt;
    END IF;
--
    --�I�����������G���[��
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
    errbuf                    OUT    VARCHAR2,  --�G���[���b�Z�[�W #�Œ�#
    retcode                   OUT    VARCHAR2,  --�G���[�R�[�h     #�Œ�#
    iv_file_id                IN     VARCHAR2,  --�t�@�C��ID
    iv_format_pattern         IN     VARCHAR2   --�t�@�C���t�H�[�}�b�g
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
       ov_retcode => lv_retcode
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
       TO_NUMBER(iv_file_id)     --�t�@�C��ID
      ,iv_format_pattern         --�t�@�C���t�H�[�}�b�g
      ,lv_errbuf                 --�G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                --���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                 --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
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
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
END XXCMM003A29C;
/
