CREATE OR REPLACE PACKAGE BODY XXCOI001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI001A01C(body)
 * Description      : ���Y�����V�X�e������c�ƃV�X�e���ւ̏o�׈˗��f�[�^�̒��o�E�f�[�^�A�g���s��
 * MD.050           : ���ɏ��擾 MD050_COI_001_A01
 * Version          : 1.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_summary_record     ���ɏ��T�}���̒��o(A-2)
 *  get_detail_record      ���ɏ��ڍׂ̒��o(A-3)
 *  get_subinventories     �ۊǏꏊ��񏈗�(A-4)
 *  ins_summary_unconfirmed���ɏ��T�}���̓o�^[���ɖ��m�F](A-5)
 *  ins_summary_confirmed  ���ɏ��T�}���̓o�^[���Ɋm�F��](A-6)
 *  upd_summary_disp       ���ɏ��T�}���̍X�V[�o�׈˗��X�e�[�^�XNULL�Ώ�](A-7)
 *  upd_summary_close      ���ɏ��T�}���̍X�V[�o�׈˗��X�e�[�^�X03�Ώ�](A-8)
 *  upd_summary_results    ���ɏ��T�}���̍X�V[�o�׈˗��X�e�[�^�X04�Ώ�](A-9)
 *  ins_detail_confirmed   ���ɏ��ڍׂ̓o�^(A-10)
 *  upd_detail_close       ���ɏ��ڍׂ̍X�V[�o�׈˗��X�e�[�^�X03�Ώ�](A-11)
 *  upd_detail_results     ���ɏ��ڍׂ̍X�V[�o�׈˗��X�e�[�^�X04�Ώ�](A-12)
 *  upd_order_lines        �󒍖��׃A�h�I���X�V(A-13)
 *  chk_item               �i�ڗL���`�F�b�N(A-15)
 *  chk_summary_data       ���ɏ��T�}�����݊m�F(A-16)
 *  chk_detail_data        ���ɏ��ڍב��݊m�F(A-17)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *  chk_period_status      �݌ɉ�v���ԃ`�F�b�N(A-20)
 *  del_detail_data        �����׍폜����(A-21)
 *  upd_old_data           �����o�ɐ��ʏ���������(A-22)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   S.Moriyama       main�V�K�쐬
 *  2009/03/16    1.1   H.Wada           ��Q�ԍ�T1_0041 get_subinventories
 *                                         �ۊǏꏊ�̗L���`�F�b�N�擾�����ύX
 *  2009/04/02    1.2   T.Nakamura       ��Q�ԍ�T1_0004 get_summary_record, get_detail_record
 *                                         �o�׎��ѐ��ʂ�����2���Ɋۂ߂�悤�ύX
 *  2009/04/16    1.3   H.Sasaki         [T1_0386]�f�[�^���o�����̕ύX�i�z����ԍ��j
 *                                                ���o���̕ύX�i�z����ԍ��j
 *                                       [T1_0387]�f�[�^���o�����̕ύX�i���R�[�h�^�C�v�j
 *  2009/05/01    1.4   T.Nakamura       [T1_0485]�T�}���A�ڍג��o�����̒ǉ��A�ڍׂ̎擾���̕ύX
 *                                                �o�׈˗��X�e�[�^�X04�Ώۂ̃T�}���A�ڍׂ̍X�V���̕ύX
 *  2009/05/14    1.5   H.Sasaki         [T1_0387]���ɏ��ꎞ�\�̑��݃`�F�b�N�������C��
 *  2009/06/03    1.6   H.Sasaki         [T1_1186]�T�}���A���׃J�[�\����PT
 *  2009/07/13    1.7   H.Sasaki         [0000495]���ɏ��T�}�����o�J�[�\����PT�Ή�
 *  2009/09/08    1.8   H.Sasaki         [0001266]OPM�i�ڃA�h�I���̔ŊǗ��Ή�
 *  2009/10/26    1.9   H.Sasaki         [E_T4_00076]�q�ɃR�[�h�̐ݒ���@���C��
 *  2009/11/06    1.10  H.Sasaki         [E_T4_00143]PT�Ή�
 *  2009/11/13    1.11  N.Abe            [E_T4_00189]�i��1���ڂ�5,6�����ނƂ��ď���
 *  2009/12/08    1.12  N.Abe            [E_�{�ғ�_00308,E_�{�ғ�_00312]�폜�f�[�^���������̏C��
 *                                       [E_�{�ғ�_00374]�폜�f�[�^�o�^���@�̏C��
 *  2009/12/14    1.13  H.Sasaki         [E_�{�ғ�_00428]�݌ɉ�v����CLOSE���̏������C��
 *  2009/12/18    1.14  H.Sasaki         [E_�{�ғ�_00524]�`�[���t�Ⴂ�̓��ɏ��ҏW���e���C��
 *  2010/01/04    1.15  H.Sasaki         [E_�{�ғ�_00760]�T�}���f�[�^�̍X�V���@���C��
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
  gn_target_cnt    NUMBER;                                            -- �Ώی���
  gn_normal_cnt    NUMBER;                                            -- ���팏��
  gn_error_cnt     NUMBER;                                            -- �G���[����
  gn_warn_cnt      NUMBER;                                            -- �X�L�b�v����
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
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  subinventory_found_expt   EXCEPTION;                                -- �ۊǏꏊ���݃`�F�b�N�G���[
  subinventory_disable_expt EXCEPTION;                                -- �ۊǏꏊ�L���`�F�b�N�G���[
  subinventory_plural_expt  EXCEPTION;                                -- �ۊǏꏊ�擾�G���[
  item_found_expt           EXCEPTION;                                -- �i�ڑ��݃`�F�b�N�G���[
  item_disable_expt         EXCEPTION;                                -- �i�ڗL���`�F�b�N�G���[
  item_expt                 EXCEPTION;                                -- �i�ڃ`�F�b�N�֐��G���[
  lock_expt                 EXCEPTION;                                -- ���b�N������O
  conv_slip_num_expt        EXCEPTION;                                -- �`�[�ԍ��R���o�[�g�G���[
  period_status_close_expt  EXCEPTION;                                -- �݌ɉ�v���ԃN���[�Y�G���[
  period_status_common_expt EXCEPTION;                                -- �݌ɉ�v���ԗ�O
-- == 2009/10/26 V1.9 Modified START ===============================================================
  main_store_expt           EXCEPTION;                                -- ���C���q�ɋ敪�d���G���[
-- == 2009/10/26 V1.9 Modified END   ===============================================================
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOI001A01C';          -- �p�b�P�[�W��
  cv_application   CONSTANT VARCHAR2(100) := 'XXCOI';                 -- �A�v���P�[�V������
--
  cv_slip_type     CONSTANT VARCHAR2(100) := '10';                    -- �H�����
  cv_y_flag        CONSTANT VARCHAR2(100) := 'Y';                     -- �t���O�l:Y
  cv_n_flag        CONSTANT VARCHAR2(100) := 'N';                     -- �t���O�l:N
  cv_status_flag   CONSTANT VARCHAR2(100) := 'A';                     -- �t���O�l:A
  cv_class_code    CONSTANT VARCHAR2(100) := '1';                     -- �ڋq�敪:1�i���_�j
  cv_hht_kbn       CONSTANT VARCHAR2(100) := '1';                     -- �S�ݓXHHT�敪:1�i�S�ݓX�j
  cv_site_use_code CONSTANT VARCHAR2(100) := 'SHIP_TO';               -- �ڋq���ݒn�g�p�ړI�i�o�א�j
  cv_subinv_class  CONSTANT VARCHAR2(100) := '3';                     -- �ۊǏꏊ�敪:3�i�a����j
  cv_subinv_type   CONSTANT VARCHAR2(100) := '9';                     -- �ۊǏꏊ����:9�i�S�ݓX�a����j
  cv_exclude_type  CONSTANT VARCHAR2(100) := 'XXCOI1_EXCLUDE_ORDER_TYPE';  -- ���O�󒍃^�C�v�R�[�h
  cv_item_category CONSTANT VARCHAR2(100) := 'XXCOI1_ITEM_CATEGORY_CLASS'; -- �i�ڃJ�e�S��
  cv_order_type    CONSTANT VARCHAR2(100) := 'ORDER';                 -- �󒍃^�C�v:ORDER
  cv_return_type   CONSTANT VARCHAR2(100) := 'RETURN';                -- �󒍃^�C�v:RETURN
  cv_0             CONSTANT VARCHAR2(100) := '0';                     -- �R�[�h�Œ�l:0
  cv_1             CONSTANT VARCHAR2(100) := '1';                     -- �R�[�h�Œ�l:1
  cv_2             CONSTANT VARCHAR2(100) := '2';                     -- �R�[�h�Œ�l:2
--
  cv_tkn_pro       CONSTANT VARCHAR2(100) := 'PRO_TOK';
  cv_tkn_org       CONSTANT VARCHAR2(100) := 'ORG_CODE_TOK';
  cv_tkn_base_code CONSTANT VARCHAR2(100) := 'BASE_CODE';
  cv_tkn_warehouse CONSTANT VARCHAR2(100) := 'WAREHOUSE_CODE';
  cv_tkn_item_code CONSTANT VARCHAR2(100) := 'ITEM_CODE';
  cv_tkn_den_no    CONSTANT VARCHAR2(100) := 'DEN_NO';
  cv_tkn_api_nm    CONSTANT VARCHAR2(100) := 'API_NAME';
  cv_tkn_target    CONSTANT VARCHAR2(100) := 'TARGET_DATE';
-- == 2009/10/26 V1.9 Modified START ===============================================================
  cv_token_10379   CONSTANT VARCHAR2(30)  := 'BASE_CODE_TOK';
-- == 2009/10/26 V1.9 Modified END   ===============================================================
--
  -- ���������o��
  cv_prf_org_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_prf_ship_err_msg         CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10168'; -- �o�׈˗��X�e�[�^�X�R�[�h�擾�G���[���b�Z�[�W
  cv_prf_notice_err_msg       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10169'; -- �ʒm�X�e�[�^�X�R�[�h�擾�G���[���b�Z�[�W
  cv_org_id_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_prf_lot_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10343'; -- ���b�g���R�[�h�擾�G���[���b�Z�[�W
  cv_prf_itou_ou_mfg_err_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10338'; -- ���Y�c�ƒP�ʎ擾���̎擾�G���[���b�Z�[�W
--
  -- �f�[�^�`�F�b�N�����o��
  cv_subinventory_found_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10053'; -- �ۊǏꏊ���݃`�F�b�N�G���[
  cv_subinventory_disable_msg CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10238'; -- �ۊǏꏊ�L���`�F�b�N�G���[
  cv_subinventory_plural_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10239'; -- �ۊǏꏊ�擾�G���[
  cv_item_found_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10236'; -- �i�ڑ��݃`�F�b�N�G���[���b�Z�[�W
  cv_item_disable_msg         CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10237'; -- �i�ڗL���`�F�b�N�G���[���b�Z�[�W
  cv_conv_slip_num_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10032'; -- �˗�No�R���o�[�g�G���[���b�Z�[�W
  cv_item_expt_msg            CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00010'; -- API�G���[���b�Z�[�W
  cv_process_date_expt_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_period_status_cmn_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00026'; -- �݌ɉ�v���Ԏ擾�G���[���b�Z�[�W
  cv_period_status_close_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10361'; -- �݌ɉ�v���ԃN���[�Y���b�Z�[�W
-- == 2009/10/26 V1.9 Modified START ===============================================================
  cv_msg_code_10379           CONSTANT VARCHAR2(30)  := 'APP-XXCOI1-10379'; -- ���C���q�ɋ敪�d���G���[���b�Z�[�W
-- == 2009/10/26 V1.9 Modified END   ===============================================================
--
  -- �X�V���o��
  cv_lock_expt_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10029'; -- ���b�N�G���[���b�Z�[�W(���ɏ��ꎞ�\)
  cv_detail_lock_expt_err_msg CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10336'; -- ���b�N�G���[���b�Z�[�W(���ɏ��ꎞ�\)
  cv_lines_lock_expt_msg      CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10031'; -- ���b�N�G���[���b�Z�[�W(�󒍖��׃A�h�I���e�[�u��)
--
  cv_conc_not_parm_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_not_found_slip_msg       CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- �Ώۃf�[�^����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_org_code                 mtl_parameters.organization_code%TYPE;  -- �݌ɑg�D�R�[�h
  gt_org_id                   mtl_parameters.organization_id%TYPE;    -- �݌ɑg�DID
  gt_ship_status_close        xxwsh_order_headers_all.req_status%TYPE;-- �o�׈˗��X�e�[�^�X_���ߍς�
  gt_ship_status_result       xxwsh_order_headers_all.req_status%TYPE;-- �o�׈˗��X�e�[�^�X_�o�׎��ьv���
  gt_ship_status_cancel       xxwsh_order_headers_all.req_status%TYPE;-- �o�׈˗��X�e�[�^�X_���
  gt_notice_status            xxwsh_order_headers_all.notif_status%TYPE;
                                                                      -- �ʒm�X�e�[�^�X_�m��ʒm��
  gt_lot_status_request       xxinv_mov_lot_details.record_type_code%TYPE;
                                                                      -- ���b�g���R�[�h�X�e�[�^�X_�o�׎w��
  gt_lot_status_results       xxinv_mov_lot_details.record_type_code%TYPE;
                                                                      -- ���b�g���R�[�h�X�e�[�^�X_�o�׎���
  gt_org_name                 hr_organization_units.name%TYPE;        -- �c�ƒP�ʖ���
  gt_itou_ou_id               hr_organization_units.organization_id%TYPE;
                                                                      -- �g�DID
  gd_process_date             DATE;                                   -- �Ɩ����t
  gv_slip_num                 VARCHAR2(12);                           -- �`�[No(12���R���o�[�g��)
  gn_summary_cnt              NUMBER;                                 -- �T�}�����R�[�h�擾����
  gn_detail_cnt               NUMBER;                                 -- �ڍ׃��R�[�h�擾����
  gn_slip_cnt                 NUMBER;                                 -- �T�}�����R�[�h�J�E���^
  gn_line_cnt                 NUMBER;                                 -- �ڍ׃��R�[�h�J�E���^
--
  TYPE g_summary_rtype IS RECORD(
      req_status        xxwsh_order_headers_all.req_status%TYPE       -- �o�׎��уX�e�[�^�X
    , result_deliver_to xxwsh_order_headers_all.result_deliver_to%TYPE-- �o�א�_����
    , slip_date         xxwsh_order_headers_all.arrival_date%TYPE     -- �`�[���t
    , req_move_no       xxwsh_order_headers_all.request_no%TYPE       -- �˗�No
    , deliver_from      xxwsh_order_headers_all.deliver_from%TYPE     -- �o�׌��ۊǏꏊ
    , item_no           xxwsh_order_lines_all.request_item_code%TYPE  -- �q�i�ڃR�[�h
    , parent_item_no    ic_item_mst_b.item_no%TYPE                    -- �e�i�ڃR�[�h
    , base_code         hz_cust_accounts.account_number%TYPE          -- ���_�R�[�h
    , delete_flag       xxwsh_order_lines_all.delete_flag%TYPE        -- �폜�t���O
    , dept_hht_div      xxcmm_cust_accounts.dept_hht_div%TYPE         -- �S�ݓX�pHHT�敪
    , deliverly_code    hz_cust_acct_sites_all.attribute18%TYPE       -- �z����R�[�h
    , case_in_qty       ic_item_mst_b.attribute11%TYPE                -- �P�[�X����
    , shipped_qty       xxwsh_order_lines_all.shipped_quantity%TYPE   -- �o�׎��ѐ���
  );
  TYPE g_detail_rtype IS RECORD(
      req_status              xxwsh_order_headers_all.req_status%TYPE -- �o�׎��уX�e�[�^�X
    , result_deliver_to       xxwsh_order_headers_all.result_deliver_to%TYPE
                                                                      -- �o�א�_����
    , slip_date               xxwsh_order_headers_all.arrival_date%TYPE
                                                                      -- �`�[���t
    , req_move_no             xxwsh_order_headers_all.request_no%TYPE -- �˗�No
    , deliver_from            xxwsh_order_headers_all.deliver_from%TYPE
                                                                      -- �o�׌��ۊǏꏊ
    , item_no                 xxwsh_order_lines_all.request_item_code%TYPE
                                                                      -- �q�i�ڃR�[�h
    , parent_item_no          ic_item_mst_b.item_no%TYPE              -- �e�i�ڃR�[�h
    , base_code               hz_cust_accounts.account_number%TYPE    -- ���_�R�[�h
    , delete_flag             xxwsh_order_lines_all.delete_flag%TYPE  -- �폜�t���O
    , dept_hht_div            xxcmm_cust_accounts.dept_hht_div%TYPE   -- �S�ݓX�pHHT�敪
    , deliverly_code          hz_cust_acct_sites_all.attribute18%TYPE -- �z����R�[�h
    , case_in_qty             ic_item_mst_b.attribute11%TYPE          -- �P�[�X����
    , taste_term              ic_lots_mst.attribute3%TYPE             -- �ܖ�����
    , difference_summary_code ic_lots_mst.attribute2%TYPE             -- �ŗL�ԍ�
    , order_header_id         xxwsh_order_lines_all.order_header_id%TYPE
                                                                      -- �󒍃w�b�_ID
    , order_line_id           xxwsh_order_lines_all.order_line_id%TYPE-- �󒍖���ID
    , shipped_qty             xxwsh_order_lines_all.shipped_quantity%TYPE
                                                                      -- �o�׎��ѐ���
  );
--
  TYPE g_summary_ttype IS TABLE OF g_summary_rtype INDEX BY BINARY_INTEGER ;
  g_summary_tab                    g_summary_ttype;
  TYPE g_detail_ttype IS TABLE OF g_detail_rtype INDEX BY BINARY_INTEGER ;
  g_detail_tab                    g_detail_ttype;
--
-- == 2009/12/18 V1.14 Added START ===============================================================
  /**********************************************************************************
   * Procedure Name   : del_detail_data�i���[�v���j
   * Description      : �����׍폜����(A-21)
   ***********************************************************************************/
  PROCEDURE del_detail_data(
      in_slip_cnt   IN NUMBER                                          -- 1.���[�v�J�E���^
    , iv_store_code IN VARCHAR2                                        -- 2.�q�ɃR�[�h
    , ov_errbuf    OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_detail_data';    -- �v���O������
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���׏����폜
    -- ���b�N�����̓T�}�����̍X�V�����Ŏ��{
    DELETE  FROM  xxcoi_storage_information   xsi
    WHERE   xsi.slip_num          = gv_slip_num
    AND     xsi.slip_date         = g_summary_tab ( in_slip_cnt ) .slip_date
    AND     xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
    AND     xsi.warehouse_code    = iv_store_code
    AND     xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
    AND     xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
    AND     xsi.slip_type         = cv_slip_type
    AND     xsi.summary_data_flag = cv_n_flag;
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
  END del_detail_data;
  --
  /**********************************************************************************
   * Procedure Name   : upd_old_data�i���[�v���j
   * Description      : �����o�ɐ��ʏ���������(A-22)
   ***********************************************************************************/
  PROCEDURE upd_old_data(
      in_slip_cnt   IN NUMBER                                          -- 1.���[�v�J�E���^
    , iv_store_code IN VARCHAR2                                        -- 2.�q�ɃR�[�h
    , ov_errbuf    OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_old_data';    -- �v���O������
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
    CURSOR  old_data_lock_cur
    IS
      SELECT  1
      FROM    xxcoi_storage_information     xsi
      WHERE   xsi.slip_num          = gv_slip_num
      AND     xsi.slip_date        <> g_summary_tab ( in_slip_cnt ) .slip_date
      AND     xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
      AND     xsi.warehouse_code    = iv_store_code
      AND     xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
      AND     xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
      AND     xsi.slip_type         = cv_slip_type
      FOR UPDATE NOWAIT;

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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    OPEN  old_data_lock_cur;
    --
    IF (old_data_lock_cur%NOTFOUND) THEN
      NULL;
    ELSE
      -- ����̓`�[�ԍ��A�i�ڂœ`�[���t�̈قȂ�f�[�^�����݂���ꍇ
      -- �قȂ�`�[���t�̏o�א��ʁi�P�[�X�A�o���A���o���j��������
      UPDATE  xxcoi_storage_information   xsi
      SET     ship_case_qty           =   0
             ,ship_singly_qty         =   0
             ,ship_summary_qty        =   0
             ,last_updated_by         = cn_last_updated_by
             ,last_update_date        = SYSDATE
             ,last_update_login       = cn_last_update_login
             ,request_id              = cn_request_id
             ,program_application_id  = cn_program_application_id
             ,program_id              = cn_program_id
             ,program_update_date     = SYSDATE
      WHERE   xsi.slip_num          = gv_slip_num
      AND     xsi.slip_date        <> g_summary_tab ( in_slip_cnt ) .slip_date
      AND     xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
      AND     xsi.warehouse_code    = iv_store_code
      AND     xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
      AND     xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
      AND     xsi.slip_type         = cv_slip_type;
    END IF;
    --
    CLOSE old_data_lock_cur;
    --
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( old_data_lock_cur%ISOPEN ) THEN
        CLOSE old_data_lock_cur;
      END IF;
--
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_lock_expt_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
      ROLLBACK TO SAVEPOINT summary_point;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( old_data_lock_cur%ISOPEN ) THEN
        CLOSE old_data_lock_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( old_data_lock_cur%ISOPEN ) THEN
        CLOSE old_data_lock_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( old_data_lock_cur%ISOPEN ) THEN
        CLOSE old_data_lock_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_old_data;
-- == 2009/12/18 V1.14 Added END   ===============================================================
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf    OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                   -- �v���O������
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
    cv_prf_org                CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE';
                                                                      -- XXCOI:�݌ɑg�D�R�[�h
    cv_prf_ship_status_close  CONSTANT VARCHAR2(100) := 'XXCOI1_SHIP_STATUS_CLOSE';
                                                                      -- XXCOI:�o�׈˗��X�e�[�^�X_���ߍς�
    cv_prf_ship_status_result CONSTANT VARCHAR2(100) := 'XXCOI1_SHIP_STATUS_RESULTS';
                                                                      -- XXCOI:�o�׈˗��X�e�[�^�X_�o�׎��ьv���
    cv_prf_ship_status_cancel CONSTANT VARCHAR2(100) := 'XXCOI1_SHIP_STATUS_CANCEL';
                                                                      -- XXCOI:�o�׈˗��X�e�[�^�X_���
    cv_prf_notice_status      CONSTANT VARCHAR2(100) := 'XXCOI1_NOTICE_STATUS_CLOSE';
                                                                      -- XXCOI:�ʒm�X�e�[�^�X_�m��ʒm��
    cv_prf_lot_status_request CONSTANT VARCHAR2(100) := 'XXCOI1_LOT_STATUS_REQUEST';
                                                                      -- XXCOI:���b�g���R�[�h�X�e�[�^�X_�o�׎w��
    cv_prf_lot_status_results CONSTANT VARCHAR2(100) := 'XXCOI1_LOT_STATUS_RESULTS';
                                                                      -- XXCOI:���b�g���R�[�h�X�e�[�^�X_�o�׎���
    cv_prf_itou_ou_mfg        CONSTANT VARCHAR2(100) := 'XXCOI1_ITOE_OU_MFG';
                                                                      -- XXCOI:���Y�c�ƒP�ʎ擾����
    cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';      -- �A�h�I���F���ʁEIF�̈�
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�R���J�����g�p�����[�^�o�́i�Ȃ��j
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name
                    , iv_name        => cv_conc_not_parm_msg
                  );
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    fnd_file.put_line(
       which => fnd_file.log
      ,buff  => gv_out_msg
    );
    fnd_file.put_line(
        which  => fnd_file.output
      , buff   => ''
    );
    -- ��s�o��
    fnd_file.put_line(
        which  => fnd_file.log
      , buff   => ''
    );
--
    --==============================================================
    --�v���t�@�C�����݌ɑg�D�R�[�h�擾
    --==============================================================
    gt_org_code := fnd_profile.value( cv_prf_org );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_org_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C�����o�׈˗��X�e�[�^�X_���ߍςݎ擾
    --==============================================================
    gt_ship_status_close := fnd_profile.value( cv_prf_ship_status_close );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_ship_status_close IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_ship_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_ship_status_close
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C�����o�׈˗��X�e�[�^�X_�o�׎��ьv��ώ擾
    --==============================================================
    gt_ship_status_result := fnd_profile.value( cv_prf_ship_status_result );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_ship_status_result IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_ship_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_ship_status_result
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C�����o�׈˗��X�e�[�^�X_���
    --==============================================================
    gt_ship_status_cancel := fnd_profile.value( cv_prf_ship_status_cancel );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_ship_status_cancel IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_ship_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_ship_status_cancel
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C�����ʒm�X�e�[�^�X_�m��ʒm�ώ擾
    --==============================================================
    gt_notice_status := fnd_profile.value( cv_prf_notice_status );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_notice_status IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_notice_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_notice_status
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C����胍�b�g���R�[�h�X�e�[�^�X_�o�׎w���擾
    --==============================================================
    gt_lot_status_request := fnd_profile.value( cv_prf_lot_status_request );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_lot_status_request IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_lot_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_lot_status_request
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C����胍�b�g���R�[�h�X�e�[�^�X_�o�׎��ю擾
    --==============================================================
    gt_lot_status_results := fnd_profile.value( cv_prf_lot_status_results );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_lot_status_results IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_lot_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_lot_status_results
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C����萶�Y�c�ƒP�ʎ擾����
    --==============================================================
    gt_org_name := fnd_profile.value( cv_prf_itou_ou_mfg );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_org_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_prf_itou_ou_mfg_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_itou_ou_mfg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      BEGIN
        SELECT hou.organization_id
        INTO   gt_itou_ou_id
        FROM   hr_organization_units hou
        WHERE  hou.name = gt_org_name;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_prf_itou_ou_mfg_err_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_prf_itou_ou_mfg
                     );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    END IF;
--
    --==============================================================
    --���ʊ֐����݌ɑg�DID�擾
    --==============================================================
    gt_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => gt_org_code
                 );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_org_id_err_msg
                     , iv_token_name1  => cv_tkn_org
                     , iv_token_value1 => gt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���ʊ֐����Ɩ����t�擾
    --==============================================================
    gd_process_date := TRUNC(xxccp_common_pkg2.get_process_date);
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application
                     , iv_name        => cv_process_date_expt_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_summary_record
   * Description      : ���ɏ��T�}���̒��o(A-2)
   ***********************************************************************************/
  PROCEDURE get_summary_record(
      ov_errbuf    OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_summary_record';     -- �v���O������
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
    -- ���ɏ��T�}���̒��o
    CURSOR summary_cur
    IS
-- == 2009/06/03 V1.6 Modified START ===============================================================
--      SELECT  xoha.req_status                  AS req_status          -- �o�׈˗��X�e�[�^�X
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                xoha.result_deliver_to ELSE xoha.deliver_to END
--                                               AS result_deliver_to   -- �o�א�_����
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                xoha.arrival_date ELSE xoha.schedule_arrival_date END
--                                               AS arrive_date         -- �`�[���t
--            , xoha.request_no                  AS req_move_no         -- �˗�No
--            , xoha.deliver_from                AS deliver_from        -- �o�׌��ۊǏꏊ
--            , xola.request_item_code           AS item_no             -- �q�i�ڃR�[�h
--            , imbp.item_no                     AS parent_item_no      -- �e�i�ڃR�[�h
--            , hca.account_number               AS base_code           -- ���_�R�[�h
--            , xola.delete_flag                 AS delete_flag         -- �폜�t���O
--            , xca.dept_hht_div                 AS dept_hht_div        -- �S�ݓX�pHHT�敪
---- == 2009/04/16 V1.3 Modified START ===============================================================
----            , hcasa.attribute18                AS deliverly_code      -- �z����R�[�h
--            , hl.province                      AS deliverly_code
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--            , imbc.attribute11                 AS case_in_qty         -- �P�[�X����
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                CASE WHEN otta.order_category_code = cv_order_type THEN
---- == 2009/04/02 V1.2 Moded START ===============================================================
----                  SUM(xola.shipped_quantity)
--                  SUM( ROUND( xola.shipped_quantity, 2 ) )
---- == 2009/04/02 V1.2 Moded END   ===============================================================
--                     WHEN otta.order_category_code = cv_return_type THEN
---- == 2009/04/02 V1.2 Moded START ===============================================================
----                  SUM(xola.shipped_quantity) * -1
--                  SUM( ROUND( xola.shipped_quantity, 2 ) * -1 )
---- == 2009/04/02 V1.2 Moded END   ===============================================================
--                END
--              ELSE
--                CASE WHEN otta.order_category_code = cv_order_type THEN
---- == 2009/04/02 V1.2 Moded START ===============================================================
----                  SUM(xola.quantity)
--                  SUM( ROUND( xola.quantity, 2 ) )
---- == 2009/04/02 V1.2 Moded END   ===============================================================
--                     WHEN otta.order_category_code = cv_return_type THEN
---- == 2009/04/02 V1.2 Moded START ===============================================================
----                  SUM(xola.quantity) * -1
--                  SUM( ROUND( xola.quantity, 2 ) * -1 )
---- == 2009/04/02 V1.2 Moded END   ===============================================================
--                END
--              END                              AS shipped_quantity    -- �o�׎��ѐ���
--      FROM    xxwsh_order_headers_all          xoha                   -- �󒍃w�b�_�A�h�I��
--            , xxwsh_order_lines_all            xola                   -- �󒍖��׃A�h�I��
--            , ic_item_mst_b                    imbc                   -- OPM�i�ڃ}�X�^�i�q�j
--            , ic_item_mst_b                    imbp                   -- OPM�i�ڃ}�X�^�i�e�j
--            , xxcmn_item_mst_b                 ximb                   -- OPM�i�ڃA�h�I���}�X�^
--            , mtl_system_items_b               msib                   -- Disc�i�ڃ}�X�^
--            , hz_party_sites                   hps                    -- �p�[�e�B�T�C�g�}�X�^
--            , hz_cust_accounts                 hca                    -- �ڋq�}�X�^
--            , hz_cust_acct_sites_all           hcasa                  -- �ڋq���ݒn�}�X�^
--            , hz_cust_site_uses_all            hcaua                  -- �ڋq�g�p�ړI�}�X�^
--            , xxcmm_cust_accounts              xca                    -- �ڋq�ǉ����
--            , oe_transaction_types_all         otta                   -- �󒍃^�C�v�}�X�^
--            , oe_transaction_types_tl          ottt
---- == 2009/04/16 V1.3 Added START ===============================================================
--            ,hz_locations                      hl                     -- ���Ə��}�X�^
---- == 2009/04/16 V1.3 Added END   ===============================================================
--      WHERE  xoha.order_header_id = xola.order_header_id
--      AND    xola.request_item_id = msib.inventory_item_id
--      AND    imbc.item_no         = msib.segment1
--      AND    imbc.item_id         = ximb.item_id
--      AND    imbp.item_id         = ximb.parent_item_id
--      AND    msib.organization_id = gt_org_id
--      AND ( ( -- ���ߍς݁A�m��ʒm�Ϗo�׈˗��i�o�׈˗��͍폜���ׂ����O�j
--              xoha.req_status                          = gt_ship_status_close
--              AND xoha.notif_status                    = gt_notice_status
--              AND NVL(xola.delete_flag,cv_n_flag)      = cv_n_flag
--              AND xola.shipping_request_if_flg         = cv_n_flag
--              AND xola.shipping_result_if_flg          = cv_n_flag
--              AND xoha.deliver_to_id                   = hps.party_site_id
--            )
--         OR ( -- �o�׎��ьv��Ϗo�׎��сi�o�׎��т͍폜���ׂ����O�A�������o�׈˗��A�g�ς͑Ώہj
--              (xoha.actual_confirm_class               = cv_y_flag
--              AND xoha.result_deliver_to_id            = hps.party_site_id)
--              AND(( xoha.req_status                    = gt_ship_status_result
--                   AND NVL(xola.delete_flag,cv_n_flag) = cv_n_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
--                  )
--              OR ( xoha.req_status                     = gt_ship_status_result
--                   AND xola.delete_flag                = cv_y_flag
--                   AND xola.shipping_request_if_flg    = cv_y_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
--                 ))
--            )
--         OR ( -- �o�׈˗��A�g�ςɑ΂��Ď�����s�������̂͑Ώ�
--              xoha.req_status                                       = gt_ship_status_cancel
--              AND NVL(xoha.deliver_to_id,xoha.result_deliver_to_id) = hps.party_site_id
--              AND xola.shipping_request_if_flg                      = cv_y_flag
--              AND xola.shipping_result_if_flg                       = cv_n_flag
--              AND xola.delete_flag                                  = cv_y_flag
--            )
--          )
--      AND     otta.attribute1             = cv_1
--      AND     NVL ( otta.attribute4 , cv_1 ) <> cv_2
--      AND     otta.org_id                 = gt_itou_ou_id
--      AND     otta.transaction_type_id    = ottt.transaction_type_id
--      AND     ottt.language               = USERENV('LANG')
--      AND NOT EXISTS ( SELECT   '1'
--                       FROM     fnd_lookup_values flv
--                              , fnd_lookup_types flt
--                       WHERE    flt.lookup_type = cv_exclude_type
--                       AND      flt.lookup_type = flv.lookup_type
--                       AND      flv.enabled_flag = cv_y_flag
--                       AND      flv.language = USERENV('LANG')
--                       AND      gd_process_date BETWEEN flv.start_date_active AND NVL ( flv.end_date_active , gd_process_date )
--                       AND      ottt.name = flv.meaning
--                     )
--      AND     xoha.order_type_id          = ottt.transaction_type_id
--      AND     hps.party_id                = hca.party_id
--      AND     hca.cust_account_id         = hcasa.cust_account_id
--      AND     hcasa.cust_acct_site_id     = hcaua.cust_acct_site_id
--      AND     hcaua.site_use_code         = cv_site_use_code
--      AND     hcaua.status                = cv_status_flag
--      AND     hcaua.primary_flag          = cv_y_flag
--      AND     hca.cust_account_id         = xca.customer_id
--      AND     hca.customer_class_code     = cv_class_code
--      AND     hca.status                  = cv_status_flag
---- == 2009/04/16 V1.3 Modified START ===============================================================
----      AND     SUBSTRB ( hcasa.attribute18 , 1 , 1 ) = cv_0
--      AND     hps.location_id             = hl.location_id
--      AND     SUBSTRB(hl.province, 1, 1)  = cv_0
---- == 2009/04/16 V1.3 Modified END   ===============================================================
---- == 2009/05/01 V1.4 Added START ==================================================================
--      AND     xoha.latest_external_flag   = cv_y_flag
---- == 2009/05/01 V1.4 Added END   ==================================================================
--      GROUP BY  xoha.req_status
--              , xoha.request_no
--              , hca.account_number
--              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                     xoha.result_deliver_to ELSE xoha.deliver_to END
--              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                   xoha.arrival_date ELSE xoha.schedule_arrival_date END
--              , xoha.deliver_from
--              , xola.request_item_code
--              , imbp.item_no
--              , xola.delete_flag
--              , xca.dept_hht_div
---- == 2009/04/16 V1.3 Modified START ===============================================================
----            , hcasa.attribute18
--              , hl.province
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--              , imbc.attribute11
--              , otta.order_category_code
--      ORDER BY  xoha.req_status
--              , xoha.request_no
--              , hca.account_number
--              , xola.request_item_code
--              , imbp.item_no
--      ;
--
      SELECT
-- == 2009/07/13 V1.7 Added START ===============================================================
              /*+ leading(ottt otta xoha xola) use_nl(xoha xola msib imbc imbp ximb hps hl) */
-- == 2009/07/13 V1.7 Added END   ===============================================================
              xoha.req_status                  AS req_status          -- �o�׈˗��X�e�[�^�X
            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
                xoha.result_deliver_to ELSE xoha.deliver_to END
                                               AS result_deliver_to   -- �o�א�_����
            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
                xoha.arrival_date ELSE xoha.schedule_arrival_date END
                                               AS arrive_date         -- �`�[���t
            , xoha.request_no                  AS req_move_no         -- �˗�No
            , xoha.deliver_from                AS deliver_from        -- �o�׌��ۊǏꏊ
            , xola.request_item_code           AS item_no             -- �q�i�ڃR�[�h
            , imbp.item_no                     AS parent_item_no      -- �e�i�ڃR�[�h
            , hca.account_number               AS base_code           -- ���_�R�[�h
-- == 2009/12/08 V1.12 Modified START ===============================================================
--            , xola.delete_flag                 AS delete_flag         -- �폜�t���O
            , NVL(xola.delete_flag,cv_n_flag)  AS delete_flag         -- �폜�t���O
-- == 2009/12/08 V1.12 Modified END   ===============================================================
            , xca.dept_hht_div                 AS dept_hht_div        -- �S�ݓX�pHHT�敪
            , hl.province                      AS deliverly_code
            , imbc.attribute11                 AS case_in_qty         -- �P�[�X����
-- == 2009/12/18 V1.14 Modified START ===============================================================
--             , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                 CASE WHEN otta.order_category_code = cv_order_type THEN
--                   SUM( ROUND( xola.shipped_quantity, 2 ) )
--                      WHEN otta.order_category_code = cv_return_type THEN
--                   SUM( ROUND( xola.shipped_quantity, 2 ) * -1 )
--                 END
--               ELSE
--                 CASE WHEN otta.order_category_code = cv_order_type THEN
--                   SUM( ROUND( xola.quantity, 2 ) )
--                      WHEN otta.order_category_code = cv_return_type THEN
--                   SUM( ROUND( xola.quantity, 2 ) * -1 )
--                 END
--               END                              AS shipped_quantity    -- �o�׎��ѐ���
            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
                CASE WHEN otta.order_category_code = cv_order_type THEN
                  SUM( ROUND( NVL(xola.shipped_quantity, 0), 2 ) )
                     WHEN otta.order_category_code = cv_return_type THEN
                  SUM( ROUND( NVL(xola.shipped_quantity, 0), 2 ) * -1 )
                END
              ELSE
                CASE WHEN otta.order_category_code = cv_order_type THEN
                  SUM( ROUND( NVL(xola.quantity, 0), 2 ) )
                     WHEN otta.order_category_code = cv_return_type THEN
                  SUM( ROUND( NVL(xola.quantity, 0), 2 ) * -1 )
                END
              END                              AS shipped_quantity    -- �o�׎��ѐ���
-- == 2009/12/18 V1.14 Modified END   ===============================================================
      FROM    xxwsh_order_headers_all          xoha                   -- �󒍃w�b�_�A�h�I��
            , xxwsh_order_lines_all            xola                   -- �󒍖��׃A�h�I��
            , ic_item_mst_b                    imbc                   -- OPM�i�ڃ}�X�^�i�q�j
            , ic_item_mst_b                    imbp                   -- OPM�i�ڃ}�X�^�i�e�j
            , xxcmn_item_mst_b                 ximb                   -- OPM�i�ڃA�h�I���}�X�^
            , mtl_system_items_b               msib                   -- Disc�i�ڃ}�X�^
            , hz_party_sites                   hps                    -- �p�[�e�B�T�C�g�}�X�^
            , hz_cust_accounts                 hca                    -- �ڋq�}�X�^
            , xxcmm_cust_accounts              xca                    -- �ڋq�ǉ����
            , oe_transaction_types_all         otta                   -- �󒍃^�C�v�}�X�^
            , oe_transaction_types_tl          ottt
            ,hz_locations                      hl                     -- ���Ə��}�X�^
      WHERE  xoha.order_header_id   =   xola.order_header_id
      AND    xola.request_item_id   =   msib.inventory_item_id
      AND    imbc.item_no           =   msib.segment1
      AND    imbc.item_id           =   ximb.item_id
      AND    imbp.item_id           =   ximb.parent_item_id
-- == 2009/09/08 V1.8 Added START ===============================================================
      AND    ((xoha.req_status = gt_ship_status_result
               AND
               xoha.arrival_date BETWEEN ximb.start_date_active
                                 AND     NVL(ximb.end_date_active, xoha.arrival_date)
              )
              OR
              (xoha.req_status <> gt_ship_status_result
               AND
               xoha.schedule_arrival_date BETWEEN ximb.start_date_active
                                          AND     NVL(ximb.end_date_active, xoha.schedule_arrival_date)
              )
             )
-- == 2009/09/08 V1.8 Added END   ===============================================================
      AND    msib.organization_id   =   gt_org_id
      AND ( ( -- ���ߍς݁A�m��ʒm�Ϗo�׈˗��i�o�׈˗��͍폜���ׂ����O�j
              xoha.req_status                          = gt_ship_status_close
              AND xoha.notif_status                    = gt_notice_status
              AND NVL(xola.delete_flag,cv_n_flag)      = cv_n_flag
-- == 2009/12/08 V1.12 Modified START ===============================================================
--              AND xola.shipping_request_if_flg         = cv_n_flag
--              AND xola.shipping_result_if_flg          = cv_n_flag
              AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_n_flag
              AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
              AND xoha.deliver_to_id                   = hps.party_site_id
            )
         OR ( -- �o�׎��ьv��Ϗo�׎��сi�o�׎��т͍폜���ׂ����O�A�������o�׈˗��A�g�ς͑Ώہj
              (xoha.actual_confirm_class               = cv_y_flag
              AND xoha.result_deliver_to_id            = hps.party_site_id)
              AND(( xoha.req_status                    = gt_ship_status_result
                   AND NVL(xola.delete_flag,cv_n_flag) = cv_n_flag
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                   AND xola.shipping_result_if_flg     = cv_n_flag
                   AND NVL(xola.shipping_result_if_flg,cv_n_flag) = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                  )
              OR ( xoha.req_status                     = gt_ship_status_result
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                   AND xola.delete_flag                = cv_y_flag
--                   AND xola.shipping_request_if_flg    = cv_y_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
                   AND NVL(xola.delete_flag,cv_n_flag)             = cv_y_flag
                   AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_y_flag
                   AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                 ))
            )
         OR ( -- �o�׈˗��A�g�ςɑ΂��Ď�����s�������̂͑Ώ�
              xoha.req_status                                       = gt_ship_status_cancel
              AND NVL(xoha.deliver_to_id,xoha.result_deliver_to_id) = hps.party_site_id
-- == 2009/12/08 V1.12 Modified START ===============================================================
--              AND xola.shipping_request_if_flg                      = cv_y_flag
--              AND xola.shipping_result_if_flg                       = cv_n_flag
--              AND xola.delete_flag                                  = cv_y_flag
              AND NVL(xola.shipping_request_if_flg,cv_n_flag)       = cv_y_flag
              AND NVL(xola.shipping_result_if_flg,cv_n_flag)        = cv_n_flag
              AND NVL(xola.delete_flag,cv_n_flag)                   = cv_y_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
            )
          )
      AND     otta.attribute1             = cv_1
      AND     NVL(otta.attribute4, cv_1) <> cv_2
      AND     otta.org_id                 = gt_itou_ou_id
      AND     otta.transaction_type_id    = ottt.transaction_type_id
      AND     ottt.language               = USERENV('LANG')
      AND NOT EXISTS ( SELECT   '1'
                       FROM     fnd_lookup_values flv
                       WHERE    flv.lookup_type   = cv_exclude_type
                       AND      flv.enabled_flag  = cv_y_flag
                       AND      flv.language      = USERENV('LANG')
                       AND      gd_process_date BETWEEN flv.start_date_active AND NVL ( flv.end_date_active , gd_process_date )
                       AND      ottt.name         = flv.meaning
                     )
      AND     xoha.order_type_id          = ottt.transaction_type_id
      AND     hps.party_id                = hca.party_id
      AND     hca.cust_account_id         = xca.customer_id
      AND     hca.customer_class_code     = cv_class_code
      AND     hca.status                  = cv_status_flag
      AND     hps.location_id             = hl.location_id
      AND     SUBSTRB(hl.province, 1, 1)  = cv_0
      AND     xoha.latest_external_flag   = cv_y_flag
      GROUP BY  xoha.req_status
              , xoha.request_no
              , hca.account_number
              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
                     xoha.result_deliver_to ELSE xoha.deliver_to END
              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
                   xoha.arrival_date ELSE xoha.schedule_arrival_date END
              , xoha.deliver_from
              , xola.request_item_code
              , imbp.item_no
-- == 2009/12/08 V1.12 Modified START ===============================================================
--              , xola.delete_flag
              , NVL(xola.delete_flag,cv_n_flag)
-- == 2009/12/08 V1.12 Modified END   ===============================================================
              , xca.dept_hht_div
              , hl.province
              , imbc.attribute11
              , otta.order_category_code
      ORDER BY  xoha.req_status
              , xoha.request_no
              , hca.account_number
              , xola.request_item_code
              , imbp.item_no
-- == 2009/12/08 V1.12 Modified START ===============================================================
              , NVL(xola.delete_flag,cv_n_flag) DESC
-- == 2009/12/08 V1.12 Modified END   ===============================================================
      ;
-- == 2009/06/03 V1.6 Modified END   ===============================================================
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
    -- �J�[�\���I�[�v��
    OPEN summary_cur;
    FETCH summary_cur BULK COLLECT INTO g_summary_tab;
--
    -- �Ώۏ�������
    gn_target_cnt := g_summary_tab.COUNT;
    -- �T�}���J�E���g�Z�b�g
    gn_summary_cnt := g_summary_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE summary_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( summary_cur%ISOPEN ) THEN
        CLOSE summary_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( summary_cur%ISOPEN ) THEN
        CLOSE summary_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( summary_cur%ISOPEN ) THEN
        CLOSE summary_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_summary_record;
--
  /**********************************************************************************
   * Procedure Name   : get_detail_record
   * Description      : ���ɏ��ڍׂ̒��o(A-3)
   ***********************************************************************************/
  PROCEDURE get_detail_record(
      in_slip_cnt   IN NUMBER                                         -- ���[�v�J�E���^
    , ov_errbuf    OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_detail_record';      -- �v���O������
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
    -- ���ɏ��ڍׂ̒��o
    CURSOR detail_cur(
      g_summary_tab g_summary_ttype )
    IS
-- == 2009/06/03 V1.6 Modified START ===============================================================
--      SELECT  xoha.req_status                  AS req_status          -- �o�׈˗��X�e�[�^�X
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                xoha.result_deliver_to ELSE xoha.deliver_to END
--                                               AS result_deliver_to   -- �o�א�_����
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                xoha.arrival_date ELSE xoha.schedule_arrival_date END
--                                               AS arrive_date         -- �`�[���t
--            , xoha.request_no                  AS req_move_no         -- �˗�No
--            , xoha.deliver_from                AS deliver_from        -- �o�׌��ۊǏꏊ
--            , xola.request_item_code           AS item_no             -- �q�i�ڃR�[�h
--            , imbp.item_no                     AS parent_item_no      -- �e�i�ڃR�[�h
--            , hca.account_number               AS base_code           -- ���_�R�[�h
--            , xola.delete_flag                 AS delete_flag         -- �폜�t���O
--            , xca.dept_hht_div                 AS dept_hht_div        -- �S�ݓX�pHHT�敪
---- == 2009/04/16 V1.3 Modified START ===============================================================
----            , hcasa.attribute18                AS deliverly_code      -- �z����R�[�h
--            , hl.province                      AS deliverly_code
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--            , imbc.attribute11                 AS case_in_qty         -- �P�[�X����
--            , ilm.attribute3                   AS taste_term          -- �ܖ�����
--            , ilm.attribute2                   AS difference_summary_code
--                                                                      -- �ŗL�L��
--            , xola.order_header_id             AS order_header_id     -- �󒍃w�b�_ID
--            , xola.order_line_id               AS order_line_id       -- �󒍖���ID
---- == 2009/05/01 V1.4 Modified START ===============================================================
----            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
----                CASE WHEN otta.order_category_code = cv_order_type THEN
------ == 2009/04/02 V1.2 Moded START ===============================================================
------                  SUM(xola.shipped_quantity)
----                  SUM( ROUND( xola.shipped_quantity, 2 ) )
------ == 2009/04/02 V1.2 Moded END   ===============================================================
----                     WHEN otta.order_category_code = cv_return_type THEN
------ == 2009/04/02 V1.2 Moded START ===============================================================
------                  SUM(xola.shipped_quantity) * -1
----                  SUM( ROUND( xola.shipped_quantity, 2 ) * -1 )
------ == 2009/04/02 V1.2 Moded END   ===============================================================
----                END
----              ELSE
----                CASE WHEN otta.order_category_code = cv_order_type THEN
------ == 2009/04/02 V1.2 Moded START ===============================================================
------                  SUM(xola.quantity)
----                  SUM( ROUND( xola.quantity, 2 ) )
------ == 2009/04/02 V1.2 Moded END   ===============================================================
----                     WHEN otta.order_category_code = cv_return_type THEN
------ == 2009/04/02 V1.2 Moded START ===============================================================
------                  SUM(xola.quantity) * -1
----                  SUM( ROUND( xola.quantity, 2 ) * -1 )
------ == 2009/04/02 V1.2 Moded END   ===============================================================
----                END
--            , CASE WHEN otta.order_category_code = cv_order_type THEN
--                SUM( ROUND( xmld.actual_quantity, 2 ) )
--                   WHEN otta.order_category_code = cv_return_type THEN
--                SUM( ROUND( xmld.actual_quantity, 2 ) * -1 )
---- == 2009/05/01 V1.4 Modified END   ===============================================================
--              END                              AS shipped_quantity    -- �o�׎��ѐ���
--      FROM    xxwsh_order_headers_all          xoha                   -- �󒍃w�b�_�A�h�I��
--            , xxwsh_order_lines_all            xola                   -- �󒍖��׃A�h�I��
--            , ic_item_mst_b                    imbc                   -- OPM�i�ڃ}�X�^�i�q�j
--            , ic_item_mst_b                    imbp                   -- OPM�i�ڃ}�X�^�i�e�j
--            , xxcmn_item_mst_b                 ximb                   -- OPM�i�ڃA�h�I���}�X�^
--            , mtl_system_items_b               msib                   -- Disc�i�ڃ}�X�^
--            , hz_party_sites                   hps                    -- �p�[�e�B�T�C�g�}�X�^
--            , hz_cust_accounts                 hca                    -- �ڋq�}�X�^
--            , hz_cust_acct_sites_all           hcasa                  -- �ڋq���ݒn�}�X�^
--            , hz_cust_site_uses_all            hcaua                  -- �ڋq�g�p�ړI�}�X�^
--            , xxcmm_cust_accounts              xca                    -- �ڋq�ǉ����
--            , xxinv_mov_lot_details            xmld                   -- �ړ����b�g�ڍ�(�A�h�I��)
--            , ic_lots_mst                      ilm                    -- OPM���b�g�}�X�^
--            , oe_transaction_types_all         otta                   -- �󒍃^�C�v�}�X�^
--            , oe_transaction_types_tl          ottt
---- == 2009/04/16 V1.3 Added START ===============================================================
--            , hz_locations                     hl                     -- ���Ə��}�X�^
---- == 2009/04/16 V1.3 Added END   ===============================================================
--      WHERE   xoha.order_header_id = xola.order_header_id
--      AND     xola.request_item_id = msib.inventory_item_id
--      AND     imbc.item_no         = msib.segment1
--      AND     imbc.item_id         = ximb.item_id
--      AND     imbp.item_id         = ximb.parent_item_id
--      AND     msib.organization_id = gt_org_id
--      AND ( ( -- ���ߍς݁A�m��ʒm�Ϗo�׈˗��i�o�׈˗��͍폜���ׂ����O�j
--              xoha.req_status                          = gt_ship_status_close
--              AND xoha.notif_status                    = gt_notice_status
--              AND NVL(xola.delete_flag,cv_n_flag)      = cv_n_flag
--              AND xola.shipping_request_if_flg         = cv_n_flag
--              AND xola.shipping_result_if_flg          = cv_n_flag
--              AND xoha.deliver_to_id                   = hps.party_site_id
--            )
--         OR ( -- �o�׎��ьv��Ϗo�׎��сi�o�׎��т͍폜���ׂ����O�A�������o�׈˗��A�g�ς͑Ώہj
--              (xoha.actual_confirm_class               = cv_y_flag
--              AND xoha.result_deliver_to_id            = hps.party_site_id)
--              AND(( xoha.req_status                    = gt_ship_status_result
--                   AND NVL(xola.delete_flag,cv_n_flag) = cv_n_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
--                  )
--              OR ( xoha.req_status                     = gt_ship_status_result
--                   AND xola.delete_flag                = cv_y_flag
--                   AND xola.shipping_request_if_flg    = cv_y_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
--                 ))
--            )
--         OR ( -- �o�׈˗��A�g�ςɑ΂��Ď�����s�������̂͑Ώ�
--              xoha.req_status                                       = gt_ship_status_cancel
--              AND NVL(xoha.deliver_to_id,xoha.result_deliver_to_id) = hps.party_site_id
--              AND xola.shipping_request_if_flg                      = cv_y_flag
--              AND xola.shipping_result_if_flg                       = cv_n_flag
--              AND xola.delete_flag                                  = cv_y_flag
--            )
--          )
--      AND     otta.attribute1             = cv_1
--      AND     NVL ( otta.attribute4 , cv_1 ) <> cv_2
--      AND     otta.org_id                 = gt_itou_ou_id
--      AND     otta.transaction_type_id    = ottt.transaction_type_id
--      AND     ottt.language               = USERENV('LANG')
--      AND     xoha.order_type_id          = ottt.transaction_type_id
--      AND     hps.party_id                = hca.party_id
--      AND     hca.cust_account_id         = hcasa.cust_account_id
--      AND     hcasa.cust_acct_site_id     = hcaua.cust_acct_site_id
--      AND     hcaua.site_use_code         = cv_site_use_code
--      AND     hcaua.status                = cv_status_flag
--      AND     hcaua.primary_flag          = cv_y_flag
--      AND     hca.cust_account_id         = xca.customer_id
--      AND     hca.customer_class_code     = cv_class_code
--      AND     hca.status                  = cv_status_flag
---- == 2009/04/16 V1.3 Modified START ===============================================================
----      AND     SUBSTRB ( hcasa.attribute18 , 1 , 1 ) = cv_0
--      AND     hps.location_id             = hl.location_id
--      AND     SUBSTRB(hl.province, 1, 1)  = cv_0
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--      AND     xola.order_line_id          = xmld.mov_line_id(+)
--      AND     xmld.lot_id                 = ilm.lot_id(+)
--      AND     xmld.item_id                = ilm.item_id(+)
--      AND     xoha.req_status             = g_summary_tab ( in_slip_cnt ) .req_status
--      AND     xoha.request_no             = g_summary_tab ( in_slip_cnt ) .req_move_no
--      AND     xoha.deliver_from           = g_summary_tab ( in_slip_cnt ) .deliver_from
--      AND     xola.request_item_code      = g_summary_tab ( in_slip_cnt ) .item_no
--      AND ( (
--              xoha.req_status                IN ( gt_ship_status_close , gt_ship_status_cancel )
---- == 2009/04/16 V1.3 Modified START ===============================================================
----              AND xmld.record_type_code      = gt_lot_status_request
--              AND (   (xmld.record_type_code  = gt_lot_status_request)
--                   OR (xmld.record_type_code  IS NULL)
--                  )
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--              AND xoha.deliver_to            = g_summary_tab ( in_slip_cnt ) .result_deliver_to
--              AND xoha.schedule_arrival_date = g_summary_tab ( in_slip_cnt ) .slip_date
--            )
--         OR (
--              xoha.req_status            = gt_ship_status_result
---- == 2009/04/16 V1.3 Modified START ===============================================================
----              AND xmld.record_type_code  = gt_lot_status_results
--              AND (   (xmld.record_type_code  = gt_lot_status_results)
--                   OR (xmld.record_type_code  IS NULL)
--                  )
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--              AND xoha.result_deliver_to = g_summary_tab ( in_slip_cnt ) .result_deliver_to
--              AND xoha.arrival_date      = g_summary_tab ( in_slip_cnt ) .slip_date
--            )
--          )
---- == 2009/05/01 V1.4 Added START ==================================================================
--      AND     xoha.latest_external_flag   = cv_y_flag
---- == 2009/05/01 V1.4 Added END   ==================================================================
--      GROUP BY  xoha.req_status
--              , xoha.request_no
--              , hca.account_number
--              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                     xoha.result_deliver_to ELSE xoha.deliver_to END
--              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                   xoha.arrival_date ELSE xoha.schedule_arrival_date END
--              , xoha.deliver_from
--              , xola.request_item_code
--              , imbp.item_no
--              , xola.delete_flag
--              , xca.dept_hht_div
---- == 2009/04/16 V1.3 Modified START ===============================================================
----            , hcasa.attribute18
--              , hl.province
---- == 2009/04/16 V1.3 Modified END   ===============================================================
--              , imbc.attribute11
--              , otta.order_category_code
--              , xmld.lot_no
--              , ilm.attribute3
--              , ilm.attribute2
--              , xola.order_header_id
--              , xola.order_line_id
--      ;
--
-- == 2009/11/06 V1.10 Modified START ===============================================================
--      SELECT  xoha.req_status                  AS req_status          -- �o�׈˗��X�e�[�^�X
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                xoha.result_deliver_to ELSE xoha.deliver_to END
--                                               AS result_deliver_to   -- �o�א�_����
--            , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                xoha.arrival_date ELSE xoha.schedule_arrival_date END
--                                               AS arrive_date         -- �`�[���t
--            , xoha.request_no                  AS req_move_no         -- �˗�No
--            , xoha.deliver_from                AS deliver_from        -- �o�׌��ۊǏꏊ
--            , xola.request_item_code           AS item_no             -- �q�i�ڃR�[�h
--            , imbp.item_no                     AS parent_item_no      -- �e�i�ڃR�[�h
--            , hca.account_number               AS base_code           -- ���_�R�[�h
--            , xola.delete_flag                 AS delete_flag         -- �폜�t���O
--            , xca.dept_hht_div                 AS dept_hht_div        -- �S�ݓX�pHHT�敪
--            , hl.province                      AS deliverly_code
--            , imbc.attribute11                 AS case_in_qty         -- �P�[�X����
--            , ilm.attribute3                   AS taste_term          -- �ܖ�����
--            , ilm.attribute2                   AS difference_summary_code
--                                                                      -- �ŗL�L��
--            , xola.order_header_id             AS order_header_id     -- �󒍃w�b�_ID
--            , xola.order_line_id               AS order_line_id       -- �󒍖���ID
--            , CASE WHEN otta.order_category_code = cv_order_type THEN
--                SUM( ROUND( xmld.actual_quantity, 2 ) )
--                   WHEN otta.order_category_code = cv_return_type THEN
--                SUM( ROUND( xmld.actual_quantity, 2 ) * -1 )
--              END                              AS shipped_quantity    -- �o�׎��ѐ���
--      FROM    xxwsh_order_headers_all          xoha                   -- �󒍃w�b�_�A�h�I��
--            , xxwsh_order_lines_all            xola                   -- �󒍖��׃A�h�I��
--            , ic_item_mst_b                    imbc                   -- OPM�i�ڃ}�X�^�i�q�j
--            , ic_item_mst_b                    imbp                   -- OPM�i�ڃ}�X�^�i�e�j
--            , xxcmn_item_mst_b                 ximb                   -- OPM�i�ڃA�h�I���}�X�^
--            , mtl_system_items_b               msib                   -- Disc�i�ڃ}�X�^
--            , hz_party_sites                   hps                    -- �p�[�e�B�T�C�g�}�X�^
--            , hz_cust_accounts                 hca                    -- �ڋq�}�X�^
--            , xxcmm_cust_accounts              xca                    -- �ڋq�ǉ����
--            , xxinv_mov_lot_details            xmld                   -- �ړ����b�g�ڍ�(�A�h�I��)
--            , ic_lots_mst                      ilm                    -- OPM���b�g�}�X�^
--            , oe_transaction_types_all         otta                   -- �󒍃^�C�v�}�X�^
--            , oe_transaction_types_tl          ottt
--            , hz_locations                     hl                     -- ���Ə��}�X�^
--      WHERE   xoha.order_header_id  =   xola.order_header_id
--      AND     xola.request_item_id  =   msib.inventory_item_id
--      AND     imbc.item_no          =   msib.segment1
--      AND     imbc.item_id          =   ximb.item_id
--      AND     imbp.item_id          =   ximb.parent_item_id
---- == 2009/09/08 V1.8 Added START ===============================================================
--      AND    ((xoha.req_status = gt_ship_status_result
--               AND
--               xoha.arrival_date BETWEEN ximb.start_date_active
--                                 AND     NVL(ximb.end_date_active, xoha.arrival_date)
--              )
--              OR
--              (xoha.req_status <> gt_ship_status_result
--               AND
--               xoha.schedule_arrival_date BETWEEN ximb.start_date_active
--                                          AND     NVL(ximb.end_date_active, xoha.schedule_arrival_date)
--              )
--             )
---- == 2009/09/08 V1.8 Added END   ===============================================================
--      AND     msib.organization_id  =   gt_org_id
--      AND ( ( -- ���ߍς݁A�m��ʒm�Ϗo�׈˗��i�o�׈˗��͍폜���ׂ����O�j
--              xoha.req_status                          = gt_ship_status_close
--              AND xoha.notif_status                    = gt_notice_status
--              AND NVL(xola.delete_flag,cv_n_flag)      = cv_n_flag
--              AND xola.shipping_request_if_flg         = cv_n_flag
--              AND xola.shipping_result_if_flg          = cv_n_flag
--              AND xoha.deliver_to_id                   = hps.party_site_id
--            )
--         OR ( -- �o�׎��ьv��Ϗo�׎��сi�o�׎��т͍폜���ׂ����O�A�������o�׈˗��A�g�ς͑Ώہj
--              (xoha.actual_confirm_class               = cv_y_flag
--              AND xoha.result_deliver_to_id            = hps.party_site_id)
--              AND(( xoha.req_status                    = gt_ship_status_result
--                   AND NVL(xola.delete_flag,cv_n_flag) = cv_n_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
--                  )
--              OR ( xoha.req_status                     = gt_ship_status_result
--                   AND xola.delete_flag                = cv_y_flag
--                   AND xola.shipping_request_if_flg    = cv_y_flag
--                   AND xola.shipping_result_if_flg     = cv_n_flag
--                 ))
--            )
--         OR ( -- �o�׈˗��A�g�ςɑ΂��Ď�����s�������̂͑Ώ�
--              xoha.req_status                                       = gt_ship_status_cancel
--              AND NVL(xoha.deliver_to_id,xoha.result_deliver_to_id) = hps.party_site_id
--              AND xola.shipping_request_if_flg                      = cv_y_flag
--              AND xola.shipping_result_if_flg                       = cv_n_flag
--              AND xola.delete_flag                                  = cv_y_flag
--            )
--          )
--      AND     otta.attribute1             = cv_1
--      AND     NVL ( otta.attribute4 , cv_1 ) <> cv_2
--      AND     otta.org_id                 = gt_itou_ou_id
--      AND     otta.transaction_type_id    = ottt.transaction_type_id
--      AND     ottt.language               = USERENV('LANG')
--      AND     xoha.order_type_id          = ottt.transaction_type_id
--      AND     hps.party_id                = hca.party_id
--      AND     hca.cust_account_id         = xca.customer_id
--      AND     hca.customer_class_code     = cv_class_code
--      AND     hca.status                  = cv_status_flag
--      AND     hps.location_id             = hl.location_id
--      AND     SUBSTRB(hl.province, 1, 1)  = cv_0
--      AND     xola.order_line_id          = xmld.mov_line_id(+)
--      AND     xmld.lot_id                 = ilm.lot_id(+)
--      AND     xmld.item_id                = ilm.item_id(+)
--      AND     xoha.req_status             = g_summary_tab ( in_slip_cnt ) .req_status
--      AND     xoha.request_no             = g_summary_tab ( in_slip_cnt ) .req_move_no
--      AND     xoha.deliver_from           = g_summary_tab ( in_slip_cnt ) .deliver_from
--      AND     xola.request_item_code      = g_summary_tab ( in_slip_cnt ) .item_no
--      AND ( (
--              xoha.req_status                IN ( gt_ship_status_close , gt_ship_status_cancel )
--              AND (   (xmld.record_type_code  = gt_lot_status_request)
--                   OR (xmld.record_type_code  IS NULL)
--                  )
--              AND xoha.deliver_to            = g_summary_tab ( in_slip_cnt ) .result_deliver_to
--              AND xoha.schedule_arrival_date = g_summary_tab ( in_slip_cnt ) .slip_date
--            )
--         OR (
--              xoha.req_status            = gt_ship_status_result
--              AND (   (xmld.record_type_code  = gt_lot_status_results)
--                   OR (xmld.record_type_code  IS NULL)
--                  )
--              AND xoha.result_deliver_to = g_summary_tab ( in_slip_cnt ) .result_deliver_to
--              AND xoha.arrival_date      = g_summary_tab ( in_slip_cnt ) .slip_date
--            )
--          )
--      AND     xoha.latest_external_flag   = cv_y_flag
--      GROUP BY  xoha.req_status
--              , xoha.request_no
--              , hca.account_number
--              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                     xoha.result_deliver_to ELSE xoha.deliver_to END
--              , CASE WHEN xoha.req_status = gt_ship_status_result THEN
--                   xoha.arrival_date ELSE xoha.schedule_arrival_date END
--              , xoha.deliver_from
--              , xola.request_item_code
--              , imbp.item_no
--              , xola.delete_flag
--              , xca.dept_hht_div
--              , hl.province
--              , imbc.attribute11
--              , otta.order_category_code
--              , xmld.lot_no
--              , ilm.attribute3
--              , ilm.attribute2
--              , xola.order_header_id
--              , xola.order_line_id
--      ;
-- == 2009/06/03 V1.6 Modified END   ===============================================================
      SELECT
                    oiv.req_status                    AS  req_status                        -- �o�׈˗��X�e�[�^�X
                  , oiv.result_deliver_to             AS  result_deliver_to                 -- �o�א�_����
                  , oiv.arrive_date                   AS  arrive_date                       -- �`�[���t
                  , oiv.req_move_no                   AS  req_move_no                       -- �˗�No
                  , oiv.deliver_from                  AS  deliver_from                      -- �o�׌��ۊǏꏊ
                  , oiv.item_no                       AS  item_no                           -- �q�i�ڃR�[�h
                  , imbp.item_no                      AS  parent_item_no                    -- �e�i�ڃR�[�h
                  , hca.account_number                AS  base_code                         -- ���_�R�[�h
                  , oiv.delete_flag                   AS  delete_flag                       -- �폜�t���O
                  , xca.dept_hht_div                  AS  dept_hht_div                      -- �S�ݓX�pHHT�敪
                  , hl.province                       AS  deliverly_code                    -- �z����R�[�h
                  , imbc.attribute11                  AS  case_in_qty                       -- �P�[�X����
                  , oiv.taste_term                    AS  taste_term                        -- �ܖ�����
                  , oiv.difference_summary_code       AS  difference_summary_code           -- �ŗL�L��
                  , oiv.order_header_id               AS  order_header_id                   -- �󒍃w�b�_ID
                  , oiv.order_line_id                 AS  order_line_id                     -- �󒍖���ID
                  , CASE  WHEN oiv.order_category_code = cv_order_type
                            THEN  SUM(oiv.actual_quantity)
                          WHEN oiv.order_category_code = cv_return_type
                            THEN  SUM(oiv.actual_quantity * -1)
                    END                               AS  shipped_quantity                  -- �o�׎��ѐ���
      FROM
                    ic_item_mst_b               imbc                  -- OPM�i�ڃ}�X�^�i�q�j
                  , ic_item_mst_b               imbp                  -- OPM�i�ڃ}�X�^�i�e�j
                  , xxcmn_item_mst_b            ximb                  -- OPM�i�ڃA�h�I���}�X�^
                  , mtl_system_items_b          msib                  -- Disc�i�ڃ}�X�^
                  , hz_party_sites              hps                   -- �p�[�e�B�T�C�g�}�X�^
                  , hz_cust_accounts            hca                   -- �ڋq�}�X�^
                  , xxcmm_cust_accounts         xca                   -- �ڋq�ǉ����
                  , hz_locations                hl                    -- ���Ə��}�X�^
                  , (
                      SELECT        xoha.req_status                     AS  req_status                  -- �o�׈˗��X�e�[�^�X
                                  , CASE  WHEN xoha.req_status = gt_ship_status_result
                                            THEN  xoha.result_deliver_to
                                            ELSE  xoha.deliver_to
                                    END                                 AS  result_deliver_to           -- �o�א�_����
                                  , CASE  WHEN xoha.req_status = gt_ship_status_result
                                            THEN  xoha.arrival_date
                                            ELSE  xoha.schedule_arrival_date
                                    END                                 AS  arrive_date                 -- �`�[���t
                                  , xoha.request_no                     AS  req_move_no                 -- �˗�No
                                  , xoha.deliver_from                   AS  deliver_from                -- �o�׌��ۊǏꏊ
                                  , xola.request_item_code              AS  item_no                     -- �q�i�ڃR�[�h
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                  , xola.delete_flag                    AS  delete_flag                 -- �폜�t���O
                                  , NVL(xola.delete_flag,cv_n_flag)     AS  delete_flag                 -- �폜�t���O
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                  , ilm.attribute3                      AS  taste_term                  -- �ܖ�����
                                  , ilm.attribute2                      AS  difference_summary_code     -- �ŗL�L��
                                  , xola.order_header_id                AS  order_header_id             -- �󒍃w�b�_ID
                                  , xola.order_line_id                  AS  order_line_id               -- �󒍖���ID
                                  , otta.order_category_code            AS  order_category_code         -- �󒍃J�e�S��
-- == 2009/12/18 V1.14 Modified START ===============================================================
--                                   , ROUND( xmld.actual_quantity, 2 )    AS  actual_quantity             -- �o�׎��ѐ���
                                  , ROUND( NVL(xmld.actual_quantity, 0), 2 )    AS  actual_quantity             -- �o�׎��ѐ���
-- == 2009/12/18 V1.14 Modified END   ===============================================================
                                  , xmld.lot_no                         AS  lot_no                      -- ���b�g�ԍ�
                                  , xola.request_item_id                AS  request_item_id             -- �i��ID
                                  , CASE  WHEN      xoha.req_status                   = gt_ship_status_close
                                                AND xoha.notif_status                 = gt_notice_status
                                                AND NVL(xola.delete_flag,cv_n_flag)   = cv_n_flag
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                                AND xola.shipping_request_if_flg      = cv_n_flag
--                                                AND xola.shipping_result_if_flg       = cv_n_flag
                                                AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_n_flag
                                                AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                          THEN  xoha.deliver_to_id
                                          WHEN      xoha.actual_confirm_class         = cv_y_flag
                                                AND xoha.req_status                   = gt_ship_status_result
                                                AND NVL(xola.delete_flag,cv_n_flag)   = cv_n_flag
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                                AND xola.shipping_result_if_flg       = cv_n_flag
                                                AND NVL(xola.shipping_result_if_flg,cv_n_flag) = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                          THEN  xoha.result_deliver_to_id
                                          WHEN      xoha.actual_confirm_class         = cv_y_flag
                                                AND xoha.req_status                   = gt_ship_status_result
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                                AND xola.delete_flag                  = cv_y_flag
--                                                AND xola.shipping_request_if_flg      = cv_y_flag
--                                                AND xola.shipping_result_if_flg       = cv_n_flag
                                                AND NVL(xola.delete_flag,cv_n_flag)             = cv_y_flag
                                                AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_y_flag
                                                AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                          THEN  xoha.result_deliver_to_id
                                          WHEN      xoha.req_status                   = gt_ship_status_cancel
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                                AND xola.shipping_request_if_flg      = cv_y_flag
--                                                AND xola.shipping_result_if_flg       = cv_n_flag
--                                                AND xola.delete_flag                  = cv_y_flag
                                                AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_y_flag
                                                AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
                                                AND NVL(xola.delete_flag,cv_n_flag)             = cv_y_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                          THEN NVL(xoha.deliver_to_id, xoha.result_deliver_to_id)
                                    END                                 AS  party_site_id               -- �p�[�e�B�T�C�g����ID
                      FROM
                                  xxwsh_order_headers_all           xoha                                -- �󒍃w�b�_�A�h�I��
                                , xxwsh_order_lines_all             xola                                -- �󒍖��׃A�h�I��
                                , xxinv_mov_lot_details             xmld                                -- �ړ����b�g�ڍ�(�A�h�I��)
                                , ic_lots_mst                       ilm                                 -- OPM���b�g�}�X�^
                                , oe_transaction_types_all          otta                                -- �󒍃^�C�v�}�X�^
                      WHERE       xoha.order_header_id              =   xola.order_header_id
                      AND         xoha.order_type_id                =   otta.transaction_type_id
                      AND         otta.attribute1                   =   cv_1
                      AND         NVL ( otta.attribute4 , cv_1 )    <>  cv_2
                      AND         otta.org_id                       =   gt_itou_ou_id
                      AND         otta.transaction_type_code        =   cv_order_type
                      AND         xola.order_line_id                =   xmld.mov_line_id(+)
                      AND         xmld.lot_id                       =   ilm.lot_id(+)
                      AND         xmld.item_id                      =   ilm.item_id(+)
                      AND         xoha.req_status                   =   g_summary_tab ( in_slip_cnt ) .req_status
                      AND         xoha.request_no                   =   g_summary_tab ( in_slip_cnt ) .req_move_no
                      AND         xoha.deliver_from                 =   g_summary_tab ( in_slip_cnt ) .deliver_from
                      AND         xola.request_item_code            =   g_summary_tab ( in_slip_cnt ) .item_no
                      AND         xoha.latest_external_flag         =   cv_y_flag
                      AND(        ( -- ���ߍς݁A�m��ʒm�Ϗo�׈˗��i�o�׈˗��͍폜���ׂ����O�j
                                        xoha.req_status                         = gt_ship_status_close
                                    AND xoha.notif_status                       = gt_notice_status
                                    AND NVL(xola.delete_flag,cv_n_flag)         = cv_n_flag
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                    AND xola.shipping_request_if_flg            = cv_n_flag
--                                    AND xola.shipping_result_if_flg             = cv_n_flag
                                    AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_n_flag
                                    AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                  )
                                  OR
                                  ( -- �o�׎��ьv��Ϗo�׎��сi�o�׎��т͍폜���ׂ����O�A�������o�׈˗��A�g�ς͑Ώہj
                                        xoha.actual_confirm_class               = cv_y_flag
                                    AND xoha.req_status                         = gt_ship_status_result
                                    AND(
                                        (     NVL(xola.delete_flag,cv_n_flag)   = cv_n_flag
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                          AND xola.shipping_result_if_flg       = cv_n_flag
                                          AND NVL(xola.shipping_result_if_flg,cv_n_flag) = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                        )
                                        OR
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                        (     xola.delete_flag                  = cv_y_flag
--                                          AND xola.shipping_request_if_flg      = cv_y_flag
--                                          AND xola.shipping_result_if_flg       = cv_n_flag
                                        (     NVL(xola.delete_flag,cv_n_flag)             = cv_y_flag
                                          AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_y_flag
                                          AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                        )
                                    )
                                  )
                                  OR
                                  ( -- �o�׈˗��A�g�ςɑ΂��Ď�����s�������̂͑Ώ�
                                        xoha.req_status                         = gt_ship_status_cancel
-- == 2009/12/08 V1.12 Modified START ===============================================================
--                                    AND xola.shipping_request_if_flg            = cv_y_flag
--                                    AND xola.shipping_result_if_flg             = cv_n_flag
--                                    AND xola.delete_flag                        = cv_y_flag
                                    AND NVL(xola.delete_flag,cv_n_flag)             = cv_y_flag
                                    AND NVL(xola.shipping_request_if_flg,cv_n_flag) = cv_y_flag
                                    AND NVL(xola.shipping_result_if_flg,cv_n_flag)  = cv_n_flag
-- == 2009/12/08 V1.12 Modified END   ===============================================================
                                  )
                      )
                      AND(        (
                                        xoha.req_status               IN (gt_ship_status_close, gt_ship_status_cancel)
                                    AND xoha.deliver_to               = g_summary_tab ( in_slip_cnt ) .result_deliver_to
                                    AND xoha.schedule_arrival_date    = g_summary_tab ( in_slip_cnt ) .slip_date
                                    AND (     (xmld.record_type_code  = gt_lot_status_request)
                                          OR  (xmld.record_type_code  IS NULL)
                                    )
                                  )
                                  OR
                                  (
                                        xoha.req_status               = gt_ship_status_result
                                    AND xoha.result_deliver_to        = g_summary_tab ( in_slip_cnt ) .result_deliver_to
                                    AND xoha.arrival_date             = g_summary_tab ( in_slip_cnt ) .slip_date
                                    AND (     (xmld.record_type_code  = gt_lot_status_results)
                                          OR  (xmld.record_type_code  IS NULL)
                                    )
                                  )
                      )
                    )                           oiv                   -- �󒍏��View
      WHERE     msib.inventory_item_id      =   oiv.request_item_id
      AND       msib.organization_id        =   gt_org_id
      AND       msib.segment1               =   imbc.item_no
      AND       imbc.item_id                =   ximb.item_id
      AND       imbp.item_id                =   ximb.parent_item_id
      AND       hps.party_id                =   hca.party_id
      AND       hca.customer_class_code     =   cv_class_code
      AND       hca.status                  =   cv_status_flag
      AND       hca.cust_account_id         =   xca.customer_id
      AND       hps.location_id             =   hl.location_id
      AND       SUBSTRB(hl.province, 1, 1)  =   cv_0
      AND       oiv.arrive_date   BETWEEN   ximb.start_date_active
                                  AND       NVL(ximb.end_date_active, oiv.arrive_date)
      AND       oiv.party_site_id           =   hps.party_site_id
      GROUP BY
                oiv.req_status
              , oiv.req_move_no
              , hca.account_number
              , oiv.result_deliver_to
              , oiv.arrive_date
              , oiv.deliver_from
              , oiv.item_no
              , imbp.item_no
              , oiv.delete_flag
              , xca.dept_hht_div
              , hl.province
              , imbc.attribute11
              , oiv.order_category_code
              , oiv.lot_no
              , oiv.taste_term
              , oiv.difference_summary_code
              , oiv.order_header_id
-- == 2009/12/08 V1.12 Modified START ===============================================================
--              , oiv.order_line_id;
              , oiv.order_line_id
      ORDER BY  oiv.delete_flag   DESC
      ;
-- == 2009/12/08 V1.12 Modified END   ===============================================================
-- == 2009/11/06 V1.10 Modified END   ===============================================================
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
    -- �J�[�\���I�[�v��
    OPEN detail_cur(
      g_summary_tab );
    FETCH detail_cur BULK COLLECT INTO g_detail_tab;
--
    -- �ڍ׃J�E���g�Z�b�g
    gn_detail_cnt := g_detail_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE detail_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( detail_cur%ISOPEN ) THEN
        CLOSE detail_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( detail_cur%ISOPEN ) THEN
        CLOSE detail_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( detail_cur%ISOPEN ) THEN
        CLOSE detail_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_detail_record;
--
  /**********************************************************************************
   * Procedure Name   : get_subinventories
   * Description      : �ۊǏꏊ��񏈗�(A-4)
   ***********************************************************************************/
  PROCEDURE get_subinventories(
      iv_base_code              IN VARCHAR2                                         -- 1.���_�R�[�h
-- == 2009/04/16 V1.3 Added START ===============================================================
    , it_deliverly_code         IN  hz_locations.province%TYPE                      -- 2.�z����R�[�h
-- == 2009/04/16 V1.3 Added END   ===============================================================
    , it_org_id                 IN mtl_secondary_inventories.organization_id%TYPE   -- 3.�݌ɑg�DID
    , ot_store_code             OUT xxcoi_subinventory_info_v.store_code%TYPE       -- 4.�q�ɃR�[�h
    , ot_shop_code              OUT xxcoi_subinventory_info_v.shop_code%TYPE        -- 5.�X�܃R�[�h
    , ot_auto_confirmation_flag OUT mtl_secondary_inventories.attribute11%TYPE      -- 6.�������Ɋm�F�t���O
    , ov_errbuf                 OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode                OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg                 OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_subinventories';     -- �v���O������
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
    lt_store_code        xxcoi_subinventory_info_v.store_code%TYPE;   -- �q�ɃR�[�h
    ln_valid_cnt         NUMBER;
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
    --1.�{�Ћ��_�q�ɃR�[�h�̎擾
    --==============================================================
-- == 2009/04/16 V1.3 Modified START ===============================================================
--    BEGIN
--      SELECT xsi.store_code
--      INTO   lt_store_code
--      FROM   xxcoi_subinventory_info_v xsi
--      WHERE  xsi.base_code              = iv_base_code
--      AND    xsi.base_code NOT LIKE '7%'
--      AND    xsi.organization_id        = it_org_id
--      AND    xsi.auto_confirmation_flag = cv_y_flag
--      AND    xsi.subinventory_class     = cv_1
--      ;
--    EXCEPTION
--      WHEN OTHERS THEN
--    --==============================================================
--    --2.�ڋq���ݒn�}�X�^���q�ɃR�[�h�̎擾
--    --==============================================================
--        BEGIN
--          SELECT  SUBSTRB ( hcasa.attribute18 , LENGTHB(hcasa.attribute18)-1 , 2 )
--          INTO    lt_store_code
--          FROM    hz_cust_accounts        hca             -- �ڋq�}�X�^
--                , hz_cust_acct_sites_all  hcasa           -- �ڋq���ݒn
--                , hz_cust_site_uses_all   hcsua           -- �ڋq�g�p�ړI
--          WHERE   hca.account_number      = iv_base_code
--          AND     hca.cust_account_id     = hcasa.cust_account_id
--          AND     hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
--          AND     hca.customer_class_code = cv_class_code
--          AND     hca.status              = cv_status_flag
--          AND     hcsua.site_use_code     = cv_site_use_code
--          AND     hcsua.status            = hca.status
--          AND     hcsua.primary_flag      = cv_y_flag
--          ;
--        EXCEPTION
--          WHEN NO_DATA_FOUND THEN
--            RAISE subinventory_found_expt;
--        END;
--    END;
--
-- == 2009/10/26 V1.9 Modified START ===============================================================
    --==============================================================
    --1.�q�ɃR�[�h�̎擾
    --==============================================================
--    lt_store_code :=  SUBSTRB ( it_deliverly_code , LENGTHB(it_deliverly_code)-1 , 2 );
-- == 2009/04/16 V1.3 Added END   ===============================================================
    BEGIN
      SELECT  xsi.store_code
      INTO    lt_store_code
      FROM    xxcoi_subinventory_info_v xsi
      WHERE   xsi.base_code               =   iv_base_code
      AND     xsi.organization_id         =   it_org_id
      AND     xsi.auto_confirmation_flag  =   cv_y_flag
      AND     xsi.main_store_class        =   cv_y_flag;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_store_code :=  SUBSTRB ( it_deliverly_code , LENGTHB(it_deliverly_code)-1 , 2 );
      WHEN TOO_MANY_ROWS THEN
        RAISE main_store_expt;
    END;
-- == 2009/10/26 V1.9 Modified END   ===============================================================
--
    --==============================================================
    --3.1�Ŏ擾�����q�ɃR�[�h���ۊǏꏊ�̑��݃`�F�b�N���s��
    --==============================================================
    SELECT COUNT(1)
    INTO   ln_valid_cnt
    FROM   xxcoi_subinventory_info_v xsi
    WHERE  xsi.base_code        = iv_base_code
    AND    xsi.store_code       = lt_store_code
    AND    xsi.organization_id  = it_org_id
    AND    ROWNUM = 1
    ;
--
    IF ( ln_valid_cnt = 0 ) THEN
      RAISE subinventory_found_expt;
    END IF;
--
    --==============================================================
    --4.1�Ŏ擾�����q�ɃR�[�h���ۊǏꏊ�̗L���`�F�b�N���s��
    --==============================================================
    BEGIN
      SELECT  xsi.store_code
            , xsi.auto_confirmation_flag
      INTO    ot_store_code
            , ot_auto_confirmation_flag
      FROM    xxcoi_subinventory_info_v xsi
      WHERE   xsi.base_code = iv_base_code
      AND     xsi.store_code = lt_store_code
      AND     xsi.organization_id = it_org_id
      AND     ( xsi.disable_date IS NULL
              OR xsi.disable_date > gd_process_date )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE subinventory_disable_expt;
      WHEN TOO_MANY_ROWS THEN
        RAISE subinventory_plural_expt;
    END;
--
    --==============================================================
    --5.���_�R�[�h�����ɗa����X�܃R�[�h�̎擾���s��
    --==============================================================
    BEGIN
      SELECT  xsi.shop_code
      INTO    ot_shop_code
      FROM    xxcoi_subinventory_info_v xsi
      WHERE   xsi.base_code = iv_base_code
      AND     xsi.organization_id = it_org_id
      AND     xsi.subinventory_class = cv_subinv_class
      AND     xsi.subinventory_type = cv_subinv_type
      AND     ( xsi.disable_date IS NULL
              OR xsi.disable_date > gd_process_date )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ot_shop_code := NULL;
      WHEN TOO_MANY_ROWS THEN
        ot_shop_code := NULL;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
-- == 2009/10/26 V1.9 Modified START ===============================================================
    WHEN main_store_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_code_10379
                       , iv_token_name1  => cv_token_10379
                       , iv_token_value1 => iv_base_code
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
-- == 2009/10/26 V1.9 Modified END   ===============================================================
    WHEN subinventory_found_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_subinventory_found_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => iv_base_code
                       , iv_token_name2  => cv_tkn_warehouse
                       , iv_token_value2 => lt_store_code
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
--      ROLLBACK TO SAVEPOINT summary_point;
--
    WHEN subinventory_disable_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_subinventory_disable_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => iv_base_code
                       , iv_token_name2  => cv_tkn_warehouse
                       , iv_token_value2 => lt_store_code
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
--      ROLLBACK TO SAVEPOINT summary_point;
--
    WHEN subinventory_plural_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_subinventory_plural_msg
                       , iv_token_name1  => cv_tkn_base_code
                       , iv_token_value1 => iv_base_code
                       , iv_token_name2  => cv_tkn_warehouse
                       , iv_token_value2 => lt_store_code
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
--      ROLLBACK TO SAVEPOINT summary_point;
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
  END get_subinventories;
--
  /**********************************************************************************
   * Procedure Name   : ins_summary_unconfirmed
   * Description      : ���ɏ��T�}���̓o�^[���ɖ��m�F](A-5)
   ***********************************************************************************/
  PROCEDURE ins_summary_unconfirmed(
      in_slip_cnt    IN NUMBER                                        -- 1.���[�v�J�E���^
    , iv_store_code  IN VARCHAR2                                      -- 2.�q�ɃR�[�h
    , iv_shop_code   IN VARCHAR2                                      -- 3.�X�܃R�[�h
    , it_auto_confirmation_flag IN mtl_secondary_inventories.attribute11%TYPE
                                                                      -- 4.�������Ɋm�F�t���O
    , ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_summary_unconfirmed';-- �v���O������
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
    --================================
    --���ɏ��ꎞ�\�ւ̃f�[�^�o�^
    --================================
    INSERT INTO xxcoi_storage_information(
        transaction_id
      , base_code
      , warehouse_code
      , slip_date
      , slip_num
      , req_status
      , parent_item_code
      , item_code
      , case_in_qty
      , ship_case_qty
      , ship_singly_qty
      , ship_summary_qty
      , ship_warehouse_code
      , check_warehouse_code
      , check_case_qty
      , check_singly_qty
      , check_summary_qty
      , material_transaction_unset_qty
      , slip_type
      , ship_base_code
      , taste_term
      , difference_summary_code
      , summary_data_flag
      , store_check_flag
      , material_transaction_set_flag
      , auto_store_check_flag
      , created_by
      , creation_date
      , last_updated_by
      , last_update_date
      , last_update_login
      , request_id
      , program_application_id
      , program_id
      , program_update_date
    ) VALUES (
        xxcoi_storage_information_s01.nextval                         -- ���ID
      , g_summary_tab ( in_slip_cnt ) .base_code                      -- ���_�R�[�h
      , iv_store_code                                                 -- �q�ɃR�[�h
      , g_summary_tab ( in_slip_cnt ) .slip_date                      -- �`�[���t
      , gv_slip_num                                                   -- �`�[No
      , g_summary_tab ( in_slip_cnt ) .req_status                     -- �o�׈˗��X�e�[�^�X
      , g_summary_tab ( in_slip_cnt ). parent_item_no                 -- �e�i�ڃR�[�h
      , g_summary_tab ( in_slip_cnt ). item_no                        -- �q�i�ڃR�[�h
      , g_summary_tab ( in_slip_cnt ). case_in_qty                    -- ����
-- == 2009/12/08 V1.12 Modified START ===============================================================
--      , TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty / g_summary_tab ( in_slip_cnt ) .case_in_qty )
--                                                                      -- �o�ɐ��ʃP�[�X��
--      , MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty , NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) )
--                                                                      -- �o�ɐ��ʃo����
--      , g_summary_tab ( in_slip_cnt ) .shipped_qty                    -- �o�א��ʑ��o����
      , DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
          TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty / g_summary_tab ( in_slip_cnt ) .case_in_qty ) )
                                                                      -- �o�ɐ��ʃP�[�X��
      , DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
          MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty , NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) ) )
                                                                      -- �o�ɐ��ʃo����
      , DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
          g_summary_tab ( in_slip_cnt ) .shipped_qty )                -- �o�א��ʑ��o����
-- == 2009/12/08 V1.12 Modified END   ===============================================================
      , DECODE ( g_summary_tab ( in_slip_cnt ) .dept_hht_div , cv_hht_kbn , iv_shop_code , NULL )
                                                                      -- �]����q�ɃR�[�h
      , iv_store_code                                                 -- �m�F�q�ɃR�[�h
      , 0                                                             -- �m�F���ʃP�[�X��
      , 0                                                             -- �m�F���ʃo����
      , 0                                                             -- �m�F���ʑ��o����
      , 0                                                             -- ���ގ�����A�g����
      , cv_slip_type                                                  -- �`�[�敪
      , g_summary_tab ( in_slip_cnt ) .deliver_from                   -- �o�ɋ��_�R�[�h
      , NULL                                                          -- �ܖ�����
      , NULL                                                          -- �H��ŗL�L��
      , cv_y_flag                                                     -- �T�}���[�f�[�^�t���O
      , cv_n_flag                                                     -- ���Ɋm�F�t���O
      , cv_n_flag                                                     -- ���ގ���A�g�σt���O
      , it_auto_confirmation_flag                                     -- �������Ɋm�F�t���O
      , cn_created_by
      , SYSDATE
      , cn_last_updated_by
      , SYSDATE
      , cn_last_update_login
      , cn_request_id
      , cn_program_application_id
      , cn_program_id
      , SYSDATE
    );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END ins_summary_unconfirmed;
--
  /**********************************************************************************
   * Procedure Name   : ins_summary_confirmed
   * Description      : ���ɏ��T�}���̓o�^[���Ɋm�F��](A-6)
   ***********************************************************************************/
  PROCEDURE ins_summary_confirmed(
      in_slip_cnt    IN NUMBER                                        -- 1.���[�v�J�E���^
    , iv_store_code  IN VARCHAR2                                      -- 2.�q�ɃR�[�h
    , iv_shop_code   IN VARCHAR2                                      -- 3.�X�܃R�[�h
    , it_auto_confirmation_flag IN mtl_secondary_inventories.attribute11%TYPE
                                                                      -- 4.�������Ɋm�F�t���O
    , ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_summary_confirmed';  -- �v���O������
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
    --================================
    --���ɏ��ꎞ�\�ւ̃f�[�^�o�^
    --================================
    INSERT INTO xxcoi_storage_information(
        transaction_id
      , base_code
      , warehouse_code
      , slip_date
      , slip_num
      , req_status
      , parent_item_code
      , item_code
      , case_in_qty
      , ship_case_qty
      , ship_singly_qty
      , ship_summary_qty
      , ship_warehouse_code
      , check_warehouse_code
      , check_case_qty
      , check_singly_qty
      , check_summary_qty
      , material_transaction_unset_qty
      , slip_type
      , ship_base_code
      , taste_term
      , difference_summary_code
      , summary_data_flag
      , store_check_flag
      , material_transaction_set_flag
      , auto_store_check_flag
      , created_by
      , creation_date
      , last_updated_by
      , last_update_date
      , last_update_login
      , request_id
      , program_application_id
      , program_id
      , program_update_date
    ) VALUES (
        xxcoi_storage_information_s01.nextval                         -- ���ID
      , g_summary_tab ( in_slip_cnt ) .base_code                      -- ���_�R�[�h
      , iv_store_code                                                 -- �q�ɃR�[�h
      , g_summary_tab ( in_slip_cnt ) .slip_date                      -- �`�[���t
      , gv_slip_num                                                   -- �`�[No
      , g_summary_tab ( in_slip_cnt ) .req_status                     -- �o�׈˗��X�e�[�^�X
      , g_summary_tab ( in_slip_cnt ) .parent_item_no                 -- �e�i�ڃR�[�h
      , g_summary_tab ( in_slip_cnt ) .item_no                        -- �q�i�ڃR�[�h
      , g_summary_tab ( in_slip_cnt ) .case_in_qty                    -- ����
-- == 2009/12/08 V1.12 Modified START ===============================================================
--      , TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty / g_summary_tab ( in_slip_cnt ) .case_in_qty )
--                                                                      -- �o�ɐ��ʃP�[�X��
--      , MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty , NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) )
--                                                                      -- �o�ɐ��ʃo����
--      , g_summary_tab ( in_slip_cnt ) .shipped_qty                    -- �o�א��ʑ��o����
      , DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
          TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty / g_summary_tab ( in_slip_cnt ) .case_in_qty ) )
                                                                      -- �o�ɐ��ʃP�[�X��
      , DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
          MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty , NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) ) )
                                                                      -- �o�ɐ��ʃo����
      , DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
          g_summary_tab ( in_slip_cnt ) .shipped_qty )                -- �o�א��ʑ��o����
-- == 2009/12/08 V1.12 Modified END   ===============================================================
      , DECODE ( g_summary_tab ( in_slip_cnt ) .dept_hht_div , cv_hht_kbn , iv_shop_code , NULL )
                                                                      -- �]����q�ɃR�[�h
      , iv_store_code                                                 -- �m�F�q�ɃR�[�h
      , 0                                                             -- �m�F���ʃP�[�X��
      , 0                                                             -- �m�F���ʃo����
      , 0                                                             -- �m�F���ʑ��o����
      , 0                                                             -- ���ގ�����A�g����
      , cv_slip_type                                                  -- �`�[�敪
      , g_summary_tab ( in_slip_cnt ) .deliver_from                   -- �o�ɋ��_�R�[�h
      , NULL                                                          -- �ܖ�����
      , NULL                                                          -- �H��ŗL�L��
      , cv_y_flag                                                     -- �T�}���[�f�[�^�t���O
      , cv_y_flag                                                     -- ���Ɋm�F�t���O
      , cv_n_flag                                                     -- ���ގ���A�g�σt���O
      , it_auto_confirmation_flag                                     -- �������Ɋm�F�t���O
      , cn_created_by
      , SYSDATE
      , cn_last_updated_by
      , SYSDATE
      , cn_last_update_login
      , cn_request_id
      , cn_program_application_id
      , cn_program_id
      , SYSDATE
    );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END ins_summary_confirmed;
--
  /**********************************************************************************
   * Procedure Name   : upd_summary_disp
   * Description      : ���ɏ��T�}���̍X�V[�o�׈˗��X�e�[�^�XNULL�Ώ�](A-7)
   ***********************************************************************************/
  PROCEDURE upd_summary_disp(
      in_slip_cnt   IN NUMBER                                          -- 1.���[�v�J�E���^
    , iv_rowid      IN ROWID                                           -- 2.�X�V�Ώ�ROWID
-- == 2009/12/18 V1.14 Added START ===============================================================
    , iv_store_code IN VARCHAR2                                        -- 3.�q�ɃR�[�h
-- == 2009/12/18 V1.14 Added END   ===============================================================
    , ov_errbuf    OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_summary_disp';       -- �v���O������
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
    CURSOR upd_xsi_tbl_cur
    IS
      SELECT xsi.rowid
      FROM   xxcoi_storage_information xsi
-- == 2009/12/18 V1.14 Modified START ===============================================================
--      WHERE  xsi.rowid = iv_rowid
      WHERE  xsi.slip_num          = gv_slip_num
      AND    xsi.slip_date         = g_summary_tab ( in_slip_cnt ) .slip_date
      AND    xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
      AND    xsi.warehouse_code    = iv_store_code
      AND    xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
      AND    xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
      AND    xsi.slip_type         = cv_slip_type
-- == 2009/12/18 V1.14 Modified END   ===============================================================
      FOR UPDATE NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
    upd_xsi_tbl_rec  upd_xsi_tbl_cur%ROWTYPE;
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
    -- ===============================
    --���ɏ��ꎞ�\�̃��b�N�擾
    -- ===============================
    OPEN upd_xsi_tbl_cur;
--
    -- ���R�[�h�Ǎ�
    FETCH upd_xsi_tbl_cur INTO upd_xsi_tbl_rec;
--
      -- ���ɏ��T�}���̍X�V
      UPDATE  xxcoi_storage_information xsi
      SET     req_status             = g_summary_tab ( in_slip_cnt ) .req_status
            , case_in_qty            = g_summary_tab ( in_slip_cnt ) .case_in_qty
            , ship_case_qty          = DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
                                         TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty
                                               / g_summary_tab ( in_slip_cnt ) .case_in_qty ) )
            , ship_singly_qty        = DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
                                         MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty ,
                                               NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) ) )
            , ship_summary_qty       = g_summary_tab ( in_slip_cnt ) .shipped_qty
            , ship_base_code         = g_summary_tab ( in_slip_cnt ) .deliver_from
            , last_updated_by        = cn_last_updated_by
            , last_update_date       = SYSDATE
            , last_update_login      = cn_last_update_login
            , request_id             = cn_request_id
            , program_application_id = cn_program_application_id
            , program_id             = cn_program_id
            , program_update_date    = SYSDATE
-- == 2010/01/04 V1.15 Modified START ===============================================================
--      WHERE  xsi.rowid               = upd_xsi_tbl_rec.rowid
      WHERE  xsi.rowid               = iv_rowid
-- == 2010/01/04 V1.15 Modified END   ===============================================================
      ;
--
    -- �J�[�\���N���[�Y
    CLOSE upd_xsi_tbl_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_lock_expt_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
      ROLLBACK TO SAVEPOINT summary_point;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_summary_disp;
--
  /**********************************************************************************
   * Procedure Name   : upd_summary_close�i���[�v���j
   * Description      : ���ɏ��T�}���̍X�V[�o�׈˗��X�e�[�^�X03�Ώ�](A-8)
   ***********************************************************************************/
  PROCEDURE upd_summary_close(
      in_slip_cnt   IN NUMBER                                          -- 1.���[�v�J�E���^
    , iv_rowid      IN ROWID                                           -- 2.�X�V�Ώ�ROWID
-- == 2009/12/18 V1.14 Added START ===============================================================
    , iv_store_code IN VARCHAR2                                        -- 3.�q�ɃR�[�h
-- == 2009/12/18 V1.14 Added END   ===============================================================
    , ov_errbuf    OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_summary_close';      -- �v���O������
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
    CURSOR upd_xsi_tbl_cur
    IS
      SELECT xsi.rowid
      FROM   xxcoi_storage_information xsi
-- == 2009/12/18 V1.14 Modified START ===============================================================
--       WHERE  xsi.rowid = iv_rowid
      WHERE  xsi.slip_num          = gv_slip_num
      AND    xsi.slip_date         = g_summary_tab ( in_slip_cnt ) .slip_date
      AND    xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
      AND    xsi.warehouse_code    = iv_store_code
      AND    xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
      AND    xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
      AND    xsi.slip_type         = cv_slip_type
-- == 2009/12/18 V1.14 Modified END   ===============================================================
      FOR UPDATE NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
    upd_xsi_tbl_rec  upd_xsi_tbl_cur%ROWTYPE;
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
    -- ===============================
    --���ɏ��ꎞ�\�̃��b�N�擾
    -- ===============================
    OPEN upd_xsi_tbl_cur;
--
    -- ���R�[�h�Ǎ�
    FETCH upd_xsi_tbl_cur INTO upd_xsi_tbl_rec;
--
      -- ���ɏ��T�}���̍X�V
      UPDATE xxcoi_storage_information xsi
      SET     req_status             = g_summary_tab ( in_slip_cnt ) .req_status
            , ship_case_qty          = DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
                                         TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty
                                               / g_summary_tab ( in_slip_cnt ) .case_in_qty ) )
            , ship_singly_qty        = DECODE( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
                                         MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty ,
                                             NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) ) )
            , ship_summary_qty       = DECODE( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
                                         g_summary_tab ( in_slip_cnt ) .shipped_qty )
            , ship_base_code         = g_summary_tab ( in_slip_cnt ) .deliver_from
            , last_updated_by        = cn_last_updated_by
            , last_update_date       = SYSDATE
            , last_update_login      = cn_last_update_login
            , request_id             = cn_request_id
            , program_application_id = cn_program_application_id
            , program_id             = cn_program_id
            , program_update_date    = SYSDATE
-- == 2010/01/04 V1.15 Modified START ===============================================================
--      WHERE  xsi.rowid               = upd_xsi_tbl_rec.rowid
      WHERE  xsi.rowid               = iv_rowid
-- == 2010/01/04 V1.15 Modified END   ===============================================================
      ;
--
    -- �J�[�\���N���[�Y
    CLOSE upd_xsi_tbl_cur;
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_lock_expt_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
      ROLLBACK TO SAVEPOINT summary_point;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_summary_close;
--
  /**********************************************************************************
   * Procedure Name   : upd_summary_results�i���[�v���j
   * Description      : ���ɏ��T�}���̍X�V[�o�׈˗��X�e�[�^�X04�Ώ�](A-9)
   ***********************************************************************************/
  PROCEDURE upd_summary_results(
      in_slip_cnt   IN NUMBER                                          -- 1.���[�v�J�E���^
    , iv_rowid      IN ROWID                                           -- 2.�X�V�Ώ�ROWID
-- == 2009/12/18 V1.14 Added START ===============================================================
    , iv_store_code IN VARCHAR2                                        -- 3.�q�ɃR�[�h
-- == 2009/12/18 V1.14 Added END   ===============================================================
    , ov_errbuf    OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_summary_results';    -- �v���O������
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
    CURSOR upd_xsi_tbl_cur
    IS
      SELECT xsi.rowid
      FROM   xxcoi_storage_information xsi
-- == 2009/12/18 V1.14 Modified START ===============================================================
--       WHERE  xsi.rowid = iv_rowid
      WHERE  xsi.slip_num          = gv_slip_num
      AND    xsi.slip_date         = g_summary_tab ( in_slip_cnt ) .slip_date
      AND    xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
      AND    xsi.warehouse_code    = iv_store_code
      AND    xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
      AND    xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
      AND    xsi.slip_type         = cv_slip_type
-- == 2009/12/18 V1.14 Modified END   ===============================================================
      FOR UPDATE NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
    upd_xsi_tbl_rec  upd_xsi_tbl_cur%ROWTYPE;
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
    -- ===============================
    --���ɏ��ꎞ�\�̃��b�N�擾
    -- ===============================
    OPEN upd_xsi_tbl_cur;
--
    -- ���R�[�h�Ǎ�
    FETCH upd_xsi_tbl_cur INTO upd_xsi_tbl_rec;
--
      -- ���ɏ��T�}���̍X�V
      UPDATE xxcoi_storage_information xsi
      SET     ship_case_qty          = DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
-- == 2009/05/01 V1.4 Modified START ===============================================================
--                                         ship_case_qty + TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty
                                         TRUNC ( g_summary_tab ( in_slip_cnt ) .shipped_qty
-- == 2009/05/01 V1.4 Modified END   ===============================================================
                                                           / g_summary_tab ( in_slip_cnt ) .case_in_qty ) )
            , ship_singly_qty        = DECODE ( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
-- == 2009/05/01 V1.4 Modified START ===============================================================
--                                         ship_singly_qty + MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty ,
                                         MOD ( g_summary_tab ( in_slip_cnt ) .shipped_qty ,
-- == 2009/05/01 V1.4 Modified END   ===============================================================
                                                           NVL ( g_summary_tab ( in_slip_cnt ) .case_in_qty , 0 ) ) )
            , ship_summary_qty       = DECODE( g_summary_tab ( in_slip_cnt ) .delete_flag , cv_y_flag , 0 ,
-- == 2009/05/01 V1.4 Modified START ===============================================================
--                                         ship_summary_qty + g_summary_tab ( in_slip_cnt ) .shipped_qty )
                                         g_summary_tab ( in_slip_cnt ) .shipped_qty )
-- == 2009/05/01 V1.4 Modified END   ===============================================================
            , ship_base_code         = g_summary_tab ( in_slip_cnt ) .deliver_from
            , last_updated_by        = cn_last_updated_by
            , last_update_date       = SYSDATE
            , last_update_login      = cn_last_update_login
            , request_id             = cn_request_id
            , program_application_id = cn_program_application_id
            , program_id             = cn_program_id
            , program_update_date    = SYSDATE
-- == 2010/01/04 V1.15 Modified START ===============================================================
--      WHERE  xsi.rowid               = upd_xsi_tbl_rec.rowid
      WHERE  xsi.rowid               = iv_rowid
-- == 2010/01/04 V1.15 Modified END   ===============================================================
      ;
--
    -- �J�[�\���N���[�Y
    CLOSE upd_xsi_tbl_cur;
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_lock_expt_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
      ROLLBACK TO SAVEPOINT summary_point;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_summary_results;
--
  /**********************************************************************************
   * Procedure Name   : ins_detail_confirmed�i���[�v���j
   * Description      : ���ɏ��ڍׂ̓o�^(A-10)
   ***********************************************************************************/
  PROCEDURE ins_detail_confirmed(
      in_line_cnt    IN NUMBER                                        -- 1.���[�v�J�E���^
    , iv_store_code  IN VARCHAR2                                      -- 2.�q�ɃR�[�h
    , iv_shop_code   IN VARCHAR2                                      -- 3.�X�܃R�[�h
    , it_auto_confirmation_flag IN mtl_secondary_inventories.attribute11%TYPE
                                                                      -- 4.�������Ɋm�F�t���O
    , ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_detail_confirmed';   -- �v���O������
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���ɖ��m�F���X�g���[���[�N�e�[�u���ւ̃f�[�^�o�^
    --==============================================================
    INSERT INTO xxcoi_storage_information(
        transaction_id
      , base_code
      , warehouse_code
      , slip_date
      , slip_num
      , req_status
      , parent_item_code
      , item_code
      , case_in_qty
      , ship_case_qty
      , ship_singly_qty
      , ship_summary_qty
      , ship_warehouse_code
      , check_warehouse_code
      , check_case_qty
      , check_singly_qty
      , check_summary_qty
      , material_transaction_unset_qty
      , slip_type
      , ship_base_code
      , taste_term
      , difference_summary_code
      , summary_data_flag
      , store_check_flag
      , material_transaction_set_flag
      , auto_store_check_flag
      , created_by
      , creation_date
      , last_updated_by
      , last_update_date
      , last_update_login
      , request_id
      , program_application_id
      , program_id
      , program_update_date
    ) VALUES (
        xxcoi_storage_information_s01.nextval                          -- ���ID
      , g_detail_tab(in_line_cnt).base_code                            -- ���_�R�[�h
      , iv_store_code                                                  -- �q�ɃR�[�h
      , g_detail_tab(in_line_cnt).slip_date                            -- �`�[���t
      , gv_slip_num                                                    -- �`�[No
      , g_detail_tab(in_line_cnt).req_status                           -- �o�׈˗��X�e�[�^�X
      , g_detail_tab(in_line_cnt).parent_item_no                       -- �e�i�ڃR�[�h
      , g_detail_tab(in_line_cnt).item_no                              -- �q�i�ڃR�[�h
      , g_detail_tab(in_line_cnt).case_in_qty                          -- ����
-- == 2009/12/08 V1.12 Modified START ===============================================================
--      , TRUNC ( g_detail_tab ( in_line_cnt ) .shipped_qty / g_detail_tab ( in_line_cnt ) .case_in_qty )
--                                                                       -- �o�ɐ��ʃP�[�X��
--      , MOD ( g_detail_tab ( in_line_cnt ) .shipped_qty , NVL ( g_detail_tab ( in_line_cnt ) .case_in_qty , 0 ) )
--                                                                       -- �o�ɐ��ʃo����
--      , g_detail_tab ( in_line_cnt ). shipped_qty                      -- �o�א��ʑ��o����
      , DECODE ( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
          TRUNC ( g_detail_tab ( in_line_cnt ) .shipped_qty / g_detail_tab ( in_line_cnt ) .case_in_qty ) )
                                                                       -- �o�ɐ��ʃP�[�X��
      , DECODE ( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
          MOD ( g_detail_tab ( in_line_cnt ) .shipped_qty , NVL ( g_detail_tab ( in_line_cnt ) .case_in_qty , 0 ) ) )
                                                                       -- �o�ɐ��ʃo����
      , DECODE ( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
          g_detail_tab ( in_line_cnt ). shipped_qty )                  -- �o�א��ʑ��o����
-- == 2009/12/08 V1.12 Modified END   ===============================================================
      , DECODE ( g_detail_tab ( in_line_cnt ) .dept_hht_div , cv_hht_kbn , iv_shop_code , NULL )
                                                                       -- �]����q�ɃR�[�h
      , iv_store_code                                                  -- �m�F�q�ɃR�[�h
      , 0                                                              -- �m�F���ʃP�[�X��
      , 0                                                              -- �m�F���ʃo����
      , 0                                                              -- �m�F���ʑ��o����
      , 0                                                              -- ���ގ�����A�g����
      , cv_slip_type                                                   -- �`�[�敪
      , g_detail_tab ( in_line_cnt ) .deliver_from                     -- �o�ɋ��_�R�[�h
      , g_detail_tab ( in_line_cnt ) .taste_term                       -- �ܖ�����
      , g_detail_tab ( in_line_cnt ) .difference_summary_code          -- �H��ŗL�L��
      , cv_n_flag                                                      -- �T�}���[�f�[�^�t���O
      , cv_n_flag                                                      -- ���Ɋm�F�t���O
      , cv_n_flag                                                      -- ���ގ���A�g�σt���O
      , it_auto_confirmation_flag                                      -- �������Ɋm�F�t���O
      , cn_created_by
      , SYSDATE
      , cn_last_updated_by
      , SYSDATE
      , cn_last_update_login
      , cn_request_id
      , cn_program_application_id
      , cn_program_id
      , SYSDATE
    );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END ins_detail_confirmed;
--
  /**********************************************************************************
   * Procedure Name   : upd_detail_close�i���[�v���j
   * Description      : ���ɏ��ڍׂ̍X�V[�o�׈˗��X�e�[�^�X03�Ώ�](A-11)
   ***********************************************************************************/
  PROCEDURE upd_detail_close(
      in_line_cnt    IN NUMBER                                        -- 1.���[�v�J�E���^
    , iv_rowid       IN ROWID                                         -- 2.�X�V�Ώ�ROWID
    , iv_store_code  IN VARCHAR2                                      -- 3.�q�ɃR�[�h
    , iv_shop_code   IN VARCHAR2                                      -- 4.�X�܃R�[�h
    , ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_detail_close';       -- �v���O������
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
    CURSOR upd_xsi_tbl_cur
    IS
      SELECT xsi.rowid
      FROM   xxcoi_storage_information xsi
      WHERE  xsi.rowid = iv_rowid
      FOR UPDATE NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
    upd_xsi_tbl_rec  upd_xsi_tbl_cur%ROWTYPE;
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
    -- ===============================
    --���ɏ��ꎞ�\�̃��b�N�擾
    -- ===============================
    OPEN upd_xsi_tbl_cur;
    -- ���R�[�h�Ǎ�
    FETCH upd_xsi_tbl_cur INTO upd_xsi_tbl_rec;
--
      -- ���ɏ��ڍׂ̍X�V
      UPDATE  xxcoi_storage_information  xsi
      SET     req_status                    = g_detail_tab ( in_line_cnt ) .req_status
            , ship_case_qty                 = DECODE ( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
                                                TRUNC ( g_detail_tab ( in_line_cnt ) .shipped_qty / g_detail_tab ( in_line_cnt ) .case_in_qty ) )
            , ship_singly_qty               = DECODE( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
                                                MOD ( g_detail_tab ( in_line_cnt ) .shipped_qty ,
                                                NVL ( g_detail_tab ( in_line_cnt ) .case_in_qty , 0 ) ) )
            , ship_summary_qty              = DECODE( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
                                                g_detail_tab ( in_line_cnt ) .shipped_qty )
            , ship_warehouse_code           = DECODE ( g_detail_tab ( in_line_cnt ) .dept_hht_div , cv_hht_kbn , iv_shop_code , NULL )
            , check_warehouse_code          = iv_store_code
            , ship_base_code                = g_detail_tab ( in_line_cnt ) .deliver_from
            , taste_term                    = g_detail_tab ( in_line_cnt ) .taste_term
            , difference_summary_code       = g_detail_tab ( in_line_cnt ) .difference_summary_code
            , material_transaction_set_flag = cv_n_flag
            , last_updated_by               = cn_last_updated_by
            , last_update_date              = SYSDATE
            , last_update_login             = cn_last_update_login
            , request_id                    = cn_request_id
            , program_application_id        = cn_program_application_id
            , program_id                    = cn_program_id
            , program_update_date           = SYSDATE
      WHERE   xsi.rowid                     = upd_xsi_tbl_rec.rowid
      ;
--
    -- �J�[�\���N���[�Y
    CLOSE upd_xsi_tbl_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_detail_lock_expt_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
      ROLLBACK TO SAVEPOINT summary_point;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_detail_close;
--
  /**********************************************************************************
   * Procedure Name   : upd_detail_results�i���[�v���j
   * Description      : ���ɏ��ڍׂ̍X�V[�o�׈˗��X�e�[�^�X04�Ώ�](A-12)
   ***********************************************************************************/
  PROCEDURE upd_detail_results(
      in_line_cnt    IN NUMBER                                        -- 1.���[�v�J�E���^
    , iv_rowid       IN ROWID                                         -- 2.�X�V�Ώ�ROWID
    , iv_store_code  IN VARCHAR2                                      -- 3.�q�ɃR�[�h
    , iv_shop_code   IN VARCHAR2                                      -- 4.�X�܃R�[�h
    , ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_detail_results';     -- �v���O������
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
    CURSOR upd_xsi_tbl_cur
    IS
      SELECT xsi.rowid
      FROM   xxcoi_storage_information xsi
      WHERE  xsi.rowid = iv_rowid
      FOR UPDATE NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
    upd_xsi_tbl_rec  upd_xsi_tbl_cur%ROWTYPE;
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
    -- ===============================
    --���ɏ��ꎞ�\�̃��b�N�擾
    -- ===============================
    OPEN upd_xsi_tbl_cur;
    -- ���R�[�h�Ǎ�
    FETCH upd_xsi_tbl_cur INTO upd_xsi_tbl_rec;
--
      -- ���ɏ��ڍׂ̍X�V
      UPDATE  xxcoi_storage_information xsi
      SET     req_status                    = g_detail_tab ( in_line_cnt ) .req_status
            , case_in_qty                   = g_detail_tab ( in_line_cnt ) .case_in_qty
            , ship_case_qty                 = DECODE ( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
-- == 2009/05/01 V1.4 Modified START ===============================================================
--                                                ship_case_qty + TRUNC ( g_detail_tab ( in_line_cnt ) .shipped_qty
                                                TRUNC ( g_detail_tab ( in_line_cnt ) .shipped_qty
-- == 2009/05/01 V1.4 Modified END   ===============================================================
                                                                      / g_detail_tab ( in_line_cnt ) .case_in_qty ) )
            , ship_singly_qty               = DECODE ( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
-- == 2009/05/01 V1.4 Modified START ===============================================================
--                                                ship_singly_qty + MOD ( g_detail_tab ( in_line_cnt ) .shipped_qty ,
                                                MOD ( g_detail_tab ( in_line_cnt ) .shipped_qty ,
-- == 2009/05/01 V1.4 Modified END   ===============================================================
                                                                  NVL ( g_detail_tab ( in_line_cnt ) .case_in_qty , 0 ) ) )
            , ship_summary_qty              = DECODE( g_detail_tab ( in_line_cnt ) .delete_flag , cv_y_flag , 0 ,
-- == 2009/05/01 V1.4 Modified START ===============================================================
--                                                ship_summary_qty + g_detail_tab ( in_line_cnt ) .shipped_qty )
                                                g_detail_tab ( in_line_cnt ) .shipped_qty )
-- == 2009/05/01 V1.4 Modified END   ===============================================================
            , ship_warehouse_code           = DECODE ( g_detail_tab ( in_line_cnt ) .dept_hht_div , cv_hht_kbn , iv_shop_code , NULL )
            , check_warehouse_code          = iv_store_code
            , ship_base_code                = g_detail_tab(in_line_cnt).deliver_from
            , taste_term                    = g_detail_tab ( in_line_cnt ) .taste_term
            , difference_summary_code       = g_detail_tab ( in_line_cnt ) .difference_summary_code
            , material_transaction_set_flag = cv_n_flag
            , last_updated_by               = cn_last_updated_by
            , last_update_date              = SYSDATE
            , last_update_login             = cn_last_update_login
            , request_id                    = cn_request_id
            , program_application_id        = cn_program_application_id
            , program_id                    = cn_program_id
            , program_update_date           = SYSDATE
      WHERE   xsi.rowid                     = upd_xsi_tbl_rec.rowid
      ;
--
    -- �J�[�\���N���[�Y
    CLOSE upd_xsi_tbl_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_detail_lock_expt_err_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
      ROLLBACK TO SAVEPOINT summary_point;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( upd_xsi_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xsi_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_detail_results;
--
  /**********************************************************************************
   * Procedure Name   : upd_order_lines�i���[�v���j
   * Description      : �󒍖��׃A�h�I���X�V(A-13)
   ***********************************************************************************/
  PROCEDURE upd_order_lines(
      in_line_cnt    IN NUMBER                                        -- 1.���[�v�J�E���^
    , ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_order_lines';        -- �v���O������
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
    CURSOR upd_xola_tbl_cur(
      g_detail_tab g_detail_ttype )
    IS
      SELECT xola.rowid
      FROM   xxwsh_order_lines_all xola
      WHERE  xola.order_header_id = g_detail_tab ( in_line_cnt ) .order_header_id
      AND    xola.order_line_id   = g_detail_tab ( in_line_cnt ) .order_line_id
      FOR UPDATE NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
    upd_xola_tbl_rec  upd_xola_tbl_cur%ROWTYPE;
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
    -- ===============================
    -- �󒍖��׃A�h�I���e�[�u���̃��b�N�擾
    -- ===============================
    OPEN upd_xola_tbl_cur(
      g_detail_tab
    );
    -- ���R�[�h�Ǎ�
    FETCH upd_xola_tbl_cur INTO upd_xola_tbl_rec;
--
      IF ( g_detail_tab ( in_line_cnt ) .req_status = gt_ship_status_close ) THEN
        -- �󒍖��׃A�h�I���e�[�u���̍X�V�i�o�׎w���̏ꍇ�͎w���A�g�ς݃t���O�X�V�j
        UPDATE xxwsh_order_lines_all xola
        SET    xola.shipping_request_if_flg = cv_y_flag
        WHERE  xola.rowid                   = upd_xola_tbl_rec.rowid
        ;
      ELSE
        -- �󒍖��׃A�h�I���e�[�u���̍X�V�i�o�׎��сE����̏ꍇ�͎��јA�g�ς݃t���O�X�V�j
        UPDATE xxwsh_order_lines_all xola
        SET    xola.shipping_result_if_flg  = cv_y_flag
        WHERE  xola.rowid                   = upd_xola_tbl_rec.rowid
        ;
      END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE upd_xola_tbl_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN
      IF ( upd_xola_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xola_tbl_cur;
      END IF;
--
      gn_error_cnt := gn_error_cnt + 1;
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_lines_lock_expt_msg
                       , iv_token_name1  => cv_tkn_den_no
                       , iv_token_value1 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( upd_xola_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xola_tbl_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( upd_xola_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xola_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( upd_xola_tbl_cur%ISOPEN ) THEN
        CLOSE upd_xola_tbl_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_order_lines;
--
  /**********************************************************************************
   * Procedure Name   : chk_item�i���[�v���j
   * Description      : �i�ڗL���`�F�b�N(A-15)
   ***********************************************************************************/
  PROCEDURE chk_item(
      in_slip_cnt   IN  NUMBER        --   1.���[�v�J�E���^
    , ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item';               -- �v���O������
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
    cv_status                 CONSTANT VARCHAR2(10) := 'Inactive';
    cv_cmnfunc_nm             CONSTANT VARCHAR2(50) := 'XXCOI_COMMON_PKG.GET_ITEM_INFO';
--
    -- *** ���[�J���ϐ� ***
    lt_item_status            mtl_system_items_b.inventory_item_status_code%TYPE;
    lt_cust_order_flg         mtl_system_items_b.customer_order_enabled_flag%TYPE;
    lt_transaction_enable     mtl_system_items_b.mtl_transactions_enabled_flag%TYPE;
    lt_stock_enabled_flg      mtl_system_items_b.stock_enabled_flag%TYPE;
    lt_return_enable          mtl_system_items_b.returnable_flag%TYPE;
    lt_sales_class            ic_item_mst_b.attribute26%TYPE;
    lt_primary_unit           mtl_system_items_b.primary_unit_of_measure%TYPE;
    ln_item_cnt               NUMBER;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===============================
    -- ���ʊ֐����g�p���i�ڏ����擾
    -- ===============================
      xxcoi_common_pkg.get_item_info(
         iv_item_code          => g_summary_tab ( in_slip_cnt ) .item_no
                                                                      -- 1.�i�ڃR�[�h
        ,in_org_id             => gt_org_id                           -- 2.�݌ɑg�DID
        ,ov_item_status        => lt_item_status                      -- 3.�i�ڃX�e�[�^�X
        ,ov_cust_order_flg     => lt_cust_order_flg                   -- 4.�ڋq�󒍉\�t���O
        ,ov_transaction_enable => lt_transaction_enable               -- 5.����\
        ,ov_stock_enabled_flg  => lt_stock_enabled_flg                -- 6.�݌ɕۗL�\�t���O
        ,ov_return_enable      => lt_return_enable                    -- 7.�ԕi�\
        ,ov_sales_class        => lt_sales_class                      -- 8.����Ώۋ敪
        ,ov_primary_unit       => lt_primary_unit                     -- 9.��P��
        ,ov_errbuf             => lv_errbuf                           -- 10.�G���[�E���b�Z�[�W
        ,ov_retcode            => lv_retcode                          -- 11.���^�[���E�R�[�h
        ,ov_errmsg             => lv_errmsg                           -- 12.���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE item_expt;
      ELSIF ( lt_item_status IS NULL ) THEN
        RAISE item_found_expt;
      ELSIF ( lt_item_status != cv_status ) THEN
        --�q�i�ځ{�i�ڃJ�e�S���F���ވȊO���G���[�Ƃ���
        IF ( lt_cust_order_flg = cv_y_flag
             AND lt_transaction_enable = cv_y_flag
             AND lt_stock_enabled_flg = cv_y_flag
             AND lt_return_enable = cv_y_flag )
        THEN
          SELECT   COUNT(*)
          INTO     ln_item_cnt
          FROM     mtl_system_items_b msib
                 , ic_item_mst_b iimbc
                 , ic_item_mst_b iimbp
                 , xxcmn_item_mst_b ximb
          WHERE    msib.organization_id               = gt_org_id
          AND      iimbc.item_no                      = msib.segment1
          AND      msib.segment1                      = g_summary_tab ( in_slip_cnt ) .item_no
          AND      iimbc.item_id                      = ximb.item_id
          AND      iimbp.item_id                      = ximb.parent_item_id
-- == 2009/09/08 V1.8 Added START ===============================================================
          AND      g_summary_tab( in_slip_cnt ).slip_date BETWEEN ximb.start_date_active
                                                          AND     NVL(ximb.end_date_active, g_summary_tab( in_slip_cnt ).slip_date)
-- == 2009/09/08 V1.8 Added END   ===============================================================
-- == 2009/11/13 V1.11 Modified START ===============================================================
--          AND      ( ximb.parent_item_id = iimbc.item_id
--                   AND iimbc.attribute26 != cv_1
--                   AND NOT EXISTS ( SELECT '1'
--                                    FROM   mtl_system_items_b     msib2
--                                         , mtl_category_sets_tl   mcst
--                                         , mtl_item_categories    mic
--                                         , mtl_categories_b       mcb
--                                    WHERE  msib2.organization_id  = gt_org_id
--                                    AND    mcst.category_set_name = fnd_profile.value ( cv_item_category )
--                                    AND    mcst.language          = USERENV('LANG')
--                                    AND    mic.category_set_id    = mcst.category_set_id
--                                    AND    mic.inventory_item_id  = msib2.inventory_item_id
--                                    AND    mic.organization_id    = msib2.organization_id
--                                    AND    mcb.category_id        = mic.category_id
--                                    AND    mcb.enabled_flag       = cv_y_flag
--                                    AND    mcb.segment1           = cv_2
--                                    AND    msib.inventory_item_id = msib2.inventory_item_id
--                                  )
--                  );
          AND      iimbp.attribute26 != cv_1
          AND      NOT EXISTS    ( SELECT  1
                                   FROM    mtl_system_items_b    msib2
                                   WHERE  msib2.organization_id   = gt_org_id
                                   AND    msib2.inventory_item_id = msib.inventory_item_id
                                   AND   (msib2.segment1          LIKE '5%'
                                   OR     msib2.segment1          LIKE '6%')
                                 );
-- == 2009/11/13 V1.11 Modified END   ===============================================================
          IF (ln_item_cnt != 0) THEN
            RAISE item_disable_expt;
          END IF;
        ELSE
          RAISE item_disable_expt;
        END IF;
      ELSE
        RAISE item_disable_expt;
      END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN item_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_item_expt_msg
                       , iv_token_name1  => cv_tkn_api_nm
                       , iv_token_value1 => cv_cmnfunc_nm
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
--      ROLLBACK TO SAVEPOINT summary_point;
--
    WHEN item_found_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_item_disable_msg
                       , iv_token_name1  => cv_tkn_item_code
                       , iv_token_value1 => g_summary_tab(in_slip_cnt).item_no
                       , iv_token_name2  => cv_tkn_den_no
                       , iv_token_value2 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
--      ROLLBACK TO SAVEPOINT summary_point;
--
    WHEN item_disable_expt THEN
      lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_item_disable_msg
                       , iv_token_name1  => cv_tkn_item_code
                       , iv_token_value1 => g_summary_tab(in_slip_cnt).item_no
                       , iv_token_name2  => cv_tkn_den_no
                       , iv_token_value2 => gv_slip_num
                     );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
--      ROLLBACK TO SAVEPOINT summary_point;
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
  END chk_item;
--
  /**********************************************************************************
   * Procedure Name   : chk_summary_data�i���[�v���j
   * Description      : ���ɏ��T�}�����݊m�F(A-16)
   ***********************************************************************************/
  PROCEDURE chk_summary_data(
      in_slip_cnt      IN NUMBER                                      -- 1.���[�v�J�E���^
    , iv_store_code    IN VARCHAR2                                    -- 2.�q�ɃR�[�h
    , ov_rowid        OUT ROWID                                       -- 3.ROWID
    , ot_req_status   OUT xxcoi_storage_information.req_status%TYPE   -- 4.�o�׈˗��X�e�[�^�X
    , ob_record_valid OUT BOOLEAN                                     -- 5.TRUE:�T�}�����R�[�h���� FALSE:���݂���
    , ov_errbuf       OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_summary_data';       -- �v���O������
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===============================
    -- ���ɏ��ꎞ�\�ɃT�}�����R�[�h�����݂��邩�`�F�b�N���s��
    -- ===============================
    BEGIN
      SELECT  xsi.rowid
            , xsi.req_status
      INTO    ov_rowid
            , ot_req_status
      FROM    xxcoi_storage_information xsi
      WHERE   xsi.slip_num          = gv_slip_num
      AND     xsi.slip_date         = g_summary_tab ( in_slip_cnt ) .slip_date
      AND     xsi.base_code         = g_summary_tab ( in_slip_cnt ) .base_code
      AND     xsi.warehouse_code    = iv_store_code
      AND     xsi.parent_item_code  = g_summary_tab ( in_slip_cnt ) .parent_item_no
      AND     xsi.item_code         = g_summary_tab ( in_slip_cnt ) .item_no
      AND     xsi.slip_type         = cv_slip_type
      AND     xsi.summary_data_flag = cv_y_flag
      ;
      ob_record_valid := TRUE;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_record_valid := FALSE;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ob_record_valid := FALSE;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ob_record_valid := FALSE;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ob_record_valid := FALSE;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_summary_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_detail_data�i���[�v���j
   * Description      : ���ɏ��ڍב��݊m�F(A-17)
   ***********************************************************************************/
  PROCEDURE chk_detail_data(
      in_line_cnt      IN NUMBER                                      -- 1.���[�v�J�E���^
    , iv_store_code    IN VARCHAR2                                    -- 2.�q�ɃR�[�h
    , ov_rowid        OUT ROWID                                       -- 3.ROWID
    , ot_req_status   OUT xxcoi_storage_information.req_status%TYPE   -- 4.�o�׈˗��X�e�[�^�X
    , ob_record_valid OUT BOOLEAN                                     -- 5.TRUE:�ڍ׃��R�[�h���� FALSE:���݂���
    , ov_errbuf       OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode      OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg       OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_detail_data';        -- �v���O������
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===============================
    -- ���ɏ��ꎞ�\�ɏڍ׃��R�[�h�����݂��邩�`�F�b�N���s��
    -- ===============================
    BEGIN
      SELECT xsi.rowid
            ,xsi.req_status
      INTO   ov_rowid
            ,ot_req_status
      FROM   xxcoi_storage_information xsi
      WHERE  xsi.slip_num                 = gv_slip_num
      AND    xsi.slip_date                = g_detail_tab ( in_line_cnt ) .slip_date
      AND    xsi.base_code                = g_detail_tab ( in_line_cnt ) .base_code
      AND    xsi.warehouse_code           = iv_store_code
      AND    xsi.parent_item_code         = g_detail_tab ( in_line_cnt ) .parent_item_no
      AND    xsi.item_code                = g_detail_tab ( in_line_cnt ) .item_no
-- == 2009/05/14 V1.5 Modified START ===============================================================
--      AND    xsi.taste_term               = g_detail_tab ( in_line_cnt ) .taste_term
--      AND    xsi.difference_summary_code  = g_detail_tab ( in_line_cnt ) .difference_summary_code
      AND    (   (xsi.taste_term          = g_detail_tab ( in_line_cnt ) .taste_term)
              OR (xsi.taste_term IS NULL)
             )
      AND    (   (xsi.difference_summary_code  = g_detail_tab ( in_line_cnt ) .difference_summary_code)
              OR (xsi.difference_summary_code IS NULL)
             )
-- == 2009/05/14 V1.5 Modified END   ===============================================================
      AND    xsi.slip_type                = cv_slip_type
      AND    xsi.summary_data_flag        = cv_n_flag
      ;
      ob_record_valid := TRUE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_record_valid := FALSE;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ob_record_valid := FALSE;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ob_record_valid := FALSE;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ob_record_valid := FALSE;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_detail_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_period_status�i���[�v���j
   * Description      : �݌ɉ�v���ԃ`�F�b�N(A-20)
   ***********************************************************************************/
  PROCEDURE chk_period_status(
      in_slip_cnt   IN  NUMBER        --   1.���[�v�J�E���^
    , ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period_status';      -- �v���O������
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
    lb_fnc_status             BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
-- == 2009/12/14 V1.13 Added START ===============================================================
    CURSOR  cur_upd_lines
    IS
      SELECT  1
      FROM    xxwsh_order_headers_all   xoh
             ,xxwsh_order_lines_all     xol
      WHERE   xoh.order_header_id       =   xol.order_header_id
      AND     xoh.latest_external_flag  =   cv_y_flag
      AND     xoh.request_no            =   g_summary_tab ( in_slip_cnt ) .req_move_no
      FOR UPDATE NOWAIT;
-- == 2009/12/14 V1.13 Added END   ===============================================================
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===============================
    -- ���ʊ֐����g�p���݌ɉ�v���ԃX�e�[�^�X���擾
    -- ===============================
    IF ( TO_CHAR(gd_process_date,'YYYYMM') >= TO_CHAR(g_summary_tab ( in_slip_cnt ) .slip_date ,'YYYYMM')) THEN
      xxcoi_common_pkg.org_acct_period_chk(
          in_organization_id => gt_org_id                             -- 1.�݌ɑg�DID
        , id_target_date     => g_summary_tab ( in_slip_cnt ) .slip_date
                                                                      -- 2.�`�[���t
        , ob_chk_result      => lb_fnc_status
        , ov_errbuf          => lv_errbuf
        , ov_retcode         => lv_retcode
        , ov_errmsg          => lv_errmsg
      );
      IF ( lb_fnc_status = FALSE ) THEN
-- == 2009/12/14 V1.13 Added START ===============================================================
        -- �󒍖��׃��b�N�擾
        OPEN    cur_upd_lines;
        CLOSE   cur_upd_lines;
        --
        -- ���ɍ݌ɉ�v���Ԃ��N���[�Y����Ă���f�[�^�͎捞�ς݂Ƃ���
        -- �󒍖��ׁu�o�׎��јA�g�σt���O�v�X�V
        UPDATE xxwsh_order_lines_all xol
        SET    xol.shipping_result_if_flg   =   cv_y_flag
        WHERE  xol.order_header_id          =   ( SELECT    xoh.order_header_id
                                                  FROM      xxwsh_order_headers_all   xoh
                                                  WHERE     xoh.request_no            =   g_summary_tab ( in_slip_cnt ) .req_move_no
                                                  AND       xoh.latest_external_flag  =   cv_y_flag
                                                )
        ;
-- == 2009/12/14 V1.13 Added END   ===============================================================
        RAISE period_status_close_expt;
      ELSIF ( lv_retcode != cv_status_normal ) THEN
        RAISE period_status_common_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
-- == 2009/12/14 V1.13 Added START ===============================================================
    WHEN lock_expt THEN
      IF ( cur_upd_lines%ISOPEN ) THEN
        CLOSE cur_upd_lines;
      END IF;
      --
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_application
                        , iv_name         => cv_lines_lock_expt_msg
                        , iv_token_name1  => cv_tkn_den_no
                        , iv_token_value1 => g_summary_tab ( in_slip_cnt ) .req_move_no
                      );
      lv_errbuf   :=  lv_errmsg;
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  :=  cv_status_warn;
      --
-- == 2009/12/14 V1.13 Added END   ===============================================================
    WHEN period_status_close_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_period_status_close_msg
                     , iv_token_name1  => cv_tkn_den_no
                     , iv_token_value1 => gv_slip_num
                     , iv_token_name2  => cv_tkn_target
                     , iv_token_value2 => TO_CHAR ( g_summary_tab ( in_slip_cnt ) .slip_date , 'YYYY/MM/DD' )
                   );
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    WHEN period_status_common_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_period_status_cmn_msg
                     , iv_token_name1  => cv_tkn_target
                     , iv_token_value1 => TO_CHAR ( g_summary_tab ( in_slip_cnt ) .slip_date , 'YYYY/MM/DD' )
                   );
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END chk_period_status;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf    OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode   OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2 )    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- �v���O������
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
    lv_rowid                  ROWID;
    lt_req_status             xxcoi_storage_information.req_status%TYPE;
                                                                      -- �o�׈˗��X�e�[�^�X
    lb_record_valid           BOOLEAN;                                -- �o�^/�X�V����p�t���O
    lb_slip_chk_status        BOOLEAN;                                -- �`�[�P�ʃX�L�b�v����p�t���O
    lt_store_code             xxcoi_subinventory_info_v.store_code%TYPE;
                                                                      -- �q�ɃR�[�h
    lt_shop_code              xxcoi_subinventory_info_v.shop_code%TYPE;
                                                                      -- �X�܃R�[�h
    lt_auto_confirmation_flg  xxcoi_subinventory_info_v.auto_confirmation_flag%TYPE;
                                                                      -- �������Ɋm�F�t���O
    ln_store_check_cnt        NUMBER;                                 -- �������Ɋm�F�ϓ`�[�J�E���^
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
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
    -- A-1.��������
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf                                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode                                      -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.���ɏ��T�}���̎擾
    -- ===============================
    get_summary_record(
        ov_errbuf  => lv_errbuf                                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode                                      -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���ɏ��T�}�����o��0�����͒��o���R�[�h�Ȃ��ŏI��
    IF (gn_summary_cnt > 0) THEN
      <<g_summary_tab_loop>>
      FOR gn_slip_cnt IN 1 .. gn_summary_cnt LOOP
--
        --�`�[�P�ʏ�������t���O������
        lb_slip_chk_status := TRUE;
--
    -- ===============================
    -- �Z�[�u�|�C���g�ݒ�
    -- ===============================
        SAVEPOINT summary_point;
--
        gv_slip_num := g_summary_tab(gn_slip_cnt).req_move_no;
--
    -- ===============================
    -- A-4.�ۊǏꏊ��񏈗�
    -- ===============================
        IF ( lb_slip_chk_status = TRUE ) THEN
          get_subinventories(
              iv_base_code              => g_summary_tab(gn_slip_cnt).base_code
                                                                      -- 1.���_�R�[�h
-- == 2009/04/16 V1.3 Added START ===============================================================
            , it_deliverly_code         => g_summary_tab(gn_slip_cnt).deliverly_code
                                                                      -- 2.�z����R�[�h
-- == 2009/04/16 V1.3 Added END   ===============================================================
            , it_org_id                 => gt_org_id                  -- 3.�݌ɑg�DID
            , ot_store_code             => lt_store_code              -- 4.�q�ɃR�[�h
            , ot_shop_code              => lt_shop_code               -- 5.�X�܃R�[�h
            , ot_auto_confirmation_flag => lt_auto_confirmation_flg   -- 6.�������Ɋm�F�t���O
            , ov_errbuf                 => lv_errbuf                  -- �G���[�E���b�Z�[�W
            , ov_retcode                => lv_retcode                 -- ���^�[���E�R�[�h
            , ov_errmsg                 => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            gn_warn_cnt := gn_warn_cnt + 1;
            lb_slip_chk_status := FALSE;
          END IF;
        END IF;
--
    -- ===============================
    -- A-15.�i�ڗL���`�F�b�N
    -- ===============================
        IF ( lb_slip_chk_status = TRUE ) THEN
          chk_item(
              in_slip_cnt => gn_slip_cnt                              -- 1.���[�v�J�E���^
            , ov_errbuf   => lv_errbuf                                -- �G���[�E���b�Z�[�W
            , ov_retcode  => lv_retcode                               -- ���^�[���E�R�[�h
            , ov_errmsg   => lv_errmsg                                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            gn_warn_cnt := gn_warn_cnt + 1;
            lb_slip_chk_status := FALSE;
          END IF;
        END IF;
--
    -- ===============================
    -- A-20.�݌ɉ�v���ԃ`�F�b�N
    -- ===============================
        IF ( lb_slip_chk_status = TRUE ) THEN
          chk_period_status(
              in_slip_cnt => gn_slip_cnt                              -- 1.���[�v�J�E���^
            , ov_errbuf   => lv_errbuf                                -- �G���[�E���b�Z�[�W
            , ov_retcode  => lv_retcode                               -- ���^�[���E�R�[�h
            , ov_errmsg   => lv_errmsg                                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            gn_warn_cnt := gn_warn_cnt + 1;
            lb_slip_chk_status := FALSE;
          END IF;
        END IF;
--
-- *************************************************************************************************
--  �T�}�����̍쐬(START)
-- *************************************************************************************************
        -- �`�[�P�ʂł̃X�L�b�v����
        IF ( lb_slip_chk_status = TRUE ) THEN
          -- ===============================
          -- A-16.���ɏ��T�}�����݊m�F
          -- ===============================
          chk_summary_data(
              in_slip_cnt     => gn_slip_cnt                          -- 1.���[�v�J�E���^
            , iv_store_code   => lt_store_code                        -- 2.�q�ɃR�[�h
            , ov_rowid        => lv_rowid                             -- 3.ROWID
            , ot_req_status   => lt_req_status                        -- 4.�o�׈˗��X�e�[�^�X
            , ob_record_valid => lb_record_valid                      -- 5.TRUE:�T�}�����R�[�h���� FALSE:���݂���
            , ov_errbuf       => lv_errbuf                            -- �G���[�E���b�Z�[�W
            , ov_retcode      => lv_retcode                           -- ���^�[���E�R�[�h
            , ov_errmsg       => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ==========================================
          --  ���o�Ɉꎞ�\�ɃT�}���f�[�^�����݂���ꍇ
          -- ==========================================
          IF ( lb_record_valid = TRUE ) THEN
--
            IF ( lt_req_status IS NULL ) THEN
              -- ======================================
              -- ���o�Ɉꎞ�\�̏o�׈˗��X�e�[�^�X��NULL
              -- A-7.���ɏ��T�}���̍X�V
              -- ======================================
              upd_summary_disp(
                  in_slip_cnt   => gn_slip_cnt                        -- 1.���[�v�J�E���^
                , iv_rowid      => lv_rowid                           -- 2.�X�V�Ώ�ROWID
-- == 2009/12/18 V1.14 Added START ===============================================================
                , iv_store_code => lt_store_code                      -- 3.�q�ɃR�[�h
-- == 2009/12/18 V1.14 Added END   ===============================================================
                , ov_errbuf     => lv_errbuf                          -- �G���[�E���b�Z�[�W
                , ov_retcode    => lv_retcode                         -- ���^�[���E�R�[�h
                , ov_errmsg     => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                gn_warn_cnt := gn_warn_cnt + 1;
                lb_slip_chk_status := FALSE;
              END IF;
            ELSIF ( lt_req_status = gt_ship_status_close ) THEN
              -- ======================================
              -- ���o�Ɉꎞ�\�̏o�׈˗��X�e�[�^�X��03
              -- A-8.���ɏ��T�}���̍X�V
              -- ======================================
              upd_summary_close(
                  in_slip_cnt   => gn_slip_cnt                        -- 1.���[�v�J�E���^
                , iv_rowid      => lv_rowid                           -- 2.�X�V�Ώ�ROWID
-- == 2009/12/18 V1.14 Added START ===============================================================
                , iv_store_code => lt_store_code                      -- 3.�q�ɃR�[�h
-- == 2009/12/18 V1.14 Added END   ===============================================================
                , ov_errbuf     => lv_errbuf                          -- �G���[�E���b�Z�[�W
                , ov_retcode    => lv_retcode                         -- ���^�[���E�R�[�h
                , ov_errmsg     => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                gn_warn_cnt := gn_warn_cnt + 1;
                lb_slip_chk_status := FALSE;
              END IF;
            ELSIF ( lt_req_status = gt_ship_status_result ) THEN
              -- ======================================
              -- ���o�Ɉꎞ�\�̏o�׈˗��X�e�[�^�X��04
              -- A-9.���ɏ��T�}���̍X�V
              -- ======================================
              upd_summary_results(
                  in_slip_cnt   => gn_slip_cnt                        -- 1.���[�v�J�E���^
                , iv_rowid      => lv_rowid                           -- 2.�X�V�Ώ�ROWID
-- == 2009/12/18 V1.14 Added START ===============================================================
                , iv_store_code => lt_store_code                      -- 3.�q�ɃR�[�h
-- == 2009/12/18 V1.14 Added END   ===============================================================
                , ov_errbuf     => lv_errbuf                          -- �G���[�E���b�Z�[�W
                , ov_retcode    => lv_retcode                         -- ���^�[���E�R�[�h
                , ov_errmsg     => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                gn_warn_cnt := gn_warn_cnt + 1;
                lb_slip_chk_status := FALSE;
              END IF;
            END IF;
            --
-- == 2009/12/18 V1.14 Added START ===============================================================
            IF (lb_slip_chk_status) THEN
              -- ======================================
              -- A-21.�����׍폜����
              -- ======================================
              del_detail_data(
                  in_slip_cnt   => gn_slip_cnt                        -- 1.���[�v�J�E���^
                , iv_store_code => lt_store_code                      -- 2.�q�ɃR�[�h
                , ov_errbuf     => lv_errbuf                          -- �G���[�E���b�Z�[�W
                , ov_retcode    => lv_retcode                         -- ���^�[���E�R�[�h
                , ov_errmsg     => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                gn_warn_cnt := gn_warn_cnt + 1;
                lb_slip_chk_status := FALSE;
              END IF;
            END IF;
-- == 2009/12/18 V1.14 Added END   ===============================================================
          ELSE
            -- ===========================================
            --  ���o�Ɉꎞ�\�ɃT�}���f�[�^�����݂��Ȃ��ꍇ
            -- ===========================================
            -- =========================================
            -- �擾�����`�[�����Ɋm�F�ς��J�E���g
            -- =========================================
            BEGIN
              SELECT COUNT(*)
              INTO   ln_store_check_cnt
              FROM   xxcoi_storage_information xsi
              WHERE  xsi.slip_num = gv_slip_num
              AND    xsi.store_check_flag = cv_y_flag
              AND    ROWNUM = 1
              ;
            EXCEPTION
              WHEN OTHERS THEN
                ln_store_check_cnt := 0;
            END;
--
            IF ( ln_store_check_cnt > 0 ) THEN
              -- =========================================
              --  �擾�����`�[�����Ɋm�F�ς̏ꍇ
              --  A-6.���ɏ��T�}���̓o�^
              -- =========================================
              ins_summary_confirmed(
                  in_slip_cnt               => gn_slip_cnt            -- 1.���[�v�J�E���^
                , iv_store_code             => lt_store_code          -- 2.�q�ɃR�[�h
                , iv_shop_code              => lt_shop_code           -- 3.�X�܃R�[�h
                , it_auto_confirmation_flag => lt_auto_confirmation_flg
                                                                      -- 4.�������Ɋm�F�t���O
                , ov_errbuf                 => lv_errbuf              -- �G���[�E���b�Z�[�W
                , ov_retcode                => lv_retcode             -- ���^�[���E�R�[�h
                , ov_errmsg                 => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
            ELSE
              -- =========================================
              --  �擾�����`�[�����ɖ��m�F�̏ꍇ
              --  A-5.���ɏ��T�}���̓o�^
              -- =========================================
              ins_summary_unconfirmed(
                  in_slip_cnt               => gn_slip_cnt            -- 1.���[�v�J�E���^
                , iv_store_code             => lt_store_code          -- 2.�q�ɃR�[�h
                , iv_shop_code              => lt_shop_code           -- 3.�X�܃R�[�h
                , it_auto_confirmation_flag => lt_auto_confirmation_flg
                                                                      -- 4.�������Ɋm�F�t���O
                , ov_errbuf                 => lv_errbuf              -- �G���[�E���b�Z�[�W
                , ov_retcode                => lv_retcode             -- ���^�[���E�R�[�h
                , ov_errmsg                 => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          END IF;
          --
-- == 2009/12/18 V1.14 Added START ===============================================================
          -- �`�[���t�s��v�f�[�^�̏o�ɑ����ʏ�����
          IF (lb_slip_chk_status) THEN
            -- ======================================
            -- A-22.�����o�ɐ��ʏ���������
            -- ======================================
            upd_old_data(
                in_slip_cnt   => gn_slip_cnt                        -- 1.���[�v�J�E���^
              , iv_store_code => lt_store_code                      -- 2.�q�ɃR�[�h
              , ov_errbuf     => lv_errbuf                          -- �G���[�E���b�Z�[�W
              , ov_retcode    => lv_retcode                         -- ���^�[���E�R�[�h
              , ov_errmsg     => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            ELSIF ( lv_retcode = cv_status_warn ) THEN
              gn_warn_cnt := gn_warn_cnt + 1;
              lb_slip_chk_status := FALSE;
            END IF;
          END IF;
-- == 2009/12/18 V1.14 Added END   ===============================================================
        END IF;
-- *************************************************************************************************
--  �T�}�����̍쐬(END)
-- *************************************************************************************************
--
-- *************************************************************************************************
--  ���׏��̍쐬(START)
-- *************************************************************************************************
        -- �`�[�P�ʂł̃X�L�b�v����
        IF ( lb_slip_chk_status = TRUE ) THEN
          -- ===============================
          -- A-3.���ɏ��ڍׂ̎擾
          -- ===============================
          get_detail_record(
              in_slip_cnt => gn_slip_cnt                              -- 1.���[�v�J�E���^
            , ov_errbuf   => lv_errbuf                                -- �G���[�E���b�Z�[�W
            , ov_retcode  => lv_retcode                               -- ���^�[���E�R�[�h
            , ov_errmsg   => lv_errmsg                                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          <<g_detail_tab_loop>>
          FOR gn_line_cnt IN 1..g_detail_tab.COUNT LOOP
-- == 2009/12/18 V1.14 Deleted START ===============================================================
--             -- ===============================
--             -- A-17.���ɏ��ڍב��݊m�F
--             -- ===============================
--             chk_detail_data(
--                 in_line_cnt     => gn_line_cnt                        -- 1.���[�v�J�E���^
--               , iv_store_code   => lt_store_code                      -- 2.�q�ɃR�[�h
--               , ov_rowid        => lv_rowid                           -- 3.ROWID
--               , ot_req_status   => lt_req_status                      -- 4.�o�׈˗��X�e�[�^�X
--               , ob_record_valid => lb_record_valid                    -- 5.TRUE:�ڍ׃��R�[�h���� FALSE:���݂���
--               , ov_errbuf       => lv_errbuf                          -- �G���[�E���b�Z�[�W
--               , ov_retcode      => lv_retcode                         -- ���^�[���E�R�[�h
--               , ov_errmsg       => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
--             );
--             IF ( lv_retcode = cv_status_error ) THEN
--               RAISE global_process_expt;
--             END IF;
-- == 2009/12/18 V1.14 Deleted END   ===============================================================
--
-- == 2009/12/18 V1.14 Modified START ===============================================================
--             IF ( lb_record_valid = TRUE ) THEN
--               IF ( lt_req_status = gt_ship_status_result ) THEN
--                 -- ===============================
--                 -- A-12.���ɏ��ڍׂ̍X�V
--                 -- ===============================
--                 upd_detail_results(
--                     in_line_cnt   => gn_line_cnt                      -- 1.���[�v�J�E���^
--                   , iv_rowid      => lv_rowid                         -- 2.�X�V�Ώ�ROWID
--                   , iv_store_code => lt_store_code                    -- 3.�q�ɃR�[�h
--                   , iv_shop_code  => lt_shop_code                     -- 4.�X�܃R�[�h
--                   , ov_errbuf     => lv_errbuf                        -- �G���[�E���b�Z�[�W
--                   , ov_retcode    => lv_retcode                       -- ���^�[���E�R�[�h
--                   , ov_errmsg     => lv_errmsg                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--                 );
--                 IF ( lv_retcode = cv_status_error ) THEN
--                   RAISE global_process_expt;
--                 ELSIF ( lv_retcode = cv_status_warn ) THEN
--                   gn_warn_cnt := gn_warn_cnt + 1;
--                   lb_slip_chk_status := FALSE;
--                   -- ���`�[No�֑J��
--                   EXIT g_detail_tab_loop;
--                 END IF;
--               ELSE
--                 -- ===============================
--                 -- A-11.���ɏ��ڍׂ̍X�V
--                 -- ===============================
--                 upd_detail_close(
--                     in_line_cnt   => gn_line_cnt                      -- 1.���[�v�J�E���^
--                   , iv_rowid      => lv_rowid                         -- 2.�X�V�Ώ�ROWID
--                   , iv_store_code => lt_store_code                    -- 3.�q�ɃR�[�h
--                   , iv_shop_code  => lt_shop_code                     -- 4.�X�܃R�[�h
--                   , ov_errbuf     => lv_errbuf                        -- �G���[�E���b�Z�[�W
--                   , ov_retcode    => lv_retcode                       -- ���^�[���E�R�[�h
--                   , ov_errmsg     => lv_errmsg                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--                 );
--                 IF ( lv_retcode = cv_status_error ) THEN
--                   RAISE global_process_expt;
--                 ELSIF ( lv_retcode = cv_status_warn ) THEN
--                   gn_warn_cnt := gn_warn_cnt + 1;
--                   lb_slip_chk_status := FALSE;
--                   -- ���`�[No�֑J��
--                   EXIT g_detail_tab_loop;
--                 END IF;
--               END IF;
--             ELSE
--               -- ===============================
--               -- A-10.���ɏ��ڍׂ̓o�^
--               -- ===============================
--               ins_detail_confirmed(
--                   in_line_cnt               => gn_line_cnt            -- 1.���[�v�J�E���^
--                 , iv_store_code             => lt_store_code          -- 2.�q�ɃR�[�h
--                 , iv_shop_code              => lt_shop_code           -- 3.�X�܃R�[�h
--                 , it_auto_confirmation_flag => lt_auto_confirmation_flg
--                                                                       -- 4.�������Ɋm�F�t���O
--                 , ov_errbuf                 => lv_errbuf              -- �G���[�E���b�Z�[�W
--                 , ov_retcode                => lv_retcode             -- ���^�[���E�R�[�h
--                 , ov_errmsg                 => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
--               );
--               IF ( lv_retcode = cv_status_error ) THEN
--                 RAISE global_process_expt;
--               END IF;
--             END IF;
--
            -- ===============================
            -- A-10.���ɏ��ڍׂ̓o�^
            -- ===============================
            ins_detail_confirmed(
                in_line_cnt               => gn_line_cnt            -- 1.���[�v�J�E���^
              , iv_store_code             => lt_store_code          -- 2.�q�ɃR�[�h
              , iv_shop_code              => lt_shop_code           -- 3.�X�܃R�[�h
              , it_auto_confirmation_flag => lt_auto_confirmation_flg
                                                                    -- 4.�������Ɋm�F�t���O
              , ov_errbuf                 => lv_errbuf              -- �G���[�E���b�Z�[�W
              , ov_retcode                => lv_retcode             -- ���^�[���E�R�[�h
              , ov_errmsg                 => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
-- == 2009/12/18 V1.14 Modified END   ===============================================================
            --
            -- ===============================
            -- A-13.�󒍖��׃A�h�I���̍X�V
            -- ===============================
            upd_order_lines(
                in_line_cnt => gn_line_cnt                            -- 1.���[�v�J�E���^
              , ov_errbuf   => lv_errbuf                              -- �G���[�E���b�Z�[�W
              , ov_retcode  => lv_retcode                             -- ���^�[���E�R�[�h
              , ov_errmsg   => lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W
            );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            ELSIF ( lv_retcode = cv_status_warn ) THEN
              gn_warn_cnt := gn_warn_cnt + 1;
              -- ���`�[No�֑J��
              EXIT g_detail_tab_loop;
            END IF;
            --
          END LOOP g_detail_tab_loop;
        END IF;
--
        -- ����I�������J�E���g�A�b�v�i�`�[�P�ʁj
        IF ( lb_slip_chk_status = TRUE ) THEN
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSE
          fnd_file.put_line(
              which => fnd_file.output
            , buff  => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          fnd_file.put_line(
              which => fnd_file.log
            , buff  => lv_errbuf --�G���[���b�Z�[�W
          );
        END IF;
      END LOOP g_summary_tab_loop;
-- *************************************************************************************************
--  ���׏��̍쐬(END)
-- *************************************************************************************************
    ELSE
      -- �ΏۃT�}�����O���̏ꍇ
      lv_retcode := cv_status_normal;
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                     , iv_name         => cv_not_found_slip_msg
                   );
      lv_errbuf := lv_errmsg;
    END IF;
--
    -- ===============================
    -- A-17.�I������
    -- ===============================
--
    IF ( lv_retcode = cv_status_error ) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      --�x������
      --submain�̏I���X�e�[�^�X(ov_retcode)�̃Z�b�g��
      --�G���[���b�Z�[�W���Z�b�g���郍�W�b�N�Ȃǂ��L�q���ĉ������B
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    ELSIF ( gn_warn_cnt > 0 ) THEN
      --�x������
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
--
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      gn_error_cnt := 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      gn_error_cnt := 1;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      gn_error_cnt := 1;
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
      errbuf      OUT VARCHAR2       --   �G���[�E���b�Z�[�W  --# �Œ� #
    , retcode     OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
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
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
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
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      fnd_file.put_line(
          which => fnd_file.output
        , buff  => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
          which => fnd_file.log
        , buff  => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    fnd_file.put_line(
        which => fnd_file.output
      , buff  => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                   );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_warn_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_warn_cnt )
                   );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_error_cnt )
                   );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name
                    , iv_name        => lv_message_code
                   );
    fnd_file.put_line(
        which => fnd_file.output
      , buff  => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCOI001A01C;
/
