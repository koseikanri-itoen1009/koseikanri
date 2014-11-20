CREATE OR REPLACE PACKAGE BODY APPS.XXCOS010A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS010A01C (body)
 * Description      : �󒍃f�[�^�捞�@�\
 * MD.050           : �󒍃f�[�^�捞(MD050_COS_010_A01)
 * Version          : 1.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_param_check       ���̓p�����[�^�Ó����`�F�b�N(A-1)
 *  proc_init              ��������(A-2)
 *  proc_get_edi_work      EDI�󒍏�񃏁[�N�e�[�u���f�[�^���o(A-3)
 *  proc_set_edi_errors    EDI�G���[���ϐ��i�[(A-5-1)
 *  proc_data_validate     �f�[�^�Ó����`�F�b�N(A-4)
 *  proc_set_edi_work      EDI�󒍏�񃏁[�N�ϐ��i�[(A-5)
 *  proc_set_edi_status    EDI�X�e�[�^�X�X�V�p�ϐ��i�[(A-6)
 *  proc_get_edi_headers   EDI�w�b�_���e�[�u���f�[�^���o(A-7)
 *  proc_set_ins_headers   EDI�w�b�_���C���T�[�g�p�ϐ��i�[(A-8)
 *  proc_set_upd_headers   EDI�w�b�_���A�b�v�f�[�g�p�ϐ��i�[(A-9)
 *  proc_get_edi_lines     EDI���׏��e�[�u���f�[�^���o(A-10)
 *  proc_set_ins_lines     EDI���׏��C���T�[�g�p�ϐ��i�[(A-11)
 *  proc_set_upd_lines     EDI���׏��A�b�v�f�[�g�p�ϐ��i�[(A-12)
 *  proc_calc_inv_total    �`�[���̍��v�l���Z�o(A-13)
 *  proc_set_inv_total     EDI�w�b�_���p�ϐ��ɓ`�[�v��ݒ�(A-14)
 *  proc_ins_edi_headers   EDI�w�b�_���e�[�u���f�[�^�ǉ�(A-15)
 *  proc_upd_edi_headers   EDI�w�b�_���e�[�u���f�[�^�X�V(A-16)
 *  proc_ins_edi_lines     EDI���׏��e�[�u���f�[�^�ǉ�(A-17)
 *  proc_upd_edi_lines     EDI���׏��e�[�u���f�[�^�X�V(A-18)
 *  proc_del_edi_errors    EDI�G���[���e�[�u���f�[�^�폜(A-19-1)
 *  proc_ins_edi_errors    EDI�G���[���e�[�u���f�[�^�ǉ�(A-19)
 *  proc_upd_edi_work      EDI�󒍏�񃏁[�N�e�[�u���X�e�[�^�X�X�V(A-20)
 *  proc_del_edi_work      EDI�󒍏�񃏁[�N�e�[�u���f�[�^�폜(A-21)
 *  proc_del_edi_head_line EDI�w�b�_���e�[�u���AEDI���׏��e�[�u���f�[�^�폜(A-22)
 *  proc_end               �I������(A-23)
 *  proc_loop_main         ���C�����[�v�v���V�[�W��
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01    1.0   M.Yamaki         �V�K�쐬
 *  2009/02/05    1.1   M.Yamaki         [COS_025]����f�[�^���������o�O�̑Ή�
 *                                       [COS_026]�ڋq�}�X�^�i�ڋq�敪:10�j�̌ڋq�X�e�[�^�X�ɑΉ�
 *                                       [COS_063]�ڋq�X�e�[�^�X�ɑΉ�
 *  2009/02/24    1.2   T.Nakamura       [COS_133]���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/02/26    1.3   M.Yamaki         [COS_140]���팏���A�x�������̑Ή�
 *  2009/05/08    1.4   T.Kitajima       [T1_0780]���i�\���ݒ胊�J�o���[�Ή�
 *  2009/05/19    1.5   T.Kitajima       [T1_0242]�i�ڎ擾���AOPM�i�ڃ}�X�^.�����i�����j�J�n�������ǉ�
 *                                       [T1_0243]�i�ڎ擾���A�q�i�ڑΏۊO�����ǉ�
 *  2009/06/29    1.6   M.Sano           [T1_0022],[T1_0023],[T1_0024],[T1_0042],[T1_0201]
 *                                       ���敪�ɂ��K�{�`�F�b�N�̎��s����A�u���C�N�L�[�ύX�Ή�
 *  2009/07/16    1.7   M.Sano           [0000345]�X�ܔ[�i���o�͕s���Ή�
 *  2009/07/22    1.8   M.Sano           [0000644]�[�������Ή�
 *                                       [0000436]PT�Ή�
 *  2009/07/24    1.8   N.Maeda          [0000644](�`�[�v)�������z�Ϗ㏈���ǉ�
 *  2009/08/06    1.8   M.Sano           [0000644]���r���[�w�E�Ή�
 *  2009/09/02    1.9   M.Sano           [0001067]PT�ǉ��Ή�
 *  2009/10/02    1.10  M.Sano           [0001156]�ڋq�i�ڒ��o�����ǉ�
 *  2009/11/19    1.11  M.Sano           [I_E_688]�u���C�N�L�[�Ƀ`�F�[���X�R�[�h��ǉ�
 *  2009/11/25    1.12  K.Atsushiba      [E_�{�ғ�_00098]�u���C�N�L�[�ɓX�ܔ[�i���ǉ��A�u���C�N������NULL�l��
 *                                       �ڋq�`�F�b�N��OTHERS��O�ǉ�
 *  2009/11/29    1.13  N.Maeda          [E_�{�ғ�_00185] �d���f�[�^�����������C��
 *  2009/12/28    1.14  M.Sano           [E_�{�ғ�_00738]
 *                                       �E�K�{�`�F�b�N�O�̃��R�[�h�쐬���̎󒍘A�g�σt���O�̃Z�b�g�l�ύX
 *                                       �E���ځu�ʉߍ݌Ɍ^�敪�v�̒ǉ�
 *  2010/01/19    1.15  M.Sano           [E_�{�ғ�_01154][E_�{�ғ�_01156][E_�{�ғ�_01159][E_�{�ғ�_01162][E_�{�ғ�_01551]
 *                                       �E���̓p�����[�^�u�`�F�[���X�R�[�h�v�ǉ�
 *                                       �EEDI�G���[���ɗ�̒ǉ��Ή�
 *                                        (�G���[���b�Z�[�W�R�[�h�EEDI�i�ږ��EEDI��M���E�G���[���X�g�o�͍σt���O)
 *                                       �EEDI�w�b�_���ɗ�̒ǉ��Ή� (EDI��M��)
 *                                       �E�Ó����`�F�b�N�̒ǉ��E�C���i�K�{�E�S���c�ƈ��E�󒍊֘A���הԍ�)
 *                                       �E�󒍃G���[���X�g�o�͗p�̕i�ڃG���[���b�Z�[�W�̕ύX
 *                                       �EEDI�G���[���̃p�[�W�����ǉ�
 *                                       �E���敪�u04�v���̓`�F�b�N���������{
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
  gn_warn_cnt      NUMBER;                    -- �x������
  gn_skip_cnt      NUMBER;                    -- �X�L�b�v����
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
  lock_expt                 EXCEPTION;       -- ���b�N�G���[
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCOS010A01C';              -- �p�b�P�[�W��
  --
  cv_application         CONSTANT VARCHAR2(5)   := 'XXCOS';                     -- �A�v���P�[�V������
  cv_application_coi     CONSTANT VARCHAR2(5)   := 'XXCOI';                     -- �A�h�I���F�̕��E�݌ɗ̈�
  -- �v���t�@�C��
  cv_prf_purge_term      CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_PURGE_TERM';     -- XXCOS:EDI���폜����
  cv_prf_case_uom        CONSTANT VARCHAR2(50)  := 'XXCOS1_CASE_UOM_CODE';      -- XXCOS:�P�[�X�P�ʃR�[�h
  cv_prf_organization_cd CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:�݌ɑg�D�R�[�h
  cv_prf_org_unit        CONSTANT VARCHAR2(50)  := 'ORG_ID';                    -- MO:�c�ƒP��
-- 2010/01/19 Ver.1.15 M.Sano add Start
  cv_prf_err_purge_term  CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_ERRMSG_PARGE_TERM';
                                                                                -- XXCOS:EDI�G���[���ێ�����
-- 2010/01/19 Ver.1.15 M.Sano add End
  -- �G���[�R�[�h
  cv_msg_param_required  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00006';          -- �K�{���̓p�����[�^���ݒ�G���[���b�Z�[�W
  cv_msg_param_invalid   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00019';          -- ���̓p�����[�^�s���G���[���b�Z�[�W
  cv_msg_profile         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';          -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_organization_id CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';          -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_mst_notfound    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10002';          -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_getdata         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';          -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_nodata          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';          -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_required        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00015';          -- �K�{�����̓G���[���b�Z�[�W
  cv_msg_cust_conv       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00020';          -- �ڋq�R�[�h�ϊ��G���[���b�Z�[�W
-- 2009/11/25 K.Atsushiba Ver.1.12 Add Start
  cv_msg_many_cust_conv  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00197';          -- �ڋq�R�[�h�ϊ��G���[���b�Z�[�W
-- 2009/11/25 K.Atsushiba Ver.1.12 Add End
  cv_msg_price_list      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00022';          -- ���i�\���ݒ�G���[���b�Z�[�W
  cv_msg_edi_item        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00023';          -- EDI�A�g�i�ڃR�[�h�敪�G���[���b�Z�[�W
  cv_msg_item_conv       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00024';          -- ���i�R�[�h�ϊ��G���[���b�Z�[�W
  cv_msg_price_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00123';          -- �P���擾�G���[���b�Z�[�W
-- 2010/01/19 Ver.1.15 M.Sano add Start
  cv_msg_salesrep_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11963';          -- �S���c�ƈ��擾�G���[���b�Z�[�W
  cv_msg_line_no_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11964';          -- �sNo�d���G���[���b�Z�[�W
-- 2010/01/19 Ver.1.15 M.Sano add End
  cv_msg_insert          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';          -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_update          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';          -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_delete          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00012';          -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_duplicate       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00025';          -- �d���o�^�G���[���b�Z�[�W
  cv_msg_lock            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';          -- ���b�N�G���[���b�Z�[�W
  cv_msg_targetcnt       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';          -- �Ώی������b�Z�[�W
  cv_msg_successcnt      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';          -- �����������b�Z�[�W
  cv_msg_errorcnt        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';          -- �G���[�������b�Z�[�W
  cv_msg_item_cnt        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00039';          -- ���i�R�[�h�G���[�������b�Z�[�W
  cv_msg_normal          CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';          -- ����I�����b�Z�[�W
  cv_msg_warning         CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';          -- �x���I�����b�Z�[�W
  cv_msg_error           CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';          -- �G���[�I���S���[���o�b�N���b�Z�[�W
  cv_msg_lookup_value    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00046';          -- �N�C�b�N�R�[�h
  cv_msg_org_unit        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';          -- MO:�c�ƒP��
  cv_msg_organization_cd CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00048';          -- XXCOI:�݌ɑg�D�R�[�h
  cv_msg_case_uom_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00057';          -- XXCOS:�P�[�X�P�ʃR�[�h
  cv_msg_edi_wk_tbl      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00113';          -- EDI�󒍏�񃏁[�N�e�[�u��
  cv_msg_head_tbl        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00114';          -- EDI�w�b�_���e�[�u��
  cv_msg_line_tbl        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00115';          -- EDI���׏��e�[�u��
  cv_msg_err_tbl         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00116';          -- EDI�G���[���e�[�u��
  cv_msg_param_info      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11951';          -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_edi_exe         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11952';          -- ���s�敪
  cv_msg_purge_term      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11953';          -- XXCOS:EDI���폜����
-- 2010/01/19 Ver.1.15 M.Sano add Start
  cv_msg_err_purge_term  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11962';          -- XXCOS:EDI�G���[���폜����
-- 2010/01/19 Ver.1.15 M.Sano add End
  cv_msg_shop_code       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11954';          -- �X�R�[�h
  cv_msg_line_no         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11955';          -- �s�ԍ�
  cv_msg_order_qty       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11956';          -- �������ʁi���v�A�o���j
  cv_msg_prod_type_jan   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11957';          -- JAN�R�[�h
  cv_msg_prod_type_cust  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11958';          -- �ڋq�i��
  cv_msg_item_err_type   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11959';          -- EDI�i�ڃG���[�^�C�v
  cv_msg_file_name       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11960';          -- �C���^�t�F�[�X�t�@�C����
  cv_msg_creation_class  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11961';          -- �쐬���敪
  cv_msg_rep_required    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00149';          -- �G���[���X�g�p�F�K�{���ږ����̓G���[
  cv_msg_rep_cust_conv   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00150';          -- �G���[���X�g�p�F�ڋq�R�[�h�ϊ��G���[
  cv_msg_rep_cust_stop   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00151';          -- �G���[���X�g�p�F�ڋq���~�\���G���[
  cv_msg_rep_price_list  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00152';          -- �G���[���X�g�p�F���i�\���ݒ�G���[
  cv_msg_rep_edi_item    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00153';          -- �G���[���X�g�p�FEDI�A�g�i�ڃR�[�h�敪�G���[
  cv_msg_rep_item_conv   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00154';          -- �G���[���X�g�p�F���i�R�[�h�ϊ��G���[
  cv_msg_rep_duplicate   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00155';          -- �G���[���X�g�p�F�d���o�^�G���[
  cv_msg_rep_price_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00156';          -- �G���[���X�g�p�F�P���擾�G���[
-- 2010/01/19 Ver.1.15 M.Sano add Start
  cv_msg_rep_salesrep    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00198';          -- �G���[���X�g�p�F�S���c�ƈ��擾�G���[
  cv_msg_rep_line_no     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00199';          -- �G���[���X�g�p�F�sNo�d���G���[
  cv_msg_rep_no_shop_cd  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00200';          -- �G���[���X�g�p�F�K�{����(�X�R�[�h)�����̓G���[
  cv_msg_rep_no_line_no  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00201';          -- �G���[���X�g�p�F�K�{����(�sNo)�����̓G���[
  cv_msg_rep_no_quantity CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00202';          -- �G���[���X�g�p�F�K�{����(�{��)�����̓G���[
  cv_msg_rep_cust_item   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00203';          -- �G���[���X�g�p�F�ڋq�i�ڕϊ��G���[
-- 2010/01/19 Ver.1.15 M.Sano add End
  -- �g�[�N��
  cv_tkn_in_param        CONSTANT VARCHAR2(20)  := 'IN_PARAM';                  -- ���̓p�����[�^
  cv_tkn_profile         CONSTANT VARCHAR2(20)  := 'PROFILE';                   -- �v���t�@�C��
  cv_tkn_org_code_tok    CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';              -- �݌ɑg�D�R�[�h
  cv_tkn_item            CONSTANT VARCHAR2(20)  := 'ITEM';                      -- �K�{���͍���
  cv_tkn_prod_code       CONSTANT VARCHAR2(20)  := 'PROD_CODE';                 -- ���i�R�[�h�Q
  cv_tkn_prod_type       CONSTANT VARCHAR2(20)  := 'PROD_TYPE';                 -- �ڋq�i�ڂ܂���JAN�R�[�h
  cv_tkn_chain_shop_code CONSTANT VARCHAR2(20)  := 'CHAIN_SHOP_CODE';           -- EDI�`�F�[���X�R�[�h
  cv_tkn_shop_code       CONSTANT VARCHAR2(20)  := 'SHOP_CODE';                 -- �X�R�[�h
  cv_tkn_order_no        CONSTANT VARCHAR2(20)  := 'ORDER_NO';                  -- �`�[�ԍ�
  cv_tkn_store_deliv_dt  CONSTANT VARCHAR2(20)  := 'STORE_DELIVERY_DATE';       -- �X�ܔ[�i��
  cv_tkn_line_no         CONSTANT VARCHAR2(20)  := 'LINE_NO';                   -- �s�ԍ�
  cv_tkn_table_name      CONSTANT VARCHAR2(20)  := 'TABLE_NAME';                -- �e�[�u����
  cv_tkn_key_data        CONSTANT VARCHAR2(20)  := 'KEY_DATA';                  -- �L�[���
  cv_tkn_table           CONSTANT VARCHAR2(20)  := 'TABLE';                     -- �e�[�u����
  cv_tkn_column          CONSTANT VARCHAR2(20)  := 'COLMUN';                    -- �J������
  cv_tkn_param1          CONSTANT VARCHAR2(20)  := 'PARAME1';                   -- �p�����[�^�P
  cv_tkn_param2          CONSTANT VARCHAR2(20)  := 'PARAME2';                   -- �p�����[�^�Q
-- 2010/01/19 Ver.1.15 M.Sano add Start
  cv_tkn_param3          CONSTANT VARCHAR2(20)  := 'PARAM3';                    -- �p�����[�^�R
  cv_tkn_new_line_no     CONSTANT VARCHAR2(20)  := 'NEW_LINE_NO';               -- �s�ԍ�(�̔Ԍ�)
  cv_tkn_cust_code       CONSTANT VARCHAR2(20)  := 'CUST_CODE';                 -- (�ϊ���)�ڋq�R�[�h
-- 2010/01/19 Ver.1.15 M.Sano add End
  -- �N�C�b�N�R�[�h�^�C�v
  cv_qck_edi_exe         CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_EXE_TYPE';       -- ���s�敪
  cv_qck_creation_class  CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_CREATE_CLASS';   -- EDI�쐬���敪
  cv_qck_edi_err_type    CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_ITEM_ERR_TYPE';  -- EDI�i�ڃG���[�^�C�v
-- 2009/12/28 M.Sano Ver.1.14 add Start
  cv_order_class         CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_ORDER_CLASS';    -- �󒍃f�[�^(�󒍔[�i�m��敪11,12,24)
-- 2009/12/28 M.Sano Ver.1.14 add End
  -- ���̑��萔
  cv_exe_type_new        CONSTANT VARCHAR2(10)  := '0';                         -- ���s�敪�F�V�K
  cv_exe_type_retry      CONSTANT VARCHAR2(10)  := '1';                         -- ���s�敪�F�Ď��{
  cv_edi_status_new      CONSTANT VARCHAR2(10)  := '0';                         -- EDI�X�e�[�^�X�F�V�K
  cv_edi_status_warning  CONSTANT VARCHAR2(10)  := '1';                         -- EDI�X�e�[�^�X�F�x��
  cv_edi_status_normal   CONSTANT VARCHAR2(10)  := '2';                         -- EDI�X�e�[�^�X�F����
  cv_edi_status_error    CONSTANT VARCHAR2(10)  := '9';                         -- EDI�X�e�[�^�X�F�G���[
  cv_data_type_code      CONSTANT VARCHAR2(10)  := '11';                        -- �f�[�^��R�[�h�FEDI��
  cv_creation_class      CONSTANT VARCHAR2(10)  := '10';                        -- �쐬���敪�F��
  cv_cust_class_base     CONSTANT VARCHAR2(10)  := '1';                         -- �ڋq�敪�i���_�j
  cv_cust_class_cust     CONSTANT VARCHAR2(10)  := '10';                        -- �ڋq�敪�i�ڋq�j
  cv_cust_class_chain    CONSTANT VARCHAR2(10)  := '18';                        -- �ڋq�敪�i�`�F�[���X�j
  cv_cust_site_use_code  CONSTANT VARCHAR2(10)  := 'SHIP_TO';                   -- �ڋq�g�p�ړI�F�o�א�
  cv_cust_status_30      CONSTANT VARCHAR2(10)  := '30';                        -- �ڋq�X�e�[�^�X�F30�i���F�ρj
  cv_cust_status_40      CONSTANT VARCHAR2(10)  := '40';                        -- �ڋq�X�e�[�^�X�F40�i�ڋq�j
  cv_cust_status_99      CONSTANT VARCHAR2(10)  := '99';                        -- �ڋq�X�e�[�^�X�F99�i�ΏۊO�j
  cv_item_code_div_jan   CONSTANT VARCHAR2(10)  := '2';                         -- EDI�A�g�i�ڃR�[�h�敪�FJAN�R�[�h
  cv_item_code_div_cust  CONSTANT VARCHAR2(10)  := '1';                         -- EDI�A�g�i�ڃR�[�h�敪�F�ڋq�i��
  cv_cust_order_flag     CONSTANT VARCHAR2(10)  := 'Y';                         -- �ڋq�󒍉\�t���O
  cv_sales_class         CONSTANT VARCHAR2(10)  := '1';                         -- ����Ώۋ敪����
  cv_error_item_type_1   CONSTANT VARCHAR2(10)  := '1';                         -- �i�ڃG���[�^�C�v�P
  cv_error_item_type_2   CONSTANT VARCHAR2(10)  := '2';                         -- �i�ڃG���[�^�C�v�Q
  cv_error_item_type_3   CONSTANT VARCHAR2(10)  := '3';                         -- �i�ڃG���[�^�C�v�R
  cv_error_delete_flag   CONSTANT VARCHAR2(10)  := 'Y';                         -- EDI�G���[�폜�t���O
  cv_cust_item_def_level CONSTANT VARCHAR2(10)  := '1';                         -- �ڋq�}�X�^�F��`���x��
  cv_order_forward_flag  CONSTANT VARCHAR2(10)  := 'N';                         -- �󒍘A�g�σt���O�F�f�t�H���g
-- 2009/12/28 M.Sano Ver.1.14 add Start
  cv_order_forward_no    CONSTANT VARCHAR2(10)  := 'S';                         -- �󒍘A�g�σt���O�F�A�g�ΏۊO
-- 2009/12/28 M.Sano Ver.1.14 add End
  cv_edi_delivery_flag   CONSTANT VARCHAR2(10)  := 'N';                         -- EDI�[�i�\�著�M�σt���O�F�f�t�H���g
  cv_hht_delivery_flag   CONSTANT VARCHAR2(10)  := 'N';                         -- HHT�[�i�\��A�g�σt���O�F�f�t�H���g
  cv_cust_status_active  CONSTANT VARCHAR2(10)  := 'A';                         -- �ڋq�}�X�^�X�e�[�^�X�FA�i�L���j
  cv_enabled             CONSTANT VARCHAR2(10)  := 'Y';                         -- �L���t���O
  cv_default_language    CONSTANT VARCHAR2(10)  := USERENV('LANG');             -- �W������^�C�v
--****************************** 2009/05/19 1.5 T.Kitajima ADD START  ******************************--
  cv_format_yyyymmdds    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                -- ���t�t�H�[�}�b�g
--****************************** 2009/05/19 1.5 T.Kitajima ADD  END  ******************************--
-- 2009/06/29 M.Sano Ver.1.6 add Start
  cv_info_class_01       CONSTANT VARCHAR2(10)  := '01';                        -- ���敪:01
  cv_info_class_02       CONSTANT VARCHAR2(10)  := '02';                        -- ���敪:02
-- 2010/01/19 Ver.1.15 M.Sano add Start
  cv_info_class_04       CONSTANT VARCHAR2(10)  := '04';                        -- ���敪:04
-- 2010/01/19 Ver.1.15 M.Sano add End
  cn_check_record_yes    CONSTANT NUMBER        := 1;                           -- �Ώۃ��R�[�h�̃`�F�b�N�F�L
  cn_check_record_no     CONSTANT NUMBER        := 0;                           -- �Ώۃ��R�[�h�̃`�F�b�N�F��
-- 2009/06/29 M.Sano Ver.1.6 mod End
-- 2009/10/02 Ver1.10 M.Sano Add Start
  cv_inactive_flag_no    CONSTANT VARCHAR2(1)   := 'N';                         -- �ڋq�i�ڥ���ݎQ��.�L���t���O�F�L��
-- 2009/10/02 Ver1.10 M.Sano Add End
-- 2010/01/19 Ver1.15 M.Sano Add Start
  cv_err_out_flag_new    CONSTANT VARCHAR2(2)   := 'N0';                        -- �G���[���X�g�o�͍σt���O�F���o��(�V�K)
  cv_err_out_flag_retry  CONSTANT VARCHAR2(2)   := 'N1';                        -- �G���[���X�g�o�͍σt���O�F���o��(�Ď��{)
  cv_err_out_flag_yes    CONSTANT VARCHAR2(2)   := 'Y';                         -- �G���[���X�g�o�͍σt���O�F�o�͍�
  cv_edi_create_class    CONSTANT VARCHAR2(2)   := '01';                        -- �G���[���X�g��ʁF��
  ct_order_date_def      CONSTANT DATE          := SYSDATE;                     -- �c�ƒS���`�F�b�N�p���tNULL���̃f�t�H���g�l
-- 2010/01/19 Ver1.15 M.Sano Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- EDI�󒍏�񃏁[�N�e�[�u���J�[�\��
  CURSOR edi_order_work_cur(
    iv_file_name       VARCHAR2,             -- �C���^�t�F�[�X�t�@�C����
    iv_data_type_code  VARCHAR2,             -- �f�[�^��R�[�h
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    iv_status          VARCHAR2              -- �X�e�[�^�X
    iv_status          VARCHAR2,             -- �X�e�[�^�X
    iv_edi_chain_code  VARCHAR2              -- EDI�`�F�[���X�R�[�h
-- 2010/01/19 Ver1.15 M.Sano Mod End
  )
  IS
    SELECT  edi.order_info_work_id           order_info_work_id,                -- �󒍏�񃏁[�NID
            edi.medium_class                 medium_class,                      -- �}�̋敪
            edi.data_type_code               data_type_code,                    -- �f�[�^��R�[�h
            edi.file_no                      file_no,                           -- �t�@�C���m��
            edi.info_class                   info_class,                        -- ���敪
            edi.process_date                 process_date,                      -- ������
            edi.process_time                 process_time,                      -- ��������
            edi.base_code                    base_code,                         -- ���_�i����j�R�[�h
            edi.base_name                    base_name,                         -- ���_���i�������j
            edi.base_name_alt                base_name_alt,                     -- ���_���i�J�i�j
            edi.edi_chain_code               edi_chain_code,                    -- �d�c�h�`�F�[���X�R�[�h
            edi.edi_chain_name               edi_chain_name,                    -- �d�c�h�`�F�[���X���i�����j
            edi.edi_chain_name_alt           edi_chain_name_alt,                -- �d�c�h�`�F�[���X���i�J�i�j
            edi.chain_code                   chain_code,                        -- �`�F�[���X�R�[�h
            edi.chain_name                   chain_name,                        -- �`�F�[���X���i�����j
            edi.chain_name_alt               chain_name_alt,                    -- �`�F�[���X���i�J�i�j
            edi.report_code                  report_code,                       -- ���[�R�[�h
            edi.report_show_name             report_show_name,                  -- ���[�\����
            edi.customer_code                customer_code,                     -- �ڋq�R�[�h
            edi.customer_name                customer_name,                     -- �ڋq���i�����j
            edi.customer_name_alt            customer_name_alt,                 -- �ڋq���i�J�i�j
            edi.company_code                 company_code,                      -- �ЃR�[�h
            edi.company_name                 company_name,                      -- �Ж��i�����j
            edi.company_name_alt             company_name_alt,                  -- �Ж��i�J�i�j
            edi.shop_code                    shop_code,                         -- �X�R�[�h
            edi.shop_name                    shop_name,                         -- �X���i�����j
            edi.shop_name_alt                shop_name_alt,                     -- �X���i�J�i�j
            edi.delivery_center_code         delivery_center_code,              -- �[���Z���^�[�R�[�h
            edi.delivery_center_name         delivery_center_name,              -- �[���Z���^�[���i�����j
            edi.delivery_center_name_alt     delivery_center_name_alt,          -- �[���Z���^�[���i�J�i�j
            edi.order_date                   order_date,                        -- ������
            edi.center_delivery_date         center_delivery_date,              -- �Z���^�[�[�i��
            edi.result_delivery_date         result_delivery_date,              -- ���[�i��
            edi.shop_delivery_date           shop_delivery_date,                -- �X�ܔ[�i��
            edi.data_creation_date_edi_data  data_creation_date_edi_data,       -- �f�[�^�쐬���i�d�c�h�f�[�^���j
            edi.data_creation_time_edi_data  data_creation_time_edi_data,       -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
            edi.invoice_class                invoice_class,                     -- �`�[�敪
            edi.small_classification_code    small_classification_code,         -- �����ރR�[�h
            edi.small_classification_name    small_classification_name,         -- �����ޖ�
            edi.middle_classification_code   middle_classification_code,        -- �����ރR�[�h
            edi.middle_classification_name   middle_classification_name,        -- �����ޖ�
            edi.big_classification_code      big_classification_code,           -- �啪�ރR�[�h
            edi.big_classification_name      big_classification_name,           -- �啪�ޖ�
            edi.other_party_department_code  other_party_department_code,       -- ����敔��R�[�h
            edi.other_party_order_number     other_party_order_number,          -- ����攭���ԍ�
            edi.check_digit_class            check_digit_class,                 -- �`�F�b�N�f�W�b�g�L���敪
            edi.invoice_number               invoice_number,                    -- �`�[�ԍ�
            edi.check_digit                  check_digit,                       -- �`�F�b�N�f�W�b�g
            edi.close_date                   close_date,                        -- ����
            edi.order_no_ebs                 order_no_ebs,                      -- �󒍂m���i�d�a�r�j
            edi.ar_sale_class                ar_sale_class,                     -- �����敪
            edi.delivery_classe              delivery_classe,                   -- �z���敪
            edi.opportunity_no               opportunity_no,                    -- �ւm��
            edi.contact_to                   contact_to,                        -- �A����
            edi.route_sales                  route_sales,                       -- ���[�g�Z�[���X
            edi.corporate_code               corporate_code,                    -- �@�l�R�[�h
            edi.maker_name                   maker_name,                        -- ���[�J�[��
            edi.area_code                    area_code,                         -- �n��R�[�h
            edi.area_name                    area_name,                         -- �n�於�i�����j
            edi.area_name_alt                area_name_alt,                     -- �n�於�i�J�i�j
            edi.vendor_code                  vendor_code,                       -- �����R�[�h
            edi.vendor_name                  vendor_name,                       -- ����於�i�����j
            edi.vendor_name1_alt             vendor_name1_alt,                  -- ����於�P�i�J�i�j
            edi.vendor_name2_alt             vendor_name2_alt,                  -- ����於�Q�i�J�i�j
            edi.vendor_tel                   vendor_tel,                        -- �����s�d�k
            edi.vendor_charge                vendor_charge,                     -- �����S����
            edi.vendor_address               vendor_address,                    -- �����Z���i�����j
            edi.deliver_to_code_itouen       deliver_to_code_itouen,            -- �͂���R�[�h�i�ɓ����j
            edi.deliver_to_code_chain        deliver_to_code_chain,             -- �͂���R�[�h�i�`�F�[���X�j
            edi.deliver_to                   deliver_to,                        -- �͂���i�����j
            edi.deliver_to1_alt              deliver_to1_alt,                   -- �͂���P�i�J�i�j
            edi.deliver_to2_alt              deliver_to2_alt,                   -- �͂���Q�i�J�i�j
            edi.deliver_to_address           deliver_to_address,                -- �͂���Z���i�����j
            edi.deliver_to_address_alt       deliver_to_address_alt,            -- �͂���Z���i�J�i�j
            edi.deliver_to_tel               deliver_to_tel,                    -- �͂���s�d�k
            edi.balance_accounts_code        balance_accounts_code,             -- ������R�[�h
            edi.balance_accounts_company_code balance_accounts_company_code,    -- ������ЃR�[�h
            edi.balance_accounts_shop_code   balance_accounts_shop_code,        -- ������X�R�[�h
            edi.balance_accounts_name        balance_accounts_name,             -- �����於�i�����j
            edi.balance_accounts_name_alt    balance_accounts_name_alt,         -- �����於�i�J�i�j
            edi.balance_accounts_address     balance_accounts_address,          -- ������Z���i�����j
            edi.balance_accounts_address_alt balance_accounts_address_alt,      -- ������Z���i�J�i�j
            edi.balance_accounts_tel         balance_accounts_tel,              -- ������s�d�k
            edi.order_possible_date          order_possible_date,               -- �󒍉\��
            edi.permission_possible_date     permission_possible_date,          -- ���e�\��
            edi.forward_month                forward_month,                     -- ����N����
            edi.payment_settlement_date      payment_settlement_date,           -- �x�����ϓ�
            edi.handbill_start_date_active   handbill_start_date_active,        -- �`���V�J�n��
            edi.billing_due_date             billing_due_date,                  -- ��������
            edi.shipping_time                shipping_time,                     -- �o�׎���
            edi.delivery_schedule_time       delivery_schedule_time,            -- �[�i�\�莞��
            edi.order_time                   order_time,                        -- ��������
            edi.general_date_item1           general_date_item1,                -- �ėp���t���ڂP
            edi.general_date_item2           general_date_item2,                -- �ėp���t���ڂQ
            edi.general_date_item3           general_date_item3,                -- �ėp���t���ڂR
            edi.general_date_item4           general_date_item4,                -- �ėp���t���ڂS
            edi.general_date_item5           general_date_item5,                -- �ėp���t���ڂT
            edi.arrival_shipping_class       arrival_shipping_class,            -- ���o�׋敪
            edi.vendor_class                 vendor_class,                      -- �����敪
            edi.invoice_detailed_class       invoice_detailed_class,            -- �`�[����敪
            edi.unit_price_use_class         unit_price_use_class,              -- �P���g�p�敪
            edi.sub_distribution_center_code sub_distribution_center_code,      -- �T�u�����Z���^�[�R�[�h
            edi.sub_distribution_center_name sub_distribution_center_name,      -- �T�u�����Z���^�[�R�[�h��
            edi.center_delivery_method       center_delivery_method,            -- �Z���^�[�[�i���@
            edi.center_use_class             center_use_class,                  -- �Z���^�[���p�敪
            edi.center_whse_class            center_whse_class,                 -- �Z���^�[�q�ɋ敪
            edi.center_area_class            center_area_class,                 -- �Z���^�[�n��敪
            edi.center_arrival_class         center_arrival_class,              -- �Z���^�[���׋敪
            edi.depot_class                  depot_class,                       -- �f�|�敪
            edi.tcdc_class                   tcdc_class,                        -- �s�b�c�b�敪
            edi.upc_flag                     upc_flag,                          -- �t�o�b�t���O
            edi.simultaneously_class         simultaneously_class,              -- ��ċ敪
            edi.business_id                  business_id,                       -- �Ɩ��h�c
            edi.whse_directly_class          whse_directly_class,               -- �q���敪
            edi.premium_rebate_class         premium_rebate_class,              -- �i�i���ߋ敪
            edi.item_type                    item_type,                         -- ���ڎ��
            edi.cloth_house_food_class       cloth_house_food_class,            -- �߉ƐH�敪
            edi.mix_class                    mix_class,                         -- ���݋敪
            edi.stk_class                    stk_class,                         -- �݌ɋ敪
            edi.last_modify_site_class       last_modify_site_class,            -- �ŏI�C���ꏊ�敪
            edi.report_class                 report_class,                      -- ���[�敪
            edi.addition_plan_class          addition_plan_class,               -- �ǉ��E�v��敪
            edi.registration_class           registration_class,                -- �o�^�敪
            edi.specific_class               specific_class,                    -- ����敪
            edi.dealings_class               dealings_class,                    -- ����敪
            edi.order_class                  order_class,                       -- �����敪
            edi.sum_line_class               sum_line_class,                    -- �W�v���׋敪
            edi.shipping_guidance_class      shipping_guidance_class,           -- �o�׈ē��ȊO�敪
            edi.shipping_class               shipping_class,                    -- �o�׋敪
            edi.product_code_use_class       product_code_use_class,            -- ���i�R�[�h�g�p�敪
            edi.cargo_item_class             cargo_item_class,                  -- �ϑ��i�敪
            edi.ta_class                     ta_class,                          -- �s�^�`�敪
            edi.plan_code                    plan_code,                         -- ���R�[�h
            edi.category_code                category_code,                     -- �J�e�S���[�R�[�h
            edi.category_class               category_class,                    -- �J�e�S���[�敪
            edi.carrier_means                carrier_means,                     -- �^����i
            edi.counter_code                 counter_code,                      -- ����R�[�h
            edi.move_sign                    move_sign,                         -- �ړ��T�C��
            edi.eos_handwriting_class        eos_handwriting_class,             -- �d�n�r�E�菑�敪
            edi.delivery_to_section_code     delivery_to_section_code,          -- �[�i��ۃR�[�h
            edi.invoice_detailed             invoice_detailed,                  -- �`�[����
            edi.attach_qty                   attach_qty,                        -- �Y�t��
            edi.other_party_floor            other_party_floor,                 -- �t���A
            edi.text_no                      text_no,                           -- �s�d�w�s�m��
            edi.in_store_code                in_store_code,                     -- �C���X�g�A�R�[�h
            edi.tag_data                     tag_data,                          -- �^�O
            edi.competition_code             competition_code,                  -- ����
            edi.billing_chair                billing_chair,                     -- ��������
            edi.chain_store_code             chain_store_code,                  -- �`�F�[���X�g�A�[�R�[�h
            edi.chain_store_short_name       chain_store_short_name,            -- �`�F�[���X�g�A�[�R�[�h��������
            edi.direct_delivery_rcpt_fee     direct_delivery_rcpt_fee,          -- ���z���^���旿
            edi.bill_info                    bill_info,                         -- ��`���
            edi.description                  description,                       -- �E�v
            edi.interior_code                interior_code,                     -- �����R�[�h
            edi.order_info_delivery_category order_info_delivery_category,      -- �������@�[�i�J�e�S���[
            edi.purchase_type                purchase_type,                     -- �d���`��
            edi.delivery_to_name_alt         delivery_to_name_alt,              -- �[�i�ꏊ���i�J�i�j
            edi.shop_opened_site             shop_opened_site,                  -- �X�o�ꏊ
            edi.counter_name                 counter_name,                      -- ���ꖼ
            edi.extension_number             extension_number,                  -- �����ԍ�
            edi.charge_name                  charge_name,                       -- �S���Җ�
            edi.price_tag                    price_tag,                         -- �l�D
            edi.tax_type                     tax_type,                          -- �Ŏ�
            edi.consumption_tax_class        consumption_tax_class,             -- ����ŋ敪
            edi.brand_class                  brand_class,                       -- �a�q
            edi.id_code                      id_code,                           -- �h�c�R�[�h
            edi.department_code              department_code,                   -- �S�ݓX�R�[�h
            edi.department_name              department_name,                   -- �S�ݓX��
            edi.item_type_number             item_type_number,                  -- �i�ʔԍ�
            edi.description_department       description_department,            -- �E�v�i�S�ݓX�j
            edi.price_tag_method             price_tag_method,                  -- �l�D���@
            edi.reason_column                reason_column,                     -- ���R��
            edi.a_column_header              a_column_header,                   -- �`���w�b�_
            edi.d_column_header              d_column_header,                   -- �c���w�b�_
            edi.brand_code                   brand_code,                        -- �u�����h�R�[�h
            edi.line_code                    line_code,                         -- ���C���R�[�h
            edi.class_code                   class_code,                        -- �N���X�R�[�h
            edi.a1_column                    a1_column,                         -- �`�|�P��
            edi.b1_column                    b1_column,                         -- �a�|�P��
            edi.c1_column                    c1_column,                         -- �b�|�P��
            edi.d1_column                    d1_column,                         -- �c�|�P��
            edi.e1_column                    e1_column,                         -- �d�|�P��
            edi.a2_column                    a2_column,                         -- �`�|�Q��
            edi.b2_column                    b2_column,                         -- �a�|�Q��
            edi.c2_column                    c2_column,                         -- �b�|�Q��
            edi.d2_column                    d2_column,                         -- �c�|�Q��
            edi.e2_column                    e2_column,                         -- �d�|�Q��
            edi.a3_column                    a3_column,                         -- �`�|�R��
            edi.b3_column                    b3_column,                         -- �a�|�R��
            edi.c3_column                    c3_column,                         -- �b�|�R��
            edi.d3_column                    d3_column,                         -- �c�|�R��
            edi.e3_column                    e3_column,                         -- �d�|�R��
            edi.f1_column                    f1_column,                         -- �e�|�P��
            edi.g1_column                    g1_column,                         -- �f�|�P��
            edi.h1_column                    h1_column,                         -- �g�|�P��
            edi.i1_column                    i1_column,                         -- �h�|�P��
            edi.j1_column                    j1_column,                         -- �i�|�P��
            edi.k1_column                    k1_column,                         -- �j�|�P��
            edi.l1_column                    l1_column,                         -- �k�|�P��
            edi.f2_column                    f2_column,                         -- �e�|�Q��
            edi.g2_column                    g2_column,                         -- �f�|�Q��
            edi.h2_column                    h2_column,                         -- �g�|�Q��
            edi.i2_column                    i2_column,                         -- �h�|�Q��
            edi.j2_column                    j2_column,                         -- �i�|�Q��
            edi.k2_column                    k2_column,                         -- �j�|�Q��
            edi.l2_column                    l2_column,                         -- �k�|�Q��
            edi.f3_column                    f3_column,                         -- �e�|�R��
            edi.g3_column                    g3_column,                         -- �f�|�R��
            edi.h3_column                    h3_column,                         -- �g�|�R��
            edi.i3_column                    i3_column,                         -- �h�|�R��
            edi.j3_column                    j3_column,                         -- �i�|�R��
            edi.k3_column                    k3_column,                         -- �j�|�R��
            edi.l3_column                    l3_column,                         -- �k�|�R��
            edi.chain_peculiar_area_header   chain_peculiar_area_header,        -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
            edi.order_connection_number      order_connection_number,           -- �󒍊֘A�ԍ�
            edi.line_no                      line_no,                           -- �s�m��
            edi.stockout_class               stockout_class,                    -- ���i�敪
            edi.stockout_reason              stockout_reason,                   -- ���i���R
            edi.product_code_itouen          product_code_itouen,               -- ���i�R�[�h�i�ɓ����j
            edi.product_code1                product_code1,                     -- ���i�R�[�h�P
            edi.product_code2                product_code2,                     -- ���i�R�[�h�Q
            edi.jan_code                     jan_code,                          -- �i�`�m�R�[�h
            edi.itf_code                     itf_code,                          -- �h�s�e�R�[�h
            edi.extension_itf_code           extension_itf_code,                -- �����h�s�e�R�[�h
            edi.case_product_code            case_product_code,                 -- �P�[�X���i�R�[�h
            edi.ball_product_code            ball_product_code,                 -- �{�[�����i�R�[�h
            edi.product_code_item_type       product_code_item_type,            -- ���i�R�[�h�i��
            edi.prod_class                   prod_class,                        -- ���i�敪
            edi.product_name                 product_name,                      -- ���i���i�����j
            edi.product_name1_alt            product_name1_alt,                 -- ���i���P�i�J�i�j
            edi.product_name2_alt            product_name2_alt,                 -- ���i���Q�i�J�i�j
            edi.item_standard1               item_standard1,                    -- �K�i�P
            edi.item_standard2               item_standard2,                    -- �K�i�Q
            edi.qty_in_case                  qty_in_case,                       -- ����
            edi.num_of_cases                 num_of_cases,                      -- �P�[�X����
            edi.num_of_ball                  num_of_ball,                       -- �{�[������
            edi.item_color                   item_color,                        -- �F
            edi.item_size                    item_size,                         -- �T�C�Y
            edi.expiration_date              expiration_date,                   -- �ܖ�������
            edi.product_date                 product_date,                      -- ������
            edi.order_uom_qty                order_uom_qty,                     -- �����P�ʐ�
            edi.shipping_uom_qty             shipping_uom_qty,                  -- �o�גP�ʐ�
            edi.packing_uom_qty              packing_uom_qty,                   -- ����P�ʐ�
            edi.deal_code                    deal_code,                         -- ����
            edi.deal_class                   deal_class,                        -- �����敪
            edi.collation_code               collation_code,                    -- �ƍ�
            edi.uom_code                     uom_code,                          -- �P��
            edi.unit_price_class             unit_price_class,                  -- �P���敪
            edi.parent_packing_number        parent_packing_number,             -- �e����ԍ�
            edi.packing_number               packing_number,                    -- ����ԍ�
            edi.product_group_code           product_group_code,                -- ���i�Q�R�[�h
            edi.case_dismantle_flag          case_dismantle_flag,               -- �P�[�X��̕s�t���O
            edi.case_class                   case_class,                        -- �P�[�X�敪
            edi.indv_order_qty               indv_order_qty,                    -- �������ʁi�o���j
            edi.case_order_qty               case_order_qty,                    -- �������ʁi�P�[�X�j
            edi.ball_order_qty               ball_order_qty,                    -- �������ʁi�{�[���j
            edi.sum_order_qty                sum_order_qty,                     -- �������ʁi���v�A�o���j
            edi.indv_shipping_qty            indv_shipping_qty,                 -- �o�א��ʁi�o���j
            edi.case_shipping_qty            case_shipping_qty,                 -- �o�א��ʁi�P�[�X�j
            edi.ball_shipping_qty            ball_shipping_qty,                 -- �o�א��ʁi�{�[���j
            edi.pallet_shipping_qty          pallet_shipping_qty,               -- �o�א��ʁi�p���b�g�j
            edi.sum_shipping_qty             sum_shipping_qty,                  -- �o�א��ʁi���v�A�o���j
            edi.indv_stockout_qty            indv_stockout_qty,                 -- ���i���ʁi�o���j
            edi.case_stockout_qty            case_stockout_qty,                 -- ���i���ʁi�P�[�X�j
            edi.ball_stockout_qty            ball_stockout_qty,                 -- ���i���ʁi�{�[���j
            edi.sum_stockout_qty             sum_stockout_qty,                  -- ���i���ʁi���v�A�o���j
            edi.case_qty                     case_qty,                          -- �P�[�X����
            edi.fold_container_indv_qty      fold_container_indv_qty,           -- �I���R���i�o���j����
            edi.order_unit_price             order_unit_price,                  -- ���P���i�����j
            edi.shipping_unit_price          shipping_unit_price,               -- ���P���i�o�ׁj
            edi.order_cost_amt               order_cost_amt,                    -- �������z�i�����j
-- 2009/07/22 Ver.1.8 M.Sano Mod Start
--            edi.shipping_cost_amt            shipping_cost_amt,                 -- �������z�i�o�ׁj
--            edi.stockout_cost_amt            stockout_cost_amt,                 -- �������z�i���i�j
            TRUNC(edi.shipping_cost_amt)     shipping_cost_amt,                 -- �������z�i�o�ׁj
            TRUNC(edi.stockout_cost_amt)     stockout_cost_amt,                 -- �������z�i���i�j
-- 2009/07/22 Ver.1.8 M.Sano Mod End
            edi.selling_price                selling_price,                     -- ���P��
            edi.order_price_amt              order_price_amt,                   -- �������z�i�����j
            edi.shipping_price_amt           shipping_price_amt,                -- �������z�i�o�ׁj
            edi.stockout_price_amt           stockout_price_amt,                -- �������z�i���i�j
            edi.a_column_department          a_column_department,               -- �`���i�S�ݓX�j
            edi.d_column_department          d_column_department,               -- �c���i�S�ݓX�j
            edi.standard_info_depth          standard_info_depth,               -- �K�i���E���s��
            edi.standard_info_height         standard_info_height,              -- �K�i���E����
            edi.standard_info_width          standard_info_width,               -- �K�i���E��
            edi.standard_info_weight         standard_info_weight,              -- �K�i���E�d��
            edi.general_succeeded_item1      general_succeeded_item1,           -- �ėp���p�����ڂP
            edi.general_succeeded_item2      general_succeeded_item2,           -- �ėp���p�����ڂQ
            edi.general_succeeded_item3      general_succeeded_item3,           -- �ėp���p�����ڂR
            edi.general_succeeded_item4      general_succeeded_item4,           -- �ėp���p�����ڂS
            edi.general_succeeded_item5      general_succeeded_item5,           -- �ėp���p�����ڂT
            edi.general_succeeded_item6      general_succeeded_item6,           -- �ėp���p�����ڂU
            edi.general_succeeded_item7      general_succeeded_item7,           -- �ėp���p�����ڂV
            edi.general_succeeded_item8      general_succeeded_item8,           -- �ėp���p�����ڂW
            edi.general_succeeded_item9      general_succeeded_item9,           -- �ėp���p�����ڂX
            edi.general_succeeded_item10     general_succeeded_item10,          -- �ėp���p�����ڂP�O
            edi.general_add_item1            general_add_item1,                 -- �ėp�t�����ڂP
            edi.general_add_item2            general_add_item2,                 -- �ėp�t�����ڂQ
            edi.general_add_item3            general_add_item3,                 -- �ėp�t�����ڂR
            edi.general_add_item4            general_add_item4,                 -- �ėp�t�����ڂS
            edi.general_add_item5            general_add_item5,                 -- �ėp�t�����ڂT
            edi.general_add_item6            general_add_item6,                 -- �ėp�t�����ڂU
            edi.general_add_item7            general_add_item7,                 -- �ėp�t�����ڂV
            edi.general_add_item8            general_add_item8,                 -- �ėp�t�����ڂW
            edi.general_add_item9            general_add_item9,                 -- �ėp�t�����ڂX
            edi.general_add_item10           general_add_item10,                -- �ėp�t�����ڂP�O
            edi.chain_peculiar_area_line     chain_peculiar_area_line,          -- �`�F�[���X�ŗL�G���A�i���ׁj
            edi.invoice_indv_order_qty       invoice_indv_order_qty,            -- �i�`�[�v�j�������ʁi�o���j
            edi.invoice_case_order_qty       invoice_case_order_qty,            -- �i�`�[�v�j�������ʁi�P�[�X�j
            edi.invoice_ball_order_qty       invoice_ball_order_qty,            -- �i�`�[�v�j�������ʁi�{�[���j
            edi.invoice_sum_order_qty        invoice_sum_order_qty,             -- �i�`�[�v�j�������ʁi���v�A�o���j
            edi.invoice_indv_shipping_qty    invoice_indv_shipping_qty,         -- �i�`�[�v�j�o�א��ʁi�o���j
            edi.invoice_case_shipping_qty    invoice_case_shipping_qty,         -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
            edi.invoice_ball_shipping_qty    invoice_ball_shipping_qty,         -- �i�`�[�v�j�o�א��ʁi�{�[���j
            edi.invoice_pallet_shipping_qty  invoice_pallet_shipping_qty,       -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
            edi.invoice_sum_shipping_qty     invoice_sum_shipping_qty,          -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
            edi.invoice_indv_stockout_qty    invoice_indv_stockout_qty,         -- �i�`�[�v�j���i���ʁi�o���j
            edi.invoice_case_stockout_qty    invoice_case_stockout_qty,         -- �i�`�[�v�j���i���ʁi�P�[�X�j
            edi.invoice_ball_stockout_qty    invoice_ball_stockout_qty,         -- �i�`�[�v�j���i���ʁi�{�[���j
            edi.invoice_sum_stockout_qty     invoice_sum_stockout_qty,          -- �i�`�[�v�j���i���ʁi���v�A�o���j
            edi.invoice_case_qty             invoice_case_qty,                  -- �i�`�[�v�j�P�[�X����
            edi.invoice_fold_container_qty   invoice_fold_container_qty,        -- �i�`�[�v�j�I���R���i�o���j����
            edi.invoice_order_cost_amt       invoice_order_cost_amt,            -- �i�`�[�v�j�������z�i�����j
            edi.invoice_shipping_cost_amt    invoice_shipping_cost_amt,         -- �i�`�[�v�j�������z�i�o�ׁj
            edi.invoice_stockout_cost_amt    invoice_stockout_cost_amt,         -- �i�`�[�v�j�������z�i���i�j
            edi.invoice_order_price_amt      invoice_order_price_amt,           -- �i�`�[�v�j�������z�i�����j
            edi.invoice_shipping_price_amt   invoice_shipping_price_amt,        -- �i�`�[�v�j�������z�i�o�ׁj
            edi.invoice_stockout_price_amt   invoice_stockout_price_amt,        -- �i�`�[�v�j�������z�i���i�j
            edi.total_indv_order_qty         total_indv_order_qty,              -- �i�����v�j�������ʁi�o���j
            edi.total_case_order_qty         total_case_order_qty,              -- �i�����v�j�������ʁi�P�[�X�j
            edi.total_ball_order_qty         total_ball_order_qty,              -- �i�����v�j�������ʁi�{�[���j
            edi.total_sum_order_qty          total_sum_order_qty,               -- �i�����v�j�������ʁi���v�A�o���j
            edi.total_indv_shipping_qty      total_indv_shipping_qty,           -- �i�����v�j�o�א��ʁi�o���j
            edi.total_case_shipping_qty      total_case_shipping_qty,           -- �i�����v�j�o�א��ʁi�P�[�X�j
            edi.total_ball_shipping_qty      total_ball_shipping_qty,           -- �i�����v�j�o�א��ʁi�{�[���j
            edi.total_pallet_shipping_qty    total_pallet_shipping_qty,         -- �i�����v�j�o�א��ʁi�p���b�g�j
            edi.total_sum_shipping_qty       total_sum_shipping_qty,            -- �i�����v�j�o�א��ʁi���v�A�o���j
            edi.total_indv_stockout_qty      total_indv_stockout_qty,           -- �i�����v�j���i���ʁi�o���j
            edi.total_case_stockout_qty      total_case_stockout_qty,           -- �i�����v�j���i���ʁi�P�[�X�j
            edi.total_ball_stockout_qty      total_ball_stockout_qty,           -- �i�����v�j���i���ʁi�{�[���j
            edi.total_sum_stockout_qty       total_sum_stockout_qty,            -- �i�����v�j���i���ʁi���v�A�o���j
            edi.total_case_qty               total_case_qty,                    -- �i�����v�j�P�[�X����
            edi.total_fold_container_qty     total_fold_container_qty,          -- �i�����v�j�I���R���i�o���j����
            edi.total_order_cost_amt         total_order_cost_amt,              -- �i�����v�j�������z�i�����j
            edi.total_shipping_cost_amt      total_shipping_cost_amt,           -- �i�����v�j�������z�i�o�ׁj
            edi.total_stockout_cost_amt      total_stockout_cost_amt,           -- �i�����v�j�������z�i���i�j
            edi.total_order_price_amt        total_order_price_amt,             -- �i�����v�j�������z�i�����j
            edi.total_shipping_price_amt     total_shipping_price_amt,          -- �i�����v�j�������z�i�o�ׁj
            edi.total_stockout_price_amt     total_stockout_price_amt,          -- �i�����v�j�������z�i���i�j
            edi.total_line_qty               total_line_qty,                    -- �g�[�^���s��
            edi.total_invoice_qty            total_invoice_qty,                 -- �g�[�^���`�[����
            edi.chain_peculiar_area_footer   chain_peculiar_area_footer,        -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--            edi.err_status                   err_status                         -- �X�e�[�^�X
            edi.err_status                   err_status,                        -- �X�e�[�^�X
            edi.creation_date                creation_date                      -- �쐬��
-- 2010/01/19 Ver1.15 M.Sano Mod End
    FROM    xxcos_edi_order_work             edi
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    WHERE   edi.if_file_name                 = iv_file_name                     -- �C���^�t�F�[�X�t�@�C����
    WHERE (   iv_file_name IS NULL
           OR edi.if_file_name               = iv_file_name )                   -- �C���^�t�F�[�X�t�@�C����
    AND   (   iv_edi_chain_code IS NULL
           OR edi.edi_chain_code             = iv_edi_chain_code )              -- EDI�`�F�[���X�R�[�h
-- 2010/01/19 Ver1.15 M.Sano Mod End
    AND     edi.data_type_code               = iv_data_type_code                -- �f�[�^��R�[�h
    AND     edi.err_status                   = iv_status                        -- �X�e�[�^�X
    ORDER BY
-- 2009/11/25 K.Atsushiba Ver.1.12 Add Start
            shop_delivery_date,
-- 2009/11/25 K.Atsushiba Ver.1.12 Add Start
-- 2009/11/19 M.Sano Ver.1.11 add Start
            edi_chain_code,
-- 2009/11/19 M.Sano Ver.1.11 add End
-- 2009/06/29 M.Sano Ver.1.6 add Start
            shop_code,
-- 2009/06/29 M.Sano Ver.1.6 add End
            invoice_number,
            line_no
    FOR UPDATE NOWAIT;
--
  -- �`�[�ʔ������ʍ��v ���R�[�h�^�C�v��`
  TYPE g_inv_total_rtype IS RECORD
    (
      indv_order_qty                         NUMBER,                            -- �������ʁi�o���j
      case_order_qty                         NUMBER,                            -- �������ʁi�P�[�X�j
      ball_order_qty                         NUMBER,                            -- �������ʁi�{�[���j
      sum_order_qty                          NUMBER,                            -- �������ʁi���v�A�o���j
      order_cost_amt                         NUMBER,                            -- �������z(����)
-- *************************** 2009/07/24 1.8 N.Maeda ADD START ********************************** --
      shipping_cost_amt                      NUMBER,                            -- �������z�i�o�ׁj
      stockout_cost_amt                      NUMBER                             -- �������z�i���i�j
-- *************************** 2009/07/24 1.8 N.Maeda ADD  END  ********************************** --
    );
--
  -- EDI�󒍏�񃏁[�N�e�[�u�� ���R�[�h�^�C�v��`
  TYPE g_edi_work_rtype IS RECORD
    (
      order_info_work_id                     xxcos_edi_order_work.order_info_work_id%TYPE,               -- �󒍏�񃏁[�NID
      medium_class                           xxcos_edi_order_work.medium_class%TYPE,                     -- �}�̋敪
      data_type_code                         xxcos_edi_order_work.data_type_code%TYPE,                   -- �f�[�^��R�[�h
      file_no                                xxcos_edi_order_work.file_no%TYPE,                          -- �t�@�C���m��
      info_class                             xxcos_edi_order_work.info_class%TYPE,                       -- ���敪
      process_date                           xxcos_edi_order_work.process_date%TYPE,                     -- ������
      process_time                           xxcos_edi_order_work.process_time%TYPE,                     -- ��������
      base_code                              xxcos_edi_order_work.base_code%TYPE,                        -- ���_�i����j�R�[�h
      base_name                              xxcos_edi_order_work.base_name%TYPE,                        -- ���_���i�������j
      base_name_alt                          xxcos_edi_order_work.base_name_alt%TYPE,                    -- ���_���i�J�i�j
      edi_chain_code                         xxcos_edi_order_work.edi_chain_code%TYPE,                   -- �d�c�h�`�F�[���X�R�[�h
      edi_chain_name                         xxcos_edi_order_work.edi_chain_name%TYPE,                   -- �d�c�h�`�F�[���X���i�����j
      edi_chain_name_alt                     xxcos_edi_order_work.edi_chain_name_alt%TYPE,               -- �d�c�h�`�F�[���X���i�J�i�j
      chain_code                             xxcos_edi_order_work.chain_code%TYPE,                       -- �`�F�[���X�R�[�h
      chain_name                             xxcos_edi_order_work.chain_name%TYPE,                       -- �`�F�[���X���i�����j
      chain_name_alt                         xxcos_edi_order_work.chain_name_alt%TYPE,                   -- �`�F�[���X���i�J�i�j
      report_code                            xxcos_edi_order_work.report_code%TYPE,                      -- ���[�R�[�h
      report_show_name                       xxcos_edi_order_work.report_show_name%TYPE,                 -- ���[�\����
      customer_code                          xxcos_edi_order_work.customer_code%TYPE,                    -- �ڋq�R�[�h
      customer_name                          xxcos_edi_order_work.customer_name%TYPE,                    -- �ڋq���i�����j
      customer_name_alt                      xxcos_edi_order_work.customer_name_alt%TYPE,                -- �ڋq���i�J�i�j
      company_code                           xxcos_edi_order_work.company_code%TYPE,                     -- �ЃR�[�h
      company_name                           xxcos_edi_order_work.company_name%TYPE,                     -- �Ж��i�����j
      company_name_alt                       xxcos_edi_order_work.company_name_alt%TYPE,                 -- �Ж��i�J�i�j
      shop_code                              xxcos_edi_order_work.shop_code%TYPE,                        -- �X�R�[�h
      shop_name                              xxcos_edi_order_work.shop_name%TYPE,                        -- �X���i�����j
      shop_name_alt                          xxcos_edi_order_work.shop_name_alt%TYPE,                    -- �X���i�J�i�j
      delivery_center_code                   xxcos_edi_order_work.delivery_center_code%TYPE,             -- �[���Z���^�[�R�[�h
      delivery_center_name                   xxcos_edi_order_work.delivery_center_name%TYPE,             -- �[���Z���^�[���i�����j
      delivery_center_name_alt               xxcos_edi_order_work.delivery_center_name_alt%TYPE,         -- �[���Z���^�[���i�J�i�j
      order_date                             xxcos_edi_order_work.order_date%TYPE,                       -- ������
      center_delivery_date                   xxcos_edi_order_work.center_delivery_date%TYPE,             -- �Z���^�[�[�i��
      result_delivery_date                   xxcos_edi_order_work.result_delivery_date%TYPE,             -- ���[�i��
      shop_delivery_date                     xxcos_edi_order_work.shop_delivery_date%TYPE,               -- �X�ܔ[�i��
      data_creation_date_edi_data            xxcos_edi_order_work.data_creation_date_edi_data%TYPE,      -- �f�[�^�쐬���i�d�c�h�f�[�^���j
      data_creation_time_edi_data            xxcos_edi_order_work.data_creation_time_edi_data%TYPE,      -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
      invoice_class                          xxcos_edi_order_work.invoice_class%TYPE,                    -- �`�[�敪
      small_classification_code              xxcos_edi_order_work.small_classification_code%TYPE,        -- �����ރR�[�h
      small_classification_name              xxcos_edi_order_work.small_classification_name%TYPE,        -- �����ޖ�
      middle_classification_code             xxcos_edi_order_work.middle_classification_code%TYPE,       -- �����ރR�[�h
      middle_classification_name             xxcos_edi_order_work.middle_classification_name%TYPE,       -- �����ޖ�
      big_classification_code                xxcos_edi_order_work.big_classification_code%TYPE,          -- �啪�ރR�[�h
      big_classification_name                xxcos_edi_order_work.big_classification_name%TYPE,          -- �啪�ޖ�
      other_party_department_code            xxcos_edi_order_work.other_party_department_code%TYPE,      -- ����敔��R�[�h
      other_party_order_number               xxcos_edi_order_work.other_party_order_number%TYPE,         -- ����攭���ԍ�
      check_digit_class                      xxcos_edi_order_work.check_digit_class%TYPE,                -- �`�F�b�N�f�W�b�g�L���敪
      invoice_number                         xxcos_edi_order_work.invoice_number%TYPE,                   -- �`�[�ԍ�
      check_digit                            xxcos_edi_order_work.check_digit%TYPE,                      -- �`�F�b�N�f�W�b�g
      close_date                             xxcos_edi_order_work.close_date%TYPE,                       -- ����
      order_no_ebs                           xxcos_edi_order_work.order_no_ebs%TYPE,                     -- �󒍂m���i�d�a�r�j
      ar_sale_class                          xxcos_edi_order_work.ar_sale_class%TYPE,                    -- �����敪
      delivery_classe                        xxcos_edi_order_work.delivery_classe%TYPE,                  -- �z���敪
      opportunity_no                         xxcos_edi_order_work.opportunity_no%TYPE,                   -- �ւm��
      contact_to                             xxcos_edi_order_work.contact_to%TYPE,                       -- �A����
      route_sales                            xxcos_edi_order_work.route_sales%TYPE,                      -- ���[�g�Z�[���X
      corporate_code                         xxcos_edi_order_work.corporate_code%TYPE,                   -- �@�l�R�[�h
      maker_name                             xxcos_edi_order_work.maker_name%TYPE,                       -- ���[�J�[��
      area_code                              xxcos_edi_order_work.area_code%TYPE,                        -- �n��R�[�h
      area_name                              xxcos_edi_order_work.area_name%TYPE,                        -- �n�於�i�����j
      area_name_alt                          xxcos_edi_order_work.area_name_alt%TYPE,                    -- �n�於�i�J�i�j
      vendor_code                            xxcos_edi_order_work.vendor_code%TYPE,                      -- �����R�[�h
      vendor_name                            xxcos_edi_order_work.vendor_name%TYPE,                      -- ����於�i�����j
      vendor_name1_alt                       xxcos_edi_order_work.vendor_name1_alt%TYPE,                 -- ����於�P�i�J�i�j
      vendor_name2_alt                       xxcos_edi_order_work.vendor_name2_alt%TYPE,                 -- ����於�Q�i�J�i�j
      vendor_tel                             xxcos_edi_order_work.vendor_tel%TYPE,                       -- �����s�d�k
      vendor_charge                          xxcos_edi_order_work.vendor_charge%TYPE,                    -- �����S����
      vendor_address                         xxcos_edi_order_work.vendor_address%TYPE,                   -- �����Z���i�����j
      deliver_to_code_itouen                 xxcos_edi_order_work.deliver_to_code_itouen%TYPE,           -- �͂���R�[�h�i�ɓ����j
      deliver_to_code_chain                  xxcos_edi_order_work.deliver_to_code_chain%TYPE,            -- �͂���R�[�h�i�`�F�[���X�j
      deliver_to                             xxcos_edi_order_work.deliver_to%TYPE,                       -- �͂���i�����j
      deliver_to1_alt                        xxcos_edi_order_work.deliver_to1_alt%TYPE,                  -- �͂���P�i�J�i�j
      deliver_to2_alt                        xxcos_edi_order_work.deliver_to2_alt%TYPE,                  -- �͂���Q�i�J�i�j
      deliver_to_address                     xxcos_edi_order_work.deliver_to_address%TYPE,               -- �͂���Z���i�����j
      deliver_to_address_alt                 xxcos_edi_order_work.deliver_to_address_alt%TYPE,           -- �͂���Z���i�J�i�j
      deliver_to_tel                         xxcos_edi_order_work.deliver_to_tel%TYPE,                   -- �͂���s�d�k
      balance_accounts_code                  xxcos_edi_order_work.balance_accounts_code%TYPE,            -- ������R�[�h
      balance_accounts_company_code          xxcos_edi_order_work.balance_accounts_company_code%TYPE,    -- ������ЃR�[�h
      balance_accounts_shop_code             xxcos_edi_order_work.balance_accounts_shop_code%TYPE,       -- ������X�R�[�h
      balance_accounts_name                  xxcos_edi_order_work.balance_accounts_name%TYPE,            -- �����於�i�����j
      balance_accounts_name_alt              xxcos_edi_order_work.balance_accounts_name_alt%TYPE,        -- �����於�i�J�i�j
      balance_accounts_address               xxcos_edi_order_work.balance_accounts_address%TYPE,         -- ������Z���i�����j
      balance_accounts_address_alt           xxcos_edi_order_work.balance_accounts_address_alt%TYPE,     -- ������Z���i�J�i�j
      balance_accounts_tel                   xxcos_edi_order_work.balance_accounts_tel%TYPE,             -- ������s�d�k
      order_possible_date                    xxcos_edi_order_work.order_possible_date%TYPE,              -- �󒍉\��
      permission_possible_date               xxcos_edi_order_work.permission_possible_date%TYPE,         -- ���e�\��
      forward_month                          xxcos_edi_order_work.forward_month%TYPE,                    -- ����N����
      payment_settlement_date                xxcos_edi_order_work.payment_settlement_date%TYPE,          -- �x�����ϓ�
      handbill_start_date_active             xxcos_edi_order_work.handbill_start_date_active%TYPE,       -- �`���V�J�n��
      billing_due_date                       xxcos_edi_order_work.billing_due_date%TYPE,                 -- ��������
      shipping_time                          xxcos_edi_order_work.shipping_time%TYPE,                    -- �o�׎���
      delivery_schedule_time                 xxcos_edi_order_work.delivery_schedule_time%TYPE,           -- �[�i�\�莞��
      order_time                             xxcos_edi_order_work.order_time%TYPE,                       -- ��������
      general_date_item1                     xxcos_edi_order_work.general_date_item1%TYPE,               -- �ėp���t���ڂP
      general_date_item2                     xxcos_edi_order_work.general_date_item2%TYPE,               -- �ėp���t���ڂQ
      general_date_item3                     xxcos_edi_order_work.general_date_item3%TYPE,               -- �ėp���t���ڂR
      general_date_item4                     xxcos_edi_order_work.general_date_item4%TYPE,               -- �ėp���t���ڂS
      general_date_item5                     xxcos_edi_order_work.general_date_item5%TYPE,               -- �ėp���t���ڂT
      arrival_shipping_class                 xxcos_edi_order_work.arrival_shipping_class%TYPE,           -- ���o�׋敪
      vendor_class                           xxcos_edi_order_work.vendor_class%TYPE,                     -- �����敪
      invoice_detailed_class                 xxcos_edi_order_work.invoice_detailed_class%TYPE,           -- �`�[����敪
      unit_price_use_class                   xxcos_edi_order_work.unit_price_use_class%TYPE,             -- �P���g�p�敪
      sub_distribution_center_code           xxcos_edi_order_work.sub_distribution_center_code%TYPE,     -- �T�u�����Z���^�[�R�[�h
      sub_distribution_center_name           xxcos_edi_order_work.sub_distribution_center_name%TYPE,     -- �T�u�����Z���^�[�R�[�h��
      center_delivery_method                 xxcos_edi_order_work.center_delivery_method%TYPE,           -- �Z���^�[�[�i���@
      center_use_class                       xxcos_edi_order_work.center_use_class%TYPE,                 -- �Z���^�[���p�敪
      center_whse_class                      xxcos_edi_order_work.center_whse_class%TYPE,                -- �Z���^�[�q�ɋ敪
      center_area_class                      xxcos_edi_order_work.center_area_class%TYPE,                -- �Z���^�[�n��敪
      center_arrival_class                   xxcos_edi_order_work.center_arrival_class%TYPE,             -- �Z���^�[���׋敪
      depot_class                            xxcos_edi_order_work.depot_class%TYPE,                      -- �f�|�敪
      tcdc_class                             xxcos_edi_order_work.tcdc_class%TYPE,                       -- �s�b�c�b�敪
      upc_flag                               xxcos_edi_order_work.upc_flag%TYPE,                         -- �t�o�b�t���O
      simultaneously_class                   xxcos_edi_order_work.simultaneously_class%TYPE,             -- ��ċ敪
      business_id                            xxcos_edi_order_work.business_id%TYPE,                      -- �Ɩ��h�c
      whse_directly_class                    xxcos_edi_order_work.whse_directly_class%TYPE,              -- �q���敪
      premium_rebate_class                   xxcos_edi_order_work.premium_rebate_class%TYPE,             -- �i�i���ߋ敪
      item_type                              xxcos_edi_order_work.item_type%TYPE,                        -- ���ڎ��
      cloth_house_food_class                 xxcos_edi_order_work.cloth_house_food_class%TYPE,           -- �߉ƐH�敪
      mix_class                              xxcos_edi_order_work.mix_class%TYPE,                        -- ���݋敪
      stk_class                              xxcos_edi_order_work.stk_class%TYPE,                        -- �݌ɋ敪
      last_modify_site_class                 xxcos_edi_order_work.last_modify_site_class%TYPE,           -- �ŏI�C���ꏊ�敪
      report_class                           xxcos_edi_order_work.report_class%TYPE,                     -- ���[�敪
      addition_plan_class                    xxcos_edi_order_work.addition_plan_class%TYPE,              -- �ǉ��E�v��敪
      registration_class                     xxcos_edi_order_work.registration_class%TYPE,               -- �o�^�敪
      specific_class                         xxcos_edi_order_work.specific_class%TYPE,                   -- ����敪
      dealings_class                         xxcos_edi_order_work.dealings_class%TYPE,                   -- ����敪
      order_class                            xxcos_edi_order_work.order_class%TYPE,                      -- �����敪
      sum_line_class                         xxcos_edi_order_work.sum_line_class%TYPE,                   -- �W�v���׋敪
      shipping_guidance_class                xxcos_edi_order_work.shipping_guidance_class%TYPE,          -- �o�׈ē��ȊO�敪
      shipping_class                         xxcos_edi_order_work.shipping_class%TYPE,                   -- �o�׋敪
      product_code_use_class                 xxcos_edi_order_work.product_code_use_class%TYPE,           -- ���i�R�[�h�g�p�敪
      cargo_item_class                       xxcos_edi_order_work.cargo_item_class%TYPE,                 -- �ϑ��i�敪
      ta_class                               xxcos_edi_order_work.ta_class%TYPE,                         -- �s�^�`�敪
      plan_code                              xxcos_edi_order_work.plan_code%TYPE,                        -- ���R�[�h
      category_code                          xxcos_edi_order_work.category_code%TYPE,                    -- �J�e�S���[�R�[�h
      category_class                         xxcos_edi_order_work.category_class%TYPE,                   -- �J�e�S���[�敪
      carrier_means                          xxcos_edi_order_work.carrier_means%TYPE,                    -- �^����i
      counter_code                           xxcos_edi_order_work.counter_code%TYPE,                     -- ����R�[�h
      move_sign                              xxcos_edi_order_work.move_sign%TYPE,                        -- �ړ��T�C��
      eos_handwriting_class                  xxcos_edi_order_work.eos_handwriting_class%TYPE,            -- �d�n�r�E�菑�敪
      delivery_to_section_code               xxcos_edi_order_work.delivery_to_section_code%TYPE,         -- �[�i��ۃR�[�h
      invoice_detailed                       xxcos_edi_order_work.invoice_detailed%TYPE,                 -- �`�[����
      attach_qty                             xxcos_edi_order_work.attach_qty%TYPE,                       -- �Y�t��
      other_party_floor                      xxcos_edi_order_work.other_party_floor%TYPE,                -- �t���A
      text_no                                xxcos_edi_order_work.text_no%TYPE,                          -- �s�d�w�s�m��
      in_store_code                          xxcos_edi_order_work.in_store_code%TYPE,                    -- �C���X�g�A�R�[�h
      tag_data                               xxcos_edi_order_work.tag_data%TYPE,                         -- �^�O
      competition_code                       xxcos_edi_order_work.competition_code%TYPE,                 -- ����
      billing_chair                          xxcos_edi_order_work.billing_chair%TYPE,                    -- ��������
      chain_store_code                       xxcos_edi_order_work.chain_store_code%TYPE,                 -- �`�F�[���X�g�A�[�R�[�h
      chain_store_short_name                 xxcos_edi_order_work.chain_store_short_name%TYPE,           -- �`�F�[���X�g�A�[�R�[�h��������
      direct_delivery_rcpt_fee               xxcos_edi_order_work.direct_delivery_rcpt_fee%TYPE,         -- ���z���^���旿
      bill_info                              xxcos_edi_order_work.bill_info%TYPE,                        -- ��`���
      description                            xxcos_edi_order_work.description%TYPE,                      -- �E�v
      interior_code                          xxcos_edi_order_work.interior_code%TYPE,                    -- �����R�[�h
      order_info_delivery_category           xxcos_edi_order_work.order_info_delivery_category%TYPE,     -- �������@�[�i�J�e�S���[
      purchase_type                          xxcos_edi_order_work.purchase_type%TYPE,                    -- �d���`��
      delivery_to_name_alt                   xxcos_edi_order_work.delivery_to_name_alt%TYPE,             -- �[�i�ꏊ���i�J�i�j
      shop_opened_site                       xxcos_edi_order_work.shop_opened_site%TYPE,                 -- �X�o�ꏊ
      counter_name                           xxcos_edi_order_work.counter_name%TYPE,                     -- ���ꖼ
      extension_number                       xxcos_edi_order_work.extension_number%TYPE,                 -- �����ԍ�
      charge_name                            xxcos_edi_order_work.charge_name%TYPE,                      -- �S���Җ�
      price_tag                              xxcos_edi_order_work.price_tag%TYPE,                        -- �l�D
      tax_type                               xxcos_edi_order_work.tax_type%TYPE,                         -- �Ŏ�
      consumption_tax_class                  xxcos_edi_order_work.consumption_tax_class%TYPE,            -- ����ŋ敪
      brand_class                            xxcos_edi_order_work.brand_class%TYPE,                      -- �a�q
      id_code                                xxcos_edi_order_work.id_code%TYPE,                          -- �h�c�R�[�h
      department_code                        xxcos_edi_order_work.department_code%TYPE,                  -- �S�ݓX�R�[�h
      department_name                        xxcos_edi_order_work.department_name%TYPE,                  -- �S�ݓX��
      item_type_number                       xxcos_edi_order_work.item_type_number%TYPE,                 -- �i�ʔԍ�
      description_department                 xxcos_edi_order_work.description_department%TYPE,           -- �E�v�i�S�ݓX�j
      price_tag_method                       xxcos_edi_order_work.price_tag_method%TYPE,                 -- �l�D���@
      reason_column                          xxcos_edi_order_work.reason_column%TYPE,                    -- ���R��
      a_column_header                        xxcos_edi_order_work.a_column_header%TYPE,                  -- �`���w�b�_
      d_column_header                        xxcos_edi_order_work.d_column_header%TYPE,                  -- �c���w�b�_
      brand_code                             xxcos_edi_order_work.brand_code%TYPE,                       -- �u�����h�R�[�h
      line_code                              xxcos_edi_order_work.line_code%TYPE,                        -- ���C���R�[�h
      class_code                             xxcos_edi_order_work.class_code%TYPE,                       -- �N���X�R�[�h
      a1_column                              xxcos_edi_order_work.a1_column%TYPE,                        -- �`�|�P��
      b1_column                              xxcos_edi_order_work.b1_column%TYPE,                        -- �a�|�P��
      c1_column                              xxcos_edi_order_work.c1_column%TYPE,                        -- �b�|�P��
      d1_column                              xxcos_edi_order_work.d1_column%TYPE,                        -- �c�|�P��
      e1_column                              xxcos_edi_order_work.e1_column%TYPE,                        -- �d�|�P��
      a2_column                              xxcos_edi_order_work.a2_column%TYPE,                        -- �`�|�Q��
      b2_column                              xxcos_edi_order_work.b2_column%TYPE,                        -- �a�|�Q��
      c2_column                              xxcos_edi_order_work.c2_column%TYPE,                        -- �b�|�Q��
      d2_column                              xxcos_edi_order_work.d2_column%TYPE,                        -- �c�|�Q��
      e2_column                              xxcos_edi_order_work.e2_column%TYPE,                        -- �d�|�Q��
      a3_column                              xxcos_edi_order_work.a3_column%TYPE,                        -- �`�|�R��
      b3_column                              xxcos_edi_order_work.b3_column%TYPE,                        -- �a�|�R��
      c3_column                              xxcos_edi_order_work.c3_column%TYPE,                        -- �b�|�R��
      d3_column                              xxcos_edi_order_work.d3_column%TYPE,                        -- �c�|�R��
      e3_column                              xxcos_edi_order_work.e3_column%TYPE,                        -- �d�|�R��
      f1_column                              xxcos_edi_order_work.f1_column%TYPE,                        -- �e�|�P��
      g1_column                              xxcos_edi_order_work.g1_column%TYPE,                        -- �f�|�P��
      h1_column                              xxcos_edi_order_work.h1_column%TYPE,                        -- �g�|�P��
      i1_column                              xxcos_edi_order_work.i1_column%TYPE,                        -- �h�|�P��
      j1_column                              xxcos_edi_order_work.j1_column%TYPE,                        -- �i�|�P��
      k1_column                              xxcos_edi_order_work.k1_column%TYPE,                        -- �j�|�P��
      l1_column                              xxcos_edi_order_work.l1_column%TYPE,                        -- �k�|�P��
      f2_column                              xxcos_edi_order_work.f2_column%TYPE,                        -- �e�|�Q��
      g2_column                              xxcos_edi_order_work.g2_column%TYPE,                        -- �f�|�Q��
      h2_column                              xxcos_edi_order_work.h2_column%TYPE,                        -- �g�|�Q��
      i2_column                              xxcos_edi_order_work.i2_column%TYPE,                        -- �h�|�Q��
      j2_column                              xxcos_edi_order_work.j2_column%TYPE,                        -- �i�|�Q��
      k2_column                              xxcos_edi_order_work.k2_column%TYPE,                        -- �j�|�Q��
      l2_column                              xxcos_edi_order_work.l2_column%TYPE,                        -- �k�|�Q��
      f3_column                              xxcos_edi_order_work.f3_column%TYPE,                        -- �e�|�R��
      g3_column                              xxcos_edi_order_work.g3_column%TYPE,                        -- �f�|�R��
      h3_column                              xxcos_edi_order_work.h3_column%TYPE,                        -- �g�|�R��
      i3_column                              xxcos_edi_order_work.i3_column%TYPE,                        -- �h�|�R��
      j3_column                              xxcos_edi_order_work.j3_column%TYPE,                        -- �i�|�R��
      k3_column                              xxcos_edi_order_work.k3_column%TYPE,                        -- �j�|�R��
      l3_column                              xxcos_edi_order_work.l3_column%TYPE,                        -- �k�|�R��
      chain_peculiar_area_header             xxcos_edi_order_work.chain_peculiar_area_header%TYPE,       -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
      order_connection_number                xxcos_edi_order_work.order_connection_number%TYPE,          -- �󒍊֘A�ԍ�
      line_no                                xxcos_edi_order_work.line_no%TYPE,                          -- �s�m��
      stockout_class                         xxcos_edi_order_work.stockout_class%TYPE,                   -- ���i�敪
      stockout_reason                        xxcos_edi_order_work.stockout_reason%TYPE,                  -- ���i���R
      product_code_itouen                    xxcos_edi_order_work.product_code_itouen%TYPE,              -- ���i�R�[�h�i�ɓ����j
      product_code1                          xxcos_edi_order_work.product_code1%TYPE,                    -- ���i�R�[�h�P
      product_code2                          xxcos_edi_order_work.product_code2%TYPE,                    -- ���i�R�[�h�Q
      jan_code                               xxcos_edi_order_work.jan_code%TYPE,                         -- �i�`�m�R�[�h
      itf_code                               xxcos_edi_order_work.itf_code%TYPE,                         -- �h�s�e�R�[�h
      extension_itf_code                     xxcos_edi_order_work.extension_itf_code%TYPE,               -- �����h�s�e�R�[�h
      case_product_code                      xxcos_edi_order_work.case_product_code%TYPE,                -- �P�[�X���i�R�[�h
      ball_product_code                      xxcos_edi_order_work.ball_product_code%TYPE,                -- �{�[�����i�R�[�h
      product_code_item_type                 xxcos_edi_order_work.product_code_item_type%TYPE,           -- ���i�R�[�h�i��
      prod_class                             xxcos_edi_order_work.prod_class%TYPE,                       -- ���i�敪
      product_name                           xxcos_edi_order_work.product_name%TYPE,                     -- ���i���i�����j
      product_name1_alt                      xxcos_edi_order_work.product_name1_alt%TYPE,                -- ���i���P�i�J�i�j
      product_name2_alt                      xxcos_edi_order_work.product_name2_alt%TYPE,                -- ���i���Q�i�J�i�j
      item_standard1                         xxcos_edi_order_work.item_standard1%TYPE,                   -- �K�i�P
      item_standard2                         xxcos_edi_order_work.item_standard2%TYPE,                   -- �K�i�Q
      qty_in_case                            xxcos_edi_order_work.qty_in_case%TYPE,                      -- ����
      num_of_cases                           xxcos_edi_order_work.num_of_cases%TYPE,                     -- �P�[�X����
      num_of_ball                            xxcos_edi_order_work.num_of_ball%TYPE,                      -- �{�[������
      item_color                             xxcos_edi_order_work.item_color%TYPE,                       -- �F
      item_size                              xxcos_edi_order_work.item_size%TYPE,                        -- �T�C�Y
      expiration_date                        xxcos_edi_order_work.expiration_date%TYPE,                  -- �ܖ�������
      product_date                           xxcos_edi_order_work.product_date%TYPE,                     -- ������
      order_uom_qty                          xxcos_edi_order_work.order_uom_qty%TYPE,                    -- �����P�ʐ�
      shipping_uom_qty                       xxcos_edi_order_work.shipping_uom_qty%TYPE,                 -- �o�גP�ʐ�
      packing_uom_qty                        xxcos_edi_order_work.packing_uom_qty%TYPE,                  -- ����P�ʐ�
      deal_code                              xxcos_edi_order_work.deal_code%TYPE,                        -- ����
      deal_class                             xxcos_edi_order_work.deal_class%TYPE,                       -- �����敪
      collation_code                         xxcos_edi_order_work.collation_code%TYPE,                   -- �ƍ�
      uom_code                               xxcos_edi_order_work.uom_code%TYPE,                         -- �P��
      unit_price_class                       xxcos_edi_order_work.unit_price_class%TYPE,                 -- �P���敪
      parent_packing_number                  xxcos_edi_order_work.parent_packing_number%TYPE,            -- �e����ԍ�
      packing_number                         xxcos_edi_order_work.packing_number%TYPE,                   -- ����ԍ�
      product_group_code                     xxcos_edi_order_work.product_group_code%TYPE,               -- ���i�Q�R�[�h
      case_dismantle_flag                    xxcos_edi_order_work.case_dismantle_flag%TYPE,              -- �P�[�X��̕s�t���O
      case_class                             xxcos_edi_order_work.case_class%TYPE,                       -- �P�[�X�敪
      indv_order_qty                         xxcos_edi_order_work.indv_order_qty%TYPE,                   -- �������ʁi�o���j
      case_order_qty                         xxcos_edi_order_work.case_order_qty%TYPE,                   -- �������ʁi�P�[�X�j
      ball_order_qty                         xxcos_edi_order_work.ball_order_qty%TYPE,                   -- �������ʁi�{�[���j
      sum_order_qty                          xxcos_edi_order_work.sum_order_qty%TYPE,                    -- �������ʁi���v�A�o���j
      indv_shipping_qty                      xxcos_edi_order_work.indv_shipping_qty%TYPE,                -- �o�א��ʁi�o���j
      case_shipping_qty                      xxcos_edi_order_work.case_shipping_qty%TYPE,                -- �o�א��ʁi�P�[�X�j
      ball_shipping_qty                      xxcos_edi_order_work.ball_shipping_qty%TYPE,                -- �o�א��ʁi�{�[���j
      pallet_shipping_qty                    xxcos_edi_order_work.pallet_shipping_qty%TYPE,              -- �o�א��ʁi�p���b�g�j
      sum_shipping_qty                       xxcos_edi_order_work.sum_shipping_qty%TYPE,                 -- �o�א��ʁi���v�A�o���j
      indv_stockout_qty                      xxcos_edi_order_work.indv_stockout_qty%TYPE,                -- ���i���ʁi�o���j
      case_stockout_qty                      xxcos_edi_order_work.case_stockout_qty%TYPE,                -- ���i���ʁi�P�[�X�j
      ball_stockout_qty                      xxcos_edi_order_work.ball_stockout_qty%TYPE,                -- ���i���ʁi�{�[���j
      sum_stockout_qty                       xxcos_edi_order_work.sum_stockout_qty%TYPE,                 -- ���i���ʁi���v�A�o���j
      case_qty                               xxcos_edi_order_work.case_qty%TYPE,                         -- �P�[�X����
      fold_container_indv_qty                xxcos_edi_order_work.fold_container_indv_qty%TYPE,          -- �I���R���i�o���j����
      order_unit_price                       xxcos_edi_order_work.order_unit_price%TYPE,                 -- ���P���i�����j
      shipping_unit_price                    xxcos_edi_order_work.shipping_unit_price%TYPE,              -- ���P���i�o�ׁj
      order_cost_amt                         xxcos_edi_order_work.order_cost_amt%TYPE,                   -- �������z�i�����j
      shipping_cost_amt                      xxcos_edi_order_work.shipping_cost_amt%TYPE,                -- �������z�i�o�ׁj
      stockout_cost_amt                      xxcos_edi_order_work.stockout_cost_amt%TYPE,                -- �������z�i���i�j
      selling_price                          xxcos_edi_order_work.selling_price%TYPE,                    -- ���P��
      order_price_amt                        xxcos_edi_order_work.order_price_amt%TYPE,                  -- �������z�i�����j
      shipping_price_amt                     xxcos_edi_order_work.shipping_price_amt%TYPE,               -- �������z�i�o�ׁj
      stockout_price_amt                     xxcos_edi_order_work.stockout_price_amt%TYPE,               -- �������z�i���i�j
      a_column_department                    xxcos_edi_order_work.a_column_department%TYPE,              -- �`���i�S�ݓX�j
      d_column_department                    xxcos_edi_order_work.d_column_department%TYPE,              -- �c���i�S�ݓX�j
      standard_info_depth                    xxcos_edi_order_work.standard_info_depth%TYPE,              -- �K�i���E���s��
      standard_info_height                   xxcos_edi_order_work.standard_info_height%TYPE,             -- �K�i���E����
      standard_info_width                    xxcos_edi_order_work.standard_info_width%TYPE,              -- �K�i���E��
      standard_info_weight                   xxcos_edi_order_work.standard_info_weight%TYPE,             -- �K�i���E�d��
      general_succeeded_item1                xxcos_edi_order_work.general_succeeded_item1%TYPE,          -- �ėp���p�����ڂP
      general_succeeded_item2                xxcos_edi_order_work.general_succeeded_item2%TYPE,          -- �ėp���p�����ڂQ
      general_succeeded_item3                xxcos_edi_order_work.general_succeeded_item3%TYPE,          -- �ėp���p�����ڂR
      general_succeeded_item4                xxcos_edi_order_work.general_succeeded_item4%TYPE,          -- �ėp���p�����ڂS
      general_succeeded_item5                xxcos_edi_order_work.general_succeeded_item5%TYPE,          -- �ėp���p�����ڂT
      general_succeeded_item6                xxcos_edi_order_work.general_succeeded_item6%TYPE,          -- �ėp���p�����ڂU
      general_succeeded_item7                xxcos_edi_order_work.general_succeeded_item7%TYPE,          -- �ėp���p�����ڂV
      general_succeeded_item8                xxcos_edi_order_work.general_succeeded_item8%TYPE,          -- �ėp���p�����ڂW
      general_succeeded_item9                xxcos_edi_order_work.general_succeeded_item9%TYPE,          -- �ėp���p�����ڂX
      general_succeeded_item10               xxcos_edi_order_work.general_succeeded_item10%TYPE,         -- �ėp���p�����ڂP�O
      general_add_item1                      xxcos_edi_order_work.general_add_item1%TYPE,                -- �ėp�t�����ڂP
      general_add_item2                      xxcos_edi_order_work.general_add_item2%TYPE,                -- �ėp�t�����ڂQ
      general_add_item3                      xxcos_edi_order_work.general_add_item3%TYPE,                -- �ėp�t�����ڂR
      general_add_item4                      xxcos_edi_order_work.general_add_item4%TYPE,                -- �ėp�t�����ڂS
      general_add_item5                      xxcos_edi_order_work.general_add_item5%TYPE,                -- �ėp�t�����ڂT
      general_add_item6                      xxcos_edi_order_work.general_add_item6%TYPE,                -- �ėp�t�����ڂU
      general_add_item7                      xxcos_edi_order_work.general_add_item7%TYPE,                -- �ėp�t�����ڂV
      general_add_item8                      xxcos_edi_order_work.general_add_item8%TYPE,                -- �ėp�t�����ڂW
      general_add_item9                      xxcos_edi_order_work.general_add_item9%TYPE,                -- �ėp�t�����ڂX
      general_add_item10                     xxcos_edi_order_work.general_add_item10%TYPE,               -- �ėp�t�����ڂP�O
      chain_peculiar_area_line               xxcos_edi_order_work.chain_peculiar_area_line%TYPE,         -- �`�F�[���X�ŗL�G���A�i���ׁj
      invoice_indv_order_qty                 xxcos_edi_order_work.invoice_indv_order_qty%TYPE,           -- �i�`�[�v�j�������ʁi�o���j
      invoice_case_order_qty                 xxcos_edi_order_work.invoice_case_order_qty%TYPE,           -- �i�`�[�v�j�������ʁi�P�[�X�j
      invoice_ball_order_qty                 xxcos_edi_order_work.invoice_ball_order_qty%TYPE,           -- �i�`�[�v�j�������ʁi�{�[���j
      invoice_sum_order_qty                  xxcos_edi_order_work.invoice_sum_order_qty%TYPE,            -- �i�`�[�v�j�������ʁi���v�A�o���j
      invoice_indv_shipping_qty              xxcos_edi_order_work.invoice_indv_shipping_qty%TYPE,        -- �i�`�[�v�j�o�א��ʁi�o���j
      invoice_case_shipping_qty              xxcos_edi_order_work.invoice_case_shipping_qty%TYPE,        -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
      invoice_ball_shipping_qty              xxcos_edi_order_work.invoice_ball_shipping_qty%TYPE,        -- �i�`�[�v�j�o�א��ʁi�{�[���j
      invoice_pallet_shipping_qty            xxcos_edi_order_work.invoice_pallet_shipping_qty%TYPE,      -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
      invoice_sum_shipping_qty               xxcos_edi_order_work.invoice_sum_shipping_qty%TYPE,         -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
      invoice_indv_stockout_qty              xxcos_edi_order_work.invoice_indv_stockout_qty%TYPE,        -- �i�`�[�v�j���i���ʁi�o���j
      invoice_case_stockout_qty              xxcos_edi_order_work.invoice_case_stockout_qty%TYPE,        -- �i�`�[�v�j���i���ʁi�P�[�X�j
      invoice_ball_stockout_qty              xxcos_edi_order_work.invoice_ball_stockout_qty%TYPE,        -- �i�`�[�v�j���i���ʁi�{�[���j
      invoice_sum_stockout_qty               xxcos_edi_order_work.invoice_sum_stockout_qty%TYPE,         -- �i�`�[�v�j���i���ʁi���v�A�o���j
      invoice_case_qty                       xxcos_edi_order_work.invoice_case_qty%TYPE,                 -- �i�`�[�v�j�P�[�X����
      invoice_fold_container_qty             xxcos_edi_order_work.invoice_fold_container_qty%TYPE,       -- �i�`�[�v�j�I���R���i�o���j����
      invoice_order_cost_amt                 xxcos_edi_order_work.invoice_order_cost_amt%TYPE,           -- �i�`�[�v�j�������z�i�����j
      invoice_shipping_cost_amt              xxcos_edi_order_work.invoice_shipping_cost_amt%TYPE,        -- �i�`�[�v�j�������z�i�o�ׁj
      invoice_stockout_cost_amt              xxcos_edi_order_work.invoice_stockout_cost_amt%TYPE,        -- �i�`�[�v�j�������z�i���i�j
      invoice_order_price_amt                xxcos_edi_order_work.invoice_order_price_amt%TYPE,          -- �i�`�[�v�j�������z�i�����j
      invoice_shipping_price_amt             xxcos_edi_order_work.invoice_shipping_price_amt%TYPE,       -- �i�`�[�v�j�������z�i�o�ׁj
      invoice_stockout_price_amt             xxcos_edi_order_work.invoice_stockout_price_amt%TYPE,       -- �i�`�[�v�j�������z�i���i�j
      total_indv_order_qty                   xxcos_edi_order_work.total_indv_order_qty%TYPE,             -- �i�����v�j�������ʁi�o���j
      total_case_order_qty                   xxcos_edi_order_work.total_case_order_qty%TYPE,             -- �i�����v�j�������ʁi�P�[�X�j
      total_ball_order_qty                   xxcos_edi_order_work.total_ball_order_qty%TYPE,             -- �i�����v�j�������ʁi�{�[���j
      total_sum_order_qty                    xxcos_edi_order_work.total_sum_order_qty%TYPE,              -- �i�����v�j�������ʁi���v�A�o���j
      total_indv_shipping_qty                xxcos_edi_order_work.total_indv_shipping_qty%TYPE,          -- �i�����v�j�o�א��ʁi�o���j
      total_case_shipping_qty                xxcos_edi_order_work.total_case_shipping_qty%TYPE,          -- �i�����v�j�o�א��ʁi�P�[�X�j
      total_ball_shipping_qty                xxcos_edi_order_work.total_ball_shipping_qty%TYPE,          -- �i�����v�j�o�א��ʁi�{�[���j
      total_pallet_shipping_qty              xxcos_edi_order_work.total_pallet_shipping_qty%TYPE,        -- �i�����v�j�o�א��ʁi�p���b�g�j
      total_sum_shipping_qty                 xxcos_edi_order_work.total_sum_shipping_qty%TYPE,           -- �i�����v�j�o�א��ʁi���v�A�o���j
      total_indv_stockout_qty                xxcos_edi_order_work.total_indv_stockout_qty%TYPE,          -- �i�����v�j���i���ʁi�o���j
      total_case_stockout_qty                xxcos_edi_order_work.total_case_stockout_qty%TYPE,          -- �i�����v�j���i���ʁi�P�[�X�j
      total_ball_stockout_qty                xxcos_edi_order_work.total_ball_stockout_qty%TYPE,          -- �i�����v�j���i���ʁi�{�[���j
      total_sum_stockout_qty                 xxcos_edi_order_work.total_sum_stockout_qty%TYPE,           -- �i�����v�j���i���ʁi���v�A�o���j
      total_case_qty                         xxcos_edi_order_work.total_case_qty%TYPE,                   -- �i�����v�j�P�[�X����
      total_fold_container_qty               xxcos_edi_order_work.total_fold_container_qty%TYPE,         -- �i�����v�j�I���R���i�o���j����
      total_order_cost_amt                   xxcos_edi_order_work.total_order_cost_amt%TYPE,             -- �i�����v�j�������z�i�����j
      total_shipping_cost_amt                xxcos_edi_order_work.total_shipping_cost_amt%TYPE,          -- �i�����v�j�������z�i�o�ׁj
      total_stockout_cost_amt                xxcos_edi_order_work.total_stockout_cost_amt%TYPE,          -- �i�����v�j�������z�i���i�j
      total_order_price_amt                  xxcos_edi_order_work.total_order_price_amt%TYPE,            -- �i�����v�j�������z�i�����j
      total_shipping_price_amt               xxcos_edi_order_work.total_shipping_price_amt%TYPE,         -- �i�����v�j�������z�i�o�ׁj
      total_stockout_price_amt               xxcos_edi_order_work.total_stockout_price_amt%TYPE,         -- �i�����v�j�������z�i���i�j
      total_line_qty                         xxcos_edi_order_work.total_line_qty%TYPE,                   -- �g�[�^���s��
      total_invoice_qty                      xxcos_edi_order_work.total_invoice_qty%TYPE,                -- �g�[�^���`�[����
      chain_peculiar_area_footer             xxcos_edi_order_work.chain_peculiar_area_footer%TYPE,       -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
      err_status                             xxcos_edi_order_work.err_status%TYPE,                       -- �X�e�[�^�X
-- 2010/01/19 Ver1.15 M.Sano Mod Start
      creation_date                          xxcos_edi_order_work.creation_date%TYPE,                    -- �쐬��
-- 2010/01/19 Ver1.15 M.Sano Mod End
      -- �ȍ~�AEDI�󒍏�񃏁[�N�e�[�u���ȊO�̃J����
      conv_customer_code                     xxcos_edi_headers.conv_customer_code%TYPE,                  -- �ϊ���ڋq�R�[�h
      price_list_header_id                   xxcos_edi_headers.price_list_header_id%TYPE,                -- ���i�\�w�b�_ID
      item_code                              xxcos_edi_lines.item_code%TYPE,                             -- �i�ڃR�[�h
      line_uom                               xxcos_edi_lines.line_uom%TYPE,                              -- ���גP��
-- 2009/12/28 M.Sano Ver.1.14 add Start
      order_forward_flag                     xxcos_edi_headers.order_forward_flag%TYPE,                  -- �󒍘A�g�σt���O
      tsukagatazaiko_div                     xxcos_edi_headers.tsukagatazaiko_div%TYPE,                  -- �ʉߍ݌Ɍ^�敪
-- 2009/12/28 M.Sano Ver.1.14 add End
-- 2010/01/19 Ver.1.15 M.Sano add Start
      order_connection_line_number           xxcos_edi_lines.order_connection_line_number%TYPE,          -- �󒍊֘A���הԍ�
-- 2010/01/19 Ver.1.15 M.Sano add End
      check_status                           xxcos_edi_order_work.err_status%TYPE                        -- �`�F�b�N�X�e�[�^�X
    );
--
  -- EDI�󒍏�񃏁[�N�e�[�u�� �e�[�u���^�C�v��`
  TYPE g_edi_order_work_ttype                IS TABLE OF edi_order_work_cur%ROWTYPE
    INDEX BY PLS_INTEGER;
  TYPE g_edi_work_ttype                      IS TABLE OF g_edi_work_rtype;
-- EDI�X�e�[�^�X�X�V��`
  TYPE g_order_info_work_id_ttype            IS TABLE OF xxcos_edi_order_work.order_info_work_id%TYPE
    INDEX BY PLS_INTEGER;     -- EDI�󒍏�񃏁[�NID
  TYPE g_edi_err_status_ttype                IS TABLE OF xxcos_edi_order_work.err_status%TYPE
    INDEX BY PLS_INTEGER;     -- �X�e�[�^�X
--
  -- EDI�w�b�_���e�[�u�� �e�[�u���^�C�v��`
  TYPE g_edi_headers_ttype                   IS TABLE OF xxcos_edi_headers%ROWTYPE
    INDEX BY PLS_INTEGER;     -- EDI�w�b�_���e�[�u��
--
  -- EDI�w�b�_���e�[�u�� �e�[�u���^�C�v��`
  TYPE g_edi_header_info_id_ttype            IS TABLE OF xxcos_edi_headers.edi_header_info_id%TYPE
    INDEX BY PLS_INTEGER;     -- EDI�w�b�_���ID
  TYPE g_medium_class_ttype                  IS TABLE OF xxcos_edi_headers.medium_class%TYPE
    INDEX BY PLS_INTEGER;     -- �}�̋敪
  TYPE g_data_type_code_ttype                IS TABLE OF xxcos_edi_headers.data_type_code%TYPE
    INDEX BY PLS_INTEGER;     -- �f�[�^��R�[�h
  TYPE g_file_no_ttype                       IS TABLE OF xxcos_edi_headers.file_no%TYPE
    INDEX BY PLS_INTEGER;     -- �t�@�C���m��
  TYPE g_info_class_ttype                    IS TABLE OF xxcos_edi_headers.info_class%TYPE
    INDEX BY PLS_INTEGER;     -- ���敪
  TYPE g_process_date_ttype                  IS TABLE OF xxcos_edi_headers.process_date%TYPE
    INDEX BY PLS_INTEGER;     -- ������
  TYPE g_process_time_ttype                  IS TABLE OF xxcos_edi_headers.process_time%TYPE
    INDEX BY PLS_INTEGER;     -- ��������
  TYPE g_base_code_ttype                     IS TABLE OF xxcos_edi_headers.base_code%TYPE
    INDEX BY PLS_INTEGER;     -- ���_�i����j�R�[�h
  TYPE g_base_name_ttype                     IS TABLE OF xxcos_edi_headers.base_name%TYPE
    INDEX BY PLS_INTEGER;     -- ���_���i�������j
  TYPE g_base_name_alt_ttype                 IS TABLE OF xxcos_edi_headers.base_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- ���_���i�J�i�j
  TYPE g_edi_chain_code_ttype                IS TABLE OF xxcos_edi_headers.edi_chain_code%TYPE
    INDEX BY PLS_INTEGER;     -- �d�c�h�`�F�[���X�R�[�h
  TYPE g_edi_chain_name_ttype                IS TABLE OF xxcos_edi_headers.edi_chain_name%TYPE
    INDEX BY PLS_INTEGER;     -- �d�c�h�`�F�[���X���i�����j
  TYPE g_edi_chain_name_alt_ttype            IS TABLE OF xxcos_edi_headers.edi_chain_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- �d�c�h�`�F�[���X���i�J�i�j
  TYPE g_chain_code_ttype                    IS TABLE OF xxcos_edi_headers.chain_code%TYPE
    INDEX BY PLS_INTEGER;     -- �`�F�[���X�R�[�h
  TYPE g_chain_name_ttype                    IS TABLE OF xxcos_edi_headers.chain_name%TYPE
    INDEX BY PLS_INTEGER;     -- �`�F�[���X���i�����j
  TYPE g_chain_name_alt_ttype                IS TABLE OF xxcos_edi_headers.chain_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- �`�F�[���X���i�J�i�j
  TYPE g_report_code_ttype                   IS TABLE OF xxcos_edi_headers.report_code%TYPE
    INDEX BY PLS_INTEGER;     -- ���[�R�[�h
  TYPE g_report_show_name_ttype              IS TABLE OF xxcos_edi_headers.report_show_name%TYPE
    INDEX BY PLS_INTEGER;     -- ���[�\����
  TYPE g_customer_code_ttype                 IS TABLE OF xxcos_edi_headers.customer_code%TYPE
    INDEX BY PLS_INTEGER;     -- �ڋq�R�[�h
  TYPE g_customer_name_ttype                 IS TABLE OF xxcos_edi_headers.customer_name%TYPE
    INDEX BY PLS_INTEGER;     -- �ڋq���i�����j
  TYPE g_customer_name_alt_ttype             IS TABLE OF xxcos_edi_headers.customer_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- �ڋq���i�J�i�j
  TYPE g_company_code_ttype                  IS TABLE OF xxcos_edi_headers.company_code%TYPE
    INDEX BY PLS_INTEGER;     -- �ЃR�[�h
  TYPE g_company_name_ttype                  IS TABLE OF xxcos_edi_headers.company_name%TYPE
    INDEX BY PLS_INTEGER;     -- �Ж��i�����j
  TYPE g_company_name_alt_ttype              IS TABLE OF xxcos_edi_headers.company_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- �Ж��i�J�i�j
  TYPE g_shop_code_ttype                     IS TABLE OF xxcos_edi_headers.shop_code%TYPE
    INDEX BY PLS_INTEGER;     -- �X�R�[�h
  TYPE g_shop_name_ttype                     IS TABLE OF xxcos_edi_headers.shop_name%TYPE
    INDEX BY PLS_INTEGER;     -- �X���i�����j
  TYPE g_shop_name_alt_ttype                 IS TABLE OF xxcos_edi_headers.shop_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- �X���i�J�i�j
  TYPE g_delivery_center_cd_ttype            IS TABLE OF xxcos_edi_headers.delivery_center_code%TYPE
    INDEX BY PLS_INTEGER;     -- �[���Z���^�[�R�[�h
  TYPE g_delivery_center_nm_ttype            IS TABLE OF xxcos_edi_headers.delivery_center_name%TYPE
    INDEX BY PLS_INTEGER;     -- �[���Z���^�[���i�����j
  TYPE g_delivery_center_nm_alt_ttype        IS TABLE OF xxcos_edi_headers.delivery_center_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- �[���Z���^�[���i�J�i�j
  TYPE g_order_date_ttype                    IS TABLE OF xxcos_edi_headers.order_date%TYPE
    INDEX BY PLS_INTEGER;     -- ������
  TYPE g_center_delivery_date_ttype          IS TABLE OF xxcos_edi_headers.center_delivery_date%TYPE
    INDEX BY PLS_INTEGER;     -- �Z���^�[�[�i��
  TYPE g_result_delivery_date_ttype          IS TABLE OF xxcos_edi_headers.result_delivery_date%TYPE
    INDEX BY PLS_INTEGER;     -- ���[�i��
  TYPE g_shop_delivery_date_ttype            IS TABLE OF xxcos_edi_headers.shop_delivery_date%TYPE
    INDEX BY PLS_INTEGER;     -- �X�ܔ[�i��
  TYPE g_data_creation_date_edi_ttype        IS TABLE OF xxcos_edi_headers.data_creation_date_edi_data%TYPE
    INDEX BY PLS_INTEGER;     -- �f�[�^�쐬���i�d�c�h�f�[�^���j
  TYPE g_data_creation_time_edi_ttype        IS TABLE OF xxcos_edi_headers.data_creation_time_edi_data%TYPE
    INDEX BY PLS_INTEGER;     -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
  TYPE g_invoice_class_ttype                 IS TABLE OF xxcos_edi_headers.invoice_class%TYPE
    INDEX BY PLS_INTEGER;     -- �`�[�敪
  TYPE g_small_class_code_ttype              IS TABLE OF xxcos_edi_headers.small_classification_code%TYPE
    INDEX BY PLS_INTEGER;     -- �����ރR�[�h
  TYPE g_small_class_name_ttype              IS TABLE OF xxcos_edi_headers.small_classification_name%TYPE
    INDEX BY PLS_INTEGER;     -- �����ޖ�
  TYPE g_middle_class_code_ttype             IS TABLE OF xxcos_edi_headers.middle_classification_code%TYPE
    INDEX BY PLS_INTEGER;     -- �����ރR�[�h
  TYPE g_middle_class_name_ttype             IS TABLE OF xxcos_edi_headers.middle_classification_name%TYPE
    INDEX BY PLS_INTEGER;     -- �����ޖ�
  TYPE g_big_class_code_ttype                IS TABLE OF xxcos_edi_headers.big_classification_code%TYPE
    INDEX BY PLS_INTEGER;     -- �啪�ރR�[�h
  TYPE g_big_class_name_ttype                IS TABLE OF xxcos_edi_headers.big_classification_name%TYPE
    INDEX BY PLS_INTEGER;     -- �啪�ޖ�
  TYPE g_other_party_depart_cd_ttype         IS TABLE OF xxcos_edi_headers.other_party_department_code%TYPE
    INDEX BY PLS_INTEGER;     -- ����敔��R�[�h
  TYPE g_other_party_order_num_ttype         IS TABLE OF xxcos_edi_headers.other_party_order_number%TYPE
    INDEX BY PLS_INTEGER;     -- ����攭���ԍ�
  TYPE g_check_digit_class_ttype             IS TABLE OF xxcos_edi_headers.check_digit_class%TYPE
    INDEX BY PLS_INTEGER;     -- �`�F�b�N�f�W�b�g�L���敪
  TYPE g_invoice_number_ttype                IS TABLE OF xxcos_edi_headers.invoice_number%TYPE
    INDEX BY PLS_INTEGER;     -- �`�[�ԍ�
  TYPE g_check_digit_ttype                   IS TABLE OF xxcos_edi_headers.check_digit%TYPE
    INDEX BY PLS_INTEGER;     -- �`�F�b�N�f�W�b�g
  TYPE g_close_date_ttype                    IS TABLE OF xxcos_edi_headers.close_date%TYPE
    INDEX BY PLS_INTEGER;     -- ����
  TYPE g_order_no_ebs_ttype                  IS TABLE OF xxcos_edi_headers.order_no_ebs%TYPE
    INDEX BY PLS_INTEGER;     -- �󒍂m���i�d�a�r�j
  TYPE g_ar_sale_class_ttype                 IS TABLE OF xxcos_edi_headers.ar_sale_class%TYPE
    INDEX BY PLS_INTEGER;     -- �����敪
  TYPE g_delivery_classe_ttype               IS TABLE OF xxcos_edi_headers.delivery_classe%TYPE
    INDEX BY PLS_INTEGER;     -- �z���敪
  TYPE g_opportunity_no_ttype                IS TABLE OF xxcos_edi_headers.opportunity_no%TYPE
    INDEX BY PLS_INTEGER;     -- �ւm��
  TYPE g_contact_to_ttype                    IS TABLE OF xxcos_edi_headers.contact_to%TYPE
    INDEX BY PLS_INTEGER;     -- �A����
  TYPE g_route_sales_ttype                   IS TABLE OF xxcos_edi_headers.route_sales%TYPE
    INDEX BY PLS_INTEGER;     -- ���[�g�Z�[���X
  TYPE g_corporate_code_ttype                IS TABLE OF xxcos_edi_headers.corporate_code%TYPE
    INDEX BY PLS_INTEGER;     -- �@�l�R�[�h
  TYPE g_maker_name_ttype                    IS TABLE OF xxcos_edi_headers.maker_name%TYPE
    INDEX BY PLS_INTEGER;     -- ���[�J�[��
  TYPE g_area_code_ttype                     IS TABLE OF xxcos_edi_headers.area_code%TYPE
    INDEX BY PLS_INTEGER;     -- �n��R�[�h
  TYPE g_area_name_ttype                     IS TABLE OF xxcos_edi_headers.area_name%TYPE
    INDEX BY PLS_INTEGER;     -- �n�於�i�����j
  TYPE g_area_name_alt_ttype                 IS TABLE OF xxcos_edi_headers.area_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- �n�於�i�J�i�j
  TYPE g_vendor_code_ttype                   IS TABLE OF xxcos_edi_headers.vendor_code%TYPE
    INDEX BY PLS_INTEGER;     -- �����R�[�h
  TYPE g_vendor_name_ttype                   IS TABLE OF xxcos_edi_headers.vendor_name%TYPE
    INDEX BY PLS_INTEGER;     -- ����於�i�����j
  TYPE g_vendor_name1_alt_ttype              IS TABLE OF xxcos_edi_headers.vendor_name1_alt%TYPE
    INDEX BY PLS_INTEGER;     -- ����於�P�i�J�i�j
  TYPE g_vendor_name2_alt_ttype              IS TABLE OF xxcos_edi_headers.vendor_name2_alt%TYPE
    INDEX BY PLS_INTEGER;     -- ����於�Q�i�J�i�j
  TYPE g_vendor_tel_ttype                    IS TABLE OF xxcos_edi_headers.vendor_tel%TYPE
    INDEX BY PLS_INTEGER;     -- �����s�d�k
  TYPE g_vendor_charge_ttype                 IS TABLE OF xxcos_edi_headers.vendor_charge%TYPE
    INDEX BY PLS_INTEGER;     -- �����S����
  TYPE g_vendor_address_ttype                IS TABLE OF xxcos_edi_headers.vendor_address%TYPE
    INDEX BY PLS_INTEGER;     -- �����Z���i�����j
  TYPE g_deliver_to_code_itouen_ttype        IS TABLE OF xxcos_edi_headers.deliver_to_code_itouen%TYPE
    INDEX BY PLS_INTEGER;     -- �͂���R�[�h�i�ɓ����j
  TYPE g_deliver_to_code_chain_ttype         IS TABLE OF xxcos_edi_headers.deliver_to_code_chain%TYPE
    INDEX BY PLS_INTEGER;     -- �͂���R�[�h�i�`�F�[���X�j
  TYPE g_deliver_to_ttype                    IS TABLE OF xxcos_edi_headers.deliver_to%TYPE
    INDEX BY PLS_INTEGER;     -- �͂���i�����j
  TYPE g_deliver_to1_alt_ttype               IS TABLE OF xxcos_edi_headers.deliver_to1_alt%TYPE
    INDEX BY PLS_INTEGER;     -- �͂���P�i�J�i�j
  TYPE g_deliver_to2_alt_ttype               IS TABLE OF xxcos_edi_headers.deliver_to2_alt%TYPE
    INDEX BY PLS_INTEGER;     -- �͂���Q�i�J�i�j
  TYPE g_deliver_to_address_ttype            IS TABLE OF xxcos_edi_headers.deliver_to_address%TYPE
    INDEX BY PLS_INTEGER;     -- �͂���Z���i�����j
  TYPE g_deliver_to_address_alt_ttype        IS TABLE OF xxcos_edi_headers.deliver_to_address_alt%TYPE
    INDEX BY PLS_INTEGER;     -- �͂���Z���i�J�i�j
  TYPE g_deliver_to_tel_ttype                IS TABLE OF xxcos_edi_headers.deliver_to_tel%TYPE
    INDEX BY PLS_INTEGER;     -- �͂���s�d�k
  TYPE g_balance_acct_cd_ttype               IS TABLE OF xxcos_edi_headers.balance_accounts_code%TYPE
    INDEX BY PLS_INTEGER;     -- ������R�[�h
  TYPE g_balance_acct_comp_cd_ttype          IS TABLE OF xxcos_edi_headers.balance_accounts_company_code%TYPE
    INDEX BY PLS_INTEGER;     -- ������ЃR�[�h
  TYPE g_balance_acct_shop_cd_ttype          IS TABLE OF xxcos_edi_headers.balance_accounts_shop_code%TYPE
    INDEX BY PLS_INTEGER;     -- ������X�R�[�h
  TYPE g_balance_acct_nm_ttype               IS TABLE OF xxcos_edi_headers.balance_accounts_name%TYPE
    INDEX BY PLS_INTEGER;     -- �����於�i�����j
  TYPE g_balance_acct_nm_alt_ttype           IS TABLE OF xxcos_edi_headers.balance_accounts_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- �����於�i�J�i�j
  TYPE g_balance_acct_address_ttype          IS TABLE OF xxcos_edi_headers.balance_accounts_address%TYPE
    INDEX BY PLS_INTEGER;     -- ������Z���i�����j
  TYPE g_balance_acct_addr_alt_ttype         IS TABLE OF xxcos_edi_headers.balance_accounts_address_alt%TYPE
    INDEX BY PLS_INTEGER;     -- ������Z���i�J�i�j
  TYPE g_balance_acct_tel_ttype              IS TABLE OF xxcos_edi_headers.balance_accounts_tel%TYPE
    INDEX BY PLS_INTEGER;     -- ������s�d�k
  TYPE g_order_possible_date_ttype           IS TABLE OF xxcos_edi_headers.order_possible_date%TYPE
    INDEX BY PLS_INTEGER;     -- �󒍉\��
  TYPE g_permit_possible_date_ttype          IS TABLE OF xxcos_edi_headers.permission_possible_date%TYPE
    INDEX BY PLS_INTEGER;     -- ���e�\��
  TYPE g_forward_month_ttype                 IS TABLE OF xxcos_edi_headers.forward_month%TYPE
    INDEX BY PLS_INTEGER;     -- ����N����
  TYPE g_payment_settle_date_ttype           IS TABLE OF xxcos_edi_headers.payment_settlement_date%TYPE
    INDEX BY PLS_INTEGER;     -- �x�����ϓ�
  TYPE g_handbill_st_date_act_ttype          IS TABLE OF xxcos_edi_headers.handbill_start_date_active%TYPE
    INDEX BY PLS_INTEGER;     -- �`���V�J�n��
  TYPE g_billing_due_date_ttype              IS TABLE OF xxcos_edi_headers.billing_due_date%TYPE
    INDEX BY PLS_INTEGER;     -- ��������
  TYPE g_shipping_time_ttype                 IS TABLE OF xxcos_edi_headers.shipping_time%TYPE
    INDEX BY PLS_INTEGER;     -- �o�׎���
  TYPE g_delivery_schedule_time_ttype        IS TABLE OF xxcos_edi_headers.delivery_schedule_time%TYPE
    INDEX BY PLS_INTEGER;     -- �[�i�\�莞��
  TYPE g_order_time_ttype                    IS TABLE OF xxcos_edi_headers.order_time%TYPE
    INDEX BY PLS_INTEGER;     -- ��������
  TYPE g_general_date_item1_ttype            IS TABLE OF xxcos_edi_headers.general_date_item1%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���t���ڂP
  TYPE g_general_date_item2_ttype            IS TABLE OF xxcos_edi_headers.general_date_item2%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���t���ڂQ
  TYPE g_general_date_item3_ttype            IS TABLE OF xxcos_edi_headers.general_date_item3%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���t���ڂR
  TYPE g_general_date_item4_ttype            IS TABLE OF xxcos_edi_headers.general_date_item4%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���t���ڂS
  TYPE g_general_date_item5_ttype            IS TABLE OF xxcos_edi_headers.general_date_item5%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���t���ڂT
  TYPE g_arrival_shipping_class_ttype        IS TABLE OF xxcos_edi_headers.arrival_shipping_class%TYPE
    INDEX BY PLS_INTEGER;     -- ���o�׋敪
  TYPE g_vendor_class_ttype                  IS TABLE OF xxcos_edi_headers.vendor_class%TYPE
    INDEX BY PLS_INTEGER;     -- �����敪
  TYPE g_invoice_detailed_class_ttype        IS TABLE OF xxcos_edi_headers.invoice_detailed_class%TYPE
    INDEX BY PLS_INTEGER;     -- �`�[����敪
  TYPE g_unit_price_use_class_ttype          IS TABLE OF xxcos_edi_headers.unit_price_use_class%TYPE
    INDEX BY PLS_INTEGER;     -- �P���g�p�敪
  TYPE g_sub_dist_center_cd_ttype            IS TABLE OF xxcos_edi_headers.sub_distribution_center_code%TYPE
    INDEX BY PLS_INTEGER;     -- �T�u�����Z���^�[�R�[�h
  TYPE g_sub_dist_center_nm_ttype            IS TABLE OF xxcos_edi_headers.sub_distribution_center_name%TYPE
    INDEX BY PLS_INTEGER;     -- �T�u�����Z���^�[�R�[�h��
  TYPE g_center_delivery_method_ttype        IS TABLE OF xxcos_edi_headers.center_delivery_method%TYPE
    INDEX BY PLS_INTEGER;     -- �Z���^�[�[�i���@
  TYPE g_center_use_class_ttype              IS TABLE OF xxcos_edi_headers.center_use_class%TYPE
    INDEX BY PLS_INTEGER;     -- �Z���^�[���p�敪
  TYPE g_center_whse_class_ttype             IS TABLE OF xxcos_edi_headers.center_whse_class%TYPE
    INDEX BY PLS_INTEGER;     -- �Z���^�[�q�ɋ敪
  TYPE g_center_area_class_ttype             IS TABLE OF xxcos_edi_headers.center_area_class%TYPE
    INDEX BY PLS_INTEGER;     -- �Z���^�[�n��敪
  TYPE g_center_arrival_class_ttype          IS TABLE OF xxcos_edi_headers.center_arrival_class%TYPE
    INDEX BY PLS_INTEGER;     -- �Z���^�[���׋敪
  TYPE g_depot_class_ttype                   IS TABLE OF xxcos_edi_headers.depot_class%TYPE
    INDEX BY PLS_INTEGER;     -- �f�|�敪
  TYPE g_tcdc_class_ttype                    IS TABLE OF xxcos_edi_headers.tcdc_class%TYPE
    INDEX BY PLS_INTEGER;     -- �s�b�c�b�敪
  TYPE g_upc_flag_ttype                      IS TABLE OF xxcos_edi_headers.upc_flag%TYPE
    INDEX BY PLS_INTEGER;     -- �t�o�b�t���O
  TYPE g_simultaneously_class_ttype          IS TABLE OF xxcos_edi_headers.simultaneously_class%TYPE
    INDEX BY PLS_INTEGER;     -- ��ċ敪
  TYPE g_business_id_ttype                   IS TABLE OF xxcos_edi_headers.business_id%TYPE
    INDEX BY PLS_INTEGER;     -- �Ɩ��h�c
  TYPE g_whse_directly_class_ttype           IS TABLE OF xxcos_edi_headers.whse_directly_class%TYPE
    INDEX BY PLS_INTEGER;     -- �q���敪
  TYPE g_premium_rebate_class_ttype          IS TABLE OF xxcos_edi_headers.premium_rebate_class%TYPE
    INDEX BY PLS_INTEGER;     -- �i�i���ߋ敪
  TYPE g_item_type_ttype                     IS TABLE OF xxcos_edi_headers.item_type%TYPE
    INDEX BY PLS_INTEGER;     -- ���ڎ��
  TYPE g_cloth_house_food_class_ttype        IS TABLE OF xxcos_edi_headers.cloth_house_food_class%TYPE
    INDEX BY PLS_INTEGER;     -- �߉ƐH�敪
  TYPE g_mix_class_ttype                     IS TABLE OF xxcos_edi_headers.mix_class%TYPE
    INDEX BY PLS_INTEGER;     -- ���݋敪
  TYPE g_stk_class_ttype                     IS TABLE OF xxcos_edi_headers.stk_class%TYPE
    INDEX BY PLS_INTEGER;     -- �݌ɋ敪
  TYPE g_last_modify_site_class_ttype        IS TABLE OF xxcos_edi_headers.last_modify_site_class%TYPE
    INDEX BY PLS_INTEGER;     -- �ŏI�C���ꏊ�敪
  TYPE g_report_class_ttype                  IS TABLE OF xxcos_edi_headers.report_class%TYPE
    INDEX BY PLS_INTEGER;     -- ���[�敪
  TYPE g_addition_plan_class_ttype           IS TABLE OF xxcos_edi_headers.addition_plan_class%TYPE
    INDEX BY PLS_INTEGER;     -- �ǉ��E�v��敪
  TYPE g_registration_class_ttype            IS TABLE OF xxcos_edi_headers.registration_class%TYPE
    INDEX BY PLS_INTEGER;     -- �o�^�敪
  TYPE g_specific_class_ttype                IS TABLE OF xxcos_edi_headers.specific_class%TYPE
    INDEX BY PLS_INTEGER;     -- ����敪
  TYPE g_dealings_class_ttype                IS TABLE OF xxcos_edi_headers.dealings_class%TYPE
    INDEX BY PLS_INTEGER;     -- ����敪
  TYPE g_order_class_ttype                   IS TABLE OF xxcos_edi_headers.order_class%TYPE
    INDEX BY PLS_INTEGER;     -- �����敪
  TYPE g_sum_line_class_ttype                IS TABLE OF xxcos_edi_headers.sum_line_class%TYPE
    INDEX BY PLS_INTEGER;     -- �W�v���׋敪
  TYPE g_shipping_guide_class_ttype          IS TABLE OF xxcos_edi_headers.shipping_guidance_class%TYPE
    INDEX BY PLS_INTEGER;     -- �o�׈ē��ȊO�敪
  TYPE g_shipping_class_ttype                IS TABLE OF xxcos_edi_headers.shipping_class%TYPE
    INDEX BY PLS_INTEGER;     -- �o�׋敪
  TYPE g_product_code_use_class_ttype        IS TABLE OF xxcos_edi_headers.product_code_use_class%TYPE
    INDEX BY PLS_INTEGER;     -- ���i�R�[�h�g�p�敪
  TYPE g_cargo_item_class_ttype              IS TABLE OF xxcos_edi_headers.cargo_item_class%TYPE
    INDEX BY PLS_INTEGER;     -- �ϑ��i�敪
  TYPE g_ta_class_ttype                      IS TABLE OF xxcos_edi_headers.ta_class%TYPE
    INDEX BY PLS_INTEGER;     -- �s�^�`�敪
  TYPE g_plan_code_ttype                     IS TABLE OF xxcos_edi_headers.plan_code%TYPE
    INDEX BY PLS_INTEGER;     -- ���R�[�h
  TYPE g_category_code_ttype                 IS TABLE OF xxcos_edi_headers.category_code%TYPE
    INDEX BY PLS_INTEGER;     -- �J�e�S���[�R�[�h
  TYPE g_category_class_ttype                IS TABLE OF xxcos_edi_headers.category_class%TYPE
    INDEX BY PLS_INTEGER;     -- �J�e�S���[�敪
  TYPE g_carrier_means_ttype                 IS TABLE OF xxcos_edi_headers.carrier_means%TYPE
    INDEX BY PLS_INTEGER;     -- �^����i
  TYPE g_counter_code_ttype                  IS TABLE OF xxcos_edi_headers.counter_code%TYPE
    INDEX BY PLS_INTEGER;     -- ����R�[�h
  TYPE g_move_sign_ttype                     IS TABLE OF xxcos_edi_headers.move_sign%TYPE
    INDEX BY PLS_INTEGER;     -- �ړ��T�C��
  TYPE g_eos_handwriting_class_ttype         IS TABLE OF xxcos_edi_headers.eos_handwriting_class%TYPE
    INDEX BY PLS_INTEGER;     -- �d�n�r�E�菑�敪
  TYPE g_delivery_to_section_cd_ttype        IS TABLE OF xxcos_edi_headers.delivery_to_section_code%TYPE
    INDEX BY PLS_INTEGER;     -- �[�i��ۃR�[�h
  TYPE g_invoice_detailed_ttype              IS TABLE OF xxcos_edi_headers.invoice_detailed%TYPE
    INDEX BY PLS_INTEGER;     -- �`�[����
  TYPE g_attach_qty_ttype                    IS TABLE OF xxcos_edi_headers.attach_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �Y�t��
  TYPE g_other_party_floor_ttype             IS TABLE OF xxcos_edi_headers.other_party_floor%TYPE
    INDEX BY PLS_INTEGER;     -- �t���A
  TYPE g_text_no_ttype                       IS TABLE OF xxcos_edi_headers.text_no%TYPE
    INDEX BY PLS_INTEGER;     -- �s�d�w�s�m��
  TYPE g_in_store_code_ttype                 IS TABLE OF xxcos_edi_headers.in_store_code%TYPE
    INDEX BY PLS_INTEGER;     -- �C���X�g�A�R�[�h
  TYPE g_tag_data_ttype                      IS TABLE OF xxcos_edi_headers.tag_data%TYPE
    INDEX BY PLS_INTEGER;     -- �^�O
  TYPE g_competition_code_ttype              IS TABLE OF xxcos_edi_headers.competition_code%TYPE
    INDEX BY PLS_INTEGER;     -- ����
  TYPE g_billing_chair_ttype                 IS TABLE OF xxcos_edi_headers.billing_chair%TYPE
    INDEX BY PLS_INTEGER;     -- ��������
  TYPE g_chain_store_code_ttype              IS TABLE OF xxcos_edi_headers.chain_store_code%TYPE
    INDEX BY PLS_INTEGER;     -- �`�F�[���X�g�A�[�R�[�h
  TYPE g_chain_store_short_name_ttype        IS TABLE OF xxcos_edi_headers.chain_store_short_name%TYPE
    INDEX BY PLS_INTEGER;     -- �`�F�[���X�g�A�[�R�[�h��������
  TYPE g_direct_delive_rcpt_fee_ttype        IS TABLE OF xxcos_edi_headers.direct_delivery_rcpt_fee%TYPE
    INDEX BY PLS_INTEGER;     -- ���z���^���旿
  TYPE g_bill_info_ttype                     IS TABLE OF xxcos_edi_headers.bill_info%TYPE
    INDEX BY PLS_INTEGER;     -- ��`���
  TYPE g_description_ttype                   IS TABLE OF xxcos_edi_headers.description%TYPE
    INDEX BY PLS_INTEGER;     -- �E�v
  TYPE g_interior_code_ttype                 IS TABLE OF xxcos_edi_headers.interior_code%TYPE
    INDEX BY PLS_INTEGER;     -- �����R�[�h
  TYPE g_order_info_delive_cat_ttype         IS TABLE OF xxcos_edi_headers.order_info_delivery_category%TYPE
    INDEX BY PLS_INTEGER;     -- �������@�[�i�J�e�S���[
  TYPE g_purchase_type_ttype                 IS TABLE OF xxcos_edi_headers.purchase_type%TYPE
    INDEX BY PLS_INTEGER;     -- �d���`��
  TYPE g_delivery_to_name_alt_ttype          IS TABLE OF xxcos_edi_headers.delivery_to_name_alt%TYPE
    INDEX BY PLS_INTEGER;     -- �[�i�ꏊ���i�J�i�j
  TYPE g_shop_opened_site_ttype              IS TABLE OF xxcos_edi_headers.shop_opened_site%TYPE
    INDEX BY PLS_INTEGER;     -- �X�o�ꏊ
  TYPE g_counter_name_ttype                  IS TABLE OF xxcos_edi_headers.counter_name%TYPE
    INDEX BY PLS_INTEGER;     -- ���ꖼ
  TYPE g_extension_number_ttype              IS TABLE OF xxcos_edi_headers.extension_number%TYPE
    INDEX BY PLS_INTEGER;     -- �����ԍ�
  TYPE g_charge_name_ttype                   IS TABLE OF xxcos_edi_headers.charge_name%TYPE
    INDEX BY PLS_INTEGER;     -- �S���Җ�
  TYPE g_price_tag_ttype                     IS TABLE OF xxcos_edi_headers.price_tag%TYPE
    INDEX BY PLS_INTEGER;     -- �l�D
  TYPE g_tax_type_ttype                      IS TABLE OF xxcos_edi_headers.tax_type%TYPE
    INDEX BY PLS_INTEGER;     -- �Ŏ�
  TYPE g_consumption_tax_class_ttype         IS TABLE OF xxcos_edi_headers.consumption_tax_class%TYPE
    INDEX BY PLS_INTEGER;     -- ����ŋ敪
  TYPE g_brand_class_ttype                   IS TABLE OF xxcos_edi_headers.brand_class%TYPE
    INDEX BY PLS_INTEGER;     -- �a�q
  TYPE g_id_code_ttype                       IS TABLE OF xxcos_edi_headers.id_code%TYPE
    INDEX BY PLS_INTEGER;     -- �h�c�R�[�h
  TYPE g_department_code_ttype               IS TABLE OF xxcos_edi_headers.department_code%TYPE
    INDEX BY PLS_INTEGER;     -- �S�ݓX�R�[�h
  TYPE g_department_name_ttype               IS TABLE OF xxcos_edi_headers.department_name%TYPE
    INDEX BY PLS_INTEGER;     -- �S�ݓX��
  TYPE g_item_type_number_ttype              IS TABLE OF xxcos_edi_headers.item_type_number%TYPE
    INDEX BY PLS_INTEGER;     -- �i�ʔԍ�
  TYPE g_description_department_ttype        IS TABLE OF xxcos_edi_headers.description_department%TYPE
    INDEX BY PLS_INTEGER;     -- �E�v�i�S�ݓX�j
  TYPE g_price_tag_method_ttype              IS TABLE OF xxcos_edi_headers.price_tag_method%TYPE
    INDEX BY PLS_INTEGER;     -- �l�D���@
  TYPE g_reason_column_ttype                 IS TABLE OF xxcos_edi_headers.reason_column%TYPE
    INDEX BY PLS_INTEGER;     -- ���R��
  TYPE g_a_column_header_ttype               IS TABLE OF xxcos_edi_headers.a_column_header%TYPE
    INDEX BY PLS_INTEGER;     -- �`���w�b�_
  TYPE g_d_column_header_ttype               IS TABLE OF xxcos_edi_headers.d_column_header%TYPE
    INDEX BY PLS_INTEGER;     -- �c���w�b�_
  TYPE g_brand_code_ttype                    IS TABLE OF xxcos_edi_headers.brand_code%TYPE
    INDEX BY PLS_INTEGER;     -- �u�����h�R�[�h
  TYPE g_line_code_ttype                     IS TABLE OF xxcos_edi_headers.line_code%TYPE
    INDEX BY PLS_INTEGER;     -- ���C���R�[�h
  TYPE g_class_code_ttype                    IS TABLE OF xxcos_edi_headers.class_code%TYPE
    INDEX BY PLS_INTEGER;     -- �N���X�R�[�h
  TYPE g_a1_column_ttype                     IS TABLE OF xxcos_edi_headers.a1_column%TYPE
    INDEX BY PLS_INTEGER;     -- �`�|�P��
  TYPE g_b1_column_ttype                     IS TABLE OF xxcos_edi_headers.b1_column%TYPE
    INDEX BY PLS_INTEGER;     -- �a�|�P��
  TYPE g_c1_column_ttype                     IS TABLE OF xxcos_edi_headers.c1_column%TYPE
    INDEX BY PLS_INTEGER;     -- �b�|�P��
  TYPE g_d1_column_ttype                     IS TABLE OF xxcos_edi_headers.d1_column%TYPE
    INDEX BY PLS_INTEGER;     -- �c�|�P��
  TYPE g_e1_column_ttype                     IS TABLE OF xxcos_edi_headers.e1_column%TYPE
    INDEX BY PLS_INTEGER;     -- �d�|�P��
  TYPE g_a2_column_ttype                     IS TABLE OF xxcos_edi_headers.a2_column%TYPE
    INDEX BY PLS_INTEGER;     -- �`�|�Q��
  TYPE g_b2_column_ttype                     IS TABLE OF xxcos_edi_headers.b2_column%TYPE
    INDEX BY PLS_INTEGER;     -- �a�|�Q��
  TYPE g_c2_column_ttype                     IS TABLE OF xxcos_edi_headers.c2_column%TYPE
    INDEX BY PLS_INTEGER;     -- �b�|�Q��
  TYPE g_d2_column_ttype                     IS TABLE OF xxcos_edi_headers.d2_column%TYPE
    INDEX BY PLS_INTEGER;     -- �c�|�Q��
  TYPE g_e2_column_ttype                     IS TABLE OF xxcos_edi_headers.e2_column%TYPE
    INDEX BY PLS_INTEGER;     -- �d�|�Q��
  TYPE g_a3_column_ttype                     IS TABLE OF xxcos_edi_headers.a3_column%TYPE
    INDEX BY PLS_INTEGER;     -- �`�|�R��
  TYPE g_b3_column_ttype                     IS TABLE OF xxcos_edi_headers.b3_column%TYPE
    INDEX BY PLS_INTEGER;     -- �a�|�R��
  TYPE g_c3_column_ttype                     IS TABLE OF xxcos_edi_headers.c3_column%TYPE
    INDEX BY PLS_INTEGER;     -- �b�|�R��
  TYPE g_d3_column_ttype                     IS TABLE OF xxcos_edi_headers.d3_column%TYPE
    INDEX BY PLS_INTEGER;     -- �c�|�R��
  TYPE g_e3_column_ttype                     IS TABLE OF xxcos_edi_headers.e3_column%TYPE
    INDEX BY PLS_INTEGER;     -- �d�|�R��
  TYPE g_f1_column_ttype                     IS TABLE OF xxcos_edi_headers.f1_column%TYPE
    INDEX BY PLS_INTEGER;     -- �e�|�P��
  TYPE g_g1_column_ttype                     IS TABLE OF xxcos_edi_headers.g1_column%TYPE
    INDEX BY PLS_INTEGER;     -- �f�|�P��
  TYPE g_h1_column_ttype                     IS TABLE OF xxcos_edi_headers.h1_column%TYPE
    INDEX BY PLS_INTEGER;     -- �g�|�P��
  TYPE g_i1_column_ttype                     IS TABLE OF xxcos_edi_headers.i1_column%TYPE
    INDEX BY PLS_INTEGER;     -- �h�|�P��
  TYPE g_j1_column_ttype                     IS TABLE OF xxcos_edi_headers.j1_column%TYPE
    INDEX BY PLS_INTEGER;     -- �i�|�P��
  TYPE g_k1_column_ttype                     IS TABLE OF xxcos_edi_headers.k1_column%TYPE
    INDEX BY PLS_INTEGER;     -- �j�|�P��
  TYPE g_l1_column_ttype                     IS TABLE OF xxcos_edi_headers.l1_column%TYPE
    INDEX BY PLS_INTEGER;     -- �k�|�P��
  TYPE g_f2_column_ttype                     IS TABLE OF xxcos_edi_headers.f2_column%TYPE
    INDEX BY PLS_INTEGER;     -- �e�|�Q��
  TYPE g_g2_column_ttype                     IS TABLE OF xxcos_edi_headers.g2_column%TYPE
    INDEX BY PLS_INTEGER;     -- �f�|�Q��
  TYPE g_h2_column_ttype                     IS TABLE OF xxcos_edi_headers.h2_column%TYPE
    INDEX BY PLS_INTEGER;     -- �g�|�Q��
  TYPE g_i2_column_ttype                     IS TABLE OF xxcos_edi_headers.i2_column%TYPE
    INDEX BY PLS_INTEGER;     -- �h�|�Q��
  TYPE g_j2_column_ttype                     IS TABLE OF xxcos_edi_headers.j2_column%TYPE
    INDEX BY PLS_INTEGER;     -- �i�|�Q��
  TYPE g_k2_column_ttype                     IS TABLE OF xxcos_edi_headers.k2_column%TYPE
    INDEX BY PLS_INTEGER;     -- �j�|�Q��
  TYPE g_l2_column_ttype                     IS TABLE OF xxcos_edi_headers.l2_column%TYPE
    INDEX BY PLS_INTEGER;     -- �k�|�Q��
  TYPE g_f3_column_ttype                     IS TABLE OF xxcos_edi_headers.f3_column%TYPE
    INDEX BY PLS_INTEGER;     -- �e�|�R��
  TYPE g_g3_column_ttype                     IS TABLE OF xxcos_edi_headers.g3_column%TYPE
    INDEX BY PLS_INTEGER;     -- �f�|�R��
  TYPE g_h3_column_ttype                     IS TABLE OF xxcos_edi_headers.h3_column%TYPE
    INDEX BY PLS_INTEGER;     -- �g�|�R��
  TYPE g_i3_column_ttype                     IS TABLE OF xxcos_edi_headers.i3_column%TYPE
    INDEX BY PLS_INTEGER;     -- �h�|�R��
  TYPE g_j3_column_ttype                     IS TABLE OF xxcos_edi_headers.j3_column%TYPE
    INDEX BY PLS_INTEGER;     -- �i�|�R��
  TYPE g_k3_column_ttype                     IS TABLE OF xxcos_edi_headers.k3_column%TYPE
    INDEX BY PLS_INTEGER;     -- �j�|�R��
  TYPE g_l3_column_ttype                     IS TABLE OF xxcos_edi_headers.l3_column%TYPE
    INDEX BY PLS_INTEGER;     -- �k�|�R��
  TYPE g_chain_pecul_area_head_ttype         IS TABLE OF xxcos_edi_headers.chain_peculiar_area_header%TYPE
    INDEX BY PLS_INTEGER;     -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
  TYPE g_order_connection_num_ttype          IS TABLE OF xxcos_edi_headers.order_connection_number%TYPE
    INDEX BY PLS_INTEGER;     -- �󒍊֘A�ԍ�
  TYPE g_inv_indv_order_qty_ttype            IS TABLE OF xxcos_edi_headers.invoice_indv_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�������ʁi�o���j
  TYPE g_inv_case_order_qty_ttype            IS TABLE OF xxcos_edi_headers.invoice_case_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�������ʁi�P�[�X�j
  TYPE g_inv_ball_order_qty_ttype            IS TABLE OF xxcos_edi_headers.invoice_ball_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�������ʁi�{�[���j
  TYPE g_inv_sum_order_qty_ttype             IS TABLE OF xxcos_edi_headers.invoice_sum_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�������ʁi���v�A�o���j
  TYPE g_inv_indv_shipping_qty_ttype         IS TABLE OF xxcos_edi_headers.invoice_indv_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�o�א��ʁi�o���j
  TYPE g_inv_case_shipping_qty_ttype         IS TABLE OF xxcos_edi_headers.invoice_case_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
  TYPE g_inv_ball_shipping_qty_ttype         IS TABLE OF xxcos_edi_headers.invoice_ball_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�o�א��ʁi�{�[���j
  TYPE g_inv_plt_shipping_qty_ttype          IS TABLE OF xxcos_edi_headers.invoice_pallet_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
  TYPE g_inv_sum_shipping_qty_ttype          IS TABLE OF xxcos_edi_headers.invoice_sum_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
  TYPE g_inv_indv_stockout_qty_ttype         IS TABLE OF xxcos_edi_headers.invoice_indv_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j���i���ʁi�o���j
  TYPE g_inv_case_stockout_qty_ttype         IS TABLE OF xxcos_edi_headers.invoice_case_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j���i���ʁi�P�[�X�j
  TYPE g_inv_ball_stockout_qty_ttype         IS TABLE OF xxcos_edi_headers.invoice_ball_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j���i���ʁi�{�[���j
  TYPE g_inv_sum_stockout_qty_ttype          IS TABLE OF xxcos_edi_headers.invoice_sum_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j���i���ʁi���v�A�o���j
  TYPE g_inv_case_qty_ttype                  IS TABLE OF xxcos_edi_headers.invoice_case_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�P�[�X����
  TYPE g_inv_fold_container_qty_ttype        IS TABLE OF xxcos_edi_headers.invoice_fold_container_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�I���R���i�o���j����
  TYPE g_inv_order_cost_amt_ttype            IS TABLE OF xxcos_edi_headers.invoice_order_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�������z�i�����j
  TYPE g_inv_shipping_cost_amt_ttype         IS TABLE OF xxcos_edi_headers.invoice_shipping_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�������z�i�o�ׁj
  TYPE g_inv_stockout_cost_amt_ttype         IS TABLE OF xxcos_edi_headers.invoice_stockout_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�������z�i���i�j
  TYPE g_inv_order_price_amt_ttype           IS TABLE OF xxcos_edi_headers.invoice_order_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�������z�i�����j
  TYPE g_inv_shipping_price_amt_ttype        IS TABLE OF xxcos_edi_headers.invoice_shipping_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�������z�i�o�ׁj
  TYPE g_inv_stockout_price_amt_ttype        IS TABLE OF xxcos_edi_headers.invoice_stockout_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�[�v�j�������z�i���i�j
  TYPE g_total_indv_order_qty_ttype          IS TABLE OF xxcos_edi_headers.total_indv_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�������ʁi�o���j
  TYPE g_total_case_order_qty_ttype          IS TABLE OF xxcos_edi_headers.total_case_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�������ʁi�P�[�X�j
  TYPE g_total_ball_order_qty_ttype          IS TABLE OF xxcos_edi_headers.total_ball_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�������ʁi�{�[���j
  TYPE g_total_sum_order_qty_ttype           IS TABLE OF xxcos_edi_headers.total_sum_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�������ʁi���v�A�o���j
  TYPE g_total_indv_ship_qty_ttype           IS TABLE OF xxcos_edi_headers.total_indv_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�o�א��ʁi�o���j
  TYPE g_total_case_ship_qty_ttype           IS TABLE OF xxcos_edi_headers.total_case_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�o�א��ʁi�P�[�X�j
  TYPE g_total_ball_ship_qty_ttype           IS TABLE OF xxcos_edi_headers.total_ball_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�o�א��ʁi�{�[���j
  TYPE g_total_pallet_ship_qty_ttype         IS TABLE OF xxcos_edi_headers.total_pallet_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�o�א��ʁi�p���b�g�j
  TYPE g_total_sum_ship_qty_ttype            IS TABLE OF xxcos_edi_headers.total_sum_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�o�א��ʁi���v�A�o���j
  TYPE g_total_indv_stkout_qty_ttype         IS TABLE OF xxcos_edi_headers.total_indv_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j���i���ʁi�o���j
  TYPE g_total_case_stkout_qty_ttype         IS TABLE OF xxcos_edi_headers.total_case_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j���i���ʁi�P�[�X�j
  TYPE g_total_ball_stkout_qty_ttype         IS TABLE OF xxcos_edi_headers.total_ball_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j���i���ʁi�{�[���j
  TYPE g_total_sum_stkout_qty_ttype          IS TABLE OF xxcos_edi_headers.total_sum_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j���i���ʁi���v�A�o���j
  TYPE g_total_case_qty_ttype                IS TABLE OF xxcos_edi_headers.total_case_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�P�[�X����
  TYPE g_total_fold_contain_qty_ttype        IS TABLE OF xxcos_edi_headers.total_fold_container_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�I���R���i�o���j����
  TYPE g_total_order_cost_amt_ttype          IS TABLE OF xxcos_edi_headers.total_order_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�������z�i�����j
  TYPE g_total_ship_cost_amt_ttype           IS TABLE OF xxcos_edi_headers.total_shipping_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�������z�i�o�ׁj
  TYPE g_total_stkout_cost_amt_ttype         IS TABLE OF xxcos_edi_headers.total_stockout_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�������z�i���i�j
  TYPE g_total_order_price_amt_ttype         IS TABLE OF xxcos_edi_headers.total_order_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�������z�i�����j
  TYPE g_total_ship_price_amt_ttype          IS TABLE OF xxcos_edi_headers.total_shipping_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�������z�i�o�ׁj
  TYPE g_total_stock_price_amt_ttype         IS TABLE OF xxcos_edi_headers.total_stockout_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �i�����v�j�������z�i���i�j
  TYPE g_total_line_qty_ttype                IS TABLE OF xxcos_edi_headers.total_line_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �g�[�^���s��
  TYPE g_total_invoice_qty_ttype             IS TABLE OF xxcos_edi_headers.total_invoice_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �g�[�^���`�[����
  TYPE g_chain_pecul_area_foot_ttype         IS TABLE OF xxcos_edi_headers.chain_peculiar_area_footer%TYPE
    INDEX BY PLS_INTEGER;     -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
  TYPE g_conv_customer_code_ttype            IS TABLE OF xxcos_edi_headers.conv_customer_code%TYPE
    INDEX BY PLS_INTEGER;     -- �ϊ���ڋq�R�[�h
  TYPE g_order_forward_flag_ttype            IS TABLE OF xxcos_edi_headers.order_forward_flag%TYPE
    INDEX BY PLS_INTEGER;     -- �󒍘A�g�σt���O
  TYPE g_creation_class_ttype                IS TABLE OF xxcos_edi_headers.creation_class%TYPE
    INDEX BY PLS_INTEGER;     -- �쐬���敪
  TYPE g_edi_delivery_sche_flag_ttype        IS TABLE OF xxcos_edi_headers.edi_delivery_schedule_flag%TYPE
    INDEX BY PLS_INTEGER;     -- EDI�[�i�\�著�M�σt���O
  TYPE g_price_list_header_id_ttype          IS TABLE OF xxcos_edi_headers.price_list_header_id%TYPE
    INDEX BY PLS_INTEGER;     -- ���i�\�w�b�_ID
-- 2009/12/28 M.Sano Ver.1.14 add Start
  TYPE g_tsukagatazaiko_div_ttype            IS TABLE OF xxcos_edi_headers.tsukagatazaiko_div%TYPE
    INDEX BY PLS_INTEGER;     -- �ʉߍ݌Ɍ^�敪
-- 2009/12/28 M.Sano Ver.1.14 add End
-- 2010/01/19 Ver.1.15 M.Sano add Start
  TYPE g_edi_received_date_ttype             IS TABLE OF xxcos_edi_headers.edi_received_date%TYPE
    INDEX BY PLS_INTEGER;     -- EDI��M��
-- 2010/01/19 Ver.1.15 M.Sano add End
--
  -- EDI���׏��e�[�u�� �e�[�u���^�C�v��`
  TYPE g_edi_lines_ttype                     IS TABLE OF xxcos_edi_lines%ROWTYPE
    INDEX BY PLS_INTEGER;     -- EDI�w�b�_���e�[�u��
--
  -- EDI���׏��e�[�u�� �e�[�u���^�C�v��`
  TYPE g_edi_line_info_id_ttype              IS TABLE OF xxcos_edi_lines.edi_line_info_id%TYPE
    INDEX BY PLS_INTEGER;     -- EDI���׏��ID
  TYPE g_edi_line_head_info_id_ttype         IS TABLE OF xxcos_edi_lines.edi_header_info_id%TYPE
    INDEX BY PLS_INTEGER;     -- EDI�w�b�_���ID
  TYPE g_line_no_ttype                       IS TABLE OF xxcos_edi_lines.line_no%TYPE
    INDEX BY PLS_INTEGER;     -- �s�m��
  TYPE g_stockout_class_ttype                IS TABLE OF xxcos_edi_lines.stockout_class%TYPE
    INDEX BY PLS_INTEGER;     -- ���i�敪
  TYPE g_stockout_reason_ttype               IS TABLE OF xxcos_edi_lines.stockout_reason%TYPE
    INDEX BY PLS_INTEGER;     -- ���i���R
  TYPE g_product_code_itouen_ttype           IS TABLE OF xxcos_edi_lines.product_code_itouen%TYPE
    INDEX BY PLS_INTEGER;     -- ���i�R�[�h�i�ɓ����j
  TYPE g_product_code1_ttype                 IS TABLE OF xxcos_edi_lines.product_code1%TYPE
    INDEX BY PLS_INTEGER;     -- ���i�R�[�h�P
  TYPE g_product_code2_ttype                 IS TABLE OF xxcos_edi_lines.product_code2%TYPE
    INDEX BY PLS_INTEGER;     -- ���i�R�[�h�Q
  TYPE g_jan_code_ttype                      IS TABLE OF xxcos_edi_lines.jan_code%TYPE
    INDEX BY PLS_INTEGER;     -- �i�`�m�R�[�h
  TYPE g_itf_code_ttype                      IS TABLE OF xxcos_edi_lines.itf_code%TYPE
    INDEX BY PLS_INTEGER;     -- �h�s�e�R�[�h
  TYPE g_extension_itf_code_ttype            IS TABLE OF xxcos_edi_lines.extension_itf_code%TYPE
    INDEX BY PLS_INTEGER;     -- �����h�s�e�R�[�h
  TYPE g_case_product_code_ttype             IS TABLE OF xxcos_edi_lines.case_product_code%TYPE
    INDEX BY PLS_INTEGER;     -- �P�[�X���i�R�[�h
  TYPE g_ball_product_code_ttype             IS TABLE OF xxcos_edi_lines.ball_product_code%TYPE
    INDEX BY PLS_INTEGER;     -- �{�[�����i�R�[�h
  TYPE g_product_code_item_type_ttype        IS TABLE OF xxcos_edi_lines.product_code_item_type%TYPE
    INDEX BY PLS_INTEGER;     -- ���i�R�[�h�i��
  TYPE g_prod_class_ttype                    IS TABLE OF xxcos_edi_lines.prod_class%TYPE
    INDEX BY PLS_INTEGER;     -- ���i�敪
  TYPE g_product_name_ttype                  IS TABLE OF xxcos_edi_lines.product_name%TYPE
    INDEX BY PLS_INTEGER;     -- ���i���i�����j
  TYPE g_product_name1_alt_ttype             IS TABLE OF xxcos_edi_lines.product_name1_alt%TYPE
    INDEX BY PLS_INTEGER;     -- ���i���P�i�J�i�j
  TYPE g_product_name2_alt_ttype             IS TABLE OF xxcos_edi_lines.product_name2_alt%TYPE
    INDEX BY PLS_INTEGER;     -- ���i���Q�i�J�i�j
  TYPE g_item_standard1_ttype                IS TABLE OF xxcos_edi_lines.item_standard1%TYPE
    INDEX BY PLS_INTEGER;     -- �K�i�P
  TYPE g_item_standard2_ttype                IS TABLE OF xxcos_edi_lines.item_standard2%TYPE
    INDEX BY PLS_INTEGER;     -- �K�i�Q
  TYPE g_qty_in_case_ttype                   IS TABLE OF xxcos_edi_lines.qty_in_case%TYPE
    INDEX BY PLS_INTEGER;     -- ����
  TYPE g_num_of_cases_ttype                  IS TABLE OF xxcos_edi_lines.num_of_cases%TYPE
    INDEX BY PLS_INTEGER;     -- �P�[�X����
  TYPE g_num_of_ball_ttype                   IS TABLE OF xxcos_edi_lines.num_of_ball%TYPE
    INDEX BY PLS_INTEGER;     -- �{�[������
  TYPE g_item_color_ttype                    IS TABLE OF xxcos_edi_lines.item_color%TYPE
    INDEX BY PLS_INTEGER;     -- �F
  TYPE g_item_size_ttype                     IS TABLE OF xxcos_edi_lines.item_size%TYPE
    INDEX BY PLS_INTEGER;     -- �T�C�Y
  TYPE g_expiration_date_ttype               IS TABLE OF xxcos_edi_lines.expiration_date%TYPE
    INDEX BY PLS_INTEGER;     -- �ܖ�������
  TYPE g_product_date_ttype                  IS TABLE OF xxcos_edi_lines.product_date%TYPE
    INDEX BY PLS_INTEGER;     -- ������
  TYPE g_order_uom_qty_ttype                 IS TABLE OF xxcos_edi_lines.order_uom_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �����P�ʐ�
  TYPE g_shipping_uom_qty_ttype              IS TABLE OF xxcos_edi_lines.shipping_uom_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �o�גP�ʐ�
  TYPE g_packing_uom_qty_ttype               IS TABLE OF xxcos_edi_lines.packing_uom_qty%TYPE
    INDEX BY PLS_INTEGER;     -- ����P�ʐ�
  TYPE g_deal_code_ttype                     IS TABLE OF xxcos_edi_lines.deal_code%TYPE
    INDEX BY PLS_INTEGER;     -- ����
  TYPE g_deal_class_ttype                    IS TABLE OF xxcos_edi_lines.deal_class%TYPE
    INDEX BY PLS_INTEGER;     -- �����敪
  TYPE g_collation_code_ttype                IS TABLE OF xxcos_edi_lines.collation_code%TYPE
    INDEX BY PLS_INTEGER;     -- �ƍ�
  TYPE g_uom_code_ttype                      IS TABLE OF xxcos_edi_lines.uom_code%TYPE
    INDEX BY PLS_INTEGER;     -- �P��
  TYPE g_unit_price_class_ttype              IS TABLE OF xxcos_edi_lines.unit_price_class%TYPE
    INDEX BY PLS_INTEGER;     -- �P���敪
  TYPE g_parent_packing_number_ttype         IS TABLE OF xxcos_edi_lines.parent_packing_number%TYPE
    INDEX BY PLS_INTEGER;     -- �e����ԍ�
  TYPE g_packing_number_ttype                IS TABLE OF xxcos_edi_lines.packing_number%TYPE
    INDEX BY PLS_INTEGER;     -- ����ԍ�
  TYPE g_product_group_code_ttype            IS TABLE OF xxcos_edi_lines.product_group_code%TYPE
    INDEX BY PLS_INTEGER;     -- ���i�Q�R�[�h
  TYPE g_case_dismantle_flag_ttype           IS TABLE OF xxcos_edi_lines.case_dismantle_flag%TYPE
    INDEX BY PLS_INTEGER;     -- �P�[�X��̕s�t���O
  TYPE g_case_class_ttype                    IS TABLE OF xxcos_edi_lines.case_class%TYPE
    INDEX BY PLS_INTEGER;     -- �P�[�X�敪
  TYPE g_indv_order_qty_ttype                IS TABLE OF xxcos_edi_lines.indv_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �������ʁi�o���j
  TYPE g_case_order_qty_ttype                IS TABLE OF xxcos_edi_lines.case_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �������ʁi�P�[�X�j
  TYPE g_ball_order_qty_ttype                IS TABLE OF xxcos_edi_lines.ball_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �������ʁi�{�[���j
  TYPE g_sum_order_qty_ttype                 IS TABLE OF xxcos_edi_lines.sum_order_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �������ʁi���v�A�o���j
  TYPE g_indv_shipping_qty_ttype             IS TABLE OF xxcos_edi_lines.indv_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �o�א��ʁi�o���j
  TYPE g_case_shipping_qty_ttype             IS TABLE OF xxcos_edi_lines.case_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �o�א��ʁi�P�[�X�j
  TYPE g_ball_shipping_qty_ttype             IS TABLE OF xxcos_edi_lines.ball_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �o�א��ʁi�{�[���j
  TYPE g_pallet_shipping_qty_ttype           IS TABLE OF xxcos_edi_lines.pallet_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �o�א��ʁi�p���b�g�j
  TYPE g_sum_shipping_qty_ttype              IS TABLE OF xxcos_edi_lines.sum_shipping_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �o�א��ʁi���v�A�o���j
  TYPE g_indv_stockout_qty_ttype             IS TABLE OF xxcos_edi_lines.indv_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- ���i���ʁi�o���j
  TYPE g_case_stockout_qty_ttype             IS TABLE OF xxcos_edi_lines.case_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- ���i���ʁi�P�[�X�j
  TYPE g_ball_stockout_qty_ttype             IS TABLE OF xxcos_edi_lines.ball_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- ���i���ʁi�{�[���j
  TYPE g_sum_stockout_qty_ttype              IS TABLE OF xxcos_edi_lines.sum_stockout_qty%TYPE
    INDEX BY PLS_INTEGER;     -- ���i���ʁi���v�A�o���j
  TYPE g_case_qty_ttype                      IS TABLE OF xxcos_edi_lines.case_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �P�[�X����
  TYPE g_fold_contain_indv_qty_ttype         IS TABLE OF xxcos_edi_lines.fold_container_indv_qty%TYPE
    INDEX BY PLS_INTEGER;     -- �I���R���i�o���j����
  TYPE g_order_unit_price_ttype              IS TABLE OF xxcos_edi_lines.order_unit_price%TYPE
    INDEX BY PLS_INTEGER;     -- ���P���i�����j
  TYPE g_shipping_unit_price_ttype           IS TABLE OF xxcos_edi_lines.shipping_unit_price%TYPE
    INDEX BY PLS_INTEGER;     -- ���P���i�o�ׁj
  TYPE g_order_cost_amt_ttype                IS TABLE OF xxcos_edi_lines.order_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �������z�i�����j
  TYPE g_shipping_cost_amt_ttype             IS TABLE OF xxcos_edi_lines.shipping_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �������z�i�o�ׁj
  TYPE g_stockout_cost_amt_ttype             IS TABLE OF xxcos_edi_lines.stockout_cost_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �������z�i���i�j
  TYPE g_selling_price_ttype                 IS TABLE OF xxcos_edi_lines.selling_price%TYPE
    INDEX BY PLS_INTEGER;     -- ���P��
  TYPE g_order_price_amt_ttype               IS TABLE OF xxcos_edi_lines.order_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �������z�i�����j
  TYPE g_shipping_price_amt_ttype            IS TABLE OF xxcos_edi_lines.shipping_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �������z�i�o�ׁj
  TYPE g_stockout_price_amt_ttype            IS TABLE OF xxcos_edi_lines.stockout_price_amt%TYPE
    INDEX BY PLS_INTEGER;     -- �������z�i���i�j
  TYPE g_a_column_department_ttype           IS TABLE OF xxcos_edi_lines.a_column_department%TYPE
    INDEX BY PLS_INTEGER;     -- �`���i�S�ݓX�j
  TYPE g_d_column_department_ttype           IS TABLE OF xxcos_edi_lines.d_column_department%TYPE
    INDEX BY PLS_INTEGER;     -- �c���i�S�ݓX�j
  TYPE g_standard_info_depth_ttype           IS TABLE OF xxcos_edi_lines.standard_info_depth%TYPE
    INDEX BY PLS_INTEGER;     -- �K�i���E���s��
  TYPE g_standard_info_height_ttype          IS TABLE OF xxcos_edi_lines.standard_info_height%TYPE
    INDEX BY PLS_INTEGER;     -- �K�i���E����
  TYPE g_standard_info_width_ttype           IS TABLE OF xxcos_edi_lines.standard_info_width%TYPE
    INDEX BY PLS_INTEGER;     -- �K�i���E��
  TYPE g_standard_info_weight_ttype          IS TABLE OF xxcos_edi_lines.standard_info_weight%TYPE
    INDEX BY PLS_INTEGER;     -- �K�i���E�d��
  TYPE g_general_succeed_item1_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item1%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���p�����ڂP
  TYPE g_general_succeed_item2_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item2%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���p�����ڂQ
  TYPE g_general_succeed_item3_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item3%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���p�����ڂR
  TYPE g_general_succeed_item4_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item4%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���p�����ڂS
  TYPE g_general_succeed_item5_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item5%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���p�����ڂT
  TYPE g_general_succeed_item6_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item6%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���p�����ڂU
  TYPE g_general_succeed_item7_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item7%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���p�����ڂV
  TYPE g_general_succeed_item8_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item8%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���p�����ڂW
  TYPE g_general_succeed_item9_ttype         IS TABLE OF xxcos_edi_lines.general_succeeded_item9%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���p�����ڂX
  TYPE g_general_succeed_item10_ttype        IS TABLE OF xxcos_edi_lines.general_succeeded_item10%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp���p�����ڂP�O
  TYPE g_general_add_item1_ttype             IS TABLE OF xxcos_edi_lines.general_add_item1%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp�t�����ڂP
  TYPE g_general_add_item2_ttype             IS TABLE OF xxcos_edi_lines.general_add_item2%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp�t�����ڂQ
  TYPE g_general_add_item3_ttype             IS TABLE OF xxcos_edi_lines.general_add_item3%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp�t�����ڂR
  TYPE g_general_add_item4_ttype             IS TABLE OF xxcos_edi_lines.general_add_item4%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp�t�����ڂS
  TYPE g_general_add_item5_ttype             IS TABLE OF xxcos_edi_lines.general_add_item5%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp�t�����ڂT
  TYPE g_general_add_item6_ttype             IS TABLE OF xxcos_edi_lines.general_add_item6%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp�t�����ڂU
  TYPE g_general_add_item7_ttype             IS TABLE OF xxcos_edi_lines.general_add_item7%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp�t�����ڂV
  TYPE g_general_add_item8_ttype             IS TABLE OF xxcos_edi_lines.general_add_item8%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp�t�����ڂW
  TYPE g_general_add_item9_ttype             IS TABLE OF xxcos_edi_lines.general_add_item9%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp�t�����ڂX
  TYPE g_general_add_item10_ttype            IS TABLE OF xxcos_edi_lines.general_add_item10%TYPE
    INDEX BY PLS_INTEGER;     -- �ėp�t�����ڂP�O
  TYPE g_chain_pecul_area_line_ttype         IS TABLE OF xxcos_edi_lines.chain_peculiar_area_line%TYPE
    INDEX BY PLS_INTEGER;     -- �`�F�[���X�ŗL�G���A�i���ׁj
  TYPE g_item_code_ttype                     IS TABLE OF xxcos_edi_lines.item_code%TYPE
    INDEX BY PLS_INTEGER;     -- �i�ڃR�[�h
  TYPE g_line_uom_ttype                      IS TABLE OF xxcos_edi_lines.line_uom%TYPE
    INDEX BY PLS_INTEGER;     -- ���גP��
  TYPE g_hht_delivery_sche_flag_ttype        IS TABLE OF xxcos_edi_lines.hht_delivery_schedule_flag%TYPE
    INDEX BY PLS_INTEGER;     -- HHT�[�i�\��A�g�σt���O
  TYPE g_order_connect_line_num_ttype        IS TABLE OF xxcos_edi_lines.order_connection_line_number%TYPE
    INDEX BY PLS_INTEGER;     -- �󒍊֘A���הԍ�
--
  -- EDI�G���[���e�[�u�� �e�[�u���^�C�v��`
  TYPE g_edi_errors_ttype                    IS TABLE OF xxcos_edi_errors%ROWTYPE
    INDEX BY PLS_INTEGER;     -- EDI�G���[���e�[�u��
--
  -- EDI�i�ڃG���[�^�C�v��`
  TYPE g_edi_item_err_type_ttype             IS TABLE OF VARCHAR2(20) INDEX BY VARCHAR2(1);
--
-- 2009/12/28 M.Sano Ver.1.14 add Start
  -- �ʉߍ݌Ɍ^�敪�^�C�v��`
  TYPE g_lookup_tsukagata_div_ttype     IS TABLE OF xxcmm_cust_accounts.tsukagatazaiko_div%TYPE
    INDEX BY xxcmm_cust_accounts.tsukagatazaiko_div%TYPE;
--
-- 2009/12/28 M.Sano Ver.1.14 add End
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_purge_term                              fnd_profile_option_values.profile_option_value%TYPE;   -- EDI���폜����
-- 2010/01/19 Ver.1.15 M.Sano add Start
  gv_err_purge_term                          fnd_profile_option_values.profile_option_value%TYPE;   -- EDI�G���[���ێ�����
-- 2010/01/19 Ver.1.15 M.Sano add End
  gv_case_uom_code                           fnd_profile_option_values.profile_option_value%TYPE;   -- �P�[�X�P�ʃR�[�h
  gn_organization_id                         NUMBER;                                                -- �݌ɑg�DID
  gn_org_unit_id                             NUMBER;                                                -- �c�ƒP��
  gv_creation_class                          fnd_lookup_values.meaning%TYPE;                        -- �쐬���敪
--
  -- �`�[�G���[�t���O�ϐ�
  gn_invoice_err_flag                        NUMBER(1) := 0;
-- 2009/06/29 M.Sano Ver.1.6 add Start
  -- �����Ώۃ��R�[�h�̃`�F�b�N��������t���O�ϐ�
  gn_check_record_flag                       NUMBER(1); 
-- 2009/06/29 M.Sano Ver.1.6 add End

--
  -- EDI�󒍏�񃏁[�N�e�[�u���p�ϐ��i�J�[�\�����R�[�h�^�j
  gt_edi_order_work                          g_edi_order_work_ttype;
--
  -- EDI�󒍏�񃏁[�N�e�[�u���p�ϐ�
  gt_order_info_work_id                      g_order_info_work_id_ttype;
  gt_edi_err_status                          g_edi_err_status_ttype;
--
  -- �`�[�ʍ��v�ϐ�
  gt_inv_total                               g_inv_total_rtype;
--
  -- EDI�󒍏�񃏁[�N�e�[�u���ϐ�
  gt_edi_work                                g_edi_work_ttype;
--
  -- EDI�w�b�_���C���T�[�g�p�ϐ�
  gt_edi_headers                             g_edi_headers_ttype;               -- EDI�w�b�_���e�[�u��
--
  -- EDI�w�b�_���A�b�v�f�[�g�p�ϐ�
  gt_upd_edi_header_info_id                  g_edi_header_info_id_ttype;        -- EDI�w�b�_���ID
  gt_upd_medium_class                        g_medium_class_ttype;              -- �}�̋敪
  gt_upd_data_type_code                      g_data_type_code_ttype;            -- �f�[�^��R�[�h
  gt_upd_file_no                             g_file_no_ttype;                   -- �t�@�C���m��
  gt_upd_info_class                          g_info_class_ttype;                -- ���敪
  gt_upd_process_date                        g_process_date_ttype;              -- ������
  gt_upd_process_time                        g_process_time_ttype;              -- ��������
  gt_upd_base_code                           g_base_code_ttype;                 -- ���_�i����j�R�[�h
  gt_upd_base_name                           g_base_name_ttype;                 -- ���_���i�������j
  gt_upd_base_name_alt                       g_base_name_alt_ttype;             -- ���_���i�J�i�j
  gt_upd_edi_chain_code                      g_edi_chain_code_ttype;            -- �d�c�h�`�F�[���X�R�[�h
  gt_upd_edi_chain_name                      g_edi_chain_name_ttype;            -- �d�c�h�`�F�[���X���i�����j
  gt_upd_edi_chain_name_alt                  g_edi_chain_name_alt_ttype;        -- �d�c�h�`�F�[���X���i�J�i�j
  gt_upd_chain_code                          g_chain_code_ttype;                -- �`�F�[���X�R�[�h
  gt_upd_chain_name                          g_chain_name_ttype;                -- �`�F�[���X���i�����j
  gt_upd_chain_name_alt                      g_chain_name_alt_ttype;            -- �`�F�[���X���i�J�i�j
  gt_upd_report_code                         g_report_code_ttype;               -- ���[�R�[�h
  gt_upd_report_show_name                    g_report_show_name_ttype;          -- ���[�\����
  gt_upd_customer_code                       g_customer_code_ttype;             -- �ڋq�R�[�h
  gt_upd_customer_name                       g_customer_name_ttype;             -- �ڋq���i�����j
  gt_upd_customer_name_alt                   g_customer_name_alt_ttype;         -- �ڋq���i�J�i�j
  gt_upd_company_code                        g_company_code_ttype;              -- �ЃR�[�h
  gt_upd_company_name                        g_company_name_ttype;              -- �Ж��i�����j
  gt_upd_company_name_alt                    g_company_name_alt_ttype;          -- �Ж��i�J�i�j
  gt_upd_shop_code                           g_shop_code_ttype;                 -- �X�R�[�h
  gt_upd_shop_name                           g_shop_name_ttype;                 -- �X���i�����j
  gt_upd_shop_name_alt                       g_shop_name_alt_ttype;             -- �X���i�J�i�j
  gt_upd_delivery_cent_cd                    g_delivery_center_cd_ttype;        -- �[���Z���^�[�R�[�h
  gt_upd_delivery_cent_nm                    g_delivery_center_nm_ttype;        -- �[���Z���^�[���i�����j
  gt_upd_delivery_cent_nm_alt                g_delivery_center_nm_alt_ttype;    -- �[���Z���^�[���i�J�i�j
  gt_upd_order_date                          g_order_date_ttype;                -- ������
  gt_upd_center_delivery_date                g_center_delivery_date_ttype;      -- �Z���^�[�[�i��
  gt_upd_result_delivery_date                g_result_delivery_date_ttype;      -- ���[�i��
  gt_upd_shop_delivery_date                  g_shop_delivery_date_ttype;        -- �X�ܔ[�i��
  gt_upd_data_creation_date_edi              g_data_creation_date_edi_ttype;    -- �f�[�^�쐬���i�d�c�h�f�[�^���j
  gt_upd_data_creation_time_edi              g_data_creation_time_edi_ttype;    -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
  gt_upd_invoice_class                       g_invoice_class_ttype;             -- �`�[�敪
  gt_upd_small_class_cd                      g_small_class_code_ttype;          -- �����ރR�[�h
  gt_upd_small_class_nm                      g_small_class_name_ttype;          -- �����ޖ�
  gt_upd_middle_class_cd                     g_middle_class_code_ttype;         -- �����ރR�[�h
  gt_upd_middle_class_nm                     g_middle_class_name_ttype;         -- �����ޖ�
  gt_upd_big_class_cd                        g_big_class_code_ttype;            -- �啪�ރR�[�h
  gt_upd_big_class_nm                        g_big_class_name_ttype;            -- �啪�ޖ�
  gt_upd_other_party_depart_cd               g_other_party_depart_cd_ttype;     -- ����敔��R�[�h
  gt_upd_other_party_order_num               g_other_party_order_num_ttype;     -- ����攭���ԍ�
  gt_upd_check_digit_class                   g_check_digit_class_ttype;         -- �`�F�b�N�f�W�b�g�L���敪
  gt_upd_invoice_number                      g_invoice_number_ttype;            -- �`�[�ԍ�
  gt_upd_check_digit                         g_check_digit_ttype;               -- �`�F�b�N�f�W�b�g
  gt_upd_close_date                          g_close_date_ttype;                -- ����
  gt_upd_order_no_ebs                        g_order_no_ebs_ttype;              -- �󒍂m���i�d�a�r�j
  gt_upd_ar_sale_class                       g_ar_sale_class_ttype;             -- �����敪
  gt_upd_delivery_classe                     g_delivery_classe_ttype;           -- �z���敪
  gt_upd_opportunity_no                      g_opportunity_no_ttype;            -- �ւm��
  gt_upd_contact_to                          g_contact_to_ttype;                -- �A����
  gt_upd_route_sales                         g_route_sales_ttype;               -- ���[�g�Z�[���X
  gt_upd_corporate_code                      g_corporate_code_ttype;            -- �@�l�R�[�h
  gt_upd_maker_name                          g_maker_name_ttype;                -- ���[�J�[��
  gt_upd_area_code                           g_area_code_ttype;                 -- �n��R�[�h
  gt_upd_area_name                           g_area_name_ttype;                 -- �n�於�i�����j
  gt_upd_area_name_alt                       g_area_name_alt_ttype;             -- �n�於�i�J�i�j
  gt_upd_vendor_code                         g_vendor_code_ttype;               -- �����R�[�h
  gt_upd_vendor_name                         g_vendor_name_ttype;               -- ����於�i�����j
  gt_upd_vendor_name1_alt                    g_vendor_name1_alt_ttype;          -- ����於�P�i�J�i�j
  gt_upd_vendor_name2_alt                    g_vendor_name2_alt_ttype;          -- ����於�Q�i�J�i�j
  gt_upd_vendor_tel                          g_vendor_tel_ttype;                -- �����s�d�k
  gt_upd_vendor_charge                       g_vendor_charge_ttype;             -- �����S����
  gt_upd_vendor_address                      g_vendor_address_ttype;            -- �����Z���i�����j
  gt_upd_deliver_to_code_itouen              g_deliver_to_code_itouen_ttype;    -- �͂���R�[�h�i�ɓ����j
  gt_upd_deliver_to_code_chain               g_deliver_to_code_chain_ttype;     -- �͂���R�[�h�i�`�F�[���X�j
  gt_upd_deliver_to                          g_deliver_to_ttype;                -- �͂���i�����j
  gt_upd_deliver_to1_alt                     g_deliver_to1_alt_ttype;           -- �͂���P�i�J�i�j
  gt_upd_deliver_to2_alt                     g_deliver_to2_alt_ttype;           -- �͂���Q�i�J�i�j
  gt_upd_deliver_to_address                  g_deliver_to_address_ttype;        -- �͂���Z���i�����j
  gt_upd_deliver_to_address_alt              g_deliver_to_address_alt_ttype;    -- �͂���Z���i�J�i�j
  gt_upd_deliver_to_tel                      g_deliver_to_tel_ttype;            -- �͂���s�d�k
  gt_upd_balance_acct_cd                     g_balance_acct_cd_ttype;           -- ������R�[�h
  gt_upd_balance_acct_company_cd             g_balance_acct_comp_cd_ttype;      -- ������ЃR�[�h
  gt_upd_balance_acct_shop_cd                g_balance_acct_shop_cd_ttype;      -- ������X�R�[�h
  gt_upd_balance_acct_nm                     g_balance_acct_nm_ttype;           -- �����於�i�����j
  gt_upd_balance_acct_nm_alt                 g_balance_acct_nm_alt_ttype;       -- �����於�i�J�i�j
  gt_upd_balance_acct_addr                   g_balance_acct_address_ttype;      -- ������Z���i�����j
  gt_upd_balance_acct_addr_alt               g_balance_acct_addr_alt_ttype;     -- ������Z���i�J�i�j
  gt_upd_balance_acct_tel                    g_balance_acct_tel_ttype;          -- ������s�d�k
  gt_upd_order_possible_date                 g_order_possible_date_ttype;       -- �󒍉\��
  gt_upd_permit_possible_date                g_permit_possible_date_ttype;      -- ���e�\��
  gt_upd_forward_month                       g_forward_month_ttype;             -- ����N����
  gt_upd_payment_settlement_date             g_payment_settle_date_ttype;       -- �x�����ϓ�
  gt_upd_handbill_start_date_act             g_handbill_st_date_act_ttype;      -- �`���V�J�n��
  gt_upd_billing_due_date                    g_billing_due_date_ttype;          -- ��������
  gt_upd_shipping_time                       g_shipping_time_ttype;             -- �o�׎���
  gt_upd_delivery_schedule_time              g_delivery_schedule_time_ttype;    -- �[�i�\�莞��
  gt_upd_order_time                          g_order_time_ttype;                -- ��������
  gt_upd_general_date_item1                  g_general_date_item1_ttype;        -- �ėp���t���ڂP
  gt_upd_general_date_item2                  g_general_date_item2_ttype;        -- �ėp���t���ڂQ
  gt_upd_general_date_item3                  g_general_date_item3_ttype;        -- �ėp���t���ڂR
  gt_upd_general_date_item4                  g_general_date_item4_ttype;        -- �ėp���t���ڂS
  gt_upd_general_date_item5                  g_general_date_item5_ttype;        -- �ėp���t���ڂT
  gt_upd_arrival_shipping_class              g_arrival_shipping_class_ttype;    -- ���o�׋敪
  gt_upd_vendor_class                        g_vendor_class_ttype;              -- �����敪
  gt_upd_invoice_detailed_class              g_invoice_detailed_class_ttype;    -- �`�[����敪
  gt_upd_unit_price_use_class                g_unit_price_use_class_ttype;      -- �P���g�p�敪
  gt_upd_sub_dist_center_cd                  g_sub_dist_center_cd_ttype;        -- �T�u�����Z���^�[�R�[�h
  gt_upd_sub_dist_center_nm                  g_sub_dist_center_nm_ttype;        -- �T�u�����Z���^�[�R�[�h��
  gt_upd_center_delivery_method              g_center_delivery_method_ttype;    -- �Z���^�[�[�i���@
  gt_upd_center_use_class                    g_center_use_class_ttype;          -- �Z���^�[���p�敪
  gt_upd_center_whse_class                   g_center_whse_class_ttype;         -- �Z���^�[�q�ɋ敪
  gt_upd_center_area_class                   g_center_area_class_ttype;         -- �Z���^�[�n��敪
  gt_upd_center_arrival_class                g_center_arrival_class_ttype;      -- �Z���^�[���׋敪
  gt_upd_depot_class                         g_depot_class_ttype;               -- �f�|�敪
  gt_upd_tcdc_class                          g_tcdc_class_ttype;                -- �s�b�c�b�敪
  gt_upd_upc_flag                            g_upc_flag_ttype;                  -- �t�o�b�t���O
  gt_upd_simultaneously_class                g_simultaneously_class_ttype;      -- ��ċ敪
  gt_upd_business_id                         g_business_id_ttype;               -- �Ɩ��h�c
  gt_upd_whse_directly_class                 g_whse_directly_class_ttype;       -- �q���敪
  gt_upd_premium_rebate_class                g_premium_rebate_class_ttype;      -- �i�i���ߋ敪
  gt_upd_item_type                           g_item_type_ttype;                 -- ���ڎ��
  gt_upd_cloth_house_food_class              g_cloth_house_food_class_ttype;    -- �߉ƐH�敪
  gt_upd_mix_class                           g_mix_class_ttype;                 -- ���݋敪
  gt_upd_stk_class                           g_stk_class_ttype;                 -- �݌ɋ敪
  gt_upd_last_modify_site_class              g_last_modify_site_class_ttype;    -- �ŏI�C���ꏊ�敪
  gt_upd_report_class                        g_report_class_ttype;              -- ���[�敪
  gt_upd_addition_plan_class                 g_addition_plan_class_ttype;       -- �ǉ��E�v��敪
  gt_upd_registration_class                  g_registration_class_ttype;        -- �o�^�敪
  gt_upd_specific_class                      g_specific_class_ttype;            -- ����敪
  gt_upd_dealings_class                      g_dealings_class_ttype;            -- ����敪
  gt_upd_order_class                         g_order_class_ttype;               -- �����敪
  gt_upd_sum_line_class                      g_sum_line_class_ttype;            -- �W�v���׋敪
  gt_upd_shipping_guidance_class             g_shipping_guide_class_ttype;      -- �o�׈ē��ȊO�敪
  gt_upd_shipping_class                      g_shipping_class_ttype;            -- �o�׋敪
  gt_upd_product_code_use_class              g_product_code_use_class_ttype;    -- ���i�R�[�h�g�p�敪
  gt_upd_cargo_item_class                    g_cargo_item_class_ttype;          -- �ϑ��i�敪
  gt_upd_ta_class                            g_ta_class_ttype;                  -- �s�^�`�敪
  gt_upd_plan_code                           g_plan_code_ttype;                 -- ���R�[�h
  gt_upd_category_code                       g_category_code_ttype;             -- �J�e�S���[�R�[�h
  gt_upd_category_class                      g_category_class_ttype;            -- �J�e�S���[�敪
  gt_upd_carrier_means                       g_carrier_means_ttype;             -- �^����i
  gt_upd_counter_code                        g_counter_code_ttype;              -- ����R�[�h
  gt_upd_move_sign                           g_move_sign_ttype;                 -- �ړ��T�C��
  gt_upd_eos_handwriting_class               g_eos_handwriting_class_ttype;     -- �d�n�r�E�菑�敪
  gt_upd_delivery_to_sect_cd                 g_delivery_to_section_cd_ttype;    -- �[�i��ۃR�[�h
  gt_upd_invoice_detailed                    g_invoice_detailed_ttype;          -- �`�[����
  gt_upd_attach_qty                          g_attach_qty_ttype;                -- �Y�t��
  gt_upd_other_party_floor                   g_other_party_floor_ttype;         -- �t���A
  gt_upd_text_no                             g_text_no_ttype;                   -- �s�d�w�s�m��
  gt_upd_in_store_code                       g_in_store_code_ttype;             -- �C���X�g�A�R�[�h
  gt_upd_tag_data                            g_tag_data_ttype;                  -- �^�O
  gt_upd_competition_code                    g_competition_code_ttype;          -- ����
  gt_upd_billing_chair                       g_billing_chair_ttype;             -- ��������
  gt_upd_chain_store_code                    g_chain_store_code_ttype;          -- �`�F�[���X�g�A�[�R�[�h
  gt_upd_chain_store_short_name              g_chain_store_short_name_ttype;    -- �`�F�[���X�g�A�[�R�[�h��������
  gt_upd_dirct_delivery_rcpt_fee             g_direct_delive_rcpt_fee_ttype;    -- ���z���^���旿
  gt_upd_bill_info                           g_bill_info_ttype;                 -- ��`���
  gt_upd_description                         g_description_ttype;               -- �E�v
  gt_upd_interior_code                       g_interior_code_ttype;             -- �����R�[�h
  gt_upd_order_info_delivery_cat             g_order_info_delive_cat_ttype;     -- �������@�[�i�J�e�S���[
  gt_upd_purchase_type                       g_purchase_type_ttype;             -- �d���`��
  gt_upd_delivery_to_name_alt                g_delivery_to_name_alt_ttype;      -- �[�i�ꏊ���i�J�i�j
  gt_upd_shop_opened_site                    g_shop_opened_site_ttype;          -- �X�o�ꏊ
  gt_upd_counter_name                        g_counter_name_ttype;              -- ���ꖼ
  gt_upd_extension_number                    g_extension_number_ttype;          -- �����ԍ�
  gt_upd_charge_name                         g_charge_name_ttype;               -- �S���Җ�
  gt_upd_price_tag                           g_price_tag_ttype;                 -- �l�D
  gt_upd_tax_type                            g_tax_type_ttype;                  -- �Ŏ�
  gt_upd_consumption_tax_class               g_consumption_tax_class_ttype;     -- ����ŋ敪
  gt_upd_brand_class                         g_brand_class_ttype;               -- �a�q
  gt_upd_id_code                             g_id_code_ttype;                   -- �h�c�R�[�h
  gt_upd_department_code                     g_department_code_ttype;           -- �S�ݓX�R�[�h
  gt_upd_department_name                     g_department_name_ttype;           -- �S�ݓX��
  gt_upd_item_type_number                    g_item_type_number_ttype;          -- �i�ʔԍ�
  gt_upd_description_department              g_description_department_ttype;    -- �E�v�i�S�ݓX�j
  gt_upd_price_tag_method                    g_price_tag_method_ttype;          -- �l�D���@
  gt_upd_reason_column                       g_reason_column_ttype;             -- ���R��
  gt_upd_a_column_header                     g_a_column_header_ttype;           -- �`���w�b�_
  gt_upd_d_column_header                     g_d_column_header_ttype;           -- �c���w�b�_
  gt_upd_brand_code                          g_brand_code_ttype;                -- �u�����h�R�[�h
  gt_upd_line_code                           g_line_code_ttype;                 -- ���C���R�[�h
  gt_upd_class_code                          g_class_code_ttype;                -- �N���X�R�[�h
  gt_upd_a1_column                           g_a1_column_ttype;                 -- �`�|�P��
  gt_upd_b1_column                           g_b1_column_ttype;                 -- �a�|�P��
  gt_upd_c1_column                           g_c1_column_ttype;                 -- �b�|�P��
  gt_upd_d1_column                           g_d1_column_ttype;                 -- �c�|�P��
  gt_upd_e1_column                           g_e1_column_ttype;                 -- �d�|�P��
  gt_upd_a2_column                           g_a2_column_ttype;                 -- �`�|�Q��
  gt_upd_b2_column                           g_b2_column_ttype;                 -- �a�|�Q��
  gt_upd_c2_column                           g_c2_column_ttype;                 -- �b�|�Q��
  gt_upd_d2_column                           g_d2_column_ttype;                 -- �c�|�Q��
  gt_upd_e2_column                           g_e2_column_ttype;                 -- �d�|�Q��
  gt_upd_a3_column                           g_a3_column_ttype;                 -- �`�|�R��
  gt_upd_b3_column                           g_b3_column_ttype;                 -- �a�|�R��
  gt_upd_c3_column                           g_c3_column_ttype;                 -- �b�|�R��
  gt_upd_d3_column                           g_d3_column_ttype;                 -- �c�|�R��
  gt_upd_e3_column                           g_e3_column_ttype;                 -- �d�|�R��
  gt_upd_f1_column                           g_f1_column_ttype;                 -- �e�|�P��
  gt_upd_g1_column                           g_g1_column_ttype;                 -- �f�|�P��
  gt_upd_h1_column                           g_h1_column_ttype;                 -- �g�|�P��
  gt_upd_i1_column                           g_i1_column_ttype;                 -- �h�|�P��
  gt_upd_j1_column                           g_j1_column_ttype;                 -- �i�|�P��
  gt_upd_k1_column                           g_k1_column_ttype;                 -- �j�|�P��
  gt_upd_l1_column                           g_l1_column_ttype;                 -- �k�|�P��
  gt_upd_f2_column                           g_f2_column_ttype;                 -- �e�|�Q��
  gt_upd_g2_column                           g_g2_column_ttype;                 -- �f�|�Q��
  gt_upd_h2_column                           g_h2_column_ttype;                 -- �g�|�Q��
  gt_upd_i2_column                           g_i2_column_ttype;                 -- �h�|�Q��
  gt_upd_j2_column                           g_j2_column_ttype;                 -- �i�|�Q��
  gt_upd_k2_column                           g_k2_column_ttype;                 -- �j�|�Q��
  gt_upd_l2_column                           g_l2_column_ttype;                 -- �k�|�Q��
  gt_upd_f3_column                           g_f3_column_ttype;                 -- �e�|�R��
  gt_upd_g3_column                           g_g3_column_ttype;                 -- �f�|�R��
  gt_upd_h3_column                           g_h3_column_ttype;                 -- �g�|�R��
  gt_upd_i3_column                           g_i3_column_ttype;                 -- �h�|�R��
  gt_upd_j3_column                           g_j3_column_ttype;                 -- �i�|�R��
  gt_upd_k3_column                           g_k3_column_ttype;                 -- �j�|�R��
  gt_upd_l3_column                           g_l3_column_ttype;                 -- �k�|�R��
  gt_upd_chain_pecul_area_head               g_chain_pecul_area_head_ttype;     -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
  gt_upd_order_connection_num                g_order_connection_num_ttype;      -- �󒍊֘A�ԍ�
  gt_upd_inv_indv_order_qty                  g_inv_indv_order_qty_ttype;        -- �i�`�[�v�j�������ʁi�o���j
  gt_upd_inv_case_order_qty                  g_inv_case_order_qty_ttype;        -- �i�`�[�v�j�������ʁi�P�[�X�j
  gt_upd_inv_ball_order_qty                  g_inv_ball_order_qty_ttype;        -- �i�`�[�v�j�������ʁi�{�[���j
  gt_upd_inv_sum_order_qty                   g_inv_sum_order_qty_ttype;         -- �i�`�[�v�j�������ʁi���v�A�o���j
  gt_upd_inv_indv_shipping_qty               g_inv_indv_shipping_qty_ttype;     -- �i�`�[�v�j�o�א��ʁi�o���j
  gt_upd_inv_case_shipping_qty               g_inv_case_shipping_qty_ttype;     -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
  gt_upd_inv_ball_shipping_qty               g_inv_ball_shipping_qty_ttype;     -- �i�`�[�v�j�o�א��ʁi�{�[���j
  gt_upd_inv_pallet_shipping_qty             g_inv_plt_shipping_qty_ttype;      -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
  gt_upd_inv_sum_shipping_qty                g_inv_sum_shipping_qty_ttype;      -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
  gt_upd_inv_indv_stockout_qty               g_inv_indv_stockout_qty_ttype;     -- �i�`�[�v�j���i���ʁi�o���j
  gt_upd_inv_case_stockout_qty               g_inv_case_stockout_qty_ttype;     -- �i�`�[�v�j���i���ʁi�P�[�X�j
  gt_upd_inv_ball_stockout_qty               g_inv_ball_stockout_qty_ttype;     -- �i�`�[�v�j���i���ʁi�{�[���j
  gt_upd_inv_sum_stockout_qty                g_inv_sum_stockout_qty_ttype;      -- �i�`�[�v�j���i���ʁi���v�A�o���j
  gt_upd_inv_case_qty                        g_inv_case_qty_ttype;              -- �i�`�[�v�j�P�[�X����
  gt_upd_inv_fold_container_qty              g_inv_fold_container_qty_ttype;    -- �i�`�[�v�j�I���R���i�o���j����
  gt_upd_inv_order_cost_amt                  g_inv_order_cost_amt_ttype;        -- �i�`�[�v�j�������z�i�����j
  gt_upd_inv_shipping_cost_amt               g_inv_shipping_cost_amt_ttype;     -- �i�`�[�v�j�������z�i�o�ׁj
  gt_upd_inv_stockout_cost_amt               g_inv_stockout_cost_amt_ttype;     -- �i�`�[�v�j�������z�i���i�j
  gt_upd_inv_order_price_amt                 g_inv_order_price_amt_ttype;       -- �i�`�[�v�j�������z�i�����j
  gt_upd_inv_shipping_price_amt              g_inv_shipping_price_amt_ttype;    -- �i�`�[�v�j�������z�i�o�ׁj
  gt_upd_inv_stockout_price_amt              g_inv_stockout_price_amt_ttype;    -- �i�`�[�v�j�������z�i���i�j
  gt_upd_total_indv_order_qty                g_total_indv_order_qty_ttype;      -- �i�����v�j�������ʁi�o���j
  gt_upd_total_case_order_qty                g_total_case_order_qty_ttype;      -- �i�����v�j�������ʁi�P�[�X�j
  gt_upd_total_ball_order_qty                g_total_ball_order_qty_ttype;      -- �i�����v�j�������ʁi�{�[���j
  gt_upd_total_sum_order_qty                 g_total_sum_order_qty_ttype;       -- �i�����v�j�������ʁi���v�A�o���j
  gt_upd_total_indv_ship_qty                 g_total_indv_ship_qty_ttype;       -- �i�����v�j�o�א��ʁi�o���j
  gt_upd_total_case_ship_qty                 g_total_case_ship_qty_ttype;       -- �i�����v�j�o�א��ʁi�P�[�X�j
  gt_upd_total_ball_ship_qty                 g_total_ball_ship_qty_ttype;       -- �i�����v�j�o�א��ʁi�{�[���j
  gt_upd_total_pallet_ship_qty               g_total_pallet_ship_qty_ttype;     -- �i�����v�j�o�א��ʁi�p���b�g�j
  gt_upd_total_sum_ship_qty                  g_total_sum_ship_qty_ttype;        -- �i�����v�j�o�א��ʁi���v�A�o���j
  gt_upd_total_indv_stockout_qty             g_total_indv_stkout_qty_ttype;     -- �i�����v�j���i���ʁi�o���j
  gt_upd_total_case_stockout_qty             g_total_case_stkout_qty_ttype;     -- �i�����v�j���i���ʁi�P�[�X�j
  gt_upd_total_ball_stockout_qty             g_total_ball_stkout_qty_ttype;     -- �i�����v�j���i���ʁi�{�[���j
  gt_upd_total_sum_stockout_qty              g_total_sum_stkout_qty_ttype;      -- �i�����v�j���i���ʁi���v�A�o���j
  gt_upd_total_case_qty                      g_total_case_qty_ttype;            -- �i�����v�j�P�[�X����
  gt_upd_total_fold_contain_qty              g_total_fold_contain_qty_ttype;    -- �i�����v�j�I���R���i�o���j����
  gt_upd_total_order_cost_amt                g_total_order_cost_amt_ttype;      -- �i�����v�j�������z�i�����j
  gt_upd_total_shipping_cost_amt             g_total_ship_cost_amt_ttype;       -- �i�����v�j�������z�i�o�ׁj
  gt_upd_total_stockout_cost_amt             g_total_stkout_cost_amt_ttype;     -- �i�����v�j�������z�i���i�j
  gt_upd_total_order_price_amt               g_total_order_price_amt_ttype;     -- �i�����v�j�������z�i�����j
  gt_upd_total_ship_price_amt                g_total_ship_price_amt_ttype;      -- �i�����v�j�������z�i�o�ׁj
  gt_upd_total_stock_price_amt               g_total_stock_price_amt_ttype;     -- �i�����v�j�������z�i���i�j
  gt_upd_total_line_qty                      g_total_line_qty_ttype;            -- �g�[�^���s��
  gt_upd_total_invoice_qty                   g_total_invoice_qty_ttype;         -- �g�[�^���`�[����
  gt_upd_chain_pecul_area_foot               g_chain_pecul_area_foot_ttype;     -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
  gt_upd_conv_customer_code                  g_conv_customer_code_ttype;        -- �ϊ���ڋq�R�[�h
  gt_upd_order_forward_flag                  g_order_forward_flag_ttype;        -- �󒍘A�g�σt���O
  gt_upd_creation_class                      g_creation_class_ttype;            -- �쐬���敪
  gt_upd_edi_delivery_sche_flag              g_edi_delivery_sche_flag_ttype;    -- EDI�[�i�\�著�M�σt���O
  gt_upd_price_list_header_id                g_price_list_header_id_ttype;      -- ���i�\�w�b�_ID
-- 2009/12/28 M.Sano Ver.1.14 add Start
  gt_upd_tsukagatazaiko_div                  g_tsukagatazaiko_div_ttype;        -- �ʉߍ݌Ɍ^�敪
-- 2009/12/28 M.Sano Ver.1.14 add End
--
  --  EDI���׏��C���T�[�g�p�ϐ�
  gt_edi_lines                               g_edi_lines_ttype;                 -- EDI���׏��e�[�u��
--
  -- EDI���׏��A�b�v�f�[�g�p�ϐ�
  gt_upd_edi_line_info_id                    g_edi_line_info_id_ttype;          -- EDI���׏��ID
  gt_upd_edi_line_header_info_id             g_edi_line_head_info_id_ttype;     -- EDI�w�b�_���ID
  gt_upd_line_no                             g_line_no_ttype;                   -- �s�m��
  gt_upd_stockout_class                      g_stockout_class_ttype;            -- ���i�敪
  gt_upd_stockout_reason                     g_stockout_reason_ttype;           -- ���i���R
  gt_upd_product_code_itouen                 g_product_code_itouen_ttype;       -- ���i�R�[�h�i�ɓ����j
  gt_upd_product_code1                       g_product_code1_ttype;             -- ���i�R�[�h�P
  gt_upd_product_code2                       g_product_code2_ttype;             -- ���i�R�[�h�Q
  gt_upd_jan_code                            g_jan_code_ttype;                  -- �i�`�m�R�[�h
  gt_upd_itf_code                            g_itf_code_ttype;                  -- �h�s�e�R�[�h
  gt_upd_extension_itf_code                  g_extension_itf_code_ttype;        -- �����h�s�e�R�[�h
  gt_upd_case_product_code                   g_case_product_code_ttype;         -- �P�[�X���i�R�[�h
  gt_upd_ball_product_code                   g_ball_product_code_ttype;         -- �{�[�����i�R�[�h
  gt_upd_product_code_item_type              g_product_code_item_type_ttype;    -- ���i�R�[�h�i��
  gt_upd_prod_class                          g_prod_class_ttype;                -- ���i�敪
  gt_upd_product_name                        g_product_name_ttype;              -- ���i���i�����j
  gt_upd_product_name1_alt                   g_product_name1_alt_ttype;         -- ���i���P�i�J�i�j
  gt_upd_product_name2_alt                   g_product_name2_alt_ttype;         -- ���i���Q�i�J�i�j
  gt_upd_item_standard1                      g_item_standard1_ttype;            -- �K�i�P
  gt_upd_item_standard2                      g_item_standard2_ttype;            -- �K�i�Q
  gt_upd_qty_in_case                         g_qty_in_case_ttype;               -- ����
  gt_upd_num_of_cases                        g_num_of_cases_ttype;              -- �P�[�X����
  gt_upd_num_of_ball                         g_num_of_ball_ttype;               -- �{�[������
  gt_upd_item_color                          g_item_color_ttype;                -- �F
  gt_upd_item_size                           g_item_size_ttype;                 -- �T�C�Y
  gt_upd_expiration_date                     g_expiration_date_ttype;           -- �ܖ�������
  gt_upd_product_date                        g_product_date_ttype;              -- ������
  gt_upd_order_uom_qty                       g_order_uom_qty_ttype;             -- �����P�ʐ�
  gt_upd_shipping_uom_qty                    g_shipping_uom_qty_ttype;          -- �o�גP�ʐ�
  gt_upd_packing_uom_qty                     g_packing_uom_qty_ttype;           -- ����P�ʐ�
  gt_upd_deal_code                           g_deal_code_ttype;                 -- ����
  gt_upd_deal_class                          g_deal_class_ttype;                -- �����敪
  gt_upd_collation_code                      g_collation_code_ttype;            -- �ƍ�
  gt_upd_uom_code                            g_uom_code_ttype;                  -- �P��
  gt_upd_unit_price_class                    g_unit_price_class_ttype;          -- �P���敪
  gt_upd_parent_packing_number               g_parent_packing_number_ttype;     -- �e����ԍ�
  gt_upd_packing_number                      g_packing_number_ttype;            -- ����ԍ�
  gt_upd_product_group_code                  g_product_group_code_ttype;        -- ���i�Q�R�[�h
  gt_upd_case_dismantle_flag                 g_case_dismantle_flag_ttype;       -- �P�[�X��̕s�t���O
  gt_upd_case_class                          g_case_class_ttype;                -- �P�[�X�敪
  gt_upd_indv_order_qty                      g_indv_order_qty_ttype;            -- �������ʁi�o���j
  gt_upd_case_order_qty                      g_case_order_qty_ttype;            -- �������ʁi�P�[�X�j
  gt_upd_ball_order_qty                      g_ball_order_qty_ttype;            -- �������ʁi�{�[���j
  gt_upd_sum_order_qty                       g_sum_order_qty_ttype;             -- �������ʁi���v�A�o���j
  gt_upd_indv_shipping_qty                   g_indv_shipping_qty_ttype;         -- �o�א��ʁi�o���j
  gt_upd_case_shipping_qty                   g_case_shipping_qty_ttype;         -- �o�א��ʁi�P�[�X�j
  gt_upd_ball_shipping_qty                   g_ball_shipping_qty_ttype;         -- �o�א��ʁi�{�[���j
  gt_upd_pallet_shipping_qty                 g_pallet_shipping_qty_ttype;       -- �o�א��ʁi�p���b�g�j
  gt_upd_sum_shipping_qty                    g_sum_shipping_qty_ttype;          -- �o�א��ʁi���v�A�o���j
  gt_upd_indv_stockout_qty                   g_indv_stockout_qty_ttype;         -- ���i���ʁi�o���j
  gt_upd_case_stockout_qty                   g_case_stockout_qty_ttype;         -- ���i���ʁi�P�[�X�j
  gt_upd_ball_stockout_qty                   g_ball_stockout_qty_ttype;         -- ���i���ʁi�{�[���j
  gt_upd_sum_stockout_qty                    g_sum_stockout_qty_ttype;          -- ���i���ʁi���v�A�o���j
  gt_upd_case_qty                            g_case_qty_ttype;                  -- �P�[�X����
  gt_upd_fold_container_indv_qty             g_fold_contain_indv_qty_ttype;     -- �I���R���i�o���j����
  gt_upd_order_unit_price                    g_order_unit_price_ttype;          -- ���P���i�����j
  gt_upd_shipping_unit_price                 g_shipping_unit_price_ttype;       -- ���P���i�o�ׁj
  gt_upd_order_cost_amt                      g_order_cost_amt_ttype;            -- �������z�i�����j
  gt_upd_shipping_cost_amt                   g_shipping_cost_amt_ttype;         -- �������z�i�o�ׁj
  gt_upd_stockout_cost_amt                   g_stockout_cost_amt_ttype;         -- �������z�i���i�j
  gt_upd_selling_price                       g_selling_price_ttype;             -- ���P��
  gt_upd_order_price_amt                     g_order_price_amt_ttype;           -- �������z�i�����j
  gt_upd_shipping_price_amt                  g_shipping_price_amt_ttype;        -- �������z�i�o�ׁj
  gt_upd_stockout_price_amt                  g_stockout_price_amt_ttype;        -- �������z�i���i�j
  gt_upd_a_column_department                 g_a_column_department_ttype;       -- �`���i�S�ݓX�j
  gt_upd_d_column_department                 g_d_column_department_ttype;       -- �c���i�S�ݓX�j
  gt_upd_standard_info_depth                 g_standard_info_depth_ttype;       -- �K�i���E���s��
  gt_upd_standard_info_height                g_standard_info_height_ttype;      -- �K�i���E����
  gt_upd_standard_info_width                 g_standard_info_width_ttype;       -- �K�i���E��
  gt_upd_standard_info_weight                g_standard_info_weight_ttype;      -- �K�i���E�d��
  gt_upd_general_succeed_item1               g_general_succeed_item1_ttype;     -- �ėp���p�����ڂP
  gt_upd_general_succeed_item2               g_general_succeed_item2_ttype;     -- �ėp���p�����ڂQ
  gt_upd_general_succeed_item3               g_general_succeed_item3_ttype;     -- �ėp���p�����ڂR
  gt_upd_general_succeed_item4               g_general_succeed_item4_ttype;     -- �ėp���p�����ڂS
  gt_upd_general_succeed_item5               g_general_succeed_item5_ttype;     -- �ėp���p�����ڂT
  gt_upd_general_succeed_item6               g_general_succeed_item6_ttype;     -- �ėp���p�����ڂU
  gt_upd_general_succeed_item7               g_general_succeed_item7_ttype;     -- �ėp���p�����ڂV
  gt_upd_general_succeed_item8               g_general_succeed_item8_ttype;     -- �ėp���p�����ڂW
  gt_upd_general_succeed_item9               g_general_succeed_item9_ttype;     -- �ėp���p�����ڂX
  gt_upd_general_succeed_item10              g_general_succeed_item10_ttype;    -- �ėp���p�����ڂP�O
  gt_upd_general_add_item1                   g_general_add_item1_ttype;         -- �ėp�t�����ڂP
  gt_upd_general_add_item2                   g_general_add_item2_ttype;         -- �ėp�t�����ڂQ
  gt_upd_general_add_item3                   g_general_add_item3_ttype;         -- �ėp�t�����ڂR
  gt_upd_general_add_item4                   g_general_add_item4_ttype;         -- �ėp�t�����ڂS
  gt_upd_general_add_item5                   g_general_add_item5_ttype;         -- �ėp�t�����ڂT
  gt_upd_general_add_item6                   g_general_add_item6_ttype;         -- �ėp�t�����ڂU
  gt_upd_general_add_item7                   g_general_add_item7_ttype;         -- �ėp�t�����ڂV
  gt_upd_general_add_item8                   g_general_add_item8_ttype;         -- �ėp�t�����ڂW
  gt_upd_general_add_item9                   g_general_add_item9_ttype;         -- �ėp�t�����ڂX
  gt_upd_general_add_item10                  g_general_add_item10_ttype;        -- �ėp�t�����ڂP�O
  gt_upd_chain_pecul_area_line               g_chain_pecul_area_line_ttype;     -- �`�F�[���X�ŗL�G���A�i���ׁj
  gt_upd_item_code                           g_item_code_ttype;                 -- �i�ڃR�[�h
  gt_upd_line_uom                            g_line_uom_ttype;                  -- ���גP��
  gt_upd_hht_delivery_sche_flag              g_hht_delivery_sche_flag_ttype;    -- HHT�[�i�\��A�g�σt���O
  gt_upd_order_connect_line_num              g_order_connect_line_num_ttype;    -- �󒍊֘A���הԍ�
--
  -- EDI�G���[���p�ϐ�
  gt_edi_errors                              g_edi_errors_ttype;                -- EDI�G���[���e�[�u��
--
  -- EDI�i�ڃG���[�^�C�v�ϐ�
  gt_edi_item_err_type                       g_edi_item_err_type_ttype;
--
-- 2009/12/28 M.Sano Ver.1.14 add Start
  -- �ʉߍ݌Ɍ^�敪�^�C�v�ϐ�
  gt_lookup_tsukagata_divs                   g_lookup_tsukagata_div_ttype;
-- 2009/12/28 M.Sano Ver.1.14 add End
--
  /**********************************************************************************
   * Procedure Name   : proc_msg_output
   * Description      : ���b�Z�[�W�A���O�o��
   ***********************************************************************************/
  PROCEDURE proc_msg_output(
    iv_program      IN  VARCHAR2,            -- �v���O������
    iv_message      IN  VARCHAR2)            -- ���[�U�[�E�G���[���b�Z�[�W
  IS
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => iv_message
    );
--
    -- ���O���b�Z�[�W����
    lv_errbuf := SUBSTRB( cv_pkg_name||cv_msg_cont||iv_program||cv_msg_part||iv_message, 1, 5000 );
--
    -- ���O�o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errbuf
    );
--
  END proc_msg_output;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_param_check
   * Description      : ���̓p�����[�^�Ó����`�F�b�N(A-1)
   ***********************************************************************************/
  PROCEDURE proc_param_check(
-- 2010/01/19 Ver1.15 M.Sano Add Start
--    iv_filename   IN  VARCHAR2,              -- �C���^�t�F�[�X�t�@�C����
--    iv_exe_type   IN  VARCHAR2,              -- ���s�敪
    iv_filename       IN  VARCHAR2,          -- �C���^�t�F�[�X�t�@�C����
    iv_exe_type       IN  VARCHAR2,          -- ���s�敪
    iv_edi_chain_code IN  VARCHAR2,          -- EDI�`�F�[���X�R�[�h
-- 2010/01/19 Ver1.15 M.Sano Add End
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_param_check'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    ln_count   NUMBER(1);       -- ���R�[�h�J�E���g
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    --==============================================================
    -- �u�p�����[�^�o�̓��b�Z�[�W�v���o��
    --==============================================================
    lv_errmsg  := xxccp_common_pkg.get_msg( cv_application,
                                            cv_msg_param_info,
                                            cv_tkn_param1,
                                            iv_filename,
                                            cv_tkn_param2,
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--                                            iv_exe_type
                                            iv_exe_type,
                                            cv_tkn_param3,
                                            iv_edi_chain_code
-- 2010/01/19 Ver1.15 M.Sano Mod End
                                          );
    lv_errbuf  := lv_errmsg;
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => lv_errbuf
    );
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errbuf
    );
    --��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => NULL
    );
--
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    -- �C���^�t�F�[�X�t�@�C�����������͂̏ꍇ
--    IF ( iv_filename IS NULL ) THEN
    -- IF�t�@�C����EDI�`�F�[���X���ǂ��炩�w�肷��K�v������ׁAIF�t�@�C����EDI�`�F�[���X�̕K�{�`�F�b�N�����{
    -- �E �����ꂩ���ݒ� �� �㑱�̏��������{
    -- �E �����Ƃ�NULL   �� �K�{�p�����[�^���ݒ�G���[(IF�t�@�C��)
    IF ( iv_filename IS NULL AND iv_edi_chain_code IS NULL ) THEN
-- 2010/01/19 Ver1.15 M.Sano Mod End
      -- �K�{�p�����[�^���ݒ�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_file_name );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_param_required, cv_tkn_in_param, lv_tkn1 );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���s�敪�p�����[�^�������͂̏ꍇ
    IF ( iv_exe_type IS NULL ) THEN
      -- �K�{�p�����[�^���ݒ�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_edi_exe );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_param_required, cv_tkn_in_param, lv_tkn1 );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �N�C�b�N�R�[�h������s�敪�p�����[�^���擾
    SELECT  count(*)
    INTO    ln_count
    FROM    fnd_lookup_values           lup_values
    WHERE   lup_values.language         = cv_default_language
    AND     lup_values.enabled_flag     = cv_enabled
    AND     lup_values.lookup_type      = cv_qck_edi_exe
    AND     lup_values.lookup_code      = iv_exe_type
    AND     TRUNC( SYSDATE )
    BETWEEN lup_values.start_date_active
    AND     NVL( lup_values.end_date_active, TRUNC( SYSDATE ) );
--
    -- �N�C�b�N�R�[�h�ɖ��o�^�̏ꍇ
    IF ( ln_count = 0 ) THEN
      -- �p�����[�^�s��(�p�����[�^���o�^)�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_edi_exe );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_param_invalid, cv_tkn_in_param, lv_tkn1 );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_param_check;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ��������(A-2)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- EDI�쐬���敪�J�[�\��
    CURSOR edi_create_class_cur
    IS
      SELECT  lup_values.meaning        creation_class                -- �쐬���敪�R�[�h
      FROM    fnd_lookup_values         lup_values
      WHERE   lup_values.language       = cv_default_language
      AND     lup_values.enabled_flag   = cv_enabled
      AND     lup_values.lookup_type    = cv_qck_creation_class       -- EDI�쐬���敪
      AND     lup_values.lookup_code    = cv_creation_class           -- �쐬���敪�F��
      AND     TRUNC( SYSDATE )
      BETWEEN lup_values.start_date_active
      AND     NVL( lup_values.end_date_active, TRUNC( SYSDATE ) );
--
    -- EDI�i�ڃG���[�^�C�v�J�[�\��
    CURSOR edi_item_err_type_cur
    IS
      SELECT  lup_values.lookup_code    dummy_item_code,              -- �_�~�[�i�ڃR�[�h
              lup_values.attribute1     item_err_type                 -- �i�ڃG���[�^�C�v
      FROM    fnd_lookup_values         lup_values
      WHERE   lup_values.language       = cv_default_language
      AND     lup_values.enabled_flag   = cv_enabled
      AND     lup_values.lookup_type    = cv_qck_edi_err_type         -- EDI�i�ڃG���[�^�C�v
      AND     TRUNC( SYSDATE )
      BETWEEN lup_values.start_date_active
      AND     NVL( lup_values.end_date_active, TRUNC( SYSDATE ) );
--
-- 2009/12/28 M.Sano Ver.1.14 add Start
    -- �󒍍쐬�Ώۂ̒ʉߍ݌Ɍ^�敪�J�[�\��
    CURSOR tsukagatazaiko_div_cur
    IS
      SELECT  lup_values.meaning        tsukagatazaiko_div            -- �ʉߍ݌Ɍ^�敪
      FROM    fnd_lookup_values         lup_values
      WHERE   lup_values.language       = cv_default_language
      AND     lup_values.enabled_flag   = cv_enabled
      AND     lup_values.lookup_type    = cv_order_class              -- �󒍔[�i�m��敪�E��
      AND     TRUNC( SYSDATE )
      BETWEEN lup_values.start_date_active
      AND     NVL( lup_values.end_date_active, TRUNC( SYSDATE ) );
--
-- 2009/12/28 M.Sano Ver.1.14 add End
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_organization_cd   fnd_profile_option_values.profile_option_value%TYPE := NULL;     -- �݌ɑg�D�R�[�h
    lt_create_class_rec  edi_create_class_cur%ROWTYPE;                -- EDI�쐬���敪�J�[�\�� ���R�[�h�ϐ�
    l_err_type_rec       edi_item_err_type_cur%ROWTYPE;               -- EDI�i�ڃG���[�^�C�v�J�[�\�� ���R�[�h�ϐ�
-- 2009/12/28 M.Sano Ver.1.14 add Start
    lt_tsukagata_div_rec tsukagatazaiko_div_cur%ROWTYPE;              --�󒍍쐬�Ώۂ̒ʉߍ݌Ɍ^�敪�J�[�\�� ���R�[�h�ϐ�
-- 2009/12/28 M.Sano Ver.1.14 add End
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
    -- �ϐ�������
    gv_purge_term      := NULL;
    gv_case_uom_code   := NULL;
    gn_organization_id := NULL;
    gn_org_unit_id     := NULL;
    gv_creation_class  := NULL;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:EDI���폜����)
    --==============================================================
    gv_purge_term := FND_PROFILE.VALUE( cv_prf_purge_term );
--
    -- �v���t�@�C�����擾�ł��Ȃ������ꍇ
    IF ( gv_purge_term IS NULL ) THEN
      -- �v���t�@�C���i�P�[�X�P�ʃR�[�h�j�擾�G���[���o��
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_purge_term );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_profile, cv_tkn_profile, lv_tkn1 );
      lv_errbuf := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:�P�[�X�P�ʃR�[�h)
    --==============================================================
    gv_case_uom_code := FND_PROFILE.VALUE( cv_prf_case_uom );
--
    -- �v���t�@�C�����擾�ł��Ȃ������ꍇ
    IF ( gv_case_uom_code IS NULL ) THEN
      -- �v���t�@�C���i�P�[�X�P�ʃR�[�h�j�擾�G���[���o��
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_case_uom_code );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_profile, cv_tkn_profile, lv_tkn1 );
      lv_errbuf := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOI:�݌ɑg�D�R�[�h)
    --==============================================================
    lv_organization_cd := FND_PROFILE.VALUE( cv_prf_organization_cd );
--
    -- �v���t�@�C�����擾�ł��Ȃ������ꍇ
    IF ( lv_organization_cd IS NULL ) THEN
      -- �v���t�@�C���i�݌ɑg�D�R�[�h�j�擾�G���[���o��
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_organization_cd );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_profile, cv_tkn_profile, lv_tkn1 );
      lv_errbuf := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
    --==============================================================
    -- �݌ɑg�DID�̎擾
    --==============================================================
    IF ( lv_organization_cd IS NOT NULL ) THEN
--
      -- �݌ɑg�DID�擾
      gn_organization_id := xxcoi_common_pkg.get_organization_id( lv_organization_cd );
--
      -- �݌ɑg�DID���擾�ł��Ȃ������ꍇ
      IF ( gn_organization_id IS NULL ) THEN
        -- �݌ɑg�DID�擾�G���[���o��
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application_coi, cv_msg_organization_id, cv_tkn_org_code_tok, lv_organization_cd );
        lv_errbuf := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        ov_retcode := cv_status_error;
      END IF;
--
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(MO:�c�ƒP��)
    --==============================================================
    gn_org_unit_id := FND_PROFILE.VALUE( cv_prf_org_unit );
--
    -- �v���t�@�C�����擾�ł��Ȃ������ꍇ
    IF ( gn_org_unit_id IS NULL ) THEN
      -- �v���t�@�C���i�c�ƒP�ʁj�擾�G���[���o��
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_unit );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_profile, cv_tkn_profile, lv_tkn1 );
      lv_errbuf := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
-- 2010/01/19 Ver.1.15 M.Sano add Start
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:EDI�G���[���폜����)
    --==============================================================
    gv_err_purge_term := FND_PROFILE.VALUE( cv_prf_err_purge_term );
--
    -- �v���t�@�C�����擾�ł��Ȃ������ꍇ
    IF ( gv_err_purge_term IS NULL ) THEN
      -- �v���t�@�C���iXXCOS:EDI�G���[���폜����)�擾�G���[���o��
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_purge_term );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_profile, cv_tkn_profile, lv_tkn1 );
      lv_errbuf := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
-- 2010/01/19 Ver.1.15 M.Sano add End
    --==============================================================
    -- EDI�쐬���敪�擾
    --==============================================================
    <<loop_set_creation_class>>
    FOR lt_create_class_rec IN edi_create_class_cur LOOP
      gv_creation_class := lt_create_class_rec.creation_class;
    END LOOP;
--
    -- �쐬���敪���擾�ł��Ȃ������ꍇ
    IF ( gv_creation_class IS NULL ) THEN
      -- �}�X�^�`�F�b�N�G���[���o��
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_creation_class );
      lv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_value );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst_notfound, cv_tkn_column, lv_tkn1, cv_tkn_table, lv_tkn2 );
      lv_errbuf := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
--
    --==============================================================
    -- EDI�i�ڃG���[�^�C�v�擾
    --==============================================================
    gt_edi_item_err_type.DELETE;
--
    <<loop_set_edi_err_type>>
    FOR l_err_type_rec IN edi_item_err_type_cur LOOP
      gt_edi_item_err_type(l_err_type_rec.item_err_type) := l_err_type_rec.dummy_item_code;
    END LOOP;
--
    -- EDI�i�ڃG���[�^�C�v���擾�ł��Ȃ������ꍇ
    IF ( gt_edi_item_err_type.COUNT = 0 ) THEN
      -- �}�X�^�`�F�b�N�G���[���o��
      lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_err_type );
      lv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_value );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst_notfound, cv_tkn_column, lv_tkn1, cv_tkn_table, lv_tkn2 );
      lv_errbuf := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      ov_retcode := cv_status_error;
    END IF;
-- 2009/12/28 M.Sano Ver.1.14 add Start
--
    --==============================================================
    -- �󒍍쐬�Ώۂ̒ʉߍ݌Ɍ^�敪�擾
    --==============================================================
    gt_lookup_tsukagata_divs.DELETE;
--
    <<loop_set_edi_err_type>>
    FOR lt_tsukagata_div_rec IN tsukagatazaiko_div_cur LOOP
      gt_lookup_tsukagata_divs(lt_tsukagata_div_rec.tsukagatazaiko_div) := lt_tsukagata_div_rec.tsukagatazaiko_div;
    END LOOP;
-- 2009/12/28 M.Sano Ver.1.14 add End
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_init;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_edi_work
   * Description      : EDI�󒍏�񃏁[�N�e�[�u���f�[�^���o(A-3)
   ***********************************************************************************/
  PROCEDURE proc_get_edi_work(
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    iv_filename   IN  VARCHAR2,            -- �C���^�t�F�[�X�t�@�C����
--    iv_exe_type   IN  VARCHAR2,            -- ���s�敪
    iv_filename       IN  VARCHAR2,        -- �C���^�t�F�[�X�t�@�C����
    iv_exe_type       IN  VARCHAR2,        -- ���s�敪
    iv_edi_chain_code IN  VARCHAR2,        -- EDI�`�F�[���X�R�[�h
-- 2010/01/19 Ver1.15 M.Sano Mod End
    on_target_cnt OUT NOCOPY NUMBER,       -- �Ώۃf�[�^����
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_edi_work'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_status            xxcos_edi_order_work.err_status%TYPE;        -- �X�e�[�^�X
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
    -- OUT�p�����[�^������
    on_target_cnt := 0;
--
    -- ���s�敪���u�V�K�v�̏ꍇ�A�u�V�K�v�f�[�^�������ΏۂƂ���
    IF ( iv_exe_type = cv_exe_type_new ) THEN
      lv_status := cv_edi_status_new;
--
    -- ���s�敪���u�Ď��{�v�̏ꍇ�A�u�x���v�f�[�^�������ΏۂƂ���
    ELSE
      lv_status := cv_edi_status_warning;
--
    END IF;
--
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    -- �J�[�\���I�[�v��
--    OPEN edi_order_work_cur( iv_filename, cv_data_type_code, lv_status );
    -- �J�[�\���I�[�v��
    OPEN edi_order_work_cur( iv_filename, cv_data_type_code, lv_status, iv_edi_chain_code );
-- 2010/01/19 Ver1.15 M.Sano Mod End
    -- �o���N�t�F�b�`
    FETCH edi_order_work_cur BULK COLLECT INTO gt_edi_order_work;
    -- ���o�����Z�b�g
    on_target_cnt := edi_order_work_cur%ROWCOUNT;
    -- �J�[�\���N���[�Y
    CLOSE edi_order_work_cur;
--
    -- �Ώۃf�[�^�����݂��Ȃ��ꍇ
    IF ( on_target_cnt = 0 ) THEN
      -- �Ώۃf�[�^�Ȃ����o��
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_nodata );
      lv_errbuf := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
-- 2009/02/24 T.Nakamura Ver.1.1 add start
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
    END IF;
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- EDI�󒍏�񃏁[�N�e�[�u�����b�N�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_edi_wk_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, lv_tkn1 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF ( edi_order_work_cur%ISOPEN ) THEN
        CLOSE edi_order_work_cur;
      END IF;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- EDI�󒍏�񃏁[�N�e�[�u���f�[�^���o�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_edi_wk_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_getdata, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF ( edi_order_work_cur%ISOPEN ) THEN
        CLOSE edi_order_work_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_get_edi_work;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_edi_errors
   * Description      : EDI�G���[�ϐ��i�[(A-5-1)
   ***********************************************************************************/
  PROCEDURE proc_set_edi_errors(
    it_edi_work          IN g_edi_work_rtype,     -- EDI�󒍏�񃏁[�N���R�[�h
    iv_dummy_item        IN VARCHAR2,             -- �_�~�[�i�ڃR�[�h
    iv_delete_flag       IN VARCHAR2,             -- �폜�t���O
    iv_message_id        IN VARCHAR2              -- ���b�Z�[�WID
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_edi_errors'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
-- 2010/01/19 Ver1.15 M.Sano Add Start
    cv_brank             VARCHAR2(1) := '';
    cv_err_item_yes      VARCHAR2(1) := 'Y';
    cv_err_item_no       VARCHAR2(1) := 'N';
-- 2010/01/19 Ver1.15 M.Sano Add End
--
    -- *** ���[�J���ϐ� ***
    ln_idx               NUMBER;
    ln_seq               NUMBER;
-- 2010/01/19 Ver1.15 M.Sano Add Start
    lv_error_type        VARCHAR2(1);
    lv_err_item_flag     VARCHAR2(1);
    lt_err_list_out_flag xxcos_edi_errors.err_list_out_flag%TYPE;
    lt_item_code         ic_item_mst_b.item_no%TYPE;
    lt_item_name         xxcmn_item_mst_b.item_short_name%TYPE;
    ld_delivery_date     DATE;                                    -- �[�i�\���
-- 2010/01/19 Ver1.15 M.Sano Add End
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    ln_idx := gt_edi_errors.COUNT + 1;
--
    -- EDI�G���[���ID���V�[�P���X����擾����
    BEGIN
      SELECT  xxcos_edi_errors_s01.NEXTVAL
      INTO    ln_seq
      FROM    dual;
    END;
--
    -- ���b�Z�[�WID���烁�b�Z�[�W���擾
    lv_errmsg := xxccp_common_pkg.get_msg( cv_application, iv_message_id );
--
-- 2010/01/19 Ver1.15 M.Sano Add Start
    -- �E�sNo�d���G���[�̏ꍇ�A�g�[�N���ɍsNo���擾����ׁA�ēx���b�Z�[�W���擾
    IF ( iv_message_id = cv_msg_rep_line_no ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_application
                     , iv_message_id
                     , cv_tkn_line_no
                     , it_edi_work.order_connection_line_number
                   );
    END IF;
--
    -- EDI�G���[���̍��ڎZ�o
    -- �EEDI�G���[���ɃZ�b�g����G���[���X�g�o�͍σt���O���擾����B
    --   (�V�K�捞�̏ꍇ �� �G���[���X�g�o�͍σt���O�ɁuN0�v�j
    --   (�Ď��{�̏ꍇ   �� �G���[���X�g�o�͍σt���O�ɁuN1�v�j
    IF ( it_edi_work.err_status = cv_edi_status_new ) THEN
      lt_err_list_out_flag := cv_err_out_flag_new;
    ELSE
      lt_err_list_out_flag := cv_err_out_flag_retry;
    END IF;
--
    -- �E�Ώەi�ڂ��G���[�i�ڂ��ǂ������肷��B
    lv_err_item_flag := cv_err_item_no;
    lv_error_type    := gt_edi_item_err_type.FIRST;
    lt_item_code     := NVL(iv_dummy_item, it_edi_work.item_code);
    WHILE ( lv_error_type IS NOT NULL AND lt_item_code IS NOT NULL ) LOOP
      IF ( gt_edi_item_err_type(lv_error_type) = lt_item_code ) THEN
        lv_err_item_flag := cv_err_item_yes;
      END IF;
      lv_error_type := gt_edi_item_err_type.NEXT(lv_error_type);
    END LOOP;
--
    -- �EEDI�i�ږ��̂𒊏o����B
    --   1. �G���[�i��    �ŏ��i���Q�i�J�i�j���́A�K�i2��NULL�ȊO �� EDI�i�ږ��̂Ɂu���i���Q�i�J�i�j + �K�i2�v
    IF ( lv_err_item_flag = cv_err_item_yes
      AND ( it_edi_work.product_name2_alt IS NOT NULL OR it_edi_work.item_standard2 IS NOT NULL )
    ) THEN
      lt_item_name := NVL(it_edi_work.product_name2_alt, cv_brank)
                   || NVL(it_edi_work.item_standard2, cv_brank);
    --   2. �G���[�i��    �ŏ��i���P�i�J�i�j���́A�K�i1��NULL�ȊO �� EDI�i�ږ��̂Ɂu���i���P�i�J�i�j + �K�i1�v
    ELSIF ( lv_err_item_flag = cv_err_item_yes
      AND ( it_edi_work.product_name1_alt IS NOT NULL OR it_edi_work.item_standard1 IS NOT NULL )
    ) THEN
      lt_item_name := NVL(it_edi_work.product_name1_alt, cv_brank)
                   || NVL(it_edi_work.item_standard1, cv_brank);
    --   3. �G���[�i�ڈȊO�ŕi�ڃR�[�h��NULL�ȊO                  �� EDI�i�ږ��̂ɁuOPM�i�ڃ}�X�^.�i�ږ��́v
    ELSIF ( lv_err_item_flag = cv_err_item_no AND lt_item_code IS NOT NULL  ) THEN
      --[�v�������擾]
      ld_delivery_date := NVL( it_edi_work.shop_delivery_date, 
                            NVL( it_edi_work.center_delivery_date, 
                                 NVL( it_edi_work.order_date, 
                                      it_edi_work.data_creation_date_edi_data
                                    )
                               )
                          );
      --[�i�ږ��̂��擾]
      BEGIN
        SELECT ximb.item_short_name item_name           -- �i�ږ���
        INTO   lt_item_name
        FROM   ic_item_mst_b      iimb                  -- OPM�i�ڃ}�X�^
             , xxcmn_item_mst_b   ximb                  -- OPM�i�ڃ}�X�^�A�h�I��
        WHERE  iimb.item_no    = lt_item_code
        AND    ximb.item_id    = iimb.item_id
        AND    ld_delivery_date
                 BETWEEN NVL(TRUNC(ximb.start_date_active), ld_delivery_date)
                 AND     NVL(TRUNC(ximb.end_date_active),   ld_delivery_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lt_item_name := NULL;
      END;
    --   4. ��L�ȊO                                              �� EDI�i�ږ��̂ɁuNULL�v
    ELSE
      lt_item_name := NULL;
    END IF;
--
    -- EDI�G���[���ɍ쐬����f�[�^���쐬�p�z��Ɋi�[
-- 2010/01/19 Ver1.15 M.Sano Mod End
    gt_edi_errors(ln_idx).edi_err_id                   := ln_seq;                                        -- EDI�G���[ID
    gt_edi_errors(ln_idx).edi_create_class             := gv_creation_class;                             -- EDI�쐬���敪�F��
    gt_edi_errors(ln_idx).chain_code                   := it_edi_work.edi_chain_code;                    -- EDI�`�F�[���X�R�[�h
-- 2009/07/16 Ver.1.7 M.Sano Mod Start
--    gt_edi_errors(ln_idx).dlv_date                     := it_edi_work.center_delivery_date;              -- �X�ܔ[�i��
    gt_edi_errors(ln_idx).dlv_date                     := it_edi_work.shop_delivery_date;                -- �X�ܔ[�i��
-- 2009/07/16 Ver.1.7 M.Sano Mod End
    gt_edi_errors(ln_idx).invoice_number               := it_edi_work.invoice_number;                    -- �`�[�ԍ�
    gt_edi_errors(ln_idx).shop_code                    := it_edi_work.shop_code;                         -- �X�܃R�[�h
    gt_edi_errors(ln_idx).line_no                      := it_edi_work.line_no;                           -- �s�ԍ�
    gt_edi_errors(ln_idx).edi_item_code                := it_edi_work.product_code2;                     -- ���i�R�[�h�Q
    gt_edi_errors(ln_idx).item_code                    := NVL(iv_dummy_item, it_edi_work.item_code);     -- �i�ڃR�[�h
    gt_edi_errors(ln_idx).quantity                     := it_edi_work.sum_order_qty;                     -- �󒍐��ʁi���v�A�o���j
    gt_edi_errors(ln_idx).unit_price                   := it_edi_work.order_unit_price;                  -- ���P���i�����j
    gt_edi_errors(ln_idx).delete_flag                  := iv_delete_flag;                                -- �폜�t���O
    gt_edi_errors(ln_idx).work_id                      := it_edi_work.order_info_work_id;                -- EDI�󒍏�񃏁[�NID
    gt_edi_errors(ln_idx).status                       := cv_edi_status_warning;                         -- �X�e�[�^�X�F�x��
    gt_edi_errors(ln_idx).err_message                  := SUBSTRB(lv_errmsg, 1, 40);                     -- �G���[���b�Z�[�W�i40�޲ĕ��j
-- 2010/01/19 Ver1.15 M.Sano Add Start
    gt_edi_errors(ln_idx).err_message_code             := iv_message_id;                                 -- ���b�Z�[�WID
    gt_edi_errors(ln_idx).edi_received_date            := it_edi_work.creation_date;                     -- EDI��M��
    gt_edi_errors(ln_idx).err_list_out_flag            := lt_err_list_out_flag;                          -- �󒍃G���[���X�g�o�͍σt���O
    gt_edi_errors(ln_idx).edi_item_name                := SUBSTRB(lt_item_name, 1, 20);                  -- EDI�i�ږ���
-- 2010/01/19 Ver1.15 M.Sano Add End
    gt_edi_errors(ln_idx).created_by                   := cn_created_by;                                 -- �쐬��
    gt_edi_errors(ln_idx).creation_date                := cd_creation_date;                              -- �쐬��
    gt_edi_errors(ln_idx).last_updated_by              := cn_last_updated_by;                            -- �ŏI�X�V��
    gt_edi_errors(ln_idx).last_update_date             := cd_last_update_date;                           -- �ŏI�X�V��
    gt_edi_errors(ln_idx).last_update_login            := cn_last_update_login;                          -- �ŏI�X�V���O�C��
    gt_edi_errors(ln_idx).request_id                   := cn_request_id;                                 -- �v��ID
    gt_edi_errors(ln_idx).program_application_id       := cn_program_application_id;                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    gt_edi_errors(ln_idx).program_id                   := cn_program_id;                                 -- �R���J�����g�E�v���O����ID
    gt_edi_errors(ln_idx).program_update_date          := cd_program_update_date;                        -- �v���O�����X�V��
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
--
--#####################################  �Œ蕔 END   ##########################################
  END proc_set_edi_errors;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_data_validate
   * Description      : �f�[�^�Ó����`�F�b�N���o(A-4)
   ***********************************************************************************/
  PROCEDURE proc_data_validate(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_data_validate'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
--
    -- *** ���[�J���萔 ***
-- 2010/01/19 M.Sano Ver.1.15 add Start
    cv_line_no_dupli_yes   CONSTANT VARCHAR2(1) := 'Y';                         -- �sNo�d���G���[:Yes
    cv_line_no_dupli_no    CONSTANT VARCHAR2(1) := 'N';                         -- �sNo�d���G���[:No
-- 2010/01/19 M.Sano Ver.1.15 add End
--
    -- *** ���[�J���ϐ� ***
    -- �ڋq����`
    TYPE l_cust_info_rtype IS RECORD
      (
        conv_cust_code        hz_cust_accounts.account_number%TYPE,             -- �ڋq�R�[�h
-- 2009/12/28 M.Sano Ver.1.14 add Start
        tsukagatazaiko_div    xxcmm_cust_accounts.tsukagatazaiko_div%TYPE,      -- �ʉߍ݌Ɍ^�敪
-- 2009/12/28 M.Sano Ver.1.14 add End
        price_list_id         hz_cust_site_uses_all.price_list_id%TYPE          -- ���i�\ID
      );
--
    -- �i�ڏ���`
    TYPE l_item_info_rtype IS RECORD
      (
        item_id               ic_item_mst_b.item_id%TYPE,                       -- �i��ID
        item_no               ic_item_mst_b.item_no%TYPE,                       -- �i���R�[�h
        cust_order_flag       mtl_system_items_b.customer_order_enabled_flag%TYPE,
                                                                                -- �ڋq�󒍉\�t���O
        sales_class           ic_item_mst_b.attribute26%TYPE,                   -- ����Ώۋ敪
        unit                  mtl_system_items_b.primary_unit_of_measure%TYPE,  -- �P��
        unit_price            NUMBER                                            -- �P��
      );
--
    lt_cust_info_rec          l_cust_info_rtype;                                -- �ڋq���ϐ�
    lt_item_info_rec          l_item_info_rtype;                                -- �i�ڏ��ϐ�
    lv_edi_item_code_div      xxcmm_cust_accounts.edi_item_code_div%TYPE;       -- EDI�A�g�i�ڃR�[�h�敪
    lv_check_status           xxcos_edi_order_work.err_status%TYPE;             -- EDI�G���[�X�e�[�^�X
    ln_idx                    NUMBER;
-- 2010/01/19 M.Sano Ver.1.15 add Start
    ln_new_line_no            NUMBER;                                           -- �sNo(�č̔ԗp)
    lt_salesrep_id            jtf_rs_salesreps.salesrep_id%TYPE;                -- �c�ƒS��ID
-- 2010/01/19 M.Sano Ver.1.15 add End
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�v���V�W�� ***
--
    -- -------------------------------
    -- �S�f�[�^�̃X�e�[�^�X���x���ɂ���
    -- -------------------------------
    PROCEDURE set_check_status_all(
      iv_err_status      IN VARCHAR2
    )
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'set_check_status_all'; -- �v���O������
-- 2009/06/29 M.Sano Ver.1.6 add End
      -- *** ���[�J���ϐ� ***
      ln_idx             NUMBER;
    BEGIN
--
      -- �`�[�P�ʂ̑S���ׂ̃X�e�[�^�X��ݒ肷��
      <<loop_set_edi_status>>
      FOR ln_idx IN 1..gt_edi_work.COUNT LOOP
        -- �X�e�[�^�X��ݒ�
        gt_edi_work(ln_idx).check_status := iv_err_status;
      END LOOP;
--
    EXCEPTION
      -- ��O�����������ꍇ
      WHEN OTHERS THEN
        NULL;
--
    END;
--
    -- -------------------------------
    -- �K�{���̓`�F�b�N
    -- -------------------------------
    FUNCTION check_required(
      it_edi_work        IN g_edi_work_ttype                -- IN�FEDI�󒍏�񃏁[�N�f�[�^
    ) RETURN NUMBER
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'check_required'; -- �v���O������
-- 2009/06/29 M.Sano Ver.1.6 add End
      -- *** ���[�J���ϐ� ***
      ln_idx             NUMBER;
      ln_result          NUMBER;
    BEGIN
--
      -- ���^�[���R�[�h������
      ln_result := 0;
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--      -- �X�R�[�h�������͂̏ꍇ
--      IF ( it_edi_work(it_edi_work.first).shop_code IS NULL ) THEN
      -- �Y�����R�[�h���`�F�b�N�ΏہA���A�X�R�[�h�������͂̏ꍇ
      IF ( (  gn_check_record_flag = cn_check_record_yes )
      AND  ( it_edi_work(it_edi_work.first).shop_code IS NULL ) ) THEN
-- 2009/06/29 M.Sano Ver.1.6 mod End
        -- �K�{���ځi�X�R�[�h�j�����̓G���[���o��
        lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_shop_code );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_required, cv_tkn_item, lv_tkn1 );
        lv_errbuf := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- EDI�G���[���ǉ�
-- 2010/01/19 Ver.1.15 M.Sano mod Start
--        proc_set_edi_errors( it_edi_work(it_edi_work.first), NULL, NULL, cv_msg_rep_required );
        proc_set_edi_errors( it_edi_work(it_edi_work.first), NULL, cv_error_delete_flag, cv_msg_rep_no_shop_cd );
-- 2010/01/19 Ver.1.15 M.Sano mod End
        -- �G���[�ݒ�
        ln_result := 1;
      END IF;
--
      <<loop_check_edi_required>>
      FOR ln_idx IN 1..it_edi_work.COUNT LOOP
--
        -- �sNo�������͂̏ꍇ
        IF ( NVL( it_edi_work(ln_idx).line_no, 0 ) = 0 ) THEN
          -- �K�{���ځi�s�ԍ��j�����̓G���[���o��
          lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_no );
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_required, cv_tkn_item, lv_tkn1 );
          lv_errbuf := lv_errmsg;
          -- ���O�o��
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- EDI�G���[���ǉ�
-- 2010/01/19 Ver.1.15 M.Sano mod Start
--          proc_set_edi_errors( it_edi_work(ln_idx), NULL, NULL, cv_msg_rep_required );
          proc_set_edi_errors( it_edi_work(ln_idx), NULL, cv_error_delete_flag, cv_msg_rep_no_line_no );
-- 2010/01/19 Ver.1.15 M.Sano mod End
          -- �G���[�ݒ�
          ln_result := 1;
        END IF;
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--        -- �Y�����R�[�h���`�F�b�N�ΏہA���A�������ʁi���v�A�o���j�������͂̏ꍇ
--        IF ( NVL( it_edi_work(ln_idx).sum_order_qty, 0) = 0 ) THEN
        -- �Y�����R�[�h���`�F�b�N�ΏہA���A�������ʁi���v�A�o���j�������͂̏ꍇ
        IF ( ( gn_check_record_flag = cn_check_record_yes )
        AND  ( NVL( it_edi_work(ln_idx).sum_order_qty, 0) = 0 ) ) THEN
-- 2009/06/29 M.Sano Ver.1.6 mod End
          -- �K�{���ځi�������ʁj�����̓G���[���o��
          lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_order_qty );
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_required, cv_tkn_item, lv_tkn1 );
          lv_errbuf := lv_errmsg;
          -- ���O�o��
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- EDI�G���[���ǉ�
-- 2010/01/19 Ver.1.15 M.Sano mod Start
--          proc_set_edi_errors( it_edi_work(ln_idx), NULL, NULL, cv_msg_rep_required );
          proc_set_edi_errors( it_edi_work(ln_idx), NULL, cv_error_delete_flag, cv_msg_rep_no_quantity );
-- 2010/01/19 Ver.1.15 M.Sano mod End
          -- �G���[�ݒ�
          ln_result := 1;
        END IF;
--
      END LOOP;
--
      RETURN ln_result;
--
    EXCEPTION
      -- ��O�����������ꍇ
      WHEN OTHERS THEN
        RETURN 1;
--
    END;
--
    -- -------------------------------
    -- �ڋq���`�F�b�N
    -- -------------------------------
    PROCEDURE customer_conv_check(
      it_edi_work        IN  g_edi_work_rtype,              -- IN�FEDI�󒍏�񃏁[�N���R�[�h
      ot_cust_info_rec   OUT NOCOPY l_cust_info_rtype,      -- OUT�F�ڋq���
      ov_check_status    OUT NOCOPY VARCHAR2                -- OUT�F�`�F�b�N�X�e�[�^�X
    )
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'customer_conv_check'; -- �v���O������
-- 2009/06/29 M.Sano Ver.1.6 add End
    BEGIN
--
      -- OUT�p�����[�^(�ڋq���)������
      ov_check_status                 := cv_edi_status_normal;
      ot_cust_info_rec.conv_cust_code := NULL;
      ot_cust_info_rec.price_list_id  := NULL;
--
      SELECT  accounts.account_number,                                          -- �ڋq�R�[�h
-- 2009/12/28 M.Sano Ver.1.14 add Start
              addon.tsukagatazaiko_div,                                         -- �ʉߍ݌Ɍ^�敪(EDI)
-- 2009/12/28 M.Sano Ver.1.14 add End
              uses.price_list_id                                                -- ���i�\ID
      INTO    ot_cust_info_rec.conv_cust_code,
-- 2009/12/28 M.Sano Ver.1.14 add Start
              ot_cust_info_rec.tsukagatazaiko_div,
-- 2009/12/28 M.Sano Ver.1.14 add End
              ot_cust_info_rec.price_list_id
      FROM    hz_cust_accounts               accounts,                          -- �ڋq�}�X�^
              xxcmm_cust_accounts            addon,                             -- �ڋq�A�h�I��
              hz_cust_acct_sites_all         sites,                             -- �ڋq���ݒn
              hz_cust_site_uses_all          uses,                              -- �ڋq�g�p�ړI
              hz_parties                     party                              -- �p�[�e�B�}�X�^
      WHERE   accounts.cust_account_id       = sites.cust_account_id
      AND     sites.cust_acct_site_id        = uses.cust_acct_site_id
      AND     accounts.cust_account_id       = addon.customer_id
      AND     accounts.status                = cv_cust_status_active            -- �X�e�[�^�X�FA�i�L���j
      AND     accounts.customer_class_code   = cv_cust_class_cust               -- �ڋq�敪�F10�i�ڋq�j
      AND     accounts.party_id              = party.party_id
      AND     party.duns_number_c            IN ( cv_cust_status_30,            -- �ڋq�X�e�[�^�X�F30�i���F�ρj
                                                  cv_cust_status_40 )           -- �ڋq�X�e�[�^�X�F40�i�ڋq�j
      AND     addon.chain_store_code         = it_edi_work.edi_chain_code       -- EDI�`�F�[���X�R�[�h
      AND     addon.store_code               = it_edi_work.shop_code            -- �X�R�[�h
      AND     sites.org_id                   = gn_org_unit_id                   -- �c�ƒP��
      AND     uses.site_use_code             = cv_cust_site_use_code            -- �ڋq�g�p�ړI�FSHIP_TO(�o�א�)
      AND     uses.org_id                    = gn_org_unit_id;                  -- �c�ƒP��
--
    EXCEPTION
      -- �f�[�^�����݂��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--        -- �ڋq�R�[�h�ϊ��G���[���o��
--        lv_errmsg := xxccp_common_pkg.get_msg( cv_application,
--                                               cv_msg_cust_conv,
--                                               cv_tkn_chain_shop_code,
--                                               it_edi_work.edi_chain_code,
--                                               cv_tkn_shop_code,
--                                               it_edi_work.shop_code
--                                             );
--        lv_errbuf := lv_errmsg;
--        -- ���O�o��
--        proc_msg_output( cv_prg_name, lv_errbuf );
--        -- �x���X�e�[�^�X�ݒ�
--        ov_check_status := cv_edi_status_warning;
--        -- EDI�G���[���ǉ�
--        proc_set_edi_errors( it_edi_work, NULL, NULL, cv_msg_rep_cust_conv );
--        -- �`�[�G���[�t���O�ݒ�
--        gn_invoice_err_flag := 1;
        -- �`�F�b�N�����Ώۂ̏ꍇ�̓G���[
        IF ( gn_check_record_flag = cn_check_record_yes ) THEN
          -- �ڋq�R�[�h�ϊ��G���[���o��
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application,
                                                 cv_msg_cust_conv,
                                                 cv_tkn_chain_shop_code,
                                                 it_edi_work.edi_chain_code,
                                                 cv_tkn_shop_code,
                                                 it_edi_work.shop_code
                                               );
          lv_errbuf := lv_errmsg;
          -- ���O�o��
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- �x���X�e�[�^�X�ݒ�
          ov_check_status := cv_edi_status_warning;
          -- EDI�G���[���ǉ�
          proc_set_edi_errors( it_edi_work, NULL, NULL, cv_msg_rep_cust_conv );
          -- �`�[�G���[�t���O�ݒ�
          gn_invoice_err_flag := 1;
        ELSE
          ot_cust_info_rec.conv_cust_code := NULL;
          ot_cust_info_rec.price_list_id  := NULL;
        END IF;
-- 2009/06/29 M.Sano Ver.1.6 mod End
-- 2009/11/25 K.Atsushiba Ver.1.12 Add Start
      WHEN TOO_MANY_ROWS THEN
        IF ( gn_check_record_flag = cn_check_record_yes ) THEN
          -- �ڋq�R�[�h�ϊ��G���[���o��
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application,
                                                 cv_msg_many_cust_conv,
                                                 cv_tkn_chain_shop_code,
                                                 it_edi_work.edi_chain_code,
                                                 cv_tkn_shop_code,
                                                 it_edi_work.shop_code
                                               );
          lv_errbuf := lv_errmsg;
          -- ���O�o��
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- �x���X�e�[�^�X�ݒ�
          ov_check_status := cv_edi_status_warning;
          -- EDI�G���[���ǉ�
          proc_set_edi_errors( it_edi_work, NULL, NULL, cv_msg_rep_cust_conv );
          -- �`�[�G���[�t���O�ݒ�
          gn_invoice_err_flag := 1;
        ELSE
          ot_cust_info_rec.conv_cust_code := NULL;
          ot_cust_info_rec.price_list_id  := NULL;
        END IF;
      WHEN OTHERS THEN
        IF ( gn_check_record_flag = cn_check_record_yes ) THEN
          -- �x���X�e�[�^�X�ݒ�
          ov_check_status := cv_edi_status_warning;
          -- EDI�G���[���ǉ�
          proc_set_edi_errors( it_edi_work, NULL, NULL, cv_msg_rep_cust_conv );
          -- �`�[�G���[�t���O�ݒ�
          gn_invoice_err_flag := 1;
        ELSE
          ot_cust_info_rec.conv_cust_code := NULL;
          ot_cust_info_rec.price_list_id  := NULL;
        END IF;
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        -- ���O�o��
        proc_msg_output( cv_prg_name, ov_errbuf );
-- 2009/11/25 K.Atsushiba Ver.1.12 Add End
--
    END;
--
    -- -------------------------------
    -- EDI�A�g�i�ڃR�[�h�敪�擾
    -- -------------------------------
    PROCEDURE get_edi_item_code_div(
      iv_edi_chain_code        IN  VARCHAR2,           -- IN�FEDI�`�F�[���X�R�[�h
      ov_edi_item_code_div     OUT NOCOPY VARCHAR2     -- OUT�FEDI�A�g�i�ڃR�[�h�敪
    )
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'get_edi_item_code_div'; -- �v���O������
-- 2009/06/29 M.Sano Ver.1.6 add End
    BEGIN
      -- OUT�p�����[�^������
      ov_edi_item_code_div := NULL;
--
      SELECT  addon.edi_item_code_div                                 -- EDI�A�g�i�ڃR�[�h�敪
      INTO    ov_edi_item_code_div
      FROM    hz_cust_accounts               accounts,                -- �ڋq�}�X�^
              xxcmm_cust_accounts            addon,                   -- �ڋq�A�h�I��
              hz_parties                     party                    -- �p�[�e�B�}�X�^
      WHERE   accounts.cust_account_id       = addon.customer_id
      AND     accounts.party_id              = party.party_id
      AND     addon.edi_chain_code           = iv_edi_chain_code      -- EDI�`�F�[���X�R�[�h
      AND     accounts.customer_class_code   = cv_cust_class_chain    -- �ڋq�敪�F18(�`�F�[���X)
      AND     accounts.status                = cv_cust_status_active  -- �X�e�[�^�X�FA�i�L���j
      AND     party.duns_number_c            = cv_cust_status_99;     -- �ڋq�X�e�[�^�X�F99�i�ΏۊO�j
--
    EXCEPTION
      -- �f�[�^�����݂��Ȃ��ꍇ�A�ďo���ŃG���[���������{����
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
-- 2010/01/19 Ver.1.15 M.Sano add Start
    -- -------------------------------
    -- �c�ƒS��ID�擾
    -- -------------------------------
    PROCEDURE get_salesrep_id(
      it_customer_code         IN  hz_cust_accounts.account_number%TYPE, -- IN �F�ڋq�R�[�h
      id_date                  IN  DATE,                                 -- IN �F�󒍓��t
      ot_salesrep_id           OUT jtf_rs_salesreps.salesrep_id%TYPE     -- OUT�F�c�ƒS��ID
    )
    IS
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'get_salesrep_id'; -- �v���O������
      
    BEGIN
      SELECT jrs.salesrep_id                                                    -- �c�ƒS��ID
      INTO   ot_salesrep_id
      FROM   hz_cust_accounts          hca                                      -- �ڋq�}�X�^
            ,hz_organization_profiles  hop                                      -- �g�D�v���t�@�C��
            ,ego_resource_agv          era                                      -- �g�D�v���t�@�C���g��
            ,jtf_rs_salesreps          jrs                                      -- �c�ƒS��
      WHERE  hca.account_number          = it_customer_code                     -- [���o]�ڋq�R�[�h
      AND    hop.party_id                = hca.party_id                         -- [����]�p�[�e�BID
      AND    era.organization_profile_id = hop.organization_profile_id          -- [����]�g�D�v���t�@�C��ID
      AND    hop.effective_end_date      IS NULL                                -- [���o]�g�D�v���t�@�C��.�L���I�����FNULL
      AND    jrs.salesrep_number         = era.resource_no                      -- [����]�c�ƒS��No
      AND    jrs.org_id                  = gn_org_unit_id                       -- [���o]�c�ƒP��ID
      AND    TRUNC(era.resource_s_date)              <= TRUNC(NVL(id_date, ct_order_date_def) )
      AND    TRUNC(NVL(era.resource_e_date, NVL(id_date, ct_order_date_def) ) )
                                                     >= TRUNC(NVL(id_date, ct_order_date_def) )
      AND    TRUNC(jrs.start_date_active)            <= TRUNC(NVL(id_date, ct_order_date_def) )
      AND    TRUNC(NVL(jrs.end_date_active, NVL(id_date, ct_order_date_def) ) )
                                                     >= TRUNC(NVL(id_date, ct_order_date_def) )
      AND    ROWNUM = 1
      ;
    EXCEPTION
      -- �f�[�^�����݂��Ȃ��ꍇ�A�ďo���ŃG���[���������{����
      WHEN NO_DATA_FOUND THEN
        ot_salesrep_id := NULL;
    END;
--
-- 2010/01/19 Ver.1.15 M.Sano add End
    -- -------------------------------
    -- JAN�R�[�h���擾
    -- -------------------------------
    FUNCTION get_jan_code_item(
--****************************** 2009/05/19 1.5 T.Kitajima MOD START ******************************--
--      iv_product_code2      IN  VARCHAR2,         -- IN�F���i�R�[�h�Q
      it_edi_work           IN  g_edi_work_rtype, -- IN�FEDI�󒍏�񃏁[�N���R�[�h
--****************************** 2009/05/19 1.5 T.Kitajima MOD  END  ******************************--
      on_item_id            OUT NOCOPY NUMBER,    -- OUT�F�i��ID
      ov_item_code          OUT NOCOPY VARCHAR2,  -- OUT�F�i�ڃR�[�h
      ov_cust_order_flag    OUT NOCOPY VARCHAR2,  -- OUT�F�ڋq�󒍉\�t���O
      ov_sales_class        OUT NOCOPY VARCHAR2,  -- OUT�F����Ώۋ敪
      ov_unit               OUT NOCOPY VARCHAR2   -- OUT�F�P��
    ) RETURN NUMBER
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'get_jan_code_item'; -- �v���O������
-- 2009/06/29 M.Sano Ver.1.6 add End
    BEGIN
--
--****************************** 2009/05/19 1.5 T.Kitajima MOD START ******************************--
--      SELECT  disc_item.inventory_item_id,                       -- �i��ID
--              opm_item.item_no,                                  -- �i���R�[�h
--              disc_item.customer_order_enabled_flag,             -- �ڋq�󒍉\�t���O
--              opm_item.attribute26,                              -- ����Ώۋ敪
--              disc_item.primary_unit_of_measure                  -- �P��
--      INTO    on_item_id,
--              ov_item_code,
--              ov_cust_order_flag,
--              ov_sales_class,
--              ov_unit
--      FROM    ic_item_mst_b             opm_item,                -- �n�o�l�i��
--              mtl_system_items_b        disc_item                -- Disc�i��
--      WHERE   opm_item.attribute21      = iv_product_code2       -- ���i�R�[�h�Q
--      AND     opm_item.item_no          = disc_item.segment1     -- �i�ڃR�[�h
--      AND     disc_item.organization_id = gn_organization_id;    -- �݌ɑg�DID
--
      SELECT ims.inventory_item_id,
             ims.item_no,
             ims.customer_order_enabled_flag,
             ims.attribute26,
             ims.primary_unit_of_measure
        INTO on_item_id,
             ov_item_code,
             ov_cust_order_flag,
             ov_sales_class,
             ov_unit
        FROM (
              SELECT msi.inventory_item_id           inventory_item_id,           --�i��ID
                     iim.item_no                     item_no,                     --�i���R�[�h
                     msi.customer_order_enabled_flag customer_order_enabled_flag, --�ڋq�󒍉\�t���O
                     iim.attribute26                 attribute26,                 --����Ώۋ敪
                     msi.primary_unit_of_measure     primary_unit_of_measure      --�P��
                FROM ic_item_mst_b                   iim,                         --OPM�i��
                     xxcmn_item_mst_b                xim,                         --OPM�i�ڃA�h�I��
                     mtl_system_items_b              msi                          --Disc�i��
               WHERE iim.attribute21      = it_edi_work.product_code2             --���i�R�[�h�Q
                 AND iim.item_no          = msi.segment1                          --�i�ڃR�[�h
                 AND msi.organization_id  = gn_organization_id                    --�݌ɑg�DID
                 AND xim.item_id          = iim.item_id                           --OPM�i��.�i��ID        =OPM�i�ڃA�h�I��.�i��ID
                 AND xim.item_id          = xim.parent_item_id                    --OPM�i�ڃA�h�I��.�i��ID=OPM�i�ڃA�h�I��.�e�i��ID
                 --OPM�i�ڃ}�X�^.�����i�����j�J�n��.(ATTRIBUTE13) <= 
                 --NVL( �X�ܔ[�i��, NVL( �Z���^�[�[�i��, NVL( ������, �f�[�^�쐬���iEDI�f�[�^���j) ) )
                 AND TO_DATE(iim.attribute13,cv_format_yyyymmdds) <=
                                                NVL( it_edi_work.shop_delivery_date, 
                                                     NVL( it_edi_work.center_delivery_date, 
                                                          NVL( it_edi_work.order_date, 
                                                               it_edi_work.data_creation_date_edi_data
                                                             )
                                                        )
                                                   )
              ORDER BY iim.attribute13 DESC
             ) ims
       WHERE ROWNUM  = 1
       ;
--****************************** 2009/05/19 1.5 T.Kitajima MOD  END  ******************************--
--
      RETURN 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 0;
--#################################  �Œ��O������ START   ####################################
--
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
        RETURN 0;
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
        RETURN 0;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
        -- ���O�o��
        proc_msg_output( cv_prg_name, ov_errbuf );
        RETURN 0;
--
--#####################################  �Œ蕔 END   ##########################################
    END;
--
    -- -------------------------------
    -- �P�[�XJAN�R�[�h���擾
    -- -------------------------------
    FUNCTION get_case_jan_code_item(
--****************************** 2009/05/19 1.5 T.Kitajima MOD START ******************************--
--      iv_product_code2      IN  VARCHAR2,         -- IN�F���i�R�[�h�Q
      it_edi_work           IN  g_edi_work_rtype, -- IN�FEDI�󒍏�񃏁[�N���R�[�h
--****************************** 2009/05/19 1.5 T.Kitajima MOD  END  ******************************--
      on_item_id            OUT NOCOPY NUMBER,    -- OUT�F�i��ID
      ov_item_code          OUT NOCOPY VARCHAR2,  -- OUT�F�i�ڃR�[�h
      ov_cust_order_flag    OUT NOCOPY VARCHAR2,  -- OUT�F�ڋq�󒍉\�t���O
      ov_sales_class        OUT NOCOPY VARCHAR2,  -- OUT�F����Ώۋ敪
      ov_unit               OUT NOCOPY VARCHAR2   -- OUT�F�P��
    ) RETURN NUMBER
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'get_case_jan_code_item'; -- �v���O������
-- 2009/06/29 M.Sano Ver.1.6 add End
    BEGIN
--
--****************************** 2009/05/19 1.5 T.Kitajima MOD START ******************************--
--      SELECT  disc_item.inventory_item_id,                       -- �i��ID
--              opm_item.item_no,                                  -- �i���R�[�h
--              disc_item.customer_order_enabled_flag,             -- �ڋq�󒍉\�t���O
--              opm_item.attribute26,                              -- ����Ώۋ敪
--              gv_case_uom_code                                   -- �P��
--      INTO    on_item_id,
--              ov_item_code,
--              ov_cust_order_flag,
--              ov_sales_class,
--              ov_unit
--      FROM    ic_item_mst_b             opm_item,                -- �n�o�l�i��
--              mtl_system_items_b        disc_item,               -- Disc�i��
--              xxcmm_system_items_b      item_addon               -- Disc�i�ڃA�h�I��
--      WHERE   item_addon.case_jan_code  = iv_product_code2       -- ���i�R�[�h�Q
--      AND     item_addon.item_code      = disc_item.segment1
--      AND     disc_item.segment1        = opm_item.item_no
--      AND     disc_item.organization_id = gn_organization_id;
--
      SELECT ims.inventory_item_id,
             ims.item_no,
             ims.customer_order_enabled_flag,
             ims.attribute26,
             gv_case_uom_code                                                     --�P��
        INTO on_item_id,
             ov_item_code,
             ov_cust_order_flag,
             ov_sales_class,
             ov_unit
        FROM (
              SELECT msi.inventory_item_id           inventory_item_id,           --�i��ID
                     iim.item_no                     item_no,                     --�i���R�[�h
                     msi.customer_order_enabled_flag customer_order_enabled_flag, --�ڋq�󒍉\�t���O
                     iim.attribute26                 attribute26                  --����Ώۋ敪
                FROM ic_item_mst_b                   iim,                         --OPM�i��
                     xxcmn_item_mst_b                xim,                         --OPM�i�ڃA�h�I��
                     mtl_system_items_b              msi,                         --Disc�i��
                     xxcmm_system_items_b            xsi                          --Disc�i�ڃA�h�I��
               WHERE xsi.case_jan_code    = it_edi_work.product_code2             --���i�R�[�h�Q
                 AND xsi.item_code        = msi.segment1
                 AND msi.segment1         = iim.item_no
                 AND msi.organization_id  = gn_organization_id
                 AND xim.item_id          = iim.item_id                           --OPM�i��.�i��ID        =OPM�i�ڃA�h�I��.�i��ID
                 AND xim.item_id          = xim.parent_item_id                    --OPM�i�ڃA�h�I��.�i��ID=OPM�i�ڃA�h�I��.�e�i��ID
                 --OPM�i�ڃ}�X�^.�����i�����j�J�n��.(ATTRIBUTE13) <= 
                 --NVL( �X�ܔ[�i��, NVL( �Z���^�[�[�i��, NVL( ������, �f�[�^�쐬���iEDI�f�[�^���j) ) )
                 AND TO_DATE(iim.attribute13,cv_format_yyyymmdds) <=
                                                NVL( it_edi_work.shop_delivery_date, 
                                                     NVL( it_edi_work.center_delivery_date, 
                                                          NVL( it_edi_work.order_date, 
                                                               it_edi_work.data_creation_date_edi_data
                                                             )
                                                        )
                                                   )
              ORDER BY iim.attribute13 DESC
            ) ims
       WHERE ROWNUM  = 1
       ;
--****************************** 2009/05/19 1.5 T.Kitajima MOD  END  ******************************--
--
      RETURN 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 0;
--#################################  �Œ��O������ START   ####################################
--
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
        RETURN 0;
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
        RETURN 0;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
        -- ���O�o��
        proc_msg_output( cv_prg_name, ov_errbuf );
        RETURN 0;
--
--#####################################  �Œ蕔 END   ##########################################
    END;
--
    -- -------------------------------
    -- �ڋq�i�ڏ��擾
    -- -------------------------------
    FUNCTION get_cust_item(
      iv_edi_chain_code     IN  VARCHAR2,         -- IN�FEDI�`�F�[���X�R�[�h
      iv_product_code2      IN  VARCHAR2,         -- IN�F���i�R�[�h�Q
      on_item_id            OUT NOCOPY NUMBER,    -- OUT�F�i��ID
      ov_item_code          OUT NOCOPY VARCHAR2,  -- OUT�F�i�ڃR�[�h
      ov_cust_order_flag    OUT NOCOPY VARCHAR2,  -- OUT�F�ڋq�󒍉\�t���O
      ov_sales_class        OUT NOCOPY VARCHAR2,  -- OUT�F����Ώۋ敪
      ov_unit               OUT NOCOPY VARCHAR2   -- OUT�F�P��
    ) RETURN NUMBER
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_item'; -- �v���O������
-- 2009/06/29 M.Sano Ver.1.6 add End
    BEGIN
--
      SELECT  cust_xref.inventory_item_id,                       -- �i��ID
              opm_item.item_no,                                  -- �i���R�[�h
              disc_item.customer_order_enabled_flag,             -- �ڋq�󒍉\�t���O
              opm_item.attribute26,                              -- ����Ώۋ敪
              cust_item.attribute1                               -- �P��
      INTO    on_item_id,
              ov_item_code,
              ov_cust_order_flag,
              ov_sales_class,
              ov_unit
      FROM    mtl_customer_items        cust_item,               -- �ڋq�i��
              mtl_customer_item_xrefs   cust_xref,               -- �ڋq�i�ڑ��ݎQ��
              hz_cust_accounts          cust_chain_shop,         -- EDI�`�F�[���X�}�X�^
              xxcmm_cust_accounts       cust_chain_addon,        -- �ڋq�ǉ����
              hz_parties                cust_chain_party,        -- �p�[�e�B�}�X�^
              ic_item_mst_b             opm_item,                -- �n�o�l�i��
              mtl_system_items_b        disc_item,               -- Disc�i��
              mtl_parameters            params                   -- �p�����[�^
      WHERE   cust_item.customer_item_id          = cust_xref.customer_item_id
      AND     cust_item.customer_id               = cust_chain_shop.cust_account_id
      AND     cust_chain_addon.edi_chain_code     = iv_edi_chain_code
      AND     cust_chain_shop.cust_account_id     = cust_chain_addon.customer_id
      AND     cust_chain_shop.party_id            = cust_chain_party.party_id
      AND     cust_chain_shop.customer_class_code = cv_cust_class_chain              -- �ڋq�敪�F18(�`�F�[���X)
      AND     cust_chain_party.duns_number_c      = cv_cust_status_99                -- �ڋq�X�e�[�^�X�F99�i�ΏۊO�j
      AND     cust_xref.inventory_item_id         = disc_item.inventory_item_id
      AND     params.organization_id              = gn_organization_id               -- �݌ɑg�DID
      AND     cust_xref.master_organization_id    = params.master_organization_id    -- �}�X�^�g�DID
-- 2009/10/02 M.Sano Ver.1.10 add Start
      AND     cust_xref.inactive_flag             = cv_inactive_flag_no              -- �L���t���O�FN
      AND     cust_xref.preference_number         = (
                SELECT MIN(cust_xref_ck.preference_number)
                FROM   mtl_customer_item_xrefs  cust_xref_ck
                WHERE  cust_xref_ck.customer_item_id       = cust_xref.customer_item_id
                AND    cust_xref_ck.master_organization_id = cust_xref.master_organization_id
                AND    cust_xref_ck.inactive_flag          = cv_inactive_flag_no
              )                                                                      -- �ŏ��̃����N
      AND     cust_item.inactive_flag             = cv_inactive_flag_no              -- �L���t���O�FN
-- 2009/10/02 M.Sano Ver.1.10 add End
      AND     cust_item.customer_item_number      = iv_product_code2                 -- ���i�R�[�h�Q
      AND     cust_item.item_definition_level     = cv_cust_item_def_level           -- ��`���x��
      AND     disc_item.segment1                  = opm_item.item_no                 -- �i�ڃR�[�h
      AND     disc_item.organization_id           = gn_organization_id;              -- �݌ɑg�DID
--
      RETURN 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 0;
--#################################  �Œ��O������ START   ####################################
--
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
        RETURN 0;
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
        RETURN 0;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
        -- ���O�o��
        proc_msg_output( cv_prg_name, ov_errbuf );
        RETURN 0;
--
--#####################################  �Œ蕔 END   ##########################################
    END;
--
    -- -------------------------------
    -- DISC�i�ڏ��擾
    -- -------------------------------
    PROCEDURE get_disc_item_info(
      iv_item_no            IN  VARCHAR2,         -- IN�F�i�ڃR�[�h
      on_item_id            OUT NOCOPY NUMBER,    -- OUT�F�i��ID
      ov_unit               OUT NOCOPY VARCHAR2   -- OUT�F�P��
    )
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'get_disc_item_info'; -- �v���O������
-- 2009/06/29 M.Sano Ver.1.6 add End
    BEGIN
--
      SELECT  disc_item.inventory_item_id,                       -- �i��ID
              disc_item.primary_unit_of_measure                  -- �P��
      INTO    on_item_id,
              ov_unit
      FROM    mtl_system_items_b        disc_item                -- Disc�i��
      WHERE   disc_item.segment1        = iv_item_no             -- �i�ڃR�[�h
      AND     disc_item.organization_id = gn_organization_id;    -- �݌ɑg�DID
--
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--#################################  �Œ��O������ START   ####################################
--
      -- *** ���ʊ֐���O�n���h�� ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      WHEN global_api_others_expt THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
        -- ���O�o��
        proc_msg_output( cv_prg_name, ov_errbuf );
--
--#####################################  �Œ蕔 END   ##########################################
    END;
--
    -- -------------------------------
    -- �i�ڏ��`�F�b�N
    -- -------------------------------
    PROCEDURE item_code_check(
      iv_edi_item_code_div    IN  VARCHAR2,                      -- IN�FEDI�A�g�i�ڃR�[�h�敪
      it_edi_work             IN  g_edi_work_rtype,              -- IN�FEDI�󒍏�񃏁[�N���R�[�h
      ot_item_info_rec        OUT NOCOPY l_item_info_rtype,      -- OUT�F�i�ڏ��
      ov_check_status         OUT NOCOPY VARCHAR2                -- OUT�F�`�F�b�N�X�e�[�^�X
    )
    IS
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- ===============================
      -- �Œ胍�[�J���萔
      -- ===============================
      cv_prg_name   CONSTANT VARCHAR2(100) := 'item_code_check'; -- �v���O������
-- 2009/06/29 M.Sano Ver.1.6 add End
      -- *** ���[�J���ϐ� ***
      lv_error_type           VARCHAR2(1);
      lv_msg_prod_type        VARCHAR2(50);
      lv_dummy_item           xxcos_edi_lines.item_code%TYPE;
      ln_rowcount             NUMBER := 0;
--
    BEGIN
--
      -- OUT�p�����[�^(�i�ڏ��)������
      ov_check_status                  := cv_edi_status_normal;
      ot_item_info_rec.item_id         := 0;
      ot_item_info_rec.item_no         := NULL;
      ot_item_info_rec.cust_order_flag := NULL;
      ot_item_info_rec.sales_class     := NULL;
      ot_item_info_rec.unit            := NULL;
      ot_item_info_rec.unit_price      := 0;
--
      -- EDI�A�g�i�ڃR�[�h�敪���uJAN�R�[�h�v�̏ꍇ
      IF ( iv_edi_item_code_div = cv_item_code_div_jan ) THEN
--
        -- �i�ڃ^�C�v�FJAN�R�[�h
        lv_msg_prod_type := cv_msg_prod_type_jan;
--
        -- JAN�R�[�h���擾
        ln_rowcount := get_jan_code_item(
--****************************** 2009/05/19 1.5 T.Kitajima MOD START ******************************--
--                         it_edi_work.product_code2,
                         it_edi_work,
--****************************** 2009/05/19 1.5 T.Kitajima MOD  END  ******************************--
                         ot_item_info_rec.item_id,
                         ot_item_info_rec.item_no,
                         ot_item_info_rec.cust_order_flag,
                         ot_item_info_rec.sales_class,
                         ot_item_info_rec.unit
                       );
--
        -- �f�[�^���擾�ł��Ȃ������ꍇ
        IF ( ln_rowcount = 0 ) THEN
--
          -- �P�[�XJAN�R�[�h���擾
          ln_rowcount := get_case_jan_code_item(
--****************************** 2009/05/19 1.5 T.Kitajima MOD START ******************************--
--                           it_edi_work.product_code2,
                           it_edi_work,
--****************************** 2009/05/19 1.5 T.Kitajima MOD  END  ******************************--
                           ot_item_info_rec.item_id,
                           ot_item_info_rec.item_no,
                           ot_item_info_rec.cust_order_flag,
                           ot_item_info_rec.sales_class,
                           ot_item_info_rec.unit
                         );
--
        END IF;
--
      -- EDI�A�g�i�ڃR�[�h�敪���u�ڋq�i�ځv�̏ꍇ
      ELSIF ( iv_edi_item_code_div = cv_item_code_div_cust ) THEN
--
        -- �i�ڃ^�C�v�F�ڋq�i��
        lv_msg_prod_type := cv_msg_prod_type_cust;
--
        -- �ڋq�i�ڏ��擾
        ln_rowcount := get_cust_item(
                         it_edi_work.edi_chain_code,
                         it_edi_work.product_code2,
                         ot_item_info_rec.item_id,
                         ot_item_info_rec.item_no,
                         ot_item_info_rec.cust_order_flag,
                         ot_item_info_rec.sales_class,
                         ot_item_info_rec.unit
                       );
--
      END IF;
--
      -- EDI�_�~�[�i�ځAEDI�i�ڃG���[�^�C�v��������
      lv_error_type := NULL;
      lv_dummy_item := NULL;
--
      -- �Y���f�[�^�Ȃ�
      IF ( ln_rowcount = 0 ) THEN
        -- �i�ڃG���[�^�C�v�P��ݒ�
        lv_error_type := cv_error_item_type_1;
--
      -- �ڋq�󒍉\�t���O��'Y'�̏ꍇ
      ELSIF (( ot_item_info_rec.cust_order_flag IS NULL )
         OR ( ot_item_info_rec.cust_order_flag != cv_cust_order_flag )) THEN
        -- �i�ڃG���[�^�C�v�Q��ݒ�
        lv_error_type := cv_error_item_type_2;
--
      -- ����Ώۋ敪���P�̏ꍇ
      ELSIF (( ot_item_info_rec.sales_class IS NULL )
         OR ( ot_item_info_rec.sales_class != cv_sales_class )) THEN
        -- �i�ڃG���[�^�C�v�R��ݒ�
        lv_error_type := cv_error_item_type_3;
--
      END IF;
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--      -- EDI�i�ڃG���[�̏ꍇ
--      IF ( lv_error_type IS NOT NULL ) THEN
      -- �`�F�b�N�����L���EDI�i�ڃG���[�̏ꍇ�A�G���[�������s�Ȃ��B
      IF ( ( gn_check_record_flag = cn_check_record_yes )
      AND  ( lv_error_type IS NOT NULL ) ) THEN
-- 2009/06/29 M.Sano Ver.1.6 mod End
        -- ���i�R�[�h�ϊ��G���[���o��
        lv_tkn1   := xxccp_common_pkg.get_msg( cv_application, lv_msg_prod_type );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application,
                                               cv_msg_item_conv,
                                               cv_tkn_prod_code,
                                               it_edi_work.product_code2,
                                               cv_tkn_prod_type,
                                               lv_tkn1
                                             );
        lv_errbuf := lv_errmsg;
        -- ���O�o��
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- �x���X�e�[�^�X�ݒ�
        ov_check_status := cv_edi_status_warning;
--
        -- �_�~�[�i�ڃR�[�h���擾
        IF ( gt_edi_item_err_type.EXISTS( lv_error_type ) ) THEN
          lv_dummy_item := gt_edi_item_err_type( lv_error_type );
        END IF;
--
        -- �i�ڃR�[�h�Ƀ_�~�[�i�ڂ�ݒ肷��
        ot_item_info_rec.item_no := lv_dummy_item;
--
        -- DISC�i�ڏ����擾
        get_disc_item_info( ot_item_info_rec.item_no,
                            ot_item_info_rec.item_id,
                            ot_item_info_rec.unit );
--
-- 2010/01/19 Ver.1.15 M.Sano mod Start
--        -- EDI�G���[���ǉ�
--        proc_set_edi_errors( it_edi_work, lv_dummy_item, cv_error_delete_flag, cv_msg_rep_item_conv );
        -- EDI�G���[���ǉ�
        -- �EJAN�R�[�h �� �u���i�R�[�h�ϊ��G���[�v �ڋq�i�� �� �u�ڋq�i�ڕϊ��G���[�v
        IF ( iv_edi_item_code_div = cv_item_code_div_jan ) THEN
          proc_set_edi_errors( it_edi_work, lv_dummy_item, cv_error_delete_flag, cv_msg_rep_item_conv );
        ELSIF ( iv_edi_item_code_div = cv_item_code_div_cust ) THEN
          proc_set_edi_errors( it_edi_work, lv_dummy_item, cv_error_delete_flag, cv_msg_rep_cust_item );
        END IF;
-- 2010/01/19 Ver.1.15 M.Sano mod End
--
        -- �G���[�����C���N�������g
        gn_warn_cnt := gn_warn_cnt + 1;
--
      END IF;
--
    END;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- EDI�󒍏�񃏁[�N�f�[�^�����ݒ�̏ꍇ�͏����I��
    IF ( gt_edi_work.COUNT = 0 ) THEN
      RETURN;
    END IF;
--
    -- ����X�e�[�^�X�ݒ�
    gt_edi_work(gt_edi_work.first).check_status := cv_edi_status_normal;
--
    -- �`�[�G���[�t���O������
    gn_invoice_err_flag := 0;
-- 2010/01/19 Ver.1.15 M.Sano add Start
    -- �ŏI�s�̍sNo���擾����B
    ln_new_line_no := gt_edi_work( gt_edi_work.last ).line_no;
-- 2010/01/19 Ver.1.15 M.Sano add End
-- 2009/06/29 M.Sano Ver.1.6 add Start
--
    -- �`�F�b�N�Ώۂ̗L�����擾����B
    IF ( ( gt_edi_work(gt_edi_work.first).info_class IS NULL )
    OR   ( gt_edi_work(gt_edi_work.first).info_class  = cv_info_class_01 )
-- 2010/01/19 Ver.1.15 M.Sano add Start
    OR   ( gt_edi_work(gt_edi_work.first).info_class  = cv_info_class_04 )
-- 2010/01/19 Ver.1.15 M.Sano add End
    OR   ( gt_edi_work(gt_edi_work.first).info_class  = cv_info_class_02 ) ) THEN
      gn_check_record_flag := cn_check_record_yes;
    ELSE
      gn_check_record_flag := cn_check_record_no;
    END IF;
-- 2009/06/29 M.Sano Ver.1.6 add End
-- 2010/01/19 Ver.1.15 M.Sano add Start
--
    ----------------------------------------
    -- �ڋq�R�[�h�ϊ��`�F�b�N
    ----------------------------------------
    -- �X�R�[�h��NULL�ȊO�̏ꍇ
    IF ( gt_edi_work(gt_edi_work.first).shop_code IS NOT NULL ) THEN
      --�`�F�[���X�E�X�R�[�h����ڋq�����擾����B
      customer_conv_check(
        gt_edi_work(gt_edi_work.first),        -- IN�FEDI�󒍏�񃏁[�N�f�[�^
        lt_cust_info_rec,                      -- OUT�F�ڋq���
        lv_check_status                        -- OUT�F�`�F�b�N�X�e�[�^�X
      );
--
      -- �G���[�`�F�b�N
      -- �E�G���[���A�S�f�[�^�̃X�e�[�^�X���x���ɕύX��A�`�F�b�N�����I��
      IF ( lv_check_status != cv_edi_status_normal ) THEN
        set_check_status_all( lv_check_status );
        ov_retcode := cv_status_warn;
        RETURN;
      END IF;
    END IF;
-- 2010/01/19 Ver.1.15 M.Sano add end
--
    ----------------------------------------
    -- �K�{���̓`�F�b�N
    ----------------------------------------
    IF ( check_required( gt_edi_work )  != 0 ) THEN
      -- �S�f�[�^�Ɍx���X�e�[�^�X��ݒ�
      set_check_status_all( cv_edi_status_warning );
      -- �`�[�G���[�t���O�ݒ�
      gn_invoice_err_flag := 1;
      -- �`�F�b�N�����I��
      ov_retcode := cv_status_warn;
      RETURN;
    END IF;
--
-- 2010/01/19 Ver.1.15 M.Sano del Start
--    -- �ڋq�R�[�h�ϊ��`�F�b�N
--    customer_conv_check(
--      gt_edi_work(gt_edi_work.first),        -- IN�FEDI�󒍏�񃏁[�N�f�[�^
--      lt_cust_info_rec,                      -- OUT�F�ڋq���
--      lv_check_status                        -- OUT�F�`�F�b�N�X�e�[�^�X
--    );
----
--    -- �X�e�[�^�X������ȊO�́A�X�e�[�^�X��ݒ�
--    IF ( lv_check_status != cv_edi_status_normal ) THEN
--      -- �S�f�[�^�ɃX�e�[�^�X��ݒ�
--      set_check_status_all( lv_check_status );
--      -- �`�F�b�N�����I��
--      ov_retcode := cv_status_warn;
--      RETURN;
--    END IF;
-- 2010/01/19 Ver.1.15 M.Sano del end
--
    -- EDI�A�g�i�ڃR�[�h�敪���擾
    get_edi_item_code_div(
      gt_edi_work(gt_edi_work.first).edi_chain_code,
      lv_edi_item_code_div
    );
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--    -- EDI�A�g�i�ڃR�[�h�敪���u0:�Ȃ��v�̏ꍇ
--    IF ( NVL( lv_edi_item_code_div, 0 ) = 0 ) THEN
    -- �`�F�b�N�Ώۂ�EDI�A�g�i�ڃR�[�h�敪���u0:�Ȃ��v�̏ꍇ
    IF ( ( gn_check_record_flag = cn_check_record_yes )
    AND  ( NVL( lv_edi_item_code_div, 0 ) = 0 ) ) THEN
-- 2009/06/29 M.Sano Ver.1.6 mod End
      -- EDI�A�g�i�ڃR�[�h�敪�G���[���o��
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_edi_item,
                                             cv_tkn_chain_shop_code,
                                             gt_edi_work(gt_edi_work.first).edi_chain_code
                                           );
      lv_errbuf := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      -- �S�f�[�^�Ɍx���X�e�[�^�X��ݒ�
      set_check_status_all( cv_edi_status_warning );
      -- EDI�G���[���ǉ�
      proc_set_edi_errors( gt_edi_work(gt_edi_work.first), NULL, NULL, cv_msg_rep_edi_item );
      -- �`�[�G���[�t���O�ݒ�
      gn_invoice_err_flag := 1;
      -- �`�F�b�N�����I��
      ov_retcode := cv_status_warn;
      RETURN;
    END IF;
--
-- 2010/01/19 Ver.1.15 M.Sano add Start
    ----------------------------------------
    -- �c�ƒS�������݃`�F�b�N
    ----------------------------------------
    get_salesrep_id(
      lt_cust_info_rec.conv_cust_code,            -- IN �F�ڋq�R�[�h
      gt_edi_work(gt_edi_work.first).order_date,  -- IN �F�󒍓�
      lt_salesrep_id                              -- OUT�F�c�ƒS����ID
    );
    IF ( lt_salesrep_id IS NULL AND gn_check_record_flag = cn_check_record_yes )THEN
      -- �c�ƒS�����擾�G���[���o��
      lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_application
                     , cv_msg_salesrep_err
                     , cv_tkn_chain_shop_code
                     , gt_edi_work(gt_edi_work.first).edi_chain_code
                     , cv_tkn_shop_code
                     , gt_edi_work(gt_edi_work.first).shop_code
                     , cv_tkn_cust_code
                     , lt_cust_info_rec.conv_cust_code
                     , cv_tkn_order_no
                     , gt_edi_work(gt_edi_work.first).invoice_number
                     , cv_tkn_store_deliv_dt
                     , TO_CHAR( gt_edi_work(gt_edi_work.first).shop_delivery_date
                              , cv_format_yyyymmdds )
                   );
      lv_errbuf := lv_errmsg;
      -- ���O�o��
      proc_msg_output( cv_prg_name, lv_errbuf );
      -- �S�f�[�^�Ɍx���X�e�[�^�X��ݒ�
      set_check_status_all( cv_edi_status_warning );
      -- EDI�G���[���ǉ�
      proc_set_edi_errors( gt_edi_work(gt_edi_work.first), NULL, NULL, cv_msg_rep_salesrep );
      -- �`�[�G���[�t���O�ݒ�
      gn_invoice_err_flag := 1;
      -- �`�F�b�N�����I��
      ov_retcode := cv_status_warn;
      RETURN;
    END IF;
-- 2010/01/19 Ver.1.15 M.Sano add End
    -- ����`�[���̑S���ׂ̃`�F�b�N
    <<loop_edi_lines_check>>
    FOR ln_Idx IN 1..gt_edi_work.COUNT LOOP
--
      -- ����X�e�[�^�X�ݒ�
      gt_edi_work(ln_idx).check_status := cv_edi_status_normal;
--
      ----------------------------------------
      -- ���i�R�[�h�ϊ��`�F�b�N
      ----------------------------------------
      item_code_check(
        lv_edi_item_code_div,                -- IN�FEDI�A�g�i�ڃR�[�h�敪
        gt_edi_work(ln_idx),                 -- IN�FEDI�󒍏�񃏁[�N�f�[�^
        lt_item_info_rec,                    -- OUT�F�ڋq���
        lv_check_status                      -- OUT�F�`�F�b�N�X�e�[�^�X
      );
--
      -- �X�e�[�^�X������ȊO�́A�X�e�[�^�X��ݒ�
      IF ( lv_check_status != cv_edi_status_normal ) THEN
        gt_edi_work(ln_idx).check_status := lv_check_status;
      END IF;
--
      -- �i�ڃR�[�h��ݒ�
      gt_edi_work(ln_idx).item_code := lt_item_info_rec.item_no;
--
      -- ���גP�ʂ�ݒ�
      gt_edi_work(ln_idx).line_uom := lt_item_info_rec.unit;
--
      -- �ϊ���ڋq�R�[�h��ݒ�
      gt_edi_work(ln_idx).conv_customer_code := lt_cust_info_rec.conv_cust_code;
-- 2009/12/28 M.Sano Ver.1.14 add Start
--
      -- �ʉߍ݌Ɍ^�敪��ݒ�
      gt_edi_work(ln_idx).tsukagatazaiko_div := lt_cust_info_rec.tsukagatazaiko_div;
--
      -- �󒍘A�g�σt���O��ݒ�
      IF (  gt_lookup_tsukagata_divs.EXISTS(lt_cust_info_rec.tsukagatazaiko_div)
-- 2010/01/19 Ver.1.15 M.Sano add Start
--        AND gn_check_record_flag = cn_check_record_yes
          AND (   gt_edi_work(gt_edi_work.first).info_class IS NULL
               OR gt_edi_work(gt_edi_work.first).info_class  = cv_info_class_01
               OR gt_edi_work(gt_edi_work.first).info_class  = cv_info_class_02 )
-- 2010/01/19 Ver.1.15 M.Sano add End
      ) THEN
        gt_edi_work(gt_edi_work.first).order_forward_flag := cv_order_forward_flag;
      ELSE
        gt_edi_work(gt_edi_work.first).order_forward_flag := cv_order_forward_no;
      END IF;
-- 2009/12/28 M.Sano Ver.1.14 add End
--
      ----------------------------------------
      -- �P������ݒ�
      -- �����P���i�����j�����ݒ�̏ꍇ�́A���i�\�̒P����ݒ肷��
      ----------------------------------------
      -- ���P���i�����j�����ݒ�̏ꍇ
      IF ( NVL( gt_edi_work(ln_idx).order_unit_price, 0 ) = 0 ) THEN
--
        -- ���i�\�w�b�_ID���ݒ肳��Ă���ꍇ
        IF ( lt_cust_info_rec.price_list_id IS NOT NULL ) THEN
--
          -- ���ʊ֐��ɂ��P�����擾
          lt_item_info_rec.unit_price := xxcos_common2_pkg.get_unit_price(
                                           lt_item_info_rec.item_id,
                                           lt_cust_info_rec.price_list_id,
                                           lt_item_info_rec.unit
                                         );
--
          -- �P�����擾�ł����ꍇ
          IF ( lt_item_info_rec.unit_price > 0 ) THEN
--
            -- �擾�����P����ݒ�
            gt_edi_work(ln_idx).order_unit_price := lt_item_info_rec.unit_price;
            -- ���i�\�w�b�_ID��ݒ�i�P���R�[�h�ځj
            gt_edi_work(gt_edi_work.first).price_list_header_id := lt_cust_info_rec.price_list_id;
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--          ELSE
          -- ��L�ȊO�ŁA�`�F�b�N�Ώۂ̏ꍇ�̓G���[
          ELSIF (gn_check_record_flag = cn_check_record_yes) THEN
-- 2009/06/29 M.Sano Ver.1.6 mod End
            -- �P�����擾�ł��Ȃ������i���ʊ֐��ŃG���[�j�ꍇ
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_price_err );
            lv_errbuf := lv_errmsg;
            -- ���O�o��
            proc_msg_output( cv_prg_name, lv_errbuf );
            -- �x���X�e�[�^�X�ݒ�
            gt_edi_work(ln_idx).check_status := cv_edi_status_warning;
            -- EDI�G���[���ǉ�
            proc_set_edi_errors( gt_edi_work(ln_idx), NULL, cv_error_delete_flag, cv_msg_rep_price_err );
            -- �G���[�����C���N�������g
            gn_warn_cnt := gn_warn_cnt + 1;
--
          END IF;
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--        ELSE
        -- ��L�ȊO�ŁA�`�F�b�N�Ώۂ̏ꍇ�̓G���[
        ELSIF (gn_check_record_flag = cn_check_record_yes) THEN
-- 2009/06/29 M.Sano Ver.1.6 mod End
          -- ���i�\���ݒ�G���[���o��
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application,
                                                 cv_msg_price_list,
                                                 cv_tkn_chain_shop_code,
                                                 gt_edi_work(ln_idx).edi_chain_code,
                                                 cv_tkn_shop_code,
                                                 gt_edi_work(ln_idx).shop_code
                                               );
          lv_errbuf := lv_errmsg;
          -- ���O�o��
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- �x���X�e�[�^�X�ݒ�
          gt_edi_work(ln_idx).check_status := cv_edi_status_warning;
          -- EDI�G���[���ǉ�
          proc_set_edi_errors( gt_edi_work(ln_idx), NULL, cv_error_delete_flag, cv_msg_rep_price_list );
          -- �G���[�����C���N�������g
          gn_warn_cnt := gn_warn_cnt + 1;
--
        END IF;
--
      END IF;
--
-- 2010/01/19 Ver.1.15 M.Sano add Start
      ----------------------------------------
      -- �sNo�d���`�F�b�N
      ----------------------------------------
      -- 1���R�[�h�ڈȊO�őO���R�[�h�Ɠ���̍sNo�̏ꍇ
      IF ( ln_idx <> 1 AND gt_edi_work(ln_idx - 1).line_no = gt_edi_work(ln_idx).line_no ) THEN
        -- �󒍊֘A���הԍ��ɍsNo�̍ő�l+1��ݒ肷��B
        ln_new_line_no := ln_new_line_no + 1;
        gt_edi_work(ln_idx).order_connection_line_number := ln_new_line_no;
        -- �`�F�b�N�Ώۂ̏ꍇ�A�sNo�d���G���[
        IF ( gn_check_record_flag = cn_check_record_yes ) THEN
          -- �sNo�d���G���[���o��
          lv_errmsg := xxccp_common_pkg.get_msg(
                           cv_application
                         , cv_msg_line_no_err
                         , cv_tkn_new_line_no
                         , gt_edi_work(ln_idx).order_connection_line_number
                         , cv_tkn_chain_shop_code
                         , gt_edi_work(ln_idx).edi_chain_code
                         , cv_tkn_shop_code
                         , gt_edi_work(ln_idx).shop_code
                         , cv_tkn_order_no
                         , gt_edi_work(ln_idx).invoice_number
                         , cv_tkn_store_deliv_dt
                         , TO_CHAR( gt_edi_work(ln_idx).shop_delivery_date, cv_format_yyyymmdds )
                         , cv_tkn_line_no
                         , gt_edi_work(ln_idx).line_no
                       );
          lv_errbuf := lv_errmsg;
          -- ���O�o��
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- �x���X�e�[�^�X�ݒ�
          gt_edi_work(ln_idx).check_status := cv_edi_status_warning;
          -- EDI�G���[���ǉ�
          proc_set_edi_errors( gt_edi_work(ln_idx), NULL, cv_error_delete_flag, cv_msg_rep_line_no );
          -- �G���[�����C���N�������g
          gn_warn_cnt := gn_warn_cnt + 1;
        END IF;
      ELSE
        -- �󒍊֘A���הԍ��ɍsNo��ݒ肷��B
        gt_edi_work(ln_idx).order_connection_line_number := gt_edi_work(ln_idx).line_no;
      END IF;
--
-- 2010/01/19 Ver.1.15 M.Sano add End
      -- �������z(����)���Čv�Z�y��������(���v�A�o��)�~���P��(����)�z
-- 2009/08/06 Ver.1.8 M.Sano Mod Start
--      gt_edi_work(ln_idx).order_cost_amt := NVL( gt_edi_work(ln_idx).sum_order_qty, 0 )
--                                          * NVL( gt_edi_work(ln_idx).order_unit_price, 0 );
      IF ( NVL(gt_edi_work(ln_idx).order_cost_amt, 0) = 0 ) THEN
        gt_edi_work(ln_idx).order_cost_amt := TRUNC(NVL( gt_edi_work(ln_idx).sum_order_qty, 0 )
                                                    * NVL( gt_edi_work(ln_idx).order_unit_price, 0 ));
      END IF;
-- 2009/08/06 Ver.1.8 M.Sano Mod End
--
      -- �`�[�G���[�t���O���G���[�ɂȂ��Ă���ꍇ
      IF ( gn_invoice_err_flag = 1 ) THEN
        -- �x���X�e�[�^�X�ݒ�
        gt_edi_work(ln_idx).check_status := cv_edi_status_warning;
      END IF;
--
      -- �����ꂩ�̃`�F�b�N�ŃG���[�ɂȂ��Ă���ꍇ
      IF ( gt_edi_work(ln_idx).check_status != cv_edi_status_normal ) THEN
        -- �I���X�e�[�^�X�Ɍx����ݒ�
        lv_retcode := cv_status_warn;
      END IF;
--
    END LOOP;
--
    -- �I���X�e�[�^�X�ݒ�
    ov_retcode := lv_retcode;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- ���O�o��
      proc_msg_output( cv_prg_name, ov_errbuf );
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_data_validate;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_edi_work
   * Description      : EDI�󒍏�񃏁[�N�ϐ��ɐݒ肷��(A-5)
   ***********************************************************************************/
  PROCEDURE proc_set_edi_work(
    it_edi_work   IN  edi_order_work_cur%ROWTYPE,      -- EDI�󒍏�񃏁[�N�f�[�^
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_edi_work'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx     NUMBER;
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
    gt_edi_work.EXTEND;
    ln_idx := gt_edi_work.COUNT;
--
    gt_edi_work(ln_idx).order_info_work_id             := it_edi_work.order_info_work_id;                -- �󒍏�񃏁[�NID
    gt_edi_work(ln_idx).medium_class                   := it_edi_work.medium_class;                      -- �}�̋敪
    gt_edi_work(ln_idx).data_type_code                 := it_edi_work.data_type_code;                    -- �f�[�^��R�[�h
    gt_edi_work(ln_idx).file_no                        := it_edi_work.file_no;                           -- �t�@�C���m��
    gt_edi_work(ln_idx).info_class                     := it_edi_work.info_class;                        -- ���敪
    gt_edi_work(ln_idx).process_date                   := it_edi_work.process_date;                      -- ������
    gt_edi_work(ln_idx).process_time                   := it_edi_work.process_time;                      -- ��������
    gt_edi_work(ln_idx).base_code                      := it_edi_work.base_code;                         -- ���_�i����j�R�[�h
    gt_edi_work(ln_idx).base_name                      := it_edi_work.base_name;                         -- ���_���i�������j
    gt_edi_work(ln_idx).base_name_alt                  := it_edi_work.base_name_alt;                     -- ���_���i�J�i�j
    gt_edi_work(ln_idx).edi_chain_code                 := it_edi_work.edi_chain_code;                    -- �d�c�h�`�F�[���X�R�[�h
    gt_edi_work(ln_idx).edi_chain_name                 := it_edi_work.edi_chain_name;                    -- �d�c�h�`�F�[���X���i�����j
    gt_edi_work(ln_idx).edi_chain_name_alt             := it_edi_work.edi_chain_name_alt;                -- �d�c�h�`�F�[���X���i�J�i�j
    gt_edi_work(ln_idx).chain_code                     := it_edi_work.chain_code;                        -- �`�F�[���X�R�[�h
    gt_edi_work(ln_idx).chain_name                     := it_edi_work.chain_name;                        -- �`�F�[���X���i�����j
    gt_edi_work(ln_idx).chain_name_alt                 := it_edi_work.chain_name_alt;                    -- �`�F�[���X���i�J�i�j
    gt_edi_work(ln_idx).report_code                    := it_edi_work.report_code;                       -- ���[�R�[�h
    gt_edi_work(ln_idx).report_show_name               := it_edi_work.report_show_name;                  -- ���[�\����
    gt_edi_work(ln_idx).customer_code                  := it_edi_work.customer_code;                     -- �ڋq�R�[�h
    gt_edi_work(ln_idx).customer_name                  := it_edi_work.customer_name;                     -- �ڋq���i�����j
    gt_edi_work(ln_idx).customer_name_alt              := it_edi_work.customer_name_alt;                 -- �ڋq���i�J�i�j
    gt_edi_work(ln_idx).company_code                   := it_edi_work.company_code;                      -- �ЃR�[�h
    gt_edi_work(ln_idx).company_name                   := it_edi_work.company_name;                      -- �Ж��i�����j
    gt_edi_work(ln_idx).company_name_alt               := it_edi_work.company_name_alt;                  -- �Ж��i�J�i�j
    gt_edi_work(ln_idx).shop_code                      := it_edi_work.shop_code;                         -- �X�R�[�h
    gt_edi_work(ln_idx).shop_name                      := it_edi_work.shop_name;                         -- �X���i�����j
    gt_edi_work(ln_idx).shop_name_alt                  := it_edi_work.shop_name_alt;                     -- �X���i�J�i�j
    gt_edi_work(ln_idx).delivery_center_code           := it_edi_work.delivery_center_code;              -- �[���Z���^�[�R�[�h
    gt_edi_work(ln_idx).delivery_center_name           := it_edi_work.delivery_center_name;              -- �[���Z���^�[���i�����j
    gt_edi_work(ln_idx).delivery_center_name_alt       := it_edi_work.delivery_center_name_alt;          -- �[���Z���^�[���i�J�i�j
    gt_edi_work(ln_idx).order_date                     := it_edi_work.order_date;                        -- ������
    gt_edi_work(ln_idx).center_delivery_date           := it_edi_work.center_delivery_date;              -- �Z���^�[�[�i��
    gt_edi_work(ln_idx).result_delivery_date           := it_edi_work.result_delivery_date;              -- ���[�i��
    gt_edi_work(ln_idx).shop_delivery_date             := it_edi_work.shop_delivery_date;                -- �X�ܔ[�i��
    gt_edi_work(ln_idx).data_creation_date_edi_data    := it_edi_work.data_creation_date_edi_data;       -- �f�[�^�쐬���i�d�c�h�f�[�^���j
    gt_edi_work(ln_idx).data_creation_time_edi_data    := it_edi_work.data_creation_time_edi_data;       -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
    gt_edi_work(ln_idx).invoice_class                  := it_edi_work.invoice_class;                     -- �`�[�敪
    gt_edi_work(ln_idx).small_classification_code      := it_edi_work.small_classification_code;         -- �����ރR�[�h
    gt_edi_work(ln_idx).small_classification_name      := it_edi_work.small_classification_name;         -- �����ޖ�
    gt_edi_work(ln_idx).middle_classification_code     := it_edi_work.middle_classification_code;        -- �����ރR�[�h
    gt_edi_work(ln_idx).middle_classification_name     := it_edi_work.middle_classification_name;        -- �����ޖ�
    gt_edi_work(ln_idx).big_classification_code        := it_edi_work.big_classification_code;           -- �啪�ރR�[�h
    gt_edi_work(ln_idx).big_classification_name        := it_edi_work.big_classification_name;           -- �啪�ޖ�
    gt_edi_work(ln_idx).other_party_department_code    := it_edi_work.other_party_department_code;       -- ����敔��R�[�h
    gt_edi_work(ln_idx).other_party_order_number       := it_edi_work.other_party_order_number;          -- ����攭���ԍ�
    gt_edi_work(ln_idx).check_digit_class              := it_edi_work.check_digit_class;                 -- �`�F�b�N�f�W�b�g�L���敪
    gt_edi_work(ln_idx).invoice_number                 := it_edi_work.invoice_number;                    -- �`�[�ԍ�
    gt_edi_work(ln_idx).check_digit                    := it_edi_work.check_digit;                       -- �`�F�b�N�f�W�b�g
    gt_edi_work(ln_idx).close_date                     := it_edi_work.close_date;                        -- ����
    gt_edi_work(ln_idx).order_no_ebs                   := it_edi_work.order_no_ebs;                      -- �󒍂m���i�d�a�r�j
    gt_edi_work(ln_idx).ar_sale_class                  := it_edi_work.ar_sale_class;                     -- �����敪
    gt_edi_work(ln_idx).delivery_classe                := it_edi_work.delivery_classe;                   -- �z���敪
    gt_edi_work(ln_idx).opportunity_no                 := it_edi_work.opportunity_no;                    -- �ւm��
    gt_edi_work(ln_idx).contact_to                     := it_edi_work.contact_to;                        -- �A����
    gt_edi_work(ln_idx).route_sales                    := it_edi_work.route_sales;                       -- ���[�g�Z�[���X
    gt_edi_work(ln_idx).corporate_code                 := it_edi_work.corporate_code;                    -- �@�l�R�[�h
    gt_edi_work(ln_idx).maker_name                     := it_edi_work.maker_name;                        -- ���[�J�[��
    gt_edi_work(ln_idx).area_code                      := it_edi_work.area_code;                         -- �n��R�[�h
    gt_edi_work(ln_idx).area_name                      := it_edi_work.area_name;                         -- �n�於�i�����j
    gt_edi_work(ln_idx).area_name_alt                  := it_edi_work.area_name_alt;                     -- �n�於�i�J�i�j
    gt_edi_work(ln_idx).vendor_code                    := it_edi_work.vendor_code;                       -- �����R�[�h
    gt_edi_work(ln_idx).vendor_name                    := it_edi_work.vendor_name;                       -- ����於�i�����j
    gt_edi_work(ln_idx).vendor_name1_alt               := it_edi_work.vendor_name1_alt;                  -- ����於�P�i�J�i�j
    gt_edi_work(ln_idx).vendor_name2_alt               := it_edi_work.vendor_name2_alt;                  -- ����於�Q�i�J�i�j
    gt_edi_work(ln_idx).vendor_tel                     := it_edi_work.vendor_tel;                        -- �����s�d�k
    gt_edi_work(ln_idx).vendor_charge                  := it_edi_work.vendor_charge;                     -- �����S����
    gt_edi_work(ln_idx).vendor_address                 := it_edi_work.vendor_address;                    -- �����Z���i�����j
    gt_edi_work(ln_idx).deliver_to_code_itouen         := it_edi_work.deliver_to_code_itouen;            -- �͂���R�[�h�i�ɓ����j
    gt_edi_work(ln_idx).deliver_to_code_chain          := it_edi_work.deliver_to_code_chain;             -- �͂���R�[�h�i�`�F�[���X�j
    gt_edi_work(ln_idx).deliver_to                     := it_edi_work.deliver_to;                        -- �͂���i�����j
    gt_edi_work(ln_idx).deliver_to1_alt                := it_edi_work.deliver_to1_alt;                   -- �͂���P�i�J�i�j
    gt_edi_work(ln_idx).deliver_to2_alt                := it_edi_work.deliver_to2_alt;                   -- �͂���Q�i�J�i�j
    gt_edi_work(ln_idx).deliver_to_address             := it_edi_work.deliver_to_address;                -- �͂���Z���i�����j
    gt_edi_work(ln_idx).deliver_to_address_alt         := it_edi_work.deliver_to_address_alt;            -- �͂���Z���i�J�i�j
    gt_edi_work(ln_idx).deliver_to_tel                 := it_edi_work.deliver_to_tel;                    -- �͂���s�d�k
    gt_edi_work(ln_idx).balance_accounts_code          := it_edi_work.balance_accounts_code;             -- ������R�[�h
    gt_edi_work(ln_idx).balance_accounts_company_code  := it_edi_work.balance_accounts_company_code;     -- ������ЃR�[�h
    gt_edi_work(ln_idx).balance_accounts_shop_code     := it_edi_work.balance_accounts_shop_code;        -- ������X�R�[�h
    gt_edi_work(ln_idx).balance_accounts_name          := it_edi_work.balance_accounts_name;             -- �����於�i�����j
    gt_edi_work(ln_idx).balance_accounts_name_alt      := it_edi_work.balance_accounts_name_alt;         -- �����於�i�J�i�j
    gt_edi_work(ln_idx).balance_accounts_address       := it_edi_work.balance_accounts_address;          -- ������Z���i�����j
    gt_edi_work(ln_idx).balance_accounts_address_alt   := it_edi_work.balance_accounts_address_alt;      -- ������Z���i�J�i�j
    gt_edi_work(ln_idx).balance_accounts_tel           := it_edi_work.balance_accounts_tel;              -- ������s�d�k
    gt_edi_work(ln_idx).order_possible_date            := it_edi_work.order_possible_date;               -- �󒍉\��
    gt_edi_work(ln_idx).permission_possible_date       := it_edi_work.permission_possible_date;          -- ���e�\��
    gt_edi_work(ln_idx).forward_month                  := it_edi_work.forward_month;                     -- ����N����
    gt_edi_work(ln_idx).payment_settlement_date        := it_edi_work.payment_settlement_date;           -- �x�����ϓ�
    gt_edi_work(ln_idx).handbill_start_date_active     := it_edi_work.handbill_start_date_active;        -- �`���V�J�n��
    gt_edi_work(ln_idx).billing_due_date               := it_edi_work.billing_due_date;                  -- ��������
    gt_edi_work(ln_idx).shipping_time                  := it_edi_work.shipping_time;                     -- �o�׎���
    gt_edi_work(ln_idx).delivery_schedule_time         := it_edi_work.delivery_schedule_time;            -- �[�i�\�莞��
    gt_edi_work(ln_idx).order_time                     := it_edi_work.order_time;                        -- ��������
    gt_edi_work(ln_idx).general_date_item1             := it_edi_work.general_date_item1;                -- �ėp���t���ڂP
    gt_edi_work(ln_idx).general_date_item2             := it_edi_work.general_date_item2;                -- �ėp���t���ڂQ
    gt_edi_work(ln_idx).general_date_item3             := it_edi_work.general_date_item3;                -- �ėp���t���ڂR
    gt_edi_work(ln_idx).general_date_item4             := it_edi_work.general_date_item4;                -- �ėp���t���ڂS
    gt_edi_work(ln_idx).general_date_item5             := it_edi_work.general_date_item5;                -- �ėp���t���ڂT
    gt_edi_work(ln_idx).arrival_shipping_class         := it_edi_work.arrival_shipping_class;            -- ���o�׋敪
    gt_edi_work(ln_idx).vendor_class                   := it_edi_work.vendor_class;                      -- �����敪
    gt_edi_work(ln_idx).invoice_detailed_class         := it_edi_work.invoice_detailed_class;            -- �`�[����敪
    gt_edi_work(ln_idx).unit_price_use_class           := it_edi_work.unit_price_use_class;              -- �P���g�p�敪
    gt_edi_work(ln_idx).sub_distribution_center_code   := it_edi_work.sub_distribution_center_code;      -- �T�u�����Z���^�[�R�[�h
    gt_edi_work(ln_idx).sub_distribution_center_name   := it_edi_work.sub_distribution_center_name;      -- �T�u�����Z���^�[�R�[�h��
    gt_edi_work(ln_idx).center_delivery_method         := it_edi_work.center_delivery_method;            -- �Z���^�[�[�i���@
    gt_edi_work(ln_idx).center_use_class               := it_edi_work.center_use_class;                  -- �Z���^�[���p�敪
    gt_edi_work(ln_idx).center_whse_class              := it_edi_work.center_whse_class;                 -- �Z���^�[�q�ɋ敪
    gt_edi_work(ln_idx).center_area_class              := it_edi_work.center_area_class;                 -- �Z���^�[�n��敪
    gt_edi_work(ln_idx).center_arrival_class           := it_edi_work.center_arrival_class;              -- �Z���^�[���׋敪
    gt_edi_work(ln_idx).depot_class                    := it_edi_work.depot_class;                       -- �f�|�敪
    gt_edi_work(ln_idx).tcdc_class                     := it_edi_work.tcdc_class;                        -- �s�b�c�b�敪
    gt_edi_work(ln_idx).upc_flag                       := it_edi_work.upc_flag;                          -- �t�o�b�t���O
    gt_edi_work(ln_idx).simultaneously_class           := it_edi_work.simultaneously_class;              -- ��ċ敪
    gt_edi_work(ln_idx).business_id                    := it_edi_work.business_id;                       -- �Ɩ��h�c
    gt_edi_work(ln_idx).whse_directly_class            := it_edi_work.whse_directly_class;               -- �q���敪
    gt_edi_work(ln_idx).premium_rebate_class           := it_edi_work.premium_rebate_class;              -- �i�i���ߋ敪
    gt_edi_work(ln_idx).item_type                      := it_edi_work.item_type;                         -- ���ڎ��
    gt_edi_work(ln_idx).cloth_house_food_class         := it_edi_work.cloth_house_food_class;            -- �߉ƐH�敪
    gt_edi_work(ln_idx).mix_class                      := it_edi_work.mix_class;                         -- ���݋敪
    gt_edi_work(ln_idx).stk_class                      := it_edi_work.stk_class;                         -- �݌ɋ敪
    gt_edi_work(ln_idx).last_modify_site_class         := it_edi_work.last_modify_site_class;            -- �ŏI�C���ꏊ�敪
    gt_edi_work(ln_idx).report_class                   := it_edi_work.report_class;                      -- ���[�敪
    gt_edi_work(ln_idx).addition_plan_class            := it_edi_work.addition_plan_class;               -- �ǉ��E�v��敪
    gt_edi_work(ln_idx).registration_class             := it_edi_work.registration_class;                -- �o�^�敪
    gt_edi_work(ln_idx).specific_class                 := it_edi_work.specific_class;                    -- ����敪
    gt_edi_work(ln_idx).dealings_class                 := it_edi_work.dealings_class;                    -- ����敪
    gt_edi_work(ln_idx).order_class                    := it_edi_work.order_class;                       -- �����敪
    gt_edi_work(ln_idx).sum_line_class                 := it_edi_work.sum_line_class;                    -- �W�v���׋敪
    gt_edi_work(ln_idx).shipping_guidance_class        := it_edi_work.shipping_guidance_class;           -- �o�׈ē��ȊO�敪
    gt_edi_work(ln_idx).shipping_class                 := it_edi_work.shipping_class;                    -- �o�׋敪
    gt_edi_work(ln_idx).product_code_use_class         := it_edi_work.product_code_use_class;            -- ���i�R�[�h�g�p�敪
    gt_edi_work(ln_idx).cargo_item_class               := it_edi_work.cargo_item_class;                  -- �ϑ��i�敪
    gt_edi_work(ln_idx).ta_class                       := it_edi_work.ta_class;                          -- �s�^�`�敪
    gt_edi_work(ln_idx).plan_code                      := it_edi_work.plan_code;                         -- ���R�[�h
    gt_edi_work(ln_idx).category_code                  := it_edi_work.category_code;                     -- �J�e�S���[�R�[�h
    gt_edi_work(ln_idx).category_class                 := it_edi_work.category_class;                    -- �J�e�S���[�敪
    gt_edi_work(ln_idx).carrier_means                  := it_edi_work.carrier_means;                     -- �^����i
    gt_edi_work(ln_idx).counter_code                   := it_edi_work.counter_code;                      -- ����R�[�h
    gt_edi_work(ln_idx).move_sign                      := it_edi_work.move_sign;                         -- �ړ��T�C��
    gt_edi_work(ln_idx).eos_handwriting_class          := it_edi_work.eos_handwriting_class;             -- �d�n�r�E�菑�敪
    gt_edi_work(ln_idx).delivery_to_section_code       := it_edi_work.delivery_to_section_code;          -- �[�i��ۃR�[�h
    gt_edi_work(ln_idx).invoice_detailed               := it_edi_work.invoice_detailed;                  -- �`�[����
    gt_edi_work(ln_idx).attach_qty                     := it_edi_work.attach_qty;                        -- �Y�t��
    gt_edi_work(ln_idx).other_party_floor              := it_edi_work.other_party_floor;                 -- �t���A
    gt_edi_work(ln_idx).text_no                        := it_edi_work.text_no;                           -- �s�d�w�s�m��
    gt_edi_work(ln_idx).in_store_code                  := it_edi_work.in_store_code;                     -- �C���X�g�A�R�[�h
    gt_edi_work(ln_idx).tag_data                       := it_edi_work.tag_data;                          -- �^�O
    gt_edi_work(ln_idx).competition_code               := it_edi_work.competition_code;                  -- ����
    gt_edi_work(ln_idx).billing_chair                  := it_edi_work.billing_chair;                     -- ��������
    gt_edi_work(ln_idx).chain_store_code               := it_edi_work.chain_store_code;                  -- �`�F�[���X�g�A�[�R�[�h
    gt_edi_work(ln_idx).chain_store_short_name         := it_edi_work.chain_store_short_name;            -- �`�F�[���X�g�A�[�R�[�h��������
    gt_edi_work(ln_idx).direct_delivery_rcpt_fee       := it_edi_work.direct_delivery_rcpt_fee;          -- ���z���^���旿
    gt_edi_work(ln_idx).bill_info                      := it_edi_work.bill_info;                         -- ��`���
    gt_edi_work(ln_idx).description                    := it_edi_work.description;                       -- �E�v
    gt_edi_work(ln_idx).interior_code                  := it_edi_work.interior_code;                     -- �����R�[�h
    gt_edi_work(ln_idx).order_info_delivery_category   := it_edi_work.order_info_delivery_category;      -- �������@�[�i�J�e�S���[
    gt_edi_work(ln_idx).purchase_type                  := it_edi_work.purchase_type;                     -- �d���`��
    gt_edi_work(ln_idx).delivery_to_name_alt           := it_edi_work.delivery_to_name_alt;              -- �[�i�ꏊ���i�J�i�j
    gt_edi_work(ln_idx).shop_opened_site               := it_edi_work.shop_opened_site;                  -- �X�o�ꏊ
    gt_edi_work(ln_idx).counter_name                   := it_edi_work.counter_name;                      -- ���ꖼ
    gt_edi_work(ln_idx).extension_number               := it_edi_work.extension_number;                  -- �����ԍ�
    gt_edi_work(ln_idx).charge_name                    := it_edi_work.charge_name;                       -- �S���Җ�
    gt_edi_work(ln_idx).price_tag                      := it_edi_work.price_tag;                         -- �l�D
    gt_edi_work(ln_idx).tax_type                       := it_edi_work.tax_type;                          -- �Ŏ�
    gt_edi_work(ln_idx).consumption_tax_class          := it_edi_work.consumption_tax_class;             -- ����ŋ敪
    gt_edi_work(ln_idx).brand_class                    := it_edi_work.brand_class;                       -- �a�q
    gt_edi_work(ln_idx).id_code                        := it_edi_work.id_code;                           -- �h�c�R�[�h
    gt_edi_work(ln_idx).department_code                := it_edi_work.department_code;                   -- �S�ݓX�R�[�h
    gt_edi_work(ln_idx).department_name                := it_edi_work.department_name;                   -- �S�ݓX��
    gt_edi_work(ln_idx).item_type_number               := it_edi_work.item_type_number;                  -- �i�ʔԍ�
    gt_edi_work(ln_idx).description_department         := it_edi_work.description_department;            -- �E�v�i�S�ݓX�j
    gt_edi_work(ln_idx).price_tag_method               := it_edi_work.price_tag_method;                  -- �l�D���@
    gt_edi_work(ln_idx).reason_column                  := it_edi_work.reason_column;                     -- ���R��
    gt_edi_work(ln_idx).a_column_header                := it_edi_work.a_column_header;                   -- �`���w�b�_
    gt_edi_work(ln_idx).d_column_header                := it_edi_work.d_column_header;                   -- �c���w�b�_
    gt_edi_work(ln_idx).brand_code                     := it_edi_work.brand_code;                        -- �u�����h�R�[�h
    gt_edi_work(ln_idx).line_code                      := it_edi_work.line_code;                         -- ���C���R�[�h
    gt_edi_work(ln_idx).class_code                     := it_edi_work.class_code;                        -- �N���X�R�[�h
    gt_edi_work(ln_idx).a1_column                      := it_edi_work.a1_column;                         -- �`�|�P��
    gt_edi_work(ln_idx).b1_column                      := it_edi_work.b1_column;                         -- �a�|�P��
    gt_edi_work(ln_idx).c1_column                      := it_edi_work.c1_column;                         -- �b�|�P��
    gt_edi_work(ln_idx).d1_column                      := it_edi_work.d1_column;                         -- �c�|�P��
    gt_edi_work(ln_idx).e1_column                      := it_edi_work.e1_column;                         -- �d�|�P��
    gt_edi_work(ln_idx).a2_column                      := it_edi_work.a2_column;                         -- �`�|�Q��
    gt_edi_work(ln_idx).b2_column                      := it_edi_work.b2_column;                         -- �a�|�Q��
    gt_edi_work(ln_idx).c2_column                      := it_edi_work.c2_column;                         -- �b�|�Q��
    gt_edi_work(ln_idx).d2_column                      := it_edi_work.d2_column;                         -- �c�|�Q��
    gt_edi_work(ln_idx).e2_column                      := it_edi_work.e2_column;                         -- �d�|�Q��
    gt_edi_work(ln_idx).a3_column                      := it_edi_work.a3_column;                         -- �`�|�R��
    gt_edi_work(ln_idx).b3_column                      := it_edi_work.b3_column;                         -- �a�|�R��
    gt_edi_work(ln_idx).c3_column                      := it_edi_work.c3_column;                         -- �b�|�R��
    gt_edi_work(ln_idx).d3_column                      := it_edi_work.d3_column;                         -- �c�|�R��
    gt_edi_work(ln_idx).e3_column                      := it_edi_work.e3_column;                         -- �d�|�R��
    gt_edi_work(ln_idx).f1_column                      := it_edi_work.f1_column;                         -- �e�|�P��
    gt_edi_work(ln_idx).g1_column                      := it_edi_work.g1_column;                         -- �f�|�P��
    gt_edi_work(ln_idx).h1_column                      := it_edi_work.h1_column;                         -- �g�|�P��
    gt_edi_work(ln_idx).i1_column                      := it_edi_work.i1_column;                         -- �h�|�P��
    gt_edi_work(ln_idx).j1_column                      := it_edi_work.j1_column;                         -- �i�|�P��
    gt_edi_work(ln_idx).k1_column                      := it_edi_work.k1_column;                         -- �j�|�P��
    gt_edi_work(ln_idx).l1_column                      := it_edi_work.l1_column;                         -- �k�|�P��
    gt_edi_work(ln_idx).f2_column                      := it_edi_work.f2_column;                         -- �e�|�Q��
    gt_edi_work(ln_idx).g2_column                      := it_edi_work.g2_column;                         -- �f�|�Q��
    gt_edi_work(ln_idx).h2_column                      := it_edi_work.h2_column;                         -- �g�|�Q��
    gt_edi_work(ln_idx).i2_column                      := it_edi_work.i2_column;                         -- �h�|�Q��
    gt_edi_work(ln_idx).j2_column                      := it_edi_work.j2_column;                         -- �i�|�Q��
    gt_edi_work(ln_idx).k2_column                      := it_edi_work.k2_column;                         -- �j�|�Q��
    gt_edi_work(ln_idx).l2_column                      := it_edi_work.l2_column;                         -- �k�|�Q��
    gt_edi_work(ln_idx).f3_column                      := it_edi_work.f3_column;                         -- �e�|�R��
    gt_edi_work(ln_idx).g3_column                      := it_edi_work.g3_column;                         -- �f�|�R��
    gt_edi_work(ln_idx).h3_column                      := it_edi_work.h3_column;                         -- �g�|�R��
    gt_edi_work(ln_idx).i3_column                      := it_edi_work.i3_column;                         -- �h�|�R��
    gt_edi_work(ln_idx).j3_column                      := it_edi_work.j3_column;                         -- �i�|�R��
    gt_edi_work(ln_idx).k3_column                      := it_edi_work.k3_column;                         -- �j�|�R��
    gt_edi_work(ln_idx).l3_column                      := it_edi_work.l3_column;                         -- �k�|�R��
    gt_edi_work(ln_idx).chain_peculiar_area_header     := it_edi_work.chain_peculiar_area_header;        -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
    gt_edi_work(ln_idx).order_connection_number        := it_edi_work.order_connection_number;           -- �󒍊֘A�ԍ�
    gt_edi_work(ln_idx).line_no                        := it_edi_work.line_no;                           -- �s�m��
    gt_edi_work(ln_idx).stockout_class                 := it_edi_work.stockout_class;                    -- ���i�敪
    gt_edi_work(ln_idx).stockout_reason                := it_edi_work.stockout_reason;                   -- ���i���R
    gt_edi_work(ln_idx).product_code_itouen            := it_edi_work.product_code_itouen;               -- ���i�R�[�h�i�ɓ����j
    gt_edi_work(ln_idx).product_code1                  := it_edi_work.product_code1;                     -- ���i�R�[�h�P
    gt_edi_work(ln_idx).product_code2                  := it_edi_work.product_code2;                     -- ���i�R�[�h�Q
    gt_edi_work(ln_idx).jan_code                       := it_edi_work.jan_code;                          -- �i�`�m�R�[�h
    gt_edi_work(ln_idx).itf_code                       := it_edi_work.itf_code;                          -- �h�s�e�R�[�h
    gt_edi_work(ln_idx).extension_itf_code             := it_edi_work.extension_itf_code;                -- �����h�s�e�R�[�h
    gt_edi_work(ln_idx).case_product_code              := it_edi_work.case_product_code;                 -- �P�[�X���i�R�[�h
    gt_edi_work(ln_idx).ball_product_code              := it_edi_work.ball_product_code;                 -- �{�[�����i�R�[�h
    gt_edi_work(ln_idx).product_code_item_type         := it_edi_work.product_code_item_type;            -- ���i�R�[�h�i��
    gt_edi_work(ln_idx).prod_class                     := it_edi_work.prod_class;                        -- ���i�敪
    gt_edi_work(ln_idx).product_name                   := it_edi_work.product_name;                      -- ���i���i�����j
    gt_edi_work(ln_idx).product_name1_alt              := it_edi_work.product_name1_alt;                 -- ���i���P�i�J�i�j
    gt_edi_work(ln_idx).product_name2_alt              := it_edi_work.product_name2_alt;                 -- ���i���Q�i�J�i�j
    gt_edi_work(ln_idx).item_standard1                 := it_edi_work.item_standard1;                    -- �K�i�P
    gt_edi_work(ln_idx).item_standard2                 := it_edi_work.item_standard2;                    -- �K�i�Q
    gt_edi_work(ln_idx).qty_in_case                    := it_edi_work.qty_in_case;                       -- ����
    gt_edi_work(ln_idx).num_of_cases                   := it_edi_work.num_of_cases;                      -- �P�[�X����
    gt_edi_work(ln_idx).num_of_ball                    := it_edi_work.num_of_ball;                       -- �{�[������
    gt_edi_work(ln_idx).item_color                     := it_edi_work.item_color;                        -- �F
    gt_edi_work(ln_idx).item_size                      := it_edi_work.item_size;                         -- �T�C�Y
    gt_edi_work(ln_idx).expiration_date                := it_edi_work.expiration_date;                   -- �ܖ�������
    gt_edi_work(ln_idx).product_date                   := it_edi_work.product_date;                      -- ������
    gt_edi_work(ln_idx).order_uom_qty                  := it_edi_work.order_uom_qty;                     -- �����P�ʐ�
    gt_edi_work(ln_idx).shipping_uom_qty               := it_edi_work.shipping_uom_qty;                  -- �o�גP�ʐ�
    gt_edi_work(ln_idx).packing_uom_qty                := it_edi_work.packing_uom_qty;                   -- ����P�ʐ�
    gt_edi_work(ln_idx).deal_code                      := it_edi_work.deal_code;                         -- ����
    gt_edi_work(ln_idx).deal_class                     := it_edi_work.deal_class;                        -- �����敪
    gt_edi_work(ln_idx).collation_code                 := it_edi_work.collation_code;                    -- �ƍ�
    gt_edi_work(ln_idx).uom_code                       := it_edi_work.uom_code;                          -- �P��
    gt_edi_work(ln_idx).unit_price_class               := it_edi_work.unit_price_class;                  -- �P���敪
    gt_edi_work(ln_idx).parent_packing_number          := it_edi_work.parent_packing_number;             -- �e����ԍ�
    gt_edi_work(ln_idx).packing_number                 := it_edi_work.packing_number;                    -- ����ԍ�
    gt_edi_work(ln_idx).product_group_code             := it_edi_work.product_group_code;                -- ���i�Q�R�[�h
    gt_edi_work(ln_idx).case_dismantle_flag            := it_edi_work.case_dismantle_flag;               -- �P�[�X��̕s�t���O
    gt_edi_work(ln_idx).case_class                     := it_edi_work.case_class;                        -- �P�[�X�敪
    gt_edi_work(ln_idx).indv_order_qty                 := it_edi_work.indv_order_qty;                    -- �������ʁi�o���j
    gt_edi_work(ln_idx).case_order_qty                 := it_edi_work.case_order_qty;                    -- �������ʁi�P�[�X�j
    gt_edi_work(ln_idx).ball_order_qty                 := it_edi_work.ball_order_qty;                    -- �������ʁi�{�[���j
    gt_edi_work(ln_idx).sum_order_qty                  := it_edi_work.sum_order_qty;                     -- �������ʁi���v�A�o���j
    gt_edi_work(ln_idx).indv_shipping_qty              := it_edi_work.indv_shipping_qty;                 -- �o�א��ʁi�o���j
    gt_edi_work(ln_idx).case_shipping_qty              := it_edi_work.case_shipping_qty;                 -- �o�א��ʁi�P�[�X�j
    gt_edi_work(ln_idx).ball_shipping_qty              := it_edi_work.ball_shipping_qty;                 -- �o�א��ʁi�{�[���j
    gt_edi_work(ln_idx).pallet_shipping_qty            := it_edi_work.pallet_shipping_qty;               -- �o�א��ʁi�p���b�g�j
    gt_edi_work(ln_idx).sum_shipping_qty               := it_edi_work.sum_shipping_qty;                  -- �o�א��ʁi���v�A�o���j
    gt_edi_work(ln_idx).indv_stockout_qty              := it_edi_work.indv_stockout_qty;                 -- ���i���ʁi�o���j
    gt_edi_work(ln_idx).case_stockout_qty              := it_edi_work.case_stockout_qty;                 -- ���i���ʁi�P�[�X�j
    gt_edi_work(ln_idx).ball_stockout_qty              := it_edi_work.ball_stockout_qty;                 -- ���i���ʁi�{�[���j
    gt_edi_work(ln_idx).sum_stockout_qty               := it_edi_work.sum_stockout_qty;                  -- ���i���ʁi���v�A�o���j
    gt_edi_work(ln_idx).case_qty                       := it_edi_work.case_qty;                          -- �P�[�X����
    gt_edi_work(ln_idx).fold_container_indv_qty        := it_edi_work.fold_container_indv_qty;           -- �I���R���i�o���j����
    gt_edi_work(ln_idx).order_unit_price               := it_edi_work.order_unit_price;                  -- ���P���i�����j
    gt_edi_work(ln_idx).shipping_unit_price            := it_edi_work.shipping_unit_price;               -- ���P���i�o�ׁj
    gt_edi_work(ln_idx).order_cost_amt                 := it_edi_work.order_cost_amt;                    -- �������z�i�����j
    gt_edi_work(ln_idx).shipping_cost_amt              := it_edi_work.shipping_cost_amt;                 -- �������z�i�o�ׁj
    gt_edi_work(ln_idx).stockout_cost_amt              := it_edi_work.stockout_cost_amt;                 -- �������z�i���i�j
    gt_edi_work(ln_idx).selling_price                  := it_edi_work.selling_price;                     -- ���P��
    gt_edi_work(ln_idx).order_price_amt                := it_edi_work.order_price_amt;                   -- �������z�i�����j
    gt_edi_work(ln_idx).shipping_price_amt             := it_edi_work.shipping_price_amt;                -- �������z�i�o�ׁj
    gt_edi_work(ln_idx).stockout_price_amt             := it_edi_work.stockout_price_amt;                -- �������z�i���i�j
    gt_edi_work(ln_idx).a_column_department            := it_edi_work.a_column_department;               -- �`���i�S�ݓX�j
    gt_edi_work(ln_idx).d_column_department            := it_edi_work.d_column_department;               -- �c���i�S�ݓX�j
    gt_edi_work(ln_idx).standard_info_depth            := it_edi_work.standard_info_depth;               -- �K�i���E���s��
    gt_edi_work(ln_idx).standard_info_height           := it_edi_work.standard_info_height;              -- �K�i���E����
    gt_edi_work(ln_idx).standard_info_width            := it_edi_work.standard_info_width;               -- �K�i���E��
    gt_edi_work(ln_idx).standard_info_weight           := it_edi_work.standard_info_weight;              -- �K�i���E�d��
    gt_edi_work(ln_idx).general_succeeded_item1        := it_edi_work.general_succeeded_item1;           -- �ėp���p�����ڂP
    gt_edi_work(ln_idx).general_succeeded_item2        := it_edi_work.general_succeeded_item2;           -- �ėp���p�����ڂQ
    gt_edi_work(ln_idx).general_succeeded_item3        := it_edi_work.general_succeeded_item3;           -- �ėp���p�����ڂR
    gt_edi_work(ln_idx).general_succeeded_item4        := it_edi_work.general_succeeded_item4;           -- �ėp���p�����ڂS
    gt_edi_work(ln_idx).general_succeeded_item5        := it_edi_work.general_succeeded_item5;           -- �ėp���p�����ڂT
    gt_edi_work(ln_idx).general_succeeded_item6        := it_edi_work.general_succeeded_item6;           -- �ėp���p�����ڂU
    gt_edi_work(ln_idx).general_succeeded_item7        := it_edi_work.general_succeeded_item7;           -- �ėp���p�����ڂV
    gt_edi_work(ln_idx).general_succeeded_item8        := it_edi_work.general_succeeded_item8;           -- �ėp���p�����ڂW
    gt_edi_work(ln_idx).general_succeeded_item9        := it_edi_work.general_succeeded_item9;           -- �ėp���p�����ڂX
    gt_edi_work(ln_idx).general_succeeded_item10       := it_edi_work.general_succeeded_item10;          -- �ėp���p�����ڂP�O
    gt_edi_work(ln_idx).general_add_item1              := it_edi_work.general_add_item1;                 -- �ėp�t�����ڂP
    gt_edi_work(ln_idx).general_add_item2              := it_edi_work.general_add_item2;                 -- �ėp�t�����ڂQ
    gt_edi_work(ln_idx).general_add_item3              := it_edi_work.general_add_item3;                 -- �ėp�t�����ڂR
    gt_edi_work(ln_idx).general_add_item4              := it_edi_work.general_add_item4;                 -- �ėp�t�����ڂS
    gt_edi_work(ln_idx).general_add_item5              := it_edi_work.general_add_item5;                 -- �ėp�t�����ڂT
    gt_edi_work(ln_idx).general_add_item6              := it_edi_work.general_add_item6;                 -- �ėp�t�����ڂU
    gt_edi_work(ln_idx).general_add_item7              := it_edi_work.general_add_item7;                 -- �ėp�t�����ڂV
    gt_edi_work(ln_idx).general_add_item8              := it_edi_work.general_add_item8;                 -- �ėp�t�����ڂW
    gt_edi_work(ln_idx).general_add_item9              := it_edi_work.general_add_item9;                 -- �ėp�t�����ڂX
    gt_edi_work(ln_idx).general_add_item10             := it_edi_work.general_add_item10;                -- �ėp�t�����ڂP�O
    gt_edi_work(ln_idx).chain_peculiar_area_line       := it_edi_work.chain_peculiar_area_line;          -- �`�F�[���X�ŗL�G���A�i���ׁj
    gt_edi_work(ln_idx).invoice_indv_order_qty         := it_edi_work.invoice_indv_order_qty;            -- �i�`�[�v�j�������ʁi�o���j
    gt_edi_work(ln_idx).invoice_case_order_qty         := it_edi_work.invoice_case_order_qty;            -- �i�`�[�v�j�������ʁi�P�[�X�j
    gt_edi_work(ln_idx).invoice_ball_order_qty         := it_edi_work.invoice_ball_order_qty;            -- �i�`�[�v�j�������ʁi�{�[���j
    gt_edi_work(ln_idx).invoice_sum_order_qty          := it_edi_work.invoice_sum_order_qty;             -- �i�`�[�v�j�������ʁi���v�A�o���j
    gt_edi_work(ln_idx).invoice_indv_shipping_qty      := it_edi_work.invoice_indv_shipping_qty;         -- �i�`�[�v�j�o�א��ʁi�o���j
    gt_edi_work(ln_idx).invoice_case_shipping_qty      := it_edi_work.invoice_case_shipping_qty;         -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
    gt_edi_work(ln_idx).invoice_ball_shipping_qty      := it_edi_work.invoice_ball_shipping_qty;         -- �i�`�[�v�j�o�א��ʁi�{�[���j
    gt_edi_work(ln_idx).invoice_pallet_shipping_qty    := it_edi_work.invoice_pallet_shipping_qty;       -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
    gt_edi_work(ln_idx).invoice_sum_shipping_qty       := it_edi_work.invoice_sum_shipping_qty;          -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
    gt_edi_work(ln_idx).invoice_indv_stockout_qty      := it_edi_work.invoice_indv_stockout_qty;         -- �i�`�[�v�j���i���ʁi�o���j
    gt_edi_work(ln_idx).invoice_case_stockout_qty      := it_edi_work.invoice_case_stockout_qty;         -- �i�`�[�v�j���i���ʁi�P�[�X�j
    gt_edi_work(ln_idx).invoice_ball_stockout_qty      := it_edi_work.invoice_ball_stockout_qty;         -- �i�`�[�v�j���i���ʁi�{�[���j
    gt_edi_work(ln_idx).invoice_sum_stockout_qty       := it_edi_work.invoice_sum_stockout_qty;          -- �i�`�[�v�j���i���ʁi���v�A�o���j
    gt_edi_work(ln_idx).invoice_case_qty               := it_edi_work.invoice_case_qty;                  -- �i�`�[�v�j�P�[�X����
    gt_edi_work(ln_idx).invoice_fold_container_qty     := it_edi_work.invoice_fold_container_qty;        -- �i�`�[�v�j�I���R���i�o���j����
    gt_edi_work(ln_idx).invoice_order_cost_amt         := it_edi_work.invoice_order_cost_amt;            -- �i�`�[�v�j�������z�i�����j
    gt_edi_work(ln_idx).invoice_shipping_cost_amt      := it_edi_work.invoice_shipping_cost_amt;         -- �i�`�[�v�j�������z�i�o�ׁj
    gt_edi_work(ln_idx).invoice_stockout_cost_amt      := it_edi_work.invoice_stockout_cost_amt;         -- �i�`�[�v�j�������z�i���i�j
    gt_edi_work(ln_idx).invoice_order_price_amt        := it_edi_work.invoice_order_price_amt;           -- �i�`�[�v�j�������z�i�����j
    gt_edi_work(ln_idx).invoice_shipping_price_amt     := it_edi_work.invoice_shipping_price_amt;        -- �i�`�[�v�j�������z�i�o�ׁj
    gt_edi_work(ln_idx).invoice_stockout_price_amt     := it_edi_work.invoice_stockout_price_amt;        -- �i�`�[�v�j�������z�i���i�j
    gt_edi_work(ln_idx).total_indv_order_qty           := it_edi_work.total_indv_order_qty;              -- �i�����v�j�������ʁi�o���j
    gt_edi_work(ln_idx).total_case_order_qty           := it_edi_work.total_case_order_qty;              -- �i�����v�j�������ʁi�P�[�X�j
    gt_edi_work(ln_idx).total_ball_order_qty           := it_edi_work.total_ball_order_qty;              -- �i�����v�j�������ʁi�{�[���j
    gt_edi_work(ln_idx).total_sum_order_qty            := it_edi_work.total_sum_order_qty;               -- �i�����v�j�������ʁi���v�A�o���j
    gt_edi_work(ln_idx).total_indv_shipping_qty        := it_edi_work.total_indv_shipping_qty;           -- �i�����v�j�o�א��ʁi�o���j
    gt_edi_work(ln_idx).total_case_shipping_qty        := it_edi_work.total_case_shipping_qty;           -- �i�����v�j�o�א��ʁi�P�[�X�j
    gt_edi_work(ln_idx).total_ball_shipping_qty        := it_edi_work.total_ball_shipping_qty;           -- �i�����v�j�o�א��ʁi�{�[���j
    gt_edi_work(ln_idx).total_pallet_shipping_qty      := it_edi_work.total_pallet_shipping_qty;         -- �i�����v�j�o�א��ʁi�p���b�g�j
    gt_edi_work(ln_idx).total_sum_shipping_qty         := it_edi_work.total_sum_shipping_qty;            -- �i�����v�j�o�א��ʁi���v�A�o���j
    gt_edi_work(ln_idx).total_indv_stockout_qty        := it_edi_work.total_indv_stockout_qty;           -- �i�����v�j���i���ʁi�o���j
    gt_edi_work(ln_idx).total_case_stockout_qty        := it_edi_work.total_case_stockout_qty;           -- �i�����v�j���i���ʁi�P�[�X�j
    gt_edi_work(ln_idx).total_ball_stockout_qty        := it_edi_work.total_ball_stockout_qty;           -- �i�����v�j���i���ʁi�{�[���j
    gt_edi_work(ln_idx).total_sum_stockout_qty         := it_edi_work.total_sum_stockout_qty;            -- �i�����v�j���i���ʁi���v�A�o���j
    gt_edi_work(ln_idx).total_case_qty                 := it_edi_work.total_case_qty;                    -- �i�����v�j�P�[�X����
    gt_edi_work(ln_idx).total_fold_container_qty       := it_edi_work.total_fold_container_qty;          -- �i�����v�j�I���R���i�o���j����
    gt_edi_work(ln_idx).total_order_cost_amt           := it_edi_work.total_order_cost_amt;              -- �i�����v�j�������z�i�����j
    gt_edi_work(ln_idx).total_shipping_cost_amt        := it_edi_work.total_shipping_cost_amt;           -- �i�����v�j�������z�i�o�ׁj
    gt_edi_work(ln_idx).total_stockout_cost_amt        := it_edi_work.total_stockout_cost_amt;           -- �i�����v�j�������z�i���i�j
    gt_edi_work(ln_idx).total_order_price_amt          := it_edi_work.total_order_price_amt;             -- �i�����v�j�������z�i�����j
    gt_edi_work(ln_idx).total_shipping_price_amt       := it_edi_work.total_shipping_price_amt;          -- �i�����v�j�������z�i�o�ׁj
    gt_edi_work(ln_idx).total_stockout_price_amt       := it_edi_work.total_stockout_price_amt;          -- �i�����v�j�������z�i���i�j
    gt_edi_work(ln_idx).total_line_qty                 := it_edi_work.total_line_qty;                    -- �g�[�^���s��
    gt_edi_work(ln_idx).total_invoice_qty              := it_edi_work.total_invoice_qty;                 -- �g�[�^���`�[����
    gt_edi_work(ln_idx).chain_peculiar_area_footer     := it_edi_work.chain_peculiar_area_footer;        -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
    gt_edi_work(ln_idx).err_status                     := it_edi_work.err_status;                        -- �X�e�[�^�X
-- 2010/01/19 Ver.1.15 M.Sano add Start
    gt_edi_work(ln_idx).creation_date                  := it_edi_work.creation_date;                     -- �쐬��
-- 2010/01/19 Ver.1.15 M.Sano add End
    gt_edi_work(ln_idx).conv_customer_code             := NULL;                                          -- �ϊ���ڋq�R�[�h
    gt_edi_work(ln_idx).price_list_header_id           := NULL;                                          -- ���i�\�w�b�_ID
    gt_edi_work(ln_idx).item_code                      := NULL;                                          -- �i�ڃR�[�h
    gt_edi_work(ln_idx).line_uom                       := NULL;                                          -- ���גP��
-- 2009/12/28 M.Sano Ver.1.14 add Start
    gt_edi_work(ln_idx).tsukagatazaiko_div             := NULL;                                          -- �ʉߍ݌Ɍ^�敪
    gt_edi_work(ln_idx).order_forward_flag             := NULL;                                          -- �󒍘A�g�σt���O
-- 2009/12/28 M.Sano Ver.1.14 add End
    gt_edi_work(ln_idx).check_status                   := cv_edi_status_normal;                          -- �`�F�b�N�X�e�[�^�X
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_set_edi_work;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_edi_status
   * Description      : EDI�X�e�[�^�X�X�V�p�ϐ��i�[(A-6)
   ***********************************************************************************/
  PROCEDURE proc_set_edi_status(
    in_order_info_work_id IN NUMBER,       -- EDI�󒍃��[�NID
    iv_err_status         IN VARCHAR2,     -- �X�e�[�^�X
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_edi_status'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx     NUMBER;
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
    ln_idx := gt_order_info_work_id.COUNT + 1;
--
    -- EDI�󒍏�񃏁[�NID�A�X�e�[�^�X��ێ�����
    gt_order_info_work_id(ln_idx)       := in_order_info_work_id;
    gt_edi_err_status(ln_idx)           := iv_err_status;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_set_edi_status;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_edi_headers
   * Description      : EDI�w�b�_���e�[�u���f�[�^���o(A-7)
   ***********************************************************************************/
  PROCEDURE proc_get_edi_headers(
    it_edi_work   IN  g_edi_work_rtype,      -- EDI�󒍏�񃏁[�N���R�[�h
    on_edi_header_info_id OUT NOCOPY NUMBER, -- EDI�w�b�_���ID
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_edi_headers'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- OUT�p�����[�^������
    on_edi_header_info_id := NULL;
--
    --EDI�w�b�_���f�[�^���o
    SELECT  head.edi_header_info_id
    INTO    on_edi_header_info_id
    FROM    xxcos_edi_headers           head
    WHERE   head.data_type_code         = it_edi_work.data_type_code                 -- �f�[�^��R�[�h�F��
    AND     head.edi_chain_code         = it_edi_work.edi_chain_code                 -- EDI�`�F�[���X�R�[�h
    AND     head.invoice_number         = it_edi_work.invoice_number                 -- �`�[�ԍ�
    AND     ( ( head.shop_delivery_date IS NULL AND it_edi_work.shop_delivery_date IS NULL )
            OR ( head.shop_delivery_date = it_edi_work.shop_delivery_date ) )        -- �X�ܔ[�i��
    AND     ( ( head.center_delivery_date IS NULL AND it_edi_work.center_delivery_date IS NULL )
            OR ( head.center_delivery_date = it_edi_work.center_delivery_date ) )    -- �Z���^�[�[�i��
    AND     ( ( head.order_date IS NULL AND it_edi_work.order_date IS NULL  )
            OR ( head.order_date = it_edi_work.order_date ) )                        -- ������
-- ************ 2009/11/29 1.13 N.Maeda MOD START ************ --
    AND     ( ( head.data_creation_date_edi_data IS NULL AND it_edi_work.data_creation_date_edi_data IS NULL)
            OR ( TRUNC( head.data_creation_date_edi_data ) = TRUNC( it_edi_work.data_creation_date_edi_data ) ) )
--    AND     TRUNC( head.data_creation_date_edi_data ) = TRUNC( it_edi_work.data_creation_date_edi_data ) -- �f�[�^�쐬���i�d�c�h�f�[�^���j
-- ************ 2009/11/29 1.13 N.Maeda MOD START ************ --
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--    AND     head.shop_code              = it_edi_work.shop_code;                      -- �X�R�[�h
    AND     head.shop_code              = it_edi_work.shop_code                      -- �X�R�[�h
    AND     (  ( head.info_class IS NULL AND it_edi_work.info_class IS NULL )
            OR ( head.info_class        = it_edi_work.info_class ) )
    ;                    -- ���敪
-- 2009/06/29 M.Sano Ver.1.6 mod End
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** �Ώۃf�[�^�Ȃ���O�n���h�� ***
      NULL;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_get_edi_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_ins_headers
   * Description      : EDI�w�b�_���C���T�[�g�p�ϐ��i�[(A-8)
   ***********************************************************************************/
  PROCEDURE proc_set_ins_headers(
    it_edi_work   IN  g_edi_work_rtype,      -- EDI�󒍏�񃏁[�N���R�[�h
    on_edi_header_info_id OUT NOCOPY NUMBER, -- EDI�w�b�_���ID
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_ins_headers'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx     NUMBER;
    ln_seq_1   NUMBER;
    ln_seq_2   NUMBER;
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
    -- OUT�p�����[�^������
    on_edi_header_info_id := NULL;
--
    ln_idx := gt_edi_headers.COUNT + 1;
--
    -- EDI�w�b�_���ID���V�[�P���X����擾����
    BEGIN
      SELECT xxcos_edi_headers_s01.NEXTVAL
      INTO   ln_seq_1
      FROM   dual;
--
      -- �擾�����V�[�P���X��OUT�p�����[�^�ŕԂ�
      on_edi_header_info_id := ln_seq_1;
    END;
--
    -- �󒍊֘A�ԍ����V�[�P���X����擾����
    BEGIN
      SELECT xxcos_edi_headers_s02.NEXTVAL
      INTO   ln_seq_2
      FROM   dual;
    END;
--
    gt_edi_headers(ln_idx).edi_header_info_id               := ln_seq_1;                                      -- EDI�w�b�_���ID
    gt_edi_headers(ln_idx).medium_class                     := it_edi_work.medium_class;                      -- �}�̋敪
    gt_edi_headers(ln_idx).data_type_code                   := it_edi_work.data_type_code;                    -- �f�[�^��R�[�h
    gt_edi_headers(ln_idx).file_no                          := it_edi_work.file_no;                           -- �t�@�C���m��
    gt_edi_headers(ln_idx).info_class                       := it_edi_work.info_class;                        -- ���敪
    gt_edi_headers(ln_idx).process_date                     := it_edi_work.process_date;                      -- ������
    gt_edi_headers(ln_idx).process_time                     := it_edi_work.process_time;                      -- ��������
    gt_edi_headers(ln_idx).base_code                        := it_edi_work.base_code;                         -- ���_�i����j�R�[�h
    gt_edi_headers(ln_idx).base_name                        := it_edi_work.base_name;                         -- ���_���i�������j
    gt_edi_headers(ln_idx).base_name_alt                    := it_edi_work.base_name_alt;                     -- ���_���i�J�i�j
    gt_edi_headers(ln_idx).edi_chain_code                   := it_edi_work.edi_chain_code;                    -- �d�c�h�`�F�[���X�R�[�h
    gt_edi_headers(ln_idx).edi_chain_name                   := it_edi_work.edi_chain_name;                    -- �d�c�h�`�F�[���X���i�����j
    gt_edi_headers(ln_idx).edi_chain_name_alt               := it_edi_work.edi_chain_name_alt;                -- �d�c�h�`�F�[���X���i�J�i�j
    gt_edi_headers(ln_idx).chain_code                       := it_edi_work.chain_code;                        -- �`�F�[���X�R�[�h
    gt_edi_headers(ln_idx).chain_name                       := it_edi_work.chain_name;                        -- �`�F�[���X���i�����j
    gt_edi_headers(ln_idx).chain_name_alt                   := it_edi_work.chain_name_alt;                    -- �`�F�[���X���i�J�i�j
    gt_edi_headers(ln_idx).report_code                      := it_edi_work.report_code;                       -- ���[�R�[�h
    gt_edi_headers(ln_idx).report_show_name                 := it_edi_work.report_show_name;                  -- ���[�\����
    gt_edi_headers(ln_idx).customer_code                    := it_edi_work.customer_code;                     -- �ڋq�R�[�h
    gt_edi_headers(ln_idx).customer_name                    := it_edi_work.customer_name;                     -- �ڋq���i�����j
    gt_edi_headers(ln_idx).customer_name_alt                := it_edi_work.customer_name_alt;                 -- �ڋq���i�J�i�j
    gt_edi_headers(ln_idx).company_code                     := it_edi_work.company_code;                      -- �ЃR�[�h
    gt_edi_headers(ln_idx).company_name                     := it_edi_work.company_name;                      -- �Ж��i�����j
    gt_edi_headers(ln_idx).company_name_alt                 := it_edi_work.company_name_alt;                  -- �Ж��i�J�i�j
    gt_edi_headers(ln_idx).shop_code                        := it_edi_work.shop_code;                         -- �X�R�[�h
    gt_edi_headers(ln_idx).shop_name                        := it_edi_work.shop_name;                         -- �X���i�����j
    gt_edi_headers(ln_idx).shop_name_alt                    := it_edi_work.shop_name_alt;                     -- �X���i�J�i�j
    gt_edi_headers(ln_idx).delivery_center_code             := it_edi_work.delivery_center_code;              -- �[���Z���^�[�R�[�h
    gt_edi_headers(ln_idx).delivery_center_name             := it_edi_work.delivery_center_name;              -- �[���Z���^�[���i�����j
    gt_edi_headers(ln_idx).delivery_center_name_alt         := it_edi_work.delivery_center_name_alt;          -- �[���Z���^�[���i�J�i�j
    gt_edi_headers(ln_idx).order_date                       := it_edi_work.order_date;                        -- ������
    gt_edi_headers(ln_idx).center_delivery_date             := it_edi_work.center_delivery_date;              -- �Z���^�[�[�i��
    gt_edi_headers(ln_idx).result_delivery_date             := it_edi_work.result_delivery_date;              -- ���[�i��
    gt_edi_headers(ln_idx).shop_delivery_date               := it_edi_work.shop_delivery_date;                -- �X�ܔ[�i��
    gt_edi_headers(ln_idx).data_creation_date_edi_data      := it_edi_work.data_creation_date_edi_data;       -- �f�[�^�쐬���i�d�c�h�f�[�^���j
    gt_edi_headers(ln_idx).data_creation_time_edi_data      := it_edi_work.data_creation_time_edi_data;       -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
    gt_edi_headers(ln_idx).invoice_class                    := it_edi_work.invoice_class;                     -- �`�[�敪
    gt_edi_headers(ln_idx).small_classification_code        := it_edi_work.small_classification_code;         -- �����ރR�[�h
    gt_edi_headers(ln_idx).small_classification_name        := it_edi_work.small_classification_name;         -- �����ޖ�
    gt_edi_headers(ln_idx).middle_classification_code       := it_edi_work.middle_classification_code;        -- �����ރR�[�h
    gt_edi_headers(ln_idx).middle_classification_name       := it_edi_work.middle_classification_name;        -- �����ޖ�
    gt_edi_headers(ln_idx).big_classification_code          := it_edi_work.big_classification_code;           -- �啪�ރR�[�h
    gt_edi_headers(ln_idx).big_classification_name          := it_edi_work.big_classification_name;           -- �啪�ޖ�
    gt_edi_headers(ln_idx).other_party_department_code      := it_edi_work.other_party_department_code;       -- ����敔��R�[�h
    gt_edi_headers(ln_idx).other_party_order_number         := it_edi_work.other_party_order_number;          -- ����攭���ԍ�
    gt_edi_headers(ln_idx).check_digit_class                := it_edi_work.check_digit_class;                 -- �`�F�b�N�f�W�b�g�L���敪
    gt_edi_headers(ln_idx).invoice_number                   := it_edi_work.invoice_number;                    -- �`�[�ԍ�
    gt_edi_headers(ln_idx).check_digit                      := it_edi_work.check_digit;                       -- �`�F�b�N�f�W�b�g
    gt_edi_headers(ln_idx).close_date                       := it_edi_work.close_date;                        -- ����
    gt_edi_headers(ln_idx).order_no_ebs                     := it_edi_work.order_no_ebs;                      -- �󒍂m���i�d�a�r�j
    gt_edi_headers(ln_idx).ar_sale_class                    := it_edi_work.ar_sale_class;                     -- �����敪
    gt_edi_headers(ln_idx).delivery_classe                  := it_edi_work.delivery_classe;                   -- �z���敪
    gt_edi_headers(ln_idx).opportunity_no                   := it_edi_work.opportunity_no;                    -- �ւm��
    gt_edi_headers(ln_idx).contact_to                       := it_edi_work.contact_to;                        -- �A����
    gt_edi_headers(ln_idx).route_sales                      := it_edi_work.route_sales;                       -- ���[�g�Z�[���X
    gt_edi_headers(ln_idx).corporate_code                   := it_edi_work.corporate_code;                    -- �@�l�R�[�h
    gt_edi_headers(ln_idx).maker_name                       := it_edi_work.maker_name;                        -- ���[�J�[��
    gt_edi_headers(ln_idx).area_code                        := it_edi_work.area_code;                         -- �n��R�[�h
    gt_edi_headers(ln_idx).area_name                        := it_edi_work.area_name;                         -- �n�於�i�����j
    gt_edi_headers(ln_idx).area_name_alt                    := it_edi_work.area_name_alt;                     -- �n�於�i�J�i�j
    gt_edi_headers(ln_idx).vendor_code                      := it_edi_work.vendor_code;                       -- �����R�[�h
    gt_edi_headers(ln_idx).vendor_name                      := it_edi_work.vendor_name;                       -- ����於�i�����j
    gt_edi_headers(ln_idx).vendor_name1_alt                 := it_edi_work.vendor_name1_alt;                  -- ����於�P�i�J�i�j
    gt_edi_headers(ln_idx).vendor_name2_alt                 := it_edi_work.vendor_name2_alt;                  -- ����於�Q�i�J�i�j
    gt_edi_headers(ln_idx).vendor_tel                       := it_edi_work.vendor_tel;                        -- �����s�d�k
    gt_edi_headers(ln_idx).vendor_charge                    := it_edi_work.vendor_charge;                     -- �����S����
    gt_edi_headers(ln_idx).vendor_address                   := it_edi_work.vendor_address;                    -- �����Z���i�����j
    gt_edi_headers(ln_idx).deliver_to_code_itouen           := it_edi_work.deliver_to_code_itouen;            -- �͂���R�[�h�i�ɓ����j
    gt_edi_headers(ln_idx).deliver_to_code_chain            := it_edi_work.deliver_to_code_chain;             -- �͂���R�[�h�i�`�F�[���X�j
    gt_edi_headers(ln_idx).deliver_to                       := it_edi_work.deliver_to;                        -- �͂���i�����j
    gt_edi_headers(ln_idx).deliver_to1_alt                  := it_edi_work.deliver_to1_alt;                   -- �͂���P�i�J�i�j
    gt_edi_headers(ln_idx).deliver_to2_alt                  := it_edi_work.deliver_to2_alt;                   -- �͂���Q�i�J�i�j
    gt_edi_headers(ln_idx).deliver_to_address               := it_edi_work.deliver_to_address;                -- �͂���Z���i�����j
    gt_edi_headers(ln_idx).deliver_to_address_alt           := it_edi_work.deliver_to_address_alt;            -- �͂���Z���i�J�i�j
    gt_edi_headers(ln_idx).deliver_to_tel                   := it_edi_work.deliver_to_tel;                    -- �͂���s�d�k
    gt_edi_headers(ln_idx).balance_accounts_code            := it_edi_work.balance_accounts_code;             -- ������R�[�h
    gt_edi_headers(ln_idx).balance_accounts_company_code    := it_edi_work.balance_accounts_company_code;     -- ������ЃR�[�h
    gt_edi_headers(ln_idx).balance_accounts_shop_code       := it_edi_work.balance_accounts_shop_code;        -- ������X�R�[�h
    gt_edi_headers(ln_idx).balance_accounts_name            := it_edi_work.balance_accounts_name;             -- �����於�i�����j
    gt_edi_headers(ln_idx).balance_accounts_name_alt        := it_edi_work.balance_accounts_name_alt;         -- �����於�i�J�i�j
    gt_edi_headers(ln_idx).balance_accounts_address         := it_edi_work.balance_accounts_address;          -- ������Z���i�����j
    gt_edi_headers(ln_idx).balance_accounts_address_alt     := it_edi_work.balance_accounts_address_alt;      -- ������Z���i�J�i�j
    gt_edi_headers(ln_idx).balance_accounts_tel             := it_edi_work.balance_accounts_tel;              -- ������s�d�k
    gt_edi_headers(ln_idx).order_possible_date              := it_edi_work.order_possible_date;               -- �󒍉\��
    gt_edi_headers(ln_idx).permission_possible_date         := it_edi_work.permission_possible_date;          -- ���e�\��
    gt_edi_headers(ln_idx).forward_month                    := it_edi_work.forward_month;                     -- ����N����
    gt_edi_headers(ln_idx).payment_settlement_date          := it_edi_work.payment_settlement_date;           -- �x�����ϓ�
    gt_edi_headers(ln_idx).handbill_start_date_active       := it_edi_work.handbill_start_date_active;        -- �`���V�J�n��
    gt_edi_headers(ln_idx).billing_due_date                 := it_edi_work.billing_due_date;                  -- ��������
    gt_edi_headers(ln_idx).shipping_time                    := it_edi_work.shipping_time;                     -- �o�׎���
    gt_edi_headers(ln_idx).delivery_schedule_time           := it_edi_work.delivery_schedule_time;            -- �[�i�\�莞��
    gt_edi_headers(ln_idx).order_time                       := it_edi_work.order_time;                        -- ��������
    gt_edi_headers(ln_idx).general_date_item1               := it_edi_work.general_date_item1;                -- �ėp���t���ڂP
    gt_edi_headers(ln_idx).general_date_item2               := it_edi_work.general_date_item2;                -- �ėp���t���ڂQ
    gt_edi_headers(ln_idx).general_date_item3               := it_edi_work.general_date_item3;                -- �ėp���t���ڂR
    gt_edi_headers(ln_idx).general_date_item4               := it_edi_work.general_date_item4;                -- �ėp���t���ڂS
    gt_edi_headers(ln_idx).general_date_item5               := it_edi_work.general_date_item5;                -- �ėp���t���ڂT
    gt_edi_headers(ln_idx).arrival_shipping_class           := it_edi_work.arrival_shipping_class;            -- ���o�׋敪
    gt_edi_headers(ln_idx).vendor_class                     := it_edi_work.vendor_class;                      -- �����敪
    gt_edi_headers(ln_idx).invoice_detailed_class           := it_edi_work.invoice_detailed_class;            -- �`�[����敪
    gt_edi_headers(ln_idx).unit_price_use_class             := it_edi_work.unit_price_use_class;              -- �P���g�p�敪
    gt_edi_headers(ln_idx).sub_distribution_center_code     := it_edi_work.sub_distribution_center_code;      -- �T�u�����Z���^�[�R�[�h
    gt_edi_headers(ln_idx).sub_distribution_center_name     := it_edi_work.sub_distribution_center_name;      -- �T�u�����Z���^�[�R�[�h��
    gt_edi_headers(ln_idx).center_delivery_method           := it_edi_work.center_delivery_method;            -- �Z���^�[�[�i���@
    gt_edi_headers(ln_idx).center_use_class                 := it_edi_work.center_use_class;                  -- �Z���^�[���p�敪
    gt_edi_headers(ln_idx).center_whse_class                := it_edi_work.center_whse_class;                 -- �Z���^�[�q�ɋ敪
    gt_edi_headers(ln_idx).center_area_class                := it_edi_work.center_area_class;                 -- �Z���^�[�n��敪
    gt_edi_headers(ln_idx).center_arrival_class             := it_edi_work.center_arrival_class;              -- �Z���^�[���׋敪
    gt_edi_headers(ln_idx).depot_class                      := it_edi_work.depot_class;                       -- �f�|�敪
    gt_edi_headers(ln_idx).tcdc_class                       := it_edi_work.tcdc_class;                        -- �s�b�c�b�敪
    gt_edi_headers(ln_idx).upc_flag                         := it_edi_work.upc_flag;                          -- �t�o�b�t���O
    gt_edi_headers(ln_idx).simultaneously_class             := it_edi_work.simultaneously_class;              -- ��ċ敪
    gt_edi_headers(ln_idx).business_id                      := it_edi_work.business_id;                       -- �Ɩ��h�c
    gt_edi_headers(ln_idx).whse_directly_class              := it_edi_work.whse_directly_class;               -- �q���敪
    gt_edi_headers(ln_idx).premium_rebate_class             := it_edi_work.premium_rebate_class;              -- �i�i���ߋ敪
    gt_edi_headers(ln_idx).item_type                        := it_edi_work.item_type;                         -- ���ڎ��
    gt_edi_headers(ln_idx).cloth_house_food_class           := it_edi_work.cloth_house_food_class;            -- �߉ƐH�敪
    gt_edi_headers(ln_idx).mix_class                        := it_edi_work.mix_class;                         -- ���݋敪
    gt_edi_headers(ln_idx).stk_class                        := it_edi_work.stk_class;                         -- �݌ɋ敪
    gt_edi_headers(ln_idx).last_modify_site_class           := it_edi_work.last_modify_site_class;            -- �ŏI�C���ꏊ�敪
    gt_edi_headers(ln_idx).report_class                     := it_edi_work.report_class;                      -- ���[�敪
    gt_edi_headers(ln_idx).addition_plan_class              := it_edi_work.addition_plan_class;               -- �ǉ��E�v��敪
    gt_edi_headers(ln_idx).registration_class               := it_edi_work.registration_class;                -- �o�^�敪
    gt_edi_headers(ln_idx).specific_class                   := it_edi_work.specific_class;                    -- ����敪
    gt_edi_headers(ln_idx).dealings_class                   := it_edi_work.dealings_class;                    -- ����敪
    gt_edi_headers(ln_idx).order_class                      := it_edi_work.order_class;                       -- �����敪
    gt_edi_headers(ln_idx).sum_line_class                   := it_edi_work.sum_line_class;                    -- �W�v���׋敪
    gt_edi_headers(ln_idx).shipping_guidance_class          := it_edi_work.shipping_guidance_class;           -- �o�׈ē��ȊO�敪
    gt_edi_headers(ln_idx).shipping_class                   := it_edi_work.shipping_class;                    -- �o�׋敪
    gt_edi_headers(ln_idx).product_code_use_class           := it_edi_work.product_code_use_class;            -- ���i�R�[�h�g�p�敪
    gt_edi_headers(ln_idx).cargo_item_class                 := it_edi_work.cargo_item_class;                  -- �ϑ��i�敪
    gt_edi_headers(ln_idx).ta_class                         := it_edi_work.ta_class;                          -- �s�^�`�敪
    gt_edi_headers(ln_idx).plan_code                        := it_edi_work.plan_code;                         -- ���R�[�h
    gt_edi_headers(ln_idx).category_code                    := it_edi_work.category_code;                     -- �J�e�S���[�R�[�h
    gt_edi_headers(ln_idx).category_class                   := it_edi_work.category_class;                    -- �J�e�S���[�敪
    gt_edi_headers(ln_idx).carrier_means                    := it_edi_work.carrier_means;                     -- �^����i
    gt_edi_headers(ln_idx).counter_code                     := it_edi_work.counter_code;                      -- ����R�[�h
    gt_edi_headers(ln_idx).move_sign                        := it_edi_work.move_sign;                         -- �ړ��T�C��
    gt_edi_headers(ln_idx).eos_handwriting_class            := it_edi_work.eos_handwriting_class;             -- �d�n�r�E�菑�敪
    gt_edi_headers(ln_idx).delivery_to_section_code         := it_edi_work.delivery_to_section_code;          -- �[�i��ۃR�[�h
    gt_edi_headers(ln_idx).invoice_detailed                 := it_edi_work.invoice_detailed;                  -- �`�[����
    gt_edi_headers(ln_idx).attach_qty                       := it_edi_work.attach_qty;                        -- �Y�t��
    gt_edi_headers(ln_idx).other_party_floor                := it_edi_work.other_party_floor;                 -- �t���A
    gt_edi_headers(ln_idx).text_no                          := it_edi_work.text_no;                           -- �s�d�w�s�m��
    gt_edi_headers(ln_idx).in_store_code                    := it_edi_work.in_store_code;                     -- �C���X�g�A�R�[�h
    gt_edi_headers(ln_idx).tag_data                         := it_edi_work.tag_data;                          -- �^�O
    gt_edi_headers(ln_idx).competition_code                 := it_edi_work.competition_code;                  -- ����
    gt_edi_headers(ln_idx).billing_chair                    := it_edi_work.billing_chair;                     -- ��������
    gt_edi_headers(ln_idx).chain_store_code                 := it_edi_work.chain_store_code;                  -- �`�F�[���X�g�A�[�R�[�h
    gt_edi_headers(ln_idx).chain_store_short_name           := it_edi_work.chain_store_short_name;            -- �`�F�[���X�g�A�[�R�[�h��������
    gt_edi_headers(ln_idx).direct_delivery_rcpt_fee         := it_edi_work.direct_delivery_rcpt_fee;          -- ���z���^���旿
    gt_edi_headers(ln_idx).bill_info                        := it_edi_work.bill_info;                         -- ��`���
    gt_edi_headers(ln_idx).description                      := it_edi_work.description;                       -- �E�v
    gt_edi_headers(ln_idx).interior_code                    := it_edi_work.interior_code;                     -- �����R�[�h
    gt_edi_headers(ln_idx).order_info_delivery_category     := it_edi_work.order_info_delivery_category;      -- �������@�[�i�J�e�S���[
    gt_edi_headers(ln_idx).purchase_type                    := it_edi_work.purchase_type;                     -- �d���`��
    gt_edi_headers(ln_idx).delivery_to_name_alt             := it_edi_work.delivery_to_name_alt;              -- �[�i�ꏊ���i�J�i�j
    gt_edi_headers(ln_idx).shop_opened_site                 := it_edi_work.shop_opened_site;                  -- �X�o�ꏊ
    gt_edi_headers(ln_idx).counter_name                     := it_edi_work.counter_name;                      -- ���ꖼ
    gt_edi_headers(ln_idx).extension_number                 := it_edi_work.extension_number;                  -- �����ԍ�
    gt_edi_headers(ln_idx).charge_name                      := it_edi_work.charge_name;                       -- �S���Җ�
    gt_edi_headers(ln_idx).price_tag                        := it_edi_work.price_tag;                         -- �l�D
    gt_edi_headers(ln_idx).tax_type                         := it_edi_work.tax_type;                          -- �Ŏ�
    gt_edi_headers(ln_idx).consumption_tax_class            := it_edi_work.consumption_tax_class;             -- ����ŋ敪
    gt_edi_headers(ln_idx).brand_class                      := it_edi_work.brand_class;                       -- �a�q
    gt_edi_headers(ln_idx).id_code                          := it_edi_work.id_code;                           -- �h�c�R�[�h
    gt_edi_headers(ln_idx).department_code                  := it_edi_work.department_code;                   -- �S�ݓX�R�[�h
    gt_edi_headers(ln_idx).department_name                  := it_edi_work.department_name;                   -- �S�ݓX��
    gt_edi_headers(ln_idx).item_type_number                 := it_edi_work.item_type_number;                  -- �i�ʔԍ�
    gt_edi_headers(ln_idx).description_department           := it_edi_work.description_department;            -- �E�v�i�S�ݓX�j
    gt_edi_headers(ln_idx).price_tag_method                 := it_edi_work.price_tag_method;                  -- �l�D���@
    gt_edi_headers(ln_idx).reason_column                    := it_edi_work.reason_column;                     -- ���R��
    gt_edi_headers(ln_idx).a_column_header                  := it_edi_work.a_column_header;                   -- �`���w�b�_
    gt_edi_headers(ln_idx).d_column_header                  := it_edi_work.d_column_header;                   -- �c���w�b�_
    gt_edi_headers(ln_idx).brand_code                       := it_edi_work.brand_code;                        -- �u�����h�R�[�h
    gt_edi_headers(ln_idx).line_code                        := it_edi_work.line_code;                         -- ���C���R�[�h
    gt_edi_headers(ln_idx).class_code                       := it_edi_work.class_code;                        -- �N���X�R�[�h
    gt_edi_headers(ln_idx).a1_column                        := it_edi_work.a1_column;                         -- �`�|�P��
    gt_edi_headers(ln_idx).b1_column                        := it_edi_work.b1_column;                         -- �a�|�P��
    gt_edi_headers(ln_idx).c1_column                        := it_edi_work.c1_column;                         -- �b�|�P��
    gt_edi_headers(ln_idx).d1_column                        := it_edi_work.d1_column;                         -- �c�|�P��
    gt_edi_headers(ln_idx).e1_column                        := it_edi_work.e1_column;                         -- �d�|�P��
    gt_edi_headers(ln_idx).a2_column                        := it_edi_work.a2_column;                         -- �`�|�Q��
    gt_edi_headers(ln_idx).b2_column                        := it_edi_work.b2_column;                         -- �a�|�Q��
    gt_edi_headers(ln_idx).c2_column                        := it_edi_work.c2_column;                         -- �b�|�Q��
    gt_edi_headers(ln_idx).d2_column                        := it_edi_work.d2_column;                         -- �c�|�Q��
    gt_edi_headers(ln_idx).e2_column                        := it_edi_work.e2_column;                         -- �d�|�Q��
    gt_edi_headers(ln_idx).a3_column                        := it_edi_work.a3_column;                         -- �`�|�R��
    gt_edi_headers(ln_idx).b3_column                        := it_edi_work.b3_column;                         -- �a�|�R��
    gt_edi_headers(ln_idx).c3_column                        := it_edi_work.c3_column;                         -- �b�|�R��
    gt_edi_headers(ln_idx).d3_column                        := it_edi_work.d3_column;                         -- �c�|�R��
    gt_edi_headers(ln_idx).e3_column                        := it_edi_work.e3_column;                         -- �d�|�R��
    gt_edi_headers(ln_idx).f1_column                        := it_edi_work.f1_column;                         -- �e�|�P��
    gt_edi_headers(ln_idx).g1_column                        := it_edi_work.g1_column;                         -- �f�|�P��
    gt_edi_headers(ln_idx).h1_column                        := it_edi_work.h1_column;                         -- �g�|�P��
    gt_edi_headers(ln_idx).i1_column                        := it_edi_work.i1_column;                         -- �h�|�P��
    gt_edi_headers(ln_idx).j1_column                        := it_edi_work.j1_column;                         -- �i�|�P��
    gt_edi_headers(ln_idx).k1_column                        := it_edi_work.k1_column;                         -- �j�|�P��
    gt_edi_headers(ln_idx).l1_column                        := it_edi_work.l1_column;                         -- �k�|�P��
    gt_edi_headers(ln_idx).f2_column                        := it_edi_work.f2_column;                         -- �e�|�Q��
    gt_edi_headers(ln_idx).g2_column                        := it_edi_work.g2_column;                         -- �f�|�Q��
    gt_edi_headers(ln_idx).h2_column                        := it_edi_work.h2_column;                         -- �g�|�Q��
    gt_edi_headers(ln_idx).i2_column                        := it_edi_work.i2_column;                         -- �h�|�Q��
    gt_edi_headers(ln_idx).j2_column                        := it_edi_work.j2_column;                         -- �i�|�Q��
    gt_edi_headers(ln_idx).k2_column                        := it_edi_work.k2_column;                         -- �j�|�Q��
    gt_edi_headers(ln_idx).l2_column                        := it_edi_work.l2_column;                         -- �k�|�Q��
    gt_edi_headers(ln_idx).f3_column                        := it_edi_work.f3_column;                         -- �e�|�R��
    gt_edi_headers(ln_idx).g3_column                        := it_edi_work.g3_column;                         -- �f�|�R��
    gt_edi_headers(ln_idx).h3_column                        := it_edi_work.h3_column;                         -- �g�|�R��
    gt_edi_headers(ln_idx).i3_column                        := it_edi_work.i3_column;                         -- �h�|�R��
    gt_edi_headers(ln_idx).j3_column                        := it_edi_work.j3_column;                         -- �i�|�R��
    gt_edi_headers(ln_idx).k3_column                        := it_edi_work.k3_column;                         -- �j�|�R��
    gt_edi_headers(ln_idx).l3_column                        := it_edi_work.l3_column;                         -- �k�|�R��
    gt_edi_headers(ln_idx).chain_peculiar_area_header       := it_edi_work.chain_peculiar_area_header;        -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
    gt_edi_headers(ln_idx).order_connection_number          := ln_seq_2;                                      -- �󒍊֘A�ԍ�
    gt_edi_headers(ln_idx).invoice_indv_order_qty           := it_edi_work.invoice_indv_order_qty;            -- �i�`�[�v�j�������ʁi�o���j
    gt_edi_headers(ln_idx).invoice_case_order_qty           := it_edi_work.invoice_case_order_qty;            -- �i�`�[�v�j�������ʁi�P�[�X�j
    gt_edi_headers(ln_idx).invoice_ball_order_qty           := it_edi_work.invoice_ball_order_qty;            -- �i�`�[�v�j�������ʁi�{�[���j
    gt_edi_headers(ln_idx).invoice_sum_order_qty            := it_edi_work.invoice_sum_order_qty;             -- �i�`�[�v�j�������ʁi���v�A�o���j
    gt_edi_headers(ln_idx).invoice_indv_shipping_qty        := it_edi_work.invoice_indv_shipping_qty;         -- �i�`�[�v�j�o�א��ʁi�o���j
    gt_edi_headers(ln_idx).invoice_case_shipping_qty        := it_edi_work.invoice_case_shipping_qty;         -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
    gt_edi_headers(ln_idx).invoice_ball_shipping_qty        := it_edi_work.invoice_ball_shipping_qty;         -- �i�`�[�v�j�o�א��ʁi�{�[���j
    gt_edi_headers(ln_idx).invoice_pallet_shipping_qty      := it_edi_work.invoice_pallet_shipping_qty;       -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
    gt_edi_headers(ln_idx).invoice_sum_shipping_qty         := it_edi_work.invoice_sum_shipping_qty;          -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
    gt_edi_headers(ln_idx).invoice_indv_stockout_qty        := it_edi_work.invoice_indv_stockout_qty;         -- �i�`�[�v�j���i���ʁi�o���j
    gt_edi_headers(ln_idx).invoice_case_stockout_qty        := it_edi_work.invoice_case_stockout_qty;         -- �i�`�[�v�j���i���ʁi�P�[�X�j
    gt_edi_headers(ln_idx).invoice_ball_stockout_qty        := it_edi_work.invoice_ball_stockout_qty;         -- �i�`�[�v�j���i���ʁi�{�[���j
    gt_edi_headers(ln_idx).invoice_sum_stockout_qty         := it_edi_work.invoice_sum_stockout_qty;          -- �i�`�[�v�j���i���ʁi���v�A�o���j
    gt_edi_headers(ln_idx).invoice_case_qty                 := it_edi_work.invoice_case_qty;                  -- �i�`�[�v�j�P�[�X����
    gt_edi_headers(ln_idx).invoice_fold_container_qty       := it_edi_work.invoice_fold_container_qty;        -- �i�`�[�v�j�I���R���i�o���j����
    gt_edi_headers(ln_idx).invoice_order_cost_amt           := it_edi_work.invoice_order_cost_amt;            -- �i�`�[�v�j�������z�i�����j
    gt_edi_headers(ln_idx).invoice_shipping_cost_amt        := it_edi_work.invoice_shipping_cost_amt;         -- �i�`�[�v�j�������z�i�o�ׁj
    gt_edi_headers(ln_idx).invoice_stockout_cost_amt        := it_edi_work.invoice_stockout_cost_amt;         -- �i�`�[�v�j�������z�i���i�j
    gt_edi_headers(ln_idx).invoice_order_price_amt          := it_edi_work.invoice_order_price_amt;           -- �i�`�[�v�j�������z�i�����j
    gt_edi_headers(ln_idx).invoice_shipping_price_amt       := it_edi_work.invoice_shipping_price_amt;        -- �i�`�[�v�j�������z�i�o�ׁj
    gt_edi_headers(ln_idx).invoice_stockout_price_amt       := it_edi_work.invoice_stockout_price_amt;        -- �i�`�[�v�j�������z�i���i�j
    gt_edi_headers(ln_idx).total_indv_order_qty             := it_edi_work.total_indv_order_qty;              -- �i�����v�j�������ʁi�o���j
    gt_edi_headers(ln_idx).total_case_order_qty             := it_edi_work.total_case_order_qty;              -- �i�����v�j�������ʁi�P�[�X�j
    gt_edi_headers(ln_idx).total_ball_order_qty             := it_edi_work.total_ball_order_qty;              -- �i�����v�j�������ʁi�{�[���j
    gt_edi_headers(ln_idx).total_sum_order_qty              := it_edi_work.total_sum_order_qty;               -- �i�����v�j�������ʁi���v�A�o���j
    gt_edi_headers(ln_idx).total_indv_shipping_qty          := it_edi_work.total_indv_shipping_qty;           -- �i�����v�j�o�א��ʁi�o���j
    gt_edi_headers(ln_idx).total_case_shipping_qty          := it_edi_work.total_case_shipping_qty;           -- �i�����v�j�o�א��ʁi�P�[�X�j
    gt_edi_headers(ln_idx).total_ball_shipping_qty          := it_edi_work.total_ball_shipping_qty;           -- �i�����v�j�o�א��ʁi�{�[���j
    gt_edi_headers(ln_idx).total_pallet_shipping_qty        := it_edi_work.total_pallet_shipping_qty;         -- �i�����v�j�o�א��ʁi�p���b�g�j
    gt_edi_headers(ln_idx).total_sum_shipping_qty           := it_edi_work.total_sum_shipping_qty;            -- �i�����v�j�o�א��ʁi���v�A�o���j
    gt_edi_headers(ln_idx).total_indv_stockout_qty          := it_edi_work.total_indv_stockout_qty;           -- �i�����v�j���i���ʁi�o���j
    gt_edi_headers(ln_idx).total_case_stockout_qty          := it_edi_work.total_case_stockout_qty;           -- �i�����v�j���i���ʁi�P�[�X�j
    gt_edi_headers(ln_idx).total_ball_stockout_qty          := it_edi_work.total_ball_stockout_qty;           -- �i�����v�j���i���ʁi�{�[���j
    gt_edi_headers(ln_idx).total_sum_stockout_qty           := it_edi_work.total_sum_stockout_qty;            -- �i�����v�j���i���ʁi���v�A�o���j
    gt_edi_headers(ln_idx).total_case_qty                   := it_edi_work.total_case_qty;                    -- �i�����v�j�P�[�X����
    gt_edi_headers(ln_idx).total_fold_container_qty         := it_edi_work.total_fold_container_qty;          -- �i�����v�j�I���R���i�o���j����
    gt_edi_headers(ln_idx).total_order_cost_amt             := it_edi_work.total_order_cost_amt;              -- �i�����v�j�������z�i�����j
    gt_edi_headers(ln_idx).total_shipping_cost_amt          := it_edi_work.total_shipping_cost_amt;           -- �i�����v�j�������z�i�o�ׁj
    gt_edi_headers(ln_idx).total_stockout_cost_amt          := it_edi_work.total_stockout_cost_amt;           -- �i�����v�j�������z�i���i�j
    gt_edi_headers(ln_idx).total_order_price_amt            := it_edi_work.total_order_price_amt;             -- �i�����v�j�������z�i�����j
    gt_edi_headers(ln_idx).total_shipping_price_amt         := it_edi_work.total_shipping_price_amt;          -- �i�����v�j�������z�i�o�ׁj
    gt_edi_headers(ln_idx).total_stockout_price_amt         := it_edi_work.total_stockout_price_amt;          -- �i�����v�j�������z�i���i�j
    gt_edi_headers(ln_idx).total_line_qty                   := it_edi_work.total_line_qty;                    -- �g�[�^���s��
    gt_edi_headers(ln_idx).total_invoice_qty                := it_edi_work.total_invoice_qty;                 -- �g�[�^���`�[����
    gt_edi_headers(ln_idx).chain_peculiar_area_footer       := it_edi_work.chain_peculiar_area_footer;        -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
    gt_edi_headers(ln_idx).conv_customer_code               := it_edi_work.conv_customer_code;                -- �ϊ���ڋq�R�[�h
-- 2009/12/28 M.Sano Ver.1.14 mod Start
--    gt_edi_headers(ln_idx).order_forward_flag               := cv_order_forward_flag;                         -- �󒍘A�g�σt���O
    gt_edi_headers(ln_idx).order_forward_flag               := it_edi_work.order_forward_flag;                -- �󒍘A�g�σt���O
-- 2009/12/28 M.Sano Ver.1.14 mod End
    gt_edi_headers(ln_idx).creation_class                   := gv_creation_class;                             -- �쐬���敪�F��
    gt_edi_headers(ln_idx).edi_delivery_schedule_flag       := cv_edi_delivery_flag;                          -- EDI�[�i�\�著�M�σt���O
    gt_edi_headers(ln_idx).price_list_header_id             := it_edi_work.price_list_header_id;              -- ���i�\�w�b�_ID
-- 2009/12/28 M.Sano Ver.1.14 add Start
    gt_edi_headers(ln_idx).tsukagatazaiko_div               := it_edi_work.tsukagatazaiko_div;                -- �ʉߍ݌Ɍ^�敪
-- 2009/12/28 M.Sano Ver.1.14 add End
-- 2010/01/19 Ver1.15 M.Sano Add Start
    gt_edi_headers(ln_idx).edi_received_date                := it_edi_work.creation_date;                     -- EDI��M��
-- 2010/01/19 Ver1.15 M.Sano Add End
    gt_edi_headers(ln_idx).created_by                       := cn_created_by;                                 -- �쐬��
    gt_edi_headers(ln_idx).creation_date                    := cd_creation_date;                              -- �쐬��
    gt_edi_headers(ln_idx).last_updated_by                  := cn_last_updated_by;                            -- �ŏI�X�V��
    gt_edi_headers(ln_idx).last_update_date                 := cd_last_update_date;                           -- �ŏI�X�V��
    gt_edi_headers(ln_idx).last_update_login                := cn_last_update_login;                          -- �ŏI�X�V���O�C��
    gt_edi_headers(ln_idx).request_id                       := cn_request_id;                                 -- �v��ID
    gt_edi_headers(ln_idx).program_application_id           := cn_program_application_id;                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    gt_edi_headers(ln_idx).program_id                       := cn_program_id;                                 -- �R���J�����g�E�v���O����ID
    gt_edi_headers(ln_idx).program_update_date              := cd_program_update_date;                        -- �v���O�����X�V��
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_set_ins_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_upd_headers
   * Description      : EDI�w�b�_���A�b�v�f�[�g�p�ϐ��i�[(A-9)
   ***********************************************************************************/
  PROCEDURE proc_set_upd_headers(
    it_edi_work   IN  g_edi_work_rtype,    -- EDI�󒍏�񃏁[�N���R�[�h
    in_edi_header_info_id IN NUMBER,       -- EDI�w�b�_���ID
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_upd_headers'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx     NUMBER;
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
    ln_idx := gt_upd_edi_header_info_id.COUNT + 1;
--
    gt_upd_edi_header_info_id(ln_idx)                  := in_edi_header_info_id;                         -- EDI�w�b�_���ID
    gt_upd_medium_class(ln_idx)                        := it_edi_work.medium_class;                      -- �}�̋敪
    gt_upd_data_type_code(ln_idx)                      := it_edi_work.data_type_code;                    -- �f�[�^��R�[�h
    gt_upd_file_no(ln_idx)                             := it_edi_work.file_no;                           -- �t�@�C���m��
    gt_upd_info_class(ln_idx)                          := it_edi_work.info_class;                        -- ���敪
    gt_upd_process_date(ln_idx)                        := it_edi_work.process_date;                      -- ������
    gt_upd_process_time(ln_idx)                        := it_edi_work.process_time;                      -- ��������
    gt_upd_base_code(ln_idx)                           := it_edi_work.base_code;                         -- ���_�i����j�R�[�h
    gt_upd_base_name(ln_idx)                           := it_edi_work.base_name;                         -- ���_���i�������j
    gt_upd_base_name_alt(ln_idx)                       := it_edi_work.base_name_alt;                     -- ���_���i�J�i�j
    gt_upd_edi_chain_code(ln_idx)                      := it_edi_work.edi_chain_code;                    -- �d�c�h�`�F�[���X�R�[�h
    gt_upd_edi_chain_name(ln_idx)                      := it_edi_work.edi_chain_name;                    -- �d�c�h�`�F�[���X���i�����j
    gt_upd_edi_chain_name_alt(ln_idx)                  := it_edi_work.edi_chain_name_alt;                -- �d�c�h�`�F�[���X���i�J�i�j
    gt_upd_chain_code(ln_idx)                          := it_edi_work.chain_code;                        -- �`�F�[���X�R�[�h
    gt_upd_chain_name(ln_idx)                          := it_edi_work.chain_name;                        -- �`�F�[���X���i�����j
    gt_upd_chain_name_alt(ln_idx)                      := it_edi_work.chain_name_alt;                    -- �`�F�[���X���i�J�i�j
    gt_upd_report_code(ln_idx)                         := it_edi_work.report_code;                       -- ���[�R�[�h
    gt_upd_report_show_name(ln_idx)                    := it_edi_work.report_show_name;                  -- ���[�\����
    gt_upd_customer_code(ln_idx)                       := it_edi_work.customer_code;                     -- �ڋq�R�[�h
    gt_upd_customer_name(ln_idx)                       := it_edi_work.customer_name;                     -- �ڋq���i�����j
    gt_upd_customer_name_alt(ln_idx)                   := it_edi_work.customer_name_alt;                 -- �ڋq���i�J�i�j
    gt_upd_company_code(ln_idx)                        := it_edi_work.company_code;                      -- �ЃR�[�h
    gt_upd_company_name(ln_idx)                        := it_edi_work.company_name;                      -- �Ж��i�����j
    gt_upd_company_name_alt(ln_idx)                    := it_edi_work.company_name_alt;                  -- �Ж��i�J�i�j
    gt_upd_shop_code(ln_idx)                           := it_edi_work.shop_code;                         -- �X�R�[�h
    gt_upd_shop_name(ln_idx)                           := it_edi_work.shop_name;                         -- �X���i�����j
    gt_upd_shop_name_alt(ln_idx)                       := it_edi_work.shop_name_alt;                     -- �X���i�J�i�j
    gt_upd_delivery_cent_cd(ln_idx)                    := it_edi_work.delivery_center_code;              -- �[���Z���^�[�R�[�h
    gt_upd_delivery_cent_nm(ln_idx)                    := it_edi_work.delivery_center_name;              -- �[���Z���^�[���i�����j
    gt_upd_delivery_cent_nm_alt(ln_idx)                := it_edi_work.delivery_center_name_alt;          -- �[���Z���^�[���i�J�i�j
    gt_upd_order_date(ln_idx)                          := it_edi_work.order_date;                        -- ������
    gt_upd_center_delivery_date(ln_idx)                := it_edi_work.center_delivery_date;              -- �Z���^�[�[�i��
    gt_upd_result_delivery_date(ln_idx)                := it_edi_work.result_delivery_date;              -- ���[�i��
    gt_upd_shop_delivery_date(ln_idx)                  := it_edi_work.shop_delivery_date;                -- �X�ܔ[�i��
    gt_upd_data_creation_date_edi(ln_idx)              := it_edi_work.data_creation_date_edi_data;       -- �f�[�^�쐬���i�d�c�h�f�[�^���j
    gt_upd_data_creation_time_edi(ln_idx)              := it_edi_work.data_creation_time_edi_data;       -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
    gt_upd_invoice_class(ln_idx)                       := it_edi_work.invoice_class;                     -- �`�[�敪
    gt_upd_small_class_cd(ln_idx)                      := it_edi_work.small_classification_code;         -- �����ރR�[�h
    gt_upd_small_class_nm(ln_idx)                      := it_edi_work.small_classification_name;         -- �����ޖ�
    gt_upd_middle_class_cd(ln_idx)                     := it_edi_work.middle_classification_code;        -- �����ރR�[�h
    gt_upd_middle_class_nm(ln_idx)                     := it_edi_work.middle_classification_name;        -- �����ޖ�
    gt_upd_big_class_cd(ln_idx)                        := it_edi_work.big_classification_code;           -- �啪�ރR�[�h
    gt_upd_big_class_nm(ln_idx)                        := it_edi_work.big_classification_name;           -- �啪�ޖ�
    gt_upd_other_party_depart_cd(ln_idx)               := it_edi_work.other_party_department_code;       -- ����敔��R�[�h
    gt_upd_other_party_order_num(ln_idx)               := it_edi_work.other_party_order_number;          -- ����攭���ԍ�
    gt_upd_check_digit_class(ln_idx)                   := it_edi_work.check_digit_class;                 -- �`�F�b�N�f�W�b�g�L���敪
    gt_upd_invoice_number(ln_idx)                      := it_edi_work.invoice_number;                    -- �`�[�ԍ�
    gt_upd_check_digit(ln_idx)                         := it_edi_work.check_digit;                       -- �`�F�b�N�f�W�b�g
    gt_upd_close_date(ln_idx)                          := it_edi_work.close_date;                        -- ����
    gt_upd_order_no_ebs(ln_idx)                        := it_edi_work.order_no_ebs;                      -- �󒍂m���i�d�a�r�j
    gt_upd_ar_sale_class(ln_idx)                       := it_edi_work.ar_sale_class;                     -- �����敪
    gt_upd_delivery_classe(ln_idx)                     := it_edi_work.delivery_classe;                   -- �z���敪
    gt_upd_opportunity_no(ln_idx)                      := it_edi_work.opportunity_no;                    -- �ւm��
    gt_upd_contact_to(ln_idx)                          := it_edi_work.contact_to;                        -- �A����
    gt_upd_route_sales(ln_idx)                         := it_edi_work.route_sales;                       -- ���[�g�Z�[���X
    gt_upd_corporate_code(ln_idx)                      := it_edi_work.corporate_code;                    -- �@�l�R�[�h
    gt_upd_maker_name(ln_idx)                          := it_edi_work.maker_name;                        -- ���[�J�[��
    gt_upd_area_code(ln_idx)                           := it_edi_work.area_code;                         -- �n��R�[�h
    gt_upd_area_name(ln_idx)                           := it_edi_work.area_name;                         -- �n�於�i�����j
    gt_upd_area_name_alt(ln_idx)                       := it_edi_work.area_name_alt;                     -- �n�於�i�J�i�j
    gt_upd_vendor_code(ln_idx)                         := it_edi_work.vendor_code;                       -- �����R�[�h
    gt_upd_vendor_name(ln_idx)                         := it_edi_work.vendor_name;                       -- ����於�i�����j
    gt_upd_vendor_name1_alt(ln_idx)                    := it_edi_work.vendor_name1_alt;                  -- ����於�P�i�J�i�j
    gt_upd_vendor_name2_alt(ln_idx)                    := it_edi_work.vendor_name2_alt;                  -- ����於�Q�i�J�i�j
    gt_upd_vendor_tel(ln_idx)                          := it_edi_work.vendor_tel;                        -- �����s�d�k
    gt_upd_vendor_charge(ln_idx)                       := it_edi_work.vendor_charge;                     -- �����S����
    gt_upd_vendor_address(ln_idx)                      := it_edi_work.vendor_address;                    -- �����Z���i�����j
    gt_upd_deliver_to_code_itouen(ln_idx)              := it_edi_work.deliver_to_code_itouen;            -- �͂���R�[�h�i�ɓ����j
    gt_upd_deliver_to_code_chain(ln_idx)               := it_edi_work.deliver_to_code_chain;             -- �͂���R�[�h�i�`�F�[���X�j
    gt_upd_deliver_to(ln_idx)                          := it_edi_work.deliver_to;                        -- �͂���i�����j
    gt_upd_deliver_to1_alt(ln_idx)                     := it_edi_work.deliver_to1_alt;                   -- �͂���P�i�J�i�j
    gt_upd_deliver_to2_alt(ln_idx)                     := it_edi_work.deliver_to2_alt;                   -- �͂���Q�i�J�i�j
    gt_upd_deliver_to_address(ln_idx)                  := it_edi_work.deliver_to_address;                -- �͂���Z���i�����j
    gt_upd_deliver_to_address_alt(ln_idx)              := it_edi_work.deliver_to_address_alt;            -- �͂���Z���i�J�i�j
    gt_upd_deliver_to_tel(ln_idx)                      := it_edi_work.deliver_to_tel;                    -- �͂���s�d�k
    gt_upd_balance_acct_cd(ln_idx)                     := it_edi_work.balance_accounts_code;             -- ������R�[�h
    gt_upd_balance_acct_company_cd(ln_idx)             := it_edi_work.balance_accounts_company_code;     -- ������ЃR�[�h
    gt_upd_balance_acct_shop_cd(ln_idx)                := it_edi_work.balance_accounts_shop_code;        -- ������X�R�[�h
    gt_upd_balance_acct_nm(ln_idx)                     := it_edi_work.balance_accounts_name;             -- �����於�i�����j
    gt_upd_balance_acct_nm_alt(ln_idx)                 := it_edi_work.balance_accounts_name_alt;         -- �����於�i�J�i�j
    gt_upd_balance_acct_addr(ln_idx)                   := it_edi_work.balance_accounts_address;          -- ������Z���i�����j
    gt_upd_balance_acct_addr_alt(ln_idx)               := it_edi_work.balance_accounts_address_alt;      -- ������Z���i�J�i�j
    gt_upd_balance_acct_tel(ln_idx)                    := it_edi_work.balance_accounts_tel;              -- ������s�d�k
    gt_upd_order_possible_date(ln_idx)                 := it_edi_work.order_possible_date;               -- �󒍉\��
    gt_upd_permit_possible_date(ln_idx)                := it_edi_work.permission_possible_date;          -- ���e�\��
    gt_upd_forward_month(ln_idx)                       := it_edi_work.forward_month;                     -- ����N����
    gt_upd_payment_settlement_date(ln_idx)             := it_edi_work.payment_settlement_date;           -- �x�����ϓ�
    gt_upd_handbill_start_date_act(ln_idx)             := it_edi_work.handbill_start_date_active;        -- �`���V�J�n��
    gt_upd_billing_due_date(ln_idx)                    := it_edi_work.billing_due_date;                  -- ��������
    gt_upd_shipping_time(ln_idx)                       := it_edi_work.shipping_time;                     -- �o�׎���
    gt_upd_delivery_schedule_time(ln_idx)              := it_edi_work.delivery_schedule_time;            -- �[�i�\�莞��
    gt_upd_order_time(ln_idx)                          := it_edi_work.order_time;                        -- ��������
    gt_upd_general_date_item1(ln_idx)                  := it_edi_work.general_date_item1;                -- �ėp���t���ڂP
    gt_upd_general_date_item2(ln_idx)                  := it_edi_work.general_date_item2;                -- �ėp���t���ڂQ
    gt_upd_general_date_item3(ln_idx)                  := it_edi_work.general_date_item3;                -- �ėp���t���ڂR
    gt_upd_general_date_item4(ln_idx)                  := it_edi_work.general_date_item4;                -- �ėp���t���ڂS
    gt_upd_general_date_item5(ln_idx)                  := it_edi_work.general_date_item5;                -- �ėp���t���ڂT
    gt_upd_arrival_shipping_class(ln_idx)              := it_edi_work.arrival_shipping_class;            -- ���o�׋敪
    gt_upd_vendor_class(ln_idx)                        := it_edi_work.vendor_class;                      -- �����敪
    gt_upd_invoice_detailed_class(ln_idx)              := it_edi_work.invoice_detailed_class;            -- �`�[����敪
    gt_upd_unit_price_use_class(ln_idx)                := it_edi_work.unit_price_use_class;              -- �P���g�p�敪
    gt_upd_sub_dist_center_cd(ln_idx)                  := it_edi_work.sub_distribution_center_code;      -- �T�u�����Z���^�[�R�[�h
    gt_upd_sub_dist_center_nm(ln_idx)                  := it_edi_work.sub_distribution_center_name;      -- �T�u�����Z���^�[�R�[�h��
    gt_upd_center_delivery_method(ln_idx)              := it_edi_work.center_delivery_method;            -- �Z���^�[�[�i���@
    gt_upd_center_use_class(ln_idx)                    := it_edi_work.center_use_class;                  -- �Z���^�[���p�敪
    gt_upd_center_whse_class(ln_idx)                   := it_edi_work.center_whse_class;                 -- �Z���^�[�q�ɋ敪
    gt_upd_center_area_class(ln_idx)                   := it_edi_work.center_area_class;                 -- �Z���^�[�n��敪
    gt_upd_center_arrival_class(ln_idx)                := it_edi_work.center_arrival_class;              -- �Z���^�[���׋敪
    gt_upd_depot_class(ln_idx)                         := it_edi_work.depot_class;                       -- �f�|�敪
    gt_upd_tcdc_class(ln_idx)                          := it_edi_work.tcdc_class;                        -- �s�b�c�b�敪
    gt_upd_upc_flag(ln_idx)                            := it_edi_work.upc_flag;                          -- �t�o�b�t���O
    gt_upd_simultaneously_class(ln_idx)                := it_edi_work.simultaneously_class;              -- ��ċ敪
    gt_upd_business_id(ln_idx)                         := it_edi_work.business_id;                       -- �Ɩ��h�c
    gt_upd_whse_directly_class(ln_idx)                 := it_edi_work.whse_directly_class;               -- �q���敪
    gt_upd_premium_rebate_class(ln_idx)                := it_edi_work.premium_rebate_class;              -- �i�i���ߋ敪
    gt_upd_item_type(ln_idx)                           := it_edi_work.item_type;                         -- ���ڎ��
    gt_upd_cloth_house_food_class(ln_idx)              := it_edi_work.cloth_house_food_class;            -- �߉ƐH�敪
    gt_upd_mix_class(ln_idx)                           := it_edi_work.mix_class;                         -- ���݋敪
    gt_upd_stk_class(ln_idx)                           := it_edi_work.stk_class;                         -- �݌ɋ敪
    gt_upd_last_modify_site_class(ln_idx)              := it_edi_work.last_modify_site_class;            -- �ŏI�C���ꏊ�敪
    gt_upd_report_class(ln_idx)                        := it_edi_work.report_class;                      -- ���[�敪
    gt_upd_addition_plan_class(ln_idx)                 := it_edi_work.addition_plan_class;               -- �ǉ��E�v��敪
    gt_upd_registration_class(ln_idx)                  := it_edi_work.registration_class;                -- �o�^�敪
    gt_upd_specific_class(ln_idx)                      := it_edi_work.specific_class;                    -- ����敪
    gt_upd_dealings_class(ln_idx)                      := it_edi_work.dealings_class;                    -- ����敪
    gt_upd_order_class(ln_idx)                         := it_edi_work.order_class;                       -- �����敪
    gt_upd_sum_line_class(ln_idx)                      := it_edi_work.sum_line_class;                    -- �W�v���׋敪
    gt_upd_shipping_guidance_class(ln_idx)             := it_edi_work.shipping_guidance_class;           -- �o�׈ē��ȊO�敪
    gt_upd_shipping_class(ln_idx)                      := it_edi_work.shipping_class;                    -- �o�׋敪
    gt_upd_product_code_use_class(ln_idx)              := it_edi_work.product_code_use_class;            -- ���i�R�[�h�g�p�敪
    gt_upd_cargo_item_class(ln_idx)                    := it_edi_work.cargo_item_class;                  -- �ϑ��i�敪
    gt_upd_ta_class(ln_idx)                            := it_edi_work.ta_class;                          -- �s�^�`�敪
    gt_upd_plan_code(ln_idx)                           := it_edi_work.plan_code;                         -- ���R�[�h
    gt_upd_category_code(ln_idx)                       := it_edi_work.category_code;                     -- �J�e�S���[�R�[�h
    gt_upd_category_class(ln_idx)                      := it_edi_work.category_class;                    -- �J�e�S���[�敪
    gt_upd_carrier_means(ln_idx)                       := it_edi_work.carrier_means;                     -- �^����i
    gt_upd_counter_code(ln_idx)                        := it_edi_work.counter_code;                      -- ����R�[�h
    gt_upd_move_sign(ln_idx)                           := it_edi_work.move_sign;                         -- �ړ��T�C��
    gt_upd_eos_handwriting_class(ln_idx)               := it_edi_work.eos_handwriting_class;             -- �d�n�r�E�菑�敪
    gt_upd_delivery_to_sect_cd(ln_idx)                 := it_edi_work.delivery_to_section_code;          -- �[�i��ۃR�[�h
    gt_upd_invoice_detailed(ln_idx)                    := it_edi_work.invoice_detailed;                  -- �`�[����
    gt_upd_attach_qty(ln_idx)                          := it_edi_work.attach_qty;                        -- �Y�t��
    gt_upd_other_party_floor(ln_idx)                   := it_edi_work.other_party_floor;                 -- �t���A
    gt_upd_text_no(ln_idx)                             := it_edi_work.text_no;                           -- �s�d�w�s�m��
    gt_upd_in_store_code(ln_idx)                       := it_edi_work.in_store_code;                     -- �C���X�g�A�R�[�h
    gt_upd_tag_data(ln_idx)                            := it_edi_work.tag_data;                          -- �^�O
    gt_upd_competition_code(ln_idx)                    := it_edi_work.competition_code;                  -- ����
    gt_upd_billing_chair(ln_idx)                       := it_edi_work.billing_chair;                     -- ��������
    gt_upd_chain_store_code(ln_idx)                    := it_edi_work.chain_store_code;                  -- �`�F�[���X�g�A�[�R�[�h
    gt_upd_chain_store_short_name(ln_idx)              := it_edi_work.chain_store_short_name;            -- �`�F�[���X�g�A�[�R�[�h��������
    gt_upd_dirct_delivery_rcpt_fee(ln_idx)             := it_edi_work.direct_delivery_rcpt_fee;          -- ���z���^���旿
    gt_upd_bill_info(ln_idx)                           := it_edi_work.bill_info;                         -- ��`���
    gt_upd_description(ln_idx)                         := it_edi_work.description;                       -- �E�v
    gt_upd_interior_code(ln_idx)                       := it_edi_work.interior_code;                     -- �����R�[�h
    gt_upd_order_info_delivery_cat(ln_idx)             := it_edi_work.order_info_delivery_category;      -- �������@�[�i�J�e�S���[
    gt_upd_purchase_type(ln_idx)                       := it_edi_work.purchase_type;                     -- �d���`��
    gt_upd_delivery_to_name_alt(ln_idx)                := it_edi_work.delivery_to_name_alt;              -- �[�i�ꏊ���i�J�i�j
    gt_upd_shop_opened_site(ln_idx)                    := it_edi_work.shop_opened_site;                  -- �X�o�ꏊ
    gt_upd_counter_name(ln_idx)                        := it_edi_work.counter_name;                      -- ���ꖼ
    gt_upd_extension_number(ln_idx)                    := it_edi_work.extension_number;                  -- �����ԍ�
    gt_upd_charge_name(ln_idx)                         := it_edi_work.charge_name;                       -- �S���Җ�
    gt_upd_price_tag(ln_idx)                           := it_edi_work.price_tag;                         -- �l�D
    gt_upd_tax_type(ln_idx)                            := it_edi_work.tax_type;                          -- �Ŏ�
    gt_upd_consumption_tax_class(ln_idx)               := it_edi_work.consumption_tax_class;             -- ����ŋ敪
    gt_upd_brand_class(ln_idx)                         := it_edi_work.brand_class;                       -- �a�q
    gt_upd_id_code(ln_idx)                             := it_edi_work.id_code;                           -- �h�c�R�[�h
    gt_upd_department_code(ln_idx)                     := it_edi_work.department_code;                   -- �S�ݓX�R�[�h
    gt_upd_department_name(ln_idx)                     := it_edi_work.department_name;                   -- �S�ݓX��
    gt_upd_item_type_number(ln_idx)                    := it_edi_work.item_type_number;                  -- �i�ʔԍ�
    gt_upd_description_department(ln_idx)              := it_edi_work.description_department;            -- �E�v�i�S�ݓX�j
    gt_upd_price_tag_method(ln_idx)                    := it_edi_work.price_tag_method;                  -- �l�D���@
    gt_upd_reason_column(ln_idx)                       := it_edi_work.reason_column;                     -- ���R��
    gt_upd_a_column_header(ln_idx)                     := it_edi_work.a_column_header;                   -- �`���w�b�_
    gt_upd_d_column_header(ln_idx)                     := it_edi_work.d_column_header;                   -- �c���w�b�_
    gt_upd_brand_code(ln_idx)                          := it_edi_work.brand_code;                        -- �u�����h�R�[�h
    gt_upd_line_code(ln_idx)                           := it_edi_work.line_code;                         -- ���C���R�[�h
    gt_upd_class_code(ln_idx)                          := it_edi_work.class_code;                        -- �N���X�R�[�h
    gt_upd_a1_column(ln_idx)                           := it_edi_work.a1_column;                         -- �`�|�P��
    gt_upd_b1_column(ln_idx)                           := it_edi_work.b1_column;                         -- �a�|�P��
    gt_upd_c1_column(ln_idx)                           := it_edi_work.c1_column;                         -- �b�|�P��
    gt_upd_d1_column(ln_idx)                           := it_edi_work.d1_column;                         -- �c�|�P��
    gt_upd_e1_column(ln_idx)                           := it_edi_work.e1_column;                         -- �d�|�P��
    gt_upd_a2_column(ln_idx)                           := it_edi_work.a2_column;                         -- �`�|�Q��
    gt_upd_b2_column(ln_idx)                           := it_edi_work.b2_column;                         -- �a�|�Q��
    gt_upd_c2_column(ln_idx)                           := it_edi_work.c2_column;                         -- �b�|�Q��
    gt_upd_d2_column(ln_idx)                           := it_edi_work.d2_column;                         -- �c�|�Q��
    gt_upd_e2_column(ln_idx)                           := it_edi_work.e2_column;                         -- �d�|�Q��
    gt_upd_a3_column(ln_idx)                           := it_edi_work.a3_column;                         -- �`�|�R��
    gt_upd_b3_column(ln_idx)                           := it_edi_work.b3_column;                         -- �a�|�R��
    gt_upd_c3_column(ln_idx)                           := it_edi_work.c3_column;                         -- �b�|�R��
    gt_upd_d3_column(ln_idx)                           := it_edi_work.d3_column;                         -- �c�|�R��
    gt_upd_e3_column(ln_idx)                           := it_edi_work.e3_column;                         -- �d�|�R��
    gt_upd_f1_column(ln_idx)                           := it_edi_work.f1_column;                         -- �e�|�P��
    gt_upd_g1_column(ln_idx)                           := it_edi_work.g1_column;                         -- �f�|�P��
    gt_upd_h1_column(ln_idx)                           := it_edi_work.h1_column;                         -- �g�|�P��
    gt_upd_i1_column(ln_idx)                           := it_edi_work.i1_column;                         -- �h�|�P��
    gt_upd_j1_column(ln_idx)                           := it_edi_work.j1_column;                         -- �i�|�P��
    gt_upd_k1_column(ln_idx)                           := it_edi_work.k1_column;                         -- �j�|�P��
    gt_upd_l1_column(ln_idx)                           := it_edi_work.l1_column;                         -- �k�|�P��
    gt_upd_f2_column(ln_idx)                           := it_edi_work.f2_column;                         -- �e�|�Q��
    gt_upd_g2_column(ln_idx)                           := it_edi_work.g2_column;                         -- �f�|�Q��
    gt_upd_h2_column(ln_idx)                           := it_edi_work.h2_column;                         -- �g�|�Q��
    gt_upd_i2_column(ln_idx)                           := it_edi_work.i2_column;                         -- �h�|�Q��
    gt_upd_j2_column(ln_idx)                           := it_edi_work.j2_column;                         -- �i�|�Q��
    gt_upd_k2_column(ln_idx)                           := it_edi_work.k2_column;                         -- �j�|�Q��
    gt_upd_l2_column(ln_idx)                           := it_edi_work.l2_column;                         -- �k�|�Q��
    gt_upd_f3_column(ln_idx)                           := it_edi_work.f3_column;                         -- �e�|�R��
    gt_upd_g3_column(ln_idx)                           := it_edi_work.g3_column;                         -- �f�|�R��
    gt_upd_h3_column(ln_idx)                           := it_edi_work.h3_column;                         -- �g�|�R��
    gt_upd_i3_column(ln_idx)                           := it_edi_work.i3_column;                         -- �h�|�R��
    gt_upd_j3_column(ln_idx)                           := it_edi_work.j3_column;                         -- �i�|�R��
    gt_upd_k3_column(ln_idx)                           := it_edi_work.k3_column;                         -- �j�|�R��
    gt_upd_l3_column(ln_idx)                           := it_edi_work.l3_column;                         -- �k�|�R��
    gt_upd_chain_pecul_area_head(ln_idx)               := it_edi_work.chain_peculiar_area_header;        -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
--  gt_upd_order_connection_num(ln_idx)                := NULL;                                          -- �󒍊֘A�ԍ�
    gt_upd_inv_indv_order_qty(ln_idx)                  := it_edi_work.invoice_indv_order_qty;            -- �i�`�[�v�j�������ʁi�o���j
    gt_upd_inv_case_order_qty(ln_idx)                  := it_edi_work.invoice_case_order_qty;            -- �i�`�[�v�j�������ʁi�P�[�X�j
    gt_upd_inv_ball_order_qty(ln_idx)                  := it_edi_work.invoice_ball_order_qty;            -- �i�`�[�v�j�������ʁi�{�[���j
    gt_upd_inv_sum_order_qty(ln_idx)                   := it_edi_work.invoice_sum_order_qty;             -- �i�`�[�v�j�������ʁi���v�A�o���j
    gt_upd_inv_indv_shipping_qty(ln_idx)               := it_edi_work.invoice_indv_shipping_qty;         -- �i�`�[�v�j�o�א��ʁi�o���j
    gt_upd_inv_case_shipping_qty(ln_idx)               := it_edi_work.invoice_case_shipping_qty;         -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
    gt_upd_inv_ball_shipping_qty(ln_idx)               := it_edi_work.invoice_ball_shipping_qty;         -- �i�`�[�v�j�o�א��ʁi�{�[���j
    gt_upd_inv_pallet_shipping_qty(ln_idx)             := it_edi_work.invoice_pallet_shipping_qty;       -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
    gt_upd_inv_sum_shipping_qty(ln_idx)                := it_edi_work.invoice_sum_shipping_qty;          -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
    gt_upd_inv_indv_stockout_qty(ln_idx)               := it_edi_work.invoice_indv_stockout_qty;         -- �i�`�[�v�j���i���ʁi�o���j
    gt_upd_inv_case_stockout_qty(ln_idx)               := it_edi_work.invoice_case_stockout_qty;         -- �i�`�[�v�j���i���ʁi�P�[�X�j
    gt_upd_inv_ball_stockout_qty(ln_idx)               := it_edi_work.invoice_ball_stockout_qty;         -- �i�`�[�v�j���i���ʁi�{�[���j
    gt_upd_inv_sum_stockout_qty(ln_idx)                := it_edi_work.invoice_sum_stockout_qty;          -- �i�`�[�v�j���i���ʁi���v�A�o���j
    gt_upd_inv_case_qty(ln_idx)                        := it_edi_work.invoice_case_qty;                  -- �i�`�[�v�j�P�[�X����
    gt_upd_inv_fold_container_qty(ln_idx)              := it_edi_work.invoice_fold_container_qty;        -- �i�`�[�v�j�I���R���i�o���j����
    gt_upd_inv_order_cost_amt(ln_idx)                  := it_edi_work.invoice_order_cost_amt;            -- �i�`�[�v�j�������z�i�����j
    gt_upd_inv_shipping_cost_amt(ln_idx)               := it_edi_work.invoice_shipping_cost_amt;         -- �i�`�[�v�j�������z�i�o�ׁj
    gt_upd_inv_stockout_cost_amt(ln_idx)               := it_edi_work.invoice_stockout_cost_amt;         -- �i�`�[�v�j�������z�i���i�j
    gt_upd_inv_order_price_amt(ln_idx)                 := it_edi_work.invoice_order_price_amt;           -- �i�`�[�v�j�������z�i�����j
    gt_upd_inv_shipping_price_amt(ln_idx)              := it_edi_work.invoice_shipping_price_amt;        -- �i�`�[�v�j�������z�i�o�ׁj
    gt_upd_inv_stockout_price_amt(ln_idx)              := it_edi_work.invoice_stockout_price_amt;        -- �i�`�[�v�j�������z�i���i�j
    gt_upd_total_indv_order_qty(ln_idx)                := it_edi_work.total_indv_order_qty;              -- �i�����v�j�������ʁi�o���j
    gt_upd_total_case_order_qty(ln_idx)                := it_edi_work.total_case_order_qty;              -- �i�����v�j�������ʁi�P�[�X�j
    gt_upd_total_ball_order_qty(ln_idx)                := it_edi_work.total_ball_order_qty;              -- �i�����v�j�������ʁi�{�[���j
    gt_upd_total_sum_order_qty(ln_idx)                 := it_edi_work.total_sum_order_qty;               -- �i�����v�j�������ʁi���v�A�o���j
    gt_upd_total_indv_ship_qty(ln_idx)                 := it_edi_work.total_indv_shipping_qty;           -- �i�����v�j�o�א��ʁi�o���j
    gt_upd_total_case_ship_qty(ln_idx)                 := it_edi_work.total_case_shipping_qty;           -- �i�����v�j�o�א��ʁi�P�[�X�j
    gt_upd_total_ball_ship_qty(ln_idx)                 := it_edi_work.total_ball_shipping_qty;           -- �i�����v�j�o�א��ʁi�{�[���j
    gt_upd_total_pallet_ship_qty(ln_idx)               := it_edi_work.total_pallet_shipping_qty;         -- �i�����v�j�o�א��ʁi�p���b�g�j
    gt_upd_total_sum_ship_qty(ln_idx)                  := it_edi_work.total_sum_shipping_qty;            -- �i�����v�j�o�א��ʁi���v�A�o���j
    gt_upd_total_indv_stockout_qty(ln_idx)             := it_edi_work.total_indv_stockout_qty;           -- �i�����v�j���i���ʁi�o���j
    gt_upd_total_case_stockout_qty(ln_idx)             := it_edi_work.total_case_stockout_qty;           -- �i�����v�j���i���ʁi�P�[�X�j
    gt_upd_total_ball_stockout_qty(ln_idx)             := it_edi_work.total_ball_stockout_qty;           -- �i�����v�j���i���ʁi�{�[���j
    gt_upd_total_sum_stockout_qty(ln_idx)              := it_edi_work.total_sum_stockout_qty;            -- �i�����v�j���i���ʁi���v�A�o���j
    gt_upd_total_case_qty(ln_idx)                      := it_edi_work.total_case_qty;                    -- �i�����v�j�P�[�X����
    gt_upd_total_fold_contain_qty(ln_idx)              := it_edi_work.total_fold_container_qty;          -- �i�����v�j�I���R���i�o���j����
    gt_upd_total_order_cost_amt(ln_idx)                := it_edi_work.total_order_cost_amt;              -- �i�����v�j�������z�i�����j
    gt_upd_total_shipping_cost_amt(ln_idx)             := it_edi_work.total_shipping_cost_amt;           -- �i�����v�j�������z�i�o�ׁj
    gt_upd_total_stockout_cost_amt(ln_idx)             := it_edi_work.total_stockout_cost_amt;           -- �i�����v�j�������z�i���i�j
    gt_upd_total_order_price_amt(ln_idx)               := it_edi_work.total_order_price_amt;             -- �i�����v�j�������z�i�����j
    gt_upd_total_ship_price_amt(ln_idx)                := it_edi_work.total_shipping_price_amt;          -- �i�����v�j�������z�i�o�ׁj
    gt_upd_total_stock_price_amt(ln_idx)               := it_edi_work.total_stockout_price_amt;          -- �i�����v�j�������z�i���i�j
    gt_upd_total_line_qty(ln_idx)                      := it_edi_work.total_line_qty;                    -- �g�[�^���s��
    gt_upd_total_invoice_qty(ln_idx)                   := it_edi_work.total_invoice_qty;                 -- �g�[�^���`�[����
    gt_upd_chain_pecul_area_foot(ln_idx)               := it_edi_work.chain_peculiar_area_footer;        -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
    gt_upd_conv_customer_code(ln_idx)                  := it_edi_work.conv_customer_code;                -- �ϊ���ڋq�R�[�h
--  gt_upd_order_forward_flag(ln_idx)                  := cv_order_forward_flag;                         -- �󒍘A�g�σt���O
--  gt_upd_creation_class(ln_idx)                      := cv_creation_class                              -- �쐬���敪
--  gt_upd_edi_delivery_sche_flag(ln_idx)              := cv_edi_delivery_flag;                          -- EDI�[�i�\�著�M�σt���O
-- 2009/12/28 M.Sano Ver.1.14 add Start
    gt_upd_tsukagatazaiko_div(ln_idx)                  := it_edi_work.tsukagatazaiko_div;                -- �ʉߍ݌Ɍ^�敪
-- 2009/12/28 M.Sano Ver.1.14 add End
    gt_upd_price_list_header_id(ln_idx)                := it_edi_work.price_list_header_id;              -- ���i�\�w�b�_ID
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_set_upd_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_edi_lines
   * Description      : EDI���׏��e�[�u���f�[�^���o(A-10)
   ***********************************************************************************/
  PROCEDURE proc_get_edi_lines(
    it_edi_work   IN  g_edi_work_rtype,      -- EDI�󒍏�񃏁[�N���R�[�h
    in_edi_header_info_id IN  NUMBER,        -- EDI�w�b�_���ID
    on_edi_line_info_id   OUT NOCOPY NUMBER, -- EDI���׏��ID
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_edi_lines'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- OUT�p�����[�^������
    on_edi_line_info_id   := NULL;
--
    --EDI���׏��f�[�^���o
    SELECT  line.edi_line_info_id
    INTO    on_edi_line_info_id
    FROM    xxcos_edi_lines             line
    WHERE   line.edi_header_info_id     = in_edi_header_info_id            -- EDI�w�b�_���ID
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    AND     line.line_no                = it_edi_work.line_no;             -- �s�ԍ�
    AND     line.order_connection_line_number = it_edi_work.order_connection_line_number; -- �󒍊֘A���הԍ�
-- 2010/01/19 Ver1.15 M.Sano Mod End
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** �Ώۃf�[�^�Ȃ���O�n���h�� ***
      NULL;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_get_edi_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_ins_lines
   * Description      : EDI���׏��e�[�u���C���T�[�g�p�ϐ��i�[(A-11)
   ***********************************************************************************/
  PROCEDURE proc_set_ins_lines(
    it_edi_work    IN  g_edi_work_rtype,     -- EDI�󒍏�񃏁[�N���R�[�h
    in_edi_head_id IN  NUMBER,               -- EDI�w�b�_���ID
    on_edi_line_id OUT NOCOPY NUMBER,        -- EDI���׏��ID
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_ins_lines'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx     NUMBER;
    ln_seq     NUMBER;
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
    -- OUT�p�����[�^������
    on_edi_line_id := NULL;
--
    ln_idx := gt_edi_lines.COUNT + 1;
--
    -- EDI���׏��ID���V�[�P���X����擾����
    BEGIN
      SELECT xxcos_edi_lines_s01.NEXTVAL
      INTO   ln_seq
      FROM   dual;
    END;
--
    -- �擾�����V�[�P���X��OUT�p�����[�^�ŕԂ�
    on_edi_line_id := ln_seq;
--
    gt_edi_lines(ln_idx).edi_line_info_id              := ln_seq;                                        -- EDI���׏��ID
    gt_edi_lines(ln_idx).edi_header_info_id            := in_edi_head_id;                                -- EDI�w�b�_���ID
    gt_edi_lines(ln_idx).line_no                       := it_edi_work.line_no;                           -- �s�m��
    gt_edi_lines(ln_idx).stockout_class                := it_edi_work.stockout_class;                    -- ���i�敪
    gt_edi_lines(ln_idx).stockout_reason               := it_edi_work.stockout_reason;                   -- ���i���R
    gt_edi_lines(ln_idx).product_code_itouen           := it_edi_work.product_code_itouen;               -- ���i�R�[�h�i�ɓ����j
    gt_edi_lines(ln_idx).product_code1                 := it_edi_work.product_code1;                     -- ���i�R�[�h�P
    gt_edi_lines(ln_idx).product_code2                 := it_edi_work.product_code2;                     -- ���i�R�[�h�Q
    gt_edi_lines(ln_idx).jan_code                      := it_edi_work.jan_code;                          -- �i�`�m�R�[�h
    gt_edi_lines(ln_idx).itf_code                      := it_edi_work.itf_code;                          -- �h�s�e�R�[�h
    gt_edi_lines(ln_idx).extension_itf_code            := it_edi_work.extension_itf_code;                -- �����h�s�e�R�[�h
    gt_edi_lines(ln_idx).case_product_code             := it_edi_work.case_product_code;                 -- �P�[�X���i�R�[�h
    gt_edi_lines(ln_idx).ball_product_code             := it_edi_work.ball_product_code;                 -- �{�[�����i�R�[�h
    gt_edi_lines(ln_idx).product_code_item_type        := it_edi_work.product_code_item_type;            -- ���i�R�[�h�i��
    gt_edi_lines(ln_idx).prod_class                    := it_edi_work.prod_class;                        -- ���i�敪
    gt_edi_lines(ln_idx).product_name                  := it_edi_work.product_name;                      -- ���i���i�����j
    gt_edi_lines(ln_idx).product_name1_alt             := it_edi_work.product_name1_alt;                 -- ���i���P�i�J�i�j
    gt_edi_lines(ln_idx).product_name2_alt             := it_edi_work.product_name2_alt;                 -- ���i���Q�i�J�i�j
    gt_edi_lines(ln_idx).item_standard1                := it_edi_work.item_standard1;                    -- �K�i�P
    gt_edi_lines(ln_idx).item_standard2                := it_edi_work.item_standard2;                    -- �K�i�Q
    gt_edi_lines(ln_idx).qty_in_case                   := it_edi_work.qty_in_case;                       -- ����
    gt_edi_lines(ln_idx).num_of_cases                  := it_edi_work.num_of_cases;                      -- �P�[�X����
    gt_edi_lines(ln_idx).num_of_ball                   := it_edi_work.num_of_ball;                       -- �{�[������
    gt_edi_lines(ln_idx).item_color                    := it_edi_work.item_color;                        -- �F
    gt_edi_lines(ln_idx).item_size                     := it_edi_work.item_size;                         -- �T�C�Y
    gt_edi_lines(ln_idx).expiration_date               := it_edi_work.expiration_date;                   -- �ܖ�������
    gt_edi_lines(ln_idx).product_date                  := it_edi_work.product_date;                      -- ������
    gt_edi_lines(ln_idx).order_uom_qty                 := it_edi_work.order_uom_qty;                     -- �����P�ʐ�
    gt_edi_lines(ln_idx).shipping_uom_qty              := it_edi_work.shipping_uom_qty;                  -- �o�גP�ʐ�
    gt_edi_lines(ln_idx).packing_uom_qty               := it_edi_work.packing_uom_qty;                   -- ����P�ʐ�
    gt_edi_lines(ln_idx).deal_code                     := it_edi_work.deal_code;                         -- ����
    gt_edi_lines(ln_idx).deal_class                    := it_edi_work.deal_class;                        -- �����敪
    gt_edi_lines(ln_idx).collation_code                := it_edi_work.collation_code;                    -- �ƍ�
    gt_edi_lines(ln_idx).uom_code                      := it_edi_work.uom_code;                          -- �P��
    gt_edi_lines(ln_idx).unit_price_class              := it_edi_work.unit_price_class;                  -- �P���敪
    gt_edi_lines(ln_idx).parent_packing_number         := it_edi_work.parent_packing_number;             -- �e����ԍ�
    gt_edi_lines(ln_idx).packing_number                := it_edi_work.packing_number;                    -- ����ԍ�
    gt_edi_lines(ln_idx).product_group_code            := it_edi_work.product_group_code;                -- ���i�Q�R�[�h
    gt_edi_lines(ln_idx).case_dismantle_flag           := it_edi_work.case_dismantle_flag;               -- �P�[�X��̕s�t���O
    gt_edi_lines(ln_idx).case_class                    := it_edi_work.case_class;                        -- �P�[�X�敪
    gt_edi_lines(ln_idx).indv_order_qty                := it_edi_work.indv_order_qty;                    -- �������ʁi�o���j
    gt_edi_lines(ln_idx).case_order_qty                := it_edi_work.case_order_qty;                    -- �������ʁi�P�[�X�j
    gt_edi_lines(ln_idx).ball_order_qty                := it_edi_work.ball_order_qty;                    -- �������ʁi�{�[���j
    gt_edi_lines(ln_idx).sum_order_qty                 := it_edi_work.sum_order_qty;                     -- �������ʁi���v�A�o���j
    gt_edi_lines(ln_idx).indv_shipping_qty             := it_edi_work.indv_shipping_qty;                 -- �o�א��ʁi�o���j
    gt_edi_lines(ln_idx).case_shipping_qty             := it_edi_work.case_shipping_qty;                 -- �o�א��ʁi�P�[�X�j
    gt_edi_lines(ln_idx).ball_shipping_qty             := it_edi_work.ball_shipping_qty;                 -- �o�א��ʁi�{�[���j
    gt_edi_lines(ln_idx).pallet_shipping_qty           := it_edi_work.pallet_shipping_qty;               -- �o�א��ʁi�p���b�g�j
    gt_edi_lines(ln_idx).sum_shipping_qty              := it_edi_work.sum_shipping_qty;                  -- �o�א��ʁi���v�A�o���j
    gt_edi_lines(ln_idx).indv_stockout_qty             := it_edi_work.indv_stockout_qty;                 -- ���i���ʁi�o���j
    gt_edi_lines(ln_idx).case_stockout_qty             := it_edi_work.case_stockout_qty;                 -- ���i���ʁi�P�[�X�j
    gt_edi_lines(ln_idx).ball_stockout_qty             := it_edi_work.ball_stockout_qty;                 -- ���i���ʁi�{�[���j
    gt_edi_lines(ln_idx).sum_stockout_qty              := it_edi_work.sum_stockout_qty;                  -- ���i���ʁi���v�A�o���j
    gt_edi_lines(ln_idx).case_qty                      := it_edi_work.case_qty;                          -- �P�[�X����
    gt_edi_lines(ln_idx).fold_container_indv_qty       := it_edi_work.fold_container_indv_qty;           -- �I���R���i�o���j����
    gt_edi_lines(ln_idx).order_unit_price              := it_edi_work.order_unit_price;                  -- ���P���i�����j
    gt_edi_lines(ln_idx).shipping_unit_price           := it_edi_work.shipping_unit_price;               -- ���P���i�o�ׁj
    gt_edi_lines(ln_idx).order_cost_amt                := it_edi_work.order_cost_amt;                    -- �������z�i�����j
    gt_edi_lines(ln_idx).shipping_cost_amt             := it_edi_work.shipping_cost_amt;                 -- �������z�i�o�ׁj
    gt_edi_lines(ln_idx).stockout_cost_amt             := it_edi_work.stockout_cost_amt;                 -- �������z�i���i�j
    gt_edi_lines(ln_idx).selling_price                 := it_edi_work.selling_price;                     -- ���P��
    gt_edi_lines(ln_idx).order_price_amt               := it_edi_work.order_price_amt;                   -- �������z�i�����j
    gt_edi_lines(ln_idx).shipping_price_amt            := it_edi_work.shipping_price_amt;                -- �������z�i�o�ׁj
    gt_edi_lines(ln_idx).stockout_price_amt            := it_edi_work.stockout_price_amt;                -- �������z�i���i�j
    gt_edi_lines(ln_idx).a_column_department           := it_edi_work.a_column_department;               -- �`���i�S�ݓX�j
    gt_edi_lines(ln_idx).d_column_department           := it_edi_work.d_column_department;               -- �c���i�S�ݓX�j
    gt_edi_lines(ln_idx).standard_info_depth           := it_edi_work.standard_info_depth;               -- �K�i���E���s��
    gt_edi_lines(ln_idx).standard_info_height          := it_edi_work.standard_info_height;              -- �K�i���E����
    gt_edi_lines(ln_idx).standard_info_width           := it_edi_work.standard_info_width;               -- �K�i���E��
    gt_edi_lines(ln_idx).standard_info_weight          := it_edi_work.standard_info_weight;              -- �K�i���E�d��
    gt_edi_lines(ln_idx).general_succeeded_item1       := it_edi_work.general_succeeded_item1;           -- �ėp���p�����ڂP
    gt_edi_lines(ln_idx).general_succeeded_item2       := it_edi_work.general_succeeded_item2;           -- �ėp���p�����ڂQ
    gt_edi_lines(ln_idx).general_succeeded_item3       := it_edi_work.general_succeeded_item3;           -- �ėp���p�����ڂR
    gt_edi_lines(ln_idx).general_succeeded_item4       := it_edi_work.general_succeeded_item4;           -- �ėp���p�����ڂS
    gt_edi_lines(ln_idx).general_succeeded_item5       := it_edi_work.general_succeeded_item5;           -- �ėp���p�����ڂT
    gt_edi_lines(ln_idx).general_succeeded_item6       := it_edi_work.general_succeeded_item6;           -- �ėp���p�����ڂU
    gt_edi_lines(ln_idx).general_succeeded_item7       := it_edi_work.general_succeeded_item7;           -- �ėp���p�����ڂV
    gt_edi_lines(ln_idx).general_succeeded_item8       := it_edi_work.general_succeeded_item8;           -- �ėp���p�����ڂW
    gt_edi_lines(ln_idx).general_succeeded_item9       := it_edi_work.general_succeeded_item9;           -- �ėp���p�����ڂX
    gt_edi_lines(ln_idx).general_succeeded_item10      := it_edi_work.general_succeeded_item10;          -- �ėp���p�����ڂP�O
    gt_edi_lines(ln_idx).general_add_item1             := it_edi_work.general_add_item1;                 -- �ėp�t�����ڂP
    gt_edi_lines(ln_idx).general_add_item2             := it_edi_work.general_add_item2;                 -- �ėp�t�����ڂQ
    gt_edi_lines(ln_idx).general_add_item3             := it_edi_work.general_add_item3;                 -- �ėp�t�����ڂR
    gt_edi_lines(ln_idx).general_add_item4             := it_edi_work.general_add_item4;                 -- �ėp�t�����ڂS
    gt_edi_lines(ln_idx).general_add_item5             := it_edi_work.general_add_item5;                 -- �ėp�t�����ڂT
    gt_edi_lines(ln_idx).general_add_item6             := it_edi_work.general_add_item6;                 -- �ėp�t�����ڂU
    gt_edi_lines(ln_idx).general_add_item7             := it_edi_work.general_add_item7;                 -- �ėp�t�����ڂV
    gt_edi_lines(ln_idx).general_add_item8             := it_edi_work.general_add_item8;                 -- �ėp�t�����ڂW
    gt_edi_lines(ln_idx).general_add_item9             := it_edi_work.general_add_item9;                 -- �ėp�t�����ڂX
    gt_edi_lines(ln_idx).general_add_item10            := it_edi_work.general_add_item10;                -- �ėp�t�����ڂP�O
    gt_edi_lines(ln_idx).chain_peculiar_area_line      := it_edi_work.chain_peculiar_area_line;          -- �`�F�[���X�ŗL�G���A�i���ׁj
    gt_edi_lines(ln_idx).item_code                     := it_edi_work.item_code;                         -- �i�ڃR�[�h
    gt_edi_lines(ln_idx).line_uom                      := it_edi_work.line_uom;                          -- ���גP��
    gt_edi_lines(ln_idx).hht_delivery_schedule_flag    := cv_hht_delivery_flag;                          -- HHT�[�i�\��A�g�σt���O
-- 2010/01/19 Ver.1.15 M.Sano add Start
--    gt_edi_lines(ln_idx).order_connection_line_number  := it_edi_work.line_no;                           -- �󒍊֘A���הԍ�
    gt_edi_lines(ln_idx).order_connection_line_number  := it_edi_work.order_connection_line_number;      -- �󒍊֘A���הԍ�
-- 2010/01/19 Ver.1.15 M.Sano add End
--****************************** 2009/05/08 1.4 T.Kitajima ADD START ******************************--
    gt_edi_lines(ln_idx).taking_unit_price             := it_edi_work.order_unit_price;                  -- �捞�����P���i�����j
--****************************** 2009/05/08 1.4 T.Kitajima ADD  END  ******************************--
    gt_edi_lines(ln_idx).created_by                    := cn_created_by;                                 -- �쐬��
    gt_edi_lines(ln_idx).creation_date                 := cd_creation_date;                              -- �쐬��
    gt_edi_lines(ln_idx).last_updated_by               := cn_last_updated_by;                            -- �ŏI�X�V��
    gt_edi_lines(ln_idx).last_update_date              := cd_last_update_date;                           -- �ŏI�X�V��
    gt_edi_lines(ln_idx).last_update_login             := cn_last_update_login;                          -- �ŏI�X�V���O�C��
    gt_edi_lines(ln_idx).request_id                    := cn_request_id;                                 -- �v��ID
    gt_edi_lines(ln_idx).program_application_id        := cn_program_application_id;                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    gt_edi_lines(ln_idx).program_id                    := cn_program_id;                                 -- �R���J�����g�E�v���O����ID
    gt_edi_lines(ln_idx).program_update_date           := cd_program_update_date;                        -- �v���O�����X�V��
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_set_ins_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_upd_lines
   * Description      : EDI���׏��e�[�u���A�b�v�f�[�g�p�ϐ��i�[(A-12)
   ***********************************************************************************/
  PROCEDURE proc_set_upd_lines(
    it_edi_work    IN g_edi_work_rtype,      -- EDI�󒍏�񃏁[�N���R�[�h
    in_edi_head_id IN NUMBER,                -- EDI�w�b�_���ID
    in_edi_line_id IN NUMBER,                -- EDI���׏��ID
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_upd_lines'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx     NUMBER;
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
    ln_idx := gt_upd_edi_line_info_id.COUNT + 1;
--
    gt_upd_edi_line_info_id(ln_idx)                    := in_edi_line_id;                                -- EDI���׏��ID
    gt_upd_edi_line_header_info_id(ln_idx)             := in_edi_head_id;                                -- EDI�w�b�_���ID
    gt_upd_line_no(ln_idx)                             := it_edi_work.line_no;                           -- �s�m��
    gt_upd_stockout_class(ln_idx)                      := it_edi_work.stockout_class;                    -- ���i�敪
    gt_upd_stockout_reason(ln_idx)                     := it_edi_work.stockout_reason;                   -- ���i���R
    gt_upd_product_code_itouen(ln_idx)                 := it_edi_work.product_code_itouen;               -- ���i�R�[�h�i�ɓ����j
    gt_upd_product_code1(ln_idx)                       := it_edi_work.product_code1;                     -- ���i�R�[�h�P
    gt_upd_product_code2(ln_idx)                       := it_edi_work.product_code2;                     -- ���i�R�[�h�Q
    gt_upd_jan_code(ln_idx)                            := it_edi_work.jan_code;                          -- �i�`�m�R�[�h
    gt_upd_itf_code(ln_idx)                            := it_edi_work.itf_code;                          -- �h�s�e�R�[�h
    gt_upd_extension_itf_code(ln_idx)                  := it_edi_work.extension_itf_code;                -- �����h�s�e�R�[�h
    gt_upd_case_product_code(ln_idx)                   := it_edi_work.case_product_code;                 -- �P�[�X���i�R�[�h
    gt_upd_ball_product_code(ln_idx)                   := it_edi_work.ball_product_code;                 -- �{�[�����i�R�[�h
    gt_upd_product_code_item_type(ln_idx)              := it_edi_work.product_code_item_type;            -- ���i�R�[�h�i��
    gt_upd_prod_class(ln_idx)                          := it_edi_work.prod_class;                        -- ���i�敪
    gt_upd_product_name(ln_idx)                        := it_edi_work.product_name;                      -- ���i���i�����j
    gt_upd_product_name1_alt(ln_idx)                   := it_edi_work.product_name1_alt;                 -- ���i���P�i�J�i�j
    gt_upd_product_name2_alt(ln_idx)                   := it_edi_work.product_name2_alt;                 -- ���i���Q�i�J�i�j
    gt_upd_item_standard1(ln_idx)                      := it_edi_work.item_standard1;                    -- �K�i�P
    gt_upd_item_standard2(ln_idx)                      := it_edi_work.item_standard2;                    -- �K�i�Q
    gt_upd_qty_in_case(ln_idx)                         := it_edi_work.qty_in_case;                       -- ����
    gt_upd_num_of_cases(ln_idx)                        := it_edi_work.num_of_cases;                      -- �P�[�X����
    gt_upd_num_of_ball(ln_idx)                         := it_edi_work.num_of_ball;                       -- �{�[������
    gt_upd_item_color(ln_idx)                          := it_edi_work.item_color;                        -- �F
    gt_upd_item_size(ln_idx)                           := it_edi_work.item_size;                         -- �T�C�Y
    gt_upd_expiration_date(ln_idx)                     := it_edi_work.expiration_date;                   -- �ܖ�������
    gt_upd_product_date(ln_idx)                        := it_edi_work.product_date;                      -- ������
    gt_upd_order_uom_qty(ln_idx)                       := it_edi_work.order_uom_qty;                     -- �����P�ʐ�
    gt_upd_shipping_uom_qty(ln_idx)                    := it_edi_work.shipping_uom_qty;                  -- �o�גP�ʐ�
    gt_upd_packing_uom_qty(ln_idx)                     := it_edi_work.packing_uom_qty;                   -- ����P�ʐ�
    gt_upd_deal_code(ln_idx)                           := it_edi_work.deal_code;                         -- ����
    gt_upd_deal_class(ln_idx)                          := it_edi_work.deal_class;                        -- �����敪
    gt_upd_collation_code(ln_idx)                      := it_edi_work.collation_code;                    -- �ƍ�
    gt_upd_uom_code(ln_idx)                            := it_edi_work.uom_code;                          -- �P��
    gt_upd_unit_price_class(ln_idx)                    := it_edi_work.unit_price_class;                  -- �P���敪
    gt_upd_parent_packing_number(ln_idx)               := it_edi_work.parent_packing_number;             -- �e����ԍ�
    gt_upd_packing_number(ln_idx)                      := it_edi_work.packing_number;                    -- ����ԍ�
    gt_upd_product_group_code(ln_idx)                  := it_edi_work.product_group_code;                -- ���i�Q�R�[�h
    gt_upd_case_dismantle_flag(ln_idx)                 := it_edi_work.case_dismantle_flag;               -- �P�[�X��̕s�t���O
    gt_upd_case_class(ln_idx)                          := it_edi_work.case_class;                        -- �P�[�X�敪
    gt_upd_indv_order_qty(ln_idx)                      := it_edi_work.indv_order_qty;                    -- �������ʁi�o���j
    gt_upd_case_order_qty(ln_idx)                      := it_edi_work.case_order_qty;                    -- �������ʁi�P�[�X�j
    gt_upd_ball_order_qty(ln_idx)                      := it_edi_work.ball_order_qty;                    -- �������ʁi�{�[���j
    gt_upd_sum_order_qty(ln_idx)                       := it_edi_work.sum_order_qty;                     -- �������ʁi���v�A�o���j
    gt_upd_indv_shipping_qty(ln_idx)                   := it_edi_work.indv_shipping_qty;                 -- �o�א��ʁi�o���j
    gt_upd_case_shipping_qty(ln_idx)                   := it_edi_work.case_shipping_qty;                 -- �o�א��ʁi�P�[�X�j
    gt_upd_ball_shipping_qty(ln_idx)                   := it_edi_work.ball_shipping_qty;                 -- �o�א��ʁi�{�[���j
    gt_upd_pallet_shipping_qty(ln_idx)                 := it_edi_work.pallet_shipping_qty;               -- �o�א��ʁi�p���b�g�j
    gt_upd_sum_shipping_qty(ln_idx)                    := it_edi_work.sum_shipping_qty;                  -- �o�א��ʁi���v�A�o���j
    gt_upd_indv_stockout_qty(ln_idx)                   := it_edi_work.indv_stockout_qty;                 -- ���i���ʁi�o���j
    gt_upd_case_stockout_qty(ln_idx)                   := it_edi_work.case_stockout_qty;                 -- ���i���ʁi�P�[�X�j
    gt_upd_ball_stockout_qty(ln_idx)                   := it_edi_work.ball_stockout_qty;                 -- ���i���ʁi�{�[���j
    gt_upd_sum_stockout_qty(ln_idx)                    := it_edi_work.sum_stockout_qty;                  -- ���i���ʁi���v�A�o���j
    gt_upd_case_qty(ln_idx)                            := it_edi_work.case_qty;                          -- �P�[�X����
    gt_upd_fold_container_indv_qty(ln_idx)             := it_edi_work.fold_container_indv_qty;           -- �I���R���i�o���j����
    gt_upd_order_unit_price(ln_idx)                    := it_edi_work.order_unit_price;                  -- ���P���i�����j
    gt_upd_shipping_unit_price(ln_idx)                 := it_edi_work.shipping_unit_price;               -- ���P���i�o�ׁj
    gt_upd_order_cost_amt(ln_idx)                      := it_edi_work.order_cost_amt;                    -- �������z�i�����j
    gt_upd_shipping_cost_amt(ln_idx)                   := it_edi_work.shipping_cost_amt;                 -- �������z�i�o�ׁj
    gt_upd_stockout_cost_amt(ln_idx)                   := it_edi_work.stockout_cost_amt;                 -- �������z�i���i�j
    gt_upd_selling_price(ln_idx)                       := it_edi_work.selling_price;                     -- ���P��
    gt_upd_order_price_amt(ln_idx)                     := it_edi_work.order_price_amt;                   -- �������z�i�����j
    gt_upd_shipping_price_amt(ln_idx)                  := it_edi_work.shipping_price_amt;                -- �������z�i�o�ׁj
    gt_upd_stockout_price_amt(ln_idx)                  := it_edi_work.stockout_price_amt;                -- �������z�i���i�j
    gt_upd_a_column_department(ln_idx)                 := it_edi_work.a_column_department;               -- �`���i�S�ݓX�j
    gt_upd_d_column_department(ln_idx)                 := it_edi_work.d_column_department;               -- �c���i�S�ݓX�j
    gt_upd_standard_info_depth(ln_idx)                 := it_edi_work.standard_info_depth;               -- �K�i���E���s��
    gt_upd_standard_info_height(ln_idx)                := it_edi_work.standard_info_height;              -- �K�i���E����
    gt_upd_standard_info_width(ln_idx)                 := it_edi_work.standard_info_width;               -- �K�i���E��
    gt_upd_standard_info_weight(ln_idx)                := it_edi_work.standard_info_weight;              -- �K�i���E�d��
    gt_upd_general_succeed_item1(ln_idx)               := it_edi_work.general_succeeded_item1;           -- �ėp���p�����ڂP
    gt_upd_general_succeed_item2(ln_idx)               := it_edi_work.general_succeeded_item2;           -- �ėp���p�����ڂQ
    gt_upd_general_succeed_item3(ln_idx)               := it_edi_work.general_succeeded_item3;           -- �ėp���p�����ڂR
    gt_upd_general_succeed_item4(ln_idx)               := it_edi_work.general_succeeded_item4;           -- �ėp���p�����ڂS
    gt_upd_general_succeed_item5(ln_idx)               := it_edi_work.general_succeeded_item5;           -- �ėp���p�����ڂT
    gt_upd_general_succeed_item6(ln_idx)               := it_edi_work.general_succeeded_item6;           -- �ėp���p�����ڂU
    gt_upd_general_succeed_item7(ln_idx)               := it_edi_work.general_succeeded_item7;           -- �ėp���p�����ڂV
    gt_upd_general_succeed_item8(ln_idx)               := it_edi_work.general_succeeded_item8;           -- �ėp���p�����ڂW
    gt_upd_general_succeed_item9(ln_idx)               := it_edi_work.general_succeeded_item9;           -- �ėp���p�����ڂX
    gt_upd_general_succeed_item10(ln_idx)              := it_edi_work.general_succeeded_item10;          -- �ėp���p�����ڂP�O
    gt_upd_general_add_item1(ln_idx)                   := it_edi_work.general_add_item1;                 -- �ėp�t�����ڂP
    gt_upd_general_add_item2(ln_idx)                   := it_edi_work.general_add_item2;                 -- �ėp�t�����ڂQ
    gt_upd_general_add_item3(ln_idx)                   := it_edi_work.general_add_item3;                 -- �ėp�t�����ڂR
    gt_upd_general_add_item4(ln_idx)                   := it_edi_work.general_add_item4;                 -- �ėp�t�����ڂS
    gt_upd_general_add_item5(ln_idx)                   := it_edi_work.general_add_item5;                 -- �ėp�t�����ڂT
    gt_upd_general_add_item6(ln_idx)                   := it_edi_work.general_add_item6;                 -- �ėp�t�����ڂU
    gt_upd_general_add_item7(ln_idx)                   := it_edi_work.general_add_item7;                 -- �ėp�t�����ڂV
    gt_upd_general_add_item8(ln_idx)                   := it_edi_work.general_add_item8;                 -- �ėp�t�����ڂW
    gt_upd_general_add_item9(ln_idx)                   := it_edi_work.general_add_item9;                 -- �ėp�t�����ڂX
    gt_upd_general_add_item10(ln_idx)                  := it_edi_work.general_add_item10;                -- �ėp�t�����ڂP�O
    gt_upd_chain_pecul_area_line(ln_idx)               := it_edi_work.chain_peculiar_area_line;          -- �`�F�[���X�ŗL�G���A�i���ׁj
    gt_upd_item_code(ln_idx)                           := it_edi_work.item_code;                         -- �i�ڃR�[�h
    gt_upd_line_uom(ln_idx)                            := it_edi_work.line_uom;                          -- ���גP��
    gt_upd_hht_delivery_sche_flag(ln_idx)              := cv_hht_delivery_flag;                          -- HHT�[�i�\��A�g�σt���O
-- 2010/01/19 Ver.1.15 M.Sano add Start
--    gt_upd_order_connect_line_num(ln_idx)              := it_edi_work.line_no;                           -- �󒍊֘A���הԍ�
    gt_upd_order_connect_line_num(ln_idx)              := it_edi_work.order_connection_line_number;      -- �󒍊֘A���הԍ�
-- 2010/01/19 Ver.1.15 M.Sano add End
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_set_upd_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_calc_inv_total
   * Description      : �`�[���̍��v�l���Z�o(A-13)
   ***********************************************************************************/
  PROCEDURE proc_calc_inv_total(
    it_edi_work   IN  g_edi_work_rtype,      -- EDI�󒍏�񃏁[�N���R�[�h
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_calc_inv_total'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �e���v�l�ɉ��Z
    gt_inv_total.indv_order_qty := gt_inv_total.indv_order_qty + NVL( it_edi_work.indv_order_qty, 0 );   -- �������ʁi�o���j
    gt_inv_total.case_order_qty := gt_inv_total.case_order_qty + NVL( it_edi_work.case_order_qty, 0 );   -- �������ʁi�P�[�X�j
    gt_inv_total.ball_order_qty := gt_inv_total.ball_order_qty + NVL( it_edi_work.ball_order_qty, 0 );   -- �������ʁi�{�[���j
    gt_inv_total.sum_order_qty  := gt_inv_total.sum_order_qty  + NVL( it_edi_work.sum_order_qty, 0 );    -- �������ʁi���v�A�o���j
    gt_inv_total.order_cost_amt := gt_inv_total.order_cost_amt + NVL( it_edi_work.order_cost_amt, 0 );   -- �������z�i�����j
-- *************************** 2009/07/24 1.8 N.Maeda ADD START ********************************** --
    gt_inv_total.shipping_cost_amt := gt_inv_total.shipping_cost_amt + NVL( it_edi_work.shipping_cost_amt , 0 ); -- �������z�i�o�ׁj
    gt_inv_total.stockout_cost_amt := gt_inv_total.stockout_cost_amt + NVL( it_edi_work.stockout_cost_amt , 0 ); -- �������z�i���i�j
-- *************************** 2009/07/24 1.8 N.Maeda ADD  END  ********************************** --
    
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_calc_inv_total;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_set_inv_total
   * Description      : EDI�w�b�_���p�ϐ��ɓ`�[�v��ݒ�(A-14)
   ***********************************************************************************/
  PROCEDURE proc_set_inv_total(
    in_edi_head_ins_flag IN NUMBER,          -- EDI�w�b�_���C���T�[�g�t���O
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_inv_total'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx     NUMBER;
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
    -- EDI�w�b�_��񂪃C���T�[�g�̏ꍇ
    IF ( in_edi_head_ins_flag = 1 ) THEN
      -- EDI�w�b�_���C���T�[�g�ϐ��ɔ������ʍ��v�l��ݒ�
      ln_idx := gt_edi_headers.COUNT;
      gt_edi_headers(ln_idx).invoice_indv_order_qty    := gt_inv_total.indv_order_qty;         -- �������ʁi�o���j
      gt_edi_headers(ln_idx).invoice_case_order_qty    := gt_inv_total.case_order_qty;         -- �������ʁi�P�[�X�j
      gt_edi_headers(ln_idx).invoice_ball_order_qty    := gt_inv_total.ball_order_qty;         -- �������ʁi�{�[���j
      gt_edi_headers(ln_idx).invoice_sum_order_qty     := gt_inv_total.sum_order_qty;          -- �������ʁi���v�A�o���j
      gt_edi_headers(ln_idx).invoice_order_cost_amt    := gt_inv_total.order_cost_amt;         -- �������z�i�����j
-- *************************** 2009/07/24 1.8 N.Maeda ADD START ********************************** --
      gt_edi_headers(ln_idx).invoice_shipping_cost_amt := gt_inv_total.shipping_cost_amt;      -- �������z�i�o�ׁj
      gt_edi_headers(ln_idx).invoice_stockout_cost_amt := gt_inv_total.stockout_cost_amt;      -- �������z�i���i�j
-- *************************** 2009/07/24 1.8 N.Maeda ADD  END  ********************************** --
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_set_inv_total;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_edi_headers
   * Description      : EDI�w�b�_���e�[�u���f�[�^�ǉ�(A-15)
   ***********************************************************************************/
  PROCEDURE proc_ins_edi_headers(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_edi_headers'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx     INTEGER;
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
    -- EDI�w�b�_���f�[�^�ǉ�����
    FORALL ln_idx IN 1..gt_edi_headers.COUNT
      INSERT INTO xxcos_edi_headers
        VALUES gt_edi_headers(ln_idx);
--
  EXCEPTION
    -- *** �L�[�d����O�n���h�� ***
    WHEN DUP_VAL_ON_INDEX THEN
      -- �f�[�^�o�^�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_insert, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �f�[�^�o�^�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_insert, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_ins_edi_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_edi_headers
   * Description      : EDI�w�b�_���e�[�u���f�[�^�X�V(A-16)
   ***********************************************************************************/
  PROCEDURE proc_upd_edi_headers(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_edi_headers'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx     INTEGER;
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
    -- EDI�w�b�_���f�[�^�X�V����
    FORALL ln_idx IN 1..gt_upd_edi_header_info_id.COUNT
      UPDATE  xxcos_edi_headers
      SET     medium_class                        = gt_upd_medium_class(ln_idx),               -- �}�̋敪
              data_type_code                      = gt_upd_data_type_code(ln_idx),             -- �f�[�^��R�[�h
              file_no                             = gt_upd_file_no(ln_idx),                    -- �t�@�C���m��
              info_class                          = gt_upd_info_class(ln_idx),                 -- ���敪
              process_date                        = gt_upd_process_date(ln_idx),               -- ������
              process_time                        = gt_upd_process_time(ln_idx),               -- ��������
              base_code                           = gt_upd_base_code(ln_idx),                  -- ���_�i����j�R�[�h
              base_name                           = gt_upd_base_name(ln_idx),                  -- ���_���i�������j
              base_name_alt                       = gt_upd_base_name_alt(ln_idx),              -- ���_���i�J�i�j
              edi_chain_code                      = gt_upd_edi_chain_code(ln_idx),             -- �d�c�h�`�F�[���X�R�[�h
              edi_chain_name                      = gt_upd_edi_chain_name(ln_idx),             -- �d�c�h�`�F�[���X���i�����j
              edi_chain_name_alt                  = gt_upd_edi_chain_name_alt(ln_idx),         -- �d�c�h�`�F�[���X���i�J�i�j
              chain_code                          = gt_upd_chain_code(ln_idx),                 -- �`�F�[���X�R�[�h
              chain_name                          = gt_upd_chain_name(ln_idx),                 -- �`�F�[���X���i�����j
              chain_name_alt                      = gt_upd_chain_name_alt(ln_idx),             -- �`�F�[���X���i�J�i�j
              report_code                         = gt_upd_report_code(ln_idx),                -- ���[�R�[�h
              report_show_name                    = gt_upd_report_show_name(ln_idx),           -- ���[�\����
              customer_code                       = gt_upd_customer_code(ln_idx),              -- �ڋq�R�[�h
              customer_name                       = gt_upd_customer_name(ln_idx),              -- �ڋq���i�����j
              customer_name_alt                   = gt_upd_customer_name_alt(ln_idx),          -- �ڋq���i�J�i�j
              company_code                        = gt_upd_company_code(ln_idx),               -- �ЃR�[�h
              company_name                        = gt_upd_company_name(ln_idx),               -- �Ж��i�����j
              company_name_alt                    = gt_upd_company_name_alt(ln_idx),           -- �Ж��i�J�i�j
              shop_code                           = gt_upd_shop_code(ln_idx),                  -- �X�R�[�h
              shop_name                           = gt_upd_shop_name(ln_idx),                  -- �X���i�����j
              shop_name_alt                       = gt_upd_shop_name_alt(ln_idx),              -- �X���i�J�i�j
              delivery_center_code                = gt_upd_delivery_cent_cd(ln_idx),           -- �[���Z���^�[�R�[�h
              delivery_center_name                = gt_upd_delivery_cent_nm(ln_idx),           -- �[���Z���^�[���i�����j
              delivery_center_name_alt            = gt_upd_delivery_cent_nm_alt(ln_idx),       -- �[���Z���^�[���i�J�i�j
              order_date                          = gt_upd_order_date(ln_idx),                 -- ������
              center_delivery_date                = gt_upd_center_delivery_date(ln_idx),       -- �Z���^�[�[�i��
              result_delivery_date                = gt_upd_result_delivery_date(ln_idx),       -- ���[�i��
              shop_delivery_date                  = gt_upd_shop_delivery_date(ln_idx),         -- �X�ܔ[�i��
              data_creation_date_edi_data         = gt_upd_data_creation_date_edi(ln_idx),     -- �f�[�^�쐬���i�d�c�h�f�[�^���j
              data_creation_time_edi_data         = gt_upd_data_creation_time_edi(ln_idx),     -- �f�[�^�쐬�����i�d�c�h�f�[�^���j
              invoice_class                       = gt_upd_invoice_class(ln_idx),              -- �`�[�敪
              small_classification_code           = gt_upd_small_class_cd(ln_idx),             -- �����ރR�[�h
              small_classification_name           = gt_upd_small_class_nm(ln_idx),             -- �����ޖ�
              middle_classification_code          = gt_upd_middle_class_cd(ln_idx),            -- �����ރR�[�h
              middle_classification_name          = gt_upd_middle_class_nm(ln_idx),            -- �����ޖ�
              big_classification_code             = gt_upd_big_class_cd(ln_idx),               -- �啪�ރR�[�h
              big_classification_name             = gt_upd_big_class_nm(ln_idx),               -- �啪�ޖ�
              other_party_department_code         = gt_upd_other_party_depart_cd(ln_idx),      -- ����敔��R�[�h
              other_party_order_number            = gt_upd_other_party_order_num(ln_idx),      -- ����攭���ԍ�
              check_digit_class                   = gt_upd_check_digit_class(ln_idx),          -- �`�F�b�N�f�W�b�g�L���敪
              invoice_number                      = gt_upd_invoice_number(ln_idx),             -- �`�[�ԍ�
              check_digit                         = gt_upd_check_digit(ln_idx),                -- �`�F�b�N�f�W�b�g
              close_date                          = gt_upd_close_date(ln_idx),                 -- ����
              order_no_ebs                        = gt_upd_order_no_ebs(ln_idx),               -- �󒍂m���i�d�a�r�j
              ar_sale_class                       = gt_upd_ar_sale_class(ln_idx),              -- �����敪
              delivery_classe                     = gt_upd_delivery_classe(ln_idx),            -- �z���敪
              opportunity_no                      = gt_upd_opportunity_no(ln_idx),             -- �ւm��
              contact_to                          = gt_upd_contact_to(ln_idx),                 -- �A����
              route_sales                         = gt_upd_route_sales(ln_idx),                -- ���[�g�Z�[���X
              corporate_code                      = gt_upd_corporate_code(ln_idx),             -- �@�l�R�[�h
              maker_name                          = gt_upd_maker_name(ln_idx),                 -- ���[�J�[��
              area_code                           = gt_upd_area_code(ln_idx),                  -- �n��R�[�h
              area_name                           = gt_upd_area_name(ln_idx),                  -- �n�於�i�����j
              area_name_alt                       = gt_upd_area_name_alt(ln_idx),              -- �n�於�i�J�i�j
              vendor_code                         = gt_upd_vendor_code(ln_idx),                -- �����R�[�h
              vendor_name                         = gt_upd_vendor_name(ln_idx),                -- ����於�i�����j
              vendor_name1_alt                    = gt_upd_vendor_name1_alt(ln_idx),           -- ����於�P�i�J�i�j
              vendor_name2_alt                    = gt_upd_vendor_name2_alt(ln_idx),           -- ����於�Q�i�J�i�j
              vendor_tel                          = gt_upd_vendor_tel(ln_idx),                 -- �����s�d�k
              vendor_charge                       = gt_upd_vendor_charge(ln_idx),              -- �����S����
              vendor_address                      = gt_upd_vendor_address(ln_idx),             -- �����Z���i�����j
              deliver_to_code_itouen              = gt_upd_deliver_to_code_itouen(ln_idx),     -- �͂���R�[�h�i�ɓ����j
              deliver_to_code_chain               = gt_upd_deliver_to_code_chain(ln_idx),      -- �͂���R�[�h�i�`�F�[���X�j
              deliver_to                          = gt_upd_deliver_to(ln_idx),                 -- �͂���i�����j
              deliver_to1_alt                     = gt_upd_deliver_to1_alt(ln_idx),            -- �͂���P�i�J�i�j
              deliver_to2_alt                     = gt_upd_deliver_to2_alt(ln_idx),            -- �͂���Q�i�J�i�j
              deliver_to_address                  = gt_upd_deliver_to_address(ln_idx),         -- �͂���Z���i�����j
              deliver_to_address_alt              = gt_upd_deliver_to_address_alt(ln_idx),     -- �͂���Z���i�J�i�j
              deliver_to_tel                      = gt_upd_deliver_to_tel(ln_idx),             -- �͂���s�d�k
              balance_accounts_code               = gt_upd_balance_acct_cd(ln_idx),            -- ������R�[�h
              balance_accounts_company_code       = gt_upd_balance_acct_company_cd(ln_idx),    -- ������ЃR�[�h
              balance_accounts_shop_code          = gt_upd_balance_acct_shop_cd(ln_idx),       -- ������X�R�[�h
              balance_accounts_name               = gt_upd_balance_acct_nm(ln_idx),            -- �����於�i�����j
              balance_accounts_name_alt           = gt_upd_balance_acct_nm_alt(ln_idx),        -- �����於�i�J�i�j
              balance_accounts_address            = gt_upd_balance_acct_addr(ln_idx),          -- ������Z���i�����j
              balance_accounts_address_alt        = gt_upd_balance_acct_addr_alt(ln_idx),      -- ������Z���i�J�i�j
              balance_accounts_tel                = gt_upd_balance_acct_tel(ln_idx),           -- ������s�d�k
              order_possible_date                 = gt_upd_order_possible_date(ln_idx),        -- �󒍉\��
              permission_possible_date            = gt_upd_permit_possible_date(ln_idx),       -- ���e�\��
              forward_month                       = gt_upd_forward_month(ln_idx),              -- ����N����
              payment_settlement_date             = gt_upd_payment_settlement_date(ln_idx),    -- �x�����ϓ�
              handbill_start_date_active          = gt_upd_handbill_start_date_act(ln_idx),    -- �`���V�J�n��
              billing_due_date                    = gt_upd_billing_due_date(ln_idx),           -- ��������
              shipping_time                       = gt_upd_shipping_time(ln_idx),              -- �o�׎���
              delivery_schedule_time              = gt_upd_delivery_schedule_time(ln_idx),     -- �[�i�\�莞��
              order_time                          = gt_upd_order_time(ln_idx),                 -- ��������
              general_date_item1                  = gt_upd_general_date_item1(ln_idx),         -- �ėp���t���ڂP
              general_date_item2                  = gt_upd_general_date_item2(ln_idx),         -- �ėp���t���ڂQ
              general_date_item3                  = gt_upd_general_date_item3(ln_idx),         -- �ėp���t���ڂR
              general_date_item4                  = gt_upd_general_date_item4(ln_idx),         -- �ėp���t���ڂS
              general_date_item5                  = gt_upd_general_date_item5(ln_idx),         -- �ėp���t���ڂT
              arrival_shipping_class              = gt_upd_arrival_shipping_class(ln_idx),     -- ���o�׋敪
              vendor_class                        = gt_upd_vendor_class(ln_idx),               -- �����敪
              invoice_detailed_class              = gt_upd_invoice_detailed_class(ln_idx),     -- �`�[����敪
              unit_price_use_class                = gt_upd_unit_price_use_class(ln_idx),       -- �P���g�p�敪
              sub_distribution_center_code        = gt_upd_sub_dist_center_cd(ln_idx),         -- �T�u�����Z���^�[�R�[�h
              sub_distribution_center_name        = gt_upd_sub_dist_center_nm(ln_idx),         -- �T�u�����Z���^�[�R�[�h��
              center_delivery_method              = gt_upd_center_delivery_method(ln_idx),     -- �Z���^�[�[�i���@
              center_use_class                    = gt_upd_center_use_class(ln_idx),           -- �Z���^�[���p�敪
              center_whse_class                   = gt_upd_center_whse_class(ln_idx),          -- �Z���^�[�q�ɋ敪
              center_area_class                   = gt_upd_center_area_class(ln_idx),          -- �Z���^�[�n��敪
              center_arrival_class                = gt_upd_center_arrival_class(ln_idx),       -- �Z���^�[���׋敪
              depot_class                         = gt_upd_depot_class(ln_idx),                -- �f�|�敪
              tcdc_class                          = gt_upd_tcdc_class(ln_idx),                 -- �s�b�c�b�敪
              upc_flag                            = gt_upd_upc_flag(ln_idx),                   -- �t�o�b�t���O
              simultaneously_class                = gt_upd_simultaneously_class(ln_idx),       -- ��ċ敪
              business_id                         = gt_upd_business_id(ln_idx),                -- �Ɩ��h�c
              whse_directly_class                 = gt_upd_whse_directly_class(ln_idx),        -- �q���敪
              premium_rebate_class                = gt_upd_premium_rebate_class(ln_idx),       -- �i�i���ߋ敪
              item_type                           = gt_upd_item_type(ln_idx),                  -- ���ڎ��
              cloth_house_food_class              = gt_upd_cloth_house_food_class(ln_idx),     -- �߉ƐH�敪
              mix_class                           = gt_upd_mix_class(ln_idx),                  -- ���݋敪
              stk_class                           = gt_upd_stk_class(ln_idx),                  -- �݌ɋ敪
              last_modify_site_class              = gt_upd_last_modify_site_class(ln_idx),     -- �ŏI�C���ꏊ�敪
              report_class                        = gt_upd_report_class(ln_idx),               -- ���[�敪
              addition_plan_class                 = gt_upd_addition_plan_class(ln_idx),        -- �ǉ��E�v��敪
              registration_class                  = gt_upd_registration_class(ln_idx),         -- �o�^�敪
              specific_class                      = gt_upd_specific_class(ln_idx),             -- ����敪
              dealings_class                      = gt_upd_dealings_class(ln_idx),             -- ����敪
              order_class                         = gt_upd_order_class(ln_idx),                -- �����敪
              sum_line_class                      = gt_upd_sum_line_class(ln_idx),             -- �W�v���׋敪
              shipping_guidance_class             = gt_upd_shipping_guidance_class(ln_idx),    -- �o�׈ē��ȊO�敪
              shipping_class                      = gt_upd_shipping_class(ln_idx),             -- �o�׋敪
              product_code_use_class              = gt_upd_product_code_use_class(ln_idx),     -- ���i�R�[�h�g�p�敪
              cargo_item_class                    = gt_upd_cargo_item_class(ln_idx),           -- �ϑ��i�敪
              ta_class                            = gt_upd_ta_class(ln_idx),                   -- �s�^�`�敪
              plan_code                           = gt_upd_plan_code(ln_idx),                  -- ���R�[�h
              category_code                       = gt_upd_category_code(ln_idx),              -- �J�e�S���[�R�[�h
              category_class                      = gt_upd_category_class(ln_idx),             -- �J�e�S���[�敪
              carrier_means                       = gt_upd_carrier_means(ln_idx),              -- �^����i
              counter_code                        = gt_upd_counter_code(ln_idx),               -- ����R�[�h
              move_sign                           = gt_upd_move_sign(ln_idx),                  -- �ړ��T�C��
              eos_handwriting_class               = gt_upd_eos_handwriting_class(ln_idx),      -- �d�n�r�E�菑�敪
              delivery_to_section_code            = gt_upd_delivery_to_sect_cd(ln_idx),        -- �[�i��ۃR�[�h
              invoice_detailed                    = gt_upd_invoice_detailed(ln_idx),           -- �`�[����
              attach_qty                          = gt_upd_attach_qty(ln_idx),                 -- �Y�t��
              other_party_floor                   = gt_upd_other_party_floor(ln_idx),          -- �t���A
              text_no                             = gt_upd_text_no(ln_idx),                    -- �s�d�w�s�m��
              in_store_code                       = gt_upd_in_store_code(ln_idx),              -- �C���X�g�A�R�[�h
              tag_data                            = gt_upd_tag_data(ln_idx),                   -- �^�O
              competition_code                    = gt_upd_competition_code(ln_idx),           -- ����
              billing_chair                       = gt_upd_billing_chair(ln_idx),              -- ��������
              chain_store_code                    = gt_upd_chain_store_code(ln_idx),           -- �`�F�[���X�g�A�[�R�[�h
              chain_store_short_name              = gt_upd_chain_store_short_name(ln_idx),     -- �`�F�[���X�g�A�[�R�[�h��������
              direct_delivery_rcpt_fee            = gt_upd_dirct_delivery_rcpt_fee(ln_idx),    -- ���z���^���旿
              bill_info                           = gt_upd_bill_info(ln_idx),                  -- ��`���
              description                         = gt_upd_description(ln_idx),                -- �E�v
              interior_code                       = gt_upd_interior_code(ln_idx),              -- �����R�[�h
              order_info_delivery_category        = gt_upd_order_info_delivery_cat(ln_idx),    -- �������@�[�i�J�e�S���[
              purchase_type                       = gt_upd_purchase_type(ln_idx),              -- �d���`��
              delivery_to_name_alt                = gt_upd_delivery_to_name_alt(ln_idx),       -- �[�i�ꏊ���i�J�i�j
              shop_opened_site                    = gt_upd_shop_opened_site(ln_idx),           -- �X�o�ꏊ
              counter_name                        = gt_upd_counter_name(ln_idx),               -- ���ꖼ
              extension_number                    = gt_upd_extension_number(ln_idx),           -- �����ԍ�
              charge_name                         = gt_upd_charge_name(ln_idx),                -- �S���Җ�
              price_tag                           = gt_upd_price_tag(ln_idx),                  -- �l�D
              tax_type                            = gt_upd_tax_type(ln_idx),                   -- �Ŏ�
              consumption_tax_class               = gt_upd_consumption_tax_class(ln_idx),      -- ����ŋ敪
              brand_class                         = gt_upd_brand_class(ln_idx),                -- �a�q
              id_code                             = gt_upd_id_code(ln_idx),                    -- �h�c�R�[�h
              department_code                     = gt_upd_department_code(ln_idx),            -- �S�ݓX�R�[�h
              department_name                     = gt_upd_department_name(ln_idx),            -- �S�ݓX��
              item_type_number                    = gt_upd_item_type_number(ln_idx),           -- �i�ʔԍ�
              description_department              = gt_upd_description_department(ln_idx),     -- �E�v�i�S�ݓX�j
              price_tag_method                    = gt_upd_price_tag_method(ln_idx),           -- �l�D���@
              reason_column                       = gt_upd_reason_column(ln_idx),              -- ���R��
              a_column_header                     = gt_upd_a_column_header(ln_idx),            -- �`���w�b�_
              d_column_header                     = gt_upd_d_column_header(ln_idx),            -- �c���w�b�_
              brand_code                          = gt_upd_brand_code(ln_idx),                 -- �u�����h�R�[�h
              line_code                           = gt_upd_line_code(ln_idx),                  -- ���C���R�[�h
              class_code                          = gt_upd_class_code(ln_idx),                 -- �N���X�R�[�h
              a1_column                           = gt_upd_a1_column(ln_idx),                  -- �`�|�P��
              b1_column                           = gt_upd_b1_column(ln_idx),                  -- �a�|�P��
              c1_column                           = gt_upd_c1_column(ln_idx),                  -- �b�|�P��
              d1_column                           = gt_upd_d1_column(ln_idx),                  -- �c�|�P��
              e1_column                           = gt_upd_e1_column(ln_idx),                  -- �d�|�P��
              a2_column                           = gt_upd_a2_column(ln_idx),                  -- �`�|�Q��
              b2_column                           = gt_upd_b2_column(ln_idx),                  -- �a�|�Q��
              c2_column                           = gt_upd_c2_column(ln_idx),                  -- �b�|�Q��
              d2_column                           = gt_upd_d2_column(ln_idx),                  -- �c�|�Q��
              e2_column                           = gt_upd_e2_column(ln_idx),                  -- �d�|�Q��
              a3_column                           = gt_upd_a3_column(ln_idx),                  -- �`�|�R��
              b3_column                           = gt_upd_b3_column(ln_idx),                  -- �a�|�R��
              c3_column                           = gt_upd_c3_column(ln_idx),                  -- �b�|�R��
              d3_column                           = gt_upd_d3_column(ln_idx),                  -- �c�|�R��
              e3_column                           = gt_upd_e3_column(ln_idx),                  -- �d�|�R��
              f1_column                           = gt_upd_f1_column(ln_idx),                  -- �e�|�P��
              g1_column                           = gt_upd_g1_column(ln_idx),                  -- �f�|�P��
              h1_column                           = gt_upd_h1_column(ln_idx),                  -- �g�|�P��
              i1_column                           = gt_upd_i1_column(ln_idx),                  -- �h�|�P��
              j1_column                           = gt_upd_j1_column(ln_idx),                  -- �i�|�P��
              k1_column                           = gt_upd_k1_column(ln_idx),                  -- �j�|�P��
              l1_column                           = gt_upd_l1_column(ln_idx),                  -- �k�|�P��
              f2_column                           = gt_upd_f2_column(ln_idx),                  -- �e�|�Q��
              g2_column                           = gt_upd_g2_column(ln_idx),                  -- �f�|�Q��
              h2_column                           = gt_upd_h2_column(ln_idx),                  -- �g�|�Q��
              i2_column                           = gt_upd_i2_column(ln_idx),                  -- �h�|�Q��
              j2_column                           = gt_upd_j2_column(ln_idx),                  -- �i�|�Q��
              k2_column                           = gt_upd_k2_column(ln_idx),                  -- �j�|�Q��
              l2_column                           = gt_upd_l2_column(ln_idx),                  -- �k�|�Q��
              f3_column                           = gt_upd_f3_column(ln_idx),                  -- �e�|�R��
              g3_column                           = gt_upd_g3_column(ln_idx),                  -- �f�|�R��
              h3_column                           = gt_upd_h3_column(ln_idx),                  -- �g�|�R��
              i3_column                           = gt_upd_i3_column(ln_idx),                  -- �h�|�R��
              j3_column                           = gt_upd_j3_column(ln_idx),                  -- �i�|�R��
              k3_column                           = gt_upd_k3_column(ln_idx),                  -- �j�|�R��
              l3_column                           = gt_upd_l3_column(ln_idx),                  -- �k�|�R��
              chain_peculiar_area_header          = gt_upd_chain_pecul_area_head(ln_idx),      -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
--            order_connection_number             = gt_upd_order_connection_num(ln_idx),       -- �󒍊֘A�ԍ�
--            invoice_indv_order_qty              = invoice_indv_order_qty + gt_upd_inv_indv_order_qty(ln_idx),         -- �i�`�[�v�j�������ʁi�o���j
--            invoice_case_order_qty              = invoice_case_order_qty + gt_upd_inv_case_order_qty(ln_idx),         -- �i�`�[�v�j�������ʁi�P�[�X�j
--            invoice_ball_order_qty              = invoice_ball_order_qty + gt_upd_inv_ball_order_qty(ln_idx),         -- �i�`�[�v�j�������ʁi�{�[���j
--            invoice_sum_order_qty               = invoice_sum_order_qty + gt_upd_inv_sum_order_qty(ln_idx),           -- �i�`�[�v�j�������ʁi���v�A�o���j
              invoice_indv_shipping_qty           = gt_upd_inv_indv_shipping_qty(ln_idx),      -- �i�`�[�v�j�o�א��ʁi�o���j
              invoice_case_shipping_qty           = gt_upd_inv_case_shipping_qty(ln_idx),      -- �i�`�[�v�j�o�א��ʁi�P�[�X�j
              invoice_ball_shipping_qty           = gt_upd_inv_ball_shipping_qty(ln_idx),      -- �i�`�[�v�j�o�א��ʁi�{�[���j
              invoice_pallet_shipping_qty         = gt_upd_inv_pallet_shipping_qty(ln_idx),    -- �i�`�[�v�j�o�א��ʁi�p���b�g�j
              invoice_sum_shipping_qty            = gt_upd_inv_sum_shipping_qty(ln_idx),       -- �i�`�[�v�j�o�א��ʁi���v�A�o���j
              invoice_indv_stockout_qty           = gt_upd_inv_indv_stockout_qty(ln_idx),      -- �i�`�[�v�j���i���ʁi�o���j
              invoice_case_stockout_qty           = gt_upd_inv_case_stockout_qty(ln_idx),      -- �i�`�[�v�j���i���ʁi�P�[�X�j
              invoice_ball_stockout_qty           = gt_upd_inv_ball_stockout_qty(ln_idx),      -- �i�`�[�v�j���i���ʁi�{�[���j
              invoice_sum_stockout_qty            = gt_upd_inv_sum_stockout_qty(ln_idx),       -- �i�`�[�v�j���i���ʁi���v�A�o���j
              invoice_case_qty                    = gt_upd_inv_case_qty(ln_idx),               -- �i�`�[�v�j�P�[�X����
              invoice_fold_container_qty          = gt_upd_inv_fold_container_qty(ln_idx),     -- �i�`�[�v�j�I���R���i�o���j����
--            invoice_order_cost_amt              = gt_upd_inv_order_cost_amt(ln_idx),         -- �i�`�[�v�j�������z�i�����j
              invoice_shipping_cost_amt           = gt_upd_inv_shipping_cost_amt(ln_idx),      -- �i�`�[�v�j�������z�i�o�ׁj
              invoice_stockout_cost_amt           = gt_upd_inv_stockout_cost_amt(ln_idx),      -- �i�`�[�v�j�������z�i���i�j
              invoice_order_price_amt             = gt_upd_inv_order_price_amt(ln_idx),        -- �i�`�[�v�j�������z�i�����j
              invoice_shipping_price_amt          = gt_upd_inv_shipping_price_amt(ln_idx),     -- �i�`�[�v�j�������z�i�o�ׁj
              invoice_stockout_price_amt          = gt_upd_inv_stockout_price_amt(ln_idx),     -- �i�`�[�v�j�������z�i���i�j
              total_indv_order_qty                = gt_upd_total_indv_order_qty(ln_idx),       -- �i�����v�j�������ʁi�o���j
              total_case_order_qty                = gt_upd_total_case_order_qty(ln_idx),       -- �i�����v�j�������ʁi�P�[�X�j
              total_ball_order_qty                = gt_upd_total_ball_order_qty(ln_idx),       -- �i�����v�j�������ʁi�{�[���j
              total_sum_order_qty                 = gt_upd_total_sum_order_qty(ln_idx),        -- �i�����v�j�������ʁi���v�A�o���j
              total_indv_shipping_qty             = gt_upd_total_indv_ship_qty(ln_idx),        -- �i�����v�j�o�א��ʁi�o���j
              total_case_shipping_qty             = gt_upd_total_case_ship_qty(ln_idx),        -- �i�����v�j�o�א��ʁi�P�[�X�j
              total_ball_shipping_qty             = gt_upd_total_ball_ship_qty(ln_idx),        -- �i�����v�j�o�א��ʁi�{�[���j
              total_pallet_shipping_qty           = gt_upd_total_pallet_ship_qty(ln_idx),      -- �i�����v�j�o�א��ʁi�p���b�g�j
              total_sum_shipping_qty              = gt_upd_total_sum_ship_qty(ln_idx),         -- �i�����v�j�o�א��ʁi���v�A�o���j
              total_indv_stockout_qty             = gt_upd_total_indv_stockout_qty(ln_idx),    -- �i�����v�j���i���ʁi�o���j
              total_case_stockout_qty             = gt_upd_total_case_stockout_qty(ln_idx),    -- �i�����v�j���i���ʁi�P�[�X�j
              total_ball_stockout_qty             = gt_upd_total_ball_stockout_qty(ln_idx),    -- �i�����v�j���i���ʁi�{�[���j
              total_sum_stockout_qty              = gt_upd_total_sum_stockout_qty(ln_idx),     -- �i�����v�j���i���ʁi���v�A�o���j
              total_case_qty                      = gt_upd_total_case_qty(ln_idx),             -- �i�����v�j�P�[�X����
              total_fold_container_qty            = gt_upd_total_fold_contain_qty(ln_idx),     -- �i�����v�j�I���R���i�o���j����
              total_order_cost_amt                = gt_upd_total_order_cost_amt(ln_idx),       -- �i�����v�j�������z�i�����j
              total_shipping_cost_amt             = gt_upd_total_shipping_cost_amt(ln_idx),    -- �i�����v�j�������z�i�o�ׁj
              total_stockout_cost_amt             = gt_upd_total_stockout_cost_amt(ln_idx),    -- �i�����v�j�������z�i���i�j
              total_order_price_amt               = gt_upd_total_order_price_amt(ln_idx),      -- �i�����v�j�������z�i�����j
              total_shipping_price_amt            = gt_upd_total_ship_price_amt(ln_idx),       -- �i�����v�j�������z�i�o�ׁj
              total_stockout_price_amt            = gt_upd_total_stock_price_amt(ln_idx),      -- �i�����v�j�������z�i���i�j
              total_line_qty                      = gt_upd_total_line_qty(ln_idx),             -- �g�[�^���s��
              total_invoice_qty                   = gt_upd_total_invoice_qty(ln_idx),          -- �g�[�^���`�[����
              chain_peculiar_area_footer          = gt_upd_chain_pecul_area_foot(ln_idx),      -- �`�F�[���X�ŗL�G���A�i�t�b�^�[�j
              conv_customer_code                  = gt_upd_conv_customer_code(ln_idx),         -- �ϊ���ڋq�R�[�h
--            order_forward_flag                  = gt_upd_order_forward_flag(ln_idx),         -- �󒍘A�g�σt���O
--            creation_class                      = gt_upd_creation_class(ln_idx),             -- �쐬���敪
--            edi_delivery_schedule_flag          = gt_upd_edi_delivery_sche_flag(ln_idx),     -- EDI�[�i�\�著�M�σt���O
              price_list_header_id                = NVL( gt_upd_price_list_header_id(ln_idx), price_list_header_id ),
                                                                                               -- ���i�\�w�b�_ID
-- 2009/12/28 M.Sano Ver.1.14 add Start
              tsukagatazaiko_div                  = gt_upd_tsukagatazaiko_div(ln_idx),             -- �ʉߍ݌Ɍ^�敪
-- 2009/12/28 M.Sano Ver.1.14 add End
              last_updated_by                     = cn_last_updated_by,                        -- �ŏI�X�V��
              last_update_date                    = cd_last_update_date,                       -- �ŏI�X�V��
              last_update_login                   = cn_last_update_login,                      -- �ŏI�X�V���O�C��
              request_id                          = cn_request_id,                             -- �v��ID
              program_application_id              = cn_program_application_id,                 -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              program_id                          = cn_program_id,                             -- �R���J�����g�E�v���O����ID
              program_update_date                 = cd_program_update_date                     -- �v���O�����X�V��
      WHERE   edi_header_info_id                  = gt_upd_edi_header_info_id(ln_idx);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �f�[�^�X�V�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_update, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_upd_edi_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_edi_lines
   * Description      : EDI���׏��e�[�u���f�[�^�ǉ�(A-17)
   ***********************************************************************************/
  PROCEDURE proc_ins_edi_lines(
    on_normal_cnt OUT NUMBER,                -- ���팏��
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_edi_lines'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx     NUMBER;
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
    -- OUT�p�����[�^������
    on_normal_cnt := 0;
--
    -- EDI���׏��f�[�^�ǉ�����
    FORALL ln_idx IN 1..gt_edi_lines.COUNT
      INSERT INTO xxcos_edi_lines
        VALUES gt_edi_lines(ln_idx);
--
    -- �o�^������ݒ�
    on_normal_cnt := gt_edi_lines.COUNT;
--
  EXCEPTION
    -- *** �L�[�d����O�n���h�� ***
    WHEN DUP_VAL_ON_INDEX THEN
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_insert, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �f�[�^�o�^�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_insert, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_ins_edi_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_edi_lines
   * Description      : EDI���׏��e�[�u���f�[�^�X�V(A-18)
   ***********************************************************************************/
  PROCEDURE proc_upd_edi_lines(
    on_normal_cnt OUT NUMBER,                -- ���팏��
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_edi_lines'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx     INTEGER;
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
    -- OUT�p�����[�^������
    on_normal_cnt := 0;
--
    -- EDI���׏��f�[�^�X�V����
    FORALL ln_idx IN 1..gt_upd_edi_line_info_id.COUNT
      UPDATE  xxcos_edi_lines
      SET     stockout_class                 = gt_upd_stockout_class(ln_idx),              -- ���i�敪
              stockout_reason                = gt_upd_stockout_reason(ln_idx),             -- ���i���R
              product_code_itouen            = gt_upd_product_code_itouen(ln_idx),         -- ���i�R�[�h�i�ɓ����j
              product_code1                  = gt_upd_product_code1(ln_idx),               -- ���i�R�[�h�P
              product_code2                  = gt_upd_product_code2(ln_idx),               -- ���i�R�[�h�Q
              jan_code                       = gt_upd_jan_code(ln_idx),                    -- �i�`�m�R�[�h
              itf_code                       = gt_upd_itf_code(ln_idx),                    -- �h�s�e�R�[�h
              extension_itf_code             = gt_upd_extension_itf_code(ln_idx),          -- �����h�s�e�R�[�h
              case_product_code              = gt_upd_case_product_code(ln_idx),           -- �P�[�X���i�R�[�h
              ball_product_code              = gt_upd_ball_product_code(ln_idx),           -- �{�[�����i�R�[�h
              product_code_item_type         = gt_upd_product_code_item_type(ln_idx),      -- ���i�R�[�h�i��
              prod_class                     = gt_upd_prod_class(ln_idx),                  -- ���i�敪
              product_name                   = gt_upd_product_name(ln_idx),                -- ���i���i�����j
              product_name1_alt              = gt_upd_product_name1_alt(ln_idx),           -- ���i���P�i�J�i�j
              product_name2_alt              = gt_upd_product_name2_alt(ln_idx),           -- ���i���Q�i�J�i�j
              item_standard1                 = gt_upd_item_standard1(ln_idx),              -- �K�i�P
              item_standard2                 = gt_upd_item_standard2(ln_idx),              -- �K�i�Q
              qty_in_case                    = gt_upd_qty_in_case(ln_idx),                 -- ����
              num_of_cases                   = gt_upd_num_of_cases(ln_idx),                -- �P�[�X����
              num_of_ball                    = gt_upd_num_of_ball(ln_idx),                 -- �{�[������
              item_color                     = gt_upd_item_color(ln_idx),                  -- �F
              item_size                      = gt_upd_item_size(ln_idx),                   -- �T�C�Y
              expiration_date                = gt_upd_expiration_date(ln_idx),             -- �ܖ�������
              product_date                   = gt_upd_product_date(ln_idx),                -- ������
              order_uom_qty                  = gt_upd_order_uom_qty(ln_idx),               -- �����P�ʐ�
              shipping_uom_qty               = gt_upd_shipping_uom_qty(ln_idx),            -- �o�גP�ʐ�
              packing_uom_qty                = gt_upd_packing_uom_qty(ln_idx),             -- ����P�ʐ�
              deal_code                      = gt_upd_deal_code(ln_idx),                   -- ����
              deal_class                     = gt_upd_deal_class(ln_idx),                  -- �����敪
              collation_code                 = gt_upd_collation_code(ln_idx),              -- �ƍ�
              uom_code                       = gt_upd_uom_code(ln_idx),                    -- �P��
              unit_price_class               = gt_upd_unit_price_class(ln_idx),            -- �P���敪
              parent_packing_number          = gt_upd_parent_packing_number(ln_idx),       -- �e����ԍ�
              packing_number                 = gt_upd_packing_number(ln_idx),              -- ����ԍ�
              product_group_code             = gt_upd_product_group_code(ln_idx),          -- ���i�Q�R�[�h
              case_dismantle_flag            = gt_upd_case_dismantle_flag(ln_idx),         -- �P�[�X��̕s�t���O
              case_class                     = gt_upd_case_class(ln_idx),                  -- �P�[�X�敪
              indv_order_qty                 = gt_upd_indv_order_qty(ln_idx),              -- �������ʁi�o���j
              case_order_qty                 = gt_upd_case_order_qty(ln_idx),              -- �������ʁi�P�[�X�j
              ball_order_qty                 = gt_upd_ball_order_qty(ln_idx),              -- �������ʁi�{�[���j
              sum_order_qty                  = gt_upd_sum_order_qty(ln_idx),               -- �������ʁi���v�A�o���j
              indv_shipping_qty              = gt_upd_indv_shipping_qty(ln_idx),           -- �o�א��ʁi�o���j
              case_shipping_qty              = gt_upd_case_shipping_qty(ln_idx),           -- �o�א��ʁi�P�[�X�j
              ball_shipping_qty              = gt_upd_ball_shipping_qty(ln_idx),           -- �o�א��ʁi�{�[���j
              pallet_shipping_qty            = gt_upd_pallet_shipping_qty(ln_idx),         -- �o�א��ʁi�p���b�g�j
              sum_shipping_qty               = gt_upd_sum_shipping_qty(ln_idx),            -- �o�א��ʁi���v�A�o���j
              indv_stockout_qty              = gt_upd_indv_stockout_qty(ln_idx),           -- ���i���ʁi�o���j
              case_stockout_qty              = gt_upd_case_stockout_qty(ln_idx),           -- ���i���ʁi�P�[�X�j
              ball_stockout_qty              = gt_upd_ball_stockout_qty(ln_idx),           -- ���i���ʁi�{�[���j
              sum_stockout_qty               = gt_upd_sum_stockout_qty(ln_idx),            -- ���i���ʁi���v�A�o���j
              case_qty                       = gt_upd_case_qty(ln_idx),                    -- �P�[�X����
              fold_container_indv_qty        = gt_upd_fold_container_indv_qty(ln_idx),     -- �I���R���i�o���j����
              order_unit_price               = gt_upd_order_unit_price(ln_idx),            -- ���P���i�����j
              shipping_unit_price            = gt_upd_shipping_unit_price(ln_idx),         -- ���P���i�o�ׁj
              order_cost_amt                 = gt_upd_order_cost_amt(ln_idx),              -- �������z�i�����j
              shipping_cost_amt              = gt_upd_shipping_cost_amt(ln_idx),           -- �������z�i�o�ׁj
              stockout_cost_amt              = gt_upd_stockout_cost_amt(ln_idx),           -- �������z�i���i�j
              selling_price                  = gt_upd_selling_price(ln_idx),               -- ���P��
              order_price_amt                = gt_upd_order_price_amt(ln_idx),             -- �������z�i�����j
              shipping_price_amt             = gt_upd_shipping_price_amt(ln_idx),          -- �������z�i�o�ׁj
              stockout_price_amt             = gt_upd_stockout_price_amt(ln_idx),          -- �������z�i���i�j
              a_column_department            = gt_upd_a_column_department(ln_idx),         -- �`���i�S�ݓX�j
              d_column_department            = gt_upd_d_column_department(ln_idx),         -- �c���i�S�ݓX�j
              standard_info_depth            = gt_upd_standard_info_depth(ln_idx),         -- �K�i���E���s��
              standard_info_height           = gt_upd_standard_info_height(ln_idx),        -- �K�i���E����
              standard_info_width            = gt_upd_standard_info_width(ln_idx),         -- �K�i���E��
              standard_info_weight           = gt_upd_standard_info_weight(ln_idx),        -- �K�i���E�d��
              general_succeeded_item1        = gt_upd_general_succeed_item1(ln_idx),       -- �ėp���p�����ڂP
              general_succeeded_item2        = gt_upd_general_succeed_item2(ln_idx),       -- �ėp���p�����ڂQ
              general_succeeded_item3        = gt_upd_general_succeed_item3(ln_idx),       -- �ėp���p�����ڂR
              general_succeeded_item4        = gt_upd_general_succeed_item4(ln_idx),       -- �ėp���p�����ڂS
              general_succeeded_item5        = gt_upd_general_succeed_item5(ln_idx),       -- �ėp���p�����ڂT
              general_succeeded_item6        = gt_upd_general_succeed_item6(ln_idx),       -- �ėp���p�����ڂU
              general_succeeded_item7        = gt_upd_general_succeed_item7(ln_idx),       -- �ėp���p�����ڂV
              general_succeeded_item8        = gt_upd_general_succeed_item8(ln_idx),       -- �ėp���p�����ڂW
              general_succeeded_item9        = gt_upd_general_succeed_item9(ln_idx),       -- �ėp���p�����ڂX
              general_succeeded_item10       = gt_upd_general_succeed_item10(ln_idx),      -- �ėp���p�����ڂP�O
              general_add_item1              = gt_upd_general_add_item1(ln_idx),           -- �ėp�t�����ڂP
              general_add_item2              = gt_upd_general_add_item2(ln_idx),           -- �ėp�t�����ڂQ
              general_add_item3              = gt_upd_general_add_item3(ln_idx),           -- �ėp�t�����ڂR
              general_add_item4              = gt_upd_general_add_item4(ln_idx),           -- �ėp�t�����ڂS
              general_add_item5              = gt_upd_general_add_item5(ln_idx),           -- �ėp�t�����ڂT
              general_add_item6              = gt_upd_general_add_item6(ln_idx),           -- �ėp�t�����ڂU
              general_add_item7              = gt_upd_general_add_item7(ln_idx),           -- �ėp�t�����ڂV
              general_add_item8              = gt_upd_general_add_item8(ln_idx),           -- �ėp�t�����ڂW
              general_add_item9              = gt_upd_general_add_item9(ln_idx),           -- �ėp�t�����ڂX
              general_add_item10             = gt_upd_general_add_item10(ln_idx),          -- �ėp�t�����ڂP�O
              chain_peculiar_area_line       = gt_upd_chain_pecul_area_line(ln_idx),       -- �`�F�[���X�ŗL�G���A�i���ׁj
              item_code                      = gt_upd_item_code(ln_idx),                   -- �i�ڃR�[�h
              line_uom                       = gt_upd_line_uom(ln_idx),                    -- ���גP��
              order_connection_line_number   = gt_upd_order_connect_line_num(ln_idx),      -- �󒍊֘A���הԍ�
              last_updated_by                = cn_last_updated_by,                         -- �ŏI�X�V��
              last_update_date               = cd_last_update_date,                        -- �ŏI�X�V��
              last_update_login              = cn_last_update_login,                       -- �ŏI�X�V���O�C��
              request_id                     = cn_request_id,                              -- �v��ID
              program_application_id         = cn_program_application_id,                  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              program_id                     = cn_program_id,                              -- �R���J�����g�E�v���O����ID
              program_update_date            = cd_program_update_date                      -- �v���O�����X�V��
      WHERE   edi_line_info_id               = gt_upd_edi_line_info_id(ln_idx)             -- EDI���׏��ID
      AND     edi_header_info_id             = gt_upd_edi_line_header_info_id(ln_idx);     -- EDI�w�b�_���ID
--
    -- �X�V������ݒ�
    on_normal_cnt := gt_upd_edi_line_info_id.COUNT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �f�[�^�X�V�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_update, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_upd_edi_lines;
--
-- 2010/01/19 Ver1.15 M.Sano Add Start
  /**********************************************************************************
   * Procedure Name   : proc_del_edi_errors
   * Description      : EDI�G���[���e�[�u���f�[�^�폜(A-19-1)
   ***********************************************************************************/
  PROCEDURE proc_del_edi_errors(
    iv_exe_type   IN  VARCHAR2,              -- ���s�敪
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_set_edi_errors'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx               NUMBER;
    ld_purge_date        DATE;
    lt_work_id           xxcos_edi_errors.work_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- EDI���폜�ΏۃJ�[�\��(EDI�w�b�_ID)
    CURSOR edi_errors_lock1_cur (
      it_work_id     xxcos_edi_errors.work_id%TYPE
    )
    IS
      SELECT  xee.edi_err_id                       -- EDI�G���[ID
      FROM    xxcos_edi_errors  xee                -- EDI�G���[�e�[�u��
      WHERE   xee.work_id = it_work_id
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    IF ( iv_exe_type = cv_exe_type_retry ) THEN
      -- EDI���폜�Ώۂ�EDI�G���[���e�[�u���̃��b�N���擾����B
      <<work_id_lock_loop>>
      FOR ln_idx IN 1..gt_order_info_work_id.COUNT LOOP
        lt_work_id := gt_order_info_work_id(ln_idx);
        OPEN edi_errors_lock1_cur(lt_work_id);
        CLOSE edi_errors_lock1_cur;
      END LOOP work_id_lock_loop;
--
      -- �Ώۃf�[�^���폜
      FORALL ln_idx IN 1..gt_order_info_work_id.COUNT
        DELETE
        FROM   xxcos_edi_errors xee
        WHERE  xee.work_id = gt_order_info_work_id(ln_idx)
        ;
    END IF;
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- ���b�N�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, lv_tkn1 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF ( edi_errors_lock1_cur%ISOPEN ) THEN
        CLOSE edi_errors_lock1_cur;
      END IF;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �f�[�^�폜�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_delete, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF ( edi_errors_lock1_cur%ISOPEN ) THEN
        CLOSE edi_errors_lock1_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_del_edi_errors;
-- 2010/01/19 Ver1.15 M.Sano Add End
--
  /**********************************************************************************
   * Procedure Name   : proc_ins_edi_errors
   * Description      : EDI�G���[���e�[�u���f�[�^�ǉ�(A-19)
   ***********************************************************************************/
  PROCEDURE proc_ins_edi_errors(
    on_warn_cnt   OUT NOCOPY NUMBER,         -- �x������
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ins_edi_errors'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx     NUMBER;
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
    -- OUT�p�����[�^������
    on_warn_cnt := 0;
--
    -- EDI�G���[���f�[�^�ǉ�����
    FORALL ln_idx IN 1..gt_edi_errors.COUNT
      INSERT INTO xxcos_edi_errors
        VALUES gt_edi_errors(ln_idx);
--
    -- �x��������ݒ�
    on_warn_cnt := gt_edi_errors.COUNT;
--
  EXCEPTION
    -- *** �L�[�d����O�n���h�� ***
    WHEN DUP_VAL_ON_INDEX THEN
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_insert, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �f�[�^�o�^�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_insert, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_ins_edi_errors;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_edi_work
   * Description      : EDI�󒍏�񃏁[�N�e�[�u���X�e�[�^�X�X�V(A-20)
   ***********************************************************************************/
  PROCEDURE proc_upd_edi_work(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_edi_work'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx          NUMBER;
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
    -- EDI�󒍏�񃏁[�N�e�[�u���̃X�e�[�^�X���ꊇ�X�V����
    FORALL ln_idx IN 1..gt_order_info_work_id.COUNT
      UPDATE  xxcos_edi_order_work                                              -- EDI�󒍏�񃏁[�N�e�[�u��
      SET     err_status                = gt_edi_err_status(ln_idx),            -- �X�e�[�^�X
              last_updated_by           = cn_last_updated_by,                   -- �ŏI�X�V��
              last_update_date          = cd_last_update_date,                  -- �ŏI�X�V��
              last_update_login         = cn_last_update_login,                 -- �ŏI�X�V���O�C��
              request_id                = cn_request_id,                        -- �v��ID
              program_application_id    = cn_program_application_id,            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              program_id                = cn_program_id,                        -- �R���J�����g�E�v���O����ID
              program_update_date       = cd_program_update_date                -- �v���O�����X�V��
      WHERE   order_info_work_id        = gt_order_info_work_id(ln_idx);        -- EDI�󒍏�񃏁[�NID
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �f�[�^�X�V�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_edi_wk_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_update, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_upd_edi_work;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_del_edi_work
   * Description      : EDI�󒍏�񃏁[�N�e�[�u���f�[�^�폜(A-21)
   ***********************************************************************************/
  PROCEDURE proc_del_edi_work(
    iv_filename   IN  VARCHAR2,              -- �C���^�t�F�[�X�t�@�C����
    ov_errbuf     OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_del_edi_work'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx          NUMBER;
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
    -- EDI�󒍏�񃏁[�N�e�[�u���f�[�^�폜�i����f�[�^�̂݁j
    DELETE
    FROM    xxcos_edi_order_work                            -- EDI�󒍏�񃏁[�N�e�[�u��
    WHERE   if_file_name     = iv_filename                  -- �C���^�t�F�[�X�t�@�C����
    AND     data_type_code   = cv_data_type_code            -- �f�[�^��R�[�h�F��
    AND     err_status       = cv_edi_status_normal;        -- �X�e�[�^�X���u����v
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �f�[�^�폜�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_edi_wk_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_delete, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_del_edi_work;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_del_edi_head_line
   * Description      : EDI�w�b�_���e�[�u���AEDI���׏��e�[�u���f�[�^�폜(A-22)
   *                    EDI���폜���Ԃ��o�߂��Ă���f�[�^���폜����
   ***********************************************************************************/
  PROCEDURE proc_del_edi_head_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_del_edi_head_line'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(100);   -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ld_purge_date        DATE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- EDI���폜�ΏۃJ�[�\��
    CURSOR edi_head_line_cur(
      id_purge_date DATE                                         -- EDI���폜���
    )
    IS
-- 2009/09/02 Ver1.9 M.Sano Mod Start
--      SELECT  head.edi_header_info_id,                           -- EDI�w�b�_���ID
      SELECT  /*+ 
                LEADING( head )
                USE_NL( line )
                INDEX( head xxcos_edi_headers_n06)
                INDEX( line xxcos_edi_lines_n01)
               */
              head.edi_header_info_id,                           -- EDI�w�b�_���ID
-- 2009/09/02 Ver1.9 M.Sano Mod End
              line.edi_line_info_id                              -- EDI���׏��ID
      FROM    xxcos_edi_lines           line,                    -- EDI���׏��e�[�u��
              xxcos_edi_headers         head                     -- EDI�w�b�_���e�[�u��
      WHERE   head.data_type_code       = cv_data_type_code      -- �f�[�^��R�[�h�FEDI��
      AND     head.edi_header_info_id   = line.edi_header_info_id
      AND     NVL( head.shop_delivery_date,                      -- �X�ܔ[�i��
                NVL( head.center_delivery_date,                  -- �Z���^�[�[�i��
                  NVL( head.order_date,                          -- ������
                    TRUNC( head.data_creation_date_edi_data )    -- �f�[�^�쐬���i�d�c�h�f�[�^���j
                  )
                )
              )                         < id_purge_date
      FOR UPDATE NOWAIT;
--
-- 2010/01/19 Ver1.15 M.Sano Add Start
    -- EDI���폜�ΏۃJ�[�\��(EDI��M��)
    CURSOR edi_errors_lock2_cur (
      id_purge_date DATE
    )
    IS
      SELECT  xee.edi_err_id                          -- EDI�G���[ID
      FROM    xxcos_edi_errors  xee                   -- EDI�G���[�e�[�u��
      WHERE   xee.creation_date     < id_purge_date       -- �쐬�����p�[�W�Ώۓ��ȑO
      AND     xee.edi_create_class  = cv_edi_create_class -- �G���[���X�g��ʁF��
      FOR UPDATE NOWAIT;
--
-- 2010/01/19 Ver1.15 M.Sano Add End
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
    -- EDI���폜������擾
    SELECT  TRUNC( SYSDATE - TO_NUMBER( gv_purge_term ) )
    INTO    ld_purge_date
    FROM    dual;
--
    -- ���b�N�J�[�\���I�[�v��
    OPEN edi_head_line_cur(ld_purge_date);
--
    -- EDI���׏��e�[�u���f�[�^�폜
-- 2009/09/02 Ver1.9 M.Sano Add Start
--    DELETE
--    FROM    xxcos_edi_lines
--    WHERE   edi_line_info_id IN (
--              SELECT  edi_line_info_id                                -- EDI���׏��ID
    DELETE /*+ INDEX ( line_d xxcos_edi_lines_pk ) */
    FROM    xxcos_edi_lines line_m
    WHERE   line_m.edi_line_info_id IN (
              SELECT  
                  /*+ LEADING( head )
                      USE_NL( line )
                      INDEX( head xxcos_edi_headers_n06)
                      INDEX( line xxcos_edi_lines_n01)   */
                      edi_line_info_id                                -- EDI���׏��ID
-- 2009/09/02 Ver1.9 M.Sano Mod END
              FROM    xxcos_edi_lines         line,                   -- EDI���׏��e�[�u��
                      xxcos_edi_headers       head                    -- EDI�w�b�_���e�[�u��
              WHERE   head.data_type_code     = cv_data_type_code     -- �f�[�^��R�[�h�FEDI��
              AND     head.edi_header_info_id = line.edi_header_info_id
              AND     NVL( head.shop_delivery_date,                   -- �X�ܔ[�i��
                        NVL( head.center_delivery_date,               -- �Z���^�[�[�i��
                          NVL( head.order_date,                       -- ������
                            TRUNC( head.data_creation_date_edi_data ) -- �f�[�^�쐬���i�d�c�h�f�[�^���j
                          )
                        )
                      )                       < ld_purge_date
            );
--
    -- EDI�w�b�_���e�[�u���f�[�^�폜
    DELETE
    FROM    xxcos_edi_headers                 head                    -- EDI�w�b�_���e�[�u��
    WHERE   head.data_type_code               = cv_data_type_code     -- �f�[�^��R�[�h�FEDI��
    AND     NVL( head.shop_delivery_date,                             -- �X�ܔ[�i��
              NVL( head.center_delivery_date,                         -- �Z���^�[�[�i��
                NVL( head.order_date,                                 -- ������
                  TRUNC( head.data_creation_date_edi_data )           -- �f�[�^�쐬���i�d�c�h�f�[�^���j
                )
              )
            )                                 < ld_purge_date;
--
    -- ���b�N�J�[�\���N���[�Y
    CLOSE edi_head_line_cur;
--
-- 2010/01/19 Ver1.15 M.Sano Add Start
    -- EDI���폜������擾
    SELECT  TRUNC( SYSDATE - TO_NUMBER( gv_err_purge_term ) )
    INTO    ld_purge_date
    FROM    dual;
--
    -- EDI���폜�Ώۂ�EDI�G���[���e�[�u���̃��b�N���擾����B
    OPEN edi_errors_lock2_cur(ld_purge_date);
    CLOSE edi_errors_lock2_cur;
--
    -- �Ώۃf�[�^���폜
    DELETE
    FROM   xxcos_edi_errors xee
    WHERE  xee.creation_date    < ld_purge_date       -- �쐬�����p�[�W�Ώۓ��ȑO
    AND    xee.edi_create_class = cv_edi_create_class -- �G���[���X�g��ʁF��
    ;
-- 2010/01/19 Ver1.15 M.Sano Add End
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      -- ���b�N�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, lv_tkn1 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
-- 2010/01/19 Ver1.15 M.Sano Del Start
--      ov_retcode := cv_status_error;
-- 2010/01/19 Ver1.15 M.Sano Del End
--
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF ( edi_head_line_cur%ISOPEN ) THEN
        CLOSE edi_head_line_cur;
      END IF;
-- 2010/01/19 Ver1.15 M.Sano Add Start
      IF ( edi_errors_lock2_cur%ISOPEN ) THEN
        CLOSE edi_errors_lock2_cur;
      END IF;
-- 2010/01/19 Ver1.15 M.Sano Add End
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �f�[�^�폜�G���[���o��
      lv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tbl );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_delete, cv_tkn_table_name, lv_tkn1, cv_tkn_key_data, NULL );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
      -- �J�[�\�����I�[�v�����Ă���ꍇ�̓N���[�Y����
      IF ( edi_head_line_cur%ISOPEN ) THEN
        CLOSE edi_head_line_cur;
      END IF;
-- 2010/01/19 Ver1.15 M.Sano Add Start
      IF ( edi_errors_lock2_cur%ISOPEN ) THEN
        CLOSE edi_errors_lock2_cur;
      END IF;
-- 2010/01/19 Ver1.15 M.Sano Add End
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_del_edi_head_line;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_loop_main
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE proc_loop_main(
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_loop_main'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_tkn1    VARCHAR2(20);    -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(20);    -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_idx                    NUMBER;
    ln_cnt                    NUMBER;
    ln_edi_head_id            NUMBER := NULL;          -- EDI�w�b�_���ID
    ln_edi_line_id            NUMBER := NULL;          -- EDI���׏��ID
    lv_invoice_number         xxcos_edi_order_work.invoice_number%TYPE := NULL;
    ln_edi_head_ins_flag      NUMBER(1) := 0;          -- EDI�w�b�_���o�^�t���O
    ln_head_duplicate_err     NUMBER := 0;             -- �w�b�_�d���G���[�t���O
    ln_line_duplicate_err     NUMBER := 0;             -- ���׏d���G���[�t���O
-- 2009/06/29 M.Sano Ver.1.6 add Start
    lv_shop_code              xxcos_edi_order_work.shop_code%TYPE      := NULL;  -- �X�R�[�h
-- 2009/06/29 M.Sano Ver.1.6 add End
-- 2009/11/19 M.Sano Ver.1.11 add Start
    lv_edi_chain_code         xxcos_edi_order_work.edi_chain_code%TYPE := NULL;  -- EDI�`�F�[���X�R�[�h
-- 2009/11/19 M.Sano Ver.1.11 add End
-- 2009/11/25 K.Atsushiba Ver.1.12 Add Start
    lt_shop_delivery_date     xxcos_edi_order_work.shop_delivery_date%TYPE := NULL;  -- �X�ܔ[�i��
-- 2009/11/25 K.Atsushiba Ver.1.12 Add End
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
    -- EDI�󒍏�񃏁[�N�e�[�u���f�[�^�����[�v
    <<loop_edi_order_work>>
    FOR ln_idx IN 1..gt_edi_order_work.COUNT LOOP
--
      -- �`�[�ԍ���ێ�����
      lv_invoice_number := gt_edi_order_work(ln_idx).invoice_number;
-- 2009/06/29 M.Sano Ver.1.6 add Start
      -- �X�R�[�h��ێ�����
      lv_shop_code      := gt_edi_order_work(ln_idx).shop_code;
-- 2009/06/29 M.Sano Ver.1.6 add End
-- 2009/11/19 M.Sano Ver.1.11 add Start
      -- EDI�`�F�[���X�R�[�h��ێ�����
      lv_edi_chain_code := gt_edi_order_work(ln_idx).edi_chain_code;
-- 2009/11/19 M.Sano Ver.1.11 add End
-- 2009/11/25 K.Atsushiba Ver.1.12 Add Start
      -- �X�ܔ[�i����ێ�����
      lt_shop_delivery_date := gt_edi_order_work(ln_idx).shop_delivery_date;
-- 2009/11/25 K.Atsushiba Ver.1.12 Add END
--
      -- ============================================
      -- EDI�󒍏�񃏁[�N�ϐ��i�[(A-5)
      -- ============================================
      proc_set_edi_work(
        gt_edi_order_work(ln_idx),
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      -- �f�[�^�擾�Ɏ��s�����ꍇ�A�������~
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
-- 2009/11/25 K.Atsushiba Ver.1.12 Mod Start
--      -- �`�[�ԍ����ς������
--      IF ( ( ln_idx = gt_edi_order_work.COUNT )
---- 2009/11/19 M.Sano Ver.1.11 add Start
--      OR ( lv_edi_chain_code != gt_edi_order_work(ln_idx + 1).edi_chain_code )
---- 2009/11/19 M.Sano Ver.1.11 add End
---- 2009/06/29 M.Sano Ver.1.6 add Start
--      OR ( lv_shop_code      != gt_edi_order_work(ln_idx + 1).shop_code )
---- 2009/06/29 M.Sano Ver.1.6 add End
--      OR ( lv_invoice_number != gt_edi_order_work(ln_idx + 1).invoice_number ) ) THEN
--
      -- EDI�w�b�_�L�[�`�F�b�N
      IF ( ( ln_idx != gt_edi_order_work.COUNT )
           AND
           ( ( lv_edi_chain_code = gt_edi_order_work(ln_idx + 1).edi_chain_code )
             AND
             ( lv_invoice_number = gt_edi_order_work(ln_idx + 1).invoice_number )
             AND
             ( ( ( lv_shop_code IS NULL ) AND ( gt_edi_order_work(ln_idx + 1).shop_code IS NULL ) )
               OR
               ( lv_shop_code = gt_edi_order_work(ln_idx + 1).shop_code )
             )
             AND
             ( ( ( lt_shop_delivery_date IS NULL ) AND ( gt_edi_order_work(ln_idx + 1).shop_delivery_date IS NULL ) )
               OR
               ( lt_shop_delivery_date = gt_edi_order_work(ln_idx + 1).shop_delivery_date )
             )
           )
      ) THEN
        -- EDI�w�b�_�������ꍇ
        NULL;
      ELSE
        -- EDI�w�b�_���ς�����ꍇ
-- 2009/11/25 K.Atsushiba Ver.1.12 Mod End
        -- �`�[�G���[�t���O������
        gn_invoice_err_flag := 0;
        -- �w�b�_�d���G���[�t���O������
        ln_head_duplicate_err := 0;
--
        -- ============================================
        -- �f�[�^�Ó����`�F�b�N(A-4)
        -- ============================================
        proc_data_validate(
          lv_errbuf,
          lv_retcode,
          lv_errmsg
        );
--
        -- �G���[���������Ă���ꍇ
        IF ( lv_retcode != cv_status_normal ) THEN
          -- �I���X�e�[�^�X�ݒ�
          ov_retcode := lv_retcode;
        END IF;
--
        -- �`�[�G���[���������Ă��Ȃ��ꍇ
        IF ( gn_invoice_err_flag = 0 ) THEN
--
          -- EDI�w�b�_�A����ID��������
          ln_edi_head_id := NULL;
          ln_edi_line_id := NULL;
          ln_edi_head_ins_flag := 0;
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--          -- ============================================
--          -- EDI�w�b�_���e�[�u���f�[�^���o(A-7)
--          -- ============================================
--          proc_get_edi_headers(
--            gt_edi_work(gt_edi_work.first),
--            ln_edi_head_id,
--            lv_errbuf,
--            lv_retcode,
--            lv_errmsg
--          );
----
--          -- A-7�ŃG���[�����������ꍇ�A�������~
--          IF ( lv_retcode = cv_status_error ) THEN
--            RAISE global_process_expt;
--          END IF;
          IF ( gn_check_record_flag = cn_check_record_yes ) THEN
            -- ============================================
            -- EDI�w�b�_���e�[�u���f�[�^���o(A-7)
            -- ============================================
            proc_get_edi_headers(
              gt_edi_work(gt_edi_work.first),
              ln_edi_head_id,
              lv_errbuf,
              lv_retcode,
              lv_errmsg
            );
  --
            -- A-7�ŃG���[�����������ꍇ�A�������~
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
          ELSE
            ln_edi_head_id := NULL;
          END IF;
-- 2009/06/29 M.Sano Ver.1.6 mod End
--
          -- EDI�w�b�_��񂪑��݂��Ȃ��ꍇ
          IF ( ln_edi_head_id IS NULL ) THEN
--
            -- ============================================
            -- EDI�w�b�_���C���T�[�g�p�ϐ��i�[(A-8)
            -- ============================================
            proc_set_ins_headers(
              gt_edi_work(gt_edi_work.first),
              ln_edi_head_id,
              lv_errbuf,
              lv_retcode,
              lv_errmsg
            );
--
            -- A-8�ŗ�O�����������ꍇ�A�������~
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
            -- EDI�w�b�_���C���T�[�g��
            ln_edi_head_ins_flag := 1;
--
          -- ���Y�f�[�^���x���X�e�[�^�X�̏ꍇ�AEDI�w�b�_�����A�b�v�f�[�g����
          ELSIF ( gt_edi_work(gt_edi_work.first).err_status = cv_edi_status_warning ) THEN
--
            -- ============================================
            -- EDI�w�b�_���A�b�v�f�[�g�p�ϐ��i�[(A-9)
            -- ============================================
            proc_set_upd_headers(
              gt_edi_work(gt_edi_work.first),
              ln_edi_head_id,
              lv_errbuf,
              lv_retcode,
              lv_errmsg
            );
--
            -- A-9�ŗ�O�����������ꍇ�A�������~
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          -- �X�e�[�^�X���x���ȊO�̏ꍇ
          ELSE
--
            -- �w�b�_�d���G���[��ݒ�
            ln_head_duplicate_err := 1;
            -- �I���X�e�[�^�X�Ɍx����ݒ�
            ov_retcode := cv_status_warn;
--
          END IF;
--
          -- �`�[���׍��v��������
          gt_inv_total.indv_order_qty := 0;
          gt_inv_total.case_order_qty := 0;
          gt_inv_total.ball_order_qty := 0;
          gt_inv_total.sum_order_qty  := 0;
          gt_inv_total.order_cost_amt := 0;
-- *************************** 2009/07/24 1.8 N.Maeda ADD START ********************************** --
          gt_inv_total.shipping_cost_amt := 0;
          gt_inv_total.stockout_cost_amt := 0;
-- *************************** 2009/07/24 1.8 N.Maeda ADD  END  ********************************** --
--
          <<loop_set_edi_lines>>
          FOR ln_Idx IN 1..gt_edi_work.COUNT LOOP
--
            -- ���׏d���G���[�t���O������
            ln_line_duplicate_err := 0;
--
            -- �`�[�G���[�A�w�b�_�d���G���[���������Ă��Ȃ��ꍇ
            IF (( gn_invoice_err_flag = 0 ) AND ( ln_head_duplicate_err = 0 )) THEN
--
-- 2009/06/29 M.Sano Ver.1.6 mod Start
--              -- ============================================
--              -- EDI���׏��e�[�u���f�[�^���o(A-10)
--              -- ============================================
--              proc_get_edi_lines(
--                gt_edi_work(ln_Idx),
--                ln_edi_head_id,
--                ln_edi_line_id,
--                lv_errbuf,
--                lv_retcode,
--                lv_errmsg
--              );
----
--              -- A-10�ŃG���[�����������ꍇ�A�������~
--              IF ( lv_retcode = cv_status_error ) THEN
--                RAISE global_process_expt;
--              END IF;
              IF ( gn_check_record_flag = cn_check_record_yes ) THEN
                -- ============================================
                -- EDI���׏��e�[�u���f�[�^���o(A-10)
                -- ============================================
                proc_get_edi_lines(
                  gt_edi_work(ln_Idx),
                  ln_edi_head_id,
                  ln_edi_line_id,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg
                );
--
                -- A-10�ŃG���[�����������ꍇ�A�������~
                IF ( lv_retcode = cv_status_error ) THEN
                  RAISE global_process_expt;
                END IF;
              ELSE
                ln_edi_line_id := NULL;
              END IF;
-- 2009/06/29 M.Sano Ver.1.6 mod End
--
              -- EDI���׏�񂪑��݂��Ȃ��ꍇ
              IF ( ln_edi_line_id IS NULL ) THEN
--
                -- ============================================
                -- EDI���׏��C���T�[�g�p�ϐ��i�[(A-11)
                -- ============================================
                proc_set_ins_lines(
                  gt_edi_work(ln_Idx),
                  ln_edi_head_id,
                  ln_edi_line_id,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg
                );
--
                -- A-11�ŃG���[�����������ꍇ�A�������~
                IF ( lv_retcode = cv_status_error ) THEN
                  RAISE global_process_expt;
                END IF;
--
              -- ���Y�f�[�^���x���X�e�[�^�X�̏ꍇ�AEDI���׏����A�b�v�f�[�g����
              ELSIF ( gt_edi_work(ln_Idx).err_status = cv_edi_status_warning ) THEN
--
                -- ============================================
                -- EDI���׏��A�b�v�f�[�g�p�ϐ��i�[(A-12)
                -- ============================================
                proc_set_upd_lines(
                  gt_edi_work(ln_Idx),
                  ln_edi_head_id,
                  ln_edi_line_id,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg
                );
--
                -- A-12�ŃG���[�����������ꍇ�A�������~
                IF ( lv_retcode = cv_status_error ) THEN
                  RAISE global_process_expt;
                END IF;
--
              -- �X�e�[�^�X���x���ȊO�̏ꍇ
              ELSE
--
                -- ���׏d���G���[��ݒ�
                ln_line_duplicate_err := 1;
                -- �I���X�e�[�^�X�Ɍx����ݒ�
                ov_retcode := cv_status_warn;
--
              END IF;
--
              -- ============================================
              -- �`�[���̍��v�l���Z�o(A-13)
              -- ============================================
              proc_calc_inv_total(
                gt_edi_work(ln_Idx),
                lv_errbuf,
                lv_retcode,
                lv_errmsg
              );
--
              -- A-13�ŃG���[�����������ꍇ�A�������~
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
--
            END IF;
--
            -- �w�b�_�d���G���[�A���׏d���G���[�����������ꍇ�́A�G���[���b�Z�[�W���o��
            IF (( ln_head_duplicate_err = 1 ) OR ( ln_line_duplicate_err = 1 )) THEN
--
              -- �d���o�^�G���[���o��
              lv_errmsg  := xxccp_common_pkg.get_msg( cv_application,
                                                      cv_msg_duplicate,
                                                      cv_tkn_chain_shop_code,
                                                      gt_edi_work(ln_Idx).edi_chain_code,
                                                      cv_tkn_order_no,
                                                      gt_edi_work(ln_Idx).invoice_number,
                                                      cv_tkn_store_deliv_dt,
-- 2010/01/19 Ver.1.15 M.Sano mod Start
--                                                      gt_edi_work(ln_Idx).shop_delivery_date,
                                                      TO_CHAR(gt_edi_work(ln_Idx).shop_delivery_date,
                                                              cv_format_yyyymmdds),
-- 2010/01/19 Ver.1.15 M.Sano mod End
                                                      cv_tkn_shop_code,
                                                      gt_edi_work(ln_Idx).shop_code,
                                                      cv_tkn_line_no,
                                                      gt_edi_work(ln_Idx).line_no );
              lv_errbuf  := lv_errmsg;
              -- ���O�o��
              proc_msg_output( cv_prg_name, lv_errbuf );
              -- �x���X�e�[�^�X�ݒ�
              gt_edi_work(ln_Idx).check_status := cv_edi_status_warning;
              -- EDI�G���[���ǉ�
              proc_set_edi_errors( gt_edi_work(ln_Idx), NULL, cv_error_delete_flag, cv_msg_rep_duplicate );
--
            END IF;
--
          END LOOP;
--
          -- ============================================
          -- EDI�w�b�_���p�ϐ��ɓ`�[�v��ݒ�(A-14)
          -- ============================================
          proc_set_inv_total(
            ln_edi_head_ins_flag,
            lv_errbuf,
            lv_retcode,
            lv_errmsg
          );
--
          -- A-14�ŃG���[�����������ꍇ�A�������~
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        -- �`�[�G���[���������Ă���ꍇ
        ELSE
--
          -- �X�L�b�v�����ɓ`�[���א������Z
          gn_skip_cnt := gn_skip_cnt + gt_edi_work.COUNT;
--
        END IF;
--
        -- ============================================
        -- EDI�X�e�[�^�X�X�V�p�ϐ��i�[(A-6)
        -- ============================================
        -- �`�[�P�ʂ̑S���ׂ̃X�e�[�^�X��ێ�����
        <<loop_set_edi_status>>
        FOR ln_cnt IN 1..gt_edi_work.COUNT LOOP
          -- �X�e�[�^�X��ێ�
          proc_set_edi_status(
            gt_edi_work(ln_cnt).order_info_work_id,
            gt_edi_work(ln_cnt).check_status,
            lv_errbuf,
            lv_retcode,
            lv_errmsg
          );
--
          -- A-6�ŃG���[�����������ꍇ�A�������~
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END LOOP;
--
        -- EDI�[�i�ԕi��񃏁[�N�ϐ����N���A
        gt_edi_work.DELETE;
--
      END IF;
--
    END LOOP;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END proc_loop_main;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
-- 2010/01/19 Ver1.15 M.Sano Add Start
--    iv_filename   IN  VARCHAR2,              --   �C���^�t�F�[�X�t�@�C����
--    iv_exetype    IN  VARCHAR2,              --   ���s�敪�i0�F�V�K�A1�F�Ď��{�j
    iv_filename       IN  VARCHAR2,              --   �C���^�t�F�[�X�t�@�C����
    iv_exetype        IN  VARCHAR2,              --   ���s�敪�i0�F�V�K�A1�F�Ď��{�j
    iv_edi_chain_code IN  VARCHAR2,              --   EDI�`�F�[���X�R�[�h
-- 2010/01/19 Ver1.15 M.Sano Add End
    ov_errbuf     OUT NOCOPY VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_tkn1    VARCHAR2(20);    -- ���b�Z�[�W�g�[�N���P
    lv_tkn2    VARCHAR2(20);    -- ���b�Z�[�W�g�[�N���Q
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_invoice_number         xxcos_edi_order_work.invoice_number%TYPE := NULL;
    ln_ins_normal_cnt         NUMBER := 0;             -- ���팏���i�o�^�p�j
    ln_upd_normal_cnt         NUMBER := 0;             -- ���팏���i�X�V�p�j
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
    gn_skip_cnt   := 0;
    gt_edi_work   := g_edi_work_ttype();
    gt_edi_order_work.DELETE;
    gt_order_info_work_id.DELETE;
    gt_edi_headers.DELETE;
    gt_edi_lines.DELETE;
    gt_edi_errors.DELETE;
    gt_upd_edi_header_info_id.DELETE;
    gt_upd_edi_line_info_id.DELETE;
--
    -- ============================================
    -- ���̓p�����[�^�Ó����`�F�b�N(A-1)
    -- ============================================
    proc_param_check(
      iv_filename,
      iv_exetype,
-- 2010/01/19 Ver1.15 M.Sano Add Start
      iv_edi_chain_code,
-- 2010/01/19 Ver1.15 M.Sano Add End
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �`�F�b�N�G���[�̏ꍇ�A�������~
    IF ( lv_retcode != cv_status_normal ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- ��������(A-2)
    -- ============================================
    proc_init(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �G���[�����̏ꍇ�A�������~
    IF ( lv_retcode != cv_status_normal ) THEN
      ov_retcode := lv_retcode;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDI�󒍏�񃏁[�N�e�[�u���f�[�^���o(A-3)
    -- ============================================
    proc_get_edi_work(
      iv_filename,
      iv_exetype,
-- 2010/01/19 Ver1.15 M.Sano Add Start
      iv_edi_chain_code,
-- 2010/01/19 Ver1.15 M.Sano Add End
      gn_target_cnt,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �G���[�̏ꍇ�A�������~
    IF ( lv_retcode != cv_status_normal ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- ���[�v���C������
    -- ============================================
    proc_loop_main(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �x�����������Ă���ꍇ�́A�X�e�[�^�X��ێ�����
    IF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := lv_retcode;
--
    -- �G���[�����������ꍇ�͏������~
    ELSIF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    --EDI�w�b�_���e�[�u���f�[�^�ǉ�(A-15)
    -- ============================================
    proc_ins_edi_headers(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �G���[�����������ꍇ�͏������~
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDI�w�b�_���e�[�u���f�[�^�X�V(A-16)
    -- ============================================
    proc_upd_edi_headers(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �G���[�����������ꍇ�͏������~
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDI���׏��e�[�u���f�[�^�ǉ�(A-17)
    -- ============================================
    proc_ins_edi_lines(
      ln_ins_normal_cnt,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �G���[�����������ꍇ�͏������~
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDI���׏��e�[�u���f�[�^�X�V(A-18)
    -- ============================================
    proc_upd_edi_lines(
      ln_upd_normal_cnt,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �G���[�����������ꍇ�͏������~
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ���팏����ݒ�
    gn_normal_cnt := ln_ins_normal_cnt + ln_upd_normal_cnt;
--
-- 2010/01/19 Ver1.15 M.Sano Add Start
    -- ============================================
    -- EDI�G���[���e�[�u���f�[�^�폜(A-18-1)
    -- ============================================
    proc_del_edi_errors(
      iv_exetype,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �G���[�����������ꍇ�͏������~
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
-- 2010/01/19 Ver1.15 M.Sano Add End
    -- ============================================
    -- EDI�G���[���e�[�u���f�[�^�ǉ�(A-19)
    -- ============================================
    proc_ins_edi_errors(
      gn_warn_cnt,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �G���[�����������ꍇ�͏������~
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDI�󒍏�񃏁[�N�e�[�u���X�e�[�^�X�X�V(A-20)
    -- ============================================
    proc_upd_edi_work(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �G���[�����������ꍇ�͏������~
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ============================================
    -- EDI�󒍏�񃏁[�N�e�[�u���f�[�^�폜(A-21)
    -- ============================================
    proc_del_edi_work(
      iv_filename,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �G���[�����������ꍇ�͏������~
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- �����܂Ő���Ȃ�΃R�~�b�g
    COMMIT;
--
    -- ============================================
    -- EDI�w�b�_���e�[�u���AEDI���׏��e�[�u���f�[�^�폜(A-22)
    -- ============================================
    proc_del_edi_head_line(
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- �G���[�����������ꍇ�͏������~
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,              --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,              --   ���^�[���E�R�[�h    --# �Œ� #
-- 2010/01/19 Ver1.15 M.Sano Mod Start
--    iv_file_name  IN  VARCHAR2,              --   �C���^�t�F�[�X�t�@�C����
--    iv_exetype    IN  VARCHAR2               --   ���s�敪�i0�F�V�K�A1�F�Ď��{�j
    iv_file_name      IN  VARCHAR2 DEFAULT NULL,    --   �C���^�t�F�[�X�t�@�C����
    iv_exetype        IN  VARCHAR2 DEFAULT NULL,    --   ���s�敪�i0�F�V�K�A1�F�Ď��{�j
    iv_edi_chain_code IN  VARCHAR2 DEFAULT NULL     --   EDI�`�F�[���X�R�[�h
-- 2010/01/19 Ver1.15 M.Sano Mod End
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
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00039'; -- �x���������b�Z�[�W�i���i�R�[�h�G���[�j
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
       iv_file_name -- �C���^�t�F�[�X�t�@�C����
      ,iv_exetype   -- ���s�敪
-- 2010/01/19 Ver1.15 M.Sano Add Start
      ,iv_edi_chain_code  -- EDI�`�F�[���X�R�[�h
-- 2010/01/19 Ver1.15 M.Sano Add End
      ,lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�����ݒ�
      gn_error_cnt := 1;
--
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
      IF ( lv_errmsg IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
-- 2009/02/24 T.Nakamura Ver.1.1 mod start
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
--
    -- �x���I����
    ELSIF (lv_retcode = cv_status_warn) THEN
--
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
--
    END IF;
--
-- 2009/02/24 T.Nakamura Ver.1.1 mod end
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�x��(���i�G���[)�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/02/24 T.Nakamura Ver.1.1 add start
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/02/24 T.Nakamura Ver.1.1 add end
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
END XXCOS010A01C;
/
